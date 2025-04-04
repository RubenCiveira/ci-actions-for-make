#!/bin/bash

case "$FORGE_KIND" in
  gitlab)
    source "$SCRIPT_DIR/forge/gitlab-forge.sh"
    ;;
  *)
    echo "Tipo de proyecto no soportado: $KIND"
    exit 1
    ;;
esac

