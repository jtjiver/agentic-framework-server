#!/bin/bash

# Setup Project Vault Helper
# Helps users create and configure project-specific vaults

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

PROJECT_NAME="$1"
PROJECT_DIR="${2:-$PWD}"

if [[ -z "$PROJECT_NAME" ]]; then
    echo -e "${RED}❌ Usage: $0 <project-name> [project-directory]${NC}"
    echo -e "${YELLOW}Example: $0 MyStartup /opt/asw/projects/personal/my-startup${NC}"
    exit 1
fi

VAULT_NAME="${PROJECT_NAME}-Secrets"

echo -e "${BLUE}🔐 Setting up project vault for: $PROJECT_NAME${NC}"
echo -e "${BLUE}📁 Project directory: $PROJECT_DIR${NC}"

# Check if vault exists
echo -e "\n${YELLOW}Checking 1Password vaults...${NC}"
if op vault list --format=json | jq -r '.[].name' | grep -q "^${VAULT_NAME}$"; then
    echo -e "${GREEN}✅ Vault '$VAULT_NAME' already exists${NC}"
else
    echo -e "${YELLOW}⚠️  Vault '$VAULT_NAME' does not exist${NC}"
    echo -e "\n${BLUE}To create the vault, you need to:${NC}"
    echo -e "1. Use the 1Password web interface or desktop app"
    echo -e "2. Create a new vault named: ${GREEN}$VAULT_NAME${NC}"
    echo -e "3. Grant your service account access to this vault"
    echo -e "\n${YELLOW}Alternative: Use the existing shared vault${NC}"
    echo -e "You can use 'TennisTracker-Dev-Vault' for development"
    
    read -p "Would you like to use the existing 'TennisTracker-Dev-Vault' instead? (y/n): " use_existing
    if [[ "$use_existing" == "y" || "$use_existing" == "Y" ]]; then
        VAULT_NAME="TennisTracker-Dev-Vault"
        echo -e "${GREEN}✅ Using existing vault: $VAULT_NAME${NC}"
    else
        echo -e "${YELLOW}Please create the vault manually and re-run this script${NC}"
        exit 1
    fi
fi

# Create vault config file
cd "$PROJECT_DIR"
source /opt/asw/agentic-framework-security/lib/shared/vault-context-manager.sh

echo -e "\n${BLUE}Creating vault configuration...${NC}"
create_vault_config "$VAULT_NAME"

# Create sample secret if using existing vault
if [[ "$VAULT_NAME" == "TennisTracker-Dev-Vault" ]]; then
    echo -e "\n${BLUE}Creating sample project secret...${NC}"
    
    # Create a sample item for this project
    SAMPLE_ITEM="${PROJECT_NAME}-API-Key"
    SAMPLE_VALUE="sample-api-key-$(date +%s)"
    
    if op item create \
        --category="API Credential" \
        --title="$SAMPLE_ITEM" \
        --vault="$VAULT_NAME" \
        "api_key=$SAMPLE_VALUE" \
        "notes=Sample API key for $PROJECT_NAME project" 2>/dev/null; then
        echo -e "${GREEN}✅ Created sample secret: $SAMPLE_ITEM${NC}"
        
        # Test retrieval
        echo -e "\n${BLUE}Testing secret retrieval...${NC}"
        if retrieved_value=$(get_secret "$SAMPLE_ITEM" "api_key"); then
            echo -e "${GREEN}✅ Successfully retrieved secret!${NC}"
            echo -e "${BLUE}Value: ${retrieved_value:0:10}...${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️  Could not create sample secret (may already exist)${NC}"
    fi
fi

# Create project initialization script
cat > "$PROJECT_DIR/init-vault.sh" << 'EOF'
#!/bin/bash
# Initialize vault context for this project
source /opt/asw/agentic-framework-security/lib/shared/vault-context-manager.sh

echo "🔐 Vault context initialized"
echo "Available commands:"
echo "  get_secret <item-name> [field-name]"
echo "  create_secret <item-name> <field-name> <value>"
echo "  list_vault_items"
echo ""
echo "Example: get_secret 'API-Key' 'token'"
EOF

chmod +x "$PROJECT_DIR/init-vault.sh"

echo -e "\n${GREEN}✅ Project vault setup complete!${NC}"
echo -e "\n${BLUE}To use secrets in this project:${NC}"
echo -e "1. Source the vault manager: ${YELLOW}source ./init-vault.sh${NC}"
echo -e "2. Get secrets: ${YELLOW}get_secret 'item-name' 'field-name'${NC}"
echo -e "3. Create secrets: ${YELLOW}create_secret 'item-name' 'field-name' 'value'${NC}"
echo -e "\n${BLUE}Vault configured: ${GREEN}$VAULT_NAME${NC}"