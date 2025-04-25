#!/bin/bash

# Define variables
INSTANCE_TEMPLATE_NAME="nginx"
HEALTH_CHECK_NAME="common"
MACHINE_TYPE="n1-standard-1"
FIREWALL_RULE_NAME="default-allow-http"
SSH_KEY="${USER}":"${KEY}"
MIG_NAME="nginx"
REGION="us-central1"
ZONES="us-central1-a,us-central1-c"

# Create firewall rule to allow HTTP traffic
gcloud compute firewall-rules create "${FIREWALL_RULE_NAME}" \
    --project=$(gcloud config get-value project) \
    --direction=INGRESS \
    --priority=1000 \
    --network=default \
    --action=ALLOW \
    --rules=tcp:80 \
    --source-ranges=0.0.0.0/0 \
    --target-tags=http-server \
    --description="Allow HTTP traffic to instances with the http-server tag"

gcloud compute firewall-rules create default-allow-health-check \
    --project=$(gcloud config get-value project) \
    --direction=INGRESS \
    --priority=1000 \
    --network=default \
    --action=ALLOW \
    --rules=tcp:80 \
    --source-ranges=130.211.0.0/22,35.191.0.0/16 \
    --target-tags=health-check \
    --description="Allow HTTP traffic to instances with the http-server tag for health checks"


# Create health check
gcloud compute health-checks create http "${HEALTH_CHECK_NAME}" \
    --project=$(gcloud config get-value project) \
    --port=80 \
    --request-path="/" \
    --check-interval=5s \
    --timeout=5s \
    --healthy-threshold=2 \
    --unhealthy-threshold=2 \
    --description="HTTP health check for EPAM task 7 servers"

# Create instance template
gcloud compute instance-templates create "${INSTANCE_TEMPLATE_NAME}" \
    --project=$(gcloud config get-value project) \
    --machine-type="${MACHINE_TYPE}" \
    --network-interface=network=default,network-tier=PREMIUM \
    --maintenance-policy=MIGRATE \
    --provisioning-model=STANDARD \
    --tags=http-server,health-check,lb-health-check \
    --create-disk=auto-delete=yes,boot=yes,device-name=boot-disk,image=projects/debian-cloud/global/images/family/debian-11,mode=rw,size=10,type=pd-balanced \
    --no-shielded-secure-boot \
    --shielded-vtpm \
    --shielded-integrity-monitoring \
    --reservation-affinity=any \
    --metadata=ssh-keys="${SSH_KEY}",startup-script='#!/bin/bash
# Install nginx
apt-get update
apt-get install -y nginx

# Get instance metadata
INSTANCE_NAME=$(curl -s "http://metadata.google.internal/computeMetadata/v1/instance/name" -H "Metadata-Flavor: Google")
INSTANCE_ZONE=$(curl -s "http://metadata.google.internal/computeMetadata/v1/instance/zone" -H "Metadata-Flavor: Google" | cut -d/ -f4)
NGINX_DEFAULT_PAGE="/var/www/html/index.nginx-debian.html"
TEXT_TO_APPEND="<p>This is the instance: ${INSTANCE_NAME} and the instance zone is: ${INSTANCE_ZONE}</p>"
echo "$TEXT_TO_APPEND" >> "$NGINX_DEFAULT_PAGE"
systemctl restart nginx
'

# Create MIG
gcloud compute instance-groups managed create "${MIG_NAME}" \
    --project=$(gcloud config get-value project) \
    --template="${INSTANCE_TEMPLATE_NAME}" \
    --region="${REGION}" \
    --zones="${ZONES}" \
    --size=1 \
    --base-instance-name="${INSTANCE_TEMPLATE_NAME}" \
    --health-check="${HEALTH_CHECK_NAME}" \
    --initial-delay=300

gcloud compute instance-groups set-named-ports "${MIG_NAME}" \
    --named-ports=http:80 \
    --region="${REGION}"

# Configure autoscaling
gcloud compute instance-groups managed set-autoscaling "${MIG_NAME}" \
    --project=$(gcloud config get-value project) \
    --region="${REGION}" \
    --min-num-replicas=1 \
    --max-num-replicas=2 \
    --target-cpu-utilization=0.5 \
    --cool-down-period=60

# Check the MIG
gcloud compute instance-groups managed describe "${MIG_NAME}" \
    --region="${REGION}" >> logs.txt
gcloud compute instance-groups managed list-instances "${MIG_NAME}" \
    --region="${REGION}" >> logs.txt