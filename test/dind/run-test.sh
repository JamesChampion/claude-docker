#!/bin/bash
# Wrapper script to build and run the Docker-in-Docker test
# This script builds the test image and runs it with the claude-docker repo mounted

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Convert Windows paths for Docker Desktop
# Git Bash on Windows uses /a/, /c/, etc. which need to be converted to /a, /c for Docker
if [[ "$REPO_ROOT" =~ ^/[a-z]/ ]]; then
    # Convert /a/path/to/repo to //a/path/to/repo for Docker on Windows
    # Docker Desktop expects double slash for drive letters
    DOCKER_REPO_ROOT="/$REPO_ROOT"
    echo "Detected Windows path, converting for Docker: $DOCKER_REPO_ROOT"
else
    DOCKER_REPO_ROOT="$REPO_ROOT"
fi

echo "========================================="
echo "Docker-in-Docker Test Runner"
echo "========================================="
echo ""
echo "Repository: $REPO_ROOT"
echo "Docker path: $DOCKER_REPO_ROOT"
echo "Test directory: $SCRIPT_DIR"
echo ""

# Build the test image
echo "Step 1: Building test image..."
docker build -t claude-docker-dind-test "$SCRIPT_DIR"

echo ""
echo "Step 2: Running tests in Docker-in-Docker environment..."
echo "This will:"
echo "  1. Start a Docker daemon inside the container"
echo "  2. Copy the claude-docker repository"
echo "  3. Run the installation script"
echo "  4. Build the claude-docker image"
echo "  5. Test basic container execution"
echo ""
echo "This may take several minutes..."
echo ""

# Run the test container with privileged mode (required for DinD)
# Mount the repository as read-only at /repo
docker run --rm \
    --privileged \
    -v "$DOCKER_REPO_ROOT:/repo:ro" \
    --name claude-docker-dind-test \
    claude-docker-dind-test

echo ""
echo "========================================="
echo "Test completed successfully!"
echo "========================================="
