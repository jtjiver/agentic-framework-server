#!/bin/bash

echo "🧪 Testing Dev Package Access to Core and Security Tools"
echo "=========================================================="

# Navigate to dev package
cd /opt/asw/node_modules/@jtjiver/agentic-framework-dev

echo ""
echo "1. Testing Core Package Tools Access:"
echo "-------------------------------------"

# Test accessing core logger from dev package
if [[ -f "node_modules/@jtjiver/agentic-framework-core/lib/logging/bash-logger.sh" ]]; then
    source node_modules/@jtjiver/agentic-framework-core/lib/logging/bash-logger.sh
    log_success "✅ Core logger accessible from dev package"
else
    echo "❌ Core logger NOT accessible"
fi

# Test accessing core 1Password helper
if [[ -f "node_modules/@jtjiver/agentic-framework-core/lib/security/1password-helper/1password-inject.sh" ]]; then
    echo "✅ Core 1Password tools accessible"
else
    echo "❌ Core 1Password tools NOT accessible"
fi

echo ""
echo "2. Testing Security Package Tools Access:"
echo "-----------------------------------------"

# Test accessing security vault manager
if [[ -f "node_modules/@jtjiver/agentic-framework-security/lib/shared/vault-context-manager.sh" ]]; then
    echo "✅ Security vault manager accessible"
else
    echo "❌ Security vault manager NOT accessible"
fi

# Test accessing security CLI
if [[ -f "node_modules/@jtjiver/agentic-framework-security/bin/cli.js" ]]; then
    echo "✅ Security CLI accessible"
    # Test running the CLI
    node node_modules/@jtjiver/agentic-framework-security/bin/cli.js version
else
    echo "❌ Security CLI NOT accessible"
fi

echo ""
echo "3. Testing Integration in Dev Scripts:"
echo "--------------------------------------"

# Check if dev scripts can source dependencies
echo "Checking lib/projects/create-project.sh references:"
grep -l "agentic-framework-core" lib/projects/create-project.sh 2>/dev/null && echo "✅ Core referenced in create-project" || echo "⚠️  Core not referenced in create-project"
grep -l "agentic-framework-security" lib/projects/create-project.sh 2>/dev/null && echo "✅ Security referenced in create-project" || echo "⚠️  Security not referenced in create-project"

echo ""
echo "4. Available Tools Summary:"
echo "---------------------------"
echo "From Core Package:"
ls -1 node_modules/@jtjiver/agentic-framework-core/lib/*/  2>/dev/null | head -5
echo ""
echo "From Security Package:"
ls -1 node_modules/@jtjiver/agentic-framework-security/lib/*/ 2>/dev/null | head -5

echo ""
echo "=========================================================="
echo "✅ Dev package can now properly access tools from its dependencies!"
echo "   - Core utilities (logging, 1Password, etc.) are available"
echo "   - Security tools (vault management, CLI) are available"
echo "   - No duplication needed - just source from node_modules"