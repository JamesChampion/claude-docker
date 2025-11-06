# Suggested Commands

## Primary Usage Commands

### Running Claude Docker
```bash
# Start in current directory
claude-docker

# Resume previous conversation
claude-docker --continue

# Force rebuild image (after .env changes)
claude-docker --rebuild

# Rebuild without cache
claude-docker --rebuild --no-cache

# Use podman instead of docker
claude-docker --podman

# Set memory limit
claude-docker --memory 8g

# Enable GPU access
claude-docker --gpus all
```

## Installation & Setup

### Initial Setup
```bash
# Clone repository
git clone https://github.com/VishalJ99/claude-docker.git
cd claude-docker

# Configure environment
cp .env.example .env
nano .env  # Add API keys

# Install
./src/install.sh
```

### SSH Key Setup (for git push)
```bash
mkdir -p ~/.claude-docker/ssh
ssh-keygen -t rsa -b 4096 -f ~/.claude-docker/ssh/id_rsa -N ''
cat ~/.claude-docker/ssh/id_rsa.pub  # Add to GitHub
```

## Development Commands

### Testing Changes
```bash
# Test scripts locally
./src/claude-docker.sh

# Check Docker image
docker images | grep claude-docker

# Inspect container
docker ps -a | grep claude-docker
```

### Git Operations (Inside Container)
```bash
git status
git diff
git add .
git commit -m "message"
git push  # Uses SSH keys from ~/.claude-docker/ssh/
```

## System Utilities (Linux-specific)

### File Operations
```bash
ls -la
find . -name "pattern"
grep -r "pattern" .
```

### Process Management
```bash
ps aux
top
htop  # If installed
```

## MCP-Related Commands

### Serena Indexing
```bash
# Index project (should be run automatically)
uvx --from git+https://github.com/oraios/serena index-project
```

## Environment Variables

### In .env file
```bash
# Twilio (optional)
TWILIO_ACCOUNT_SID=...
TWILIO_AUTH_TOKEN=...
TWILIO_FROM_NUMBER=+1234567890
TWILIO_TO_NUMBER=+0987654321

# Conda (optional)
CONDA_PREFIX=/path/to/conda
CONDA_EXTRA_DIRS="/path/to/envs /path/to/pkgs"

# System packages (optional)
SYSTEM_PACKAGES="libopenslide0 libgdal-dev"
```

## Troubleshooting

### Force Clean Rebuild
```bash
docker rmi claude-docker:latest
claude-docker --rebuild --no-cache
```

### Check Authentication
```bash
ls -la ~/.claude.json ~/.claude/.credentials.json
```

### WSL-specific
```bash
# Check Docker integration
docker ps

# Find Windows .claude.json
ls -la /mnt/c/Users/*/.claude.json
```
