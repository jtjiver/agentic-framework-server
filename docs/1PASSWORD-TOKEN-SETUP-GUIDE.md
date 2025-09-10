# 1Password Service Account Token Setup Guide

## 🎯 Overview
This guide provides step-by-step instructions for configuring 1Password service account tokens on your ASW Framework server for seamless vault access.

## 📋 Prerequisites
- ✅ ASW Framework server setup completed
- ✅ 1Password service account created with vault access
- ✅ SSH access to server working

## 🔧 Step-by-Step Configuration

### 1️⃣ Get Your Service Account Token

**From 1Password Console:**
1. Go to [1Password Business Console](https://my.1password.com)
2. Navigate to **Integrations** → **Service Accounts**
3. Create new service account or select existing one
4. Copy the service account token (starts with `ops_`)

### 2️⃣ Configure Token on Server

**Method 1: Direct Configuration**
```bash
# SSH to server
ssh -A -p 2222 cc-user@YOUR_SERVER_IP

# Add token to configuration file
echo 'ops_YOUR_ACTUAL_TOKEN_HERE' > ~/.config/1password/token
chmod 600 ~/.config/1password/token

# Set environment variable for current session
export OP_SERVICE_ACCOUNT_TOKEN=$(cat ~/.config/1password/token)
```

**Method 2: Using 1Password CLI on Local Machine**
```bash
# If you have 1Password CLI locally, retrieve token
op item get "Service Account Token" --fields token --reveal > /tmp/token

# Copy to server
scp -P 2222 /tmp/token cc-user@YOUR_SERVER_IP:~/.config/1password/token
ssh -A -p 2222 cc-user@YOUR_SERVER_IP "chmod 600 ~/.config/1password/token"

# Clean up local temp file
rm /tmp/token
```

### 3️⃣ Test Token Configuration

**Basic Token Test:**
```bash
# SSH to server
ssh -A -p 2222 cc-user@YOUR_SERVER_IP

# Load environment
source ~/.bashrc

# Test token is working
op vault list
```

**Expected Output:**
```
ID                          NAME                    TYPE      
abcd1234efgh5678ijkl        TennisTracker-Dev-Vault PERSONAL  
efgh5678ijkl9012mnop        Infrastructure-Secrets  PERSONAL  
```

### 4️⃣ Test Vault Access

**List Items in Specific Vault:**
```bash
# Replace with your actual vault name
op item list --vault "TennisTracker-Dev-Vault"
```

**Get Specific Item:**
```bash
# Test retrieving an item
op item get "SSH-Key" --vault "TennisTracker-Dev-Vault"
```

### 5️⃣ Verify Framework Integration

**Test ASW Framework Integration:**
```bash
# Run framework validation
validate-all

# Check 1Password status specifically
validate-core | grep -A 5 "1PASSWORD"
```

## 🔍 Troubleshooting

### Token Not Working
```bash
# Check if token file exists and has correct permissions
ls -la ~/.config/1password/token

# Check if token is loaded in environment
echo "Token loaded: ${OP_SERVICE_ACCOUNT_TOKEN:+YES}"

# Test token format (should start with ops_)
head -c 10 ~/.config/1password/token
```

### Permission Errors
```bash
# Fix file permissions
chmod 600 ~/.config/1password/token
chown cc-user:cc-user ~/.config/1password/token
```

### Vault Access Issues
```bash
# Check vault permissions in 1Password Console
# Ensure service account has access to required vaults

# Test different vault names
op vault list --format json | jq -r '.[].name'
```

## 🎯 Complete Verification Workflow

**Run this complete test sequence:**
```bash
#!/bin/bash
# Complete 1Password verification script

echo "🔍 Testing 1Password Integration..."

# 1. Check token file
if [[ -f ~/.config/1password/token ]]; then
    echo "✅ Token file exists"
else
    echo "❌ Token file missing"
    exit 1
fi

# 2. Load environment
source ~/.bashrc

# 3. Test basic connectivity
if op vault list >/dev/null 2>&1; then
    echo "✅ 1Password CLI connection working"
    vault_count=$(op vault list --format json | jq length)
    echo "   📦 Access to $vault_count vault(s)"
else
    echo "❌ 1Password CLI connection failed"
    exit 1
fi

# 4. Test framework integration
if command -v validate-core >/dev/null 2>&1; then
    echo "✅ Framework commands available"
else
    echo "⚠️  Framework commands not in PATH"
fi

# 5. Test Claude integration
if [[ -f /opt/asw/agentic-framework-core/lib/utils/login-banner.sh ]]; then
    echo "✅ Framework files accessible"
    source /opt/asw/agentic-framework-core/lib/utils/login-banner.sh
    if declare -f show_framework_banner >/dev/null; then
        echo "✅ Banner system functional"
    fi
fi

echo ""
echo "🎉 1Password integration verification complete!"
```

## ⚡ Quick Commands Reference

| Task | Command |
|------|---------|
| List vaults | `op vault list` |
| List items | `op item list --vault "VAULT_NAME"` |
| Get item | `op item get "ITEM_NAME" --vault "VAULT_NAME"` |
| Get password | `op item get "ITEM_NAME" --fields password --reveal` |
| Get token | `op item get "ITEM_NAME" --fields token --reveal` |
| Check token | `echo ${OP_SERVICE_ACCOUNT_TOKEN:+Token loaded}` |
| Reload config | `source ~/.bashrc` |

## 🔗 Related Documentation
- [README-Complete-Server-Setup.md](./README-Complete-Server-Setup.md) - Main setup guide
- [HYBRID-VAULT-USAGE.md](./HYBRID-VAULT-USAGE.md) - Advanced vault workflows
- [ASW_FRAMEWORK_SCRIPTS_SUMMARY.md](./ASW_FRAMEWORK_SCRIPTS_SUMMARY.md) - All framework commands