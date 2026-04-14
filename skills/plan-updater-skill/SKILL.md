---
name: plan-updater-skill
description: Update branch-specific PLAN.md files with progress. Detects branch name, finds matching PLAN file, updates checkboxes, and commits changes. Supports both GitHub (PLAN-GIT-*.md) and JIRA (PLAN-*.md) conventions.
license: Apache-2.0
compatibility: opencode
metadata:
  audience: developers, agents, subagents
  workflow: documentation, progress-tracking
---

## What I do

I provide automatic PLAN.md synchronization for any workflow that implements developer code:

1. **Detect Branch Reference**: Extract issue/ticket number from current branch name
2. **Find PLAN File**: Locate matching PLAN file in `PLANS/` directory
3. **Update Progress**: Mark checkboxes as complete based on recent commits
4. **Commit Changes**: Commit with semantic message format
5. **Graceful Skip**: Skip silently when no PLAN file exists

## When to use me

Use this skill when:
- Your subagent implements code changes (refactoring, testing, features)
- You're about to create a PR and want PLAN.md to reflect current state
- You've completed a significant milestone in development
- You want to maintain traceability between commits and plans

**Trigger phrases**:
- "update plan"
- "sync plan"
- "update PLAN.md"
- "mark plan progress"

## Subagents That Should Use This Skill

| Subagent | When to Invoke |
|----------|----------------|
| pr-workflow-subagent | Before creating PR (step 3.5) |
| refactoring-subagent | After completing refactoring |
| testing-subagent | After creating tests |
| ticket-creation-subagent | After initial PLAN creation |

## Core Workflow

### Step 1: Detect Branch Reference

Extract issue/ticket number from branch name:

**Supported Branch Patterns**:
- `GIT-123` - GitHub issue (preferred)
- `issue-123` - GitHub issue (legacy)
- `123` - GitHub issue (legacy)
- `PROJECT-123` - JIRA ticket

```bash
BRANCH_NAME=$(git branch --show-current)

# GitHub pattern: GIT-123
if [[ "$BRANCH_NAME" =~ ^GIT-([0-9]+)$ ]]; then
  ISSUE_NUM="${BASH_REMATCH[1]}"
  PLAN_TYPE="github"
  PLAN_ID="$ISSUE_NUM"
fi

# Legacy GitHub pattern (backwards compatibility): issue-123 or 123
if [[ "$BRANCH_NAME" =~ ^issue-([0-9]+)$ ]] || [[ "$BRANCH_NAME" =~ ^([0-9]+)$ ]]; then
  ISSUE_NUM="${BASH_REMATCH[1]}"
  PLAN_TYPE="github"
  PLAN_ID="$ISSUE_NUM"
fi

```

### Step 2: Find PLAN File

Locate the matching PLAN file:

```bash
# GitHub convention
GITHUB_PLAN="PLANS/PLAN-GIT-${ISSUE_NUM}.md"

# JIRA convention
JIRA_PLAN="PLANS/PLAN-${PLAN_ID}.md"

# Check which exists
if [ -f "$GITHUB_PLAN" ]; then
  PLAN_FILE="$GITHUB_PLAN"
elif [ -f "$JIRA_PLAN" ]; then
  PLAN_FILE="$JIRA_PLAN"
else
  echo "No PLAN file found for branch: $BRANCH_NAME"
  echo "Skipping PLAN.md update (graceful skip)"
  exit 0
fi

echo "Found PLAN file: $PLAN_FILE"
```

### Step 3: Analyze Recent Commits

Get commits on this branch to determine completed work:

```bash
# Get commits specific to this branch (not in base branch)
BASE_BRANCH="main"  # or detect from origin

# Get commits on current branch not in base
COMMITS=$(git log ${BASE_BRANCH}..HEAD --oneline)

# Get files changed in this branch
FILES_CHANGED=$(git diff --name-only ${BASE_BRANCH}...HEAD)

# Get commit count
COMMIT_COUNT=$(git rev-list --count ${BASE_BRANCH}..HEAD)
```

### Step 4: Update Progress Checkboxes

Update PLAN.md checkboxes based on completed work:

**Rules for checkbox updates**:
1. Mark checkbox `[ ]` as `[x]` if related file was modified
2. Don't uncheck already completed items
3. Preserve all other content exactly

**Example update logic**:

```markdown
Before:
- [ ] Implement user authentication
- [ ] Add OAuth2 support
- [ ] Write unit tests

After (if auth and OAuth files were changed):
- [x] Implement user authentication
- [x] Add OAuth2 support
- [ ] Write unit tests
```

### Step 5: Add Progress Note (Optional)

Add a progress note section if significant work was done:

```markdown
## Progress Log

### 2024-01-25 - Authentication Implementation
- Completed OAuth2 integration
- Added token refresh mechanism
- Files changed: src/auth/oauth.ts, src/auth/token.ts
```

### Step 6: Commit PLAN Changes

Commit with semantic format:

```bash
# Stage PLAN file
git add "$PLAN_FILE"

# Commit with semantic message
git commit -m "docs(plan): update ${PLAN_FILE##*/} with current progress"

echo "Committed PLAN update: $PLAN_FILE"
```

## PLAN File Naming Convention

| Source | Branch Pattern | PLAN File |
|--------|---------------|-----------|
| GitHub issue | `GIT-123` | `PLANS/PLAN-GIT-123.md` |
| GitHub issue (legacy) | `issue-123` or `123` | `PLANS/PLAN-GIT-123.md` |
| JIRA ticket | `IBIS-456` | `PLANS/PLAN-IBIS-456.md` |
| JIRA ticket | `PROJ-789` | `PLANS/PLAN-PROJ-789.md` |

## Integration Pattern

### For Subagent Developers

Add this to your subagent's workflow:

```markdown
Workflow:
1. [Your existing steps...]
2. [Your existing steps...]
N. Check for and update branch-specific PLAN.md
   - Invoke plan-updater skill
   - If PLAN exists, it will be updated and committed
   - If no PLAN exists, gracefully skip
```

### For Skills

Call from other skills:

```markdown
## After Making Changes

5. Update PLAN.md if it exists
   - Use plan-updater skill to sync progress
   - Ensures traceability between commits and planning
```

## Error Handling

### No PLAN File Found

```bash
# Graceful skip - not an error
echo "No PLAN file found for current branch"
echo "Continuing without PLAN update..."
```

### PLAN File Malformed

```bash
# Log warning but don't fail
if ! grep -q "\- \[" "$PLAN_FILE"; then
  echo "Warning: PLAN file may not have standard checkbox format"
  echo "Proceeding with caution..."
fi
```

### Branch Name Unparseable

```bash
# Try to find any PLAN file with recent modification
RECENT_PLAN=$(find PLANS -name "PLAN-*.md" -mtime -1 | head -1)

if [ -n "$RECENT_PLAN" ]; then
  echo "Found recently modified PLAN: $RECENT_PLAN"
  read -p "Update this PLAN file? (y/n): " CONFIRM
  if [ "$CONFIRM" = "y" ]; then
    PLAN_FILE="$RECENT_PLAN"
  fi
fi
```

## Best Practices

### When to Update

- **Before PR creation**: Ensure PLAN reflects final state
- **After milestones**: Mark significant progress
- **After refactoring**: Update scope if changed
- **After testing**: Mark test-related tasks complete

### What to Update

- Mark completed tasks as `[x]`
- Add progress notes for significant changes
- Update scope if files changed
- Keep acceptance criteria aligned with actual work

### What NOT to Do

- Don't uncheck already completed items
- Don't modify the original plan structure
- Don't remove sections
- Don't change the issue reference

## Example Usage

### In pr-workflow-subagent

```markdown
## Workflow

1. Detect project framework
2. Run quality checks (lint, build, test)
3. Generate coverage badges
4. **UPDATE PLAN.md** ← Add this step
   - Invoke plan-updater skill
   - Ensures PLAN reflects current state before PR
5. Create PR
6. Update JIRA ticket
```

### In refactoring-subagent

```markdown
## Refactoring Workflow

1. Analyze codebase for duplication
2. Apply DRY principle
3. Consolidate code
4. Verify with tests
5. **UPDATE PLAN.md** ← Add this step
   - Mark refactoring tasks as complete
   - Add notes about changes made
6. Report results
```

### In testing-subagent

```markdown
## Test Generation Workflow

1. Analyze code to test
2. Generate comprehensive tests
3. Run tests to verify
4. **UPDATE PLAN.md** ← Add this step
   - Mark test-related tasks complete
   - Note coverage improvements
5. Report coverage
```

## Verification

After updating PLAN:

```bash
# Verify PLAN was updated
git log -1 --oneline

# Should show something like:
# abc1234 docs(plan): update PLAN-GIT-123.md with current progress

# Check PLAN content
grep "\- \[x\]" "$PLAN_FILE" | wc -l
echo "Completed tasks in PLAN"
```

## References

- `ticket-plan-workflow` - Creates GitHub issue and JIRA ticket PLAN files
- `git-issue-updater` - Updates issues with commit progress
- `git-semantic-commits` - Commit message formatting
