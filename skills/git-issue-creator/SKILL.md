---
name: git-issue-creator
description: GitHub issue creation with intelligent tag detection, extending ticket-branch-workflow
license: Apache-2.0
compatibility: opencode
metadata:
  audience: developers
  workflow: github-issue-branch
---

## What I do

I implement GitHub issue creation with intelligent tag detection by extending `ticket-branch-workflow`:

1. **Analyze Request**: Parse the user's statement to determine issue type
2. **Detect Tags**: Automatically assign relevant tags (feature, bug, documentation, enhancement, task) based on content analysis
3. **Create GitHub Issue**: Use `gh issue create` with title, description, auto-detected labels, and assignee
4. **Delegate to Framework**: Use `ticket-branch-workflow` for branch creation, PLAN.md, commit, and push
5. **Display Summary**: Show issue URL, branch name, and framework completion status

## When to use me

**Framework**: This skill extends `ticket-branch-workflow` for core workflow (branch creation, PLAN.md, commit, push), adding GitHub-specific issue creation and intelligent tag detection.

Use this workflow when:
- You need to create a GitHub issue with intelligent tag assignment
- You want the complete workflow: issue → branch → PLAN.md → commit → push
- You prefer GitHub CLI (`gh`) for issue creation over manual entry

## Prerequisites

- GitHub CLI (`gh`) installed and authenticated
- Git repository initialized
- Write access to the GitHub repository
- Valid `GITHUB_TOKEN` or `gh` authentication setup

## Steps

### Step 1: Analyze the Request
- Read the user's statement describing the issue
- Identify key indicators for issue type:
  - **Bug**: "fix", "error", "doesn't work", "broken", "crash", "fails"
  - **Feature**: "add", "implement", "create", "new", "support"
  - **Enhancement**: "improve", "optimize", "refactor", "update", "enhance"
  - **Documentation**: "document", "readme", "docs", "guide", "explain"
  - **Task**: "setup", "configure", "deploy", "clean", "organize"

### Step 2: Determine Tags
- Analyze the statement for multiple possible tags
- Assign all applicable tags from:
  - `feature`: New functionality or features
  - `bug`: Defects or fixes required
  - `documentation`: Documentation updates or improvements
  - `enhancement`: Existing functionality improvements
  - `task`: Administrative or setup tasks
- Default to `enhancement` if no specific type is detected

### Step 3: Create GitHub Issue
- Get the current authenticated GitHub user:
  ```bash
  gh api user --jq '.login'
  ```
- Use `gh issue create` command:
  ```bash
  gh issue create --title "<Issue Title>" --body "<Issue Description>" --label "<tag1>,<tag2>" --assignee @me
  ```
- Format the issue body:
  ```markdown
  ## Description
  <Detailed description of the issue>

  ## Type
  <Primary tag>

  ## Additional Labels
  - <tag2>
  - <tag3>

  ## Context
  <Additional context or background information>

  ## Acceptance Criteria
  - <Criteria 1>
  - <Criteria 2>
  ```
- Store the issue number, URL, and assignee for reference

### Step 4: Execute Ticket-Branch-Workflow
- Use `ticket-branch-workflow` for the following steps:
  - Create GitHub branch: `git checkout -b issue-<issue-number>` or `feature/<issue-number>-<short-title>`
  - Create PLAN.md with issue reference
  - Commit PLAN.md: `git commit -m "Add PLAN.md for #<issue-number>: <issue-title>"`
  - Push branch: `git push -u origin <branch-name>`

### Step 5: Display Summary
- Display issue and framework completion status:
  ```
  ✅ GitHub Issue #<issue-number> created successfully!
  ✅ Branch created and checked out: <branch-name>
  ✅ PLAN.md created and committed (via ticket-branch-workflow)
  ✅ Branch pushed to remote (via ticket-branch-workflow)

  **Issue Details**:
  - Title: <issue-title>
  - URL: <issue-url>
  - Labels: <tag1>, <tag2>, <tag3>
  - Assignee: <current-user>

  **Branch**:
  - Name: <branch-name>
  - Base Branch: <previous-branch>
  - Remote: origin/<branch-name>

  **PLAN.md**:
  - Created at: ./PLAN.md
  - Committed: Yes
  - Pushed: Yes

  You're now on the new branch and ready to start implementation!
  ```

## Tag Detection Logic

The skill uses keyword matching to determine appropriate tags:

### Bug Detection
Keywords: `fix`, `error`, `doesn't work`, `broken`, `crash`, `fails`, `issue`, `problem`, `incorrect`, `wrong`, `bug`

### Feature Detection
Keywords: `add`, `implement`, `create`, `new`, `support`, `introduce`, `build`, `develop`

### Documentation Detection
Keywords: `document`, `readme`, `docs`, `guide`, `explain`, `tutorial`, `wiki`, `comment`

### Enhancement Detection
Keywords: `improve`, `optimize`, `refactor`, `update`, `enhance`, `better`, `faster`, `cleaner`

### Task Detection
Keywords: `setup`, `configure`, `deploy`, `clean`, `organize`, `maintenance`, `chore`, `update dependencies`

## Examples

### Example 1: Bug Fix
**User Input**: "Fix the login error when user enters invalid credentials"

**Detected Tags**: `bug`

**Issue Created**:
- Title: "Fix the login error when user enters invalid credentials"
- Labels: `bug`
- Assignee: `<current-user>`
- Branch: `issue-123`

**Framework Executes**: ticket-branch-workflow creates branch, PLAN.md, commits, and pushes

### Example 2: New Feature
**User Input**: "Add support for dark mode in the dashboard"

**Detected Tags**: `feature`, `enhancement`

**Issue Created**:
- Title: "Add support for dark mode in the dashboard"
- Labels: `feature, enhancement`
- Assignee: `<current-user>`
- Branch: `feature/124-add-dark-mode`

**Framework Executes**: ticket-branch-workflow creates branch, PLAN.md, commits, and pushes

### Example 3: Documentation
**User Input**: "Document the API endpoints for the authentication module"

**Detected Tags**: `documentation`

**Issue Created**:
- Title: "Document the API endpoints for the authentication module"
- Labels: `documentation`
- Assignee: `<current-user>`
- Branch: `issue-125`

**Framework Executes**: ticket-branch-workflow creates branch, PLAN.md, commits, and pushes

### Example 4: Multiple Tags
**User Input**: "Improve performance of the search functionality and optimize database queries"

**Detected Tags**: `enhancement`, `task`

**Issue Created**:
- Title: "Improve performance of the search functionality and optimize database queries"
- Labels: `enhancement, task`
- Assignee: `<current-user>`
- Branch: `issue-126`

**Framework Executes**: ticket-branch-workflow creates branch, PLAN.md, commits, and pushes

## PLAN.md Template Structure

The framework generates PLAN.md with this structure:
```markdown
# Plan: <Issue Title>

## Overview
Brief description of what this issue implements or fixes.

## Issue Reference
- Issue: #<issue-number>
- URL: <issue-url>
- Labels: <tag1>, <tag2>, <tag3>

## Files to Modify
1. `src/path/to/file1.ts` - Description of changes
2. `src/path/to/file2.tsx` - Description of changes
3. `README.md` - Documentation updates

## Approach
Detailed steps or methodology for implementation:

1. **Step 1**: Description
2. **Step 2**: Description
3. **Step 3**: Description

## Success Criteria
- [ ] All files modified correctly
- [ ] No build errors
- [ ] All tests pass
- [ ] Code review completed

## Notes
Any additional notes, constraints, or considerations.
```

## Best Practices

- Always provide clear, descriptive issue titles
- Include sufficient context in the issue description
- Assign issues to yourself (`--assignee @me`) for accountability
- Assign multiple tags when applicable (up to 3 recommended)
- Use semantic branch names that reference the issue number
- Confirm the issue URL is accessible
- The framework handles branch creation, PLAN.md, commit, and push automatically
- Keep issue titles concise (under 72 characters preferred)
- Update the issue with a comment linking to the PR when ready

## Common Issues

### GitHub CLI Not Authenticated
**Issue**: `gh issue create` fails with authentication error

**Solution**: Run `gh auth login` to authenticate with GitHub

### Repository Not Initialized
**Issue**: Git commands fail with "not a git repository"

**Solution**: Initialize the repository: `git init` and set up remote: `git remote add origin <repo-url>`

### Branch Already Exists
**Issue**: Branch checkout fails due to existing branch

**Solution**: The framework handles this with `-B` flag to force branch creation

### No Tags Detected
**Issue**: Issue created without labels

**Solution**: Default to `enhancement` tag if no keywords match

### PLAN.md Already Exists
**Issue**: PLAN.md file already exists in the branch

**Solution**: The framework handles this by asking if you want to overwrite or append

## Troubleshooting Checklist

Before creating the issue:
- [ ] GitHub CLI is installed: `gh --version`
- [ ] GitHub CLI is authenticated: `gh auth status`
- [ ] Git repository is initialized: `git status`
- [ ] Current branch is clean (no uncommitted changes)
- [ ] Remote repository is set up: `git remote -v`

After issue creation:
- [ ] Issue number is captured
- [ ] Issue URL is accessible
- [ ] Labels are correctly applied
- [ ] Issue is assigned to current user
- [ ] Framework completes successfully: branch created, PLAN.md committed, branch pushed

## Related Commands

```bash
# View current authenticated GitHub user
gh api user --jq '.login'

# List issues in the repository
gh issue list

# View issue details
gh issue view <issue-number>

# Edit an issue
gh issue edit <issue-number> --title "New Title" --body "New Description"

# Assign issue to yourself
gh issue edit <issue-number> --add-assignee @me

# Delete an issue
gh issue delete <issue-number>
```

## Related Skills

- **Framework**: `ticket-branch-workflow` - Provides core workflow (branch creation, PLAN.md, commit, push)
- `nextjs-pr-workflow`: For creating PRs after completing the issue
- `jira-git-workflow`: For JIRA-integrated workflows (uses same ticket-branch-workflow framework)
- `jira-git-integration`: For JIRA-specific operations when working with JIRA tickets
