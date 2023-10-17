#!/bin/bash

# Project
export GCP_PROJECT="ds561-amahr"

# Link - Bucket
export LINK_FILES_BUCKET_NAME="gs://ds561-amahr-hw2"

# Web Server - Bucket, Service Account, VM
export WEB_SERVER_FILES_BUCKET_NAME="gs://ds561-amahr-hw4"
export WEB_SERVER_SA_NAME="$GCP_PROJECT-hw4-sa"
export WEB_SERVER_SA_EMAIL="$WEB_SERVER_SA_NAME@$GCP_PROJECT.iam.gserviceaccount.com"
export WEB_SERVER_VM_NAME="$GCP_PROJECT-hw4-vm1"
export WEB_SERVER_VM_REGION="us-east4"
export WEB_SERVER_VM_ZONE=$WEB_SERVER_VM_REGION"-c"
export WEB_SERVER_VM_IP_NAME="$GCP_PROJECT-hw4-ip"
export WEB_SERVER_VM_DIR="/root/web-server"
export WEB_SERVER_VM_TIER="f1-micro"

# PubSub
export PUB_SUB_TOPIC="$GCP_PROJECT-hw4-pubsub-topic"
export PUB_SUB_SUBSCRIPTION="$GCP_PROJECT-hw4-pubsub-subscription"

# PubSub Subscriber - VM
export PUB_SUB_SUBSCRIBER_VM_NAME="$GCP_PROJECT-hw4-vm3"
export PUB_SUB_SUBSCRIBER_VM_REGION="us-east4"
export PUB_SUB_SUBSCRIBER_VM_ZONE=$PUB_SUB_SUBSCRIBER_VM_REGION"-c"
export PUB_SUB_SUBSCRIBER_VM_TIER="f1-micro"

# Stress Test - VM
export STRESS_TEST_VM_NAME="$GCP_PROJECT-hw4-vm2"
export STRESS_TEST_VM_REGION="us-east4"
export STRESS_TEST_VM_ZONE=$PUB_SUB_SUBSCRIBER_VM_REGION"-c"
export STRESS_TEST_VM_TIER="n1-standard-1"
