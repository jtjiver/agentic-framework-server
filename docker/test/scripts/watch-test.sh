#!/bin/bash
# Watch for file changes and trigger tests automatically
# Perfect for development workflow

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
WATCH_DIRS="${WATCH_DIRS:-scripts agentic-framework-*}"
DOCKER_COMPOSE_FILE="${DOCKER_COMPOSE_FILE:-docker/docker-compose.test.yml}"
TEST_DELAY="${TEST_DELAY:-2}"  # seconds to wait after file change
EXCLUDED_PATTERNS="${EXCLUDED_PATTERNS:-.git node_modules .trash test-results}"

log() {
    echo -e "${BLUE}[WATCH]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[WATCH]${NC} ✅ $1"
}

log_error() {
    echo -e "${RED}[WATCH]${NC} ❌ $1"
}

log_warning() {
    echo -e "${YELLOW}[WATCH]${NC} ⚠️ $1"
}

# Check dependencies
check_dependencies() {
    local missing_deps=()
    
    if ! command -v inotifywait &> /dev/null; then
        missing_deps+=("inotify-tools")
    fi
    
    if ! command -v docker &> /dev/null; then
        missing_deps+=("docker")
    fi
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        log_error "Missing dependencies: ${missing_deps[*]}"
        log "Please install: sudo apt-get install ${missing_deps[*]}"
        exit 1
    fi
}

# Start test environment if not running
ensure_test_environment() {
    local compose_cmd
    if command -v docker compose &> /dev/null; then
        compose_cmd="docker compose"
    else
        compose_cmd="docker-compose"
    fi
    
    if ! $compose_cmd -f "$DOCKER_COMPOSE_FILE" ps asw-test | grep -q "Up"; then
        log "Starting test environment..."
        $compose_cmd -f "$DOCKER_COMPOSE_FILE" up -d asw-test
        sleep 5
    fi
}

# Run tests based on changed file type
run_targeted_tests() {
    local changed_file="$1"
    local test_type="all"
    
    # Determine test type based on file extension and path
    case "$changed_file" in
        *.sh)
            if [[ "$changed_file" == *"scripts/check"* ]]; then
                test_type="integration"
            elif [[ "$changed_file" == *"test"* ]]; then
                test_type="unit" 
            else
                test_type="syntax"
            fi
            ;;
        *.json|package.json)
            test_type="packages"
            ;;
        *.bats)
            test_type="unit"
            ;;
        *.md)
            log "Documentation change detected - skipping tests"
            return 0
            ;;
        *)
            test_type="syntax"
            ;;
    esac
    
    log "Running $test_type tests for: $(basename "$changed_file")"
    
    local compose_cmd
    if command -v docker compose &> /dev/null; then
        compose_cmd="docker compose"
    else
        compose_cmd="docker-compose"
    fi
    
    if $compose_cmd -f "$DOCKER_COMPOSE_FILE" exec -T asw-test \
        bash -c "source ~/.test-config && /opt/asw/docker/test/scripts/test-runner.sh $test_type" 2>/dev/null; then
        log_success "Tests passed for $test_type"
        
        # Play success sound if available
        command -v paplay >/dev/null 2>&1 && paplay /usr/share/sounds/alsa/Front_Right.wav 2>/dev/null || true
    else
        log_error "Tests failed for $test_type"
        
        # Play error sound if available  
        command -v paplay >/dev/null 2>&1 && paplay /usr/share/sounds/alsa/Side_Left.wav 2>/dev/null || true
    fi
}

# Build exclude pattern for inotifywait
build_exclude_pattern() {
    local excludes=""
    for pattern in $EXCLUDED_PATTERNS; do
        if [[ -n "$excludes" ]]; then
            excludes="$excludes|"
        fi
        excludes="$excludes$pattern"
    done
    echo "$excludes"
}

# Main watch loop
start_watching() {
    local exclude_pattern
    exclude_pattern=$(build_exclude_pattern)
    
    log "🔍 Starting file watcher..."
    log "Watching directories: $WATCH_DIRS"
    log "Excluding patterns: $EXCLUDED_PATTERNS"
    log "Test delay: ${TEST_DELAY}s"
    log "Press Ctrl+C to stop"
    echo ""
    
    # Use inotifywait to monitor file changes
    inotifywait -m -r -e modify,create,delete,move \
        --format '%w%f %e' \
        --exclude "($exclude_pattern)" \
        $WATCH_DIRS 2>/dev/null | \
    while read -r file event; do
        # Skip if file doesn't exist (might be deleted)
        if [[ ! -f "$file" ]]; then
            continue
        fi
        
        log "File changed: $(basename "$file") ($event)"
        
        # Wait a bit to avoid running tests on every keystroke
        sleep "$TEST_DELAY"
        
        # Check if more changes happened during delay
        if [[ $(find "$file" -mmin -0.1 2>/dev/null | wc -l) -eq 0 ]]; then
            continue
        fi
        
        ensure_test_environment
        run_targeted_tests "$file"
        echo ""
    done
}

# Cleanup function
cleanup() {
    log "Stopping file watcher..."
    exit 0
}

# Set trap for cleanup
trap cleanup INT TERM

# Show usage
show_usage() {
    echo "ASW Framework Development Test Watcher"
    echo "====================================="
    echo ""
    echo "Automatically runs tests when files change during development."
    echo ""
    echo "Usage: $0 [command]"
    echo ""
    echo "Commands:"
    echo "  watch   Start watching for file changes (default)"
    echo "  setup   Install dependencies and prepare environment" 
    echo "  test    Run tests once and exit"
    echo "  help    Show this help"
    echo ""
    echo "Environment Variables:"
    echo "  WATCH_DIRS          Directories to watch (default: scripts agentic-framework-*)"
    echo "  TEST_DELAY          Delay after file change in seconds (default: 2)"
    echo "  EXCLUDED_PATTERNS   Patterns to exclude (default: .git node_modules .trash test-results)"
    echo ""
    echo "Examples:"
    echo "  $0                                    # Start watching"
    echo "  WATCH_DIRS='scripts' $0               # Watch only scripts directory"
    echo "  TEST_DELAY=5 $0                       # Wait 5 seconds after changes"
}

# Setup environment
setup_environment() {
    log "Setting up watch test environment..."
    
    # Install inotify-tools if not present
    if ! command -v inotifywait &> /dev/null; then
        if [[ "$EUID" -eq 0 ]] || command -v sudo &> /dev/null; then
            log "Installing inotify-tools..."
            sudo apt-get update && sudo apt-get install -y inotify-tools
        else
            log_error "Please install inotify-tools: apt-get install inotify-tools"
            exit 1
        fi
    fi
    
    # Build test environment
    log "Building test environment..."
    ./docker/test/scripts/ci-test.sh build
    
    log_success "Setup complete! Run '$0 watch' to start watching."
}

# Main execution
case "${1:-watch}" in
    watch)
        check_dependencies
        start_watching
        ;;
    setup)
        setup_environment
        ;;
    test)
        check_dependencies
        ensure_test_environment
        run_targeted_tests "$(pwd)/dummy"
        ;;
    help|--help|-h)
        show_usage
        ;;
    *)
        echo "Unknown command: $1"
        show_usage
        exit 1
        ;;
esac