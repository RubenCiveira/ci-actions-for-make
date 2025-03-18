#!/bin/bash

MAIN_BRANCH=main
DEVELOP_BRANCH=develop
RELEASE_BRANCH=release

CHANGELOG_FILE=CHANGELOG.md

DEBUG=false
LOG=true

# FINAL_NAME=mio
# BUILDING_REPORTS_DIR=reports

source .ci/actions/lib/build-commons.sh
source .ci/actions/lib/flow-commons.sh
source .ci/actions/lib/local-commons.sh

# LINTER
#		Para indicar un linter especifico por ejemplo SONAR
# SAST
#		Para indicar un sast específico, por ejemplo FORTIFY

source .ci/actions/lib/source/source-maven.sh

source .ci/actions/lib/project-manager/project-manager-gitlab.sh

# Se necesita un fichero .env para el entorno local de cada usuario
#!/bin/bash

# FINAL_NAME=mio
BUILDING_REPORTS_DIR=reports

if [[ -f ".ci/actions/.env" ]]; then
	source .ci/actions/.env
else
	source .ci/actions/template.env.sh
fi

if declare -f "$1" > /dev/null; then
    "$1"  # Ejecuta la función con el nombre del primer argumento
    exit
else
    echo "Error: '$1' no es un comando válido."
    echo "Comandos disponibles:"
    declare -F | awk '{print $3}'  # Lista las funciones disponibles
    exit 1
fi

if [[ "$1" == "prepare" ]]; then
	prepare
fi

if [[ "$1" == "build" ]]; then
	run_build
fi

if [[ "$1" == "lint" ]]; then
	run_lint
fi

if [[ "$1" == "format" ]]; then
	format_source
fi

if [[ "$1" == "report" ]]; then
	run_report
fi

if [[ "$1" == "sast" ]]; then
	run_sast
fi

if [[ "$1" == "test" ]]; then
	run_test
fi

if [[ "$1" == "verify" ]]; then
	run_verify
fi

if [[ "$1" == "branch" ]]; then
	new_branch
fi

if [[ "$1" == "pull" ]]; then
	pull_from_develop
fi
