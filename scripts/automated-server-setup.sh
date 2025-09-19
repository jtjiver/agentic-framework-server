#!/bin/bash
# Automated Idempotent Server Setup Script
# Can be run multiple times safely - checks state before making changes

set -e  # Exit on error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging functions
log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Configuration
SETUP_LOG="/tmp/server-setup-$(date +%Y%m%d-%H%M%S).log"
STATE_FILE="/var/lib/asw-setup-state"
VAULT_NAME="TennisTracker-Dev-Vault"
SERVER_1P_ITEM="netcup - VPS"

# Initialize state tracking
init_state() {
    if [[ ! -f "$STATE_FILE" ]]; then
        sudo touch "$STATE_FILE"
        echo "{}" | sudo tee "$STATE_FILE" > /dev/null
    fi
}

# Check if a step has been completed
is_completed() {
    local step=$1
    grep -q "\"$step\": true" "$STATE_FILE" 2>/dev/null
}

# Mark a step as completed
mark_completed() {
    local step=$1
    local current=$(cat "$STATE_FILE")
    echo "$current" | jq ". + {\"$step\": true}" | sudo tee "$STATE_FILE" > /dev/null
    log_info "✓ Completed: $step"
}

# Get server credentials from 1Password
get_server_credentials() {
    log_info "Retrieving server credentials from 1Password..."
    
    # Get server details
    SERVER_IP=$(op item get "$SERVER_1P_ITEM" --vault "$VAULT_NAME" --format json | jq -r '.urls[0].href' | cut -d'/' -f1)
    ROOT_PASS=$(op item get "$SERVER_1P_ITEM" --vault "$VAULT_NAME" --fields password --reveal)
    
    if [[ -z "$SERVER_IP" ]] || [[ -z "$ROOT_PASS" ]]; then
        log_error "Failed to retrieve server credentials from 1Password"
        return 1
    fi
    
    log_info "Server IP: $SERVER_IP"
    echo "$SERVER_IP" > /tmp/.server_ip
    echo "$ROOT_PASS" > /tmp/.root_pass
    chmod 600 /tmp/.root_pass
}

# Execute command on remote server
remote_exec() {
    local cmd=$1
    local server_ip=$(cat /tmp/.server_ip)
    local root_pass=$(cat /tmp/.root_pass)
    
    sshpass -p "$root_pass" ssh -o StrictHostKeyChecking=no \
        -o PreferredAuthentications=password \
        -o PubkeyAuthentication=no \
        root@"$server_ip" "$cmd"
}

# Execute command on remote server as cc-user
remote_exec_cc() {
    local cmd=$1
    ssh -i /tmp/cc-user-key -o StrictHostKeyChecking=no \
        -o IdentitiesOnly=yes \
        cc-user@$(cat /tmp/.server_ip) "$cmd"
}

# Step 1: System update
setup_system_update() {
    if is_completed "system_update"; then
        log_info "System already updated, skipping..."
        return 0
    fi
    
    log_info "Updating system packages..."
    remote_exec "apt update && apt upgrade -y"
    mark_completed "system_update"
}

# Step 2: Install essential packages
install_essentials() {
    if is_completed "essentials"; then
        log_info "Essential packages already installed, skipping..."
        return 0
    fi
    
    log_info "Installing essential packages..."
    remote_exec "apt install -y sudo curl git wget htop vim nano build-essential bc net-tools python3 python3-pip python3-venv"
    mark_completed "essentials"
}

# Step 3: Create cc-user
create_cc_user() {
    if is_completed "cc_user"; then
        log_info "cc-user already exists, skipping..."
        return 0
    fi
    
    log_info "Creating cc-user..."
    
    # Generate secure password
    CC_USER_PASS=$(openssl rand -base64 20)
    
    # Generate SSH key if it doesn't exist
    if [[ ! -f /tmp/cc-user-key ]]; then
        ssh-keygen -t ed25519 -f /tmp/cc-user-key -N "" -C "cc-user@automated-setup"
    fi
    
    # Create user on server
    remote_exec "
        if ! id -u cc-user >/dev/null 2>&1; then
            useradd -m -s /bin/bash cc-user
            echo 'cc-user:${CC_USER_PASS}' | chpasswd
            usermod -aG sudo cc-user
        fi
        
        # Setup SSH
        mkdir -p /home/cc-user/.ssh
        chmod 700 /home/cc-user/.ssh
        echo '$(cat /tmp/cc-user-key.pub)' > /home/cc-user/.ssh/authorized_keys
        chmod 600 /home/cc-user/.ssh/authorized_keys
        chown -R cc-user:cc-user /home/cc-user/.ssh
        
        # Configure for 1Password SSH agent
        cat > /home/cc-user/.ssh/config << 'EOL'
Host *
    IdentityAgent ~/.1password/agent.sock
    ForwardAgent yes
EOL
        chmod 644 /home/cc-user/.ssh/config
        chown cc-user:cc-user /home/cc-user/.ssh/config
        
        # Create /opt/asw
        mkdir -p /opt/asw
        chown cc-user:cc-user /opt/asw
    "
    
    # Save credentials to 1Password
    log_info "Saving cc-user credentials to 1Password..."
    
    # Create new 1Password item for cc-user
    op item create \
        --category=server \
        --title="netcup VPS - cc-user" \
        --vault="$VAULT_NAME" \
        username=cc-user \
        password="$CC_USER_PASS" \
        server="$(cat /tmp/.server_ip)" \
        notesPlain="SSH Key:\n$(cat /tmp/cc-user-key)\n\nPublic Key:\n$(cat /tmp/cc-user-key.pub)" \
        2>/dev/null || \
    op item edit "netcup VPS - cc-user" \
        --vault="$VAULT_NAME" \
        password="$CC_USER_PASS" \
        2>/dev/null
    
    mark_completed "cc_user"
}

# Step 4: Install Node.js and npm
install_nodejs() {
    if is_completed "nodejs"; then
        log_info "Node.js already installed, skipping..."
        return 0
    fi
    
    log_info "Installing Node.js and npm..."
    remote_exec "
        curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
        apt-get install -y nodejs
    "
    mark_completed "nodejs"
}

# Step 5: Install 1Password CLI
install_1password() {
    if is_completed "1password_cli"; then
        log_info "1Password CLI already installed, skipping..."
        return 0
    fi
    
    log_info "Installing 1Password CLI..."
    remote_exec '
        curl -sS https://downloads.1password.com/linux/keys/1password.asc | \
            gpg --dearmor --output /usr/share/keyrings/1password-archive-keyring.gpg
        
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/1password-archive-keyring.gpg] \
            https://downloads.1password.com/linux/debian/$(dpkg --print-architecture) stable main" | \
            tee /etc/apt/sources.list.d/1password.list
        
        mkdir -p /etc/debsig/policies/AC2D62742012EA22/
        curl -sS https://downloads.1password.com/linux/debian/debsig/1password.pol | \
            tee /etc/debsig/policies/AC2D62742012EA22/1password.pol
        
        mkdir -p /usr/share/debsig/keyrings/AC2D62742012EA22
        curl -sS https://downloads.1password.com/linux/keys/1password.asc | \
            gpg --dearmor --output /usr/share/debsig/keyrings/AC2D62742012EA22/debsig.gpg
        
        apt update && apt install -y 1password-cli
        
        # Setup for cc-user
        mkdir -p /home/cc-user/.1password
        chown cc-user:cc-user /home/cc-user/.1password
    '
    mark_completed "1password_cli"
}

# Step 6: SSH Hardening
harden_ssh() {
    if is_completed "ssh_hardening"; then
        log_info "SSH already hardened, skipping..."
        return 0
    fi
    
    log_info "Hardening SSH configuration..."
    remote_exec '
        # Backup original config
        cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup.$(date +%Y%m%d)
        
        # Create hardening config
        cat > /etc/ssh/sshd_config.d/99-hardening.conf << "EOF"
# SSH Hardening - Automated Setup
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
AllowTcpForwarding yes  # Required for VSCode/Cursor Remote SSH
GatewayPorts no
SyslogFacility AUTH
LogLevel VERBOSE
Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com
MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com
KexAlgorithms curve25519-sha256,curve25519-sha256@libssh.org
EOF
        
        # Test and restart SSH
        sshd -t && systemctl restart ssh
    '
    mark_completed "ssh_hardening"
}

# Step 7: Clone ASW Framework
clone_framework() {
    if is_completed "asw_framework"; then
        log_info "ASW framework already cloned, skipping..."
        return 0
    fi
    
    log_info "Cloning ASW framework repositories..."
    
    # Get GitHub username from user or environment
    GITHUB_USER=${GITHUB_USER:-"yourusername"}
    
    remote_exec_cc "
        cd /opt/asw
        # Clone repositories if they exist
        git clone https://github.com/${GITHUB_USER}/agentic-framework-infrastructure.git 2>/dev/null || true
        git clone https://github.com/${GITHUB_USER}/agentic-framework-security.git 2>/dev/null || true
        git clone https://github.com/${GITHUB_USER}/agentic-framework-core.git 2>/dev/null || true
    "
    
    mark_completed "asw_framework"
}

# Step 7b: Setup System Monitoring
setup_monitoring() {
    if is_completed "monitoring_setup"; then
        log_info "Monitoring already setup, skipping..."
        return 0
    fi
    
    log_info "Installing system monitoring and Gmail API dependencies..."
    
    # Install Gmail API dependencies
    remote_exec "pip3 install google-auth google-auth-oauthlib google-auth-httplib2 google-api-python-client"
    
    # Setup monitoring if framework is available
    remote_exec_cc "
        if [[ -f /opt/asw/agentic-framework-infrastructure/lib/monitoring/install-monitoring.sh ]]; then
            sudo /opt/asw/agentic-framework-infrastructure/lib/monitoring/install-monitoring.sh
        fi
    "
    
    mark_completed "monitoring_setup"
}

# Step 8: Additional Security
additional_security() {
    if is_completed "additional_security"; then
        log_info "Additional security already configured, skipping..."
        return 0
    fi
    
    log_info "Configuring additional security measures..."
    remote_exec '
        # Install UFW firewall
        apt install -y ufw
        ufw default deny incoming
        ufw default allow outgoing
        ufw allow 2222/tcp comment 'SSH on port 2222'
        ufw allow 80/tcp
        ufw allow 443/tcp
        echo "y" | ufw enable
        
        # Install fail2ban
        apt install -y fail2ban
        systemctl enable fail2ban
        systemctl start fail2ban
        
        # Configure automatic updates
        apt install -y unattended-upgrades
        dpkg-reconfigure -plow unattended-upgrades
    '
    mark_completed "additional_security"
}

# Validation
validate_setup() {
    log_info "Validating setup..."
    
    # Test cc-user SSH access
    if remote_exec_cc "whoami" | grep -q "cc-user"; then
        log_info "✓ cc-user SSH access working"
    else
        log_error "✗ cc-user SSH access failed"
        return 1
    fi
    
    # Test that root SSH is disabled
    if ! ssh -o PasswordAuthentication=no -o PreferredAuthentications=publickey \
         root@$(cat /tmp/.server_ip) "echo test" 2>/dev/null; then
        log_info "✓ Root SSH access properly disabled"
    else
        log_warn "⚠ Root SSH might still be accessible"
    fi
    
    # Check installed tools
    remote_exec_cc "
        echo 'Checking installed tools:'
        command -v node && node --version
        command -v npm && npm --version
        command -v op && op --version
        command -v git && git --version
    "
    
    log_info "✓ Setup validation complete"
}

# Main execution
main() {
    log_info "Starting automated server setup..."
    log_info "Log file: $SETUP_LOG"
    
    # Initialize
    init_state
    
    # Get credentials
    get_server_credentials || exit 1
    
    # Execute setup steps
    setup_system_update
    install_essentials
    create_cc_user
    install_nodejs
    install_1password
    harden_ssh
    clone_framework
    setup_monitoring
    additional_security
    
    # Validate
    validate_setup
    
    # Cleanup sensitive files
    rm -f /tmp/.root_pass
    
    log_info "========================================="
    log_info "Server setup complete!"
    log_info "SSH access: ssh -i /tmp/cc-user-key cc-user@$(cat /tmp/.server_ip)"
    log_info "Credentials saved in 1Password: 'netcup VPS - cc-user'"
    log_info "========================================="
}

# Run main function
main "$@" 2>&1 | tee "$SETUP_LOG"