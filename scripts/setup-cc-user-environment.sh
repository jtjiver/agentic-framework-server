#!/bin/bash
# ASW Framework - CC User Environment Setup
# Sets up consistent shell environment with tmux and dependencies

set -euo pipefail

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check if running as root or cc-user
if [[ $EUID -eq 0 ]]; then
    TARGET_USER="cc-user"
    TARGET_HOME="/home/cc-user"
    SUDO_PREFIX="sudo -u cc-user"
else
    TARGET_USER=$(whoami)
    TARGET_HOME="$HOME"
    SUDO_PREFIX=""
fi

log_info "Setting up environment for user: $TARGET_USER"

# Install required packages
log_info "Installing required packages..."
apt update -qq
apt install -y \
    tmux \
    bash-completion \
    curl \
    git \
    unzip \
    jq

log_success "Packages installed"

# Create necessary directories
log_info "Creating configuration directories..."
$SUDO_PREFIX mkdir -p "$TARGET_HOME/.config/claude-projects"
$SUDO_PREFIX mkdir -p "$TARGET_HOME/.config/1password"
$SUDO_PREFIX mkdir -p "$TARGET_HOME/.local/bin"

# Install Claude Code if not present
if [[ ! -f "$TARGET_HOME/.local/bin/claude" ]]; then
    log_info "Setting up Claude Code..."
    
    # Check if Claude Code is available system-wide
    if command -v claude >/dev/null 2>&1; then
        log_info "Found system Claude Code, linking to user directory"
        $SUDO_PREFIX ln -sf "$(which claude)" "$TARGET_HOME/.local/bin/claude"
    else
        log_warning "Claude Code not found system-wide. Please install Claude Code manually."
        # Create placeholder
        $SUDO_PREFIX touch "$TARGET_HOME/.local/bin/claude"
        $SUDO_PREFIX chmod +x "$TARGET_HOME/.local/bin/claude"
    fi
    
    # Create claude-native alias
    $SUDO_PREFIX ln -sf "$TARGET_HOME/.local/bin/claude" "$TARGET_HOME/.local/bin/claude-native"
    
    log_success "Claude Code setup complete"
else
    log_info "Claude Code already installed"
fi

# Install bashrc template
log_info "Installing bashrc configuration..."
if [[ -f "/opt/asw/templates/cc-user-bashrc-template.sh" ]]; then
    $SUDO_PREFIX cp "/opt/asw/templates/cc-user-bashrc-template.sh" "$TARGET_HOME/.bashrc"
    log_success "Bashrc configuration installed"
else
    log_warning "Bashrc template not found, skipping"
fi

# Create basic tmux configuration
log_info "Creating tmux configuration..."
$SUDO_PREFIX tee "$TARGET_HOME/.tmux.conf" > /dev/null << 'EOF'
# ASW Framework tmux configuration
set -g default-terminal "screen-256color"
set -g history-limit 10000

# Enable mouse support
set -g mouse on

# Start windows and panes at 1, not 0
set -g base-index 1
setw -g pane-base-index 1

# Prefix key
set -g prefix C-b
bind-key C-b send-prefix

# Reload config
bind r source-file ~/.tmux.conf \; display "Config reloaded!"

# Better pane splitting
bind | split-window -h
bind - split-window -v

# Pane navigation
bind h select-pane -L
bind j select-pane -D
bind k select-pane -U
bind l select-pane -R

# Status bar
set -g status-style bg=blue,fg=white
set -g status-left-length 40
set -g status-left "#[fg=green]Session: #S #[fg=yellow]#I #[fg=cyan]#P"
set -g status-right "#[fg=cyan]%d %b %R"
set -g status-justify centre

# Activity monitoring
setw -g monitor-activity on
set -g visual-activity on
EOF

log_success "Tmux configuration created"

# Create 1Password token placeholder if it doesn't exist
if [[ ! -f "$TARGET_HOME/.config/1password/token" ]]; then
    log_info "Creating 1Password token placeholder..."
    $SUDO_PREFIX touch "$TARGET_HOME/.config/1password/token"
    $SUDO_PREFIX chmod 600 "$TARGET_HOME/.config/1password/token"
    log_warning "Remember to add your 1Password service account token to ~/.config/1password/token"
fi

# Set proper ownership
if [[ $EUID -eq 0 ]]; then
    chown -R cc-user:cc-user "$TARGET_HOME/.config"
    chown -R cc-user:cc-user "$TARGET_HOME/.local"
    chown cc-user:cc-user "$TARGET_HOME/.bashrc"
    chown cc-user:cc-user "$TARGET_HOME/.tmux.conf"
fi

log_success "CC User environment setup complete!"
echo ""
echo "🚀 Next steps:"
echo "   1. Add your 1Password service account token to ~/.config/1password/token"
echo "   2. Log out and back in to load the new shell configuration"
echo "   3. Use 'claude [project-name]' to start Claude sessions with tmux"
echo ""