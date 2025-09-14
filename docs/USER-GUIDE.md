# ASW Framework User Guide

Welcome to the **Agentic Secure Workflow (ASW) Framework** - a comprehensive infrastructure toolkit designed for secure, scalable VPS server management with integrated CI/CD, monitoring, and development tools.

## Table of Contents

- [Quick Start](#quick-start)
- [What is ASW Framework](#what-is-asw-framework)
- [Installation](#installation)
- [Core Components](#core-components)
- [Daily Workflows](#daily-workflows)
- [Testing Your Changes](#testing-your-changes)
- [Project Management](#project-management)
- [Security Features](#security-features)
- [Troubleshooting](#troubleshooting)
- [Advanced Usage](#advanced-usage)

## Quick Start

### 1. Set Up Your VPS Server

```bash
# From your local machine (one-time setup)
LOCAL_ASW="/opt/asw"
VPS_IP="your.server.ip"
VPS_PORT="2222"
VPS_USER="cc-user"
ONEPASSWORD_ITEM="Your-Server-Name"

# Run complete server setup
ssh -A -p $VPS_PORT $VPS_USER@$VPS_IP "bash -s '$ONEPASSWORD_ITEM'" < "$LOCAL_ASW/scripts/complete-server-setup.sh"
```

### 2. Access Your Server

```bash
# SSH with 1Password SSH agent
ssh -A -p 2222 cc-user@your.server.ip

# Navigate to ASW framework
cd /opt/asw

# Check framework status
./scripts/check-all-phases.sh
```

### 3. Start Testing (Development)

```bash
# Run comprehensive tests
./docker/test/scripts/ci-test.sh

# Or start file watcher for automatic testing
./docker/test/scripts/watch-test.sh
```

## What is ASW Framework

The ASW Framework provides:

### 🏗️ **Infrastructure Management**
- **Automated VPS setup** with Ubuntu hardening
- **Docker-based services** for databases, web servers, monitoring
- **Port management** system for multiple applications
- **SSL certificate automation** with Certbot

### 🛡️ **Security First**
- **SSH key-only authentication** with 1Password integration
- **UFW firewall** with fail2ban intrusion prevention
- **Security scanning** with TruffleHog and custom scanners
- **Secrets management** through 1Password vaults

### 🧪 **Testing & Quality**
- **Docker-based testing environment** matching production
- **Automated testing** for syntax, integration, security
- **CI/CD integration** with GitHub Actions
- **File watching** for development workflow

### 🚀 **Development Tools**
- **Claude Code integration** for AI-assisted development
- **Multiple project support** with automatic port allocation
- **GitHub CLI integration** for repository management
- **Python/Node.js environments** with package managers

## Installation

### Prerequisites

- **Local Machine**: Git, SSH, 1Password CLI
- **VPS Server**: Ubuntu/Debian with root access
- **1Password**: SSH key in Private vault, server credentials

### Step-by-Step Installation

#### 1. Clone ASW Framework Locally

```bash
# Create local ASW directory
LOCAL_ASW="/opt/asw"
sudo mkdir -p "$LOCAL_ASW"
sudo chown $(whoami):$(whoami) "$LOCAL_ASW"
cd "$LOCAL_ASW"

# Clone main repository
git clone https://github.com/jtjiver/agentic-framework-server.git .

# Clone submodules
git clone https://github.com/jtjiver/agentic-framework-core.git
git clone https://github.com/jtjiver/agentic-framework-dev.git
git clone https://github.com/jtjiver/agentic-framework-infrastructure.git
git clone https://github.com/jtjiver/agentic-framework-security.git
```

#### 2. Configure 1Password

```bash
# Create SSH key in 1Password Private vault
# - Title: "Your Server Name SSH Key"
# - Type: ED25519
# - Enable SSH agent integration

# Store server credentials in 1Password
# - Item Name: "Your Server Name"
# - Fields: IP address, username, root password
# - Vault: Your chosen vault name
```

#### 3. Run Server Setup

```bash
# Set your configuration
VPS_IP="your.server.ip.address"
VPS_PORT="22"  # Will change to 2222 after setup
VPS_USER="cc-user"
ONEPASSWORD_ITEM="Your-Server-Name"
VAULT_NAME="Your-Vault-Name"

# Execute three-phase setup
ssh -A -p $VPS_PORT $VPS_USER@$VPS_IP "bash -s '$ONEPASSWORD_ITEM' '$VAULT_NAME'" < "$LOCAL_ASW/scripts/complete-server-setup.sh"

# Setup 1Password service account token
ssh -A -p 2222 cc-user@$VPS_IP "bash -s" < "$LOCAL_ASW/scripts/setup-1password-interactive.sh"

# Validate installation
ssh -A -p 2222 cc-user@$VPS_IP "bash -s" < "$LOCAL_ASW/scripts/check-all-phases.sh"
```

## Core Components

### Server Repository (`agentic-framework-server`)
- **Setup Scripts**: Complete VPS configuration automation
- **Check Scripts**: System validation and health monitoring  
- **Docker Testing**: Comprehensive testing environment
- **Documentation**: User guides and technical references

### Core Framework (`agentic-framework-core`)
- **Base utilities** and shared libraries
- **Logging framework** for consistent output
- **Security tools** and scanners
- **1Password integration** helpers

### Development Tools (`agentic-framework-dev`)
- **Project creation** and management tools
- **Development server** management
- **Claude Code integration** and hooks
- **Local development** environment setup

### Infrastructure (`agentic-framework-infrastructure`)
- **Port management** system
- **Nginx configuration** management
- **Monitoring tools** and dashboards
- **Service orchestration** utilities

### Security (`agentic-framework-security`)
- **Security scanning** tools and policies
- **Threat detection** and monitoring
- **Compliance validation** frameworks
- **Audit logging** and reporting

## Daily Workflows

### Development Workflow

#### 1. Making Changes to Scripts

```bash
# Start file watcher for automatic testing
./docker/test/scripts/watch-test.sh

# In another terminal, edit any script
vim scripts/check-phase-01-bootstrap.sh

# Tests run automatically when you save!
# Check results in test-results/ directory
```

#### 2. Testing Specific Components

```bash
# Test syntax only (fast)
docker-compose -f docker/docker-compose.test.yml exec asw-test test-runner syntax

# Test security
docker-compose -f docker/docker-compose.test.yml exec asw-test test-runner security

# Full test suite
./docker/test/scripts/ci-test.sh
```

#### 3. Creating New Projects

```bash
# SSH to your server
ssh -A -p 2222 cc-user@your.server.ip

# Create new project with automatic port allocation
asw-new-project my-awesome-app personal

# Start development server
asw-dev-server start my-awesome-app
```

### Server Management

#### 1. Health Monitoring

```bash
# Check all framework phases
./scripts/check-all-phases.sh

# Check specific phase
./scripts/check-phase-01-bootstrap.sh
./scripts/check-phase-03-dev-environment.sh

# System resource monitoring
htop         # CPU and memory
iotop        # Disk I/O
nethogs      # Network usage
```

#### 2. Security Audits

```bash
# Run security scanner
asw-scan

# Check firewall status
sudo ufw status verbose

# Check fail2ban status
sudo fail2ban-client status

# Review SSH logs
sudo journalctl -u ssh -f
```

#### 3. Service Management

```bash
# Check running services
systemctl status nginx
systemctl status docker
systemctl status fail2ban

# Check port allocations
asw-port-manager list

# Check SSL certificates
certbot certificates
```

### Git Workflow

#### 1. Committing Changes

```bash
# Stage your changes
git add scripts/your-modified-script.sh

# Commit with standard format
git commit -m "Improve error handling in bootstrap script

- Add better error messages for missing dependencies
- Fix timeout handling for slow networks
- Update validation checks for Node.js version

🤖 Generated with Claude Code
Co-Authored-By: Claude <noreply@anthropic.com>"

# Push to remote
git push origin master
```

#### 2. Creating Pull Requests

```bash
# Create feature branch
git checkout -b feature/improve-error-handling

# Make changes and commit
git commit -m "Your changes"

# Push branch
git push origin feature/improve-error-handling

# Create PR using GitHub CLI
gh pr create --title "Improve error handling" --body "Description of changes"
```

## Testing Your Changes

The ASW Framework includes a comprehensive testing environment that runs in Docker containers matching your VPS configuration.

### Quick Testing

```bash
# Run all tests
./docker/test/scripts/ci-test.sh

# Run specific test types
docker-compose -f docker/docker-compose.test.yml up -d
docker-compose -f docker/docker-compose.test.yml exec asw-test test-runner syntax
docker-compose -f docker/docker-compose.test.yml exec asw-test test-runner integration
```

### Development Testing (Auto-run)

```bash
# Start file watcher
./docker/test/scripts/watch-test.sh

# Now edit any script - tests run automatically!
# Perfect for development workflow
```

### Test Categories

- **Syntax Tests**: Shellcheck validation, JSON parsing
- **Unit Tests**: Individual function testing with BATS
- **Integration Tests**: End-to-end script execution
- **Package Tests**: npm install/test for all Node.js components
- **Security Tests**: Secret scanning, permission audits

### Adding Your Own Tests

#### BATS Tests (Unit Testing)

Create `.bats` files anywhere in the repository:

```bash
#!/usr/bin/env bats

@test "my script has valid syntax" {
  run bash -n /opt/asw/scripts/my-script.sh
  [ "$status" -eq 0 ]
}

@test "my script produces expected output" {
  run /opt/asw/scripts/my-script.sh --test-flag
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Expected output" ]]
}
```

#### Integration Tests

Add scripts to `scripts/tests/test-*.sh`:

```bash
#!/bin/bash
# Test my new functionality

if /opt/asw/scripts/my-script.sh --validate; then
    echo "✅ My script validation passed"
    exit 0
else
    echo "❌ My script validation failed"
    exit 1
fi
```

## Project Management

### Creating New Projects

```bash
# SSH to server
ssh -A -p 2222 cc-user@your.server.ip

# Create project with automatic port allocation
asw-new-project project-name category
# Categories: personal, work, client, test

# Example
asw-new-project ecommerce-site client
asw-new-project blog-engine personal
```

### Managing Existing Projects

```bash
# List all projects
asw-port-manager list

# Start/stop projects
asw-dev-server start project-name
asw-dev-server stop project-name
asw-dev-server restart project-name

# Check project status
asw-dev-server status project-name
```

### Port Management

```bash
# View port allocations
asw-port-manager list

# Reserve specific port
asw-port-manager reserve 3000 my-app

# Release port
asw-port-manager release 3000
```

## Security Features

### 1Password Integration

#### SSH Key Management
- **SSH keys stored in 1Password Private vault**
- **Automatic SSH agent integration**
- **No local key files needed**

```bash
# SSH with 1Password agent
ssh -A -p 2222 cc-user@your.server.ip

# Keys are automatically loaded from 1Password
```

#### Secrets Management
- **Service account tokens in 1Password**
- **API keys and database passwords**
- **SSL certificates and private keys**

```bash
# Access secrets on server (with service account token configured)
op item get "Database Credentials" --vault "Your-Vault"
op item get "API Keys" --fields api_key --reveal
```

### Security Monitoring

#### Automated Scans
```bash
# Run security scanner
asw-scan

# Check for secrets in code
asw-scan --secrets-only

# Vulnerability scanning
asw-scan --vulnerabilities
```

#### Firewall Management
```bash
# Check firewall status
sudo ufw status verbose

# Add new rules (if needed)
sudo ufw allow from 192.168.1.0/24 to any port 22

# Check blocked attempts
sudo fail2ban-client status sshd
```

### Security Best Practices

1. **Never store secrets in code** - use 1Password
2. **Use SSH keys only** - password auth is disabled
3. **Keep software updated** - run `sudo apt update && sudo apt upgrade`
4. **Monitor logs regularly** - check `/var/log/auth.log`
5. **Review firewall rules** - only open necessary ports
6. **Rotate credentials** - update 1Password items regularly

## Troubleshooting

### Common Issues

#### SSH Connection Problems

```bash
# Check SSH service
sudo systemctl status ssh

# Check firewall
sudo ufw status

# Test connection
ssh -v -A -p 2222 cc-user@your.server.ip

# Check 1Password SSH agent
ssh-add -L
```

#### 1Password Issues

```bash
# Check 1Password CLI
op --version

# Test vault access
op vault list

# Check service account token
echo $OP_SERVICE_ACCOUNT_TOKEN

# Re-configure token
./scripts/setup-1password-interactive.sh
```

#### Docker Testing Problems

```bash
# Check Docker
docker --version
docker ps

# Rebuild test environment
docker-compose -f docker/docker-compose.test.yml build --no-cache

# Check test container logs
docker-compose -f docker/docker-compose.test.yml logs asw-test
```

#### Service Failures

```bash
# Check system logs
sudo journalctl -xe

# Check specific service
sudo systemctl status nginx
sudo systemctl status docker
sudo systemctl status fail2ban

# Restart services
sudo systemctl restart nginx
```

### Getting Help

#### Check System Status
```bash
# Run comprehensive validation
./scripts/check-all-phases.sh

# Check specific components
./scripts/check-phase-01-bootstrap.sh
./scripts/check-phase-03-dev-environment.sh
```

#### Debug Mode
```bash
# Run scripts with debug output
bash -x /opt/asw/scripts/check-phase-01-bootstrap.sh

# Check test environment
docker-compose -f docker/docker-compose.test.yml exec asw-test bash
```

#### Log Files
- **Setup logs**: `/opt/asw/logs/server-setup-*.log`
- **Test results**: `/opt/asw/test-results/`
- **System logs**: `/var/log/` (auth.log, nginx/, fail2ban.log)
- **Application logs**: Check individual project directories

## Advanced Usage

### Custom Configuration

#### Environment Variables
```bash
# In ~/.bashrc on server
export ASW_DEFAULT_PORT_RANGE="3000-3999"
export ASW_PROJECT_ROOT="/opt/projects"
export ASW_LOG_LEVEL="debug"
```

#### Custom Hooks
```bash
# Create custom Claude Code hooks
mkdir -p ~/.claude/hooks
# Add your custom hook scripts
```

### Performance Tuning

#### System Resources
```bash
# Monitor resource usage
htop
iotop
nethogs
sar -u 1 10  # CPU usage
sar -r 1 10  # Memory usage
```

#### Docker Optimization
```bash
# Clean up unused containers
docker system prune

# Optimize test environment
export DOCKER_BUILDKIT=1
export COMPOSE_DOCKER_CLI_BUILD=1
```

### Integration with External Services

#### GitHub Actions
The framework includes automatic GitHub Actions for:
- **Automated testing** on push/PR
- **Security scanning** with Trivy
- **Performance benchmarks** on main branch
- **Artifact uploads** for test results

#### Monitoring Integration
```bash
# Export metrics to external monitoring
# Custom monitoring hooks in agentic-framework-infrastructure
```

### Extending the Framework

#### Adding New Components
1. **Create new repository** following naming convention
2. **Add as submodule** to main server repository
3. **Update setup scripts** to include new component
4. **Add tests** for new functionality
5. **Update documentation**

#### Custom Scripts
```bash
# Add custom scripts to scripts/ directory
# Follow existing patterns and naming conventions
# Include proper error handling and logging
# Add corresponding tests
```

---

## Summary

The ASW Framework provides a complete infrastructure toolkit that combines:

- **🏗️ Automated server setup** with security hardening
- **🛡️ Integrated secrets management** via 1Password
- **🧪 Comprehensive testing** with Docker environments
- **🚀 Development tools** for efficient workflows
- **📊 Monitoring and validation** tools
- **🔄 CI/CD integration** for quality assurance

### Key Benefits

✅ **Production-Ready**: Battle-tested setup scripts and configurations  
✅ **Secure by Default**: SSH keys, firewall, intrusion prevention  
✅ **Developer Friendly**: File watching, auto-testing, Claude Code integration  
✅ **Scalable**: Multi-project support with port management  
✅ **Maintainable**: Comprehensive testing and documentation  

### Getting Support

- **Documentation**: `/opt/asw/docs/`
- **Testing Guide**: `/opt/asw/docs/testing-framework.md`
- **Setup Guide**: `/opt/asw/docs/asw-server-setup.md`
- **Issues**: Check logs and run validation scripts
- **Community**: GitHub repository discussions and issues

---

*ASW Framework - Secure, Scalable, Simple* 🚀