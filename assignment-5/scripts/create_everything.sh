#!/bin/bash

source scripts/bash_vars.sh

# Create GCP bucket for web server files
gsutil mb "$WEB_SERVER_FILES_BUCKET_NAME"
echo "Create GCP bucket for web server files: $?"

# Copy web server files to GCP bucket
gsutil cp app/main.py "$WEB_SERVER_FILES_BUCKET_NAME"
gsutil cp app/requirements.txt "$WEB_SERVER_FILES_BUCKET_NAME"
echo "Copy web server files to GCP bucket: $?"

# Create Cloud SQL instance for logging requests
gcloud sql instances create "$CLOUD_SQL_INSTANCE_NAME" \
  --database-version=MYSQL_8_0 \
  --cpu=4 \
  --memory=16GiB \
  --root-password="$CLOUD_SQL_INSTANCE_ROOT_PASSWORD" \
  --storage-size=100GiB \
  --zone="$CLOUD_SQL_INSTANCE_ZONE" \
  --edition=enterprise
echo "Create Cloud SQL instance for logging requests: $?"

# Add 0.0.0.0/0 to the authorized networks for the Cloud SQL instance
gcloud sql instances patch "$CLOUD_SQL_INSTANCE_NAME" \
  --authorized-networks="0.0.0.0/0"
echo "Add 0.0.0.0/0 to the authorized networks for the Cloud SQL instance: $?"

# Create a database for the web server
gcloud sql databases create "$CLOUD_SQL_DATABASE_NAME" \
  --instance="$CLOUD_SQL_INSTANCE_NAME"
echo "Create a database for the web server: $?"

# Create a service account for the web server VM
gcloud iam service-accounts create "$WEB_SERVER_SA_NAME" --display-name "$WEB_SERVER_SA_NAME"
echo "Create a service account for the web server VM: $?"

# Grant the service account Cloud SQL Client permissions
gcloud projects add-iam-policy-binding "$GCP_PROJECT" \
  --member "serviceAccount:$WEB_SERVER_SA_EMAIL" \
  --role roles/cloudsql.client
echo "Grant the service account Cloud SQL Client permissions: $?"

# Grant the service account permission to use Cloud Logging
gcloud projects add-iam-policy-binding "$GCP_PROJECT" \
  --member "serviceAccount:$WEB_SERVER_SA_EMAIL" \
  --role roles/logging.logWriter
echo "Grant the service account permission to use Cloud Logging: $?"

# Grant the service account permission to access the GCP buckets
gcloud storage buckets add-iam-policy-binding "$WEB_SERVER_FILES_BUCKET_NAME" \
  --member "serviceAccount:$WEB_SERVER_SA_EMAIL" \
  --role roles/storage.objectViewer
gcloud storage buckets add-iam-policy-binding "$LINK_FILES_BUCKET_NAME" \
  --member "serviceAccount:$WEB_SERVER_SA_EMAIL" \
  --role roles/storage.objectViewer
echo "Grant the service account permission to access the GCP buckets: $?"

# Create a Pub/Sub topic for the web server VM
gcloud pubsub topics create "$PUB_SUB_TOPIC"
echo "Create a Pub/Sub topic for the web server VM: $?"

# Create a Pub/Sub subscription for the web server VM
gcloud pubsub subscriptions create "$PUB_SUB_SUBSCRIPTION" \
  --topic "$PUB_SUB_TOPIC"
echo "Create a Pub/Sub subscription for the web server VM: $?"

# Grant the service account permission to publish and subscribe to Pub/Sub messages
gcloud pubsub topics add-iam-policy-binding "$PUB_SUB_TOPIC" \
  --member "serviceAccount:$WEB_SERVER_SA_EMAIL" \
  --role roles/pubsub.publisher
gcloud pubsub subscriptions add-iam-policy-binding "$PUB_SUB_SUBSCRIPTION" \
  --member "serviceAccount:$WEB_SERVER_SA_EMAIL" \
  --role roles/pubsub.subscriber
echo "Grant the service account permission to publish and subscribe to Pub/Sub messages: $?"

# Create static IP address for the web server VM
gcloud compute addresses create "$WEB_SERVER_VM_IP_NAME" \
  --project "$GCP_PROJECT" \
  --region "$WEB_SERVER_VM_REGION"
echo "Create static IP address for the web server VM: $?"

# Create a firewall rule to allow HTTP traffic from anywhere with the tag http-server
# gcloud compute firewall-rules create allow-http-server \
#   --project "$GCP_PROJECT" \
#   --direction=INGRESS \
#   --allow=tcp:80 \
#   --target-tags=http-server
# echo "Create a firewall rule to allow HTTP traffic from anywhere with the tag http-server: $?"

# Create a VM for the web server
gcloud compute instances create "$WEB_SERVER_VM_NAME" \
  --project=$GCP_PROJECT \
  --zone=$WEB_SERVER_VM_ZONE \
  --machine-type=$WEB_SERVER_VM_TIER \
  --address=$WEB_SERVER_VM_IP_NAME \
  --maintenance-policy=MIGRATE \
  --provisioning-model=STANDARD \
  --service-account=$WEB_SERVER_SA_EMAIL \
  --scopes=https://www.googleapis.com/auth/cloud-platform \
  --tags=http-server \
  --create-disk=auto-delete=yes,boot=yes,device-name=ds561-amahr-hw4-vm1,image=projects/debian-cloud/global/images/debian-11-bullseye-v20231010,mode=rw,size=10,type=projects/ds561-amahr/zones/us-central1-a/diskTypes/pd-balanced \
  --no-shielded-secure-boot \
  --shielded-vtpm \
  --shielded-integrity-monitoring \
  --labels=goog-ec-src=vm_add-gcloud \
  --reservation-affinity=any \
  --metadata-from-file=startup-script=scripts/vm_startup.sh
echo "Create a VM for the web server: $?"
