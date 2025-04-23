#!/bin/bash

LOCAL_FILE_PATH="$1"
BUCKET_NAME="$2"
BUCKET_URI="gs://$BUCKET_NAME"

FILENAME="$LOCAL_FILE_PATH"

if [ ! -f "$LOCAL_FILE_PATH" ]; then
    echo "Error: Local file '$LOCAL_FILE_PATH' not found."
    exit 1
fi

gcloud storage cp "$LOCAL_FILE_PATH" "$BUCKET_URI"

if [ $? -ne 0 ]; then
    echo "Error: Failed to upload '$FILENAME' to '$BUCKET_URI'."
    # Consider attempting to delete the bucket if the upload fails? (Optional)
    # echo "Attempting to delete partially set up bucket $BUCKET_URI..."
    # gcloud storage buckets delete "$BUCKET_URI" --quiet
    exit 1
fi

echo "You can access it at: https://storage.cloud.google.com/$BUCKET_NAME/$FILENAME"
