# Quick Start Guide

Get up and running with WhatsApp automation in 30 minutes!

## Prerequisites Checklist

- [ ] Azure Account with active subscription
- [ ] Azure CLI installed and logged in
- [ ] WhatsApp number (not used with WhatsApp Business API)
- [ ] Basic understanding of REST APIs

## Step 1: Clone Evolution API

```bash
# Clone the Evolution API repository
git clone https://github.com/EvolutionAPI/evolution-api.git
cd evolution-api
```

## Step 2: Deploy to Azure (Fastest Method)

### Using Azure Container Instances

```bash
# Set variables
RESOURCE_GROUP="whatsapp-automation-rg"
LOCATION="eastus"
API_KEY="your-secure-api-key-$(openssl rand -hex 16)"

# Create resource group
az group create --name $RESOURCE_GROUP --location $LOCATION

# Create PostgreSQL database
az postgres flexible-server create \
  --name whatsapp-db-$RANDOM \
  --resource-group $RESOURCE_GROUP \
  --location $LOCATION \
  --admin-user dbadmin \
  --admin-password "SecurePass123!" \
  --sku-name Standard_B2s \
  --public-access 0.0.0.0

# Deploy Evolution API
az container create \
  --resource-group $RESOURCE_GROUP \
  --name evolution-api \
  --image atendai/evolution-api:latest \
  --dns-name-label evolution-api-$RANDOM \
  --ports 8080 \
  --cpu 2 \
  --memory 4 \
  --environment-variables \
    SERVER_URL=http://evolution-api.azurecontainer.io:8080 \
    DATABASE_PROVIDER=postgresql \
    AUTHENTICATION_API_KEY=$API_KEY

# Get your API URL
echo "Your Evolution API is ready at:"
az container show \
  --resource-group $RESOURCE_GROUP \
  --name evolution-api \
  --query ipAddress.fqdn \
  --output tsv
```

## Step 3: Deploy n8n

```bash
# Deploy n8n
az container create \
  --resource-group $RESOURCE_GROUP \
  --name n8n \
  --image n8nio/n8n:latest \
  --dns-name-label n8n-$RANDOM \
  --ports 5678 \
  --cpu 2 \
  --memory 4 \
  --environment-variables \
    N8N_HOST=0.0.0.0 \
    N8N_PORT=5678

# Get n8n URL
echo "Your n8n is ready at:"
az container show \
  --resource-group $RESOURCE_GROUP \
  --name n8n \
  --query ipAddress.fqdn \
  --output tsv
```

## Step 4: Connect WhatsApp

```bash
# Save your Evolution API URL
EVOLUTION_URL="http://YOUR_CONTAINER_FQDN:8080"

# Create WhatsApp instance
curl -X POST $EVOLUTION_URL/instance/create \
  -H "apikey: $API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "instanceName": "my-bot",
    "token": "my-instance-token",
    "qrcode": true
  }'

# Get QR Code to scan
curl -X GET $EVOLUTION_URL/instance/connect/my-bot \
  -H "apikey: $API_KEY"
```

**Open WhatsApp on your phone:**
1. Go to Settings → Linked Devices
2. Tap "Link a Device"
3. Scan the QR code from the response

## Step 5: Send Your First Message

```bash
# Send a test message
curl -X POST $EVOLUTION_URL/message/sendText/my-bot \
  -H "apikey: $API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "number": "1234567890",
    "text": "Hello from Evolution API! 🚀"
  }'
```

## Step 6: Create Your First n8n Workflow

1. Open n8n in your browser (the URL from Step 3)
2. Create new workflow
3. Add "Webhook" node
4. Add "HTTP Request" node pointing to Evolution API
5. Configure to send messages when webhook is triggered

## Next Steps

- [ ] Read the full [README.md](README.md) for advanced features
- [ ] Set up webhooks for receiving messages
- [ ] Configure SSL/HTTPS for production
- [ ] Enable Redis for better performance
- [ ] Set up monitoring and alerts

## Common Commands

```bash
# Check Evolution API status
curl $EVOLUTION_URL/ -H "apikey: $API_KEY"

# List all instances
curl $EVOLUTION_URL/instance/fetchInstances -H "apikey: $API_KEY"

# Check instance connection
curl $EVOLUTION_URL/instance/connectionState/my-bot -H "apikey: $API_KEY"

# View container logs
az container logs --resource-group $RESOURCE_GROUP --name evolution-api
```

## Troubleshooting

### WhatsApp won't connect
- Ensure QR code is fresh (expires after 60 seconds)
- Check phone has internet connection
- Verify instance was created successfully

### Can't send messages
- Verify instance is connected: `connectionState` should return "open"
- Check phone number format: include country code (e.g., "1234567890")
- Ensure API key is correct

### Container won't start
- Check logs: `az container logs --name evolution-api`
- Verify database connection string is correct
- Ensure ports are not blocked

## Need Help?

- 📖 [Full Documentation](README.md)
- 💬 [Evolution API Community](https://evolution-api.com/discord)
- 🐛 [Report Issues](https://github.com/MuhammadTayyabIlyas/WhatsApp_AZURE_n8n_Automation/issues)

---

**Estimated setup time:** 20-30 minutes
**Estimated monthly cost:** $50-100 (Azure resources)
