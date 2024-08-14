#!/bin/bash

source .actions/.env.sh

verify_release

git checkout release  >/dev/null 2>&1

NEXT_VERSION=$(git_next_version "final")

merge_upgrade_to_branch_for_version $MAIN_BRANCH $NEXT_VERSION
