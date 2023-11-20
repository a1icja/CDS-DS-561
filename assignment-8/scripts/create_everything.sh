#!/bin/bash

source scripts/bash_vars.sh

# Create GCP bucket for web server files
gsutil mb "$WEB_SERVER_FILES_BUCKET_NAME"
echo "Create GCP bucket for web server files: $?"

# Copy web server files to GCP bucket
gsutil cp app/main.py "$WEB_SERVER_FILES_BUCKET_NAME"
gsutil cp app/requirements.txt "$WEB_SERVER_FILES_BUCKET_NAME"
echo "Copy web server files to GCP bucket: $?"

# Create a service account for the web server VM
gcloud iam service-accounts create "$WEB_SERVER_SA_NAME" --display-name "$WEB_SERVER_SA_NAME"
echo "Create a service account for the web server VM: $?"

# Grant the service account permission to access the GCP buckets
gcloud storage buckets add-iam-policy-binding "$WEB_SERVER_FILES_BUCKET_NAME" \
  --member "serviceAccount:$WEB_SERVER_SA_EMAIL" \
  --role roles/storage.objectViewer
gcloud storage buckets add-iam-policy-binding "$LINK_FILES_BUCKET_NAME" \
  --member "serviceAccount:$WEB_SERVER_SA_EMAIL" \
  --role roles/storage.objectViewer
echo "Grant the service account permission to access the GCP buckets: $?"

# Create a firewall rule to allow HTTP traffic from anywhere with the tag http-server
gcloud compute firewall-rules create allow-http-server \
  --project "$GCP_PROJECT" \
  --direction=INGRESS \
  --allow=tcp:80 \
  --target-tags=http-server
echo "Create a firewall rule to allow HTTP traffic from anywhere with the tag http-server: $?"

# VM 1

# Create static IP address for the web server 1 VM
gcloud compute addresses create "$WEB_SERVER_1_VM_IP_NAME" \
  --project "$GCP_PROJECT" \
  --region "$WEB_SERVER_VM_REGION"
echo "Create static IP address for the web server 1 VM: $?"

# Create a VM for the web server 1
gcloud compute instances create "$WEB_SERVER_1_VM_NAME" \
  --project=$GCP_PROJECT \
  --zone=$WEB_SERVER_1_VM_ZONE \
  --machine-type=$WEB_SERVER_VM_TIER \
  --address=$WEB_SERVER_1_VM_IP_NAME \
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
  --metadata-from-file=startup-script="$WEB_SERVER_1_STARTUP_SCRIPT"
echo "Create a VM for the web server 1: $?"

# VM 2

# Create static IP address for the web server 2 VM
gcloud compute addresses create "$WEB_SERVER_2_VM_IP_NAME" \
  --project "$GCP_PROJECT" \
  --region "$WEB_SERVER_VM_REGION"
echo "Create static IP address for the web server 2 VM: $?"

# Create a VM for the web server 2
gcloud compute instances create "$WEB_SERVER_2_VM_NAME" \
  --project=$GCP_PROJECT \
  --zone=$WEB_SERVER_2_VM_ZONE \
  --machine-type=$WEB_SERVER_VM_TIER \
  --address=$WEB_SERVER_2_VM_IP_NAME \
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
  --metadata-from-file=startup-script="$WEB_SERVER_2_STARTUP_SCRIPT"
echo "Create a VM for the web server 2: $?"

# Load Balancer

gcloud compute addresses create "$LOAD_BALANCER_IP_NAME" \
  --project "$GCP_PROJECT" \
  --region "$WEB_SERVER_VM_REGION"
echo "Create static IP address for the load balancer: $?"

gcloud compute http-health-checks create "$LOAD_BALANCER_HEALTH_CHECK_NAME" \
  --project "$GCP_PROJECT" \
  --request-path=/healthz \
  --port=80
echo "Create a health check for the load balancer: $?"

gcloud compute target-pools create "$LOAD_BALANCER_TARGET_POOL_NAME" \
  --region "$WEB_SERVER_VM_REGION" \
  --http-health-check "$LOAD_BALANCER_HEALTH_CHECK_NAME"
echo "Create a target pool for the load balancer: $?"

gcloud compute target-pools add-instances "$LOAD_BALANCER_TARGET_POOL_NAME" \
  --instances "$WEB_SERVER_1_VM_NAME" \
  --instances-zone "$WEB_SERVER_1_VM_ZONE"
gcloud compute target-pools add-instances "$LOAD_BALANCER_TARGET_POOL_NAME" \
  --instances "$WEB_SERVER_2_VM_NAME" \
  --instances-zone "$WEB_SERVER_2_VM_ZONE"
echo "Add the web server VMs to the target pool: $?"

gcloud compute forwarding-rules create "$LOAD_BALANCER_FORWARDING_RULE_NAME" \
  --region "$WEB_SERVER_VM_REGION" \
  --ports=80 \
  --address "$LOAD_BALANCER_IP_NAME" \
  --target-pool "$LOAD_BALANCER_TARGET_POOL_NAME"
echo "Create a forwarding rule for the load balancer: $?"

IPADDRESS=$(gcloud compute forwarding-rules describe "$LOAD_BALANCER_FORWARDING_RULE_NAME" --region "$WEB_SERVER_VM_REGION" --format="json" | jq -r .IPAddress)
echo "Load balancer IP address: $IPADDRESS"
