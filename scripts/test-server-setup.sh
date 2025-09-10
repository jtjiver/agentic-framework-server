#!/bin/bash
# ASW Framework - Complete Server Setup Test Script
# Validates that all components are working correctly

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

echo -e "${BLUE}🧪 ASW Framework - Complete Setup Validation${NC}"
echo -e "${BLUE}============================================${NC}"
echo ""

# Helper functions
test_pass() {
    echo -e "${GREEN}✅ $1${NC}"
    ((TESTS_PASSED++))
    ((TESTS_RUN++))
}

test_fail() {
    echo -e "${RED}❌ $1${NC}"
    ((TESTS_FAILED++))
    ((TESTS_RUN++))
}

test_warn() {
    echo -e "${YELLOW}⚠️  $1${NC}"
    ((TESTS_RUN++))
}

# 1. Environment Tests
echo -e "${YELLOW}1. ENVIRONMENT VALIDATION${NC}"
echo "========================="

# Check if we're on the server
if [[ -d "/opt/asw" ]]; then
    test_pass "ASW framework directory exists"
else
    test_fail "ASW framework directory missing - run on server"
    exit 1
fi

# Check user
if [[ "$(whoami)" == "cc-user" ]]; then
    test_pass "Running as cc-user"
else
    test_warn "Not running as cc-user (current: $(whoami))"
fi

# Check bashrc
if [[ -f ~/.bashrc ]] && grep -q "ASW Framework" ~/.bashrc; then
    test_pass "ASW bashrc configuration loaded"
else
    test_fail "ASW bashrc configuration missing"
fi

echo ""

# 2. Tool Availability Tests
echo -e "${YELLOW}2. DEVELOPMENT TOOLS${NC}"
echo "==================="

# Node.js
if command -v node >/dev/null 2>&1; then
    node_version=$(node --version)
    test_pass "Node.js available ($node_version)"
else
    test_fail "Node.js not available"
fi

# Python + uv
if command -v python3 >/dev/null 2>&1; then
    python_version=$(python3 --version)
    test_pass "Python 3 available ($python_version)"
else
    test_fail "Python 3 not available"
fi

if command -v uv >/dev/null 2>&1 || [[ -f "$HOME/.local/bin/uv" ]]; then
    if command -v uv >/dev/null 2>&1; then
        uv_version=$(uv --version)
    else
        uv_version=$("$HOME/.local/bin/uv" --version 2>/dev/null)
    fi
    test_pass "uv Python package manager available ($uv_version)"
else
    test_fail "uv not available - check PATH or installation"
fi

# Claude Code
if command -v claude >/dev/null 2>&1; then
    claude_version=$(claude --version 2>/dev/null || echo "installed")
    test_pass "Claude Code available ($claude_version)"
else
    test_fail "Claude Code not available"
fi

# 1Password CLI
if command -v op >/dev/null 2>&1; then
    op_version=$(op --version)
    test_pass "1Password CLI available ($op_version)"
else
    test_fail "1Password CLI not available"
fi

echo ""

# 3. Monitoring Tools Tests
echo -e "${YELLOW}3. MONITORING TOOLS${NC}"
echo "==================="

monitoring_tools=("htop" "iotop" "nethogs" "sar" "dstat" "tree" "lsof" "strace")
for tool in "${monitoring_tools[@]}"; do
    if command -v "$tool" >/dev/null 2>&1; then
        test_pass "$tool available"
    else
        test_fail "$tool not available"
    fi
done

echo ""

# 4. 1Password Integration Tests
echo -e "${YELLOW}4. 1PASSWORD INTEGRATION${NC}"
echo "========================="

# Check token file
if [[ -f ~/.config/1password/token ]]; then
    test_pass "1Password token file exists"
    
    # Check token format
    if grep -q "^ops_" ~/.config/1password/token 2>/dev/null; then
        test_pass "Token has correct format (starts with ops_)"
        
        # Test token validity
        export OP_SERVICE_ACCOUNT_TOKEN=$(cat ~/.config/1password/token)
        if op vault list >/dev/null 2>&1; then
            vault_count=$(op vault list --format json 2>/dev/null | jq length 2>/dev/null || echo "0")
            test_pass "1Password token is valid (access to $vault_count vaults)"
        else
            test_fail "1Password token is invalid or lacks vault access"
        fi
    else
        test_fail "Token format incorrect (should start with ops_)"
    fi
else
    test_fail "1Password token file missing (~/.config/1password/token)"
fi

echo ""

# 5. Framework Integration Tests
echo -e "${YELLOW}5. FRAMEWORK INTEGRATION${NC}"
echo "========================="

# Check banner functionality
if [[ -f "/opt/asw/agentic-framework-core/lib/utils/login-banner.sh" ]]; then
    test_pass "Login banner script exists"
    
    if source /opt/asw/agentic-framework-core/lib/utils/login-banner.sh 2>/dev/null && declare -f show_framework_banner >/dev/null; then
        test_pass "Banner script can be sourced successfully"
    else
        test_fail "Banner script has issues"
    fi
else
    test_fail "Login banner script missing"
fi

# Check aliases
if alias b >/dev/null 2>&1; then
    test_pass "Banner alias (b) available"
else
    test_fail "Banner alias (b) missing"
fi

if command -v validate-all >/dev/null 2>&1; then
    test_pass "Framework validation commands available"
else
    test_warn "Framework validation commands not in PATH"
fi

echo ""

# 6. Service Tests
echo -e "${YELLOW}6. SYSTEM SERVICES${NC}"
echo "=================="

# SSH service
if systemctl is-active ssh >/dev/null 2>&1; then
    test_pass "SSH service is active"
else
    test_fail "SSH service is not active"
fi

# UFW firewall
if command -v ufw >/dev/null 2>&1 && sudo ufw status | grep -q "Status: active"; then
    test_pass "UFW firewall is active"
else
    test_fail "UFW firewall is not active"
fi

# fail2ban
if systemctl is-active fail2ban >/dev/null 2>&1; then
    test_pass "fail2ban service is active"
else
    test_fail "fail2ban service is not active"
fi

# sysstat
if systemctl is-active sysstat >/dev/null 2>&1; then
    test_pass "sysstat service is active"
else
    test_fail "sysstat service is not active"
fi

echo ""

# 7. Quick Functional Tests
echo -e "${YELLOW}7. FUNCTIONAL TESTS${NC}"
echo "==================="

# Test Python + uv
if command -v uv >/dev/null 2>&1 || [[ -f "$HOME/.local/bin/uv" ]]; then
    UV_CMD="uv"
    if ! command -v uv >/dev/null 2>&1; then
        UV_CMD="$HOME/.local/bin/uv"
    fi
    
    if cd /tmp && $UV_CMD --version >/dev/null 2>&1; then
        test_pass "uv functional test passed"
    else
        test_fail "uv functional test failed"
    fi
else
    test_fail "uv not available for functional test"
fi

# Test monitoring command
if command -v free >/dev/null 2>&1 && free -h >/dev/null 2>&1; then
    test_pass "System monitoring commands functional"
else
    test_fail "System monitoring commands not functional"
fi

echo ""

# Summary
echo -e "${BLUE}============================================${NC}"
echo -e "${BLUE}TEST SUMMARY${NC}"
echo -e "${BLUE}============================================${NC}"

if [[ $TESTS_FAILED -eq 0 ]]; then
    echo -e "${GREEN}🎉 ALL TESTS PASSED${NC}"
    echo -e "   ${GREEN}✓${NC} $TESTS_PASSED/$TESTS_RUN tests passed"
    echo ""
    echo -e "${GREEN}✅ Server is fully operational and ready for development!${NC}"
    exit 0
else
    echo -e "${RED}❌ SOME TESTS FAILED${NC}"
    echo -e "   ${GREEN}✓${NC} $TESTS_PASSED/$TESTS_RUN tests passed"
    echo -e "   ${RED}✗${NC} $TESTS_FAILED tests failed"
    echo ""
    echo -e "${YELLOW}⚠️  Please review failed tests and fix issues before using server${NC}"
    exit 1
fi