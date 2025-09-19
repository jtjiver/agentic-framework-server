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

# Initialize and update all Git submodules
echo -e "${BLUE}🔧 Setting up Framework Submodules...${NC}"

# Initialize submodules if not already done
if ! git submodule status | grep -q "^-"; then
    echo -e "${BLUE}📦 Submodules already initialized${NC}"
else
    echo -e "${BLUE}📦 Initializing submodules...${NC}"
    git submodule init
fi

# Update all submodules to latest commits
echo -e "${BLUE}📦 Updating submodules to latest...${NC}"
git submodule update --remote --merge

# Configure submodules to track main branches (prevents detached HEAD)
echo -e "${BLUE}🔧 Configuring submodule branch tracking...${NC}"
git config submodule.agentic-framework-core.branch main
git config submodule.agentic-framework-infrastructure.branch main  
git config submodule.agentic-framework-security.branch main
git config submodule.agentic-framework-dev.branch main
git config submodule.agentic-claude-config.branch main

# Ensure all submodules are on their main/master branches (not detached HEAD)
echo -e "${BLUE}🔧 Ensuring submodules are on proper branches...${NC}"
git submodule foreach 'branch=$(git config -f ../.gitmodules submodule.$name.branch); git checkout ${branch:-main} 2>/dev/null || git checkout main 2>/dev/null || git checkout master 2>/dev/null || echo "Warning: Could not checkout main/master for $name"'

echo -e "${GREEN}✅ All submodules configured and updated${NC}"

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

# Install ASW Version Checker
echo -e "${BLUE}🔧 Installing ASW Version Checker...${NC}"
if [[ -f "scripts/install-asw-check-version.sh" ]]; then
    if command -v uv >/dev/null 2>&1; then
        if ./scripts/install-asw-check-version.sh --local; then
            echo -e "${GREEN}✅ Version checker installed to ~/.local/bin${NC}"
            echo -e "${YELLOW}💡 Add ~/.local/bin to your PATH if not already done${NC}"
        else
            echo -e "${YELLOW}⚠️  Version checker installation failed, you can install manually later${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️  uv not found, skipping version checker installation${NC}"
        echo "   Install uv, then run: ./scripts/install-asw-check-version.sh"
    fi
else
    echo -e "${YELLOW}⚠️  Version checker installer not found, skipping${NC}"
fi

# Setup Claude Code Configuration
echo -e "${BLUE}🤖 Setting up Claude Code Configuration...${NC}"
if [[ -f "agentic-claude-config/cli/install-config.sh" ]]; then
    # Check if .claude directory already exists
    if [[ -d ".claude" ]]; then
        echo -e "${YELLOW}📁 Claude config already exists, updating...${NC}"
        if [[ -f "agentic-claude-config/cli/update-config.sh" ]]; then
            if ./agentic-claude-config/cli/update-config.sh /opt/asw; then
                echo -e "${GREEN}✅ Claude Code configuration updated${NC}"
            else
                echo -e "${YELLOW}⚠️  Claude config update failed, you can update manually later${NC}"
            fi
        else
            echo -e "${YELLOW}⚠️  Update script not found, skipping update${NC}"
        fi
    else
        echo -e "${BLUE}📁 Installing Claude Code configuration...${NC}"
        if ./agentic-claude-config/cli/install-config.sh /opt/asw; then
            echo -e "${GREEN}✅ Claude Code configuration installed${NC}"
            echo -e "${BLUE}💡 Configuration includes hooks, settings, and prompt files${NC}"
        else
            echo -e "${YELLOW}⚠️  Claude config installation failed, you can install manually later${NC}"
            echo "   Run: ./agentic-claude-config/cli/install-config.sh /opt/asw"
        fi
    fi
else
    echo -e "${YELLOW}⚠️  Claude config installer not found (submodule may not be initialized)${NC}"
    echo "   After submodules are ready, run: ./agentic-claude-config/cli/install-config.sh /opt/asw"
fi

echo ""
echo -e "${GREEN}🎉 Framework Setup Complete!${NC}"
echo ""
echo -e "${BLUE}📋 What was installed (but not tracked in this repo):${NC}"
ls -la | grep agentic-framework || echo "   No framework directories found"

echo ""
echo -e "${BLUE}🚀 Next Steps:${NC}"
echo "1. Set up your 1Password service account token"
echo "2. Create your first project: ./scripts/new-project.sh my-project personal"  
echo "3. Check versions: asw-check-version (if installed)"
echo "4. Read the guide: cat FINAL-FRAMEWORK-GUIDE.md"
echo ""
echo -e "${GREEN}Ready to build! 🚀${NC}"