# Hybrid Vault Architecture Design

## Current Analysis ✅
The framework already has vault context switching via `vault-context-manager.sh`!

## Proposed Hybrid Architecture

### Server-Level Vaults (Framework Operations)
- **`Infrastructure-Secrets`** - Server management, SSH keys, monitoring
- **`Framework-Secrets`** - GitHub tokens, NPM tokens, CI/CD keys  
- **`Developer-Environment-Secrets`** - Development tools, container registries

### Project-Level Vaults (Client/Project Isolation)
- **`{ProjectName}-Secrets`** - Auto-detected from package.json or directory
- **`{ClientName}-{ProjectName}-Secrets`** - For multi-client scenarios

## Current Context Detection Logic ✅
Already working in `vault-context-manager.sh`:
1. Infrastructure context → `Infrastructure-Secrets`
2. Dev framework context → `Developer-Environment-Secrets`  
3. Project with `.vault-config` → Custom vault name
4. Project with `package.json` → `{ProjectName}-Secrets`
5. Python projects → `{ProjectName}-Secrets`
6. Fallback → `Infrastructure-Secrets`

## Implementation Plan

### 1. Enhance Vault Context Detection
- Add better client/multi-project support
- Add framework-specific vault detection
- Improve auto-naming conventions

### 2. Update Token Management
- Single token at `/opt/asw/.secrets/op-service-account-token`
- Vault context switching for all operations
- Proper fallback handling

### 3. Framework Script Integration  
- Core scripts use `Infrastructure-Secrets` or `Framework-Secrets`
- Dev scripts use `Developer-Environment-Secrets`
- Project operations auto-detect appropriate vault

## Vault Usage Examples

```bash
# Framework operations (server-level)
/opt/asw/agentic-framework-core/scripts/setup.sh → Infrastructure-Secrets
/opt/asw/agentic-framework-security/lib/setup.sh → Framework-Secrets

# Development operations  
/opt/asw/agentic-framework-dev/lib/projects/create-project.sh → Developer-Environment-Secrets

# Project operations (auto-detected)
cd /path/to/my-nextjs-app && get_secret "API Key" → MyNextjsApp-Secrets
cd /path/to/client-project && get_secret "DB_URL" → ClientProject-Secrets (if .vault-config exists)
```

## Benefits
✅ Single token management
✅ Perfect secret isolation per project
✅ Shared infrastructure secrets
✅ Auto-context switching
✅ Minimal config required
✅ Already mostly implemented!