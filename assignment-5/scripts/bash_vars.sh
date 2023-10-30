#!/bin/bash

# Project
export GCP_PROJECT="ds561-amahr"

# Link - Bucket
export LINK_FILES_BUCKET_NAME="gs://ds561-amahr-hw2"

# Web Server - Bucket, Service Account, VM
export WEB_SERVER_FILES_BUCKET_NAME="gs://ds561-amahr-hw5"
export WEB_SERVER_SA_NAME="$GCP_PROJECT-hw5-sa"
export WEB_SERVER_SA_EMAIL="$WEB_SERVER_SA_NAME@$GCP_PROJECT.iam.gserviceaccount.com"
export WEB_SERVER_VM_NAME="$GCP_PROJECT-hw5-vm1"
export WEB_SERVER_VM_REGION="us-east4"
export WEB_SERVER_VM_ZONE=$WEB_SERVER_VM_REGION"-c"
export WEB_SERVER_VM_IP_NAME="$GCP_PROJECT-hw5-ip"
export WEB_SERVER_VM_DIR="/root/web-server"
export WEB_SERVER_VM_TIER="f1-micro"

# Cloud SQL - Instance, Database
export CLOUD_SQL_INSTANCE_NAME="$GCP_PROJECT-hw5-db-instance"
export CLOUD_SQL_INSTANCE_REGION="us-east4"
export CLOUD_SQL_INSTANCE_ZONE=$CLOUD_SQL_INSTANCE_REGION"-c"
export CLOUD_SQL_INSTANCE_ROOT_PASSWORD="trj-RHP0hvz2kcw1yqr"
export CLOUD_SQL_DATABASE_NAME="hw5-db"

# PubSub
export PUB_SUB_TOPIC="$GCP_PROJECT-hw5-pubsub-topic"
export PUB_SUB_SUBSCRIPTION="$GCP_PROJECT-hw5-pubsub-subscription"
