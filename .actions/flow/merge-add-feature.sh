#!/bin/bash

source .actions/.env.sh

verify_current

merge_squash_from_current_to_develop
