---
name: pr-creation-workflow
description: Generic PR creation workflow with configurable quality checks and multi-platform integration
license: Apache-2.0
compatibility: opencode
metadata:
  audience: developers
  workflow: pr-creation
---

## What I do

I provide a generic PR creation workflow:
- Identify target branch (configurable, not hardcoded)
- Run quality checks (linting, build, test, type check, docstrings)
- Detect tracking (JIRA tickets or git issues)
- Create PR with comprehensive description linked to tracking
- Handle images (upload local, embed URLs)
- Merge confirmation with JIRA status update

## When to use me

Use when:
- Creating PR after completing work
- Need configurable quality checks (not just linting)
- Need PRs linked to JIRA or git issues
- Support multiple merge targets (not just `dev`)
- Need image attachments in PRs
- Building workflow skill with PR creation

This is a **framework skill** - provides PR creation logic that other skills extend.

## Steps

### Step 1: Identify Target Branch

**Methods**:
- Ask user: `read -p "Enter target branch (main/develop/staging): " TARGET_BRANCH`
- Detect default: `git symbolic-ref refs/remotes/origin/HEAD`
- Read config: Check `.git/config`

**Common targets**: main, develop, staging, production, master

**Important**: Don't hardcode to `dev` - different projects use different conventions!

### Step 2: Run Quality Checks

**Configurable checks**:

| Check | JS/TS | Python | Java | C# |
|-------|--------|--------|-----|-----|
| Linting | `npm run lint` | `poetry run ruff check` | `mvn checkstyle` | `dotnet format` |
| Build | `npm run build` | N/A | `mvn compile` | `dotnet build` |
| Test | `npm run test` | `poetry run pytest` | `mvn test` | `dotnet test` |
| Type check | `npm run typecheck` | `mypy .` | N/A | N/A |
| Docstrings | `docstring-generator` | `docstring-generator` | `docstring-generator` | `docstring-generator` |

**Error handling**: If check fails, ask user to fix, continue, or cancel

### Step 3: Detect Tracking System

**Detection**:
```bash
JIRA_TICKET=$(git log --oneline -1 | grep -oE '[A-Z]+-[0-9]+')
GIT_ISSUE=$(git log --oneline -1 | grep -oE '#[0-9]+')

if [ -f "PLAN.md" ]; then
  PLAN_JIRA=$(grep -oE '[A-Z]+-[0-9]+' PLAN.md | head -1)
fi
```

**Systems**:
- JIRA: `PROJECT-NUM` format (e.g., `IBIS-123`)
- Git Issue: `#NUM` format (e.g., `#456`)
- None: Standalone PR

### Step 4: Check Git Status

**Verify**:
```bash
# Check working tree
if [ -n "$(git status --porcelain)" ]; then
  read -p "Commit changes? (y/n): " COMMIT_CHANGES
  if [ "$COMMIT_CHANGES" = "y" ]; then
    git add . && git commit -m "Prepare for PR"
  fi
fi

# Check remote tracking
CURRENT_BRANCH=$(git branch --show-current)
if ! git branch -vv | grep "* $CURRENT_BRANCH" | grep -q "\["; then
  git push -u origin "$CURRENT_BRANCH"
fi
```

### Step 5: Create PR

**PR title format** (use `git-semantic-commits`):
- `feat: <summary> [${TRACKING_ID}]` - New feature
- `fix: <summary> [${TRACKING_ID}]` - Bug fix
- `docs: <summary> [${TRACKING_ID}]` - Documentation
- With scope: `feat(api): add auth [${TRACKING_ID}]`
- Breaking: `feat!: breaking change [${TRACKING_ID}]`

**PR body template**:
```markdown
## Summary
<Bullet points describing changes>

<if jira>
## JIRA Reference
- Ticket: ${TRACKING_ID}
- Link: https://<company>.atlassian.net/browse/${TRACKING_ID}
</if>

<if git issue>
## Issue Reference
- Resolves #${TRACKING_ID}
</if>

## Changes
- <Key change 1>
- <Key change 2>

## Quality Checks
- Linting: ${LINT_RESULT}
- Build: ${BUILD_RESULT}
- Tests: ${TEST_RESULT}
- Type Check: ${TYPECHECK_RESULT}

## Files Modified
- `src/path/to/file.ts` - Description
- `README.md` - Documentation updates

## Checklist
- [ ] Code follows style guidelines
- [ ] All quality checks passed
- [ ] Documentation updated
- [ ] Self-reviewed
```

**Create PR**:
```bash
gh pr create \
  --base "$TARGET_BRANCH" \
  --title "feat: <summary> [${TRACKING_ID}]" \
  --body "$(cat pr-body.md)"
```

### Step 6: Handle Images

**Detection**:
```bash
# Find images in common locations
IMAGES=$(find diagrams /tmp . -maxdepth 2 \
  -type f \( -name "*.png" -o -name "*.svg" -o -name "*.jpg" \) \
  -mmin -60 2>/dev/null)
```

**Handling**:
- Public URL: Embed directly in PR
- Local file: Upload to external host or JIRA
- Temp file: Warn user it's temporary

### Step 7: Merge and Update JIRA

**Merge confirmation**:
```bash
read -p "Merge this PR? (y/n): " MERGE_CONFIRM

if [ "$MERGE_CONFIRM" = "y" ]; then
  gh pr merge "$PR_NUMBER"
  
  # Update JIRA status
  if [ "$TRACKING_SYSTEM" = "jira" ]; then
    read -p "Update JIRA to Done? (y/n): " UPDATE_JIRA
    if [ "$UPDATE_JIRA" = "y" ]; then
      # Use jira-status-updater framework
      jira-status-updater --ticket "$TRACKING_ID" --status "Done"
    fi
  fi
fi
```

## Frameworks Used

- `git-semantic-commits` - PR title formatting
- `git-issue-updater` - Issue progress updates
- `jira-status-updater` - JIRA status transitions
- `jira-git-integration` - JIRA operations
- `linting-workflow` - Quality checks
- `docstring-generator` - Docstring verification

## Best Practices

- **Target branch**: Don't hardcode to `dev` - detect or ask
- **Quality checks**: Make configurable per project
- **Tracking links**: Always include JIRA/git issue references
- **PR descriptions**: Consistent format with summary, changes, checks
- **Image handling**: Upload local files, don't link to `/tmp/`
- **Merge confirmation**: Always ask before merging
- **Branch cleanliness**: Ensure clean working tree before PR
- **PR titles**: Use semantic format via `git-semantic-commits`
- **PR size**: Keep focused and small (<400 lines changed)

## Common Issues

### Target Branch Not Specified
```bash
read -p "Enter target branch (main/develop/staging): " TARGET_BRANCH
```

### Quality Checks Fail
```bash
read -p "Linting failed. Run auto-fix? (y/n): " AUTO_FIX
read -p "Create PR anyway? (y/n): " CONTINUE_PR
```

### Tracking Not Detected
```bash
# Create standalone PR
TRACKING_SYSTEM="none"

# Or ask user
read -p "Enter JIRA ticket or issue number: " USER_TRACKING
```

### Branch Not Pushed
```bash
git push -u origin $(git branch --show-current)
```

### Image Upload Issues
- Commit images to repository (for diagrams)
- Upload to external image hosting
- Upload to JIRA if ticket exists

## Troubleshooting

**Before creating PR**:
- [ ] All changes committed
- [ ] Working tree clean
- [ ] Branch has remote tracking
- [ ] Target branch identified
- [ ] Quality checks configured
- [ ] Tracking system reference identified

**After PR creation**:
- [ ] PR number captured
- [ ] PR URL accessible
- [ ] PR description complete
- [ ] Quality check status included
- [ ] Images properly referenced
- [ ] Tracking reference included

## Relevant Skills

**Skills using this framework**:
- `git-pr-creator` - PR creation with JIRA integration
- `nextjs-pr-workflow` - Next.js-specific PR workflow

**Supporting frameworks**:
- `git-semantic-commits` - Semantic commit formatting
- `git-issue-updater` - Issue progress updates
- `jira-status-updater` - JIRA status transitions
- `jira-git-integration` - JIRA operations
- `linting-workflow` - Quality checks
- `ticket-branch-workflow` - Initial setup
