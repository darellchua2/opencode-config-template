---
name: git-workflow-framework
description: Framework for Git-based development workflows including branching, commits, and PRs
license: Apache-2.0
compatibility: opencode
metadata:
  audience: developers
  workflow: version-control
  type: framework
---

## What I do

Framework for Git workflow automation. Extended by Git-specific and PR-related skills.

## Extensions

| Skill | Purpose |
|-------|---------|
| `git-semantic-commits` | Conventional commit formatting |
| `git-issue-creator` | Create GitHub issues with labels |
| `git-issue-updater` | Update issues with progress |
| `git-issue-labeler` | Auto-assign labels |
| `git-issue-plan-workflow` | Full issue → branch → plan workflow |
| `git-pr-creator` | Create PRs with tracking |
| `pr-creation-workflow` | Generic PR creation framework |

## Workflow Steps

### 1. Branch Management
- Create feature branch: `git checkout -b feature/name`
- Naming: `feature/`, `fix/`, `docs/`, `refactor/`
- Track with issue: `git checkout -b issue-123`

### 2. Commit Workflow
- Stage changes: `git add .` or `git add -p`
- Use semantic commits via `git-semantic-commits`:
  - `feat:`, `fix:`, `docs:`, `refactor:`, `test:`, `chore:`
- Reference issue: `feat: add auth #123`

### 3. Sync & Push
- Pull latest: `git pull --rebase origin main`
- Push branch: `git push -u origin branch-name`
- Force push (careful): `git push --force-with-lease`

### 4. PR Creation
- Use `git-pr-creator` or `pr-creation-workflow`
- Link to issues/tickets
- Include quality check results

### 5. Merge & Cleanup
- Merge PR via GitHub/GitLab
- Delete feature branch
- Update local: `git fetch --prune`

## Common Commands

```bash
git status              # Check state
git branch -a           # List branches
git log --oneline -10   # Recent commits
git diff                # Unstaged changes
git stash               # Save changes
git rebase -i HEAD~3    # Interactive rebase
```

## Branch Naming Patterns

| Type | Pattern | Example |
|------|---------|---------|
| Feature | `feature/description` | `feature/user-auth` |
| Fix | `fix/description` | `fix/login-error` |
| Issue | `issue-NUM` | `issue-123` |
| JIRA | `PROJECT-NUM` | `IBIS-456` |

## Best Practices

1. Commit often, push regularly
2. Use semantic commit messages
3. Keep branches short-lived
4. Rebase before merge
5. Link commits to issues
6. Review before merge

## Related Skills

- `git-semantic-commits` - Commit formatting
- `git-issue-*` skills - Issue management
- `git-pr-creator` - PR creation
- `pr-creation-workflow` - PR framework
