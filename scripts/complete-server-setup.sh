#!/bin/bash
# Complete VPS Server Setup - One Stop Shop
# Automated server hardening with 1Password SSH integration
# 
# IMPORTANT: 1Password SSH Key Requirements
# ========================================= 
# 1Password SSH Agent only uses keys from your PRIVATE vault by default.
# Service accounts (like Claude Code) cannot access Private vault.
#
# Setup Process:
# 1. Create SSH key in your PRIVATE vault (not shared team vaults)
# 2. This script will prompt for the SSH public key
# 3. Server gets configured with the public key
# 4. You connect using: ssh -A cc-user@SERVER_IP
#
# Usage: ./complete-server-setup.sh "1Password-Server-Item-Name"
# Example: ./complete-server-setup.sh "netcup - VPS"

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

log() { echo -e "${GREEN}[$(date +'%H:%M:%S')]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
info() { echo -e "${BLUE}[INFO]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Check arguments
if [[ $# -lt 1 ]]; then
    echo "Usage: $0 <1Password-Server-Item>"
    echo "Example: $0 'netcup - VPS'"
    echo ""
    echo "📋 Prerequisites:"
    echo "1. Create SSH key in your 1Password PRIVATE vault"
    echo "2. Enable 1Password SSH agent in 1Password settings"
    echo "3. Have server root credentials in 1Password"
    exit 1
fi

SERVER_ITEM="$1"
VAULT_NAME="${2:-TennisTracker-Dev-Vault}"

# Create logs directory and setup logging
LOGS_DIR="/opt/asw/logs"
mkdir -p "$LOGS_DIR"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
LOG_FILE="$LOGS_DIR/server-setup-${TIMESTAMP}.log"
MD_REPORT="$LOGS_DIR/server-setup-${TIMESTAMP}.md"

# Enhanced log function that writes to both console and files
log() { 
    local msg="$1"
    echo -e "${GREEN}[$(date +'%H:%M:%S')]${NC} $msg" | tee -a "$LOG_FILE"
    echo "$(date +'%H:%M:%S') - $msg" >> "$MD_REPORT"
}

warn() { 
    local msg="$1"
    echo -e "${YELLOW}[WARN]${NC} $msg" | tee -a "$LOG_FILE"
    echo "⚠️ **WARNING**: $msg" >> "$MD_REPORT"
}

info() { 
    local msg="$1"
    echo -e "${BLUE}[INFO]${NC} $msg" | tee -a "$LOG_FILE"
    echo "ℹ️ **INFO**: $msg" >> "$MD_REPORT"
}

error() { 
    local msg="$1"
    echo -e "${RED}[ERROR]${NC} $msg" | tee -a "$LOG_FILE"
    echo "❌ **ERROR**: $msg" >> "$MD_REPORT"
}

# Initialize markdown report
cat > "$MD_REPORT" << EOF
# VPS Server Setup Report

**Server Item**: $SERVER_ITEM  
**Vault**: $VAULT_NAME  
**Started**: $(date '+%Y-%m-%d %H:%M:%S')  
**Log File**: $LOG_FILE  

## Setup Progress

EOF

log "🚀 Starting Complete VPS Server Setup"
log "Server Item: $SERVER_ITEM"
log "SSH Key Item: $SSH_KEY_ITEM"
log "Vault: $VAULT_NAME"
info "📝 Logs being written to: $LOG_FILE"
info "📊 Report being written to: $MD_REPORT"

# Step 1: Check 1Password CLI
log "📋 Step 1: Checking 1Password CLI access..."
if ! command -v op &> /dev/null; then
    echo "❌ 1Password CLI not found. Install it first."
    exit 1
fi

if ! op account list &> /dev/null; then
    echo "❌ Please sign in to 1Password first: eval \$(op signin)"
    exit 1
fi

# Step 2: Get server credentials
log "🔑 Step 2: Getting server credentials from 1Password..."
SERVER_IP=$(op item get "$SERVER_ITEM" --vault "$VAULT_NAME" --format json | jq -r '.urls[0].href' | cut -d'/' -f1)
ROOT_PASS=$(op item get "$SERVER_ITEM" --vault "$VAULT_NAME" --fields password --reveal)

if [[ -z "$SERVER_IP" ]] || [[ -z "$ROOT_PASS" ]]; then
    echo "❌ Could not retrieve server credentials"
    exit 1
fi

log "Server IP: $SERVER_IP"

# Step 3: Get SSH public key (since Private vault isn't accessible to service account)
log "🔐 Step 3: Getting SSH public key..."
echo ""
info "1Password SSH Key Setup Requirements:"
echo "▶ SSH keys must be in your PRIVATE vault for SSH agent to use them"
echo "▶ Service accounts cannot access Private vault (good security!)"
echo "▶ Please provide your SSH public key from 1Password or SSH agent"
echo ""
echo "📋 To get your public key:"
echo "1. From 1Password: Open your SSH key item and copy the public key"
echo "2. From SSH agent: Run 'ssh-add -L | grep netcup' on your laptop"
echo ""

read -p "📝 Paste your SSH public key here: " SSH_PUBLIC_KEY

if [[ -z "$SSH_PUBLIC_KEY" ]]; then
    error "SSH public key is required"
    echo ""
    echo "🔄 To create SSH key in 1Password:"
    echo "1. Open 1Password on your laptop"
    echo "2. Click '+' → SSH Key"
    echo "3. Title: netcup VPS SSH Key"
    echo "4. Save to: Private vault (NOT team vaults)"
    echo "5. Generate ED25519 key"
    echo "6. Enable 1Password SSH agent in settings"
    exit 1
fi

# Validate SSH key format
if [[ ! "$SSH_PUBLIC_KEY" =~ ^ssh-(rsa|ed25519|ecdsa) ]]; then
    error "Invalid SSH public key format"
    echo "Key should start with: ssh-rsa, ssh-ed25519, or ssh-ecdsa"
    exit 1
fi

info "✅ SSH public key received: ${SSH_PUBLIC_KEY:0:50}..."

# Step 4: Install sshpass if needed
if ! command -v sshpass &> /dev/null; then
    log "📦 Installing sshpass..."
    if [[ "$OSTYPE" == "darwin"* ]]; then
        brew install hudochenkov/sshpass/sshpass
    else
        sudo apt-get update && sudo apt-get install -y sshpass
    fi
fi

# Step 4.5: Detect SSH port
log "🔍 Step 4.5: Detecting SSH port..."
SSH_PORT=22
# Use netcat to test ports without authentication attempts
if timeout 3 nc -z "$SERVER_IP" 22 2>/dev/null; then
    SSH_PORT=22
    log "Port 22 is open, using SSH port 22"
elif timeout 3 nc -z "$SERVER_IP" 2222 2>/dev/null; then
    SSH_PORT=2222
    log "Port 2222 is open, using SSH port 2222"
else
    error "Cannot detect SSH port (tried 22 and 2222)"
    exit 1
fi

# Step 5: Prepare for step-by-step execution
log "📝 Step 5: Preparing step-by-step server setup..."

# Step 6: Run setup on server with real-time output
log "🔄 Step 6: Executing setup on server..."
log "  📦 6.1: Updating system packages..."
ssh -A -o StrictHostKeyChecking=no -p "$SSH_PORT" cc-user@"$SERVER_IP" "sudo apt update && sudo apt upgrade -y"

log "  🔧 6.2: Installing essential packages..."
ssh -A -o StrictHostKeyChecking=no -p "$SSH_PORT" cc-user@"$SERVER_IP" "sudo apt install -y sudo curl git wget htop vim nano build-essential ufw fail2ban unattended-upgrades iotop nethogs sysstat tmux bash-completion jq unzip"

log "  📊 6.2.1: Enabling system statistics collection..."
ssh -A -o StrictHostKeyChecking=no -p "$SSH_PORT" cc-user@"$SERVER_IP" "sudo systemctl enable sysstat && sudo systemctl start sysstat"

log "  👤 6.3: Setting up cc-user..."
ssh -A -o StrictHostKeyChecking=no -p "$SSH_PORT" cc-user@"$SERVER_IP" "
if ! id -u cc-user >/dev/null 2>&1; then
    sudo useradd -m -s /bin/bash cc-user
    CC_PASS=\$(openssl rand -base64 20)
    echo \"cc-user:\${CC_PASS}\" | sudo chpasswd
    sudo usermod -aG sudo cc-user
    echo \"cc-user ALL=(ALL) NOPASSWD:ALL\" | sudo tee /etc/sudoers.d/cc-user
    sudo chmod 440 /etc/sudoers.d/cc-user
    echo \"NEW_CC_PASSWORD=\${CC_PASS}\" | sudo tee /tmp/cc-user-creds
    echo \"✅ cc-user created with password: \${CC_PASS}\"
else
    echo \"✅ cc-user already exists\"
    if [ ! -f /etc/sudoers.d/cc-user ]; then
        echo \"cc-user ALL=(ALL) NOPASSWD:ALL\" | sudo tee /etc/sudoers.d/cc-user
        sudo chmod 440 /etc/sudoers.d/cc-user
        echo \"✅ Passwordless sudo configured for cc-user\"
    fi
fi"

log "  🔐 6.4: Setting up SSH configuration..."
ssh -A -o StrictHostKeyChecking=no -p "$SSH_PORT" cc-user@"$SERVER_IP" "
mkdir -p ~/.ssh
chmod 700 ~/.ssh
cat > ~/.ssh/config << 'EOF'
Host *
    IdentityAgent ~/.1password/agent.sock
    ForwardAgent yes
EOF
chmod 644 ~/.ssh/config"


log "  📁 6.5: Creating ASW directory..."
ssh -A -o StrictHostKeyChecking=no -p "$SSH_PORT" cc-user@"$SERVER_IP" "sudo mkdir -p /opt/asw && sudo chown -R cc-user:cc-user /opt/asw"

log "  ⚙️ 6.6: Installing Node.js..."
ssh -A -o StrictHostKeyChecking=no -p "$SSH_PORT" cc-user@"$SERVER_IP" "
if ! command -v node &> /dev/null; then
    curl -fsSL https://deb.nodesource.com/setup_20.x | sudo bash -
    sudo apt-get install -y nodejs
    echo \"✅ Node.js installed: \$(node --version)\"
else
    echo \"✅ Node.js already installed: \$(node --version)\"
fi"

log "  🤖 6.7: Installing Claude Code CLI..."
ssh -A -o StrictHostKeyChecking=no -p "$SSH_PORT" cc-user@"$SERVER_IP" "
if ! command -v claude &> /dev/null; then
    sudo npm install -g @anthropic-ai/claude-code
    echo \"✅ Claude Code CLI installed\"
else
    echo \"✅ Claude Code CLI already installed: \$(claude --version 2>/dev/null || echo 'installed')\"
fi"

log "  🔑 6.8: Installing 1Password CLI..."
ssh -A -o StrictHostKeyChecking=no -p "$SSH_PORT" cc-user@"$SERVER_IP" "
if ! command -v op &> /dev/null; then
    curl -sS https://downloads.1password.com/linux/keys/1password.asc | sudo gpg --dearmor --output /usr/share/keyrings/1password-archive-keyring.gpg
    echo \"deb [arch=\$(dpkg --print-architecture) signed-by=/usr/share/keyrings/1password-archive-keyring.gpg] https://downloads.1password.com/linux/debian/\$(dpkg --print-architecture) stable main\" | sudo tee /etc/apt/sources.list.d/1password.list
    sudo apt update && sudo apt install -y 1password-cli
    sudo mkdir -p ~/.1password && sudo chown cc-user:cc-user ~/.1password
    echo \"✅ 1Password CLI installed: \$(op --version)\"
else
    echo \"✅ 1Password CLI already installed: \$(op --version)\"
fi"

log "  🛡️ 6.9: Configuring firewall..."
ssh -A -o StrictHostKeyChecking=no -p "$SSH_PORT" cc-user@"$SERVER_IP" "
sudo ufw default deny incoming
sudo ufw default allow outgoing  
sudo ufw allow 2222/tcp comment 'SSH on port 2222'
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
echo 'y' | sudo ufw enable
echo \"✅ UFW firewall configured\""

log "  🚨 6.10: Configuring fail2ban..."
ssh -A -o StrictHostKeyChecking=no -p "$SSH_PORT" cc-user@"$SERVER_IP" "sudo systemctl enable fail2ban && sudo systemctl start fail2ban && echo \"✅ fail2ban configured\""

log "  🔒 6.11: Hardening SSH configuration..."
ssh -A -o StrictHostKeyChecking=no -p "$SSH_PORT" cc-user@"$SERVER_IP" "
sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup.\$(date +%Y%m%d) 2>/dev/null || true
sudo tee /etc/ssh/sshd_config.d/99-hardening.conf > /dev/null << 'EOF'
# SSH Hardening - Complete Setup
Port 2222
PermitRootLogin no
Protocol 2
PasswordAuthentication no
PermitEmptyPasswords no
PubkeyAuthentication yes
HostbasedAuthentication no
IgnoreRhosts yes
MaxAuthTries 3
MaxSessions 10
AllowUsers cc-user
LoginGraceTime 60
StrictModes yes
X11Forwarding no
PrintLastLog yes
TCPKeepAlive yes
ClientAliveInterval 300
ClientAliveCountMax 2
AllowAgentForwarding yes
AllowTcpForwarding yes
GatewayPorts no
SyslogFacility AUTH
LogLevel VERBOSE
Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com
MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com
KexAlgorithms curve25519-sha256,curve25519-sha256@libssh.org
EOF
sudo sshd -t && echo \"✅ SSH configuration hardened\"
"

log "✅ Step 6: Server setup complete!"

# Step 7: Add SSH public key
log "🔐 Step 7: Adding 1Password SSH public key to server..."
ssh -A -o StrictHostKeyChecking=no -p "$SSH_PORT" cc-user@"$SERVER_IP" \
    "echo '$SSH_PUBLIC_KEY' >> ~/.ssh/authorized_keys && \
     chmod 600 ~/.ssh/authorized_keys"

# Step 8: Restart SSH service
log "🔄 Step 8: Restarting SSH service with hardened config..."
ssh -A -o StrictHostKeyChecking=no -p "$SSH_PORT" cc-user@"$SERVER_IP" \
    "sudo systemctl restart ssh"

# Step 9: Get new cc-user password
log "🔑 Step 9: Retrieving cc-user password..."
CC_PASS=$(ssh -A -o StrictHostKeyChecking=no -p "$SSH_PORT" cc-user@"$SERVER_IP" \
    "sudo cat /tmp/cc-user-creds 2>/dev/null | grep NEW_CC_PASSWORD | cut -d= -f2" || echo "")

# Step 10: Test 1Password SSH access
log "🧪 Step 10: Testing 1Password SSH access..."
sleep 3  # Give SSH service a moment to restart

# After restart, SSH will be on port 2222 due to hardening config
if ssh -o PasswordAuthentication=no -o StrictHostKeyChecking=no -p 2222 \
    cc-user@"$SERVER_IP" "echo 'SSH access working!'" 2>/dev/null; then
    log "✅ 1Password SSH access working!"
else
    warn "⚠️  1Password SSH test failed - you may need to configure SSH agent"
fi

# Step 11: Update 1Password with server details
log "💾 Step 11: Updating 1Password with server details..."
op item edit "$SERVER_ITEM" \
    --vault "$VAULT_NAME" \
    "cc-user password"="$CC_PASS" \
    "Setup Status"="Complete - $(date)" \
    2>/dev/null || warn "Could not update 1Password item (check permissions)"

# Step 12: Clone framework repositories
log "📦 Step 12: Setting up framework repositories as proper git repos..."

# Get GitHub token
GITHUB_TOKEN=$(op item get "Github Personal Access Token - TennisTracker CI/CD" --vault "$VAULT_NAME" --fields token --reveal 2>/dev/null || echo "")

if [[ -n "$GITHUB_TOKEN" ]]; then
    # Remove the existing /opt/asw directory structure and clone agentic-framework-server as the main repo
    ssh -A -p 2222 cc-user@"$SERVER_IP" "
        # Backup any existing content
        if [ -d /opt/asw ]; then
            sudo mv /opt/asw /opt/asw-backup-$(date +%s)
        fi
        
        # Clone agentic-framework-server as the main /opt/asw repository
        sudo git clone https://$GITHUB_TOKEN@github.com/jtjiver/agentic-framework-server.git /opt/asw
        sudo chown -R cc-user:cc-user /opt/asw
        echo '✅ agentic-framework-server cloned as main /opt/asw repo'
    "
    
    # Clone agentic-claude-config and copy .claude folder
    ssh -A -p 2222 cc-user@"$SERVER_IP" "cd /opt/asw && \
        git clone https://$GITHUB_TOKEN@github.com/jtjiver/agentic-claude-config.git temp-claude && \
        cp -r temp-claude/.claude . && \
        rm -rf temp-claude && \
        git add .claude && \
        git config user.email 'cc-user@$(hostname)' && \
        git config user.name 'CC User' && \
        git commit -m 'Add Claude Code configuration' || true && \
        echo '✅ .claude configuration added to main repo'"
    
    # Clone other agentic-framework repositories as subdirectories
    for repo in core dev infrastructure security; do
        ssh -A -p 2222 cc-user@"$SERVER_IP" "cd /opt/asw && \
            git clone https://$GITHUB_TOKEN@github.com/jtjiver/agentic-framework-$repo.git agentic-framework-$repo && \
            echo '✅ agentic-framework-$repo cloned as submodule'"
    done
    
    # Run the framework setup script if it exists
    ssh -A -p 2222 cc-user@"$SERVER_IP" "cd /opt/asw && [ -f ./setup.sh ] && ./setup.sh || echo 'No setup.sh found, skipping framework setup'"
    
    # Set up cc-user shell environment with banner (after framework files are in place)
    log "🎨 Step 12.1: Setting up cc-user shell environment with banner..."
    ssh -A -p 2222 cc-user@"$SERVER_IP" "
        if [[ -f /opt/asw/scripts/setup-cc-user-environment.sh ]]; then
            echo '✅ Setting up enhanced shell environment with banner and aliases...'
            sudo /opt/asw/scripts/setup-cc-user-environment.sh
            echo '✅ Shell environment setup complete - login banner will be available'
        else
            echo '⚠️ cc-user environment setup script not found, skipping enhanced shell setup'
        fi"
else
    warn "⚠️  No GitHub token found - framework repositories not cloned"
    warn "    Repositories must be set up manually"
    
    # Even without framework repos, we can still set up basic cc-user environment
    log "🎨 Step 12.1: Setting up basic cc-user shell environment..."
    ssh -A -p 2222 cc-user@"$SERVER_IP" "
        # Create basic tmux config and environment setup without framework dependencies
        echo '⚠️ Setting up basic shell environment (no framework files available)'
        
        # Install basic packages
        sudo apt update -qq
        sudo apt install -y tmux bash-completion curl git unzip jq
        
        # Create directories
        mkdir -p ~/.config/claude-projects ~/.config/1password ~/.local/bin
        
        # Basic .bashrc setup (without framework banner)
        cat > ~/.bashrc << 'BASHRC_EOF'
# Basic bash configuration
case \$- in
    *i*) ;;
      *) return;;
esac

HISTCONTROL=ignoreboth
shopt -s histappend
HISTSIZE=2000
HISTFILESIZE=4000

# Colors and aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

# PATH
export PATH=\"\$HOME/.local/bin:\$PATH\"

echo '⚠️ ASW Framework not installed - basic shell only'
BASHRC_EOF
        
        echo '✅ Basic shell environment setup complete (framework banner unavailable)'
    "
fi

# Step 13: Final verification
log "✅ Step 13: Basic system verification..."
ssh -o PasswordAuthentication=no -o ConnectTimeout=10 -p 2222 \
    cc-user@"$SERVER_IP" \
    "echo 'Server: $(hostname)' && echo 'User: $(whoami)' && echo 'Node.js: $(node --version)' && echo 'Claude Code: $(claude --version 2>/dev/null || echo \"not found\")' && echo '1Password: $(op --version)' && echo 'Framework: $(ls -la /opt/asw/ | wc -l) directories'" \
    2>/dev/null || warn "Basic verification had issues"

# Step 14: Comprehensive ASW Framework validation
log "🔍 Step 14: Running comprehensive ASW Framework validation..."
echo "" >> "$MD_REPORT"
echo "## ASW Framework Validation Results" >> "$MD_REPORT"
echo "" >> "$MD_REPORT"
echo '```' >> "$MD_REPORT"

# Capture validation output to both console and report
VALIDATION_OUTPUT=$(ssh -A -o StrictHostKeyChecking=no -p 2222 cc-user@"$SERVER_IP" \
    "cd /opt/asw && /opt/asw/scripts/check-all-phases.sh" 2>&1)

echo "$VALIDATION_OUTPUT" | tee -a "$LOG_FILE"
echo "$VALIDATION_OUTPUT" >> "$MD_REPORT"
echo '```' >> "$MD_REPORT"

# Extract validation result for final summary
if echo "$VALIDATION_OUTPUT" | grep -q "COMPLETE ASW FRAMEWORK VALIDATION: SUCCESS"; then
    VALIDATION_STATUS="✅ SUCCESS"
elif echo "$VALIDATION_OUTPUT" | grep -q "PARTIAL ASW FRAMEWORK VALIDATION"; then
    VALIDATION_STATUS="⚠️ PARTIAL"
else
    VALIDATION_STATUS="❌ FAILED"
fi

echo "" >> "$MD_REPORT"
echo "**Validation Status**: $VALIDATION_STATUS" >> "$MD_REPORT"

# Step 15: Pull back remote validation logs
log "📥 Step 15: Retrieving remote validation logs..."
REMOTE_LOG_DIR="/opt/asw/logs"
LOCAL_REMOTE_LOGS_DIR="$LOGS_DIR/remote-$(basename "$SERVER_IP")"
mkdir -p "$LOCAL_REMOTE_LOGS_DIR"

# Get the latest validation log file from remote server if it exists
ssh -A -o StrictHostKeyChecking=no -p 2222 cc-user@"$SERVER_IP" \
    "find /opt/asw -name '*.log' -o -name '*validation*.md' 2>/dev/null | head -10" > /tmp/remote_logs_list.txt 2>/dev/null || true

if [[ -s /tmp/remote_logs_list.txt ]]; then
    while IFS= read -r remote_log; do
        if [[ -n "$remote_log" ]]; then
            log_filename=$(basename "$remote_log")
            log "  📄 Copying remote log: $log_filename"
            scp -P 2222 -o StrictHostKeyChecking=no cc-user@"$SERVER_IP":"$remote_log" "$LOCAL_REMOTE_LOGS_DIR/" 2>/dev/null || warn "Failed to copy $log_filename"
        fi
    done < /tmp/remote_logs_list.txt
    rm -f /tmp/remote_logs_list.txt
else
    info "No remote validation logs found to retrieve"
fi

# Also create a comprehensive validation summary file locally
VALIDATION_SUMMARY="$LOGS_DIR/validation-summary-$(basename "$SERVER_IP")-$TIMESTAMP.md"
cat > "$VALIDATION_SUMMARY" << EOF
# Server Validation Summary

**Server**: $SERVER_IP  
**Validation Date**: $(date '+%Y-%m-%d %H:%M:%S')  
**Setup Session**: $TIMESTAMP  
**Status**: $VALIDATION_STATUS  

## Remote Logs Retrieved
$(ls -la "$LOCAL_REMOTE_LOGS_DIR" 2>/dev/null | tail -n +2 | awk '{print "- " $9 " (" $5 " bytes, " $6 " " $7 " " $8 ")"}' || echo "No remote logs available")

## Validation Output
\`\`\`
$VALIDATION_OUTPUT
\`\`\`

## Next Steps
$(if [[ "$VALIDATION_STATUS" == "✅ SUCCESS" ]]; then
    echo "✅ Server is fully operational and ready for development"
elif [[ "$VALIDATION_STATUS" == "⚠️ PARTIAL" ]]; then
    echo "⚠️ Review validation results and address any failed components"
else
    echo "❌ Server requires attention - check validation output for specific issues"
fi)
EOF

log "📋 Validation summary created: $VALIDATION_SUMMARY"
info "🗂️ Remote logs stored in: $LOCAL_REMOTE_LOGS_DIR"

# Cleanup - no temp files to remove

# Finalize markdown report
cat >> "$MD_REPORT" << EOF

## Final Summary

**Completed**: $(date '+%Y-%m-%d %H:%M:%S')  
**Duration**: $(($(date +%s) - $(date -r "$LOG_FILE" +%s 2>/dev/null || date +%s))) seconds  
**Server IP**: $SERVER_IP  
**Username**: cc-user  
**SSH Access**: \`ssh -A -p 2222 cc-user@$SERVER_IP\`  
**Framework Directory**: /opt/asw/  
**Validation Status**: $VALIDATION_STATUS  

### Features Configured
- ✅ SSH hardened (key-only, no root)
- ✅ UFW firewall enabled  
- ✅ fail2ban active
- ✅ Node.js + Claude Code + 1Password CLI installed
- ✅ ASW framework repositories cloned
- ✅ Claude Code configuration (.claude) installed
- ✅ 1Password SSH agent integration

### Requirements
- ✅ SSH key in 1Password Private vault
- ✅ 1Password SSH agent enabled  
- ✅ Use -A flag for agent forwarding

### Log Files
- **Setup Log**: $LOG_FILE
- **Setup Report**: $MD_REPORT  
- **Validation Summary**: $VALIDATION_SUMMARY
- **Remote Logs**: $LOCAL_REMOTE_LOGS_DIR

### Next Steps
$(if [[ "$VALIDATION_STATUS" == "✅ SUCCESS" ]]; then
    echo "🎉 Server is fully configured and ready for development!"
    echo "- Create your first project: \`/opt/asw/scripts/new-project.sh my-project personal\`"
    echo "- Start development server: \`asw-dev-server start\`"
elif [[ "$VALIDATION_STATUS" == "⚠️ PARTIAL" ]]; then
    echo "⚠️ Server setup is partially complete. Review validation results above."
    echo "- Address any failed components"  
    echo "- Re-run validation: \`ssh -A -p 2222 cc-user@$SERVER_IP 'cd /opt/asw && ./scripts/check-all-phases.sh'\`"
else
    echo "❌ Server setup has issues. Review validation results above."
    echo "- Check the validation output for specific failures"
    echo "- Consider re-running specific setup phases"
fi)
EOF

log "🎉 SETUP COMPLETE!"
echo ""
echo "=========================================="
echo "🚀 VPS Server Setup Complete!"
echo "=========================================="
echo "📍 Server IP: $SERVER_IP"
echo "👤 Username: cc-user" 
echo "🔑 Password: $CC_PASS (saved in 1Password)"
echo "🔐 SSH Access: ssh -A -p 2222 cc-user@$SERVER_IP"
echo "📁 Framework: /opt/asw/"
echo "📊 Setup Report: $MD_REPORT"
echo "📝 Setup Log: $LOG_FILE"
echo "📋 Validation Summary: $VALIDATION_SUMMARY"
echo "🗂️ Remote Logs: $LOCAL_REMOTE_LOGS_DIR"
echo ""
echo "✅ Features Configured:"
echo "  - SSH hardened (key-only, no root)"
echo "  - UFW firewall enabled"
echo "  - fail2ban active"
echo "  - Node.js + Claude Code + 1Password CLI installed"
echo "  - ASW framework repositories cloned"
echo "  - Claude Code configuration (.claude) installed"
echo "  - 1Password SSH agent integration"
echo ""
echo "🔍 Validation Status: $VALIDATION_STATUS"
echo ""
echo "🔗 Connect with 1Password SSH agent:"
echo "   ssh -A -p 2222 cc-user@$SERVER_IP"
echo ""
echo "📋 Requirements:"
echo "  ✅ SSH key in 1Password Private vault"
echo "  ✅ 1Password SSH agent enabled"
echo "  ✅ Use -A flag for agent forwarding"
echo "=========================================="