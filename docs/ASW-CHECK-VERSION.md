# ASW Version Checker

The `asw-check-version` script provides comprehensive version checking across the ASW Framework infrastructure.

## Overview

This script compares Git commit versions across three environments:
- **Local**: Where the script is run (e.g., your laptop with `/opt/asw`)
- **VPS**: The production server (`cc-user@152.53.136.76`)
- **GitHub**: Latest commits on default branches (public repos only)

## Usage

```bash
# Basic usage - checks all repos including VPS and projects
asw-check-version

# Skip VPS checking (faster, useful when offline)
asw-check-version --no-vps

# Skip project repositories (only check framework repos)
asw-check-version --no-projects

# Verbose output with detailed progress
asw-check-version --verbose

# JSON output for scripting
asw-check-version --json

# Combined options
asw-check-version --no-vps --no-projects --verbose
```

## Repository Types Checked

### 1. Main Repository
- `agentic-framework-server` - The parent repository containing all submodules

### 2. Submodules
- `agentic-claude-config` - Claude AI configuration
- `agentic-framework-core` - Core framework functionality
- `agentic-framework-dev` - Development tools and utilities
- `agentic-framework-infrastructure` - Infrastructure and deployment tools
- `agentic-framework-security` - Security tools and configurations

### 3. Project Repositories
- All Git repositories found in `/opt/asw/projects/`
- Each project is checked independently

## Status Meanings

| Status | Description |
|--------|-------------|
| `all_synced` | Local, VPS, and GitHub all have the same commit |
| `github_synced` | Local matches GitHub (VPS may differ) |
| `vps_synced` | Local matches VPS (GitHub may differ) |
| `outdated` | Local differs from both VPS and/or GitHub |
| `no_local` | No local Git repository found |
| `no_vps` | VPS directory doesn't exist or isn't accessible |
| `no_github` | GitHub repository not accessible (private/API limit) |
| `unknown` | Unable to determine status |

## Output Format

The script outputs a formatted table showing:
- Repository name
- Repository type (main/submodule/project)
- Local commit hash and branch
- VPS commit hash and branch (if `--no-vps` not used)
- GitHub commit hash and branch (if accessible)
- Overall status with color coding

## Color Coding

- 🟢 **Green** (`all_synced`): Everything is synchronized
- 🟡 **Yellow** (`github_synced`): Local matches GitHub
- 🔵 **Cyan** (`vps_synced`): Local matches VPS
- 🔴 **Red** (`outdated`): Local is different from remote(s)
- 🟣 **Magenta** (`no_*`): Missing access to environment
- ⚪ **White** (`unknown`): Unable to determine

## Requirements

- **uv**: Python package manager (auto-installs dependencies)
- **SSH access**: Configured SSH access to VPS with agent forwarding
- **Git**: Git must be available in PATH
- **Internet**: For GitHub API access (public repos only)

## Installation

### Automatic Installation (Recommended)

When you run the main setup script, the version checker is automatically installed:

```bash
cd /opt/asw
./setup.sh
```

This installs the command to `~/.local/bin/asw-check-version` (no sudo required).

### Manual Installation

If you want to install manually or to a different location:

```bash
# Install to user's local bin (no sudo required)
cd /opt/asw
./scripts/install-asw-check-version.sh --local

# Install system-wide (requires sudo)
sudo ./scripts/install-asw-check-version.sh

# Install to custom location
./scripts/install-asw-check-version.sh --dir /custom/path --name custom-name

# Check installation status
./scripts/install-asw-check-version.sh --check

# Uninstall
./scripts/install-asw-check-version.sh --uninstall
```

### PATH Setup

If installing to `~/.local/bin`, ensure it's in your PATH:

```bash
# Add to your shell profile (.bashrc, .zshrc, etc.)
export PATH="$HOME/.local/bin:$PATH"

# Or create a one-time alias
alias asw-check-version="$HOME/.local/bin/asw-check-version"
```

### Installation Options

The installer supports several options:

- `--local`: Install to `~/.local/bin` (no sudo required)
- `--dir DIR`: Custom installation directory
- `--name NAME`: Custom command name
- `--uninstall`: Remove the installation
- `--check`: Verify installation status

## Technical Details

### SSH Configuration
- Uses: `ssh -A -p 2222 cc-user@152.53.136.76`
- Requires SSH agent forwarding (`-A` flag)
- Times out after 10 seconds per command

### GitHub API
- Uses public GitHub API (no authentication)
- Only works with public repositories
- Rate limited to 60 requests/hour per IP

### Dependencies
Auto-installed via uv:
- `requests` - GitHub API access
- `tabulate` - Table formatting
- `colorama` - Cross-platform colored output

## Examples

### Basic Check
```bash
$ asw-check-version
ASW Framework Version Checker
Checking versions at: 2025-09-19 18:06:17

+----------------------------------+-----------+-------------------+-------------------+-------------------+---------------+
| Repository                       | Type      | Local             | VPS               | GitHub            | Status        |
+==================================+===========+===================+===================+===================+===============+
| agentic-framework-server         | main      | 7e2db907 (master) | 7e2db907 (master) | 7e2db907 (master) | all_synced    |
| agentic-framework-core           | submodule | 49a0ad3f (main)   | 49a0ad3f (main)   | N/A               | vps_synced    |
+----------------------------------+-----------+-------------------+-------------------+-------------------+---------------+

=== VERSION CHECK SUMMARY ===
Total repositories: 11
all_synced: 1
vps_synced: 5
outdated: 3
unknown: 2
```

### JSON Output
```bash
$ asw-check-version --json --no-projects
[
  {
    "repo_name": "agentic-framework-server",
    "repo_type": "main",
    "local_commit": "7e2db907",
    "local_branch": "master",
    "local_date": "2025-09-19 17:00:00 +0000",
    "vps_commit": "7e2db907",
    "vps_branch": "master",
    "vps_date": "2025-09-19 17:00:00 +0000",
    "github_commit": "7e2db907",
    "github_branch": "master",
    "github_date": "2025-09-19T17:00:00Z",
    "status": "all_synced"
  }
]
```

## Troubleshooting

### SSH Connection Issues
- Ensure SSH agent is running: `ssh-add -l`
- Test VPS connection manually: `ssh -A -p 2222 cc-user@152.53.136.76 'echo "Connected"'`
- Check SSH key access to GitHub from VPS

### GitHub API Limits
- Public repos only - private repos show "N/A"
- Rate limited to 60 requests/hour
- Use `--no-github` flag if needed (not implemented yet)

### Missing Dependencies
- Ensure `uv` is installed: `curl -LsSf https://astral.sh/uv/install.sh | sh`
- Script auto-installs Python dependencies via uv

## Future Enhancements

Potential improvements:
- GitHub token support for private repositories
- Branch comparison (not just latest commits)
- Update automation (pull latest versions)
- Webhook integration for notifications
- Configuration file support
- More detailed diff analysis