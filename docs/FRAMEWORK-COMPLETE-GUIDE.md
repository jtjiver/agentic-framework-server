# 🎯 Agentic Framework Complete Guide

## The Simple Rule: **Location = Context**

The framework automatically knows what you need based on **where you are**. No complex configuration needed!

---

## 🚀 Three Use Cases, Three Patterns

### 1️⃣ **Server Management** (DevOps/Infrastructure)
```
📁 Files: /opt/asw/ (system-wide)
🔐 Vaults: Infrastructure-Secrets, Framework-Secrets  
🎯 Focus: VPS management, monitoring, system security
```

### 2️⃣ **Project Development** (Individual Projects)
```
📁 Files: Project directory (user-owned)
🔐 Vaults: ProjectName-Secrets
🎯 Focus: Local development, project secrets, Claude integration
```

### 3️⃣ **Full Development Platform** (Teams/Agencies)
```
📁 Files: /opt/asw/ + project containers
🔐 Vaults: All vault types (server + per-project isolation)
🎯 Focus: Multi-client development with container orchestration
```

---

## 📋 Quick Start Guide

### Step 1: What Are You Doing?
- **Managing a VPS?** → Go to Step 2
- **Just developing a project?** → Skip to [Project Setup](#project-setup)

### Step 2: Multiple Projects/Clients?  
- **YES** → [Full Platform Setup](#full-platform-setup)
- **NO** → [Server-Only Setup](#server-only-setup)

---

## 🔧 Setup Instructions

### Server-Only Setup
```bash
# Install on VPS
sudo mkdir -p /opt/asw && cd /opt/asw
npm install -g @jtjiver/agentic-framework-core
npm install -g @jtjiver/agentic-framework-security

# Configure server secrets
export OP_SERVICE_ACCOUNT_TOKEN="ops_YOUR_TOKEN"

# Use it
source /opt/asw/agentic-framework-security/lib/shared/vault-context-manager.sh
get_secret "SSH-Private-Key"  # Auto-uses Infrastructure-Secrets vault
```

### Project Setup
```bash
# In your project directory  
cd ~/my-project
npm install @jtjiver/agentic-framework-security

# Configure project vault
echo 'VAULT_NAME="MyProject-Secrets"' > .vault-config

# Use it
source node_modules/@jtjiver/agentic-framework-security/lib/shared/vault-context-manager.sh
get_secret "DATABASE_URL"  # Auto-uses MyProject-Secrets vault
```

### Full Platform Setup
```bash
# Install complete framework
cd /opt/asw
npm install -g @jtjiver/agentic-framework-core
npm install -g @jtjiver/agentic-framework-security
npm install -g @jtjiver/agentic-framework-dev

# Create containerized projects
./node_modules/.bin/af-create-project client-webapp --template=nextjs-typescript

# Manage containers
./node_modules/.bin/af-manage-containers list
```

---

## 🔐 1Password Vault Strategy

### Single Service Account Token
- **One token** configured as environment variable: `OP_SERVICE_ACCOUNT_TOKEN`
- **Multiple vaults** accessed based on context
- **Automatic vault selection** - no manual specification needed

### Vault Structure
```
Infrastructure-Secrets        # Server management (SSH, certs, monitoring)
Framework-Secrets             # Framework tools (GitHub, NPM tokens)  
Developer-Environment-Secrets # Development tools (Docker, registries)
ProjectName-Secrets           # Individual project secrets
ClientName-ProjectName-Secrets # Client-isolated project secrets
```

### How It Works
```bash
# The same command, different results based on location:

cd /opt/asw/agentic-framework-core
get_secret "SSH-Key"          # → Infrastructure-Secrets

cd /opt/asw/agentic-framework-security  
get_secret "GitHub-Token"     # → Framework-Secrets

cd ~/my-project
get_secret "API-Key"          # → MyProject-Secrets

cd /opt/asw/projects/client-app/workspace
get_secret "Database-URL"     # → ClientApp-Secrets
```

---

## 📁 File Organization

### Clean, Predictable Structure
```
/opt/asw/                           # Framework packages (if using server)
├── agentic-framework-core/         # Core utilities  
├── agentic-framework-security/     # Vault management
├── agentic-framework-dev/          # Container orchestration
├── .secrets/                       # Service tokens (optional)
├── docs/                           # Documentation
└── scripts/tests/                  # Test scripts

~/project-directory/                # Project files (if project-only)
├── .vault-config                   # Project vault name
├── .client-config                  # Client info (optional)  
└── node_modules/@jtjiver/          # Framework tools (local install)
```

### Context Detection Rules
1. **In framework directories** → Server/framework operations
2. **In project with .vault-config** → Project-specific operations
3. **In container workspace** → Container project operations  
4. **Fallback** → Infrastructure operations

---

## 🎯 Key Benefits

### ✅ Simple & Predictable
- **Location determines context** - no complex config files
- **Auto-detection** - framework knows what you need
- **Consistent patterns** - same commands work everywhere

### ✅ Secure & Isolated  
- **Single token** for all operations
- **Vault isolation** - projects can't see each other's secrets
- **Proper permissions** - files owned by appropriate users

### ✅ Flexible & Scalable
- **Start simple** - begin with one use case, grow as needed
- **Mix and match** - server infrastructure + local projects
- **Container ready** - full orchestration when you need it

---

## 🔧 Common Commands

### Universal Commands (work everywhere)
```bash
# Source vault manager (adjust path as needed)
source /opt/asw/agentic-framework-security/lib/shared/vault-context-manager.sh

# Get secrets (auto-detects vault)
get_secret "SECRET_NAME"
get_secret "DATABASE_URL" "username"  # Specific field
get_secret "API_KEY" "password" "Custom-Vault"  # Override vault

# Show current context
show_context

# List available secrets
list_vault_items
```

### Server Management (when in /opt/asw/)
```bash
# System health and monitoring
asw-health-check
asw-scan  # Security scanning

# Framework updates
npm update -g @jtjiver/agentic-framework-*
```

### Container Management (full platform)
```bash
# Project lifecycle
./node_modules/.bin/af-create-project myapp --template=nextjs-typescript
./node_modules/.bin/af-manage-containers start myapp
./node_modules/.bin/af-manage-containers logs myapp
```

---

## 🎉 You're Ready!

The framework is designed to be **simple and intuitive**:

1. **Install where you need it** (system-wide or project-local)
2. **Work where you need to work** (framework auto-detects context)  
3. **Get secrets easily** (`get_secret` knows which vault to use)

**That's it!** The location-based context system handles the complexity for you.

---

## 📚 Documentation Index

- **[Use Cases & Patterns](./FRAMEWORK-USE-CASES-AND-PATTERNS.md)** - Detailed use case breakdown
- **[Simple Flows](./SIMPLE-FRAMEWORK-FLOWS.md)** - Visual flows and examples
- **[Hybrid Vault Usage](./HYBRID-VAULT-USAGE.md)** - Advanced vault management
- **[File Organization](./CLEANED-FILE-ORGANIZATION.md)** - Where files live and why

**The framework makes complex infrastructure simple through smart defaults and context awareness.** 🚀