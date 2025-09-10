# SSH Port Configuration

## Overview
The ASW Framework configures SSH to run on **port 2222** instead of the default port 22 for enhanced security.

## Port Configuration Details

### Current Configuration
- **SSH Port**: 2222
- **Configuration File**: `/etc/ssh/sshd_config.d/99-hardening.conf`
- **TCP Forwarding**: Enabled (REQUIRED for VSCode/Cursor Remote SSH)

### Key Settings
```bash
Port 2222
AllowTcpForwarding yes  # Required for VSCode/Cursor Remote SSH
```

## Connecting to the Server

### Standard SSH Connection
```bash
ssh -p 2222 cc-user@SERVER_IP
```

### VSCode Remote SSH Configuration
Add to your `~/.ssh/config`:
```
Host dev-server-netcup
    HostName SERVER_IP
    Port 2222
    User cc-user
    IdentityFile ~/.ssh/your_key
```

## Script Updates
All hardening scripts have been updated to include:
1. Port 2222 configuration
2. TCP forwarding enabled (required for VSCode/Cursor Remote SSH)
3. All other security hardening settings maintained

### Updated Scripts
- `/opt/asw/scripts/apply-full-hardening.sh`
- `/opt/asw/scripts/automated-server-setup.sh`
- `/opt/asw/scripts/complete-server-setup.sh`
- `/opt/asw/scripts/complete-remote-vps-setup.sh`
- `/opt/asw/scripts/setup-new-server.sh`

## Security Considerations
- Port 2222 reduces automated SSH scanning attempts
- TCP forwarding is enabled (required for VSCode/Cursor Remote SSH functionality)
- This is a necessary trade-off for developer productivity with VSCode/Cursor
- All other security hardening remains in place:
  - Key-only authentication
  - No root login
  - Strong ciphers and algorithms
  - Rate limiting via fail2ban

## Firewall Configuration
The firewall MUST be configured to allow port 2222 for SSH to work:
```bash
sudo ufw allow 2222/tcp comment 'SSH on port 2222'
sudo ufw reload
```

**Important**: Without this firewall rule, SSH connections will hang/timeout.

## Verification
Check SSH is listening on port 2222:
```bash
sudo ss -tlnp | grep :2222
```

Test configuration:
```bash
sudo sshd -t
```

## Troubleshooting

### Connection Timeout/Hanging
If SSH connection hangs or times out:
1. **Check firewall first**: `sudo ufw status | grep 2222`
   - If missing, add: `sudo ufw allow 2222/tcp comment 'SSH on port 2222'`
   - Then reload: `sudo ufw reload`
2. Verify SSH is listening: `sudo ss -tlnp | grep :2222`
3. Check SSH service status: `sudo systemctl status ssh`
4. Confirm port in config: `grep ^Port /etc/ssh/sshd_config.d/99-hardening.conf`

### VSCode/Cursor Remote SSH Issues
If VSCode/Cursor Remote SSH fails:
1. Ensure your VSCode/Cursor SSH config uses port 2222
2. Verify firewall allows port 2222: `sudo ufw status | grep 2222`
3. Confirm TCP forwarding is enabled: `grep AllowTcpForwarding /etc/ssh/sshd_config.d/99-hardening.conf`
4. If TCP forwarding shows 'no', enable it and restart SSH:
   ```bash
   sudo sed -i 's/AllowTcpForwarding no/AllowTcpForwarding yes/' /etc/ssh/sshd_config.d/99-hardening.conf
   sudo systemctl restart ssh
   ```

## Important Notes
- Always maintain an active SSH session when making SSH configuration changes
- Test new configurations before closing existing sessions
- Keep backup of working SSH configuration