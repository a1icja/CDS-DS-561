#!/bin/bash

# Project
export GCP_PROJECT="ds561-amahr"

# Link - Bucket
export LINK_FILES_BUCKET_NAME="gs://ds561-amahr-hw2"

# Web Server - Both
export WEB_SERVER_FILES_BUCKET_NAME="gs://ds561-amahr-hw8"
export WEB_SERVER_SA_NAME="$GCP_PROJECT-hw8-sa"
export WEB_SERVER_SA_EMAIL="$WEB_SERVER_SA_NAME@$GCP_PROJECT.iam.gserviceaccount.com"
export WEB_SERVER_VM_REGION="us-east4"
export WEB_SERVER_VM_DIR="/root/web-server"
export WEB_SERVER_VM_TIER="f1-micro"

# Web Server 1
export WEB_SERVER_1_VM_NAME="$GCP_PROJECT-hw8-vm1"
export WEB_SERVER_1_VM_ZONE=$WEB_SERVER_VM_REGION"-a"
export WEB_SERVER_1_VM_IP_NAME="$GCP_PROJECT-hw8-ip-vm1"
export WEB_SERVER_1_STARTUP_SCRIPT="scripts/vm1_startup.sh"

# Web Server 2
export WEB_SERVER_2_VM_NAME="$GCP_PROJECT-hw8-vm2"
export WEB_SERVER_2_VM_ZONE=$WEB_SERVER_VM_REGION"-c"
export WEB_SERVER_2_VM_IP_NAME="$GCP_PROJECT-hw8-ip-vm2"
export WEB_SERVER_2_STARTUP_SCRIPT="scripts/vm2_startup.sh"

# Load Balancer
export LOAD_BALANCER_NAME="$GCP_PROJECT-hw8-lb"
export LOAD_BALANCER_IP_NAME="$GCP_PROJECT-hw8-ip-lb"
export LOAD_BALANCER_HEALTH_CHECK_NAME="$GCP_PROJECT-hw8-hc"
export LOAD_BALANCER_TARGET_POOL_NAME="$GCP_PROJECT-hw8-tp"
export LOAD_BALANCER_FORWARDING_RULE_NAME="$GCP_PROJECT-hw8-fr"
