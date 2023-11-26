#!/bin/bash

source scripts/utils/bash_vars.sh

# Grant the GCE SA permission to use Cloud Logging
gcloud projects add-iam-policy-binding "$GCP_PROJECT" \
  --member "serviceAccount:$GCE_SA_EMAIL" \
  --role roles/logging.logWriter
echo "Grant the GCE SA permission to use Cloud Logging: $?"

# Grant the GCE SA permission to access the GCP buckets
gcloud storage buckets add-iam-policy-binding "$LINK_FILES_BUCKET_NAME" \
  --member "serviceAccount:$GCE_SA_EMAIL" \
  --role roles/storage.objectViewer
echo "Grant the GCE SA permission to access the GCP buckets: $?"

# Create a Pub/Sub topic
gcloud pubsub topics create "$PUB_SUB_TOPIC"
echo "Create a Pub/Sub topic: $?"

# Create a Pub/Sub subscription
gcloud pubsub subscriptions create "$PUB_SUB_SUBSCRIPTION" \
  --topic "$PUB_SUB_TOPIC"
echo "Create a Pub/Sub subscription: $?"

# Grant the GCE SA permission to publish and subscribe to Pub/Sub messages
gcloud pubsub topics add-iam-policy-binding "$PUB_SUB_TOPIC" \
  --member "serviceAccount:$GCE_SA_EMAIL" \
  --role roles/pubsub.publisher
gcloud pubsub subscriptions add-iam-policy-binding "$PUB_SUB_SUBSCRIPTION" \
  --member "serviceAccount:$GCE_SA_EMAIL" \
  --role roles/pubsub.subscriber
echo "Grant the GCE SA permission to publish and subscribe to Pub/Sub messages: $?"

# Create a VM for the Pub/Sub subscriber
gcloud compute instances create "$PUB_SUB_SUBSCRIBER_VM_NAME" \
  --project=$GCP_PROJECT \
  --zone=$PUB_SUB_SUBSCRIBER_VM_ZONE \
  --machine-type=$PUB_SUB_SUBSCRIBER_VM_TIER \
  --network-interface=network-tier=PREMIUM,stack-type=IPV4_ONLY,subnet=default \
  --maintenance-policy=MIGRATE \
  --provisioning-model=STANDARD \
  --service-account=$GCE_SA_EMAIL \
  --scopes=https://www.googleapis.com/auth/cloud-platform \
  --create-disk=auto-delete=yes,boot=yes,device-name=ds561-amahr-hw4-vm3,image=projects/debian-cloud/global/images/debian-11-bullseye-v20231010,mode=rw,size=10,type=projects/ds561-amahr/zones/us-central1-a/diskTypes/pd-balanced \
  --no-shielded-secure-boot \
  --shielded-vtpm \
  --shielded-integrity-monitoring \
  --labels=goog-ec-src=vm_add-gcloud \
  --reservation-affinity=any
echo "Create a VM for the Pub/Sub subscriber: $?"

# Create a VM for the HTTP client
gcloud compute instances create "$HTTP_CLIENT_VM_NAME" \
  --project=$GCP_PROJECT \
  --zone=$HTTP_CLIENT_VM_ZONE \
  --machine-type=$HTTP_CLIENT_VM_TIER \
  --network-interface=network-tier=PREMIUM,stack-type=IPV4_ONLY,subnet=default \
  --maintenance-policy=MIGRATE \
  --provisioning-model=STANDARD \
  --service-account=$GCE_SA_EMAIL \
  --scopes=https://www.googleapis.com/auth/cloud-platform \
  --create-disk=auto-delete=yes,boot=yes,device-name=ds561-amahr-hw4-vm2,image=projects/debian-cloud/global/images/debian-11-bullseye-v20231010,mode=rw,size=10,type=projects/ds561-amahr/zones/us-central1-a/diskTypes/pd-balanced \
  --no-shielded-secure-boot \
  --shielded-vtpm \
  --shielded-integrity-monitoring \
  --labels=goog-ec-src=vm_add-gcloud \
  --reservation-affinity=any
echo "Create a VM for the HTTP client: $?"

# Create a container repository
gcloud artifacts repositories create "$CONTAINER_REPOSITORY_NAME" \
  --project="$GCP_PROJECT" \
  --repository-format=docker \
  --location="$CONTAINER_REPOSITORY_REGION"
echo "Create a container repository: $?"

# Build the container image
source scripts/utils/submit_container_build.sh
echo "Build the container image: $?"

# Create a GKE cluster
gcloud container clusters create-auto "$CONTAINER_CLUSTER_NAME" \
  --location "$CONTAINER_CLUSTER_REGION" \
  --project "$GCP_PROJECT"
echo "Create a GKE cluster: $?"

# Get the credentials for the cluster
gcloud container clusters get-credentials "$CONTAINER_CLUSTER_NAME" \
  --region "$CONTAINER_CLUSTER_REGION" \
  --project "$GCP_PROJECT"
echo "Get the credentials for the cluster: $?"

# Update the workload pool
gcloud container clusters update "$CONTAINER_CLUSTER_NAME" \
  --region "$CONTAINER_CLUSTER_REGION" \
  --workload-pool="$GCP_PROJECT.svc.id.goog"
echo "Update the workload pool: $?"

# Create a GKE service account
kubectl create serviceaccount gke-service-account
echo "Create a GKE service account: $?"

# Allow the k8s SA to impersonate the GCE SA
gcloud iam service-accounts add-iam-policy-binding \
  --role roles/iam.workloadIdentityUser \
  --member "serviceAccount:$GCP_PROJECT.svc.id.goog[default/gke-service-account]" \
  "$GCE_SA_EMAIL"
echo "Allow the k8s SA to impersonate the GCE SA: $?"

# Annotate the GKE service account with the GCE SA email
kubectl annotate serviceaccount gke-service-account \
  --namespace default \
  iam.gke.io/gcp-service-account="$GCE_SA_EMAIL"
echo "Annotate the GKE service account with the GCE SA email: $?"

# Deploy the container image
source scripts/utils/deploy_container_build.sh
echo "Deploy the container image: $?"
