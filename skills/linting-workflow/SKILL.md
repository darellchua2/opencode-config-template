---
name: linting-workflow
description: Generic linting workflow for multiple languages with auto-fix and error resolution
license: Apache-2.0
compatibility: opencode
metadata:
  audience: developers
  workflow: code-quality
---

## What I do

I provide a generic linting workflow for multiple languages:
- Detect project language and linter configuration
- Run linting and apply auto-fix when available
- Guide resolution of linting errors
- Verify fixes and commit changes

## When to use me

Use when:
- Linting code before committing or PRs
- Building workflow skills with code quality checks
- Need consistent linting across multiple languages

This is a **framework skill** - provides linting logic that other skills extend.

## Steps

### Step 1: Detect Language and Linter

**Detection**:
- `package.json` + `tsconfig.json` → TypeScript (ESLint)
- `package.json` → JavaScript (ESLint)
- `pyproject.toml` / `requirements.txt` → Python (Ruff)
- `go.mod` → Go (golint/golangci-lint)
- `Gemfile` → Ruby (RuboCop)

**Configuration files**:
- ESLint: `eslint.config.ts/js/mjs`, `.eslintrc.json/js/yaml`
- Ruff: `pyproject.toml`, `.ruff.toml`, `ruff.toml`

### Step 2: Detect Package Manager

| Language | Manager | Lock File | Command |
|----------|---------|-----------|---------|
| JS/TS | npm | `package-lock.json` | `npm run <script>` |
| JS/TS | yarn | `yarn.lock` | `yarn <script>` |
| JS/TS | pnpm | `pnpm-lock.yaml` | `pnpm run <script>` |
| Python | Poetry | `pyproject.toml` | `poetry run <script>` |
| Python | pip | `requirements.txt` | Direct command |

### Step 3: Run Linting

**Commands**:
```bash
# JavaScript/TypeScript (ESLint)
npm run lint              # npm
yarn lint                 # yarn
pnpm run lint            # pnpm
npx eslint .             # direct

# Python (Ruff)
ruff check .             # direct
poetry run ruff check .  # poetry
```

### Step 4: Apply Auto-Fix

**Auto-fix commands**:
- ESLint: `npm run lint -- --fix`
- Prettier: `npx prettier --write .`
- Ruff: `ruff check . --fix`
- Black: `black .`

**Auto-fix capabilities**:
- Style violations, unused variables, simple syntax issues
- Formatting, indentation, quotes
- Unused imports, simple refactorings

### Step 5: Fix Remaining Errors

**Error categories**:
- Syntax errors (prevents code from running)
- Style violations (code style guidelines)
- Potential bugs (risky code patterns)
- Deprecation warnings (deprecated features)
- Type errors (TypeScript type mismatches)
- Missing docstrings (public functions/classes)

**Resolution workflow**:
1. Run auto-fix first
2. Fix remaining errors incrementally
3. Re-run linting after each batch
4. Use error messages for guidance

### Step 6: Verify and Commit

**Re-run linting**:
```bash
# Re-check after manual fixes
npm run lint      # or
ruff check .
```

**Commit fixes**:
```bash
git add .
git commit -m "fix(lint): resolve linting errors"
```

## Best Practices

- Run linting before committing
- Apply auto-fix before manual fixes
- Fix errors incrementally, re-run between batches
- Don't disable rules as workaround
- Configure editor to lint on save
- Integrate into CI/CD pipelines
- Use pre-commit hooks (Husky, pre-commit)

## Common Issues

### Linter Not Found
**Install linter**:
```bash
npm install --save-dev eslint  # ESLint
pip install ruff                # Ruff
```

### Config File Missing
**Create default config**:
- ESLint: `.eslintrc.json` with `{"extends": "eslint:recommended"}`
- Ruff: `pyproject.toml` with `[tool.ruff] line-length = 88`

### Too Many Errors
- Focus on one category at a time
- Fix incrementally
- Re-run after each batch

### Auto-Fix Doesn't Work
- Some errors require manual intervention
- Review error messages
- Check if rule supports auto-fix

## Related Skills

- `python-ruff-linter`: Python-specific Ruff linting
- `javascript-eslint-linter`: JavaScript/TypeScript-specific ESLint linting
- `pr-creation-workflow`: Run linting before PRs
- `test-generator-framework`: Code quality before testing
