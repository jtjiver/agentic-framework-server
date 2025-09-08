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

## 🔄 Integrating Existing Projects

### Cloning & Integrating a GitHub Project

Have an existing project you want to integrate with the Agentic Framework? Here's how:

#### Example: Integrating an Existing Next.js App

```bash
# 1. Navigate to your projects directory
cd /opt/asw/projects/personal/

# 2. Clone your existing project
git clone https://github.com/yourusername/my-existing-app.git
cd my-existing-app

# 3. Set up vault configuration for the project
source /opt/asw/agentic-framework-security/lib/shared/vault-context-manager.sh
create_vault_config "MyExistingApp-Secrets"

# 4. Create vault helper for easier secret management
/opt/asw/scripts/setup-project-vault.sh MyExistingApp .

# 5. Migrate existing .env files to 1Password
# If you have a .env file with secrets:
cat .env  # Review your secrets
# Then add each to 1Password:
create_secret "DATABASE_URL" "url" "postgresql://..."
create_secret "STRIPE_KEY" "key" "sk_live_..."

# 6. Create a secure .env loader (optional)
cat > load-env.sh << 'EOF'
#!/bin/bash
source /opt/asw/agentic-framework-security/lib/shared/vault-context-manager.sh
export DATABASE_URL=$(get_secret "DATABASE_URL" "url")
export STRIPE_KEY=$(get_secret "STRIPE_KEY" "key")
echo "✅ Environment loaded from vault"
EOF
chmod +x load-env.sh

# 7. Update .gitignore to exclude sensitive files
echo -e "\n# Agentic Framework\n.vault-config\nload-env.sh\n.env*" >> .gitignore

# 8. Run your project with secure secrets
source load-env.sh
npm run dev  # or your usual start command
```

### Example: Integrating a Python Flask API

```bash
cd /opt/asw/projects/personal/

# Clone and enter project
git clone https://github.com/yourusername/flask-api.git
cd flask-api

# Set up framework integration
source /opt/asw/agentic-framework-security/lib/shared/vault-context-manager.sh
create_vault_config "FlaskAPI-Secrets"

# Create Python-friendly secret loader
cat > config.py << 'EOF'
import subprocess
import json

def get_secret(item_name, field_name="password"):
    """Get secret from 1Password vault"""
    cmd = f"source /opt/asw/agentic-framework-security/lib/shared/vault-context-manager.sh && get_secret '{item_name}' '{field_name}'"
    result = subprocess.run(cmd, shell=True, capture_output=True, text=True, executable='/bin/bash')
    return result.stdout.strip()

# Load your secrets
DATABASE_URL = get_secret("DATABASE_URL", "url")
API_KEY = get_secret("API_KEY", "key")
SECRET_KEY = get_secret("SESSION_SECRET", "value")
EOF

# Update your Flask app to use the secure config
# In app.py or wherever you initialize Flask:
# from config import DATABASE_URL, API_KEY, SECRET_KEY
```

### Quick Integration Checklist

For any existing project you want to integrate:

1. **Clone to `/opt/asw/projects/`** - Keep everything organized
   ```bash
   cd /opt/asw/projects/personal/  # or clients/ or experiments/
   git clone <your-repo-url>
   ```

2. **Set up vault configuration** - Project-specific secrets
   ```bash
   source /opt/asw/agentic-framework-security/lib/shared/vault-context-manager.sh
   create_vault_config "ProjectName-Secrets"
   ```

3. **Migrate secrets to 1Password** - Move from .env files
   ```bash
   # Use create_secret or the 1Password UI to add secrets
   create_secret "SECRET_NAME" "field" "value"
   ```

4. **Create language-specific loaders** - Based on your stack
   - Node.js: Shell script that exports env vars
   - Python: Config module using subprocess
   - Go: Use `os/exec` to call vault scripts
   - Ruby: Use backticks or `Open3.popen3`

5. **Update .gitignore** - Exclude sensitive files
   ```bash
   echo ".vault-config" >> .gitignore
   ```

### Working with Different Project Types

#### Docker Compose Projects
```bash
# Create docker-compose override for local dev
cat > docker-compose.override.yml << 'EOF'
version: '3'
services:
  app:
    env_file:
      - .env.local  # Generated from vault
EOF

# Generate .env.local from vault before running
source vault-helper.sh
echo "DB_URL=$(project_get_secret 'DATABASE_URL' 'url')" > .env.local
docker-compose up
```

#### Monorepo Projects
```bash
# Set up vault config at monorepo root
cd /opt/asw/projects/personal/my-monorepo
create_vault_config "Monorepo-Secrets"

# Each package can access the same vault
cd packages/api && get_secret "API_DB_URL"
cd ../frontend && get_secret "FRONTEND_API_KEY"
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