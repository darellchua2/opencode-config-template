---
name: jira-git-integration
description: Generic JIRA + Git workflow utilities for ticket management, branch creation, and integration
license: Apache-2.0
compatibility: opencode
metadata:
  audience: developers
  workflow: jira-git-integration
---

## What I do
- Retrieve Atlassian cloud ID, visible projects, and accessible resources
- Get current user's account ID for ticket assignment
- Create JIRA tickets (tasks, stories, bugs) in specified projects
- Add comments to existing JIRA tickets with Markdown formatting
- Upload local images as JIRA attachments and retrieve attachment URLs
- Generate consistent branch names from JIRA tickets
- Fetch JIRA issue details (status, assignee, description)

## When to use me
Use this framework when:
- You need JIRA integration in a workflow
- You're creating a skill that requires JIRA ticket management
- You need to upload images to JIRA tickets
- You want to ensure consistent branch naming across JIRA workflows
- You need to add comments or attachments to JIRA tickets

This is a **framework skill** - it provides JIRA utilities that other skills use.

## Core Workflow Steps

### Step 1: Get Accessible Atlassian Resources
**Tool**: `atlassian_getAccessibleAtlassianResources`
```bash
atlassian_getAccessibleAtlassianResources
```
**Extract**: Store `id` field as cloud ID for subsequent JIRA operations.

### Step 2: Get JIRA User Information
**Tool**: `atlassian_atlassianUserInfo`
```bash
atlassian_atlassianUserInfo
```
**Extract**: Store `account_id` for ticket assignment.

### Step 3: Get Visible JIRA Projects
**Tool**: `atlassian_getVisibleJiraProjects --cloudId <CLOUD_ID>`
```bash
atlassian_getVisibleJiraProjects --cloudId <CLOUD_ID>
```
**Extract**: Store `key` field (e.g., `IBIS`) for ticket creation.

### Step 4: Create JIRA Ticket
**Tool**: `atlassian_createJiraIssue`
```bash
atlassian_createJiraIssue \
  --cloudId <CLOUD_ID> \
  --projectKey <PROJECT_KEY> \
  --issueTypeName <ISSUE_TYPE> \
  --summary "<Ticket Title>" \
  --description "<Ticket Description>" \
  --assignee_account_id <USER_ACCOUNT_ID>
```
**Parameters**:
- `cloudId`: Atlassian cloud ID
- `projectKey`: JIRA project key (e.g., `IBIS`)
- `issueTypeName`: Issue type name (e.g., `Task`, `Story`, `Bug`)
- `summary`: Short ticket title
- `description`: Markdown-formatted description
- `assignee_account_id`: User's account ID (optional)

**Description Template**:
```markdown
## Description
<Detailed description of work>

## Type
<Task | Story | Bug>

## Context
<Additional background information>

## Acceptance Criteria
- [ ] Criteria 1
- [ ] Criteria 2

## Files to Modify
1. `path/to/file1.ts` - Description
2. `path/to/file2.tsx` - Description
```
**Extract**: Store `key` field (e.g., `IBIS-101`) for reference.

### Step 5: Add Comment to JIRA Ticket
**Tool**: `atlassian_addCommentToJiraIssue`
```bash
atlassian_addCommentToJiraIssue \
  --cloudId <CLOUD_ID> \
  --issueIdOrKey <TICKET_KEY> \
  --commentBody "<Comment Content>"
```
**Parameters**:
- `cloudId`: Atlassian cloud ID
- `issueIdOrKey`: Ticket key (e.g., `IBIS-101`)
- `commentBody`: Markdown-formatted comment

**PR Reference Comment Template**:
```markdown
## Pull Request Created
**PR**: #<PR_NUMBER> - <PR_TITLE>
**URL**: <PR_URL>

### Quality Checks
- Linting: ✅ Passed
- Build: ✅ Passed
- Tests: ✅ Passed

### Review Request
@reviewer1 @reviewer2
```

### Step 6: Upload Image to JIRA
**Tool**: `atlassian_addAttachmentToJiraIssue`
```bash
atlassian_addAttachmentToJiraIssue \
  --cloudId <CLOUD_ID> \
  --issueIdOrKey <TICKET_KEY> \
  --attachment <IMAGE_FILE_PATH>
```
**Parameters**:
- `cloudId`: Atlassian cloud ID
- `issueIdOrKey`: Ticket key
- `attachment`: Path to local image file

**Extract**: `self` field provides attachment URL for embedding in comments.
**Usage**: `![Workflow Diagram](https://company.atlassian.net/secure/attachment/<ID>/filename.png)`

### Step 7: Generate JIRA Branch Name
**Conventions**:
- Simple: `IBIS-101`
- Feature: `feature/IBIS-101`
- Descriptive: `feature/IBIS-101-add-login`
- Bugfix: `bugfix/IBIS-102`
- Hotfix: `hotfix/IBIS-103`

**Implementation**:
```bash
TICKET_KEY="IBIS-101"
BRANCH_NAME="feature/${TICKET_KEY}"  # feature/IBIS-101
git checkout -b "${BRANCH_NAME}"
```

### Step 8: Get JIRA Issue Details
**Tool**: `atlassian_getJiraIssue`
```bash
atlassian_getJiraIssue \
  --cloudId <CLOUD_ID> \
  --issueIdOrKey <TICKET_KEY>
```
**Parameters**:
- `cloudId`: Atlassian cloud ID
- `issueIdOrKey`: Ticket key

**Extract**: Ticket status, assignee information, description content.

### Step 9: Transition JIRA Ticket Status
**Tools**: `atlassian_getTransitionsForJiraIssue`, `atlassian_transitionJiraIssue`
```bash
# Get available transitions
TRANSITIONS=$(atlassian_getTransitionsForJiraIssue --cloudId <CLOUD_ID> --issueIdOrKey <TICKET_KEY>)

# Find "Done" or "Closed" transition ID
TARGET_TRANSITION_ID=$(echo "$TRANSITIONS" | jq -r '.transitions[] | select(.to.name == "Done" or .to.name == "Closed") | .id' | head -1)

# Execute transition
atlassian_transitionJiraIssue \
  --cloudId <CLOUD_ID> \
  --issueIdOrKey <TICKET_KEY> \
  --transition '{"id": "<TRANSITION_ID>"}')
```

## Image Handling Strategy

**Detection Patterns**:
```bash
./diagrams/**/*.png
./diagrams/**/*.svg
/tmp/*.png
/tmp/*.jpg
**/*workflow*.png
**/*diagram*.png
```

**Handling Types**:
- `accessible_url`: Embed directly in JIRA comment
- `inaccessible_url`: Download and upload as JIRA attachment
- `local_file`: Upload as JIRA attachment
- `not_found`: Warn user and skip

## Best Practices

- Always retrieve cloud ID once per session
- Cache user account ID for assignment operations
- Use project keys (e.g., `IBIS`) consistently
- Use ticket keys (e.g., `IBIS-101`) for traceability
- Use consistent branch naming with ticket keys
- Upload local/temporary images, don't link to local paths
- Use Markdown for rich formatting in JIRA comments
- Check for JIRA API errors and provide clear messages
- Verify user has appropriate permissions for operations

## Common Issues

### Cloud ID Not Found
**Solution**: Use `atlassian_getAccessibleAtlassianResources` to find cloud ID.

### Project Not Found
**Solution**: List visible projects with `atlassian_getVisibleJiraProjects --cloudId <CLOUD_ID>`.

### User Not Assigned
**Solution**: Get user account ID with `atlassian_atlassianUserInfo`, then create ticket with `--assignee_account_id`.

### Image Upload Fails
**Solution**: Verify file path, check size limits (JIRA limits to 10-100MB), ensure permissions, verify file is not corrupted.

### Branch Name Conflicts
**Solution**: Force create with `git checkout -B <branch-name>` or switch to existing branch with `git checkout <existing-branch>`.

## Related Skills

Skills that use this JIRA integration framework:
- `git-pr-creator`: PR creation with JIRA comments and image uploads
- `jira-git-workflow`: JIRA ticket creation and branch management
- `nextjs-pr-workflow`: Next.js PR workflow with JIRA integration
- `jira-status-updater`: Automated JIRA ticket status transitions after PR merge

Additional related skills:
- `pr-creation-workflow`: Generic PR creation workflow
- `ticket-branch-workflow`: Ticket-to-branch-to-PLAN workflow
