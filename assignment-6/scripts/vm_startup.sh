#!/bin/bash

CSV_BUCKET_NAME="gs://ds561-amahr-hw6"
SCRIPT_VM_DIR="/root/script"

# Check if the script directory exists
if [ ! -d "$SCRIPT_VM_DIR" ]; then
  # Create the script directory
  mkdir "$SCRIPT_VM_DIR"
  echo "Create the script directory: $?"

  # Download the script files from the GCP bucket
  gsutil cp "$CSV_BUCKET_NAME/*" "$SCRIPT_VM_DIR"
  echo "Download the script files from the GCP bucket: $?"

  # Install Pip
  apt-get update -y
  apt-get install --no-install-recommends -y python3-pip
  echo "Install Pip: $?"

  # Install the script dependencies
  python3 -m pip install -r "$SCRIPT_VM_DIR/requirements.txt"
  echo "Install the script dependencies: $?"
fi

# cd into the script directory
cd "$SCRIPT_VM_DIR"

# Start the script
echo "Running the model scripts..."
python3 main.py
