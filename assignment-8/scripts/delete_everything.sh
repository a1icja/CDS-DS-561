#!/bin/bash

source scripts/bash_vars.sh

# Delete the forwarding rule for the load balancer
gcloud compute forwarding-rules delete "$LOAD_BALANCER_FORWARDING_RULE_NAME" \
    --project "$GCP_PROJECT" \
    --region "$WEB_SERVER_VM_REGION" \
    --quiet
echo "Delete the forwarding rule for the load balancer: $?"

# Delete the target pool for the load balancer
gcloud compute target-pools delete "$LOAD_BALANCER_TARGET_POOL_NAME" \
    --project "$GCP_PROJECT" \
    --region "$WEB_SERVER_VM_REGION" \
    --quiet
echo "Delete the target pool for the load balancer: $?"

# Delete the health check for the load balancer
gcloud compute http-health-checks delete "$LOAD_BALANCER_HEALTH_CHECK_NAME" \
    --project "$GCP_PROJECT" \
    --quiet
echo "Delete the health check for the load balancer: $?"

# Delete the static IP address for the load balancer
gcloud compute addresses delete "$LOAD_BALANCER_IP_NAME" \
    --project "$GCP_PROJECT" \
    --region "$WEB_SERVER_VM_REGION" \
    --quiet
echo "Delete the static IP address for the load balancer: $?"

# Delete the VM for the web server 1
gcloud compute instances delete "$WEB_SERVER_1_VM_NAME" \
    --project "$GCP_PROJECT" \
    --zone "$WEB_SERVER_1_VM_ZONE" \
    --quiet
echo "Delete the VM for the web server 1: $?"

# Delete the static IP address for the web server 1
gcloud compute addresses delete "$WEB_SERVER_1_VM_IP_NAME" \
    --project "$GCP_PROJECT" \
    --region "$WEB_SERVER_VM_REGION" \
    --quiet
echo "Delete the static IP address for the web server 1: $?"

# Delete the VM for the web server 2
gcloud compute instances delete "$WEB_SERVER_2_VM_NAME" \
    --project "$GCP_PROJECT" \
    --zone "$WEB_SERVER_2_VM_ZONE" \
    --quiet
echo "Delete the VM for the web server 2: $?"

# Delete the static IP address for the web server 2
gcloud compute addresses delete "$WEB_SERVER_2_VM_IP_NAME" \
    --project "$GCP_PROJECT" \
    --region "$WEB_SERVER_VM_REGION" \
    --quiet
echo "Delete the static IP address for the web server 2: $?"

# Revoke the service account permission to access the GCP buckets
gcloud storage buckets remove-iam-policy-binding "$LINK_FILES_BUCKET_NAME" \
    --project "$GCP_PROJECT" \
    --role roles/storage.objectViewer \
    --member serviceAccount:"$WEB_SERVER_SA_EMAIL"
gcloud storage buckets remove-iam-policy-binding "$WEB_SERVER_FILES_BUCKET_NAME" \
    --project "$GCP_PROJECT" \
    --role roles/storage.objectViewer \
    --member serviceAccount:"$WEB_SERVER_SA_EMAIL"
echo "Revoke the service account permission to access the GCP buckets: $?"

# Delete the service account
gcloud iam service-accounts delete "$WEB_SERVER_SA_EMAIL" \
    --project "$GCP_PROJECT" \
    --quiet
echo "Delete the service account: $?"

# Delete the GCP bucket for the web server
gsutil rm -r "$WEB_SERVER_FILES_BUCKET_NAME"
echo "Delete the GCP bucket for the web server: $?"
