#!/bin/bash

start_release_candidate() {
  prepare_env_for_feature || return 1

  local increment_type
  increment_type=$(get_increment_type)
  echo "🔍 Incremento detectado: $increment_type"

  local base_version
  base_version=$(git show "$MAIN_BRANCH:pom.xml" | xmllint --xpath "/*[local-name()='project']/*[local-name()='version']/text()" - 2>/dev/null)
  echo "📦 Versión base: $base_version"

  local new_version
  new_version=$(bump_version "$base_version" "$increment_type")
  echo "🎯 Nueva versión candidata: $new_version"

  local rc_number
  rc_number=$(next_rc_number "$new_version")

  local release_branch="release/${new_version}-rc.${rc_number}"
  git checkout "$DEVELOP_BRANCH" && git pull origin "$DEVELOP_BRANCH" || return 1
  git checkout -b "$release_branch" || return 1

  echo "🚀 Rama creada: $release_branch"

  set_version "${new_version}-rc.${rc_number}" || return 1
  generate_changelog_from_last_tag "${new_version}-rc.${rc_number}" || return 1

  git add .
  git commit -m "chore(release): ${new_version}-rc.${rc_number}" || return 1
  echo "ℹ️  Revisa los cambios y ejecuta:"
  echo "    git push --set-upstream origin $release_branch"
}
