#!/bin/bash
MVN=./mvnw

# NVD_API_KEY
#        an access token to gitlab


set_project_version() {
	local snap_version=$1
	$MVN versions:set -DnewVersion=$snap_version -DgenerateBackupPoms=false -q -DforceStdout >/dev/null 2>&1 
	echo "pom.xml"
}

get_project_version() {
	local snap_version=$1
	$MVN help:evaluate -Dexpression=project.version -q -DforceStdout
}


lint() {
	local result=0
	local TEMP="pmd-pom.xml"
	echo "- Running local owsp dependency check"
	append_profile "pom.xml" ".actions/conf/maven/pmd-profile.xml" $TEMP
	if log; then
		$MVN clean pmd:pmd pmd:cpd pmd:check pmd:cpd-check -Dformat=csv -f $TEMP -Ppmd-profile >&2
	else
		$MVN clean pmd:pmd pmd:cpd pmd:check pmd:cpd-check -Dformat=csv -f $TEMP -Ppmd-profile -q -DforceStdout >/dev/null 2>&1
	fi
	# to retrieve $? the local definition must be before maven execution
	result=$?
	rm $TEMP
	mkdir ./target/lint
	mv ./target/cpd.csv ./target/lint/cpd.csv
	mv ./target/pmd.csv ./target/lint/pmd.csv
	echo "./target/lint"
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
	if log; then
		$MVN clean org.owasp:dependency-check-maven:check -Dformat=CSV -DfailBuildOnCVSS=7 -Denforce.failBuild=true $PARAMS >&2
	else
		$MVN clean org.owasp:dependency-check-maven:check -Dformat=CSV -DfailBuildOnCVSS=7 -Denforce.failBuild=true $PARAMS -q -DforceStdout >/dev/null 2>&1
	fi

	# to retrieve $? the local definition must be before maven execution
	result=$?
	echo "./target/dependency-check-report.csv"
	
	mkdir ./target/sast
	mv ./target/dependency-check-report.csv ./target/sast/dependency-check-report.csv
	echo "./target/sast"
	
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
	if log; then
		$MVN clean verify -f $TEMP -Pjacoco-profile $PARAMS >&2
	else
		$MVN clean verify -f $TEMP -Pjacoco-profile $PARAMS -q -DforceStdout >/dev/null 2>&1
	fi
	# to retrieve $? the local definition must be before maven execution
	result=$?
	rm $TEMP
	
	mkdir ./target/verify
	mv ./target/site/jacoco/jacoco.csv ./target/verify/jacoco.csv
	echo "./target/verify"
	
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
	
	if log; then
		$MVN clean verify -f $TEMP -Ppit-profile $PARAMS >&2
	else
		$MVN clean verify -f $TEMP -Ppit-profile $PARAMS -q -DforceStdout >/dev/null 2>&1
	fi
	
	# to retrieve $? the local definition must be before maven execution
	result=$?
	rm $TEMP
	
	mkdir ./target/test
	mv ./target/site/jacoco/jacoco.csv ./target/test/jacoco.csv
	echo "./target/test"
	
	echo "./target/pit-reports/mutations.csv"
	return $result
}

build() {
	local PARAMS=""
	if has_debug; then
		PARAMS="$PARAMS -X"
	fi
	log "- Starting building with maven"
	if log; then
		$MVN clean package $PARAMS -DskipTests=true >&2
	else
		$MVN clean package $PARAMS -DskipTests=true -q -DforceStdout >/dev/null 2>&1
	fi
	# to retrieve $? the local definition must be before maven execution
	result=$?
	
	local artifactName=$(artifact_name_without_extension)
	local extension=$(artifact_packaging_extension)
	
	if [[ "$FINAL_NAME" != "" ]]; then
		mv "./target/${artifactName}.${extension}" "./target/${FINAL_NAME}.${extension}"
		artifactName="$FINAL_NAME"
	fi
	
	return $result
}

deploy() {
	local PARAMS=""
	if has_debug; then
		PARAMS="$PARAMS -X"
	fi
	if log; then
		$MVN clean package $PARAMS -DskipTests=true >&2
	else
		$MVN clean package $PARAMS -DskipTests=true -q -DforceStdout >/dev/null 2>&1
	fi
	# to retrieve $? the local definition must be before maven execution
	result=$?
	
	if [[ "$result" == "0" ]]; then
		local version=$(get_project_version)
	
	
		docker login registry.gitlab.com -u $DOCKER_HARBOUR_USER -p $DOCKER_HARBOUR_PASS >&2 && \
			docker build -f src/main/docker/Dockerfile.jvm -t dagda/security .  >&2 && \
			docker tag dagda/security $DOCKER_HARBOUR_URL:$version  >&2 && \
			docker push $DOCKER_HARBOUR_URL:$version >&2
		result=$?
	fi
	
	return $result
}

report() {
	local FILE="$1"
	local TEMP="pdf-pom.xml"
	local PARAMS=""
	if [[ "$FILE" != "" ]]; then
		FILE=$(echo "$FILE" | sed 's/ /\\ /g')
		PARAMS="$PARAMS -Dinput.book=$FILE"
	fi
	echo "- Running maven pdf generation"
	cp ".actions/conf/maven/pdf-pom.xml" $TEMP
	if log; then
		$MVN clean verify -f $TEMP -Ppdf $PARAMS >&2
	else
		$MVN clean verify -f $TEMP -Ppdf $PARAMS -q -DforceStdout >/dev/null 2>&1
	fi
	
	# to retrieve $? the local definition must be before maven execution
	result=$?
	rm $TEMP
	
	# find ./target/pdf -type f
	mv "./target/pdf" "./target/report"
	echo "./target/report"
	
	
	return $result
}

get_artifact_name() {
	local artifactName=$(artifact_name_without_extension)
	local packaging=$(artifact_packaging_extension)
	echo "./target/${artifactName}.${packaging}"
}

artifact_packaging_extension() {
	local packaging=$($MVN help:evaluate -Dexpression=project.packaging -q -DforceStdout)
	echo $packaging
}

artifact_name_without_extension() {
	local artifactName=""
	local finalName=$($MVN help:evaluate -Dexpression=project.build.finalName -q -DforceStdout)
	if [ -n "$finalName" ]; then
		artifactName="$finalName"
	else
		local artifactId=$($MVN help:evaluate -Dexpression=project.artifactId -q -DforceStdout)
		local version=$($MVN help:evaluate -Dexpression=project.version -q -DforceStdout)
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
