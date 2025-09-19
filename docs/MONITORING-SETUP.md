# Server Monitoring Setup Guide

## Overview

The ASW Framework now includes comprehensive server health monitoring with email notifications. This guide documents the monitoring system setup process and dependencies.

## Components Installed

### 1. Core Health Monitoring
- **System Health Check Script**: `/opt/asw/agentic-framework-infrastructure/lib/monitoring/system-health-check.sh`
- **CLI Wrapper**: `/opt/asw/agentic-framework-infrastructure/bin/asw-health-check`
- **Safe Wrapper**: `/opt/asw/agentic-framework-infrastructure/lib/monitoring/health-check`

### 2. Email System (Gmail API)
- **Gmail API Sender**: `/opt/asw/agentic-framework-infrastructure/lib/monitoring/gmail-send.py`
- **Setup Scripts**: 
  - `setup-gmail-api.sh` - Main Gmail API configuration
  - `setup-gmail-credentials.sh` - 1Password credential integration
- **Email Wrapper**: `/usr/local/bin/send-health-report-api`

### 3. Configuration Files
- **Email Config**: `/etc/asw/email-config.conf`
- **Cron Job**: `/etc/cron.d/health-report` (Daily reports at 8:00 AM)
- **Credentials**: `/opt/asw/.gmail/` (OAuth tokens and credentials)

## Dependencies Added to Server Setup Scripts

### System Packages
```bash
bc                    # Calculator for health check calculations
net-tools            # Network utilities (netstat, etc.)
python3              # Python runtime
python3-pip          # Python package manager
python3-venv         # Virtual environment support
```

### Python Packages
```bash
google-auth                # Google OAuth authentication
google-auth-oauthlib      # OAuth 2.0 flow handling
google-auth-httplib2      # HTTP transport for Google Auth
google-api-python-client  # Gmail API client library
```

## Server Setup Script Updates

### Modified Scripts
1. **`/opt/asw/agentic-framework-infrastructure/lib/server-setup/setup-server.sh`**
   - Added monitoring system dependencies to essential packages
   - Added Gmail API Python dependencies installation
   - Added monitoring system setup step

2. **`/opt/asw/scripts/automated-server-setup.sh`**
   - Added monitoring dependencies to essential packages step
   - Added new `setup_monitoring()` function
   - Integrated monitoring setup into main execution flow

## Installation Process

### Automatic (via server setup scripts)
The monitoring system is now automatically installed on new servers when using:
- `/opt/asw/agentic-framework-infrastructure/lib/server-setup/setup-server.sh`
- `/opt/asw/scripts/automated-server-setup.sh`

### Manual Installation
```bash
# 1. Install system dependencies
sudo apt install -y bc net-tools python3 python3-pip python3-venv

# 2. Install Python Gmail API dependencies
sudo pip3 install google-auth google-auth-oauthlib google-auth-httplib2 google-api-python-client

# 3. Create directory structure
sudo mkdir -p /etc/asw
mkdir -p /opt/asw/.gmail

# 4. Install monitoring system
cd /opt/asw/agentic-framework-infrastructure/lib/monitoring
sudo ./install-monitoring.sh

# 5. Setup Gmail API
sudo ./setup-gmail-api.sh

# 6. Configure credentials (requires Google Cloud Console setup)
# Follow the setup instructions provided by setup-gmail-api.sh
```

## Configuration Required

### Gmail API Setup
1. **Google Cloud Console**:
   - Create project or use existing
   - Enable Gmail API
   - Create OAuth 2.0 Desktop Application credentials
   - Download credentials JSON file

2. **Server Configuration**:
   - Place credentials in `/etc/asw/gmail-api/credentials.json`
   - Run OAuth setup: `/etc/asw/gmail-api/venv/bin/python3 /etc/asw/gmail-api/setup_oauth.py`
   - Follow browser authentication prompts

3. **Email Configuration**:
   - Update `/etc/asw/email-config.conf` with appropriate email addresses
   - Test email functionality: `/usr/local/bin/send-health-report-api`

## Current Status

### ✅ Completed
- System health check functionality working
- All monitoring scripts present and functional
- Email configuration framework in place
- Cron job scheduled for daily reports
- Dependencies added to server build scripts
- Directory structure created

### ⏳ Pending
- Gmail API credentials configuration (requires Google Cloud Console setup)
- Email functionality testing (depends on credentials)

## Testing

### Health Check Test
```bash
# Test health check functionality
/opt/asw/agentic-framework-infrastructure/lib/monitoring/system-health-check.sh

# Test via CLI wrapper
/opt/asw/agentic-framework-infrastructure/bin/asw-health-check
```

### Email Test (after credential setup)
```bash
# Test email sending
/usr/local/bin/send-health-report-api

# Test with specific recipient
/opt/asw/agentic-framework-infrastructure/lib/monitoring/test-email.sh your@email.com
```

## Security Considerations

- Gmail API uses OAuth 2.0 (more secure than SMTP passwords)
- Credentials stored with restricted permissions (600)
- Uses app-specific authentication flow
- 1Password integration available for credential management

## Monitoring Features

### Health Checks
- CPU usage and load averages
- Memory usage (RAM/Swap)
- Disk usage per partition
- Process health and zombie detection
- Network connectivity and ports
- Docker container status
- System update status
- Space recovery recommendations

### Reporting
- Color-coded terminal output
- HTML report generation
- Email notifications (daily reports)
- Critical threshold alerts

## Next Steps

1. **Complete Gmail API Setup**: Configure Google Cloud Console project and OAuth credentials
2. **Test Email Functionality**: Verify email sending works correctly
3. **Customize Thresholds**: Adjust monitoring thresholds as needed
4. **Add Additional Recipients**: Configure multiple email recipients if required

## Troubleshooting

### Health Check Issues
- Ensure all dependencies installed: `bc`, `net-tools`
- Check script permissions: all scripts should be executable
- Run with sudo for full system access

### Email Issues
- Verify Gmail API credentials are properly configured
- Check `/etc/asw/email-config.conf` settings
- Test OAuth token validity
- Review setup instructions from `setup-gmail-api.sh`

## References

- **Main Documentation**: `/opt/asw/agentic-framework-infrastructure/lib/monitoring/README.md`
- **Gmail API Setup**: Google Cloud Console > APIs & Services
- **1Password Integration**: Service account token configuration