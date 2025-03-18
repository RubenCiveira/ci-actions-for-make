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

#
# Format the code
#
format_source() {
	:
}

# Retrieve the name of the final artifact that would be generated
get_artifact_name() {
	:
}

#
# Execute a lint over the project, and print the list of files with the reports to archive.
# A line that starts with - or [ will be precessed as log
# return 0 if the lint is rigth
# return 1 if the lint is wrong
# we can use `if [ $? -eq 0 ]; then` to check lint result 
# 
lint() {
	:
}

#
# Execute a sast over the project, and print the list of files with the reports to archive.
# A line that starts with - or [ will be precessed as log
# return 0 if the sast is rigth
# return 1 if the sast is wrong
# we can use `if [ $? -eq 0 ]; then` to check lint result 
# 
sast() {
	:
}

#
# Execute a quick set of tests over the project, and print the list of files with the reports to archive.
# A line that starts with - or [ will be precessed as log
# return 0 if the test is rigth
# return 1 if the test is wrong
# we can use `if [ $? -eq 0 ]; then` to check lint result 
# 
verify() {
	:
}


#
# Execute a complete and long set of tests over the project, and print the list of files with the reports to archive.
# A line that starts with - or [ will be precessed as log
# return 0 if the test is rigth
# return 1 if the test is wrong
# we can use `if [ $? -eq 0 ]; then` to check lint result 
# 
test() {
	:
}

#
# Execute a build over the project, and print the list of files with the reports to archive.
# A line that starts with - or [ will be precessed as log
# return 0 if the build is rigth
# return 1 if the build is wrong
# we can use `if [ $? -eq 0 ]; then` to check lint result 
# 
build() {
	:
}

#
# Execute a report over the project, and print the list of files with the reports to archive.
# A line that starts with - or [ will be precessed as log
# return 0 if the report is rigth
# return 1 if the report is wrong
# we can use `if [ $? -eq 0 ]; then` to check lint result 
# 
report() {
	:
}

#
# Execute a deploy over the project, and print the list of files with the reports to archive.
# A line that starts with - or [ will be precessed as log
# return 0 if the deploy is rigth
# return 1 if the deploy is wrong
# we can use `if [ $? -eq 0 ]; then` to check lint result 
# 
deploy() {
	:
}

