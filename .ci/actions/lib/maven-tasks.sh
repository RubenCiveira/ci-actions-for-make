#!/bin/bash

MVN=./mvnw

mvn_clean() {
    mvn_run_clean
    return $?
}

mvn_format() {
	mvn_format_formatter
	return $?
}

mvn_lint() {
	mvn_lint_pmd
	return $?
}

mvn_sast() {
	mvn_sast_owasp
	return $?
}

mvn_verify() {
	mvn_verify_jacoco
	return $?
}

mvn_test() {
	mvn_test_pit
	return $?
}

mvn_report() {
	mvn_report_adoc
	return $?
}