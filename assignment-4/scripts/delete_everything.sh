#!/bin/bash

source scripts/bash_vars.sh

# Delete the web server VM
gcloud compute instances delete "$WEB_SERVER_VM_NAME" \
    --project "$GCP_PROJECT" \
    --zone "$WEB_SERVER_VM_ZONE" \
    --quiet
echo "Delete the web server VM: $?"

# Delete the firewall rule to allow HTTP traffic from anywhere with the tag http-server
gcloud compute firewall-rules delete allow-http-server \
    --project "$GCP_PROJECT" \
    --quiet
echo "Delete the firewall rule to allow HTTP traffic from anywhere with the tag http-server: $?"

# Delete the static IP address for the web server VM
gcloud compute addresses delete "$WEB_SERVER_VM_IP_NAME" \
    --project "$GCP_PROJECT" \
    --region "$WEB_SERVER_VM_REGION" \
    --quiet
echo "Delete the static IP address for the web server VM: $?"

# Delete the service account permission to publish and subscribe to Pub/Sub messages
gcloud pubsub topics remove-iam-policy-binding "$PUB_SUB_TOPIC" \
    --member "serviceAccount:$WEB_SERVER_SA_EMAIL" \
    --role roles/pubsub.publisher
gcloud pubsub subscriptions remove-iam-policy-binding "$PUB_SUB_SUBSCRIPTION" \
    --member "serviceAccount:$WEB_SERVER_SA_EMAIL" \
    --role roles/pubsub.subscriber
echo "Delete the service account permission to publish and subscribe to Pub/Sub messages: $?"

# Delete the Pub/Sub subscription for the web server VM
gcloud pubsub subscriptions delete "$PUB_SUB_SUBSCRIPTION" \
    --project "$GCP_PROJECT" \
    --quiet
echo "Delete the Pub/Sub subscription for the web server VM: $?"

# Delete the Pub/Sub topic for the web server VM
gcloud pubsub topics delete "$PUB_SUB_TOPIC" \
    --project "$GCP_PROJECT" \
    --quiet
echo "Delete the Pub/Sub topic for the web server VM: $?"

# Delete the service account permission to access the GCP buckets
gcloud storage buckets remove-iam-policy-binding "$WEB_SERVER_FILES_BUCKET_NAME" \
    --member "serviceAccount:$WEB_SERVER_SA_EMAIL" \
    --role roles/storage.objectViewer
gcloud storage buckets remove-iam-policy-binding "$LINK_FILES_BUCKET_NAME" \
    --member "serviceAccount:$WEB_SERVER_SA_EMAIL" \
    --role roles/storage.objectViewer
echo "Delete the service account permission to access the GCP buckets: $?"

# Delete the service account permission to use Cloud Logging
gcloud projects remove-iam-policy-binding "$GCP_PROJECT" \
    --member "serviceAccount:$WEB_SERVER_SA_EMAIL" \
    --role roles/logging.logWriter
echo "Delete the service account permission to use Cloud Logging: $?"

# Delete the service account for the web server VM
gcloud iam service-accounts delete "$WEB_SERVER_SA_EMAIL" \
    --project "$GCP_PROJECT" \
    --quiet
echo "Delete the service account for the web server VM: $?"

# Delete the GCP bucket for web server files
gsutil rm -r "$WEB_SERVER_FILES_BUCKET_NAME"
echo "Delete the GCP bucket for web server files: $?"
