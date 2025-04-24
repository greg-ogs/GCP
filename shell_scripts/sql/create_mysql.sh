#!/bin/bash

# Variables
VPC_NAME="testings"
SUBNET1_NAME="main"
SUBNET1_REGION="us-central1"
SUBNET1_CIDR="10.1.0.0/24"

# Secret Manager configuration
SECRET_MANAGER_API="secretmanager.googleapis.com"

# Create the network where all the resources gonna be deployed.
echo "Creating network"
gcloud compute networks create "$VPC_NAME" \
    --project=$(gcloud config get-value project) \
    --subnet-mode=custom \
    --mtu=1460 \
    --bgp-routing-mode=regional

echo "Creating subnet '$SUBNET1_NAME' in region '$SUBNET1_REGION'..."
gcloud compute networks subnets create "$SUBNET1_NAME" \
    --project=$(gcloud config get-value project) \
    --network="$VPC_NAME" \
    --range="$SUBNET1_CIDR" \
    --enable-private-ip-google-access \
    --region="$SUBNET1_REGION"

gcloud compute networks describe "$VPC_NAME" --project=$(gcloud config get-value project)

gcloud compute networks subnets describe "$SUBNET1_NAME" --region="$SUBNET1_REGION" --project=$(gcloud config get-value project)

# Configure firewall rule for ssh
gcloud compute firewall-rules create "main-ssh-allow" \
        --network="${VPC_NAME}" \
        --direction=INGRESS \
        --priority=1000 \
        --action=ALLOW \
        --target-tags=ssh-server \
        --rules=tcp:22 \
        --source-ranges="0.0.0.0/0" \
        --description="Allow SSH ingress traffic from anywhere to target instances in network"

# Configure Private Services Acces (PSA)
IP_RANGE_NAME="google-managed-services-range"
IP_RANGE_CIDR="10.2.0.0/24"
SERVICE_NETWORKING_API="servicenetworking.googleapis.com"
PROJECT_ID=$(gcloud config get-value project)

# Enable required APIs
gcloud services enable $SERVICE_NETWORKING_API --project=$PROJECT_ID
gcloud services enable $SECRET_MANAGER_API --project=$PROJECT_ID

# Create secrets for database credentials in the same region as the Cloud SQL instance
DB_USER="cmtr-14dfb3bf-user"
DB_NAME="alchemy"

# Create secret for DB_USER
echo "Creating secret for DB_USER..."
gcloud secrets create DB_USER \
    --project=$PROJECT_ID \
    --replication-policy=user-managed \
    --locations=$SUBNET1_REGION \
    --labels=purpose=database,environment=sandbox,resource=cloudsql \
    --data-file=./secret.txt

# Create secret for DB_PASS
echo "Creating secret for DB_PASS..."
printf "${DB_PASS}" | gcloud secrets create DB_PASS \
    --project=$PROJECT_ID \
    --replication-policy=user-managed \
    --locations=$SUBNET1_REGION \
    --labels=purpose=database,environment=sandbox,resource=cloudsql \
    --data-file=-

# Create secret for DB_NAME
echo "Creating secret for DB_NAME..."
printf "${DB_NAME}" | gcloud secrets create DB_NAME \
    --project=$PROJECT_ID \
    --replication-policy=user-managed \
    --locations=$SUBNET1_REGION \
    --labels=purpose=database,environment=sandbox,resource=cloudsql \
    --data-file=-

# Allocate range of ip adresses
gcloud compute addresses create "$IP_RANGE_NAME" \
    --global \
    --project=$PROJECT_ID \
    --purpose=VPC_PEERING \
    --network="$VPC_NAME" \
    --prefix-length=${IP_RANGE_CIDR#*/} \
    --addresses=${IP_RANGE_CIDR%/*}

# Create Private Services Access connection
echo "Creating Private Services Access connection..."
gcloud services vpc-peerings connect \
    --project=$PROJECT_ID \
    --service=$SERVICE_NETWORKING_API \
    --ranges="$IP_RANGE_NAME" \
    --network="$VPC_NAME"

# Load SQL Variables
MYSQL_INSTANCE_NAME="cmtr-14dfb3bf-06"
MYSQL_ZONE="us-central1-a"
MYSQL_VERSION="MYSQL_8_0"
MYSQL_TIER="db-f1-micro"
SQL_API="sqladmin.googleapis.com"

gcloud services enable $SQL_API --project=$PROJECT_ID

# Retrieve DB_PASS from Secret Manager
ROOT_PASSWORD=$(gcloud secrets versions access latest --secret=DB_PASS --project=$PROJECT_ID)

gcloud sql instances create "$MYSQL_INSTANCE_NAME" \
    --project=$PROJECT_ID \
    --database-version="$MYSQL_VERSION" \
    --tier="$MYSQL_TIER" \
    --edition=enterprise \
    --zone="$MYSQL_ZONE" \
    --network="$VPC_NAME" \
    --no-assign-ip \
    --storage-type=SSD \
    --storage-size=10GB \
    --no-deletion-protection \
    --no-storage-auto-increase \
    --root-password="${ROOT_PASSWORD}" \
    --availability-type=ZONAL

# Create a database
# Retrieve DB_NAME from Secret Manager
DATABASE_NAME=$(gcloud secrets versions access latest --secret=DB_NAME --project=$PROJECT_ID)

gcloud sql databases create "$DATABASE_NAME" \
    --instance="$MYSQL_INSTANCE_NAME" \
    --project=$PROJECT_ID \
    --charset=utf8mb4 --collation=utf8mb4_unicode_ci

# Create user
# Retrieve DB_USER from Secret Manager
MYSQL_USER=$(gcloud secrets versions access latest --secret=DB_USER --project=$PROJECT_ID)

gcloud sql users create "$MYSQL_USER" \
    --instance="$MYSQL_INSTANCE_NAME" \
    --project=$PROJECT_ID \
    --host='%' \
    --password="${ROOT_PASSWORD}"
