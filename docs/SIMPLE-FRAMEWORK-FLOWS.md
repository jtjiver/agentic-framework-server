# Simple Framework Flows & Examples

## 🚀 Quick Start: Which Use Case Are You?

```
┌─────────────────────────────────────┐
│ What are you trying to do?         │
└─────────────┬───────────────────────┘
              │
              ▼
    ┌─────────────────────┐
    │ Managing a VPS?     │
    └─────┬───────────┬───┘
          │ YES       │ NO
          ▼           ▼
    ┌─────────────┐   └─► USE CASE 2: Project-Only
    │Multiple     │       📁 Files in project directory  
    │Projects?    │       🔐 Project-specific vault
    └──┬─────┬────┘       🤖 Claude in project folder
       │ YES │ NO
       ▼     ▼
USE CASE 3: USE CASE 1:
Full VPS    Server-Only
📁 /opt/asw/ 📁 /opt/asw/
🔐 All vaults 🔐 Infra vault
🤖 Containers 🤖 System mgmt
```

## 📋 Use Case Examples

### Example 1: DevOps Managing VPS (Server-Only)
**Scenario**: You manage a VPS and need monitoring, backups, security

```bash
# Install framework on VPS
sudo mkdir -p /opt/asw
cd /opt/asw
npm install -g @jtjiver/agentic-framework-core
npm install -g @jtjiver/agentic-framework-security

# Configure server vault
source /opt/asw/agentic-framework-security/lib/shared/vault-context-manager.sh
get_secret "SSH-Private-Key"  # → Infrastructure-Secrets

# Files live in:
/opt/asw/.secrets/           # Service tokens
/opt/asw/config/            # Server configs
~/.bashrc                   # User environment
```

### Example 2: Developer Working on App (Project-Only)
**Scenario**: You're building a Next.js app and need project secrets

```bash
# In your project directory
cd ~/my-awesome-app

# Install framework tools locally
npm install @jtjiver/agentic-framework-security

# Set up project vault
echo 'VAULT_NAME="MyAwesomeApp-Secrets"' > .vault-config

# Get project secrets
source node_modules/@jtjiver/agentic-framework-security/lib/shared/vault-context-manager.sh
get_secret "DATABASE_URL"    # → MyAwesomeApp-Secrets

# Files live in:
~/my-awesome-app/.vault-config    # Project vault config
~/my-awesome-app/.env.local       # Environment variables
~/.config/op/                     # 1Password CLI
```

### Example 3: Claude Code Config Only
**Scenario**: You just want Claude Code configuration without other framework components

```bash
# Set up project directory
PROJECT_DIR=test
echo ${PROJECT_DIR}
mkdir ${PROJECT_DIR} && cd ${PROJECT_DIR} && pwd

# Clone the Claude config
git clone https://github.com/jtjiver/agentic-claude-config.git 

# Run setup scripts
./agentic-claude-config/cli/prereq-check.sh
./agentic-claude-config/cli/configure-claude.sh

# Set up ElevenLabs API key (if using TTS)
# If .env doesn't exist:
# echo "ELEVENLABS_API_KEY=$(op item get "elevenlabs - API - claude-code" --vault "TennisTracker-Dev-Vault" --fields label=credential --reveal)" > .env

# If .env exists, update the key:
sed -i '' "s/^ELEVENLABS_API_KEY=.*/ELEVENLABS_API_KEY=$(op item get "elevenlabs - API - claude-code" --vault "TennisTracker-Dev-Vault" --fields label=credential --reveal)/" .env

# Verify setup
# more .env

# Test with TTS feedback
claude -p "will it rain"
```

### Example 4: Agency with Multiple Clients (Full VPS)
**Scenario**: You host multiple client projects in containers

```bash
# Set up full framework on VPS
cd /opt/asw
npm install -g @jtjiver/agentic-framework-core
npm install -g @jtjiver/agentic-framework-security  
npm install -g @jtjiver/agentic-framework-dev

# Create client project in container
./node_modules/.bin/af-create-project acme-webapp --template=nextjs-typescript

# Access client-specific secrets
cd /opt/asw/projects/acme-webapp/workspace
source /opt/asw/agentic-framework-security/lib/shared/vault-context-manager.sh
get_secret "ACME_API_KEY"    # → AcmeWebapp-Secrets

# Files live in:
/opt/asw/.secrets/                     # Shared service token
/opt/asw/projects/acme-webapp/         # Client container
/opt/asw/projects/client-b-api/        # Another client
```

## 🔄 Configuration Flows

### Flow 1: Infrastructure First
```
1. Set up VPS
   └── Install core + security packages to /opt/asw/

2. Configure infrastructure secrets  
   └── Set up Infrastructure-Secrets vault
   └── Add SSH keys, monitoring tokens

3. Add development capabilities (optional)
   └── Install dev package
   └── Set up Developer-Environment-Secrets vault

4. Create projects (optional)
   └── Use af-create-project 
   └── Each gets its own vault
```

### Flow 2: Project First  
```
1. Start in project directory
   └── Install security package locally

2. Configure project vault
   └── Create .vault-config
   └── Set up ProjectName-Secrets vault

3. Integrate with Claude Code
   └── Set up .claude/ directory
   └── Configure project-specific commands

4. Scale up (optional)  
   └── Move to VPS infrastructure
   └── Migrate to containerized setup
```

### Flow 3: Full Environment
```
1. Infrastructure setup
   └── Install all packages to /opt/asw/
   └── Configure Infrastructure-Secrets
   └── Configure Framework-Secrets  

2. Development environment
   └── Configure Developer-Environment-Secrets
   └── Set up container templates

3. Project creation
   └── Use af-create-project for each client
   └── Each gets isolated vault (Client-Project-Secrets)

4. Management
   └── Use af-manage-containers 
   └── Monitor with infrastructure tools
```

## 📂 File Location Logic

### Where Do Files Live?

**Rule**: Files live where they're **used** and **owned**:

| File Type | Location | Why |
|-----------|----------|-----|
| Framework packages | `/opt/asw/` | System-wide, sudo installed |
| Service tokens | `/opt/asw/.secrets/` | System-wide, root owned |
| Project configs | Project directory | Project-specific, user owned |
| User environment | `~/.bashrc` | User-specific settings |
| Container workspaces | `/opt/asw/projects/*/workspace/` | Isolated, container owned |

### Context Auto-Detection

The framework knows what you need based on **where you are**:

```bash
# Working directory determines context:

cd /opt/asw/agentic-framework-core
get_secret "something"  
# → Infrastructure-Secrets (server management)

cd /opt/asw/agentic-framework-security  
get_secret "something"
# → Framework-Secrets (framework management)

cd ~/my-project
get_secret "something"
# → MyProject-Secrets (project-specific)

cd /opt/asw/projects/client-app/workspace
get_secret "something"  
# → ClientApp-Secrets (container project)
```

## 🎯 Simple Decision Making

**"Where should I install the framework?"**
- Managing a server? → `/opt/asw/`
- Just working on a project? → Project directory (`npm install` locally)

**"Where do my secrets live?"**  
- Server secrets → `Infrastructure-Secrets` vault
- Framework secrets → `Framework-Secrets` vault  
- Project secrets → `ProjectName-Secrets` vault
- Client secrets → `ClientName-ProjectName-Secrets` vault

**"How do I get my secrets?"**
- `cd` to where you're working
- `source` the vault manager
- `get_secret "SECRET_NAME"` (auto-detects vault)

**Simple, location-based, predictable!** 🎉