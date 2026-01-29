---
name: test-generator-framework
description: Generic test generation framework supporting multiple languages and testing frameworks
license: Apache-2.0
compatibility: opencode
metadata:
  audience: developers
  workflow: testing-framework
---

## What I do

I provide a generic test generation framework for multiple languages:
- Analyze codebase to identify functions, classes, components
- Detect testing framework (Jest, Vitest, Pytest, etc.)
- Generate comprehensive test scenarios (happy paths, edge cases, errors)
- Create test files with proper structure
- Verify tests are executable

## When to use me

Use when:
- Creating new test generation skill for specific language/framework
- Standardizing test generation across projects
- Building language-specific test generators

This is a **framework skill** - provides foundational workflow for other skills.

## Steps

### Step 1: Detect Framework and Package Manager

**Framework detection**:
- JavaScript/TypeScript: `grep -E "(jest|vitest)" package.json`
- Python: `grep pytest pyproject.toml` or `requirements.txt`
- Ruby: `grep -E "(rspec|minitest)" Gemfile`
- Go: Built-in testing

**Package manager detection**:
| Language | Manager | Lock File | Command |
|----------|---------|-----------|---------|
| JS/TS | npm | `package-lock.json` | `npm run <script>` |
| JS/TS | yarn | `yarn.lock` | `yarn <script>` |
| JS/TS | pnpm | `pnpm-lock.yaml` | `pnpm run <script>` |
| Python | Poetry | `pyproject.toml` | `poetry run <script>` |
| Python | pip | `requirements.txt` | Direct command |

### Step 2: Analyze Source Code

Use glob patterns to find source files (exclude test files):
```
<glob_pattern> --exclude "**/*test*.<ext>" --exclude "**/test/**/*"
```

Identify:
- Functions, classes, modules, components
- Import statements and dependencies
- Export patterns

### Step 3: Generate Test Scenarios

**Scenario categories**:

**Happy path**: Normal inputs, expected outputs, common use cases
**Edge cases**: Empty inputs, boundary values (0, 1, -1, max, min), single-item collections
**Error handling**: Invalid types, out of range values, missing params, invalid formats, permissions
**State management**: Initial state, state updates, multiple transitions, reset, cleanup
**User interactions**: Click events, form submissions, keyboard nav, input changes, hover/focus

**Scenario generation template**:
```
For each [function/class/component]:
  1. Identify inputs and return values
  2. Determine normal behavior (happy path)
  3. List edge cases based on input types
  4. Identify error conditions
  5. Check for state management or user interactions
```

### Step 4: Display Scenarios for Confirmation

```
📋 Generated Test Scenarios for <file_name>

**Type:** <Component | Function | Class>
**Item:** <Item Name>

**Scenarios:**
1. Happy Path: <description> → <result>
2. Edge Case: <description> → <result>
3. Error Case: <description> → <error>

**Total Scenarios:** <number>
**Framework:** <Jest | Vitest | Pytest>
**Test Command:** <command>

Proceed? (y/n/suggest)
```

### Step 5: Create Test Files

**Test file structure**:
```
describe('<ItemName>', () => {
  describe('Happy Path', () => { /* tests */ })
  describe('Edge Cases', () => { /* tests */ })
  describe('Error Handling', () => { /* tests */ })
  describe('State/Interactions', () => { /* tests */ })
})
```

**Naming conventions**:
- Jest/Vitest: `<Component>.test.tsx` or `<Component>.spec.tsx`
- Pytest: `test_<module>.py` or `<module>_test.py`
- RSpec: `<module>_spec.rb`
- Go: `<module>_test.go`

### Step 6: Verify Executability

**Run tests**:
```bash
# JavaScript/TypeScript
npm run test              # npm
yarn test                 # yarn
pnpm run test            # pnpm

# Python
pytest                   # direct
poetry run pytest        # poetry
```

**Verification checklist**:
- [ ] Test files created in correct location
- [ ] Naming follows framework conventions
- [ ] Imports resolve correctly
- [ ] Tests are discoverable
- [ ] Tests execute (even if they fail)
- [ ] No syntax errors

## Best Practices

- **Organization**: Keep tests in `tests/` or `__tests__/` directory
- **Fixtures**: Use framework-specific fixtures for common setup
- **Parametrization**: Use parametrized tests for similar cases
- **Isolation**: Each test should be independent
- **Coverage**: Aim for 80%+ code coverage
- **Speed**: Keep unit tests fast (< 0.1s each)
- **AAA pattern**: Structure tests as Arrange-Act-Assert
- **Confirmation**: Always show scenarios before creating files

## Common Issues

### Framework Not Detected
Check for config files:
- JS/TS: `package.json`, `jest.config.js`, `vitest.config.ts`
- Python: `pyproject.toml`, `pytest.ini`, `setup.cfg`

### Package Manager Not Detected
Check lock files:
- `package-lock.json` → npm
- `yarn.lock` → yarn
- `pnpm-lock.yaml` → pnpm
- `pyproject.toml` → poetry (or pip)

### Import Errors
Ensure correct import paths and modules are exported:
```bash
# Python
export PYTHONPATH="${PYTHONPATH}:$(pwd)"

# JS/TS
grep '"exports"' package.json
```

### Tests Not Discovered
Verify correct naming and location per framework patterns

## Related Skills

- `nextjs-unit-test-creator`: Next.js/React testing (Jest/Vitest)
- `python-pytest-creator`: Python testing (Pytest)
- `tdd-workflow`: Test Driven Development methodology
- `linting-workflow`: Code quality before testing
