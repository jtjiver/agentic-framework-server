#!/bin/bash

# Agentic Framework Server Setup Script
# Installs framework packages to /opt/asw while keeping server repo clean

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}🚀 Agentic Framework Server Setup${NC}"
echo "=================================="

# Check if we're in /opt/asw
if [[ "$PWD" != "/opt/asw" ]]; then
    echo -e "${RED}❌ This script should be run from /opt/asw${NC}"
    echo "Current directory: $PWD"
    exit 1
fi

echo -e "${BLUE}📍 Setting up framework in: $PWD${NC}"

# Function to clone or update repo
setup_repo() {
    local repo_name="$1"
    local repo_url="$2"
    
    if [[ -d "$repo_name" ]]; then
        echo -e "${YELLOW}📦 Updating $repo_name...${NC}"
        cd "$repo_name"
        git pull origin main || git pull origin master
        cd ..
    else
        echo -e "${BLUE}📦 Cloning $repo_name...${NC}"
        git clone "$repo_url" "$repo_name"
    fi
}

# Clone/update framework packages
echo -e "${BLUE}🔧 Installing Framework Packages...${NC}"

setup_repo "agentic-framework-core" "https://github.com/jtjiver/agentic-framework-core.git"
setup_repo "agentic-framework-security" "https://github.com/jtjiver/agentic-framework-security.git"  
setup_repo "agentic-framework-dev" "https://github.com/jtjiver/agentic-framework-dev.git"

# Optional packages (only if they exist)
echo -e "${BLUE}🔧 Installing Optional Packages...${NC}"

if git ls-remote --exit-code https://github.com/jtjiver/agentic-framework-infrastructure.git >/dev/null 2>&1; then
    setup_repo "agentic-framework-infrastructure" "https://github.com/jtjiver/agentic-framework-infrastructure.git"
else
    echo -e "${YELLOW}⚠️  agentic-framework-infrastructure not available, skipping${NC}"
fi

if git ls-remote --exit-code https://github.com/jtjiver/agentic-claude-config.git >/dev/null 2>&1; then
    setup_repo "agentic-claude-config" "https://github.com/jtjiver/agentic-claude-config.git"
else
    echo -e "${YELLOW}⚠️  agentic-claude-config not available, skipping${NC}"
fi

# Install NPM packages globally
echo -e "${BLUE}📦 Installing NPM Packages...${NC}"

if command -v npm >/dev/null 2>&1; then
    npm install -g @jtjiver/agentic-framework-core@latest
    npm install -g @jtjiver/agentic-framework-security@latest  
    npm install -g @jtjiver/agentic-framework-dev@latest
    
    echo -e "${GREEN}✅ NPM packages installed globally${NC}"
else
    echo -e "${YELLOW}⚠️  npm not found, skipping global package installation${NC}"
    echo "   Install Node.js and npm, then run: npm install -g @jtjiver/agentic-framework-*"
fi

# Set up project directories with proper permissions
echo -e "${BLUE}📁 Setting up project directories...${NC}"
mkdir -p projects/{personal,clients,experiments,containers}
chown -R cc-user:cc-user projects/ 2>/dev/null || chown -R $USER:$USER projects/

# Create secrets directory (optional)
if [[ ! -d ".secrets" ]]; then
    echo -e "${BLUE}🔐 Setting up secrets directory...${NC}"
    mkdir -p .secrets
    chmod 700 .secrets
    echo -e "${YELLOW}💡 Add your 1Password service account token:${NC}"
    echo "   echo 'ops_YOUR_TOKEN' > /opt/asw/.secrets/op-service-account-token"
    echo "   chmod 600 /opt/asw/.secrets/op-service-account-token"
fi

# Check git status to show what's ignored
echo -e "${BLUE}🔍 Git status check...${NC}"
git status --ignored

echo ""
echo -e "${GREEN}🎉 Framework Setup Complete!${NC}"
echo ""
echo -e "${BLUE}📋 What was installed (but not tracked in this repo):${NC}"
ls -la | grep agentic-framework || echo "   No framework directories found"

echo ""
echo -e "${BLUE}🚀 Next Steps:${NC}"
echo "1. Set up your 1Password service account token"
echo "2. Create your first project: ./scripts/new-project.sh my-project personal"  
echo "3. Read the guide: cat FINAL-FRAMEWORK-GUIDE.md"
echo ""
echo -e "${GREEN}Ready to build! 🚀${NC}"