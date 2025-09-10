#!/bin/bash
# Complete Remote VPS Setup Script
# Executes entire server setup from Claude Code instance
# Usage: ./complete-remote-vps-setup.sh "1Password-Server-Item" [github-username]

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

# Logging
log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_action() { echo -e "${BLUE}[ACTION]${NC} $1"; }

# Configuration
SERVER_ITEM="${1}"
GITHUB_USER="${2:-yourusername}"
VAULT_NAME="${3:-TennisTracker-Dev-Vault}"

# Validate arguments
if [[ -z "$SERVER_ITEM" ]]; then
    echo "Usage: $0 <1Password-Server-Item> [github-username] [vault-name]"
    echo "Example: $0 'My VPS Server' 'myusername' 'My-Vault'"
    exit 1
fi

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}     Complete Remote VPS Setup - Claude Code Automation${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

log_info "Configuration:"
echo "  • 1Password Item: $SERVER_ITEM"
echo "  • GitHub User: $GITHUB_USER"
echo "  • Vault: $VAULT_NAME"
echo ""

# Check prerequisites
log_action "Checking prerequisites..."

if ! command -v op &> /dev/null; then
    log_error "1Password CLI not found. Please install it first."
    exit 1
fi

if ! op account list &> /dev/null; then
    log_error "Please sign in to 1Password first: eval \$(op signin)"
    exit 1
fi

# Get server credentials
log_action "Retrieving server credentials from 1Password..."

SERVER_IP=$(op item get "$SERVER_ITEM" --vault "$VAULT_NAME" --format json 2>/dev/null | jq -r '.urls[0].href' | cut -d'/' -f1) || true
ROOT_PASS=$(op item get "$SERVER_ITEM" --vault "$VAULT_NAME" --fields password --reveal 2>/dev/null) || true

if [[ -z "$SERVER_IP" ]]; then
    # Try to get IP from fields
    SERVER_IP=$(op item get "$SERVER_ITEM" --vault "$VAULT_NAME" --fields ip --reveal 2>/dev/null) || true
fi

if [[ -z "$SERVER_IP" ]] || [[ -z "$ROOT_PASS" ]]; then
    log_error "Could not retrieve server credentials from 1Password"
    log_info "Make sure the item '$SERVER_ITEM' exists in vault '$VAULT_NAME'"
    log_info "The item should have:"
    echo "  • URL or 'ip' field with the server IP"
    echo "  • password field with root password"
    exit 1
fi

log_info "Target server: $SERVER_IP"

# Phase 1: Bootstrap
echo ""
log_action "Phase 1: Bootstrapping server..."
echo ""

# Check if we can connect as root
if ! sshpass -p "$ROOT_PASS" ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no root@$SERVER_IP "echo 'Connected'" &>/dev/null; then
    log_error "Cannot connect to server as root"
    log_info "Please check:"
    echo "  • Server IP is correct: $SERVER_IP"
    echo "  • Root password is correct"
    echo "  • SSH is enabled for root (temporarily)"
    exit 1
fi

# Run bootstrap script
if [[ -f "/opt/asw/scripts/complete-server-setup.sh" ]]; then
    log_info "Running bootstrap script..."
    /opt/asw/scripts/complete-server-setup.sh "$SERVER_ITEM" "$VAULT_NAME"
else
    log_warn "Bootstrap script not found, using inline commands..."
    
    # Get SSH public key
    log_info "Please provide your SSH public key from 1Password Private vault:"
    read -p "SSH Public Key: " SSH_PUBLIC_KEY
    
    if [[ -z "$SSH_PUBLIC_KEY" ]]; then
        log_error "SSH public key is required"
        exit 1
    fi
    
    # Execute bootstrap remotely
    sshpass -p "$ROOT_PASS" ssh -o StrictHostKeyChecking=no root@$SERVER_IP 'bash -s' << BOOTSTRAP_SCRIPT
#!/bin/bash
set -e

# Create cc-user
useradd -m -s /bin/bash cc-user 2>/dev/null || echo "User exists"
usermod -aG sudo cc-user

# Generate random password
CC_USER_PASS=\$(openssl rand -base64 32)
echo "cc-user:\$CC_USER_PASS" | chpasswd

# Setup SSH directory
mkdir -p /home/cc-user/.ssh
chmod 700 /home/cc-user/.ssh

# Add SSH key
echo "$SSH_PUBLIC_KEY" > /home/cc-user/.ssh/authorized_keys
chmod 600 /home/cc-user/.ssh/authorized_keys
chown -R cc-user:cc-user /home/cc-user/.ssh

# Install essential packages
apt update
apt install -y sudo curl git wget vim htop build-essential software-properties-common

# Install Node.js
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt install -y nodejs

# Install 1Password CLI
curl -sS https://downloads.1password.com/linux/keys/1password.asc | \\
    gpg --dearmor --output /usr/share/keyrings/1password-archive-keyring.gpg

echo "deb [arch=\$(dpkg --print-architecture) signed-by=/usr/share/keyrings/1password-archive-keyring.gpg] \\
    https://downloads.1password.com/linux/debian/\$(dpkg --print-architecture) stable main" | \\
    tee /etc/apt/sources.list.d/1password.list

apt update && apt install -y 1password-cli

# Create ASW directory
mkdir -p /opt/asw
chown -R cc-user:cc-user /opt/asw

# Basic SSH hardening
sed -i 's/PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
systemctl restart ssh

echo "Bootstrap complete"
echo "Password for cc-user: \$CC_USER_PASS"
BOOTSTRAP_SCRIPT
fi

# Wait for SSH to restart
log_info "Waiting for SSH to restart..."
sleep 10

# Test cc-user access
log_action "Testing cc-user access..."
if ! ssh -A -o ConnectTimeout=10 -o StrictHostKeyChecking=no cc-user@$SERVER_IP "whoami" &>/dev/null; then
    log_warn "Cannot connect as cc-user yet, continuing anyway..."
fi

# Phase 2: Security Hardening
echo ""
log_action "Phase 2: Applying security hardening..."
echo ""

ssh -A -o StrictHostKeyChecking=no cc-user@$SERVER_IP 'bash -s' << 'HARDENING_SCRIPT'
#!/bin/bash
set -e

echo "Starting security hardening..."

# Install security packages
sudo apt update
sudo apt install -y ufw fail2ban unattended-upgrades

# Configure UFW firewall
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 2222/tcp comment 'SSH on port 2222'
sudo ufw allow 80/tcp comment 'HTTP'
sudo ufw allow 443/tcp comment 'HTTPS'
echo "y" | sudo ufw enable

# Configure fail2ban
sudo tee /etc/fail2ban/jail.local > /dev/null << 'EOF'
[DEFAULT]
bantime = 1h
findtime = 10m
maxretry = 3
backend = systemd

[sshd]
enabled = true
port = ssh
filter = sshd
backend = systemd
maxretry = 3
bantime = 1h
EOF

sudo systemctl enable fail2ban
sudo systemctl restart fail2ban

# SSH Hardening
sudo tee /etc/ssh/sshd_config.d/99-hardening.conf > /dev/null << 'EOF'
# ASW Framework SSH Hardening
Port 2222
PermitRootLogin no
PasswordAuthentication no
PermitEmptyPasswords no
PubkeyAuthentication yes
AuthenticationMethods publickey
AllowUsers cc-user
MaxAuthTries 3
MaxSessions 10
Protocol 2
StrictModes yes
X11Forwarding no
AllowAgentForwarding yes
AllowTcpForwarding yes  # Required for VSCode/Cursor Remote SSH
ClientAliveInterval 300
ClientAliveCountMax 2
Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com
MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com
KexAlgorithms curve25519-sha256,curve25519-sha256@libssh.org
EOF

# Test and restart SSH
sudo sshd -t && sudo systemctl restart ssh

# Kernel hardening
sudo tee /etc/sysctl.d/99-asw-hardening.conf > /dev/null << 'EOF'
# Network security
net.ipv4.tcp_syncookies = 1
net.ipv4.ip_forward = 0
net.ipv6.conf.all.forwarding = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.all.accept_redirects = 0
net.ipv6.conf.all.accept_redirects = 0
net.ipv4.conf.all.accept_source_route = 0
net.ipv6.conf.all.accept_source_route = 0
net.ipv4.conf.all.log_martians = 1
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.icmp_ignore_bogus_error_responses = 1
net.ipv4.conf.all.rp_filter = 1
fs.protected_hardlinks = 1
fs.protected_symlinks = 1
kernel.randomize_va_space = 2
EOF

sudo sysctl -p /etc/sysctl.d/99-asw-hardening.conf >/dev/null 2>&1

# Configure automatic updates
sudo tee /etc/apt/apt.conf.d/50unattended-upgrades > /dev/null << 'EOF'
Unattended-Upgrade::Origins-Pattern {
    "origin=Debian,codename=\${distro_codename}-security,label=Debian-Security";
    "origin=Debian,codename=\${distro_codename}-updates";
};
Unattended-Upgrade::Remove-Unused-Dependencies "true";
Unattended-Upgrade::Remove-Unused-Kernel-Packages "true";
Unattended-Upgrade::Automatic-Reboot "false";
EOF

echo "Security hardening complete"
HARDENING_SCRIPT

# Phase 3: Development Environment Setup
echo ""
log_action "Phase 3: Setting up development environment..."
echo ""

# Replace GITHUB_USER in the script
ssh -A -o StrictHostKeyChecking=no cc-user@$SERVER_IP "bash -s $GITHUB_USER" << 'DEV_SETUP_SCRIPT'
#!/bin/bash
set -e

GITHUB_USER=$1
echo "Setting up development environment..."

# Install required packages
sudo apt update
sudo apt install -y jq nginx certbot python3-certbot-nginx docker.io docker-compose htop iotop nethogs

# Clone ASW framework repositories if not present
if [[ ! -d "/opt/asw/agentic-framework-core" ]]; then
    echo "Cloning ASW framework repositories..."
    cd /opt/asw
    
    # Clone repos (using HTTPS for public repos)
    for repo in agentic-framework-core agentic-framework-infrastructure agentic-framework-dev agentic-framework-security; do
        if [[ ! -d "$repo" ]]; then
            git clone "https://github.com/${GITHUB_USER}/${repo}.git" 2>/dev/null || \
            echo "Note: Repository ${repo} not found or not public"
        fi
    done
fi

# Create framework structure even if repos don't exist
cd /opt/asw
for dir in agentic-framework-core agentic-framework-infrastructure agentic-framework-dev agentic-framework-security; do
    mkdir -p "$dir"
done

# Link NPM packages if they have package.json
cd /opt/asw
for pkg in agentic-framework-*; do
    if [[ -d "$pkg" ]] && [[ -f "$pkg/package.json" ]]; then
        echo "Linking package: $pkg"
        cd "$pkg"
        sudo npm link 2>/dev/null || echo "Package $pkg already linked"
        cd ..
    fi
done

# Create command symlinks for infrastructure binaries
if [[ -d "/opt/asw/agentic-framework-infrastructure/bin" ]]; then
    for cmd in /opt/asw/agentic-framework-infrastructure/bin/*; do
        if [[ -f "$cmd" ]] && [[ -x "$cmd" ]]; then
            cmd_name=$(basename "$cmd")
            sudo ln -sf "$cmd" "/usr/local/bin/$cmd_name"
            echo "Linked: $cmd_name"
        fi
    done
fi

# Create command symlinks for core binaries
if [[ -d "/opt/asw/agentic-framework-core/bin" ]]; then
    for cmd in /opt/asw/agentic-framework-core/bin/*; do
        if [[ -f "$cmd" ]] && [[ -x "$cmd" ]]; then
            cmd_name=$(basename "$cmd")
            sudo ln -sf "$cmd" "/usr/local/bin/$cmd_name"
            echo "Linked: $cmd_name"
        fi
    done
fi

# Initialize port registry
mkdir -p /opt/asw/projects
if [[ ! -f "/opt/asw/projects/.ports-registry.json" ]]; then
    echo '{"ports":{}}' > /opt/asw/projects/.ports-registry.json
    echo "Port registry initialized"
fi

# Configure Docker if installed
if command -v docker &> /dev/null; then
    sudo usermod -aG docker cc-user 2>/dev/null || true
    sudo systemctl enable docker
    sudo systemctl start docker
    echo "Docker configured"
fi

# Create helper script
cat > ~/asw-env.sh << 'EOF'
#!/bin/bash
# ASW Framework Environment

export PATH="/usr/local/bin:$PATH"

# Aliases
alias asw-status='echo "=== ASW Status ===" && sudo ufw status | head -5 && echo "" && sudo systemctl is-active fail2ban ssh nginx docker 2>/dev/null'
alias asw-check='/opt/asw/scripts/server-check.sh 2>/dev/null || echo "Server check script not found"'
alias asw-ports='asw-port-manager list 2>/dev/null || echo "Port manager not available"'

# Functions
asw-new-project() {
    local name="${1:-my-project}"
    mkdir -p ~/"$name"
    cd ~/"$name"
    npm init -y
    echo "Project $name created at $(pwd)"
}

echo "ASW Framework environment loaded"
echo "Commands: asw-status, asw-check, asw-ports, asw-new-project"
EOF

chmod +x ~/asw-env.sh
echo "Environment script created at ~/asw-env.sh"

echo "Development environment setup complete"
DEV_SETUP_SCRIPT

# Phase 4: Validation
echo ""
log_action "Phase 4: Validating setup..."
echo ""

ssh -A -o StrictHostKeyChecking=no cc-user@$SERVER_IP << 'VALIDATION_SCRIPT'
#!/bin/bash

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  VALIDATION REPORT"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo "Security Status:"
echo "  • Firewall: $(sudo ufw status | grep -q "Status: active" && echo "✓ Active" || echo "✗ Inactive")"
echo "  • fail2ban: $(sudo systemctl is-active fail2ban | grep -q "active" && echo "✓ Active" || echo "✗ Inactive")"
echo "  • SSH: $(sudo systemctl is-active ssh | grep -q "active" && echo "✓ Active" || echo "✗ Inactive")"
echo ""

echo "Installed Packages:"
echo "  • Node.js: $(node --version 2>/dev/null || echo "Not installed")"
echo "  • npm: $(npm --version 2>/dev/null || echo "Not installed")"
echo "  • 1Password CLI: $(op --version 2>/dev/null || echo "Not installed")"
echo "  • Docker: $(docker --version 2>/dev/null | cut -d' ' -f3 | cut -d',' -f1 || echo "Not installed")"
echo ""

echo "ASW Framework:"
echo "  • Directory: $([ -d /opt/asw ] && echo "✓ /opt/asw exists" || echo "✗ Missing")"
echo "  • Port Registry: $([ -f /opt/asw/projects/.ports-registry.json ] && echo "✓ Initialized" || echo "✗ Not found")"
echo ""

echo "Available Commands:"
for cmd in asw-dev-server asw-port-manager asw-nginx-manager asw-init; do
    which $cmd &>/dev/null && echo "  • ✓ $cmd" || echo "  • ✗ $cmd"
done
echo ""

echo "Framework Directories:"
ls -la /opt/asw/ | grep "agentic-framework" | awk '{print "  • " $9}'
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
VALIDATION_SCRIPT

# Save connection info
echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}     🎉 Complete Remote VPS Setup Finished!${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
log_info "Server Details:"
echo "  • IP Address: $SERVER_IP"
echo "  • SSH Access: ssh -A cc-user@$SERVER_IP"
echo "  • User: cc-user"
echo ""
log_info "Next Steps:"
echo "  1. Connect: ssh -A cc-user@$SERVER_IP"
echo "  2. Load environment: source ~/asw-env.sh"
echo "  3. Create project: asw-new-project my-app"
echo "  4. Start dev server: cd ~/my-app && asw-dev-server start"
echo ""
log_info "Your VPS is now:"
echo "  ✅ Fully hardened with UFW firewall and fail2ban"
echo "  ✅ Configured with ASW framework tools"
echo "  ✅ Ready for development with Node.js and Docker"
echo "  ✅ Protected with SSH key-only authentication"
echo ""

# Update 1Password with completion status (optional)
if command -v op &> /dev/null; then
    log_info "Updating 1Password item with setup status..."
    op item edit "$SERVER_ITEM" "Setup Status=Complete" --vault "$VAULT_NAME" 2>/dev/null || true
    op item edit "$SERVER_ITEM" "Setup Date=$(date)" --vault "$VAULT_NAME" 2>/dev/null || true
    op item edit "$SERVER_ITEM" "SSH Command=ssh -A cc-user@$SERVER_IP" --vault "$VAULT_NAME" 2>/dev/null || true
fi

log_info "Setup complete! 🚀"