#!/bin/bash

start_release_candidate() {
  prepare_env_for_feature || return 1

  # 1. Obtener tipo de incremento desde commits entre main y develop
  local increment_type
  increment_type=$(get_increment_type)
  echo "🔍 Incremento detectado: $increment_type"

  # 2. Obtener versión base desde main
  local base_version
  base_version=$(git show "$MAIN_BRANCH:pom.xml" | xmllint --xpath "/*[local-name()='project']/*[local-name()='version']/text()" - 2>/dev/null)
  echo "📦 Versión base: $base_version"

  # 3. Generar nueva versión
  local new_version
  new_version=$(bump_version "$base_version" "$increment_type")
  echo "🎯 Nueva versión candidata: $new_version"

  # 4. Determinar número de rc siguiente
  local rc_number
  rc_number=$(next_rc_number "$new_version")

  # 5. Crear rama
  local release_branch="release/${new_version}-rc.${rc_number}"
  git checkout "$DEVELOP_BRANCH"
  git pull origin "$DEVELOP_BRANCH"
  git checkout -b "$release_branch"

  echo "🚀 Se ha creado la rama: $release_branch"
  
  set_version ${new_version}-rc.${rc_number}
  generate_changelog_from_last_tag ${new_version}-rc.${rc_number}
  git add .
  git commit -m "Update version"
}

