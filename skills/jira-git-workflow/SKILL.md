---
name: jira-git-workflow
description: JIRA ticket creation and branching, extending ticket-branch-workflow and jira-git-integration
license: Apache-2.0
compatibility: opencode
metadata:
  audience: developers
  workflow: jira-git
---

## What I do

I implement the standard JIRA-to-Git workflow by combining `jira-git-integration` and `ticket-branch-workflow`:

1. **Identify JIRA Project**: Use `jira-git-integration` to find project and cloud ID
2. **Create JIRA Ticket**: Use `jira-git-integration` to create task/issue with summary and description
3. **Add Comments** (Optional): Use `jira-git-integration` to add clarifying comments if needed
4. **Create Git Branch**: Create branch named after JIRA ticket (format: `PROJECT-NUM`)
5. **Commit PLAN.md**: Use `ticket-branch-workflow` to create and commit PLAN.md

## When to use me

**Framework**: This skill combines two frameworks:
- `jira-git-integration` - Handles JIRA-specific operations (project discovery, ticket creation, comments)
- `ticket-branch-workflow` - Handles core workflow (branch creation, PLAN.md, commit, push)

Use this workflow when:
- Starting a new development task tracked in JIRA
- You need a systematic approach: JIRA ticket → branch → PLAN.md
- Following the standard practice of planning before coding

## Prerequisites

- Active Atlassian/JIRA account with appropriate permissions
- Git repository initialized
- Write access to the repository

## Steps

### Step 1: Identify JIRA Project
- Use `jira-git-integration` project discovery:
  - Use `atlassian_getVisibleJiraProjects` to list available projects
  - Identify the project key for your work (e.g., IBIS, DA, etc.)
  - Get the cloud ID using `atlassian_getAccessibleAtlassianResources`

### Step 2: Create JIRA Ticket
- Use `jira-git-integration` ticket creation:
  - Use `atlassian_createJiraIssue` with:
    - `cloudId`: The Atlassian cloud ID
    - `projectKey`: The project key (e.g., IBIS)
    - `issueTypeName`: Typically "Task" or "Story"
    - `summary`: Concise title for the work
    - `description`: Detailed description with:
      - Overview
      - Scope/files affected
      - Requirements
      - Rationale
    - `assignee_account_id`: Your account ID (optional, use `atlassian_atlassianUserInfo` to get it)
  - Store the ticket key (e.g., IBIS-101)

### Step 3: Add Comments (Optional)
- If clarification is needed, use `jira-git-integration` comment features:
  - Use `atlassian_addCommentToJiraIssue` with:
    - `cloudId`: The cloud ID
    - `issueIdOrKey`: The ticket key (e.g., IBIS-101)
    - `commentBody`: The comment in Markdown format

### Step 4: Create Git Branch
- Create branch named after JIRA ticket: `git checkout -b <TICKET-KEY>`
- Example: `git checkout -b IBIS-101`

### Step 5: Execute Ticket-Branch-Workflow
- Use `ticket-branch-workflow` to:
  - Create PLAN.md with JIRA ticket reference
  - Commit PLAN.md: `git commit -m "Add PLAN.md for <TICKET-KEY>: <brief summary>"`
  - Push branch to remote: `git push -u origin <TICKET-KEY>`

## Example PLAN.md Structure

The framework generates PLAN.md with JIRA reference:
```markdown
# Plan: <Ticket Summary>

## Overview
Brief description of what this ticket implements.

## Ticket Reference
- Ticket: <TICKET-KEY>
- URL: <ticket-url>

## Files to Modify
1. `src/path/to/file1.ts` - Description
2. `src/path/to/file2.tsx` - Description

## Approach
Detailed steps or methodology for implementation.

## Success Criteria
- All files modified correctly
- No build errors
- Tests pass
```

## Best Practices

- Use `jira-git-integration` for all JIRA operations (project discovery, ticket creation, comments)
- Use `ticket-branch-workflow` for branch, PLAN.md, commit, and push operations
- Keep the plan specific and actionable
- Use the JIRA ticket key as the branch name for traceability
- Include a clear rationale in both the JIRA ticket and PLAN.md
- Commit the PLAN.md as the first commit on the new branch

## Common Issues

### Permission denied on JIRA
**Issue**: Cannot create JIRA ticket

**Solution**: Ensure your account has create permissions for the project (handled by `jira-git-integration`)

### Branch already exists
**Issue**: Branch checkout fails due to existing branch

**Solution**: The framework handles this with `-B` flag to force branch creation

### Missing cloud ID
**Issue**: Cannot create JIRA ticket without cloud ID

**Solution**: `jira-git-integration` provides tools to find your cloud ID: `atlassian_getAccessibleAtlassianResources`

### Assignee error
**Issue**: Cannot assign ticket to yourself

**Solution**: Use `atlassian_atlassianUserInfo` to get your account ID (part of `jira-git-integration`)

## Troubleshooting Checklist

Before starting:
- [ ] Atlassian/JIRA account has project access
- [ ] Git repository is initialized: `git status`
- [ ] Current branch is clean (no uncommitted changes)
- [ ] Remote repository is set up: `git remote -v`

After ticket creation:
- [ ] Ticket key is captured (e.g., IBIS-101)
- [ ] Ticket URL is accessible
- [ ] Ticket is assigned (if needed)

After framework execution:
- [ ] Branch is created and checked out successfully
- [ ] PLAN.md is created with ticket reference
- [ ] PLAN.md is committed to the branch
- [ ] Branch is pushed to remote successfully

## Related Skills

- **Frameworks**:
  - `jira-git-integration` - Provides JIRA-specific operations (project discovery, ticket creation, comments)
  - `ticket-branch-workflow` - Provides core workflow (branch creation, PLAN.md, commit, push)
- `nextjs-pr-workflow`: For creating PRs after completing the ticket
- `git-issue-creator`: For GitHub-integrated workflows (uses same ticket-branch-workflow framework)
