#!/bin/bash

start_hotfix() {
  local hotfix_branch=$(hotfix_branch $1)
  ensure_branch_does_not_exist $feature_branch || return 1
  
  prepare_env_for_feature || return 1
  
  # Crear rama desde MAIN_BRANCH
  git checkout "$MAIN_BRANCH" && git pull origin "$MAIN_BRANCH" || return 1
  git checkout -b "$hotfix_branch" || return 1

  echo "🚑 Se ha creado la rama: $hotfix_branch"
}

finish_hotfix() {
	if [[ "$DEVELOP_BRANCH_PROTECTED" == "true" ]]; then
		echo "❌ La rama develop está protegida, no se puede mergear directamente."
	fi
	local hotfix_branch=$(hotfix_branch $1)

	ensure_branch_exists $hotfix_branch || return 1
	
	prepare_env_for_feature || return 1

    # Merge a main y tagueo
    git checkout "$MAIN_BRANCH" && git pull origin "$MAIN_BRANCH" || return 1
    git merge --no-ff "$hotfix_branch" || return 1
    git tag "v$1"
    git push origin "$MAIN_BRANCH"
    git push origin "v$1"

    # Merge a develop si no está protegida
    git checkout "$DEVELOP_BRANCH" && git pull origin "$DEVELOP_BRANCH" || return 1
    git merge --no-ff "$hotfix_branch" || return 1
    git push origin "$DEVELOP_BRANCH"
  
    git branch -d "$hotfix_branch"
    git push origin --delete "$hotfix_branch"
}

hotfix_branch() {
    local name="$1"

	if [[ -z "$name" ]]; then
		echo "❌ No se indica el nombre de la rama."
		return 1
	fi

    local prefix=""
	if [[ "$FEATURE_USE_VERSION_PREFIX" == "true" ]]; then
		git checkout main
		prefix=$(get_version)
		prefix="${prefix}-"
	fi
	echo hotfix/${prefix}${name}
}
