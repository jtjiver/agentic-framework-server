#!/bin/bash

# Simple script to clone a repo and inflate .env from 1Password
# Usage: ./setup-project-env.sh <repo-url> [project-dir]

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# Get arguments
REPO_URL="$1"
PROJECT_DIR="${2:-$(basename "$REPO_URL" .git)}"

if [[ -z "$REPO_URL" ]]; then
    echo -e "${RED}❌ Usage: $0 <repo-url> [project-dir]${NC}"
    echo "Example: $0 https://github.com/username/my-project.git"
    exit 1
fi

echo -e "${BLUE}🚀 Setting up project: $PROJECT_DIR${NC}"

# Step 1: Clone the repository
if [[ ! -d "$PROJECT_DIR" ]]; then
    echo -e "${YELLOW}📦 Cloning repository...${NC}"
    git clone "$REPO_URL" "$PROJECT_DIR"
else
    echo -e "${YELLOW}📁 Directory already exists, skipping clone${NC}"
fi

cd "$PROJECT_DIR"

# Step 2: Check for 1Password CLI
if ! command -v op &> /dev/null; then
    echo -e "${RED}❌ 1Password CLI not found. Please install it first:${NC}"
    echo "   brew install 1password-cli"
    exit 1
fi

# Step 3: Check 1Password access
echo -e "${YELLOW}🔐 Checking 1Password access...${NC}"
if ! op vault list > /dev/null 2>&1; then
    echo -e "${RED}❌ Not authenticated with 1Password${NC}"
    echo "   Run: eval \$(op signin)"
    exit 1
fi
echo -e "${GREEN}✅ 1Password authenticated${NC}"

# Step 4: Look for .env.template or .env.example
ENV_TEMPLATE=""
if [[ -f ".env.template" ]]; then
    ENV_TEMPLATE=".env.template"
elif [[ -f ".env.example" ]]; then
    ENV_TEMPLATE=".env.example"
elif [[ -f ".env.sample" ]]; then
    ENV_TEMPLATE=".env.sample"
fi

# Step 5: Handle .env file creation
if [[ -n "$ENV_TEMPLATE" ]]; then
    echo -e "${YELLOW}📄 Found template: $ENV_TEMPLATE${NC}"
    
    # Check if template has 1Password references
    if grep -q "op://" "$ENV_TEMPLATE"; then
        echo -e "${BLUE}🔑 Template contains 1Password references${NC}"
        echo -e "${YELLOW}⚙️  Injecting secrets from 1Password...${NC}"
        
        # Use op inject to create .env
        if op inject -i "$ENV_TEMPLATE" -o .env; then
            echo -e "${GREEN}✅ Created .env with secrets from 1Password${NC}"
        else
            echo -e "${RED}❌ Failed to inject secrets. Check your vault access${NC}"
            exit 1
        fi
    else
        echo -e "${YELLOW}📝 Creating .env from template (no 1Password refs found)${NC}"
        cp "$ENV_TEMPLATE" .env
    fi
else
    echo -e "${YELLOW}⚠️  No .env template found${NC}"
    
    # Check if there's a vault config
    if [[ -f ".vault-config" ]]; then
        VAULT_NAME=$(grep -E "^VAULT_NAME=" .vault-config | cut -d'=' -f2 | tr -d '"')
        echo -e "${BLUE}🔐 Found vault config: $VAULT_NAME${NC}"
        echo "   You can manually get secrets with:"
        echo "   op item get <item-name> --vault \"$VAULT_NAME\""
    fi
fi

# Step 6: Copy Claude config if needed
if [[ ! -d ".claude" ]] && [[ -d "/opt/asw/agentic-claude-config/.claude" ]]; then
    echo -e "${YELLOW}🤖 Copying Claude configuration...${NC}"
    cp -r /opt/asw/agentic-claude-config/.claude .
    echo -e "${GREEN}✅ Claude config added${NC}"
fi

# Step 7: Install dependencies
if [[ -f "package.json" ]]; then
    echo -e "${YELLOW}📦 Installing npm dependencies...${NC}"
    npm install
elif [[ -f "requirements.txt" ]]; then
    echo -e "${YELLOW}🐍 Installing Python dependencies...${NC}"
    pip install -r requirements.txt
fi

echo -e "${GREEN}✅ Project setup complete!${NC}"
echo ""
echo -e "${BLUE}Next steps:${NC}"
echo "  cd $PROJECT_DIR"
echo "  npm run dev  # or your start command"