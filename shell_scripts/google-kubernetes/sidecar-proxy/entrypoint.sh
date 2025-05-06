#!/bin/bash

export PROJECT_ID=gc-bootcamp-14dfb3bf

gcloud auth activate-service-account --key-file=/app/mnt/key.json

 gcloud config set project "${PROJECT_ID}"

# Start the Cloud SQL Proxy in the background.
# Use the INSTANCE_CONNECTION_NAME environment variable.
# The '&' sends it to the background.
export DB_USER=$(gcloud secrets versions access latest --secret="DB_USER" --project=$PROJECT_ID)
export DB_PASS=$(gcloud secrets versions access latest --secret="DB_PASS" --project=$PROJECT_ID)
export DB_NAME=$(gcloud secrets versions access latest --secret="DB_NAME" --project=$PROJECT_ID)
export INSTANCE_CONNECTION_NAME=$(gcloud secrets versions access latest --secret="INSTANCE_CONNECTION_NAME" --project=$PROJECT_ID)

echo "$(gcloud secrets versions access latest --secret="key" --project="$(gcloud config get-value project)")" > /app/key.json
export GOOGLE_APPLICATION_CREDENTIALS="/app/mnt/key.json"

# Activate the virtual environment
source /app/main/bin/activate
cd /app/python-docs-samples/cloud-sql/mysql/sqlalchemy

# Execute the command passed as arguments to this script (from CMD)
# 'exec' replaces the script process with the command, ensuring signals are handled correctly.
exec "$@"
