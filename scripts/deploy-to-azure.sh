#!/bin/bash

# ==========================================
# WhatsApp Automation Azure Deployment Script
# ==========================================
# This script automates the deployment of Evolution API and n8n to Azure

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}WhatsApp Automation Azure Deployment${NC}"
echo -e "${GREEN}========================================${NC}"

# Check if Azure CLI is installed
if ! command -v az &> /dev/null; then
    echo -e "${RED}Error: Azure CLI is not installed${NC}"
    echo "Please install from: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
    exit 1
fi

# Check if logged in to Azure
if ! az account show &> /dev/null; then
    echo -e "${YELLOW}Not logged in to Azure. Please login...${NC}"
    az login
fi

# Configuration
read -p "Enter Resource Group Name [whatsapp-automation-rg]: " RESOURCE_GROUP
RESOURCE_GROUP=${RESOURCE_GROUP:-whatsapp-automation-rg}

read -p "Enter Azure Region [eastus]: " LOCATION
LOCATION=${LOCATION:-eastus}

read -p "Enter Database Admin Password: " -s DB_PASSWORD
echo

read -p "Enter Evolution API Key (or press Enter to generate): " API_KEY
if [ -z "$API_KEY" ]; then
    API_KEY=$(openssl rand -hex 32)
    echo -e "${GREEN}Generated API Key: ${API_KEY}${NC}"
fi

# Generate unique suffix
SUFFIX=$RANDOM

echo -e "\n${YELLOW}Deployment Configuration:${NC}"
echo "Resource Group: $RESOURCE_GROUP"
echo "Location: $LOCATION"
echo "Unique Suffix: $SUFFIX"

read -p "Continue with deployment? (y/n): " CONFIRM
if [ "$CONFIRM" != "y" ]; then
    echo "Deployment cancelled"
    exit 0
fi

# Create Resource Group
echo -e "\n${YELLOW}Creating Resource Group...${NC}"
az group create \
    --name $RESOURCE_GROUP \
    --location $LOCATION

# Create PostgreSQL Database
echo -e "\n${YELLOW}Creating PostgreSQL Database...${NC}"
DB_SERVER_NAME="whatsapp-db-${SUFFIX}"
az postgres flexible-server create \
    --name $DB_SERVER_NAME \
    --resource-group $RESOURCE_GROUP \
    --location $LOCATION \
    --admin-user dbadmin \
    --admin-password "$DB_PASSWORD" \
    --sku-name Standard_B2s \
    --tier Burstable \
    --version 14 \
    --storage-size 32 \
    --public-access 0.0.0.0

# Create databases
echo -e "\n${YELLOW}Creating databases...${NC}"
az postgres flexible-server db create \
    --resource-group $RESOURCE_GROUP \
    --server-name $DB_SERVER_NAME \
    --database-name evolution_db

az postgres flexible-server db create \
    --resource-group $RESOURCE_GROUP \
    --server-name $DB_SERVER_NAME \
    --database-name n8n_db

# Configure firewall
az postgres flexible-server firewall-rule create \
    --resource-group $RESOURCE_GROUP \
    --name $DB_SERVER_NAME \
    --rule-name AllowAzureServices \
    --start-ip-address 0.0.0.0 \
    --end-ip-address 0.0.0.0

# Create Redis Cache
echo -e "\n${YELLOW}Creating Redis Cache...${NC}"
REDIS_NAME="whatsapp-redis-${SUFFIX}"
az redis create \
    --name $REDIS_NAME \
    --resource-group $RESOURCE_GROUP \
    --location $LOCATION \
    --sku Basic \
    --vm-size c0

# Get Redis key
REDIS_KEY=$(az redis list-keys \
    --name $REDIS_NAME \
    --resource-group $RESOURCE_GROUP \
    --query primaryKey \
    --output tsv)

# Create Storage Account
echo -e "\n${YELLOW}Creating Storage Account...${NC}"
STORAGE_NAME="whatsappstorage${SUFFIX}"
az storage account create \
    --name $STORAGE_NAME \
    --resource-group $RESOURCE_GROUP \
    --location $LOCATION \
    --sku Standard_LRS \
    --kind StorageV2

# Create container
STORAGE_KEY=$(az storage account keys list \
    --resource-group $RESOURCE_GROUP \
    --account-name $STORAGE_NAME \
    --query '[0].value' \
    --output tsv)

az storage container create \
    --name evolution-media \
    --account-name $STORAGE_NAME \
    --account-key $STORAGE_KEY \
    --public-access blob

# Build connection strings
DB_CONNECTION_URI="postgresql://dbadmin:${DB_PASSWORD}@${DB_SERVER_NAME}.postgres.database.azure.com:5432/evolution_db?schema=public&sslmode=require"
REDIS_URI="redis://:${REDIS_KEY}@${REDIS_NAME}.redis.cache.windows.net:6380"

# Deploy Evolution API
echo -e "\n${YELLOW}Deploying Evolution API...${NC}"
EVOLUTION_NAME="evolution-api-${SUFFIX}"
az container create \
    --resource-group $RESOURCE_GROUP \
    --name $EVOLUTION_NAME \
    --image atendai/evolution-api:latest \
    --dns-name-label $EVOLUTION_NAME \
    --ports 8080 \
    --cpu 2 \
    --memory 4 \
    --environment-variables \
        SERVER_URL=http://${EVOLUTION_NAME}.${LOCATION}.azurecontainer.io:8080 \
        PORT=8080 \
        DATABASE_PROVIDER=postgresql \
        DATABASE_CONNECTION_URI="$DB_CONNECTION_URI" \
        REDIS_ENABLED=true \
        REDIS_URI="$REDIS_URI" \
        AUTHENTICATION_API_KEY="$API_KEY" \
        S3_ENABLED=true \
        S3_ACCESS_KEY="$STORAGE_NAME" \
        S3_SECRET_KEY="$STORAGE_KEY" \
        S3_BUCKET=evolution-media \
        S3_ENDPOINT=https://${STORAGE_NAME}.blob.core.windows.net \
        LOG_LEVEL=INFO \
    --restart-policy Always

# Deploy n8n
echo -e "\n${YELLOW}Deploying n8n...${NC}"
N8N_NAME="n8n-${SUFFIX}"
N8N_ENCRYPTION_KEY=$(openssl rand -hex 32)

az container create \
    --resource-group $RESOURCE_GROUP \
    --name $N8N_NAME \
    --image n8nio/n8n:latest \
    --dns-name-label $N8N_NAME \
    --ports 5678 \
    --cpu 2 \
    --memory 4 \
    --environment-variables \
        N8N_HOST=0.0.0.0 \
        N8N_PORT=5678 \
        WEBHOOK_URL=http://${N8N_NAME}.${LOCATION}.azurecontainer.io:5678 \
        DB_TYPE=postgresdb \
        DB_POSTGRESDB_HOST=${DB_SERVER_NAME}.postgres.database.azure.com \
        DB_POSTGRESDB_PORT=5432 \
        DB_POSTGRESDB_DATABASE=n8n_db \
        DB_POSTGRESDB_USER=dbadmin \
        DB_POSTGRESDB_PASSWORD="$DB_PASSWORD" \
        DB_POSTGRESDB_SSL_ENABLED=true \
        DB_POSTGRESDB_SSL_REJECT_UNAUTHORIZED=false \
        N8N_ENCRYPTION_KEY="$N8N_ENCRYPTION_KEY" \
        GENERIC_TIMEZONE=America/New_York \
    --restart-policy Always

# Get endpoints
EVOLUTION_FQDN=$(az container show \
    --resource-group $RESOURCE_GROUP \
    --name $EVOLUTION_NAME \
    --query ipAddress.fqdn \
    --output tsv)

N8N_FQDN=$(az container show \
    --resource-group $RESOURCE_GROUP \
    --name $N8N_NAME \
    --query ipAddress.fqdn \
    --output tsv)

# Save configuration
CONFIG_FILE="deployment-config.txt"
cat > $CONFIG_FILE << EOF
==========================================
Deployment Complete!
==========================================

Evolution API:
  URL: http://${EVOLUTION_FQDN}:8080
  API Key: ${API_KEY}

n8n:
  URL: http://${N8N_FQDN}:5678

Database:
  Server: ${DB_SERVER_NAME}.postgres.database.azure.com
  User: dbadmin
  Password: ${DB_PASSWORD}

Redis:
  Host: ${REDIS_NAME}.redis.cache.windows.net
  Key: ${REDIS_KEY}

Storage:
  Account: ${STORAGE_NAME}
  Key: ${STORAGE_KEY}

Resource Group: ${RESOURCE_GROUP}
Location: ${LOCATION}

==========================================
Next Steps:
==========================================

1. Access n8n and create your admin account:
   http://${N8N_FQDN}:5678

2. Create a WhatsApp instance:
   curl -X POST http://${EVOLUTION_FQDN}:8080/instance/create \\
     -H "apikey: ${API_KEY}" \\
     -H "Content-Type: application/json" \\
     -d '{
       "instanceName": "my-bot",
       "token": "my-token",
       "qrcode": true
     }'

3. Get QR code and scan with WhatsApp:
   curl -X GET http://${EVOLUTION_FQDN}:8080/instance/connect/my-bot \\
     -H "apikey: ${API_KEY}"

4. Configure SSL/HTTPS for production use

5. Set up monitoring and alerts

==========================================
EOF

echo -e "\n${GREEN}Deployment configuration saved to: ${CONFIG_FILE}${NC}"
cat $CONFIG_FILE

echo -e "\n${GREEN}Deployment completed successfully!${NC}"
