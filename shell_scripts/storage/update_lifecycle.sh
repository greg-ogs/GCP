#!/bin/bash

BUCKET_NAME1="cmtr-14dfb3bf-bucket-02"
BUCKET_URI1="gs://$BUCKET_NAME1"
BUCKET_NAME2="cmtr-14dfb3bf-bucket-05"
BUCKET_URI2="gs://$BUCKET_NAME2"
BUCKET_NAME3="cmtr-14dfb3bf-bucket-03"
BUCKET_URI3="gs://$BUCKET_NAME3"
BUCKET_NAME4="cmtr-14dfb3bf-bucket-04"
BUCKET_URI4="gs://$BUCKET_NAME4"

gcloud storage buckets update "${BUCKET_URI1}" --lifecycle-file=/home/greg-ogs/GCP-shell/storage/lifecycle_2.json

gcloud storage buckets update "${BUCKET_URI3}" --lifecycle-file=/home/greg-ogs/GCP-shell/storage/lifecycle_3.json

gcloud storage buckets update "${BUCKET_URI4}" --lifecycle-file=/home/greg-ogs/GCP-shell/storage/lifecycle_4.json

gcloud storage buckets update "${BUCKET_URI2}" --lifecycle-file=/home/greg-ogs/GCP-shell/storage/lifecycle_5.json

gsutil lifecycle get "${BUCKET_URI1}"
gsutil lifecycle get "${BUCKET_URI3}"
gsutil lifecycle get "${BUCKET_URI4}"
gsutil lifecycle get "${BUCKET_URI2}"