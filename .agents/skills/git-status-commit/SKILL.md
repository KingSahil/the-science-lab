---
name: git-status-commit
description: Inspects current Git source control working tree condition (git status and git diff) before generating or suggesting Git commit messages.
---

# Git Status & Commit Message Skill

This skill enforces a mandatory workflow whenever the user requests a Git commit message or source control summary.

## Mandatory Workflow Rules

1. **Always Inspect Source Control Condition First**:
   - BEFORE drafting, generating, or suggesting any Git commit message or summary:
     - Run `git status` to check all modified, staged, and untracked files.
     - Run `git diff --stat` (or `git diff`) to inspect exact lines changed.
   - Example commands:
     ```powershell
     git status
     git diff --stat
     ```

2. **Commit Message Formatting**:
   - Provide clean, structured Git commit messages following Conventional Commits format (`type(scope): summary`).
   - Group bullet points accurately based on actual files modified in `git status`.
