#!/bin/bash

source .actions/.env.sh

git checkout $DEVELOPMENT_BRANCH >/dev/null 2>&1
git pull >/dev/null 2>&1
git checkout -b "$1" >/dev/null 2>&1
git push --set-upstream origin "$1" >/dev/null 2>&1

move_branch "$1"
