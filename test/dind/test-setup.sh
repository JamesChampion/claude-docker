#!/bin/bash
# Test script for claude-docker setup in Docker-in-Docker environment
# This script:
# 1. Copies the claude-docker repo
# 2. Creates mock authentication files
# 3. Runs the installation
# 4. Verifies the setup

set -e

echo "========================================="
echo "Testing claude-docker in Docker-in-Docker"
echo "========================================="

# Step 1: Copy the repo (it should be mounted from the host)
echo ""
echo "Step 1: Setting up test repository..."
if [ -d "/repo" ]; then
    echo "Copying claude-docker repository..."
    cp -r /repo /home/testuser/claude-docker
    cd /home/testuser/claude-docker

    # Convert Windows line endings to Unix (fixes pipefail error)
    echo "Converting line endings for Linux compatibility..."
    find . -type f -name "*.sh" -exec dos2unix {} \; 2>/dev/null
    find . -type f -name "*.md" -exec dos2unix {} \; 2>/dev/null

    # Make scripts executable
    chmod +x src/*.sh
    echo "✓ Made scripts executable and converted line endings"
else
    echo "ERROR: Repository not found at /repo"
    exit 1
fi

# Step 2: Create mock .env file
echo ""
echo "Step 2: Creating test .env file..."
cat > .env << 'EOF'
# Test environment file for DinD testing
# Using dummy values - real credentials not needed for testing

# Mock Twilio credentials (optional)
TWILIO_ACCOUNT_SID=test_account_sid
TWILIO_AUTH_TOKEN=test_auth_token
TWILIO_FROM_NUMBER=+1234567890
TWILIO_TO_NUMBER=+0987654321

# System packages (optional)
SYSTEM_PACKAGES=""

# Conda paths (optional)
CONDA_PREFIX=""
CONDA_EXTRA_DIRS=""
EOF

echo "✓ Created .env file with test values"

# Step 3: Create mock Claude authentication
echo ""
echo "Step 3: Creating mock Claude authentication files..."
mkdir -p ~/.claude

# Create a mock .claude.json file (minimal valid structure)
cat > ~/.claude.json << 'EOF'
{
  "sessionToken": "mock_session_token_for_testing",
  "userId": "mock_user_id"
}
EOF

# Create mock credentials file (would normally be created after authentication)
mkdir -p ~/.claude
cat > ~/.claude/.credentials.json << 'EOF'
{
  "accessToken": "mock_access_token_for_testing",
  "refreshToken": "mock_refresh_token_for_testing"
}
EOF

echo "✓ Created mock Claude authentication files"

# Step 4: Run the installation
echo ""
echo "Step 4: Running installation script..."
./src/install.sh

# Verify installation results
echo ""
echo "Step 5: Verifying installation..."

# Check if claude-home directory was created
if [ -d "$HOME/.claude-docker/claude-home" ]; then
    echo "✓ ~/.claude-docker/claude-home directory created"
else
    echo "✗ ERROR: ~/.claude-docker/claude-home directory not found"
    exit 1
fi

# Check if scripts directory was created
if [ -d "$HOME/.claude-docker/scripts" ]; then
    echo "✓ ~/.claude-docker/scripts directory created"
else
    echo "✗ ERROR: ~/.claude-docker/scripts directory not found"
    exit 1
fi

# Check if .zshrc was updated
if grep -q "claude-docker" ~/.zshrc; then
    echo "✓ claude-docker alias added to .zshrc"
else
    echo "✗ ERROR: claude-docker alias not found in .zshrc"
    exit 1
fi

# Check if PATH was updated in .bashrc
if grep -q ".claude-docker/scripts" ~/.bashrc; then
    echo "✓ Scripts directory added to .bashrc PATH"
else
    echo "✗ ERROR: Scripts directory not found in .bashrc PATH"
    exit 1
fi

# Check if PATH was updated in .zshrc
if grep -q ".claude-docker/scripts" ~/.zshrc; then
    echo "✓ Scripts directory added to .zshrc PATH"
else
    echo "✗ ERROR: Scripts directory not found in .zshrc PATH"
    exit 1
fi

# Step 6: Test Docker image build
echo ""
echo "Step 6: Testing Docker image build..."
echo "Building claude-docker image..."

# Source the .zshrc to get the alias
source ~/.zshrc

# Try to build the image by running the claude-docker script with --rebuild
# We'll do a dry-run by checking if the script executes correctly
cd /home/testuser/claude-docker

# Test that docker is accessible
if docker info >/dev/null 2>&1; then
    echo "✓ Docker daemon is accessible"
else
    echo "✗ ERROR: Cannot access Docker daemon"
    exit 1
fi

# Build the claude-docker image
echo "Building claude-docker image (this may take a few minutes)..."
/bin/bash ./src/claude-docker.sh --rebuild || {
    echo "✗ ERROR: Docker build failed"
    exit 1
}

# Verify the image was built
if docker images | grep -q "claude-docker"; then
    echo "✓ claude-docker image built successfully"
else
    echo "✗ ERROR: claude-docker image not found"
    exit 1
fi

# Step 7: Test basic container run (without actually starting Claude)
echo ""
echo "Step 7: Testing container execution..."

# Create a test project directory
mkdir -p /home/testuser/test-project
cd /home/testuser/test-project

# Try to run the container with a simple command that exits immediately
# We'll just verify the container can start and execute a command
echo "Testing container startup with echo command..."
timeout 30 docker run --rm \
    -v "$(pwd):/workspace" \
    -v "$HOME/.claude-docker/claude-home:/home/claude-user/.claude:rw" \
    -v "$HOME/.claude-docker/ssh:/home/claude-user/.ssh:rw" \
    -v "$HOME/.claude-docker/scripts:/home/claude-user/scripts:rw" \
    -e CLAUDE_CONTINUE_FLAG="" \
    --workdir /workspace \
    claude-docker:latest \
    echo "Container test successful" || {
    echo "✗ ERROR: Container execution failed"
    exit 1
}

echo "✓ Container executed successfully"

# Final summary
echo ""
echo "========================================="
echo "All tests passed! ✓"
echo "========================================="
echo ""
echo "Summary:"
echo "  ✓ Repository copied successfully"
echo "  ✓ Installation script completed"
echo "  ✓ Directory structure created"
echo "  ✓ Shell configuration updated"
echo "  ✓ Docker image built successfully"
echo "  ✓ Container execution verified"
echo ""
echo "claude-docker is ready to use!"
