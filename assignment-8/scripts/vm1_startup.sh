#!/bin/bash

WEB_SERVER_GCP_BUCKET="gs://ds561-amahr-hw8"
WEB_SERVER_VM_DIR="/root/web-server"
ZONE="us-east4-a"

# Check if the web server directory exists
if [ ! -d "$WEB_SERVER_VM_DIR" ]; then
  # Create the web server directory
  mkdir "$WEB_SERVER_VM_DIR"
  echo "Create the web server directory: $?"

  # Download the web server files from the GCP bucket
  gsutil cp "$WEB_SERVER_GCP_BUCKET/*" "$WEB_SERVER_VM_DIR"
  echo "Download the web server files from the GCP bucket: $?"

  # Install Pip
  apt-get update -y
  apt-get install --no-install-recommends -y python3-pip
  echo "Install Pip: $?"

  # Install the web server dependencies
  python3 -m pip install -r "$WEB_SERVER_VM_DIR/requirements.txt"
  echo "Install the web server dependencies: $?"
fi

# cd into the web server directory
cd "$WEB_SERVER_VM_DIR"

# Start the web server
echo "Starting the web server..."
ZONE="$ZONE" python3 main.py
