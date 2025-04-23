#!/bin/bash

# Create vm

VM1_NAME="cmtr-14dfb3bf-nginx-01"
# SERVICE_ACCOUNT_NAME must be in set as env variable (use export)
ADDITIONAL_DISK_VM1_NAME="cmtr-14dfb3bf-vm1-disk"
SSH_KEY="${USER}:${KEY}"
VM_ZONE="us-central1-c"

echo "First VM"

gcloud compute instances create "${VM1_NAME}" \
    --project=$(gcloud config get-value project) \
    --zone="${VM_ZONE}" \
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

gcloud compute instances describe ${VM1_NAME} --zone="${VM_ZONE}" --format='get(networkInterfaces[0].accessConfigs[0].natIP)'

# Post creation metadata add
gcloud compute instances add-metadata $VM1_NAME --metadata serial-port-logging-enable=TRUE

# Creation of the snapshot

echo "Snapshot 1"

SOURCE_DISK="cmtr-14dfb3bf-nginx-01"

gcloud compute snapshots create cmtr-14dfb3bf-snapshot \
    --project=$(gcloud config get-value project) \
    --source-disk="${SOURCE_DISK}" \
    --source-disk-zone="${VM_ZONE}" \
    --storage-location=us-central1 \
    --snapshot-type=STANDARD

gcloud compute snapshots list --filter="sourceDisk.scope(disks)='$SOURCE_DISK'"

# Second snapshot for testing bug

#echo "Snapshot for bug"

#gcloud compute snapshots create cmtr-5ff9f6d1-snapshot \
#    --project=$(gcloud config get-value project) \
#    --source-disk="${SOURCE_DISK}" \
#    --source-disk-zone="${VM_ZONE}" \
#    --storage-location=us-central1 \
#    --snapshot-type=STANDARD
#
#gcloud compute snapshots list --filter="sourceDisk.scope(disks)='$SOURCE_DISK'"

# Vm from snapshot

echo "VM 2"

VM2_NAME="cmtr-14dfb3bf-nginx-02"
ADDITIONAL_DISK_VM2_NAME="cmtr-14dfb3bf-vm2-disk"

gcloud compute instances create "${VM2_NAME}" \
    --project=$(gcloud config get-value project) \
    --zone="${VM_ZONE}" \
    --machine-type=n1-standard-1 \
    --network-interface=network=default,network-tier=PREMIUM,stack-type=IPV4_ONLY \
    --maintenance-policy=MIGRATE \
    --provisioning-model=STANDARD \
    --service-account="${SERVICE_ACCOUNT_NAME}" \
    --tags=http-server,https-server \
    --create-disk=auto-delete=yes,boot=yes,device-name="${VM2_NAME}",source-snapshot=cmtr-14dfb3bf-snapshot \
    --create-disk=auto-delete=no,device-name="${ADDITIONAL_DISK_VM2_NAME}",mode=rw,size=10GB,type=pd-balanced \
    --no-shielded-secure-boot \
    --shielded-vtpm \
    --shielded-integrity-monitoring \
    --reservation-affinity=any

gcloud compute instances describe ${VM2_NAME} --zone="${VM_ZONE}" --format='get(networkInterfaces[0].accessConfigs[0].natIP)'

gcloud compute instances add-metadata "${VM2_NAME}" --metadata serial-port-logging-enable=TRUE

# Machine image from the vm

echo "Image creation"

IMAGE_NAME="cmtr-14dfb3bf-machine-image"
IMAGE_FAMILY="gcloud-epam-tasks"
IMAGE_DESCRIPTION="Custom Debian 12 image with Nginx pre-installed for EPAM task"

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