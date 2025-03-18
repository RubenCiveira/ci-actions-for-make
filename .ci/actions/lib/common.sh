#!/bin/bash

#
# Set the version on the project management file (pom.xml, gradle.build, package.json...)
# Print a line for each file
# A line that starts with - or [ will be precessed as log
#
set_version() {
	:
}

#
# Print the version of the project management file (pom.xml, gradle.build, package.json...)
#
get_version() {
	:
}

get_platform() {
	ARCH=$(uname -m)
	if [[ "$ARCH" == "x86_64" ]]; then
		echo "amd64"
	elif [[ "$ARCH" == "amd64" ]]; then
		echo "amd64"
	elif [[ "$ARCH" == "aarch64" ]]; then
		echo "arm64"
	elif [[ "$ARCH" == "arm64" ]]; then
		echo "arm64"
	else
		echo "Arquitectura desconocida"
		exit 1
	fi
}

get_info() {
	echo "Artifact: [$(get_name)]"
	echo "Version: [$(get_version)]"
	echo "Platform: [$(get_platform)]"
}

has_debug() {
	if [[ "$DEBUG" == "true" ]]; then
		return 0
	else
		return 1
	fi
}

has_log() {
	if [[ "$LOG" == "true" ]]; then
		return 0
	else
		return 1
	fi
}

log() {
	if has_log; then
		echo "$1"
	fi
}
