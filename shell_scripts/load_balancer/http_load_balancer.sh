#!/bin/bash

# Script to create an HTTP Load Balancer with a reserved static IP address
# that routes /nginx requests to nginx MIG and all others to alchemy MIG

# Define variables
PROJECT_ID=$(gcloud config get-value project)
REGION_NGINX="us-central1"
ZONE_NGINX="us-central1-a"
REGION_ALCHEMY="us-west1"
ZONE_ALCHEMY="us-west1-a"
HEALTH_CHECK_NAME="common"
STATIC_IP_NAME="lb-ip"
BACKEND_SERVICE_NGINX="nginx-backend"
BACKEND_SERVICE_ALCHEMY="alchemy-backend"
URL_MAP_NAME="lb"
HTTP_PROXY_NAME="lb"
FORWARDING_RULE_NAME="http-lb-forwarding-rule"
NGINX_MIG_NAME="nginx"
ALCHEMY_MIG_NAME="alchemy"

# Reserve a static IP address
echo "Reserving a static IP address..."
gcloud compute addresses create ${STATIC_IP_NAME} \
    --project=${PROJECT_ID} \
    --global

# Get the reserved IP address
STATIC_IP=$(gcloud compute addresses describe ${STATIC_IP_NAME} \
    --project=${PROJECT_ID} \
    --global \
    --format="get(address)")

echo "Reserved static IP address: ${STATIC_IP}"

# Create backend service for nginx MIG
echo "Creating backend service for nginx MIG..."
gcloud compute backend-services create ${BACKEND_SERVICE_NGINX} \
    --project=${PROJECT_ID} \
    --protocol=HTTP \
    --port-name=http \
    --health-checks=${HEALTH_CHECK_NAME} \
    --global

# Check if nginx MIG is regional or zonal
echo "Checking if nginx MIG is regional or zonal..."
NGINX_MIG_REGIONAL=$(gcloud compute instance-groups managed list \
    --project=${PROJECT_ID} \
    --filter="name=${NGINX_MIG_NAME} AND region:*" \
    --format="get(name)" 2>/dev/null)

# Add nginx MIG as a backend to the nginx backend service
echo "Adding nginx MIG as a backend to the nginx backend service..."
if [ -n "${NGINX_MIG_REGIONAL}" ]; then
    # Regional MIG
    echo "Nginx MIG is regional. Adding as regional backend..."
    gcloud compute backend-services add-backend ${BACKEND_SERVICE_NGINX} \
        --project=${PROJECT_ID} \
        --instance-group=${NGINX_MIG_NAME} \
        --instance-group-region=${REGION_NGINX} \
        --global
else
    # Zonal MIG
    echo "Nginx MIG is zonal. Adding as zonal backend..."
    gcloud compute backend-services add-backend ${BACKEND_SERVICE_NGINX} \
        --project=${PROJECT_ID} \
        --instance-group=${NGINX_MIG_NAME} \
        --instance-group-zone=${ZONE_NGINX} \
        --global
fi

# Create backend service for alchemy MIG
echo "Creating backend service for alchemy MIG..."
gcloud compute backend-services create ${BACKEND_SERVICE_ALCHEMY} \
    --project=${PROJECT_ID} \
    --protocol=HTTP \
    --port-name=http \
    --health-checks=${HEALTH_CHECK_NAME} \
    --global

# Check if alchemy MIG is regional or zonal
echo "Checking if alchemy MIG is regional or zonal..."
ALCHEMY_MIG_REGIONAL=$(gcloud compute instance-groups managed list \
    --project=${PROJECT_ID} \
    --filter="name=${ALCHEMY_MIG_NAME} AND region:*" \
    --format="get(name)" 2>/dev/null)

# Add alchemy MIG as a backend to the alchemy backend service
echo "Adding alchemy MIG as a backend to the alchemy backend service..."
if [ -n "${ALCHEMY_MIG_REGIONAL}" ]; then
    # Regional MIG
    echo "Alchemy MIG is regional. Adding as regional backend..."
    gcloud compute backend-services add-backend ${BACKEND_SERVICE_ALCHEMY} \
        --project=${PROJECT_ID} \
        --instance-group=${ALCHEMY_MIG_NAME} \
        --instance-group-region=${REGION_ALCHEMY} \
        --global
else
    # Zonal MIG
    echo "Alchemy MIG is zonal. Adding as zonal backend..."
    gcloud compute backend-services add-backend ${BACKEND_SERVICE_ALCHEMY} \
        --project=${PROJECT_ID} \
        --instance-group=${ALCHEMY_MIG_NAME} \
        --instance-group-zone=${ZONE_ALCHEMY} \
        --global
fi

# Create URL map for path-based routing
echo "Creating URL map for path-based routing..."
gcloud compute url-maps create ${URL_MAP_NAME} \
    --project=${PROJECT_ID} \
    --default-service=${BACKEND_SERVICE_ALCHEMY} \
    --global

# Add path matcher to route /nginx requests to nginx backend
echo "Adding path matcher to route /nginx requests to nginx backend..."
gcloud compute url-maps add-path-matcher ${URL_MAP_NAME} \
    --project=${PROJECT_ID} \
    --path-matcher-name=nginx-path-matcher \
    --default-service=${BACKEND_SERVICE_ALCHEMY} \
    --path-rules="/nginx=projects/${PROJECT_ID}/global/backendServices/${BACKEND_SERVICE_NGINX}" \
    --global

# Create HTTP proxy
echo "Creating HTTP proxy..."
gcloud compute target-http-proxies create ${HTTP_PROXY_NAME} \
    --project=${PROJECT_ID} \
    --url-map=${URL_MAP_NAME} \
    --global

# Create forwarding rule with the static IP
echo "Creating forwarding rule with the static IP..."
gcloud compute forwarding-rules create ${FORWARDING_RULE_NAME} \
    --project=${PROJECT_ID} \
    --load-balancing-scheme=EXTERNAL \
    --network-tier=PREMIUM \
    --address=${STATIC_IP_NAME} \
    --global \
    --target-http-proxy=${HTTP_PROXY_NAME} \
    --ports=80

echo "HTTP Load Balancer setup complete!"
echo "Static IP address: ${STATIC_IP}"
echo "Requests to http://${STATIC_IP}/nginx will be routed to the nginx MIG"
echo "All other requests will be routed to the alchemy MIG"
