# ASW Project Cleanup & Resource Management Guide

This guide covers how to properly clean up projects and release resources (ports, firewall rules, nginx configs) for reuse.

## Quick Cleanup (TL;DR)

```bash
# Complete cleanup from project directory
cd /opt/asw/projects/personal/<project-name>
/opt/asw/agentic-framework-infrastructure/bin/asw-dev-server teardown
cd ..
rm -rf <project-name>
```

This releases the port, removes firewall rules, cleans nginx config, and deletes the project.

## Resource Types Managed by ASW

When you create/run a project, these resources are allocated:

1. **Port Allocation** (3000-3099 range)
2. **Firewall Rules** (UFW entries)
3. **Nginx Configuration** (reverse proxy configs)
4. **Process/PID Files** (running servers)
5. **Log Files** (server logs)
6. **Project Directory** (code and dependencies)

## Step-by-Step Cleanup Process

### Step 1: Stop Running Servers

```bash
# Check if server is running
/opt/asw/agentic-framework-infrastructure/bin/asw-dev-server status

# Stop the server gracefully
/opt/asw/agentic-framework-infrastructure/bin/asw-dev-server stop
```

### Step 2: Complete Resource Teardown

The `teardown` command handles all resource cleanup:

```bash
# From project directory
cd /opt/asw/projects/personal/<project-name>

# Run complete teardown
/opt/asw/agentic-framework-infrastructure/bin/asw-dev-server teardown
```

This automatically:
- ✅ Stops any running servers
- ✅ Releases the allocated port
- ✅ Removes firewall rules
- ✅ Deletes nginx configurations
- ✅ Cleans up PID files
- ✅ Removes state files

### Step 3: Delete Project Directory

```bash
# Move up one directory
cd ..

# Remove project directory
rm -rf <project-name>
```

## Manual Resource Cleanup (If Needed)

Sometimes resources might be orphaned. Here's how to clean them manually:

### Check and Release Ports

```bash
# List all port allocations
/opt/asw/agentic-framework-infrastructure/bin/asw-port-manager list

# Check specific port status
/opt/asw/agentic-framework-infrastructure/bin/asw-port-manager check 3000

# Manually release a port
/opt/asw/agentic-framework-infrastructure/bin/asw-port-manager release <project-name>
```

### Check and Remove Firewall Rules

```bash
# List firewall rules with line numbers
sudo ufw status numbered

# Remove specific rule (use number from above)
sudo ufw delete <rule-number>

# Example: Remove rule for port 3000
sudo ufw delete allow 3000/tcp
```

### Clean Nginx Configurations

```bash
# List nginx site configs
ls -la /etc/nginx/sites-available/
ls -la /etc/nginx/sites-enabled/

# Remove project-specific config (current: IP-based, future: domain-based)
sudo rm /etc/nginx/sites-enabled/<project-name>*
sudo rm /etc/nginx/sites-available/<project-name>*

# After domain migration, also remove domain configs
sudo rm /etc/nginx/sites-enabled/<project-name>.8020perfect.com*
sudo rm /etc/nginx/sites-available/<project-name>.8020perfect.com*

# Reload nginx
sudo nginx -s reload
```

#### SSL Certificate Cleanup (Post-Domain Migration)
```bash
# Remove self-signed certificates
sudo rm /etc/ssl/asw-dev/<project-name>.8020perfect.com.*

# For Let's Encrypt certificates (future)
# sudo certbot delete --cert-name <project-name>.8020perfect.com
```

### Kill Orphaned Processes

```bash
# Find processes on a specific port
lsof -i :3000

# Kill process by PID
kill -9 <PID>

# Kill all node/bun processes (careful!)
pkill -f "bun.*next dev"
pkill -f "node.*next dev"
```

## Bulk Cleanup Operations

### Clean All Stopped Projects

```bash
#!/bin/bash
# Script to clean all stopped projects

for project in /opt/asw/projects/*/* ; do
    if [ -d "$project" ]; then
        project_name=$(basename "$project")
        cd "$project"
        
        # Check if server is running
        if ! /opt/asw/agentic-framework-infrastructure/bin/asw-dev-server status 2>/dev/null | grep -q "running"; then
            echo "Cleaning up: $project_name"
            /opt/asw/agentic-framework-infrastructure/bin/asw-dev-server teardown
        fi
    fi
done
```

### Reset All Ports

```bash
# View all allocations
/opt/asw/agentic-framework-infrastructure/bin/asw-port-manager list

# Release specific projects
/opt/asw/agentic-framework-infrastructure/bin/asw-port-manager release project1
/opt/asw/agentic-framework-infrastructure/bin/asw-port-manager release project2

# Nuclear option: Reset ports registry (careful!)
sudo rm /opt/asw/projects/.ports-registry.json
```

## Resource Management Best Practices

### 1. Always Use Teardown Before Deletion
```bash
# Good practice
asw-dev-server teardown
rm -rf project-directory

# Bad practice (leaves resources allocated)
rm -rf project-directory  # Port and firewall still allocated!
```

### 2. Regular Resource Audits
```bash
# Weekly audit script
#!/bin/bash

echo "=== Port Allocations ==="
/opt/asw/agentic-framework-infrastructure/bin/asw-port-manager list

echo -e "\n=== Firewall Rules ==="
sudo ufw status numbered | grep -E "3[0-9]{3}"

echo -e "\n=== Running Servers ==="
ps aux | grep -E "(bun|node|npm).*dev" | grep -v grep

echo -e "\n=== Nginx Sites ==="
ls -la /etc/nginx/sites-enabled/*.conf 2>/dev/null
```

### 3. Project Lifecycle Commands

```bash
# Full lifecycle example
PROJECT="my-new-app"

# Create
cd /opt/asw/projects/personal
git clone https://github.com/example/$PROJECT.git
cd $PROJECT

# Setup & Run
bun install
/opt/asw/agentic-framework-infrastructure/bin/asw-dev-server start --no-nginx

# ... Development work ...

# Cleanup
/opt/asw/agentic-framework-infrastructure/bin/asw-dev-server teardown
cd ..
rm -rf $PROJECT
```

## Troubleshooting Resource Leaks

### Symptoms of Resource Leaks
- Cannot allocate ports (all in use)
- Firewall has many unused rules
- Nginx configs for deleted projects
- High memory/CPU from orphaned processes

### Diagnostic Commands
```bash
# Check port usage vs allocations
echo "Allocated ports:"
/opt/asw/agentic-framework-infrastructure/bin/asw-port-manager list

echo "Actually in use:"
netstat -tlnp | grep -E ":(30[0-9]{2})"

# Find orphaned processes
ps aux | grep -E "(bun|node|npm)" | grep -v grep

# Check firewall rules count
sudo ufw status | grep -c "^30[0-9]{2}"
```

### Complete System Reset (Nuclear Option)

⚠️ **WARNING**: This will stop ALL development servers and reset everything!

```bash
#!/bin/bash
# Complete ASW development environment reset

echo "⚠️  This will stop ALL servers and reset the environment!"
read -p "Are you sure? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "Cancelled"
    exit 1
fi

# Stop all dev servers
pkill -f "bun.*dev"
pkill -f "node.*dev"
pkill -f "npm.*dev"

# Clear all development firewall rules (3000-3099)
for port in {3000..3099}; do
    sudo ufw delete allow $port/tcp 2>/dev/null
done

# Remove all nginx dev configs
sudo rm -f /etc/nginx/sites-enabled/*.8020perfect.com.conf
sudo rm -f /etc/nginx/sites-available/*.8020perfect.com.conf
sudo nginx -s reload

# Reset ports registry
sudo rm -f /opt/asw/projects/.ports-registry.json

echo "✅ Development environment reset complete"
```

## Monitoring Resource Usage

### Create a Resource Dashboard
```bash
#!/bin/bash
# Save as /opt/asw/bin/asw-resource-status

echo "========================================"
echo "     ASW Development Resources Status    "
echo "========================================"
echo ""

echo "📊 PORT ALLOCATIONS"
echo "-------------------"
/opt/asw/agentic-framework-infrastructure/bin/asw-port-manager list
echo ""

echo "🔥 FIREWALL RULES (Dev Ports)"
echo "-----------------------------"
sudo ufw status | grep -E "30[0-9]{2}" || echo "No dev ports open"
echo ""

echo "⚙️  RUNNING SERVERS"
echo "------------------"
ps aux | grep -E "(bun|node).*dev" | grep -v grep | awk '{print $2, $11, $12}' || echo "No servers running"
echo ""

echo "🌐 NGINX SITES"
echo "--------------"
ls -1 /etc/nginx/sites-enabled/*.conf 2>/dev/null | xargs -n1 basename | grep -E "8020perfect" || echo "No nginx configs"
echo ""

echo "💾 DISK USAGE (Projects)"
echo "------------------------"
du -sh /opt/asw/projects/*/* 2>/dev/null | sort -rh | head -10
```

Make it executable:
```bash
chmod +x /opt/asw/bin/asw-resource-status
```

## Cleanup Checklist

Before deleting any project, ensure:

- [ ] Server stopped: `asw-dev-server stop`
- [ ] Resources released: `asw-dev-server teardown`
- [ ] Port freed: `asw-port-manager list` (verify)
- [ ] Firewall cleaned: `sudo ufw status` (verify)
- [ ] Nginx cleaned: `ls /etc/nginx/sites-enabled/` (verify)
- [ ] Directory removed: `rm -rf project-directory`
- [ ] No orphan processes: `ps aux | grep project-name`

## Common Issues & Solutions

### "Port already allocated to another project"
```bash
# Release the old allocation
/opt/asw/agentic-framework-infrastructure/bin/asw-port-manager release old-project
```

### "Address already in use"
```bash
# Find and kill process
lsof -i :3000
kill -9 <PID>
```

### "Too many firewall rules"
```bash
# Audit and clean unused rules
sudo ufw status numbered
# Delete unused rules by number
```

### "Can't delete project directory"
```bash
# Check for running processes in directory
lsof +D /opt/asw/projects/personal/project-name
# Kill any processes using the directory
```

## Automation Scripts Location

Save cleanup scripts in:
```bash
/opt/asw/bin/           # System-wide scripts
~/bin/                  # User scripts
/opt/asw/scripts/       # ASW utility scripts
```

---

*Last updated: 2025-01-13*
*ASW Infrastructure Version: 1.0*