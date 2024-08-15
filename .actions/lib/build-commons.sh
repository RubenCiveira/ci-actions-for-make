#!/bin/bash

source .actions/lib/source-interface.sh

run_build() {
	echo "- Building"
	local FILES
	# To store $? the local and the capture must be two differnt calls
	FILES=$(build)
	local result="$?"
	log_phase_file "build" "$FILES"
	if [ $result -eq 0 ]; then
	    echo "- Build ok."
	else
	    echo "- The build verification was wrong."
	fi
	save_phase_files "build" "$FILES"
	return $result
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
	echo "- Running report"
	local FILES
	# To store $? the local and the capture must be two differnt calls
	FILES=$(report "$1")
	local result="$?"
	log_phase_file "report" "$FILES"
	if [ $result -eq 0 ]; then
	    echo "- Report ok."
	else
	    echo "- There was fails generating reports."
	fi
	save_phase_files "report" "$FILES"
	return $result
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

run_verify() {
	echo "- Running verify"
	local FILES
	# To store $? the local and the capture must be two differnt calls
	FILES=$(verify)
	local result="$?"
	log_phase_file "verify" "$FILES"
	if [ $result -eq 0 ]; then
	    echo "- Verification ok."
	else
	    echo "- The verification fail."
	fi
	save_phase_files "verification" "$FILES"
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
  if [[ "$BUILDING_REPORTS_DIR" != "" ]]; then
	  if [[ "$FILES" != "" ]]; then
		echo "- Store files from $PHASE"
	  else
	  	echo "- No files to store in $PHASE"
	  fi
	  while IFS= read -r file; do
	    if [[ ! "$file" =~ ^[-[] ]]; then
	      if [ -f "$file" ]; then
	        mv "$file" "$BUILDING_REPORTS_DIR"
	      else
	      	echo "    > El fichero $file no existe."
	      fi
	    fi
	  done <<< "$FILES"
  else
  	echo "- There is no directory to store build output files, use BUILDING_REPORTS_DIR to it"
  fi
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

if [ -n "$BUILDING_REPORTS_DIR" ]; then
    if [ ! -d "$BUILDING_REPORTS_DIR" ]; then
        # Crear el directorio si no existe
    	mkdir -p "$BUILDING_REPORTS_DIR"
    fi
fi