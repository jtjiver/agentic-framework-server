#!/bin/bash

# ASW Aliases Installer
# Installs all ASW navigation and validation shortcuts to user's shell

set -euo pipefail

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}🚀 ASW Aliases Installer${NC}"
echo -e "${BLUE}========================${NC}\n"

# Detect user's shell config file
SHELL_CONFIG=""
if [[ -f "$HOME/.bashrc" ]]; then
    SHELL_CONFIG="$HOME/.bashrc"
elif [[ -f "$HOME/.bash_profile" ]]; then
    SHELL_CONFIG="$HOME/.bash_profile"
elif [[ -f "$HOME/.zshrc" ]]; then
    SHELL_CONFIG="$HOME/.zshrc"
else
    echo -e "${RED}❌ Could not find shell configuration file${NC}"
    echo -e "${YELLOW}Please manually add to your shell config:${NC}"
    echo -e "source /opt/asw/agentic-framework-core/lib/utils/asw-aliases.sh"
    exit 1
fi

echo -e "${GREEN}✅ Found shell config: $SHELL_CONFIG${NC}"

# Check if already installed
if grep -q "asw-aliases.sh" "$SHELL_CONFIG" 2>/dev/null; then
    echo -e "${YELLOW}⚠️  ASW aliases already installed${NC}"
    echo -e "${BLUE}To reload: source $SHELL_CONFIG${NC}"
else
    # Add ASW aliases source
    echo "" >> "$SHELL_CONFIG"
    echo "# ASW Framework Aliases (Added $(date))" >> "$SHELL_CONFIG"
    echo "# Source all ASW navigation and validation shortcuts" >> "$SHELL_CONFIG"
    echo 'if [[ -f "/opt/asw/agentic-framework-core/lib/utils/asw-aliases.sh" ]]; then' >> "$SHELL_CONFIG"
    echo '    source "/opt/asw/agentic-framework-core/lib/utils/asw-aliases.sh"' >> "$SHELL_CONFIG"
    echo 'fi' >> "$SHELL_CONFIG"
    
    echo -e "${GREEN}✅ Added ASW aliases to $SHELL_CONFIG${NC}"
fi

# Source immediately for current session
if [[ -f "/opt/asw/agentic-framework-core/lib/utils/asw-aliases.sh" ]]; then
    source "/opt/asw/agentic-framework-core/lib/utils/asw-aliases.sh"
    echo -e "${GREEN}✅ Aliases loaded for current session${NC}"
fi

echo -e "\n${BLUE}Available Commands:${NC}"
echo -e "  ${GREEN}asw-help${NC}        → Show all ASW commands"
echo -e "  ${GREEN}cdhelp${NC}          → Show navigation shortcuts"
echo -e "  ${GREEN}validate-help${NC}   → Show validation commands"
echo -e "  ${GREEN}validate-all${NC}    → Run all framework validations"

echo -e "\n${BLUE}Quick Navigation:${NC}"
echo -e "  ${GREEN}cdp${NC}  → Go to container projects"
echo -e "  ${GREEN}cda${NC}  → Go to ASW root"
echo -e "  ${GREEN}cdc${NC}  → Go to Claude config"

echo -e "\n${GREEN}✨ Installation complete!${NC}"
echo -e "${YELLOW}Note: Restart your shell or run: source $SHELL_CONFIG${NC}"