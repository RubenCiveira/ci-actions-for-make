#!/bin/bash
MVN=./mvnw

# NVD_API_KEY
#        an access token to gitlab

# Override set_version
set_version() {
	local snap_version=$1
	if [[ "" == "$1" ]]; then
		echo "No se ha indicado version"
		exit 1
	fi
	$MVN versions:set -DnewVersion=${snap_version} -DgenerateBackupPoms=false -q -DforceStdout rem >/dev/null 2>&1
	echo pom.xml 
}

# Override get_version
get_version() {
	$MVN help:evaluate -Dexpression=project.version -q -DforceStdout 2>/dev/null | grep -E '^[0-9]+\.[0-9]+(\.[0-9]+)?(-SNAPSHOT)?$'
}