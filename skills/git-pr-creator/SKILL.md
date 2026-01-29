---
name: git-pr-creator
description: Create Git pull requests and optionally update JIRA tickets with comments and image attachments
license: Apache-2.0
compatibility: opencode
metadata:
  audience: developers
  workflow: pr-creation
---

## What I do

- Check git status and verify all changes are committed
- Ask user if JIRA is used for the project
- Create Git pull request with comprehensive description
- Use git-semantic-commits for PR title formatting
- Scan for workflow-related images and diagrams
- Attach local/temporary images directly to JIRA (not just links)
- Add JIRA comments with PR details and attachments
- Update JIRA ticket status after manual merge (optional)

## When to use me

Use when:
- You've completed work on a feature or fix and need to create a PR
- You want to update JIRA tickets with PR information
- You have diagrams or images that need to be attached to JIRA
- You need to ensure traceability between PRs and JIRA tickets
- You want to maintain consistency in PR creation workflow

## Prerequisites

- Git repository with commits to push
- GitHub CLI (`gh`) or GitLab CLI (`glab`) installed and authenticated
- If using JIRA: Atlassian account with appropriate permissions
- JIRA cloud ID and project key (if JIRA is used)

## Steps

### Step 1: Check Git Status

```bash
git status
```

**Ensure**:
- All changes are committed
- No uncommitted changes exist
- Working tree is clean

### Step 2: Push Branch to Remote

```bash
git push -u origin <branch-name>
```

### Step 3: Ask About JIRA Integration

```bash
read -p "Is JIRA used for this project? (yes/no): " JIRA_ENABLED
```

- If yes, proceed with JIRA integration steps
- If no, skip JIRA-related steps

### Step 4: Get JIRA Ticket Information (if JIRA is used)

```bash
read -p "Enter JIRA ticket key (e.g., IBIS-101): " TICKET_KEY

# Verify ticket exists
atlassian_getJiraIssue --cloudId <CLOUD_ID> --issueIdOrKey $TICKET_KEY
```

### Step 5: Scan for Diagrams and Images

**Common image locations**:
```bash
./diagrams/**/*.png
./diagrams/**/*.svg
/tmp/*.png
/tmp/*.jpg
**/*workflow*.png
**/*diagram*.png
**/*flow*.png
**/*architecture*.png
**/*sequence*.png
```

**Categorization**:
- Accessible URLs: Embed directly in JIRA comment
- Local/temporary files: Upload as JIRA attachments
- Not found: Warn user and skip

### Step 6: Upload Images to JIRA (if needed)

```bash
for image_path in $LOCAL_IMAGES; do
  atlassian_addAttachmentToJiraIssue \
    --cloudId <CLOUD_ID> \
    --issueIdOrKey $TICKET_KEY \
    --attachment $image_path
done
```

**Output**: Store attachment URLs returned for use in JIRA comments.

### Step 7: Create JIRA Comments (if JIRA is used)

**Comment Template**:
```markdown
## Pull Request Created

**PR**: #<PR_NUMBER> - <PR_TITLE>
**URL**: <PR_URL>
**Branch**: <branch-name>

### Changes Summary
<Brief description of changes>

### Files Modified
<list of key files changed>

### Quality Checks
- Linting: ✅ Passed
- Build: ✅ Passed
- Tests: ✅ Passed

### Diagrams/Visuals
<embed uploaded images using JIRA attachment format>

### Review Request
@reviewer1 @reviewer2
```

### Step 8: Create Pull Request

**Use git-semantic-commits for PR title formatting**:
```bash
# Format: <type>(<scope>): <subject>
# Examples:
# feat: add login functionality
# fix(auth): resolve session timeout
# docs: update API documentation
```

**Create PR**:
```bash
gh pr create --title "<PR Title>" --body "<PR Description>"
```

**PR description should include**:
- Overview of changes
- JIRA ticket reference (if applicable)
- Files changed
- Testing performed
- Screenshots/diagrams (as references or attachments)
- Review request

## Best Practices

- Ensure all changes are committed before creating PR
- Use descriptive, clear PR titles following Conventional Commits
- Include JIRA ticket reference in PR description for traceability
- Attach images to JIRA for better visibility (not just links)
- Use consistent formatting for PR descriptions
- Request appropriate reviewers based on changes
- Include test coverage information if relevant
- Add breaking change indicators if applicable (`feat!:`, `fix!:`)
- Ensure PR branch is up to date with target branch

## Common Issues

### Uncommitted Changes Exist
**Solution**: Commit all changes with `git add . && git commit -m "<message>"`.

### Branch Push Fails
**Solution**: Ensure remote exists, check authentication, resolve conflicts with `git pull origin main`.

### JIRA Ticket Not Found
**Solution**: Verify ticket key, check cloud ID, ensure ticket exists in JIRA.

### Image Upload Fails
**Solution**: Verify file path, check file size limits, ensure you have JIRA permissions.

### PR Title Doesn't Follow Conventions
**Solution**: Use git-semantic-commits framework for proper formatting.

## References

- GitHub PR Documentation: https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/proposing-changes
- Conventional Commits: https://www.conventionalcommits.org/
- git-semantic-commits skill: For PR title formatting
