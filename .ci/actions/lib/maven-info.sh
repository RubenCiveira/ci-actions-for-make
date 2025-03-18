#!/bin/bash

MVN=./mvnw

source "$SCRIPT_DIR/lib/impl/maven-lib.sh"

# Override set_version
set_version() {
	mvn_set_version $1
}

# Override get_version
get_version() {
	mvn_get_version
}
