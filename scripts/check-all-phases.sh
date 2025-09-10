#!/bin/bash
# check-all-phases.sh
# Master validation script that runs all phase checks according to COMPLETE-AUTOMATION-ARCHITECTURE.md
# Can be run locally on target server or remotely via SSH

# Removed set -e to prevent hanging on conditional checks

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Phase tracking
PHASES_PASSED=0
PHASES_FAILED=0
PHASE_RESULTS=()

echo -e "${CYAN}${BOLD}🔍 ASW Framework - Complete System Validation${NC}"
echo -e "${CYAN}${BOLD}==============================================${NC}"
echo ""
echo -e "${BLUE}Validating all three phases of ASW Framework setup:${NC}"
echo -e "  • Phase 1: Bootstrap (User account, base packages, SSH)"
echo -e "  • Phase 2: Security Hardening (Firewall, fail2ban, SSH hardening)"
echo -e "  • Phase 3: Development Environment (Framework, tools, services)"
echo ""
echo -e "${YELLOW}Starting comprehensive system validation...${NC}"
echo ""

# Function to run a phase check
run_phase_check() {
    local phase_num="$1"
    local phase_name="$2"
    local script_name="$3"
    local script_path="$SCRIPT_DIR/$script_name"
    
    echo -e "${CYAN}${BOLD}═══════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}${BOLD}PHASE $phase_num: $phase_name${NC}"
    echo -e "${CYAN}${BOLD}═══════════════════════════════════════════════════════════════════════${NC}"
    echo ""
    
    if [[ -f "$script_path" ]]; then
        if bash "$script_path"; then
            PHASE_RESULTS[$phase_num]="PASSED"
            ((PHASES_PASSED++))
            echo ""
            echo -e "${GREEN}${BOLD}✅ PHASE $phase_num ($phase_name) PASSED${NC}"
        else
            PHASE_RESULTS[$phase_num]="FAILED"
            ((PHASES_FAILED++))
            echo ""
            echo -e "${RED}${BOLD}❌ PHASE $phase_num ($phase_name) FAILED${NC}"
        fi
    else
        PHASE_RESULTS[$phase_num]="MISSING"
        ((PHASES_FAILED++))
        echo -e "${RED}❌ Validation script not found: $script_path${NC}"
    fi
    
    echo ""
    sleep 2  # Brief pause between phases
}

# Check if we're running the right scripts
echo -e "${BLUE}Validation script locations:${NC}"
for script in "check-phase-01-bootstrap.sh" "check-phase-02-hardening.sh" "check-phase-03-dev-environment.sh"; do
    if [[ -f "$SCRIPT_DIR/$script" ]]; then
        echo -e "  ${GREEN}✓${NC} $SCRIPT_DIR/$script"
    else
        echo -e "  ${RED}✗${NC} $SCRIPT_DIR/$script (missing)"
    fi
done
echo ""

# Show system info before starting
echo -e "${BLUE}System Information:${NC}"
echo -e "  Hostname: $(hostname)"
echo -e "  OS: $(lsb_release -d 2>/dev/null | cut -f2 || cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)"
echo -e "  Kernel: $(uname -r)"
echo -e "  Architecture: $(uname -m)"
echo -e "  Uptime: $(uptime -p 2>/dev/null || uptime | awk -F'up ' '{print $2}' | awk -F',' '{print $1}')"
echo -e "  Load Average: $(uptime | awk -F'load average:' '{print $2}' | xargs)"
echo ""

# Run each phase validation
run_phase_check 1 "BOOTSTRAP" "check-phase-01-bootstrap.sh"
run_phase_check 2 "SECURITY HARDENING" "check-phase-02-hardening.sh"
run_phase_check 3 "DEVELOPMENT ENVIRONMENT" "check-phase-03-dev-environment.sh"

# Final summary
echo -e "${CYAN}${BOLD}═══════════════════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}${BOLD}FINAL VALIDATION SUMMARY${NC}"
echo -e "${CYAN}${BOLD}═══════════════════════════════════════════════════════════════════════${NC}"
echo ""

# Show individual phase results
echo -e "${BOLD}Phase Results:${NC}"
for i in 1 2 3; do
    phase_name=""
    case $i in
        1) phase_name="Bootstrap" ;;
        2) phase_name="Security Hardening" ;;
        3) phase_name="Development Environment" ;;
    esac
    
    case "${PHASE_RESULTS[$i]}" in
        "PASSED")
            echo -e "  ${GREEN}✅ Phase $i ($phase_name): PASSED${NC}"
            ;;
        "FAILED")
            echo -e "  ${RED}❌ Phase $i ($phase_name): FAILED${NC}"
            ;;
        "MISSING")
            echo -e "  ${YELLOW}⚠️  Phase $i ($phase_name): VALIDATION SCRIPT MISSING${NC}"
            ;;
    esac
done

echo ""

# Overall result
TOTAL_PHASES=3
if [[ $PHASES_FAILED -eq 0 ]]; then
    echo -e "${GREEN}${BOLD}🎉 COMPLETE ASW FRAMEWORK VALIDATION: SUCCESS${NC}"
    echo -e "${GREEN}${BOLD}All $TOTAL_PHASES phases passed validation!${NC}"
    echo ""
    echo -e "${GREEN}✅ Your ASW Framework installation is complete and ready for use!${NC}"
    echo ""
    echo -e "${BLUE}${BOLD}🚀 READY FOR DEVELOPMENT${NC}"
    echo -e "${BLUE}========================${NC}"
    echo -e "Your server now has:"
    echo -e "  • Secure user account and SSH configuration"
    echo -e "  • Hardened security (firewall, fail2ban, SSH)"
    echo -e "  • Complete development environment"
    echo -e "  • ASW Framework tools and commands"
    echo -e "  • Web server and SSL certificate support"
    echo ""
    echo -e "${YELLOW}Next steps:${NC}"
    echo -e "  1. Create your first project:"
    echo -e "     ${CYAN}/opt/asw/scripts/new-project.sh my-awesome-project personal${NC}"
    echo -e "  2. Start development server:"
    echo -e "     ${CYAN}asw-dev-server start${NC}"
    echo -e "  3. View all available commands:"
    echo -e "     ${CYAN}ls /usr/local/bin/asw-*${NC}"
    echo ""
    echo -e "${GREEN}${BOLD}🎊 Happy coding with ASW Framework!${NC}"
    
    exit 0
    
elif [[ $PHASES_PASSED -eq 0 ]]; then
    echo -e "${RED}${BOLD}💥 COMPLETE ASW FRAMEWORK VALIDATION: TOTAL FAILURE${NC}"
    echo -e "${RED}${BOLD}All $TOTAL_PHASES phases failed validation!${NC}"
    echo ""
    echo -e "${RED}🚨 CRITICAL: Your ASW Framework installation has serious issues${NC}"
    echo -e "${YELLOW}🔧 Recommended action: Start over with complete setup${NC}"
    echo -e "     ${CYAN}/opt/asw/scripts/complete-remote-vps-setup.sh \"Your-1Password-Item\"${NC}"
    
    exit 3
    
else
    echo -e "${YELLOW}${BOLD}⚠️  PARTIAL ASW FRAMEWORK VALIDATION${NC}"
    echo -e "${YELLOW}${BOLD}$PHASES_PASSED/$TOTAL_PHASES phases passed, $PHASES_FAILED failed${NC}"
    echo ""
    echo -e "${YELLOW}🔧 Your installation is partially complete but needs attention${NC}"
    echo ""
    echo -e "${BLUE}Remediation steps:${NC}"
    
    # Provide specific remediation based on failed phases
    for i in 1 2 3; do
        if [[ "${PHASE_RESULTS[$i]}" == "FAILED" ]]; then
            case $i in
                1)
                    echo -e "  ${RED}Phase 1 Failed:${NC} Re-run bootstrap setup"
                    echo -e "    ${CYAN}./complete-server-setup.sh \"1Password-Server-Item\"${NC}"
                    ;;
                2)
                    echo -e "  ${RED}Phase 2 Failed:${NC} Re-run security hardening"
                    echo -e "    ${CYAN}ssh -A -p 2222 cc-user@SERVER_IP 'bash -s' < apply-full-hardening.sh${NC}"
                    ;;
                3)
                    echo -e "  ${RED}Phase 3 Failed:${NC} Re-run development environment setup"
                    echo -e "    ${CYAN}ssh -A -p 2222 cc-user@SERVER_IP 'bash -s' < complete-dev-environment-setup.sh${NC}"
                    ;;
            esac
        fi
    done
    
    echo ""
    echo -e "${YELLOW}After fixing the issues, re-run this validation:${NC}"
    echo -e "  ${CYAN}$SCRIPT_DIR/check-all-phases.sh${NC}"
    
    exit 2
fi