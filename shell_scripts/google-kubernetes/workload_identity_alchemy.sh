#!/bin/bash

# Script to create a Kubernetes service account named "alchemy" and connect it with 
# the Google Cloud service account "alchemy-gc-sa" using Workload Identity

# Define variables
PROJECT_ID=$(gcloud config get-value project)
CLUSTER_NAME="private-cluster"  # Same as in google_kubernetes_cluster.sh
REGION="us-central1"            # Same as in google_kubernetes_cluster.sh
ZONE="${REGION}-a"              # Same as in google_kubernetes_cluster.sh
K8S_NAMESPACE="default"         # Using default namespace
K8S_SA_NAME="alchemy"           # Kubernetes service account name
GCP_SA_NAME="alchemy-gc-sa"     # Google Cloud service account name
GCP_SA_EMAIL="${GCP_SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"

# Ensure we're connected to the cluster
echo "Configuring kubectl to connect to cluster '${CLUSTER_NAME}'..."
gcloud container clusters get-credentials "${CLUSTER_NAME}" \
    --project="${PROJECT_ID}" \
    --zone="${ZONE}"

# 1. Create the Kubernetes service account
echo "Creating Kubernetes service account '${K8S_SA_NAME}'..."
kubectl create serviceaccount "${K8S_SA_NAME}" \
    --namespace="${K8S_NAMESPACE}"

# 2. Annotate the Kubernetes service account to use the Google Cloud service account
echo "Annotating Kubernetes service account to use Google Cloud service account..."
kubectl annotate serviceaccount "${K8S_SA_NAME}" \
    --namespace="${K8S_NAMESPACE}" \
    iam.gke.io/gcp-service-account="${GCP_SA_EMAIL}"

# 3. Add IAM policy binding to allow the Kubernetes service account to act as the Google Cloud service account
echo "Adding IAM policy binding to allow Kubernetes service account to act as Google Cloud service account..."
gcloud iam service-accounts add-iam-policy-binding "${GCP_SA_EMAIL}" \
    --project="${PROJECT_ID}" \
    --role="roles/iam.workloadIdentityUser" \
    --member="serviceAccount:${PROJECT_ID}.svc.id.goog[${K8S_NAMESPACE}/${K8S_SA_NAME}]"

# 4. Verify the configuration
echo "Verifying Kubernetes service account configuration..."
kubectl describe serviceaccount "${K8S_SA_NAME}" \
    --namespace="${K8S_NAMESPACE}"

echo "Workload Identity configuration completed successfully!"
echo "The Kubernetes service account '${K8S_SA_NAME}' is now connected to the Google Cloud service account '${GCP_SA_EMAIL}'."
echo "Pods using the '${K8S_SA_NAME}' service account will now have the permissions of the '${GCP_SA_EMAIL}' service account."

# Example usage in a Pod:
echo ""
echo "Example Pod YAML to use this service account:"
echo "---"
echo "apiVersion: v1"
echo "kind: Pod"
echo "metadata:"
echo "  name: example-pod"
echo "spec:"
echo "  serviceAccountName: ${K8S_SA_NAME}"
echo "  containers:"
echo "  - name: main-container"
echo "    image: gcr.io/google.com/cloudsdktool/cloud-sdk:slim"
echo "    command: ['sleep', '3600']"
echo "---"