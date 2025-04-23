#!/bin/bash
# Bucket_viewer
# --- Configuration ---

SERVICE_ACCOUNT_ID="$1"
DISPLAY_NAME="$SERVICE_ACCOUNT_ID"
DESCRIPTION="Service account for VM"
PROJECT_ID=$(gcloud config get-value project) # Gets the currently configured project ID

# Check if PROJECT_ID is set
if [ -z "$PROJECT_ID" ]; then
  echo "Error: Google Cloud project ID not set."
  echo "Please configure your project using 'gcloud config set project YOUR_PROJECT_ID'"
  exit 1
fi

echo "Creating service account '$SERVICE_ACCOUNT_ID' in project '$PROJECT_ID'..."

# --- Service Account Command ---
gcloud iam service-accounts create "$SERVICE_ACCOUNT_ID" \
  --project="$PROJECT_ID" \
  --display-name="$DISPLAY_NAME" \
  --description="$DESCRIPTION"

# --- Verification ---
# Check if the command was successful
if [ $? -eq 0 ]; then
  echo "------------------------------------------------------"
  echo "Service Account created successfully!"
  EMAIL="${SERVICE_ACCOUNT_ID}@${PROJECT_ID}.iam.gserviceaccount.com"

  # Grant Logging Writer
  gcloud projects add-iam-policy-binding $PROJECT_ID \
      --member="serviceAccount:$EMAIL" \
      --role="roles/logging.logWriter"

  # Grant Monitoring Metric Writer
  gcloud projects add-iam-policy-binding $PROJECT_ID \
      --member="serviceAccount:$EMAIL" \
      --role="roles/monitoring.metricWriter"

  # Grant Service Usage Consumer (often needed for API access)
  gcloud projects add-iam-policy-binding $PROJECT_ID \
      --member="serviceAccount:$EMAIL" \
      --role="roles/serviceusage.serviceUsageConsumer"

  # (Optional) Grant Error Reporting Writer
  gcloud projects add-iam-policy-binding $PROJECT_ID \
      --member="serviceAccount:$EMAIL" \
      --role="roles/errorreporting.writer"

  echo "Full Email: $EMAIL"
  echo "Display Name: $DISPLAY_NAME"
else
  echo "Error: Failed to create service account '$SERVICE_ACCOUNT_ID'."
  exit 1
fi

exit 0

# echo "Grant necessary IAM roles/permissions to this service account:"

# echo "Optionally, create and download a key file if needed for authentication outside GCP:"
# gcloud iam service-accounts keys create ./${SERVICE_ACCOUNT_ID}-key.json --iam-account=\"${SERVICE_ACCOUNT_ID}@${PROJECT_ID}.iam.gserviceaccount.com\""