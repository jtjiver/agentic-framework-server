#!/bin/bash
# ASW Framework Test Runner
# Comprehensive testing orchestrator for all ASW components

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

# Test configuration
TEST_ROOT="${ASW_TEST_ROOT:-/opt/asw}"
RESULTS_DIR="${TEST_RESULTS_DIR:-/opt/test-results}"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
LOG_FILE="$RESULTS_DIR/test-run-$TIMESTAMP.log"
REPORT_FILE="$RESULTS_DIR/test-report-$TIMESTAMP.md"

# Counters
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0
SKIPPED_TESTS=0

# Initialize
mkdir -p "$RESULTS_DIR"
echo "🧪 ASW Framework Test Runner" | tee "$LOG_FILE"
echo "================================" | tee -a "$LOG_FILE"
echo "Started: $(date)" | tee -a "$LOG_FILE"
echo "Test Root: $TEST_ROOT" | tee -a "$LOG_FILE"
echo "Results Dir: $RESULTS_DIR" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

# Helper functions
log() {
    echo -e "[$(date +'%H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $1" | tee -a "$LOG_FILE"
    ((PASSED_TESTS++))
    ((TOTAL_TESTS++))
}

log_failure() {
    echo -e "${RED}[✗]${NC} $1" | tee -a "$LOG_FILE"
    ((FAILED_TESTS++))
    ((TOTAL_TESTS++))
}

log_skip() {
    echo -e "${YELLOW}[⚠]${NC} $1" | tee -a "$LOG_FILE"
    ((SKIPPED_TESTS++))
    ((TOTAL_TESTS++))
}

# Test categories
run_syntax_tests() {
    log "${BLUE}${BOLD}Running Syntax Tests${NC}"
    echo "======================"
    
    # Test all shell scripts with shellcheck
    find "$TEST_ROOT" -name "*.sh" -type f | while read -r script; do
        if [[ "$script" == *".trash"* ]]; then
            continue
        fi
        
        log "Testing syntax: $(basename "$script")"
        if shellcheck "$script" > "$RESULTS_DIR/shellcheck-$(basename "$script")-$TIMESTAMP.txt" 2>&1; then
            log_success "Shellcheck passed: $(basename "$script")"
        else
            log_failure "Shellcheck failed: $(basename "$script")"
            echo "  → See $RESULTS_DIR/shellcheck-$(basename "$script")-$TIMESTAMP.txt"
        fi
    done
    
    # Test JSON files
    find "$TEST_ROOT" -name "*.json" -type f | while read -r json_file; do
        if [[ "$json_file" == *".trash"* ]]; then
            continue
        fi
        
        log "Testing JSON syntax: $(basename "$json_file")"
        if jq empty "$json_file" > /dev/null 2>&1; then
            log_success "JSON syntax valid: $(basename "$json_file")"
        else
            log_failure "JSON syntax invalid: $(basename "$json_file")"
        fi
    done
    
    echo ""
}

run_unit_tests() {
    log "${BLUE}${BOLD}Running Unit Tests${NC}"
    echo "=================="
    
    # Run BATS tests
    if find "$TEST_ROOT" -name "*.bats" -type f | head -1 | grep -q .; then
        find "$TEST_ROOT" -name "*.bats" -type f | while read -r bats_file; do
            if [[ "$bats_file" == *".trash"* ]]; then
                continue
            fi
            
            test_name=$(basename "$bats_file" .bats)
            log "Running BATS test: $test_name"
            if bats "$bats_file" > "$RESULTS_DIR/bats-$test_name-$TIMESTAMP.txt" 2>&1; then
                log_success "BATS test passed: $test_name"
            else
                log_failure "BATS test failed: $test_name"
                echo "  → See $RESULTS_DIR/bats-$test_name-$TIMESTAMP.txt"
            fi
        done
    else
        log_skip "No BATS test files found"
    fi
    
    # Run existing test scripts
    if [[ -d "$TEST_ROOT/scripts/tests" ]]; then
        find "$TEST_ROOT/scripts/tests" -name "test-*.sh" -type f | while read -r test_script; do
            test_name=$(basename "$test_script" .sh)
            log "Running test script: $test_name"
            if bash "$test_script" > "$RESULTS_DIR/$test_name-$TIMESTAMP.txt" 2>&1; then
                log_success "Test script passed: $test_name"
            else
                log_failure "Test script failed: $test_name"
                echo "  → See $RESULTS_DIR/$test_name-$TIMESTAMP.txt"
            fi
        done
    fi
    
    echo ""
}

run_integration_tests() {
    log "${BLUE}${BOLD}Running Integration Tests${NC}"
    echo "========================="
    
    # Test script dependencies
    scripts_to_test=(
        "scripts/check-phase-01-bootstrap.sh"
        "scripts/check-phase-03-dev-environment.sh"
        "scripts/check-all-phases.sh"
    )
    
    for script in "${scripts_to_test[@]}"; do
        if [[ -f "$TEST_ROOT/$script" ]]; then
            script_name=$(basename "$script" .sh)
            log "Testing script execution: $script_name"
            
            # Run in test mode with timeout
            if timeout 300 bash "$TEST_ROOT/$script" > "$RESULTS_DIR/integration-$script_name-$TIMESTAMP.txt" 2>&1; then
                log_success "Integration test passed: $script_name"
            else
                log_failure "Integration test failed: $script_name"
                echo "  → See $RESULTS_DIR/integration-$script_name-$TIMESTAMP.txt"
            fi
        else
            log_skip "Script not found: $script"
        fi
    done
    
    echo ""
}

run_package_tests() {
    log "${BLUE}${BOLD}Running Package Tests${NC}"
    echo "====================="
    
    # Test each submodule's package.json
    for package_dir in "$TEST_ROOT"/agentic-framework-*; do
        if [[ -d "$package_dir" && -f "$package_dir/package.json" ]]; then
            package_name=$(basename "$package_dir")
            log "Testing package: $package_name"
            
            cd "$package_dir"
            
            # Test package.json validity
            if jq empty package.json > /dev/null 2>&1; then
                log_success "Package.json valid: $package_name"
            else
                log_failure "Package.json invalid: $package_name"
                continue
            fi
            
            # Test npm install (if not already installed)
            if [[ ! -d "node_modules" ]]; then
                log "Installing dependencies: $package_name"
                if npm install > "$RESULTS_DIR/npm-install-$package_name-$TIMESTAMP.txt" 2>&1; then
                    log_success "Dependencies installed: $package_name"
                else
                    log_failure "Dependency installation failed: $package_name"
                    continue
                fi
            fi
            
            # Run package tests if they exist
            if jq -e '.scripts.test' package.json > /dev/null 2>&1; then
                log "Running package tests: $package_name"
                if npm test > "$RESULTS_DIR/npm-test-$package_name-$TIMESTAMP.txt" 2>&1; then
                    log_success "Package tests passed: $package_name"
                else
                    log_failure "Package tests failed: $package_name"
                fi
            else
                log_skip "No test script defined: $package_name"
            fi
            
            cd "$TEST_ROOT"
        fi
    done
    
    echo ""
}

run_security_tests() {
    log "${BLUE}${BOLD}Running Security Tests${NC}"
    echo "======================"
    
    # Test for common security issues
    log "Scanning for hardcoded secrets..."
    
    # Look for potential secrets (excluding test files)
    if grep -r -i -E "(password|secret|token|key).*=" "$TEST_ROOT" \
        --exclude-dir=".git" \
        --exclude-dir=".trash" \
        --exclude-dir="node_modules" \
        --exclude-dir="test-results" \
        --exclude="*.md" \
        --exclude="test-*" \
        > "$RESULTS_DIR/security-scan-$TIMESTAMP.txt" 2>&1; then
        
        # Filter out obvious false positives
        if grep -v -E "(TEST_|EXAMPLE_|_PASSWORD=\$|password.*\$|#.*password)" "$RESULTS_DIR/security-scan-$TIMESTAMP.txt" | head -1 | grep -q .; then
            log_failure "Potential secrets found - review security scan"
            echo "  → See $RESULTS_DIR/security-scan-$TIMESTAMP.txt"
        else
            log_success "No hardcoded secrets detected"
        fi
    else
        log_success "No hardcoded secrets detected"
    fi
    
    # Test script permissions
    log "Checking script permissions..."
    find "$TEST_ROOT" -name "*.sh" -type f | while read -r script; do
        if [[ "$script" == *".trash"* ]]; then
            continue
        fi
        
        perms=$(stat -c "%a" "$script")
        if [[ "$perms" =~ ^[67][0-7][0-7]$ ]]; then
            log_success "Safe permissions: $(basename "$script") ($perms)"
        else
            log_failure "Unsafe permissions: $(basename "$script") ($perms)"
        fi
    done
    
    echo ""
}

# Generate test report
generate_report() {
    log "${BLUE}${BOLD}Generating Test Report${NC}"
    echo "======================"
    
    cat > "$REPORT_FILE" << EOF
# ASW Framework Test Report

**Generated**: $(date)  
**Test Run ID**: $TIMESTAMP  
**Environment**: Docker Test Container  

## Test Summary

| Metric | Count |
|--------|-------|
| Total Tests | $TOTAL_TESTS |
| Passed | $PASSED_TESTS |
| Failed | $FAILED_TESTS |
| Skipped | $SKIPPED_TESTS |

**Success Rate**: $(( TOTAL_TESTS > 0 ? (PASSED_TESTS * 100) / TOTAL_TESTS : 0 ))%

## Test Categories

- ✅ Syntax Tests (Shellcheck, JSON validation)
- ✅ Unit Tests (BATS, individual test scripts)  
- ✅ Integration Tests (Script execution, dependencies)
- ✅ Package Tests (npm install, npm test)
- ✅ Security Tests (Secret scanning, permissions)

## Detailed Results

See individual test output files in: \`$RESULTS_DIR\`

### Log Files Generated
$(ls -la "$RESULTS_DIR"/*-$TIMESTAMP.* 2>/dev/null | awk '{print "- " $9}' || echo "- No detailed logs generated")

## Recommendations

$(if [[ $FAILED_TESTS -gt 0 ]]; then
    echo "⚠️ **Action Required**: $FAILED_TESTS test(s) failed. Review the detailed logs above."
else
    echo "✅ **All tests passed!** The ASW Framework is ready for deployment."
fi)

## Next Steps

1. Review any failed tests and fix issues
2. Run tests again after fixes: \`docker-compose -f docker-compose.test.yml exec asw-test test-runner\`
3. For CI/CD integration: \`./docker/test/scripts/ci-test.sh\`

---
*Generated by ASW Framework Test Runner*
EOF

    log "Test report generated: $REPORT_FILE"
}

# Main execution
main() {
    case "${1:-all}" in
        syntax)
            run_syntax_tests
            ;;
        unit)
            run_unit_tests
            ;;
        integration)
            run_integration_tests
            ;;
        packages)
            run_package_tests
            ;;
        security)
            run_security_tests
            ;;
        all|*)
            run_syntax_tests
            run_unit_tests
            run_integration_tests  
            run_package_tests
            run_security_tests
            ;;
    esac
    
    generate_report
    
    # Final summary
    echo ""
    log "${BOLD}Test Run Complete${NC}"
    echo "=================="
    echo -e "Total Tests: ${BOLD}$TOTAL_TESTS${NC}"
    echo -e "Passed: ${GREEN}$PASSED_TESTS${NC}"
    echo -e "Failed: ${RED}$FAILED_TESTS${NC}"
    echo -e "Skipped: ${YELLOW}$SKIPPED_TESTS${NC}"
    echo ""
    echo "📋 Full report: $REPORT_FILE"
    echo "📝 Log file: $LOG_FILE"
    
    # Exit with error if any tests failed
    exit $FAILED_TESTS
}

# Show usage if requested
if [[ "${1:-}" == "--help" ]] || [[ "${1:-}" == "-h" ]]; then
    echo "Usage: $0 [test-type]"
    echo ""
    echo "Test types:"
    echo "  all         Run all tests (default)"
    echo "  syntax      Run syntax/linting tests only"
    echo "  unit        Run unit tests only"
    echo "  integration Run integration tests only" 
    echo "  packages    Run package tests only"
    echo "  security    Run security tests only"
    echo ""
    echo "Examples:"
    echo "  $0              # Run all tests"
    echo "  $0 syntax       # Run only syntax tests"
    echo "  $0 security     # Run only security tests"
    exit 0
fi

main "$@"