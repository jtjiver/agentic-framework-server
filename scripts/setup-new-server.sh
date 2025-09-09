#!/bin/bash
# One-command server setup script
# Usage: ./setup-new-server.sh "1Password-Item-Name"

set -e

# Check if 1Password item name is provided
if [[ $# -eq 0 ]]; then
    echo "Usage: $0 <1Password-Item-Name>"
    echo "Example: $0 'netcup - VPS'"
    exit 1
fi

ITEM_NAME="$1"
VAULT_NAME="${2:-TennisTracker-Dev-Vault}"  # Default vault, can override

echo "Setting up server from 1Password item: $ITEM_NAME"

# Check 1Password CLI is available
if ! command -v op &> /dev/null; then
    echo "Error: 1Password CLI not installed"
    echo "Install with: brew install 1password-cli"
    exit 1
fi

# Check if signed in to 1Password
if ! op account list &> /dev/null; then
    echo "Please sign in to 1Password first:"
    echo "eval \$(op signin)"
    exit 1
fi

# Get server credentials
echo "Retrieving server credentials..."
SERVER_IP=$(op item get "$ITEM_NAME" --vault "$VAULT_NAME" --format json | jq -r '.urls[0].href' | cut -d'/' -f1)
ROOT_PASS=$(op item get "$ITEM_NAME" --vault "$VAULT_NAME" --fields password --reveal)

if [[ -z "$SERVER_IP" ]] || [[ -z "$ROOT_PASS" ]]; then
    echo "Error: Could not retrieve server credentials from 1Password"
    exit 1
fi

echo "Server IP: $SERVER_IP"

# Install sshpass if needed
if ! command -v sshpass &> /dev/null; then
    echo "Installing sshpass..."
    if [[ "$OSTYPE" == "darwin"* ]]; then
        brew install hudochenkov/sshpass/sshpass
    else
        sudo apt-get install -y sshpass
    fi
fi

# Generate SSH key for cc-user
SSH_KEY="/tmp/cc-user-key-$$"
ssh-keygen -t ed25519 -f "$SSH_KEY" -N "" -C "cc-user@automated-setup" -q

# Create the complete setup script
cat > /tmp/remote-setup.sh << 'SCRIPT'
#!/bin/bash
set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}Starting server setup...${NC}"

# 1. Update system
echo "Updating system..."
apt update && apt upgrade -y

# 2. Install essentials
echo "Installing essential packages..."
apt install -y sudo curl git wget htop vim nano build-essential

# 3. Create cc-user
echo "Creating cc-user..."
if ! id -u cc-user >/dev/null 2>&1; then
    useradd -m -s /bin/bash cc-user
    CC_PASS=$(openssl rand -base64 20)
    echo "cc-user:${CC_PASS}" | chpasswd
    usermod -aG sudo cc-user
    echo "CC_USER_PASSWORD=${CC_PASS}" > /tmp/cc-user-creds
fi

# 4. Setup SSH for cc-user
mkdir -p /home/cc-user/.ssh
chmod 700 /home/cc-user/.ssh

# SSH config for 1Password
cat > /home/cc-user/.ssh/config << 'EOF'
Host *
    IdentityAgent ~/.1password/agent.sock
    ForwardAgent yes
EOF

chmod 644 /home/cc-user/.ssh/config
chown -R cc-user:cc-user /home/cc-user/.ssh

# 5. Create /opt/asw
mkdir -p /opt/asw
chown cc-user:cc-user /opt/asw

# 6. Install Node.js
echo "Installing Node.js..."
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt-get install -y nodejs

# 7. Install 1Password CLI
echo "Installing 1Password CLI..."
curl -sS https://downloads.1password.com/linux/keys/1password.asc | \
    gpg --dearmor --output /usr/share/keyrings/1password-archive-keyring.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/1password-archive-keyring.gpg] \
    https://downloads.1password.com/linux/debian/$(dpkg --print-architecture) stable main" | \
    tee /etc/apt/sources.list.d/1password.list

apt update && apt install -y 1password-cli

mkdir -p /home/cc-user/.1password
chown cc-user:cc-user /home/cc-user/.1password

# 8. SSH Hardening
echo "Hardening SSH..."
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup.$(date +%Y%m%d)

cat > /etc/ssh/sshd_config.d/99-hardening.conf << 'EOF'
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

# 9. Additional Security
echo "Setting up firewall..."
apt install -y ufw fail2ban unattended-upgrades

ufw default deny incoming
ufw default allow outgoing
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp
echo "y" | ufw enable

systemctl enable fail2ban
systemctl start fail2ban

echo -e "${GREEN}Server setup complete!${NC}"
SCRIPT

# Copy SSH public key and setup script to server
echo "Setting up server..."
sshpass -p "$ROOT_PASS" ssh -o StrictHostKeyChecking=no root@"$SERVER_IP" \
    "cat > /tmp/cc-user-key.pub" < "${SSH_KEY}.pub"

sshpass -p "$ROOT_PASS" ssh -o StrictHostKeyChecking=no root@"$SERVER_IP" \
    "bash -s" < /tmp/remote-setup.sh

# Add SSH key to cc-user
sshpass -p "$ROOT_PASS" ssh -o StrictHostKeyChecking=no root@"$SERVER_IP" \
    "cat /tmp/cc-user-key.pub >> /home/cc-user/.ssh/authorized_keys && \
     chmod 600 /home/cc-user/.ssh/authorized_keys && \
     chown cc-user:cc-user /home/cc-user/.ssh/authorized_keys"

# Get cc-user password
CC_PASS=$(sshpass -p "$ROOT_PASS" ssh -o StrictHostKeyChecking=no root@"$SERVER_IP" \
    "cat /tmp/cc-user-creds 2>/dev/null | grep CC_USER_PASSWORD | cut -d= -f2" || echo "")

# Restart SSH
sshpass -p "$ROOT_PASS" ssh -o StrictHostKeyChecking=no root@"$SERVER_IP" \
    "sshd -t && systemctl restart ssh"

# Save to 1Password
echo "Saving credentials to 1Password..."

# Create the SSH key content for notes
SSH_KEY_CONTENT=$(cat "$SSH_KEY")
SSH_PUB_CONTENT=$(cat "${SSH_KEY}.pub")

# Create or update 1Password item
op item create \
    --category=server \
    --title="${ITEM_NAME} - cc-user" \
    --vault="$VAULT_NAME" \
    username=cc-user \
    password="${CC_PASS:-GeneratedOnServer}" \
    server="$SERVER_IP" \
    "SSH Private Key[password]"="$SSH_KEY_CONTENT" \
    notesPlain="Public Key:\n${SSH_PUB_CONTENT}\n\nSSH Command:\nssh -i ~/.ssh/cc-user-key cc-user@${SERVER_IP}" \
    2>/dev/null || \
op item edit "${ITEM_NAME} - cc-user" \
    --vault="$VAULT_NAME" \
    password="${CC_PASS:-GeneratedOnServer}" \
    2>/dev/null || true

# Save SSH key locally
mkdir -p ~/.ssh
cp "$SSH_KEY" ~/.ssh/cc-user-key-${SERVER_IP}
chmod 600 ~/.ssh/cc-user-key-${SERVER_IP}

# Test connection
echo "Testing cc-user connection..."
if ssh -i ~/.ssh/cc-user-key-${SERVER_IP} -o StrictHostKeyChecking=no \
    cc-user@"$SERVER_IP" "whoami" | grep -q cc-user; then
    echo "✅ Setup complete!"
    echo ""
    echo "========================================="
    echo "Server setup successful!"
    echo "SSH access: ssh -i ~/.ssh/cc-user-key-${SERVER_IP} cc-user@${SERVER_IP}"
    echo "Credentials saved in 1Password: '${ITEM_NAME} - cc-user'"
    echo "========================================="
else
    echo "⚠️  Setup complete but SSH test failed"
fi

# Cleanup
rm -f /tmp/remote-setup.sh "$SSH_KEY" "${SSH_KEY}.pub"