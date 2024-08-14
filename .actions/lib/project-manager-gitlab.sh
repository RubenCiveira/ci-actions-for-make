#!/bin/bash

#
# if is not the self repository
#
# GITLAB_MANAGEMENT_TOKEN
#        an access token to gitlab
# GITLAB_MANAGEMENT_URL
#        a project url from the api and the project id
#        https://gitlab.com/api/v4/projects/60703443/
#

get_issue() {
	local ISSUE_ID="$1"
	
	local INFO=$(lookup_repository_api)
	if [[ "$GITLAB_MANAGEMENT_TOKEN" != "" ]]; then
		local PRIVATE_TOKEN=$GITLAB_MANAGEMENT_TOKEN
	else
		local PRIVATE_TOKEN=$(echo "$INFO" | grep private-token | cut -d= -f2)
	fi
	if [[ "$GITLAB_MANAGEMENT_URL" != "" ]]; then
		local PROJECT_API_URL=GITLAB_MANAGEMENT_URL
	else
		local PROJECT_API_URL=$(echo "$INFO" | grep project-api-url | cut -d= -f2)
	fi
	
	local JSON=$(curl --silent --header "PRIVATE-TOKEN: $PRIVATE_TOKEN" "$PROJECT_API_URL/issues/$ISSUE_ID" )
	local TITLE=$(echo "$JSON" | grep -o '"title": *"[^"]*"' | sed 's/"title": *"//' | sed 's/"$//')
	local DESCRIPTION=$(echo "$JSON" | grep -o '"description": *"[^"]*"' | sed 's/"description": *"//' | sed 's/"$//')
	
	echo "description=$DESCRIPTION"
	echo "title=$TITLE"
}

# delete local branch and close related issue
# create a new branch for dev from an issue