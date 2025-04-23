#!/bin/bash

VPC_NAME="cmtr-14dfb3bf-vpc"

SSH_KEY="${USER}":"${KEY}"

#DEFAULT_SA in the env

# Subnet configurations
SUBNET1_NAME="first"
SUBNET1_REGION="us-central1"
SUBNET1_CIDR="10.1.0.0/24"

SUBNET2_NAME="second"
SUBNET2_REGION="us-east1"
SUBNET2_CIDR="10.2.0.0/24"

# VM configurations
VM1_NAME="cmtr-14dfb3bf-vps-01"
VM2_NAME="cmtr-14dfb3bf-vps-02"
VM3_NAME="cmtr-14dfb3bf-vps-03"

VM1_ZONE="us-central1-c" # Zone for the default network VM
VM2_ZONE="us-central1-c"
VM3_ZONE="us-east1-c"

# Create the VPC network

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

# Fw rule to allow http ingress traffic

gcloud compute firewall-rules create "allow-http-to-all" \
        --network=default \
        --direction=INGRESS \
        --priority=1000 \
        --action=ALLOW \
        --rules=tcp:80 \
        --source-ranges="0.0.0.0/0" \
        --description="Allow HTTP ingress traffic from anywhere to all instances in default"

# Create peering bidirectional

PEERING_NAME1="peer-cmtr-to-default"
PEERING_NAME2="peer-default-to-cmtr"
NET_1="cmtr-14dfb3bf-vpc"
NET_2="default"

gcloud compute networks peerings create "${PEERING_NAME1}" \
    --network="${NET_1}" \
    --peer-network="${NET_2}" \
    --stack-type=IPV4_ONLY

gcloud compute networks peerings create "${PEERING_NAME2}" \
    --network="${NET_2}" \
    --peer-network="${NET_1}" \
    --stack-type=IPV4_ONLY
#    --peer-project=[NET_1_VPC_PROJECT_ID] \
#    --project=[NET_2_VPC_PROJECT_ID]

# Confirm peer
gcloud compute networks peerings list \
    --network=default

echo "Creating VM 1"
gcloud compute instances create "${VM1_NAME}" \
    --project=$(gcloud config get-value project) \
    --zone="${VM1_ZONE}" \
    --machine-type=n1-standard-1 \
    --network-interface=network=default,network-tier=PREMIUM,stack-type=IPV4_ONLY \
    --maintenance-policy=MIGRATE \
    --provisioning-model=STANDARD \
    --service-account="${DEFAULT_SA}" \
    --tags=http-server \
    --create-disk=auto-delete=yes,boot=yes,device-name="${VM1_NAME}",image=projects/debian-cloud/global/images/debian-12-bookworm-v20250415,mode=rw,size=10 \
    --reservation-affinity=any \
    --no-shielded-secure-boot \
    --shielded-vtpm \
    --shielded-integrity-monitoring \
    --metadata=ssh-keys="${SSH_KEY}",startup-script='#! /bin/bash
    sudo apt update
    sudo apt install nginx -y
    systemctl start nginx
    systemctl enable nginx
    nginx -v
    echo "Nginx installation and startup complete."
    NGINX_DEFAULT_PAGE="/var/www/html/index.nginx-debian.html"
    TEXT_TO_APPEND="<p>This is the instance cmtr-14dfb3bf-vps-01</p>"
    echo "$TEXT_TO_APPEND" >> "$NGINX_DEFAULT_PAGE"
    '

gcloud compute instances add-metadata $VM1_NAME --metadata serial-port-logging-enable=TRUE

echo "Creating VM 2"
gcloud compute instances create "${VM2_NAME}" \
    --project=$(gcloud config get-value project) \
    --zone="${VM2_ZONE}" \
    --machine-type=n1-standard-1 \
    --network-interface=network-tier=PREMIUM,stack-type=IPV4_ONLY,network="${VPC_NAME}",subnet="${SUBNET1_NAME}" \
    --maintenance-policy=MIGRATE \
    --provisioning-model=STANDARD \
    --service-account="${DEFAULT_SA}" \
    --tags=http-server,server \
    --create-disk=auto-delete=yes,boot=yes,device-name="${VM2_NAME}",image=projects/debian-cloud/global/images/debian-12-bookworm-v20250415,mode=rw,size=10 \
    --reservation-affinity=any \
    --no-shielded-secure-boot \
    --shielded-vtpm \
    --shielded-integrity-monitoring \
    --metadata=ssh-keys="${SSH_KEY}",startup-script='#! /bin/bash
    sudo apt update
    sudo apt install nginx -y
    systemctl start nginx
    systemctl enable nginx
    nginx -v
    echo "Nginx installation and startup complete."
    NGINX_DEFAULT_PAGE="/var/www/html/index.nginx-debian.html"
    TEXT_TO_APPEND="<p>This is the instance cmtr-14dfb3bf-vps-02</p>"
    echo "$TEXT_TO_APPEND" >> "$NGINX_DEFAULT_PAGE"
    '

gcloud compute instances add-metadata $VM2_NAME --metadata serial-port-logging-enable=TRUE

echo "Creating VM3"
gcloud compute instances create "${VM3_NAME}" \
    --project=$(gcloud config get-value project) \
    --zone="${VM3_ZONE}" \
    --machine-type=n1-standard-1 \
    --network-interface=network-tier=PREMIUM,stack-type=IPV4_ONLY,network="${VPC_NAME}",subnet="${SUBNET2_NAME}" \
    --maintenance-policy=MIGRATE \
    --provisioning-model=STANDARD \
    --service-account="${DEFAULT_SA}" \
    --create-disk=auto-delete=yes,boot=yes,device-name="${VM3_NAME}",image=projects/debian-cloud/global/images/debian-12-bookworm-v20250415,mode=rw,size=10 \
    --reservation-affinity=any \
    --no-shielded-secure-boot \
    --shielded-vtpm \
    --shielded-integrity-monitoring \
    --metadata=ssh-keys="${SSH_KEY}",startup-script='#! /bin/bash
    sudo apt update
    sudo apt install nginx -y
    systemctl start nginx
    systemctl enable nginx
    nginx -v
    echo "Nginx installation and startup complete."
    NGINX_DEFAULT_PAGE="/var/www/html/index.nginx-debian.html"
    TEXT_TO_APPEND="<p>This is the instance cmtr-14dfb3bf-vps-03</p>"
    echo "$TEXT_TO_APPEND" >> "$NGINX_DEFAULT_PAGE"
    '

gcloud compute instances add-metadata $VM3_NAME \
  --zone="${VM3_ZONE}" \
  --metadata serial-port-logging-enable=TRUE
