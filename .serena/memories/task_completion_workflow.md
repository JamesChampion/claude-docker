# Task Completion Workflow

## When a Task is Complete

### 1. Verify Changes
```bash
# Check git status
git status

# Review changes
git diff

# Test functionality (if applicable)
# Run any relevant tests or validations
```

### 2. Rebuild Docker Image (If Needed)
Rebuild is required when:
- `.env` file was modified
- `Dockerfile` was changed
- `mcp-servers.txt` was updated
- System packages were added

```bash
claude-docker --rebuild
```

### 3. Update Documentation
- Update `README.md` if features/usage changed
- Update `MCP_SERVERS.md` if MCP configuration changed
- Update `.env.example` if new variables were added
- Ensure inline comments are accurate

### 4. Git Operations
```bash
# Stage changes
git add <files>

# Commit with descriptive message
git commit -m "Brief description of changes"

# Push if working with remote
git push
```

### 5. SMS Notification (If Configured)
If Twilio is configured, send completion notification:
- This is handled automatically by CLAUDE.md instructions
- Verifies delivery status and retries if needed

## Testing Guidelines

### Before Committing
1. **Functionality test**: Does the change work as expected?
2. **Integration test**: Does it work with existing features?
3. **WSL/Windows test**: If relevant, verify cross-platform compatibility

### Shell Scripts
```bash
# Syntax check
bash -n script.sh

# Run with verbose output
bash -x script.sh
```

### Python Scripts
```bash
# Syntax check
python3 -m py_compile script.py

# Run with test data
python3 script.py --help
```

### Docker Image
```bash
# Build and test
docker build -t test-image .
docker run --rm test-image <test-command>
```

## Rollback Procedures

### Undo Local Changes
```bash
git checkout -- <file>
git reset --hard HEAD
```

### Rebuild Previous Image
```bash
# Remove current image
docker rmi claude-docker:latest

# Rebuild from clean state
claude-docker --rebuild --no-cache
```

## Continuous Integration Notes

This project does not currently have CI/CD configured, but future enhancements should include:
- Automated testing of shell scripts
- Docker image build verification
- Cross-platform testing (Linux, macOS, WSL)
- Security scanning

## Quality Checklist

Before marking a task complete:
- [ ] Changes tested locally
- [ ] Documentation updated
- [ ] Git state is clean (or intentionally dirty)
- [ ] No sensitive data (credentials, keys) in commits
- [ ] Line endings are correct (LF for text files)
- [ ] Appropriate error handling added
- [ ] Edge cases considered
