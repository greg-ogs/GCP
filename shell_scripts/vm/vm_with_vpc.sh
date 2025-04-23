#!/bin/bash

VPC_NAME="default"

SSH_KEY="${USER}":"${KEY}"

#DEFAULT_SA must be set as env variable (use export)

# VM configurations
VM1_NAME="cmtr-14dfb3bf-vps-01"

VM1_ZONE="us-central1-c" # Zone for the default network VM

gcloud compute firewall-rules create "allow-http-to-all" \
        --network=default \
        --direction=INGRESS \
        --priority=1000 \
        --action=ALLOW \
        --rules=tcp:80 \
        --source-ranges="0.0.0.0/0" \
        --description="Allow HTTP ingress traffic from anywhere to all instances in default"

echo "Creating VM 1"
gcloud compute instances create "${VM1_NAME}" \
    --project=$(gcloud config get-value project) \
    --zone="${VM1_ZONE}" \
    --machine-type=n1-standard-1 \
    --network-interface=network="${VPC_NAME}",network-tier=PREMIUM,stack-type=IPV4_ONLY \
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