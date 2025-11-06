Check if .serena/project.yml exists in /workspace:
- IF EXISTS: Skip initialization (already initialized), just read git status and latest commit
- IF NOT EXISTS:
  1. Activate Serena project at /workspace and check onboarding status
  2. Run onboarding if needed
  3. Read ./CLAUDE.md and ./Context.md if they exist
  4. Read last git commit
  5. Summarise current state to user

This conditional approach saves ~2,500 tokens on subsequent startups in daemon mode.
