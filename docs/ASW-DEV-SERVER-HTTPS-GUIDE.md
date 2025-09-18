# ASW Development Server HTTPS Guide

Complete guide for using HTTPS with the ASW Development Server infrastructure.

## Overview

The ASW Development Server now provides complete HTTPS support with:
- **Project-specific SSL certificates** stored in `.ssl/` directory
- **Complete nginx HTTPS configuration** with HTTP redirect
- **Enhanced teardown** that cleans up all SSL resources
- **One-command setup** for full HTTPS development environment

## Quick Start

### Start with HTTPS
```bash
cd /opt/asw/projects/your-project
asw-dev-server start --https --domain your-project.dev.8020perfect.com
```

This single command:
1. ✅ Allocates a port from the pool (3000-3099)
2. ✅ Opens firewall port
3. ✅ Generates project-specific SSL certificates in `.ssl/`
4. ✅ Creates nginx configuration with HTTPS and HTTP redirect
5. ✅ Starts your development server
6. ✅ Provides immediate HTTPS access

### Access Your App
- **HTTPS URL**: `https://your-project.dev.8020perfect.com`
- **Direct access**: `http://server-ip:port` (fallback)

## SSL Certificate Management

### Project-Specific Certificates

The enhanced system creates SSL certificates in your project directory:

```
your-project/
├── .ssl/
│   ├── cert.pem    # SSL certificate
│   └── key.pem     # Private key
├── package.json
└── ...
```

**Benefits:**
- ✅ **Isolation**: Each project has its own certificates
- ✅ **No sudo required**: Certificates created with user permissions
- ✅ **Easy cleanup**: `teardown` removes everything
- ✅ **Version control**: `.ssl/` can be gitignored for security

### Certificate Details

Certificates include:
- **Subject Alternative Names (SAN)**: Your domain, localhost, 127.0.0.1, server IP
- **Validity**: 365 days
- **Auto-renewal**: Regenerated if expired on next startup

## Nginx Configuration

### HTTPS Configuration

When `--https` is used, nginx gets:

```nginx
# HTTPS server
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name your-project.dev.8020perfect.com;
    
    # SSL configuration
    ssl_certificate /path/to/project/.ssl/cert.pem;
    ssl_certificate_key /path/to/project/.ssl/key.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    
    # Security headers
    add_header X-Forwarded-Proto $scheme always;
    # ... additional security headers
    
    # Proxy configuration
    location / {
        proxy_pass http://localhost:PORT;
        proxy_set_header X-Forwarded-Proto $scheme;
        # ... additional proxy settings
    }
}

# HTTP redirect
server {
    listen 80;
    server_name your-project.dev.8020perfect.com;
    return 301 https://$server_name$request_uri;
}
```

## Commands Reference

### Start Commands
```bash
# Basic HTTPS startup
asw-dev-server start --https

# HTTPS with custom domain
asw-dev-server start --https --domain myapp.dev.8020perfect.com

# HTTPS with live logs (foreground)
asw-dev-server start --https --logs
```

### Management Commands
```bash
# Check status (shows HTTPS/HTTP URLs)
asw-dev-server status

# Stop server (keeps certificates and nginx config)
asw-dev-server stop

# Complete teardown (removes everything)
asw-dev-server teardown

# Restart with HTTPS
asw-dev-server restart --https
```

## Status Display

Enhanced status shows complete information:

```
ASW Development Server Status
────────────────────────────────────
Project: tennis-tracker
Port: 3014
Domain: tennis-tracker.dev.8020perfect.com
Started: 2025-09-17
Status: ● Running (PID: 12345)
Port Status: ● Listening

Access URLs:
  https://tennis-tracker.dev.8020perfect.com
  Direct: http://152.53.136.76:3014
  SSL: Project-specific certificates
```

## Teardown Process

### Stop vs Teardown

**`asw-dev-server stop`** (partial cleanup):
- ✅ Stops the server process
- ❌ Keeps port allocation
- ❌ Keeps nginx configuration
- ❌ Keeps SSL certificates
- ❌ Keeps firewall rules

**`asw-dev-server teardown`** (complete cleanup):
- ✅ Stops the server process
- ✅ Releases port allocation
- ✅ Removes nginx configuration
- ✅ Removes SSL certificates (`.ssl/` directory)
- ✅ Removes firewall rules
- ✅ Cleans up all state files

### Manual Cleanup

If needed, you can manually clean up:

```bash
# Remove project SSL certificates
rm -rf .ssl/

# Remove nginx configuration
sudo rm -f /etc/nginx/sites-{enabled,available}/your-domain.dev.8020perfect.com
sudo systemctl reload nginx

# Check allocated ports
/opt/asw/agentic-framework-infrastructure/bin/asw-port-manager list
```

## Browser Certificate Acceptance

Since these are self-signed certificates, browsers will show security warnings:

### Chrome/Edge
1. Click "Advanced"
2. Click "Proceed to your-domain.dev.8020perfect.com (unsafe)"

### Firefox
1. Click "Advanced..."
2. Click "Accept the Risk and Continue"

### Safari
1. Click "Show Details"
2. Click "visit this website"
3. Click "Visit Website"

## Troubleshooting

### Certificate Issues

**Problem**: Certificate expired or invalid
```bash
# Check certificate validity
openssl x509 -in .ssl/cert.pem -text -noout | grep -A2 "Validity"

# Force regeneration
rm -rf .ssl/
asw-dev-server restart --https
```

**Problem**: Certificate not trusted
- This is expected with self-signed certificates
- Add exception in browser or import certificate to OS trust store

### Nginx Issues

**Problem**: nginx configuration error
```bash
# Test nginx configuration
sudo nginx -t

# Check specific site
cat /etc/nginx/sites-available/your-domain.dev.8020perfect.com

# Reload nginx
sudo systemctl reload nginx
```

### Port Issues

**Problem**: Port already in use
```bash
# Check what's using the port
lsof -i :PORT

# Release port allocation
asw-dev-server teardown
```

### Domain Resolution

**Problem**: Domain doesn't resolve
```bash
# Check DNS resolution
nslookup your-domain.dev.8020perfect.com

# Test direct access
curl -k https://your-domain.dev.8020perfect.com
```

## Migration Guide

### From HTTP to HTTPS

If you have an existing HTTP setup:

```bash
# Stop current server
asw-dev-server stop

# Start with HTTPS
asw-dev-server start --https
```

Your existing port allocation and nginx config will be updated automatically.

### From System SSL to Project SSL

The enhanced system automatically uses project-specific certificates:

1. **Legacy cleanup**: System SSL certificates are cleaned up during teardown
2. **New certificates**: Generated in project `.ssl/` directory
3. **Nginx update**: Configuration automatically points to project certificates

## Security Considerations

### Development Use Only

These certificates are for **development only**:
- ❌ **Not for production**: Use proper CA-signed certificates
- ❌ **Not secure**: Private keys are in project directories
- ❌ **Not trusted**: Browsers will show warnings

### Best Practices

- ✅ **Add `.ssl/` to `.gitignore`**: Don't commit certificates
- ✅ **Use HTTPS for OAuth**: Required for many OAuth providers
- ✅ **Regular cleanup**: Use `teardown` when done with projects
- ✅ **Monitor certificates**: Check expiration dates

## Integration with Development Workflow

### Package.json Scripts

Add convenience scripts:

```json
{
  "scripts": {
    "dev": "next dev",
    "dev:https": "asw-dev-server start --https --logs",
    "dev:stop": "asw-dev-server stop",
    "dev:clean": "asw-dev-server teardown"
  }
}
```

### Git Integration

Recommended `.gitignore` entries:

```gitignore
# ASW Development Server
.asw-dev-server.pid
.asw-dev-server.state
asw-dev-server.log

# SSL certificates (security)
.ssl/
```

## Advanced Configuration

### Custom Domains

Use custom domains for specific needs:

```bash
# For OAuth callback URLs
asw-dev-server start --https --domain myapp.auth.8020perfect.com

# For subdomain testing  
asw-dev-server start --https --domain api.myapp.dev.8020perfect.com
```

### Multiple Projects

Each project gets isolated configuration:

```bash
cd /opt/asw/projects/frontend
asw-dev-server start --https --domain frontend.dev.8020perfect.com

cd /opt/asw/projects/backend  
asw-dev-server start --https --domain api.dev.8020perfect.com
```

## Support and Troubleshooting

### Log Files

Check these logs for debugging:

```bash
# Development server logs
tail -f asw-dev-server.log

# Nginx logs
sudo tail -f /var/log/nginx/error.log
sudo tail -f /var/log/nginx/access.log

# System logs
journalctl -u nginx -f
```

### Getting Help

```bash
# Show help
asw-dev-server help

# Check status
asw-dev-server status

# Full teardown and restart
asw-dev-server teardown
asw-dev-server start --https
```

---

**Enhanced ASW Development Server** - One command, complete HTTPS development environment! 🚀