#!/bin/bash

run_create_pr_gitlab() {
	local TITLE="$1"
	local BODY="$2"
	local BASE="$3"
	local HEAD="$4"
	local DELETE_SOURCE="$5"
	local SQUASH="$6"

	local INFO=$(lookup_repository_api)
	
	local PRIVATE_TOKEN=$(read_from_properties "private-token" "$INFO")
	local PROJECT_API_URL=$(read_from_properties "project-api-url" "$INFO")
	
	local response=$(curl --header "PRIVATE-TOKEN: $PRIVATE_TOKEN" -s -X POST \
	    -H "Content-Type: application/json" \
	    -d "{\"title\":\"$TITLE\",\"description\":\"$BODY\", \"squash\": $SQUASH,\"remove_source_branch\":$DELETE_SOURCE,\"source_branch\":\"$HEAD\",\"target_branch\":\"$BASE\"}" \
	    "$PROJECT_API_URL/merge_requests")
	local MR_ID=$(echo $response | grep -o '"iid":[0-9]*' | head -n 1 | grep -o '[0-9]*')
	echo $MR_ID
}

run_lookup_pr_gitlab() {
	local BASE="$1"
	local HEAD="$2"

	local INFO=$(lookup_repository_api)
	
	local PRIVATE_TOKEN=$(read_from_properties "private-token" "$INFO")
	local PROJECT_API_URL=$(read_from_properties "project-api-url" "$INFO")
	
	local search_mr=$(curl -s --header "PRIVATE-TOKEN: $PRIVATE_TOKEN" "$PROJECT_API_URL/merge_requests?source_branch=$HEAD&target_branch=$BASE&state=opened")
	local MR_ID=$(echo $search_mr | grep -o '"iid":[0-9]*' | head -n 1 | grep -o '[0-9]*')
	if [[ -z "$MR_ID" || "$MR_ID" == "null" ]]; then
		echo ""
	fi
	local HAS_CONFLICT=$(echo "$search_mr" | grep -o '"has_conflicts": *[^,]*' | grep -o '[^:]*$' | xargs)
	local MERGE_STATUS=$(echo "$search_mr" | grep -o '"detailed_merge_status": *"[^"]*"' | grep -o '[^:]*$' | sed 's/"//g' | xargs)
	local SQUASH=$(echo "$search_mr" | grep -o '"squash": *[^,]*' | grep -o '[^:]*$' | xargs)
	local DELETE=$(echo "$search_mr" | grep -o '"should_remove_source_branch": *[^,]*' | grep -o '[^:]*$' | xargs)
	local TITLE=$(echo "$search_mr" | grep -o '"title": *"[^"]*"' | sed 's/"title": *"//' | sed 's/"$//')
	local DESCRIPTION=$(echo "$search_mr" | grep -o '"description": *"[^"]*"' | sed 's/"description": *"//' | sed 's/"$//')
	local WEB_URL=$(echo "$search_mr" | grep -o '"web_url": *"[^"]*"' | sed 's/"web_url": *"//' | sed 's/"$//')

	echo "id=$MR_ID"
	echo "has-conflict=$HAS_CONFLICT"
	echo "merge-status=$MERGE_STATUS"
	echo "squash=$SQUASH"
	echo "delete=$DELETE"
	echo "title=$TITLE"
	echo "description=$DESCRIPTION"
	echo "web-url=$WEB_URL"
}

run_merge_pr_gitlab() {
	local BASE="$1"
	local HEAD="$2"
	
	local INFO=$(lookup_repository_api)
	
	local PRIVATE_TOKEN=$(read_from_properties "private-token" "$INFO")
	local PROJECT_API_URL=$(read_from_properties "project-api-url" "$INFO")

	local PR=$(run_lookup_pr_gitlab "$BASE" "$HEAD")
	if [[ "$PR" == "" ]]; then
		echo "No se encontró ninguna MR pendiente de aprobación entre $HEAD y $BASE."
	    exit 0
	else
		local MR=$(read_from_properties "id" "$PR")
		local HAS_CONFLICT=$(read_from_properties "has-conflict" "$PR")
		local MERGE_STATUS=$(read_from_properties "merge-status" "$PR")
		local SQUASH=$(read_from_properties "squash" "$PR")
		local DELETE=$(read_from_properties "delete" "$PR")
		local TITLE=$(read_from_properties "title" "$PR")
		local DESCRIPTION=$(read_from_properties "description" "$PR")
		local WEB_URL=$(read_from_properties "web-url" "$PR")

		local REQUEST_BODY=""
		if [[ "$SQUASH" == "true" ]]; then
			REQUEST_BODY="$REQUEST_BODY,\"squash\":true,\"merge_commit_message\": \"$TITLE\n\n$DESCRIPTION\""
		fi
		if [[ "$DELETE" == "true" ]]; then
			REQUEST_BODY="$REQUEST_BODY,\"should_remove_source_branch\":true"
		fi
		REQUEST_BODY="{ ${REQUEST_BODY#,} }"
	
		if [[ "$HAS_CONFLICT" == "true" ]]; then
			echo "The MR #$MR_ID has conflicts and cant be automaticly merged"
			exit 0
		fi
		
		if [[ "$MERGE_STATUS" == "unchecked" ]]; then
			echo "The MR #MR_ID need to be checked at $WEB_URL"
		fi
	
		if [[ "$MERGE_STATUS" == "checking" || "$MERGE_STATUS" == "cannot_be_merged_recheck" ]]; then
			echo "The MR #$MR_ID is beeng checking by the system"
			sleep 10
			run_merge_pr_gitlab "$BASE" "$HEAD" "$PROJECT_API_URL" "$REPOSITORY_KIND"
		fi
		
		if [[ "$MERGE_STATUS" != "mergeable" ]]; then
			echo "The MR #$MR_ID cant be automaticly merged for $MERGE_STATUS"
			exit 0
		fi
		
		APPROVAL_RESPONSE=$(curl -s --request PUT --header "Content-Type: application/json" --header "PRIVATE-TOKEN: $PRIVATE_TOKEN" "$PROJECT_API_URL/merge_requests/$MR/merge" --data "$REQUEST_BODY")
		
		# Verificar si la aprobación fue exitosa
		if echo "$APPROVAL_RESPONSE" | grep -q '"state":"merged"'; then
		    echo "$MR"
		else
		    echo "Error trying to merge MR #$MR:"
		    echo "$REQUEST_BODY => "
		    echo "  => $APPROVAL_RESPONSE"
		    exit 1
		fi
	fi
		
}