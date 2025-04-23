#!/bin/bash

# Create peering bidirectional

PEERING_NAME1="peer-cmtr-to-default"
PEERING_NAME2="peer-default-to-cmtr"
NET_1="cmtr-14dfb3bf-vpc"
NET_2="default"

gcloud compute networks peerings create "${PEERING_NAME1}" \
    --network="${NET_1}" \
    --peer-network="${NET_2}" \
    --stack-type=IPV4_ONLY

gcloud compute networks peerings create "${PEERING_NAME2}" \
    --network="${NET_2}" \
    --peer-network="${NET_1}" \
    --stack-type=IPV4_ONLY
#    --peer-project=[NET_1_VPC_PROJECT_ID] \
#    --project=[NET_2_VPC_PROJECT_ID]

# Confirm peer
gcloud compute networks peerings list \
    --network=default