#!/bin/bash
set -e

# Create a new branch
echo "Create a new branch ${BRANCH_NAME}"
git checkout -b "${BRANCH_NAME}"
# Stage all files
git add -A
# Git status
GIT_STATUS=$(git status --porcelain | head -1)
echo "GIT_STATUS: ${GIT_STATUS}"

cat >> "${TEMP_MD_CONFIG_FILE}" <<EOF

# Git
    GIT_STATUS:                            ${GIT_STATUS}
EOF

if [ -z "${GIT_STATUS}" ]; then
  echo "##vso[task.logissue type=warning]No changes detected in branch '${BRANCH_NAME}' - Pull Request will be skipped. (Stage: ${SYSTEM_STAGEDISPLAYNAME}, Job: ${SYSTEM_JOBDISPLAYNAME}) - ${SYSTEM_JOBIDENTIFIER}"
fi

echo "##vso[task.setvariable variable=GIT_STATUS]${GIT_STATUS}"