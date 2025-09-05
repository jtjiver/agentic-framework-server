# Agentic Framework Server

Server configuration and setup for the Agentic Framework at `/opt/asw/`.

## 🎯 What This Repo Contains

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

## 🏗️ Repository Structure

```
agentic-framework-server/                   # This repo
├── README.md                               # This file
├── setup.sh                               # Framework installation script
├── FINAL-FRAMEWORK-GUIDE.md               # Complete usage guide
├── docs/                                   # Documentation
├── scripts/                                # Utility scripts
│   ├── new-project.sh                     # Quick project creation
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

## 🚀 Quick Setup

### 1. Clone to /opt/asw
```bash
sudo git clone https://github.com/jtjiver/agentic-framework-server.git /opt/asw
cd /opt/asw
sudo chown -R cc-user:cc-user /opt/asw  # Set proper ownership
```

### 2. Run Setup Script
```bash
./setup.sh
```

This will:
- Clone all framework package repos
- Install NPM packages globally
- Set up project directories
- Configure permissions

### 3. Configure 1Password
```bash
# Set your service account token
export OP_SERVICE_ACCOUNT_TOKEN="ops_YOUR_TOKEN"

# Or create token file
echo 'ops_YOUR_TOKEN' > .secrets/op-service-account-token
chmod 600 .secrets/op-service-account-token
```

### 4. Create Your First Project
```bash
./scripts/new-project.sh my-awesome-project personal
cd projects/personal/my-awesome-project/
```

## 🔐 Framework Architecture

### Single Location Standard
**Everything lives in `/opt/asw/`** - no scattered files, no confusion.

### Automatic Context Detection
Framework knows what vault to use based on where you are:
- In framework directories → Server operations
- In project directories → Project-specific operations

### Hybrid Vault System
- One service account token
- Multiple vaults for perfect isolation
- Automatic vault selection

## 📚 Documentation

- **[FINAL-FRAMEWORK-GUIDE.md](./FINAL-FRAMEWORK-GUIDE.md)** - Complete usage guide
- **[docs/](./docs/)** - Detailed documentation
- **Framework Package Docs** - See installed framework directories after setup

## 🔄 Updating

### Update Server Config
```bash
cd /opt/asw
git pull origin main
```

### Update Framework Packages
```bash
./setup.sh  # Re-runs setup, updates all framework repos
```

### Update NPM Packages
```bash
npm update -g @jtjiver/agentic-framework-*
```

## 🎯 Why This Structure?

1. **Clean Separation** - Config repo stays lightweight
2. **Framework Packages** - Can be updated independently  
3. **Working Directory** - `/opt/asw/` has everything you need
4. **Git Hooks Work** - Framework packages are present for husky/security
5. **No Duplication** - Single source of truth for each component

## 🛠️ Daily Workflow

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

## 🎉 Ready to Build

The framework is designed to get out of your way. Once set up:
- Create projects quickly with `./scripts/new-project.sh`
- Get secrets easily with automatic vault detection
- Use all framework tools from anywhere in `/opt/asw/`

**Focus on building, not configuration.** 🚀