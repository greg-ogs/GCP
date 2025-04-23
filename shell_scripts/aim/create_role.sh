#!/bin/bash

ROLE_NAME="$1"
PROJECT_ID="$2"
#YALM=$3

if [ $# -eq 2 ]; then
gcloud iam roles create $ROLE_NAME \
    --project="$PROJECT_ID" \
    --title="Image Downloader for EPAM task #2" \
    --description="Allows users to list objects in buckets and download specific objects." \
    --permissions="storage.objects.get,storage.objects.list" \
    --stage=ALPHA
#elif [ $# -eq 3 ]; then
#  gcloud iam roles create $ROLE_NAME --project=$PROJECT_ID --file=$YALM
#  else
#    echo "Mising arguments, must be 3 (ROLE_NAME PROJECT_ID YALM_DIR)"
fi
# cmtr_14dfb3bf_custom_role gc-bootcamp-14dfb3bf