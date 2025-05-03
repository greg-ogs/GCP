#!/bin/bash

# Private service access creation
IP_RANGE_NAME="default-google-managed-services-range"
IP_RANGE_CIDR="10.100.0.0/24"
SERVICE_NETWORKING_API="servicenetworking.googleapis.com"
PROJECT_ID=$(gcloud config get-value project)
VPC_NAME="default"

# Allocate range of ip addresses
gcloud compute addresses create "$IP_RANGE_NAME" \
    --global \
    --project=$PROJECT_ID \
    --purpose=VPC_PEERING \
    --network="$VPC_NAME" \
    --prefix-length=${IP_RANGE_CIDR#*/} \
    --addresses=${IP_RANGE_CIDR%/*}

## Try to update PSA connection
#echo "Alert: Updating Private Services Access connection..."
#gcloud services vpc-peerings update \
#    --project=$PROJECT_ID \
#    --service=$SERVICE_NETWORKING_API \
#    --network="$VPC_NAME" \
#    --ranges="$IP_RANGE_NAME" \
#    --force

# Create Private Services Access connection
echo "Alert: Creating Private Services Access connection..."
gcloud services vpc-peerings connect \
    --project=$PROJECT_ID \
    --service=$SERVICE_NETWORKING_API \
    --ranges="$IP_RANGE_NAME" \
    --network="$VPC_NAME"