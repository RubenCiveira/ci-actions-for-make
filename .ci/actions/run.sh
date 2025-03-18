#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ -f "$SCRIPT_DIR/../.env" ]]; then
	source $SCRIPT_DIR/../.env
fi
source $SCRIPT_DIR/../properties.env

# Common
source "$SCRIPT_DIR/lib/common.sh"

# Select by type
source "$SCRIPT_DIR/lib/impl/maven-lib.sh"
source "$SCRIPT_DIR/lib/impl/repos-gitlab.sh"

# Flow
source "$SCRIPT_DIR/lib/maven-info.sh"

# Tasks
source "$SCRIPT_DIR/lib/maven-tasks.sh"

source "$SCRIPT_DIR/lib/docker-tasks.sh"
source "$SCRIPT_DIR/lib/impl/git-flows.sh"
source "$SCRIPT_DIR/lib/impl/git-commons.sh"
source "$SCRIPT_DIR/lib/git-tasks.sh"

if declare -f "$1" > /dev/null; then
	func="$1"
	shift
    "$func" "$@"  # Ejecuta la función con el nombre del primer argumento
    exit
else
    echo "Error: '$1' no es un comando válido."
    echo "Comandos disponibles:"
    declare -F | awk '{print $3}'  # Lista las funciones disponibles
    exit 1
fi
