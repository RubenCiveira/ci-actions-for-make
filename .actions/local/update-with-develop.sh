#!/bin/bash

source .actions/.env.sh

git checkout $DEVELOP_BRANCH
git pull
git checkout $CURRENT_BRANCH
git fetch
git merge origin/$DEVELOP_BRANCH
git push