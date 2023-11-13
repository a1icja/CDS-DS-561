#!/bin/bash

# Get current timestamp
start=$(date +%s)

python3 main.py \
    --region="us-east4" \
    --input="gs://ds561-amahr-hw2/files/*.html" \
    --output="gs://ds561-amahr-hw7/results.txt" \
    --runner="DirectRunner" \
    --project="ds561-amahr" \
    --temp_location="gs://ds561-amahr-hw7/tmp/"

# Get current timestamp
end=$(date +%s)

# Print time taken
echo "Time taken to run the script: $((end - start)) seconds"
