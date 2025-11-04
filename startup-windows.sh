#!/bin/bash
# Startup script for Windows - handles permissions and setup inside container

set -e

echo "=================================="
echo "Claude Docker - Container Startup"
echo "=================================="
echo ""

# Fix permissions on mounted .claude directory
echo "[1/4] Fixing permissions..."
if [ -d /home/claude-user/.claude ]; then
    # Make sure claude-user owns the .claude directory
    sudo chown -R claude-user:claude-user /home/claude-user/.claude 2>/dev/null || true
    # Create debug directory if it doesn't exist
    mkdir -p /home/claude-user/.claude/debug
    chmod -R 755 /home/claude-user/.claude
fi
echo "✓ Permissions fixed"

# Copy credentials from host mount if available
echo ""
echo "[2/4] Setting up Claude authentication..."
if [ -f /home/claude-user/.claude-host/.credentials.json ]; then
    if [ ! -f /home/claude-user/.claude/.credentials.json ]; then
        cp /home/claude-user/.claude-host/.credentials.json /home/claude-user/.claude/.credentials.json
        echo "✓ Copied credentials from host"
    else
        echo "✓ Credentials already exist"
    fi
else
    echo "⚠ No host credentials found - you may need to authenticate"
fi

# Setup git config if not already set
echo ""
echo "[3/4] Checking git configuration..."
if ! git config --global user.name >/dev/null 2>&1; then
    echo "⚠ Git user.name not configured"
    echo "  You can set it inside the container with:"
    echo "  git config --global user.name 'Your Name'"
else
    echo "✓ Git configured: $(git config --global user.name)"
fi

# Ready
echo ""
echo "[4/4] Ready!"
echo ""
echo "=================================="
echo "You can now run: claude"
echo "To exit: exit"
echo "=================================="
echo ""

# Start interactive bash
exec /bin/bash
