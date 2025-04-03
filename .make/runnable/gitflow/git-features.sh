#!/bin/bash

start_feature() {
	local feature_branch=$(feature_branch $1)
	ensure_branch_does_not_exist $feature_branch || return 1

	prepare_env_for_feature || return 1
	git checkout -b "$feature_branch" || return 1
	echo "🚀 Se ha creado la rama: $feature_branch"
}

finish_feature() {
	if [[ "$DEVELOP_BRANCH_PROTECTED" == "true" ]]; then
		echo "❌ La rama develop está protegida, no se puede mergear directamente."
	fi
	local feature_branch=$(feature_branch $1)

	ensure_branch_exists $feature_branch || return 1
	
	prepare_env_for_feature || return 1
	git checkout develop
	git merge --no-ff $feature_branch
	git branch -d $feature_branch
	git push origin develop
}

feature_branch() {
    local name="$1"

    if [[ -z "$DEVELOP_BRANCH_PROTECTED" ]]; then
        echo "Develop está protegida"
		return 1
    fi
	if [[ -z "$name" ]]; then
		echo "Uso: ./run.sh start_feature nombre"
		return 1
	fi

    local prefix=""
	if [[ "$FEATURE_USE_VERSION_PREFIX" == "true" ]]; then
		prefix="${CURRENT_VERSION}-"
	fi
	echo feature/${prefix}${name}
}
