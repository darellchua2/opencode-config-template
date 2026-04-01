---
name: jira-ticket-pat-workflow
description: Create and manage JIRA tickets using Personal Access Token (PAT) API (no MCP server required)
license: Apache-2.0
compatibility: opencode
metadata:
  audience: developers
  workflow: jira-pat
---

## What I do

Create and manage JIRA tickets using direct PAT API calls:

1. Create JIRA tickets (Task, Story, Bug, Subtask)
2. Update ticket fields (summary, description)
3. Add comments to tickets
4. Transition ticket status (To Do → In Progress → Done)
5. Search tickets using JQL
6. Create git branch from ticket key

## When to use me

Use this skill when:
- You have a JIRA Personal Access Token (PAT) configured
- You want to create/manage JIRA tickets without MCP server
- You need direct API control over JIRA operations
- You prefer simpler auth than OAuth2 (no token refresh needed)

## Prerequisites

**Environment variables** (add to `~/.bashrc`):
```bash
export JIRA_PAT="your-pat-token"
export JIRA_SITE="your-site.atlassian.net"
```

**To create a PAT:**
1. Go to https://id.atlassian.com/manage-profile/security/pat
2. Click "Create token"
3. Select scopes: `read:jira-work`, `write:jira-work`
4. Copy the token

## API Reference

### Base URL
```
https://${JIRA_SITE}/rest/api/3
```

### Authentication
```
Authorization: Bearer ${JIRA_PAT}
```

## Steps

### 1. Validate Configuration
```bash
[ -z "$JIRA_PAT" ] && echo "Set JIRA_PAT environment variable" && exit 1
[ -z "$JIRA_SITE" ] && echo "Set JIRA_SITE environment variable" && exit 1
```

### 2. List Projects
```bash
curl -s -H "Authorization: Bearer $JIRA_PAT" \
  "https://${JIRA_SITE}/rest/api/3/project" | \
  python3 -c "import sys,json; [print(f\"{p['key']}\t{p['name']}\") for p in json.load(sys.stdin)]"
```

### 3. Create Ticket
```bash
curl -s -X POST \
  "https://${JIRA_SITE}/rest/api/3/issue" \
  -H "Authorization: Bearer $JIRA_PAT" \
  -H "Content-Type: application/json" \
  -d '{
    "fields": {
      "project": { "key": "PROJ" },
      "summary": "Ticket summary",
      "description": { "type": "doc", "version": 1, "content": [{ "type": "paragraph", "content": [{ "type": "text", "text": "Description" }] }] },
      "issuetype": { "name": "Task" }
    }
  }' | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('key', d))"
```

### 4. Add Comment
```bash
curl -s -X POST \
  "https://${JIRA_SITE}/rest/api/3/issue/PROJ-123/comment" \
  -H "Authorization: Bearer $JIRA_PAT" \
  -H "Content-Type: application/json" \
  -d '{ "body": { "type": "doc", "version": 1, "content": [{ "type": "paragraph", "content": [{ "type": "text", "text": "Comment text" }] }] } }'
```

### 5. Transition Status
```bash
# Get available transitions
curl -s -H "Authorization: Bearer $JIRA_PAT" \
  "https://${JIRA_SITE}/rest/api/3/issue/PROJ-123/transitions" | \
  python3 -c "import sys,json; [print(f\"{t['name']} (ID: {t['id']})\") for t in json.load(sys.stdin).get('transitions', [])]"

# Transition to new status
curl -s -X POST \
  "https://${JIRA_SITE}/rest/api/3/issue/PROJ-123/transitions" \
  -H "Authorization: Bearer $JIRA_PAT" \
  -H "Content-Type: application/json" \
  -d '{ "transition": { "id": "31" } }'
```

### 6. Search (JQL)
```bash
curl -s -G \
  "https://${JIRA_SITE}/rest/api/3/search" \
  --data-urlencode "jql=project=PROJ AND status=Open" \
  -H "Authorization: Bearer $JIRA_PAT" | \
  python3 -c "import sys,json; [print(f\"{i['key']}: {i['fields']['summary']}\") for i in json.load(sys.stdin).get('issues', [])]"
```

### 7. Create Branch
```bash
git checkout -b PROJ-123
```

## Related Skills

- `jira-ticket-oauth-workflow` - OAuth2-based JIRA workflow (requires token refresh)
- `jira-ticket-plan-workflow` - Branch and PLAN.md creation
- `git-semantic-commits` - Commit message formatting
- `git-issue-updater` - Update tickets with commit info
