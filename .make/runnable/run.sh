#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ -f "$SCRIPT_DIR/../.env" ]]; then
	source $SCRIPT_DIR/../.env
fi
source $SCRIPT_DIR/../properties.env

source $SCRIPT_DIR/artifact.sh
source $SCRIPT_DIR/common.sh
source $SCRIPT_DIR/gitflow.sh

CURRENT_PLATFORM=$(get_platform)
CURRENT_VERSION=$(get_version)

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
