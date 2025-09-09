#!/bin/bash
# Server Setup Verification Script
# Checks all components installed by the complete server setup

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Status symbols
CHECK="✓"
CROSS="✗"
INFO="ℹ"
WARN="⚠"

# Function to print section headers
print_header() {
    echo ""
    echo -e "${BOLD}${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}${CYAN}  $1${NC}"
    echo -e "${BOLD}${BLUE}═══════════════════════════════════════════════════════════${NC}"
}

# Function to check status and print result
check_status() {
    local description=$1
    local command=$2
    local expected=$3
    
    if eval "$command" >/dev/null 2>&1; then
        echo -e "${GREEN}${CHECK}${NC} ${description}"
        if [[ -n "$expected" ]]; then
            local result=$(eval "$command" 2>/dev/null)
            echo -e "  ${CYAN}└─${NC} ${result}"
        fi
        return 0
    else
        echo -e "${RED}${CROSS}${NC} ${description}"
        return 1
    fi
}

# Function to check value
check_value() {
    local description=$1
    local command=$2
    local result=$(eval "$command" 2>/dev/null)
    
    if [[ -n "$result" ]]; then
        echo -e "${GREEN}${CHECK}${NC} ${description}"
        echo -e "  ${CYAN}└─${NC} ${result}"
        return 0
    else
        echo -e "${RED}${CROSS}${NC} ${description} - Not found"
        return 1
    fi
}

# Function to check file/directory exists
check_exists() {
    local description=$1
    local path=$2
    
    if [[ -e "$path" ]]; then
        echo -e "${GREEN}${CHECK}${NC} ${description}"
        if [[ -f "$path" ]]; then
            echo -e "  ${CYAN}└─${NC} Size: $(ls -lh "$path" 2>/dev/null | awk '{print $5}')"
        elif [[ -d "$path" ]]; then
            echo -e "  ${CYAN}└─${NC} Contents: $(ls -1 "$path" 2>/dev/null | wc -l) items"
        fi
        return 0
    else
        echo -e "${RED}${CROSS}${NC} ${description} - Not found"
        return 1
    fi
}

# Start checks
echo ""
echo -e "${BOLD}${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${CYAN}║         VPS SERVER SETUP VERIFICATION REPORT              ║${NC}"
echo -e "${BOLD}${CYAN}║                $(date +'%Y-%m-%d %H:%M:%S')                    ║${NC}"
echo -e "${BOLD}${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"

# System Information
print_header "1. SYSTEM INFORMATION"
echo -e "${INFO} Hostname: ${YELLOW}$(hostname)${NC}"
echo -e "${INFO} Kernel: ${YELLOW}$(uname -r)${NC}"
echo -e "${INFO} OS: ${YELLOW}$(lsb_release -ds 2>/dev/null || cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)${NC}"
echo -e "${INFO} Architecture: ${YELLOW}$(uname -m)${NC}"
echo -e "${INFO} Uptime: ${YELLOW}$(uptime -p)${NC}"

# System Updates Status
print_header "2. SYSTEM UPDATES"
check_status "APT package lists updated" "ls -la /var/lib/apt/lists/*.* 2>/dev/null | head -1"
check_value "Upgradable packages" "apt list --upgradable 2>/dev/null | grep -c upgradable || echo '0 packages can be upgraded'"
check_value "Last update check" "stat -c %y /var/lib/apt/periodic/update-success-stamp 2>/dev/null || echo 'Never'"

# Essential Packages
print_header "3. ESSENTIAL PACKAGES"
packages=("sudo" "curl" "git" "wget" "htop" "vim" "nano" "build-essential" "ufw" "fail2ban")
for pkg in "${packages[@]}"; do
    if dpkg -l | grep -q "^ii.*$pkg"; then
        version=$(dpkg -l | grep "^ii.*$pkg" | awk '{print $3}' | head -1)
        echo -e "${GREEN}${CHECK}${NC} $pkg installed (${version})"
    else
        echo -e "${RED}${CROSS}${NC} $pkg not installed"
    fi
done

# User Account
print_header "4. USER ACCOUNT (cc-user)"
check_status "User 'cc-user' exists" "id cc-user"
check_value "User ID" "id -u cc-user"
check_value "Groups" "groups cc-user 2>/dev/null | sed 's/cc-user : //'"
check_status "Sudo privileges" "grep -q '^cc-user\|^%sudo' /etc/sudoers /etc/sudoers.d/* 2>/dev/null"
check_exists "Home directory" "/home/cc-user"
check_exists "SSH directory" "/home/cc-user/.ssh"

# SSH Configuration
print_header "5. SSH CONFIGURATION"
check_exists "SSH config directory" "/etc/ssh/sshd_config.d"
check_exists "Hardening config" "/etc/ssh/sshd_config.d/99-hardening.conf"

if [[ -f /etc/ssh/sshd_config.d/99-hardening.conf ]]; then
    echo -e "\n${BOLD}SSH Security Settings:${NC}"
    
    # Check each security setting
    settings=(
        "PermitRootLogin no:Root login disabled"
        "PasswordAuthentication no:Password auth disabled"
        "PubkeyAuthentication yes:Public key auth enabled"
        "AllowUsers cc-user:Only cc-user allowed"
        "MaxAuthTries:Max auth attempts"
        "Protocol 2:SSH Protocol 2 only"
    )
    
    for setting in "${settings[@]}"; do
        key="${setting%%:*}"
        desc="${setting#*:}"
        value=$(grep "^$key" /etc/ssh/sshd_config.d/99-hardening.conf 2>/dev/null | head -1)
        if [[ -n "$value" ]]; then
            echo -e "  ${GREEN}${CHECK}${NC} $desc"
            echo -e "    ${CYAN}└─${NC} $value"
        else
            echo -e "  ${YELLOW}${WARN}${NC} $desc - Not configured"
        fi
    done
fi

# SSH Keys
print_header "6. SSH KEY AUTHENTICATION"
if [[ -f /home/cc-user/.ssh/authorized_keys ]]; then
    key_count=$(wc -l < /home/cc-user/.ssh/authorized_keys)
    echo -e "${GREEN}${CHECK}${NC} Authorized keys file exists"
    echo -e "  ${CYAN}└─${NC} Number of keys: $key_count"
    
    # Show key fingerprints
    echo -e "\n${BOLD}SSH Key Fingerprints:${NC}"
    while IFS= read -r key; do
        if [[ -n "$key" ]] && [[ ! "$key" =~ ^# ]]; then
            fingerprint=$(echo "$key" | ssh-keygen -lf - 2>/dev/null | awk '{print $2}')
            key_type=$(echo "$key" | awk '{print $1}')
            key_comment=$(echo "$key" | awk '{print $3}')
            echo -e "  ${GREEN}${CHECK}${NC} Type: $key_type"
            echo -e "    ${CYAN}├─${NC} Fingerprint: $fingerprint"
            echo -e "    ${CYAN}└─${NC} Comment: ${key_comment:-'No comment'}"
        fi
    done < /home/cc-user/.ssh/authorized_keys
else
    echo -e "${RED}${CROSS}${NC} No authorized_keys file found"
fi

# Firewall Configuration
print_header "7. FIREWALL (UFW)"
if command -v ufw >/dev/null 2>&1; then
    ufw_status=$(sudo ufw status 2>/dev/null | head -1)
    if [[ "$ufw_status" == *"active"* ]]; then
        echo -e "${GREEN}${CHECK}${NC} UFW is active"
        echo -e "\n${BOLD}Allowed Ports:${NC}"
        sudo ufw status numbered 2>/dev/null | grep -E "^\[" | while read -r line; do
            echo -e "  ${GREEN}${CHECK}${NC} $line"
        done
    else
        echo -e "${RED}${CROSS}${NC} UFW is not active"
    fi
else
    echo -e "${RED}${CROSS}${NC} UFW not installed"
fi

# Fail2ban Status
print_header "8. INTRUSION PREVENTION (fail2ban)"
if systemctl is-active --quiet fail2ban; then
    echo -e "${GREEN}${CHECK}${NC} fail2ban is active"
    echo -e "  ${CYAN}└─${NC} Status: $(systemctl is-active fail2ban)"
    
    # Check for active jails
    if command -v fail2ban-client >/dev/null 2>&1; then
        jail_list=$(sudo fail2ban-client status 2>/dev/null | grep "Jail list" | cut -d':' -f2 | xargs)
        if [[ -n "$jail_list" ]]; then
            echo -e "\n${BOLD}Active Jails:${NC}"
            for jail in $jail_list; do
                echo -e "  ${GREEN}${CHECK}${NC} $jail"
            done
        fi
    fi
else
    echo -e "${RED}${CROSS}${NC} fail2ban is not running"
fi

# Development Tools
print_header "9. DEVELOPMENT TOOLS"

# Node.js
if command -v node >/dev/null 2>&1; then
    echo -e "${GREEN}${CHECK}${NC} Node.js installed"
    echo -e "  ${CYAN}└─${NC} Version: $(node --version)"
else
    echo -e "${RED}${CROSS}${NC} Node.js not installed"
fi

# npm
if command -v npm >/dev/null 2>&1; then
    echo -e "${GREEN}${CHECK}${NC} npm installed"
    echo -e "  ${CYAN}└─${NC} Version: $(npm --version)"
else
    echo -e "${RED}${CROSS}${NC} npm not installed"
fi

# 1Password CLI
if command -v op >/dev/null 2>&1; then
    echo -e "${GREEN}${CHECK}${NC} 1Password CLI installed"
    echo -e "  ${CYAN}└─${NC} Version: $(op --version)"
else
    echo -e "${RED}${CROSS}${NC} 1Password CLI not installed"
fi

# Git
if command -v git >/dev/null 2>&1; then
    echo -e "${GREEN}${CHECK}${NC} Git installed"
    echo -e "  ${CYAN}└─${NC} Version: $(git --version | cut -d' ' -f3)"
else
    echo -e "${RED}${CROSS}${NC} Git not installed"
fi

# ASW Framework Structure
print_header "10. ASW FRAMEWORK"
check_exists "Base directory" "/opt/asw"

if [[ -d /opt/asw ]]; then
    echo -e "\n${BOLD}Framework Components:${NC}"
    frameworks=("agentic-framework-core" "agentic-framework-dev" "agentic-framework-infrastructure" "agentic-framework-security")
    
    for framework in "${frameworks[@]}"; do
        if [[ -d "/opt/asw/$framework" ]]; then
            subdir_count=$(find "/opt/asw/$framework" -maxdepth 1 -type d | wc -l)
            echo -e "  ${GREEN}${CHECK}${NC} $framework"
            echo -e "    ${CYAN}└─${NC} Subdirectories: $((subdir_count - 1))"
        else
            echo -e "  ${RED}${CROSS}${NC} $framework - Not found"
        fi
    done
    
    # Check for scripts
    if [[ -d "/opt/asw/scripts" ]]; then
        script_count=$(ls -1 /opt/asw/scripts/*.sh 2>/dev/null | wc -l)
        echo -e "  ${GREEN}${CHECK}${NC} scripts directory"
        echo -e "    ${CYAN}└─${NC} Scripts: $script_count"
    fi
    
    # Check for docs
    if [[ -d "/opt/asw/docs" ]]; then
        doc_count=$(ls -1 /opt/asw/docs/*.md 2>/dev/null | wc -l)
        echo -e "  ${GREEN}${CHECK}${NC} docs directory"
        echo -e "    ${CYAN}└─${NC} Documents: $doc_count"
    fi
fi

# Network & Connectivity
print_header "11. NETWORK & CONNECTIVITY"
echo -e "${INFO} Primary IP: ${YELLOW}$(hostname -I | awk '{print $1}')${NC}"
echo -e "${INFO} SSH Port: ${YELLOW}$(grep -E "^Port" /etc/ssh/sshd_config /etc/ssh/sshd_config.d/* 2>/dev/null | awk '{print $2}' | head -1 || echo "22")${NC}"

# Check SSH service
if systemctl is-active --quiet ssh; then
    echo -e "${GREEN}${CHECK}${NC} SSH service is active"
else
    echo -e "${RED}${CROSS}${NC} SSH service is not active"
fi

# Summary
print_header "12. SUMMARY"

# Count successes and failures
total_checks=0
successful_checks=0

# Quick re-check of critical items
critical_items=(
    "id cc-user"
    "test -f /etc/ssh/sshd_config.d/99-hardening.conf"
    "systemctl is-active --quiet ssh"
    "sudo ufw status | grep -q active"
    "command -v node"
    "command -v op"
    "test -d /opt/asw"
)

for item in "${critical_items[@]}"; do
    total_checks=$((total_checks + 1))
    if eval "$item" >/dev/null 2>&1; then
        successful_checks=$((successful_checks + 1))
    fi
done

success_rate=$((successful_checks * 100 / total_checks))

echo -e "${BOLD}Setup Verification Results:${NC}"
echo -e "  ├─ Critical Checks Passed: ${GREEN}$successful_checks/$total_checks${NC}"
echo -e "  └─ Success Rate: ${GREEN}${success_rate}%${NC}"

if [[ $success_rate -eq 100 ]]; then
    echo ""
    echo -e "${BOLD}${GREEN}✅ Server setup verification PASSED!${NC}"
    echo -e "${GREEN}All critical components are properly configured.${NC}"
else
    echo ""
    echo -e "${BOLD}${YELLOW}⚠️  Server setup partially complete${NC}"
    echo -e "${YELLOW}Some components may need attention.${NC}"
fi

echo ""
echo -e "${BOLD}${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}Report generated at: $(date +'%Y-%m-%d %H:%M:%S')${NC}"
echo -e "${BOLD}${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""