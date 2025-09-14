# 8020perfect.com Domain Migration Guide

This guide covers migrating the 8020perfect.com domain and its subdomains from the old server to the new ASW infrastructure.

## Current State

### Old Server (Source)
- **Domain**: 8020perfect.com (pointing to old server)
- **Subdomains**: 
  - `dev.8020perfect.com`
  - `n8n.8020perfect.com`
  - Various project subdomains
- **Services**: Running on old infrastructure

### New Server (Target)
- **Servers**: 
  - Netcup: `152.53.136.76`
  - Digital Ocean: `209.97.139.211`
- **Infrastructure**: ASW framework with automatic subdomain management
- **Status**: Ready to receive domain but not yet configured

## Domain Migration Steps

### Phase 1: Preparation (Pre-migration)

#### 1. Audit Current Subdomains
```bash
# On old server - document all active subdomains
nslookup 8020perfect.com
dig 8020perfect.com ANY
```

Create inventory:
- `dev.8020perfect.com` → Port/Service
- `n8n.8020perfect.com` → Port/Service  
- `project1.8020perfect.com` → Port/Service
- etc.

#### 2. Setup DNS Management
- **Current DNS Provider**: [TO BE DETERMINED]
- **Access Required**: DNS management credentials
- **Backup**: Export current DNS records

#### 3. Prepare New Server
```bash
# Verify ASW infrastructure is ready
/opt/asw/agentic-framework-infrastructure/bin/asw-nginx-manager help
/opt/asw/agentic-framework-infrastructure/bin/asw-dev-ssl help
```

### Phase 2: DNS Migration

#### 1. Lower TTL Values (Pre-migration)
```bash
# 24-48 hours before migration
# Set TTL to 300 seconds (5 minutes) for faster propagation
```

#### 2. Update DNS Records
```bash
# Main domain A record
8020perfect.com → 152.53.136.76 (or chosen server IP)

# Wildcard subdomain
*.8020perfect.com → 152.53.136.76

# Specific subdomains (if needed)
dev.8020perfect.com → 152.53.136.76
n8n.8020perfect.com → 152.53.136.76
```

#### 3. Verify DNS Propagation
```bash
# Check DNS propagation
nslookup 8020perfect.com
dig @8.8.8.8 8020perfect.com
dig @1.1.1.1 8020perfect.com

# Online tools
# https://dnschecker.org/
```

### Phase 3: Server Configuration

#### 1. Configure Main Domain
```bash
# Setup main domain nginx configuration
/opt/asw/agentic-framework-infrastructure/bin/asw-nginx-manager setup-main 8020perfect.com
```

#### 2. Setup SSL for Main Domain
```bash
# For production (Let's Encrypt)
/opt/asw/agentic-framework-infrastructure/bin/asw-nginx-manager setup-ssl 8020perfect.com --email admin@8020perfect.com

# For development (self-signed)
/opt/asw/agentic-framework-infrastructure/bin/asw-dev-ssl 8020perfect.com
```

#### 3. Configure Subdomain Automation
The ASW infrastructure should automatically handle subdomains once the main domain is configured.

### Phase 4: Service Migration

#### 1. Migrate Core Services

**N8N Service:**
```bash
# If N8N needs to be migrated
cd /opt/asw/projects/personal
git clone <n8n-repo-url> n8n
cd n8n
/opt/asw/agentic-framework-infrastructure/bin/asw-port-manager allocate n8n
/opt/asw/agentic-framework-infrastructure/bin/asw-dev-server start --domain n8n.8020perfect.com
```

**Dev Environment:**
```bash
# Main development subdomain
/opt/asw/agentic-framework-infrastructure/bin/asw-nginx-manager setup-project dev
```

#### 2. Migrate Project Subdomains
```bash
# For each existing project
cd /opt/asw/projects/personal/<project-name>
/opt/asw/agentic-framework-infrastructure/bin/asw-dev-server start
# This automatically creates <project-name>.8020perfect.com
```

### Phase 5: Testing & Validation

#### 1. Test All Subdomains
```bash
#!/bin/bash
# Test script for all subdomains

SUBDOMAINS=(
    "dev"
    "n8n" 
    "tennis-tracker"
    # Add all project subdomains
)

for subdomain in "${SUBDOMAINS[@]}"; do
    echo "Testing $subdomain.8020perfect.com..."
    curl -I "$subdomain.8020perfect.com" || echo "FAILED: $subdomain"
done
```

#### 2. SSL Certificate Validation
```bash
# Check SSL certificates
for subdomain in dev n8n tennis-tracker; do
    echo "SSL check: $subdomain.8020perfect.com"
    openssl s_client -connect $subdomain.8020perfect.com:443 -servername $subdomain.8020perfect.com < /dev/null
done
```

#### 3. Service Health Checks
```bash
# Verify all services are responding
curl http://dev.8020perfect.com/health
curl http://n8n.8020perfect.com/health  
curl http://tennis-tracker.8020perfect.com/
```

## Migration Checklist

### Pre-Migration
- [ ] Document all current subdomains and services
- [ ] Get DNS management access credentials  
- [ ] Backup current DNS records
- [ ] Lower TTL values 24-48 hours ahead
- [ ] Verify ASW infrastructure is ready
- [ ] Test ASW subdomain creation on test domain

### During Migration
- [ ] Update main domain A record
- [ ] Update wildcard subdomain record
- [ ] Configure nginx for main domain
- [ ] Setup SSL certificates
- [ ] Test DNS propagation (allow 5-15 minutes)
- [ ] Verify main domain responds
- [ ] Test subdomain automation

### Post-Migration  
- [ ] Migrate all services to new server
- [ ] Test all subdomain access
- [ ] Verify SSL certificates  
- [ ] Update any hardcoded URLs in applications
- [ ] Monitor logs for issues
- [ ] Update documentation with new URLs
- [ ] Raise TTL values back to normal (3600s)

## Rollback Plan

### If Migration Fails
```bash
# Quick rollback - revert DNS
# Change A records back to old server IP
8020perfect.com → <old-server-ip>
*.8020perfect.com → <old-server-ip>

# DNS should propagate within 5-15 minutes (due to low TTL)
```

### Extended Issues
- Keep old server running for 24-48 hours during migration
- Gradual subdomain migration (one at a time)
- Monitor both servers during transition

## Post-Migration Tasks

### 1. Update ASW Configuration
```bash
# Update default domain in ASW scripts
# Edit /opt/asw/agentic-framework-infrastructure/bin/asw-dev-server
# Change SERVER_DOMAIN="dev.8020perfect.com" if needed
```

### 2. Documentation Updates
- [ ] Update clone-existing-project.md with working subdomain examples
- [ ] Update project-cleanup-guide.md with domain cleanup steps
- [ ] Create production deployment guide
- [ ] Update team documentation with new URLs

### 3. Monitoring Setup
```bash
# Setup monitoring for all subdomains
# Monitor SSL certificate expiration
# Setup health checks for critical services
```

## Automatic Subdomain Management (Post-Migration)

Once the domain is migrated, the ASW infrastructure provides:

### Project Creation
```bash
# Creates subdomain automatically
cd /opt/asw/projects/personal/my-new-project
/opt/asw/agentic-framework-infrastructure/bin/asw-dev-server start
# → my-new-project.8020perfect.com available immediately
```

### Custom Subdomains
```bash
# Custom subdomain names
/opt/asw/agentic-framework-infrastructure/bin/asw-dev-server start --domain custom-name.8020perfect.com
```

### SSL Automation
```bash
# HTTPS with self-signed certs (dev)
/opt/asw/agentic-framework-infrastructure/bin/asw-dev-server start --https

# Production SSL (Let's Encrypt) - future enhancement
/opt/asw/agentic-framework-infrastructure/bin/asw-nginx-manager setup-ssl project.8020perfect.com
```

## Troubleshooting

### Common Issues

#### DNS Not Propagating
```bash
# Check multiple DNS servers
dig @8.8.8.8 8020perfect.com
dig @1.1.1.1 8020perfect.com
dig @208.67.222.222 8020perfect.com

# Clear local DNS cache
sudo systemctl flush-dns
# or
sudo dscacheutil -flushcache (macOS)
```

#### Nginx Configuration Issues
```bash
# Test nginx configuration
sudo nginx -t

# Check nginx status  
sudo systemctl status nginx

# Reload nginx
sudo systemctl reload nginx

# Check nginx logs
sudo tail -f /var/log/nginx/error.log
```

#### SSL Certificate Issues
```bash
# Check certificate details
openssl x509 -in /etc/ssl/asw-dev/subdomain.8020perfect.com.crt -text -noout

# Regenerate certificate
/opt/asw/agentic-framework-infrastructure/bin/asw-dev-ssl subdomain.8020perfect.com
```

#### Port Conflicts
```bash
# Check port allocations
/opt/asw/agentic-framework-infrastructure/bin/asw-port-manager list

# Release stuck ports
/opt/asw/agentic-framework-infrastructure/bin/asw-port-manager release project-name
```

## Migration Timeline

### Recommended Schedule
- **Week -1**: Preparation and testing
- **Day -2**: Lower TTL values  
- **Day 0**: Execute migration (low traffic time)
- **Day +1**: Monitor and fix issues
- **Week +1**: Complete service migration
- **Week +2**: Decommission old server

### Critical Path
1. DNS record updates (5-15 minutes to propagate)
2. Nginx configuration (immediate)
3. SSL setup (immediate for self-signed)
4. Service migration (per service, variable time)

## Contacts & Resources

### Domain Management
- **DNS Provider**: [TO BE DETERMINED]
- **Login Credentials**: [SECURE LOCATION]
- **Backup Contact**: [EMERGENCY CONTACT]

### Server Access
- **Netcup**: `ssh -A -p 2222 cc-user@152.53.136.76`
- **Digital Ocean**: `ssh -A -p 2222 cc-user@209.97.139.211`

### Documentation
- **ASW Guides**: `/opt/asw/docs/`
- **Migration Status**: [TO BE CREATED]
- **Service Inventory**: [TO BE CREATED]

---

*Last updated: 2025-01-13*
*Status: Pre-migration planning*
*Next: Determine DNS provider and current subdomain inventory*