#!/bin/bash
set -e

# az install extension
az extension add \
    --name azure-devops \
    --allow-preview false \
    --only-show-errors

# Commit and push the changes
echo "Commit the changes and push the branch:"
git commit -m "deployment ${BUILD_BUILDNUMBER} - ${BRANCH_NAME}"
git push --set-upstream origin "${BRANCH_NAME}"

PR_PARAMETERS=""
# Set reviewers parameter
if [ -n "${TEMP_PR_REVIEWERS}" ]; then
    PR_PARAMETERS="${PR_PARAMETERS} --reviewers \"${TEMP_PR_REVIEWERS}\""
fi

# Set the delete-source-branch parameter
if [ "${TEMP_PR_DELETE_SOURCE_BRANCH}" = "True" ] ; then
    PR_PARAMETERS="${PR_PARAMETERS} --delete-source-branch true"
fi

# Set the squash parameter
if [ "${TEMP_PR_SQUASH}" = "True" ] ; then
    PR_PARAMETERS="${PR_PARAMETERS} --squash true"
fi

# Set the auto-complete parameter
if [ "${TEMP_PR_AUTO_COMPLETE}" = "True" ] ; then
    PR_PARAMETERS="${PR_PARAMETERS} --auto-complete true"
fi

echo "Additional parameterlist for 'az repos pr create': ${PR_PARAMETERS}"

PR_RESPONSE=$(az repos pr create \
    --project "${SYSTEM_TEAMPROJECT}" \
    --org "${SYSTEM_COLLECTIONURI}" \
    --repository "${TARGET_REPOSITORY}" \
    --target-branch "${TARGET_BRANCH_NAME}" \
    --source-branch "${BRANCH_NAME}" \
    --title "deployment ${BUILD_BUILDNUMBER} - ${BRANCH_NAME}" \
    ${PR_PARAMETERS} \
    -o json)

echo "Result of the pull request creation: $PR_RESPONSE"
PR_NUM=$(echo "${PR_RESPONSE}" | jq '.pullRequestId')
if [ -z "${PR_NUM}" ]; then
    echo "##[error] Variable PR_NUM must not be empty!"
    exit 1
fi

echo "Pull request id: $PR_NUM"

cat >> "${TEMP_MD_CONFIG_FILE}" <<EOF

# PullRequest
    PR_NUM:                               ${PR_NUM}
    PR_PARAMETERS:                        ${PR_PARAMETERS}

EOF
echo "##vso[task.setvariable variable=PR_NUM]$PR_NUM"
echo "##vso[task.setvariable variable=PR_NUM;isOutput=true]$PR_NUM"