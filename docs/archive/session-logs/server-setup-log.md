# Debian 12 Server Setup Log

## Server Information
- OS: Debian GNU/Linux 12
- Date: 2025-09-09
- Setup Type: Fresh server hardening with ASW framework

## Setup Process

### Prerequisites
- Root access to fresh Debian 12 server
- Server IP address
- Plan to create cc-user with sudo privileges
- Will disable root SSH access after setup

## Commands Executed

### Step 1: Initial Connection
```bash
# Server details retrieved from 1Password vault
# Server IP: 152.53.136.76
# Hostname: v2202509299078380238.supersrv.de
# Username: root
# Testing SSH connection...
sshpass -p '***' ssh -o StrictHostKeyChecking=accept-new root@152.53.136.76 'echo "Connection successful" && uname -a'
```

## Security Notes
- Root access will be disabled after initial setup
- SSH key authentication will be enforced
- cc-user will be the primary admin user
- All framework repositories will be in /opt/asw

## Post-Setup Requirements
1. Change root password immediately
2. Store cc-user credentials in 1Password
3. Verify SSH key-only access is working
4. Run ASW hardening scripts