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
	local result=0
	local TEMP="pmd-pom.xml"
	echo "- Running local owsp dependency check"
	append_profile "pom.xml" ".actions/conf/maven/pmd-profile.xml" $TEMP
	$MVN clean pmd:pmd pmd:cpd pmd:check pmd:cpd-check -f $TEMP -Ppmd-profile -q -DforceStdout >/dev/null 2>&1
	# to retrieve $? the local definition must be before maven execution
	result=$?
	rm $TEMP
	echo "./target/cpd.xml"
	echo "./target/pmd.xml"
	return $result
}

sast() {
	local PARAMS=""
	local result=0
	echo "- Running local owsp dependency check"
	if [[ "$NVD_API_KEY" != "" ]]; then
		echo "- Using an nvd api key"
		PARAMS="$PARAMS -DnvdApiKey=$NVD_API_KEY"
	else
		echo "- Without nvd api key. (get one and assging to NVD_API_KEY env variable)"
	fi
	$MVN clean org.owasp:dependency-check-maven:check -Dformat=CSV -DfailBuildOnCVSS=7 -Denforce.failBuild=true $PARAMS -q -DforceStdout >/dev/null 2>&1
	# to retrieve $? the local definition must be before maven execution
	result=$?
	echo "./target/dependency-check-report.csv"
	return $result
}

test() {
	local TEMP="jacoco-pom.xml"
	local PARAMS=""
	echo "- Running maven tests and jacoco coverage"
	append_profile "pom.xml" ".actions/conf/maven/jacoco-profile.xml" $TEMP
	if [[ "$REQUIRED_COVERAGE_INTRUCTIONS" != "" ]]; then
		echo "- Coverage of instructions at least of 0.$REQUIRED_COVERAGE_INTRUCTIONS"
		PARAMS="$PARAMS -Djacoco.min-coverage.instructions=$REQUIRED_COVERAGE_INTRUCTIONS"
	else
		echo "- No explicit instructions coverage, using 00 (use REQUIRED_COVERAGE_INTRUCTIONS to define)"
		PARAMS="$PARAMS -Djacoco.min-coverage.instructions=00"
	fi
	if [[ "$REQUIRED_COVERAGE_BRANCHES" != "" ]]; then
		echo "- Coverage of branches at least of 0.$REQUIRED_COVERAGE_BRANCHES"
		PARAMS="$PARAMS  -Djacoco.min-coverage.branches=$REQUIRED_COVERAGE_BRANCHES"
	else
		echo "- No explicit branches coverage, using 00 (use REQUIRED_COVERAGE_BRANCHES to define)"
		PARAMS="$PARAMS  -Djacoco.min-coverage.branches=00"
	fi
	echo "mvn clean verify -f $TEMP -Pjacoco-profile $PARAMS"
	$MVN clean verify -f $TEMP -Pjacoco-profile $PARAMS -q -DforceStdout >/dev/null 2>&1
	# to retrieve $? the local definition must be before maven execution
	result=$?
	rm $TEMP
	echo "./target/site/jacoco.csv"
	return $result
}

build() {
	return 0
}

report() {
	return 0
}

append_profile() {
	# Rutas a los archivos
	local POM_FILE="$1"
	local PROFILE_FILE="$2"
	local OUTPUT_FILE="$3"
	# pom_with_profile.xml"
	# Inicia la variable de salida
	local OUTPUT_CONTENT=""
	
	# Verifica si el pom.xml ya tiene una sección <profiles>
	local PROFILE_CONTENT=$(cat "$PROFILE_FILE")
	if grep -q "<profiles>" "$POM_FILE"; then
		local PRE=$(grep -B100000 '</profiles>' "$POM_FILE" | sed '$d')
		local POST=$(grep '</profiles>' "$POM_FILE" )
		echo $PRE > "$OUTPUT_FILE"
		echo "$PROFILE_CONTENT" >> "$OUTPUT_FILE"
		echo $POST >> "$OUTPUT_FILE"
	else
		local PRE=$(grep -B100000 '</project>' "$POM_FILE" | sed '$d')
		local POST=$(grep '</project>' "$POM_FILE" )
		echo $PRE > "$OUTPUT_FILE"
		echo "<profiles>$PROFILE_CONTENT</profiles>" >> "$OUTPUT_FILE"
		echo $POST >> "$OUTPUT_FILE"
	fi
	
	# Guarda el resultado en un nuevo archivo
	# echo "$OUTPUT_CONTENT" > "$OUTPUT_FILE"
}
