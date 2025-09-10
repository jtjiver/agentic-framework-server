#!/bin/bash
# check-dev-environment.sh
# Validates Phase 3: Development Environment according to COMPLETE-AUTOMATION-ARCHITECTURE.md
# Can be run locally on target server or remotely via SSH

# Removed set -e to prevent hanging on conditional checks

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Counters
TOTAL_CHECKS=0
PASSED_CHECKS=0
FAILED_CHECKS=0

echo -e "${BLUE}🛠️ ASW Framework - Phase 3 Development Environment Validation${NC}"
echo -e "${BLUE}=============================================================${NC}"
echo ""

# Helper functions
check_pass() {
    echo -e "  ${GREEN}✓${NC} $1"
    ((PASSED_CHECKS++))
    ((TOTAL_CHECKS++))
}

check_fail() {
    echo -e "  ${RED}✗${NC} $1"
    ((FAILED_CHECKS++))
    ((TOTAL_CHECKS++))
}

check_warn() {
    echo -e "  ${YELLOW}⚠${NC} $1"
    ((TOTAL_CHECKS++))
}

echo -e "${YELLOW}1. ADDITIONAL PACKAGE INSTALLATIONS${NC}"
echo "==================================="

# Check additional development packages
dev_packages=(
    "jq"           # JSON processing
    "nginx"        # Web server
    "certbot"      # SSL certificates
)

for package in "${dev_packages[@]}"; do
    if dpkg -l | grep -q "^ii.*$package "; then
        check_pass "$package is installed"
    else
        check_fail "$package is NOT installed"
    fi
done

# Check optional packages
optional_packages=(
    "docker.io"
    "docker-compose"
)

echo -e "  ${BLUE}Optional packages:${NC}"
for package in "${optional_packages[@]}"; do
    if dpkg -l | grep -q "^ii.*$package "; then
        check_pass "$package is installed (optional)"
    else
        check_warn "$package is not installed (optional)"
    fi
done

echo ""
echo -e "${YELLOW}2. ASW FRAMEWORK REPOSITORIES${NC}"
echo "============================="

# Check framework repositories
framework_repos=(
    "agentic-framework-core"
    "agentic-framework-dev"
    "agentic-framework-infrastructure"
    "agentic-framework-security"
)

for repo in "${framework_repos[@]}"; do
    if [[ -d "/opt/asw/$repo" ]]; then
        check_pass "$repo repository exists"
        
        # Check if it's a git repository
        if [[ -d "/opt/asw/$repo/.git" ]]; then
            check_pass "$repo is a git repository"
            
            # Check git remote
            cd "/opt/asw/$repo"
            if git remote -v &>/dev/null; then
                remote_url=$(git remote get-url origin 2>/dev/null || echo "No remote")
                echo -e "    ${BLUE}Remote: $remote_url${NC}"
            fi
            
            # Check last commit
            if git log -1 --oneline &>/dev/null; then
                last_commit=$(git log -1 --oneline 2>/dev/null | cut -c1-50)
                echo -e "    ${BLUE}Last commit: $last_commit${NC}"
            fi
            cd - &>/dev/null
        else
            check_warn "$repo is not a git repository"
        fi
        
        # Check package.json exists
        if [[ -f "/opt/asw/$repo/package.json" ]]; then
            check_pass "$repo has package.json"
            
            # Get package version
            if command -v jq &>/dev/null; then
                package_version=$(jq -r '.version // "unknown"' "/opt/asw/$repo/package.json" 2>/dev/null)
                package_name=$(jq -r '.name // "unknown"' "/opt/asw/$repo/package.json" 2>/dev/null)
                echo -e "    ${BLUE}Package: $package_name@$package_version${NC}"
            fi
        else
            check_warn "$repo missing package.json"
        fi
        
    else
        check_fail "$repo repository does NOT exist"
    fi
done

echo ""
echo -e "${YELLOW}3. NPM PACKAGE LINKING${NC}"
echo "======================"

# Check global npm packages
if command -v npm &>/dev/null; then
    check_pass "npm is available"
    
    # Check for globally linked packages
    global_packages=$(npm list -g --depth=0 2>/dev/null)
    if [[ -n "$global_packages" ]]; then
        echo -e "  ${BLUE}Global packages found:${NC}"
        
        # Look for ASW/agentic framework packages specifically
        framework_packages=$(echo "$global_packages" | grep -E "(agentic-framework|@jtjiver)" 2>/dev/null || echo "")
        if [[ -n "$framework_packages" ]]; then
            echo "$framework_packages" | while read -r line; do
                if [[ "$line" =~ ^[├└].*(@jtjiver|agentic-framework) ]]; then
                    package_info=$(echo "$line" | awk '{print $2}')
                    check_pass "Global package: $package_info"
                fi
            done
        else
            check_warn "No ASW framework global packages found"
        fi
        
        # Show total count of global packages
        package_count=$(echo "$global_packages" | grep -c "^[├└]" || echo "0")
        echo -e "    ${BLUE}Total global packages: $package_count${NC}"
    else
        check_warn "No global packages found"
    fi
    
    # Check npm link status for each framework repo
    for repo in "${framework_repos[@]}"; do
        if [[ -d "/opt/asw/$repo" ]] && [[ -f "/opt/asw/$repo/package.json" ]]; then
            # Get package name from package.json
            package_name=$(jq -r '.name // "unknown"' "/opt/asw/$repo/package.json" 2>/dev/null)
            
            # Check if package is globally linked by looking for symlinks
            if echo "$global_packages" | grep -q "$package_name"; then
                # Double-check if it's actually linked (not just installed)
                if echo "$global_packages" | grep "$package_name" | grep -q "\->" 2>/dev/null; then
                    check_pass "$repo is globally linked ($package_name)"
                else
                    check_warn "$repo package found but not linked ($package_name)"
                fi
            else
                check_warn "$repo is not globally linked ($package_name)"
            fi
        fi
    done
    
else
    check_fail "npm is not available"
fi

echo ""
echo -e "${YELLOW}4. COMMAND SYMLINKS${NC}"
echo "==================="

# Expected ASW commands based on documentation
expected_commands=(
    "asw-dev-server"      # infrastructure/bin/
    "asw-port-manager"    # infrastructure/bin/
    "asw-nginx-manager"   # infrastructure/bin/
    "asw-init"           # core/bin/
    "asw-scan"           # security/bin/
)

for cmd in "${expected_commands[@]}"; do
    if command -v "$cmd" &>/dev/null; then
        cmd_path=$(which "$cmd")
        check_pass "$cmd is available at $cmd_path"
        
        # Check if it's a symlink
        if [[ -L "$cmd_path" ]]; then
            target=$(readlink "$cmd_path")
            echo -e "    ${BLUE}Symlink target: $target${NC}"
        fi
        
        # Try to get version or help
        if "$cmd" --version &>/dev/null; then
            version=$("$cmd" --version 2>/dev/null | head -1)
            echo -e "    ${BLUE}Version: $version${NC}"
        elif "$cmd" --help &>/dev/null; then
            echo -e "    ${BLUE}Help available${NC}"
        fi
        
    else
        check_fail "$cmd command is NOT available"
    fi
done

# Check /usr/local/bin for ASW commands
echo -e "  ${BLUE}Commands in /usr/local/bin:${NC}"
asw_commands_count=$(ls -la /usr/local/bin/ 2>/dev/null | grep -c "asw-" 2>/dev/null || echo "0")
asw_commands_count=${asw_commands_count//[^0-9]/}  # Remove non-numeric characters
asw_commands_count=${asw_commands_count:-0}  # Default to 0 if empty
if [[ "$asw_commands_count" -gt 0 ]]; then
    echo -e "    Found $asw_commands_count ASW commands in /usr/local/bin/"
else
    check_warn "No ASW commands found in /usr/local/bin/"
fi

echo ""
echo -e "${YELLOW}5. SERVICE INITIALIZATIONS${NC}"
echo "=========================="

# Check port registry
if [[ -f "/opt/asw/projects/.ports-registry.json" ]]; then
    check_pass "Port registry file exists"
    
    # Validate JSON format
    if command -v jq &>/dev/null && jq empty "/opt/asw/projects/.ports-registry.json" &>/dev/null; then
        check_pass "Port registry has valid JSON format"
        
        # Show current ports
        ports_count=$(jq '.ports | length' "/opt/asw/projects/.ports-registry.json" 2>/dev/null || echo "0")
        echo -e "    ${BLUE}Registered ports: $ports_count${NC}"
        
        if [[ "$ports_count" -gt 0 ]]; then
            echo -e "    ${BLUE}Port assignments:${NC}"
            jq -r '.ports | to_entries[] | "      \(.key): \(.value)"' "/opt/asw/projects/.ports-registry.json" 2>/dev/null || true
        fi
        
    else
        check_fail "Port registry has invalid JSON format"
    fi
else
    check_fail "Port registry file does NOT exist"
fi

# Check projects directory structure
if [[ -d "/opt/asw/projects" ]]; then
    check_pass "Projects directory exists"
    
    # Check project subdirectories
    project_dirs=("personal" "clients" "experiments")
    for dir in "${project_dirs[@]}"; do
        if [[ -d "/opt/asw/projects/$dir" ]]; then
            check_pass "Projects/$dir directory exists"
            
            # Count projects in directory
            project_count=$(find "/opt/asw/projects/$dir" -maxdepth 1 -type d | wc -l)
            project_count=$((project_count - 1)) # Subtract 1 for the directory itself
            echo -e "    ${BLUE}Projects in $dir: $project_count${NC}"
        else
            check_warn "Projects/$dir directory does not exist"
        fi
    done
else
    check_fail "Projects directory does NOT exist"
fi

echo ""
echo -e "${YELLOW}6. WEB SERVER (NGINX)${NC}"
echo "====================="

# Check Nginx installation and configuration
if command -v nginx &>/dev/null || [[ -x "/usr/sbin/nginx" ]] || [[ -x "/sbin/nginx" ]]; then
    check_pass "Nginx is installed"
    
    # Determine nginx path
    NGINX_CMD=""
    if command -v nginx &>/dev/null; then
        NGINX_CMD="nginx"
    elif [[ -x "/usr/sbin/nginx" ]]; then
        NGINX_CMD="/usr/sbin/nginx"
    elif [[ -x "/sbin/nginx" ]]; then
        NGINX_CMD="/sbin/nginx"
    fi
    
    # Check nginx service
    if systemctl is-active nginx &>/dev/null; then
        check_pass "Nginx service is running"
    else
        check_warn "Nginx service is not running"
    fi
    
    if systemctl is-enabled nginx &>/dev/null; then
        check_pass "Nginx service is enabled"
    else
        check_warn "Nginx service is not enabled"
    fi
    
    # Check nginx configuration
    if $NGINX_CMD -t &>/dev/null; then
        check_pass "Nginx configuration is valid"
    else
        check_fail "Nginx configuration has errors"
    fi
    
    # Check for ASW nginx configurations
    if [[ -d "/etc/nginx/sites-available" ]]; then
        asw_sites=$(ls /etc/nginx/sites-available/ 2>/dev/null | grep -c "asw" || echo "0")
        if [[ "$asw_sites" -gt 0 ]]; then
            check_pass "Found $asw_sites ASW nginx configurations"
        else
            check_warn "No ASW-specific nginx configurations found"
        fi
    fi
    
else
    check_fail "Nginx is not installed"
fi

echo ""
echo -e "${YELLOW}7. SSL CERTIFICATES (CERTBOT)${NC}"
echo "=============================="

# Check certbot installation (might be in different locations)
if command -v certbot &>/dev/null || dpkg -l | grep -q "^ii.*certbot"; then
    if command -v certbot &>/dev/null; then
        check_pass "Certbot is installed"
    else
        check_pass "Certbot package is installed (may need to check PATH)"
    fi
    
    # Check for existing certificates (if certbot is accessible)
    if command -v certbot &>/dev/null; then
        cert_count=$(certbot certificates 2>/dev/null | grep -c "Certificate Name:" || echo "0")
        if [[ "$cert_count" -gt 0 ]]; then
            check_pass "Found $cert_count SSL certificates"
            
            echo -e "  ${BLUE}SSL Certificates:${NC}"
            certbot certificates 2>/dev/null | grep -E "(Certificate Name|Domains|Expiry Date)" | while read -r line; do
                echo -e "    $line"
            done
        else
            check_warn "No SSL certificates found (normal for new installations)"
        fi
    else
        check_warn "Certbot command not accessible, cannot check certificates"
    fi
    
    # Check certbot renewal timer
    if systemctl is-enabled certbot.timer &>/dev/null; then
        check_pass "Certbot automatic renewal is enabled"
    else
        check_warn "Certbot automatic renewal is not enabled"
    fi
    
else
    check_fail "Certbot is not installed"
fi

echo ""
echo -e "${YELLOW}8. DOCKER (OPTIONAL)${NC}"
echo "====================="

if command -v docker &>/dev/null; then
    check_pass "Docker is installed"
    
    # Check docker service
    if systemctl is-active docker &>/dev/null; then
        check_pass "Docker service is running"
    else
        check_warn "Docker service is not running"
    fi
    
    # Check docker permissions for cc-user
    if groups cc-user | grep -q docker; then
        check_pass "cc-user is in docker group"
    else
        check_warn "cc-user is not in docker group"
    fi
    
    # Check docker-compose
    if command -v docker-compose &>/dev/null; then
        compose_version=$(docker-compose --version 2>/dev/null)
        check_pass "Docker Compose is installed ($compose_version)"
    else
        check_warn "Docker Compose is not installed"
    fi
    
else
    check_warn "Docker is not installed (optional)"
fi

echo ""
echo -e "${YELLOW}9. DEVELOPMENT ENVIRONMENT STATUS${NC}"
echo "=================================="

echo -e "  ${BLUE}Environment Overview:${NC}"

# Framework status
framework_ready=0
for repo in "${framework_repos[@]}"; do
    if [[ -d "/opt/asw/$repo" ]]; then
        ((framework_ready++))
    fi
done
echo -e "    Framework repos: $framework_ready/${#framework_repos[@]} available"

# Command availability
cmd_ready=0
for cmd in "${expected_commands[@]}"; do
    if command -v "$cmd" &>/dev/null; then
        ((cmd_ready++))
    fi
done
echo -e "    ASW commands: $cmd_ready/${#expected_commands[@]} available"

# Services status
services=("nginx")
services_running=0
for service in "${services[@]}"; do
    if systemctl is-active "$service" &>/dev/null; then
        ((services_running++))
    fi
done
echo -e "    Key services: $services_running/${#services[@]} running"

# Disk usage for /opt/asw
if [[ -d "/opt/asw" ]]; then
    asw_size=$(du -sh /opt/asw 2>/dev/null | awk '{print $1}')
    echo -e "    ASW directory size: $asw_size"
fi

echo ""
echo -e "${BLUE}=============================================================${NC}"
echo -e "${BLUE}DEVELOPMENT ENVIRONMENT VALIDATION SUMMARY${NC}"
echo -e "${BLUE}=============================================================${NC}"

if [[ $FAILED_CHECKS -eq 0 ]]; then
    echo -e "${GREEN}🎉 Development Environment Phase PASSED${NC}"
    echo -e "   ${GREEN}✓${NC} $PASSED_CHECKS/$TOTAL_CHECKS checks passed"
    if [[ $PASSED_CHECKS -lt $TOTAL_CHECKS ]]; then
        warn_count=$((TOTAL_CHECKS - PASSED_CHECKS - FAILED_CHECKS))
        echo -e "   ${YELLOW}⚠${NC} $warn_count warnings (non-critical or optional items)"
    fi
    echo ""
    echo -e "${GREEN}✅ Phase 3 (Development Environment) is complete and ready${NC}"
    echo -e "${BLUE}🚀 Your ASW Framework development server is ready for use!${NC}"
    echo ""
    echo -e "${BLUE}Next steps:${NC}"
    echo -e "   • Create a new project: ${YELLOW}/opt/asw/scripts/new-project.sh my-project personal${NC}"
    echo -e "   • Start development server: ${YELLOW}asw-dev-server start${NC}"
    echo -e "   • View available commands: ${YELLOW}ls /usr/local/bin/asw-*${NC}"
    exit 0
else
    echo -e "${RED}❌ Development Environment Phase FAILED${NC}"
    echo -e "   ${RED}✗${NC} $FAILED_CHECKS/$TOTAL_CHECKS critical issues found"
    echo -e "   ${GREEN}✓${NC} $PASSED_CHECKS checks passed"
    if [[ $PASSED_CHECKS -lt $TOTAL_CHECKS ]]; then
        warn_count=$((TOTAL_CHECKS - PASSED_CHECKS - FAILED_CHECKS))
        [[ $warn_count -gt 0 ]] && echo -e "   ${YELLOW}⚠${NC} $warn_count warnings"
    fi
    echo ""
    echo -e "${RED}🚨 Phase 3 (Development Environment) has critical issues${NC}"
    echo -e "${YELLOW}🔧 Re-run: ssh -A -p 2222 cc-user@SERVER_IP 'bash -s' < complete-dev-environment-setup.sh${NC}"
    exit 1
fi