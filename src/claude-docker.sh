#!/usr/bin/env bash
set -euo pipefail
trap 'echo "$0: line $LINENO: $BASH_COMMAND: exitcode $?"' ERR
# ABOUTME: Wrapper script to run Claude Code in Docker container
# ABOUTME: Handles project mounting, .claude setup, and environment variables

# Parse command line arguments
DOCKER="${DOCKER:-docker}"
NO_CACHE=""
FORCE_REBUILD=false
CONTINUE_FLAG=""
MEMORY_LIMIT=""
GPU_ACCESS=""
DAEMON_MODE=true  # Default to daemon mode
COMMAND_MODE=""   # stop, restart, status, or empty for normal
ARGS=()

while [[ $# -gt 0 ]]; do
    case $1 in
        --podman)
            DOCKER=podman
            shift
            ;;
        --no-cache)
            NO_CACHE="--no-cache"
            shift
            ;;
        --rebuild)
            FORCE_REBUILD=true
            shift
            ;;
        --continue)
            CONTINUE_FLAG="--continue"
            shift
            ;;
        --memory)
            MEMORY_LIMIT="$2"
            shift 2
            ;;
        --gpus)
            GPU_ACCESS="$2"
            shift 2
            ;;
        --once)
            DAEMON_MODE=false
            shift
            ;;
        --stop)
            COMMAND_MODE="stop"
            shift
            ;;
        --restart)
            COMMAND_MODE="restart"
            shift
            ;;
        --status)
            COMMAND_MODE="status"
            shift
            ;;
        *)
            ARGS+=("$1")
            shift
            ;;
    esac
done

# Get the absolute path of the current directory
CURRENT_DIR=$(pwd)
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Generate container name from project directory
CONTAINER_NAME="claude-docker-$(basename "$CURRENT_DIR")"

# Helper functions for daemon management
check_container_running() {
    "$DOCKER" ps -q -f name="$CONTAINER_NAME" 2>/dev/null | grep -q .
}

check_container_exists() {
    "$DOCKER" ps -aq -f name="$CONTAINER_NAME" 2>/dev/null | grep -q .
}

stop_container() {
    if check_container_exists; then
        echo "Stopping Claude Docker daemon for $(basename "$CURRENT_DIR")..."
        "$DOCKER" stop "$CONTAINER_NAME" >/dev/null 2>&1 || true
        "$DOCKER" rm "$CONTAINER_NAME" >/dev/null 2>&1 || true
        echo "✓ Daemon stopped"
        return 0
    else
        echo "No daemon running for this project"
        return 1
    fi
}

get_container_status() {
    if check_container_running; then
        echo "✓ Claude Docker daemon is running for $(basename "$CURRENT_DIR")"
        echo "  Container: $CONTAINER_NAME"
        "$DOCKER" ps -f name="$CONTAINER_NAME" --format "table {{.Status}}\t{{.CreatedAt}}"
        return 0
    elif check_container_exists; then
        echo "⚠️  Claude Docker daemon exists but is stopped for $(basename "$CURRENT_DIR")"
        return 1
    else
        echo "No Claude Docker daemon for $(basename "$CURRENT_DIR")"
        return 1
    fi
}

# Handle command modes (stop, restart, status) early
case "$COMMAND_MODE" in
    stop)
        stop_container
        exit $?
        ;;
    restart)
        stop_container
        echo "Restarting daemon..."
        # Continue to normal startup flow
        ;;
    status)
        get_container_status
        exit $?
        ;;
esac

# Detect if running in WSL and find Windows home directory
WINDOWS_HOME=""
if grep -qi microsoft /proc/version 2>/dev/null || grep -qi wsl /proc/version 2>/dev/null; then
    # We're in WSL - try to find Windows username
    # First check WSLENV or common Windows environment variables
    if [ -n "${USERPROFILE:-}" ]; then
        # USERPROFILE is set (e.g., C:\Users\Username)
        WINDOWS_USER=$(basename "$USERPROFILE")
        WINDOWS_HOME="/mnt/c/Users/$WINDOWS_USER"
    elif [ -d "/mnt/c/Users" ]; then
        # Try to find the most recently modified user directory (likely the active user)
        WINDOWS_USER=$(ls -t /mnt/c/Users | grep -v "^Public$\|^Default$\|^All Users$" | head -n1)
        if [ -n "$WINDOWS_USER" ]; then
            WINDOWS_HOME="/mnt/c/Users/$WINDOWS_USER"
        fi
    fi
    if [ -n "$WINDOWS_HOME" ]; then
        echo "✓ WSL detected - Windows home: $WINDOWS_HOME"
    fi
fi

# Check if .claude directory exists in current project, create if not
if [ ! -d "$CURRENT_DIR/.claude" ]; then
    echo "Creating .claude directory for this project..."
    mkdir -p "$CURRENT_DIR/.claude"
    
    # Copy template files
    cp "$PROJECT_ROOT/.claude/CLAUDE.md" "$CURRENT_DIR/.claude/"
    
    # Create scratchpad.md if it doesn't exist
    if [ ! -f "$CURRENT_DIR/scratchpad.md" ]; then
        cp "$PROJECT_ROOT/.claude/scratchpad.md" "$CURRENT_DIR/"
    fi
    
    echo "✓ Claude configuration created"
fi

# Check if .env exists in claude-docker directory for building
ENV_FILE="$PROJECT_ROOT/.env"
if [ -f "$ENV_FILE" ]; then
    echo "✓ Found .env file with credentials"
    # Source .env to get configuration variables
    set -a
    source "$ENV_FILE" 2>/dev/null || true
    set +a
else
    echo "⚠️  No .env file found at $ENV_FILE"
    echo "   Twilio MCP features will be unavailable."
    echo "   To enable: copy .env.example to .env in the claude-docker repository and add your credentials"
fi

# Use environment variables as defaults if command line args not provided
if [ -z "${MEMORY_LIMIT:-}" ] && [ -n "${DOCKER_MEMORY_LIMIT:-}" ]; then
    MEMORY_LIMIT="$DOCKER_MEMORY_LIMIT"
    echo "✓ Using memory limit from environment: $MEMORY_LIMIT"
fi

if [ -z "${GPU_ACCESS:-}" ] && [ -n "${DOCKER_GPU_ACCESS:-}" ]; then
    GPU_ACCESS="$DOCKER_GPU_ACCESS"
    echo "✓ Using GPU access from environment: $GPU_ACCESS"
fi

# Check if we need to rebuild the image
NEED_REBUILD=false

if ! "$DOCKER" images | grep -q "claude-docker"; then
    echo "Building Claude Docker image for first time..."
    NEED_REBUILD=true
fi

if [ "$FORCE_REBUILD" = true ]; then
    echo "Forcing rebuild of Claude Docker image..."
    NEED_REBUILD=true
fi

# Warn if --no-cache is used without rebuild
if [ -n "${NO_CACHE:-}" ] && [ "$NEED_REBUILD" = false ]; then
    echo "⚠️  Warning: --no-cache flag set but image already exists. Use --rebuild --no-cache to force rebuild without cache."
fi

if [ "$NEED_REBUILD" = true ]; then
    # Copy authentication files to build context
    # Check both WSL home and Windows home (if in WSL)
    CLAUDE_JSON_PATH=""
    if [ -f "$HOME/.claude.json" ]; then
        CLAUDE_JSON_PATH="$HOME/.claude.json"
        echo "✓ Found Claude authentication in WSL home"
    elif [ -n "$WINDOWS_HOME" ] && [ -f "$WINDOWS_HOME/.claude.json" ]; then
        CLAUDE_JSON_PATH="$WINDOWS_HOME/.claude.json"
        echo "✓ Found Claude authentication in Windows home"
    fi

    if [ -n "$CLAUDE_JSON_PATH" ]; then
        cp "$CLAUDE_JSON_PATH" "$PROJECT_ROOT/.claude.json"
    else
        echo "⚠️  No .claude.json found. Claude Code authentication required."
        if [ -n "$WINDOWS_HOME" ]; then
            echo "   Checked: $HOME/.claude.json and $WINDOWS_HOME/.claude.json"
        else
            echo "   Checked: $HOME/.claude.json"
        fi
    fi

    # Get git config from host
    GIT_USER_NAME=$(git config --global --get user.name 2>/dev/null || echo "")
    GIT_USER_EMAIL=$(git config --global --get user.email 2>/dev/null || echo "")
    
    # Build docker command with conditional system packages and git config
    BUILD_ARGS="--build-arg USER_UID=$(id -u) --build-arg USER_GID=$(id -g)"
    if [ -n "${GIT_USER_NAME:-}" ] && [ -n "${GIT_USER_EMAIL:-}" ]; then
        BUILD_ARGS="$BUILD_ARGS --build-arg GIT_USER_NAME=\"$GIT_USER_NAME\" --build-arg GIT_USER_EMAIL=\"$GIT_USER_EMAIL\""
    fi
    if [ -n "${SYSTEM_PACKAGES:-}" ]; then
        echo "✓ Building with additional system packages: $SYSTEM_PACKAGES"
        BUILD_ARGS="$BUILD_ARGS --build-arg SYSTEM_PACKAGES=\"$SYSTEM_PACKAGES\""
    fi
    
    eval "'$DOCKER' build $NO_CACHE $BUILD_ARGS -t claude-docker:latest \"$PROJECT_ROOT\""
    
    # Clean up copied auth files
    rm -f "$PROJECT_ROOT/.claude.json"
fi

# Ensure the claude-home and ssh directories exist
mkdir -p "$HOME/.claude-docker/claude-home"
mkdir -p "$HOME/.claude-docker/ssh"

# Copy authentication files to persistent claude-home if they don't exist
# Check both WSL home and Windows home (if in WSL)
if [ ! -f "$HOME/.claude-docker/claude-home/.credentials.json" ]; then
    CREDENTIALS_PATH=""
    if [ -f "$HOME/.claude/.credentials.json" ]; then
        CREDENTIALS_PATH="$HOME/.claude/.credentials.json"
    elif [ -n "$WINDOWS_HOME" ] && [ -f "$WINDOWS_HOME/.claude/.credentials.json" ]; then
        CREDENTIALS_PATH="$WINDOWS_HOME/.claude/.credentials.json"
    fi

    if [ -n "$CREDENTIALS_PATH" ]; then
        echo "✓ Copying Claude credentials to persistent directory"
        cp "$CREDENTIALS_PATH" "$HOME/.claude-docker/claude-home/.credentials.json"
    fi
fi

# Log information about persistent Claude home directory
echo ""
echo "📁 Claude persistent home directory: ~/.claude-docker/claude-home/"
echo "   This directory contains Claude's settings and CLAUDE.md instructions"
echo "   Modify files here to customize Claude's behavior across all projects"
echo ""

# Check SSH key setup
SSH_KEY_PATH="$HOME/.claude-docker/ssh/id_rsa"
SSH_PUB_KEY_PATH="$HOME/.claude-docker/ssh/id_rsa.pub"

if [ ! -f "$SSH_KEY_PATH" ] || [ ! -f "$SSH_PUB_KEY_PATH" ]; then
    echo ""
    echo "⚠️  SSH keys not found for git operations"
    echo "   To enable git push/pull in Claude Docker:"
    echo ""
    echo "   1. Generate SSH key:"
    echo "      ssh-keygen -t rsa -b 4096 -f ~/.claude-docker/ssh/id_rsa -N ''"
    echo ""
    echo "   2. Add public key to GitHub:"
    echo "      cat ~/.claude-docker/ssh/id_rsa.pub"
    echo "      # Copy output and add to: GitHub → Settings → SSH Keys"
    echo ""
    echo "   3. Test connection:"
    echo "      ssh -T git@github.com -i ~/.claude-docker/ssh/id_rsa"
    echo ""
    echo "   Claude will continue without SSH keys (read-only git operations only)"
    echo ""
else
    echo "✓ SSH keys found for git operations"
    
    # Create SSH config if it doesn't exist
    SSH_CONFIG_PATH="$HOME/.claude-docker/ssh/config"
    if [ ! -f "$SSH_CONFIG_PATH" ]; then
        cat > "$SSH_CONFIG_PATH" << 'EOF'
Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_rsa
    IdentitiesOnly yes
EOF
        echo "✓ SSH config created for GitHub"
    fi
fi

# Prepare additional mount arguments
MOUNT_ARGS=""
ENV_ARGS=""
DOCKER_OPTS=""

# Add memory limit if specified
if [ -n "${MEMORY_LIMIT:-}" ]; then
    echo "✓ Setting memory limit: $MEMORY_LIMIT"
    DOCKER_OPTS="$DOCKER_OPTS --memory $MEMORY_LIMIT"
fi

# Add GPU access if specified
if [ -n "${GPU_ACCESS:-}" ]; then
    # Check if nvidia-docker2 or nvidia-container-runtime is available
    if "$DOCKER" info 2>/dev/null | grep -q nvidia || which nvidia-docker >/dev/null 2>&1; then
        echo "✓ Enabling GPU access: $GPU_ACCESS"
        DOCKER_OPTS="$DOCKER_OPTS --gpus $GPU_ACCESS"
    else
        echo "⚠️  GPU access requested but NVIDIA Docker runtime not found"
        echo "   Install nvidia-docker2 or nvidia-container-runtime to enable GPU support"
        echo "   Continuing without GPU access..."
    fi
fi

# Mount conda installation if specified
if [ -n "${CONDA_PREFIX:-}" ] && [ -d "$CONDA_PREFIX" ]; then
    echo "✓ Mounting conda installation from $CONDA_PREFIX"
    MOUNT_ARGS="$MOUNT_ARGS -v $CONDA_PREFIX:$CONDA_PREFIX:ro"
    ENV_ARGS="$ENV_ARGS -e CONDA_PREFIX=$CONDA_PREFIX -e CONDA_EXE=$CONDA_PREFIX/bin/conda"
else
    echo "No conda installation configured"
fi

# Mount additional conda directories if specified
if [ -n "${CONDA_EXTRA_DIRS:-}" ]; then
    echo "✓ Mounting additional conda directories..."
    CONDA_ENVS_PATHS=""
    CONDA_PKGS_PATHS=""
    for dir in $CONDA_EXTRA_DIRS; do
        if [ -d "$dir" ]; then
            echo "  - Mounting $dir"
            MOUNT_ARGS="$MOUNT_ARGS -v $dir:$dir:ro"
            # Build comma-separated list for CONDA_ENVS_DIRS
            if [[ "$dir" == *"env"* ]]; then
                if [ -z "${CONDA_ENVS_PATHS:-}" ]; then
                    CONDA_ENVS_PATHS="$dir"
                else
                    CONDA_ENVS_PATHS="$CONDA_ENVS_PATHS:$dir"
                fi
            fi
            # Build comma-separated list for CONDA_PKGS_DIRS
            if [[ "$dir" == *"pkg"* ]]; then
                if [ -z "${CONDA_PKGS_PATHS:-}" ]; then
                    CONDA_PKGS_PATHS="$dir"
                else
                    CONDA_PKGS_PATHS="$CONDA_PKGS_PATHS:$dir"
                fi
            fi
        else
            echo "  - Skipping $dir (not found)"
        fi
    done
    # Set CONDA_ENVS_DIRS environment variable if we found env paths
    if [ -n "${CONDA_ENVS_PATHS:-}" ]; then
        ENV_ARGS="$ENV_ARGS -e CONDA_ENVS_DIRS=$CONDA_ENVS_PATHS"
        echo "  - Setting CONDA_ENVS_DIRS=$CONDA_ENVS_PATHS"
    fi
    # Set CONDA_PKGS_DIRS environment variable if we found pkg paths
    if [ -n "${CONDA_PKGS_PATHS:-}" ]; then
        ENV_ARGS="$ENV_ARGS -e CONDA_PKGS_DIRS=$CONDA_PKGS_PATHS"
        echo "  - Setting CONDA_PKGS_DIRS=$CONDA_PKGS_PATHS"
    fi
else
    echo "No additional conda directories configured"
fi

# Run Claude Code in Docker
if [ "$DAEMON_MODE" = true ]; then
    # Daemon mode: persistent container
    if check_container_running; then
        echo "✓ Attaching to existing Claude Docker daemon..."
        echo "  (Use 'claude-docker --stop' to stop the daemon)"
        echo ""

        # Attach to running container
        "$DOCKER" exec -it "$CONTAINER_NAME" /bin/bash -c "cd /workspace && claude --dangerously-skip-permissions ${CONTINUE_FLAG} ${ARGS[*]}"
    else
        # Start new daemon container
        echo "Starting Claude Docker daemon..."
        echo "  (Use 'claude-docker --stop' to stop when done)"
        echo ""

        # Remove old stopped container if it exists
        if check_container_exists; then
            "$DOCKER" rm "$CONTAINER_NAME" >/dev/null 2>&1 || true
        fi

        # Start container in detached mode with sleep infinity to keep it alive
        "$DOCKER" run -d \
            $DOCKER_OPTS \
            -v "$CURRENT_DIR:/workspace" \
            -v "$HOME/.claude-docker/claude-home:/home/claude-user/.claude:rw" \
            -v "$HOME/.claude-docker/ssh:/home/claude-user/.ssh:rw" \
            -v "$HOME/.claude-docker/scripts:/home/claude-user/scripts:rw" \
            $MOUNT_ARGS \
            $ENV_ARGS \
            -e CLAUDE_CONTINUE_FLAG="$CONTINUE_FLAG" \
            --workdir /workspace \
            --name "$CONTAINER_NAME" \
            claude-docker:latest \
            sleep infinity >/dev/null

        echo "✓ Daemon started"
        echo ""

        # Now attach and run claude
        "$DOCKER" exec -it "$CONTAINER_NAME" /bin/bash -c "cd /workspace && claude --dangerously-skip-permissions ${CONTINUE_FLAG} ${ARGS[*]}"
    fi
else
    # Once mode: ephemeral container (original behavior)
    echo "Starting Claude Code in ephemeral mode..."
    "$DOCKER" run -it --rm \
        $DOCKER_OPTS \
        -v "$CURRENT_DIR:/workspace" \
        -v "$HOME/.claude-docker/claude-home:/home/claude-user/.claude:rw" \
        -v "$HOME/.claude-docker/ssh:/home/claude-user/.ssh:rw" \
        -v "$HOME/.claude-docker/scripts:/home/claude-user/scripts:rw" \
        $MOUNT_ARGS \
        $ENV_ARGS \
        -e CLAUDE_CONTINUE_FLAG="$CONTINUE_FLAG" \
        --workdir /workspace \
        --name "claude-docker-$(basename "$CURRENT_DIR")-$$" \
        claude-docker:latest "${ARGS[@]}"
fi
