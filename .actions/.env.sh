#!/bin/bash

MAIN_BRANCH=main
DEVELOP_BRANCH=develop
RELEASE_BRANCH=release

CHANGELOG_FILE=CHANGELOG.md

source .actions/lib/build-commons.sh
source .actions/lib/flow-commons.sh

# LINTER
#		Para indicar un linter especifico por ejemplo SONAR
# SAST
#		Para indicar un sast específico, por ejemplo FORTIFY

#
# NVD_API_KEY
#        Api key to owasp key
#
source .actions/lib/source-maven.sh

#
# GITLAB_MANAGEMENT_TOKEN
#        an access token to gitlab
# GITLAB_MANAGEMENT_URL
#        a project url from the api and the project id
#        https://gitlab.com/api/v4/projects/60703443/
#
source .actions/lib/project-manager-gitlab.sh

