#!/bin/bash

# Setup security tools for agentic-framework-core
# This script ensures 1Password CLI is available and security tools are configured

set -e

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CORE_ROOT="$(dirname "$SCRIPT_DIR")"

# Source the bash logger
source "$CORE_ROOT/lib/logging/bash-logger.sh"

log_start "Security Setup"

# Function to check if 1Password CLI is installed
check_1password_cli() {
    log_info "Checking 1Password CLI availability..."
    
    if command -v op >/dev/null 2>&1; then
        local version
        version=$(op --version 2>/dev/null || echo "unknown")
        log_success "1Password CLI found (version: $version)"
        return 0
    else
        log_warning "1Password CLI not found"
        return 1
    fi
}

# Function to show 1Password installation instructions
show_1password_install_instructions() {
    log_info "To install 1Password CLI:"
    echo ""
    echo "macOS (Homebrew):"
    echo "  brew install 1password-cli"
    echo ""
    echo "Linux (Ubuntu/Debian):"
    echo "  curl -sS https://downloads.1password.com/linux/keys/1password.asc | sudo gpg --dearmor --output /usr/share/keyrings/1password-archive-keyring.gpg"
    echo "  echo 'deb [arch=amd64 signed-by=/usr/share/keyrings/1password-archive-keyring.gpg] https://downloads.1password.com/linux/debian/amd64 stable main' | sudo tee /etc/apt/sources.list.d/1password.list"
    echo "  sudo apt update && sudo apt install 1password-cli"
    echo ""
    echo "After installation, authenticate with:"
    echo "  op signin"
}

# Function to validate security tools
validate_security_tools() {
    log_info "Validating security tools..."
    
    # Check if 1Password helper exists
    local helper_path="$CORE_ROOT/lib/security/1password-helper"
    if [[ -d "$helper_path" ]]; then
        log_success "1Password helper found at: $helper_path"
    else
        log_error "1Password helper not found at: $helper_path"
        return 1
    fi
    
    # Check if key scripts are executable
    local key_scripts=(
        "$helper_path/1password-inject.sh"
        "$helper_path/generate-template.sh"
        "$helper_path/set-vault.sh"
    )
    
    for script in "${key_scripts[@]}"; do
        if [[ -f "$script" ]]; then
            if [[ -x "$script" ]]; then
                log_success "Script is executable: $(basename "$script")"
            else
                log_warning "Making script executable: $(basename "$script")"
                chmod +x "$script"
            fi
        else
            log_error "Script not found: $script"
            return 1
        fi
    done
    
    return 0
}

# Function to set up logging
setup_logging() {
    log_info "Setting up logging framework..."
    
    local logger_path="$CORE_ROOT/lib/logging/bash-logger.sh"
    if [[ -f "$logger_path" ]]; then
        if [[ -x "$logger_path" ]]; then
            log_success "Bash logger is ready at: $logger_path"
        else
            log_info "Making bash logger executable"
            chmod +x "$logger_path"
            log_success "Bash logger setup complete"
        fi
    else
        log_error "Bash logger not found at: $logger_path"
        return 1
    fi
    
    return 0
}

# Function to create convenience aliases
create_aliases() {
    log_info "Setting up convenience aliases..."
    
    local alias_file="$HOME/.af-core-aliases"
    
    cat > "$alias_file" << EOF
# Agentic Framework Core Aliases
# Source this file in your shell profile: source ~/.af-core-aliases

# Core paths
export AF_CORE_ROOT="$CORE_ROOT"
export AF_SECURITY_PATH="$CORE_ROOT/lib/security"
export AF_LOGGING_PATH="$CORE_ROOT/lib/logging"

# 1Password helper aliases
alias af-1p-inject="$CORE_ROOT/lib/security/1password-helper/1password-inject.sh"
alias af-1p-template="$CORE_ROOT/lib/security/1password-helper/generate-template.sh"
alias af-1p-vault="$CORE_ROOT/lib/security/1password-helper/set-vault.sh"

# Logging alias
alias af-logger="source $CORE_ROOT/lib/logging/bash-logger.sh"

# Core utilities
alias af-core-info="node $CORE_ROOT/index.js info"
alias af-core-path="node $CORE_ROOT/index.js path"
EOF
    
    log_success "Aliases created at: $alias_file"
    log_info "Add to your shell profile with: echo 'source $alias_file' >> ~/.bashrc"
}

# Main execution
main() {
    log_info "Setting up agentic-framework-core security tools"
    log_info "Core installation path: $CORE_ROOT"
    
    # Check 1Password CLI
    if ! check_1password_cli; then
        log_warning "1Password CLI not available - some features will be limited"
        show_1password_install_instructions
    fi
    
    # Validate security tools
    if ! validate_security_tools; then
        log_error "Security tools validation failed"
        exit 1
    fi
    
    # Setup logging
    if ! setup_logging; then
        log_error "Logging setup failed"
        exit 1
    fi
    
    # Create aliases
    create_aliases
    
    log_success "Security setup completed successfully!"
    echo
    log_info "Next steps:"
    echo "1. Source the aliases: source ~/.af-core-aliases"
    echo "2. Test 1Password helper: af-1p-vault --help"
    echo "3. Test logging: af-logger && log_info 'Test message'"
    echo "4. View package info: af-core-info"
}

log_complete

# Execute main function
main "$@"