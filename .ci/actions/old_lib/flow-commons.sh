#!/bin/bash

source .ci/actions/lib/project-manager/project-manager-interface.sh
source .ci/actions/lib/repository/git-commons.sh

CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
PREV_BRANCH=$CURRENT_BRANCH

#
# Used to mark a branch as final point to checkout
#
move_branch() {
	PREV_BRANCH="$1"
	CURRENT_BRANCH="$1"
}

#
# Back to the initial branch
# If some where the branc is moved, then checkout to that branch
#
cleanup() {
	git checkout $PREV_BRANCH >/dev/null 2>&1
}

finish() {
	cleanup
	exit
}

trap cleanup EXIT
trap finish SIGINT SIGTERM

#
# Utility, if a method build properties for an object we can read a property with these.
# A property is a key=value
# lookup for a issue, or git info are build on these way.
#
read_from_properties() {
	local FIELD="$1"
	local METADATA="$2"
	echo "$METADATA" | grep $FIELD | cut -d= -f2
}


#
# Move to develop branch, check sync, check no conflicts with release branch neither main branch
#
verify_develop() {
	if [[ "$CURRENT_BRANCH" != "$DEVELOP_BRANCH" ]]; then
		git checkout $DEVELOP_BRANCH >/dev/null 2>&1
		CURRENT_BRANCH=$DEVELOP_BRANCH
	fi
	# Branches are sync
	check_sync_branchs "$MAIN_BRANCH" "$RELEASE_BRANCH" "$DEVELOP_BRANCH" 
	
	# Release is not ahead of main
	verify_protected $RELEASE_BRANCH $MAIN_BRANCH 
	
	# Develop is not ahead of release
	verify_protected $DEVELOP_BRANCH $RELEASE_BRANCH 
	
	git checkout $CURRENT_BRANCH >/dev/null 2>&1
}

#
# Move to release branch, check sync, check no conflicts with main branch
#
verify_release() {
	if [[ "$CURRENT_BRANCH" != "$RELEASE_BRANCH" ]]; then
		git checkout $RELEASE_BRANCH >/dev/null 2>&1
		CURRENT_BRANCH=$RELEASE_BRANCH
	fi
	# Branches are sync
	check_sync_branchs "$MAIN_BRANCH" "$RELEASE_BRANCH" "$DEVELOP_BRANCH" 

	# Release is not ahead of main
	verify_protected $RELEASE_BRANCH $MAIN_BRANCH 
	
	git checkout $CURRENT_BRANCH >/dev/null 2>&1
}

#
# Verify that we are on a feature branch, check sync, check no conflicts with development
#
verify_current() {
	if [[ "$CURRENT_BRANCH" == "$DEVELOP_BRANC" || "$CURRENT_BRANCH" == "$DEVELOP_BRANCH" || "$CURRENT_BRANCH" == "$DEVELOP_BRANC" ]]; then
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
# Verify that a protected branch is not ahead of another
# If the branch is ahead, we build a temp branch, merge from source branch to the temp branch,
# and create a pr to integrate the pr on the target branch (witch is protected and cant be merged directly).
#
# private
#
verify_protected() {
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
		local WEB=$(read_from_properties "web-url" "$PR_INFO")
		echo "Review and merge PR #$PR at $WEB"
    	exit -1
	fi
}

# 
# Mark current version on git log
# Create a PR from current branch with development and mark for squash
#
create_squash_from_current_to_develop() {
	local TARGET_BRANCH=$DEVELOP_BRANCH
	local next_version=$(git_next_version "snapshot")
	local message="$CURRENT_BRANCH developments"

	git checkout $CURRENT_BRANCH >/dev/null 2>&1

	echo "- Mark release version as $next_version"
	set_project_version_in_repo $next_version
	git commit -m "chore(release): $next_version" >/dev/null 2>&1
	
	LOCAL_COMMIT=$(git rev-parse @)
	REMOTE_COMMIT=$(git rev-parse @{u})
	BASE_COMMIT=$(git merge-base @ @{u})
	
	echo "- Push changes to origin/$CURRENT_BRANCH for RC creation"
	git push >/dev/null 2>&1
	echo "- Creating the PR"
	local PR=$(create_squash_merge $TARGET_BRANCH $CURRENT_BRANCH)
	if [[ "$PR" == "" ]]; then
		local PREV_PR=$(lookup_pr $TARGET_BRANCH $CURRENT_BRANCH)
		local MR=$(read_from_properties "id" "$PREV_PR")
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
merge_squash_from_current_to_develop() {
	local CURRENT_VERSION=$(git_current_version "snapshot")
	local PR=$(merge_pr $DEVELOP_BRANCH $CURRENT_BRANCH)
	echo "- PR #$PR was merged with develop"
	git checkout $DEVELOP_BRANCH >/dev/null 2>&1
	echo "- Remote branch $CURRENT_BRANCH should be removed"
	echo "    git branch --delete $CURRENT_BRANCH"
	move_branch $DEVELOP_BRANCH
}

#
# For a protected branch (main or release) and a version, we create a PR merge
#
create_upgrade_to_branch_for_version() {
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
	set_project_version_in_repo $VERSION
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
	
	echo "PR #$PR created"
}

#
# Merge a PR that update the code of main or release branch (if the user has the right permissions)
# We suppose that the user will have permissions to merge the above PR to sync the lower branches.
# If we merge to main: we create a PR to sync release with main, update release version a merge the PR
# After that (or always if is a merge to release): we create a PR to sync develop with release, update snapshot and merge the PR
# At least, we make a fetch pull on local.
#
merge_upgrade_to_branch_for_version() {
	local TARGET_BRANCH=$1
	local VERSION=$2
	
	# Ya estan sincronizados main - release - develop
	# Hay una PR creada
	local PR=$(merge_pr $TARGET_BRANCH temp/$TARGET_BRANCH-$VERSION)
	local PR_INFO=$(lookup_pr $TARGET_BRANCH temp/$TARGET_BRANCH-$VERSION)
	local DESCRIPTION=$(read_from_properties "description" "$PR_INFO")
	
	echo "- PR #$PR merged"
	echo "- Debemos ver de crear un tag"
	local version=$(get_version)
	git tag -a "v$(version)" -v "$DESCRIPTION"
	git push origin --tags
	
	if [[ "$TARGET_BRANCH" == "$MAIN_BRANCH" || "$TARGET_BRANCH" == "$RELEASE_BRANCH" ]]; then
		local NEW_RELEASE=$(git_next_version "release")
		local NEW_DEV=$(git_next_version "snapshot")
		if [[ "$TARGET_BRANCH" == "$MAIN_BRANCH" ]]; then
			# Para el merge de pro => actualizamos
			merge_and_change_version "$MAIN_BRANCH" "$RELEASE_BRANCH" "$NEW_RELEASE" 
		fi
		# Una vez mergeado -> actualizamos dev
		merge_and_change_version "$RELEASE_BRANCH" "$DEVELOP_BRANCH" "$NEW_DEV"
	fi
	echo "- Remove temp branch on local"
	git branch -D temp/$TARGET_BRANCH-$VERSION >/dev/null 2>&1
	echo "- Update local dev"
	update_current_with_development
}

#
# Create a temp branch from a source branch.
# Update version number and changelog on that branch.
# Create a commit with the version number.
# Create a merge request from the temp branch to the target branch
# waits for 5secs
# Merge the PR
# Delete temp branch.
#
# private
#
merge_and_change_version() {
	local BASE="$1"
	local HEAD="$2"
	local VERSION="$3"
	local TEMP_BRANCH=temp/${HEAD}-with-${BASE}-for-$VERSION
	
	git checkout $HEAD >/dev/null 2>&1
 	git pull >/dev/null 2>&1
	git fetch >/dev/null 2>&1
	
	git branch -D $TEMP_BRANCH >/dev/null 2>&1
	git checkout -b $TEMP_BRANCH  >/dev/null 2>&1
	git merge -X theirs origin/$BASE >/dev/null 2>&1
	
	echo "- Update version to $VERSION"
	set_project_version_in_repo $VERSION
	echo "- Generate changelog for release" 
	git_change_log release > CHANGELOG.md
	git add CHANGELOG.md  >/dev/null 2>&1
	git commit -m "chore(release): $VERSION"  >/dev/null 2>&1
	
	git push --set-upstream origin $TEMP_BRANCH >/dev/null 2>&1
	
	local DEV_PR=$(create_merge_pr "Update develop with release" "Update develop with release to get last changes" $HEAD $TEMP_BRANCH)
	echo "- PR #$DEV_PR created"
	sleep 5
	local MERGE_DEV=$(merge_pr $HEAD $TEMP_BRANCH)
	echo "- PR #$MERGE_DEV merged"
	
	git branch -D $TEMP_BRANCH >/dev/null 2>&1
}

#
# Update local brach of development, and after that merge with current branch
#
# private
#
update_current_with_development() {
 	git checkout $CURRENT_BRANCH >/dev/null 2>&1
 	git pull >/dev/null 2>&1
 	git fetch >/dev/null 2>&1
 	git merge -X theirs origin/$DEVELOP_BRANCH >/dev/null 2>&1
 	git push >/dev/null 2>&1
}

#
# Set project version, retrieve the list of modified files, and add all of them to the stash
#
# private
#
set_project_version_in_repo() {
  local FILES=$(set_project_version $1)
  while IFS= read -r file; do
    git add $file
  done <<< "$FILES"
}
