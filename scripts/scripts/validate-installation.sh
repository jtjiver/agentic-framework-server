#!/bin/bash

# Validate agentic-framework-core installation
# This script checks that all components are properly installed and configured

set -e

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CORE_ROOT="$(dirname "$SCRIPT_DIR")"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Validation counters
VALIDATION_ERRORS=0
VALIDATION_WARNINGS=0

# Logging functions
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; ((VALIDATION_WARNINGS++)); }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; ((VALIDATION_ERRORS++)); }

# Function to validate directory structure
validate_structure() {
    log_info "Validating directory structure..."
    
    local required_dirs=(
        "lib/security/1password-helper"
        "lib/security/1password-monitoring"
        "lib/logging"
        "lib/utils"
        "lib/housekeeping"
        "scripts"
        "docs"
    )
    
    for dir in "${required_dirs[@]}"; do
        local path="$CORE_ROOT/$dir"
        if [[ -d "$path" ]]; then
            log_success "Directory exists: $dir"
        else
            log_error "Missing directory: $dir"
        fi
    done
    
    # Check required files
    local required_files=(
        "package.json"
        "index.js"
        "README.md"
        "lib/logging/bash-logger.sh"
    )
    
    for file in "${required_files[@]}"; do
        local path="$CORE_ROOT/$file"
        if [[ -f "$path" ]]; then
            log_success "File exists: $file"
        else
            log_error "Missing file: $file"
        fi
    done
}

# Function to validate 1Password helper
validate_1password_helper() {
    log_info "Validating 1Password helper..."
    
    local helper_dir="$CORE_ROOT/lib/security/1password-helper"
    local key_scripts=(
        "1password-inject.sh"
        "generate-template.sh"
        "set-vault.sh"
    )
    
    for script in "${key_scripts[@]}"; do
        local path="$helper_dir/$script"
        if [[ -f "$path" ]]; then
            if [[ -x "$path" ]]; then
                log_success "1Password script executable: $script"
            else
                log_warning "1Password script not executable: $script"
            fi
        else
            log_error "Missing 1Password script: $script"
        fi
    done
    
    # Check if 1Password CLI is available
    if command -v op >/dev/null 2>&1; then
        log_success "1Password CLI is available"
    else
        log_warning "1Password CLI not found (install with: brew install 1password-cli)"
    fi
}

# Function to validate logging framework
validate_logging() {
    log_info "Validating logging framework..."
    
    local logger_path="$CORE_ROOT/lib/logging/bash-logger.sh"
    
    if [[ -f "$logger_path" ]]; then
        log_success "Bash logger exists"
        
        # Test if logger can be sourced
        if bash -n "$logger_path" 2>/dev/null; then
            log_success "Bash logger syntax is valid"
        else
            log_error "Bash logger has syntax errors"
        fi
        
        # Check if logger is executable
        if [[ -x "$logger_path" ]]; then
            log_success "Bash logger is executable"
        else
            log_warning "Bash logger is not executable"
        fi
    else
        log_error "Bash logger not found"
    fi
    
    # Check logging framework directory
    local framework_dir="$CORE_ROOT/lib/logging/bash-logging-framework"
    if [[ -d "$framework_dir" ]]; then
        log_success "Bash logging framework directory exists"
    else
        log_warning "Bash logging framework directory not found"
    fi
}

# Function to validate package.json
validate_package_json() {
    log_info "Validating package.json..."
    
    local package_path="$CORE_ROOT/package.json"
    
    if [[ -f "$package_path" ]]; then
        # Check if it's valid JSON
        if command -v node >/dev/null && node -e "JSON.parse(require('fs').readFileSync('$package_path', 'utf8'))" 2>/dev/null; then
            log_success "package.json is valid JSON"
            
            # Check key fields
            local name
            name=$(node -e "console.log(JSON.parse(require('fs').readFileSync('$package_path', 'utf8')).name)" 2>/dev/null)
            if [[ "$name" == "@agentic-framework/core" ]]; then
                log_success "Package name is correct: $name"
            else
                log_error "Package name incorrect: $name"
            fi
            
        elif command -v jq >/dev/null && jq empty "$package_path" 2>/dev/null; then
            log_success "package.json is valid JSON (verified with jq)"
        else
            log_error "package.json is invalid JSON"
        fi
    else
        log_error "package.json not found"
    fi
}

# Function to validate Node.js entry point
validate_entry_point() {
    log_info "Validating Node.js entry point..."
    
    local entry_path="$CORE_ROOT/index.js"
    
    if [[ -f "$entry_path" ]]; then
        if command -v node >/dev/null; then
            # Test if the entry point can be loaded
            if node -e "import('./index.js').then(() => console.log('OK')).catch(e => process.exit(1))" 2>/dev/null; then
                log_success "Entry point loads successfully"
            else
                log_error "Entry point has import/syntax errors"
            fi
        else
            log_warning "Node.js not available - cannot test entry point"
        fi
    else
        log_error "Entry point (index.js) not found"
    fi
}

# Function to validate file permissions
validate_permissions() {
    log_info "Validating file permissions..."
    
    # Find all shell scripts and check they're executable
    local script_count=0
    local executable_count=0
    
    while IFS= read -r -d '' script; do
        ((script_count++))
        if [[ -x "$script" ]]; then
            ((executable_count++))
        else
            log_warning "Script not executable: ${script#$CORE_ROOT/}"
        fi
    done < <(find "$CORE_ROOT" -name "*.sh" -type f -print0)
    
    log_info "Shell scripts: $executable_count/$script_count executable"
    
    if [[ $executable_count -eq $script_count ]]; then
        log_success "All shell scripts are executable"
    fi
}

# Function to show validation summary
show_summary() {
    echo
    echo "=================================="
    echo "VALIDATION SUMMARY"
    echo "=================================="
    
    if [[ $VALIDATION_ERRORS -eq 0 && $VALIDATION_WARNINGS -eq 0 ]]; then
        log_success "✅ All validations passed!"
        log_info "agentic-framework-core is ready for use"
        return 0
    fi
    
    if [[ $VALIDATION_ERRORS -eq 0 ]]; then
        log_success "✅ No critical errors found"
    else
        log_error "❌ $VALIDATION_ERRORS critical error(s) found"
    fi
    
    if [[ $VALIDATION_WARNINGS -eq 0 ]]; then
        log_success "✅ No warnings"
    else
        log_warning "⚠️  $VALIDATION_WARNINGS warning(s) found"
    fi
    
    echo
    
    if [[ $VALIDATION_ERRORS -gt 0 ]]; then
        log_error "Installation has critical issues that must be fixed"
        log_info "Run: npm run setup-security"
        return 1
    else
        log_success "Installation is functional"
        if [[ $VALIDATION_WARNINGS -gt 0 ]]; then
            log_info "Consider running: npm run setup-security"
        fi
        return 0
    fi
}

# Main execution
main() {
    echo "Validating @agentic-framework/core installation"
    echo "Installation path: $CORE_ROOT"
    echo
    
    # Run all validations
    validate_structure
    validate_1password_helper
    validate_logging
    validate_package_json
    validate_entry_point
    validate_permissions
    
    # Show summary and exit with appropriate code
    show_summary
}

# Execute main function
main "$@"