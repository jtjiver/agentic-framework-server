# ASW Framework - Complete Automation Architecture

## 🎯 Overview

The ASW Framework provides a fully automated path from fresh VPS to production-ready development environment, designed to be executed entirely from a remote Claude Code instance.

---

## 📐 Architecture Principles

### Remote Execution Design
All scripts are designed with **remote-first execution** in mind:
- **Claude Code server** acts as the control plane
- **Target VPS** receives commands via SSH
- **No manual intervention** required on target server
- **Idempotent operations** - safe to run multiple times

### Repository Structure
```
/opt/asw/ (on Claude Code server)
├── scripts/                           # Automation scripts
│   ├── complete-server-setup.sh      # Phase 1: Bootstrap
│   ├── apply-full-hardening.sh       # Phase 2: Security
│   └── complete-dev-environment-setup.sh # Phase 3: Dev tools
├── agentic-framework-core/           # Core utilities
├── agentic-framework-dev/            # Development tools
├── agentic-framework-infrastructure/ # Server management
└── agentic-framework-security/       # Security tools
```

---

## 🚀 Complete Remote Automation Flow

### Prerequisites
1. **Claude Code server** with ASW framework at `/opt/asw/`
2. **1Password** with server credentials and SSH keys
3. **Fresh VPS** with root access

### Three-Phase Remote Execution

```bash
# All commands run FROM Claude Code server
cd /opt/asw/scripts

# Phase 1: Bootstrap
./complete-server-setup.sh "1Password-Server-Item"

# Phase 2: Security Hardening  
ssh -A -p 2222 cc-user@SERVER_IP 'bash -s' < apply-full-hardening.sh

# Phase 3: Development Environment
ssh -A -p 2222 cc-user@SERVER_IP 'bash -s' < complete-dev-environment-setup.sh
```

---

## 📋 Detailed Phase Breakdown

### Phase 1: Bootstrap (Remote)

**Script:** `complete-server-setup.sh`  
**Execution:** Remote via SSH from Claude Code  
**Repository:** `/opt/asw/scripts/`

#### What It Does:
1. **Retrieves credentials** from 1Password
2. **Creates cc-user** account with sudo
3. **Installs base packages**:
   - git, curl, wget, vim, htop
   - Node.js v20.x and npm
   - 1Password CLI
   - build-essential
4. **Configures SSH** for key-only authentication
5. **Creates ASW framework** structure at `/opt/asw/`

#### Remote Commands Pattern:
```bash
# Executed from Claude Code server
SERVER_IP=$(op item get "$SERVER_ITEM" --format json | jq -r '.urls[0].href')
ROOT_PASS=$(op item get "$SERVER_ITEM" --fields password --reveal)

sshpass -p "$ROOT_PASS" ssh root@$SERVER_IP 'bash -s' << 'REMOTE_SCRIPT'
  useradd -m -s /bin/bash cc-user
  usermod -aG sudo cc-user
  apt update && apt install -y git curl nodejs npm
  mkdir -p /opt/asw
  chown -R cc-user:cc-user /opt/asw
REMOTE_SCRIPT
```

---

### Phase 2: Security Hardening (Remote)

**Script:** `apply-full-hardening.sh`  
**Execution:** Remote via SSH pipe  
**Repository:** `/opt/asw/scripts/`

#### What It Does:
1. **SSH Hardening**:
   - Creates `/etc/ssh/sshd_config.d/99-hardening.conf`
   - Uses port 2222 with TCP forwarding for VSCode/Cursor support
   - Disables root login and password authentication
   - Enforces strong ciphers and key exchange algorithms
2. **Firewall Configuration**:
   - UFW with ports 2222 (SSH), 80, 443 only
3. **Intrusion Prevention**:
   - fail2ban with SSH jail
4. **System Hardening**:
   - Kernel parameters via sysctl
   - Automatic security updates
5. **Monitoring Tools**:
   - htop, iotop, nethogs, sysstat
6. **CC User Environment**:
   - Standardized shell profile with tmux integration
   - Claude Code setup with 1Password integration
   - Comprehensive framework shortcuts and aliases

#### Remote Execution Method:
```bash
# From Claude Code server
ssh -A -p 2222 cc-user@$SERVER_IP 'bash -s' < /opt/asw/scripts/apply-full-hardening.sh

# Or using heredoc for inline execution
ssh -A -p 2222 cc-user@$SERVER_IP << 'REMOTE_HARDENING'
  sudo ufw allow 2222/tcp
  sudo ufw allow 80/tcp
  sudo ufw allow 443/tcp
  echo "y" | sudo ufw enable
  
  sudo tee /etc/fail2ban/jail.local << EOF
  [sshd]
  enabled = true
  backend = systemd
  EOF
  
  sudo systemctl enable fail2ban
  sudo systemctl start fail2ban
REMOTE_HARDENING
```

---

### Phase 3: Development Environment (Remote)

**Script:** `complete-dev-environment-setup.sh`  
**Execution:** Remote via SSH pipe  
**Repository:** `/opt/asw/scripts/`

#### What It Does:
1. **Installs additional packages**:
   - jq (JSON processing)
   - nginx (web server)
   - certbot (SSL certificates)
   - docker & docker-compose (optional)
2. **Links NPM packages**:
   - agentic-framework-infrastructure
   - agentic-framework-dev
   - agentic-framework-security
   - agentic-framework-core
3. **Creates command symlinks**:
   - asw-dev-server → infrastructure/bin/
   - asw-port-manager → infrastructure/bin/
   - asw-nginx-manager → infrastructure/bin/
   - asw-init → core/bin/
4. **Initializes services**:
   - Port registry at `/opt/asw/projects/.ports-registry.json`
   - Docker configuration
   - Nginx base setup

#### Remote Execution:
```bash
# From Claude Code server
ssh -A -p 2222 cc-user@$SERVER_IP 'bash -s' < /opt/asw/scripts/complete-dev-environment-setup.sh

# Or with remote framework installation
ssh -A -p 2222 cc-user@$SERVER_IP << 'REMOTE_DEV_SETUP'
  cd /opt/asw
  
  # Clone framework repos if needed
  git clone https://github.com/yourusername/agentic-framework-core.git
  git clone https://github.com/yourusername/agentic-framework-infrastructure.git
  
  # Link packages
  cd agentic-framework-infrastructure && sudo npm link
  cd ../agentic-framework-dev && sudo npm link
  
  # Create symlinks
  sudo ln -sf /opt/asw/agentic-framework-infrastructure/bin/asw-dev-server /usr/local/bin/
  
  # Initialize port registry
  mkdir -p /opt/asw/projects
  echo '{"ports":{}}' > /opt/asw/projects/.ports-registry.json
REMOTE_DEV_SETUP
```

---

## 🤖 Complete Remote Automation Script

Here's a single script that runs everything remotely:

```bash
#!/bin/bash
# complete-remote-vps-setup.sh
# Run from Claude Code server to fully configure a remote VPS

set -e

# Configuration
SERVER_ITEM="${1:-'My VPS Server'}"
GITHUB_USER="${2:-yourusername}"

echo "🚀 Starting complete remote VPS setup..."

# Get server details from 1Password
SERVER_IP=$(op item get "$SERVER_ITEM" --format json | jq -r '.urls[0].href')
ROOT_PASS=$(op item get "$SERVER_ITEM" --fields password --reveal)

if [[ -z "$SERVER_IP" ]] || [[ -z "$ROOT_PASS" ]]; then
    echo "❌ Could not retrieve server credentials from 1Password"
    exit 1
fi

echo "📍 Target server: $SERVER_IP (SSH port 2222)"

# Phase 1: Bootstrap
echo "🔧 Phase 1: Bootstrapping server..."
/opt/asw/scripts/complete-server-setup.sh "$SERVER_ITEM"

# Wait for SSH to be ready
sleep 10

# Phase 2: Security Hardening
echo "🔒 Phase 2: Applying security hardening..."
ssh -A -p 2222 cc-user@$SERVER_IP 'bash -s' << 'HARDENING_SCRIPT'
#!/bin/bash
set -e

# UFW Firewall
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 2222/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
echo "y" | sudo ufw enable

# fail2ban
sudo apt update && sudo apt install -y fail2ban
sudo tee /etc/fail2ban/jail.local > /dev/null << 'EOF'
[DEFAULT]
bantime = 1h
findtime = 10m
maxretry = 3
backend = systemd

[sshd]
enabled = true
EOF

sudo systemctl enable fail2ban
sudo systemctl restart fail2ban

# SSH Hardening
sudo tee /etc/ssh/sshd_config.d/99-hardening.conf > /dev/null << 'EOF'
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
AllowUsers cc-user
MaxAuthTries 3
Protocol 2
EOF

sudo systemctl restart ssh

# Automatic updates
sudo apt install -y unattended-upgrades
sudo dpkg-reconfigure -plow unattended-upgrades

echo "✅ Security hardening complete"
HARDENING_SCRIPT

# Phase 3: Development Environment
echo "🛠️ Phase 3: Setting up development environment..."
ssh -A -p 2222 cc-user@$SERVER_IP 'bash -s' << 'DEV_SETUP_SCRIPT'
#!/bin/bash
set -e

# Install required packages
sudo apt update
sudo apt install -y jq nginx certbot python3-certbot-nginx

# Clone ASW framework if not present
if [[ ! -d "/opt/asw/agentic-framework-core" ]]; then
    cd /opt/asw
    git clone https://github.com/GITHUB_USER/agentic-framework-core.git || true
    git clone https://github.com/GITHUB_USER/agentic-framework-infrastructure.git || true
    git clone https://github.com/GITHUB_USER/agentic-framework-dev.git || true
    git clone https://github.com/GITHUB_USER/agentic-framework-security.git || true
fi

# Link NPM packages
cd /opt/asw
for pkg in agentic-framework-*; do
    if [[ -d "$pkg" ]] && [[ -f "$pkg/package.json" ]]; then
        cd "$pkg"
        sudo npm link 2>/dev/null || echo "Package $pkg already linked"
        cd ..
    fi
done

# Create command symlinks
for cmd in /opt/asw/agentic-framework-infrastructure/bin/*; do
    if [[ -f "$cmd" ]]; then
        sudo ln -sf "$cmd" /usr/local/bin/
    fi
done

for cmd in /opt/asw/agentic-framework-core/bin/*; do
    if [[ -f "$cmd" ]]; then
        sudo ln -sf "$cmd" /usr/local/bin/
    fi
done

# Initialize port registry
mkdir -p /opt/asw/projects
[[ ! -f "/opt/asw/projects/.ports-registry.json" ]] && echo '{"ports":{}}' > /opt/asw/projects/.ports-registry.json

echo "✅ Development environment ready"
DEV_SETUP_SCRIPT

# Phase 4: Validation
echo "✅ Phase 4: Validating setup..."
ssh -A -p 2222 cc-user@$SERVER_IP << 'VALIDATION'
echo "=== Server Status ==="
echo "Firewall: $(sudo ufw status | grep Status)"
echo "fail2ban: $(sudo systemctl is-active fail2ban)"
echo "SSH: $(sudo systemctl is-active ssh)"
echo ""
echo "=== Available Commands ==="
which asw-dev-server 2>/dev/null && echo "✓ asw-dev-server" || echo "✗ asw-dev-server"
which asw-port-manager 2>/dev/null && echo "✓ asw-port-manager" || echo "✗ asw-port-manager"
which asw-nginx-manager 2>/dev/null && echo "✓ asw-nginx-manager" || echo "✗ asw-nginx-manager"
echo ""
echo "=== Framework Status ==="
ls -la /opt/asw/ | grep agentic-framework
VALIDATION

echo ""
echo "🎉 Complete VPS setup finished!"
echo "📍 Server: $SERVER_IP"
echo "👤 Access: ssh -A -p 2222 cc-user@$SERVER_IP"
echo "🚀 Ready for development!"
```

---

## 🔄 Benefits of Remote Execution

### Advantages:
1. **Zero manual intervention** - Everything automated
2. **Consistent environment** - Claude Code server has all tools
3. **Centralized management** - One place for all automation
4. **Credential security** - 1Password integration on Claude Code
5. **Idempotent execution** - Safe to run multiple times
6. **Version control** - All scripts in git repos

### Security Benefits:
- No credentials stored on target servers
- SSH keys managed via 1Password
- Service account on Claude Code has limited scope
- Audit trail of all operations

---

## 📊 Command & Library Matrix

### Scripts by Repository

| Repository | Scripts | Purpose | Execution |
|------------|---------|---------|-----------|
| `/opt/asw/scripts/` | `complete-server-setup.sh` | Bootstrap | Remote SSH |
| `/opt/asw/scripts/` | `apply-full-hardening.sh` | Security | Remote pipe |
| `/opt/asw/scripts/` | `complete-dev-environment-setup.sh` | Dev tools | Remote pipe |
| `agentic-framework-infrastructure/bin/` | `asw-dev-server` | Dev server | Local CLI |
| `agentic-framework-infrastructure/bin/` | `asw-port-manager` | Port mgmt | Local CLI |
| `agentic-framework-infrastructure/bin/` | `asw-nginx-manager` | Proxy mgmt | Local CLI |
| `agentic-framework-core/bin/` | `asw-init` | Project init | Local CLI |
| `agentic-framework-core/bin/` | `asw-scan` | Security scan | Local CLI |

### Libraries Used Internally

| Library | Location | Used By |
|---------|----------|---------|
| `bash-logger.sh` | `core/lib/logging/` | All ASW commands |
| `vault-context-manager.sh` | `security/lib/shared/` | Secret management |
| `1password-inject.sh` | `core/lib/security/1password-helper/` | Credential injection |
| `nginx-safe-manager.sh` | `infrastructure/lib/web-gateway/` | Nginx operations |
| `health-check-claude-safe.sh` | `infrastructure/lib/monitoring/` | Health monitoring |

---

## 🎯 Summary

**Yes, everything can be run remotely from Claude Code!**

The entire setup is designed for remote execution:
1. **Bootstrap** - Creates user and base setup
2. **Harden** - Applies security configuration
3. **Install** - Sets up development environment
4. **Validate** - Confirms everything works

**One command to rule them all:**
```bash
./complete-remote-vps-setup.sh "My-VPS-Server"
```

This gives you a production-ready, secure development server without ever logging into the VPS manually!