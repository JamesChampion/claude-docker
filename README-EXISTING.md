# Claude Docker - Windows with Existing Setup

Uses the **existing working Dockerfile and scripts** from the repo. No new files needed!

## What This Does

Creates a simple docker-compose.yml that uses:
- ✅ Existing `Dockerfile`
- ✅ Existing `src/startup.sh`
- ✅ Existing `install-mcp-servers.sh`
- ✅ Existing everything!

Just adds a Windows-friendly launcher.

## Quick Start

```cmd
run-existing.bat
```

That's it!

## What Happens

1. **Checks** Docker is running
2. **Checks** you have `.claude.json` (authenticated on Windows)
3. **Creates** `.env` if needed
4. **Copies** `.claude.json` to build context
5. **Builds** using existing Dockerfile (first time only)
6. **Runs** container with existing startup.sh
7. **Cleans up** build context files

## Files

- `docker-compose-existing.yml` - Uses existing Dockerfile, just mounts volumes
- `run-existing.bat` - Windows launcher that handles setup
- That's it!

## How It Works

The existing repo setup:
- `Dockerfile` builds image with Claude Code + MCP servers
- `src/startup.sh` runs when container starts
- Everything is already tested and working

We just add:
- Docker Compose config for Windows volume paths
- Batch file to handle Windows-specific prep

## Rebuilding

To rebuild after updating .env:
```cmd
docker-compose -f docker-compose-existing.yml build
run-existing.bat
```

## That's It

No new complex files. Just use what already works!
