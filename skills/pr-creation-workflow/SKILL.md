---
name: pr-creation-workflow
description: Generic pull request creation workflow with configurable quality checks and multi-platform integration
license: Apache-2.0
compatibility: opencode
metadata:
  audience: developers
  workflow: pr-creation
---

## What I do

I provide a generic PR creation workflow that can be adapted for multiple scenarios:

1. **Identify Target Branch**: Determine which branch PR should merge into (configurable, not hardcoded)
2. **Run Quality Checks**: Execute configurable quality checks (linting, building, testing)
3. **Identify Tracking**: Check for JIRA tickets or git issue references in commits/PLAN.md
4. **Create Pull Request**: Create a PR linked to tracking systems with comprehensive description
5. **Handle Images**: Upload local images and embed in PR description/comments
6. **Merge Confirmation**: Prompt user for merge target after PR creation

## When to use me

Use this framework when:
- You need to create a pull request after completing work
- You want configurable quality checks (not just linting)
- You need PRs linked to JIRA or git issues
- You want to support multiple merge targets (not just `dev`)
- You need image attachments in PRs
- You're building a workflow skill that includes PR creation

This is a **framework skill** - it provides PR creation logic that other skills extend.

## Core Workflow Steps

### Step 1: Identify Target Branch

**Purpose**: Determine the correct base branch for PR

**Detection Methods**:

| Method | Description | Command |
|--------|-------------|----------|
| Ask user | Prompt for target branch | N/A (interactive) |
| Detect default | Get repository default branch | `git symbolic-ref refs/remotes/origin/HEAD` |
| Read config | Check for configured default | Read `.git/config` |

**Implementation**:
```bash
# Method 1: Ask user
read -p "Enter target branch (main/develop/staging/etc.): " TARGET_BRANCH

# Method 2: Detect default
if [ -z "$TARGET_BRANCH" ]; then
  TARGET_BRANCH=$(git symbolic-ref refs/remotes/origin/HEAD | sed 's@^refs/remotes/origin/@@')
fi

# Method 3: Use provided default (e.g., from PLAN.md or previous PRs)
# If branch name contains "feature/*", default to develop or main
# If branch name contains "hotfix/*", default to main
# If branch name contains "release/*", default to main or staging
```

**Target Branch Examples**:
- `main` - Main production branch
- `develop` - Development branch
- `staging` - Pre-production branch
- `production` - Production branch (some projects use this instead of `main`)
- `master` - Legacy main branch

**Important**: Don't hardcode to `dev` - different projects use different conventions!

### Step 2: Run Quality Checks

**Purpose**: Verify code quality before creating PR

**Configurable Checks**:

| Check Type | JavaScript/TypeScript | Python | Other |
|-----------|---------------------|--------|--------|
| Linting | `npm run lint` | `poetry run ruff check` | Language-specific |
| Building | `npm run build` | N/A (Python doesn't build) | Language-specific |
| Testing | `npm run test` | `poetry run pytest` | Framework-specific |
| Type Checking | `npm run typecheck` | `mypy .` | Language-specific |

**Quality Check Execution**:
```bash
# Linting check (if enabled)
if [ "$RUN_LINTING" = "true" ]; then
  echo "Running linting..."
  if command -v npm &>/dev/null; then
    npm run lint
  elif command -v poetry &>/dev/null; then
    poetry run ruff check .
  fi
fi

# Build check (if enabled)
if [ "$RUN_BUILD" = "true" ]; then
  echo "Running build..."
  if command -v npm &>/dev/null; then
    npm run build
  fi
fi

# Test check (if enabled)
if [ "$RUN_TESTS" = "true" ]; then
  echo "Running tests..."
  if command -v npm &>/dev/null; then
    npm run test
  elif command -v poetry &>/dev/null; then
    poetry run pytest
  fi
fi

# Type check (if enabled)
if [ "$RUN_TYPECHECK" = "true" ]; then
  echo "Running type check..."
  if command -v npm &>/dev/null; then
    npm run typecheck
  elif command -v poetry &>/dev/null; then
    mypy .
  fi
fi
```

**Quality Check Results**:
```bash
# Store results for PR description
LINT_RESULT="✅ Passed" || "❌ Failed"
BUILD_RESULT="✅ Passed" || "❌ Failed"
TEST_RESULT="✅ Passed" || "❌ Failed"
TYPECHECK_RESULT="✅ Passed" || "❌ Failed"
```

**Error Handling**:
- If a check fails, ask user if they want to:
  - Fix and retry
  - Continue with failed checks
  - Cancel PR creation

### Step 3: Identify Tracking System

**Purpose**: Determine if PR should link to JIRA ticket or git issue

**Detection Methods**:

| Source | Detection Pattern | Example |
|---------|------------------|----------|
| Commit messages | Regex for JIRA ticket key | `[IBIS-123] Fix bug` |
| PLAN.md | Search for JIRA references | `JIRA Reference: IBIS-456` |
| Branch name | Parse ticket key from branch | `IBIS-101-add-feature` |
| Git config | Read from previous PRs | N/A |

**Detection Logic**:
```bash
# Check commits for JIRA ticket
JIRA_TICKET=$(git log --oneline -1 | grep -oE '[A-Z]+-[0-9]+')

# Check commits for git issue reference
GIT_ISSUE=$(git log --oneline -1 | grep -oE '#[0-9]+')

# Check PLAN.md for tracking references
if [ -f "PLAN.md" ]; then
  PLAN_JIRA=$(grep -oE '[A-Z]+-[0-9]+' PLAN.md | head -1)
  PLAN_ISSUE=$(grep -oE '#[0-9]+' PLAN.md | head -1)
fi

# Determine tracking system
if [ -n "$JIRA_TICKET" ]; then
  TRACKING_SYSTEM="jira"
  TRACKING_ID="$JIRA_TICKET"
elif [ -n "$PLAN_JIRA" ]; then
  TRACKING_SYSTEM="jira"
  TRACKING_ID="$PLAN_JIRA"
elif [ -n "$GIT_ISSUE" ]; then
  TRACKING_SYSTEM="git"
  TRACKING_ID="$GIT_ISSUE"
else
  TRACKING_SYSTEM="none"
  TRACKING_ID=""
fi
```

**Tracking System Types**:

| System | ID Format | Example |
|---------|-----------|----------|
| JIRA | PROJECT-NUM | `IBIS-123` |
| Git Issue | #NUM | `#456` |
| None | N/A | Standalone PR |

### Step 4: Check Git Status

**Purpose**: Verify all changes are committed and branch is ready for PR

**Git Status Checks**:
```bash
# Check if working tree is clean
GIT_STATUS=$(git status --porcelain)

if [ -n "$GIT_STATUS" ]; then
  echo "Warning: You have uncommitted changes:"
  echo "$GIT_STATUS"
  read -p "Commit changes before creating PR? (y/n): " COMMIT_CHANGES
  if [ "$COMMIT_CHANGES" = "y" ]; then
    git add .
    git commit -m "Prepare for PR"
  fi
fi

# Check if branch has remote tracking
CURRENT_BRANCH=$(git branch --show-current)
REMOTE_TRACKING=$(git branch --show-current | grep -q "@" && echo "yes" || echo "no")

if [ "$REMOTE_TRACKING" = "no" ]; then
  echo "Branch does not track remote. Pushing..."
  git push -u origin "$CURRENT_BRANCH"
fi
```

### Step 5: Scan for Images

**Purpose**: Find images that should be attached or referenced in PR

**Image Detection**:
```bash
# Search for common image locations
IMAGES=()

# Check diagrams directory
if [ -d "diagrams" ]; then
  IMAGES+=($(find diagrams -type f \( -name "*.png" -o -name "*.svg" -o -name "*.jpg" -o -name "*.jpeg" \)))
fi

# Check tmp directory
IMAGES+=($(find /tmp -type f \( -name "*.png" -o -name "*.svg" \) -mmin -60 2>/dev/null))

# Check for workflow-related files
IMAGES+=($(find . -maxdepth 2 -type f \( -name "*workflow*.png" -o -name "*diagram*.png" \) 2>/dev/null))

# Display found images
if [ ${#IMAGES[@]} -gt 0 ]; then
  echo "Found images:"
  printf '  - %s\n' "${IMAGES[@]}"
  read -p "Include these images in PR? (y/n): " INCLUDE_IMAGES
else
  INCLUDE_IMAGES="n"
fi
```

### Step 6: Create Pull Request

**Purpose**: Create PR with comprehensive description linked to tracking system

**PR Creation by Tracking System**:

#### JIRA-Linked PR:
```bash
gh pr create \
  --base "$TARGET_BRANCH" \
  --title "[${TRACKING_ID}] <Summary>" \
  --body "$(cat <<'EOF'
## Summary
<Bullet points describing changes>

## JIRA Reference
- Ticket: ${TRACKING_ID}
- Link: https://<company>.atlassian.net/browse/${TRACKING_ID}

## Changes
- <Key change 1>
- <Key change 2>
- <Key change 3>

## Quality Checks
- Linting: ${LINT_RESULT}
- Build: ${BUILD_RESULT}
- Tests: ${TEST_RESULT}
- Type Check: ${TYPECHECK_RESULT}

## Files Modified
- \`src/path/to/file1.ts\` - Description
- \`src/path/to/file2.tsx\` - Description
- \`README.md\` - Documentation updates

## Checklist
- [ ] Code follows project style guidelines
- [ ] All quality checks passed
- [ ] Documentation updated
- [ ] Self-reviewed
EOF
)"
```

#### Git Issue-Linked PR:
```bash
gh pr create \
  --base "$TARGET_BRANCH" \
  --title "Fix #${TRACKING_ID}: <Summary>" \
  --body "$(cat <<'EOF'
## Summary
<Bullet points describing changes>

## Issue Reference
- Resolves #${TRACKING_ID}
- Link: <issue-url>

## Changes
- <Key change 1>
- <Key change 2>

## Quality Checks
- Linting: ${LINT_RESULT}
- Build: ${BUILD_RESULT}
- Tests: ${TEST_RESULT}

## Files Modified
- \`src/path/to/file1.ts\` - Description
- \`src/path/to/file2.tsx\` - Description

## Checklist
- [ ] Code follows project style guidelines
- [ ] All quality checks passed
- [ ] Documentation updated
- [ ] Self-reviewed
EOF
)"
```

#### Standalone PR (No Tracking):
```bash
gh pr create \
  --base "$TARGET_BRANCH" \
  --title "<Summary>" \
  --body "$(cat <<'EOF'
## Summary
<Bullet points describing changes>

## Changes
- <Key change 1>
- <Key change 2>
- <Key change 3>

## Quality Checks
- Linting: ${LINT_RESULT}
- Build: ${BUILD_RESULT}
- Tests: ${TEST_RESULT}
- Type Check: ${TYPECHECK_RESULT}

## Files Modified
- \`src/path/to/file1.ts\` - Description
- \`src/path/to/file2.tsx\` - Description

## Checklist
- [ ] Code follows project style guidelines
- [ ] All quality checks passed
- [ ] Documentation updated
- [ ] Self-reviewed
EOF
)"
```

### Step 7: Handle Images in PR

**Purpose**: Upload local images to hosting platform or reference in PR

**Image Handling Strategy**:

| Image Type | Action |
|-----------|--------|
| Public URL | Embed directly in PR |
| Local file | Upload to external host or attach to tracking system |
| Temp file | Upload or warn user it's temporary |

**Implementation**:
```bash
if [ "$INCLUDE_IMAGES" = "y" ] && [ ${#IMAGES[@]} -gt 0 ]; then
  for image in "${IMAGES[@]}"; do
    if [[ "$image" =~ ^https?:// ]]; then
      # It's already a URL - add to PR
      PR_BODY+="
![Diagram]($image)"
    elif [ -f "$image" ]; then
      # Local file - need to upload
      # Option 1: Upload to JIRA if tracking system is JIRA
      # Option 2: Upload to image hosting service
      # Option 3: Commit to repository (for diagrams)
      echo "Local image: $image"
      echo "This should be uploaded or committed to the repository"
    fi
  done
fi
```

### Step 8: Merge Confirmation

**Purpose**: Ask user to confirm merge target after successful PR creation

**Implementation**:
```bash
# Get PR number
PR_NUMBER=$(gh pr view --json number --jq '.number')
PR_URL=$(gh pr view --json url --jq '.url')

# Display success message
echo ""
echo "✅ Pull request created successfully!"
echo ""
echo "**PR Details:**"
echo "- Number: #$PR_NUMBER"
echo "- Title: <pr-title>"
echo "- Branch: $CURRENT_BRANCH"
echo "- Target: $TARGET_BRANCH"
echo "- URL: $PR_URL"
echo ""

# Ask for merge confirmation
read -p "Would you like to proceed with merging this PR? If yes, please specify target branch (default: $TARGET_BRANCH): " MERGE_CONFIRMATION

if [ "$MERGE_CONFIRMATION" = "y" ]; then
  read -p "Enter target branch (default: $TARGET_BRANCH): " MERGE_TARGET
  MERGE_TARGET=${MERGE_TARGET:-$TARGET_BRANCH}

  # Merge PR
  gh pr merge "$PR_NUMBER" --base "$MERGE_TARGET"
  echo "✅ PR merged into $MERGE_TARGET"
fi
```

## Quality Check Configuration

### JavaScript/TypeScript Projects

| Check | Script | Command | Auto-fix |
|-------|--------|----------|-----------|
| Linting | `npm run lint` | ESLint | `npm run lint -- --fix` |
| Build | `npm run build` | N/A | N/A |
| Test | `npm run test` | Jest/Vitest | N/A |
| Type Check | `npm run typecheck` | TypeScript | N/A |

### Python Projects

| Check | Command | Tool | Auto-fix |
|-------|----------|------|-----------|
| Linting | `poetry run ruff check` | Ruff | `poetry run ruff check --fix` |
| Type Check | `poetry run mypy .` | mypy | N/A |
| Test | `poetry run pytest` | pytest | N/A |

## Best Practices

- **Target Branch**: Don't hardcode to `dev` - ask user or detect default
- **Quality Checks**: Make them configurable - not all projects need all checks
- **Tracking Links**: Always include JIRA/git issue references for traceability
- **PR Descriptions**: Use consistent format with summary, changes, quality checks
- **Image Handling**: Upload local images, don't link to `/tmp/` or local paths
- **Merge Confirmation**: Always ask user before merging
- **Branch Cleanliness**: Ensure working tree is clean before creating PR
- **Commit Quality**: Use clear, descriptive commit messages
- **PR Size**: Keep PRs focused and small (< 400 lines changed ideal)
- **Review Checklist**: Include self-review checklist in every PR

## Common Issues

### Target Branch Not Specified

**Issue**: User doesn't provide target branch and auto-detection fails

**Solution**:
```bash
# Prompt user for target branch
read -p "Enter target branch (main/develop/staging/etc.): " TARGET_BRANCH

# Provide default if available
TARGET_BRANCH=${TARGET_BRANCH:-main}
```

### Quality Checks Fail

**Issue**: Linting, build, or tests fail

**Solution**:
```bash
# Offer to fix automatically
if [ "$RUN_LINTING" = "true" ]; then
  read -p "Linting failed. Run auto-fix? (y/n): " AUTO_FIX
  if [ "$AUTO_FIX" = "y" ]; then
    npm run lint -- --fix
  fi
fi

# Ask if user wants to continue anyway
read -p "Some checks failed. Create PR anyway? (y/n): " CONTINUE_PR
if [ "$CONTINUE_PR" = "n" ]; then
  echo "PR creation cancelled. Please fix issues and retry."
  exit 1
fi
```

### Tracking Not Detected

**Issue**: No JIRA ticket or git issue reference found

**Solution**:
```bash
# Create standalone PR without tracking reference
TRACKING_SYSTEM="none"
TRACKING_ID=""

# Or ask user to provide reference
read -p "Enter JIRA ticket or git issue number (leave blank for none): " USER_TRACKING
if [ -n "$USER_TRACKING" ]; then
  # Parse and use provided tracking
fi
```

### Branch Not Pushed

**Issue**: PR creation fails because branch doesn't exist on remote

**Solution**:
```bash
# Push branch with upstream tracking
git push -u origin $(git branch --show-current)
```

### Image Upload Issues

**Issue**: Local images can't be referenced in PR

**Solution**:
- Commit images to repository (for diagrams)
- Upload to external image hosting
- Upload to JIRA if JIRA ticket exists
- Ask user to handle manually

## Troubleshooting Checklist

Before creating PR:
- [ ] All changes are committed
- [ ] Working tree is clean
- [ ] Branch has remote tracking
- [ ] Target branch is identified (asked user or detected)
- [ ] Quality checks are configured correctly
- [ ] Images are handled (uploaded or committed)
- [ ] Tracking system reference is identified

After PR creation:
- [ ] PR number is captured
- [ ] PR URL is accessible
- [ ] PR description is complete
- [ ] Quality check status is included
- [ ] Images are properly referenced
- [ ] Tracking reference is included (if applicable)

## Relevant Commands

```bash
# Get current branch
git branch --show-current

# Get default branch
git symbolic-ref refs/remotes/origin/HEAD

# Check git status
git status

# Check for remote tracking
git branch -vv | grep '*'

# Push branch with upstream
git push -u origin <branch-name>

# Create PR
gh pr create --base <target> --title "Title" --body "Description"

# View PR
gh pr view

# List PRs
gh pr list

# Merge PR
gh pr merge <pr-number>

# Close PR (without merge)
gh pr close <pr-number>
```

## Relevant Skills

Skills that use this PR creation framework:
- `git-pr-creator`: PR creation with JIRA integration and image uploads
- `nextjs-pr-workflow`: Next.js-specific PR workflow with linting and building

Supporting framework skills:
- `jira-git-integration`: For JIRA ticket management and comments
- `linting-workflow`: For configurable quality checks
- `ticket-branch-workflow`: For initial ticket-to-branch setup
