# Server Check Script Usage

## 🔍 **Server Verification Tool**

The `server-check.sh` script provides comprehensive verification of all setup steps performed by the complete server setup automation.

### **Usage:**
```bash
# Run from /opt/asw on Claude Code server to check remote server
ssh -A cc-user@YOUR_SERVER_IP '/opt/asw/scripts/server-check.sh'

# Or copy and run directly on target server
scp /opt/asw/scripts/server-check.sh cc-user@YOUR_SERVER_IP:~/
ssh -A cc-user@YOUR_SERVER_IP './server-check.sh'

# Or run locally on any server from /opt/asw
cd /opt/asw
./scripts/server-check.sh
```

## 📋 **Verification Categories**

### **1. System Information**
- Hostname, kernel version, OS details
- Architecture and uptime
- Basic system health

### **2. System Updates**
- APT package lists status
- Number of upgradable packages
- Last update timestamp

### **3. Essential Packages**
- Verifies installation of: sudo, curl, git, wget, htop, vim, nano, build-essential, ufw, fail2ban
- Shows installed versions

### **4. User Account (cc-user)**
- User existence and ID
- Group memberships (sudo access)
- Home directory and SSH directory

### **5. SSH Configuration**
- SSH hardening config file
- Security settings verification:
  - Root login disabled
  - Password authentication disabled
  - Public key authentication enabled
  - User restrictions (cc-user only)
  - Max auth attempts
  - SSH protocol version

### **6. SSH Key Authentication**
- Authorized keys file status
- Number of SSH keys
- Key fingerprints and types
- Key comments

### **7. Firewall (UFW)**
- UFW status (active/inactive)
- Allowed ports and rules
- Configuration verification

### **8. Intrusion Prevention (fail2ban)**
- Service status
- Active jails
- Protection status

### **9. Development Tools**
- Node.js version
- npm version
- 1Password CLI version
- Git version

### **10. ASW Framework**
- Base directory existence
- Framework component directories:
  - agentic-framework-core
  - agentic-framework-dev
  - agentic-framework-infrastructure
  - agentic-framework-security
- Scripts and documentation count

### **11. Network & Connectivity**
- Primary IP address
- SSH port configuration
- SSH service status

### **12. Summary**
- Critical checks passed/failed count
- Success rate percentage
- Overall status (PASSED/Partial)

## 🎯 **Sample Output**

```
╔════════════════════════════════════════════════════════════╗
║         VPS SERVER SETUP VERIFICATION REPORT              ║
║                2025-09-09 16:08:10                        ║
╚════════════════════════════════════════════════════════════╝

═══════════════════════════════════════════════════════════
  1. SYSTEM INFORMATION
═══════════════════════════════════════════════════════════
ℹ Hostname: netcup-vps
ℹ Kernel: 6.1.0-39-arm64
ℹ OS: Debian GNU/Linux 12 (bookworm)
ℹ Architecture: aarch64

...

═══════════════════════════════════════════════════════════
  12. SUMMARY
═══════════════════════════════════════════════════════════
Setup Verification Results:
  ├─ Critical Checks Passed: 7/7
  └─ Success Rate: 100%

✅ Server setup verification PASSED!
All critical components are properly configured.
```

## 🔧 **Color Coding**

- 🟢 **Green ✓**: Component properly configured
- 🔴 **Red ✗**: Component missing or misconfigured  
- 🟡 **Yellow ⚠**: Warning or partial configuration
- 🔵 **Blue ℹ**: Informational details
- 🟦 **Cyan**: Values and details

## 📊 **Exit Codes**

- `0`: All critical checks passed
- `1`: Some critical checks failed
- `2`: Script execution error

This script validates every step from the complete server setup automation process!