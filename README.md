
# cd-partner-devops

## Overview

Repository *cd-partner-devops* provides an *Azure DevOps Pipeline* template, which an be used to define and automate the CD process in a pipeline.
The template should be used as is. Any custom additions should be made outside of the template.

This pipeline template can only be used in conjunction with the following preceding CI pipeline templates:

- ICM: https://github.com/intershop/icm-partner-devops
- PWA: https://github.com/intershop/pwa-partner-devops

## How to use the pipeline template

Add a file `azure-pipelines.yml` to the root-directory of your `cd-pipeline-repository`. After that, in Azure DevOps a new pipeline has to be created from this file.

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
            tag: 11.X.X
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

These imageProberties files are read by this pipeline template provided here, evaluated for each product, and generate a pull request for all changes in the respective Flux configuration repository.

## Important information:

Always refer to the `stable/v1` branch or a tag as the main/master branch is under constant development and breaking changes cannot be excluded. The `stable/v1` represents a branch that is backward compatible and does not contain any breaking changes.


