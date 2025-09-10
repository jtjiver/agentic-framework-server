#!/bin/bash
# check-bootstrap.sh
# Validates Phase 1: Bootstrap setup according to COMPLETE-AUTOMATION-ARCHITECTURE.md
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

echo -e "${BLUE}🔍 ASW Framework - Phase 1 Bootstrap Validation${NC}"
echo -e "${BLUE}=================================================${NC}"
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
    local expected="$3"
    
    if eval "$command" &>/dev/null; then
        check_pass "$description"
    else
        check_fail "$description${expected:+ (Expected: $expected)}"
    fi
}

echo -e "${YELLOW}1. USER ACCOUNT CHECKS${NC}"
echo "========================"

# Check cc-user exists
if id cc-user &>/dev/null; then
    check_pass "cc-user account exists"
    
    # Check cc-user has sudo privileges
    if groups cc-user | grep -q sudo; then
        check_pass "cc-user has sudo privileges"
    else
        check_fail "cc-user missing sudo privileges"
    fi
    
    # Check cc-user has bash shell
    if grep "^cc-user:" /etc/passwd | grep -q "/bin/bash"; then
        check_pass "cc-user has bash shell"
    else
        check_fail "cc-user shell is not /bin/bash"
    fi
    
    # Check cc-user home directory
    if [[ -d "/home/cc-user" ]]; then
        check_pass "cc-user home directory exists"
    else
        check_fail "cc-user home directory missing"
    fi
else
    check_fail "cc-user account does not exist"
fi

echo ""
echo -e "${YELLOW}2. BASE PACKAGE INSTALLATIONS${NC}"
echo "================================"

# Essential packages that should be installed
packages=(
    "git"
    "curl" 
    "wget"
    "vim"
    "htop"
    "build-essential"
    "jq"
)

for package in "${packages[@]}"; do
    if dpkg -l | grep -q "^ii.*$package "; then
        check_pass "$package is installed"
    else
        check_fail "$package is NOT installed"
    fi
done

echo ""
echo -e "${YELLOW}3. NODE.JS AND NPM${NC}"
echo "=================="

# Check Node.js installation
if command -v node &>/dev/null; then
    node_version=$(node --version)
    check_pass "Node.js is installed ($node_version)"
    
    # Check if it's version 20.x
    if [[ $node_version =~ ^v20\. ]]; then
        check_pass "Node.js is version 20.x"
    else
        check_warn "Node.js version is $node_version (expected v20.x)"
    fi
else
    check_fail "Node.js is NOT installed"
fi

# Check npm
if command -v npm &>/dev/null; then
    npm_version=$(npm --version)
    check_pass "npm is installed ($npm_version)"
else
    check_fail "npm is NOT installed"
fi

echo ""
echo -e "${YELLOW}4. 1PASSWORD CLI${NC}"
echo "=================="

if command -v op &>/dev/null; then
    op_version=$(op --version)
    check_pass "1Password CLI is installed ($op_version)"
else
    check_fail "1Password CLI is NOT installed"
fi

echo ""
echo -e "${YELLOW}5. SSH CONFIGURATION${NC}"
echo "====================="

# Check SSH service
if systemctl is-active ssh &>/dev/null; then
    check_pass "SSH service is active"
else
    check_fail "SSH service is NOT active"
fi

# Check SSH key-only authentication setup
if [[ -f "/etc/ssh/sshd_config" ]]; then
    check_pass "SSH config file exists"
    
    # Check if we have any hardening config
    if [[ -f "/etc/ssh/sshd_config.d/99-hardening.conf" ]]; then
        check_pass "SSH hardening config exists (from Phase 2)"
    else
        check_warn "SSH hardening config not found (applied in Phase 2)"
    fi
else
    check_fail "SSH config file missing"
fi

# Check SSH keys for cc-user
if [[ -d "/home/cc-user/.ssh" ]]; then
    check_pass "cc-user .ssh directory exists"
    
    if [[ -f "/home/cc-user/.ssh/authorized_keys" ]]; then
        key_count=$(wc -l < "/home/cc-user/.ssh/authorized_keys" 2>/dev/null || echo "0")
        if [[ $key_count -gt 0 ]]; then
            check_pass "cc-user has SSH authorized keys ($key_count keys)"
        else
            check_warn "cc-user authorized_keys file exists but is empty"
        fi
    else
        check_warn "cc-user authorized_keys file not found"
    fi
else
    check_warn "cc-user .ssh directory not found"
fi

echo ""
echo -e "${YELLOW}6. ASW FRAMEWORK STRUCTURE${NC}"
echo "=========================="

# Check /opt/asw directory structure
if [[ -d "/opt/asw" ]]; then
    check_pass "/opt/asw directory exists"
    
    # Check ownership
    asw_owner=$(stat -c '%U:%G' /opt/asw 2>/dev/null || echo "unknown")
    if [[ "$asw_owner" == "cc-user:cc-user" ]]; then
        check_pass "/opt/asw owned by cc-user:cc-user"
    else
        check_fail "/opt/asw ownership is $asw_owner (expected cc-user:cc-user)"
    fi
    
    # Check for expected directories/files
    expected_items=(
        "scripts"
        "docs"
        "projects"
    )
    
    for item in "${expected_items[@]}"; do
        if [[ -e "/opt/asw/$item" ]]; then
            check_pass "/opt/asw/$item exists"
        else
            check_warn "/opt/asw/$item not found (may be created later)"
        fi
    done
    
    # Check for framework repos (installed in Phase 3)
    framework_repos=(
        "agentic-framework-core"
        "agentic-framework-dev"
        "agentic-framework-infrastructure"
        "agentic-framework-security"
    )
    
    echo ""
    echo -e "  ${BLUE}Framework repositories (installed in Phase 3):${NC}"
    for repo in "${framework_repos[@]}"; do
        if [[ -d "/opt/asw/$repo" ]]; then
            check_pass "$repo repository exists"
        else
            check_warn "$repo repository not found (installed in Phase 3)"
        fi
    done
    
else
    check_fail "/opt/asw directory does not exist"
fi

echo ""
echo -e "${YELLOW}7. SYSTEM INFORMATION${NC}"
echo "====================="

echo -e "  ${BLUE}OS Information:${NC}"
if [[ -f "/etc/os-release" ]]; then
    source /etc/os-release
    echo -e "    OS: $PRETTY_NAME"
    echo -e "    Version: ${VERSION_ID:-Unknown}"
fi

echo -e "  ${BLUE}System Resources:${NC}"
echo -e "    Memory: $(free -h | awk '/^Mem:/ {print $2}') total, $(free -h | awk '/^Mem:/ {print $7}') available"
echo -e "    Disk: $(df -h / | awk 'NR==2 {print $2}') total, $(df -h / | awk 'NR==2 {print $4}') available"
echo -e "    Load: $(uptime | awk -F'load average:' '{print $2}')"

echo -e "  ${BLUE}Network:${NC}"
echo -e "    Hostname: $(hostname)"
echo -e "    IP Address: $(hostname -I | awk '{print $1}')"

echo ""
echo -e "${BLUE}=================================================${NC}"
echo -e "${BLUE}BOOTSTRAP VALIDATION SUMMARY${NC}"
echo -e "${BLUE}=================================================${NC}"

if [[ $FAILED_CHECKS -eq 0 ]]; then
    echo -e "${GREEN}🎉 Bootstrap Phase PASSED${NC}"
    echo -e "   ${GREEN}✓${NC} $PASSED_CHECKS/$TOTAL_CHECKS checks passed"
    if [[ $PASSED_CHECKS -lt $TOTAL_CHECKS ]]; then
        warn_count=$((TOTAL_CHECKS - PASSED_CHECKS - FAILED_CHECKS))
        echo -e "   ${YELLOW}⚠${NC} $warn_count warnings (non-critical issues)"
    fi
    echo ""
    echo -e "${GREEN}✅ Phase 1 (Bootstrap) setup is complete and valid${NC}"
    echo -e "${BLUE}➡️  Ready for Phase 2 (Security Hardening)${NC}"
    exit 0
else
    echo -e "${RED}❌ Bootstrap Phase FAILED${NC}"
    echo -e "   ${RED}✗${NC} $FAILED_CHECKS/$TOTAL_CHECKS checks failed"
    echo -e "   ${GREEN}✓${NC} $PASSED_CHECKS checks passed"
    if [[ $PASSED_CHECKS -lt $TOTAL_CHECKS ]]; then
        warn_count=$((TOTAL_CHECKS - PASSED_CHECKS - FAILED_CHECKS))
        [[ $warn_count -gt 0 ]] && echo -e "   ${YELLOW}⚠${NC} $warn_count warnings"
    fi
    echo ""
    echo -e "${RED}❌ Phase 1 (Bootstrap) has critical issues that need to be resolved${NC}"
    echo -e "${YELLOW}🔧 Re-run: ./complete-server-setup.sh \"1Password-Server-Item\"${NC}"
    exit 1
fi