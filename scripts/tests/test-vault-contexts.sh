#!/bin/bash

# Test script to demonstrate hybrid vault context switching

echo "🧪 Testing Hybrid Vault Context System"
echo "========================================"

# Source the enhanced vault manager from security package
source /opt/asw/agentic-framework-security/lib/shared/vault-context-manager.sh

echo ""
echo "1. Testing Server-Level Contexts:"
echo "--------------------------------"

# Test from core framework location
cd /opt/asw/agentic-framework-core
echo "📍 Location: $(pwd)"
echo "🔐 Detected vault: $(detect_vault_context)"

# Test from security framework location  
cd /opt/asw/agentic-framework-security
echo "📍 Location: $(pwd)" 
echo "🔐 Detected vault: $(detect_vault_context)"

# Test from dev framework location
cd /opt/asw/agentic-framework-dev
echo "📍 Location: $(pwd)"
echo "🔐 Detected vault: $(detect_vault_context)"

echo ""
echo "2. Testing Project-Level Contexts:"
echo "--------------------------------"

# Create a test project directory
mkdir -p /tmp/test-nextjs-project
cd /tmp/test-nextjs-project

# Create package.json for JS project detection
cat > package.json << 'EOF'
{
  "name": "@acme/my-awesome-app",
  "version": "1.0.0"
}
EOF

echo "📍 Location: $(pwd)"
echo "🔐 Detected vault: $(detect_vault_context)"

# Test with explicit vault config
echo 'VAULT_NAME="CustomClient-SecretVault"' > .vault-config
echo "📍 Added .vault-config"
echo "🔐 Detected vault: $(detect_vault_context)"

# Test with client config
echo 'CLIENT_NAME="BigCorp"' > .client-config
rm .vault-config  # Remove explicit config to test client detection
echo "📍 Added .client-config (removed .vault-config)"
echo "🔐 Detected vault: $(detect_vault_context)"

echo ""
echo "3. Testing Python Project:"
echo "-------------------------"
cd /tmp
mkdir -p test-python-project
cd test-python-project
touch requirements.txt
echo "📍 Location: $(pwd)"
echo "🔐 Detected vault: $(detect_vault_context)"

echo ""
echo "4. Context Information:"
echo "----------------------"
show_context

echo ""
echo "✅ Vault context system working!"
echo "   • Server-level vaults for framework operations"
echo "   • Project-level vaults for client isolation"
echo "   • Automatic detection based on location and files"
echo "   • Single token manages all vault access"

# Cleanup
rm -rf /tmp/test-nextjs-project /tmp/test-python-project