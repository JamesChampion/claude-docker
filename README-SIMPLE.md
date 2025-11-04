# Claude Docker - Dead Simple Setup

The absolute simplest way to run Claude in Docker. No complex builds, everything happens at runtime.

## How It Works

1. Spins up a minimal container (Node.js + basic tools)
2. Runs `init-container.sh` inside the container to install Claude Code
3. Drops you into a shell where you can run `claude`

## Quick Start

```cmd
start-simple.bat
```

That's it!

## What Happens

When you run `start-simple.bat`:

1. **Builds minimal Docker image** (if not already built)
   - Node.js 20
   - Git, curl, Python, build tools
   - A user account

2. **Starts container** with:
   - Your project mounted at `/workspace`
   - Windows `.claude` mounted (read-only) to copy credentials
   - Persistent volume for container's `.claude` directory

3. **Runs `init-container.sh`** which:
   - Installs Claude Code globally (`npm install -g @anthropic-ai/claude-code`)
   - Installs `uv` for MCP servers
   - Copies credentials from Windows
   - Creates directories with proper permissions
   - Sets up PATH

4. **Drops you into bash** where you can run `claude`

## Files

- `Dockerfile.simple` - Minimal base image
- `docker-compose.simple.yml` - Volume mounts and startup command
- `init-container.sh` - Setup script that runs inside container
- `start-simple.bat` / `start-simple.ps1` - Launch scripts

## Troubleshooting

### "Claude command not found"

The init script should install it automatically. If not:
```bash
npm install -g @anthropic-ai/claude-code
```

### Permission errors

```bash
chmod -R 777 ~/.claude
```

### Need to add MCP servers

Inside the container:
```bash
# Install uv (if not already)
curl -LsSf https://astral.sh/uv/install.sh | sh

# Add MCP servers
claude mcp add serena -- uvx --from git+https://github.com/oraios/serena serena-mcp-server
```

## Starting Fresh

To rebuild everything:
```cmd
docker-compose -f docker-compose.simple.yml down -v
docker rmi claude-simple:latest
start-simple.bat
```

## That's It

No complex setup, no credential baking, no multi-step process. Just run it.
