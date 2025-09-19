# ASW Framework - Complete Documentation & Setup Guide

## 📖 **Master Documentation Index**

This is the complete guide for the ASW Framework at `/opt/asw/`. All documentation, setup instructions, and technical references are organized here.

---

## 🚀 **Quick Start - Essential Documents**

### **[📋 Complete Server Setup Guide](docs/README-Complete-Server-Setup.md)** ⭐
**THE MAIN GUIDE** - Start here for complete VPS server setup.
- Remote execution from Claude Code server
- 1Password SSH integration and Private vault requirements
- One-command automation workflow
- Troubleshooting common SSH issues

### **[🤖 Complete Automation Architecture](docs/COMPLETE-AUTOMATION-ARCHITECTURE.md)** ⭐  
**TECHNICAL REFERENCE** - Comprehensive breakdown of the entire system.
- All scripts, repositories, and commands mapped
- Remote vs local execution patterns
- Complete automation from Claude Code instance
- Phase-by-phase breakdown with code examples

### **[🛠️ Clean Server Setup Workflow](docs/CLEAN-SERVER-SETUP-WORKFLOW.md)** ⭐
**QUICK REFERENCE** - Simple 3-step process from VPS to dev environment.
- Bootstrap → Harden → Install framework
- Clear command sequences
- Daily workflow examples

---

## 🏗️ **Repository Structure**

```
/opt/asw/                                    # ASW Framework root
├── README.md                               # This file
├── setup.sh                               # Framework installation script
├── FINAL-FRAMEWORK-GUIDE.md               # Complete usage guide
├── docs/                                   # Documentation library
├── scripts/                                # Utility scripts
│   ├── new-project.sh                     # Quick project creation
│   ├── complete-remote-vps-setup.sh       # Full automation script
│   └── tests/                             # Framework tests
├── projects/.gitkeep                      # Project directory structure
└── .gitignore                             # Excludes framework packages

# After running ./setup.sh:
├── agentic-framework-core/                 # Cloned (gitignored)
├── agentic-framework-security/             # Cloned (gitignored)
├── agentic-framework-dev/                  # Cloned (gitignored)
└── projects/                               # Ready for your projects
    ├── personal/                           # Personal projects
    ├── clients/                            # Client projects
    └── experiments/                        # Quick tests
```

---

## ⚡ **Quick Start (Fresh Installation)**

```bash
# 1. Clone the main repository
git clone <repository-url> /opt/asw
cd /opt/asw

# 2. Run setup (handles everything automatically)
./setup.sh

# 3. Verify installation  
asw-check-version
```

**What `./setup.sh` does:**
- ✅ Initializes and updates all Git submodules
- ✅ Configures proper branch tracking (prevents detached HEAD)
- ✅ Installs NPM packages globally
- ✅ Creates project directory structure
- ✅ Installs ASW version checker command
- ✅ Sets up Claude Code configuration (hooks, settings, prompts)
- ✅ Sets up secrets directory

**After setup, you can:**
- Check versions: `asw-check-version`
- Use Claude Code with configured hooks and settings
- Create projects: `./scripts/new-project.sh my-app personal`
- Deploy services: Use infrastructure utilities

---

## 🎯 **What This Repo Contains**

This is the **server configuration repo** - it contains only:
- ✅ Documentation and guides
- ✅ Server utility scripts  
- ✅ Setup/configuration files
- ✅ Project directory structure

This repo does **NOT** contain:
- ❌ Framework source code (separate repos)
- ❌ NPM packages (installed separately)
- ❌ User projects (workspace)
- ❌ Sensitive files (secrets, logs, etc.)

---

## 🚀 **Installation & Setup**

### **Option 1: Complete Automated Setup (Recommended)**
```bash
# From your Claude Code server, set up a new VPS completely:
/opt/asw/scripts/complete-remote-vps-setup.sh "Your-1Password-Item"
```

### **Option 2: Manual Setup**

#### 1. Clone to /opt/asw
```bash
sudo git clone https://github.com/jtjiver/agentic-framework-server.git /opt/asw
cd /opt/asw
sudo chown -R cc-user:cc-user /opt/asw  # Set proper ownership
```

#### 2. Run Setup Script
```bash
./setup.sh
```

This will:
- Clone all framework package repos
- Install NPM packages globally
- Set up project directories
- Configure permissions

#### 3. Configure 1Password
```bash
# Set your service account token
export OP_SERVICE_ACCOUNT_TOKEN="ops_YOUR_TOKEN"

# Or create token file
echo 'ops_YOUR_TOKEN' > .secrets/op-service-account-token
chmod 600 .secrets/op-service-account-token
```

#### 4. Create Your First Project
```bash
./scripts/new-project.sh my-awesome-project personal
cd projects/personal/my-awesome-project/
```

---

## 📚 **Core Framework Documentation**

### **Framework Architecture & Usage**
- **[ASW Framework Scripts Summary](docs/ASW_FRAMEWORK_SCRIPTS_SUMMARY.md)** - Complete reference of all scripts and utilities across 4 repositories
- **[Framework Complete Guide](docs/FRAMEWORK-COMPLETE-GUIDE.md)** - Comprehensive framework overview with location-based context
- **[Simple Framework Flows](docs/SIMPLE-FRAMEWORK-FLOWS.md)** - Common usage patterns and decision trees
- **[Framework Use Cases and Patterns](docs/FRAMEWORK-USE-CASES-AND-PATTERNS.md)** - Real-world usage scenarios

### **Security & 1Password Integration**
- **[Hybrid Vault Usage](docs/HYBRID-VAULT-USAGE.md)** - Managing multiple 1Password vaults across contexts
- **[Vault Architecture Design](docs/vault-architecture-design.md)** - Security vault design principles
- **[Server Check Usage](docs/server-check-usage.md)** - Comprehensive server verification tool

### **Specialized Features**
- **[Health Check Enhancements](docs/health-check-enhancements.md)** - Monitoring and health check setup
- **[Gmail API Setup](docs/gmail-api-setup.md)** - Email notifications configuration
- **[SSH Port Configuration](docs/SSH-PORT-CONFIGURATION.md)** - SSH port management guide

---

## 🎯 **Quick Navigation by Purpose**

### **🆕 Setting Up a New Server?**
1. **[Complete Server Setup Guide](docs/README-Complete-Server-Setup.md)** - Main setup process
2. **[Clean Server Setup Workflow](docs/CLEAN-SERVER-SETUP-WORKFLOW.md)** - Quick reference
3. **[Complete Automation Architecture](docs/COMPLETE-AUTOMATION-ARCHITECTURE.md)** - Technical details

### **🔧 Understanding the Framework?**
1. **[Framework Complete Guide](docs/FRAMEWORK-COMPLETE-GUIDE.md)** - High-level overview
2. **[ASW Framework Scripts Summary](docs/ASW_FRAMEWORK_SCRIPTS_SUMMARY.md)** - All scripts and tools
3. **[Simple Framework Flows](docs/SIMPLE-FRAMEWORK-FLOWS.md)** - Usage patterns

### **🔐 Working with 1Password & Security?**
1. **[Hybrid Vault Usage](docs/HYBRID-VAULT-USAGE.md)** - Vault management
2. **[Vault Architecture Design](docs/vault-architecture-design.md)** - Security design
3. **[Server Check Usage](docs/server-check-usage.md)** - Verification tools

### **📊 Monitoring & Operations?**
1. **[Health Check Enhancements](docs/health-check-enhancements.md)** - System monitoring
2. **[Gmail API Setup](docs/gmail-api-setup.md)** - Email notifications
3. **[Server Check Usage](docs/server-check-usage.md)** - Health verification

### **🤖 Automation & Development?**
1. **[Complete Automation Architecture](docs/COMPLETE-AUTOMATION-ARCHITECTURE.md)** - Full automation
2. **[NPM Automation](docs/NPM-AUTOMATION.md)** - Package management
3. **[Framework Use Cases and Patterns](docs/FRAMEWORK-USE-CASES-AND-PATTERNS.md)** - Development patterns

---

## 🔐 **Framework Architecture**

### **Single Location Standard**
**Everything lives in `/opt/asw/`** - no scattered files, no confusion.

### **Automatic Context Detection**
Framework knows what vault to use based on where you are:
- In framework directories → Server operations
- In project directories → Project-specific operations

### **Hybrid Vault System**
- One service account token
- Multiple vaults for perfect isolation
- Automatic vault selection

---

## 🛠️ **Daily Workflow**

```bash
# Navigate to /opt/asw (your standard working directory)
cd /opt/asw

# Create new project
./scripts/new-project.sh my-startup personal

# Work on project
cd projects/personal/my-startup/
source /opt/asw/agentic-framework-security/lib/shared/vault-context-manager.sh
get_secret "DATABASE_URL"  # Auto-uses MyStartup-Secrets vault

# Framework tools available everywhere
asw-scan  # Security scanning
af-manage-containers list  # Container management
```

---

## 🔄 **Updating**

### **Update Server Config**
```bash
cd /opt/asw
git pull origin main
```

### **Update Framework Packages**
```bash
./setup.sh  # Re-runs setup, updates all framework repos
```

### **Update NPM Packages**
```bash
npm update -g @jtjiver/agentic-framework-*
```

---

## 🛣️ **Recommended Reading Paths**

### **For New Users:**
1. [Complete Server Setup Guide](docs/README-Complete-Server-Setup.md) - Understand the process
2. [Clean Server Setup Workflow](docs/CLEAN-SERVER-SETUP-WORKFLOW.md) - See the steps
3. [Framework Complete Guide](docs/FRAMEWORK-COMPLETE-GUIDE.md) - Learn the framework

### **For Developers:**
1. [Complete Automation Architecture](docs/COMPLETE-AUTOMATION-ARCHITECTURE.md) - Technical overview
2. [ASW Framework Scripts Summary](docs/ASW_FRAMEWORK_SCRIPTS_SUMMARY.md) - All tools reference
3. [Framework Use Cases and Patterns](docs/FRAMEWORK-USE-CASES-AND-PATTERNS.md) - Implementation patterns

### **For System Administrators:**
1. [Server Check Usage](docs/server-check-usage.md) - Verification tools
2. [Hybrid Vault Usage](docs/HYBRID-VAULT-USAGE.md) - Security management
3. [Health Check Enhancements](docs/health-check-enhancements.md) - Monitoring

---

## 📊 **Document Status & Archive**

### **Active Documentation**
All documents listed above are current and actively maintained. See individual documents for specific update dates.

### **Archived Documents**
Historical references are available in:
- `/opt/asw/docs/archive/session-logs/` - Setup logs and completion summaries
- `/opt/asw/docs/archive/superseded/` - Outdated documentation for reference

---

## 🎯 **Quick Command Reference**

### **Initial Setup**
```bash
# Complete automated setup from Claude Code server
/opt/asw/scripts/complete-remote-vps-setup.sh "Your-1Password-Item"
```

### **Read Documentation**
```bash
# View main setup guide
cat /opt/asw/docs/README-Complete-Server-Setup.md

# View quick workflow
cat /opt/asw/docs/CLEAN-SERVER-SETUP-WORKFLOW.md

# View technical architecture
cat /opt/asw/docs/COMPLETE-AUTOMATION-ARCHITECTURE.md
```

### **Create Projects**
```bash
# Create new project
/opt/asw/scripts/new-project.sh project-name category
```

---

## 🎉 **Ready to Build**

The framework is designed to get out of your way. Once set up:
- Create projects quickly with `./scripts/new-project.sh`
- Get secrets easily with automatic vault detection
- Use all framework tools from anywhere in `/opt/asw/`

**Focus on building, not configuration.** 🚀

---

## 📝 **Maintenance & Support**

**Last Updated:** 2025-09-10  
**Repository:** https://github.com/jtjiver/agentic-framework-server  
**Maintained By:** ASW Framework Team  

For detailed technical information about any component, refer to the documentation links above or explore the `/opt/asw/docs/` directory.