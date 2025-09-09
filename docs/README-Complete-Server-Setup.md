# Complete VPS Server Setup - One Command Solution

## 🎯 **What This Does**
Transforms a fresh VPS server into a fully hardened, development-ready environment with **one command**.

## 🚀 **Quick Start - Remote Build Principle**

### **🔑 Core Principle: Remote Building**
This setup is designed to run **remotely from Claude Code server** via SSH commands to the new VPS. You don't run commands locally - Claude Code executes everything remotely.

### **Step 1: Prerequisites**
1. **Create SSH key in 1Password PRIVATE vault**:
   - Open 1Password → Click "+" → SSH Key
   - Title: `YourServer VPS SSH Key`
   - **IMPORTANT**: Save to **Private vault** (not team vaults)
   - Generate ED25519 key
   - Save

2. **Enable 1Password SSH Agent**:
   - 1Password Settings → Developer
   - Enable "Use the SSH agent"
   - Restart terminal

3. **Server credentials in 1Password**:
   - Create item with server IP and root password
   - Claude Code service account needs access to this item

### **Step 2: Remote Execution via Claude Code**
**YOU DON'T RUN THIS LOCALLY** - Claude Code runs it for you:

```bash
# This runs on Claude Code server (/opt/asw directory)
cd /opt/asw/scripts
./complete-server-setup.sh "Your-1Password-Server-Item"
```

**Process:**
1. **Claude Code** retrieves server credentials from 1Password
2. **Claude Code** prompts you for SSH public key (from your Private vault)
3. **Claude Code** executes remote SSH commands to configure new VPS
4. **Claude Code** reports back with connection details

### **Step 3: Connect from Your Laptop**
```bash
# You run this from your laptop
ssh -A cc-user@YOUR_SERVER_IP
```

## 🏗️ **Remote Building Architecture**

### **The Claude Code Advantage:**
```
Your Laptop  →  Claude Code Server  →  New VPS Server
     ↓              ↓                      ↓
  SSH Agent    1Password Service      Fresh Install
              Account Access            ↓
                   ↓               Fully Configured
              Automation Scripts
```

### **Why Remote Building?**
- ✅ **Consistent Environment**: Claude Code server has all tools pre-installed
- ✅ **1Password Integration**: Service account can access shared vault credentials
- ✅ **Script Availability**: All ASW framework scripts are in `/opt/asw/`
- ✅ **No Local Dependencies**: You don't need to install sshpass, configure scripts locally
- ✅ **Centralized Management**: One place for all server automation
- ✅ **Idempotent Execution**: Safe to run multiple times from stable environment

## 🔐 **1Password SSH Integration**

### **Why Private Vault?**
- 1Password SSH Agent **only uses keys from Private vault** by default
- Team/shared vaults require manual configuration
- Service accounts (like Claude Code) **cannot access Private vault** (good security)

### **The Process:**
1. **You**: Create SSH key in Private vault
2. **Script**: Prompts for public key (since it can't access Private vault)
3. **Script**: Configures server with public key
4. **You**: Connect using `ssh -A` (agent forwards your private key)

### **Critical Discovery: Vault Migration**
If you initially create the SSH key in a team/shared vault:
1. **1Password SSH agent won't use it** (Private vault only by default)
2. **You'll get "Permission denied (publickey)" errors**
3. **Solution**: Move the SSH key item to your Private vault
4. **1Password will then make it available to SSH agent**
5. **Connection will work immediately with `ssh -A`**

**Important**: This vault limitation is a 1Password security feature, not a bug!

## 📋 **What Gets Configured**

### **Security Hardening:**
- ✅ Root SSH login disabled
- ✅ Password authentication disabled
- ✅ Only cc-user allowed SSH access
- ✅ UFW firewall (ports 22, 80, 443 open)
- ✅ fail2ban protection against brute force
- ✅ Strong SSH ciphers enforced
- ✅ Automatic security updates

### **Development Tools:**
- ✅ Node.js v20.x + npm
- ✅ Claude Code CLI (`@anthropic-ai/claude-code`)
- ✅ 1Password CLI
- ✅ Git, curl, wget, vim, htop
- ✅ Essential build tools

**Claude Code CLI Details:**
- **Package**: `@anthropic-ai/claude-code` 
- **Requirements**: Node.js 18+, 4GB+ RAM, Ubuntu 20.04+/Debian 10+
- **Installation**: `sudo npm install -g @anthropic-ai/claude-code`
- **Verification**: `claude --version`
- **Documentation**: https://docs.anthropic.com/en/docs/claude-code/setup

### **ASW Framework Structure:**
```
/opt/asw/ (git repo: agentic-framework-server)
├── .claude/                           ← Claude Code configuration
├── agentic-framework-core/            ← Git repo: agentic-framework-core
├── agentic-framework-dev/             ← Git repo: agentic-framework-dev  
├── agentic-framework-infrastructure/  ← Git repo: agentic-framework-infrastructure
├── agentic-framework-security/        ← Git repo: agentic-framework-security
├── scripts/                           ← Server automation scripts
└── docs/                             ← Documentation
```

### **User Account:**
- ✅ cc-user with sudo privileges
- ✅ Secure random password (saved to 1Password)
- ✅ SSH key authentication only
- ✅ 1Password SSH agent compatibility

## 🔄 **Typical Workflow with Claude Code**

### **You Say:**
> "I have a new VPS server, credentials are in 1Password item 'MyNewServer - VPS'. Can you set it up with full hardening?"

### **Claude Code Does:**
1. **Retrieves credentials** from 1Password using service account
2. **Asks for your SSH public key** (since it can't access your Private vault)
3. **Executes the complete setup script** remotely:
   ```bash
   cd /opt/asw/scripts
   ./complete-server-setup.sh "MyNewServer - VPS"
   ```
4. **Runs all SSH commands** to the new server from `/opt/asw/`
5. **Reports completion** with connection details

### **You Get:**
- ✅ Fully hardened server ready for development
- ✅ SSH access via: `ssh -A cc-user@SERVER_IP`  
- ✅ ASW framework installed and ready
- ✅ All credentials updated in 1Password

### **No Manual Work Required:**
- ❌ No local script downloads
- ❌ No dependency installations  
- ❌ No manual SSH key management
- ❌ No server configuration steps

### **What Happens During Setup:**
1. **Credential Retrieval**: Gets server IP and root password from 1Password
2. **SSH Public Key Collection**: Prompts you for public key from Private vault
3. **Remote System Preparation**: Updates packages, installs tools
4. **User Account Creation**: Creates cc-user with secure random password
5. **SSH Configuration**: Adds your key, hardens SSH settings
6. **Security Implementation**: Firewall, fail2ban, strong ciphers
7. **Framework Repository Setup**: Clones agentic-framework-server as main /opt/asw git repo
8. **Additional Framework Repos**: Clones agentic-framework-{core,dev,infrastructure,security} as subdirectories
9. **Claude Code Integration**: Adds .claude configuration from agentic-claude-config repo
10. **Framework Package Installation**: Runs setup.sh to install all framework packages
11. **Final Validation**: Tests connection and reports success

## 🔧 **Script Features**

### **Idempotent Design:**
- ✅ Safe to run multiple times
- ✅ Checks existing state before changes
- ✅ Won't duplicate or break existing setup

### **Error Handling:**
- ✅ Validates SSH key format
- ✅ Tests configurations before applying
- ✅ Comprehensive logging
- ✅ Clear error messages

### **1Password Integration:**
- ✅ Retrieves server credentials automatically
- ✅ Updates 1Password with new user password
- ✅ Handles Private vault SSH key workflow
- ✅ Validates SSH agent compatibility

### **Framework Integration:**
- ✅ Clones agentic-framework-server as main git repository at `/opt/asw/`
- ✅ Clones all framework component repos: core, dev, infrastructure, security
- ✅ Installs Claude Code configuration (.claude folder) from agentic-claude-config
- ✅ Runs setup.sh to install all framework packages
- ✅ Creates complete working environment ready for development
- ✅ Maintains proper git repository structure for version control

## 🚨 **Troubleshooting**

### **"Too many authentication failures"**
This happens when SSH tries too many keys and hits the server's MaxAuthTries limit (3 by default).

**Solutions:**
```bash
# Option 1: Clear SSH agent and try with -A only
ssh-add -D
ssh -A cc-user@YOUR_SERVER_IP

# Option 2: Use IdentitiesOnly to limit key attempts  
ssh -A -o IdentitiesOnly=yes cc-user@YOUR_SERVER_IP

# Option 3: If Claude Code is setting up, it may temporarily increase MaxAuthTries to 10
```

**Why this happens:**
- Multiple SSH keys loaded in agent (common with 1Password + other keys)
- SSH tries all keys before failing
- Server rejects after 3 attempts for security

### **SSH key not found in agent**
```bash
# Check if key is loaded
ssh-add -l | grep yourserver

# Restart 1Password SSH agent
# 1Password Settings → Developer → Toggle SSH agent off/on
```

### **Permission denied (publickey)**
1. Verify SSH key is in **Private vault**
2. Confirm 1Password SSH agent is enabled
3. Use `-A` flag: `ssh -A cc-user@SERVER_IP`

### **Claude Code Installation Issues**
**Package not found error:**
- Correct package: `@anthropic-ai/claude-code` (not `@anthropic/claude-code-cli`)
- Install command: `sudo npm install -g @anthropic-ai/claude-code`

**Permission errors during npm install:**
- Use `sudo` for global npm installs on most Linux systems
- Verify Node.js 18+ is installed: `node --version`

**Verification:**
```bash
# Check installation
claude --version
# Should return: 1.0.109 (Claude Code) or higher

# Run diagnostics
claude doctor
```

## 📖 **Advanced Usage**

### **Custom Vault:**
```bash
./complete-server-setup.sh "Server-Item" "Custom-Vault-Name"
```

### **Multiple Servers:**
- Create separate SSH keys in 1Password for each server
- Use descriptive names: "Production SSH", "Staging SSH", etc.
- Run script for each server with different 1Password items

### **Backup Keys:**
- 1Password automatically syncs SSH keys across devices
- Private keys never leave 1Password (secure)
- Public keys can be safely shared/copied

## 🎉 **Success Indicators**

When complete, you should see:
```bash
🎉 SETUP COMPLETE!
========================================
🚀 VPS Server Setup Complete!
========================================
📍 Server IP: YOUR_IP
👤 Username: cc-user
🔐 SSH Access: ssh -A cc-user@YOUR_IP
📁 Framework: /opt/asw/

✅ Features Configured:
  - SSH hardened (key-only, no root)
  - UFW firewall enabled
  - fail2ban active
  - Node.js + Claude Code + 1Password CLI installed
  - ASW framework structure ready
  - 1Password SSH agent integration
```

## ⚙️ **Behind the Scenes: Remote Execution**

### **What Claude Code Actually Runs:**
```bash
# From Claude Code server at /opt/asw/
cd /opt/asw/scripts

# Execute complete server setup
./complete-server-setup.sh "1Password-Server-Item"

# Script performs these remote SSH operations:
sshpass -p 'ROOT_PASS' ssh root@NEW_SERVER 'bash -s' < setup-script.sh
sshpass -p 'ROOT_PASS' ssh root@NEW_SERVER 'echo "SSH_KEY" >> ~/.ssh/authorized_keys'
ssh -i temp-key cc-user@NEW_SERVER 'sudo systemctl restart ssh'

# Validation and cleanup
ssh -A cc-user@NEW_SERVER 'whoami && node --version && op --version'
```

### **Directory Structure on Claude Code Server:**
```
/opt/asw/
├── scripts/
│   ├── complete-server-setup.sh    ← Main automation script
│   ├── setup-new-server.sh         ← Alternative simple version
│   └── automated-server-setup.sh   ← Advanced idempotent version
├── docs/
│   ├── README-Complete-Server-Setup.md
│   ├── final-setup-summary.md
│   └── 1password-ssh-private-vault-requirement.md
└── agentic-framework-*/            ← Framework structure
```

### **Remote SSH Commands Executed:**
1. **System Updates**: `apt update && apt upgrade -y`
2. **Package Installation**: `apt install -y sudo curl git wget...`  
3. **User Creation**: `useradd -m cc-user && usermod -aG sudo cc-user`
4. **SSH Key Setup**: Adds 1Password SSH public key to authorized_keys
5. **SSH Hardening**: Updates `/etc/ssh/sshd_config.d/99-hardening.conf`
6. **Password Authentication Disabled**: `PasswordAuthentication no`
7. **Firewall Setup**: `ufw enable && ufw allow 22,80,443`
8. **Tool Installation**: Node.js, Claude Code CLI, 1Password CLI, fail2ban
9. **Framework Setup**: Clones agentic-framework-server as main `/opt/asw/` git repo
10. **Component Repos**: Clones agentic-framework-{core,dev,infrastructure,security} subdirectories
11. **Cleanup**: Removes temporary SSH keys, keeps only 1Password key
12. **Validation**: Tests final SSH access and tool installation

## 🔄 **Next Steps**

Your server is ready for:
1. **Domain & SSL setup** (Let's Encrypt automation)
2. **Development server provisioning** (Docker, port management)  
3. **Project scaffolding** (automated project creation)
4. **CI/CD pipeline integration**
5. **Monitoring & alerting**

**Perfect foundation for rapid, secure development!** 🚀

---

## 🎯 **Summary: Remote Build Advantage**

✅ **You**: Create SSH key in 1Password Private vault  
✅ **You**: Ask Claude Code to setup new server  
✅ **Claude Code**: Executes all automation remotely from `/opt/asw/`  
✅ **You**: Connect with `ssh -A cc-user@SERVER_IP`  

**Zero local dependencies, maximum automation!** 🚀