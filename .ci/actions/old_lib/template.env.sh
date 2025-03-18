#!/bin/bash

echo "DEBUG to enable detailed messages form command"
echo "LOG to show log"


echo "NVD_API_KEY for owasp dependency check"

if [[ "$MANAGEMENT_REPOSITORY" == "gitlab" ]]; then
	echo "GITLAB_MANAGEMENT_TOKEN the access token to use a gitlab issue management repository"
	echo "GITLAB_MANAGEMENT_URL (with the api projecyt id https://gitlab.com/api/v4/projects/60703443/) to use a gitlab issue mangement repository"
fi


echo "DOCKER_HARBOUR_URL to the url token to use a docker harbour" 
echo "DOCKER_HARBOUR_USER to the access token to use a docker harbour"
echo "DOCKER_HARBOUR_PASS to the access token to use a docker harbour"

exit 1