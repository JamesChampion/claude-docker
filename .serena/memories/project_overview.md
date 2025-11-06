# Project Overview

**Claude Docker** - A complete AI coding agent starter pack with Claude Code, pre-configured with essential MCP servers for autonomous development.

## Purpose
Provides a Docker-based isolated environment for running Claude Code with:
- Pre-configured MCP servers (Serena, Context7, Twilio)
- Persistent authentication and conversation history
- Conda environment integration
- SMS notifications for long-running tasks
- Shared utility scripts

## Key Features
- **Full autonomy**: Runs with `--dangerously-skip-permissions`
- **Modular MCP support**: Easy installation via `mcp-servers.txt`
- **Conda integration**: Direct access to host conda environments
- **Persistence**: Authentication and settings persist across sessions
- **WSL/Windows support**: Works on Linux, macOS, and Windows (via WSL2)

## Target Users
Developers who want:
- Isolated, reproducible AI coding environment
- Access to conda environments without rebuilding Docker images
- SMS notifications for long-running tasks
- Persistent Claude authentication

## Architecture Overview
```
claude-docker/
├── src/                    # Main scripts
│   ├── claude-docker.sh    # Main entry script
│   ├── install.sh          # Installation script
│   └── startup.sh          # Container startup
├── scripts/                # Shared utilities
│   └── sys_utils.py        # Common Python utilities
├── .claude/                # Claude configuration templates
│   ├── settings.json       # MCP server config
│   ├── CLAUDE.md          # Project instructions
│   └── commands/          # Slash commands
├── Dockerfile             # Container definition
└── install-mcp-servers.sh # MCP installation
```

## Data Flow
1. User runs `claude-docker` from project directory
2. Script checks/builds Docker image
3. Mounts project directory, conda dirs, SSH keys
4. Container starts with MCP servers
5. Claude Code launches with persistent auth
6. On task completion, optionally sends SMS via Twilio
