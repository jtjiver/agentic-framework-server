# Agentic Framework Use Cases and File Patterns

## 🎯 Three Main Use Cases

### 1. Server-Only Infrastructure Management
**Who**: DevOps, system administrators, infrastructure management
**What**: VPS setup, monitoring, server maintenance, infrastructure secrets
**Where**: `/opt/asw/` as the standard framework location

### 2. Project-Only Development 
**Who**: Developers working on individual projects with Claude
**What**: Local development, project secrets, CI/CD for specific projects
**Where**: Project directory (wherever the developer is working)

### 3. Full VPS + Multiple Projects
**Who**: Full-stack teams, agencies, multi-project environments  
**What**: Complete development infrastructure with containerized projects
**Where**: `/opt/asw/` for infrastructure + project-specific locations

---

## 📁 Use Case 1: Server-Only Infrastructure

### File Locations
```
/opt/asw/                                    # Framework root (standard)
├── .secrets/
│   └── op-service-account-token            # Infrastructure service token
├── agentic-framework-core/                 # Core utilities
├── agentic-framework-security/             # Advanced security  
├── agentic-framework-infrastructure/       # Server management (if exists)
└── config/
    ├── server-monitoring.conf              # Server-wide configs
    └── infrastructure-settings.json        # Infrastructure settings

~/.bashrc                                   # User environment
~/.ssh/config                               # SSH configuration  
~/logs/                                     # User-specific logs
```

### 1Password Vaults Used
- `Infrastructure-Secrets` - SSH keys, server certificates, monitoring tokens
- `Framework-Secrets` - GitHub tokens, NPM tokens, deployment keys

### Functionality Provided
✅ **Server Setup & Hardening**
✅ **Monitoring & Health Checks** 
✅ **Infrastructure Secret Management**
✅ **Framework Updates & Maintenance**
✅ **System-wide Security Scanning**

### Example Commands
```bash
# Setup server infrastructure
cd /opt/asw && ./scripts/setup-infrastructure.sh

# Monitor server health  
asw-health-check

# Manage infrastructure secrets
source /opt/asw/agentic-framework-security/lib/shared/vault-context-manager.sh
get_secret "SSH-Private-Key"  # → Infrastructure-Secrets vault
```

---

## 📁 Use Case 2: Project-Only Development

### File Locations  
```
/path/to/my-project/                        # Project root (anywhere)
├── .vault-config                          # Project vault configuration
├── .client-config                         # Client information (optional)
├── .env.local                             # Project environment variables
├── .claude/                               # Claude Code configuration
└── package.json                           # Project definition

~/.local/bin/                              # User-installed framework tools
~/.config/op/                              # 1Password CLI config
```

### 1Password Vaults Used
- `MyProject-Secrets` - Database URLs, API keys, project-specific secrets
- `ClientName-ProjectName-Secrets` - Client-isolated project secrets

### Functionality Provided  
✅ **Project Secret Management**
✅ **Claude Code Integration**
✅ **Development Environment Setup**
✅ **Project-specific CI/CD**
✅ **Local Security Scanning**

### Example Commands
```bash
# In project directory
cd /path/to/my-project

# Setup project vault
source /opt/asw/agentic-framework-security/lib/shared/vault-context-manager.sh
create_vault_config "MyProject-Secrets"

# Get project secrets (auto-detects vault)
get_secret "DATABASE_URL"  # → MyProject-Secrets vault

# Use Claude Code with project context
claude  # Uses .claude/ config
```

---

## 📁 Use Case 3: Full VPS + Multiple Projects

### File Locations
```
/opt/asw/                                   # Framework infrastructure
├── .secrets/
│   └── op-service-account-token           # Shared service token
├── agentic-framework-core/                # Core utilities
├── agentic-framework-security/            # Vault management
├── agentic-framework-dev/                 # Container management
└── projects/                              # Managed project containers
    ├── client-a-webapp/
    │   ├── workspace/                     # Project files
    │   ├── .vault-config                  # Project vault config
    │   └── docker-compose.yml             # Container definition
    └── client-b-api/
        ├── workspace/                     # Project files  
        └── .client-config                 # Client-specific config

/home/cc-user/                             # Developer home
├── .bashrc                                # Environment with framework aliases
└── .ssh/                                  # SSH keys for git access
```

### 1Password Vaults Used
- `Infrastructure-Secrets` - Server management, SSH keys
- `Framework-Secrets` - GitHub tokens, container registry access
- `Developer-Environment-Secrets` - Development tools, container configs
- `ClientA-Webapp-Secrets` - Client A project secrets
- `ClientB-Api-Secrets` - Client B project secrets

### Functionality Provided
✅ **Complete Infrastructure Management**
✅ **Multi-Project Container Orchestration** 
✅ **Per-Client Secret Isolation**
✅ **Centralized Development Environment**
✅ **Automated Project Creation & Management**
✅ **Integrated CI/CD Pipeline**

### Example Commands
```bash
# Create new containerized project
cd /opt/asw
./node_modules/.bin/af-create-project client-webapp --template=nextjs-typescript

# Manage project containers
./node_modules/.bin/af-manage-containers list
./node_modules/.bin/af-manage-containers start client-webapp

# Access project secrets (context auto-detected)
cd /opt/asw/projects/client-webapp/workspace
source /opt/asw/agentic-framework-security/lib/shared/vault-context-manager.sh
get_secret "API_KEY"  # → ClientWebapp-Secrets vault
```

---

## 🔄 Configuration Flow Patterns

### Pattern 1: Server-First Setup
1. Install framework to `/opt/asw/`
2. Configure infrastructure secrets in `Infrastructure-Secrets` vault
3. Set up monitoring and maintenance
4. Optionally add projects later

### Pattern 2: Project-First Setup  
1. Install framework tools to user space (`~/.local/bin/`)
2. Configure project-specific vault
3. Set up Claude Code in project
4. Optionally scale to server infrastructure later

### Pattern 3: Full Environment Setup
1. Install framework to `/opt/asw/` (infrastructure)
2. Configure all vault types (Infrastructure, Framework, Developer, Projects)  
3. Set up container orchestration
4. Create projects in managed environment

---

## 📋 Simple Decision Tree

**Q: Are you managing a VPS/server?**
- YES → Use Case 1 or 3 (files in `/opt/asw/`)
- NO → Use Case 2 (files in project directory)

**Q: Do you have multiple projects/clients?**  
- YES → Use Case 3 (container orchestration)
- NO → Use Case 1 (server-only) or 2 (project-only)

**Q: Do you need container isolation?**
- YES → Use Case 3 (dev package with containers)
- NO → Use Case 1 (infrastructure) or 2 (local development)

---

## 🎯 Key Principle: Location Determines Context

The framework automatically detects what you're doing based on **where you are**:

- **In `/opt/asw/agentic-framework-*`** → Server/Framework operations
- **In project directory with `.vault-config`** → Project-specific operations  
- **In containerized project workspace** → Container project operations

This makes it **simple and predictable** - the framework knows what you need based on your current location.