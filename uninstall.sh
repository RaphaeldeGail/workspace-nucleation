#!/bin/bash

# This script must be executed as an organization administrator as only them have rights to destroy projects and folders.

# Workspace name
WORKSPACE=$1

# Fetch organization ID and Workspace folder ID by name
ORGANIZATION_DOMAIN="wansho.fr"
ORGANIZATION_ID=$( gcloud organizations describe $ORGANIZATION_DOMAIN --format="value(name)" | cut -d'/' -f 2 )
FOLDER_ID=$( gcloud resource-manager folders list --organization=$ORGANIZATION_ID --filter="DISPLAY_NAME:$WORKSPACE" --format="value(ID)" )

# Delete resources from the workspace: admin project, folder and tag value.

gcloud resource-manager folders delete $FOLDER_ID

gcloud projects delete $WORKSPACE-administration

gcloud resource-manager tags values delete $ORGANIZATION_ID/workspace/$WORKSPACE

# Clear the terraform Cloud workspace without a destroy plan
export TF_WORKSPACE="$WORKSPACE-workspace"
terraform init
for x in $(terraform state list); do terraform state rm "$x"; done