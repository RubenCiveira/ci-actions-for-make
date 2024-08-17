#!/bin/bash

MAIN_BRANCH=main
DEVELOP_BRANCH=develop
RELEASE_BRANCH=release

CHANGELOG_FILE=CHANGELOG.md

DEBUG=false
LOG=true

# FINAL_NAME=mio
# BUILDING_REPORTS_DIR=reports

source .actions/lib/build-commons.sh
source .actions/lib/flow-commons.sh

# LINTER
#		Para indicar un linter especifico por ejemplo SONAR
# SAST
#		Para indicar un sast específico, por ejemplo FORTIFY


source .actions/lib/source-maven.sh

source .actions/lib/project-manager-gitlab.sh

# Se necesita un fichero .env para el entorno local de cada usuario
#!/bin/bash

# FINAL_NAME=mio
BUILDING_REPORTS_DIR=reports

if [[ -f ".actions/.env" ]]; then
	source .actions/.env
else
	source .actions/template.env.sh
fi