
# cd-partner-devops

## Overview

Repository *cd-partner-devops* provides an *Azure DevOps Pipeline* template, which an be used to define and automate the CD process in a pipeline.
The template should be used as is. Any custom additions should be made outside of the template.

This pipeline template can only be used in conjunction with the following preceding CI pipeline templates:

- ICM: https://github.com/intershop/icm-partner-devops
- PWA: https://github.com/intershop/pwa-partner-devops
- IOM: https://github.com/intershop/iom-partner-devops

## How to use the pipeline template

Add a file `azure-pipelines.yml` to the root-directory of your `cd-pipeline-repository`. After that, in Azure DevOps a new pipeline has to be created from this file.

## Parameters

| Parameter Name | Description | Default Value | Required (Default) | Only for Product | Options |
|---|---|---|---|---|---|
| id | Identifies each job uniquely when 'ci-job-template.yml' is used in a loop. Can only contain characters, numbers, and underscores. Also used to extend names of files published in extensions. |  | No |  |  |
| dependsOn | Enables an easy integration with custom jobs. The parameter will be passed as is to the 'dependsOn' property of the job. |  | No |  |  |
| condition | Enables an easy integration with custom jobs. The parameter will be passed as is to the 'condition' property of the job. |  | No |  |  |
| agentPool | Specifies the name of the agent pool. The pool name cannot be hardcoded in the pipeline template. |  | Yes |  |  |
| jobTimeoutInMinutes | Specifies the maximum job execution time in minutes. | 300 | Yes |  |  |
| jobContinueOnError | Specifies whether future jobs should run even if this job fails. | false | Yes |  |  |
| product | Specifies the product. Each product requires an individual process. |  | Yes |  | icm,pwa |
| env | Name of the environment. |  | Yes |  |  |
| environmentPath | Name of the environments repository. The name is given in "resources.repositories". | environments | Yes |  |  |
| environmentBranch | Name of the environments branch. The branch name is given in "resources.repositories". | master | Yes |  |  |
| triggerPipelineName | Name of the CI pipeline. The branch name is given in "resources.pipelines". |  | Yes |  |  |
| pipelineArtifactName | Name of the CI pipeline artifact. | image | Yes |  |  |
| imagePropertiesFile | Name of the file to be analyzed. | imageProperties.yaml | Yes |  |  |
| versionFilePath | Path of version file to be overwritten in the environment repository. For example: int/icm/version.yaml. A comma-separated list of different files can also be provided. All files will be modified with a pull request. |  | Yes |  |  |
| prCreatePullRequest | Specifies whether a PR should be created. See: https://learn.microsoft.com/de-de/cli/azure/repos/pr?view=azure-cli-latest#az-repos-pr-create | true | Yes |  |  |
| prDeleteSourceBranch | Delete the source branch after the pull request has been completed and merged into the target branch. See: https://learn.microsoft.com/de-de/cli/azure/repos/pr?view=azure-cli-latest#az-repos-pr-create | true | Yes |  |  |
| prReviewers | Additional users or groups to include as reviewers on the new pull request. Space separated. See: https://learn.microsoft.com/de-de/cli/azure/repos/pr?view=azure-cli-latest#az-repos-pr-create |  | No |  |  |
| prSquash | Squash the commits in the source branch when merging into the target branch. See: https://learn.microsoft.com/de-de/cli/azure/repos/pr?view=azure-cli-latest#az-repos-pr-create | true | Yes |  |  |
| prAutoComplete | Set the pull request to complete automatically when all policies have passed and the source branch can be merged into the target branch. See: https://learn.microsoft.com/de-de/cli/azure/repos/pr?view=azure-cli-latest#az-repos-pr-create | true | Yes |  |  |
| prAuthorName | Set the name of the commit and pull request author | ISH-CD | Yes | |  |
| prAuthorMail | Set the mail of the commit and pull request author| intershop@intershop.com | Yes | |  |
| usePredefinedRegistry | Decide whether to use a predefined registry or the registry value from the imagePropertiesFile. | false | Yes | pwa |  |
| usePredefinedPullPolicy | Decide whether to use a predefined pullPolicy.  | false | No | icm |  |
| predefinedPullPolicy | Predefined PullPolicy. | IfNotPresent | No | icm |  |
| templateRepository | Resource name of this template repository. | cd-partner-devops | Yes | |  |
| imageTagPattern | Regular expression pattern that the ImageTag must satisfy. This pattern ensures that the ImageTag is a valid Docker image tag and can be used to process only Docker Tags with this particular pattern. (POSIX-Extended Regular Expressions) | ^[^\s][[:graph:]]*$ | Yes |  |  |
| icmPredefinedProjectCustomizationName | ICM specific parameter. Predefined name of the project customization to be set in the values.yaml file. The value should only include a-z, 0-9, and hyphens. | icm-as-customization-project-icm | Yes | icm |  |
| pwaPredefinedSsrRegistry | PWA specific parameter. Predefined registry for SSR. |  | No | pwa |  |
| pwaPredefinedNginxRegistry | PWA specific parameter. Predefined registry for Nginx. |  | No | pwa |  |
| useDeploymentJob | Decide whether to use a deployment job. Attention: The deployment environments must be present and configured in the Azure DevOps project. | false | Yes |  |  |
| deploymentEnvironment | Name of the Deployment Environment. This environment must exist in the Azure DevOps project. | < product >_< env > | No | |  |
| manualValidationEnabled | Decide whether a manual validation should be carried out before the job. See: https://learn.microsoft.com/en-us/azure/devops/pipelines/tasks/reference/manual-validation-v0?view=azure-pipelines | false | Yes | | |
| manualValidationEnabledForPrd | Decide whether a manual validation should be performed before the job, which is intended for a PRD environment. Should be enabled and is only applicable for ICM or IOM. | true | Yes | | |
| manualValidationTimeout | Specify the maximum duration of the manual validation in minutes. | 43200 | Yes | |  |
| manualValidationNotifyUsers | Specify which users or groups should be informed about the upcoming manual validation. Example: <pre><code>manualValidationNotifyUsers: \| <br> userA@demo.com<br> userB@demo.com </code></pre> | | No | |  |
| manualValidationInfoText | Specify the information text for the manual validation. | "Please confirm: No breaking DB changes that could require DB rollback." | Yes | |  |

## Process:

The respective CI pipelines of the different products of the Intershop Commerce Platform generate an imageProberties file after creating all necessary container images. Examples of such an imageProberties file:

- ICM:
    ```
    images:
    - type: icm-customization
        tag: <IMAGE_TAG>
        name: <IMAGE_NAME>
        registry: <NAME>.azurecr.io
        buildWith:
        - type: buildWith
            tag: 12.X.X
            name: <IMAGE_NAME>
            registry: intershop
    ```

- PWA:
    ```
    images:
    - type: ssr
        tag: <IMAGE_TAG>
        name: <IMAGE_NAME>
        registry: <NAME>.azurecr.io
    - type: nginx
        tag: <IMAGE_TAG>
        name: issup/issup/master/pwa-nginx
        registry: <NAME>.azurecr.io
    ```
    
- IOM:
    ```
    images:
    - type: iom
        tag: <IMAGE_TAG>
        name: <IMAGE_NAME>
        registry: <NAME>.azurecr.io
    ```

These imageProberties files are read by this pipeline template provided here, evaluated for each product, and generate a pull request for all changes in the respective Flux configuration repository.

## Important information:

Always refer to the `stable/v1` branch or a tag as the main/master branch is under constant development and breaking changes cannot be excluded. The `stable/v1` represents a branch that is backward compatible and does not contain any breaking changes.


