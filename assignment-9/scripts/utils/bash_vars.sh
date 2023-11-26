#!/bin/bash

# Project
export GCP_PROJECT="ds561-amahr"

# Link - Bucket
export LINK_FILES_BUCKET_NAME="gs://ds561-amahr-hw2"

# GCE Service Account
export GCE_SA_EMAIL=""

# HTTP Client - VM
export HTTP_CLIENT_VM_NAME="$GCP_PROJECT-hw9-stress-test-vm"
export HTTP_CLIENT_VM_REGION="us-east4"
export HTTP_CLIENT_VM_ZONE=$STRESS_TEST_VM_REGION"-c"
export HTTP_CLIENT_VM_TIER="n1-standard-1"

# PubSub
export PUB_SUB_TOPIC="$GCP_PROJECT-hw9-pubsub-topic"
export PUB_SUB_SUBSCRIPTION="$GCP_PROJECT-hw9-pubsub-subscription"

# PubSub Subscriber - VM
export PUB_SUB_SUBSCRIBER_VM_NAME="$GCP_PROJECT-hw9-sub-vm"
export PUB_SUB_SUBSCRIBER_VM_REGION="us-east4"
export PUB_SUB_SUBSCRIBER_VM_ZONE=$PUB_SUB_SUBSCRIBER_VM_REGION"-c"
export PUB_SUB_SUBSCRIBER_VM_TIER="f1-micro"

# Container Repository
export CONTAINER_REPOSITORY_NAME="$GCP_PROJECT-hw9-repo"
export CONTAINER_REPOSITORY_REGION="us-central1"

# Container Cluster
export CONTAINER_CLUSTER_NAME="$GCP_PROJECT-hw9-cluster"
export CONTAINER_CLUSTER_REGION="us-east4"

# Container Deployment
export CONTAINER_DEPLOYMENT_NAME="$GCP_PROJECT-hw9-deployment"
