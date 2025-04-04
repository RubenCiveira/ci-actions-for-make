#!/bin/bash
generate_changelog() {
echo "ESTOY EN $CURRENT_VERSION"
  generate_changelog_from_last_tag $CURRENT_VERSION
}

rebuild_tagged_changelog() {
	local changelog_file="CHANGELOG.md"

	# Obtener tags alcanzables desde MAIN_BRANCH
	local tags
	tags=($(git tag --merged "$MAIN_BRANCH" --sort=creatordate))

	if [[ "${#tags[@]}" -lt 1 ]]; then
		echo "❌ No hay tags alcanzables desde '$MAIN_BRANCH'."
		return 1
	fi

	# Eliminar changelog anterior
	rm -f "$changelog_file"

	echo "🛠️ Reconstruyendo $changelog_file desde los tags de '$MAIN_BRANCH'..."
	printf '📎 Tags detectados:\n'; for tag in "${tags[@]}"; do echo "  - $tag"; done

	# 1. Desde el primer commit hasta el primer tag
	local first_tag="${tags[0]}"
	local first_commit
	first_commit=$(git rev-list --max-parents=0 HEAD)
	local version="${first_tag#v}"

	generate_changelog_from_commits "$first_commit" "$first_tag" "$version" "append"

	# 2. Entre tags intermedios
	for ((i = 0; i < ${#tags[@]} - 1; i++)); do
		local from_tag="${tags[i]}"
		local to_tag="${tags[i+1]}"
		local version="${to_tag#v}"

		generate_changelog_from_commits "$from_tag" "$to_tag" "$version" "append"
	done

	echo "✅ Changelog reconstruido correctamente hasta '$version'."
}

generate_changelog_from_last_tag() {
	local to_branch="$DEVELOP_BRANCH"
	local version="$1"
	local mode="${2:-append}"  # append o overwrite

	if [[ -z "$version" ]]; then
		echo "❌ Debes pasar la versión como argumento: generate_changelog_from_last_tag <version> [mode]"
		return 1
	fi

	local from_tag
	from_tag=$(git describe --tags --abbrev=0 "$to_branch" 2>/dev/null)

	if [[ -z "$from_tag" ]]; then
		echo "❌ No se pudo encontrar un tag en la rama $to_branch"
		return 1
	fi

	echo "📌 Generando changelog para los commits desde '$from_tag' hasta '$to_branch'..."

	generate_changelog_from_commits "$from_tag" "$to_branch" "$version" "$mode"
}

generate_changelog_from_commits() {
  block+=$(read_changelog_from_commits $1 $2 $3 $4)

  if [[ "$mode" == "overwrite" ]]; then
    echo "$block" > "$changelog_file"
    echo "📝 Se ha sobrescrito el changelog: $changelog_file"
  else
    if [[ -f "$changelog_file" ]]; then
      cp "$changelog_file" "$changelog_file.bak"
      {
        echo "$block"
        echo
        cat "$changelog_file"
      } > "$changelog_file.tmp" && mv "$changelog_file.tmp" "$changelog_file"
      echo "📝 Se ha actualizado el changelog: $changelog_file"
    else
      echo "$block" > "$changelog_file"
      echo "📝 Se ha creado el changelog: $changelog_file"
    fi
  fi
}

read_changelog_from_last_tag() {
	local to_branch="$DEVELOP_BRANCH"
	local version="$1"
	local mode="${2:-append}"  # append o overwrite

	if [[ -z "$version" ]]; then
		echo "❌ Debes pasar la versión como argumento: generate_changelog_from_last_tag <version> [mode]"
		return 1
	fi

	local from_tag
	from_tag=$(git describe --tags --abbrev=0 "$to_branch" 2>/dev/null)

	if [[ -z "$from_tag" ]]; then
		echo "❌ No se pudo encontrar un tag en la rama $to_branch"
		return 1
	fi

	echo "📌 Generando changelog para los commits desde '$from_tag' hasta '$to_branch'..."

	read_changelog_from_commits "$from_tag" "$to_branch" "$version" "$mode"
}

read_changelog_from_develop() {
  local current_branch
  current_branch=$(git rev-parse --abbrev-ref HEAD)
  local from_branch="$DEVELOP_BRANCH"
  local to_branch="$current_branch"
  local version="$1"
  local mode="${2:-append}"  # append o overwrite

  if [[ -z "$version" ]]; then
    echo "❌ Debes pasar la versión como argumento: read_changelog_from_develop <version> [mode]"
    return 1
  fi

  if [[ "$from_branch" == "$to_branch" ]]; then
    echo "⚠️  La rama actual es la misma que DEVELOP_BRANCH ('$DEVELOP_BRANCH'), no se puede generar changelog."
    return 1
  fi

  echo "📌 Generando changelog para los commits desde '$from_branch' hasta '$to_branch'..."

  read_changelog_from_commits "$from_branch" "$to_branch" "$version" "$mode"
}

read_changelog_from_commits() {
  local from_branch="$1"
  local to_branch="$2"
  local version="$3"
  local mode="${4:-append}"
  local changelog_file="CHANGELOG.md"

  if [[ -z "$from_branch" || -z "$to_branch" || -z "$version" ]]; then
    echo "❌ Uso: generate_changelog_from_commits <from_branch> <to_branch> <version> [append|overwrite]"
    return 1
  fi  

  local include_body=${CHANGELOG_INCLUDE_BODY:-false}
  local log_format="%h%n%s%n%b%n==END=="
  local commits
  commits=$(git log "$from_branch..$to_branch" --no-merges --pretty=format:"$log_format")

  if [[ -z "$commits" ]]; then
    echo "⚠️  No hay commits nuevos entre $from_branch y $to_branch."
    return 0
  fi

  local added="" fixed="" changed="" removed="" breaking="" other=""
  local current_hash="" current_title="" current_body=""

  while IFS= read -r line; do
    if [[ "$line" == "==END==" ]]; then
      local message="$current_title"
      local body_formatted=""
      local breaking_line=""

      if [[ "$include_body" == "true" && -n "$current_body" ]]; then
        trimmed_body="$(echo "$current_body" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
        if [[ -n "${trimmed_body//[$'\n\r']}" ]]; then
          body_formatted=$'\n\n'
          while IFS= read -r body_line; do
            body_formatted+="> $body_line"$'\n'
          done <<< "$trimmed_body"
        fi
      fi

      # Detectar BREAKING CHANGE:
      breaking_line=$(echo "$current_body" | grep -E "^BREAKING CHANGE:")
      if [[ -n "$breaking_line" ]]; then
        local msg="${breaking_line#BREAKING CHANGE:}"
        msg="$(echo "$msg" | sed -E 's/^[[:space:]]*//;s/[[:space:]]*$//')"
        msg="$(echo "$msg" | awk '{print toupper(substr($0,1,1)) substr($0,2)}')"
        breaking+="- $msg \`($current_hash)\`"$'\n'
      fi

      trimmed_message="$(echo "${message#*:}" | sed -E 's/^[[:space:]]*//;s/[[:space:]]*$//')"
      uc_message="$(echo "$trimmed_message" | awk '{print toupper(substr($0,1,1)) substr($0,2)}')"

      if [[ "$message" =~ ^feat(\([a-zA-Z0-9_-]+\))?: ]]; then
        added+="- $uc_message \`($current_hash)\`${body_formatted}"$'\n'
      elif [[ "$message" =~ ^fix(\([a-zA-Z0-9_-]+\))?: ]]; then
        fixed+="- $uc_message \`($current_hash)\`${body_formatted}"$'\n'
      elif [[ "$message" =~ ^(chore|refactor)(\([a-zA-Z0-9_-]+\))?: ]]; then
        changed+="- $uc_message \`($current_hash)\`${body_formatted}"$'\n'
      elif [[ "$message" =~ ^(remove|removed)(\([a-zA-Z0-9_-]+\))?: ]]; then
        removed+="- $uc_message \`($current_hash)\`${body_formatted}"$'\n'
      else
        other+="- $uc_message \`($current_hash)\`${body_formatted}"$'\n'
      fi

      current_hash=""
      current_title=""
      current_body=""
    elif [[ -z "$current_hash" ]]; then
      current_hash="$line"
    elif [[ -z "$current_title" ]]; then
      current_title="$line"
    else
      current_body+="$line"$'\n'
    fi
  done <<< "$commits"

  local date_str
  date_str=$(date +%Y-%m-%d)
  local block="## [$version] - $date_str"$'\n'

  if [[ -n "$breaking" ]]; then
    block+=$'\n'"### 💥 Breaking Changes"$'\n'"$breaking"
  fi
  if [[ -n "$added" ]]; then
    block+=$'\n'"### ✨ Added"$'\n'"$added"
  fi
  if [[ -n "$fixed" ]]; then
    block+=$'\n'"### 🐛 Fixed"$'\n'"$fixed"
  fi
  if [[ -n "$changed" ]]; then
    block+=$'\n'"### ♻️ Changed"$'\n'"$changed"
  fi
  if [[ -n "$removed" ]]; then
    block+=$'\n'"### 🔥 Removed"$'\n'"$removed"
  fi
  if [[ -n "$other" ]]; then
    block+=$'\n'"### 🧩 Other"$'\n'"$other"
  fi

  block+=$'\n'
  echo $block
}