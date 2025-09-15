# ASW Framework Testing Framework

A comprehensive Docker-based testing environment for the ASW (Agentic Secure Workflow) Framework that provides unit testing, integration testing, security scanning, and continuous integration.

## Overview

The testing framework provides:

- **Ubuntu-based Docker environment** matching your VPS setup
- **Comprehensive test suites** covering syntax, unit, integration, package, and security tests
- **Automated CI/CD integration** with GitHub Actions
- **Development workflow tools** including file watching and auto-testing
- **Multi-repository support** testing across all ASW framework components

## Quick Start

### 1. Run All Tests

```bash
# Build and run complete test suite
./docker/test/scripts/ci-test.sh

# Or using Docker Compose directly
docker-compose -f docker-compose.test.yml up --build -d
docker-compose -f docker-compose.test.yml exec asw-test test-runner
```

### 2. Development Mode (Watch for Changes)

```bash
# Install dependencies and start watching
./docker/test/scripts/watch-test.sh setup
./docker/test/scripts/watch-test.sh watch

# Now edit any script - tests will run automatically!
```

### 3. Run Specific Test Types

```bash
# Syntax tests only (shellcheck, JSON validation)
docker-compose -f docker-compose.test.yml exec asw-test test-runner syntax

# Unit tests only (BATS, individual test scripts)
docker-compose -f docker-compose.test.yml exec asw-test test-runner unit

# Integration tests (script execution, dependencies)
docker-compose -f docker-compose.test.yml exec asw-test test-runner integration

# Package tests (npm install, npm test)
docker-compose -f docker-compose.test.yml exec asw-test test-runner packages

# Security tests (secret scanning, permissions)
docker-compose -f docker-compose.test.yml exec asw-test test-runner security
```

## Architecture

### Docker Services

The test environment includes multiple services:

#### `asw-test` (Main Test Runner)
- **Base**: Ubuntu 22.04 (matching VPS)
- **User**: `cc-user` with sudo access
- **Tools**: All VPS tools + testing frameworks
- **Purpose**: Primary test execution environment

#### `asw-test-isolated` (Security Testing)
- **Base**: Same as main but restricted
- **Security**: No network privileges, read-only filesystem where possible
- **Purpose**: Isolated security and vulnerability testing

#### `test-postgres` (Database Testing)
- **Base**: PostgreSQL 15 Alpine
- **Purpose**: Integration testing with database components
- **Access**: Port 5433 (to avoid conflicts)

#### `test-nginx` (Web Server Testing)
- **Base**: Nginx Alpine
- **Purpose**: Web service integration testing
- **Access**: Port 8080

### Test Categories

#### 1. Syntax Tests
- **Shellcheck** validation for all `.sh` files
- **JSON** validation for all `.json` files
- **Basic syntax** checking across all script types

#### 2. Unit Tests
- **BATS** (Bash Automated Testing System) tests
- **Individual test scripts** in `scripts/tests/`
- **Isolated function testing**

#### 3. Integration Tests
- **Script execution** testing (check-phase scripts, setup scripts)
- **Dependency validation** between components
- **End-to-end workflow testing**

#### 4. Package Tests  
- **npm install** testing for all Node.js packages
- **npm test** execution for packages with test scripts
- **Package.json validation** across all submodules

#### 5. Security Tests
- **Secret scanning** for hardcoded credentials
- **File permission** auditing
- **Vulnerability scanning** with Trivy
- **Security configuration** validation

## File Structure

```
docker/
├── test/
│   ├── Dockerfile              # Multi-stage test environment
│   ├── test-config            # Test environment configuration  
│   ├── nginx.conf             # Test nginx configuration
│   └── scripts/
│       ├── test-runner.sh     # Main test orchestrator
│       ├── ci-test.sh         # CI/CD integration
│       └── watch-test.sh      # Development file watcher
├── docker-compose.test.yml    # Test services definition
├── test-results/              # Test output directory (created at runtime)
└── .github/workflows/test.yml # GitHub Actions CI/CD
```

## Development Workflow

### Making Changes

1. **Edit any script** in `scripts/` or `agentic-framework-*/`
2. **Tests run automatically** (if using watch mode)
3. **Review results** in terminal or `test-results/`
4. **Fix issues** and tests re-run

### Adding New Tests

#### BATS Tests
Create `.bats` files in any directory:

```bash
#!/usr/bin/env bats

load '/opt/bats-support/load'
load '/opt/bats-assert/load'

@test "addition using bc" {
  result="$(echo 2+2 | bc)"
  assert_equal "$result" 4
}

@test "script syntax check" {
  run bash -n /opt/asw/scripts/my-script.sh
  assert_success
}
```

#### Integration Tests
Add scripts to `scripts/tests/test-*.sh`:

```bash
#!/bin/bash
# Test script execution and dependencies

source /home/cc-user/.test-config

test_setup_temp_dir

# Your test logic here
if /opt/asw/scripts/check-phase-01-bootstrap.sh; then
    echo "✅ Bootstrap check passed"
    exit 0
else
    echo "❌ Bootstrap check failed"  
    exit 1
fi
```

## CI/CD Integration

### GitHub Actions

The framework includes comprehensive GitHub Actions workflows:

- **Automated testing** on push/PR to main branches
- **Multiple test matrices** (syntax, unit, integration, packages, security)
- **Artifact uploads** for test results and reports
- **Security scanning** with Trivy
- **Performance benchmarks** on main branch

### Custom CI Systems

Use the CI test script for other systems:

```bash
# Set environment variables
export CI_BUILD_ID="build-123"
export CI_BRANCH="feature/new-script"
export CI_COMMIT="abc123def"

# Run tests
./docker/test/scripts/ci-test.sh
```

## Test Configuration

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `ASW_TEST_ROOT` | `/opt/asw` | Root directory for ASW framework |
| `TEST_RESULTS_DIR` | `/opt/test-results` | Output directory for test results |
| `TEST_TIMEOUT` | `1800` | Test timeout in seconds |
| `WATCH_DIRS` | `scripts agentic-framework-*` | Directories to watch for changes |
| `TEST_DELAY` | `2` | Seconds to wait after file change |

### Mock Services

Tests can use mock services for external dependencies:

```bash
# Mock 1Password CLI
test_mock_1password

# Your test code here
op vault list  # Returns success

# Cleanup
test_cleanup_mocks
```

## Performance and Monitoring

### Resource Usage
The test framework monitors:
- **CPU usage** during test execution
- **Memory consumption** per service
- **Test execution time** by category
- **Docker container statistics**

### Optimization Tips
- Use **targeted tests** during development (syntax only for script edits)
- **Cache Docker layers** in CI/CD for faster builds  
- **Parallel test execution** for independent test categories
- **Resource limits** on containers to prevent resource exhaustion

## Troubleshooting

### Common Issues

#### "Docker not found"
```bash
# Install Docker
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER
# Logout and login again
```

#### "Permission denied" on test scripts
```bash
chmod +x docker/test/scripts/*.sh
```

#### "Container failed to start"
```bash
# Check logs
docker-compose -f docker-compose.test.yml logs asw-test

# Rebuild images
docker-compose -f docker-compose.test.yml build --no-cache
```

#### "Tests timeout"
```bash
# Increase timeout
export TEST_TIMEOUT=3600  # 1 hour
./docker/test/scripts/ci-test.sh
```

### Debug Mode

Run tests with additional debugging:

```bash
# Enable debug output
docker-compose -f docker-compose.test.yml exec asw-test bash -x /opt/asw/docker/test/scripts/test-runner.sh syntax

# Access test container directly
docker-compose -f docker-compose.test.yml exec asw-test bash

# Inside container - run individual tests
source ~/.test-config
shellcheck /opt/asw/scripts/complete-server-setup.sh
```

## Integration with Existing Tools

### Claude Code IDE
The testing framework integrates with Claude Code:

```bash
# Run from Claude Code terminal
claude test-runner.sh all

# Or specific types
claude test-runner.sh syntax
```

### 1Password Integration
Tests can safely mock 1Password CLI:

```bash
# In test scripts
test_mock_1password
# Now op commands return success without real 1Password access
```

### ASW Framework Tools
All ASW framework commands are available in test containers:

- `asw-dev-server`
- `asw-port-manager` 
- `asw-nginx-manager`
- `asw-init`
- `asw-scan`

## Best Practices

### Writing Tests

1. **Test one thing** per test function
2. **Use descriptive names** for test functions
3. **Clean up** temporary files and processes
4. **Mock external dependencies** (APIs, services)
5. **Test edge cases** and error conditions

### Test Organization

1. **Group related tests** in the same file
2. **Use consistent naming** (`test-*.sh`, `*.bats`)
3. **Document test purpose** in comments
4. **Keep tests independent** - no dependencies between tests

### Performance

1. **Use targeted tests** during development
2. **Cache dependencies** where possible
3. **Parallelize independent tests**
4. **Clean up resources** after tests

## Contributing

### Adding New Test Categories

1. **Extend test-runner.sh** with new test function
2. **Add command-line option** for new category
3. **Update documentation** with examples
4. **Test the new category** in CI/CD

### Improving Test Coverage

1. **Identify untested scripts** using coverage tools
2. **Add BATS tests** for complex functions
3. **Create integration tests** for new workflows  
4. **Update security tests** for new configurations

---

## Examples

### Run Tests for Specific Script

```bash
# Test just the setup script
docker-compose -f docker-compose.test.yml exec asw-test \
  bash -c "shellcheck /opt/asw/scripts/complete-server-setup.sh"
```

### Development Workflow

```bash
# Terminal 1: Start file watcher
./docker/test/scripts/watch-test.sh

# Terminal 2: Edit scripts
vim scripts/check-phase-01-bootstrap.sh
# Tests run automatically when you save!

# Terminal 3: Check results  
cat test-results/test-report-*.md
```

### CI/CD Integration

```bash
# Local CI test
./docker/test/scripts/ci-test.sh

# Check results
ls -la test-results/
cat test-results/ci-report-*.md
```

This testing framework provides comprehensive coverage for all ASW Framework components while maintaining the flexibility to adapt to new requirements and testing scenarios.