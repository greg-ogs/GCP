#!/bin/bash

# Create custom VPC networks in GCP
# In this case 2 subnets will be created

VPC_NAME="cmtr-14dfb3bf-vpc"
# Subnet configurations

SUBNET1_NAME="first"
SUBNET1_REGION="us-central1"
SUBNET1_CIDR="10.1.0.0/24"

SUBNET2_NAME="second"
SUBNET2_REGION="us-east1"
SUBNET2_CIDR="10.2.0.0/24"

# 1. Create the network

echo "Creating network"
gcloud compute networks create "$VPC_NAME" \
    --project=$(gcloud config get-value project) \
    --subnet-mode=custom \
    --mtu=1460 \
    --bgp-routing-mode=regional

# 2. Create the first subnet
echo "Creating subnet '$SUBNET1_NAME' in region '$SUBNET1_REGION'..."
gcloud compute networks subnets create "$SUBNET1_NAME" \
    --project=$(gcloud config get-value project) \
    --network="$VPC_NAME" \
    --range="$SUBNET1_CIDR" \
    --region="$SUBNET1_REGION"

echo "Creating subnet '$SUBNET2_NAME' in region '$SUBNET2_REGION'..."
gcloud compute networks subnets create "$SUBNET2_NAME" \
    --project=$(gcloud config get-value project) \
    --network="$VPC_NAME" \
    --range="$SUBNET2_CIDR" \
    --region="$SUBNET2_REGION"

gcloud compute networks describe "$VPC_NAME" --project=$(gcloud config get-value project)

gcloud compute networks subnets describe "$SUBNET1_NAME" --region="$SUBNET1_REGION" --project=$(gcloud config get-value project)

gcloud compute networks subnets describe "$SUBNET2_NAME" --region="$SUBNET2_REGION" --project=$(gcloud config get-value project)
