#!/bin/bash

source scripts/utils/bash_vars.sh

# Build the container image
gcloud builds submit \
    --tag "us-central1-docker.pkg.dev/$GCP_PROJECT/$CONTAINER_REPOSITORY_NAME/hw9:latest" \
    ./app
echo "Build the container image: $?"

# Show the updated artifacts
gcloud artifacts files list \
    --repository="$CONTAINER_REPOSITORY_NAME" \
    --location="$CONTAINER_REPOSITORY_REGION"
echo "Show the updated artifacts: $?"
