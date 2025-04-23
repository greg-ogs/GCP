#!/bin/bash

# Resources list can be find in: https://cloud.google.com/iam/docs/full-resource-names

PROJECT_ID='$1'
SA_EMAIL='$2'
ROLE='$3'

# Check if ROLE variable is set
if [ -z "$ROLE" ]; then
  echo "Error: ROLE environment variable is not set."
  exit 1
fi

# Check if PROJECT_ID variable is set
if [ -z "$PROJECT_ID" ]; then
  echo "Error: PROJECT_ID environment variable is not set."
  exit 1
fi

if [ -z "$SA_EMAIL" ]; then
  echo "Error: SA_EMAIL environment variable is not set."
  exit 1
fi

# Resource for service accounts
RESOURCE="//iam.googleapis.com/projects/$PROJECT_ID/serviceAccounts/$SA_EMAIL"

if gcloud iam roles list --quiet | grep -q "$ROLE" && \
   gcloud iam list-grantable-roles "$RESOURCE" --quiet | grep -q "$ROLE"; then
   gcloud iam roles list --quiet | grep "$ROLE"
fi
