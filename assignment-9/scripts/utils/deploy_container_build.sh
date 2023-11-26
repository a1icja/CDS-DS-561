#!/bin/bash

source scripts/utils/bash_vars.sh

# Create a Kubernetes deployment
echo Deploying $CONTAINER_DEPLOYMENT_NAME
echo "us-central1-docker.pkg.dev/$GCP_PROJECT/$CONTAINER_REPOSITORY_NAME/hw9:latest"
kubectl create deployment $CONTAINER_DEPLOYMENT_NAME \
    --image "us-central1-docker.pkg.dev/$GCP_PROJECT/$CONTAINER_REPOSITORY_NAME/hw9:latest"
echo "Create a Kubernetes deployment: $?"

# Expose the Kubernetes deployment
kubectl expose deployment $CONTAINER_DEPLOYMENT_NAME \
    --type LoadBalancer \
    --port 80 \
    --target-port 80
echo "Expose the Kubernetes deployment: $?"

# Get the external IP address for the Kubernetes deployment
kubectl get service $CONTAINER_DEPLOYMENT_NAME
echo "Get the external IP address for the Kubernetes deployment: $?"

# Download the deployment configuration
kubectl get deployment $CONTAINER_DEPLOYMENT_NAME \
    --output yaml >deployment.yaml
echo "Download the deployment configuration: $?"

# Add the serviceAccountName field to the deployment configuration
perl -i~ \
    -0777 \
    -pe 's/(spec:\n(\s+))(containers:\n)/\1serviceAccountName: gke-service-account\n\2\3/g' \
    deployment.yaml
echo "Add the serviceAccountName field to the deployment configuration: $?"

# Apply the deployment configuration
kubectl apply -f deployment.yaml
echo "Apply the deployment configuration: $?"

# Delete the deployment configuration
rm deployment.yaml deployment.yaml~
echo "Delete the deployment configuration: $?"
