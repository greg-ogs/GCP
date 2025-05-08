#!/bin/bash

# Create an instance template and a MIG in GCP using a flask application
# The sql server from ./sql/alchemy_sql.sh is required

# Define variables
HEALTH_CHECK_NAME="common"
MACHINE_TYPE="n1-standard-1"
FIREWALL_RULE_NAME="defaul-allow-http"
SSH_KEY="${USER}":"${KEY}"
REGION="us-central1"
ZONES="us-central1-a,us-central1-c"
VPC_NAME="default"
SUBNET=main

PROJECT_ID=$(gcloud config get-value project)

#Alchemy instance template
INSTANCE_TEMPLATE_NAME0="alchemy"

# Create instance template for alchemy
gcloud compute instance-templates create "${INSTANCE_TEMPLATE_NAME0}" \
    --project=$(gcloud config get-value project) \
    --machine-type=n1-standard-1 \
    --network-interface=network="${VPC_NAME}",network-tier=PREMIUM,stack-type=IPV4_ONLY \
    --maintenance-policy=MIGRATE \
    --provisioning-model=STANDARD \
    --service-account="${DEFAULT_SA}" \
    --scopes=cloud-platform \
    --tags=http-server \
    --create-disk=auto-delete=yes,boot=yes,device-name=boot-disk,image=projects/debian-cloud/global/images/family/debian-12,mode=rw,size=10 \
    --reservation-affinity=any \
    --no-shielded-secure-boot \
    --shielded-vtpm \
    --shielded-integrity-monitoring \
    --metadata=ssh-keys="${SSH_KEY}",serial-port-logging-enable=TRUE,startup-script='#! /bin/bash
    mkdir /app
    cd /app
    apt update && apt install --upgrade git -y && apt install --upgrade python3 -y && apt install python3.11-venv -y \
        && apt install curl -y && apt install unzip -y && apt install python3-pip -y && python3 -m venv main
    curl -o cloud-sql-proxy https://storage.googleapis.com/cloud-sql-connectors/cloud-sql-proxy/v2.15.2/cloud-sql-proxy.linux.amd64 && \
        chmod +x cloud-sql-proxy

    # Export database variables from metadata
    PROJECT_ID=
    export DB_USER=$(gcloud secrets versions access latest --secret="DB_USER" --project="$(gcloud config get-value project)")
    export DB_PASS=$(gcloud secrets versions access latest --secret="DB_PASS" --project="$(gcloud config get-value project)")
    export DB_NAME=$(gcloud secrets versions access latest --secret="DB_NAME" --project="$(gcloud config get-value project)")
    export INSTANCE_CONNECTION_NAME=$(gcloud secrets versions access latest --secret="INSTANCE_CONNECTION_NAME" --project="$(gcloud config get-value project)")
    echo "$(gcloud secrets versions access latest --secret="key" --project="$(gcloud config get-value project)")" > /app/key.json
    export GOOGLE_APPLICATION_CREDENTIALS="/app/key.json"
    git clone https://github.com/GoogleCloudPlatform/python-docs-samples  && \
        cd /app/python-docs-samples/cloud-sql/mysql/sqlalchemy && \
        /app/main/bin/pip install -r requirements.txt

      # Run cloud-sql-proxy in the background
      cd /app
      ./cloud-sql-proxy --address 0.0.0.0 --port 3306 ${INSTANCE_CONNECTION_NAME} &
      .  /app/main/bin/activate
      cd /app/python-docs-samples/cloud-sql/mysql/sqlalchemy
      sudo -E /app/main/bin/flask run --host=0.0.0.0 --port=80 &
     '

MIG_NAME_ALCHEMY="alchemy"
REGION_ALCHEMY="us-west1"
ZONES_ALCHEMY="us-west1-a"
INSTANCE_TEMPLATE_ALCHEMY="${INSTANCE_TEMPLATE_NAME0}"

# Create the regional MIG for alchemy
echo "Alert: Creating regional Managed Instance Group: ${MIG_NAME_ALCHEMY}..."
gcloud compute instance-groups managed create "${MIG_NAME_ALCHEMY}" \
    --project="${PROJECT_ID}" \
    --template="${INSTANCE_TEMPLATE_ALCHEMY}" \
    --region="${REGION_ALCHEMY}" \
    --zones="${ZONES_ALCHEMY}" \
    --size=1 `# Start with the minimum number of instances` \
    --base-instance-name="${MIG_NAME_ALCHEMY}-instance" \
    --health-check="${HEALTH_CHECK_NAME}" \
    --initial-delay=300

echo "Alert: Configuring autoscaling for ${MIG_NAME_ALCHEMY}..."
gcloud compute instance-groups managed set-autoscaling "${MIG_NAME_ALCHEMY}" \
    --project="${PROJECT_ID}" \
    --region="${REGION_ALCHEMY}" \
    --min-num-replicas=1 \
    --max-num-replicas=2 \
    --target-cpu-utilization=0.5 \
    --cool-down-period=60

echo "Alert: Configuring named ports for ${MIG_NAME_ALCHEMY}..."
gcloud compute instance-groups set-named-ports "${MIG_NAME_ALCHEMY}" \
    --project="${PROJECT_ID}" \
    --region="${REGION_ALCHEMY}" \
    --named-ports=http:80

echo "Alert: Managed Instance Group ${MIG_NAME_ALCHEMY} created and configured."