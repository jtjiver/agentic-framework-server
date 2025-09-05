# Gmail API Email Setup Documentation

## Overview
Due to DigitalOcean blocking SMTP ports (25, 587, 465), we switched from SMTP to Gmail API for sending system health reports.

## Current Configuration

### Files Structure
```
/etc/asw/gmail-api/
├── credentials.json     # OAuth2 client credentials
├── token.json          # User access token
├── send_email.py       # Python Gmail API client
└── venv/              # Python virtual environment

/usr/local/bin/send-health-report-api  # Wrapper script
/etc/asw/email-config.conf            # Email configuration
/var/log/health-report-email.log      # Email sending logs
```

### Gmail API Components

#### 1. Python Script (`/etc/asw/gmail-api/send_email.py`)
- Authenticates using OAuth2 credentials
- Sends HTML emails with attachments
- Handles token refresh automatically
- Returns proper exit codes

#### 2. Wrapper Script (`/usr/local/bin/send-health-report-api`)
- Generates health report using existing monitoring script
- Prepares email content with system status indicators
- Calls Gmail API Python script
- Logs all activities

#### 3. Configuration (`/etc/asw/email-config.conf`)
```bash
ADMIN_EMAIL="your-email@example.com"
```

## Usage

### Send Health Report
```bash
sudo /usr/local/bin/send-health-report-api
```

### Send Custom Email
```bash
/etc/asw/gmail-api/venv/bin/python3 /etc/asw/gmail-api/send_email.py \
    --to "recipient@example.com" \
    --subject "Test Subject" \
    --body "Email content" \
    --html "/path/to/file.html"
```

## Setup Process (Already Completed)
1. Created Google Cloud project and enabled Gmail API
2. Downloaded OAuth2 credentials
3. Ran authentication flow to get user token
4. Created Python virtual environment with dependencies
5. Installed wrapper scripts

## Current Status
- ✅ Gmail API authentication working
- ✅ Health reports being sent successfully
- ✅ HTML emails with attachments supported
- ⚠️ Claude Code crashes when testing (use command line instead)

## Troubleshooting

### Common Issues
1. **Authentication Errors**: Check token.json exists and is valid
2. **Permission Errors**: Ensure scripts are executable
3. **Missing Reports**: Verify health check script generates HTML files

### Testing
```bash
# Test Gmail API connection
/etc/asw/gmail-api/venv/bin/python3 /etc/asw/gmail-api/send_email.py --help

# Send test email
sudo /usr/local/bin/send-health-report-api
```

### Logs
- Email sending logs: `/var/log/health-report-email.log`
- Health check logs: `/var/log/asw/daily-health-check.log`

## Migration Notes
- Replaced SMTP configuration due to DigitalOcean port blocking
- Gmail API provides more reliable delivery and better security
- No dependency on local mail servers or external SMTP relays