#!/bin/bash
# check-hardening.sh
# Validates Phase 2: Security Hardening according to COMPLETE-AUTOMATION-ARCHITECTURE.md
# Can be run locally on target server or remotely via SSH

# Removed set -e to prevent hanging on conditional checks

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Counters
TOTAL_CHECKS=0
PASSED_CHECKS=0
FAILED_CHECKS=0

echo -e "${BLUE}🔒 ASW Framework - Phase 2 Security Hardening Validation${NC}"
echo -e "${BLUE}=========================================================${NC}"
echo ""

# Helper functions
check_pass() {
    echo -e "  ${GREEN}✓${NC} $1"
    ((PASSED_CHECKS++))
    ((TOTAL_CHECKS++))
}

check_fail() {
    echo -e "  ${RED}✗${NC} $1"
    ((FAILED_CHECKS++))
    ((TOTAL_CHECKS++))
}

check_warn() {
    echo -e "  ${YELLOW}⚠${NC} $1"
    ((TOTAL_CHECKS++))
}

run_check() {
    local description="$1"
    local command="$2"
    
    if eval "$command" &>/dev/null; then
        check_pass "$description"
    else
        check_fail "$description"
    fi
}

echo -e "${YELLOW}1. SSH HARDENING${NC}"
echo "================"

# Check SSH hardening config file
if [[ -f "/etc/ssh/sshd_config.d/99-hardening.conf" ]]; then
    check_pass "SSH hardening config file exists"
    
    # Check specific hardening settings
    config_file="/etc/ssh/sshd_config.d/99-hardening.conf"
    
    if grep -q "^PermitRootLogin no" "$config_file"; then
        check_pass "Root login is disabled"
    else
        check_fail "Root login not properly disabled"
    fi
    
    if grep -q "^PasswordAuthentication no" "$config_file"; then
        check_pass "Password authentication is disabled"
    else
        check_fail "Password authentication not properly disabled"
    fi
    
    if grep -q "^PubkeyAuthentication yes" "$config_file"; then
        check_pass "Public key authentication is enabled"
    else
        check_fail "Public key authentication not enabled"
    fi
    
    if grep -q "^AllowUsers cc-user" "$config_file"; then
        check_pass "SSH access restricted to cc-user"
    else
        check_warn "SSH user restriction not found (may be configured elsewhere)"
    fi
    
    if grep -q "^MaxAuthTries" "$config_file"; then
        max_tries=$(grep "^MaxAuthTries" "$config_file" | awk '{print $2}')
        check_pass "MaxAuthTries set to $max_tries"
    else
        check_warn "MaxAuthTries not configured"
    fi
    
    if grep -q "^Protocol 2" "$config_file"; then
        check_pass "SSH Protocol 2 enforced"
    else
        check_warn "SSH Protocol setting not found (default is usually 2)"
    fi
    
else
    check_fail "SSH hardening config file not found"
fi

# Check SSH service status
if systemctl is-active ssh &>/dev/null; then
    check_pass "SSH service is running"
else
    check_fail "SSH service is not running"
fi

# Check SSH port configuration
ssh_port=$(grep -E "^Port\s+|^#Port\s+" /etc/ssh/sshd_config /etc/ssh/sshd_config.d/* 2>/dev/null | grep -v "^#" | tail -1 | awk '{print $2}' || echo "22")
if [[ "$ssh_port" == "2222" ]]; then
    check_pass "SSH port configured to 2222"
elif [[ "$ssh_port" == "22" ]]; then
    check_warn "SSH port is default 22 (expected 2222)"
else
    check_pass "SSH port configured to custom port $ssh_port"
fi

echo ""
echo -e "${YELLOW}2. FIREWALL (UFW) CONFIGURATION${NC}"
echo "================================"

# Check if UFW is installed
if command -v ufw &>/dev/null || [[ -x "/usr/sbin/ufw" ]] || [[ -x "/sbin/ufw" ]]; then
    check_pass "UFW firewall is installed"
    
    # Determine UFW path
    UFW_CMD=""
    if command -v ufw &>/dev/null; then
        UFW_CMD="ufw"
    elif [[ -x "/usr/sbin/ufw" ]]; then
        UFW_CMD="sudo /usr/sbin/ufw"
    elif [[ -x "/sbin/ufw" ]]; then
        UFW_CMD="sudo /sbin/ufw"
    fi
    
    # Check UFW status
    if $UFW_CMD status | grep -q "Status: active"; then
        check_pass "UFW firewall is active"
        
        # Check default policies
        if $UFW_CMD status verbose | grep -q "Default: deny (incoming)"; then
            check_pass "Default incoming policy is deny"
        else
            check_fail "Default incoming policy is not deny"
        fi
        
        if $UFW_CMD status verbose | grep -q "Default: allow (outgoing)"; then
            check_pass "Default outgoing policy is allow"
        else
            check_warn "Default outgoing policy is not allow"
        fi
        
        # Check specific port rules
        ufw_rules=$($UFW_CMD status numbered 2>/dev/null)
        
        if echo "$ufw_rules" | grep -q "2222"; then
            check_pass "SSH port 2222 is allowed in UFW"
        elif echo "$ufw_rules" | grep -q " 22 "; then
            check_warn "SSH port 22 is allowed (expected 2222)"
        else
            check_fail "SSH port not found in UFW rules"
        fi
        
        if echo "$ufw_rules" | grep -q " 80 "; then
            check_pass "HTTP port 80 is allowed"
        else
            check_warn "HTTP port 80 not found in UFW rules"
        fi
        
        if echo "$ufw_rules" | grep -q " 443"; then
            check_pass "HTTPS port 443 is allowed"
        else
            check_warn "HTTPS port 443 not found in UFW rules"
        fi
        
    else
        check_fail "UFW firewall is not active"
    fi
    
else
    check_fail "UFW firewall is not installed"
fi

echo ""
echo -e "${YELLOW}3. FAIL2BAN INTRUSION PREVENTION${NC}"
echo "================================="

# Check if fail2ban is installed
if command -v fail2ban-server &>/dev/null; then
    check_pass "fail2ban is installed"
    
    # Check fail2ban service status
    if systemctl is-active fail2ban &>/dev/null; then
        check_pass "fail2ban service is running"
    else
        check_fail "fail2ban service is not running"
    fi
    
    if systemctl is-enabled fail2ban &>/dev/null; then
        check_pass "fail2ban service is enabled"
    else
        check_fail "fail2ban service is not enabled"
    fi
    
    # Check fail2ban configuration
    if [[ -f "/etc/fail2ban/jail.local" ]]; then
        check_pass "fail2ban local configuration exists"
        
        # Check SSH jail configuration
        if grep -A10 "\[sshd\]" /etc/fail2ban/jail.local | grep -q "enabled = true"; then
            check_pass "SSH jail is enabled"
        else
            check_warn "SSH jail configuration not found or not enabled"
        fi
        
        # Check for custom settings
        if grep -q "bantime" /etc/fail2ban/jail.local; then
            bantime=$(grep "bantime" /etc/fail2ban/jail.local | head -1 | awk '{print $3}')
            check_pass "Custom bantime configured: $bantime"
        else
            check_warn "Custom bantime not configured (using defaults)"
        fi
        
        if grep -q "findtime" /etc/fail2ban/jail.local; then
            findtime=$(grep "findtime" /etc/fail2ban/jail.local | head -1 | awk '{print $3}')
            check_pass "Custom findtime configured: $findtime"
        else
            check_warn "Custom findtime not configured (using defaults)"
        fi
        
        if grep -q "maxretry" /etc/fail2ban/jail.local; then
            maxretry=$(grep "maxretry" /etc/fail2ban/jail.local | head -1 | awk '{print $3}')
            check_pass "Custom maxretry configured: $maxretry"
        else
            check_warn "Custom maxretry not configured (using defaults)"
        fi
        
    else
        check_warn "fail2ban local configuration not found (using defaults)"
    fi
    
    # Check active jails
    if command -v fail2ban-client &>/dev/null && systemctl is-active fail2ban &>/dev/null; then
        active_jails=$(fail2ban-client status 2>/dev/null | grep "Jail list:" | cut -d: -f2 | xargs 2>/dev/null || echo "")
        if [[ -n "$active_jails" ]]; then
            check_pass "Active jails: $active_jails"
        else
            check_warn "Cannot check active jails (requires root access) or no jails active"
        fi
    fi
    
else
    check_fail "fail2ban is not installed"
fi

echo ""
echo -e "${YELLOW}4. SYSTEM HARDENING${NC}"
echo "==================="

# Check for automatic updates
if dpkg -l | grep -q unattended-upgrades; then
    check_pass "Unattended upgrades package is installed"
    
    if systemctl is-enabled unattended-upgrades &>/dev/null; then
        check_pass "Unattended upgrades service is enabled"
    else
        check_warn "Unattended upgrades service is not enabled"
    fi
else
    check_warn "Unattended upgrades not installed (manual updates required)"
fi

# Check kernel parameters (if any sysctl hardening was applied)
if [[ -f "/etc/sysctl.d/99-hardening.conf" ]] || [[ -f "/etc/sysctl.conf" ]]; then
    if grep -q "net.ipv4.ip_forward" /etc/sysctl.conf /etc/sysctl.d/* 2>/dev/null; then
        check_pass "Kernel IP forwarding configuration found"
    else
        check_warn "Kernel hardening parameters not found (may not be needed)"
    fi
else
    check_warn "No custom sysctl configuration found"
fi

# Check for security updates
echo -e "  ${BLUE}Checking for available security updates...${NC}"
if command -v apt &>/dev/null; then
    # Update package list silently
    apt update &>/dev/null || true
    
    security_updates=$(apt list --upgradable 2>/dev/null | grep "security" | wc -l 2>/dev/null || echo "0")
    # Clean the variable to ensure it's a single number
    security_updates=$(echo "$security_updates" | tr -d '\n' | awk '{print $1}')
    
    if [[ "$security_updates" =~ ^[0-9]+$ ]] && [[ "$security_updates" -eq 0 ]]; then
        check_pass "No pending security updates"
    elif [[ "$security_updates" =~ ^[0-9]+$ ]]; then
        check_warn "$security_updates security updates available"
        echo -e "    ${YELLOW}Run: sudo apt upgrade${NC}"
    else
        check_warn "Could not determine security update count"
    fi
fi

echo ""
echo -e "${YELLOW}5. MONITORING TOOLS${NC}"
echo "==================="

# Check monitoring tools installation
monitoring_tools=("htop" "iotop" "nethogs" "sysstat")

for tool in "${monitoring_tools[@]}"; do
    if command -v "$tool" &>/dev/null; then
        check_pass "$tool is installed"
    elif dpkg -l | grep -q "^ii.*$tool "; then
        check_pass "$tool package is installed"
    else
        check_warn "$tool is not installed"
    fi
done

# Check system statistics collection
if systemctl is-active sysstat &>/dev/null; then
    check_pass "System statistics collection (sysstat) is active"
else
    check_warn "System statistics collection is not active"
fi

echo ""
echo -e "${YELLOW}6. SECURITY STATUS OVERVIEW${NC}"
echo "============================"

echo -e "  ${BLUE}Current Security Status:${NC}"

# SSH connections
if command -v ss &>/dev/null; then
    ssh_connections=$(ss -tuln | grep ":$ssh_port " | wc -l)
    echo -e "    SSH listening on port: $ssh_port"
    echo -e "    Active SSH connections: $(ss -tu | grep ":$ssh_port" | wc -l)"
fi

# System load and resources
echo -e "    System load: $(uptime | awk -F'load average:' '{print $2}' | xargs)"
echo -e "    Memory usage: $(free | awk '/^Mem:/ {printf "%.1f%%", $3/$2*100}')"
echo -e "    Disk usage: $(df / | awk 'NR==2 {print $5}')"

# Last login attempts
if [[ -f "/var/log/auth.log" ]]; then
    failed_attempts=$(grep "Failed password" /var/log/auth.log | tail -10 | wc -l 2>/dev/null || echo "0")
    echo -e "    Recent failed login attempts: $failed_attempts (last 10 entries)"
fi

# fail2ban status
if command -v fail2ban-client &>/dev/null && systemctl is-active fail2ban &>/dev/null; then
    banned_count=$(fail2ban-client status sshd 2>/dev/null | grep "Currently banned:" | awk '{print $3}' 2>/dev/null | head -1 | tr -d '\n' || echo "0")
    if [[ "$banned_count" =~ ^[0-9]+$ ]]; then
        echo -e "    Currently banned IPs: $banned_count"
    else
        echo -e "    Currently banned IPs: Cannot check (requires root access)"
    fi
fi

echo ""
echo -e "${BLUE}=========================================================${NC}"
echo -e "${BLUE}SECURITY HARDENING VALIDATION SUMMARY${NC}"
echo -e "${BLUE}=========================================================${NC}"

if [[ $FAILED_CHECKS -eq 0 ]]; then
    echo -e "${GREEN}🎉 Security Hardening Phase PASSED${NC}"
    echo -e "   ${GREEN}✓${NC} $PASSED_CHECKS/$TOTAL_CHECKS checks passed"
    if [[ $PASSED_CHECKS -lt $TOTAL_CHECKS ]]; then
        warn_count=$((TOTAL_CHECKS - PASSED_CHECKS - FAILED_CHECKS))
        echo -e "   ${YELLOW}⚠${NC} $warn_count warnings (non-critical issues or recommendations)"
    fi
    echo ""
    echo -e "${GREEN}✅ Phase 2 (Security Hardening) is complete and secure${NC}"
    echo -e "${BLUE}➡️  Ready for Phase 3 (Development Environment)${NC}"
    exit 0
else
    echo -e "${RED}❌ Security Hardening Phase FAILED${NC}"
    echo -e "   ${RED}✗${NC} $FAILED_CHECKS/$TOTAL_CHECKS critical security issues found"
    echo -e "   ${GREEN}✓${NC} $PASSED_CHECKS checks passed"
    if [[ $PASSED_CHECKS -lt $TOTAL_CHECKS ]]; then
        warn_count=$((TOTAL_CHECKS - PASSED_CHECKS - FAILED_CHECKS))
        [[ $warn_count -gt 0 ]] && echo -e "   ${YELLOW}⚠${NC} $warn_count warnings"
    fi
    echo ""
    echo -e "${RED}🚨 Phase 2 (Security Hardening) has CRITICAL security issues${NC}"
    echo -e "${YELLOW}🔧 Re-run: ssh -A -p 2222 cc-user@SERVER_IP 'bash -s' < apply-full-hardening.sh${NC}"
    exit 1
fi