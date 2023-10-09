#!/bin/bash

gcloud functions deploy bucket_file_get \
--gen2 \
--runtime=python310 \
--region=us-east4 \
--source=. \
--entry-point=bucket_file_get \
--trigger-http \
--allow-unauthenticated \
--max-instances=10