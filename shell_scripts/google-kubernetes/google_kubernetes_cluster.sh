#!/bin/bash

# Google Kubernetes Engine (GKE) cluster creation script
# This script creates a private GKE cluster with the following specifications:
# - Standard zonal cluster in US region
# - 1 node with e2-medium machine type
# - Networking: Uses existing "testings" VPC network with new subnet and secondary ranges for pods and services
# - Cloud NAT configured for VPC
# - Workload Identity enabled
# - Autoscaling disabled

# Define variables
PROJECT_ID=$(gcloud config get-value project)
CLUSTER_NAME="private-cluster"
REGION="us-central1"
ZONE="${REGION}-a"
MACHINE_TYPE="e2-medium"
NODE_COUNT=1

# VPC Network settings
VPC_NAME="testings"
SUBNET_NAME="gke-subnet"
SUBNET_CIDR="10.10.0.0/24"
PODS_CIDR="10.20.0.0/16"
SERVICES_CIDR="10.30.0.0/16"
ROUTER_NAME="gke-nat-router"
NAT_CONFIG_NAME="gke-nat-config"

# 1. Create subnet in the existing VPC with secondary ranges for pods and services
echo "Creating subnet '${SUBNET_NAME}' in VPC '${VPC_NAME}'..."
gcloud compute networks subnets create "${SUBNET_NAME}" \
    --project="${PROJECT_ID}" \
    --network="${VPC_NAME}" \
    --region="${REGION}" \
    --range="${SUBNET_CIDR}" \
    --secondary-range="pods=${PODS_CIDR},services=${SERVICES_CIDR}"

# 2. Create Cloud Router for NAT
echo "Creating Cloud Router '${ROUTER_NAME}'..."
gcloud compute routers create "${ROUTER_NAME}" \
    --project="${PROJECT_ID}" \
    --network="${VPC_NAME}" \
    --region="${REGION}"

# 3. Configure Cloud NAT
echo "Configuring Cloud NAT '${NAT_CONFIG_NAME}'..."
gcloud compute routers nats create "${NAT_CONFIG_NAME}" \
    --project="${PROJECT_ID}" \
    --router="${ROUTER_NAME}" \
    --region="${REGION}" \
    --nat-all-subnet-ip-ranges \
    --auto-allocate-nat-external-ips

# 4. Create firewall rule to allow internal communication between nodes
FW_RULE_NAME="testings-allow-internal-cluster-communication"
echo "Creating firewall rule '${FW_RULE_NAME}' to allow communication between nodes..."
gcloud compute firewall-rules create "${FW_RULE_NAME}" \
    --project="${PROJECT_ID}" \
    --network="${VPC_NAME}" \
    --direction=INGRESS \
    --priority=1000 \
    --action=ALLOW \
    --rules=all \
    --source-ranges="${SUBNET_CIDR},${PODS_CIDR},${SERVICES_CIDR}" \
    --description="Allow all internal traffic within the cluster subnet and secondary ranges"

# 5. Create the private GKE cluster
echo "Creating private GKE cluster '${CLUSTER_NAME}'..."
gcloud container clusters create "${CLUSTER_NAME}" \
    --project="${PROJECT_ID}" \
    --zone="${ZONE}" \
    --machine-type="${MACHINE_TYPE}" \
    --num-nodes="${NODE_COUNT}" \
    --network="${VPC_NAME}" \
    --subnetwork="${SUBNET_NAME}" \
    --enable-private-nodes \
    --enable-private-endpoint \
    --master-ipv4-cidr="172.16.0.0/28" \
    --enable-ip-alias \
    --cluster-secondary-range-name="pods" \
    --services-secondary-range-name="services" \
    --enable-master-authorized-networks \
    --workload-pool="${PROJECT_ID}.svc.id.goog" \
    --no-enable-autoscaling

# 6. Verify cluster creation
echo "Verifying cluster creation..."
gcloud container clusters describe "${CLUSTER_NAME}" \
    --project="${PROJECT_ID}" \
    --zone="${ZONE}" \
    --format="value(status)"

# 7. Create additional node pool for SQL
echo "Creating additional 'sql' node pool..."
gcloud container node-pools create "sql" \
    --project="${PROJECT_ID}" \
    --cluster="${CLUSTER_NAME}" \
    --zone="${ZONE}" \
    --machine-type="${MACHINE_TYPE}" \
    --num-nodes="${NODE_COUNT}" \
    --no-enable-autoscaling

# 8. Verify node pool creation
echo "Verifying node pool creation..."
gcloud container node-pools describe "sql" \
    --project="${PROJECT_ID}" \
    --cluster="${CLUSTER_NAME}" \
    --zone="${ZONE}" \
    --format="value(status)"

#echo "GKE cluster creation completed with additional 'sql' node pool and internal communication enabled between nodes."
