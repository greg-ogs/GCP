#!/bin/bash

# Machine image from the vm

VM1_NAME="cmtr-14dfb3bf-nginx-01"
#SERVICE_ACCOUNT_NAME must be set as env variable (use export)
SSH_KEY="${USER}:${KEY}"
VM_ZONE="us-central1-c"

echo "Image creation"

IMAGE_NAME="cmtr-14dfb3bf-machine-image"
IMAGE_FAMILY="gcloud-epam-tasks"
IMAGE_DESCRIPTION="Custom Debian 12 image with Nginx pre-installed for EPAM task"

# Create image
gcloud compute instances stop "${VM1_NAME}" --zone="${VM_ZONE}" --project="$(gcloud config get-value project)"
sleep 30
gcloud compute images create "${IMAGE_NAME}" \
    --project="$(gcloud config get-value project)" \
    --source-disk="${VM1_NAME}" \
    --source-disk-zone="${VM_ZONE}" \
    --description="${IMAGE_DESCRIPTION}" \
    --family="${IMAGE_FAMILY}" \
    --storage-location="us-central1"

gcloud compute instances start "${VM1_NAME}" --zone="${VM_ZONE}" --project="$(gcloud config get-value project)"

# vm from image

echo "VM 3"

VM3_NAME="cmtr-14dfb3bf-nginx-03"

gcloud compute instances create "${VM3_NAME}" \
    --project=$(gcloud config get-value project) \
    --zone="${VM_ZONE}" \
    --machine-type=n1-standard-1 \
    --network-interface=network=default,network-tier=PREMIUM,stack-type=IPV4_ONLY \
    --maintenance-policy=MIGRATE \
    --provisioning-model=STANDARD \
    --service-account="${SERVICE_ACCOUNT_NAME}" \
    --tags=http-server,https-server \
    --image="${IMAGE_NAME}" \
    --image-project="$(gcloud config get-value project)" \
    --boot-disk-size=10GB
    --boot-disk-type=pd-balanced \
    --no-shielded-secure-boot \
    --shielded-vtpm \
    --shielded-integrity-monitoring \
    --reservation-affinity=any

gcloud compute instances describe ${VM2_NAME} --zone="${VM_ZONE}" --format='get(networkInterfaces[0].accessConfigs[0].natIP)'