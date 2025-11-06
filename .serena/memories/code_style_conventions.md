# Code Style & Conventions

## Shell Script Conventions

### File Headers
All shell scripts should include:
```bash
#!/bin/bash
set -euo pipefail  # Strict error handling
```

### Documentation
- Use `# ABOUTME:` comments at top of files to describe purpose
- Example from Dockerfile:
  ```dockerfile
  # ABOUTME: Docker image for Claude Code with Twilio MCP server
  # ABOUTME: Provides autonomous Claude Code environment with SMS notifications
  ```

### Error Handling
- Use `set -euo pipefail` for strict mode
- Exit with appropriate codes (0 = success, non-zero = error)
- Print error messages to stderr: `echo "Error: ..." >&2`

### Variable Naming
- Environment variables: `UPPER_SNAKE_CASE`
- Local variables: `lower_snake_case`
- Use quotes around variables: `"$variable"`

## Python Script Conventions

### Argument Parsing
**MANDATORY**: All Python scripts MUST use `argparse` module for CLI arguments
```python
import argparse

def main():
    parser = argparse.ArgumentParser(description='Script purpose')
    parser.add_argument('--option', help='Option description')
    args = parser.parse_args()
```

### Imports
- Standard imports from `sys_utils`:
  ```python
  from sys_utils import check_git_state_clean, create_reproduce_command
  ```

### Git State Checking
Scripts should verify clean git state before execution:
```python
check_git_state_clean()
```

## Dockerfile Conventions

### ARG vs ENV
- **ARG**: Build-time variables (e.g., `USER_UID`, `SYSTEM_PACKAGES`)
- **ENV**: Runtime environment variables (e.g., `PATH`, `HOME`)

### User Switching
- Build as root, switch to non-root user before installations
- Set ownership: `chown -R claude-user /path`

### Layer Optimization
- Combine related commands with `&&`
- Clean up in same layer: `rm -rf /var/lib/apt/lists/*`

## File Naming

### Scripts
- Main scripts: `kebab-case.sh` (e.g., `claude-docker.sh`, `install-mcp-servers.sh`)
- Utility modules: `snake_case.py` (e.g., `sys_utils.py`)

### Configuration
- Hidden configs: `.filename` (e.g., `.env`, `.claude.json`)
- Documentation: `UPPERCASE.md` or `Title_Case.md`

## Git Conventions

### Line Endings
- **Enforced via `.gitattributes`**: Unix line endings (LF) for all text files
- Critical for WSL/Windows compatibility
- No manual configuration needed

### Commit Messages
- Follow conventional format
- Be descriptive about changes

## Documentation

### README Structure
1. Quick Start / Installation
2. Prerequisites
3. Features
4. Configuration
5. Troubleshooting
6. License/Attribution

### Inline Comments
- Explain **why**, not **what**
- Use for complex logic or non-obvious behavior
- Keep comments up-to-date with code

## Security Practices

### Credentials
- **NEVER** commit `.env` files
- Use `.env.example` as template
- Document required variables in README

### SSH Keys
- Isolated keys in `~/.claude-docker/ssh/`
- Never share host's `~/.ssh/` directory
- Generate dedicated keys for Claude Docker

### Container Permissions
- Run as non-root user (`claude-user`)
- Use sudo only when necessary
- Match UID/GID with host for file permissions
