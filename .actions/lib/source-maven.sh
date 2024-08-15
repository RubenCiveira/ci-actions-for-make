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
	$MVN clean pmd:pmd pmd:cpd pmd:check pmd:cpd-check -Dformat=csv -f $TEMP -Ppmd-profile -q -DforceStdout >/dev/null 2>&1
	# to retrieve $? the local definition must be before maven execution
	result=$?
	rm $TEMP
	echo "./target/cpd.csv"
	echo "./target/pmd.csv"
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

verify() {
	local TEMP="jacoco-pom.xml"
	local PARAMS=""
	echo "- Running maven tests and jacoco coverage"
	append_profile "pom.xml" ".actions/conf/maven/jacoco-profile.xml" $TEMP
	if [[ "$REQUIRED_COVERAGE" != "" ]]; then
		echo "- Coverage of $REQUIRED_COVERAGE"
		local RESULT_REQUIRED_COVERAGE=$(echo "scale=2; $REQUIRED_COVERAGE / 100" | bc)
		PARAMS="$PARAMS -Djacoco.min-coverage.instructions=$REQUIRED_COVERAGE  -Djacoco.min-coverage.branches=$REQUIRED_COVERAGE"
	else
		echo "- No explicit coverage, using 00 (use REQUIRED_COVERAGE to define)"
		PARAMS="$PARAMS -Djacoco.min-coverage.instructions=0.00  -Djacoco.min-coverage.branches=0.00"
	fi
	$MVN clean verify -f $TEMP -Pjacoco-profile $PARAMS -q -DforceStdout >/dev/null 2>&1
	# to retrieve $? the local definition must be before maven execution
	result=$?
	rm $TEMP
	echo "./target/site/jacoco/jacoco.csv"
	return $result
}

test() {
	local TEMP="pit-pom.xml"
	local PARAMS=""
	echo "- Running maven mutation tests with pit"
	append_profile "pom.xml" ".actions/conf/maven/pit-profile.xml" $TEMP
	if [[ "$REQUIRED_COVERAGE" != "" ]]; then
		echo "- Coverage of $REQUIRED_COVERAGE"
		PARAMS="$PARAMS -DmutationThreshold=$REQUIRED_COVERAGE"
	else
		echo "- No explicit coverage, using 00 (use REQUIRED_COVERAGE to define)"
		PARAMS="$PARAMS -DmutationThreshold=0"
	fi
	
	$MVN clean verify -f $TEMP -Ppit-profile $PARAMS -q -DforceStdout >/dev/null 2>&1
	# to retrieve $? the local definition must be before maven execution
	result=$?
	rm $TEMP
	echo "./target/pit-reports/mutations.csv"
	return $result
}

build() {
	local PARAMS=""
	$MVN clean verify $PARAMS -q -DskipTests=true -q -DforceStdout >/dev/null 2>&1
	# to retrieve $? the local definition must be before maven execution
	result=$?
	
	local artifactName=$(artifact_name_without_extension)
	local extension=$(artifact_packaging_extension)
	
	if [[ "$FINAL_NAME" != "" ]]; then
		mv "./target/${artifactName}.${extension}" "./target/${FINAL_NAME}.${extension}"
		artifactName="$FINAL_NAME"
	fi
	echo "./target/${artifactName}.${extension}"
	return $result
}

get_artifact_name() {
	local artifactName=$(artifact_name_without_extension)
	local packaging=$(artifact_packaging_extension)
	echo "./target/${artifactName}.${packaging}"
}

report() {
	return 0
}

artifact_packaging_extension() {
	local packaging=$(mvn help:evaluate -Dexpression=project.packaging -q -DforceStdout)
	echo $packaging
}

artifact_name_without_extension() {
	local artifactName=""
	local finalName=$(mvn help:evaluate -Dexpression=project.build.finalName -q -DforceStdout)
	if [ -n "$finalName" ]; then
		artifactName="$finalName"
	else
		local artifactId=$(mvn help:evaluate -Dexpression=project.artifactId -q -DforceStdout)
		local version=$(mvn help:evaluate -Dexpression=project.version -q -DforceStdout)
		artifactName="$artifactId-$version"
	fi
	echo "$artifactName"
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
