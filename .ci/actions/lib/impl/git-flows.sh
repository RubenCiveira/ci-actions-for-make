#!/bin/bash

CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
PREV_BRANCH=$CURRENT_BRANCH

set_branch() {
	PREV_BRANCH="$1"
	CURRENT_BRANCH="$1"
}

cleanup() {
	git checkout $PREV_BRANCH >/dev/null 2>&1
}

finish() {
	cleanup
	exit
}

trap cleanup EXIT
trap finish SIGINT SIGTERM

create_new_branch() {
	echo "Creando la rama $1"
	git checkout $DEVELOPMENT_BRANCH >/dev/null 2>&1
	git pull >/dev/null 2>&1
	git checkout -b "$1" >/dev/null 2>&1
	
	_priv_load_into_develop
	
	git push --set-upstream origin "$1" >/dev/null 2>&1
	
	set_branch "$1"
}

merge_from_develop() {
	_priv_load_into_develop
	
	echo "GIT PUSH"
	
	git push 
}

version() {
	git_next_version "snapshot"
	echo "La siguiente version snap es es ${next_version}"
	git_next_version "release"
	echo "La siguiente version rc es es ${next_version}"
	git_next_version "final"
}

#
# Verify that we are on a feature branch, check sync, check no conflicts with development
#
verify_current_branch_clean() {
	if [[ "$CURRENT_BRANCH" == "$DEVELOP_BRANCH" || "$CURRENT_BRANCH" == "$DEVELOP_BRANCH" || "$CURRENT_BRANCH" == "$DEVELOP_BRANC" ]]; then
		echo "Unable to add feature to develop from $CURRENT_BRANCH"
		exit -1
	fi
	# Branches are sync
	check_sync_branchs "$MAIN_BRANCH" "$RELEASE_BRANCH" "$DEVELOP_BRANCH" "$CURRENT_BRANCH"

	echo "- Check that $DEVELOP_BRANCH is not ahead of $CURRENT_BRANCH"
	local verify=$(check_branch_ahead_of $DEVELOP_BRANCH $CURRENT_BRANCH)
	if [[ "$verify" != "ok" ]]; then
		echo "ERROR: $DEVELOP_BRANCH is ahead of $CURRENT_BRANCH, merge is neccesary"
		echo "      git merge $DEVELOP_BRANCH"
		echo "      resolve and accept"
		echo "      git push"
		exit 1
	fi
	
	git checkout $CURRENT_BRANCH >/dev/null 2>&1
}

#
# Move to release branch, check sync, check no conflicts with main branch
#
change_to_clean_release() {
	if [[ "$CURRENT_BRANCH" != "$DEVELOP_BRANCH" ]]; then
		git checkout $DEVELOP_BRANCH >/dev/null 2>&1
		CURRENT_BRANCH=$DEVELOP_BRANCH
	fi
	# Branches are sync
	check_sync_branchs "$MAIN_BRANCH" "$RELEASE_BRANCH" "$DEVELOP_BRANCH" 
	
	# Develop is not ahead of release
	check_protected_branch_ahead_of $DEVELOP_BRANCH $RELEASE_BRANCH 
	
	git checkout $CURRENT_BRANCH >/dev/null 2>&1
}

change_to_clean_main() {
	if [[ "$CURRENT_BRANCH" != "$RELEASE_BRANCH" ]]; then
		git checkout $RELEASE_BRANCH >/dev/null 2>&1
		CURRENT_BRANCH=$RELEASE_BRANCH
	fi
	# Branches are sync
	check_sync_branchs "$MAIN_BRANCH" "$RELEASE_BRANCH" "$DEVELOP_BRANCH" 

	# Release is not ahead of main
	check_protected_branch_ahead_of $RELEASE_BRANCH $MAIN_BRANCH 
	
	git checkout $CURRENT_BRANCH >/dev/null 2>&1
}

# 
# Mark current version on git log
# Create a PR from current branch with development and mark for squash
#
create_pr_to_develop() {
	verify_current_branch_clean
	local TARGET_BRANCH=$DEVELOP_BRANCH
	local next_version=$(git_next_version "snapshot")
	local message="$CURRENT_BRANCH developments"

	git checkout $CURRENT_BRANCH >/dev/null 2>&1

	echo "- Mark release version as $next_version"
	_priv_set_project_version_in_repo $next_version
	git commit -m "chore(release): $next_version" >/dev/null 2>&1
	
	LOCAL_COMMIT=$(git rev-parse @)
	REMOTE_COMMIT=$(git rev-parse @{u})
	BASE_COMMIT=$(git merge-base @ @{u})
	
	echo "- Push changes to origin/$CURRENT_BRANCH for RC creation"
	git push >/dev/null 2>&1
	echo "- Creating the PR from ${CURRENT_BRANCH} to ${TARGET_BRANCH}"
	local PR=$(create_squash_merge $TARGET_BRANCH $CURRENT_BRANCH)
	if [[ "$PR" == "" ]]; then
		local PREV_PR=$(lookup_pr $TARGET_BRANCH $CURRENT_BRANCH)
		local MR=$(_priv_read_from_properties "id" "$PREV_PR")
		echo "- That PR #$MR already exists"
	else
		echo "- PR #$PR created"
	fi
}

#
# Based on current version (previous create PR update the version number)
# Merge the PR (if the user has the right permissions)
# Move to develop branch and suggest to delete the squash branch
#
merge_pr_in_develop() {
	local CURRENT_VERSION=$(git_current_version "snapshot")
	local PR=$(merge_pr $DEVELOP_BRANCH $CURRENT_BRANCH)
	echo "- PR #$PR was merged with develop"
	git checkout $DEVELOP_BRANCH >/dev/null 2>&1
	echo "- Remote branch $CURRENT_BRANCH should be removed"
	echo "    git branch --delete $CURRENT_BRANCH"
	set_branch $DEVELOP_BRANCH
}

create_pr_to_rc() {
	change_to_clean_release
	git checkout develop  >/dev/null 2>&1
	NEXT_VERSION=$(git_next_version "release")
	
	_priv_create_pr_to_branch_for_version $RELEASE_BRANCH $NEXT_VERSION
}

merge_pr_in_rc() {
	change_to_clean_release
	git checkout develop  >/dev/null 2>&1
	NEXT_VERSION=$(git_next_version "release")

	_priv_merge_pr_to_branch_for_version $RELEASE_BRANCH $NEXT_VERSION
	_priv_update_on_development
}

create_pr_to_main() {
	change_to_clean_main
	git checkout release  >/dev/null 2>&1
	NEXT_VERSION=$(git_next_version "final")
	
	_priv_create_pr_to_branch_for_version $MAIN_BRANCH $NEXT_VERSION
}

merge_pr_in_main() {
	change_to_clean_main
	git checkout release  >/dev/null 2>&1
	NEXT_VERSION=$(git_next_version "final")

	_priv_merge_pr_to_branch_for_version $MAIN_BRANCH $NEXT_VERSION
	_priv_update_on_development
}

_priv_create_pr_to_branch_for_version() {
	local TARGET_BRANCH=$1
	local VERSION=$2
	
	echo "- Mark release version as $VERSION"
	TEMP_BRANCH=temp/${TARGET_BRANCH}-$VERSION
	if git ls-remote --heads origin "$TEMP_BRANCH" | grep -q "$BRANCH_NAME"; then
    	echo "Error: La rama '$TEMP_BRANCH' ya existe en el remoto."
    	exit 1
	fi

	git branch -D $TEMP_BRANCH >/dev/null 2>&1
	git checkout -b $TEMP_BRANCH  >/dev/null 2>&1
	echo "- Update version to $VERSION"
	_priv_set_project_version_in_repo $VERSION

	echo "- Generate changelog for release"
	
	if [[ "$TARGET_BRANCH" == "$MAIN_BRANCH" ]]; then
		git_change_log final > CHANGELOG.md
	else
		git_change_log release > CHANGELOG.md
	fi
	
	git add CHANGELOG.md  >/dev/null 2>&1
	git commit -m "chore(release): $VERSION"  >/dev/null 2>&1
	echo "- Push changes to $TEMP_BRANCH for PR creation"
	git push --set-upstream origin $TEMP_BRANCH >/dev/null 2>&1
	git checkout $CURRENT_BRANCH  >/dev/null 2>&1
	
	echo "- Creating PR to merge changes on $TARGET_BRANC" 
	local PR=$(create_upgrade_pr "Create relese $VERSION" $TARGET_BRANCH $TEMP_BRANCH)
	
	echo "- PR #$PR created"
}

_priv_merge_pr_to_branch_for_version() {
	local TARGET_BRANCH=$1
	local VERSION=$2
	
	# Ya estan sincronizados main - release - develop
	local PR_INFO=$(lookup_pr $TARGET_BRANCH temp/$TARGET_BRANCH-$VERSION)
	local DESCRIPTION=$(_priv_read_from_properties "title" "$PR_INFO")
	# Hay una PR creada
	local PR=$(merge_pr $TARGET_BRANCH temp/$TARGET_BRANCH-$VERSION)
	echo "- PR #$PR merged"
	echo "- Debemos ver de crear un tag"
	local version=$(get_version)
	echo "- Creando tag ${version} con ${DESCRIPTION}"
	
	git tag -a "v${version}" -m "${DESCRIPTION}"
	git push origin --tags
	
	echo "- Remove temp branch on local"
	git branch -D temp/$TARGET_BRANCH-$VERSION >/dev/null 2>&1
}

_priv_read_from_properties() {
	local FIELD="$1"
	local METADATA="$2"
	# echo "$METADATA" | grep $FIELD | cut -d= -f2
	echo "$METADATA" | grep "^$FIELD=" | cut -d= -f2
}

_priv_set_project_version_in_repo() {
  local CURRENT=$(get_version)
  if [[ "$CURRENT" != "$1" ]]; then
  	local FILES=$(set_version $1)
    while IFS= read -r file; do
      git add $file
    done <<< "$FILES"
  fi
}

_priv_update_on_development() {
 	git checkout $DEVELOP_BRANC >/dev/null 2>&1
 	git pull >/dev/null 2>&1
 	git fetch >/dev/null 2>&1
}

_priv_update_on_release() {
 	git checkout $RELEASE_BRANCH >/dev/null 2>&1
 	git pull >/dev/null 2>&1
 	git fetch >/dev/null 2>&1
}

_priv_load_into_develop() {
	_priv_load_remote $DEVELOP_BRANCH
	_priv_load_remote $RELEASE_BRANCH
	_priv_load_remote $MAIN_BRANCH

	NEXT_VERSION=$(git_next_version "snapshot")
	echo "- Update version to $NEXT_VERSION"
	_priv_set_project_version_in_repo $NEXT_VERSION
	echo "- Generate changelog for release" 
	git_change_log release > CHANGELOG.md
	echo "- Add to index"
	git add CHANGELOG.md  >/dev/null 2>&1
	if ! git diff --quiet HEAD --cached; then
        echo "- Commit of version adjutment"
		git commit -m "chore(release): $NEXT_VERSION"  >/dev/null 2>&1
    else
        echo "- No changes from relase to commit"
    fi
}

_priv_load_remote() {
	git fetch origin $BRANCH:$BRANCH
	local BRANCH="$1"
	git merge -X theirs origin/$BRANCH >/dev/null 2>&1
	
	if [ -f .git/MERGE_HEAD ]; then
        echo "- Commit with $BRANCH changes"
	    git diff --name-only --diff-filter=U | xargs git restore --source=MERGE_HEAD --staged --worktree >/dev/null 2>&1
	    git add . >/dev/null 2>&1
        git commit -m "chore(merge): Merge $BRANCH" >/dev/null 2>&1 
    else
        echo "- No changes from $BRANCH to commit"
    fi
}

check_protected_branch_ahead_of() {
	local HEAD="$1" # develop
	local BASE="$2" # release
	echo "- Check that $BASE is not ahead of $HEAD"
	local verify=$(check_branch_ahead_of $BASE $HEAD)
	if [[ "$verify" != "ok" ]]; then
		local UPDATE_BRANCH=temp/update-$HEAD-with-$BASE
		echo "$verify"
    	echo "Error, $HEAD is ahead of $BASE, a PR '$UPDATE_BRANCH' will be created to merge diffs."
		echo "    - Creating branch $UPDATE_BRANCH form $BASE for merge PR"	
		git checkout $BASE >/dev/null 2>&1
		git branch --delete $UPDATE_BRANCH >/dev/null 2>&1 
		git checkout -b $UPDATE_BRANCH >/dev/null 2>&1
		echo "    - Pushing $UPDATE_BRANCH to origin"
		git push --set-upstream origin $UPDATE_BRANCH >/dev/null 2>&1
		echo "    - Creating PR"
		local PR=$(create_merge_pr "Update $HEAD with $BASE" "Update $HEAD with $BASE to confirm than $BASE is not ahead of $HEAD" $HEAD $UPDATE_BRANCH)
		local PR_INFO=$(lookup_pr $HEAD $UPDATE_BRANCH)
		local WEB=$(_priv_read_from_properties "web-url" "$PR_INFO")
		echo "Review and merge PR #$PR at $WEB"
    	exit -1
	fi
}
