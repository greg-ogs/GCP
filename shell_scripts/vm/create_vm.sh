#!/bin/bash

VM1_NAME="cmtr-14dfb3bf-nginx-01"
#SERVICE_ACCOUNT_NAME must be set as env variable (use export)
ADDITIONAL_DISK_VM1_NAME="cmtr-14dfb3bf-vm1-disk"
SSH_KEY="${USER}:${KEY}"

gcloud compute instances create "${VM1_NAME}" \
    --project=$(gcloud config get-value project) \
    --zone=us-central1-c \
    --machine-type=n1-standard-1 \
    --network-interface=network=default,network-tier=PREMIUM,stack-type=IPV4_ONLY \
    --maintenance-policy=MIGRATE \
    --provisioning-model=STANDARD \
    --service-account="${SERVICE_ACCOUNT_NAME}" \
    --tags=http-server,https-server \
    --create-disk=auto-delete=yes,boot=yes,device-name="${VM1_NAME}",image=projects/debian-cloud/global/images/debian-12-bookworm-v20250415,mode=rw,size=10 \
    --create-disk=auto-delete=no,device-name="${ADDITIONAL_DISK_VM1_NAME}",mode=rw,size=10,type=pd-balanced \
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
    echo "Nginx installation and startup complete."'

gcloud compute instances describe ${VM1_NAME} --zone=us-central1-c --format='get(networkInterfaces[0].accessConfigs[0].natIP)'

# Post creation metadata add
gcloud compute instances add-metadata $VM1_NAME --metadata serial-port-logging-enable=TRUE