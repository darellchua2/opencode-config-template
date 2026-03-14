---
name: jira-ticket-oauth-workflow
description: Create and manage JIRA tickets using OAuth2 API (no MCP server required)
license: Apache-2.0
compatibility: opencode
metadata:
  audience: developers
  workflow: jira-oauth
---

## What I do

Create and manage JIRA tickets using direct OAuth2 API calls:

1. Create JIRA tickets (Task, Story, Bug, Subtask)
2. Update ticket fields (summary, description)
3. Add comments to tickets
4. Transition ticket status (To Do → In Progress → Done)
5. Search tickets using JQL
6. Create git branch from ticket key

## When to use me

Use this skill when:
- You have JIRA OAuth2 credentials configured in environment variables
- You want to create/manage JIRA tickets without MCP server
- You need direct API control over JIRA operations

## Prerequisites

**Environment variables** (set via `./setup.sh` → option 5):
```bash
JIRA_CLIENT_ID="your-client-id"
JIRA_CLIENT_SECRET="your-client-secret"
JIRA_ACCESS_TOKEN="your-access-token"
JIRA_REFRESH_TOKEN="your-refresh-token"
JIRA_CLOUD_ID="your-cloud-id"  # Optional
```

## API Reference

### Base URL
```
https://api.atlassian.com/ex/jira/{cloudId}/rest/api/3
```

## Steps

### 1. Validate Configuration
```bash
[ -z "$JIRA_ACCESS_TOKEN" ] && echo "Run ./setup.sh to configure JIRA OAuth2" && exit 1
```

### 2. Get Cloud ID (if not set)
```bash
curl -s -H "Authorization: Bearer $JIRA_ACCESS_TOKEN" \
  "https://api.atlassian.com/oauth/token/accessible-resources" | jq -r '.[0].id'
```

### 3. List Projects
```bash
curl -s -H "Authorization: Bearer $JIRA_ACCESS_TOKEN" \
  "https://api.atlassian.com/ex/jira/${JIRA_CLOUD_ID}/rest/api/3/project" | \
  jq -r '.[] | "\(.key)\t\(.name)"'
```

### 4. Create Ticket
```bash
curl -s -X POST \
  "https://api.atlassian.com/ex/jira/${JIRA_CLOUD_ID}/rest/api/3/issue" \
  -H "Authorization: Bearer $JIRA_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "fields": {
      "project": { "key": "PROJ" },
      "summary": "Ticket summary",
      "description": { "type": "doc", "version": 1, "content": [{ "type": "paragraph", "content": [{ "type": "text", "text": "Description" }] }] },
      "issuetype": { "name": "Task" }
    }
  }' | jq -r '.key'
```

### 5. Add Comment
```bash
curl -s -X POST \
  "https://api.atlassian.com/ex/jira/${JIRA_CLOUD_ID}/rest/api/3/issue/PROJ-123/comment" \
  -H "Authorization: Bearer $JIRA_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{ "body": { "type": "doc", "version": 1, "content": [{ "type": "paragraph", "content": [{ "type": "text", "text": "Comment text" }] }] } }'
```

### 6. Transition Status
```bash
# Get available transitions
curl -s -H "Authorization: Bearer $JIRA_ACCESS_TOKEN" \
  "https://api.atlassian.com/ex/jira/${JIRA_CLOUD_ID}/rest/api/3/issue/PROJ-123/transitions" | \
  jq -r '.transitions[] | "\(.name) (ID: \(.id))"'

# Transition to new status
curl -s -X POST \
  "https://api.atlassian.com/ex/jira/${JIRA_CLOUD_ID}/rest/api/3/issue/PROJ-123/transitions" \
  -H "Authorization: Bearer $JIRA_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{ "transition": { "id": "31" } }'
```

### 7. Search (JQL)
```bash
curl -s -G \
  "https://api.atlassian.com/ex/jira/${JIRA_CLOUD_ID}/rest/api/3/search" \
  --data-urlencode "jql=project=PROJ AND status=Open" \
  -H "Authorization: Bearer $JIRA_ACCESS_TOKEN" | \
  jq '.issues[] | {key: .key, summary: .fields.summary}'
```

### 8. Create Branch
```bash
git checkout -b PROJ-123
```

## Token Refresh

If you get a 401 error, refresh the token:
```bash
response=$(curl -s -X POST "https://auth.atlassian.com/oauth/token" \
  -H "Content-Type: application/json" \
  -d "{
    \"grant_type\": \"refresh_token\",
    \"client_id\": \"${JIRA_CLIENT_ID}\",
    \"client_secret\": \"${JIRA_CLIENT_SECRET}\",
    \"refresh_token\": \"${JIRA_REFRESH_TOKEN}\"
  }")

export JIRA_ACCESS_TOKEN=$(echo "$response" | jq -r '.access_token')
export JIRA_REFRESH_TOKEN=$(echo "$response" | jq -r '.refresh_token')
```

Then update `~/.bashrc` with the new tokens.

## Related Skills

- `ticket-branch-workflow` - Branch and PLAN.md creation
- `git-semantic-commits` - Commit message formatting
- `git-issue-updater` - Update tickets with commit info
