#!/bin/bash
MVN=./mvnw

# NVD_API_KEY
#        an access token to gitlab
set_project_version() {
	local snap_version=$1
	$MVN versions:set -DnewVersion=$snap_version -DgenerateBackupPoms=false -q -DforceStdout >/dev/null 2>&1 
	echo "pom.xml"
}

lint() {
	return 0
}

sast() {
	local PARAMS=""
	local result=0
	if [[ "$NVD_API_KEY" != "" ]]; then
		PARAMS="$PARAMS -DnvdApiKey=$NVD_API_KEY"
	fi
	echo "- Running local owsp dependency check"
	$MVN clean org.owasp:dependency-check-maven:check -Dformat=CSV -DfailBuildOnCVSS=7 -Denforce.failBuild=true $PARAMS -q -DforceStdout >/dev/null 2>&1
	# to retrieve $? the local definition must be before maven execution
	result=$?
	echo ./target/dependency-check-report.csv
	return $result
}

test() {
	$MVN
}

build() {
	return 0
}

report() {
	return 0
}

