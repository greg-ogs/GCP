#!/bin/bash

BUCKET_NAME1="cmtr-14dfb3bf-bucket-02"
BUCKET_URI1="gs://$BUCKET_NAME1"

gcloud storage buckets create "${BUCKET_URI1}" \
      --uniform-bucket-level-access

# Create the folder for HNS
#gcloud storage folders create "${BUCKET_URI1}/cmrt-14dfb3bf-cvs"
#
# CP into the folder
#gcloud storage cp "/home/greg-ogs/GCP-shell/tasks/cmrt-14dfb3bf-cv.docx" "${BUCKET_URI1}/cmrt-14dfb3bf-cvs/"

# Performs the previous 2 steps into 1 without HNS

gcloud storage cp "/home/greg-ogs/GCP-shell/tasks/cmrt-14dfb3bf-cv.docx" "${BUCKET_URI1}/cmrt-14dfb3bf-cvs/"

# Create a regional bucket

BUCKET_NAME2="cmtr-14dfb3bf-bucket-05"
BUCKET_URI2="gs://$BUCKET_NAME2"

gcloud storage buckets create "${BUCKET_URI2}" \
      --location=europe-west1 \
      --uniform-bucket-level-access

# Sync 2 buckets

gcloud storage rsync "${BUCKET_URI1}" "${BUCKET_URI2}" --recursive

# Create new buckets using different storage classes

BUCKET_NAME3="cmtr-14dfb3bf-bucket-03"
BUCKET_URI3="gs://$BUCKET_NAME3"
BUCKET_NAME4="cmtr-14dfb3bf-bucket-04"
BUCKET_URI4="gs://$BUCKET_NAME4"

gcloud storage buckets create "${BUCKET_URI3}" \
      --location=europe-west1 \
      --default-storage-class=NEARLINE \
      --enable-hierarchical-namespace \
      --uniform-bucket-level-access

gcloud storage buckets create "${BUCKET_URI4}" \
      --location=europe-west1 \
      --default-storage-class=COLDLINE \
      --enable-hierarchical-namespace \
      --uniform-bucket-level-access

# Enable object versioning

gcloud storage buckets update "${BUCKET_URI1}" --versioning

# Make bucket available for all cause UBLA

gcloud storage buckets add-iam-policy-binding "${BUCKET_URI1}" \
    --member=allUsers \
    --role=roles/storage.objectViewer

# Add signed URL

gcloud auth activate-service-account --key-file=/home/greg-ogs/GCP-shell/KEY.json

gcloud storage sign-url "${BUCKET_URI2}/cmrt-14dfb3bf-cvs/cmrt-14dfb3bf-cv.docx" \
    --duration=10m

gcloud config set account "${EMAIL}"

gcloud auth revoke KEY_email