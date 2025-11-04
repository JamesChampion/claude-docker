# Docker-in-Docker Test Suite

## Quick Start (For Users with Docker)

To test the complete claude-docker setup in an isolated environment:

```bash
cd test/dind
./run-test.sh
```

This will:
1. Build a Docker-in-Docker test image
2. Copy the entire repo into it
3. Run the installation script
4. Build the claude-docker image
5. Test that everything works

## What I've Created

This test suite includes:

### Test Files Created:
- **`Dockerfile`** - Creates a DinD environment with all dependencies
- **`entrypoint.sh`** - Starts Docker daemon and runs tests
- **`test-setup.sh`** - Comprehensive test script that validates:
  - Repository setup
  - Installation process (runs `src/install.sh`)
  - Directory structure creation
  - Shell configuration updates (.zshrc, .bashrc)
  - Docker image build
  - Container execution
- **`run-test.sh`** - Convenience wrapper to run everything
- **`README.md`** - Complete documentation

### What Gets Tested:

✓ Repository cloning and setup
✓ Mock authentication file creation
✓ `install.sh` execution
✓ Directory structure (`~/.claude-docker/`)
✓ Shell configuration (aliases and PATH)
✓ Docker image build from scratch
✓ Container startup and execution

## Why I Couldn't Run It

My current environment doesn't have Docker installed, so I can't execute the actual test. However, the test infrastructure is complete and ready for you to run on any system with Docker.

## How to Run the Tests

### Option 1: Run on Your Local Machine

```bash
# From the repository root
cd test/dind
./run-test.sh
```

### Option 2: Run in CI/CD

Add this to GitHub Actions:

```yaml
name: Test Docker-in-Docker Setup
on: [push, pull_request]
jobs:
  test-dind:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Run DinD Tests
        run: |
          cd test/dind
          ./run-test.sh
```

## Expected Output

When successful, you'll see:

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

## Test Architecture

```
test/dind/
├── Dockerfile          # DinD test environment
├── entrypoint.sh       # Starts Docker daemon
├── test-setup.sh       # Main test script
├── run-test.sh         # Convenience wrapper
└── README.md           # This file
```

The test creates a complete isolated environment that:
1. Runs Docker inside Docker (privileged mode)
2. Creates a test user with proper permissions
3. Installs Claude Code CLI
4. Runs the full installation process
5. Verifies everything works correctly

## Next Steps

1. **Run the tests** on your local machine with `./run-test.sh`
2. **Review the output** to ensure all tests pass
3. **Add to CI/CD** if you want automated testing

## Troubleshooting

If tests fail:
- Check Docker is running: `docker info`
- Ensure you have ~2GB free space
- Review logs for specific error messages
- See full troubleshooting guide in `test/dind/README.md`
