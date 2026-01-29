---
name: jira-status-updater
description: Automate JIRA ticket status transitions after pull requests are merged, ensuring proper workflow closure
license: Apache-2.0
compatibility: opencode
metadata:
  audience: developers
  workflow: jira-status-transition
---

## What I do

- Monitor GitHub pull request merge events
- Detect PR merge to identify associated JIRA ticket
- Determine appropriate JIRA status transition (e.g., "In Review" → "Done")
- Execute JIRA status transition using Atlassian MCP tools
- Support multiple workflow configurations and status mappings
- Handle edge cases: no JIRA ticket found, invalid transitions, permissions issues
- Provide logging and verification of status updates

## When to use me

Use when:
- PR has been successfully merged to main/master branch
- JIRA tickets need to be transitioned automatically after PR merge
- You want to ensure JIRA workflow reflects current development state
- You're setting up CI/CD pipeline to update JIRA status after merge
- You need to eliminate manual JIRA status updates
- You want to maintain consistency between PR status and JIRA ticket status

## Prerequisites

- GitHub repository with pull requests
- JIRA project configured with appropriate workflow
- Atlassian account with permissions to transition JIRA tickets
- JIRA cloud ID and project key
- JIRA ticket keys referenced in PR titles or descriptions

## Steps

### Step 1: Get Pull Request Information

```bash
# Get latest merged PR
gh pr list --state merged --limit 1 --json number,title,body,mergedAt,baseRefName
```

**Extract key information**:
```bash
PR_NUMBER=$(gh pr view --json number --jq '.number')
PR_TITLE=$(gh pr view --json title --jq '.title')
PR_BODY=$(gh pr view --json body --jq '.body')
MERGED_AT=$(gh pr view --json mergedAt --jq '.mergedAt')
BASE_REF=$(gh pr view --json baseRefName --jq '.baseRefName')
```

### Step 2: Extract JIRA Ticket Key

**Pattern matching**:

1. **From PR Title**: `PROJECT-123` format
```bash
TICKET_KEY=$(echo "$PR_TITLE" | grep -oE '[A-Z]+-[0-9]+' | head -1)
```

2. **From PR Body**: Search for JIRA references
```bash
TICKET_KEY=$(echo "$PR_BODY" | grep -oE '[A-Z]+-[0-9]+' | head -1)
```

3. **From Branch Name**: Extract from branch name
```bash
BRANCH_NAME=$(git branch --show-current)
TICKET_KEY=$(echo "$BRANCH_NAME" | grep -oE '[A-Z]+-[0-9]+' | head -1)
```

**Fallback**: Log warning and skip if no JIRA ticket found.

### Step 3: Verify JIRA Ticket Exists

```bash
# Query JIRA for ticket details
atlassian_getJiraIssue \
  --cloudId <CLOUD_ID> \
  --issueIdOrKey $TICKET_KEY
```

**Verify**: Ticket exists, current status allows transition, user has permissions.

### Step 4: Get Available Transitions

```bash
# Get available transitions for JIRA ticket
TRANSITIONS=$(atlassian_getTransitionsForJiraIssue \
  --cloudId <CLOUD_ID> \
  --issueIdOrKey $TICKET_KEY)
```

**Extract target transition ID** (e.g., "Done" or "Closed"):
```bash
TARGET_TRANSITION_ID=$(echo "$TRANSITIONS" | jq -r '.transitions[] | select(.to.name == "Done" or .to.name == "Closed") | .id' | head -1)
```

### Step 5: Execute Status Transition

```bash
# Execute JIRA status transition
atlassian_transitionJiraIssue \
  --cloudId <CLOUD_ID> \
  --issueIdOrKey $TICKET_KEY \
  --transition '{"id": "<TRANSITION_ID>"}'
```

### Step 6: Verify Status Update

```bash
# Query JIRA ticket to verify status change
atlassian_getJiraIssue \
  --cloudId <CLOUD_ID> \
  --issueIdOrKey $TICKET_KEY
```

**Verify**: Check that ticket status has changed to expected state.

## Status Mapping

**Common workflow configurations**:

| Current Status | Target Status | Transition Name | Trigger |
|--------------|--------------|----------------|---------|
| In Progress | Done | Done | PR merged to main/master |
| In Review | Done | Done | PR approved and merged |
| Ready for QA | Done | Done | QA passed and PR merged |
| Ready for Development | In Progress | Start Progress | PR merged and new work started |
| Open | Done | Done | Feature completed and merged |
| In Progress | Closed | Closed | Issue resolved and PR merged |

## Best Practices

- Only transition JIRA tickets after PR merge (not during PR creation)
- Verify JIRA ticket exists before attempting transition
- Check current status to ensure target transition is available
- Use consistent transition names across your JIRA workflow
- Log all status transitions for audit trail
- Handle missing JIRA tickets gracefully (log warning, don't fail)
- Use appropriate JIRA transition names for your project workflow
- Test status transitions with test tickets before enabling automation

## Common Issues

### JIRA Ticket Not Found
**Solution**: Verify ticket key format, check project key, ensure ticket exists.

### Invalid Transition
**Solution**: Check current ticket status, verify target transition is available.

### Permission Denied
**Solution**: Ensure Atlassian account has permissions to transition tickets.

### Already in Target Status
**Solution**: Check current status before transition, skip if already in target state.

### Multiple JIRA Tickets in PR
**Solution**: Extract all JIRA ticket keys, process each one individually.

## CI/CD Integration

**GitHub Actions example**:
```yaml
name: Update JIRA Status on PR Merge
on:
  pull_request:
    types: [closed]

jobs:
  update-jira:
    runs-on: ubuntu-latest
    if: github.event.pull_request.merged == true
    steps:
      - name: Update JIRA ticket status
        env:
          CLOUD_ID: ${{ secrets.ATLASSIAN_CLOUD_ID }}
        run: |
          PR_TITLE="${{ github.event.pull_request.title }}"
          
          # Extract JIRA ticket key
          TICKET_KEY=$(echo "$PR_TITLE" | grep -oE '[A-Z]+-[0-9]+' | head -1)
          
          if [ -n "$TICKET_KEY" ]; then
            # Get available transitions
            TRANSITIONS=$(atlassian_getTransitionsForJiraIssue --cloudId "$CLOUD_ID" --issueIdOrKey "$TICKET_KEY")
            
            # Find "Done" transition
            TARGET_ID=$(echo "$TRANSITIONS" | jq -r '.transitions[] | select(.to.name == "Done" or .to.name == "Closed") | .id' | head -1)
            
            # Execute transition
            atlassian_transitionJiraIssue --cloudId "$CLOUD_ID" --issueIdOrKey "$TICKET_KEY" --transition "{\"id\": \"$TARGET_ID\"}"
            
            echo "✅ Transitioned JIRA ticket $TICKET_KEY to Done"
          else
            echo "⚠️  No JIRA ticket key found in PR title"
          fi
```

## References

- Atlassian JIRA API: https://developer.atlassian.com/cloud/jira/platform/rest/v3/api-group-issue
- GitHub Actions Documentation: https://docs.github.com/en/actions
- JIRA Workflow Documentation: https://confluence.atlassian.com/jirakb/using-workflows
