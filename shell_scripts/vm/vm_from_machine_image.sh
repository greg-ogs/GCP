#!/bin/bash

# Create a machine image and then create an instance from that image.

gcloud compute instances stop "${VM1_NAME}" --zone="${VM_ZONE}" --project="$(gcloud config get-value project)"
sleep 30
gcloud compute machine-images create "${IMAGE_NAME}" \
    --project="$(gcloud config get-value project)" \
    --source-instance="${VM1_NAME}" \
    --source-instance-zone="${VM_ZONE}" \
    --description="${IMAGE_DESCRIPTION}" \
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
    --source-machine-image="${IMAGE_NAME}" \
    --boot-disk-size=10GB \
    --boot-disk-type=pd-balanced \
    --no-shielded-secure-boot \
    --shielded-vtpm \
    --shielded-integrity-monitoring \
    --reservation-affinity=any

gcloud compute instances describe ${VM3_NAME} --zone="${VM_ZONE}" --format='get(networkInterfaces[0].accessConfigs[0].natIP)'