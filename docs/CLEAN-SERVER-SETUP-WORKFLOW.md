# Clean VPS Server Setup Workflow

## 🎯 One Clear Path: From Fresh VPS to Dev Environment

### Prerequisites
1. Fresh VPS with root access
2. 1Password SSH key in Private vault
3. Server credentials in 1Password

---

## Phase 1: Initial Bootstrap (Remote)
**Run from Claude Code server**

```bash
cd /opt/asw/scripts
./complete-server-setup.sh "Your-1Password-Server-Item"
```

This gives you:
- ✅ cc-user account with sudo
- ✅ SSH key authentication
- ✅ Basic packages (git, curl, Node.js)
- ✅ 1Password CLI
- ✅ ASW framework structure at /opt/asw/

---

## Phase 2: Complete Hardening (Local)
**SSH to your server and run:**

```bash
ssh -A cc-user@YOUR_SERVER_IP
cd /opt/asw

# Run the combined hardening script
./scripts/apply-full-hardening.sh
```

This applies:
- ✅ SSH hardening (port 2222, strong ciphers, no root, TCP forwarding for VSCode/Cursor)
- ✅ UFW firewall (ports 2222, 80, 443 only)
- ✅ fail2ban (intrusion prevention)
- ✅ Automatic security updates  
- ✅ System monitoring
- ✅ CC User profile setup (tmux, Claude Code, 1Password integration)

---

## Phase 3: Development Environment (Local)
**Still on the server, install dev tools:**

```bash
# Install ASW framework packages globally
npm install -g @jtjiver/agentic-framework-infrastructure
npm install -g @jtjiver/agentic-framework-dev
npm install -g @jtjiver/agentic-framework-security

# This gives you CLI commands:
# - asw-dev-server (development server management)
# - asw-port-manager (port allocation)
# - asw-nginx-manager (reverse proxy)
# - asw-health-check (monitoring)
```

---

## Phase 4: Create Your First Project

```bash
# Option A: With framework scaffolding
asw-init my-project --template=node-typescript
cd my-project
asw-dev-server start --https

# Option B: Simple project
cd ~
git clone your-project
cd your-project
npm install
asw-dev-server start --port=3000
```

Your project is now:
- ✅ Running on allocated port
- ✅ Behind Nginx reverse proxy
- ✅ SSL certificate (Let's Encrypt or self-signed)
- ✅ Accessible at https://your-domain.com

---

## 📁 Final Structure

```
/opt/asw/
├── scripts/                    # Setup & utility scripts
│   ├── complete-server-setup.sh    # Remote bootstrap
│   ├── apply-full-hardening.sh     # Local hardening
│   └── server-check.sh             # Verification
├── node_modules/
│   └── @jtjiver/               # NPM framework packages
│       ├── agentic-framework-core/
│       ├── agentic-framework-infrastructure/
│       ├── agentic-framework-dev/
│       └── agentic-framework-security/
└── projects/                   # Your development projects
    └── my-app/

~/                              # Your user projects
└── my-project/
    ├── .asw-dev-server.state   # Dev server state
    └── .vault-config           # Project secrets config
```

---

## 🔄 Daily Workflow

```bash
# Start your dev server
cd ~/my-project
asw-dev-server start

# Check server health
asw-health-check

# View logs
asw-dev-server logs

# Stop server
asw-dev-server stop
```

---

## 🎯 Summary

**Three Simple Steps:**
1. **Bootstrap** (remote): `./complete-server-setup.sh`
2. **Harden** (local): `./apply-full-hardening.sh`
3. **Develop** (local): `npm install -g @jtjiver/...`

**Then you have:**
- Secure VPS with monitoring
- Development environment with SSL
- Framework tools via NPM commands
- Project scaffolding and management

This is the clean, straightforward path from fresh VPS to working dev environment.