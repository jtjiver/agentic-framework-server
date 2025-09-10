# CC User Profile Setup

## Overview
The ASW Framework includes a standardized cc-user profile setup that provides a consistent shell environment across all servers with integrated tmux, Claude Code, and 1Password support.

## What It Includes

### Shell Configuration
- **Enhanced Bash Profile** with colored prompts and useful aliases
- **History Management** with increased size and better search
- **Comprehensive Aliases** for framework navigation and shortcuts
- **Auto-completion** for bash commands and framework utilities

### Development Environment
- **tmux Integration** with optimized configuration
- **Claude Code** with automatic project session management
- **1Password Integration** for secure credential handling
- **Project-specific Configurations** stored per project

### Framework Integration
- **ASW Framework Shortcuts** for quick navigation
- **Agentic Framework Aliases** for development tools
- **Login Banner** showing available commands
- **Dynamic Container Aliases** based on running containers

## Installation

### Automatic Installation
The cc-user profile setup is included in the full server hardening process:
```bash
sudo /opt/asw/scripts/apply-full-hardening.sh
```

### Manual Installation
To set up just the cc-user environment:
```bash
sudo /opt/asw/scripts/setup-cc-user-environment.sh
```

## Key Features

### Enhanced `claude()` Function
The profile includes a powerful `claude()` function that:
- Creates tmux sessions with automatic Claude Code startup
- Supports project-specific configurations
- Integrates with 1Password for secure token management
- Maintains separate sessions per project

**Usage:**
```bash
claude                    # Default 'vps' project
claude myproject         # Named project session
claude work dev          # Project with session suffix
```

### Tmux Configuration
- **Mouse support** enabled
- **256-color terminal** support
- **Better key bindings** for pane navigation
- **Custom status bar** with session info
- **Activity monitoring** enabled

### Directory Structure
```
/home/cc-user/
├── .bashrc                           # Main shell configuration
├── .tmux.conf                        # tmux configuration
├── .config/
│   ├── claude-projects/              # Project-specific configs
│   │   └── [project-name]           # Per-project settings
│   └── 1password/
│       └── token                    # 1Password service account token
└── .local/
    └── bin/
        ├── claude -> /usr/bin/claude    # Claude Code symlink
        └── claude-native -> claude      # Alias for direct access
```

### Available Shortcuts
After setup, the following shortcuts are available:

#### Navigation
- `af` → Navigate to agentic framework directory
- `dev` → Navigate to development tools
- `framework` → Alias for agentic framework

#### Development Tools  
- `dev-manage` → Container management interface
- `dev-create` → Create new development project
- `claude [project]` → Start Claude session with tmux

#### Framework Utilities
- `af-summary` → Show framework overview
- `config-summary` → Display system configuration
- `tmux-help` → tmux usage guide
- `1p` → 1Password session management
- `banner` → Show framework banner

## Configuration Files

### Bashrc Template Location
The template is stored at:
```
/opt/asw/templates/cc-user-bashrc-template.sh
```

### Key Configuration Sections
1. **Basic Shell Setup** - History, prompts, colors
2. **Framework Shortcuts** - Navigation and tool aliases
3. **Claude Function** - Advanced tmux + Claude integration
4. **1Password Integration** - Secure credential management
5. **Welcome Display** - Helpful command overview

## Project-Specific Configuration

### First-Time Project Setup
When you run `claude projectname` for the first time:
1. Prompts for 1Password token (optional, falls back to default)
2. Prompts for vault name (optional)
3. Saves configuration to `~/.config/claude-projects/projectname`
4. Creates tmux session with Claude Code auto-start

### Project Config Example
```bash
# Configuration for project: myproject
# Generated on 2024-01-15 10:30:00

OP_TOKEN="op_xxxxxxxxxxxx"
VAULT_NAME="MyProject-Vault"
```

## 1Password Integration

### Token Setup
1. Create a service account token in 1Password
2. Save it to the default location:
   ```bash
   echo "your_token_here" > ~/.config/1password/token
   chmod 600 ~/.config/1password/token
   ```

### Per-Project Tokens
Each project can have its own 1Password configuration, allowing for:
- Different service account tokens per project
- Project-specific vault access
- Isolated credential management

## Verification

### Check Installation
```bash
# Verify tmux is configured
tmux -V

# Check Claude Code access
claude --version

# Test framework shortcuts
af-summary --compact

# Verify 1Password integration (if token configured)
1p-status
```

### Test Claude Function
```bash
# Start a test session
claude test

# Should create tmux session with Claude Code running
# Exit with: Ctrl+B, then type 'exit'
```

## Troubleshooting

### Common Issues

#### Shell Configuration Not Loading
- **Solution**: Log out and back in, or run `source ~/.bashrc`

#### Claude Function Not Working  
- **Check**: Ensure tmux is installed: `which tmux`
- **Check**: Verify Claude Code: `which claude`
- **Check**: 1Password token: `cat ~/.config/1password/token`

#### Tmux Session Issues
- **List sessions**: `tmux list-sessions`
- **Kill stuck session**: `tmux kill-session -t session-name`
- **Reload tmux config**: `tmux source-file ~/.tmux.conf`

#### 1Password Integration Failing
- **Verify token**: Test with `op whoami` (if op CLI installed)
- **Check permissions**: `ls -la ~/.config/1password/token`
- **Token format**: Should be `op_xxxxxxxxxx` format

### Manual Fixes

#### Restore Default Configuration
```bash
# Backup current config
cp ~/.bashrc ~/.bashrc.backup

# Restore from template
sudo cp /opt/asw/templates/cc-user-bashrc-template.sh ~/.bashrc
```

#### Reset Project Configurations
```bash
# Remove all project configs
rm -rf ~/.config/claude-projects/*

# Or remove specific project
rm ~/.config/claude-projects/projectname
```

## Advanced Usage

### Custom Project Configurations
You can manually edit project configurations:
```bash
nano ~/.config/claude-projects/myproject
```

### Multiple Sessions Per Project
```bash
claude myproject main     # Main development session  
claude myproject testing  # Testing session
claude myproject debug    # Debug session
```

### Integration with Other Tools
The setup integrates with:
- **Docker containers** - Dynamic aliases for running containers
- **Git repositories** - Enhanced prompt with git status
- **Framework utilities** - All ASW and Agentic tools
- **System monitoring** - Built-in system status commands

## Security Considerations

### Token Storage
- 1Password tokens are stored with restricted permissions (600)
- Project-specific tokens isolate access
- No tokens are logged or displayed in command output

### Session Security
- tmux sessions are user-isolated
- Claude Code runs with user permissions only
- No elevated privileges required for normal operation

## Maintenance

### Updates
The profile setup is updated when:
- Running the full hardening script
- Manually running the setup script
- Framework updates include profile changes

### Backup
Important files to backup:
- `~/.config/claude-projects/` - Project configurations
- `~/.config/1password/token` - Authentication token
- Any custom modifications to `~/.bashrc`

## Integration with Framework

### Part of Hardening Process
The cc-user profile setup is automatically included in:
- `apply-full-hardening.sh` - Full server hardening
- `complete-server-setup.sh` - Complete server setup
- `setup-new-server.sh` - New server initialization

### Validation
The setup is verified as part of the security validation process, ensuring:
- Shell configuration is properly installed
- tmux is configured and functional
- Claude Code is accessible
- Framework shortcuts are available