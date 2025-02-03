#!/bin/bash
set -e

# Custom process:
# The script reads and analyzes the file located at $TEMP_IMAGE_ARTIFACT_FILE_PATH.
# It then checks the tag against the regex pattern defined in $TEMP_IMAGE_TAG_PATTERN 
# and applies the necessary changes to the file located at $PATCH_FILE_FULL_PATH.

# Get selected image details with validation
IMAGE_REGISTRY=$(yq ".images[] | select(.type == strenv(TEMP_CUSTOM_SELECTED_IMAGE_TYPE)).registry" "${TEMP_IMAGE_ARTIFACT_FILE_PATH}")
IMAGE_NAME=$(yq ".images[] | select(.type == strenv(TEMP_CUSTOM_SELECTED_IMAGE_TYPE)).name" "${TEMP_IMAGE_ARTIFACT_FILE_PATH}")
IMAGE_TAG=$(yq ".images[] | select(.type == strenv(TEMP_CUSTOM_SELECTED_IMAGE_TYPE)).tag" "${TEMP_IMAGE_ARTIFACT_FILE_PATH}")

echo "Image: ${TEMP_PRODUCT} | ${TEMP_CUSTOM_SELECTED_IMAGE_TYPE} | ${IMAGE_NAME} | ${IMAGE_TAG} | ${IMAGE_REGISTRY} "

# Validate required fields
if [ -z "$IMAGE_REGISTRY" ] || [ -z "$IMAGE_NAME" ] || [ -z "$IMAGE_TAG" ]; then
    echo "##[error] Invalid image mapping. IMAGE_TAG, IMAGE_TYPE, IMAGE_NAME or IMAGE_REGISTRY is empty or null."
    exit 1
fi

# Combine paths logic
if [ "${TEMP_CUSTOM_IMAGE_NAME_YAML_PATH}" == "${TEMP_CUSTOM_TAG_YAML_PATH}" ]; then
    # Combined image format: <registry>/<name>:<tag>
    FULL_IMAGE_STRING="${IMAGE_REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}"

    FULL_IMAGE_STRING="${FULL_IMAGE_STRING}" \
    yq -i "${TEMP_CUSTOM_IMAGE_NAME_YAML_PATH} = strenv(FULL_IMAGE_STRING)" "${PATCH_FILE_FULL_PATH}"
else
    # Separate paths
    IMAGE_PATH="${IMAGE_REGISTRY}/${IMAGE_NAME}" \
    yq -i "${TEMP_CUSTOM_IMAGE_NAME_YAML_PATH} = strenv(IMAGE_PATH)" "${PATCH_FILE_FULL_PATH}"

    IMAGE_TAG="$IMAGE_TAG" \
    yq -i "${TEMP_CUSTOM_TAG_YAML_PATH} = strenv(IMAGE_TAG)" "${PATCH_FILE_FULL_PATH}"
fi

cat > "${TEMP_MD_PATCH_FILE}" <<EOF

    \`\`\`

    $(cat "${PATCH_FILE_FULL_PATH}")

    \`\`\`
EOF

# Calc the new buildNumber
BUILD_NUMBER_PART="${BUILD_BUILDNUMBER%%_*}"
echo "##vso[build.updatebuildnumber]${BUILD_NUMBER_PART}_CD-${TEMP_PRODUCT}-${IMAGE_NAME//[^a-zA-Z]/}-${IMAGE_TAG}"
echo "##vso[build.addbuildtag]${TEMP_PRODUCT}"

# Checking whether the Regex tag pattern is fulfilled.
if [[ ${IMAGE_TAG} =~ ${TEMP_IMAGE_TAG_PATTERN} ]]; then
    echo "${IMAGE_TAG} fulfills the pattern requirement: ${TEMP_IMAGE_TAG_PATTERN}"
    echo "##vso[task.setvariable variable=VALID_TAG]true"
    echo "##vso[build.addbuildtag]${TEMP_ENV}"
else
    echo "##vso[task.logissue type=warning;]${IMAGE_TAG} does not fulfill the pattern requirement: ${TEMP_IMAGE_TAG_PATTERN}"
    echo "##vso[task.setvariable variable=VALID_TAG]false"
    exit 0
fi