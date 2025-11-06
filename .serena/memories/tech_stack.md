# Technology Stack

## Core Technologies
- **Shell Scripting**: Bash scripts for orchestration
- **Docker**: Container runtime (supports Docker & Podman)
- **Node.js**: Runtime for Claude Code CLI
- **Python**: For utility scripts

## Key Dependencies
- **Claude Code**: `@anthropic-ai/claude-code` (npm package)
- **uv (Astral)**: Package installer for Serena MCP
- **Git**: Version control (configured from host)
- **Curl/Wget**: HTTP utilities

## MCP Servers (Pre-configured)
1. **Serena** - Semantic code navigation and manipulation
2. **Context7** - Up-to-date library documentation
3. **Twilio** - SMS notifications

## Container Image
- **Base**: `node:20-slim`
- **User**: `claude-user` (UID/GID matched to host)
- **System packages**: git, curl, python3, build-essential, sudo, wget
- **Optional packages**: Configurable via `.env` (`SYSTEM_PACKAGES`)

## Environment Integration
- **Conda**: Mounts host conda environments
- **SSH**: Isolated SSH keys in `~/.claude-docker/ssh/`
- **PATH**: Shared scripts directory (`~/.claude-docker/scripts/`)

## Platform Support
- **Linux**: Native
- **macOS**: Via Docker Desktop
- **Windows**: Via WSL2 + Docker Desktop
