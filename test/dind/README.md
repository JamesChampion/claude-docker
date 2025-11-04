# Docker-in-Docker Test Suite

This directory contains a comprehensive test suite for validating the claude-docker installation and setup in an isolated Docker-in-Docker environment.

## What This Tests

The test suite validates the entire claude-docker setup process:

1. **Installation**: Runs `install.sh` and verifies directory structure
2. **Configuration**: Validates `.zshrc` and `.bashrc` updates
3. **Docker Build**: Builds the claude-docker image from scratch
4. **Container Execution**: Verifies the container can start and run commands

## Why Docker-in-Docker?

Docker-in-Docker (DinD) allows us to:
- Test the complete setup in an isolated environment
- Verify Docker image builds work correctly
- Test without affecting the host system
- Ensure reproducibility across different environments

## Prerequisites

- Docker installed and running on your host system
- Sufficient disk space for building images (~2GB)

## Running the Tests

### Quick Start

```bash
# From the test/dind directory
./run-test.sh
```

### Manual Run

If you prefer to run steps manually:

```bash
# Build the test image
docker build -t claude-docker-dind-test .

# Run the tests
docker run --rm --privileged \
    -v "$(pwd)/../..:/repo:ro" \
    claude-docker-dind-test
```

## Test Execution Flow

1. **Entrypoint** (`entrypoint.sh`):
   - Starts Docker daemon inside the container
   - Waits for daemon to be ready
   - Executes the test script as a non-root user

2. **Test Script** (`test-setup.sh`):
   - Copies the repository to the test user's home
   - Creates mock `.env` and authentication files
   - Runs the installation script
   - Verifies directory structure and shell configuration
   - Builds the claude-docker image
   - Tests basic container execution

3. **Verification**:
   - Checks all expected directories exist
   - Validates shell configuration updates
   - Confirms Docker image was built
   - Tests container can start and execute commands

## Test Components

### Dockerfile
Creates a test environment with:
- Docker-in-Docker base image
- Required dependencies (bash, git, nodejs, npm, etc.)
- Test user with sudo privileges
- Claude Code CLI installed globally
- Git configuration

### entrypoint.sh
- Starts the Docker daemon
- Waits for daemon readiness
- Executes the test script as the test user

### test-setup.sh
Main test script that validates:
- Repository setup
- Installation process
- Configuration updates
- Docker image building
- Container execution

### run-test.sh
Convenience wrapper that:
- Builds the test image
- Runs the full test suite
- Reports results

## Expected Output

When tests pass, you should see:

```
=========================================
All tests passed! ✓
=========================================

Summary:
  ✓ Repository copied successfully
  ✓ Installation script completed
  ✓ Directory structure created
  ✓ Shell configuration updated
  ✓ Docker image built successfully
  ✓ Container execution verified

claude-docker is ready to use!
```

## Troubleshooting

### Docker daemon fails to start

If you see "Docker daemon failed to start within 30 seconds":
- Ensure you're running with `--privileged` flag
- Check host Docker daemon is running
- Try increasing the timeout in `entrypoint.sh`

### Build failures

If the Docker image build fails:
- Check you have sufficient disk space
- Verify internet connectivity for package downloads
- Review the build logs for specific error messages

### Permission errors

If you encounter permission issues:
- Ensure the test runs as the test user (not root)
- Check volume mount permissions
- Verify sudo is configured correctly

## Continuous Integration

This test suite is designed to be run in CI/CD pipelines:

```yaml
# Example GitHub Actions workflow
test:
  runs-on: ubuntu-latest
  steps:
    - uses: actions/checkout@v3
    - name: Run DinD tests
      run: |
        cd test/dind
        ./run-test.sh
```

## Security Notes

- Mock credentials are used for testing (no real API keys needed)
- The container runs in privileged mode (required for DinD)
- Test environment is fully isolated from host
- All test data is cleaned up when container exits

## Contributing

When modifying the test suite:
1. Test locally first with `./run-test.sh`
2. Ensure all test steps complete successfully
3. Update this README if adding new test cases
4. Keep test output clear and informative
