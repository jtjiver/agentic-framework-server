#!/bin/bash

# Enhanced new-project script with automatic port allocation
# Wrapper around existing new-project.sh that adds port management

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NEW_PROJECT_SCRIPT="$SCRIPT_DIR/new-project.sh"
PORT_MANAGER="/opt/asw/agentic-framework-infrastructure/bin/asw-port-manager"

# Check if new-project.sh exists
if [[ ! -f "$NEW_PROJECT_SCRIPT" ]]; then
    echo -e "${RED}Error: new-project.sh not found at $NEW_PROJECT_SCRIPT${NC}"
    exit 1
fi

# Check if port manager exists
if [[ ! -x "$PORT_MANAGER" ]]; then
    echo -e "${YELLOW}Warning: Port manager not found, proceeding without port allocation${NC}"
    # Just run the original script
    exec "$NEW_PROJECT_SCRIPT" "$@"
fi

# Get project name from arguments
PROJECT_NAME="$1"
PROJECT_TYPE="${2:-personal}"

if [[ -z "$PROJECT_NAME" ]]; then
    echo -e "${RED}Error: Project name required${NC}"
    echo "Usage: $0 <project-name> [project-type]"
    echo "Types: personal, clients, experiments (default: personal)"
    exit 1
fi

# Run the original new-project script
echo -e "${BLUE}Creating new project: $PROJECT_NAME${NC}"
"$NEW_PROJECT_SCRIPT" "$PROJECT_NAME" "$PROJECT_TYPE"

# Check if project was created successfully
PROJECT_DIR="/opt/asw/projects/$PROJECT_TYPE/$PROJECT_NAME"
if [[ ! -d "$PROJECT_DIR" ]]; then
    echo -e "${YELLOW}Warning: Project directory not found, skipping port allocation${NC}"
    exit 0
fi

# Allocate a port for the new project
echo -e "${BLUE}Allocating port for $PROJECT_NAME...${NC}"
PORT=$("$PORT_MANAGER" allocate "$PROJECT_NAME" 2>&1)

if [[ $? -eq 0 ]] && [[ -n "$PORT" ]]; then
    # Extract just the port number from output
    PORT_NUM=$(echo "$PORT" | grep -oE '[0-9]+' | tail -1)
    
    if [[ -n "$PORT_NUM" ]]; then
        echo -e "${GREEN}✓ Port $PORT_NUM allocated to $PROJECT_NAME${NC}"
        
        # Create a .port file in the project directory for reference
        echo "$PORT_NUM" > "$PROJECT_DIR/.port"
        
        echo ""
        echo -e "${GREEN}Project created successfully!${NC}"
        echo -e "  Name: ${BLUE}$PROJECT_NAME${NC}"
        echo -e "  Location: ${BLUE}$PROJECT_DIR${NC}"
        echo -e "  Port: ${BLUE}$PORT_NUM${NC}"
        echo ""
        echo "Next steps:"
        echo "  1. cd $PROJECT_DIR"
        echo "  2. npm install (or bun install)"
        echo "  3. npm run dev (will use port $PORT_NUM)"
    else
        echo -e "${YELLOW}Warning: Could not parse port number from allocation${NC}"
    fi
else
    echo -e "${YELLOW}Warning: Could not allocate port for $PROJECT_NAME${NC}"
    echo "You can manually allocate later with: asw-port-manager allocate $PROJECT_NAME"
fi

echo ""
echo -e "${BLUE}To view all port allocations:${NC} $PORT_MANAGER list"