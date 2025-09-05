#!/bin/bash
# Automated Security Library Update Checker
# Run this weekly via cron to check for updates

set -euo pipefail

SECURITY_REPO="/opt/asw/agentic-framework-security"
REPOS_BASE="/opt/asw"
NOTIFICATION_EMAIL="admin@yourdomain.com"
LOG_FILE="/opt/asw/logs/security-updates.log"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log_message() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Create log directory if needed
mkdir -p "$(dirname "$LOG_FILE")"

log_message "=== Starting Security Library Update Check ==="

# Update security repo
log_message "Pulling latest security repository..."
cd "$SECURITY_REPO"
git pull origin main >> "$LOG_FILE" 2>&1

# Check for updates
log_message "Checking for outdated security libraries..."
UPDATE_CHECK=$("$SECURITY_REPO/update-security-library.sh" check 2>&1)
echo "$UPDATE_CHECK" | tee -a "$LOG_FILE"

# Check if updates are needed
if echo "$UPDATE_CHECK" | grep -q "Update available\|not installed"; then
    log_message "Updates are available!"
    
    # Send notification (optional)
    if command -v mail >/dev/null 2>&1; then
        echo "$UPDATE_CHECK" | mail -s "Security Library Updates Available" "$NOTIFICATION_EMAIL"
    fi
    
    # Optionally auto-update (uncomment if desired)
    # log_message "Auto-updating all repositories..."
    # "$SECURITY_REPO/update-security-library.sh" update >> "$LOG_FILE" 2>&1
    # 
    # # Auto-commit updates (be careful with this!)
    # for repo in agentic-framework-infrastructure agentic-framework-core agentic-framework-dev; do
    #     if [[ -d "$REPOS_BASE/$repo" ]]; then
    #         cd "$REPOS_BASE/$repo"
    #         if git diff --quiet lib/security/; then
    #             log_message "No changes in $repo"
    #         else
    #             git add lib/security/
    #             git commit -m "chore: Update security library to latest version [automated]"
    #             git push
    #             log_message "Updated and pushed $repo"
    #         fi
    #     fi
    # done
    
    echo -e "${YELLOW}⚠ Security library updates are available${NC}"
    echo "Run: $SECURITY_REPO/update-security-library.sh update"
    exit 1
else
    log_message "All security libraries are up to date"
    echo -e "${GREEN}✓ All security libraries are up to date${NC}"
    exit 0
fi