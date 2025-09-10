# ASW Framework - CC User Bash Configuration Template
# Auto-generated configuration for consistent shell setup across servers

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# History configuration
HISTCONTROL=ignoreboth
shopt -s histappend
HISTSIZE=2000
HISTFILESIZE=4000

# Window size checking
shopt -s checkwinsize

# Set colored prompt
case "$TERM" in
    xterm-color|*-256color) color_prompt=yes;;
esac

if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
    color_prompt=yes
fi

if [ "$color_prompt" = yes ]; then
    PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi
unset color_prompt

# Terminal title
case "$TERM" in
xterm*|rxvt*)
    PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
    ;;
esac

# Color support and aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# Standard aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

# Framework shortcuts
alias af="cd /opt/agentic-framework"
alias framework="cd /opt/agentic-framework"
alias dev="cd /opt/asw/agentic-framework-core/lib/development"
alias dev-manage="/opt/asw/agentic-framework-core/lib/development/projects/manage-containers.sh"
alias dev-create="/opt/asw/agentic-framework-core/lib/development/projects/create-project.sh"

# Enhanced Claude + tmux + 1Password + Auto-start Claude Code with multi-project support
claude() {
    local PROJECT_NAME="${1:-vps}"
    local SESSION_SUFFIX="${2:-}"
    local WORKING_DIR=$(pwd)

    # Build session name with optional suffix
    local SESSION_NAME
    if [[ -n "$SESSION_SUFFIX" ]]; then
        SESSION_NAME="${PROJECT_NAME}-claude-${SESSION_SUFFIX}"
    else
        SESSION_NAME="${PROJECT_NAME}-claude"
    fi

    # Check if tmux session already exists
    if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
        echo "🔗 Attaching to existing Claude session: $SESSION_NAME"
        tmux attach-session -t "$SESSION_NAME"
        return $?
    fi

    echo "🚀 Starting new Claude session: $SESSION_NAME"
    echo "📁 Working directory: $WORKING_DIR"

    # Handle 1Password configuration per project
    local OP_TOKEN
    local VAULT_NAME
    local PROJECT_CONFIG_DIR="$HOME/.config/claude-projects"
    local PROJECT_CONFIG_FILE="$PROJECT_CONFIG_DIR/$PROJECT_NAME"

    # Create project config directory if it doesn't exist
    mkdir -p "$PROJECT_CONFIG_DIR"

    # Check if project-specific configuration exists
    if [[ -f "$PROJECT_CONFIG_FILE" ]]; then
        echo "📁 Loading project configuration for: $PROJECT_NAME"
        source "$PROJECT_CONFIG_FILE"
    else
        # Prompt for project-specific configuration
        echo "⚙️ First time setup for project: $PROJECT_NAME"
        echo ""

        # Prompt for OP token (optional)
        echo "🔐 1Password Configuration:"
        echo "Press Enter to use default token, or paste a project-specific token:"
        read -s -p "OP Token (optional): " INPUT_TOKEN
        echo ""

        if [[ -n "$INPUT_TOKEN" ]]; then
            OP_TOKEN="$INPUT_TOKEN"
        else
            # Use default token
            OP_TOKEN=$(cat ~/.config/1password/token 2>/dev/null)
        fi

        # Prompt for vault name (optional)
        echo "📦 Vault Configuration:"
        read -p "Vault name (optional, press Enter for default): " INPUT_VAULT
        VAULT_NAME="$INPUT_VAULT"

        # Save configuration for future use
        cat > "$PROJECT_CONFIG_FILE" <<CONFIGEOF
# Configuration for project: $PROJECT_NAME
# Generated on $(date)

CONFIGEOF
        if [[ -n "$INPUT_TOKEN" ]]; then
            echo "OP_TOKEN=\"$OP_TOKEN\"" >> "$PROJECT_CONFIG_FILE"
        fi
        if [[ -n "$VAULT_NAME" ]]; then
            echo "VAULT_NAME=\"$VAULT_NAME\"" >> "$PROJECT_CONFIG_FILE"
        fi

        echo "💾 Project configuration saved to: $PROJECT_CONFIG_FILE"
    fi

    # Fallback to default token if none specified
    if [[ -z "$OP_TOKEN" ]]; then
        OP_TOKEN=$(cat ~/.config/1password/token 2>/dev/null)
    fi

    if [[ -z "$OP_TOKEN" ]]; then
        echo "❌ No 1Password token found (default or project-specific)"
        echo ""
        echo "🔧 Quick Setup Options:"
        echo "1. Run interactive setup: /opt/asw/scripts/setup-1password-interactive.sh"
        echo "2. Manual setup: echo 'ops_YOUR_TOKEN' > ~/.config/1password/token && chmod 600 ~/.config/1password/token"
        echo "3. Check documentation: /opt/asw/docs/1PASSWORD-TOKEN-SETUP-GUIDE.md"
        echo ""
        echo "💡 Get your token from: https://my.1password.com → Settings → Service Accounts"
        return 1
    fi

    echo "✅ 1Password token configured"
    if [[ -n "$VAULT_NAME" ]]; then
        echo "📦 Using vault: $VAULT_NAME"
    fi
    echo "🎯 Creating tmux session with Claude Code auto-start..."

    # Create tmux session that automatically starts Claude Code
    local VAULT_ENV=""
    if [[ -n "$VAULT_NAME" ]]; then
        VAULT_ENV="export VAULT_NAME='$VAULT_NAME'"
    fi

    tmux new-session -d -s "$SESSION_NAME" -c "$WORKING_DIR" bash -c "
        export OP_SERVICE_ACCOUNT_TOKEN='$OP_TOKEN'
        $VAULT_ENV

        echo '🔐 Claude session ready with 1Password integration!'
        echo '✅ Session: $SESSION_NAME | Project: $PROJECT_NAME'
        echo '📁 Directory: $WORKING_DIR'
        echo '💡 1Password access confirmed'
        if [[ -n '$VAULT_NAME' ]]; then
            echo '📦 Vault: $VAULT_NAME'
        fi
        echo '🚀 Auto-starting Claude Code...'
        echo ''

        # Auto-start Claude Code (use full path to avoid recursion)
        exec /home/cc-user/.local/bin/claude-native
    "

    if [ $? -eq 0 ]; then
        echo "🔗 Attaching to Claude session: $SESSION_NAME"
        tmux attach-session -t "$SESSION_NAME"
    else
        echo "❌ Failed to create tmux session"
        return 1
    fi
}

# Export PATH and environment variables
export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"

# Load 1Password token if available (with fallback hierarchy)
if [[ -f "/opt/asw/.secrets/op-service-account-token" ]]; then
    export OP_SERVICE_ACCOUNT_TOKEN=$(sudo cat /opt/asw/.secrets/op-service-account-token 2>/dev/null)
elif [[ -f "$HOME/.config/1password/token" ]]; then
    export OP_SERVICE_ACCOUNT_TOKEN=$(cat $HOME/.config/1password/token 2>/dev/null)
fi

export USE_BUILTIN_RIPGREP=0

# Load Cargo environment for uv and other Rust tools
[[ -f "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"

# ASW Framework aliases
alias 1p="/opt/asw/agentic-framework-core/lib/security/1password-monitoring/1p-session.sh"
alias tmux-session="/opt/asw/agentic-framework-core/lib/utils/tmux-session.sh"
alias tmux-help="/opt/asw/agentic-framework-core/lib/utils/tmux-help.sh"
alias af-summary="/opt/asw/agentic-framework-core/lib/utils/framework-summary.sh"
alias config-summary="/opt/asw/agentic-framework-core/lib/utils/config-summary.sh"
alias claude-native="/home/cc-user/.local/bin/claude"
alias banner="source /opt/asw/agentic-framework-core/lib/utils/login-banner.sh && show_framework_banner"
alias b="banner"

# Source ASW aliases (comprehensive command set)
if [[ -f "/opt/asw/agentic-framework-core/lib/utils/asw-aliases.sh" ]]; then
    source "/opt/asw/agentic-framework-core/lib/utils/asw-aliases.sh"
fi

# Load bash completion
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

# Framework tab completion
if [[ -f "/opt/asw/agentic-framework-core/lib/utils/bash-completion.sh" ]]; then
    source "/opt/asw/agentic-framework-core/lib/utils/bash-completion.sh"
fi

# Load enhanced login banner (full rich experience)
if [[ -f "/opt/asw/agentic-framework-core/lib/utils/login-banner.sh" ]]; then
    source "/opt/asw/agentic-framework-core/lib/utils/login-banner.sh"
    
    # Override framework root detection for our ASW setup
    detect_framework_root() {
        if [[ -f '/opt/asw/agentic-framework-core/lib/utils/framework-summary.sh' ]]; then
            echo '/opt/asw/agentic-framework-core'
            return 0
        fi
        return 1
    }
    
    # Show framework banner with 1Password status
    show_framework_banner
    
    # Show 1Password setup status
    echo ""
    # Define colors for status display
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    RED='\033[0;31m'
    BLUE='\033[0;34m'
    NC='\033[0m'
    
    if [[ -n "$OP_SERVICE_ACCOUNT_TOKEN" ]]; then
        if op vault list >/dev/null 2>&1; then
            vault_count=$(op vault list --format json 2>/dev/null | jq length 2>/dev/null || echo "unknown")
            echo -e "   ${GREEN}✅ 1Password: Connected (${vault_count} vaults accessible)${NC}"
        else
            echo -e "   ${YELLOW}⚠️  1Password: Token present but authentication failed${NC}"
        fi
    else
        echo -e "   ${RED}❌ 1Password: No token configured${NC}"
        echo -e "   ${BLUE}💡 Run: /opt/asw/scripts/setup-1password-interactive.sh${NC}"
    fi
    echo ""
fi

# Note: Welcome display handled by enhanced login banner above

# Generate dynamic container aliases if available
if [[ -f ~/.generate-container-aliases.sh ]]; then
    source ~/.generate-container-aliases.sh
fi

# Source bash aliases if they exist
if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

# Bun configuration (if installed)
if [[ -d "$HOME/.bun" ]]; then
    export BUN_INSTALL="$HOME/.bun"
    export PATH="$BUN_INSTALL/bin:$PATH"
fi