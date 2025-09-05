# Hybrid Vault System - Usage Guide

## ✅ System Ready!

Your framework now supports **hybrid vault architecture** with automatic context switching.

## 🔐 Architecture Overview

### Single Service Account Token
- **Location**: Environment variable `OP_SERVICE_ACCOUNT_TOKEN` (current)
- **Alternative**: `/opt/asw/.secrets/op-service-account-token` (optional file)
- **Access**: Can access all vaults based on permissions you set in 1Password

### Automatic Vault Selection

#### Server-Level Vaults (Framework Operations)
```bash
# Working in core framework
cd /opt/asw/agentic-framework-core
get_secret "SSH-Key" → Infrastructure-Secrets vault

# Working in security framework  
cd /opt/asw/agentic-framework-security
get_secret "GitHub-Token" → Framework-Secrets vault

# Working in dev framework
cd /opt/asw/agentic-framework-dev
get_secret "Docker-Registry" → Developer-Environment-Secrets vault
```

#### Project-Level Vaults (Client Isolation)
```bash
# JavaScript project (auto-detected from package.json)
cd /path/to/my-nextjs-app
get_secret "API-Key" → MyNextjsApp-Secrets vault

# Python project (auto-detected from requirements.txt)
cd /path/to/python-project  
get_secret "Database-URL" → PythonProject-Secrets vault

# Custom vault (explicit configuration)
cd /path/to/client-project
echo 'VAULT_NAME="BigCorp-SpecialProject"' > .vault-config
get_secret "API-Key" → BigCorp-SpecialProject vault

# Client-specific project
echo 'CLIENT_NAME="AcmeCorp"' > .client-config
get_secret "API-Key" → AcmeCorp-ClientProject-Secrets vault
```

## 🚀 Quick Start

### 1. Update Your Service Account Token
```bash
# Update the environment variable with your new token
export OP_SERVICE_ACCOUNT_TOKEN="ops_YOUR_NEW_TOKEN_HERE"

# Or create the token file (optional)
echo 'ops_YOUR_NEW_TOKEN_HERE' | sudo tee /opt/asw/.secrets/op-service-account-token
sudo chmod 600 /opt/asw/.secrets/op-service-account-token
```

### 2. Set Up Your Vaults in 1Password
Create these vaults and grant your service account access:

**Server-Level:**
- `Infrastructure-Secrets` - SSH keys, server certificates, monitoring tokens
- `Framework-Secrets` - GitHub tokens, NPM tokens, CI/CD keys  
- `Developer-Environment-Secrets` - Docker registry, development tools

**Project-Level:**
- `{ProjectName}-Secrets` - Auto-created based on your project names
- `{ClientName}-{ProjectName}-Secrets` - For multi-client setups

### 3. Using the System

#### Source the Enhanced Manager
```bash
# In your scripts
source /opt/asw/enhanced-vault-context-manager.sh

# Get secrets with automatic vault detection
get_secret "API-Key"
get_secret "Database-URL" "username"  
get_secret "Secret-Item" "password" "Custom-Vault"  # Override vault

# List available items in current context
list_vault_items

# Show current context
show_context
```

#### Create Project Configurations
```bash
# For a client project
cd /path/to/project
create_vault_config "ClientName-ProjectName-Secrets" "ClientName"

# For a personal project  
create_vault_config "MyProject-Secrets"
```

## 📋 Vault Naming Conventions

- **Server vaults**: `Infrastructure-Secrets`, `Framework-Secrets`, `Developer-Environment-Secrets`
- **Project vaults**: `{ProjectName}-Secrets` (auto-generated from package.json name)
- **Client vaults**: `{ClientName}-{ProjectName}-Secrets`
- **Custom vaults**: Whatever you specify in `.vault-config`

## 🔧 Integration with Framework Scripts

Framework scripts will automatically use appropriate server-level vaults:
```bash
# Core framework scripts → Infrastructure-Secrets
/opt/asw/agentic-framework-core/scripts/setup.sh

# Security scripts → Framework-Secrets  
/opt/asw/agentic-framework-security/lib/setup.sh

# Dev scripts → Developer-Environment-Secrets
/opt/asw/agentic-framework-dev/lib/projects/create-project.sh
```

## 🎯 Benefits

✅ **Single token management** - One service account token for everything
✅ **Perfect isolation** - Projects can't access each other's secrets  
✅ **Automatic detection** - No manual configuration for most cases
✅ **Flexible override** - Custom vaults when needed
✅ **Server operations** - Framework operations use shared server vaults
✅ **Client separation** - Multiple clients can't see each other's secrets

## 🔍 Troubleshooting

```bash
# Check what vault would be used
show_context

# Test vault access
list_vault_items

# Override vault for testing
get_secret "test-item" "password" "Infrastructure-Secrets"

# Debug token
echo "Token set: ${OP_SERVICE_ACCOUNT_TOKEN:+YES}"
```

Your hybrid vault system is ready! 🎉