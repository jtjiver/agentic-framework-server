#!/bin/bash
# Compatibility wrapper - will forward to create-project-local.sh when ready
echo "⚠️  This script is deprecated. Use:"
echo "   /opt/asw/agentic-framework-dev/lib/projects/create-project-local.sh"
echo ""
echo "Falling back to basic project creation..."
exec /opt/asw/agentic-framework-dev/lib/projects/create-project-basic.sh "$@"