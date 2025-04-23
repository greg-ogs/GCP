#!/bin/bash

#SA_EMAIL must be set as env variable (use export)
VM2_NAME="cmtr-14dfb3bf-nginx-02"
ADDITIONAL_DISK_VM2_NAME="cmtr-14dfb3bf-vm2-disk"

gcloud compute instances create "${VM2_NAME}" \
    --project=$(gcloud config get-value project) \
    --zone=us-central1-c \
    --machine-type=n1-standard-1 \
    --network-interface=network=default \
    --maintenance-policy=MIGRATE \
    --provisioning-model=STANDARD \
    --service-account="${SA_EMAIL}" \
    --tags=http-server,https-server \
    --create-disk=auto-delete=yes,boot=yes,device-name="${VM2_NAME}",source-snapshot=cmtr-14dfb3bf-snapshot \
    --create-disk=auto-delete=no,device-name="${ADDITIONAL_DISK_VM2_NAME}",mode=rw,size=10GB,type=pd-balanced \
    --no-shielded-secure-boot \
    --shielded-vtpm \
    --shielded-integrity-monitoring \
    --reservation-affinity=any

    gcloud compute instances add-metadata "${VM2_NAME}" --metadata serial-port-logging-enable=TRUE