#!/bin/bash

source ./scripts/bash_vars.sh

# Get the service account email for the Cloud SQL instance
SQL_SA_EMAIL=$(gcloud sql instances describe "$CLOUD_SQL_INSTANCE_NAME" --format="value(serviceAccountEmailAddress)")
echo "Get the service account email for the Cloud SQL instance: $? ($SQL_SA_EMAIL)"

# Create a service account for the script server
gcloud iam service-accounts create "$SCRIPT_VM_SA_NAME" \
  --project=$GCP_PROJECT \
  --description="Service account for the HW6 script server" \
  --display-name="HW6 Script VM Service Account"
echo "Create a service account for the script server: $?"

# Create GCP bucket for CSV files
gsutil mb "$CSV_BUCKET_NAME"
echo "Create GCP bucket for CSV files: $?"

# Grant the CloudSQL service account permission to access the GCP bucket
gcloud storage buckets add-iam-policy-binding "$CSV_BUCKET_NAME" \
  --member "serviceAccount:$SQL_SA_EMAIL" \
  --role roles/storage.objectAdmin
echo "Grant the CloudSQL service account permission to access the GCP bucket: $?"

# Grant the VM service account permission to access the GCP bucket
gcloud storage buckets add-iam-policy-binding "$CSV_BUCKET_NAME" \
  --member "serviceAccount:$SCRIPT_VM_SA_EMAIL" \
  --role roles/storage.objectAdmin
echo "Grant the VM service account permission to access the GCP bucket: $?"

# Export CSV from Cloud SQL instance
gcloud sql export csv "$CLOUD_SQL_INSTANCE_NAME" $CSV_BUCKET_NAME/links.csv --query="SELECT * FROM requests" --database="$CLOUD_SQL_DATABASE_NAME"
echo "Export CSV from Cloud SQL instance: $?"

# Copy model files to GCP bucket
gsutil cp app/main.py "$CSV_BUCKET_NAME"
gsutil cp app/requirements.txt "$CSV_BUCKET_NAME"
echo "Copy model files to GCP bucket: $?"

# Create a VM for the script server
gcloud compute instances create "$SCRIPT_VM_NAME" \
  --project=$GCP_PROJECT \
  --zone=$SCRIPT_VM_ZONE \
  --machine-type=$SCRIPT_VM_TIER \
  --network-interface=network-tier=PREMIUM,stack-type=IPV4_ONLY,subnet=default \
  --maintenance-policy=MIGRATE \
  --provisioning-model=STANDARD \
  --service-account=$SCRIPT_VM_SA_EMAIL \
  --scopes=https://www.googleapis.com/auth/cloud-platform \
  --tags=http-server \
  --create-disk=auto-delete=yes,boot=yes,device-name=ds561-amahr-hw4-vm1,image=projects/debian-cloud/global/images/debian-11-bullseye-v20231010,mode=rw,size=10,type=projects/ds561-amahr/zones/us-central1-a/diskTypes/pd-balanced \
  --no-shielded-secure-boot \
  --shielded-vtpm \
  --shielded-integrity-monitoring \
  --labels=goog-ec-src=vm_add-gcloud \
  --reservation-affinity=any \
  --metadata-from-file=startup-script=scripts/vm_startup.sh
echo "Create a VM for the script server: $?"
