#!/bin/bash

# ASW Version Checker Installation Script
# This script installs the asw-check-version command system-wide

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Detect script location and ASW root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ASW_ROOT="$(dirname "$SCRIPT_DIR")"
VERSION_CHECKER_SCRIPT="$ASW_ROOT/scripts/asw-check-version"

# Installation options
INSTALL_DIR="/usr/local/bin"
LINK_NAME="asw-check-version"
FULL_INSTALL_PATH="$INSTALL_DIR/$LINK_NAME"

usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Install the ASW Version Checker as a system-wide command.

OPTIONS:
    -h, --help          Show this help message
    -u, --uninstall     Uninstall the command
    -d, --dir DIR       Install directory (default: $INSTALL_DIR)
    -n, --name NAME     Command name (default: $LINK_NAME)
    --local             Install to ~/.local/bin (no sudo required)
    --check             Check installation status
    
EXAMPLES:
    $0                          # Install system-wide (requires sudo)
    $0 --local                  # Install to user's local bin
    $0 --uninstall              # Remove installation
    $0 --check                  # Check if installed and working
    $0 -d /opt/bin -n asw-ver   # Custom location and name

EOF
}

check_dependencies() {
    log_info "Checking dependencies..."
    
    # Check for uv
    if ! command -v uv &> /dev/null; then
        log_error "uv is not installed. Install with: curl -LsSf https://astral.sh/uv/install.sh | sh"
        return 1
    fi
    
    # Check for git
    if ! command -v git &> /dev/null; then
        log_error "git is not installed"
        return 1
    fi
    
    # Check that the version checker script exists
    if [[ ! -f "$VERSION_CHECKER_SCRIPT" ]]; then
        log_error "Version checker script not found at: $VERSION_CHECKER_SCRIPT"
        return 1
    fi
    
    # Check that the script is executable
    if [[ ! -x "$VERSION_CHECKER_SCRIPT" ]]; then
        log_warning "Making version checker script executable..."
        chmod +x "$VERSION_CHECKER_SCRIPT"
    fi
    
    log_success "All dependencies satisfied"
    return 0
}

check_installation() {
    log_info "Checking installation status..."
    
    if [[ -L "$FULL_INSTALL_PATH" ]]; then
        local target=$(readlink "$FULL_INSTALL_PATH")
        log_info "Symlink exists: $FULL_INSTALL_PATH -> $target"
        
        if [[ "$target" == "$VERSION_CHECKER_SCRIPT" ]]; then
            log_success "Installation is correct"
            
            # Test if it works
            log_info "Testing command execution..."
            if "$FULL_INSTALL_PATH" --help >/dev/null 2>&1; then
                log_success "Command executes successfully"
                return 0
            else
                log_error "Command exists but fails to execute"
                return 1
            fi
        else
            log_warning "Symlink points to wrong location: $target"
            return 1
        fi
    elif [[ -f "$FULL_INSTALL_PATH" ]]; then
        log_warning "File exists but is not a symlink: $FULL_INSTALL_PATH"
        return 1
    else
        log_info "Command not installed"
        return 1
    fi
}

install_command() {
    local install_dir="$1"
    local command_name="$2"
    local full_path="$install_dir/$command_name"
    
    log_info "Installing ASW Version Checker..."
    log_info "Source: $VERSION_CHECKER_SCRIPT"
    log_info "Target: $full_path"
    
    # Check if target directory exists
    if [[ ! -d "$install_dir" ]]; then
        log_info "Creating install directory: $install_dir"
        if [[ "$install_dir" == "/usr/local/bin" ]] || [[ "$install_dir" =~ ^/usr/ ]]; then
            sudo mkdir -p "$install_dir"
        else
            mkdir -p "$install_dir"
        fi
    fi
    
    # Remove existing installation if it exists
    if [[ -e "$full_path" ]]; then
        log_info "Removing existing installation..."
        if [[ "$install_dir" == "/usr/local/bin" ]] || [[ "$install_dir" =~ ^/usr/ ]]; then
            sudo rm -f "$full_path"
        else
            rm -f "$full_path"
        fi
    fi
    
    # Create symlink
    log_info "Creating symlink..."
    if [[ "$install_dir" == "/usr/local/bin" ]] || [[ "$install_dir" =~ ^/usr/ ]]; then
        sudo ln -sf "$VERSION_CHECKER_SCRIPT" "$full_path"
    else
        ln -sf "$VERSION_CHECKER_SCRIPT" "$full_path"
    fi
    
    # Verify installation
    if [[ -L "$full_path" ]]; then
        log_success "Installation complete: $command_name"
        log_info "You can now run: $command_name --help"
        
        # Test execution
        if "$full_path" --help >/dev/null 2>&1; then
            log_success "Command is working correctly"
        else
            log_warning "Command installed but may not execute properly"
        fi
    else
        log_error "Installation failed"
        return 1
    fi
}

uninstall_command() {
    local install_dir="$1"
    local command_name="$2"
    local full_path="$install_dir/$command_name"
    
    log_info "Uninstalling ASW Version Checker..."
    
    if [[ -e "$full_path" ]]; then
        log_info "Removing: $full_path"
        if [[ "$install_dir" == "/usr/local/bin" ]] || [[ "$install_dir" =~ ^/usr/ ]]; then
            sudo rm -f "$full_path"
        else
            rm -f "$full_path"
        fi
        log_success "Uninstallation complete"
    else
        log_info "Command not found at: $full_path"
    fi
}

main() {
    local action="install"
    local install_dir="$INSTALL_DIR"
    local command_name="$LINK_NAME"
    local use_local=false
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                usage
                exit 0
                ;;
            -u|--uninstall)
                action="uninstall"
                shift
                ;;
            -d|--dir)
                install_dir="$2"
                shift 2
                ;;
            -n|--name)
                command_name="$2"
                shift 2
                ;;
            --local)
                use_local=true
                shift
                ;;
            --check)
                action="check"
                shift
                ;;
            *)
                log_error "Unknown option: $1"
                usage
                exit 1
                ;;
        esac
    done
    
    # Handle --local flag
    if [[ "$use_local" == true ]]; then
        install_dir="$HOME/.local/bin"
        log_info "Using local installation directory: $install_dir"
    fi
    
    # Update full path
    local full_path="$install_dir/$command_name"
    
    # Execute action
    case $action in
        install)
            check_dependencies || exit 1
            install_command "$install_dir" "$command_name"
            ;;
        uninstall)
            uninstall_command "$install_dir" "$command_name"
            ;;
        check)
            FULL_INSTALL_PATH="$full_path" check_installation
            ;;
        *)
            log_error "Unknown action: $action"
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"