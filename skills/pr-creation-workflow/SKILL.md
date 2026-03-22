---
name: pr-creation-workflow
description: Framework for creating PRs with automatic framework/language detection, configurable quality checks, multi-platform integration, semantic versioning labels (major/minor/patch), and JIRA/git issue tracking
license: Apache-2.0
compatibility: opencode
metadata:
  audience: developers
  workflow: pr-creation
  languages: [language-agnostic]
---

## What I do

I provide a generic PR creation workflow:
- **Detect framework/language** automatically from project files
- Identify target branch (configurable, not hardcoded)
- Run quality checks (linting, build, test, type check) appropriate for detected framework
- Detect tracking (JIRA tickets or git issues)
- Create PR with comprehensive description linked to tracking
- Handle images (upload local, embed URLs)
- Merge confirmation with JIRA status update

## When to use me

Use when:
- Creating PR after completing work
- Need configurable quality checks (not just linting)
- Need PRs linked to JIRA or git issues
- Support multiple merge targets (not just `dev`)
- Need image attachments in PRs
- Building workflow skill with PR creation

This is a **framework skill** - provides PR creation logic that other skills extend.

## Steps

### Step 1: Identify Target Branch

**Methods**:
- Ask user: `read -p "Enter target branch (main/develop/staging): " TARGET_BRANCH`
- Detect default: `git symbolic-ref refs/remotes/origin/HEAD`
- Read config: Check `.git/config`

**Common targets**: main, develop, staging, production, master

**Important**: Don't hardcode to `dev` - different projects use different conventions!

### Step 2: Detect Framework and Run Quality Checks

#### 2.1: Detect Framework/Language

**Detection Logic**:

```bash
# JavaScript/TypeScript detection
if [ -f "package.json" ]; then
  if grep -q '"next"' package.json 2>/dev/null; then
    FRAMEWORK="nextjs"
  elif grep -q '"@nestjs/core"' package.json 2>/dev/null; then
    FRAMEWORK="nestjs"
  elif grep -q '"vue"' package.json 2>/dev/null; then
    FRAMEWORK="vue"
  elif grep -q '"@angular/core"' package.json 2>/dev/null; then
    FRAMEWORK="angular"
  elif grep -q '"react"' package.json 2>/dev/null; then
    FRAMEWORK="react"
  elif grep -q '"express"' package.json 2>/dev/null; then
    FRAMEWORK="express"
  else
    FRAMEWORK="node"
  fi
# Python detection
elif [ -f "pyproject.toml" ] || [ -f "setup.py" ] || [ -f "requirements.txt" ]; then
  if grep -q "django" pyproject.toml 2>/dev/null || grep -q "django" requirements.txt 2>/dev/null; then
    FRAMEWORK="django"
  elif grep -q "fastapi" pyproject.toml 2>/dev/null || grep -q "fastapi" requirements.txt 2>/dev/null; then
    FRAMEWORK="fastapi"
  elif grep -q "flask" pyproject.toml 2>/dev/null || grep -q "flask" requirements.txt 2>/dev/null; then
    FRAMEWORK="flask"
  else
    FRAMEWORK="python"
  fi
# Java detection
elif [ -f "pom.xml" ]; then
  if grep -q "spring-boot" pom.xml 2>/dev/null; then
    FRAMEWORK="spring-boot"
  else
    FRAMEWORK="java-maven"
  fi
elif [ -f "build.gradle" ] || [ -f "build.gradle.kts" ]; then
  if grep -q "spring-boot" build.gradle* 2>/dev/null; then
    FRAMEWORK="spring-boot-gradle"
  else
    FRAMEWORK="java-gradle"
  fi
# .NET detection
elif ls *.csproj 1>/dev/null 2>&1 || ls *.sln 1>/dev/null 2>&1; then
  FRAMEWORK="dotnet"
# Go detection
elif [ -f "go.mod" ]; then
  FRAMEWORK="go"
# Rust detection
elif [ -f "Cargo.toml" ]; then
  FRAMEWORK="rust"
# PHP detection
elif [ -f "composer.json" ]; then
  if grep -q "laravel" composer.json 2>/dev/null; then
    FRAMEWORK="laravel"
  elif grep -q "symfony" composer.json 2>/dev/null; then
    FRAMEWORK="symfony"
  else
    FRAMEWORK="php"
  fi
# Ruby detection
elif [ -f "Gemfile" ]; then
  if grep -q "rails" Gemfile 2>/dev/null; then
    FRAMEWORK="rails"
  else
    FRAMEWORK="ruby"
  fi
else
  FRAMEWORK="unknown"
fi

echo "Detected framework: $FRAMEWORK"
```

#### 2.2: Framework Detection Table

| Framework | Detection File | Detection Pattern |
|-----------|---------------|-------------------|
| **nextjs** | `package.json` | `"next"` in dependencies |
| **nestjs** | `package.json` | `"@nestjs/core"` in dependencies |
| **vue** | `package.json` | `"vue"` in dependencies |
| **angular** | `package.json` | `"@angular/core"` in dependencies |
| **react** | `package.json` | `"react"` in dependencies |
| **express** | `package.json` | `"express"` in dependencies |
| **node** | `package.json` | (default if no framework match) |
| **django** | `pyproject.toml`/`requirements.txt` | `django` in dependencies |
| **fastapi** | `pyproject.toml`/`requirements.txt` | `fastapi` in dependencies |
| **flask** | `pyproject.toml`/`requirements.txt` | `flask` in dependencies |
| **python** | `pyproject.toml`/`setup.py` | (default if no framework match) |
| **spring-boot** | `pom.xml` | `spring-boot` in dependencies |
| **java-maven** | `pom.xml` | (default if no spring) |
| **java-gradle** | `build.gradle` | (any gradle project) |
| **dotnet** | `*.csproj`/`*.sln` | File exists |
| **go** | `go.mod` | File exists |
| **rust** | `Cargo.toml` | File exists |
| **laravel** | `composer.json` | `laravel` in dependencies |
| **symfony** | `composer.json` | `symfony` in dependencies |
| **rails** | `Gemfile` | `rails` in dependencies |

#### 2.3: Run Quality Checks Based on Framework

**Command Mapping Table**:

| Framework | Lint Command | Build Command | Test Command | Type Check |
|-----------|-------------|---------------|--------------|------------|
| **nextjs** | `npm run lint` | `npm run build` | `npm run test` | `npm run typecheck` |
| **nestjs** | `npm run lint` | `npm run build` | `npm run test` | `npm run typecheck` |
| **vue** | `npm run lint` | `npm run build` | `npm run test` | `npm run typecheck` |
| **angular** | `npm run lint` | `npm run build` | `npm run test` | `npm run typecheck` |
| **react** | `npm run lint` | `npm run build` | `npm run test` | `npm run typecheck` |
| **express** | `npm run lint` | N/A | `npm run test` | `npm run typecheck` |
| **node** | `npm run lint` | N/A | `npm run test` | `npm run typecheck` |
| **django** | `ruff check .` | N/A | `pytest` | `mypy .` |
| **fastapi** | `ruff check .` | N/A | `pytest` | `mypy .` |
| **flask** | `ruff check .` | N/A | `pytest` | `mypy .` |
| **python** | `ruff check .` | N/A | `pytest` | `mypy .` |
| **spring-boot** | `mvn checkstyle:check` | `mvn compile` | `mvn test` | N/A |
| **java-maven** | `mvn checkstyle:check` | `mvn compile` | `mvn test` | N/A |
| **java-gradle** | `./gradlew checkstyleMain` | `./gradlew build` | `./gradlew test` | N/A |
| **dotnet** | `dotnet format --verify-no-changes` | `dotnet build` | `dotnet test` | N/A |
| **go** | `golangci-lint run` | `go build ./...` | `go test ./...` | N/A |
| **rust** | `cargo clippy` | `cargo build` | `cargo test` | N/A |
| **laravel** | `./vendor/bin/pint --test` | N/A | `php artisan test` | N/A |
| **symfony** | `php ./vendor/bin/phpcs` | N/A | `php ./bin/phpunit` | N/A |
| **rails** | `bundle exec rubocop` | N/A | `bundle exec rspec` | N/A |

#### 2.4: Execute Quality Checks

```bash
# Get commands for detected framework
case "$FRAMEWORK" in
  nextjs|nestjs|vue|angular|react)
    LINT_CMD="npm run lint"
    BUILD_CMD="npm run build"
    TEST_CMD="npm run test"
    TYPECHECK_CMD="npm run typecheck"
    ;;
  express|node)
    LINT_CMD="npm run lint"
    BUILD_CMD=""
    TEST_CMD="npm run test"
    TYPECHECK_CMD="npm run typecheck"
    ;;
  django|fastapi|flask|python)
    LINT_CMD="ruff check ."
    BUILD_CMD=""
    TEST_CMD="pytest"
    TYPECHECK_CMD="mypy ."
    ;;
  spring-boot|java-maven)
    LINT_CMD="mvn checkstyle:check"
    BUILD_CMD="mvn compile"
    TEST_CMD="mvn test"
    TYPECHECK_CMD=""
    ;;
  java-gradle|spring-boot-gradle)
    LINT_CMD="./gradlew checkstyleMain"
    BUILD_CMD="./gradlew build"
    TEST_CMD="./gradlew test"
    TYPECHECK_CMD=""
    ;;
  dotnet)
    LINT_CMD="dotnet format --verify-no-changes"
    BUILD_CMD="dotnet build"
    TEST_CMD="dotnet test"
    TYPECHECK_CMD=""
    ;;
  go)
    LINT_CMD="golangci-lint run"
    BUILD_CMD="go build ./..."
    TEST_CMD="go test ./..."
    TYPECHECK_CMD=""
    ;;
  rust)
    LINT_CMD="cargo clippy"
    BUILD_CMD="cargo build"
    TEST_CMD="cargo test"
    TYPECHECK_CMD=""
    ;;
  *)
    # Fallback: Ask user
    read -p "Framework not detected. Enter lint command: " LINT_CMD
    read -p "Enter build command (or press Enter to skip): " BUILD_CMD
    read -p "Enter test command: " TEST_CMD
    ;;
esac

# Run checks with error handling
run_check() {
  local name="$1"
  local cmd="$2"
  
  if [ -z "$cmd" ]; then
    echo "[$name] Skipped (no command configured)"
    return 0
  fi
  
  echo "[$name] Running: $cmd"
  if eval "$cmd"; then
    echo "[$name] ✓ Passed"
    return 0
  else
    echo "[$name] ✗ Failed"
    read -p "[$name] Failed. Continue anyway? (y/n): " CONTINUE
    [ "$CONTINUE" = "y" ] && return 0 || return 1
  fi
}

# Execute all checks
run_check "Lint" "$LINT_CMD" || exit 1
[ -n "$BUILD_CMD" ] && run_check "Build" "$BUILD_CMD" || exit 1
run_check "Test" "$TEST_CMD" || exit 1
[ -n "$TYPECHECK_CMD" ] && run_check "TypeCheck" "$TYPECHECK_CMD"
```

**Error handling**: If check fails, ask user to fix, continue, or cancel

### Step 3: Detect Tracking System

**Detection**:
```bash
JIRA_TICKET=$(git log --oneline -1 | grep -oE '[A-Z]+-[0-9]+')
GIT_ISSUE=$(git log --oneline -1 | grep -oE '#[0-9]+')

if [ -f "PLAN.md" ]; then
  PLAN_JIRA=$(grep -oE '[A-Z]+-[0-9]+' PLAN.md | head -1)
fi
```

**Systems**:
- JIRA: `PROJECT-NUM` format (e.g., `IBIS-123`)
- Git Issue: `#NUM` format (e.g., `#456`)
- None: Standalone PR

### Step 4: Check Git Status

**Verify**:
```bash
# Check working tree
if [ -n "$(git status --porcelain)" ]; then
  read -p "Commit changes? (y/n): " COMMIT_CHANGES
  if [ "$COMMIT_CHANGES" = "y" ]; then
    git add . && git commit -m "Prepare for PR"
  fi
fi

# Check remote tracking
CURRENT_BRANCH=$(git branch --show-current)
if ! git branch -vv | grep "* $CURRENT_BRANCH" | grep -q "\["; then
  git push -u origin "$CURRENT_BRANCH"
fi
```

### Step 5: Create PR

**PR title format** (use `git-semantic-commits`):
- `feat: <summary> [${TRACKING_ID}]` - New feature
- `fix: <summary> [${TRACKING_ID}]` - Bug fix
- `docs: <summary> [${TRACKING_ID}]` - Documentation
- With scope: `feat(api): add auth [${TRACKING_ID}]`
- Breaking: `feat!: breaking change [${TRACKING_ID}]`

**PR body template**:
```markdown
## Summary
<Bullet points describing changes>

<if jira>
## JIRA Reference
- Ticket: ${TRACKING_ID}
- Link: https://<company>.atlassian.net/browse/${TRACKING_ID}
</if>

<if git issue>
## Issue Reference
- Resolves #${TRACKING_ID}
</if>

## Changes
- <Key change 1>
- <Key change 2>

## Quality Checks
- Linting: ${LINT_RESULT}
- Build: ${BUILD_RESULT}
- Tests: ${TEST_RESULT}
- Type Check: ${TYPECHECK_RESULT}

## Files Modified
- `src/path/to/file.ts` - Description
- `README.md` - Documentation updates

## Checklist
- [ ] Code follows style guidelines
- [ ] All quality checks passed
- [ ] Documentation updated
- [ ] Self-reviewed
```

**Create PR**:
```bash
gh pr create \
  --base "$TARGET_BRANCH" \
  --title "feat: <summary> [${TRACKING_ID}]" \
  --body "$(cat pr-body.md)"
```

### Step 5.5: Apply Semantic Versioning Label

**Detect version bump type from PR title**:
```bash
PR_TITLE="feat: add user authentication [IBIS-123]"

# Detect breaking change (major)
if [[ "$PR_TITLE" =~ ^[^:]+\! ]]; then
  VERSION_LABEL="major"
# Detect new feature (minor)
elif [[ "$PR_TITLE" =~ ^feat ]]; then
  VERSION_LABEL="minor"
# Detect bug fix (patch)
elif [[ "$PR_TITLE" =~ ^fix ]]; then
  VERSION_LABEL="patch"
# Default to patch for other types
else
  VERSION_LABEL="patch"
fi
```

**Apply label to PR**:
```bash
# Get PR number from last created PR
PR_NUMBER=$(gh pr list --head "$(git branch --show-current)" --json number --jq '.[0].number')

# Apply the detected label
gh pr edit "$PR_NUMBER" --add-label "$VERSION_LABEL"
```

**Label mapping table**:

| PR Title Pattern | Label | Version Bump |
|------------------|-------|--------------|
| `feat!` or `feat(scope)!` | `major` | X.0.0 |
| `feat` | `minor` | 0.X.0 |
| `fix` | `patch` | 0.0.X |
| `refactor`, `docs`, `style`, `test`, `chore` | `patch` | 0.0.X |

### Step 6: Handle Images

**Detection**:
```bash
# Find images in common locations
IMAGES=$(find diagrams /tmp . -maxdepth 2 \
  -type f \( -name "*.png" -o -name "*.svg" -o -name "*.jpg" \) \
  -mmin -60 2>/dev/null)
```

**Handling**:
- Public URL: Embed directly in PR
- Local file: Upload to external host or JIRA
- Temp file: Warn user it's temporary

### Step 7: Merge and Update JIRA

**Merge confirmation**:
```bash
read -p "Merge this PR? (y/n): " MERGE_CONFIRM

if [ "$MERGE_CONFIRM" = "y" ]; then
  gh pr merge "$PR_NUMBER"
  
  # Update JIRA status
  if [ "$TRACKING_SYSTEM" = "jira" ]; then
    read -p "Update JIRA to Done? (y/n): " UPDATE_JIRA
    if [ "$UPDATE_JIRA" = "y" ]; then
      # Use jira-status-updater framework
      jira-status-updater --ticket "$TRACKING_ID" --status "Done"
    fi
  fi
fi
```

## Frameworks Used

- `git-semantic-commits` - PR title formatting
- `git-issue-updater` - Issue progress updates
- `jira-status-updater` - JIRA status transitions
- `jira-git-integration` - JIRA operations
- `linting-workflow` - Quality checks
- `docstring-generator` - Docstring verification

## Best Practices

- **Target branch**: Don't hardcode to `dev` - detect or ask
- **Quality checks**: Make configurable per project
- **Tracking links**: Always include JIRA/git issue references
- **PR descriptions**: Consistent format with summary, changes, checks
- **Image handling**: Upload local files, don't link to `/tmp/`
- **Merge confirmation**: Always ask before merging
- **Branch cleanliness**: Ensure clean working tree before PR
- **PR titles**: Use semantic format via `git-semantic-commits`
- **PR size**: Keep focused and small (<400 lines changed)

## Common Issues

### Target Branch Not Specified
```bash
read -p "Enter target branch (main/develop/staging): " TARGET_BRANCH
```

### Quality Checks Fail
```bash
read -p "Linting failed. Run auto-fix? (y/n): " AUTO_FIX
read -p "Create PR anyway? (y/n): " CONTINUE_PR
```

### Tracking Not Detected
```bash
# Create standalone PR
TRACKING_SYSTEM="none"

# Or ask user
read -p "Enter JIRA ticket or issue number: " USER_TRACKING
```

### Branch Not Pushed
```bash
git push -u origin $(git branch --show-current)
```

### Image Upload Issues
- Commit images to repository (for diagrams)
- Upload to external image hosting
- Upload to JIRA if ticket exists

## Troubleshooting

**Before creating PR**:
- [ ] All changes committed
- [ ] Working tree clean
- [ ] Branch has remote tracking
- [ ] Target branch identified
- [ ] Quality checks configured
- [ ] Tracking system reference identified

**After PR creation**:
- [ ] PR number captured
- [ ] PR URL accessible
- [ ] PR description complete
- [ ] Quality check status included
- [ ] Images properly referenced
- [ ] Tracking reference included

## Semantic Versioning Labels

Add version bump labels to indicate release impact:

| Label | Color | Description | Version Bump | Examples |
|-------|-------|-------------|--------------|----------|
| `major` | #d73a4a (red) | Breaking changes | X.0.0 | API removal, breaking refactor |
| `minor` | #fbca04 (yellow) | New features | 0.X.0 | New API, new component |
| `patch` | #0e8a16 (green) | Bug fixes | 0.0.X | Bug fix, typo correction |

**Label Mapping from Commit Type**:
- `feat!` or `feat(scope)!` → `major` (breaking change)
- `feat` → `minor` (new feature)
- `fix` → `patch` (bug fix)
- `refactor` → `patch` (code improvement)
- `docs` → `patch` (documentation)
- `style` → `patch` (formatting)
- `test` → `patch` (tests)
- `chore` → `patch` (maintenance)

**Usage**:
```bash
# Add version label to PR
gh pr edit <PR_NUMBER> --add-label "minor"

# Or during PR creation
gh pr create --title "feat: add user auth" --add-label "minor"
```

## Relevant Skills

**Skills using this framework**:
- `git-pr-creator` - PR creation with JIRA integration
- `nextjs-pr-workflow` - Next.js-specific extension (example of framework-specific extension)

**Framework-specific extensions** (can be created for other frameworks):
- Follow `nextjs-pr-workflow` pattern for other frameworks
- Extend with framework-specific quality checks
- Add framework-specific PR templates

**Supporting frameworks**:
- `git-semantic-commits` - Semantic commit formatting
- `git-issue-updater` - Issue progress updates
- `jira-status-updater` - JIRA status transitions
- `jira-git-integration` - JIRA operations
- `linting-workflow` - Quality checks
- `git-issue-plan-workflow` - Initial setup (branch, PLAN.md)
