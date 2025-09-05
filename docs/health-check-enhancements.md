# System Health Check - Enhanced Features

## Overview
The system health check script has been enhanced with additional security and monitoring features to provide comprehensive system oversight.

## New Features Added

### 1. SSH Login Monitoring
The health check now tracks and reports SSH login activity:

**Information Collected:**
- Recent successful logins (last 20)
- Failed login attempts (last 100)
- Unique IP addresses connecting
- Root login attempt detection
- Detailed login history with timestamps and source IPs

**Security Alerts:**
- Warning when failed attempts exceed 20
- Critical alert when failed attempts exceed 50
- Special alert for any root login attempts

### 2. Package Vulnerability Scanning
Comprehensive package security assessment:

**Features:**
- Total installed packages count
- Obsolete packages detection
- Security updates pending
- Third-party package versions (Node.js, Python, Docker, etc.)
- NPM vulnerability audit (if package.json exists)
- Python package outdated checks
- Support for debsecan vulnerability scanner (if installed)

**Package Monitoring:**
- Node.js and npm versions
- Python and pip versions
- Docker version
- Database servers (MySQL, PostgreSQL, MongoDB)
- Web servers (Nginx, Apache, Caddy)
- Cache servers (Redis, Elasticsearch)

### 3. Enhanced Login Banner (MOTD)
When you SSH into the server, you'll now see:

**Quick Commands Display:**
- Health check command location
- Email report command
- SSH login history command
- Package update check command

**Live System Status:**
- CPU, Memory, and Disk usage percentages
- Critical resource warnings
- Failed SSH attempt notifications

## Usage

### Run Full Health Check
```bash
sudo /opt/asw/agentic-framework-core/lib/monitoring/system-health-check.sh
```

### Generate HTML Report
```bash
sudo /opt/asw/agentic-framework-core/lib/monitoring/system-health-check.sh html
```

### Send Email Report
```bash
sudo /usr/local/bin/send-health-report-api
```

### View SSH Login History
```bash
# Last 10 logins
last -n 10

# Failed login attempts
sudo grep "Failed password" /var/log/auth.log | tail -50
```

### Check for Vulnerabilities
```bash
# Install vulnerability scanner (optional but recommended)
sudo apt-get install debsecan

# Check npm vulnerabilities (if Node.js project)
cd /opt/asw && npm audit

# Check Python package updates
pip3 list --outdated
```

## Security Recommendations

### SSH Security
1. **Monitor Failed Attempts**: Review the SSH login section regularly
2. **Disable Root Login**: Edit `/etc/ssh/sshd_config` and set `PermitRootLogin no`
3. **Use Key Authentication**: Disable password authentication when possible
4. **Install Fail2ban**: Automatically block IPs with repeated failed attempts

### Package Security
1. **Regular Updates**: Apply security updates promptly
2. **Install debsecan**: `sudo apt-get install debsecan` for CVE detection
3. **Audit Dependencies**: Run `npm audit fix` for Node.js projects
4. **Clean Obsolete Packages**: `sudo apt-get autoremove`

## Email Reports
The health check automatically sends HTML reports via Gmail API:

**Scheduled Reports:**
- Daily at 8:00 AM
- Critical alerts hourly (if thresholds exceeded)

**Report Contents:**
- Full system health metrics
- SSH login activity summary
- Package security status
- Network and Docker status
- Actionable recommendations

## Thresholds and Alerts

### Resource Thresholds
- **CPU**: Warning at 70%, Critical at 90%
- **Memory**: Warning at 80%, Critical at 95%
- **Disk**: Warning at 80%, Critical at 90%

### Security Thresholds
- **Failed SSH**: Warning at 20, Critical at 50
- **Vulnerabilities**: Warning at 5 CVEs, Critical at 10 CVEs
- **Root Attempts**: Any attempt triggers alert

## Customization

### Modify Thresholds
Edit `/opt/asw/agentic-framework-core/lib/monitoring/system-health-check.sh`:
```bash
# Lines 22-30 contain threshold variables
CPU_WARNING=70
CPU_CRITICAL=90
MEM_WARNING=80
MEM_CRITICAL=95
```

### Adjust Email Schedule
Edit `/etc/cron.d/health-report`:
```bash
# Change the time (HH MM format)
00 08 * * * root /usr/local/bin/send-health-report-api
```

### Customize Login Banner
Edit `/etc/update-motd.d/99-health-check` to modify the SSH login display.

## Troubleshooting

### No SSH Login Data
- Check `/var/log/auth.log` exists and is readable
- Ensure rsyslog is running: `systemctl status rsyslog`

### Missing Package Data
- Update package database: `sudo apt update`
- For npm audit: Ensure package.json exists in project directory

### Email Not Sending
- Check Gmail API setup: `/opt/asw/docs/gmail-api-setup.md`
- Review logs: `tail -f /var/log/health-report-email.log`

## Integration with Monitoring Stack
The health check integrates with:
- Gmail API for email delivery
- System cron for scheduling
- rsyslog for SSH activity tracking
- APT/npm/pip for package management

## Future Enhancements
Potential additions:
- Intrusion detection integration
- Container vulnerability scanning
- SSL certificate expiry monitoring
- Service uptime tracking
- Custom alerting webhooks