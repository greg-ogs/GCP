#!/bin/bash

# Define variables
INSTANCE_TEMPLATE_NAME="nginx"
HEALTH_CHECK_NAME="common"
MACHINE_TYPE="n1-standard-1"
FIREWALL_RULE_NAME="defaul-allow-http"
SSH_KEY="${USER}":"${KEY}"
MIG_NAME="nginx"
REGION="us-central1"
ZONES="us-central1-a"
VPC_NAME="default"
SUBNET=main""

# MySQL instance variables
MYSQL_INSTANCE_NAME="private-mysql-instance"
MYSQL_ZONE="us-central1-c"
MYSQL_VERSION="MYSQL_8_0"
MYSQL_TIER="db-f1-micro"
PROJECT_ID=$(gcloud config get-value project)
# Extract region from zone (remove the last part after the last dash)
MYSQL_REGION=${MYSQL_ZONE%-*}
# Construct the instance connection name

# Secret names
SECRET_DB_USER="DB_USER"
SECRET_DB_PASS="DB_PASS"
SECRET_DB_NAME="DB_NAME"

# Create firewall rule to allow HTTP traffic
gcloud compute firewall-rules create "${FIREWALL_RULE_NAME}" \
    --project=$(gcloud config get-value project) \
    --direction=INGRESS \
    --priority=1000 \
    --network="${VPC_NAME}" \
    --action=ALLOW \
    --rules=tcp:80,tcp:8080 \
    --source-ranges=0.0.0.0/0 \
    --target-tags=http-server \
    --description="Personalized. HTTP traffic to instances with the http-server tag in default network"

gcloud compute firewall-rules create default-allow-health-check \
    --project=$(gcloud config get-value project) \
    --direction=INGRESS \
    --priority=1000 \
    --network="${VPC_NAME}" \
    --action=ALLOW \
    --rules=tcp:80,tcp:8080 \
    --source-ranges=130.211.0.0/22,35.191.0.0/16 \
    --target-tags=health-check \
    --description="Personalize. Allow HTTP traffic to instances with the health-check tag for health checks in default network"

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
    --region="${REGION}" \
    --machine-type="${MACHINE_TYPE}" \
    --service-account="${DEFAULT_SA}" \
    --network-interface=network="${VPC_NAME}",network-tier=PREMIUM,stack-type=IPV4_ONLY \
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
    --zone="${ZONES}" \
    --size=2 \
    --base-instance-name="${INSTANCE_TEMPLATE_NAME}" \
    --health-check="${HEALTH_CHECK_NAME}" \
    --initial-delay=300

# Configure named ports
gcloud compute instance-groups set-named-ports "${MIG_NAME}" \
    --named-ports=http:80 \
    --zone="${ZONES}"
#    --zone=$(echo "$ZONES" | cut -d ',' -f 1)

# Configure autoscaling
gcloud compute instance-groups managed set-autoscaling "${MIG_NAME}" \
    --project=$(gcloud config get-value project) \
    --zone="${ZONES}" \
    --min-num-replicas=1 \
    --max-num-replicas=2 \
    --target-cpu-utilization=0.5 \
    --cool-down-period=60
#    --zone=$(echo "$ZONES" | cut -d ',' -f 1)

# Check the MIG
gcloud compute instance-groups managed describe "${MIG_NAME}" \
    --zone="${ZONES}" >> logs.txt
gcloud compute instance-groups managed list-instances "${MIG_NAME}" \
    --zone="${ZONES}" >> logs.txt

# Enable required APIs for MySQL
echo "Alert: Enabling required APIs for MySQL..."
gcloud services enable sqladmin.googleapis.com --project=$PROJECT_ID

# Enable Secret Manager API
echo "Alert: Enabling Secret Manager API..."
gcloud services enable secretmanager.googleapis.com --project=$PROJECT_ID

# Retrieve secrets
MYSQL_USER=$(gcloud secrets versions access latest --secret=$SECRET_DB_USER --project=$PROJECT_ID)
MYSQL_PASSWORD=$(gcloud secrets versions access latest --secret=$SECRET_DB_PASS --project=$PROJECT_ID)
MYSQL_DB_NAME=$(gcloud secrets versions access latest --secret=$SECRET_DB_NAME --project=$PROJECT_ID)
SA_KEY=$(gcloud secrets versions access latest --secret="key" --project=$PROJECT_ID)
#Private service acces
IP_RANGE_NAME="default-google-managed-services-range"
IP_RANGE_CIDR="10.100.0.0/24"
SERVICE_NETWORKING_API="servicenetworking.googleapis.com"

# Allocate range of ip addresses
gcloud compute addresses create "$IP_RANGE_NAME" \
    --global \
    --project=$PROJECT_ID \
    --purpose=VPC_PEERING \
    --network="$VPC_NAME" \
    --prefix-length=${IP_RANGE_CIDR#*/} \
    --addresses=${IP_RANGE_CIDR%/*}

## Try to update the connection
#echo "Alert: Updating Private Services Access connection..."
#gcloud services vpc-peerings update \
#    --project=$PROJECT_ID \
#    --service=$SERVICE_NETWORKING_API \
#    --network="$VPC_NAME" \
#    --ranges="$IP_RANGE_NAME" \
#    --force

# Create Private Services Access connection
echo "Alert: Creating Private Services Access connection..."
gcloud services vpc-peerings connect \
    --project=$PROJECT_ID \
    --service=$SERVICE_NETWORKING_API \
    --ranges="$IP_RANGE_NAME" \
    --network="$VPC_NAME"

# Check if MySQL instance exists
echo "Alert: Checking if MySQL instance exists..."
MYSQL_EXISTS=$(gcloud sql instances list --project=$PROJECT_ID --filter="name:${MYSQL_INSTANCE_NAME}" --format="value(name)")

if [ -z "$MYSQL_EXISTS" ]; then
    echo "MySQL instance does not exist. Creating..."

    # Create MySQL instance
    gcloud sql instances create "$MYSQL_INSTANCE_NAME" \
        --project=$PROJECT_ID \
        --database-version="$MYSQL_VERSION" \
        --tier="$MYSQL_TIER" \
        --edition=enterprise \
        --zone="$MYSQL_ZONE" \
        --network="${VPC_NAME}" \
        --no-assign-ip \
        --storage-type=SSD \
        --storage-size=10GB \
        --root-password="${MYSQL_PASSWORD}" \
        --no-storage-auto-increase \
        --availability-type=ZONAL

    # Create database
    echo "Alert: Creating database ${MYSQL_DB_NAME}..."
    gcloud sql databases create "$MYSQL_DB_NAME" \
        --instance="$MYSQL_INSTANCE_NAME" \
        --project=$PROJECT_ID \
        --charset=utf8mb4 --collation=utf8mb4_unicode_ci

    # Create user
    echo "Alert: Creating user ${MYSQL_USER}..."
    gcloud sql users create "$MYSQL_USER" \
        --instance="$MYSQL_INSTANCE_NAME" \
        --project=$PROJECT_ID \
        --host='%' \
        --password="${MYSQL_PASSWORD}"

    echo "Alert: MySQL instance created successfully with database ${MYSQL_DB_NAME} and user ${MYSQL_USER}"
    echo "Alert: MySQL password: ${MYSQL_PASSWORD}"
else
    echo "Alert: MySQL instance ${MYSQL_INSTANCE_NAME} already exists."
fi

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
    --zone="${ZONES_ALCHEMY}" \
    --size=1 `# Start with the minimum number of instances` \
    --base-instance-name="${MIG_NAME_ALCHEMY}-instance" \
    --health-check="${HEALTH_CHECK_NAME}" \
    --initial-delay=300

echo "Alert: Configuring autoscaling for ${MIG_NAME_ALCHEMY}..."
gcloud compute instance-groups managed set-autoscaling "${MIG_NAME_ALCHEMY}" \
    --project="${PROJECT_ID}" \
    --zone="${ZONES_ALCHEMY}" \
    --min-num-replicas=1 \
    --max-num-replicas=2 \
    --target-cpu-utilization=0.5 \
    --cool-down-period=60

echo "Alert: Configuring named ports for ${MIG_NAME_ALCHEMY}..."
gcloud compute instance-groups set-named-ports "${MIG_NAME_ALCHEMY}" \
    --project="${PROJECT_ID}" \
    --zone="${ZONES_ALCHEMY}" \
    --named-ports=http:80

echo "Alert: Managed Instance Group ${MIG_NAME_ALCHEMY} created and configured."
# Check the proxy status using ps aux | grep cloud-sql-proxy in ssh console
# Or using sudo netstat -ltnp | grep ':3306'
# Or using pgrep -af cloud-sql-proxy
# Or using sudo ss -ltnp | grep ':3306'