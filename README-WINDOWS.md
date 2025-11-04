# Claude Docker - Windows Setup Guide

This guide provides **Windows-specific** instructions for using Claude Docker with Docker Compose.

## Why Docker Compose for Windows?

The original bash scripts (`install.sh`, `claude-docker.sh`) are designed for Linux/Mac and don't work well on Windows. This Docker Compose setup provides:

✅ **Native Windows compatibility** - Works on Windows 10/11
✅ **Simpler setup** - No WSL or Git Bash required
✅ **Easy to use** - Just run a batch file or PowerShell script
✅ **All the same features** - Full Claude Code functionality with MCP servers

## Prerequisites

### 1. Docker Desktop (Required)

Download and install Docker Desktop for Windows:
- **Download**: https://docs.docker.com/desktop/install/windows-install/
- **After installation**: Make sure Docker Desktop is running (check system tray)

### 2. Claude Code Authentication (Required)

You must authenticate Claude Code on your Windows machine first:

```powershell
# Install Claude Code globally (in PowerShell or CMD)
npm install -g @anthropic-ai/claude-code

# Run and complete authentication
claude

# Verify authentication files exist
dir $env:USERPROFILE\.claude.json
dir $env:USERPROFILE\.claude\
```

📖 **Full Claude Code Setup Guide**: https://docs.anthropic.com/en/docs/claude-code

### 3. Git Configuration (Required)

Configure git on your Windows system:

```powershell
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
```

## Quick Start

### Step 1: One-Time Setup

You need to run the setup script **once** to build the Docker image:

**Using Batch File:**
```cmd
git clone https://github.com/VishalJ99/claude-docker.git
cd claude-docker
setup-windows.bat
```

**Using PowerShell:**
```powershell
git clone https://github.com/VishalJ99/claude-docker.git
cd claude-docker
.\setup-windows.ps1
```

**Note**: If you get an execution policy error in PowerShell, run:
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

The setup script will:
1. Check Docker is running
2. Verify Claude Code authentication
3. Copy authentication files to build context
4. Create .env file (prompts you to edit it)
5. Create persistent directories
6. Build the Docker image (takes a few minutes first time)

### Step 2: Run Claude Docker

After setup is complete, start Claude Docker:

**Using Batch File:**
```cmd
start-claude-docker.bat
```

**Using PowerShell:**
```powershell
.\start-claude-docker.ps1
```

**Using Docker Compose Directly:**
```cmd
# Set environment variables first
set HOME=%USERPROFILE%
set PROJECT_DIR=%CD%

# Start the container
docker-compose run --rm claude-docker
```

**Inside the container:**
```bash
# Start Claude Code
claude

# When done, exit the container
exit
```

## Configuration

### Environment Variables (.env)

Edit the `.env` file in the `claude-docker` directory:

```bash
# SMS notifications (optional - highly recommended!)
TWILIO_ACCOUNT_SID=your_twilio_sid
TWILIO_AUTH_TOKEN=your_twilio_auth_token
TWILIO_FROM_NUMBER=+1234567890
TWILIO_TO_NUMBER=+0987654321

# Git configuration (auto-detected from your Windows git config)
GIT_USER_NAME=Your Name
GIT_USER_EMAIL=your.email@example.com

# Optional - System packages
SYSTEM_PACKAGES="libopenslide0 libgdal-dev"

# Optional - Resource limits
DOCKER_MEMORY_LIMIT=8g
DOCKER_CPU_LIMIT=4
```

### SSH Keys for Git Push/Pull (Optional)

To enable git push/pull operations:

1. **Create SSH directory**:
   ```powershell
   mkdir $env:USERPROFILE\.claude-docker\ssh
   ```

2. **Generate SSH key** (in PowerShell or Git Bash):
   ```bash
   ssh-keygen -t rsa -b 4096 -f $env:USERPROFILE\.claude-docker\ssh\id_rsa -N ""
   ```

3. **Add public key to GitHub**:
   ```powershell
   # Display the public key
   Get-Content $env:USERPROFILE\.claude-docker\ssh\id_rsa.pub

   # Copy the output and add to: GitHub → Settings → SSH Keys
   ```

4. **Test connection**:
   ```bash
   ssh -T git@github.com -i $env:USERPROFILE\.claude-docker\ssh\id_rsa
   ```

## Directory Structure

The setup creates the following directories in your Windows user profile:

```
%USERPROFILE%\.claude-docker\
├── claude-home\          # Claude configuration and settings
│   ├── .credentials.json # Claude authentication
│   ├── CLAUDE.md         # Instructions for Claude
│   └── settings.json     # MCP server configuration
├── ssh\                  # SSH keys for git operations
│   ├── id_rsa           # Private key
│   ├── id_rsa.pub       # Public key
│   └── config           # SSH config
└── scripts\             # Shared utility scripts
    └── sys_utils.py     # Common utilities
```

## Using with Your Projects

### Method 1: Mount Your Project

Edit `docker-compose.yml` and change the PROJECT_DIR:

```yaml
volumes:
  - C:/path/to/your/project:/workspace
```

Or set it as an environment variable:

```powershell
$env:PROJECT_DIR = "C:\path\to\your\project"
docker-compose run --rm claude-docker
```

### Method 2: Work Inside the Container

1. Start the container in the claude-docker directory
2. Inside the container, clone your project:
   ```bash
   cd /workspace
   git clone https://github.com/yourusername/yourproject.git
   cd yourproject
   claude
   ```

## Command Reference

### Starting Claude

```bash
# Inside the container
claude                  # Start new conversation
claude --continue       # Resume previous conversation
```

### Container Management

```powershell
# Start interactive shell
docker-compose run --rm claude-docker

# Start and run Claude directly
docker-compose run --rm claude-docker /bin/bash -c "claude"

# Rebuild image after changing .env
docker-compose build --no-cache

# Remove old containers
docker-compose down
```

## Troubleshooting

### Docker Desktop Not Running

**Error**: "Cannot connect to Docker daemon"

**Solution**: Start Docker Desktop from the Start menu

### Line Endings Error During Build

**Error**: `/usr/bin/env: 'bash\r': No such file or directory`

**Solution**: This happens when shell scripts have Windows line endings (CRLF) instead of Unix line endings (LF).

**If you cloned BEFORE the .gitattributes fix was added:**
1. Delete the repository directory
2. Re-clone the repository (it will now have correct line endings)
3. Run setup-windows.bat again

**The fix is already in place** - the Dockerfile now automatically converts line endings during build, and `.gitattributes` ensures new clones use correct line endings.

### Path Issues

**Error**: "Volume path is invalid"

**Solution**: Use forward slashes in paths:
- ✅ `C:/Users/YourName/project`
- ❌ `C:\Users\YourName\project`

Or use PowerShell variables:
```powershell
$env:PROJECT_DIR = (Get-Location).Path
```

### Authentication Issues

**Error**: "Claude authentication failed"

**Solution**: Make sure you've authenticated Claude on Windows first:
```powershell
claude  # This should NOT ask for API key
```

### SSH Key Permissions

**Error**: "WARNING: UNPROTECTED PRIVATE KEY FILE!"

**Solution**: Set proper permissions on the SSH key:
```powershell
icacls $env:USERPROFILE\.claude-docker\ssh\id_rsa /inheritance:r
icacls $env:USERPROFILE\.claude-docker\ssh\id_rsa /grant:r "$env:USERNAME:R"
```

### Container Can't Access Host Files

**Error**: "Permission denied" when accessing mounted directories

**Solution**:
1. Ensure Docker Desktop has access to the drive:
   - Docker Desktop → Settings → Resources → File Sharing
   - Add the drive (e.g., C:) to the shared drives list
2. Restart Docker Desktop

### .env File Not Loading

**Error**: Environment variables not set

**Solution**: Make sure .env is in the same directory as docker-compose.yml:
```powershell
# Check if .env exists
Test-Path .\\.env

# If not, create it from example
Copy-Item .env.example .env
```

## Advanced Configuration

### Custom Docker Compose Settings

You can customize `docker-compose.yml` for your needs:

**Add more volumes**:
```yaml
volumes:
  - C:/my/data:/data
  - D:/backups:/backups
```

**Set resource limits**:
```yaml
mem_limit: 16g
cpus: 8
```

**Enable GPU access** (requires NVIDIA Docker):
```yaml
deploy:
  resources:
    reservations:
      devices:
        - driver: nvidia
          count: all
          capabilities: [gpu]
```

## Features Available

All the features from the main README work on Windows:

✅ **Full Claude Code autonomy**
✅ **MCP servers** (Serena, Context7, Twilio)
✅ **SMS notifications**
✅ **Persistent conversation history**
✅ **Git integration with SSH**
✅ **Conda environment support**
✅ **Custom scripts and utilities**

## Getting Help

- **Main README**: [README.md](README.md)
- **MCP Setup**: [MCP_SERVERS.md](MCP_SERVERS.md)
- **Claude Code Docs**: https://docs.anthropic.com/en/docs/claude-code
- **Docker Desktop Docs**: https://docs.docker.com/desktop/

## What's Different from Linux/Mac?

The Windows setup uses Docker Compose instead of bash scripts:

| Feature | Linux/Mac | Windows |
|---------|-----------|---------|
| **Setup Script** | `install.sh` | Not needed |
| **Launcher** | `claude-docker.sh` | `.bat` or `.ps1` scripts |
| **Docker Compose** | Not used | Primary method |
| **Features** | All | All (identical) |

Both setups achieve the same result - the Windows version just uses Docker Compose to avoid bash script compatibility issues.

## Next Steps

1. ✅ Install Docker Desktop
2. ✅ Authenticate Claude Code on Windows
3. ✅ Clone this repository
4. ✅ Run `setup-windows.bat` or `setup-windows.ps1` (one-time setup)
5. ✅ Run `start-claude-docker.bat` or `start-claude-docker.ps1`
6. ✅ Start coding with Claude!

**Important**: After updating .env or changing system packages, run the setup script again to rebuild the image.

Happy coding! 🚀
