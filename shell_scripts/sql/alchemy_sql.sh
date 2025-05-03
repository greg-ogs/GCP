# MySQL database ready to work with alchemy application
# The alchemy application can be found in ./load_balancer/alchemy_mig.sh
# The public ip must be activated

PROJECT_ID=$(gcloud config get-value project)
VPC_NAME="default"
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

# Enable Secret Manager API
echo "Alert: Enabling Secret Manager API..."
gcloud services enable secretmanager.googleapis.com --project=$PROJECT_ID

# Allocate range of ip addresses
gcloud compute addresses create "$IP_RANGE_NAME" \
    --global \
    --project=$PROJECT_ID \
    --purpose=VPC_PEERING \
    --network="$VPC_NAME" \
    --prefix-length=${IP_RANGE_CIDR#*/} \
    --addresses=${IP_RANGE_CIDR%/*}

## Try to update
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
