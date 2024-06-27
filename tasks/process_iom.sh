#!/bin/bash
set -e

# IOM process:
# The script reads and analyzes the file located at $TEMP_IMAGE_ARTIFACT_FILE_PATH.
# It then checks the tag against the regex pattern defined in $TEMP_IMAGE_TAG_PATTERN 
# and applies the necessary changes to the file located at $PATCH_FILE_FULL_PATH.

# Read the contents of the YAML file and create an array of image mappings
readarray IMAGES_MAPPING < <(yq e -o=j -I=0 '.images[]' "${TEMP_IMAGE_ARTIFACT_FILE_PATH}" )

# Iterate over each image mapping in the array
for image in "${IMAGES_MAPPING[@]}"; do
    echo "#####"
    # Parse the values for the tag, type, name, and registry fields from the current image mapping
    IMAGE_TAG=$(echo "$image" | yq e '.tag')
    IMAGE_TYPE=$(echo "$image" | yq e '.type')
    IMAGE_NAME=$(echo "$image" | yq e '.name')
    IMAGE_REGISTRY=$(echo "$image" | yq e '.registry')
    
    echo "Image: ${IMAGE_TYPE} | ${IMAGE_NAME} | ${IMAGE_TAG} | ${IMAGE_REGISTRY} "

    # Check if IMAGE_TAG, IMAGE_TYPE, IMAGE_NAME or IMAGE_REGISTRY are empty or null
    if [[ -z "$IMAGE_TAG" || -z "$IMAGE_TYPE" || -z "$IMAGE_NAME" || -z "$IMAGE_REGISTRY" ]]; then
        echo "##[error] Invalid image mapping. IMAGE_TAG, IMAGE_TYPE, IMAGE_NAME or IMAGE_REGISTRY is empty or null."
        exit 1
    fi

    # Check if IMAGE_TYPE is "iom"
    if [[ "$IMAGE_TYPE" == "iom" ]]; then

        # Replace the tag in '.spec.values.image.tag'
        TAG="${IMAGE_TAG}" \
        yq -i '.spec.values.image.tag = strenv(TAG)' "${PATCH_FILE_FULL_PATH}"

        FINAL_REPOSITORY="${IMAGE_REGISTRY}/${IMAGE_NAME}"

        # Replace the repository in '.spec.values.image.repository'
        REPOSITORY="${FINAL_REPOSITORY}" \
        yq -i '.spec.values.image.repository = strenv(REPOSITORY)' "${PATCH_FILE_FULL_PATH}"

    else
        echo "Unknown Image Type: ${IMAGE_TYPE}"
    fi
done

cat > "${TEMP_MD_PATCH_FILE}" <<EOF

    \`\`\`

    $(cat "${PATCH_FILE_FULL_PATH}")

    \`\`\`
EOF

# Calc the new buildNumber
BUILD_NUMBER_PART="${BUILD_BUILDNUMBER%%_*}"
echo "##vso[build.updatebuildnumber]${BUILD_NUMBER_PART}_CD-${TEMP_PRODUCT}-${IMAGE_TAG}"
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