#!/bin/bash

source .actions/lib/source-interface.sh

run_build() {
	build
}

run_lint() {
	lint
}

run_report() {
	report
}

run_sast() {
	echo "- Running sast"
	local FILES
	# To store $? the local and the capture must be two differnt calls
	FILES=$(sast)
	local result="$?"
	log_phase_file "sast" "$FILES"
	if [ $result -eq 0 ]; then
	    echo "- No se encontraron dependencias vulnerables."
	else
	    echo "- Se encontraron dependencias vulnerables."
	fi
	save_phase_files "sast" "$FILES"
}

run_test() {
	test
}


#
# Set project version, retrieve the list of modified files, and add all of them to the stash
#
# private
#
save_phase_files() {
  local PHASE="$1"
  local FILES="$2"
  echo "- On $PHASE"
  while IFS= read -r file; do
    if [[ ! "$file" =~ ^[-[] ]]; then
      echo "   > Need to save $file"
    fi
  done <<< "$FILES"
}

log_phase_file() {
  local PHASE="$1"
  local FILES="$2"
  while IFS= read -r file; do
    if [[ "$file" =~ ^[-[] ]]; then
      echo "$file"
    fi
  done <<< "$FILES"

}