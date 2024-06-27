#!/bin/bash
set -e

cat > "${TEMP_MD_CONFIG_FILE}" <<EOF

# Parameters
id:                                   ${TEMP_ID}
product:                              ${TEMP_PRODUCT}
triggerPipelineName:                  ${TEMP_TRIGGER_PIPELINE_NAME}
pipelineArtifactName:                 ${TEMP_PIPELINE_ARTIFACT_NAME}
imagePropertiesFile:                  ${TEMP_IMAGE_PROPERTIES_FILE}
environmentPath:                      ${TEMP_ENVIRONMENT_PATH}
env:                                  ${TEMP_ENV}
environmentBranch:                    ${TEMP_ENVIRONMENT_BRANCH}
versionFilePath:                      ${TEMP_VERSION_FILE_PATH}
TEMP_IMAGE_ARTIFACT_FILE_PATH:        ${TEMP_IMAGE_ARTIFACT_FILE_PATH}
prCreatePullRequest:                  ${TEMP_PR_CREATE_PULL_REQUEST}
prDeleteSourceBranch:                 ${TEMP_PR_DELETE_SOURCE_BRANCH}
prReviewers:                          ${TEMP_PR_REVIEWERS}
prAutoComplete:                       ${TEMP_PR_AUTO_COMPLETE}
prSquash:                             ${TEMP_PR_SQUASH}
usePredefinedRegistry:                ${TEMP_USE_PREDEFINED_REGISTRY}
usePredefinedPullPolicy:              ${TEMP_USE_PREDEFINED_PULL_POLICY}
predefinedPullPolicy:                 ${TEMP_PREDEFINED_PULL_POLICY}
imageTagPattern:                      ${TEMP_IMAGE_TAG_PATTERN}
prAuthorName:                         ${TEMP_PR_AUTHOR_NAME}
prAuthorMail:                         ${TEMP_PR_AUTHOR_EMAIL}
templateRepository:                   ${TEMP_TEMPLATE_REPOSITORY}

# CI-Pipeline
pipelineID:                           ${TEMP_TRIGGER_PIPELINE_ID}
runName:                              ${TEMP_TRIGGER_PIPELINE_RUN_NAME}
runID:                                ${TEMP_TRIGGER_PIPELINE_RUN_ID}
runURI:                               ${TEMP_TRIGGER_PIPELINE_RUN_URI}
sourceBranch:                         ${TEMP_TRIGGER_PIPELINE_SOURCE_BRANCH}
sourceCommit:                         ${TEMP_TRIGGER_PIPELINE_SOURCE_COMMIT}

# ICM
icmPredefinedProjectCustomizationName:${TEMP_ICM_PREDEFINED_PROJECT_CUSTOMIZATION_NAME}

# PWA
ssrRegistry:                          ${TEMP_PWA_PREDEFINED_SSR_REGISTRY}
nginxRegistry:                        ${TEMP_PWA_PREDEFINED_NGINX_REGISTRY}

# Deplyoment
useDeploymentJob:                     ${TEMP_USE_DEPLOYMENT_JOB}
deploymentEnvironment:                ${TEMP_DEPLOYMENT_ENVIRONMENT}

EOF

if [ -z "${TEMP_PRODUCT}" ]; then
    echo "##[error] Parameter product must not be empty!"
    exit 1
fi
if [ -z "${TEMP_PIPELINE_ARTIFACT_NAME}" ]; then
    echo "##[error] Parameter pipelineArtifactName must not be empty!"
    exit 1
fi

if [ -z "${TEMP_IMAGE_PROPERTIES_FILE}" ]; then
    echo "##[error] Parameter imagePropertiesFile must not be empty!"
    exit 1
fi

if [ -z "${TEMP_ENVIRONMENT_BRANCH}" ]; then
    echo "##[error] Parameter environmentBranch must not be empty!"
    exit 1
fi

if [ -z "${TEMP_ENV}" ]; then
    echo "##[error] Parameter env must not be empty!"
    exit 1
fi

# Check if the 'TEMP_IMAGE_ARTIFACT_FILE_PATH' file exists
if [ ! -f "${TEMP_IMAGE_ARTIFACT_FILE_PATH}" ]; then
    echo "##[error] The file TEMP_IMAGE_ARTIFACT_FILE_PATH does not exist."
    exit 1
fi
if [ ! -s "${TEMP_IMAGE_ARTIFACT_FILE_PATH}" ]; then
    echo "##[error] The file TEMP_IMAGE_ARTIFACT_FILE_PATH exists but is empty."
    exit 1
fi

if [ -z "${TEMP_VERSION_FILE_PATH}" ]; then
    echo "##[error] Parameter versionFilePath must not be empty!"
    exit 1
fi

if [ -z "${TEMP_IMAGE_TAG_PATTERN}" ]; then
    echo "##[error] Parameter imageTagPattern must not be empty!"
    exit 1
fi

if [ -n "${TEMP_ID}" ]; then
    if echo "${TEMP_ID}" | grep -q '[^a-zA-Z0-9_]'; then
        echo "##[error] Parameter id has to consist of characters, numbers and _ only!"
        exit 1
    fi
fi