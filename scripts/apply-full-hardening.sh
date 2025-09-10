#!/bin/bash
# ASW Framework Full Server Hardening Script
# Run this LOCALLY on the server after bootstrap
# This completes all security hardening in one go

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Logging functions
log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_action() { echo -e "${BLUE}[ACTION]${NC} $1"; }

# Header
echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}     ASW Framework - Complete Server Hardening Script${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Check if running as cc-user with sudo
if [[ "$USER" != "cc-user" ]]; then
    log_warn "This script should be run as cc-user"
    log_info "Current user: $USER"
fi

# Function to check if a component is already configured
is_configured() {
    local component=$1
    case $component in
        "ufw")
            sudo ufw status 2>/dev/null | grep -q "Status: active"
            ;;
        "fail2ban")
            sudo systemctl is-active fail2ban >/dev/null 2>&1
            ;;
        "ssh_hardening")
            [[ -f /etc/ssh/sshd_config.d/99-hardening.conf ]]
            ;;
        "auto_updates")
            dpkg -l | grep -q unattended-upgrades
            ;;
        *)
            return 1
            ;;
    esac
}

# 1. SSH Hardening
apply_ssh_hardening() {
    if is_configured "ssh_hardening"; then
        log_info "✓ SSH hardening already configured"
        return 0
    fi
    
    log_action "Applying SSH hardening..."
    
    # Backup original config
    sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup.$(date +%Y%m%d) 2>/dev/null || true
    
    # Create comprehensive hardening config
    sudo tee /etc/ssh/sshd_config.d/99-hardening.conf > /dev/null << 'EOF'
# ASW Framework SSH Hardening Configuration
# Generated: $(date)

# Port configuration
Port 2222

# Authentication
PermitRootLogin no
PasswordAuthentication no
PermitEmptyPasswords no
PubkeyAuthentication yes
AuthenticationMethods publickey
HostbasedAuthentication no
IgnoreRhosts yes

# User restrictions
AllowUsers cc-user
MaxAuthTries 3
MaxSessions 10
LoginGraceTime 60

# Protocol and ciphers
Protocol 2
Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com
MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com
KexAlgorithms curve25519-sha256,curve25519-sha256@libssh.org

# Security settings
StrictModes yes
X11Forwarding no
AllowAgentForwarding yes
AllowTcpForwarding yes  # Required for VSCode/Cursor Remote SSH
GatewayPorts no
PermitTunnel no
PrintLastLog yes
TCPKeepAlive yes
Compression no

# Logging
SyslogFacility AUTH
LogLevel VERBOSE

# Client keep-alive
ClientAliveInterval 300
ClientAliveCountMax 2
EOF
    
    # Test and restart SSH
    if sudo sshd -t; then
        sudo systemctl restart ssh
        log_info "✅ SSH hardening applied successfully"
    else
        log_error "SSH configuration test failed"
        return 1
    fi
}

# 2. Firewall Setup
setup_firewall() {
    if is_configured "ufw"; then
        log_info "✓ UFW firewall already active"
        return 0
    fi
    
    log_action "Configuring UFW firewall..."
    
    # Install if needed
    if ! command -v ufw &> /dev/null; then
        sudo apt update && sudo apt install -y ufw
    fi
    
    # Configure rules
    sudo ufw default deny incoming
    sudo ufw default allow outgoing
    sudo ufw allow 2222/tcp comment 'SSH on port 2222'
    sudo ufw allow 80/tcp comment 'HTTP'
    sudo ufw allow 443/tcp comment 'HTTPS'
    
    # Enable firewall
    echo "y" | sudo ufw enable
    
    log_info "✅ UFW firewall configured and activated"
}

# 3. Intrusion Prevention
setup_fail2ban() {
    log_action "Configuring fail2ban..."
    
    # Install if needed
    if ! command -v fail2ban-client &> /dev/null; then
        sudo apt update && sudo apt install -y fail2ban
    fi
    
    # Create jail configuration for systemd
    sudo tee /etc/fail2ban/jail.local > /dev/null << 'EOF'
[DEFAULT]
# Ban for 1 hour after 3 failures in 10 minutes
bantime = 1h
findtime = 10m
maxretry = 3
backend = systemd
destemail = root@localhost
action = %(action_mwl)s

[sshd]
enabled = true
port = ssh
filter = sshd
backend = systemd
maxretry = 3
bantime = 1h
findtime = 10m

# Additional jails can be added here
# [nginx-http-auth]
# enabled = true
# filter = nginx-http-auth
# port = http,https
# backend = systemd
EOF
    
    # Enable and restart service
    sudo systemctl enable fail2ban
    sudo systemctl restart fail2ban
    
    # Wait for service to start
    sleep 2
    
    if sudo systemctl is-active fail2ban >/dev/null 2>&1; then
        log_info "✅ fail2ban configured and active"
        sudo fail2ban-client status
    else
        log_warn "⚠ fail2ban service may need manual configuration"
    fi
}

# 4. Automatic Security Updates
setup_auto_updates() {
    if is_configured "auto_updates"; then
        log_info "✓ Automatic updates already configured"
        return 0
    fi
    
    log_action "Setting up automatic security updates..."
    
    # Install unattended-upgrades
    sudo apt update && sudo apt install -y unattended-upgrades apt-listchanges
    
    # Configure unattended-upgrades
    sudo tee /etc/apt/apt.conf.d/50unattended-upgrades > /dev/null << 'EOF'
// Automatically upgrade packages from these origins
Unattended-Upgrade::Origins-Pattern {
    "origin=Debian,codename=${distro_codename}-security,label=Debian-Security";
    "origin=Debian,codename=${distro_codename}-updates";
};

// Auto remove unused packages
Unattended-Upgrade::Remove-Unused-Dependencies "true";
Unattended-Upgrade::Remove-Unused-Kernel-Packages "true";

// Auto reboot if needed (at 2 AM)
Unattended-Upgrade::Automatic-Reboot "false";
Unattended-Upgrade::Automatic-Reboot-Time "02:00";

// Email notifications
Unattended-Upgrade::Mail "root";
Unattended-Upgrade::MailReport "on-change";
EOF
    
    # Enable automatic updates
    sudo tee /etc/apt/apt.conf.d/20auto-upgrades > /dev/null << 'EOF'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Download-Upgradeable-Packages "1";
APT::Periodic::AutocleanInterval "7";
APT::Periodic::Unattended-Upgrade "1";
EOF
    
    log_info "✅ Automatic security updates configured"
}

# 5. System Hardening
apply_system_hardening() {
    log_action "Applying additional system hardening..."
    
    # Kernel hardening via sysctl
    sudo tee /etc/sysctl.d/99-asw-hardening.conf > /dev/null << 'EOF'
# ASW Framework Kernel Hardening

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

# File system security
fs.protected_hardlinks = 1
fs.protected_symlinks = 1
kernel.core_uses_pid = 1

# Process security
kernel.randomize_va_space = 2
kernel.yama.ptrace_scope = 1
EOF
    
    # Apply sysctl settings
    sudo sysctl -p /etc/sysctl.d/99-asw-hardening.conf >/dev/null 2>&1
    
    # Set secure permissions on sensitive files
    sudo chmod 600 /etc/ssh/sshd_config
    sudo chmod 600 /etc/ssh/sshd_config.d/*
    [[ -d /home/cc-user/.ssh ]] && chmod 700 /home/cc-user/.ssh
    [[ -f /home/cc-user/.ssh/authorized_keys ]] && chmod 600 /home/cc-user/.ssh/authorized_keys
    
    log_info "✅ System hardening applied"
}

# 6. Install monitoring tools
setup_monitoring() {
    log_action "Setting up basic monitoring..."
    
    # Install monitoring packages
    sudo apt update && sudo apt install -y \
        htop \
        iotop \
        nethogs \
        ncdu \
        vnstat \
        sysstat
    
    # Enable sysstat
    sudo sed -i 's/ENABLED="false"/ENABLED="true"/' /etc/default/sysstat 2>/dev/null || true
    sudo systemctl enable sysstat
    sudo systemctl start sysstat
    
    log_info "✅ Monitoring tools installed"
}

# CC User Environment Setup
setup_cc_user_environment() {
    if is_configured "cc_user_env"; then
        log_info "✓ CC User environment already configured"
        return 0
    fi
    
    log_action "Setting up CC User environment..."
    
    # Run the dedicated setup script
    if [[ -f "/opt/asw/scripts/setup-cc-user-environment.sh" ]]; then
        /opt/asw/scripts/setup-cc-user-environment.sh
        
        # Mark as configured
        mark_configured "cc_user_env" "CC User environment with tmux and shell setup"
        
        log_info "✅ CC User environment setup complete"
    else
        log_warning "CC User environment setup script not found, skipping"
    fi
}

# Validation function
validate_hardening() {
    echo ""
    log_info "Validating security configuration..."
    echo ""
    
    local passed=0
    local failed=0
    
    # Check each component
    if is_configured "ssh_hardening"; then
        echo -e "  ${GREEN}✓${NC} SSH hardening: configured"
        ((passed++))
    else
        echo -e "  ${RED}✗${NC} SSH hardening: not found"
        ((failed++))
    fi
    
    if is_configured "ufw"; then
        echo -e "  ${GREEN}✓${NC} UFW firewall: active"
        ((passed++))
    else
        echo -e "  ${RED}✗${NC} UFW firewall: not active"
        ((failed++))
    fi
    
    if is_configured "fail2ban"; then
        echo -e "  ${GREEN}✓${NC} fail2ban: active"
        ((passed++))
    else
        echo -e "  ${RED}✗${NC} fail2ban: not active"
        ((failed++))
    fi
    
    if is_configured "auto_updates"; then
        echo -e "  ${GREEN}✓${NC} Automatic updates: configured"
        ((passed++))
    else
        echo -e "  ${YELLOW}⚠${NC} Automatic updates: not configured"
    fi
    
    if is_configured "cc_user_env"; then
        echo -e "  ${GREEN}✓${NC} CC User environment: configured"
        ((passed++))
    else
        echo -e "  ${YELLOW}⚠${NC} CC User environment: not configured"
    fi
    
    echo ""
    log_info "Security Validation Summary:"
    echo -e "  ${GREEN}Passed: $passed${NC}"
    if [[ $failed -gt 0 ]]; then
        echo -e "  ${RED}Failed: $failed${NC}"
    fi
    echo ""
}

# Main execution
main() {
    log_info "Starting comprehensive server hardening..."
    log_info "This may take a few minutes..."
    echo ""
    
    # Run all hardening steps
    apply_ssh_hardening
    setup_firewall
    setup_fail2ban
    setup_auto_updates
    apply_system_hardening
    setup_cc_user_environment
    setup_monitoring
    
    # Validate
    validate_hardening
    
    # Success message
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}     🎉 Server Hardening Complete!${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    log_info "Your server is now secured with:"
    echo "  • SSH hardening with key-only authentication"
    echo "  • UFW firewall with minimal ports"
    echo "  • fail2ban intrusion prevention"
    echo "  • Automatic security updates"
    echo "  • Kernel security hardening"
    echo "  • System monitoring tools"
    echo "  • CC User environment (tmux, shell, Claude Code)"
    echo ""
    log_info "Next step: Install ASW development framework"
    echo "  npm install -g @jtjiver/agentic-framework-infrastructure"
    echo "  npm install -g @jtjiver/agentic-framework-dev"
    echo ""
}

# Run main
main "$@"