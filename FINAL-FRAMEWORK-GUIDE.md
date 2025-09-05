# 🎉 FINAL Agentic Framework Guide - Standardized on `/opt/asw/`

## 🎯 One Rule: Everything Lives in `/opt/asw/`

**Simple. Clean. Standardized.**

---

## 📁 Standard Directory Structure

```
/opt/asw/                               # Universal framework base
├── agentic-framework-core/             # Core utilities
├── agentic-framework-security/         # Vault & security management  
├── agentic-framework-dev/              # Container orchestration
├── projects/                           # ALL your projects live here
│   ├── personal/                       # Personal side projects
│   ├── clients/                        # Client projects
│   ├── experiments/                    # Quick tests & prototypes
│   └── containers/                     # Containerized projects (managed)
├── .secrets/                           # Service account tokens
├── docs/                               # Framework documentation
└── scripts/                            # Helper scripts
```

---

## 🚀 Three Use Cases, One Location

### Use Case 1: Server Management
```bash
cd /opt/asw/
# Work with framework tools, infrastructure, monitoring
```

### Use Case 2: Project Development  
```bash
cd /opt/asw/projects/personal/my-side-hustle/
# Work on your projects with full framework support
```

### Use Case 3: Client Projects (Containerized)
```bash
cd /opt/asw/
./node_modules/.bin/af-create-project clients/big-client-webapp --template=nextjs-typescript
cd /opt/asw/projects/containers/big-client-webapp/workspace/
# Work on client projects in isolated containers
```

---

## ⚡ Quick Setup for Side Projects

### 1. Create Your Project
```bash
cd /opt/asw/projects/personal/
mkdir my-awesome-startup && cd my-awesome-startup
git init
```

### 2. Set Up Project Vault
```bash
# Configure project-specific 1Password vault
source /opt/asw/agentic-framework-security/lib/shared/vault-context-manager.sh
create_vault_config "MyAwesomeStartup-Secrets"
```

### 3. Get Your Secrets
```bash
# Framework automatically detects you're in a project
get_secret "DATABASE_URL"     # → MyAwesomeStartup-Secrets vault
get_secret "STRIPE_API_KEY"   # → MyAwesomeStartup-Secrets vault
```

### 4. Work with Claude
```bash
# Claude Code works perfectly from project directory
claude
# All your .claude/ configs work as expected
```

---

## 🔐 1Password Integration (Same Token, Smart Vaults)

**Single Service Account Token:**
```bash
export OP_SERVICE_ACCOUNT_TOKEN="ops_YOUR_NEW_TOKEN"
```

**Automatic Vault Selection:**
- Working in `/opt/asw/agentic-framework-*` → `Infrastructure-Secrets` or `Framework-Secrets`
- Working in `/opt/asw/projects/personal/my-app/` → `MyApp-Secrets`  
- Working in `/opt/asw/projects/clients/client-app/` → `ClientApp-Secrets`
- Working in `/opt/asw/projects/containers/*/workspace/` → Container-specific vault

---

## 📋 Daily Workflow

### Starting a New Side Project
```bash
cd /opt/asw/projects/personal/
mkdir my-new-idea && cd my-new-idea

# Set up vault
source /opt/asw/agentic-framework-security/lib/shared/vault-context-manager.sh  
create_vault_config "MyNewIdea-Secrets"

# Initialize project
npm init -y
git init

# Work with secrets
get_secret "DATABASE_URL"
```

### Working on Existing Project
```bash
cd /opt/asw/projects/personal/existing-project/

# Secrets work automatically (context detected)
source /opt/asw/agentic-framework-security/lib/shared/vault-context-manager.sh
get_secret "API_KEY"  # Automatically uses ExistingProject-Secrets vault
```

### Managing Multiple Projects
```bash
cd /opt/asw/projects/
ls -la                          # See all your projects
cd personal/side-hustle-1/      # Work on project 1
cd ../side-hustle-2/            # Switch to project 2
cd ../../clients/big-client/    # Work on client project
```

---

## 🎯 Key Benefits

✅ **One location** - everything in `/opt/asw/`  
✅ **Smart context** - framework knows where you are  
✅ **Organized projects** - personal, clients, experiments separated  
✅ **Secure isolation** - each project gets its own vault  
✅ **Simple setup** - `mkdir` + `create_vault_config` and you're ready  
✅ **Full framework access** - all tools available from anywhere  

---

## 🎉 You're Ready for Side Hustles!

**The Complete Workflow:**
1. `cd /opt/asw/projects/personal/`
2. `mkdir new-startup && cd new-startup`  
3. `source /opt/asw/agentic-framework-security/lib/shared/vault-context-manager.sh`
4. `create_vault_config "NewStartup-Secrets"`
5. `get_secret "whatever-you-need"`
6. **Build amazing things!** 🚀

**Framework is complete, standardized, and ready to get out of your way so you can focus on building!**