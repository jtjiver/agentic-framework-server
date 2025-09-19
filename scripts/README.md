# ASW Scripts Directory

This directory contains utility scripts for the ASW Framework.

## Version Management

### asw-check-version
Comprehensive version checking across local, VPS, and GitHub environments.

**Installation:**
```bash
# Automatic (via main setup)
./setup.sh

# Manual local install
./scripts/install-asw-check-version.sh --local

# Manual system install
sudo ./scripts/install-asw-check-version.sh
```

**Usage:**
```bash
asw-check-version                    # Full check
asw-check-version --no-vps          # Skip VPS
asw-check-version --no-projects     # Framework only
asw-check-version --verbose         # Detailed output
asw-check-version --json            # JSON format
```

**Features:**
- Compares Git commits across environments
- Checks main repo + all submodules + projects
- Color-coded status indicators
- SSH-based VPS checking
- GitHub API integration
- Multiple output formats

See [docs/ASW-CHECK-VERSION.md](../docs/ASW-CHECK-VERSION.md) for full documentation.

## Server Setup & Management

### Setup Scripts
- `complete-server-setup.sh` - Full server configuration
- `complete-dev-environment-setup.sh` - Development environment
- `setup-new-server.sh` - Initial server setup
- `setup-cc-user-environment.sh` - User environment configuration

### Security & Hardening
- `apply-full-hardening.sh` - Apply security hardening
- `check-security-updates.sh` - Check for security updates
- `remove-smtp-config.sh` - Remove SMTP configuration

### Monitoring & Validation
- `check-all-phases.sh` - Validate all setup phases
- `check-phase-01-bootstrap.sh` - Bootstrap validation
- `check-phase-02-hardening.sh` - Security validation  
- `check-phase-03-dev-environment.sh` - Dev environment validation
- `server-check.sh` - General server health check
- `test-server-setup.sh` - Test server configuration

### Project Management
- `new-project.sh` - Create new project
- `new-project-with-port.sh` - Create project with port allocation
- `setup-project-env.sh` - Configure project environment
- `setup-project-vault.sh` - Set up project secrets
- `setup-static-website.sh` - Deploy static website

### Authentication & Access
- `setup-1password-interactive.sh` - Configure 1Password
- `setup-github-ssh.sh` - Set up GitHub SSH access

### Utilities
- `install-asw-aliases.sh` - Install command aliases
- `automated-server-setup.sh` - Automated setup process

## Usage Patterns

### Fresh Installation
```bash
# 1. Clone the repository
git clone <repo-url> /opt/asw
cd /opt/asw

# 2. Run main setup (includes version checker)
./setup.sh

# 3. Check installation
asw-check-version --check
```

### Daily Operations
```bash
# Check version synchronization
asw-check-version

# Create new project
./scripts/new-project.sh my-app personal

# Run health checks
./scripts/server-check.sh
```

### Maintenance
```bash
# Security updates
./scripts/check-security-updates.sh

# Validate configuration
./scripts/check-all-phases.sh

# Version management
asw-check-version --verbose
```

## Script Categories

| Category | Scripts | Purpose |
|----------|---------|---------|
| **Version Control** | `asw-check-version`, `install-asw-check-version.sh` | Version synchronization |
| **Setup** | `complete-*-setup.sh`, `setup-*.sh` | Initial configuration |
| **Security** | `apply-full-hardening.sh`, `check-security-*.sh` | Security management |
| **Validation** | `check-*.sh`, `test-*.sh` | System validation |
| **Projects** | `new-project*.sh`, `setup-project-*.sh` | Project management |
| **Authentication** | `setup-1password-*.sh`, `setup-github-*.sh` | Access management |

## Dependencies

Most scripts require:
- **Bash** (4.0+)
- **Git** 
- **SSH** access (for VPS operations)
- **uv** (for version checker)
- **Node.js/npm** (for some project scripts)
- **1Password CLI** (for vault scripts)

## Contributing

When adding new scripts:
1. Make them executable: `chmod +x script-name.sh`
2. Add usage documentation to this README
3. Follow existing naming conventions
4. Include error handling and status output
5. Test on both local and VPS environments