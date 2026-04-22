---
name: ticket-plan-workflow-skill
description: Unified ticket/issue planning workflow for GitHub Issues and JIRA, with structured description, branch creation, PLAN.md generation, and phased execution
license: Apache-2.0
compatibility: opencode
metadata:
  audience: developers
  workflow: unified-planning
---

## What I do

I implement a unified ticket/issue creation and planning workflow supporting both GitHub Issues and JIRA:

1. **Detect Platform**: Determine whether to use GitHub Issues or JIRA based on user input and project setup
2. **Gather Ticket Requirements**: Prompt user for structured description following industry best practices
3. **Determine Ticket Scope**: Ask if work should be broken into sub-issues/subtasks
4. **Create Ticket**: Use GitHub CLI or Atlassian MCP tools to create the ticket with appropriate labels/type
5. **Create Git Branch**: Generate branch from ticket identifier (e.g., `GIT-123` or `PROJ-456`)
6. **Generate PLAN file**: Create comprehensive plan with phases and todo list in `PLANS/` directory
7. **Commit and Push**: Commit PLAN file with semantic formatting and push to remote
8. **Update Ticket**: Post progress comment to GitHub issue or JIRA ticket
9. **Prompt Execution**: Ask user if they want to proceed with plan execution

## Framework Skills Used

| Skill | Purpose | Used In |
|-------|---------|---------|
| `git-issue-labeler` | GitHub label assessment and assignment | Step 4 (GitHub) |
| `git-semantic-commits` | Conventional commit message formatting | Step 7 |
| `git-issue-updater` | Progress updates to GitHub issues | Step 8 (GitHub) |

## When to use me

Use this workflow when:
- Starting a new development task tracked in GitHub Issues or JIRA
- You want a standardized approach to ticket creation and planning
- You need to break down large work into structured phases
- Following the practice of planning before implementation

## Prerequisites

### GitHub Issues
- GitHub CLI (`gh`) installed and authenticated
- Git repository initialized with GitHub remote
- Write access to repository
- `gh auth status` shows valid authentication

### JIRA
- Active Atlassian/JIRA account with project access
- Git repository initialized with remote configured
- Write access to repository
- Atlassian MCP server configured

## Steps

### Step 1: Detect Platform

**Detection Logic**:
```bash
# Check if user specified a platform
# If user mentions JIRA ticket format (e.g., "PROJ-123") → JIRA
# If user mentions GitHub issue (#123) → GitHub
# If user says "create issue" → GitHub
# If user says "create ticket" → Ask which platform

# Auto-detect: Check for JIRA project access
atlassian_getVisibleJiraProjects --cloudId "$CLOUD_ID" 2>/dev/null

# Prompt user if ambiguous
"Which platform for this ticket?
- GitHub Issues (default)
- JIRA"
```

**Platform Selection**:
- Set `PLATFORM` variable: `github` or `jira`
- This determines all subsequent steps

### Step 2: Gather Ticket Description

Prompt the user for a structured ticket description with these sections:

**Required Information**:
1. **Title/Summary**: Concise title (max 72 characters)
2. **Overview**: Brief description of what needs to be done
3. **Acceptance Criteria**: Definition of done (bullet points)
4. **Scope**: Files or areas affected
5. **Technical Notes**: Implementation considerations (optional)

**Prompt Template**:
```
Please provide the following for your ticket:

1. **Title** (required): Brief title for the ticket
   Example: "Implement user authentication API"

2. **Overview** (required): What does this ticket accomplish?
   Example: "Add JWT-based authentication endpoints for user login/registration"

3. **Acceptance Criteria** (required): How do we know it's done?
   Example:
   - Users can register with email/password
   - Users can login and receive JWT token
   - Protected routes validate JWT

4. **Scope** (required): What files/areas will be affected?
   Example: src/api/auth/, src/middleware/, tests/auth/

5. **Technical Notes** (optional): Any implementation details?
   Example: Use bcrypt for password hashing, 24h token expiry
```

### Step 3: Determine Ticket Scope

Ask user to choose ticket complexity:

**Question**: "Should this be broken into smaller sub-issues/subtasks?"

**Options**:
- **Parent with Sub-items**: Creates a parent ticket, then prompts for sub-items
- **Single Ticket**: Creates one ticket for contained work

**Parent Flow (GitHub)**:
```markdown
If Parent selected:
1. Create parent issue
2. Prompt for sub-issues (repeat until done):
   - Sub-issue title
   - Sub-issue description
3. Create each sub-issue and link to parent
4. Branch name uses parent issue number (e.g., GIT-123)
```

**Parent Flow (JIRA)**:
```markdown
If Story selected:
1. Create parent Story ticket
2. Prompt for subtasks (repeat until done):
   - Subtask summary
   - Subtask description
3. Create each subtask linked to parent Story
4. Branch name uses Story key (e.g., PROJ-123)
```

**Single Ticket Flow**:
```markdown
If Single selected:
1. Create single ticket with appropriate labels/type
2. Branch name uses ticket identifier
```

### Step 4: Create Ticket

#### GitHub Issues

**Label Detection** — delegate to `git-issue-labeler` skill:
```bash
# Use git-issue-labeler to determine appropriate labels
# The skill analyzes issue content and assigns GitHub default labels
# See: skills/git-issue-labeler-skill/SKILL.md
```

**Available Labels** (handled by `git-issue-labeler`):
- `bug`, `enhancement`, `documentation`, `good first issue`, `help wanted`
- `question`, `invalid`, `wontfix`, `duplicate`
- `major`, `minor`, `patch` (semantic versioning)

**For Single Issue**:
```bash
ISSUE_URL=$(gh issue create \
  --title "$TITLE" \
  --body "$FORMATTED_BODY" \
  --label "$LABELS" \
  --assignee @me)

ISSUE_NUMBER=$(echo "$ISSUE_URL" | grep -oE '[0-9]+$')
```

**For Parent with Sub-issues**:
```bash
PARENT_URL=$(gh issue create \
  --title "$TITLE" \
  --body "$FORMATTED_BODY" \
  --label "$LABELS" \
  --assignee @me)

PARENT_NUMBER=$(echo "$PARENT_URL" | grep -oE '[0-9]+$')

for subissue in "${SUBISSUES[@]}"; do
  gh issue create \
    --title "$subissue.title" \
    --body "$subissue.body\n\nParent: #$PARENT_NUMBER" \
    --label "$subissue.labels" \
    --assignee @me
done
```

#### JIRA Tickets

**Select JIRA Project** (if not specified):
```bash
atlassian_getVisibleJiraProjects --cloudId "$CLOUD_ID"
# Prompt user to select project by key (e.g., IBIS, PROJ, DA)
```

**For Single Task**:
```bash
TICKET_KEY=$(atlassian_createJiraIssue \
  --cloudId "$CLOUD_ID" \
  --projectKey "$PROJECT_KEY" \
  --issueTypeName "Task" \
  --summary "$SUMMARY" \
  --description "$FORMATTED_DESCRIPTION")
```

**For Story with Subtasks**:
```bash
STORY_KEY=$(atlassian_createJiraIssue \
  --cloudId "$CLOUD_ID" \
  --projectKey "$PROJECT_KEY" \
  --issueTypeName "Story" \
  --summary "$SUMMARY" \
  --description "$FORMATTED_DESCRIPTION")

for subtask in "${SUBTASKS[@]}"; do
  atlassian_createJiraIssue \
    --cloudId "$CLOUD_ID" \
    --projectKey "$PROJECT_KEY" \
    --issueTypeName "Sub-task" \
    --summary "$subtask.summary" \
    --description "$subtask.description" \
    --parent "$STORY_KEY"
done
```

**Formatted Body/Description Template**:
```markdown
## Overview
$OVERVIEW

## Acceptance Criteria
$ACCEPTANCE_CRITERIA

## Scope
$SCOPE

## Technical Notes
$TECHNICAL_NOTES

---
*Tracking progress with ticket-plan-workflow-skill*"
---

## Implementation Phases

### Phase 1: Setup & Analysis
- [ ] Review existing codebase for affected areas
- [ ] Identify dependencies and potential conflicts
- [ ] Set up development environment if needed
- [ ] Create feature flags (if applicable)

### Phase 2: Core Implementation
- [ ] Implement primary functionality
- [ ] Add error handling and edge cases
- [ ] Update affected modules/components
- [ ] Add logging and monitoring

### Phase 3: Testing
- [ ] Write unit tests for new functionality
- [ ] Write integration tests
- [ ] Perform manual testing
- [ ] Test edge cases and error scenarios

### Phase 4: Documentation & Cleanup
- [ ] Update code documentation/docstrings
- [ ] Update README if applicable
- [ ] Remove debug code and comments
- [ ] Code review preparation

### Phase 5: Final Validation
- [ ] Run all tests (unit, integration, e2e)
- [ ] Verify acceptance criteria met
- [ ] Performance testing (if applicable)
- [ ] Security review (if applicable)

---

## Technical Notes
$TECHNICAL_NOTES

## Dependencies
_List any external dependencies or blocked-by tickets_

## Risks & Mitigation
_Identify potential risks and how to mitigate them_

## Success Metrics
_How will we measure success?_
```

### Step 7: Commit and Push PLAN file

**Use `git-semantic-commits` skill** for proper commit message formatting:

```bash
# Determine PLAN filename based on platform
if [ "$PLATFORM" = "github" ]; then
  PLAN_FILE="PLANS/PLAN-GIT-${ISSUE_NUMBER}.md"
else
  PLAN_FILE="PLANS/PLAN-${TICKET_KEY}.md"
fi

# Stage PLAN file
git add "$PLAN_FILE"

# Format commit message using git-semantic-commits pattern
COMMIT_MSG="docs(plan): add $(basename $PLAN_FILE) for $TICKET_ID

Plan file created for $TICKET_ID tracking implementation phases."

git commit -m "$COMMIT_MSG"

# Push to remote
git push -u origin "$BRANCH_NAME"

echo "Committed and pushed $PLAN_FILE"
```

**Semantic Commit Format**:
- Type: `docs` (PLAN files are documentation)
- Scope: `plan` (identifies plan-related commits)
- Subject: Describes the PLAN file added
- Body: Optional additional context

### Step 8: Update Ticket with Initial Progress

#### GitHub Issues

**Use `git-issue-updater` skill** to add progress comment:

```bash
gh issue comment "$ISSUE_NUMBER" --body "## Planning Complete - $(date '+%Y-%m-%d %H:%M')

**Branch**: \`GIT-$ISSUE_NUMBER\`
**PLAN File**: \`PLANS/PLAN-GIT-${ISSUE_NUMBER}.md\`
**Status**: Ready to begin execution

### Completed
- [x] GitHub issue created
- [x] Branch created and checked out
- [x] PLAN file generated with implementation phases
- [x] Initial commit pushed to remote

### Next Steps
1. Review \`PLANS/PLAN-GIT-${ISSUE_NUMBER}.md\`
2. Begin Phase 1: Setup & Analysis

---
*Tracking progress with ticket-plan-workflow-skill*"
```

#### JIRA Tickets

```bash
COMMENT="**Planning Complete**

- Branch created: \`$TICKET_KEY\`
- PLANS/PLAN-${TICKET_KEY}.md committed with implementation phases
- Ready to begin execution

**Next Steps**:
1. Review PLANS/PLAN-${TICKET_KEY}.md
2. Begin Phase 1: Setup & Analysis"

atlassian_addCommentToJiraIssue \
  --cloudId "$CLOUD_ID" \
  --issueIdOrKey "$TICKET_KEY" \
  --commentBody "$COMMENT"
```

**git-issue-updater Integration**:
For subsequent commits, use `git-issue-updater` skill to maintain consistent progress tracking with user, date, time, and file statistics.

### Step 9: Prompt for Plan Execution

Ask user if they want to proceed:

```
$TICKET_ID created: $TICKET_ID
Branch created and checked out: $BRANCH_NAME
$PLAN_FILE committed and pushed

Would you like to proceed with executing the plan?
- Yes: Start with Phase 1 tasks
- No: Stop here and execute manually later

[If Yes]: Begin executing todo items from $PLAN_FILE
[If No]: Workflow complete. Run tasks manually when ready.
```

## Best Practices

### Ticket Description
- **Be specific**: "Add JWT authentication" vs "Add auth"
- **Include context**: Why is this needed?
- **Define done**: Clear acceptance criteria
- **Limit scope**: One feature/fix per ticket

### Labels (GitHub)
- Use appropriate labels for discoverability
- `bug` vs `enhancement` distinction
- `help wanted` for community contributions
- `good first issue` for newcomers

### Branch Naming
- GitHub: Use `GIT-{number}` format for traceability
- JIRA: Use ticket key (e.g., `PROJ-123`)
- Keep it consistent with PLAN file naming

### PLAN File Structure
- Start with phases for large work
- Each phase has clear todo items
- Todos are actionable and verifiable
- Include success criteria

### Commit Messages
- Use semantic commits: `docs(plan):`, `feat:`, `fix:`
- Reference ticket ID in message
- Keep first line under 72 chars

## Common Issues

### GitHub CLI Not Authenticated
**Issue**: `gh` command fails with auth error

**Solution**:
```bash
gh auth login
gh auth status
```

### Cannot Create JIRA Ticket
**Issue**: Permission denied or project not found

**Solution**:
- Verify project key is correct
- Check user has create permissions
- Use `atlassian_getVisibleJiraProjects` to list accessible projects

### Branch Already Exists
**Issue**: Branch with same name exists

**Solution**:
```bash
# Switch to existing branch
git checkout "$BRANCH_NAME"

# Or force create new
git checkout -B "$BRANCH_NAME"
```

### Push Rejected
**Issue**: Remote has updates

**Solution**:
```bash
git pull --rebase origin main
git push -u origin "$BRANCH_NAME"
```

### Subtask/Sub-issue Creation Fails
**Issue**: Cannot link subtask to parent

**Solution (GitHub)**:
- Reference parent manually in body: "Parent: #123"
- Use GitHub's task lists for hierarchical tracking

**Solution (JIRA)**:
- Ensure parent Story exists first
- Use correct parent key format
- Verify subtask issue type is enabled in project

## Troubleshooting Checklist

**Before starting**:
- [ ] Platform selected (GitHub or JIRA)
- [ ] CLI authenticated (`gh auth status` or Atlassian MCP)
- [ ] Git repository initialized
- [ ] Remote repository configured
- [ ] Working directory clean

**After ticket creation**:
- [ ] Ticket ID/number captured
- [ ] Ticket accessible via URL
- [ ] Labels/type assigned correctly
- [ ] Sub-items created (if parent)

**After branch creation**:
- [ ] Branch name includes ticket identifier
- [ ] Branch checked out successfully

**After PLAN file**:
- [ ] File created in PLANS/ directory
- [ ] All sections populated
- [ ] Phases have actionable todos
- [ ] Acceptance criteria listed

**After commit/push**:
- [ ] PLAN file committed with semantic message
- [ ] Branch pushed to remote
- [ ] Ticket updated with progress

## Platform Comparison

| Aspect | GitHub Issues | JIRA |
|--------|---------------|------|
| Issue Type | Labels only | Task, Story, Bug, Subtask |
| Hierarchy | Manual linking | Native parent/subtask |
| Labels | Custom + defaults | Components, Labels |
| Projects | GitHub Projects | JIRA Boards |
| Branch naming | `GIT-123` | `PROJ-123` |
| PLAN file | `PLAN-GIT-123.md` | `PLAN-PROJ-123.md` |

## Example Usage

### GitHub Issues
```
User: Create a GitHub issue for adding user authentication

Agent: I'll help you create a GitHub issue. Please provide:

1. **Title**: [Brief title, max 72 chars]
2. **Overview**: [What this issue accomplishes]
3. **Acceptance Criteria**: [Definition of done]
4. **Scope**: [Files/areas affected]
5. **Technical Notes**: [Implementation details, optional]

User: 
1. Implement user authentication API
2. Add JWT-based authentication endpoints
3. Users can register, login, logout. Protected routes work.
4. src/api/auth/, src/middleware/
5. Use bcrypt, 24h token expiry

Agent: Should this be broken into smaller sub-issues?
- Parent with Sub-issues
- Single Issue

User: Single Issue

Agent: Labels detected: enhancement
Creating issue...

Created GitHub issue: #456
Created branch: GIT-456
Created PLANS/PLAN-GIT-456.md with 5 phases
Committed and pushed to remote

Proceed with plan execution? (yes/no)
```

### JIRA Tickets
```
User: Create a JIRA ticket for adding user authentication

Agent: I'll help you create a JIRA ticket. Please provide:

1. **Summary**: [Brief title, max 72 chars]
2. **Overview**: [What this ticket accomplishes]
3. **Acceptance Criteria**: [Definition of done]
4. **Scope**: [Files/areas affected]
5. **Technical Notes**: [Implementation details, optional]

User: 
1. Implement user authentication API
2. Add JWT-based authentication endpoints
3. Users can register, login, logout. Protected routes work.
4. src/api/auth/, src/middleware/
5. Use bcrypt, 24h token expiry

Agent: Is this a large piece of work that should be broken into subtasks?
- Story with Subtasks
- Single Task

User: Single Task

Agent: Which JIRA project?
- IBIS
- PROJ
- DA

User: IBIS

Agent: 
Created JIRA ticket: IBIS-456
Created branch: IBIS-456
Created PLANS/PLAN-IBIS-456.md with 5 phases
Committed and pushed to remote

Proceed with plan execution? (yes/no)
```
