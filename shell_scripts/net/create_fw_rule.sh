#!/bin/bash

gcloud compute firewall-rules create allow-web-traffic-to-tagged-vms \
    --project=$(gcloud config get-value project) \
    --network=default \
    --direction=INGRESS \
    --priority=1000 \
    --action=ALLOW \
    --rules=tcp:80,tcp:443 \
    --source-ranges=0.0.0.0/0 \
    --target-tags=http-server,https-server\
    --description="Allow HTTP (80) and HTTPS (443) ingress traffic from anywhere to VMs tagged with http-server"