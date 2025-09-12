# ASW Agentic Framework - Complete Scripts & Utilities Reference

## Overview
The ASW (Agentic Secure Workflow) Framework consists of four interconnected repositories that provide a comprehensive development, deployment, and security management system for web applications.

## Framework Setup & Configuration

### Main Setup Script (`/setup.sh`)
**Purpose**: Primary framework installation script that sets up the complete ASW environment

**Key Features**:
- Multi-repository cloning and updating (core, security, dev, infrastructure)
- NPM package installation for global CLI tools
- Project directory structure creation with proper permissions
- Optional Claude configuration integration
- Git status management for ignored framework directories
- Secrets directory setup with 1Password integration

**Installation Flow**:
1. Repository validation and cloning/updating
2. Global NPM package installation
3. Directory structure creation (`projects/{personal,clients,experiments,containers}`)
4. Secrets management setup (`.secrets/` directory)
5. Permission configuration for cc-user

### Claude Code Configuration System (`agentic-claude-config/`)
**Purpose**: Golden source Claude Code configuration with project-specific customization

#### CLI Installation (`/cli/install-config.sh`)
**Advanced Features**:
- **Golden Source Architecture**: Centralized configuration with project-specific overrides
- **Directory Structure**: Organized commands into `core/`, `project/`, and `local/` directories
- **Project Validation**: Comprehensive validation to prevent self-installation
- **Backup System**: Automatic backup of existing configurations with timestamps
- **Customization Layers**: Project-wide vs developer-local customization support
- **NPM Integration**: Can run as postinstall script for automated setup

**Directory Structure Created**:
```
.claude/
├── commands/
│   ├── core/           # Framework commands (committed)
│   ├── project/        # Project-specific commands (committed)
│   └── local/          # Developer-local commands (gitignored)
├── hooks/
│   ├── project/        # Project hooks (committed)
│   └── local/          # Developer hooks (gitignored)
├── settings.json       # Claude configuration
└── .gitignore          # Excludes local/ directories
```

**Installation Validation**:
- Required file/directory verification
- Command and hook counting
- Permission setting for shell scripts
- Next steps guidance with available commands

## Repository Architecture

### 1. agentic-framework-core
**Purpose**: Project initialization, repository creation, and developer workflow management

#### Core Utilities (`/bin/`)
- **`asw`** - Main framework CLI entry point
- **`asw-init`** - Repository initialization with security profiles
- **`asw-commit`** - Secure commit workflow with validation
- **`asw-push`** - Secure push operations
- **`asw-repo-create`** - GitHub repository creation automation
- **`asw-scaffold`** - Project scaffolding system
- **`asw-scan`** - Security and code quality scanning
- **`asw-doctor.cjs`** - System health diagnostics

#### Supporting Libraries (`/lib/`)

**Dependencies Management (`/lib/dependencies/`):**
- `dependency-manager.sh` - Modular dependency management system with installer framework
- `install-trufflehog.sh` - Cross-platform security scanner installer with GitHub API integration
- `TEMPLATE-install-example.sh` - Template for creating standardized dependency installers

**Housekeeping & Cleanup (`/lib/housekeeping/`):**
- `cursor-cleanup.sh` - Comprehensive resource cleanup (SSH agents, tmux, Docker, temp dirs, zombies)
- `install-cleanup.sh` - System-wide cleanup automation installer (systemd, cron, hooks)
- `ssh-cleanup-hook.sh` - SSH session disconnect cleanup with VSCode/Cursor detection
- `trash-cleanup.sh` - Interactive trash directory management with auto-discovery

**Logging Framework (`/lib/logging/bash-logging-framework/`):**
- `bash-logger.sh` - Production-ready logging with emoji indicators and rotation
- `install.sh` - Multi-method installer (local, system, symlink, copy)
- `example.sh` - Usage examples and best practices
- `test.sh` - Logging framework test suite

**Security Tools (`/lib/security/`):**
- `1password-helper/` - Complete 1Password CLI integration suite
- `1password-monitoring/` - Session management and security monitoring
- `secret-scanner/` - TruffleHog integration and secret detection

**Utilities (`/lib/utils/`):**
- `asw-aliases.sh` - Framework command aliases and shortcuts
- `bash-completion.sh` - Tab completion for ASW commands
- `claude-native-updater.sh` - Claude Code CLI updater
- `framework-summary.sh` - Installation and health summary
- `git-with-ssh-check.sh` - Git operations with SSH validation
- `health-check.sh` - System health validation
- `login-banner.sh` - Customizable login information
- `navigation-aliases.sh` - Directory navigation shortcuts
- `ssh-refresh.sh` - SSH configuration refresh
- `update-bashrc-paths.sh` - PATH management automation
- `ssh-source.sh` - SSH environment sourcing

**Versioning (`/lib/versioning/`):**
- `bump-version.sh` - Automated version management

#### Key Features
- Repository initialization with security profiles (standard, foundational, secure)
- GitHub integration with automatic repository creation
- 1Password vault integration for credentials
- Security scanning and compliance checking
- Modular dependency management with installer templates
- Comprehensive cleanup automation (systemd, cron, SSH hooks)
- Production-ready logging framework with rotation
- Interactive development environment management

### 2. agentic-framework-infrastructure
**Purpose**: VPS server management, development server provisioning, and infrastructure automation

#### Main Executables (`/bin/`)
- **`asw-dev-server`** - Complete development server lifecycle management
- **`asw-port-manager`** - Port allocation and conflict resolution
- **`asw-nginx-manager`** - Nginx proxy configuration automation
- **`asw-dev-ssl`** - SSL certificate management (Let's Encrypt + self-signed)
- **`asw-server-check`** - Comprehensive server health monitoring
- **`asw-health-check`** - Basic server health validation
- **`asw-infra`** - Infrastructure management utilities
- **`asw-server-setup`** - Initial server provisioning

#### Supporting Libraries (`/lib/`)

**Web Gateway Management:**
- `nginx-safe-manager.sh` - Safe nginx configuration updates
- `setup-project-nginx.sh` - Per-project nginx proxy setup
- `ssl-setup-helper.sh` - SSL certificate automation
- `setup-server-nginx.sh` - Main nginx server configuration
- `setup-main-domain.sh` - Domain configuration management

**Server Setup & Management:**
- `setup-server.sh` - Complete server initialization
- `setup-cc-user.sh` - User account provisioning
- `security-hardening.sh` - Server security configuration
- `setup-docker-context.sh` - Docker environment setup

**Monitoring & Health:**
- `system-health-check.sh` - System resource monitoring
- `health-check-claude-safe.sh` - LLM-safe health checks
- `setup-email-notifications.sh` - Alert system configuration
- `setup-gmail-credentials.sh` - Gmail API integration
- `install-monitoring.sh` - Monitoring system installation

**Platform & Base Images:**
- `build-base-image.sh` - Docker base image creation

**Security Integration:**
- `vault-context-manager.sh` - 1Password vault context management
- `1password-token-manager.sh` - Token lifecycle management
- `load-security.sh` - Security library initialization

**Shared Utilities:**
- `idempotent-helpers.sh` - Reusable idempotent operations

### 3. agentic-framework-security
**Purpose**: Centralized security management, credential handling, and 1Password integration

#### Main CLI (`/bin/`)
- **`cli.js`** - Main security framework interface
- **`install.sh`** - Security library installation script
- **`update.sh`** - Security component updates

#### Security Libraries (`/lib/`)

**Core Security Components:**
- `vault-context-manager.sh` - 1Password vault session management
- `1password-token-manager.sh` - Authentication token handling

**Development Environment:**
- `container-credentials.sh` - Docker container credential injection
- `setup-development-1password.sh` - Development environment security setup

**Infrastructure Security:**
- `gmail-credentials.sh` - Gmail API credential management
- `setup-infrastructure-1password.sh` - Infrastructure credential provisioning

**Project Security:**
- `generate-env-template.sh` - Environment variable template generation
- `setup-project-1password.sh` - Per-project credential management

### 4. agentic-framework-dev
**Purpose**: Development environment automation and project templates

#### Development Utilities (`/bin/`)
- **`create-project.sh`** - New project creation automation
- **`dev-server.sh`** - Development server management
- **`manage-containers.sh`** - Docker container lifecycle management

#### Supporting Libraries (`/lib/`)

**AI Assistant Session Management (`/ai-assistant/sessions/`):**
- `claude-sessions.sh` - Comprehensive tmux session manager for VPS and containers
- `start-claude-environment.sh` - Auto-starts Claude development environment
- `deploy-to-vps.sh` - VPS deployment automation

**Bootstrap System (`/bootstrap/`):**
- `bootstrap-container.sh` - Complete container initialization with 9-phase approach
- `harden-container.sh` - Security hardening for development containers

**Project Management (`/projects/`):**
- `create-project.sh` - Advanced project creation with comprehensive validation
- Multi-template support (NextJS, Python FastAPI, Payload CMS, Universal)
- Port management with template-specific allocation
- SSL certificate automation and network configuration
- Build validation and project registration

**Monitoring (`/monitoring/`):**
- `dev-dashboard.sh` - Interactive development container management dashboard
- Container status monitoring with real-time updates
- VS Code remote development integration
- SSH port forwarding guidance

**Container Management (`/containers/`):**
- `container-manager.sh` - Advanced Docker container orchestration
- Template-based container creation
- Network and volume management
- Health monitoring and auto-recovery

## Script Interactions & Dependencies

### Primary Workflows

#### 1. New Project Creation Flow
```
asw-init → asw-repo-create → af-security init → asw-scaffold
```
- `asw-init` initializes git and applies security profile
- `asw-repo-create` creates GitHub repository
- `af-security init` sets up 1Password integration
- `asw-scaffold` applies project templates

#### 2. Development Server Provisioning
```
asw-dev-server → asw-port-manager → asw-nginx-manager → asw-dev-ssl
```
- `asw-dev-server` orchestrates the complete workflow
- `asw-port-manager` allocates ports and manages conflicts
- `asw-nginx-manager` configures reverse proxy
- `asw-dev-ssl` provisions SSL certificates

#### 3. Security Context Management
```
vault-context-manager.sh → 1password-token-manager.sh → project-specific scripts
```
- Context manager establishes 1Password session
- Token manager handles authentication
- Project scripts use authenticated context

#### 4. Infrastructure Monitoring
```
asw-server-check → system-health-check.sh → email notifications
```
- `asw-server-check` runs comprehensive diagnostics
- Health check scripts monitor resources
- Email notifications alert on issues

### Cross-Repository Dependencies

#### Infrastructure → Security
- All infrastructure scripts use security library for credential management
- SSL setup requires 1Password for certificate storage
- Email notifications use secured Gmail credentials

#### Core → Security
- Repository initialization integrates 1Password vault setup
- Commit workflows validate against security policies
- Scanning includes security compliance checks

#### Dev → Infrastructure
- Development server creation calls infrastructure port management
- Container management integrates with infrastructure monitoring

## Key Integration Points

### 1Password Vault Integration
- **Context Management**: Shared session handling across all repositories
- **Credential Storage**: Centralized secret management
- **Template Generation**: Automated .env file creation

### Port Management System
- **Conflict Detection**: Checks Docker containers and active services
- **Registry Maintenance**: JSON-based port allocation tracking
- **Firewall Integration**: Automatic UFW rule management

### Nginx Proxy System
- **Domain Management**: Automated subdomain configuration
- **SSL Integration**: Let's Encrypt certificate automation
- **Configuration Safety**: Validation and rollback capabilities

### Monitoring & Health Checks
- **Multi-layer Monitoring**: System, application, and service health
- **Alert Integration**: Email notifications via Gmail API
- **LLM-Safe Reporting**: Filtered output suitable for AI processing

## Usage Patterns

### For LLMs/AI Assistants
1. **Project Initialization**: Use `asw-init` with appropriate security profile
2. **Development Server**: Use `asw-dev-server start --https` for full provisioning
3. **Health Monitoring**: Use `asw-server-check` for system diagnostics
4. **Security Management**: Use `af-security` commands for credential handling

### For Developers
1. **Quick Start**: `asw-init` → `asw-dev-server start --https`
2. **Production Deployment**: Use infrastructure scripts for server setup
3. **Security Compliance**: Regular `asw-scan` and security updates
4. **Monitoring**: Automated health checks with email alerts

## Advanced Framework Features

### 1. Modular Dependency Management System
**Innovation**: Template-based installer framework with standardized interfaces

**Architecture**:
- Pluggable installer system via `installers/install-{dependency}.sh` pattern
- Standardized check → install → ensure workflow
- Cross-platform support with fallback mechanisms
- GitHub API integration for latest release detection
- User vs system installation with PATH management

**Usage**:
```bash
./dependency-manager.sh ensure trufflehog github-cli   # Install multiple dependencies
./dependency-manager.sh check docker                   # Check single dependency
./dependency-manager.sh list                          # Show available installers
```

### 2. Comprehensive Resource Cleanup Automation
**Innovation**: Multi-layer cleanup system with intelligent detection

**Cleanup Targets**:
- **SSH Agents**: Orphaned sockets older than 24 hours
- **Tmux Sessions**: Idle sessions with 24+ hour timeout
- **Docker Resources**: Containers (7+ days), volumes, dangling images
- **Temporary Directories**: Claude, ASW test dirs, Cursor temp files
- **Zombie Processes**: Process tree cleanup with safety mechanisms
- **VSCode/Cursor Processes**: Remote server cleanup on disconnect

**Installation Methods**:
- Systemd service with 6-hour timer
- SSH logout hooks via `.bash_logout`
- Cron job backup (hourly)
- ForceCommand SSH wrapper for immediate cleanup

### 3. Production-Ready Bash Logging Framework
**Innovation**: Structured logging with emoji indicators and automatic rotation

**Features**:
- **Multi-level Logging**: DEBUG, INFO, WARNING, ERROR, SUCCESS, ACTION
- **Automatic Rotation**: Date-based rotation with configurable retention
- **Project-Aware**: Auto-detects script names and project contexts
- **Performance Optimized**: Function caching and thread-safe operations
- **Dual Output**: Console and file logging with independent control

**Configuration System**:
- Project-specific `.logger.conf` files
- Environment variable overrides
- Auto-rotation settings
- PID logging for debugging

### 4. Interactive Development Dashboard
**Innovation**: User-friendly container management with comprehensive features

**Dashboard Capabilities**:
- Real-time container status monitoring
- Interactive menu system with numbered selection
- Multiple access methods (shell, root, logs, details, custom commands)
- Docker context management and switching
- VS Code remote development integration
- SSH port forwarding guidance with tunnel setup

**Access Patterns**:
```bash
./dev-dashboard.sh                    # Interactive menu
./dev-dashboard.sh my-container       # Direct container access
./dev-dashboard.sh --vscode-setup     # VS Code integration guide
```

### 5. Advanced Project Creation System
**Innovation**: Comprehensive validation and template-specific configuration

**Creation Workflow**:
1. **Pre-creation Validation**: Resource conflict detection across Docker/ports/domains
2. **Template-Specific Setup**: Dynamic port allocation by project type
3. **Network Configuration**: Nginx proxy with HTTP → HTTPS upgrade
4. **SSL Automation**: Let's Encrypt integration with fallback certificates
5. **Build Validation**: Template-specific functionality testing
6. **Dashboard Integration**: Project registration and metadata creation

**Template Support**:
- **NextJS TypeScript**: 4 ports (app, debug, storybook, docs)
- **Python FastAPI**: 3 ports (app, debug, docs) with OpenAPI
- **Payload CMS**: Complex setup with MongoDB integration
- **Universal**: Flexible 2-port configuration

### 6. Intelligent Session Management
**Innovation**: Cross-environment tmux orchestration with auto-discovery

**Session Types**:
- **VPS Sessions**: Persistent `vps-claude` and `vps-project` sessions
- **Container Sessions**: Auto-discovered development containers
- **Framework Integration**: Path detection across installation methods
- **Interactive Menu**: Timeout handling and quick connect options

**Auto-Discovery Features**:
- Running container detection
- Framework installation path resolution
- Tmux auto-installation in containers
- Working directory standardization

### 7. Security-First Architecture
**Innovation**: Comprehensive security integration at every layer

**Security Components**:
- **1Password Integration**: Vault context management across all scripts
- **Secret Scanning**: TruffleHog integration with automated detection
- **Container Hardening**: Security configuration for development containers
- **SSH Security**: Agent cleanup, session monitoring, key rotation reminders
- **Process Monitoring**: Zombie detection and resource monitoring

### 8. Template-Based Configuration System
**Innovation**: Golden source with project-specific customization layers

**Configuration Layers**:
- **Core Commands**: Framework-provided slash commands
- **Project Commands**: Team-shared project-specific commands
- **Local Commands**: Developer-personal commands (gitignored)
- **Hooks**: Multi-layer hook system with project/local separation

**Validation & Safety**:
- Self-installation prevention
- Comprehensive project validation
- Automatic backup with timestamps
- Dry-run preview mode

## Configuration Files
- **Port Registry**: `/opt/asw/projects/.ports-registry.json`
- **Nginx Configs**: `/etc/nginx/sites-available/`
- **SSL Certificates**: `/etc/letsencrypt/live/`
- **Project State**: `.asw-dev-server.state` (per project)
- **Security Contexts**: 1Password vault sessions
- **Logger Configs**: `.logger.conf` (per project)
- **Framework Paths**: `/opt/asw/` (standard installation)
- **Claude Configs**: `.claude/` (per project with golden source)

## Environment Requirements
- **OS**: Ubuntu/Debian Linux
- **Services**: Nginx, UFW, Certbot, Docker
- **External**: 1Password CLI, GitHub CLI
- **Network**: Domain with wildcard DNS (*.dev.domain.com)
- **Development**: tmux, Node.js, Python (version-specific per template)

## Novel Functionality Summary

**System Management**:
- Modular dependency management with cross-platform support
- Multi-layer resource cleanup automation
- Intelligent session orchestration across environments

**Development Experience**:
- Interactive dashboard with comprehensive container management
- Template-based project creation with validation
- Production-ready logging framework with structured output

**Security & Configuration**:
- Golden source configuration with customization layers
- Comprehensive security integration (1Password, secret scanning, hardening)
- SSH session management with cleanup automation

**Infrastructure Automation**:
- HTTP → HTTPS upgrade workflows
- SSL certificate automation with Let's Encrypt
- Port management with conflict detection and auto-allocation

This framework provides a complete, security-first development workflow from project inception to production deployment, with comprehensive automation, monitoring capabilities, and novel approaches to common development environment challenges.