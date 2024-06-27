#!/bin/bash
set -e

# ICM process:
# The script reads and analyzes the file located at $TEMP_IMAGE_ARTIFACT_FILE_PATH.
# It then checks the tag against the regex pattern defined in $TEMP_IMAGE_TAG_PATTERN 
# and applies the necessary changes to the file located at $PATCH_FILE_FULL_PATH.

# Create valid customizations list
VALID_CUSTOMIZATIONS_LIST="[]"

# Parse values from TEMP_IMAGE_ARTIFACT_FILE_PATH
IMAGE_TAG=$(yq '.images[0].tag' "${TEMP_IMAGE_ARTIFACT_FILE_PATH}")
IMAGE_TYPE=$(yq '.images[0].type' "${TEMP_IMAGE_ARTIFACT_FILE_PATH}")
IMAGE_NAME=$(yq '.images[0].name' "${TEMP_IMAGE_ARTIFACT_FILE_PATH}")
IMAGE_REGISTRY=$(yq '.images[0].registry' "${TEMP_IMAGE_ARTIFACT_FILE_PATH}")

# Check if IMAGE_TAG, IMAGE_TYPE, IMAGE_NAME or IMAGE_REGISTRY are empty or null
if [[ -z "$IMAGE_TAG" || -z "$IMAGE_TYPE" || -z "$IMAGE_NAME" || -z "$IMAGE_REGISTRY" ]]; then
    echo "##[error] Invalid image mapping. IMAGE_TAG, IMAGE_TYPE, IMAGE_NAME or IMAGE_REGISTRY is empty or null."
    exit 1
fi

# Add TEMP_ICM_PREDEFINED_PROJECT_CUSTOMIZATION_NAME to VALID_CUSTOMIZATIONS_LIST
VALID_CUSTOMIZATIONS_LIST="$(echo "${VALID_CUSTOMIZATIONS_LIST}" | jq --arg element "${TEMP_ICM_PREDEFINED_PROJECT_CUSTOMIZATION_NAME}"  -rc '. + [$element]')"

# Add the ${IMAGE_NAME} version to .spec.values.icm-as.customizations.<customization>.repository
REPOSITORY_NAME="${TEMP_ICM_PREDEFINED_PROJECT_CUSTOMIZATION_NAME}" \
REPOSITORY_TAG="\${project_container_registry}/${IMAGE_NAME}:${IMAGE_TAG}" \
yq -i '.spec.values.icm-as.customizations.[env(REPOSITORY_NAME)].repository  = strenv(REPOSITORY_TAG)' "${PATCH_FILE_FULL_PATH}"

# If TEMP_USE_PREDEFINED_PULL_POLICY is true, than use TEMP_PREDEFINED_PULL_POLICY as pullPolicy
if [[ "${TEMP_USE_PREDEFINED_PULL_POLICY}" == "True" ]]; then
    REPOSITORY_NAME="${TEMP_ICM_PREDEFINED_PROJECT_CUSTOMIZATION_NAME}" \
    pullPolicy="${TEMP_PREDEFINED_PULL_POLICY}" \
    yq -i '.spec.values.icm-as.customizations.[env(REPOSITORY_NAME)].pullPolicy = strenv(pullPolicy)' "${PATCH_FILE_FULL_PATH}"
fi

# Check if the "build.with" key exists in the TEMP_IMAGE_ARTIFACT_FILE_PATH file
if ! yq '.images[0].buildWith != null' "${TEMP_IMAGE_ARTIFACT_FILE_PATH}" > /dev/null 2>&1; then
    echo "##[error] The 'build.with' key does not exist in the TEMP_IMAGE_ARTIFACT_FILE_PATH file."
    exit 1
fi

# Read the contents of the YAML file and create an array of image mappings
readarray IMAGES_MAPPING < <(yq e -o=j -I=0 '.images[0].buildWith[]' "${TEMP_IMAGE_ARTIFACT_FILE_PATH}" )

# Iterate over each image mapping in the array
for image in "${IMAGES_MAPPING[@]}"; do
    echo "#####"
    # Parse the values for the tag, type, name, and registry fields from the current image mapping
    IMAGE_BUILDWITH_TAG=$(echo "$image" | yq e '.tag')
    IMAGE_BUILDWITH_TYPE=$(echo "$image" | yq e '.type')
    IMAGE_BUILDWITH_NAME=$(echo "$image" | yq e '.name')
    IMAGE_BUILDWITH_REGISTRY=$(echo "$image" | yq e '.registry')

    echo "Image: ${IMAGE_BUILDWITH_TYPE} | ${IMAGE_BUILDWITH_NAME} | ${IMAGE_BUILDWITH_TAG} | ${IMAGE_BUILDWITH_REGISTRY}"

    # Check if IMAGE_TAG, IMAGE_TYPE, IMAGE_NAME or IMAGE_REGISTRY are empty or null
    if [[ -z "$IMAGE_BUILDWITH_TAG" || -z "$IMAGE_BUILDWITH_TYPE" || -z "$IMAGE_BUILDWITH_NAME" || -z "$IMAGE_BUILDWITH_REGISTRY" ]]; then
        echo "##[error] Invalid image mapping. IMAGE_BUILDWITH_TAG, IMAGE_BUILDWITH_TYPE, IMAGE_BUILDWITH_NAME or IMAGE_BUILDWITH_REGISTRY is empty or null."
        exit 1
    fi

    # Add the icm-as version to spec.values.icm-as.image.tag
    if [ "${IMAGE_BUILDWITH_NAME}" == "icm-as" ]; then
        VERSION="${IMAGE_BUILDWITH_TAG}" \
            yq -i '.spec.values.icm-as.image.tag  = strenv(VERSION)' "${PATCH_FILE_FULL_PATH}"

    # Add the icm-webadapteragent version to spec.values.icm-web.agent.image.repository  
    elif [ "${IMAGE_BUILDWITH_NAME}" == "icm-webadapteragent" ]; then
        repositoryValue="\${icm_container_registry}/${IMAGE_BUILDWITH_NAME}:${IMAGE_BUILDWITH_TAG}" \
            yq -i '.spec.values.icm-web.agent.image.repository = strenv(repositoryValue)' "${PATCH_FILE_FULL_PATH}"

    # Add the icm-webadapter version to spec.values.icm-web.webadapter.image.repository  
    elif [ "${IMAGE_BUILDWITH_NAME}" == "icm-webadapter" ]; then
        repositoryValue="\${icm_container_registry}/${IMAGE_BUILDWITH_NAME}:${IMAGE_BUILDWITH_TAG}" \
            yq -i '.spec.values.icm-web.webadapter.image.repository = strenv(repositoryValue)' "${PATCH_FILE_FULL_PATH}"

    # Add all other customizations versions to .spec.values.icm-as.customizations.<customization>.repository
    else
        # Replaces all underscores (_) in a string with hyphens (-)
        IMAGE_BUILDWITH_NAME_ONLY_HYPHENS="${IMAGE_BUILDWITH_NAME//_/-}"

        # Add IMAGE_BUILDWITH_NAME_ONLY_HYPHENS to VALID_CUSTOMIZATIONS_LIST
        VALID_CUSTOMIZATIONS_LIST="$(echo "${VALID_CUSTOMIZATIONS_LIST}" | jq --arg element "${IMAGE_BUILDWITH_NAME_ONLY_HYPHENS}"  -rc '. + [$element]')"

        REPOSITORY_NAME="${IMAGE_BUILDWITH_NAME_ONLY_HYPHENS}" \
            REPOSITORY_TAG="\${icm_container_registry}/${IMAGE_BUILDWITH_NAME}:${IMAGE_BUILDWITH_TAG}" \
            yq -i '.spec.values.icm-as.customizations.[env(REPOSITORY_NAME)].repository  = strenv(REPOSITORY_TAG)' \
            "${PATCH_FILE_FULL_PATH}"

        # If TEMP_USE_PREDEFINED_PULL_POLICY is true, than use TEMP_PREDEFINED_PULL_POLICY as pullPolicy
        if [[ "${TEMP_USE_PREDEFINED_PULL_POLICY}" == "True" ]]; then
            REPOSITORY_NAME="${IMAGE_BUILDWITH_NAME_ONLY_HYPHENS}" \
                pullPolicy="${TEMP_PREDEFINED_PULL_POLICY}" \
                yq -i '.spec.values.icm-as.customizations.[env(REPOSITORY_NAME)].pullPolicy = strenv(pullPolicy)' \
                "${PATCH_FILE_FULL_PATH}"
        fi
    fi
done

# Remove invalid customizations
ALL_CUSTOMIZATIONS="$(yq '.spec.values.icm-as.customizations | keys' "${PATCH_FILE_FULL_PATH}" -o j | jq -rc)"

echo "ALL_CUSTOMIZATIONS = ${ALL_CUSTOMIZATIONS}"
echo "VALID_CUSTOMIZATIONS_LIST = ${VALID_CUSTOMIZATIONS_LIST}"

for customization in $(echo "${ALL_CUSTOMIZATIONS}" | jq -r '.[]'); do
    if [[ -z $(echo "${VALID_CUSTOMIZATIONS_LIST}" | jq --arg el "${customization}" '. | index($el) // empty') ]]; then
        
        echo "Remove the customization: ${customization}"
        INVALID_CUSTOMIZATIONS="${customization}" \
        yq -i 'del(.spec.values.icm-as.customizations.[env(INVALID_CUSTOMIZATIONS)])' "${PATCH_FILE_FULL_PATH}"
    fi
done

# Copy the patched ${PATCH_FILE_FULL_PATH} file
cat > "${TEMP_MD_PATCH_FILE}" <<EOF

    \`\`\`

    $(cat "${PATCH_FILE_FULL_PATH}")

    \`\`\`
EOF

cat >> "${TEMP_MD_CONFIG_FILE}" <<EOF

# Customization
    image:                    ${IMAGE_NAME}
    tag:                      ${IMAGE_TAG}

EOF

# Calc the new buildNumber
BUILD_NUMBER_PART="${BUILD_BUILDNUMBER%%_*}"
echo "##vso[build.updatebuildnumber]${BUILD_NUMBER_PART}_CD-${TEMP_PRODUCT}-${IMAGE_NAME}_${IMAGE_TAG}"
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