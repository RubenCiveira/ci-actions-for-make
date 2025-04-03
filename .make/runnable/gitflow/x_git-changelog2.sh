#!/bin/bash
generate_changelog() {
  generate_changelog_from_commits $CURRENT_VERSION
}
generate_changelog_from_commits() {
	local changelog_file="CHANGELOG.md"
	local from_branch="$MAIN_BRANCH"
	local to_branch="$DEVELOP_BRANCH"
	local version="$1"  # versión a incluir en el encabezado

	if [[ -z "$version" ]]; then
		echo "❌ Debes pasar la versión como argumento: generate_changelog_from_commits 1.3.0"
		return 1
	fi

	local commits
	commits=$(git log "$from_branch..$to_branch" --pretty=format:"%h %s" --no-merges)

	if [[ -z "$commits" ]]; then
		echo "⚠️  No hay commits nuevos entre $from_branch y $to_branch."
		return 0
	fi

	local added="" fixed="" changed="" removed="" other=""

	while IFS= read -r commit; do
		local hash="${commit%% *}"
		local message="${commit#* }"

		if [[ $message =~ ^feat(\([a-zA-Z0-9_-]+\))?: ]]; then
			added+="- ${message#*:} \`($hash)\`"$'\n'
		elif [[ $message =~ ^fix(\([a-zA-Z0-9_-]+\))?: ]]; then
			fixed+="- ${message#*:} \`($hash)\`"$'\n'
		elif [[ $message =~ ^(chore|refactor)(\([a-zA-Z0-9_-]+\))?: ]]; then
			changed+="- ${message#*:} \`($hash)\`"$'\n'
		elif [[ $message =~ ^(remove|removed)(\([a-zA-Z0-9_-]+\))?: ]]; then
			removed+="- ${message#*:} \`($hash)\`"$'\n'
		else
			other+="- $message \`($hash)\`"$'\n'
		fi
	done <<< "$commits"

	local date_str
	date_str=$(date +%Y-%m-%d)
	local block="## [$version] - $date_str"$'\n'

	if [[ -n "$added" ]]; then
		block+=$'\n'"### Added"$'\n'"$added"
	fi
	if [[ -n "$fixed" ]]; then
		block+=$'\n'"### Fixed"$'\n'"$fixed"
	fi
	if [[ -n "$changed" ]]; then
		block+=$'\n'"### Changed"$'\n'"$changed"
	fi
	if [[ -n "$removed" ]]; then
		block+=$'\n'"### Removed"$'\n'"$removed"
	fi
	if [[ -n "$other" ]]; then
		block+=$'\n'"### Other"$'\n'"$other"
	fi

	block+=$'\n'

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
}
