#!/bin/bash
set -e

# Get the revision from the BUILD_BUILDNUMBER
REVISION="${BUILD_BUILDNUMBER##*.}"

if [ -z "${REVISION}" ]; then
    echo "##[error] Variable REVISION must not be empty!"
    exit 1
fi

# Short sourceCommit
SOURCE_COMMIT_SHORT="${TEMP_TRIGGER_PIPELINE_SOURCE_COMMIT:0:10}"

if [ -z "${SOURCE_COMMIT_SHORT}" ]; then
    echo "##[error] Variable SOURCE_COMMIT_SHORT must not be empty!"
    exit 1
fi

BRANCH_NAME="${TEMP_PRODUCT}-${TEMP_ENV}/${SOURCE_COMMIT_SHORT}-${BUILD_BUILDID}-${REVISION}"
echo "BRANCH_NAME: ${BRANCH_NAME}"

cat >> "${TEMP_MD_CONFIG_FILE}" <<EOF

# Branch
    branch:                    ${BRANCH_NAME}

EOF
echo "##vso[task.setvariable variable=BRANCH_NAME]${BRANCH_NAME}"