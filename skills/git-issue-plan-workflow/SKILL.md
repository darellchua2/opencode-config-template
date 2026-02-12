---
name: git-issue-plan-workflow
description: Standardized GitHub issue creation workflow with structured description, branch creation, PLAN.md generation, and phased execution
license: Apache-2.0
compatibility: opencode
metadata:
  audience: developers
  workflow: github-planning
---

## What I do

I implement a standardized GitHub issue creation and planning workflow:

1. **Gather Issue Requirements**: Prompt user for structured issue description following industry best practices
2. **Determine Issue Scope**: Ask if issue needs to be broken into sub-issues
3. **Create GitHub Issue**: Use GitHub CLI to create issue with appropriate labels
4. **Create Git Branch**: Generate branch from issue number (e.g., `issue-123`)
5. **Generate PLAN.md**: Create comprehensive plan with phases and todo list
6. **Commit and Push**: Commit PLAN.md with semantic formatting and push to remote
7. **Prompt Execution**: Ask user if they want to proceed with plan execution

## When to use me

Use this workflow when:
- Starting a new development task tracked in GitHub Issues
- You want a standardized approach to issue creation and planning
- You need to break down large work into structured phases
- Following the practice of planning before implementation

## Prerequisites

- GitHub CLI (`gh`) installed and authenticated
- Git repository initialized with GitHub remote
- Write access to repository
- `gh auth status` shows valid authentication

## Steps

### Step 1: Gather Issue Description

Prompt the user for a structured issue description with these sections:

**Required Information**:
1. **Title**: Concise title (max 72 characters)
2. **Overview**: Brief description of what needs to be done
3. **Acceptance Criteria**: Definition of done (bullet points)
4. **Scope**: Files or areas affected
5. **Technical Notes**: Implementation considerations (optional)

**Prompt Template**:
```
Please provide the following for your GitHub issue:

1. **Title** (required): Brief title for the issue
   Example: "Implement user authentication API"

2. **Overview** (required): What does this issue accomplish?
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

### Step 2: Determine Issue Scope

Ask user to choose issue complexity:

**Question**: "Should this be broken into smaller sub-issues?"

**Options**:
- **Parent with Sub-issues**: Creates a parent issue, then prompts for sub-issues
- **Single Issue**: Creates one issue for contained work

**Parent Issue Flow**:
```markdown
If Parent selected:
1. Create parent issue
2. Prompt for sub-issues (repeat until done):
   - Sub-issue title
   - Sub-issue description
3. Create each sub-issue and link to parent
4. Branch name uses parent issue number (e.g., issue-123)
```

**Single Issue Flow**:
```markdown
If Single selected:
1. Create single issue with appropriate labels
2. Branch name uses issue number (e.g., issue-124)
```

### Step 3: Determine Labels

Automatically assign labels based on issue content using `git-issue-labeler`:

**Available Labels**:
- `bug` - Something isn't working
- `enhancement` - New feature or request
- `documentation` - Improvements or additions to documentation
- `good first issue` - Good for newcomers
- `help wanted` - Extra attention is needed
- `question` - Further information is requested
- `invalid` - This doesn't seem right
- `wontfix` - This will not be worked on
- `duplicate` - This issue or pull request already exists

**Detection Logic**:
```
Keywords → Labels:
- "fix", "bug", "error", "crash", "broken" → bug
- "add", "new", "feature", "implement", "enhance" → enhancement
- "document", "readme", "doc", "comment" → documentation
- "how to", "question", "clarify" → question
```

### Step 4: Create GitHub Issue(s)

**For Single Issue**:
```bash
ISSUE_URL=$(gh issue create \
  --title "$TITLE" \
  --body "$FORMATTED_BODY" \
  --label "$LABELS" \
  --assignee @me)

# Extract issue number
ISSUE_NUMBER=$(echo "$ISSUE_URL" | grep -oE '[0-9]+$')
```

**For Parent with Sub-issues**:
```bash
# Create parent issue first
PARENT_URL=$(gh issue create \
  --title "$TITLE" \
  --body "$FORMATTED_BODY" \
  --label "$LABELS" \
  --assignee @me)

PARENT_NUMBER=$(echo "$PARENT_URL" | grep -oE '[0-9]+$')

# Create each sub-issue
for subissue in "${SUBISSUES[@]}"; do
  gh issue create \
    --title "$subissue.title" \
    --body "$subissue.body\n\nParent: #$PARENT_NUMBER" \
    --label "$subissue.labels" \
    --assignee @me
done
```

**Formatted Body Template**:
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
*Created with git-issue-plan-workflow*
```

### Step 5: Create Git Branch

**Branch Naming Convention**:
- Use issue number: `issue-123` or `123`
- For features, can prefix: `feature/issue-123`
- All lowercase, no spaces

```bash
# Check for uncommitted changes
if ! git diff-index --quiet HEAD --; then
  echo "Warning: You have uncommitted changes"
  read -p "Continue anyway? (y/n): " CONTINUE
  [ "$CONTINUE" != "y" ] && exit 1
fi

# Create and checkout branch
git checkout -b "issue-$ISSUE_NUMBER"

echo "✓ Created branch: issue-$ISSUE_NUMBER"
```

### Step 6: Generate PLAN.md

Create comprehensive PLAN.md with phases and todos:

**Template**:
```markdown
# Plan: $ISSUE_TITLE

## Issue Reference
- **Number**: #$ISSUE_NUMBER
- **URL**: $GITHUB_URL/issues/$ISSUE_NUMBER
- **Labels**: $LABELS

## Overview
$OVERVIEW

## Acceptance Criteria
- [ ] $CRITERION_1
- [ ] $CRITERION_2
- [ ] $CRITERION_3

## Scope
$SCOPE

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
_List any external dependencies or blocked-by issues_

## Risks & Mitigation
_Identify potential risks and how to mitigate them_

## Success Metrics
_How will we measure success?_
```

### Step 7: Commit and Push PLAN.md

```bash
# Stage PLAN.md
git add PLAN.md

# Commit with semantic message
git commit -m "docs(plan): add PLAN.md for issue #$ISSUE_NUMBER"

# Push to remote
git push -u origin "issue-$ISSUE_NUMBER"

echo "✓ Committed and pushed PLAN.md"
```

### Step 8: Update Issue with Initial Progress

Add comment to GitHub issue:

```bash
gh issue comment "$ISSUE_NUMBER" --body "## Planning Complete

- ✅ Branch created: \`issue-$ISSUE_NUMBER\`
- ✅ PLAN.md committed with implementation phases
- ✅ Ready to begin execution

**Next Steps**:
1. Review PLAN.md
2. Begin Phase 1: Setup & Analysis

---
*Tracking progress with git-issue-plan-workflow*"
```

### Step 9: Prompt for Plan Execution

Ask user if they want to proceed:

```
✓ GitHub issue created: #$ISSUE_NUMBER
✓ Branch created and checked out: issue-$ISSUE_NUMBER
✓ PLAN.md committed and pushed

Would you like to proceed with executing the plan?
- Yes: Start with Phase 1 tasks
- No: Stop here and execute manually later

[If Yes]: Begin executing todo items from PLAN.md
[If No]: Workflow complete. Run tasks manually when ready.
```

## Best Practices

### Issue Description
- **Be specific**: "Add JWT authentication" vs "Add auth"
- **Include context**: Why is this needed?
- **Define done**: Clear acceptance criteria
- **Limit scope**: One feature/fix per issue

### Labels
- Use appropriate labels for discoverability
- `bug` vs `enhancement` distinction
- `help wanted` for community contributions
- `good first issue` for newcomers

### Branch Naming
- Use issue number for traceability
- Keep it short and descriptive
- Use lowercase with hyphens

### PLAN.md Structure
- Start with phases for large work
- Each phase has clear todo items
- Todos are actionable and verifiable
- Include success criteria

### Commit Messages
- Use semantic commits: `docs(plan):`, `feat:`, `fix:`
- Reference issue number in message
- Keep first line under 72 chars

## Common Issues

### GitHub CLI Not Authenticated
**Issue**: `gh` command fails with auth error

**Solution**:
```bash
gh auth login
gh auth status
```

### Cannot Create Issue
**Issue**: Permission denied or repo not found

**Solution**:
- Verify repository URL: `git remote -v`
- Check user has write access
- Ensure repository exists on GitHub

### Branch Already Exists
**Issue**: Branch with same name exists

**Solution**:
```bash
# Switch to existing branch
git checkout "issue-$ISSUE_NUMBER"

# Or force create new
git checkout -B "issue-$ISSUE_NUMBER"
```

### Push Rejected
**Issue**: Remote has updates

**Solution**:
```bash
git pull --rebase origin main
git push -u origin "issue-$ISSUE_NUMBER"
```

### Sub-issue Linking
**Issue**: Cannot create linked sub-issues

**Solution**:
- Reference parent manually in body: "Parent: #123"
- Use GitHub's task lists for hierarchical tracking
- Consider using Projects for complex hierarchies

## Troubleshooting Checklist

**Before starting**:
- [ ] GitHub CLI authenticated: `gh auth status`
- [ ] Git repository initialized
- [ ] Remote repository configured
- [ ] Working directory clean

**After issue creation**:
- [ ] Issue number captured
- [ ] Issue accessible via URL
- [ ] Labels assigned correctly
- [ ] Sub-issues created (if parent)

**After branch creation**:
- [ ] Branch name includes issue number
- [ ] Branch checked out successfully

**After PLAN.md**:
- [ ] All sections populated
- [ ] Phases have actionable todos
- [ ] Acceptance criteria listed

**After commit/push**:
- [ ] PLAN.md committed with semantic message
- [ ] Branch pushed to remote
- [ ] GitHub issue updated with progress

## Related Skills

**Frameworks used**:
- `git-issue-labeler` - Automatic label assignment
- `git-semantic-commits` - Semantic commit formatting
- `git-issue-updater` - Issue progress updates

**Companion workflows**:
- `jira-ticket-plan-workflow` - JIRA ticket equivalent
- `pr-creation-workflow` - Create PR after work complete
- `git-pr-creator` - PR creation with issue linking

## Example Usage

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

✓ Created GitHub issue: #456
✓ Created branch: issue-456
✓ Created PLAN.md with 5 phases
✓ Committed and pushed to remote

Proceed with plan execution? (yes/no)
```

## GitHub vs JIRA Comparison

| Aspect | GitHub Issues | JIRA |
|--------|---------------|------|
| Issue Type | Labels only | Task, Story, Bug, Subtask |
| Hierarchy | Manual linking | Native parent/subtask |
| Labels | Custom + defaults | Components, Labels |
| Projects | GitHub Projects | JIRA Boards |
| Branch naming | `issue-123` | `PROJ-123` |
