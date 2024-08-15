#!/bin/bash

source .actions/lib/source-interface.sh

run_build() {
	build
}

run_lint() {
	echo "- Running lint"
	
	local FILES
	# To store $? the local and the capture must be two differnt calls
	FILES=$(lint)
	local result="$?"
	log_phase_file "sast" "$FILES"
	if [ $result -eq 0 ]; then
	    echo "- Lint ok."
	else
	    echo "- The lint verification was wrong."
	fi
	save_phase_files "lint" "$FILES"
	return $result
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
	    echo "- Sast ok."
	else
	    echo "- The sast verification was wrong."
	fi
	save_phase_files "sast" "$FILES"
	return $result
}

run_test() {
	echo "- Running test"
	local FILES
	# To store $? the local and the capture must be two differnt calls
	FILES=$(test)
	local result="$?"
	log_phase_file "test" "$FILES"
	if [ $result -eq 0 ]; then
	    echo "- Test ok."
	else
	    echo "- The test verification was wrong."
	fi
	save_phase_files "test" "$FILES"
	return $result
}

#
# Set project version, retrieve the list of modified files, and add all of them to the stash
#
# private
#
save_phase_files() {
  local PHASE="$1"
  local FILES="$2"
  if [[ "$FILES" != "" ]]; then
	echo "- Store files from $PHASE"
  else
  	echo "- No files to store in $PHASE"
  fi
  while IFS= read -r file; do
    if [[ ! "$file" =~ ^[-[] ]]; then
      echo "   > $file"
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