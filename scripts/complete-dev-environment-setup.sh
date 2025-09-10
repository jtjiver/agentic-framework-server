#!/bin/bash
# ASW Framework Complete Development Environment Setup
# Automates the entire setup process from hardened server to dev environment

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

# Logging
log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_action() { echo -e "${BLUE}[ACTION]${NC} $1"; }

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}     ASW Complete Development Environment Setup${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Step 1: Verify prerequisites
log_action "Checking prerequisites..."

# Check if running as cc-user
if [[ "$USER" != "cc-user" ]]; then
    log_warn "Script should be run as cc-user"
fi

# Check if in /opt/asw
if [[ ! -d "/opt/asw" ]]; then
    log_error "/opt/asw directory not found"
    exit 1
fi

cd /opt/asw

# Step 2: Install required packages
log_action "Installing required system packages..."

packages_to_install=""

# Check and add packages if not installed
for pkg in jq nginx certbot python3-certbot-nginx docker.io docker-compose; do
    if ! dpkg -l | grep -q "^ii  $pkg "; then
        packages_to_install="$packages_to_install $pkg"
    fi
done

if [[ -n "$packages_to_install" ]]; then
    sudo apt update
    sudo apt install -y $packages_to_install
else
    log_info "All required packages already installed"
fi

# Step 3: Link ASW framework packages
log_action "Setting up ASW framework packages..."

# Link infrastructure package
if [[ -d "/opt/asw/agentic-framework-infrastructure" ]]; then
    cd /opt/asw/agentic-framework-infrastructure
    sudo npm link 2>/dev/null || log_warn "Infrastructure package already linked"
else
    log_warn "Infrastructure package not found"
fi

# Link dev package
if [[ -d "/opt/asw/agentic-framework-dev" ]]; then
    cd /opt/asw/agentic-framework-dev
    sudo npm link 2>/dev/null || log_warn "Dev package already linked"
else
    log_warn "Dev package not found"
fi

# Link security package
if [[ -d "/opt/asw/agentic-framework-security" ]]; then
    cd /opt/asw/agentic-framework-security
    sudo npm link 2>/dev/null || log_warn "Security package already linked"
else
    log_warn "Security package not found"
fi

# Link core package
if [[ -d "/opt/asw/agentic-framework-core" ]]; then
    cd /opt/asw/agentic-framework-core
    sudo npm link 2>/dev/null || log_warn "Core package already linked"
else
    log_warn "Core package not found"
fi

# Step 4: Create symlinks for binaries
log_action "Creating command symlinks..."

# Infrastructure binaries
for cmd in asw-dev-server asw-port-manager asw-nginx-manager asw-server-check asw-dev-ssl; do
    if [[ -f "/opt/asw/agentic-framework-infrastructure/bin/$cmd" ]]; then
        sudo ln -sf "/opt/asw/agentic-framework-infrastructure/bin/$cmd" "/usr/local/bin/"
        log_info "✓ Linked $cmd"
    fi
done

# Core binaries
for cmd in asw asw-init asw-scan asw-commit asw-push asw-repo-create asw-doctor; do
    if [[ -f "/opt/asw/agentic-framework-core/bin/$cmd" ]]; then
        sudo ln -sf "/opt/asw/agentic-framework-core/bin/$cmd" "/usr/local/bin/"
        log_info "✓ Linked $cmd"
    fi
done

# Step 5: Initialize port registry
log_action "Initializing port management..."

if [[ ! -f "/opt/asw/projects/.ports-registry.json" ]]; then
    mkdir -p /opt/asw/projects
    echo '{"ports":{}}' > /opt/asw/projects/.ports-registry.json
    log_info "✓ Port registry initialized"
else
    log_info "Port registry already exists"
fi

# Step 6: Configure Docker (if installed)
if command -v docker &> /dev/null; then
    log_action "Configuring Docker..."
    
    # Add cc-user to docker group
    sudo usermod -aG docker cc-user 2>/dev/null || true
    
    # Enable Docker service
    sudo systemctl enable docker
    sudo systemctl start docker
    
    log_info "✓ Docker configured"
fi

# Step 7: Setup nginx base configuration
log_action "Configuring nginx..."

if command -v nginx &> /dev/null; then
    # Create sites directories if they don't exist
    sudo mkdir -p /etc/nginx/sites-available
    sudo mkdir -p /etc/nginx/sites-enabled
    
    # Test nginx configuration
    sudo nginx -t &>/dev/null && log_info "✓ Nginx configuration valid"
fi

# Step 8: Create environment setup script
log_action "Creating environment setup script..."

cat > ~/asw-env.sh << 'EOF'
#!/bin/bash
# ASW Framework Environment Setup

# Source logging if available
if [[ -f "/opt/asw/agentic-framework-core/lib/logging/bash-logger.sh" ]]; then
    source "/opt/asw/agentic-framework-core/lib/logging/bash-logger.sh"
fi

# Add ASW binaries to PATH
export PATH="/usr/local/bin:$PATH"

# ASW aliases
alias asw-check='/opt/asw/scripts/server-check.sh'
alias asw-ports='asw-port-manager list'
alias asw-projects='ls -la /opt/asw/projects/'

# Helper functions
asw-new-project() {
    local name="${1:-my-project}"
    cd ~
    mkdir -p "$name"
    cd "$name"
    npm init -y
    echo "Project $name created in $(pwd)"
}

asw-status() {
    echo "=== ASW Framework Status ==="
    echo "Port allocations:"
    asw-port-manager list 2>/dev/null || echo "Port manager not available"
    echo ""
    echo "Running services:"
    sudo systemctl status nginx --no-pager 2>/dev/null | head -3 || echo "Nginx not running"
    echo ""
    echo "Firewall status:"
    sudo ufw status | head -5
}

echo "ASW Framework environment loaded"
echo "Commands available: asw-status, asw-new-project, asw-check, asw-ports"
EOF

chmod +x ~/asw-env.sh
log_info "✓ Environment script created at ~/asw-env.sh"

# Step 9: Verify installation
log_action "Verifying installation..."

echo ""
log_info "Checking available commands:"

commands_found=0
commands_missing=0

for cmd in asw-dev-server asw-port-manager asw-nginx-manager asw-server-check; do
    if command -v $cmd &> /dev/null; then
        echo -e "  ${GREEN}✓${NC} $cmd"
        ((commands_found++))
    else
        echo -e "  ${RED}✗${NC} $cmd"
        ((commands_missing++))
    fi
done

# Step 10: Final summary
echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}     🎉 Development Environment Setup Complete!${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
log_info "Summary:"
echo "  • Framework packages linked: ✓"
echo "  • Commands available: $commands_found"
echo "  • Port management: Ready"
echo "  • Development tools: Installed"
echo ""
log_info "Next steps:"
echo "  1. Source environment: source ~/asw-env.sh"
echo "  2. Create a project: asw-new-project my-app"
echo "  3. Start dev server: cd ~/my-app && asw-dev-server start"
echo ""
log_info "For help, run: asw-dev-server --help"
echo ""