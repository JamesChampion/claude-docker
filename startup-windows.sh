#!/bin/bash
# Startup script for Windows - handles permissions and setup inside container

# Don't use set -e so we continue even if some commands fail
set -u

echo "=================================="
echo "Claude Docker - Container Startup"
echo "=================================="
echo ""

# Fix permissions on mounted .claude directory
echo "[1/4] Fixing permissions..."
# Create .claude directory if it doesn't exist
mkdir -p /home/claude-user/.claude/debug

# Try to fix ownership (may fail on some mount types, that's ok)
sudo chown -R claude-user:claude-user /home/claude-user/.claude 2>/dev/null || echo "  (chown skipped - may not be needed)"

# Make directories writable
chmod -R 755 /home/claude-user/.claude 2>/dev/null || true

# Ensure debug directory is definitely writable
sudo chmod 777 /home/claude-user/.claude/debug 2>/dev/null || chmod 777 /home/claude-user/.claude/debug 2>/dev/null || true

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
