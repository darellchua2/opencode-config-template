---
name: git-semantic-commits
description: Format Git commit messages following Conventional Commits specification with semantic versioning support
license: Apache-2.0
compatibility: opencode
metadata:
  audience: developers, maintainers
  workflow: commit-formatting
---

## What I do

I provide Git commit message formatting following Conventional Commits specification:

- **Format Commit Messages**: Enforce format: `<type>(<scope>): <subject>`
- **Detect Commit Type**: Identify type from content: feat, fix, docs, style, refactor, test, chore, perf, ci, build, revert
- **Support Scopes**: Add optional scope: `feat(api):`, `fix(ui):`
- **Detect Breaking Changes**: Identify via `!` after type/scope or `BREAKING CHANGE:` in footer
- **Provide Versioning Guidance**: Explain SemVer implications (MAJOR.MINOR.PATCH) based on commit type
- **Validate Messages**: Check commit messages follow Conventional Commits specification
- **Generate Templates**: Provide commit message templates for each type

## When to use me

Use when:
- Formatting Git commit messages following semantic conventions
- Creating workflows that generate commits
- Detecting commit type for versioning or changelog generation
- Ensuring consistent commit message formatting across team
- Creating PRs with proper title formatting
- Integrating with automated versioning tools

## Steps

### Step 1: Format Commit Messages

Enforce Conventional Commits format:

```
<type>(<scope>): <subject>

<body>

<footer>
```

**Format Rules**:
- **type**: One of allowed types (see below)
- **scope**: Optional, identifies affected component/package
- **subject**: Short description, imperative mood, no period at end
- **body**: Detailed description, can be multiple lines
- **footer**: Metadata (BREAKING CHANGE, Closes, etc.)

### Step 2: Detect Commit Type

Identify commit type from message content for versioning:

```bash
# Extract type and scope
if [[ $COMMIT_MSG =~ ^([a-z]+)(\(([a-z]+)\))?: ]]; then
    TYPE="${BASH_REMATCH[1]}"
    SCOPE="${BASH_REMATCH[2]}"
else
    TYPE="unknown"
    SCOPE=""
fi
```

### Step 3: Commit Types and Their Meanings

| Type | Description | Versioning |
|-------|-------------|-----------|
| feat | A new feature | MINOR |
| fix | A bug fix | PATCH |
| docs | Documentation only | None |
| style | Code style (formatting) | None |
| refactor | Code change (not fix/feature) | None |
| test | Adding tests or fixing existing tests | None |
| chore | Build process/auxiliary tools | None |
| perf | Performance improvement | PATCH/MINOR |
| ci | CI configuration | None |
| build | Build system changes | PATCH |
| revert | Reverts a previous commit | Varies |

### Step 4: Breaking Changes

**Breaking change indicators**:
- `!` after type/scope: `feat(api)!:`
- `BREAKING CHANGE:` in footer

**Versioning impact**: Breaking changes trigger MAJOR version increment

### Step 5: Validate Commit Messages

```bash
#!/bin/bash
COMMIT_MSG_FILE=$1
COMMIT_MSG=$(cat "$COMMIT_MSG_FILE")

# Valid types
TYPES="feat|fix|docs|style|refactor|test|chore|perf|ci|build|revert"

# Check format
if [[ ! $COMMIT_MSG =~ ^($TYPES)(\(.+\))?:\ .+ ]]; then
    echo "❌ Commit message doesn't follow Conventional Commits format"
    exit 1
fi

# Extract subject
SUBJECT=$(echo "$COMMIT_MSG" | sed 's/.*: //')

# Check subject length
if [ ${#SUBJECT} -gt 72 ]; then
    echo "❌ Subject is too long (max 72 characters)"
    exit 1
fi

# Check for breaking change
if [[ $COMMIT_MSG =~ :\! ]] || grep -q "BREAKING CHANGE:" "$COMMIT_MSG_FILE"; then
    echo "✓ Breaking change detected"
fi

echo "✅ Commit message is valid"
```

## Best Practices

### Subject Guidelines
- Use imperative mood: "add" not "added" or "adds"
- Keep it short: Under 72 characters
- No period at the end
- Be specific: "fix login bug" not "fix bug"
- Use lowercase for type and scope

### Body Guidelines
- Explain what and why, not how
- Use bullet points for multiple items
- Wrap lines at 72 characters
- Reference issues: "Closes #123"

### Footer Guidelines
- **BREAKING CHANGE**: Describe what changed and migration path
- **Closes #123**: Reference closed issues
- **Reviewed-by @user**: Acknowledge reviewers
- **Authored-by @user**: For cherry-picks

### Consistency
- Use consistent scope names across project
- Keep commit messages atomic (one change per commit)
- Write self-explanatory commit messages

## Common Issues

### Type Not in Allowed List

**Issue**: Commit type is not recognized

**Solution**: Use one of the allowed types: feat, fix, docs, style, refactor, test, chore, perf, ci, build, revert

### Subject Too Long

**Issue**: Subject exceeds 72 characters

**Solution**: Shorten subject or move details to body

### Breaking Change Not Clearly Indicated

**Issue**: Breaking change not properly marked

**Solution**: Use `!` after type/scope or add `BREAKING CHANGE:` footer

## Examples

### Feature
```
feat(auth): add OAuth2 support

Implement OAuth2 authentication flow with support for Google and GitHub.
Add token refresh mechanism.

Closes #456
```

### Bug Fix
```
fix(api): resolve login timeout issue

Increase timeout duration from 30s to 60s to handle slow networks.
Add retry logic for failed authentication attempts.
```

### Breaking Change
```
feat(api)!: change authentication endpoint structure

BREAKING CHANGE: The authentication API has been updated.
Old: /api/auth/login
New: /api/v2/auth/login
Update your clients accordingly.
```

## Scope Usage

### Common Scopes
- `api` - API changes
- `ui` - User interface changes
- `components` - Component library changes
- `auth` - Authentication/authorization
- `db` - Database changes
- `config` - Configuration changes
- `deps` - Dependency changes
- `docs` - Documentation changes
- `tests` - Test changes
- `build` - Build system changes

### Guidelines
- Use lowercase for scope names
- Keep scope names short and consistent
- Don't use scope if change affects multiple areas
- Establish project-specific scope conventions

## Integration

Skills that should use `git-semantic-commits`:
- `git-issue-creator`: Format commit messages
- `git-pr-creator`: Format PR titles using semantic format
- `pr-creation-workflow`: Format PR titles and descriptions
- `jira-git-workflow`: Format commit messages for JIRA tickets
- `nextjs-pr-workflow`: Format commit messages for Next.js projects

## Automation Tools

### Commitizen

CLI tool for enforcing Conventional Commits:

```bash
# Install commitizen
npm install -g commitizen

# Use git cz instead of git commit
git add .
git cz
```

### Commitlint

Lint commit messages to enforce format:

```bash
# Install commitlint
npm install -g @commitlint/cli @commitlint/config-conventional

# Configure commitlint
echo "module.exports = {extends: ['@commitlint/config-conventional']}" > commitlint.config.js

# Lint commit messages
echo "feat: add new feature" | commitlint
```

## References

- **Conventional Commits Specification**: https://www.conventionalcommits.org/
- **Semantic Versioning**: https://semver.org/
- **Commitizen**: https://commitizen-tools.github.io/commitizen/
- **Commitlint**: https://commitlint.js.org/
