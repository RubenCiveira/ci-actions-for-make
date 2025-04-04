#!/bin/bash
FEATURE_USE_VERSION_PREFIX=${FEATURE_USE_VERSION_PREFIX:-false}
CHANGELOG_INCLUDE_BODY=${CHANGELOG_INCLUDE_BODY:-false}

source $SCRIPT_DIR/gitflow/git-changelog.sh
source $SCRIPT_DIR/gitflow/git-common.sh
source $SCRIPT_DIR/gitflow/git-features.sh
source $SCRIPT_DIR/gitflow/git-releases.sh
source $SCRIPT_DIR/gitflow/git-hotfix.sh
