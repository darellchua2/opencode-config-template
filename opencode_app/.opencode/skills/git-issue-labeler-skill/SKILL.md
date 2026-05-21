---
name: git-issue-labeler-skill
description: Assess GitHub issues and assign labels using GitHub defaults, priority labels, and semantic versioning labels (major, minor, patch) with auto-create for missing labels
license: Apache-2.0
compatibility: opencode
metadata:
  audience: developers, maintainers
  workflow: issue-management
---

## What I do

I provide intelligent GitHub issue label assessment by:

- Analyzing issue content to determine appropriate labels
- Using keyword and pattern matching to identify issue types and priorities
- Assigning single or multiple labels based on issue complexity
- **Auto-creating missing labels** before assignment (never fails on missing labels)
- Providing label descriptions for clarity and consistency

## When to use me

Use this when:
- You need to assess and label GitHub issues automatically
- You want consistent label assignment across your repository
- You need to categorize issues using GitHub's default label scheme
- You're setting up a new repository and need label guidelines
- You want to review unlabeled or mislabeled issues
- You need to assign semantic versioning labels to pull requests

## Prerequisites

- GitHub CLI (`gh`) installed and authenticated
- Git repository with GitHub remote
- Write access to the GitHub repository
- Valid `GITHUB_TOKEN` or `gh` authentication setup

## Governance

The semantic versioning label definitions below follow `semantic-release-convention`, which is the single source of truth for version bump conventions across all skills and agents.

For JIRA ticket type and priority mapping, see `jira-ticket-labeler-skill` — a separate skill for JIRA-specific taxonomy.

## Label Taxonomy

### Issue Labels vs PR Labels

| Context | Label Set | Purpose |
|---------|-----------|---------|
| GitHub Issues | Type labels + Priority labels | Categorize and triage issues |
| GitHub PRs | Semver labels (major, minor, patch) | Determine version bump for release |

Issues get type + priority labels. PRs get exactly one semver label. These are distinct concerns.

### Label Categories

#### 1. Type Labels (GitHub Issues)

| Label | Color | Hex | Description |
|-------|-------|-----|-------------|
| `bug` | Red | #d73a4a | Something isn't working as expected |
| `enhancement` | Light blue | #a2eeef | New feature or improvement |
| `documentation` | Blue | #0075ca | Documentation improvements |
| `duplicate` | Gray | #cfd3d7 | Already exists |
| `good first issue` | Green | #7057ff | Good for newcomers |
| `help wanted` | Purple | #008672 | Extra attention needed |
| `invalid` | Yellow | #e4e669 | Not a valid issue |
| `question` | Purple | #d876e3 | Clarification needed |
| `wontfix` | White | #ffffff | Will not be worked on |

#### 2. Priority Labels (GitHub Issues)

| Label | Color | Hex | Description |
|-------|-------|-----|-------------|
| `priority: critical` | Red | #b60205 | System down, data loss, security vulnerability |
| `priority: high` | Orange | #d93f0b | Major feature broken, significant user impact |
| `priority: medium` | Yellow | #fbca04 | Functional issue with workaround |
| `priority: low` | Green | #0e8a16 | Minor inconvenience, cosmetic issue |

#### 3. Semver Labels (GitHub PRs)

| Label | Color | Hex | Version Bump | When to Apply |
|-------|-------|-----|-------------|---------------|
| `major` | Red | #d73a4a | X.0.0 | Breaking changes |
| `minor` | Yellow | #fbca04 | 0.X.0 | New features |
| `patch` | Green | #0e8a16 | 0.0.X | Bug fixes, docs, refactoring |

## Steps

### Step 1: Auto-Create Missing Labels

Before any label assignment, ensure all required labels exist:

```bash
declare -A LABELS=(
  ["bug"]="d73a4a,Something isn't working"
  ["enhancement"]="a2eeef,New feature or request"
  ["documentation"]="0075ca,Improvements or additions to documentation"
  ["duplicate"]="cfd3d7,This issue or pull request already exists"
  ["good first issue"]="7057ff,Good for newcomers"
  ["help wanted"]="008672,Extra attention is needed"
  ["invalid"]="e4e669,This doesn't seem right"
  ["question"]="d876e3,Further information is requested"
  ["wontfix"]="ffffff,This will not be worked on"
  ["priority: critical"]="b60205,System down, data loss, security vulnerability"
  ["priority: high"]="d93f0b,Major feature broken, significant user impact"
  ["priority: medium"]="fbca04,Functional issue with workaround"
  ["priority: low"]="0e8a16,Minor inconvenience, cosmetic issue"
  ["major"]="d73a4a,Breaking change (X.0.0)"
  ["minor"]="fbca04,New feature (0.X.0)"
  ["patch"]="0e8a16,Bug fix (0.0.X)"
)

existing_labels=$(gh label list --json name --jq '.[].name')

for label in "${!LABELS[@]}"; do
  if ! echo "$existing_labels" | grep -qx "$label"; then
    IFS=',' read -r color desc <<< "${LABELS[$label]}"
    gh label create "$label" --color "$color" --description "$desc" 2>/dev/null || true
  fi
done
```

### Step 2: Analyze Issue Content

```bash
gh issue view <issue-number> --json title,body,labels

issue_title=$(gh issue view <issue-number> --jq '.title')
issue_body=$(gh issue view <issue-number> --jq '.body')
issue_content="${title} ${body}"
```

### Step 3: Determine Appropriate Labels

#### Type Detection

**Bug**:
```bash
if [[ "$issue_content" =~ (fix|error|broken|crash|fail|doesn't work|incorrect|wrong|problem|bug|defect) ]]; then
  labels+=("bug")
fi
```

**Enhancement**:
```bash
if [[ "$issue_content" =~ (add|implement|create|new|feature|support|introduce|build|develop|request|suggestion) ]]; then
  labels+=("enhancement")
fi
```

**Documentation**:
```bash
if [[ "$issue_content" =~ (document|readme|docs|guide|explain|tutorial|wiki|comment|manual|help) ]]; then
  labels+=("documentation")
fi
```

**Duplicate**:
```bash
if [[ "$issue_content" =~ (duplicate|same as|already exists|similar|repeated|already reported) ]]; then
  labels+=("duplicate")
fi
```

**Good First Issue**:
```bash
if [[ "$issue_content" =~ (beginner|simple|easy|small|straightforward|first time|newcomer|junior) ]]; then
  labels+=("good first issue")
fi
```

**Help Wanted**:
```bash
if [[ "$issue_content" =~ (help wanted|need help|assistance|looking for help|collaboration|community) ]]; then
  labels+=("help wanted")
fi
```

**Invalid**:
```bash
if [[ "$issue_content" =~ (invalid|not an issue|wrong repo|user error|configuration|misunderstanding) ]]; then
  labels+=("invalid")
fi
```

**Question**:
```bash
if [[ "$issue_content" =~ (question|how|what|why|clarification|explain|understand|ask|wondering) ]]; then
  labels+=("question")
fi
```

**Wontfix**:
```bash
if [[ "$issue_content" =~ (wontfix|out of scope|not feasible|declined|rejected|wont do|never) ]]; then
  labels+=("wontfix")
fi
```

#### Priority Detection

**Critical**:
```bash
if [[ "$issue_content" =~ (critical|urgent|system down|data loss|security|vulnerability|outage|production down) ]]; then
  labels+=("priority: critical")
fi
```

**High**:
```bash
if [[ "$issue_content" =~ (high priority|important|blocking|broken|unusable|regression) ]]; then
  labels+=("priority: high")
fi
```

**Medium** (default if no other priority detected):
```bash
if [[ "$issue_content" =~ (medium|moderate|workaround|intermittent) ]]; then
  labels+=("priority: medium")
fi
```

**Low**:
```bash
if [[ "$issue_content" =~ (low priority|minor|cosmetic|nice to have|nit|typo|whenever) ]]; then
  labels+=("priority: low")
fi
```

#### Semver Label Detection (PRs only)

Applied to pull requests, not issues. See `semantic-release-convention` for the governance spec.

```bash
if [[ "$pr_title" =~ ^[^:]+\! ]]; then
  labels+=("major")
elif [[ "$pr_title" =~ ^feat ]]; then
  labels+=("minor")
else
  labels+=("patch")
fi
```

### Step 4: Assign Labels

```bash
for label in "${labels[@]}"; do
  gh issue edit <issue-number> --add-label "$label"
done
```

### Step 5: Generate Assessment Report

```markdown
# Issue Label Assessment

**Issue**: #<issue-number> - <issue-title>
**Assigned Labels**:
- `<label1>`: <label description>
- `<label2>`: <label description>

**Detection Keywords**:
- `<keyword1>` → `<label1>`
- `<keyword2>` → `<label2>`

**Confidence**: High/Medium/Low

**Recommendations**:
- Additional labels to consider
- Labels to review
- Notes on ambiguous cases
```

## Best Practices

### Label Assignment

- **Start with type label**: Assign bug or enhancement first
- **Add exactly one priority**: Every issue should have a priority
- **Maximum 3 labels**: Type + Priority + one auxiliary (good first issue, help wanted, etc.)
- **Be consistent**: Use same labels for similar issues
- **Review existing labels**: Check issue history before assigning new labels

### Content Analysis

- **Analyze both title and body**: Keywords can appear in either
- **Consider context**: Same keyword may indicate different label based on context
- **Look for explicit requests**: "Please add" vs "How to add"
- **Check for negations**: "not a bug" should not be labeled as bug
- **Review issue comments**: Comments may provide additional context

## Common Issues

### Label Doesn't Exist

**Solution**: Auto-create is built into Step 1. Labels are created before assignment. If `gh label create` fails (e.g., label already exists), the error is silently ignored via `|| true`.

### Conflicting Labels

**Issue**: Issue is assigned both "bug" and "enhancement"

**Solution**:
- Review the issue content carefully
- Determine primary intent: fix vs new feature
- Remove the conflicting label
- Add a comment explaining the decision

### Low Confidence Assignment

**Solution**:
- Leave unlabeled or use generic label like "enhancement"
- Add comment requesting clarification from issue author
- Manual review by maintainer

## Verification Commands

```bash
# 1. Verify issue has labels
gh issue view <issue-number> --jq '.labels[].name'

# 2. Check label count
label_count=$(gh issue view <issue-number> --jq '.labels | length')
echo "Issue has $label_count label(s)"

# 3. Validate labels exist in repository
for label in $(gh issue view <issue-number> --jq '.labels[].name'); do
  if gh label list --search "$label" --jq 'any(.name == "'"$label"'")' | grep -q "true"; then
    echo "OK Label '$label' exists"
  else
    echo "MISSING Label '$label' does not exist"
  fi
done
```

## Automation Example

```bash
#!/bin/bash

# Step 1: Ensure all labels exist
declare -A LABELS=(
  ["bug"]="d73a4a,Something isn't working"
  ["enhancement"]="a2eeef,New feature or request"
  ["documentation"]="0075ca,Improvements or additions to documentation"
  ["duplicate"]="cfd3d7,This issue or pull request already exists"
  ["good first issue"]="7057ff,Good for newcomers"
  ["help wanted"]="008672,Extra attention is needed"
  ["invalid"]="e4e669,This doesn't seem right"
  ["question"]="d876e3,Further information is requested"
  ["wontfix"]="ffffff,This will not be worked on"
  ["priority: critical"]="b60205,System down, data loss, security vulnerability"
  ["priority: high"]="d93f0b,Major feature broken, significant user impact"
  ["priority: medium"]="fbca04,Functional issue with workaround"
  ["priority: low"]="0e8a16,Minor inconvenience, cosmetic issue"
)

existing_labels=$(gh label list --json name --jq '.[].name')
for label in "${!LABELS[@]}"; do
  if ! echo "$existing_labels" | grep -qx "$label"; then
    IFS=',' read -r color desc <<< "${LABELS[$label]}"
    gh label create "$label" --color "$color" --description "$desc" 2>/dev/null || true
  fi
done

# Step 2: Assess all open issues without labels
for issue_number in $(gh issue list --state open --limit 50 --jq '.[].number'); do
  labels=$(gh issue view "$issue_number" --jq '.labels | length')

  if [ "$labels" -eq 0 ]; then
    echo "Assessing issue #$issue_number..."

    title=$(gh issue view "$issue_number" --jq '.title')
    body=$(gh issue view "$issue_number" --jq '.body')
    content="${title} ${body}"

    assign_labels=()

    if [[ "$content" =~ (bug|fix|error|broken|crash) ]]; then
      assign_labels+=("bug")
    fi

    if [[ "$content" =~ (enhancement|add|implement|feature) ]]; then
      assign_labels+=("enhancement")
    fi

    if [[ "$content" =~ (documentation|docs|readme) ]]; then
      assign_labels+=("documentation")
    fi

    priority_detected=false
    if [[ "$content" =~ (critical|urgent|system down|security) ]]; then
      assign_labels+=("priority: critical")
      priority_detected=true
    elif [[ "$content" =~ (high priority|important|blocking) ]]; then
      assign_labels+=("priority: high")
      priority_detected=true
    elif [[ "$content" =~ (low priority|minor|cosmetic|typo) ]]; then
      assign_labels+=("priority: low")
      priority_detected=true
    fi

    if [ "$priority_detected" = false ]; then
      assign_labels+=("priority: medium")
    fi

    if [ ${#assign_labels[@]} -gt 0 ]; then
      label_string=$(IFS=,; echo "${assign_labels[*]}")
      gh issue edit "$issue_number" --add-label "$label_string"
      echo "OK Assigned: $label_string"
    else
      echo "? Could not determine label for #$issue_number"
    fi
  fi
done
```
