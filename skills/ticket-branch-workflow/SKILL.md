---
name: ticket-branch-workflow
description: Generic ticket-to-branch-to-PLAN workflow supporting GitHub and JIRA
license: Apache-2.0
compatibility: opencode
metadata:
  audience: developers
  workflow: ticket-branch
---

## What I do

I provide a generic ticket-to-branch-to-PLAN workflow:
- Analyze request and detect platform (GitHub/JIRA)
- Create ticket with labels using `git-issue-labeler`
- Generate branch name from ticket
- Create and checkout git branch
- Create PLAN.md with semantic commit using `git-semantic-commits`
- Update issue with progress using `git-issue-updater`
- Push branch to remote

## When to use me

Use when:
- Starting new feature, bug fix, or task tracked in ticketing system
- Need systematic approach with ticket creation, branching, planning
- Support both GitHub and JIRA ticketing

**Frameworks used**:
- `git-issue-labeler` - Label assignment
- `git-semantic-commits` - Semantic commit formatting
- `git-issue-updater` - Issue progress updates
- `jira-git-integration` - JIRA operations

This is a **framework skill** - provides ticket-to-branch logic that other skills extend.

## Steps

### Step 1: Detect Platform

**Detection logic**:
```bash
if echo "$USER_INPUT" | grep -qi "github" || git remote -v | grep -q "github.com"; then
  PLATFORM="github"
elif echo "$USER_INPUT" | grep -qi "jira"; then
  PLATFORM="jira"
else
  read -p "Use GitHub or JIRA? (github/jira): " PLATFORM
fi
```

### Step 2: Determine Labels/Issue Type

**Framework**: `git-issue-labeler`

Assigns appropriate labels/issue types:
- GitHub: bug, enhancement, documentation, duplicate, good first issue, help wanted, invalid, question, wontfix
- JIRA: Task, Story, Bug

```bash
LABELS=$(git-issue-labeler --platform "$PLATFORM" --content "$TICKET_TITLE")
```

### Step 3: Create Ticket

**GitHub**:
```bash
gh issue create \
  --title "Title" \
  --body "Description" \
  --label "$LABELS" \
  --assignee @me
```

**JIRA**:
```bash
CLOUD_ID=$(atlassian_getAccessibleAtlassianResources | jq -r '.[0].id')
atlassian_createJiraIssue \
  --cloudId "$CLOUD_ID" \
  --projectKey "PROJECT" \
  --issueTypeName "Task|Story|Bug" \
  --summary "Title" \
  --description "Description"
```

### Step 4: Generate Branch Name

**Naming conventions**:
- GitHub: `issue-<number>` or `feature/<number>-<title>`
- JIRA: `PROJECT-NUM` or `feature/PROJECT-NUM`

**Rules**: Lowercase, hyphens for spaces, include ticket reference, <72 chars

```bash
if [ "$PLATFORM" = "github" ]; then
  BRANCH_NAME="issue-${ISSUE_NUMBER}"
else
  BRANCH_NAME="${TICKET_KEY}"
fi
```

### Step 5: Create Branch

```bash
# Check if exists
if git branch | grep -q "$BRANCH_NAME"; then
  git checkout "$BRANCH_NAME"
else
  git checkout -b "$BRANCH_NAME"
fi
```

### Step 6: Create PLAN.md

**Template**:
```markdown
# Plan: <Ticket Title>

## Overview
Brief description of implementation.

## Ticket Reference
- Issue/Ticket: <number or key>
- URL: <ticket-url>
- Labels/Type: <labels or issue type>

## Files to Modify
1. `path/to/file.ts` - Description

## Approach
### Phase 1: Analysis
- Step 1
- Step 2

### Phase 2: Implementation
- Step 1
- Step 2

## Success Criteria
- [ ] All files modified correctly
- [ ] No build errors
- [ ] All tests pass

## Notes
Additional notes or constraints.
```

### Step 7: Commit PLAN.md

**Framework**: `git-semantic-commits`

```bash
git add PLAN.md
git commit -m "docs(plan): add PLAN.md for <ticket-reference>"
```

### Step 8: Update Issue with Progress

**Framework**: `git-issue-updater`

```bash
git-issue-updater --issue "<ticket-id>" --platform "$PLATFORM"
```

### Step 9: Push Branch

```bash
git push -u origin "$BRANCH_NAME"
```

## Best Practices

- **Ticket titles**: Concise and descriptive (<72 chars)
- **Ticket descriptions**: Include context, acceptance criteria, affected files
- **Branch names**: Include ticket reference for traceability
- **PLAN.md first**: Always create as first commit
- **Remote push**: Push immediately after committing PLAN.md
- **Clear messaging**: Provide confirmation at each step

## Common Issues

### Platform Not Detected
Ask user to specify or detect from context:
```bash
read -p "Which platform? (github/jira): " PLATFORM
```

### Branch Already Exists
Switch to existing or create with different name:
```bash
git checkout "$BRANCH_NAME"  # or use new name
```

### Push Fails
Check remote and authentication:
```bash
git remote -v
gh auth status  # for GitHub
```

## Troubleshooting

**Before creating ticket**:
- [ ] Platform detected (GitHub or JIRA)
- [ ] Appropriate permissions
- [ ] Remote repository configured

**After ticket creation**:
- [ ] Ticket number/key captured
- [ ] Ticket URL accessible
- [ ] Labels/issue types correct

**After branch creation**:
- [ ] Branch name correct
- [ ] Branch checked out successfully

**After PLAN.md**:
- [ ] File created with correct structure
- [ ] All sections populated

**After commit**:
- [ ] Commit message clear
- [ ] Includes ticket reference

**After push**:
- [ ] Branch pushed to remote
- [ ] Branch accessible via URL

## Related Skills

**Framework skills used**:
- `git-issue-labeler` - GitHub label assignment
- `git-semantic-commits` - Semantic commit formatting
- `git-issue-updater` - Issue progress updates
- `jira-git-integration` - JIRA utilities

**Skills using this framework**:
- `git-issue-creator` - GitHub issue creation
- `jira-git-workflow` - JIRA ticket creation

**Related workflow skills**:
- `pr-creation-workflow` - PR creation workflows
- `nextjs-pr-workflow` - Next.js PR workflows
- `git-pr-creator` - PR creation with JIRA integration
