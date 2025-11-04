# Claude Docker - Simple Windows Setup

**The easier way to run Claude Docker on Windows!**

No complex builds, no credential baking - just spin up a container and go.

## Quick Start

### Prerequisites

1. **Docker Desktop** - Make sure it's running
2. **Claude authenticated** on Windows:
   ```cmd
   npm install -g @anthropic-ai/claude-code
   claude
   ```

### Run It!

**Option 1: Batch File (double-click)**
```cmd
run-windows.bat
```

**Option 2: PowerShell**
```powershell
.\run-windows.ps1
```

That's it! The first time will build a minimal Docker image (takes ~2 minutes), then you'll be in a container shell.

### Inside the Container

```bash
# Just run Claude!
claude

# Exit when done
exit
```

## What This Does Differently

This is a **simpler alternative** to the full setup. It:

✅ Uses a minimal Dockerfile (just Node + tools)
✅ Handles permissions automatically on startup
✅ No credential baking into images
✅ No complex build process
✅ Easier to debug and modify

## How It Works

1. **Minimal Image**: Basic Node.js 20 + git + Claude Code
2. **Volume Mounts**: Your project + Claude config from Windows
3. **Startup Script**: Fixes permissions and copies credentials on container start
4. **Just Works**: No build context issues or line ending problems

## File Structure

After running once:
```
%USERPROFILE%\.claude-docker\
├── claude-home\          # Container's Claude config
│   └── .credentials.json # Copied from Windows on first run
├── ssh\                  # SSH keys (if you set them up)
└── scripts\              # Custom scripts (optional)
```

## Troubleshooting

### Permission Errors

The startup script automatically fixes permissions. If you still see permission issues:
```bash
# Inside container
sudo chown -R claude-user:claude-user ~/.claude
```

### Claude Not Authenticated

Make sure you authenticated Claude **on Windows first**:
```cmd
claude  # Should NOT ask for API key
```

### Docker Build Fails

Make sure Docker Desktop is running and you have internet access.

## MCP Servers

To add MCP servers, just run inside the container:
```bash
# Example: Add Twilio MCP
claude mcp add twilio -- npx -y @yiyang.1i/sms-mcp-server
```

## Rebuilding

If you need to rebuild the image:
```cmd
docker rmi claude-docker-windows:latest
run-windows.bat  # Will rebuild automatically
```

## Comparison with Full Setup

| Feature | Simple (This) | Full Setup |
|---------|--------------|------------|
| **Setup Time** | 2 minutes | 10+ minutes |
| **Build Complexity** | Minimal | Complex |
| **Debugging** | Easy | Harder |
| **Flexibility** | High | Medium |
| **MCP Install** | Inside container | During build |

## That's It!

No setup scripts, no complex builds. Just run and code.

```cmd
run-windows.bat
```
