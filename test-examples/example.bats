#!/usr/bin/env bats
# Example BATS tests for ASW Framework
# This demonstrates testing patterns for shell scripts

# Load BATS helpers
load '/opt/bats-support/load'
load '/opt/bats-assert/load'
load '/opt/bats-file/load'

# Test setup - runs before each test
setup() {
    # Create temporary directory for each test
    export TEST_TEMP_DIR="$(mktemp -d)"
    export PATH="/opt/asw/scripts:$PATH"
}

# Test cleanup - runs after each test  
teardown() {
    # Clean up temporary files
    rm -rf "$TEST_TEMP_DIR"
}

@test "check-phase-01-bootstrap.sh syntax is valid" {
    run bash -n /opt/asw/scripts/check-phase-01-bootstrap.sh
    assert_success
}

@test "check-phase-01-bootstrap.sh has executable permissions" {
    assert_file_executable /opt/asw/scripts/check-phase-01-bootstrap.sh
}

@test "complete-server-setup.sh requires arguments" {
    run /opt/asw/scripts/complete-server-setup.sh
    assert_failure
    assert_output --partial "Usage:"
}

@test "JSON files are valid" {
    # Test all package.json files
    find /opt/asw -name "package.json" -not -path "*/.trash/*" | while read -r json_file; do
        run jq empty "$json_file"
        assert_success
    done
}

@test "all shell scripts pass shellcheck" {
    # Find all shell scripts (excluding .trash directory)
    find /opt/asw -name "*.sh" -not -path "*/.trash/*" | while read -r script; do
        run shellcheck "$script"
        assert_success
    done
}

@test "test environment has required tools" {
    # Test that all required tools are available
    local tools=("node" "npm" "jq" "curl" "git" "docker" "op" "gh" "claude")
    
    for tool in "${tools[@]}"; do
        run command -v "$tool"
        assert_success
    done
}

@test "cc-user exists and has sudo privileges" {
    run id cc-user
    assert_success
    
    run groups cc-user
    assert_output --partial "sudo"
}

@test "ASW framework directories exist" {
    assert_dir_exists /opt/asw
    assert_dir_exists /opt/asw/scripts
    assert_dir_exists /opt/asw/docs
}

@test "Node.js is version 20.x" {
    run node --version
    assert_success
    assert_output --regexp "^v20\."
}

@test "Python 3 is available" {
    run python3 --version
    assert_success
    assert_output --partial "Python 3"
}

@test "uv (Python package manager) is installed" {
    run uv --version
    assert_success
}

@test "GitHub CLI is installed and working" {
    run gh --version
    assert_success
}

@test "1Password CLI is installed" {
    run op --version
    assert_success
}

@test "Claude Code CLI is installed" {
    run claude --version
    assert_success
}

@test "temporary file operations work" {
    # Test creating and manipulating files in temp directory
    local test_file="$TEST_TEMP_DIR/test-file.txt"
    
    run touch "$test_file"
    assert_success
    assert_file_exists "$test_file"
    
    run echo "test content" > "$test_file"
    assert_success
    
    run cat "$test_file"
    assert_success
    assert_output "test content"
}