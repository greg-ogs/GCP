#!/bin/bash

# Define variables
REGISTRY_NAME="registry"
LOCATION="us-central1"  # Default region, can be changed as needed
PROJECT_ID=$(gcloud config get-value project)

echo "Creating Docker registry '${REGISTRY_NAME}' in project '${PROJECT_ID}' at location '${LOCATION}'..."

# Create the Docker registry using Artifact Registry
gcloud artifacts repositories create "${REGISTRY_NAME}" \
    --project="${PROJECT_ID}" \
    --repository-format=docker \
    --location="${LOCATION}" \
    --description="Docker registry for custom EPAM workload images"

# Check if the command was successful
if [ $? -ne 0 ]; then
    echo "Error: Failed to create Docker registry '${REGISTRY_NAME}'. It might already exist or there was another issue."
    exit 1
fi

echo "Docker registry '${REGISTRY_NAME}' created successfully."
echo "You can push images to this registry using: docker push ${LOCATION}-docker.pkg.dev/${PROJECT_ID}/${REGISTRY_NAME}/[IMAGE_NAME]"

# Log the registry details
echo "Docker registry '${REGISTRY_NAME}' created in project '${PROJECT_ID}' at $(date)" >> logs.txt

exit 0
