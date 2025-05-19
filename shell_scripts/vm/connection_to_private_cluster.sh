#!/bin/bash

# Script to create a VM instance called "connection_to_private_cluster"
# This VM will be placed in the "testings" network and will have permissions
# to communicate with the private GKE cluster and run workload_identity_alchemy.sh

# Define variables
PROJECT_ID=$(gcloud config get-value project)
VM_NAME="connection-to-private-cluster"
ZONE="us-central1-a"  # Same zone as the cluster
MACHINE_TYPE="e2-medium"
VPC_NAME="testings"  # Same VPC as the cluster
SUBNET_NAME="gke-subnet"  # Same subnet as the cluster
CLUSTER_NAME="private-cluster"
SERVICE_ACCOUNT_NAME="vm-cluster-admin"
SERVICE_ACCOUNT_EMAIL=""${SERVICE_ACCOUNT_NAME}"@"${PROJECT_ID}".iam.gserviceaccount.com"
SSH_KEY="${USER}":"${KEY}"

# 1. Create a service account for the VM with necessary permissions
echo "Creating service account '${SERVICE_ACCOUNT_NAME}'..."
gcloud iam service-accounts create "${SERVICE_ACCOUNT_NAME}" \
    --project="${PROJECT_ID}" \
    --display-name="VM Cluster Admin Service Account" \
    --description="Service account for VM to access private GKE cluster"

# 2. Grant necessary roles to the service account
echo "Granting necessary roles to service account..."
# GKE admin role for cluster access
gcloud projects add-iam-policy-binding "${PROJECT_ID}" \
    --member="serviceAccount:${SERVICE_ACCOUNT_EMAIL}" \
    --role="roles/container.admin"

# IAM admin role for modifying service account bindings
gcloud projects add-iam-policy-binding "${PROJECT_ID}" \
    --member="serviceAccount:${SERVICE_ACCOUNT_EMAIL}" \
    --role="roles/iam.serviceAccountAdmin"

# Security admin role for IAM policy bindings
gcloud projects add-iam-policy-binding "${PROJECT_ID}" \
    --member="serviceAccount:${SERVICE_ACCOUNT_EMAIL}" \
    --role="roles/iam.securityAdmin"

# 3. Create the VM instance
echo "Creating VM instance '${VM_NAME}'..."
gcloud compute instances create "${VM_NAME}" \
    --project="${PROJECT_ID}" \
    --zone="${ZONE}" \
    --machine-type="${MACHINE_TYPE}" \
    --network-interface=network="${VPC_NAME}",subnet="${SUBNET_NAME}" \
    --maintenance-policy=MIGRATE \
    --provisioning-model=STANDARD \
    --service-account="${SERVICE_ACCOUNT_EMAIL}" \
    --scopes="https://www.googleapis.com/auth/cloud-platform" \
    --create-disk=auto-delete=yes,boot=yes,device-name="${VM_NAME}",image=projects/debian-cloud/global/images/family/debian-12,mode=rw,size=10 \
    --no-shielded-secure-boot \
    --shielded-vtpm \
    --shielded-integrity-monitoring \
    --metadata=ssh-keys="${SSH_KEY}"
