#!/bin/bash

case "$TICKTING_KIND" in
  gitlab)
    source "$SCRIPT_DIR/ticketing/gitlab-ticketing.sh"
    ;;
  *)
    echo "Tipo de proyecto no soportado: $KIND"
    exit 1
    ;;
esac

