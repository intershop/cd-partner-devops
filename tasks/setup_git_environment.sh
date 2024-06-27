#!/bin/bash
set -e

git config \
    --global user.email "${TEMP_PR_AUTHOR_EMAIL}"
git config \
    --global user.name "${TEMP_PR_AUTHOR_NAME}"