#!/bin/bash

# SMTP Configuration Removal Script
# Removes old SMTP setup now that Gmail API is being used

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'
BOLD='\033[1m'

print_header() {
    echo -e "${BOLD}${BLUE}════════════════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}${YELLOW}  SMTP Configuration Removal${NC}"
    echo -e "${BOLD}${BLUE}════════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${YELLOW}This script will remove old SMTP configuration since Gmail API is now used.${NC}"
    echo ""
}

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}This script must be run as root${NC}"
        exit 1
    fi
}

# Backup configurations before removal
backup_configs() {
    echo -e "${BLUE}Creating backup of current configurations...${NC}"
    
    BACKUP_DIR="/opt/asw/backups/smtp-removal-$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$BACKUP_DIR"
    
    # Backup Postfix config
    if [[ -d /etc/postfix ]]; then
        cp -r /etc/postfix "$BACKUP_DIR/"
        echo -e "${GREEN}Postfix configuration backed up${NC}"
    fi
    
    # Backup SSMTP config
    if [[ -d /etc/ssmtp ]]; then
        cp -r /etc/ssmtp "$BACKUP_DIR/"
        echo -e "${GREEN}SSMTP configuration backed up${NC}"
    fi
    
    # Backup msmtp config
    if [[ -f /etc/msmtprc ]]; then
        cp /etc/msmtprc "$BACKUP_DIR/"
        echo -e "${GREEN}msmtp configuration backed up${NC}"
    fi
    
    # Backup old email wrapper
    if [[ -f /usr/local/bin/send-health-report ]]; then
        cp /usr/local/bin/send-health-report "$BACKUP_DIR/"
        echo -e "${GREEN}Old email wrapper backed up${NC}"
    fi
    
    # Backup cron jobs
    if [[ -f /etc/cron.d/health-report ]]; then
        cp /etc/cron.d/health-report "$BACKUP_DIR/"
    fi
    if [[ -f /etc/cron.hourly/health-check-critical ]]; then
        cp /etc/cron.hourly/health-check-critical "$BACKUP_DIR/"
    fi
    
    echo -e "${GREEN}Backup created at: $BACKUP_DIR${NC}"
    echo ""
}

# Stop SMTP services
stop_services() {
    echo -e "${BLUE}Stopping SMTP services...${NC}"
    
    systemctl stop postfix 2>/dev/null && echo -e "${GREEN}Postfix stopped${NC}" || echo -e "${YELLOW}Postfix not running${NC}"
    systemctl disable postfix 2>/dev/null && echo -e "${GREEN}Postfix disabled${NC}" || echo -e "${YELLOW}Postfix not enabled${NC}"
    
    systemctl stop sendmail 2>/dev/null && echo -e "${GREEN}Sendmail stopped${NC}" || echo -e "${YELLOW}Sendmail not running${NC}"
    systemctl disable sendmail 2>/dev/null && echo -e "${GREEN}Sendmail disabled${NC}" || echo -e "${YELLOW}Sendmail not enabled${NC}"
    
    echo ""
}

# Remove SMTP packages
remove_packages() {
    echo -e "${BLUE}Removing SMTP packages...${NC}"
    
    # Show what will be removed
    echo -e "${YELLOW}The following packages will be removed:${NC}"
    dpkg -l | grep -E "postfix|ssmtp|msmtp|sendmail" | awk '{print "  " $2}'
    echo ""
    
    read -p "Continue with package removal? (y/N): " confirm
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        echo -e "${YELLOW}Package removal skipped${NC}"
        return
    fi
    
    # Remove packages
    apt-get remove --purge -y postfix postfix-* 2>/dev/null && echo -e "${GREEN}Postfix removed${NC}"
    apt-get remove --purge -y ssmtp 2>/dev/null && echo -e "${GREEN}SSMTP removed${NC}"
    apt-get remove --purge -y msmtp msmtp-mta 2>/dev/null && echo -e "${GREEN}msmtp removed${NC}"
    apt-get remove --purge -y sendmail sendmail-cf 2>/dev/null && echo -e "${GREEN}Sendmail removed${NC}"
    
    # Keep mailutils and mutt as they might be useful for testing
    echo -e "${YELLOW}Keeping mailutils and mutt (useful for testing)${NC}"
    
    apt-get autoremove -y
    echo ""
}

# Remove configuration files
remove_configs() {
    echo -e "${BLUE}Removing configuration files...${NC}"
    
    # Remove Postfix configs
    if [[ -d /etc/postfix ]]; then
        rm -rf /etc/postfix
        echo -e "${GREEN}Postfix configuration removed${NC}"
    fi
    
    # Remove SSMTP configs
    if [[ -d /etc/ssmtp ]]; then
        rm -rf /etc/ssmtp
        echo -e "${GREEN}SSMTP configuration removed${NC}"
    fi
    
    # Remove msmtp config
    if [[ -f /etc/msmtprc ]]; then
        rm -f /etc/msmtprc
        echo -e "${GREEN}msmtp configuration removed${NC}"
    fi
    
    # Remove mail logs (optional)
    read -p "Remove mail-related log files? (y/N): " remove_logs
    if [[ "$remove_logs" == "y" || "$remove_logs" == "Y" ]]; then
        rm -f /var/log/mail.* /var/log/msmtp.log
        echo -e "${GREEN}Mail logs removed${NC}"
    fi
    
    echo ""
}

# Update email wrapper to use Gmail API
update_email_wrapper() {
    echo -e "${BLUE}Updating email wrapper to use Gmail API...${NC}"
    
    if [[ -f /usr/local/bin/send-health-report ]]; then
        # Replace old SMTP wrapper with Gmail API wrapper
        rm -f /usr/local/bin/send-health-report
        ln -sf /usr/local/bin/send-health-report-api /usr/local/bin/send-health-report
        echo -e "${GREEN}Email wrapper updated to use Gmail API${NC}"
    else
        echo -e "${YELLOW}Old email wrapper not found${NC}"
    fi
    
    echo ""
}

# Update cron jobs
update_cron_jobs() {
    echo -e "${BLUE}Updating cron jobs to use Gmail API...${NC}"
    
    # Update daily health report cron
    if [[ -f /etc/cron.d/health-report ]]; then
        sed -i 's|/usr/local/bin/send-health-report|/usr/local/bin/send-health-report-api|g' /etc/cron.d/health-report
        echo -e "${GREEN}Daily health report cron updated${NC}"
    fi
    
    # Update hourly critical check cron
    if [[ -f /etc/cron.hourly/health-check-critical ]]; then
        sed -i 's|/usr/local/bin/send-health-report|/usr/local/bin/send-health-report-api|g' /etc/cron.hourly/health-check-critical
        echo -e "${GREEN}Hourly critical check cron updated${NC}"
    fi
    
    echo ""
}

# Clean up mail queue
clean_mail_queue() {
    echo -e "${BLUE}Cleaning mail queue...${NC}"
    
    # Postfix queue cleanup
    if command -v postqueue >/dev/null 2>&1; then
        postqueue -f 2>/dev/null || true
        postsuper -d ALL 2>/dev/null || true
        echo -e "${GREEN}Postfix mail queue cleaned${NC}"
    fi
    
    # Remove mail spool files
    rm -rf /var/spool/mail/* /var/mail/* 2>/dev/null || true
    echo -e "${GREEN}Mail spool cleaned${NC}"
    
    echo ""
}

# Test Gmail API setup
test_gmail_api() {
    echo -e "${BLUE}Testing Gmail API setup...${NC}"
    
    if [[ -f /usr/local/bin/send-health-report-api ]]; then
        echo -e "${YELLOW}Gmail API wrapper found${NC}"
        
        if [[ -f /etc/asw/gmail-api/send_email.py ]]; then
            echo -e "${YELLOW}Gmail API Python script found${NC}"
            
            if [[ -f /etc/asw/gmail-api/token.json ]]; then
                echo -e "${GREEN}Gmail API authentication token found${NC}"
                echo -e "${GREEN}Gmail API setup appears complete${NC}"
            else
                echo -e "${RED}Gmail API token missing - run Gmail setup${NC}"
            fi
        else
            echo -e "${RED}Gmail API Python script missing${NC}"
        fi
    else
        echo -e "${RED}Gmail API wrapper script missing${NC}"
    fi
    
    echo ""
}

# Summary report
show_summary() {
    echo -e "${BOLD}${BLUE}════════════════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}${GREEN}  SMTP Removal Complete${NC}"
    echo -e "${BOLD}${BLUE}════════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${GREEN}✅ Old SMTP configuration removed${NC}"
    echo -e "${GREEN}✅ Email wrapper updated to use Gmail API${NC}"
    echo -e "${GREEN}✅ Cron jobs updated${NC}"
    echo -e "${GREEN}✅ System now uses Gmail API for email delivery${NC}"
    echo ""
    echo -e "${YELLOW}Next steps:${NC}"
    echo -e "  • Test email sending: ${BOLD}sudo /usr/local/bin/send-health-report-api${NC}"
    echo -e "  • Check logs: ${BOLD}tail -f /var/log/health-report-email.log${NC}"
    echo -e "  • Backup location: ${BOLD}$BACKUP_DIR${NC}"
    echo ""
}

# Main execution
main() {
    print_header
    
    read -p "This will remove SMTP configuration and switch to Gmail API. Continue? (y/N): " confirm
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        echo -e "${YELLOW}Operation cancelled${NC}"
        exit 0
    fi
    
    check_root
    backup_configs
    stop_services
    remove_packages
    remove_configs
    update_email_wrapper
    update_cron_jobs
    clean_mail_queue
    test_gmail_api
    show_summary
}

# Run main function
main "$@"