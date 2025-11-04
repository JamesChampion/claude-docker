#!/bin/bash
# Init script that runs inside the container on startup
# Does all the setup work

echo "===================================="
echo "Setting up Claude in container..."
echo "===================================="

# 1. Install Claude Code if not already installed
if ! command -v claude &> /dev/null; then
    echo "[1/5] Installing Claude Code..."
    npm install -g @anthropic-ai/claude-code
else
    echo "[1/5] Claude Code already installed"
fi

# 2. Install uv for MCP servers
if ! command -v uvx &> /dev/null; then
    echo "[2/5] Installing uv..."
    curl -LsSf https://astral.sh/uv/install.sh | sh
    export PATH="/home/user/.local/bin:$PATH"
else
    echo "[2/5] uv already installed"
fi

# 3. Copy credentials from Windows if needed
echo "[3/5] Setting up credentials..."
if [ -f /home/user/.claude-from-windows/.credentials.json ]; then
    mkdir -p /home/user/.claude
    if [ ! -f /home/user/.claude/.credentials.json ]; then
        cp /home/user/.claude-from-windows/.credentials.json /home/user/.claude/.credentials.json
        echo "  ✓ Copied credentials from Windows"
    else
        echo "  ✓ Credentials already exist"
    fi
else
    echo "  ⚠ No Windows credentials found"
fi

# 4. Create necessary directories with full permissions
echo "[4/5] Creating directories..."
mkdir -p /home/user/.claude/debug
chmod -R 777 /home/user/.claude 2>/dev/null || true

# 5. Set up PATH for this session
echo "[5/5] Setting up environment..."
export PATH="/home/user/.local/bin:$PATH"
echo 'export PATH="/home/user/.local/bin:$PATH"' >> /home/user/.bashrc

echo ""
echo "===================================="
echo "✓ Setup complete!"
echo ""
echo "You can now run: claude"
echo "To exit: exit"
echo "===================================="
echo ""
