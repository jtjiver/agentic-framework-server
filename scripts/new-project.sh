#!/bin/bash

# Quick Project Setup Script for Standardized Framework
# Creates new projects in /opt/asw/projects/ with vault configuration

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}🚀 Agentic Framework - New Project Setup${NC}"
echo "=========================================="

# Get project details
if [[ -z "$1" ]]; then
    echo "Usage: $0 <project-name> [personal|clients|experiments] [vault-name]"
    echo ""
    echo "Examples:"
    echo "  $0 my-startup personal"
    echo "  $0 big-client-app clients BigClient-WebApp-Secrets"
    echo "  $0 quick-test experiments"
    exit 1
fi

PROJECT_NAME="$1"
PROJECT_TYPE="${2:-personal}"
VAULT_NAME="$3"

# Validate project type
case "$PROJECT_TYPE" in
    personal|clients|experiments)
        ;;
    *)
        echo -e "${YELLOW}⚠️  Invalid project type. Using 'personal'${NC}"
        PROJECT_TYPE="personal"
        ;;
esac

# Create project directory
PROJECT_DIR="/opt/asw/projects/$PROJECT_TYPE/$PROJECT_NAME"

if [[ -d "$PROJECT_DIR" ]]; then
    echo -e "${YELLOW}⚠️  Project directory already exists: $PROJECT_DIR${NC}"
    echo "Do you want to continue? (y/N)"
    read -r response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        echo "Cancelled."
        exit 0
    fi
else
    echo -e "${BLUE}📁 Creating project directory: $PROJECT_DIR${NC}"
    mkdir -p "$PROJECT_DIR"
fi

cd "$PROJECT_DIR"

# Generate vault name if not provided
if [[ -z "$VAULT_NAME" ]]; then
    # Convert project name to proper vault format
    VAULT_NAME=$(echo "$PROJECT_NAME" | sed 's/[^a-zA-Z0-9-]/-/g' | sed 's/--*/-/g' | sed 's/^./\U&/' | sed 's/-\(.\)/\U\1/g')
    VAULT_NAME="${VAULT_NAME}-Secrets"
fi

# Create vault configuration
echo -e "${BLUE}🔐 Setting up 1Password vault: $VAULT_NAME${NC}"
echo "VAULT_NAME=\"$VAULT_NAME\"" > .vault-config

# Initialize git if not already a git repo
if [[ ! -d ".git" ]]; then
    echo -e "${BLUE}📦 Initializing git repository${NC}"
    git init
    
    # Create basic .gitignore
    cat > .gitignore << EOF
# Environment variables
.env
.env.local
.env.production

# Vault configuration (contains vault name, safe to commit)
# .vault-config

# Client configuration (may contain sensitive info)
.client-config

# Dependencies
node_modules/
__pycache__/
*.pyc

# Build outputs
dist/
build/
.next/

# IDE
.vscode/
.idea/

# OS
.DS_Store
Thumbs.db
EOF
fi

# Source vault manager and test
echo -e "${BLUE}🧪 Testing vault configuration...${NC}"
if source /opt/asw/agentic-framework-security/lib/shared/vault-context-manager.sh; then
    echo -e "${GREEN}✅ Vault manager loaded successfully${NC}"
    echo -e "${BLUE}🔍 Current context:${NC}"
    show_context
else
    echo -e "${YELLOW}⚠️  Could not load vault manager. Make sure security package is installed.${NC}"
fi

echo ""
echo -e "${GREEN}🎉 Project setup complete!${NC}"
echo ""
echo -e "${BLUE}📍 Project location:${NC} $PROJECT_DIR"
echo -e "${BLUE}🔐 1Password vault:${NC} $VAULT_NAME"  
echo ""
echo -e "${BLUE}Next steps:${NC}"
echo "1. cd $PROJECT_DIR"
echo "2. Set up your project (npm init, etc.)"
echo "3. Add secrets to 1Password vault: $VAULT_NAME"
echo "4. Use: source /opt/asw/agentic-framework-security/lib/shared/vault-context-manager.sh"
echo "5. Get secrets: get_secret \"SECRET_NAME\""
echo ""
echo -e "${GREEN}Happy building! 🚀${NC}"