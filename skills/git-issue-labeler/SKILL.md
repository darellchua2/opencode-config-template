---
name: git-issue-labeler
description: Assess GitHub issues and assign appropriate labels using GitHub default labels (bug, enhancement, documentation, duplicate, good first issue, help wanted, invalid, question, wontfix) with detailed descriptions
license: Apache-2.0
compatibility: opencode
metadata:
  audience: developers, maintainers
  workflow: issue-management
---

## What I do

- Analyze issue content to determine appropriate GitHub default labels
- Use keyword and pattern matching to identify issue types
- Assign single or multiple labels based on issue complexity
- Provide label descriptions for clarity and consistency
- Support 9 GitHub default labels: bug, enhancement, documentation, duplicate, good first issue, help wanted, invalid, question, wontfix
- Use GitHub CLI (`gh`) to query available repository labels
- Generate label assignment reports for review

## When to use me

Use when:
- You need to assess and label GitHub issues automatically
- You want consistent label assignment across your repository
- You need to categorize issues using GitHub's default label scheme
- You're setting up a new repository and need label guidelines
- You need to review unlabeled or mislabeled issues
- You want to train contributors on when to use specific labels

## Prerequisites

- GitHub CLI (`gh`) installed and authenticated
- Git repository with GitHub remote
- Write access to GitHub repository
- Repository uses GitHub's default labels or custom labels
- Valid `GITHUB_TOKEN` or `gh` authentication setup

## GitHub Default Labels Reference

### bug
**Description**: Something isn't working as expected or is broken

**Keywords**: fix, error, broken, crash, fail, doesn't work, incorrect, wrong, problem, issue, bug, defect

**Examples**:
- "Login fails when user enters invalid credentials"
- "App crashes when uploading large files"
- "Button click doesn't trigger expected action"

### enhancement
**Description**: New feature or request to improve existing functionality

**Keywords**: add, implement, create, new, feature, support, introduce, build, develop, request, suggestion

**Examples**:
- "Add dark mode support to dashboard"
- "Implement export to PDF functionality"
- "Add pagination to user list"

### documentation
**Description**: Improvements or additions to documentation

**Keywords**: document, readme, docs, guide, explain, tutorial, wiki, comment, manual, help

**Examples**:
- "Document API endpoints for authentication"
- "Update README with installation instructions"
- "Add code comments to complex functions"

### duplicate
**Description**: This issue or pull request already exists

**Keywords**: duplicate, same as, already exists, similar, repeated, already reported

**Examples**:
- "This is the same as issue #123"
- "Already reported in #456"
- "Similar to #789"

### good first issue
**Description**: Good for newcomers or first-time contributors

**Keywords**: beginner, simple, easy, small, straightforward, first time, newcomer, junior

**Examples**:
- "Fix typo in header component"
- "Add unit test for utility function"
- "Update example in README"

### help wanted
**Description**: Extra attention or help is needed

**Keywords**: help wanted, need help, assistance, looking for help, collaboration, community, mentorship

**Examples**:
- "Need help with performance optimization"
- "Looking for someone to review documentation"
- "Assistance needed for complex refactoring"

### invalid
**Description**: This doesn't seem right or isn't a valid issue

**Keywords**: invalid, not an issue, wrong repo, user error, configuration, misunderstanding

**Examples**:
- "This is a user configuration issue"
- "Wrong repository for this feature request"
- "Not a bug - working as designed"

### question
**Description**: Further information is requested or clarification needed

**Keywords**: question, how, what, why, clarification, explain, understand, ask, wondering

**Examples**:
- "How do I configure authentication?"
- "What is the purpose of this function?"
- "Question about API usage"

### wontfix
**Description**: This will not be worked on due to technical limitations, out of scope, or other reasons

**Keywords**: wontfix, out of scope, not feasible, declined, rejected, never, wont do

**Examples**:
- "Feature is out of scope for this project"
- "Technical limitations prevent implementation"
- "Not aligned with project goals"

## Steps

### Step 1: Query Available Labels

```bash
# Get all available labels in repository
gh label list --json name,description,color

# Get default labels specifically
gh label list --search "bug|enhancement|documentation|duplicate|good first issue|help wanted|invalid|question|wontfix"
```

### Step 2: Analyze Issue Content

```bash
# Read issue content
gh issue view <issue-number> --json title,body,labels
```

**Key elements to analyze**:
- Issue title and keywords
- Issue body content
- Existing labels
- Issue comments (optional)

### Step 3: Determine Appropriate Labels

**Pattern matching strategy**:
- Check issue title for keywords matching each label
- Check issue body for additional context
- Consider existing labels before adding new ones
- Assign multiple labels if issue fits multiple categories

**Priority order**:
1. bug (if it's a broken feature)
2. duplicate (if it already exists)
3. invalid (if it's not a valid issue)
4. enhancement, documentation (based on keywords)
5. question (if it's asking for help)
6. wontfix (if it's been declined)
7. good first issue, help wanted (based on difficulty/complexity)

### Step 4: Assign Labels to Issue

```bash
# Add label to issue
gh issue edit <issue-number> --add-label <label-name>

# Add multiple labels
gh issue edit <issue-number> --add-label "bug,enhancement"

# Remove labels (if mislabeled)
gh issue edit <issue-number> --remove-label <label-name>
```

### Step 5: Generate Report

```bash
echo "Label assignment complete!"
echo "Issue: <issue-number>"
echo "Labels added: <label1>, <label2>"
```

## Best Practices

- Use GitHub's default labels for consistency
- Check existing labels before adding new ones
- Assign bug label if issue describes broken functionality
- Assign enhancement label for new feature requests
- Use question label for clarification requests
- Use wontfix when declining requests
- Provide clear descriptions for custom labels
- Review label assignments periodically for consistency
- Consider using good first issue for simple tasks
- Use help wanted when community input is needed

## Common Issues

### Label Doesn't Exist
**Solution**: Query available labels with `gh label list`, create custom label if needed.

### Multiple Labels Conflict
**Solution**: Ensure labels aren't contradictory (e.g., bug + wontfix).

### Keyword Ambiguity
**Solution**: Review issue title and body for full context, ask clarifying questions if needed.

### Repository Permission Issues
**Solution**: Verify GitHub CLI authentication, check repository write permissions.

## References

- GitHub Labels Documentation: https://docs.github.com/articles/creating-a-label
- GitHub CLI Documentation: https://cli.github.com/manual/
- Issue Triage Best Practices: https://docs.github.com/articles/triaging-issues-and-pull-requests
