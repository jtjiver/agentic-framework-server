#!/bin/bash

# ASW Static Website Setup Script
# Sets up nginx configuration and SSL for static websites
# Works both locally and when pushed to VPS

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# Usage
if [[ $# -lt 2 ]]; then
    echo "Usage: $0 <domain> <document-root> [email]"
    echo ""
    echo "Examples:"
    echo "  $0 example.com /var/www/example.com"
    echo "  $0 example.com /var/www/example.com admin@example.com"
    echo ""
    echo "ASW Project Example:"
    echo "  $0 casadaspedrasportugal.com /var/www/casadaspedrasportugal.com jrtownsend@gmail.com"
    exit 1
fi

DOMAIN="$1"
DOCUMENT_ROOT="$2"
EMAIL="${3:-jrtownsend@gmail.com}"

echo -e "${BLUE}🌐 ASW Static Website Setup${NC}"
echo -e "Domain: ${GREEN}$DOMAIN${NC}"
echo -e "Document root: ${GREEN}$DOCUMENT_ROOT${NC}"
echo -e "Email: ${GREEN}$EMAIL${NC}"
echo ""

# Check if document root exists
if [[ ! -d "$DOCUMENT_ROOT" ]]; then
    echo -e "${RED}❌ Error: Document root does not exist: $DOCUMENT_ROOT${NC}"
    exit 1
fi

# Check if index.html exists
if [[ ! -f "$DOCUMENT_ROOT/index.html" ]]; then
    echo -e "${YELLOW}⚠️  Warning: No index.html found in $DOCUMENT_ROOT${NC}"
fi

# Create nginx configuration
echo -e "${YELLOW}📝 Creating nginx configuration...${NC}"

sudo tee /etc/nginx/sites-available/$DOMAIN > /dev/null << EOF
# ASW Static Website - $DOMAIN
# Auto-generated configuration
# Document root: $DOCUMENT_ROOT

server {
    listen 80;
    server_name $DOMAIN www.$DOMAIN;
    
    # Security headers
    add_header X-Frame-Options DENY;
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";
    add_header Referrer-Policy "strict-origin-when-cross-origin";
    add_header Content-Security-Policy "default-src 'self'; style-src 'self' 'unsafe-inline'; img-src 'self' data:;";
    
    server_tokens off;
    root $DOCUMENT_ROOT;
    index index.html index.htm;
    
    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types
        text/plain
        text/css
        text/xml
        text/javascript
        application/javascript
        application/xml+rss
        application/json
        image/svg+xml;
    
    # Main location block
    location / {
        try_files \$uri \$uri/ =404;
    }
    
    # Security: Block access to hidden files and directories
    location ~ /\\. {
        deny all;
        access_log off;
        log_not_found off;
    }
    
    # Block access to backup and temporary files
    location ~* \\.(bak|backup|old|tmp|temp)\$ {
        deny all;
        access_log off;
        log_not_found off;
    }
    
    # Cache static assets with versioning support
    location ~* \\.(css|js|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot|webp|avif)\$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
        add_header Vary "Accept-Encoding";
        access_log off;
    }
    
    # Cache HTML files for shorter time
    location ~* \\.(html|htm)\$ {
        expires 1h;
        add_header Cache-Control "public, must-revalidate";
    }
    
    # Health check endpoint for monitoring
    location /nginx-health {
        access_log off;
        return 200 "healthy\\n";
        add_header Content-Type text/plain;
    }
}
EOF

echo -e "${GREEN}✅ Nginx configuration created${NC}"

# Enable site
echo -e "${YELLOW}🔗 Enabling nginx site...${NC}"
sudo ln -sf /etc/nginx/sites-available/$DOMAIN /etc/nginx/sites-enabled/

# Test nginx configuration
echo -e "${YELLOW}🧪 Testing nginx configuration...${NC}"
if sudo nginx -t; then
    echo -e "${GREEN}✅ Nginx configuration test passed${NC}"
else
    echo -e "${RED}❌ Nginx configuration test failed${NC}"
    exit 1
fi

# Reload nginx
echo -e "${YELLOW}🔄 Reloading nginx...${NC}"
if sudo systemctl reload nginx; then
    echo -e "${GREEN}✅ Nginx reloaded successfully${NC}"
else
    echo -e "${RED}❌ Failed to reload nginx${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}🎉 Static website configured successfully!${NC}"
echo ""
echo -e "${BLUE}📋 Next Steps:${NC}"
echo -e "1. ${YELLOW}Update DNS${NC} to point $DOMAIN to this server IP"
echo -e "2. ${YELLOW}Set up SSL${NC}: sudo certbot --nginx -d $DOMAIN -d www.$DOMAIN --email $EMAIL --agree-tos --no-eff-email"
echo -e "3. ${YELLOW}Test locally${NC}: curl -H 'Host: $DOMAIN' http://localhost/"
echo -e "4. ${YELLOW}Check health${NC}: curl -H 'Host: $DOMAIN' http://localhost/nginx-health"
echo ""
echo -e "${BLUE}📁 Configuration Files:${NC}"
echo -e "• Nginx config: /etc/nginx/sites-available/$DOMAIN"
echo -e "• Document root: $DOCUMENT_ROOT"
echo ""
echo -e "${GREEN}✨ Setup complete!${NC}"