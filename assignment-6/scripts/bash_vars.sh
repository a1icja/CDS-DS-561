#!/bin/bash

# Project
export GCP_PROJECT="ds561-amahr"

# Cloud SQL
export CLOUD_SQL_INSTANCE_NAME="$GCP_PROJECT-hw5-db-instance"
export CLOUD_SQL_DATABASE_NAME="hw5-db"

# Cloud Storage
export CSV_BUCKET_NAME="gs://$GCP_PROJECT-hw6"

# Script VM
export SCRIPT_VM_NAME="$GCP_PROJECT-hw6-vm1"
export SCRIPT_VM_SA_NAME="$GCP_PROJECT-hw6-sa"
export SCRIPT_VM_SA_EMAIL="$SCRIPT_VM_SA_NAME@$GCP_PROJECT.iam.gserviceaccount.com"
export SCRIPT_VM_REGION="us-east4"
export SCRIPT_VM_ZONE=$SCRIPT_VM_REGION"-c"
export SCRIPT_VM_TIER="n1-standard-1"
