# Netcup VPS Setup Documentation

## Server Information
- **Server IP**: 152.53.136.76
- **Hostname**: v2202509299078380238.supersrv.de
- **OS**: Debian GNU/Linux 12 (Bookworm) ARM64
- **Date**: 2025-09-09

## Setup Completed

### 1. System Updates
- ✅ System packages updated and upgraded
- ✅ Essential packages installed (curl, git, wget, vim, htop, nano)

### 2. User Configuration
- ✅ Created user: `cc-user` with sudo privileges
- ✅ Temporary password: `gFpWQpOdVPBC34/pLZ83JQ==` (CHANGE THIS!)
- ✅ SSH key authentication configured
- ✅ Home directory: `/home/cc-user`
- ✅ 1Password SSH agent compatibility configured

### 3. SSH Configuration & Hardening
- ✅ SSH server installed and configured
- ✅ Root login disabled (`PermitRootLogin no`)
- ✅ Only cc-user allowed to SSH (`AllowUsers cc-user`)
- ✅ Strong ciphers and algorithms configured
- ✅ Max authentication attempts: 3
- ✅ Agent forwarding enabled for 1Password
- ✅ Password authentication still enabled (disable after confirming key access)

### 4. Directory Structure
- ✅ Created `/opt/asw` directory
- ✅ Ownership set to cc-user

### 5. Development Tools
- ✅ Node.js v20.19.5 installed
- ✅ npm v10.8.2 installed
- ✅ 1Password CLI v2.32.0 installed
- ✅ Git installed

### 6. SSH Key Information
**Private Key** (saved as `/tmp/cc-user-key` on local machine):
```
-----BEGIN OPENSSH PRIVATE KEY-----
[STORED LOCALLY - DO NOT SHARE]
-----END OPENSSH PRIVATE KEY-----
```

**Public Key** (added to server):
```
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINNx7dT9i6w3IkraGzR7nWDCqsEMejJZ0VIg66g8c3g4 cc-user@netcup-vps
```

## Next Steps

### 1. Save Credentials in 1Password
- Add SSH private key to 1Password
- Update the netcup VPS item with cc-user credentials
- Store the temporary password (and change it)

### 2. Test SSH Access
```bash
ssh -i /path/to/cc-user-key cc-user@152.53.136.76
```

### 3. Disable Password Authentication
Once key authentication is confirmed working:
```bash
sudo nano /etc/ssh/sshd_config.d/99-hardening.conf
# Change: PasswordAuthentication yes
# To: PasswordAuthentication no
sudo systemctl restart ssh
```

### 4. Clone ASW Framework Repositories
```bash
cd /opt/asw
git clone https://github.com/[your-username]/agentic-framework-infrastructure.git
git clone https://github.com/[your-username]/agentic-framework-security.git
git clone https://github.com/[your-username]/agentic-framework-core.git
```

### 5. Run Full Hardening
After cloning the repositories:
```bash
cd /opt/asw/agentic-framework-infrastructure
./bin/asw-server-setup --domain=your.domain.com
```

### 6. Additional Security Measures to Consider
- [ ] Install and configure UFW firewall
- [ ] Install and configure fail2ban
- [ ] Set up automatic security updates
- [ ] Configure system monitoring
- [ ] Set up log rotation and management

## Security Notes
- Root SSH access has been disabled
- Strong SSH ciphers are enforced
- Only cc-user can SSH to the server
- 1Password SSH agent forwarding is enabled
- Regular security updates should be configured

## Commands Reference

### Connect as cc-user
```bash
ssh -i ~/.ssh/cc-user-key cc-user@152.53.136.76
```

### Check system status
```bash
sudo systemctl status ssh
sudo systemctl status 1password
```

### Update system
```bash
sudo apt update && sudo apt upgrade -y
```

## Important Files
- SSH config: `/etc/ssh/sshd_config.d/99-hardening.conf`
- SSH backup: `/etc/ssh/sshd_config.backup.[date]`
- User SSH config: `/home/cc-user/.ssh/config`
- ASW directory: `/opt/asw/`