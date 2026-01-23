---
name: jira-git-workflow
description: Standard practice for JIRA ticket creation, branching, and PLAN.md commit workflow
license: Apache-2.0
compatibility: opencode
metadata:
  audience: developers
  workflow: jira-git
---

## What I do

I implement the standard JIRA-to-Git workflow:

1. **Create JIRA Ticket**: Create a new task/issue in the specified JIRA project with appropriate summary and description
2. **Add Comments**: Optionally add clarifying comments to the JIRA ticket if needed
3. **Create Git Branch**: Create and checkout a new git branch named after the JIRA ticket (format: `PROJECT-NUM`)
4. **Commit PLAN.md**: Create and commit a PLAN.md file to the new branch outlining the implementation approach

## When to use me

Use this workflow when:
- Starting a new development task tracked in JIRA
- You need to create a systematic approach to implement a feature or fix
- Following the standard practice of planning before coding

## Prerequisites

- Active Atlassian/JIRA account with appropriate permissions
- Git repository initialized
- Git branch named after JIRA ticket (format: `PROJECT-NUM`)
- Write access to the repository

## Steps

### Step 1: Identify JIRA Project
- Use `atlassian_getVisibleJiraProjects` to list available projects
- Identify the project key for your work (e.g., IBIS, DA, etc.)
- Get the cloud ID using `atlassian_getAccessibleAtlassianResources`

### Step 2: Create JIRA Ticket
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

### Step 3: Add Comments (Optional)
- If clarification is needed, use `atlassian_addCommentToJiraIssue` with:
  - `cloudId`: The cloud ID
  - `issueIdOrKey`: The ticket key (e.g., IBIS-101)
  - `commentBody`: The comment in Markdown format

### Step 4: Create Git Branch
- Switch to the ticket branch: `git checkout -b <TICKET-KEY>`
- Example: `git checkout -b IBIS-101`

### Step 5: Create PLAN.md
- Create a PLAN.md file with:
  - Overview section
  - Files to modify (list them out)
  - Documentation standards/approach
  - Order of implementation
  - Success criteria
- Structure the plan to be executable and trackable

### Step 6: Commit PLAN.md
- Add the file: `git add PLAN.md`
- Commit with a descriptive message: `git commit -m "Add PLAN.md for <TICKET-KEY>: <brief summary>"`
- Verify commit: `git status`

## Example PLAN.md Structure

```markdown
# Plan: <Ticket Summary>

## Overview
Brief description of what this ticket implements.

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

- Always start with a PLAN.md before making code changes
- Keep the plan specific and actionable
- Use the JIRA ticket key as the branch name for traceability
- Include a clear rationale in both the JIRA ticket and PLAN.md
- Commit the PLAN.md as the first commit on the new branch

## Common Issues

- **Permission denied on JIRA**: Ensure your account has create permissions for the project
- **Branch already exists**: Switch to existing branch or use `-B` force flag
- **Missing cloud ID**: Use `atlassian_getAccessibleAtlassianResources` to find it
- **Assignee error**: Get your account ID from `atlassian_atlassianUserInfo`