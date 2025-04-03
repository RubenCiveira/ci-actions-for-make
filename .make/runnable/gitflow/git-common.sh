#!/bin/bash

ensure_branch_exists() {
	local branch="$1"

	local exists_local=true
	local exists_remote=true

	if ! git show-ref --verify --quiet "refs/heads/$branch"; then
		echo "❌ La rama local '$branch' no existe."
		exists_local=false
	fi

    if [[ "$DEVELOP_BRANCH_PROTECTED" == "true" ]]; then
		if ! git ls-remote --exit-code --heads origin "$branch" &>/dev/null; then
			echo "❌ La rama remota '$branch' no existe en origin."
			exists_remote=false
		fi
	fi

	if ! $exists_local || ! $exists_remote; then
		return 1
	fi

	return 0
}

ensure_branch_does_not_exist() {
	local branch="$1"

	# Verificar rama local
	if git show-ref --verify --quiet "refs/heads/$branch"; then
		echo "❌ La rama local '$branch' ya existe."
		return 1
	fi

	# Verificar rama remota
	if git ls-remote --exit-code --heads origin "$branch" &>/dev/null; then
		echo "❌ La rama remota '$branch' ya existe en origin."
		return 1
	fi

	return 0
}

prepare_env_for_feature() {
	# 1. Verificar que el workspace está limpio
	if [[ -n $(git status --porcelain) ]]; then
		echo "❌ Hay cambios sin commitear. Aborta o guarda los cambios antes de continuar."
		return 1
	fi

	# 2. Cambiar a MAIN_BRANCH y actualizar
	git checkout "$MAIN_BRANCH" || return 1
	git pull origin "$MAIN_BRANCH" || return 1

	# 3. Obtener la versión actual
	if ! declare -f get_version >/dev/null; then
		echo "❌ La función get_version no está disponible."
		return 1
	fi
	CURRENT_VERSION=$(get_version)

	# 4. Verificar si hay un tag para esa versión
	if git rev-parse "v$CURRENT_VERSION" >/dev/null 2>&1; then
		echo "✅ Tag 'v$CURRENT_VERSION' ya existe."
	else
		# Crear el tag y subirlo
		git tag -a "v$CURRENT_VERSION" -m "Versión $CURRENT_VERSION"
		git push origin "v$CURRENT_VERSION"
		echo "🏷️ Tag 'v$CURRENT_VERSION' creado y subido."
	fi

	# 5. Cambiar a DEVELOP_BRANCH y actualizar
	git checkout "$DEVELOP_BRANCH" || return 1
	git pull origin "$DEVELOP_BRANCH" || return 1

	return 0
}

get_increment_type() {
  local from_branch="$MAIN_BRANCH"
  local to_branch="$DEVELOP_BRANCH"

  local commits=$(git log "$from_branch..$to_branch" --pretty=format:"%s")

  local has_breaking=false
  local has_feat=false
  local has_fix=false

  while IFS= read -r line; do
    [[ "$line" == *"BREAKING CHANGE"* || "$line" == *"!:"* ]] && has_breaking=true
    [[ "$line" == feat:* ]] && has_feat=true
    [[ "$line" == fix:* ]] && has_fix=true
  done <<< "$commits"

  if $has_breaking; then echo "major"
  elif $has_feat; then echo "minor"
  elif $has_fix; then echo "patch"
  else echo "patch" # por defecto
  fi
}

bump_version() {
  local base="$1"
  local type="$2"

  IFS='.' read -r major minor patch <<< "${base%%-*}" # ignora sufijos tipo -SNAPSHOT

  case "$type" in
    major) major=$((major + 1)); minor=0; patch=0 ;;
    minor) minor=$((minor + 1)); patch=0 ;;
    patch) patch=$((patch + 1)) ;;
  esac

  echo "$major.$minor.$patch"
}

next_rc_number() {
  local base_version="$1"
  local existing
  existing=$(git branch -r | grep "origin/release/${base_version}-rc." | sed -E 's|.*/rc\.||' | sort -n | tail -n1)
  if [[ -z "$existing" ]]; then
    echo 1
  else
    echo $((existing + 1))
  fi
}