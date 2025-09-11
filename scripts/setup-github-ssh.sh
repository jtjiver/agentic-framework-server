#!/bin/bash
# GitHub SSH Key Setup for ASW Framework
# Automates SSH key generation with manual GitHub key addition step
# Part of the ASW Framework development environment setup

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_action() { echo -e "${BLUE}[ACTION]${NC} $1"; }

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}     GitHub SSH Key Setup for ASW Framework${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Get hostname and user for key labeling
HOSTNAME=$(hostname)
USERNAME=$(whoami)
KEY_LABEL="${USERNAME}@${HOSTNAME}-github"

log_info "Setting up GitHub SSH access for: $KEY_LABEL"

# Check if SSH key already exists
SSH_KEY_PATH="$HOME/.ssh/id_ed25519"
if [[ -f "$SSH_KEY_PATH" ]]; then
    log_warn "SSH key already exists at $SSH_KEY_PATH"
    echo ""
    read -p "Do you want to use the existing key? (y/n): " -r
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log_info "Using existing SSH key"
        USE_EXISTING=true
    else
        log_action "Backing up existing key..."
        mv "$SSH_KEY_PATH" "${SSH_KEY_PATH}.backup.$(date +%Y%m%d_%H%M%S)"
        mv "${SSH_KEY_PATH}.pub" "${SSH_KEY_PATH}.pub.backup.$(date +%Y%m%d_%H%M%S)"
        log_info "Existing keys backed up"
        USE_EXISTING=false
    fi
else
    USE_EXISTING=false
fi

# Generate new SSH key if needed
if [[ "$USE_EXISTING" != true ]]; then
    log_action "Generating new ED25519 SSH key..."
    ssh-keygen -t ed25519 -C "$KEY_LABEL" -f "$SSH_KEY_PATH" -N ""
    log_info "✅ SSH key generated successfully"
fi

# Start SSH agent and add key
log_action "Adding key to SSH agent..."
eval "$(ssh-agent -s)" > /dev/null
ssh-add "$SSH_KEY_PATH"
log_info "✅ SSH key added to agent"

# Display public key for GitHub
echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}     MANUAL STEP REQUIRED${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
log_info "🔑 Copy the following PUBLIC KEY to GitHub:"
echo ""
echo -e "${BLUE}$(cat "${SSH_KEY_PATH}.pub")${NC}"
echo ""
echo -e "${YELLOW}📋 Steps to add to GitHub:${NC}"
echo "  1. Go to: https://github.com/settings/ssh/new"
echo "  2. Title: $KEY_LABEL"
echo "  3. Paste the above public key"
echo "  4. Click 'Add SSH key'"
echo ""

# Wait for user confirmation
read -p "Press ENTER after adding the key to GitHub..." -r
echo ""

# Test GitHub connectivity
log_action "Testing GitHub SSH connection..."
if ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
    log_info "✅ GitHub SSH authentication successful!"
    
    # Convert repositories to SSH if they exist
    if [[ -d "/opt/asw" ]]; then
        log_action "Converting repositories to SSH..."
        cd /opt/asw
        
        for repo_path in . agentic-framework-* agentic-claude-config; do
            if [[ -d "$repo_path/.git" ]]; then
                cd "/opt/asw/$repo_path"
                
                # Get current remote URL
                current_url=$(git remote get-url origin 2>/dev/null || echo "")
                
                if [[ "$current_url" == https://github.com/* ]]; then
                    # Convert HTTPS to SSH
                    ssh_url=$(echo "$current_url" | sed 's|https://github.com/|git@github.com:|')
                    git remote set-url origin "$ssh_url"
                    log_info "✅ Converted $repo_path to SSH"
                fi
            fi
        done
        
        log_info "✅ Repository conversion completed"
    fi
    
else
    log_error "❌ GitHub SSH authentication failed"
    echo ""
    echo "🔧 Troubleshooting:"
    echo "  1. Verify the key was added to GitHub correctly"
    echo "  2. Check GitHub SSH key settings: https://github.com/settings/keys"
    echo "  3. Try manual test: ssh -T git@github.com"
    exit 1
fi

# Verify all repositories are using SSH
if [[ -d "/opt/asw" ]]; then
    echo ""
    log_info "📋 Repository SSH Status:"
    cd /opt/asw
    
    for repo_path in . agentic-framework-* agentic-claude-config; do
        if [[ -d "$repo_path/.git" ]]; then
            cd "/opt/asw/$repo_path"
            remote_url=$(git remote get-url origin 2>/dev/null || echo "none")
            if [[ "$remote_url" == git@github.com:* ]]; then
                echo -e "  ${GREEN}✅${NC} $repo_path: SSH configured"
            else
                echo -e "  ${YELLOW}⚠️${NC} $repo_path: $remote_url"
            fi
        fi
    done
fi

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}     🎉 GitHub SSH Setup Complete!${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
log_info "Benefits of SSH setup:"
echo "  • Secure git operations without password prompts"
echo "  • No GitHub token expiration issues"
echo "  • Better security for automated operations"
echo ""
log_info "Available commands:"
echo "  • git pull/push now work with SSH"
echo "  • Test connection: ssh -T git@github.com"
echo ""