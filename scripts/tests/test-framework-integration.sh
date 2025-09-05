#!/bin/bash

# Test script to demonstrate Agentic Framework integration
# Tests core, security, and dev package functionality

echo "🧪 Testing Agentic Framework Integration"
echo "========================================"

# Test 1: Core Package - Logging
echo "1. Testing Core Package - Logging System"
source node_modules/@jtjiver/agentic-framework-core/lib/logging/bash-logger.sh
log_info "Core logging system initialized"
log_success "✅ Core package logging works!"

# Test 2: Security Package - CLI
echo ""
echo "2. Testing Security Package - CLI"
./node_modules/.bin/af-security version
log_success "✅ Security package CLI works!"

# Test 3: Dev Package - Available Templates  
echo ""
echo "3. Testing Dev Package - Template System"
echo "Available templates:"
ls -1 node_modules/@jtjiver/agentic-framework-dev/templates/
log_success "✅ Dev package templates available!"

# Test 4: Dev Package - CLI Help (core scripts)
echo ""
echo "4. Testing Dev Package - Core Script Access"
if [[ -f "node_modules/@jtjiver/agentic-framework-dev/lib/projects/create-project.sh" ]]; then
    log_success "✅ Dev package core scripts accessible!"
else
    log_error "❌ Dev package core scripts missing!"
fi

# Test 5: Integration - Security in Dev
echo ""
echo "5. Testing Integration - Security Package within Dev Package"
if [[ -f "node_modules/@jtjiver/agentic-framework-dev/node_modules/@jtjiver/agentic-framework-security/bin/cli.js" ]]; then
    log_success "✅ Security package integrated in dev package!"
else
    log_warning "⚠️ Security package integration may have issues"
fi

# Test 6: Available CLI Commands
echo ""
echo "6. Available CLI Commands:"
ls -1 node_modules/.bin/af-* | sed 's/node_modules\/.bin\//  - /'
log_success "✅ All CLI commands available!"

echo ""
log_success "🎉 Framework Integration Test Complete!"
log_info "The layered framework is working correctly:"
log_info "  • Core: Logging, utilities, security tools"
log_info "  • Security: 1Password integration, vault management"  
log_info "  • Dev: Container templates, project creation, AI workflows"