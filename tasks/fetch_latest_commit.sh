#!/bin/bash
set -e

git fetch origin "${TEMP_ENVIRONMENT_BRANCH}"
git checkout "${TEMP_ENVIRONMENT_BRANCH}"

git log -1