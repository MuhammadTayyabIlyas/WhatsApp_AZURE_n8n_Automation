# WhatsApp Automation with Evolution API, n8n & Azure Cloud

<div align="center">

![Evolution API](./public/images/cover.png)

**A Complete Guide to Building WhatsApp Automation on Azure Cloud**

[![Evolution API](https://img.shields.io/badge/Evolution_API-2.3.6-blue)](https://evolution-api.com)
[![n8n](https://img.shields.io/badge/n8n-Workflow_Automation-orange)](https://n8n.io)
[![Azure](https://img.shields.io/badge/Azure-Cloud_Platform-0089D6)](https://azure.microsoft.com)

</div>

---

## Table of Contents

1. [Overview](#overview)
2. [Architecture](#architecture)
3. [Prerequisites](#prerequisites)
4. [Azure Infrastructure Setup](#azure-infrastructure-setup)
5. [Evolution API Deployment](#evolution-api-deployment)
6. [n8n Deployment](#n8n-deployment)
7. [Integration Guide](#integration-guide)
8. [WhatsApp Connection Setup](#whatsapp-connection-setup)
9. [Building Automation Workflows](#building-automation-workflows)
10. [Production Best Practices](#production-best-practices)
11. [Monitoring & Maintenance](#monitoring--maintenance)
12. [Troubleshooting](#troubleshooting)
13. [Cost Optimization](#cost-optimization)
14. [Security Considerations](#security-considerations)

---

## Overview

This project demonstrates how to build a production-ready WhatsApp automation system using:

- **Evolution API**: REST API for WhatsApp communication (Baileys-based)
- **n8n**: Open-source workflow automation platform
- **Azure Cloud**: Enterprise-grade cloud infrastructure

### What You Can Build

- 🤖 **Automated Customer Support**: Respond to customer inquiries 24/7
- 📢 **Marketing Campaigns**: Send bulk messages with personalization
- 📊 **Data Collection**: Gather customer feedback and survey responses
- 🔔 **Notifications**: Send order updates, reminders, and alerts
- 💬 **Interactive Chatbots**: Create conversational flows with AI integration
- 🔄 **CRM Integration**: Sync WhatsApp conversations with your CRM
- 📈 **Analytics Dashboard**: Track message delivery and engagement

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         Azure Cloud                              │
│                                                                   │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  Azure Container Instances / App Service                 │   │
│  │                                                           │   │
│  │  ┌──────────────────┐      ┌──────────────────┐        │   │
│  │  │  Evolution API   │◄────►│      n8n         │        │   │
│  │  │  (Port 8080)     │      │  (Port 5678)     │        │   │
│  │  └────────┬─────────┘      └────────┬─────────┘        │   │
│  │           │                          │                   │   │
│  └───────────┼──────────────────────────┼───────────────────┘   │
│              │                          │                       │
│  ┌───────────▼──────────────────────────▼───────────────────┐  │
│  │         Azure Database for PostgreSQL                     │  │
│  │              (Flexible Server)                            │  │
│  └───────────────────────────────────────────────────────────┘  │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │              Azure Redis Cache                            │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │              Azure Blob Storage                           │  │
│  │           (Media Files Storage)                           │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
                            │
                            ▼
                    WhatsApp Servers
```

### Component Roles

| Component | Purpose | Azure Service |
|-----------|---------|---------------|
| **Evolution API** | WhatsApp REST API controller | Container Instances / App Service |
| **n8n** | Workflow automation engine | Container Instances / App Service |
| **PostgreSQL** | Database for both services | Azure Database for PostgreSQL |
| **Redis** | Caching & session management | Azure Cache for Redis |
| **Blob Storage** | Media file storage | Azure Blob Storage |

---

## Prerequisites

### Required Tools

- Azure CLI installed (`az --version`)
- Git installed
- Docker installed (for local testing)
- Node.js 20+ (for local development)
- Text editor (VS Code recommended)

### Required Accounts

- Azure Account with active subscription
- GitHub account (for code repository)
- WhatsApp number (not used with WhatsApp Business API)

### Knowledge Requirements

- Basic Linux/bash commands
- Understanding of REST APIs
- Basic Docker concepts
- Azure fundamentals

---

## Azure Infrastructure Setup

### Step 1: Login to Azure

```bash
# Login to Azure
az login

# Set your subscription
az account set --subscription "YOUR_SUBSCRIPTION_ID"

# Verify
az account show
```

### Step 2: Create Resource Group

```bash
# Create a resource group
az group create \
  --name whatsapp-automation-rg \
  --location eastus

# Verify
az group show --name whatsapp-automation-rg
```

### Step 3: Create Azure Database for PostgreSQL

```bash
# Create PostgreSQL Flexible Server
az postgres flexible-server create \
  --name whatsapp-postgres-server \
  --resource-group whatsapp-automation-rg \
  --location eastus \
  --admin-user adminuser \
  --admin-password 'YourStrongPassword123!' \
  --sku-name Standard_B2s \
  --tier Burstable \
  --version 14 \
  --storage-size 32 \
  --public-access 0.0.0.0

# Create databases
az postgres flexible-server db create \
  --resource-group whatsapp-automation-rg \
  --server-name whatsapp-postgres-server \
  --database-name evolution_db

az postgres flexible-server db create \
  --resource-group whatsapp-automation-rg \
  --server-name whatsapp-postgres-server \
  --database-name n8n_db

# Configure firewall (allow Azure services)
az postgres flexible-server firewall-rule create \
  --resource-group whatsapp-automation-rg \
  --name whatsapp-postgres-server \
  --rule-name AllowAzureServices \
  --start-ip-address 0.0.0.0 \
  --end-ip-address 0.0.0.0
```

### Step 4: Create Azure Cache for Redis

```bash
# Create Redis Cache (Basic tier for testing, Standard/Premium for production)
az redis create \
  --name whatsapp-redis-cache \
  --resource-group whatsapp-automation-rg \
  --location eastus \
  --sku Basic \
  --vm-size c0

# Get connection details
az redis list-keys \
  --name whatsapp-redis-cache \
  --resource-group whatsapp-automation-rg
```

### Step 5: Create Azure Storage Account

```bash
# Create Storage Account
az storage account create \
  --name whatsappmediastorage \
  --resource-group whatsapp-automation-rg \
  --location eastus \
  --sku Standard_LRS \
  --kind StorageV2

# Create container for media files
az storage container create \
  --name evolution-media \
  --account-name whatsappmediastorage \
  --public-access blob

# Get connection string
az storage account show-connection-string \
  --name whatsappmediastorage \
  --resource-group whatsapp-automation-rg
```

### Step 6: Create Virtual Network (Optional but Recommended)

```bash
# Create Virtual Network
az network vnet create \
  --name whatsapp-vnet \
  --resource-group whatsapp-automation-rg \
  --address-prefix 10.0.0.0/16 \
  --subnet-name app-subnet \
  --subnet-prefix 10.0.1.0/24

# Create additional subnet for database
az network vnet subnet create \
  --name db-subnet \
  --resource-group whatsapp-automation-rg \
  --vnet-name whatsapp-vnet \
  --address-prefix 10.0.2.0/24
```

---

## Evolution API Deployment

### Option A: Deploy using Azure Container Instances

#### Step 1: Prepare Environment Variables

Create a file named `evolution-api.env`:

```bash
# Server Configuration
SERVER_URL=https://your-domain.com
PORT=8080
CORS_ORIGIN=*
CORS_CREDENTIALS=true

# Database Configuration (PostgreSQL)
DATABASE_PROVIDER=postgresql
DATABASE_CONNECTION_URI=postgresql://adminuser:YourStrongPassword123!@whatsapp-postgres-server.postgres.database.azure.com:5432/evolution_db?schema=public&sslmode=require
DATABASE_CONNECTION_CLIENT_NAME=evolution_api

# Redis Configuration
REDIS_ENABLED=true
REDIS_URI=redis://:YOUR_REDIS_PRIMARY_KEY@whatsapp-redis-cache.redis.cache.windows.net:6380
REDIS_PREFIX_KEY=evolution

# Authentication
AUTHENTICATION_API_KEY=your-secure-api-key-here
AUTHENTICATION_EXPOSE_IN_FETCH_INSTANCES=true

# Storage Configuration (Azure Blob)
S3_ENABLED=true
S3_ACCESS_KEY=YOUR_STORAGE_ACCOUNT_NAME
S3_SECRET_KEY=YOUR_STORAGE_ACCOUNT_KEY
S3_BUCKET=evolution-media
S3_ENDPOINT=https://whatsappmediastorage.blob.core.windows.net
S3_USE_SSL=true

# WhatsApp Settings
QRCODE_COLOR=#198754
INSTANCE_EXPIRATION_TIME=false

# Webhook Global
WEBHOOK_GLOBAL_ENABLED=false
WEBHOOK_GLOBAL_URL=
WEBHOOK_GLOBAL_WEBHOOK_BY_EVENTS=false

# Logs
LOG_LEVEL=ERROR,WARN,DEBUG,INFO,LOG,VERBOSE,DARK,WEBHOOKS
LOG_COLOR=true
LOG_BAILEYS=error

# Telemetry
TELEMETRY_ENABLED=false
```

#### Step 2: Create Container Instance

```bash
# Create container instance
az container create \
  --resource-group whatsapp-automation-rg \
  --name evolution-api-container \
  --image atendai/evolution-api:latest \
  --dns-name-label evolution-api-unique \
  --ports 8080 \
  --cpu 2 \
  --memory 4 \
  --environment-variables-file evolution-api.env \
  --restart-policy Always

# Get public IP
az container show \
  --resource-group whatsapp-automation-rg \
  --name evolution-api-container \
  --query ipAddress.fqdn \
  --output tsv
```

#### Step 3: Verify Deployment

```bash
# Check container logs
az container logs \
  --resource-group whatsapp-automation-rg \
  --name evolution-api-container

# Test API
curl http://YOUR_CONTAINER_FQDN:8080/
```

### Option B: Deploy using Azure App Service

#### Step 1: Create App Service Plan

```bash
# Create App Service Plan (Linux)
az appservice plan create \
  --name whatsapp-app-plan \
  --resource-group whatsapp-automation-rg \
  --location eastus \
  --is-linux \
  --sku B2

# Create Web App for Evolution API
az webapp create \
  --resource-group whatsapp-automation-rg \
  --plan whatsapp-app-plan \
  --name evolution-api-webapp \
  --deployment-container-image-name atendai/evolution-api:latest
```

#### Step 2: Configure App Settings

```bash
# Configure environment variables
az webapp config appsettings set \
  --resource-group whatsapp-automation-rg \
  --name evolution-api-webapp \
  --settings \
    SERVER_URL=https://evolution-api-webapp.azurewebsites.net \
    PORT=8080 \
    DATABASE_PROVIDER=postgresql \
    DATABASE_CONNECTION_URI="postgresql://adminuser:YourStrongPassword123!@whatsapp-postgres-server.postgres.database.azure.com:5432/evolution_db?schema=public&sslmode=require" \
    REDIS_ENABLED=true \
    REDIS_URI="redis://:YOUR_REDIS_PRIMARY_KEY@whatsapp-redis-cache.redis.cache.windows.net:6380" \
    AUTHENTICATION_API_KEY=your-secure-api-key-here
```

#### Step 3: Enable Logging

```bash
# Enable container logging
az webapp log config \
  --resource-group whatsapp-automation-rg \
  --name evolution-api-webapp \
  --docker-container-logging filesystem

# Stream logs
az webapp log tail \
  --resource-group whatsapp-automation-rg \
  --name evolution-api-webapp
```

---

## n8n Deployment

### Step 1: Deploy n8n using Container Instances

Create `n8n.env`:

```bash
# n8n Configuration
N8N_HOST=0.0.0.0
N8N_PORT=5678
N8N_PROTOCOL=https
WEBHOOK_URL=https://your-n8n-domain.com
N8N_EDITOR_BASE_URL=https://your-n8n-domain.com

# Database
DB_TYPE=postgresdb
DB_POSTGRESDB_HOST=whatsapp-postgres-server.postgres.database.azure.com
DB_POSTGRESDB_PORT=5432
DB_POSTGRESDB_DATABASE=n8n_db
DB_POSTGRESDB_USER=adminuser
DB_POSTGRESDB_PASSWORD=YourStrongPassword123!
DB_POSTGRESDB_SSL_ENABLED=true
DB_POSTGRESDB_SSL_REJECT_UNAUTHORIZED=false

# Encryption
N8N_ENCRYPTION_KEY=your-encryption-key-here

# Timezone
GENERIC_TIMEZONE=America/New_York

# Executions
EXECUTIONS_PROCESS=main
EXECUTIONS_DATA_SAVE_ON_ERROR=all
EXECUTIONS_DATA_SAVE_ON_SUCCESS=all
EXECUTIONS_DATA_SAVE_MANUAL_EXECUTIONS=true
```

Deploy n8n:

```bash
# Create n8n container
az container create \
  --resource-group whatsapp-automation-rg \
  --name n8n-container \
  --image n8nio/n8n:latest \
  --dns-name-label n8n-automation-unique \
  --ports 5678 \
  --cpu 2 \
  --memory 4 \
  --environment-variables-file n8n.env \
  --restart-policy Always

# Get n8n URL
az container show \
  --resource-group whatsapp-automation-rg \
  --name n8n-container \
  --query ipAddress.fqdn \
  --output tsv
```

### Step 2: Access n8n Interface

1. Open browser: `http://YOUR_N8N_FQDN:5678`
2. Create your n8n account (first user is admin)
3. Complete the setup wizard

---

## Integration Guide

### Step 1: Install Evolution API Node in n8n

n8n has community nodes for Evolution API. Install via npm:

```bash
# If you have access to n8n container, install the node
npm install n8n-nodes-evolution-api
```

Or use HTTP Request nodes to interact with Evolution API.

### Step 2: Configure Evolution API Credentials in n8n

1. In n8n, go to **Credentials** → **New Credential**
2. Search for "HTTP Request" or "Evolution API"
3. Add credentials:
   - **Base URL**: `http://evolution-api-container:8080` or your Evolution API URL
   - **API Key**: Your Evolution API key from `AUTHENTICATION_API_KEY`

### Step 3: Test Connection

Create a simple workflow in n8n:

```json
{
  "nodes": [
    {
      "parameters": {
        "url": "={{$env.EVOLUTION_API_URL}}/instance/fetchInstances",
        "authentication": "predefinedCredentialType",
        "nodeCredentialType": "evolutionApiApi",
        "options": {}
      },
      "name": "Get Instances",
      "type": "n8n-nodes-base.httpRequest",
      "position": [250, 300]
    }
  ]
}
```

---

## WhatsApp Connection Setup

### Step 1: Create WhatsApp Instance

Use Evolution API to create an instance:

```bash
curl -X POST http://YOUR_EVOLUTION_API_URL/instance/create \
  -H "apikey: your-secure-api-key-here" \
  -H "Content-Type: application/json" \
  -d '{
    "instanceName": "my-whatsapp-bot",
    "token": "unique-instance-token",
    "qrcode": true,
    "integration": "WHATSAPP-BAILEYS"
  }'
```

### Step 2: Connect WhatsApp

```bash
# Get QR Code
curl -X GET http://YOUR_EVOLUTION_API_URL/instance/connect/my-whatsapp-bot \
  -H "apikey: your-secure-api-key-here"
```

Response will include base64 QR code. Scan with WhatsApp on your phone:
1. Open WhatsApp on your phone
2. Go to **Settings** → **Linked Devices**
3. Tap **Link a Device**
4. Scan the QR code

### Step 3: Verify Connection

```bash
# Check instance status
curl -X GET http://YOUR_EVOLUTION_API_URL/instance/connectionState/my-whatsapp-bot \
  -H "apikey: your-secure-api-key-here"
```

---

## Building Automation Workflows

### Example 1: Auto-Reply to New Messages

Create this workflow in n8n:

**Workflow Structure:**
1. **Webhook Trigger** (Evolution API sends new message events)
2. **Switch Node** (Route based on message content)
3. **HTTP Request** (Send reply via Evolution API)

**n8n Workflow JSON:**

```json
{
  "name": "WhatsApp Auto-Reply",
  "nodes": [
    {
      "parameters": {
        "path": "whatsapp-webhook",
        "options": {}
      },
      "name": "Webhook",
      "type": "n8n-nodes-base.webhook",
      "typeVersion": 1,
      "position": [240, 300],
      "webhookId": "unique-webhook-id"
    },
    {
      "parameters": {
        "conditions": {
          "string": [
            {
              "value1": "={{$json.body.data.message.conversation}}",
              "operation": "contains",
              "value2": "hello"
            }
          ]
        }
      },
      "name": "IF Hello",
      "type": "n8n-nodes-base.if",
      "typeVersion": 1,
      "position": [460, 300]
    },
    {
      "parameters": {
        "url": "={{$env.EVOLUTION_API_URL}}/message/sendText/my-whatsapp-bot",
        "authentication": "predefinedCredentialType",
        "nodeCredentialType": "evolutionApiApi",
        "method": "POST",
        "jsonParameters": true,
        "options": {},
        "bodyParametersJson": "={\n  \"number\": \"{{$json.body.data.key.remoteJid}}\",\n  \"text\": \"Hello! How can I help you today?\"\n}"
      },
      "name": "Send Reply",
      "type": "n8n-nodes-base.httpRequest",
      "typeVersion": 3,
      "position": [680, 300]
    }
  ],
  "connections": {
    "Webhook": {
      "main": [[{"node": "IF Hello", "type": "main", "index": 0}]]
    },
    "IF Hello": {
      "main": [[{"node": "Send Reply", "type": "main", "index": 0}]]
    }
  }
}
```

**Configure Evolution API Webhook:**

```bash
curl -X POST http://YOUR_EVOLUTION_API_URL/webhook/set/my-whatsapp-bot \
  -H "apikey: your-secure-api-key-here" \
  -H "Content-Type: application/json" \
  -d '{
    "url": "http://YOUR_N8N_URL:5678/webhook/whatsapp-webhook",
    "webhook_by_events": true,
    "webhook_base64": false,
    "events": [
      "MESSAGES_UPSERT"
    ]
  }'
```

### Example 2: Send Bulk Messages with Personalization

**Use Case:** Send promotional messages to a list of customers

**n8n Workflow:**
1. **Schedule Trigger** (Daily at 9 AM)
2. **Read CSV** (Customer list with names and numbers)
3. **Loop** (Iterate through customers)
4. **HTTP Request** (Send personalized message)
5. **Wait** (Delay between messages to avoid blocking)

```json
{
  "name": "Bulk Message Campaign",
  "nodes": [
    {
      "parameters": {
        "rule": {
          "interval": [{"field": "cronExpression", "expression": "0 9 * * *"}]
        }
      },
      "name": "Schedule Trigger",
      "type": "n8n-nodes-base.scheduleTrigger",
      "position": [240, 300]
    },
    {
      "parameters": {
        "filePath": "/data/customers.csv",
        "options": {}
      },
      "name": "Read CSV",
      "type": "n8n-nodes-base.readFile",
      "position": [460, 300]
    },
    {
      "parameters": {
        "batchSize": 1,
        "options": {}
      },
      "name": "Split In Batches",
      "type": "n8n-nodes-base.splitInBatches",
      "position": [680, 300]
    },
    {
      "parameters": {
        "url": "={{$env.EVOLUTION_API_URL}}/message/sendText/my-whatsapp-bot",
        "method": "POST",
        "jsonParameters": true,
        "bodyParametersJson": "={\n  \"number\": \"{{$json.phone}}\",\n  \"text\": \"Hi {{$json.name}}! 🎉 Special offer just for you...\"\n}"
      },
      "name": "Send Message",
      "type": "n8n-nodes-base.httpRequest",
      "position": [900, 300]
    },
    {
      "parameters": {
        "amount": 3,
        "unit": "seconds"
      },
      "name": "Wait",
      "type": "n8n-nodes-base.wait",
      "position": [1120, 300]
    }
  ]
}
```

### Example 3: Customer Support with AI (OpenAI Integration)

**Use Case:** Intelligent customer support bot

**Workflow:**
1. Receive message → 2. Extract intent (OpenAI) → 3. Query knowledge base → 4. Generate response → 5. Send reply

**Configuration in n8n:**

```json
{
  "name": "AI Customer Support",
  "nodes": [
    {
      "parameters": {},
      "name": "Webhook",
      "type": "n8n-nodes-base.webhook"
    },
    {
      "parameters": {
        "operation": "message",
        "model": "gpt-4",
        "messages": {
          "values": [
            {
              "role": "system",
              "content": "You are a helpful customer support assistant."
            },
            {
              "role": "user",
              "content": "={{$json.body.data.message.conversation}}"
            }
          ]
        }
      },
      "name": "OpenAI",
      "type": "n8n-nodes-base.openAi"
    },
    {
      "parameters": {
        "url": "={{$env.EVOLUTION_API_URL}}/message/sendText/my-whatsapp-bot",
        "method": "POST",
        "bodyParametersJson": "={\n  \"number\": \"{{$json.body.data.key.remoteJid}}\",\n  \"text\": \"{{$node.OpenAI.json.choices[0].message.content}}\"\n}"
      },
      "name": "Send AI Reply",
      "type": "n8n-nodes-base.httpRequest"
    }
  ]
}
```

### Example 4: Order Status Notifications

**Use Case:** Send order updates from your database/CRM

**Workflow:**
1. Database trigger (new order/status change)
2. Format message
3. Send WhatsApp notification

---

## Production Best Practices

### 1. Security Hardening

```bash
# Use Azure Key Vault for secrets
az keyvault create \
  --name whatsapp-keyvault \
  --resource-group whatsapp-automation-rg \
  --location eastus

# Store secrets
az keyvault secret set \
  --vault-name whatsapp-keyvault \
  --name evolution-api-key \
  --value "your-secure-api-key-here"

az keyvault secret set \
  --vault-name whatsapp-keyvault \
  --name database-password \
  --value "YourStrongPassword123!"
```

### 2. Enable HTTPS with Azure Application Gateway

```bash
# Create Application Gateway for SSL termination
az network application-gateway create \
  --name whatsapp-app-gateway \
  --resource-group whatsapp-automation-rg \
  --location eastus \
  --sku Standard_v2 \
  --public-ip-address whatsapp-public-ip \
  --vnet-name whatsapp-vnet \
  --subnet app-subnet
```

### 3. Implement Rate Limiting

In Evolution API, configure:

```env
# .env
RATE_LIMIT_ENABLED=true
RATE_LIMIT_MAX=100
RATE_LIMIT_WINDOW=60000
```

### 4. Set Up Auto-Scaling

```bash
# For App Service
az monitor autoscale create \
  --resource-group whatsapp-automation-rg \
  --resource evolution-api-webapp \
  --resource-type Microsoft.Web/serverfarms \
  --name autoscale-rules \
  --min-count 1 \
  --max-count 5 \
  --count 1

# Add scale-out rule (CPU > 70%)
az monitor autoscale rule create \
  --resource-group whatsapp-automation-rg \
  --autoscale-name autoscale-rules \
  --condition "Percentage CPU > 70 avg 5m" \
  --scale out 1
```

### 5. Database Backups

```bash
# Configure automated backups
az postgres flexible-server backup create \
  --resource-group whatsapp-automation-rg \
  --name whatsapp-postgres-server \
  --backup-name manual-backup-$(date +%Y%m%d)
```

### 6. Monitoring and Alerts

```bash
# Create Log Analytics Workspace
az monitor log-analytics workspace create \
  --resource-group whatsapp-automation-rg \
  --workspace-name whatsapp-logs

# Create alert for API errors
az monitor metrics alert create \
  --name high-error-rate \
  --resource-group whatsapp-automation-rg \
  --scopes /subscriptions/YOUR_SUBSCRIPTION/resourceGroups/whatsapp-automation-rg \
  --condition "count Http5xx > 10" \
  --description "Alert when error rate is high"
```

---

## Monitoring & Maintenance

### Application Insights Integration

```bash
# Create Application Insights
az monitor app-insights component create \
  --app whatsapp-insights \
  --location eastus \
  --resource-group whatsapp-automation-rg \
  --application-type web

# Get instrumentation key
az monitor app-insights component show \
  --app whatsapp-insights \
  --resource-group whatsapp-automation-rg \
  --query instrumentationKey
```

Add to Evolution API environment:

```env
APPINSIGHTS_INSTRUMENTATIONKEY=your-instrumentation-key
```

### Health Checks

Create a health check workflow in n8n:

```json
{
  "name": "Health Check",
  "nodes": [
    {
      "parameters": {
        "rule": {
          "interval": [{"field": "minutes", "minutesInterval": 5}]
        }
      },
      "name": "Every 5 Minutes",
      "type": "n8n-nodes-base.scheduleTrigger"
    },
    {
      "parameters": {
        "url": "={{$env.EVOLUTION_API_URL}}/",
        "options": {}
      },
      "name": "Check Evolution API",
      "type": "n8n-nodes-base.httpRequest"
    },
    {
      "parameters": {
        "conditions": {
          "number": [
            {
              "value1": "={{$json.statusCode}}",
              "operation": "notEqual",
              "value2": 200
            }
          ]
        }
      },
      "name": "IF Down",
      "type": "n8n-nodes-base.if"
    },
    {
      "parameters": {
        "url": "https://api.telegram.org/botYOUR_BOT_TOKEN/sendMessage",
        "method": "POST",
        "bodyParametersJson": "={\n  \"chat_id\": \"YOUR_CHAT_ID\",\n  \"text\": \"🚨 Evolution API is down!\"\n}"
      },
      "name": "Send Alert",
      "type": "n8n-nodes-base.httpRequest"
    }
  ]
}
```

### Logging Best Practices

```bash
# Stream Evolution API logs
az container logs \
  --resource-group whatsapp-automation-rg \
  --name evolution-api-container \
  --follow

# Stream n8n logs
az container logs \
  --resource-group whatsapp-automation-rg \
  --name n8n-container \
  --follow
```

---

## Troubleshooting

### Common Issues and Solutions

#### 1. WhatsApp Connection Drops

**Symptom:** Instance disconnects frequently

**Solutions:**
- Ensure phone has stable internet
- Check if phone battery optimization is disabled for WhatsApp
- Verify Redis is running and accessible
- Check Evolution API logs for errors

```bash
# Reconnect instance
curl -X GET http://YOUR_EVOLUTION_API_URL/instance/connect/my-whatsapp-bot \
  -H "apikey: your-secure-api-key-here"
```

#### 2. Database Connection Errors

**Symptom:** "Connection refused" or "Connection timeout"

**Solutions:**
```bash
# Check PostgreSQL firewall rules
az postgres flexible-server firewall-rule list \
  --resource-group whatsapp-automation-rg \
  --name whatsapp-postgres-server

# Test connection
psql "postgresql://adminuser:YourStrongPassword123!@whatsapp-postgres-server.postgres.database.azure.com:5432/evolution_db?sslmode=require"
```

#### 3. Messages Not Sending

**Symptom:** API returns success but message doesn't send

**Solutions:**
- Verify instance is connected
- Check if number is valid (include country code)
- Ensure number is not blocked
- Check rate limits

```bash
# Check instance status
curl -X GET http://YOUR_EVOLUTION_API_URL/instance/connectionState/my-whatsapp-bot \
  -H "apikey: your-secure-api-key-here"
```

#### 4. Webhook Not Triggering

**Symptom:** n8n workflow doesn't receive events

**Solutions:**
- Verify webhook URL is accessible from Evolution API
- Check webhook configuration
- Test webhook manually

```bash
# Get webhook config
curl -X GET http://YOUR_EVOLUTION_API_URL/webhook/find/my-whatsapp-bot \
  -H "apikey: your-secure-api-key-here"

# Test webhook
curl -X POST http://YOUR_N8N_URL:5678/webhook/whatsapp-webhook \
  -H "Content-Type: application/json" \
  -d '{"test": "data"}'
```

#### 5. High Memory Usage

**Symptom:** Container restarts or becomes unresponsive

**Solutions:**
```bash
# Check resource usage
az container show \
  --resource-group whatsapp-automation-rg \
  --name evolution-api-container \
  --query containers[0].instanceView.currentState

# Increase memory allocation
az container create \
  --resource-group whatsapp-automation-rg \
  --name evolution-api-container \
  --image atendai/evolution-api:latest \
  --memory 8
```

---

## Cost Optimization

### Estimated Monthly Costs (USD)

| Service | Configuration | Estimated Cost |
|---------|---------------|----------------|
| Container Instances (2x) | 2 vCPU, 4GB RAM each | $100 - $150 |
| PostgreSQL Flexible Server | Burstable B2s | $50 - $80 |
| Azure Cache for Redis | Basic C0 | $15 - $20 |
| Blob Storage | 100GB | $2 - $5 |
| Bandwidth | 500GB/month | $40 - $60 |
| **Total** | | **$207 - $315/month** |

### Cost Optimization Tips

1. **Use Spot Instances** for non-production environments
2. **Auto-shutdown** during off-hours if 24/7 availability isn't needed
3. **Use Azure Reserved Instances** for production (save up to 72%)
4. **Optimize Storage** by setting lifecycle policies

```bash
# Create lifecycle policy for old media files
az storage blob service-properties update \
  --account-name whatsappmediastorage \
  --enable-delete-retention true \
  --delete-retention-days 30
```

5. **Monitor and set budgets**

```bash
# Create budget alert
az consumption budget create \
  --budget-name whatsapp-budget \
  --amount 300 \
  --time-grain Monthly \
  --start-date 2025-01-01 \
  --end-date 2025-12-31 \
  --resource-group whatsapp-automation-rg
```

---

## Security Considerations

### 1. Network Security

```bash
# Create Network Security Group
az network nsg create \
  --resource-group whatsapp-automation-rg \
  --name whatsapp-nsg

# Allow only necessary ports
az network nsg rule create \
  --resource-group whatsapp-automation-rg \
  --nsg-name whatsapp-nsg \
  --name allow-https \
  --priority 100 \
  --destination-port-ranges 443 \
  --protocol Tcp \
  --access Allow
```

### 2. API Key Management

- **Never hardcode API keys** in n8n workflows
- Use **environment variables** or **Azure Key Vault**
- **Rotate keys regularly** (quarterly recommended)
- **Use different keys** for development and production

### 3. Data Encryption

```env
# Enable encryption at rest
DATABASE_ENCRYPTION_ENABLED=true

# Use SSL for database connections
DATABASE_CONNECTION_URI=postgresql://...?sslmode=require
```

### 4. Access Control

```bash
# Create Azure AD service principal for automated access
az ad sp create-for-rbac \
  --name whatsapp-automation-sp \
  --role Contributor \
  --scopes /subscriptions/YOUR_SUBSCRIPTION/resourceGroups/whatsapp-automation-rg
```

### 5. Audit Logging

```bash
# Enable diagnostic logging
az monitor diagnostic-settings create \
  --name whatsapp-diagnostics \
  --resource /subscriptions/YOUR_SUBSCRIPTION/resourceGroups/whatsapp-automation-rg \
  --logs '[{"category": "AllLogs", "enabled": true}]' \
  --workspace whatsapp-logs
```

---

## Advanced Features

### 1. Multi-Instance Management

Manage multiple WhatsApp numbers:

```bash
# Create multiple instances
for i in {1..5}; do
  curl -X POST http://YOUR_EVOLUTION_API_URL/instance/create \
    -H "apikey: your-secure-api-key-here" \
    -H "Content-Type: application/json" \
    -d "{
      \"instanceName\": \"bot-${i}\",
      \"token\": \"unique-token-${i}\",
      \"qrcode\": true
    }"
done
```

### 2. Message Templates

Create reusable message templates in n8n:

```json
{
  "templates": {
    "welcome": "Welcome {{name}}! Thanks for contacting us. 🎉",
    "order_confirmation": "Your order #{{order_id}} has been confirmed. Expected delivery: {{date}}",
    "support": "Thank you for your message. A support agent will respond within 24 hours."
  }
}
```

### 3. Analytics Integration

Send WhatsApp metrics to Azure Analytics:

```json
{
  "name": "Track Message Analytics",
  "nodes": [
    {
      "parameters": {},
      "name": "Message Sent Webhook",
      "type": "n8n-nodes-base.webhook"
    },
    {
      "parameters": {
        "functionCode": "return [\n  {\n    json: {\n      timestamp: new Date().toISOString(),\n      instance: $json.instance,\n      recipient: $json.recipient,\n      message_type: $json.type,\n      success: $json.success\n    }\n  }\n];"
      },
      "name": "Format Data",
      "type": "n8n-nodes-base.function"
    },
    {
      "parameters": {
        "url": "https://YOUR_ANALYTICS_ENDPOINT",
        "method": "POST"
      },
      "name": "Send to Analytics",
      "type": "n8n-nodes-base.httpRequest"
    }
  ]
}
```

### 4. Chatbot with Context Memory

Use Redis to store conversation context:

```javascript
// n8n Function Node
const Redis = require('redis');
const client = Redis.createClient({
  url: 'redis://:YOUR_REDIS_KEY@whatsapp-redis-cache.redis.cache.windows.net:6380'
});

await client.connect();

const userId = $json.user_id;
const context = await client.get(`context:${userId}`);

// Store new context
await client.set(`context:${userId}`, JSON.stringify({
  last_message: $json.message,
  timestamp: new Date().toISOString()
}), { EX: 3600 }); // Expire after 1 hour

return [{ json: { context: context } }];
```

---

## Performance Tuning

### 1. Database Optimization

```sql
-- Create indexes for frequently queried fields
CREATE INDEX idx_instance_name ON "Instance" ("name");
CREATE INDEX idx_message_timestamp ON "Message" ("timestamp");

-- Optimize queries
VACUUM ANALYZE;
```

### 2. Redis Caching Strategy

```env
# Evolution API caching configuration
CACHE_REDIS_ENABLED=true
CACHE_REDIS_TTL=3600
CACHE_REDIS_PREFIX_KEY=evolution:cache
CACHE_LOCAL_ENABLED=false
```

### 3. Container Resource Limits

```bash
# Optimize container resources based on load
az container create \
  --cpu 4 \
  --memory 8 \
  --environment-variables \
    NODE_OPTIONS="--max-old-space-size=7168"
```

---

## Disaster Recovery

### 1. Backup Strategy

```bash
#!/bin/bash
# backup-script.sh

# Database backup
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
az postgres flexible-server backup create \
  --resource-group whatsapp-automation-rg \
  --name whatsapp-postgres-server \
  --backup-name "backup_${TIMESTAMP}"

# Container configuration backup
az container export \
  --resource-group whatsapp-automation-rg \
  --name evolution-api-container \
  --file "evolution_backup_${TIMESTAMP}.yaml"

# Upload to Blob Storage
az storage blob upload \
  --account-name whatsappmediastorage \
  --container-name backups \
  --name "evolution_backup_${TIMESTAMP}.yaml" \
  --file "evolution_backup_${TIMESTAMP}.yaml"
```

### 2. Recovery Procedures

```bash
# Restore database from backup
az postgres flexible-server restore \
  --resource-group whatsapp-automation-rg \
  --name whatsapp-postgres-server-restored \
  --source-server whatsapp-postgres-server \
  --restore-time "2025-01-01T00:00:00Z"
```

---

## Additional Resources

### Official Documentation

- [Evolution API Documentation](https://doc.evolution-api.com)
- [n8n Documentation](https://docs.n8n.io)
- [Azure Container Instances Docs](https://learn.microsoft.com/en-us/azure/container-instances/)
- [Azure Database for PostgreSQL Docs](https://learn.microsoft.com/en-us/azure/postgresql/)

### Community Resources

- [Evolution API GitHub](https://github.com/EvolutionAPI/evolution-api)
- [n8n Community Forum](https://community.n8n.io)
- [Evolution API WhatsApp Group](https://evolution-api.com/whatsapp)
- [Evolution API Discord](https://evolution-api.com/discord)

### Useful Tools

- [Postman Collection for Evolution API](https://evolution-api.com/postman)
- [Azure CLI Documentation](https://learn.microsoft.com/en-us/cli/azure/)
- [Redis Commander](https://github.com/joeferner/redis-commander) - Redis GUI
- [pgAdmin](https://www.pgadmin.org) - PostgreSQL GUI

---

## Contributing

This project welcomes contributions and suggestions. To contribute:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

## License

This project documentation is licensed under the MIT License. See [LICENSE](LICENSE) file for details.

Evolution API is licensed under Apache-2.0. See their [license](https://github.com/EvolutionAPI/evolution-api/blob/main/LICENSE) for details.

---

## Support

If you encounter issues or have questions:

1. Check the [Troubleshooting](#troubleshooting) section
2. Search [GitHub Issues](https://github.com/MuhammadTayyabIlyas/WhatsApp_AZURE_n8n_Automation/issues)
3. Join the [Evolution API Community](https://evolution-api.com/discord)
4. Create a new issue with detailed information

---

## Changelog

### Version 1.0.0 (2025-01-02)
- Initial release
- Complete Azure deployment guide
- n8n integration workflows
- Production best practices
- Security hardening guide

---

## Acknowledgments

- [Evolution API Team](https://github.com/EvolutionAPI) for the amazing WhatsApp API
- [n8n Team](https://n8n.io) for the workflow automation platform
- [Baileys Library](https://github.com/WhiskeySockets/Baileys) for WhatsApp Web implementation
- Azure Community for cloud infrastructure support

---

<div align="center">

**Made with ❤️ for WhatsApp Automation**

[Report Bug](https://github.com/MuhammadTayyabIlyas/WhatsApp_AZURE_n8n_Automation/issues) • [Request Feature](https://github.com/MuhammadTayyabIlyas/WhatsApp_AZURE_n8n_Automation/issues) • [Documentation](https://doc.evolution-api.com)

</div>
