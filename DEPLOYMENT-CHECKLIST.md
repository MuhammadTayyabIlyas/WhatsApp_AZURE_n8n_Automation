# Deployment Checklist

Use this checklist to ensure a complete and secure deployment.

## Pre-Deployment

### Azure Account Setup
- [ ] Azure subscription is active
- [ ] Azure CLI installed and configured
- [ ] Logged in to correct subscription: `az account show`
- [ ] Required permissions (Contributor or Owner role)

### Repository Setup
- [ ] Repository cloned or forked
- [ ] Reviewed architecture documentation
- [ ] Understood pricing implications

## Infrastructure Setup

### Resource Group
- [ ] Created resource group in desired region
- [ ] Named following convention: `<project>-<env>-rg`
- [ ] Tagged with project metadata

### Database (PostgreSQL)
- [ ] Created PostgreSQL Flexible Server
- [ ] Generated strong admin password (stored securely)
- [ ] Created databases: `evolution_db`, `n8n_db`
- [ ] Configured firewall rules (Azure services allowed)
- [ ] Enabled SSL connections
- [ ] Configured backup retention
- [ ] Tested connection from local machine

### Redis Cache
- [ ] Created Azure Cache for Redis
- [ ] Selected appropriate tier (Basic for dev, Standard for prod)
- [ ] Retrieved primary and secondary keys
- [ ] Tested connection
- [ ] Configured non-SSL port if needed (port 6379)

### Storage Account
- [ ] Created Storage Account
- [ ] Created container: `evolution-media`
- [ ] Set public access level (Blob for public, Private for secure)
- [ ] Retrieved connection string and keys
- [ ] Tested upload/download

### Networking (Production Only)
- [ ] Created Virtual Network
- [ ] Configured subnets (app, database)
- [ ] Created Network Security Group
- [ ] Configured NSG rules (allow only necessary ports)
- [ ] Set up Application Gateway for SSL termination

## Evolution API Deployment

### Configuration
- [ ] Created `.env` file with all required variables
- [ ] Set strong `AUTHENTICATION_API_KEY`
- [ ] Configured `DATABASE_CONNECTION_URI` with SSL
- [ ] Configured `REDIS_URI` correctly
- [ ] Set `SERVER_URL` to actual domain/IP
- [ ] Configured S3/Blob storage settings
- [ ] Reviewed and set log levels

### Container Deployment
- [ ] Deployed container (ACI or App Service)
- [ ] Verified container is running
- [ ] Checked logs for errors
- [ ] Tested health endpoint: `GET /`
- [ ] Verified API responds to requests

### Security
- [ ] API key is strong and unique
- [ ] Database password meets complexity requirements
- [ ] SSL/TLS enabled for all connections
- [ ] Secrets stored in Azure Key Vault (production)
- [ ] Rate limiting configured
- [ ] CORS properly configured

## n8n Deployment

### Configuration
- [ ] Set encryption key: `N8N_ENCRYPTION_KEY`
- [ ] Configured database connection
- [ ] Set webhook URL correctly
- [ ] Configured timezone
- [ ] Set execution data retention policy

### Container Deployment
- [ ] Deployed n8n container
- [ ] Verified container is running
- [ ] Accessed web interface
- [ ] Created admin account
- [ ] Tested workflow execution

### Integration
- [ ] Added Evolution API credentials in n8n
- [ ] Tested connection to Evolution API
- [ ] Created sample workflow
- [ ] Tested webhook triggers

## WhatsApp Connection

### Instance Creation
- [ ] Created WhatsApp instance via API
- [ ] Generated unique instance name
- [ ] Set instance token
- [ ] Enabled QR code

### Phone Connection
- [ ] Retrieved QR code
- [ ] Scanned with WhatsApp (Settings → Linked Devices)
- [ ] Verified connection status: `connectionState` = "open"
- [ ] Tested sending message
- [ ] Tested receiving message

### Webhook Configuration
- [ ] Set webhook URL pointing to n8n
- [ ] Enabled desired events (MESSAGES_UPSERT, etc.)
- [ ] Tested webhook delivery
- [ ] Verified n8n receives events

## Monitoring & Alerts

### Application Insights
- [ ] Created Application Insights resource
- [ ] Configured instrumentation keys
- [ ] Verified telemetry is flowing
- [ ] Created custom metrics dashboard

### Alerts
- [ ] Created alert for high error rate
- [ ] Created alert for high CPU usage
- [ ] Created alert for high memory usage
- [ ] Created alert for database connection failures
- [ ] Configured alert notification channels (email, SMS)

### Health Checks
- [ ] Created n8n health check workflow
- [ ] Scheduled regular health checks
- [ ] Configured alerts for failed health checks

## Security Hardening

### Network Security
- [ ] Enabled HTTPS (SSL/TLS)
- [ ] Configured custom domain (production)
- [ ] Implemented Web Application Firewall
- [ ] Restricted access to management ports
- [ ] Enabled DDoS protection (production)

### Access Control
- [ ] Implemented least privilege access
- [ ] Created service principal for automation
- [ ] Enabled Azure AD authentication (if applicable)
- [ ] Reviewed and minimized firewall rules
- [ ] Enabled audit logging

### Data Protection
- [ ] Enabled encryption at rest (database)
- [ ] Enabled encryption in transit (SSL)
- [ ] Configured backup encryption
- [ ] Set up key rotation schedule
- [ ] Reviewed data retention policies

## Backup & Recovery

### Database Backups
- [ ] Enabled automated backups
- [ ] Set backup retention period (7-35 days)
- [ ] Tested backup restore procedure
- [ ] Documented recovery steps
- [ ] Created backup schedule

### Configuration Backups
- [ ] Exported container configurations
- [ ] Backed up environment variables
- [ ] Saved n8n workflows
- [ ] Stored in version control or secure location

## Documentation

### Internal Documentation
- [ ] Documented deployment steps taken
- [ ] Recorded all credentials (in secure vault)
- [ ] Created network diagram
- [ ] Documented custom configurations
- [ ] Created runbook for common operations

### Operational Procedures
- [ ] Documented restart procedures
- [ ] Created incident response plan
- [ ] Documented scaling procedures
- [ ] Created troubleshooting guide
- [ ] Defined on-call procedures

## Testing

### Functional Testing
- [ ] Sent test message successfully
- [ ] Received message in n8n workflow
- [ ] Tested all planned automation workflows
- [ ] Verified media file upload/download
- [ ] Tested error handling

### Performance Testing
- [ ] Load tested with expected message volume
- [ ] Verified response times acceptable
- [ ] Tested under peak load
- [ ] Verified auto-scaling (if configured)

### Security Testing
- [ ] Attempted unauthorized API access (should fail)
- [ ] Verified API key requirement
- [ ] Tested SQL injection protection
- [ ] Verified XSS protection
- [ ] Ran security vulnerability scan

## Go-Live

### Pre-Launch
- [ ] All checklist items completed
- [ ] Stakeholders notified of launch plan
- [ ] Support team trained
- [ ] Rollback plan documented
- [ ] Communication plan ready

### Launch
- [ ] Switched to production environment
- [ ] Monitored logs during initial period
- [ ] Verified all integrations working
- [ ] Confirmed metrics being collected
- [ ] Notified stakeholders of successful launch

### Post-Launch
- [ ] Monitored for 24 hours
- [ ] Reviewed metrics and logs
- [ ] Addressed any issues found
- [ ] Gathered user feedback
- [ ] Scheduled first maintenance window

## Ongoing Maintenance

### Weekly Tasks
- [ ] Review error logs
- [ ] Check performance metrics
- [ ] Verify backups completed
- [ ] Review security alerts
- [ ] Check resource utilization

### Monthly Tasks
- [ ] Review and optimize costs
- [ ] Update documentation
- [ ] Review access controls
- [ ] Test backup restore
- [ ] Update dependencies

### Quarterly Tasks
- [ ] Rotate API keys and secrets
- [ ] Review and update security policies
- [ ] Conduct security audit
- [ ] Review and optimize resource allocation
- [ ] Plan capacity for next quarter

---

## Sign-Off

| Role | Name | Date | Signature |
|------|------|------|-----------|
| DevOps Engineer | | | |
| Security Officer | | | |
| Project Manager | | | |

---

**Notes:**
- Check boxes as items are completed
- Document any deviations from standard procedures
- Keep this checklist with project documentation
- Update checklist based on lessons learned
