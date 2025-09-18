# Clone & Deploy Existing Projects with ASW Infrastructure

This guide covers how to clone an existing project and get it serving to the internet using the ASW development infrastructure.

## Quick Start (TL;DR)

```bash
# Clone, setup, and serve in one go
cd /opt/asw/projects/personal
git clone <repository-url> <project-name>
cd <project-name>
bun install
/opt/asw/agentic-framework-infrastructure/bin/asw-dev-server start --no-nginx --logs
```

Your app will be available at `http://<server-ip>:<allocated-port>`

## Detailed Steps

### Step 1: Clone the Repository

Choose the appropriate project category:
- `/opt/asw/projects/personal` - Personal projects
- `/opt/asw/projects/clients` - Client projects  
- `/opt/asw/projects/experiments` - Experimental projects

```bash
cd /opt/asw/projects/personal
git clone <repository-url> <project-name>
cd <project-name>
```

### Step 2: Install Dependencies & Setup Environment

#### Install Project Dependencies
```bash
# For Bun projects (recommended)
bun install

# For NPM projects
npm install

# For Yarn projects
yarn install
```

#### Setup Environment Variables (if using 1Password)
```bash
# Inject secrets from .env.template files
/opt/asw/agentic-framework-core/lib/security/1password-helper/1password-inject.sh .env.local.template

# Or manually copy and edit
cp .env.example .env.local
```

### Step 3: Allocate Port for the Project

The ASW port manager handles port allocation across all projects:

```bash
# Auto-allocate next available port (3000-3099 range)
/opt/asw/agentic-framework-infrastructure/bin/asw-port-manager allocate <project-name>

# Or request a specific port
/opt/asw/agentic-framework-infrastructure/bin/asw-port-manager allocate <project-name> 3005

# Check allocated port
/opt/asw/agentic-framework-infrastructure/bin/asw-port-manager get <project-name>

# View all port allocations
/opt/asw/agentic-framework-infrastructure/bin/asw-port-manager list
```

### Step 4: Start Server with ASW Dev Server Manager

The ASW dev server manager handles everything automatically:
- Opens firewall ports
- Configures network binding
- Sets up optional nginx proxy
- Manages server lifecycle

#### Option A: Direct Port Access (Development)
```bash
# Start with direct port access
/opt/asw/agentic-framework-infrastructure/bin/asw-dev-server start --no-nginx

# Start with live logs (foreground mode)
/opt/asw/agentic-framework-infrastructure/bin/asw-dev-server start --no-nginx --logs
```

Access at: `http://<server-ip>:<port>` (e.g., `http://152.53.136.76:3000`)

#### Option B: With Subdomain (Production-like)
```bash
# Start with nginx reverse proxy and automatic subdomain
/opt/asw/agentic-framework-infrastructure/bin/asw-dev-server start

# With custom domain
/opt/asw/agentic-framework-infrastructure/bin/asw-dev-server start --domain custom-name.8020perfect.com
```

Access at: `http://<project-name>.8020perfect.com`

#### Option C: With HTTPS/SSL (Secure Development)
```bash
# Start with HTTPS and self-signed certificate
/opt/asw/agentic-framework-infrastructure/bin/asw-dev-server start --https

# Custom domain with HTTPS
/opt/asw/agentic-framework-infrastructure/bin/asw-dev-server start --https --domain secure-app.8020perfect.com
```

Access at: `https://<project-name>.8020perfect.com` (accept self-signed certificate warning)

### Step 5: Access Your Application

Once started, your application is accessible from:

- **Local access**: `http://localhost:<port>`
- **Network access**: `http://<server-ip>:<port>`
- **Subdomain access**: `http://<project-name>.8020perfect.com`
- **HTTPS access**: `https://<project-name>.8020perfect.com` (with --https flag)

### Subdomain System (8020perfect.com) - ✅ ACTIVE

✅ **Domain Status**: The 8020perfect.com domain is fully operational on this server.

The ASW infrastructure automatically creates subdomains with SSL certificates:
- `<project-name>.8020perfect.com` → Proxies to `localhost:<allocated-port>`
- **Working Examples**:
  - `https://n8n.8020perfect.com` → `localhost:5678`
  - `https://monitor.dev.8020perfect.com` → `localhost:3001`
  - `https://beszel.dev.8020perfect.com` → `localhost:8080`

**Access Options**:
- Direct IP: `http://152.53.136.76:<port>`
- HTTP Subdomain: `http://<project-name>.8020perfect.com`
- **HTTPS Subdomain: `https://<project-name>.8020perfect.com`** ⭐

#### SSL Certificate Management - ✅ FULLY AUTOMATED
- **Let's Encrypt certificates** automatically provisioned
- **No browser warnings** - trusted certificates
- **Automatic renewal** via certbot
- **Zero configuration required** - handled by ASW dev server

## Management Commands

### Server Management
```bash
# Check server status
/opt/asw/agentic-framework-infrastructure/bin/asw-dev-server status

# Stop the server
/opt/asw/agentic-framework-infrastructure/bin/asw-dev-server stop

# Restart the server
/opt/asw/agentic-framework-infrastructure/bin/asw-dev-server restart

# Complete cleanup (removes port allocation, firewall rules, nginx config)
/opt/asw/agentic-framework-infrastructure/bin/asw-dev-server teardown
```

### Port Management
```bash
# View all port allocations
/opt/asw/agentic-framework-infrastructure/bin/asw-port-manager list

# Check if a port is in use
/opt/asw/agentic-framework-infrastructure/bin/asw-port-manager check 3000

# Release a port allocation
/opt/asw/agentic-framework-infrastructure/bin/asw-port-manager release <project-name>
```

### Viewing Logs
```bash
# View server logs
tail -f /opt/asw/projects/<category>/<project-name>/asw-dev-server.log

# View last 100 lines
tail -n 100 /opt/asw/projects/<category>/<project-name>/asw-dev-server.log
```

## Framework-Specific Notes

### Next.js Projects
```bash
# Ensure bun is installed
curl -fsSL https://bun.sh/install | bash
source ~/.bashrc

# The dev server will automatically run in network mode
```

### Vite/React Projects
```bash
# May need to configure vite.config.js for network access
# The ASW dev server handles this automatically
```

### Express/Node.js Projects
```bash
# Ensure the app listens on 0.0.0.0 for network access
# The ASW dev server configures HOST environment variable
```

## Troubleshooting

### Port Already in Use
```bash
# Check what's using the port
/opt/asw/agentic-framework-infrastructure/bin/asw-port-manager check <port>

# Kill processes on port and restart
/opt/asw/agentic-framework-infrastructure/bin/asw-dev-server stop
/opt/asw/agentic-framework-infrastructure/bin/asw-dev-server start --no-nginx
```

### Firewall Issues
```bash
# The ASW dev server automatically manages firewall rules
# To verify firewall status:
sudo ufw status

# Manual check (not recommended, use ASW tools instead)
sudo ufw status numbered | grep <port>
```

### Can't Access from Browser
1. Verify server is running: `asw-dev-server status`
2. Check firewall opened: `sudo ufw status | grep <port>`
3. Test local access: `curl http://localhost:<port>`
4. Check server logs: `tail -f asw-dev-server.log`

## Best Practices

1. **Always use ASW tools** - Don't manually modify firewall or ports
2. **Check port allocation first** - `asw-port-manager list`
3. **Use project categories** - Keep projects organized in personal/clients/experiments
4. **Clean up when done** - Use `asw-dev-server teardown` for unused projects
5. **Use environment files** - Keep secrets in `.env.local`, never commit them

## Example: Complete Setup for Tennis Tracker

```bash
# 1. Clone the repository
cd /opt/asw/projects/personal
git clone https://github.com/example/tennis-tracker.git
cd tennis-tracker

# 2. Install dependencies
bun install

# 3. Setup environment
/opt/asw/agentic-framework-core/lib/security/1password-helper/1password-inject.sh .env.local.template

# 4. Start the server (auto-allocates port, opens firewall, starts in network mode)
/opt/asw/agentic-framework-infrastructure/bin/asw-dev-server start --no-nginx --logs

# Your app is now accessible at http://<server-ip>:3000
```

## Server Information

### Available Servers (VPS)
- **Netcup**: `ssh -A -p 2222 cc-user@152.53.136.76`
- **Digital Ocean**: `ssh -A -p 2222 cc-user@209.97.139.211`

### Port Range
- Development ports: 3000-3099
- Automatically managed by ASW infrastructure

### Default Domain
- Pattern: `<project-name>.8020perfect.com`
- Configured via nginx reverse proxy

## Additional Resources

- Port Manager: `/opt/asw/agentic-framework-infrastructure/bin/asw-port-manager --help`
- Dev Server: `/opt/asw/agentic-framework-infrastructure/bin/asw-dev-server --help`
- 1Password Inject: `/opt/asw/agentic-framework-core/lib/security/1password-helper/1password-inject.sh --help`

---

*Last updated: 2025-01-13*
*ASW Infrastructure Version: 1.0*