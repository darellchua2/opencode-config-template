---
name: jira-workflow-framework
description: Framework for JIRA ticket management and Git integration workflows
license: Apache-2.0
compatibility: opencode
metadata:
  audience: developers, project managers
  workflow: project-tracking
  type: framework
---

## What I do

Framework for JIRA ticket management and development workflow integration. Extended by JIRA-specific skills.

## Extensions

| Skill | Purpose |
|-------|---------|
| `jira-git-integration` | Sync JIRA with Git operations |
| `jira-ticket-plan-workflow` | Full ticket → branch → plan workflow |
| `jira-status-updater` | Automate status transitions |

## Workflow Steps

### 1. Ticket Creation
- Create via `jira-ticket-plan-workflow`
- Include: title, description, acceptance criteria
- Assign to epic if applicable
- Set priority and story points

### 2. Branch from Ticket
- Branch naming: `PROJECT-NUM` (e.g., `IBIS-123`)
- Use `jira-git-integration` for linking
- Track branch in JIRA

### 3. Development Tracking
- Link commits to ticket: `git commit -m "feat: auth IBIS-123"`
- Update ticket with progress
- Add comments for significant changes

### 4. Status Transitions
- Use `jira-status-updater` for automation
- Common flow: To Do → In Progress → In Review → Done
- Update on PR creation and merge

### 5. Completion
- Update ticket with PR link
- Attach screenshots/diagrams
- Transition to Done after merge

## JIRA Operations (via MCP)

```bash
# Get issue
atlassian_getJiraIssue(cloudId, "IBIS-123")

# Create issue
atlassian_createJiraIssue(cloudId, projectKey, type, summary)

# Update issue
atlassian_editJiraIssue(cloudId, "IBIS-123", fields)

# Add comment
atlassian_addCommentToJiraIssue(cloudId, "IBIS-123", comment)

# Transition status
atlassian_transitionJiraIssue(cloudId, "IBIS-123", transitionId)
```

## Status Flow

```
To Do → In Progress → In Review → QA → Done
         ↑              ↓
         ← Reopened ←
```

## Best Practices

1. Link all commits to JIRA tickets
2. Update status on PR creation
3. Add PR link to ticket
4. Transition to Done after merge
5. Include acceptance criteria in description

## Related Skills

- `jira-git-integration` - Git + JIRA sync
- `jira-ticket-plan-workflow` - Full workflow
- `jira-status-updater` - Status automation
- `git-workflow-framework` - Git operations
