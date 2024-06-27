#!/bin/bash
set -e

PATCH_FILE_FULL_PATH="${PIPELINE_WORKSPACE}/s/${TEMP_ENVIRONMENT_PATH}/$(echo "${TEMP_VERSION_PATCH_FILE_PATH}" | xargs)"
echo "##vso[task.setvariable variable=PATCH_FILE_FULL_PATH]${PATCH_FILE_FULL_PATH}"

cat >> "${TEMP_MD_CONFIG_FILE}" <<EOF

# versionFilePath
    value:                    ${TEMP_VERSION_PATCH_FILE_PATH}
    PATCH_FILE_FULL_PATH:     ${PATCH_FILE_FULL_PATH}
EOF

# Check if the 'PATCH_FILE_FULL_PATH' file exists
if [ ! -f "${PATCH_FILE_FULL_PATH}" ]; then
    echo "##[error] The PATCH_FILE_FULL_PATH: ${PATCH_FILE_FULL_PATH} file does not exist."
    exit 1
fi