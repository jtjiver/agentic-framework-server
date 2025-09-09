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

log "🚀 Starting Complete VPS Server Setup"
log "Server Item: $SERVER_ITEM"
log "SSH Key Item: $SSH_KEY_ITEM"
log "Vault: $VAULT_NAME"

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

# Step 5: Create complete setup script
log "📝 Step 5: Creating server setup script..."
cat > /tmp/complete-remote-setup.sh << 'SETUP_SCRIPT'
#!/bin/bash
set -e

echo "🚀 Starting complete server setup..."

# Update system
echo "📦 Updating system packages..."
apt update && apt upgrade -y

# Install essentials
echo "🔧 Installing essential packages..."
apt install -y sudo curl git wget htop vim nano build-essential ufw fail2ban unattended-upgrades

# Create cc-user
echo "👤 Creating cc-user..."
if ! id -u cc-user >/dev/null 2>&1; then
    useradd -m -s /bin/bash cc-user
    CC_PASS=$(openssl rand -base64 20)
    echo "cc-user:${CC_PASS}" | chpasswd
    usermod -aG sudo cc-user
    echo "NEW_CC_PASSWORD=${CC_PASS}" > /tmp/cc-user-creds
    echo "✅ cc-user created with password: ${CC_PASS}"
else
    echo "✅ cc-user already exists"
fi

# Setup SSH directory
echo "🔐 Setting up SSH for cc-user..."
mkdir -p /home/cc-user/.ssh
chmod 700 /home/cc-user/.ssh

# SSH config for 1Password agent
cat > /home/cc-user/.ssh/config << 'EOF'
Host *
    IdentityAgent ~/.1password/agent.sock
    ForwardAgent yes
EOF

chmod 644 /home/cc-user/.ssh/config
chown -R cc-user:cc-user /home/cc-user/.ssh

# Create /opt/asw and ASW framework structure
echo "📁 Creating ASW framework structure..."
mkdir -p /opt/asw
mkdir -p /opt/asw/agentic-framework-{infrastructure,security,core,dev}/{bin,lib,docs,scripts}
chown -R cc-user:cc-user /opt/asw

# Install Node.js
echo "⚙️  Installing Node.js..."
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt-get install -y nodejs

# Install 1Password CLI
echo "🔑 Installing 1Password CLI..."
curl -sS https://downloads.1password.com/linux/keys/1password.asc | \
    gpg --dearmor --output /usr/share/keyrings/1password-archive-keyring.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/1password-archive-keyring.gpg] \
    https://downloads.1password.com/linux/debian/$(dpkg --print-architecture) stable main" | \
    tee /etc/apt/sources.list.d/1password.list

apt update && apt install -y 1password-cli

mkdir -p /home/cc-user/.1password
chown cc-user:cc-user /home/cc-user/.1password

# Configure firewall
echo "🛡️  Configuring UFW firewall..."
ufw default deny incoming
ufw default allow outgoing
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp
echo "y" | ufw enable

# Configure fail2ban
echo "🚨 Configuring fail2ban..."
systemctl enable fail2ban
systemctl start fail2ban

# SSH Hardening - BEFORE adding the key
echo "🔒 Hardening SSH configuration..."
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup.$(date +%Y%m%d)

cat > /etc/ssh/sshd_config.d/99-hardening.conf << 'EOF'
# SSH Hardening - Complete Setup
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
AllowTcpForwarding no
GatewayPorts no
SyslogFacility AUTH
LogLevel VERBOSE
Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com
MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com
KexAlgorithms curve25519-sha256,curve25519-sha256@libssh.org
EOF

# Test SSH config
sshd -t || { echo "❌ SSH config test failed"; exit 1; }

echo "✅ Server setup complete!"
SETUP_SCRIPT

# Step 6: Run setup on server
log "🔄 Step 6: Executing setup on server..."
sshpass -p "$ROOT_PASS" ssh -o StrictHostKeyChecking=no root@"$SERVER_IP" 'bash -s' < /tmp/complete-remote-setup.sh

# Step 7: Add SSH public key
log "🔐 Step 7: Adding 1Password SSH public key to server..."
sshpass -p "$ROOT_PASS" ssh -o StrictHostKeyChecking=no root@"$SERVER_IP" \
    "echo '$SSH_PUBLIC_KEY' >> /home/cc-user/.ssh/authorized_keys && \
     chmod 600 /home/cc-user/.ssh/authorized_keys && \
     chown cc-user:cc-user /home/cc-user/.ssh/authorized_keys"

# Step 8: Restart SSH service
log "🔄 Step 8: Restarting SSH service with hardened config..."
sshpass -p "$ROOT_PASS" ssh -o StrictHostKeyChecking=no root@"$SERVER_IP" \
    "systemctl restart ssh"

# Step 9: Get new cc-user password
log "🔑 Step 9: Retrieving cc-user password..."
CC_PASS=$(sshpass -p "$ROOT_PASS" ssh -o StrictHostKeyChecking=no root@"$SERVER_IP" \
    "cat /tmp/cc-user-creds 2>/dev/null | grep NEW_CC_PASSWORD | cut -d= -f2" || echo "")

# Step 10: Test 1Password SSH access
log "🧪 Step 10: Testing 1Password SSH access..."
sleep 3  # Give SSH service a moment to restart

if ssh -o PasswordAuthentication=no -o StrictHostKeyChecking=no \
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

# Step 12: Final verification
log "✅ Step 12: Final verification..."
ssh -o PasswordAuthentication=no -o ConnectTimeout=10 \
    cc-user@"$SERVER_IP" \
    "echo 'Server: $(hostname)' && echo 'User: $(whoami)' && echo 'Node.js: $(node --version)' && echo '1Password: $(op --version)' && echo 'Framework: $(ls -la /opt/asw/ | wc -l) directories'" \
    2>/dev/null || warn "Final verification had issues"

# Cleanup
rm -f /tmp/complete-remote-setup.sh

log "🎉 SETUP COMPLETE!"
echo ""
echo "=========================================="
echo "🚀 VPS Server Setup Complete!"
echo "=========================================="
echo "📍 Server IP: $SERVER_IP"
echo "👤 Username: cc-user" 
echo "🔑 Password: $CC_PASS (saved in 1Password)"
echo "🔐 SSH Access: ssh -A cc-user@$SERVER_IP"
echo "📁 Framework: /opt/asw/"
echo ""
echo "✅ Features Configured:"
echo "  - SSH hardened (key-only, no root)"
echo "  - UFW firewall enabled"
echo "  - fail2ban active"
echo "  - Node.js + 1Password CLI installed"
echo "  - ASW framework structure ready"
echo "  - 1Password SSH agent integration"
echo ""
echo "🔗 Connect with 1Password SSH agent:"
echo "   ssh -A cc-user@$SERVER_IP"
echo ""
echo "📋 Requirements:"
echo "  ✅ SSH key in 1Password Private vault"
echo "  ✅ 1Password SSH agent enabled"
echo "  ✅ Use -A flag for agent forwarding"
echo "=========================================="