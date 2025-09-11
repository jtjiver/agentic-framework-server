# ASW Framework Complete Server Setup Guide

This guide provides the complete commands needed to set up a fresh ASW Framework server with enhanced Claude Code integration.

## 🏗️ Setup Overview

The setup is run entirely from your **local driving server** which has all the framework repositories cloned. The setup scripts automatically clone the necessary repositories to the VPS during the three-phase setup process.

## Prerequisites

- VPS server running Ubuntu/Debian  
- SSH access configured with key authentication
- **Local driving server** with all ASW framework repositories cloned
- Git installed on local machine

## Setup Process

All commands are run from your **local driving server** which has all the framework repositories cloned. The setup scripts automatically clone the necessary repositories to the VPS during the three-phase setup process.

### 1. Clone Framework Repositories Locally

Clone all the framework repositories to your local driving server:

```bash
# Set up local ASW directory
LOCAL_ASW="/opt/asw"  # or wherever you want it locally
sudo mkdir -p "$LOCAL_ASW"
sudo chown $(whoami):$(whoami) "$LOCAL_ASW"
cd "$LOCAL_ASW"

# Clone all framework repositories
git clone https://github.com/jtjiver/agentic-framework-server.git .
git clone https://github.com/jtjiver/agentic-framework-core.git
git clone https://github.com/jtjiver/agentic-framework-dev.git
git clone https://github.com/jtjiver/agentic-framework-infrastructure.git
git clone https://github.com/jtjiver/agentic-framework-security.git
git clone https://github.com/jtjiver/agentic-claude-config.git

# Verify you have all repositories
ls -la  # Should show: agentic-framework-core, agentic-framework-dev, etc.
```

### 2. Configure VPS Connection Details

```bash
# Set your VPS details  
VPS_IP="your.vps.ip.address"
VPS_PORT="2222"  # or 22 if using default SSH port
VPS_USER="cc-user" 
ONEPASSWORD_ITEM="Your-Server-Name"  # Name of server item in 1Password vault
VAULT_NAME="TennisTracker-Dev-Vault"  # Optional: 1Password vault name (defaults to TennisTracker-Dev-Vault)
ASW_ROOT="/opt/asw"  # Path where framework will be installed on VPS
```

### 3. Execute Three-Phase Setup by Sending Scripts to VPS

The setup scripts are sent from your local machine to the VPS and executed remotely. The VPS will automatically clone all necessary repositories during this process:

```bash
# Phase 1: Initial server setup and bootstrap
ssh -A -p $VPS_PORT $VPS_USER@$VPS_IP "bash -s '$ONEPASSWORD_ITEM' '$VAULT_NAME'" < "$LOCAL_ASW/scripts/complete-server-setup.sh"

# Phase 2: Security hardening  
ssh -A -p $VPS_PORT $VPS_USER@$VPS_IP "bash -s" < "$LOCAL_ASW/scripts/apply-full-hardening.sh"

# Phase 3: Development environment setup
ssh -A -p $VPS_PORT $VPS_USER@$VPS_IP "bash -s" < "$LOCAL_ASW/scripts/complete-dev-environment-setup.sh"
```

### 4. Configure 1Password Service Account Token

After the three-phase setup, configure the 1Password service account token:

```bash
# Run the interactive 1Password setup script
ssh -A -p $VPS_PORT $VPS_USER@$VPS_IP "bash -s" < "$LOCAL_ASW/scripts/setup-1password-interactive.sh"
```

Alternatively, you can set it up manually:
```bash
# Manual token setup
ssh -A -p $VPS_PORT $VPS_USER@$VPS_IP
echo 'ops_YOUR_TOKEN_HERE' > ~/.config/1password/token
chmod 600 ~/.config/1password/token
exit
```

### 5. Validate Complete Installation

Run comprehensive validation to verify all phases and 1Password integration completed successfully:

```bash
# Run full system validation (checks all phases)
ssh -A -p $VPS_PORT $VPS_USER@$VPS_IP "bash -s" < "$LOCAL_ASW/scripts/check-phase-03-dev-environment.sh"
```

## 🎯 One-Liner Commands

### Complete Setup (Run from local driving server)

```bash
LOCAL_ASW="/opt/asw" && VPS_IP="your.vps.ip.address" && VPS_PORT="2222" && VPS_USER="cc-user" && ONEPASSWORD_ITEM="Your-Server-Name" && VAULT_NAME="TennisTracker-Dev-Vault" && ssh -A -p $VPS_PORT $VPS_USER@$VPS_IP "bash -s '$ONEPASSWORD_ITEM' '$VAULT_NAME'" < "$LOCAL_ASW/scripts/complete-server-setup.sh" && ssh -A -p $VPS_PORT $VPS_USER@$VPS_IP "bash -s" < "$LOCAL_ASW/scripts/apply-full-hardening.sh" && ssh -A -p $VPS_PORT $VPS_USER@$VPS_IP "bash -s" < "$LOCAL_ASW/scripts/complete-dev-environment-setup.sh" && ssh -A -p $VPS_PORT $VPS_USER@$VPS_IP "bash -s" < "$LOCAL_ASW/scripts/setup-1password-interactive.sh" && ssh -A -p $VPS_PORT $VPS_USER@$VPS_IP "bash -s" < "$LOCAL_ASW/scripts/check-phase-03-dev-environment.sh"
```

## ✨ What You Get

After successful setup, your VPS will have:

### 🔧 Enhanced Claude Code Configuration
- **UV Package Manager** - Auto-installed for Python hook functionality
- **Smart Validation** - Context-aware recommendations, no false positives
- **Self-Protection** - Prevents installation errors and conflicts
- **Complete Commands & Hooks** - Ready-to-use slash commands and Python hooks
- **Organized Structure** - Separate core, project, and local customizations

### 🛡️ Three-Phase ASW Framework
- **Phase 1**: Bootstrap and initial server setup
- **Phase 2**: Comprehensive security hardening (UFW, fail2ban, SSH configuration)
- **Phase 3**: Development environment (Docker, nginx, ASW tools)

### 📊 Expected Results
- **Claude Code**: 96% validation success rate with intelligent recommendations
- **ASW Framework**: All phases validated and operational
- **Security**: Hardened server with 32/34+ security checks passing
- **Development Tools**: Full development environment ready for use

## 🚨 Troubleshooting

### SSH Connection Issues
- Verify VPS_IP, VPS_PORT, and VPS_USER variables
- Ensure SSH key authentication is set up
- Check firewall settings allow SSH on specified port

### Permission Issues
- Ensure the user has sudo privileges on the VPS
- Check directory ownership: `sudo chown -R $(whoami):$(whoami) $ASW_ROOT`

### Validation Failures
- Run `./validate-installation.sh` to check system dependencies
- Run `./cli/validate-config.sh $ASW_ROOT` to verify Claude config
- Run `bash scripts/check-phase-03-dev-environment.sh` for full validation

## 📝 Next Steps

After successful setup:

1. **Access your server**: `ssh -A -p $VPS_PORT $VPS_USER@$VPS_IP`
2. **Navigate to ASW directory**: `cd /opt/asw`
3. **Use Claude Code**: `claude`
4. **Create projects**: `asw-new-project my-project`
5. **Start development**: `asw-dev-server start`

## 🤖 Enhanced Features

This setup includes recent enhancements:
- **Path Resolution Fixes** - Works from any directory location
- **UV Auto-Installation** - Automatic Python package manager setup
- **Smart Recommendations** - Only suggests fixes for actual issues
- **Self-Installation Protection** - Prevents circular installation problems
- **Comprehensive Validation** - 40+ checks with intelligent feedback

---

**Last Updated**: September 2025  
**Compatible With**: ASW Framework v0.3.7+, Claude Code v1.0.111+