#!/bin/bash

# Interactive 1Password Token Setup
# Handles common issues like trailing newlines

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Function to clean and validate token
clean_token() {
    local token="$1"
    # Remove any whitespace, newlines, carriage returns
    token=$(echo "$token" | tr -d '\n\r\t ' | sed 's/[[:space:]]//g')
    echo "$token"
}

clear
echo -e "${BLUE}╔══════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     1Password Token Setup Wizard        ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}This wizard will help you set up your 1Password service account token.${NC}"
echo ""
echo "Please paste your token below and press Enter."
echo "(The token should start with 'ops_')"
echo ""
echo -n -e "${GREEN}Token: ${NC}"
read -r RAW_TOKEN

if [ -z "$RAW_TOKEN" ]; then
    echo -e "${RED}❌ No token provided${NC}"
    exit 1
fi

# Clean the token
TOKEN=$(clean_token "$RAW_TOKEN")

# Validate token format
if [[ ! "$TOKEN" =~ ^ops_ ]]; then
    echo -e "${RED}❌ Invalid token format. Token should start with 'ops_'${NC}"
    exit 1
fi

# Check token length
TOKEN_LENGTH=${#TOKEN}
echo ""
echo -e "${BLUE}Token received:${NC}"
echo "  ✓ Length: $TOKEN_LENGTH characters"
echo "  ✓ Prefix: ${TOKEN:0:10}..."
echo "  ✓ Cleaned of whitespace/newlines"
echo ""

if [ "$TOKEN_LENGTH" -lt 100 ]; then
    echo -e "${RED}❌ Token seems too short (${TOKEN_LENGTH} chars).${NC}"
    echo "Valid tokens are typically 800+ characters."
    exit 1
fi

# Test the token
echo -e "${YELLOW}Testing token authentication...${NC}"
export OP_SERVICE_ACCOUNT_TOKEN="$TOKEN"

if op whoami >/dev/null 2>&1; then
    echo -e "${GREEN}✅ Token is valid!${NC}"
    echo ""

    # Show account info
    echo -e "${BLUE}Account information:${NC}"
    op whoami | sed 's/^/  /'
    echo ""

    # Show available vaults
    echo -e "${BLUE}Available vaults:${NC}"
    op vault list 2>/dev/null | sed 's/^/  /' || echo "  No vaults accessible yet"
    echo ""
else
    echo -e "${RED}❌ Token authentication failed${NC}"
    echo ""
    echo "Possible reasons:"
    echo "  • Token has expired"
    echo "  • Service account was deleted"
    echo "  • Token was copied incorrectly"
    echo ""
    echo "Please get a fresh token from:"
    echo "  https://my.1password.com → Settings → Service Accounts"
    exit 1
fi

# Ask for confirmation before storing
echo -e "${YELLOW}Ready to store the token in:${NC}"
echo "  • /opt/asw/.secrets/op-service-account-token (system)"
echo "  • ~/.config/1password/token (user)"
echo ""
echo -n "Proceed? (y/n): "
read -r CONFIRM

if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Setup cancelled${NC}"
    exit 0
fi

# Store the cleaned token
echo ""
echo -e "${YELLOW}Storing token...${NC}"

# Create directories if they don't exist
sudo mkdir -p /opt/asw/.secrets
mkdir -p ~/.config/1password

# System location
echo -n "$TOKEN" | sudo tee /opt/asw/.secrets/op-service-account-token > /dev/null
sudo chmod 600 /opt/asw/.secrets/op-service-account-token
sudo chown root:root /opt/asw/.secrets/op-service-account-token
echo -e "${GREEN}  ✅ System location configured${NC}"

# User location
echo -n "$TOKEN" > ~/.config/1password/token
chmod 600 ~/.config/1password/token
echo -e "${GREEN}  ✅ User location configured${NC}"

# Test framework integration
echo ""
echo -e "${YELLOW}Testing framework integration...${NC}"
if [[ -f "/opt/asw/agentic-framework-security/lib/shared/1password-token-manager.sh" ]]; then
    source /opt/asw/agentic-framework-security/lib/shared/1password-token-manager.sh 2>/dev/null
    if load_op_token 2>/dev/null; then
        echo -e "${GREEN}  ✅ Framework integration working${NC}"
    else
        echo -e "${YELLOW}  ⚠️  Framework integration needs manual verification${NC}"
    fi
else
    echo -e "${YELLOW}  ⚠️  Framework not fully installed yet${NC}"
fi

# Update bashrc environment
echo ""
echo -e "${YELLOW}Updating shell environment...${NC}"
if ! grep -q "OP_SERVICE_ACCOUNT_TOKEN" ~/.bashrc 2>/dev/null; then
    echo "" >> ~/.bashrc
    echo "# 1Password service account token" >> ~/.bashrc
    echo "export OP_SERVICE_ACCOUNT_TOKEN=\$(cat ~/.config/1password/token 2>/dev/null)" >> ~/.bashrc
    echo -e "${GREEN}  ✅ Added to ~/.bashrc${NC}"
else
    echo -e "${GREEN}  ✅ Already configured in ~/.bashrc${NC}"
fi

echo ""
echo -e "${GREEN}╔══════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║         Setup Complete! 🎉              ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════╝${NC}"
echo ""
echo "Your 1Password token is now configured."
echo ""
echo "To use in your current session:"
echo -e "  ${BLUE}source ~/.bashrc${NC}"
echo -e "  ${BLUE}op vault list${NC}"
echo ""
echo "To test with framework (if available):"
echo -e "  ${BLUE}source /opt/asw/agentic-framework-security/lib/shared/1password-token-manager.sh${NC}"
echo -e "  ${BLUE}validate_op_setup${NC}"
echo ""
echo "To run comprehensive validation:"
echo -e "  ${BLUE}/opt/asw/scripts/test-server-setup.sh${NC}"