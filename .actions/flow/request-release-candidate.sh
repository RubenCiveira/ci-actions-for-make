#!/bin/bash

source .actions/.env.sh

verify_develop

git checkout develop  >/dev/null 2>&1

NEXT_VERSION=$(git_next_version "release")

create_upgrade_to_branch_for_version $RELEASE_BRANCH $NEXT_VERSION

