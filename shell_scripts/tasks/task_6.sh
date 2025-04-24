#!/bin/bash

SSH_KEY="${USER}":"${KEY}"
#DEFAULT_SA must be set as env variable (use export)
VM1_NAME="cmtr-14dfb3bf-06"
VPC_NAME="testings"
VM1_ZONE="us-central1-a"

echo "Creating VM 1"
gcloud compute instances create "${VM1_NAME}" \
    --project=$(gcloud config get-value project) \
    --zone="${VM1_ZONE}" \
    --machine-type=e2-medium \
    --network-interface=network="${VPC_NAME}",subnet=main,network-tier=PREMIUM,stack-type=IPV4_ONLY \
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
               sudo apt install --upgrade git -y
               sudo apt install --upgrade python3 -y
               PYVERSION=$(python3 --version | grep -o 3.*)
               sudo apt install python3.11-venv -y
               '
gcloud compute instances describe ${VM1_NAME} --zone=us-central1-a --format='get(networkInterfaces[0].accessConfigs[0].natIP)'

# Post creation metadata add
gcloud compute instances add-metadata $VM1_NAME --zone=us-central1-a --metadata serial-port-logging-enable=TRUE

