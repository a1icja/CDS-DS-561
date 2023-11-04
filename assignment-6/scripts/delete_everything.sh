#!/bin/bash

source ./scripts/bash_vars.sh

SQL_SA_EMAIL=$(gcloud sql instances describe "$CLOUD_SQL_INSTANCE_NAME" --format="value(serviceAccountEmailAddress)")
echo "Get the service account email for the Cloud SQL instance: $? ($SQL_SA_EMAIL)"

# Delete the script VM
gcloud compute instances delete "$SCRIPT_VM_NAME" --zone=$SCRIPT_VM_ZONE --quiet
echo "Delete the script VM: $?"

# Delete the IAM policy binding for the VM service account
gcloud projects remove-iam-policy-binding "$GCP_PROJECT" \
    --member "serviceAccount:$SCRIPT_VM_SA_EMAIL" \
    --role roles/storage.objectAdmin
echo "Delete the IAM policy binding for the VM service account: $?"

# Delete the IAM policy binding for the CloudSQL service account
gcloud storage buckets remove-iam-policy-binding "$CSV_BUCKET_NAME" \
    --member "serviceAccount:$SQL_SA_EMAIL" \
    --role roles/storage.objectAdmin
echo "Delete the IAM policy binding for the CloudSQL service account: $?"

# Delete the script VM service account
gcloud iam service-accounts delete "$SCRIPT_VM_SA_EMAIL" --quiet
echo "Delete the script VM service account: $?"

# Delete the GCP bucket for CSV files
gsutil rm -r "$CSV_BUCKET_NAME"
echo "Delete the GCP bucket for CSV files: $?"
