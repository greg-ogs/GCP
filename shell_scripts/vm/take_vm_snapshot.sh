#!/bin/bash

SOURCE_DISK="cmtr-14dfb3bf-nginx-01"

gcloud compute snapshots create cmtr-14dfb3bf-snapshot \
    --project=$(gcloud config get-value project) \
    --source-disk=$SOURCE_DISK \
    --source-disk-zone=us-central1-c \
    --storage-location=us-central1 \
    --snapshot-type=STANDARD

gcloud compute snapshots list --filter="sourceDisk.scope(disks)='$SOURCE_DISK'"