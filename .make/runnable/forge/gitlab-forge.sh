#!/bin/bash

create_pull_request() {
  if [[ -z "$GITLAB_TOKEN" || -z "$GITLAB_PROJECT_ID" ]]; then
    echo "❌ GITLAB_TOKEN o GITLAB_PROJECT_ID no están definidos."
    return 1
  fi

  local source_branch=$(git rev-parse --abbrev-ref HEAD)
  local target_branch="${1:-$DEVELOP_BRANCH}"
  local title="${2:-"Merge $source_branch into $target_branch"}"
  local description="${3:-"Automated merge request from CLI"}"

  echo "🔗 Creando Merge Request en GitLab..."

  local api_url="https://gitlab.com/api/v4/projects/${GITLAB_PROJECT_ID}/merge_requests"
  local payload=$(jq -n \
    --arg source "$source_branch" \
    --arg target "$target_branch" \
    --arg title "$title" \
    --arg description "$description" \
    '{source_branch: $source, target_branch: $target, title: $title, description: $description}')

  response=$(curl -s --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
    --header "Content-Type: application/json" \
    --data "$payload" \
    "$api_url")

  if echo "$response" | grep -q '"web_url"'; then
    echo "✅ Merge Request creada con éxito."
    echo "$response" | jq -r '.web_url'
  else
    echo "❌ Error al crear la Merge Request."
    echo "$response" | jq
    return 1
  fi
}