---
name: git-issue-updater
description: Update GitHub issues and JIRA tickets with commit progress including user, date, time, and consistent documentation formatting for traceability
license: Apache-2.0
compatibility: opencode
metadata:
  audience: developers, maintainers
  workflow: issue-tracking
---

## What I do
- Extract commit details: hash, message, author, date, time, files changed
- Determine issue reference: GitHub issue number (#123) or JIRA ticket key (PROJECT-123) from commit message
- Format update comment with user, date, time, changes summary
- Support GitHub issues and JIRA tickets
- Include metadata: commit link (GitHub) or hash (JIRA), user info, timestamp
- Handle incremental updates (cumulative or per-commit)
- Verify comment was successfully added to issue/ticket

## When to use me
Use this framework when:
- Tracking commit progress in GitHub issues or JIRA tickets
- You've made commits and want to update the associated issue/ticket
- You want consistent documentation of progress with timestamps and user info
- You're creating a workflow that makes commits and should update issues
- You need traceability between commits and issues
- You want to maintain consistency in issue/ticket comments
- Working with teams that require progress updates in issues

This is a **framework skill** - it provides issue update functionality that other skills use.

## Core Workflow Steps

### Step 1: Extract Latest Commit Information
**Git Commands**:
```bash
COMMIT_HASH=$(git rev-parse HEAD)
COMMIT_MSG=$(git log -1 --pretty=%B)
COMMIT_AUTHOR=$(git log -1 --pretty=%an)
COMMIT_EMAIL=$(git log -1 --pretty=%ae)
COMMIT_DATE=$(git log -1 --date=iso8601 --pretty=%aI)
COMMIT_TIME=$(git log -1 --date=format:%H:%M%z --pretty=%aI)
CHANGED_FILES=$(git show --name-only --pretty=format: HEAD | grep -v "^$")
FILE_STATS=$(git diff --stat HEAD~1 HEAD)
```

### Step 2: Determine Issue Reference

**GitHub Issue Detection**:
```bash
ISSUE_NUM=$(echo "$COMMIT_MSG" | grep -oE '#[0-9]+' | head -1 | sed 's/#//')
if [ -n "$ISSUE_NUM" ]; then
  ISSUE_TYPE="github"
  ISSUE_REF="#$ISSUE_NUM"
fi
```

**JIRA Ticket Detection**:
```bash
TICKET_KEY=$(echo "$COMMIT_MSG" | grep -oE '[A-Z]+-[0-9]+' | head -1)
if [ -n "$TICKET_KEY" ]; then
  ISSUE_TYPE="jira"
  ISSUE_REF="$TICKET_KEY"
fi
```

**Combined Detection**:
```bash
# Try GitHub first, then JIRA, then branch name
if [ -z "$ISSUE_TYPE" ]; then
  BRANCH_NAME=$(git branch --show-current)
  echo "No issue reference found. Using branch: $BRANCH_NAME"
fi
```

### Step 3: Format Update Comment

**Comment Template**:
```markdown
## Progress Update - <Date> at <Time>

**Commit**: `<commit-hash>`
**Author**: `<user>` (<email>)
**Commit Message**: `<commit-message>`

### Changes Made
- [ ] <file1> - <brief description>
- [ ] <file2> - <brief description>

### Statistics
- Files changed: <count>
- Lines added: <+count>
- Lines removed: <-count>

### Commit Link
<platform-specific-link>
```

**GitHub Comment Example**:
```markdown
## Progress Update - 2024-01-25 at 14:30 UTC

**Commit**: `5f3a2b1c4d5e6f7`
**Author**: John Doe (john.doe@example.com)
**Commit Message**: feat(auth): add OAuth2 support

### Files Changed
- `src/auth/oauth.ts` (+150 lines)
- `src/auth/token.ts` (+95 lines)
- `src/api/auth.ts` (-12 lines, +12 lines)
```

**JIRA Comment Example**:
```markdown
## Progress Update

**Commit**: `5f3a2b1c4d5e6f7`
**Date**: 2024-01-25 14:30 UTC+08:00
**Author**: John Doe (john.doe@example.com)

### Work Completed
- [x] Implement OAuth2 authentication flow
- [x] Add token refresh mechanism

### Files Changed
- `src/auth/oauth.ts`
- `src/auth/token.ts`

### Next Steps
1. Add error handling for OAuth failures
2. Write integration tests
```

### Step 4: Update GitHub Issue

**GitHub CLI Command**:
```bash
gh issue comment "$ISSUE_NUM" --body "$COMMENT_BODY"
```

**Full Script**:
```bash
#!/bin/bash
# update-github-issue.sh

COMMIT_HASH=$(git rev-parse HEAD)
COMMIT_MSG=$(git log -1 --pretty=%s)
COMMIT_AUTHOR=$(git log -1 --pretty=%an)
COMMIT_EMAIL=$(git log -1 --pretty=%ae)
COMMIT_DATE=$(git log -1 --date=short --pretty=%aI)

ISSUE_NUM=$(echo "$COMMIT_MSG" | grep -oE '#[0-9]+' | head -1 | sed 's/#//')

if [ -z "$ISSUE_NUM" ]; then
  echo "❌ No GitHub issue number found"
  exit 1
fi

FILE_STATS=$(git diff --stat HEAD~1 HEAD)
REPO_OWNER=$(gh repo view --json ownerLogin --jq '.ownerLogin')
REPO_NAME=$(gh repo view --json name --jq '.name')
COMMIT_URL="https://github.com/${REPO_OWNER}/${REPO_NAME}/commit/${COMMIT_HASH}"

gh issue comment "$ISSUE_NUM" --body "$(cat <<EOF
## Progress Update - ${COMMIT_DATE}

**Commit**: \`$COMMIT_HASH\`
**Author**: $COMMIT_AUTHOR ($COMMIT_EMAIL)
**Commit Message**: $COMMIT_MSG

### Files Changed
\`\`\`
$FILE_STATS
\`\`\`

### Commit Link
[View on GitHub]($COMMIT_URL)
EOF
)"
```

### Step 5: Update JIRA Ticket

**JIRA API Command**:
```bash
atlassian_addCommentToJiraIssue \
  --cloudId "$CLOUD_ID" \
  --issueIdOrKey "$TICKET_KEY" \
  --commentBody "$COMMENT_BODY"
```

**Full Script**:
```bash
#!/bin/bash
# update-jira-ticket.sh

CLOUD_ID="${ATLASSIAN_CLOUD_ID:-<your-cloud-id>}"
COMMIT_HASH=$(git rev-parse HEAD)
COMMIT_MSG=$(git log -1 --pretty=%s)
COMMIT_AUTHOR=$(git log -1 --pretty=%an)
TICKET_KEY=$(echo "$COMMIT_MSG" | grep -oE '[A-Z]+-[0-9]+' | head -1)

if [ -z "$TICKET_KEY" ]; then
  echo "❌ No JIRA ticket key found"
  exit 1
fi

FILE_STATS=$(git diff --stat HEAD~1 HEAD)

atlassian_addCommentToJiraIssue \
  --cloudId "$CLOUD_ID" \
  --issueIdOrKey "$TICKET_KEY" \
  --commentBody "$(cat <<EOF
## Progress Update

**Commit**: \`$COMMIT_HASH\`
**Date**: $(git log -1 --date=short --pretty=%aI) $(git log -1 --date=format:%H:%M --pretty=%aI) UTC
**Author**: $COMMIT_AUTHOR

### Work Completed
$COMMIT_MSG

### Files Changed
\`\`\`
$FILE_STATS
\`\`\`

### File List
$(git show --name-only --pretty=format: HEAD | grep -v "^$" | sed 's/^/- /')
EOF
)"
```

### Step 6: Handle Incremental Updates

**Strategies**:

1. **Per-Commit Updates**: Each commit gets its own comment
2. **Cumulative Updates**: Combine multiple commits into one update (end of session)
3. **Checkpoint Updates**: Update at specific milestones (feature completion)

**Incremental Update Example**:
```markdown
## Progress Update #2 - 2024-01-25 at 16:45

Since last update, following work has been completed:

### Commits Made
1. **feat(auth): add OAuth2 support** (14:30)
2. **fix(auth): handle token refresh errors** (15:15)

### Total Statistics
- Commits: 2
- Files changed: 4
- Total lines added: +670
```

### Step 7: Verify Update

**GitHub Verification**:
```bash
gh issue view "$ISSUE_NUM" --json comments --jq '.comments | length'
```

**JIRA Verification**:
```bash
atlassian_getJiraIssue --cloudId "$CLOUD_ID" --issueIdOrKey "$TICKET_KEY" --expand comments
```

## Comment Format Standards

**Required Fields**:

| Field | Description | Example |
|--------|-------------|----------|
| Date | ISO 8601 or readable format | 2024-01-25 |
| Time | 24-hour format with timezone | 14:30 (UTC+08:00) |
| User | Commit author name | John Doe |
| Commit Hash | Full or short SHA | 5f3a2b1c4d5e6f7 |
| Commit Message | Subject or full message | feat(auth): add OAuth2 |
| Files Changed | List of modified files | src/auth/oauth.ts |
| Statistics | Files changed, +lines, -lines | Files: 3, +245, -12 |

**Date Formats**:
- ISO 8601: `2024-01-25T14:30:45+08:00`
- Human-Readable: `2024-01-25 at 14:30 (UTC+08:00)`

## Best Practices

### Update Timing
- Update immediately after each commit
- Batch multiple commits into one update (end of session)
- Update at specific milestones (feature completion, bug fix)
- Update when creating or merging PR

### User Information
- Always include commit author name
- Include email if needed for attribution
- Use consistent user format across all updates
- Handle co-authored commits appropriately

### Date and Time
- Use ISO 8601 format for machine readability
- Include timezone for clarity
- Be consistent with timezone across team (UTC recommended)

### Content Quality
- Provide clear summary of changes
- Include file statistics when relevant
- Link to commits for reference
- Keep updates concise but informative
- Use markdown formatting for readability

## Common Issues

### Issue Reference Not Found
**Solution**: Ask user to specify issue, use branch name as fallback.

### Comment Add Fails
**Solution**: 
- GitHub: Verify CLI authentication with `gh auth status`, check issue exists, verify write permissions
- JIRA: Verify Atlassian MCP tools, check cloud ID, verify ticket exists

### Duplicate Updates
**Solution**: Implement batching strategy, track updates in session file.

### Timezone Issues
**Solution**: Use UTC as standard timezone or store timezone in git config.

## Automation Options

### Git Commit Hook
Automatically update issue after commit:
```bash
#!/bin/bash
# .git/hooks/post-commit

COMMIT_HASH=$(git rev-parse HEAD)
COMMIT_MSG=$(git log -1 --pretty=%B)
ISSUE_REF=$(echo "$COMMIT_MSG" | grep -oE '#[0-9]+|[A-Z]+-[0-9]+' | head -1)

if [ -n "$ISSUE_REF" ]; then
  git-issue-updater "$ISSUE_REF" &
fi
```

### CI/CD Integration
Update issues in CI pipeline:
```yaml
name: Update Issue on Commit
on:
  push:
    branches: [main, develop]

jobs:
  update-issue:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Extract issue reference
        run: |
          MSG=$(git log -1 --pretty=%s)
          REF=$(echo "$MSG" | grep -oE '#[0-9]+|[A-Z]+-[0-9]+' | head -1)
          echo "ref=$REF" >> $GITHUB_OUTPUT
      - name: Update issue
        uses: peter-evans/create-or-update-comment@v2
        with:
          issue-number: ${{ steps.extract.outputs.ref }}
          body: |
            ## Progress Update
            **Commit**: ${{ github.sha }}
            **Date**: ${{ github.event.head_commit.timestamp }}
            **Author**: ${{ github.actor }}
```

## Integration with Other Skills

**Skills that use git-issue-updater**:
- `git-issue-creator`: Update issue after creating PLAN.md commit
- `ticket-branch-workflow`: Update ticket after creating PLAN.md commit
- `jira-git-workflow`: Update JIRA ticket after creating PLAN.md commit
- `git-pr-creator`: Update issue when PR is created/merged
- `nextjs-pr-workflow`: Update issue when Next.js PR is ready
- `pr-creation-workflow`: Update linked issues after PR creation

## References

- GitHub CLI Documentation: https://cli.github.com/manual/
- Git Log Formats: https://git-scm.com/docs/git-log#_pretty_formats
- ISO 8601: https://en.wikipedia.org/wiki/ISO_8601
- Atlassian API Documentation: https://developer.atlassian.com/cloud/jira/platform/rest/v3/api-group-issue-comments
