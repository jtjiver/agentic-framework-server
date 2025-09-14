#!/bin/bash
# Example test script for ASW Framework components
# This demonstrates testing patterns for integration tests

set -euo pipefail

# Load test configuration
if [[ -f "/home/cc-user/.test-config" ]]; then
    source /home/cc-user/.test-config
fi

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'  
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Helper functions
log_test() {
    echo -e "${BLUE}[TEST]${NC} $1"
    ((TESTS_RUN++))
}

log_pass() {
    echo -e "${GREEN}[PASS]${NC} $1"
    ((TESTS_PASSED++))
}

log_fail() {
    echo -e "${RED}[FAIL]${NC} $1"
    ((TESTS_FAILED++))
}

# Test individual functions
test_phase_check_syntax() {
    log_test "Testing phase check script syntax"
    
    local scripts=(
        "/opt/asw/scripts/check-phase-01-bootstrap.sh"
        "/opt/asw/scripts/check-phase-03-dev-environment.sh"
        "/opt/asw/scripts/check-all-phases.sh"
    )
    
    for script in "${scripts[@]}"; do
        if [[ -f "$script" ]]; then
            if bash -n "$script" &>/dev/null; then
                log_pass "Syntax valid: $(basename "$script")"
            else
                log_fail "Syntax error: $(basename "$script")"
            fi
        else
            log_fail "Script not found: $(basename "$script")"
        fi
    done
}

test_package_json_validity() {
    log_test "Testing package.json files validity"
    
    find /opt/asw -name "package.json" -not -path "*/.trash/*" | while read -r json_file; do
        local package_name
        package_name=$(dirname "$json_file" | xargs basename)
        
        if jq empty "$json_file" &>/dev/null; then
            log_pass "Valid package.json: $package_name"
        else
            log_fail "Invalid package.json: $package_name"
        fi
    done
}

test_required_commands() {
    log_test "Testing required command availability"
    
    local commands=("node" "npm" "git" "jq" "curl" "docker" "op" "gh" "claude")
    
    for cmd in "${commands[@]}"; do
        if command -v "$cmd" &>/dev/null; then
            log_pass "Command available: $cmd"
        else
            log_fail "Command missing: $cmd"
        fi
    done
}

test_directory_structure() {
    log_test "Testing ASW framework directory structure"
    
    local directories=(
        "/opt/asw"
        "/opt/asw/scripts"
        "/opt/asw/docs"
        "/opt/asw/agentic-framework-core"
        "/opt/asw/agentic-framework-dev"
        "/opt/asw/agentic-framework-infrastructure"
        "/opt/asw/agentic-framework-security"
    )
    
    for dir in "${directories[@]}"; do
        if [[ -d "$dir" ]]; then
            log_pass "Directory exists: $dir"
        else
            log_fail "Directory missing: $dir"
        fi
    done
}

test_user_configuration() {
    log_test "Testing cc-user configuration"
    
    # Test user exists
    if id cc-user &>/dev/null; then
        log_pass "cc-user account exists"
    else
        log_fail "cc-user account missing"
    fi
    
    # Test sudo privileges
    if groups cc-user | grep -q sudo; then
        log_pass "cc-user has sudo privileges"
    else
        log_fail "cc-user missing sudo privileges"
    fi
    
    # Test bash shell
    if grep "^cc-user:" /etc/passwd | grep -q "/bin/bash"; then
        log_pass "cc-user has bash shell"
    else
        log_fail "cc-user shell is not bash"
    fi
}

test_node_environment() {
    log_test "Testing Node.js environment"
    
    # Test Node.js version
    if node --version | grep -q "^v20\."; then
        log_pass "Node.js is version 20.x"
    else
        log_fail "Node.js is not version 20.x"
    fi
    
    # Test npm
    if npm --version &>/dev/null; then
        log_pass "npm is available"
    else
        log_fail "npm is not available"
    fi
}

test_python_environment() {
    log_test "Testing Python environment"
    
    # Test Python 3
    if python3 --version &>/dev/null; then
        log_pass "Python 3 is available"
    else
        log_fail "Python 3 is not available"
    fi
    
    # Test uv package manager
    if uv --version &>/dev/null; then
        log_pass "uv package manager is available"
    else
        log_fail "uv package manager is not available"
    fi
}

test_security_tools() {
    log_test "Testing security tools"
    
    # Test 1Password CLI
    if op --version &>/dev/null; then
        log_pass "1Password CLI is available"
    else
        log_fail "1Password CLI is not available"
    fi
    
    # Test GitHub CLI
    if gh --version &>/dev/null; then
        log_pass "GitHub CLI is available"
    else
        log_fail "GitHub CLI is not available"
    fi
}

test_docker_integration() {
    log_test "Testing Docker integration"
    
    # Test Docker CLI
    if docker --version &>/dev/null; then
        log_pass "Docker CLI is available"
    else
        log_fail "Docker CLI is not available"
    fi
    
    # Test Docker socket access (if running with Docker socket mounted)
    if [[ -S "/var/run/docker.sock" ]]; then
        log_pass "Docker socket is accessible"
    else
        log_fail "Docker socket is not accessible"
    fi
}

test_file_permissions() {
    log_test "Testing script file permissions"
    
    # Check that shell scripts are executable
    find /opt/asw -name "*.sh" -not -path "*/.trash/*" | while read -r script; do
        if [[ -x "$script" ]]; then
            log_pass "Executable: $(basename "$script")"
        else
            log_fail "Not executable: $(basename "$script")"
        fi
    done
}

# Mock tests (demonstrating how to test with mocks)
test_with_mocks() {
    log_test "Testing with mock services"
    
    # Set up mock 1Password CLI
    test_setup_temp_dir
    mkdir -p "$TEST_TEMP_DIR/bin"
    
    cat > "$TEST_TEMP_DIR/bin/op" << 'EOF'
#!/bin/bash
echo "Mock 1Password CLI response"
exit 0
EOF
    chmod +x "$TEST_TEMP_DIR/bin/op"
    
    # Test with mock
    export PATH="$TEST_TEMP_DIR/bin:$PATH"
    if op --version | grep -q "Mock"; then
        log_pass "Mock 1Password CLI working"
    else
        log_fail "Mock 1Password CLI not working"
    fi
    
    # Cleanup mock
    export PATH=$(echo "$PATH" | sed "s|$TEST_TEMP_DIR/bin:||")
    test_cleanup_temp_dir
}

# Main test execution
main() {
    echo "🧪 ASW Framework Integration Test Suite"
    echo "======================================="
    echo "Started: $(date)"
    echo ""
    
    # Run all tests
    test_phase_check_syntax
    test_package_json_validity  
    test_required_commands
    test_directory_structure
    test_user_configuration
    test_node_environment
    test_python_environment
    test_security_tools
    test_docker_integration
    test_file_permissions
    test_with_mocks
    
    # Final summary
    echo ""
    echo "======================================="
    echo "Test Summary"
    echo "======================================="
    echo "Tests Run: $TESTS_RUN"
    echo "Passed: $TESTS_PASSED"
    echo "Failed: $TESTS_FAILED"
    echo ""
    
    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo -e "${GREEN}✅ All tests passed!${NC}"
        exit 0
    else
        echo -e "${RED}❌ $TESTS_FAILED test(s) failed!${NC}"
        exit 1
    fi
}

# Run tests
main "$@"