#!/bin/bash

# Script to create a service account named "alchemy-gc-sa" with access to:
# - Docker registry (Artifact Registry)
# - GCS buckets
# - SQL instance

# Define variables
SERVICE_ACCOUNT_ID="alchemy-gc-sa"
DISPLAY_NAME="Alchemy GCP Service Account"
DESCRIPTION="Service account for accessing registry, buckets, and SQL instance"
PROJECT_ID=$(gcloud config get-value project) # Gets the currently configured project ID

# Create the service account
gcloud iam service-accounts create "$SERVICE_ACCOUNT_ID" \
  --project="$PROJECT_ID" \
  --display-name="$DISPLAY_NAME" \
  --description="$DESCRIPTION"

# Check if the command was successful
if [ $? -eq 0 ]; then
  echo "------------------------------------------------------"
  echo "Service Account created successfully!"
  EMAIL="${SERVICE_ACCOUNT_ID}@${PROJECT_ID}.iam.gserviceaccount.com"
  
  echo "Granting necessary IAM roles for registry, buckets, and SQL instance access..."
  
  # Grant Artifact Registry access
  echo "Granting Artifact Registry access..."
  gcloud projects add-iam-policy-binding $PROJECT_ID \
      --member="serviceAccount:$EMAIL" \
      --role="roles/artifactregistry.reader"
  
  gcloud projects add-iam-policy-binding $PROJECT_ID \
      --member="serviceAccount:$EMAIL" \
      --role="roles/artifactregistry.writer"
  
  # Grant Storage (Buckets) access
  echo "Granting Storage access..."
  gcloud projects add-iam-policy-binding $PROJECT_ID \
      --member="serviceAccount:$EMAIL" \
      --role="roles/storage.objectViewer"
  
  gcloud projects add-iam-policy-binding $PROJECT_ID \
      --member="serviceAccount:$EMAIL" \
      --role="roles/storage.objectCreator"
  
  # Grant Cloud SQL access
  echo "Granting Cloud SQL access..."
  gcloud projects add-iam-policy-binding $PROJECT_ID \
      --member="serviceAccount:$EMAIL" \
      --role="roles/cloudsql.client"
  
  # Grant basic logging and monitoring roles (optional but recommended)
  echo "Granting basic logging and monitoring roles..."
  gcloud projects add-iam-policy-binding $PROJECT_ID \
      --member="serviceAccount:$EMAIL" \
      --role="roles/logging.logWriter"
  
  gcloud projects add-iam-policy-binding $PROJECT_ID \
      --member="serviceAccount:$EMAIL" \
      --role="roles/monitoring.metricWriter"
  
  echo "------------------------------------------------------"
  echo "Service account '$SERVICE_ACCOUNT_ID' has been created with the following details:"
  echo "Email: $EMAIL"
  echo "Display Name: $DISPLAY_NAME"
  echo "Description: $DESCRIPTION"
  echo "Roles granted:"
  echo "  - roles/artifactregistry.reader"
  echo "  - roles/artifactregistry.writer"
  echo "  - roles/storage.objectViewer"
  echo "  - roles/storage.objectCreator"
  echo "  - roles/cloudsql.client"
  echo "  - roles/logging.logWriter"
  echo "  - roles/monitoring.metricWriter"
  echo "------------------------------------------------------"
  
  # Log the service account creation
  echo "Service account '$SERVICE_ACCOUNT_ID' created in project '$PROJECT_ID' at $(date)"
else
  echo "Error: Failed to create service account '$SERVICE_ACCOUNT_ID'."
  exit 1
fi

exit 0