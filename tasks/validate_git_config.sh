#!/bin/bash
set -e

# Get the repository name
TARGET_REPOSITORY_FULL=$(git config --get remote.origin.url)
TARGET_REPOSITORY="${TARGET_REPOSITORY_FULL##*/}"
if [ -z "${TARGET_REPOSITORY}" ]; then
    echo "##[error] Variable TARGET_REPOSITORY must not be empty!"
    exit 1
fi

# Get the branch name
TARGET_BRANCH_NAME="${TEMP_ENVIRONMENT_BRANCH}"
if [ -z "${TARGET_BRANCH_NAME}" ]; then
    echo "##[error] Variable TARGET_BRANCH_NAME must not be empty!"
    exit 1
fi

cat >> "${TEMP_MD_CONFIG_FILE}" <<EOF

# Repository
    TARGET_REPOSITORY:                    ${TARGET_REPOSITORY}
    TARGET_BRANCH_NAME:                   ${TARGET_BRANCH_NAME}

EOF
echo "##vso[task.setvariable variable=TARGET_REPOSITORY]${TARGET_REPOSITORY}"
echo "##vso[task.setvariable variable=TARGET_BRANCH_NAME]${TARGET_BRANCH_NAME}"