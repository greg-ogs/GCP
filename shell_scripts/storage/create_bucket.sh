#!/bin/bash

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <bucket_name> <local_file_path>"
    echo "  Example: $0 my-unique-gcs-bucket ./my_document.txt"
    exit 1
fi

BUCKET_NAME="$1"
BUCKET_URI="gs://$BUCKET_NAME"

gcloud storage buckets create BUCKET_NAME

if [ $? -ne 0 ]; then
    echo "Error: Failed to create bucket '$BUCKET_NAME'. It might already exist or there was another issue."
    # You might want to check if it already exists and proceed, or just exit.
    # For simplicity, we exit here.
    exit 1
fi

exit 0