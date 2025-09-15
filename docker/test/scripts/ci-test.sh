#!/bin/bash
# CI/CD Test Integration Script
# Designed for automated testing in CI/CD pipelines

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
DOCKER_COMPOSE_FILE="${DOCKER_COMPOSE_FILE:-docker/docker-compose.test.yml}"
TEST_TIMEOUT="${TEST_TIMEOUT:-1800}"  # 30 minutes
RESULTS_DIR="$(pwd)/test-results"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

log() {
    echo -e "${BLUE}[CI-TEST]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[CI-TEST]${NC} ✅ $1"
}

log_error() {
    echo -e "${RED}[CI-TEST]${NC} ❌ $1"
}

log_warning() {
    echo -e "${YELLOW}[CI-TEST]${NC} ⚠️ $1"
}

# Cleanup function
cleanup() {
    log "Cleaning up test environment..."
    docker-compose -f "$DOCKER_COMPOSE_FILE" down --volumes --remove-orphans 2>/dev/null || true
    
    # Save test results if they exist
    if [[ -d "$RESULTS_DIR" ]]; then
        log "Test results saved in: $RESULTS_DIR"
    fi
}

# Set trap for cleanup
trap cleanup EXIT

# Pre-flight checks
preflight_checks() {
    log "Running pre-flight checks..."
    
    # Check Docker
    if ! command -v docker &> /dev/null; then
        log_error "Docker not found. Please install Docker."
        exit 1
    fi
    
    # Check Docker Compose
    if ! docker compose version &> /dev/null && ! docker-compose --version &> /dev/null; then
        log_error "Docker Compose not found. Please install Docker Compose."
        exit 1
    fi
    
    # Use docker compose or docker-compose based on availability
    if docker compose version &> /dev/null; then
        COMPOSE_CMD="docker compose"
    else
        COMPOSE_CMD="docker-compose"
    fi
    
    # Check if compose file exists
    if [[ ! -f "$DOCKER_COMPOSE_FILE" ]]; then
        log_error "Docker Compose file not found: $DOCKER_COMPOSE_FILE"
        exit 1
    fi
    
    # Create results directory
    mkdir -p "$RESULTS_DIR"
    
    log_success "Pre-flight checks passed"
}

# Build test images
build_images() {
    log "Building test images..."
    
    if $COMPOSE_CMD -f "$DOCKER_COMPOSE_FILE" build --no-cache; then
        log_success "Test images built successfully"
    else
        log_error "Failed to build test images"
        exit 1
    fi
}

# Start test environment
start_environment() {
    log "Starting test environment..."
    
    if $COMPOSE_CMD -f "$DOCKER_COMPOSE_FILE" up -d; then
        log_success "Test environment started"
    else
        log_error "Failed to start test environment"
        exit 1
    fi
    
    # Wait for services to be ready
    log "Waiting for services to be ready..."
    sleep 10
    
    # Check if main test container is running
    if $COMPOSE_CMD -f "$DOCKER_COMPOSE_FILE" ps asw-test | grep -q "Up"; then
        log_success "Test container is running"
    else
        log_error "Test container failed to start"
        $COMPOSE_CMD -f "$DOCKER_COMPOSE_FILE" logs asw-test
        exit 1
    fi
}

# Run tests
run_tests() {
    log "Running comprehensive test suite..."
    
    # Run the main test runner
    local exit_code=0
    if timeout "$TEST_TIMEOUT" $COMPOSE_CMD -f "$DOCKER_COMPOSE_FILE" exec -T asw-test \
        bash -c "source ~/.test-config && /opt/asw/docker/test/scripts/test-runner.sh all"; then
        log_success "All tests passed!"
    else
        exit_code=$?
        log_error "Tests failed with exit code: $exit_code"
    fi
    
    # Copy test results from container
    log "Copying test results from container..."
    $COMPOSE_CMD -f "$DOCKER_COMPOSE_FILE" cp asw-test:/opt/test-results/. "$RESULTS_DIR/" 2>/dev/null || {
        log_warning "Could not copy some test results"
    }
    
    return $exit_code
}

# Generate CI report
generate_ci_report() {
    local exit_code=$1
    
    log "Generating CI/CD report..."
    
    local report_file="$RESULTS_DIR/ci-report-$TIMESTAMP.md"
    
    cat > "$report_file" << EOF
# ASW Framework CI/CD Test Report

**Build ID**: ${CI_BUILD_ID:-$TIMESTAMP}  
**Branch**: ${CI_BRANCH:-$(git branch --show-current 2>/dev/null || echo "unknown")}  
**Commit**: ${CI_COMMIT:-$(git rev-parse HEAD 2>/dev/null || echo "unknown")}  
**Timestamp**: $(date)  
**Exit Code**: $exit_code  

## Test Result

$(if [[ $exit_code -eq 0 ]]; then
    echo "✅ **SUCCESS** - All tests passed"
else
    echo "❌ **FAILED** - Tests failed with exit code $exit_code"
fi)

## Environment

- **Docker Version**: $(docker --version)
- **Docker Compose**: $($COMPOSE_CMD version --short 2>/dev/null || echo "Unknown")
- **OS**: $(uname -s -r)
- **Test Timeout**: ${TEST_TIMEOUT}s

## Test Artifacts

$(find "$RESULTS_DIR" -name "test-report-*.md" -type f | head -1 | xargs cat 2>/dev/null || echo "No detailed test report found")

## Log Files

\`\`\`
$(ls -la "$RESULTS_DIR" 2>/dev/null || echo "No log files found")
\`\`\`

## Container Logs

### ASW Test Container
\`\`\`
$($COMPOSE_CMD -f "$DOCKER_COMPOSE_FILE" logs --tail 50 asw-test 2>/dev/null || echo "No container logs available")
\`\`\`

---
*Generated by ASW Framework CI/CD Test Runner*
EOF

    log "CI/CD report generated: $report_file"
    
    # Print summary to stdout for CI systems
    echo ""
    echo "========================================"
    echo "ASW FRAMEWORK CI/CD TEST SUMMARY"
    echo "========================================"
    echo "Status: $(if [[ $exit_code -eq 0 ]]; then echo "PASSED"; else echo "FAILED"; fi)"
    echo "Exit Code: $exit_code"
    echo "Report: $report_file"
    echo "Results: $RESULTS_DIR"
    echo "========================================"
}

# Performance monitoring
monitor_performance() {
    log "Starting performance monitoring..."
    
    # Monitor in background
    (
        while true; do
            echo "$(date): $(docker stats --no-stream --format 'table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}' 2>/dev/null || echo 'Stats unavailable')" >> "$RESULTS_DIR/performance-$TIMESTAMP.log"
            sleep 30
        done
    ) &
    local monitor_pid=$!
    
    # Stop monitoring when script exits
    trap "kill $monitor_pid 2>/dev/null || true; cleanup" EXIT
}

# Main execution
main() {
    echo "🚀 ASW Framework CI/CD Test Runner"
    echo "=================================="
    echo "Started: $(date)"
    echo "Timeout: ${TEST_TIMEOUT}s"
    echo ""
    
    preflight_checks
    monitor_performance
    build_images
    start_environment
    
    local exit_code=0
    run_tests || exit_code=$?
    
    generate_ci_report $exit_code
    
    if [[ $exit_code -eq 0 ]]; then
        log_success "CI/CD test run completed successfully!"
    else
        log_error "CI/CD test run failed!"
    fi
    
    exit $exit_code
}

# Handle command line arguments
case "${1:-run}" in
    run)
        main
        ;;
    build)
        preflight_checks
        build_images
        ;;
    clean)
        cleanup
        ;;
    help|--help|-h)
        echo "Usage: $0 [command]"
        echo ""
        echo "Commands:"
        echo "  run     Run full CI/CD test suite (default)"
        echo "  build   Build test images only"
        echo "  clean   Clean up test environment"
        echo "  help    Show this help"
        echo ""
        echo "Environment Variables:"
        echo "  DOCKER_COMPOSE_FILE  Docker Compose file to use (default: docker-compose.test.yml)"
        echo "  TEST_TIMEOUT         Test timeout in seconds (default: 1800)"
        echo "  CI_BUILD_ID          CI build identifier"
        echo "  CI_BRANCH            Git branch name"
        echo "  CI_COMMIT            Git commit hash"
        ;;
    *)
        echo "Unknown command: $1"
        echo "Use '$0 help' for usage information"
        exit 1
        ;;
esac