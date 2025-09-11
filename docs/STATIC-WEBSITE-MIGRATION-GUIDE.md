# ASW Static Website Migration Guide

Complete documentation for migrating static websites to the ASW framework on a new VPS.

## Overview

This guide documents the complete process of migrating a static website from an old VPS to a new ASW-managed VPS, including DNS changes, SSL setup, and creating reusable scripts.

## Example Migration: casadaspedrasportugal.com

**Source:** Old VPS (209.97.139.211)  
**Destination:** New ASW VPS (152.53.136.76)  
**Result:** Fully functional HTTPS website with ASW management

---

## Prerequisites

- New VPS with ASW framework installed
- SSH access to both old and new VPS
- Domain DNS management access
- Email for SSL certificates

---

## Step 1: Analyze Old VPS Setup

First, understand the existing website structure on the old VPS:

```bash
# Check nginx configuration
ssh -A -p 2222 cc-user@OLD_VPS_IP "cat /etc/nginx/sites-available/casadaspedrasportugal.com"

# Find website repository location
ssh -A -p 2222 cc-user@OLD_VPS_IP "find / -name '.git' -type d 2>/dev/null | grep -i casadas"

# Check website files structure
ssh -A -p 2222 cc-user@OLD_VPS_IP "ls -la /opt/web-projects/casadaspedras/"

# Check deployment workflow
ssh -A -p 2222 cc-user@OLD_VPS_IP "cat /opt/web-projects/casadaspedras/scripts/deploy.sh"
```

**Key findings:**
- Repository: `/opt/web-projects/casadaspedras/`
- Source files: `/opt/web-projects/casadaspedras/www/`  
- Web directory: `/var/www/casadaspedrasportugal.com/`
- Workflow: Edit in repo → Deploy script copies to web directory → Nginx serves

---

## Step 2: Clone Website Repository to New VPS

Standardize under ASW framework structure:

```bash
# On new VPS - clone to ASW projects directory
ssh -A -p 2222 cc-user@NEW_VPS_IP "cd /opt/asw/projects/personal && git clone git@github.com:jtjiver/casadaspedras-website.git"

# Verify structure
ssh -A -p 2222 cc-user@NEW_VPS_IP "ls -la /opt/asw/projects/personal/casadaspedras-website/"
```

**ASW Structure:**
```
/opt/asw/projects/personal/casadaspedras-website/
├── www/              # Website source files
├── scripts/          # Deployment scripts
├── .git/            # Git repository
└── README.md        # Documentation
```

---

## Step 3: Prepare Web Directory and Deploy Files

Install required tools and deploy website files:

```bash
# Install rsync for deployment script
ssh -A -p 2222 cc-user@NEW_VPS_IP "sudo apt update && sudo apt install -y rsync"

# Create web user account for proper permissions
ssh -A -p 2222 cc-user@NEW_VPS_IP "sudo useradd -r -s /bin/false web-user 2>/dev/null || true"

# Create web directory
ssh -A -p 2222 cc-user@NEW_VPS_IP "sudo mkdir -p /var/www/casadaspedrasportugal.com"

# Run deployment script to copy files from project to web directory
ssh -A -p 2222 cc-user@NEW_VPS_IP "cd /opt/asw/projects/personal/casadaspedras-website && ./scripts/deploy.sh"
```

**Deploy Script Output:**
```
Deploying Casa das Pedras website...
Source: /opt/asw/projects/personal/casadaspedras-website/www
Destination: /var/www/casadaspedrasportugal.com
✅ Deployment complete!
```

---

## Step 4: Create ASW Static Website Setup Script

Since ASW framework didn't have static website support, we created a reusable script:

**Created:** `/opt/asw/scripts/setup-static-website.sh`

### Script Features:
- Nginx configuration with security headers
- Site enabling and testing
- Proper caching rules  
- Health check endpoint
- Clear next steps instructions

### Script Usage:
```bash
# Usage
./setup-static-website.sh <domain> <document-root> [email]

# Example
./setup-static-website.sh casadaspedrasportugal.com /var/www/casadaspedrasportugal.com jrtownsend@gmail.com
```

### Script Creation Process:
```bash
# Create script locally (in ASW framework repository)
cat > /opt/asw/scripts/setup-static-website.sh << 'EOF'
#!/bin/bash
# ASW Static Website Setup Script
# [Full script content documented separately]
EOF

# Make executable
chmod +x /opt/asw/scripts/setup-static-website.sh
```

---

## Step 5: Configure Nginx Using ASW Script

Run the newly created script remotely using the ASW push model:

```bash
# Run script on VPS using bash -s < pattern
ssh -A -p 2222 cc-user@NEW_VPS_IP "bash -s casadaspedrasportugal.com /var/www/casadaspedrasportugal.com jrtownsend@gmail.com" < /opt/asw/scripts/setup-static-website.sh
```

**Script Output:**
```
🌐 ASW Static Website Setup
Domain: casadaspedrasportugal.com
Document root: /var/www/casadaspedrasportugal.com
Email: jrtownsend@gmail.com

📝 Creating nginx configuration...
✅ Nginx configuration created
🔗 Enabling nginx site...
🧪 Testing nginx configuration...
✅ Nginx configuration test passed
🔄 Reloading nginx...
✅ Nginx reloaded successfully

🎉 Static website configured successfully!
```

---

## Step 6: Test Local Website Serving

Verify the website serves correctly before updating DNS:

```bash
# Test local serving with Host header
ssh -A -p 2222 cc-user@NEW_VPS_IP "curl -H 'Host: casadaspedrasportugal.com' http://localhost/ | head -5"

# Test health check endpoint
ssh -A -p 2222 cc-user@NEW_VPS_IP "curl -H 'Host: casadaspedrasportugal.com' http://localhost/nginx-health"
```

**Expected Results:**
- HTTP 200 response
- HTML content served correctly
- Health check returns "healthy"

---

## Step 7: Update DNS Records

**CRITICAL:** Update DNS A records to point to new VPS.

### DNS Changes Required:
```
Record Type: A
Name: @
Value: 152.53.136.76 (new VPS IP)
Previous: 209.97.139.211 (old VPS IP)

Record Type: A  
Name: www
Value: 152.53.136.76 (new VPS IP)
Previous: 209.97.139.211 (old VPS IP)
```

### Verify DNS Propagation:
```bash
# Check root domain
nslookup casadaspedrasportugal.com

# Check www subdomain  
nslookup www.casadaspedrasportugal.com

# Quick verification
dig +short casadaspedrasportugal.com
# Should return: 152.53.136.76
```

---

## Step 8: Test Public Website Access

Once DNS propagates, test public access:

```bash
# Test HTTP access
curl -I http://casadaspedrasportugal.com

# Verify serving from new VPS
curl -s http://casadaspedrasportugal.com | head -5
```

**Expected:** HTTP 200 with website content served from new VPS.

---

## Step 9: Set Up SSL Certificate

Configure HTTPS using Let's Encrypt:

```bash
# Install SSL certificate
ssh -A -p 2222 cc-user@NEW_VPS_IP "sudo certbot --nginx -d casadaspedrasportugal.com -d www.casadaspedrasportugal.com --email jrtownsend@gmail.com --agree-tos --no-eff-email"
```

**SSL Setup Output:**
```
Requesting a certificate for casadaspedrasportugal.com and www.casadaspedrasportugal.com
Successfully received certificate.
Certificate is saved at: /etc/letsencrypt/live/casadaspedrasportugal.com/fullchain.pem
Key is saved at: /etc/letsencrypt/live/casadaspedrasportugal.com/privkey.pem
This certificate expires on 2025-12-10.

Successfully deployed certificate for casadaspedrasportugal.com
Successfully deployed certificate for www.casadaspedrasportugal.com
Congratulations! You have successfully enabled HTTPS
```

---

## Step 10: Verify HTTPS Access

Test final HTTPS functionality:

```bash
# Test HTTPS access
curl -I https://casadaspedrasportugal.com

# Test redirect from HTTP to HTTPS
curl -I http://casadaspedrasportugal.com
# Should show 301/302 redirect to HTTPS
```

---

## Step 11: Content Updates Workflow

Document the workflow for updating website content:

### Edit-Deploy-Live Workflow:
```bash
# 1. Edit source files on VPS
ssh -A -p 2222 cc-user@NEW_VPS_IP "cd /opt/asw/projects/personal/casadaspedras-website/www && [edit files]"

# Example: Update website text
ssh -A -p 2222 cc-user@NEW_VPS_IP "cd /opt/asw/projects/personal/casadaspedras-website/www && sed -i 's/coming soon.../coming next month.../' index.html"

# 2. Deploy changes to live website
ssh -A -p 2222 cc-user@NEW_VPS_IP "cd /opt/asw/projects/personal/casadaspedras-website && ./scripts/deploy.sh"

# 3. Verify changes are live
curl -s https://casadaspedrasportugal.com | grep "next month"
```

---

## Manual Commands Summary

### Essential Commands Used:

**DNS Verification:**
```bash
nslookup casadaspedrasportugal.com
dig +short casadaspedrasportugal.com
```

**Package Installation:**
```bash
sudo apt update && sudo apt install -y rsync
```

**User Account Creation:**
```bash
sudo useradd -r -s /bin/false web-user
```

**Website Deployment:**
```bash
cd /opt/asw/projects/personal/casadaspedras-website && ./scripts/deploy.sh
```

**SSL Certificate:**
```bash
sudo certbot --nginx -d casadaspedrasportugal.com -d www.casadaspedrasportugal.com --email jrtownsend@gmail.com --agree-tos --no-eff-email
```

**Content Updates:**
```bash
sed -i 's/old-text/new-text/' index.html
```

---

## Scripts Created

### 1. ASW Static Website Setup Script
**Location:** `/opt/asw/scripts/setup-static-website.sh`

**Purpose:** Automates nginx configuration, site enabling, and SSL preparation for static websites.

**Features:**
- Security headers configuration
- Gzip compression
- Static asset caching
- Health check endpoint
- Error handling and validation

**Usage Pattern:**
```bash
# Run remotely using ASW push model
ssh -A -p 2222 cc-user@VPS_IP "bash -s domain document-root email" < /opt/asw/scripts/setup-static-website.sh
```

---

## Final Architecture

### ASW Framework Structure:
```
/opt/asw/
├── projects/personal/casadaspedras-website/    # Source repository
│   ├── www/index.html                          # Source files
│   └── scripts/deploy.sh                       # Deployment script
├── scripts/setup-static-website.sh             # ASW static site setup
└── docs/STATIC-WEBSITE-MIGRATION-GUIDE.md     # This documentation
```

### Web Server Structure:
```
/var/www/casadaspedrasportugal.com/             # Live website files
/etc/nginx/sites-available/casadaspedrasportugal.com  # Nginx config
/etc/nginx/sites-enabled/casadaspedrasportugal.com    # Enabled site
/etc/letsencrypt/live/casadaspedrasportugal.com/       # SSL certificates
```

### Workflow Summary:
1. **Development:** Edit files in `/opt/asw/projects/personal/casadaspedras-website/www/`
2. **Deployment:** Run `./scripts/deploy.sh` to copy to `/var/www/`
3. **Serving:** Nginx serves from `/var/www/` with HTTPS
4. **Management:** All managed through ASW framework scripts

---

## Success Metrics

✅ **Migration Complete:**
- Website accessible at https://casadaspedrasportugal.com
- SSL certificate installed and auto-renewing
- DNS pointing to new VPS (152.53.136.76)
- Content updates working through deploy workflow
- ASW framework extended with static website support

✅ **Performance:**
- HTTP 200 responses
- HTTPS redirect working
- Caching headers configured
- Security headers implemented
- Health check endpoint available

✅ **Maintainability:**
- Reusable setup script created
- Documentation complete
- Standard ASW directory structure
- Clear update workflow established

---

## Reusable Process

This process can be repeated for any static website:

1. **Clone** repository to `/opt/asw/projects/personal/SITE_NAME/`
2. **Deploy** files using project's deploy script
3. **Configure** nginx using `/opt/asw/scripts/setup-static-website.sh`
4. **Update** DNS records to new VPS
5. **Install** SSL certificate with certbot
6. **Test** and verify functionality

The ASW framework now has full static website support alongside its existing development server capabilities.

---

## Multiple Sites on Same VPS

The ASW framework and static website setup script support hosting multiple sites on the same VPS. Here are the common approaches:

### 1. Different Domains (Most Common)

Each site gets its own domain and nginx configuration:

```bash
# Site 1: casadaspedrasportugal.com (already set up)
/var/www/casadaspedrasportugal.com/

# Site 2: example.com
./setup-static-website.sh example.com /var/www/example.com

# Site 3: anotherdomain.com  
./setup-static-website.sh anotherdomain.com /var/www/anotherdomain.com
```

### 2. Subdomains

Multiple subdomains under one main domain:

```bash
# Main site: 8020perfect.com
./setup-static-website.sh 8020perfect.com /var/www/8020perfect.com

# Subdomain sites
./setup-static-website.sh blog.8020perfect.com /var/www/blog.8020perfect.com
./setup-static-website.sh portfolio.8020perfect.com /var/www/portfolio.8020perfect.com
```

### 3. Mixed: Static Sites + Development Projects

The ASW framework supports both static websites and development projects:

```bash
# Static websites
casadaspedrasportugal.com → /var/www/casadaspedrasportugal.com/
example.com → /var/www/example.com/

# Development projects (using asw-dev-server)
tennis-tracker.dev.8020perfect.com → localhost:3009 (Next.js)
api.dev.8020perfect.com → localhost:3010 (Node.js API)
```

---

## Setup Process for Additional Sites

### Adding Static Websites

**Step 1: Prepare Project Repository**
```bash
# Option A: Clone existing repository
ssh -A -p 2222 cc-user@VPS_IP "cd /opt/asw/projects/personal && git clone git@github.com:user/new-site.git"

# Option B: Create new project structure
ssh -A -p 2222 cc-user@VPS_IP "mkdir -p /opt/asw/projects/personal/new-site/{www,scripts}"
```

**Step 2: Deploy Website Files**
```bash
# If using existing deploy script
ssh -A -p 2222 cc-user@VPS_IP "cd /opt/asw/projects/personal/new-site && ./scripts/deploy.sh"

# Or manually copy files
ssh -A -p 2222 cc-user@VPS_IP "sudo mkdir -p /var/www/newdomain.com && sudo rsync -avz /opt/asw/projects/personal/new-site/www/ /var/www/newdomain.com/"
```

**Step 3: Configure Nginx and SSL**
```bash
# Run static website setup script remotely
ssh -A -p 2222 cc-user@VPS_IP "bash -s newdomain.com /var/www/newdomain.com your@email.com" < /opt/asw/scripts/setup-static-website.sh
```

**Step 4: Update DNS**
```bash
# Update DNS A records to point to VPS
# newdomain.com → VPS_IP
# www.newdomain.com → VPS_IP

# Verify DNS propagation
nslookup newdomain.com
```

**Step 5: Test and Verify**
```bash
# Test HTTP access
curl -I http://newdomain.com

# Setup will automatically configure SSL
curl -I https://newdomain.com
```

### Adding Development Projects

**Step 1: Clone Project**
```bash
ssh -A -p 2222 cc-user@VPS_IP "cd /opt/asw/projects/personal && git clone git@github.com:user/dev-project.git"
```

**Step 2: Install Dependencies**
```bash
ssh -A -p 2222 cc-user@VPS_IP "cd /opt/asw/projects/personal/dev-project && npm install"
```

**Step 3: Start Development Server**
```bash
ssh -A -p 2222 cc-user@VPS_IP "cd /opt/asw/projects/personal/dev-project && asw-dev-server start --https"
```

---

## Multiple Sites Example Configuration

### Nginx Sites Structure
```
/etc/nginx/sites-enabled/
├── casadaspedrasportugal.com           # Static site
├── example.com                         # Static site
├── blog.8020perfect.com                # Static subdomain
├── tennis-tracker.dev.8020perfect.com  # Dev project (proxy)
└── api.dev.8020perfect.com             # Dev project (proxy)
```

### Web Directories Structure
```
/var/www/
├── casadaspedrasportugal.com/          # Static files
├── example.com/                        # Static files
└── blog.8020perfect.com/               # Static files

/opt/asw/projects/personal/
├── casadaspedras-website/              # Source repository
├── example-site/                       # Source repository
├── blog-site/                          # Source repository
├── tennis-tracker/                     # Dev project
└── api-project/                        # Dev project
```

### SSL Certificates
```
/etc/letsencrypt/live/
├── casadaspedrasportugal.com/
├── example.com/
├── blog.8020perfect.com/
├── tennis-tracker.dev.8020perfect.com/
└── api.dev.8020perfect.com/
```

---

## Resource Considerations

### VPS Capacity
- **Static Sites**: Very lightweight, can host dozens
- **Development Projects**: More resource intensive, monitor:
  - CPU usage with `htop`
  - Memory usage with `free -h`
  - Disk space with `df -h`

### Port Management
- ASW port registry: `/opt/asw/projects/.ports-registry.json`
- Static sites use nginx (port 80/443)
- Dev projects use assigned ports (3000+)

### Monitoring
```bash
# Check all nginx sites
sudo nginx -T

# Check active development servers  
ssh -A -p 2222 cc-user@VPS_IP "ps aux | grep node"

# Check port usage
ssh -A -p 2222 cc-user@VPS_IP "ss -tulpn | grep LISTEN"
```

---

## Quick Setup Commands

### Add New Static Site
```bash
# One-liner for static site setup
DOMAIN="newsite.com" && VPS_IP="152.53.136.76" && EMAIL="your@email.com" && ssh -A -p 2222 cc-user@$VPS_IP "sudo mkdir -p /var/www/$DOMAIN && echo '<h1>$DOMAIN</h1>' | sudo tee /var/www/$DOMAIN/index.html > /dev/null" && ssh -A -p 2222 cc-user@$VPS_IP "bash -s $DOMAIN /var/www/$DOMAIN $EMAIL" < /opt/asw/scripts/setup-static-website.sh
```

### Add New Development Project
```bash
# Clone and start dev project
PROJECT="new-project" && VPS_IP="152.53.136.76" && ssh -A -p 2222 cc-user@$VPS_IP "cd /opt/asw/projects/personal && git clone git@github.com:user/$PROJECT.git && cd $PROJECT && npm install && asw-dev-server start --https"
```

The ASW framework now provides complete multi-site hosting capabilities with both static websites and development projects on a single VPS.

---

**Migration completed:** September 11, 2025  
**Total time:** ~2 hours including DNS propagation  
**Result:** Production-ready HTTPS website with ASW management  
**Multi-site capability:** Ready for unlimited additional sites