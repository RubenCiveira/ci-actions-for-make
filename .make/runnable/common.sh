#!/bin/bash

get_platform() {
	local ARCH=$(uname -m)
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
	# echo "Artifact: [$(get_name)]"
	echo "Version: [$CURRENT_VERSION]"
	echo "Platform: [$CURRENT_PLATFORM]"
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
