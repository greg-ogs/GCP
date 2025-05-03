#!/bin/bash

# For taguet instances

VPC_NAME="cmtr-14dfb3bf-vpc"
TARGET_TAG_SERVER="server"

#FW_RULE_NAME="cmtr-14dfb3bf-http-ssh"
#FW_RULE_NAME="cmtr-14dfb3bf-icmp"
FW_RULE_NAME="cmtr-14dfb3bf-all"

#RULES="tcp:80,tcp:22"
#RULES="icmp"
RULES="all"

#DESCRIPTION="Allow HTTP and SSH traffic to instances tagged with '$TARGET_TAG_SERVER'"
#DESCRIPTION="Allow ICMP traffic from any source to all instances"
#DESCRIPTION="Allow all internal traffic within the VPC subnets"

SOURCE_RANGE="10.1.0.0/24","10.2.0.0/24"

gcloud compute firewall-rules create "$FW_RULE_NAME" \
    --project=$(gcloud config get-value project) \
    --network="$VPC_NAME" \
    --direction=INGRESS \
    --priority=1000 \
    --action=ALLOW \
    --rules=$RULES \
    --source-ranges="$SOURCE_RANGE"\
    --description="Allow all internal traffic within the VPC subnets"
#    --source-ranges=0.0.0.0/0 \
#    --target-tags="$TARGET_TAG_SERVER" \

