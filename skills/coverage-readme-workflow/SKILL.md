---
name: coverage-readme-workflow
description: Ensure test coverage percentage is displayed in README.md for Next.js and Python projects following industry standards
license: Apache-2.0
compatibility: opencode
metadata:
  audience: developers
  workflow: test-coverage-documentation
---

## What I do
- Detect project type: Next.js (JavaScript/TypeScript) or Python
- Run test suite with coverage collection for detected framework
- Parse coverage output: lines, statements, branches, functions
- Generate coverage badge in industry-standard format (Shields.io)
- Update README.md with coverage badge and percentage
- Handle edge cases: missing coverage, zero coverage, threshold violations

## When to use me
Use when:
- Creating a new Next.js application or Python project
- Adding tests to an existing project
- Ensuring test coverage is visible in project documentation
- Following industry standard practices for displaying code quality metrics
- Updating coverage percentage after adding new features
- Preparing for code review or PR submission
- Tracking coverage trends over time

**Integration**: Used alongside test-generator-framework, nextjs-unit-test-creator, python-pytest-creator, before PR creation.

## Prerequisites

- Next.js project with `package.json` OR Python project with `pyproject.toml`/`requirements.txt`
- Test framework installed (Jest/Vitest for Next.js, pytest for Python)
- Coverage tools available (built-in to Jest/Vitest, pytest-cov for pytest)
- README.md file exists in project root
- Write permissions to update README.md
- Tests must pass before coverage display

## Steps

### Step 1: Detect Project Type

```bash
# Check for Next.js project
if [ -f "package.json" ]; then
  if grep -q '"next"' package.json; then
    PROJECT_TYPE="nextjs"
  else
    PROJECT_TYPE="nodejs"
  fi
fi

# Check for Python project
if [ -f "pyproject.toml" ] || [ -f "requirements.txt" ]; then
  PROJECT_TYPE="python"
fi

echo "Detected project type: $PROJECT_TYPE"
```

**Project Types**:
- `nextjs`: Next.js application (React framework)
- `nodejs`: JavaScript/TypeScript project without Next.js
- `python`: Python project

### Step 2: Detect Test Framework and Coverage Tool

**Next.js Projects**:
```bash
if grep -q '"vitest"' package.json; then
  TEST_FRAMEWORK="vitest"
  COVERAGE_CMD="npm run test -- --coverage"
elif grep -q '"jest"' package.json; then
  TEST_FRAMEWORK="jest"
  COVERAGE_CMD="npm run test -- --coverage"
else
  echo "No coverage command found"
fi
```

**Python Projects**:
```bash
if grep -q '"pytest-cov"' pyproject.toml 2>/dev/null || grep -q "pytest-cov" requirements.txt 2>/dev/null; then
  TEST_FRAMEWORK="pytest"
  COVERAGE_CMD="poetry run pytest --cov=. --cov-report=term 2>/dev/null || pytest --cov=. --cov-report=term"
fi
```

### Step 3: Run Tests with Coverage

**Next.js (Jest/Vitest)**:
```bash
$COVERAGE_CMD 2>&1 | tee /tmp/coverage_output.txt

COVERAGE_PERCENT=$(grep -oP '\d+(?=%)' /tmp/coverage_output.txt | head -1)
LINES_COV=$(grep -oP 'Lines\s*:\s*\K\d+(?=%)' /tmp/coverage_output.txt | head -1)
STATEMENTS_COV=$(grep -oP 'Statements\s*:\s*\K\d+(?=%)' /tmp/coverage_output.txt | head -1)
BRANCHES_COV=$(grep -oP 'Branches\s*:\s*\K\d+(?=%)' /tmp/coverage_output.txt | head -1)
FUNCTIONS_COV=$(grep -oP 'Functions\s*:\s*\K\d+(?=%)' /tmp/coverage_output.txt | head -1)
```

**Python (pytest-cov)**:
```bash
$COVERAGE_CMD 2>&1 | tee /tmp/coverage_output.txt

COVERAGE_PERCENT=$(grep -oP '\d+(?=%)' /tmp/coverage_output.txt | head -1)
LINES_COV=$(grep -oP 'Lines\s*:\s*\K\d+(?=%)' /tmp/coverage_output.txt | head -1)
BRANCHES_COV=$(grep -oP 'Branches\s*:\s*\K\d+(?=%)' /tmp/coverage_output.txt | head -1)
```

### Step 4: Generate Coverage Badge

```bash
BADGE_URL="https://img.shields.io/badge/coverage-${COVERAGE_PERCENT}%25-${BADGE_COLOR}.svg"

if [ "${COVERAGE_PERCENT}" -ge 80 ]; then
  BADGE_COLOR="brightgreen"
elif [ "${COVERAGE_PERCENT}" -ge 60 ]; then
  BADGE_COLOR="yellow"
elif [ "${COVERAGE_PERCENT}" -ge 40 ]; then
  BADGE_COLOR="orange"
else
  BADGE_COLOR="red"
fi

COVERAGE_BADGE="![Coverage](${BADGE_URL})"
```

**Badge Color Scheme**:
- **brightgreen** (>= 80%): Excellent coverage
- **yellow** (60-79%): Good coverage, room for improvement
- **orange** (40-59%): Moderate coverage, needs attention
- **red** (< 40%): Poor coverage, requires immediate action

### Step 5: Update README.md

```bash
if grep -q "coverage" README.md; then
  sed -i "s|!\[Coverage\](.*)|${COVERAGE_BADGE}|" README.md
else
  if grep -q "^\[!\[" README.md; then
    sed -i "/^\[!\[.*\](.*)\]/a ${COVERAGE_BADGE}" README.md
  else
    sed -i "1,/^# /s|^# \(.*\)|# \1\n\n${COVERAGE_BADGE}|" README.md
  fi
fi
```

### Step 6: Verify README.md Update

```bash
echo "Coverage badge added:"
grep -o '\[!\[Coverage\].*svg\)' README.md
echo "To commit: git add README.md && git commit -m 'docs: update coverage badge to ${COVERAGE_PERCENT}%'"
```

## Coverage Badge Templates

**Basic Badge**:
```markdown
![Coverage](https://img.shields.io/badge/coverage-85%25-brightgreen.svg)
```

**Detailed Coverage Table**:
```markdown
## Test Coverage

| Metric | Coverage |
|--------|----------|
| Overall | 85% | ![Coverage](https://img.shields.io/badge/coverage-85%25-brightgreen.svg) |
| Lines | 87% | ![Lines](https://img.shields.io/badge/lines-87%25-brightgreen.svg) |
| Branches | 82% | ![Branches](https://img.shields.io/badge/branches-82%25-yellow.svg) |
```

## Best Practices

- Aim for at least 80% coverage for production code
- Place coverage badge prominently at top of README.md
- Set up CI/CD pipeline to update badge automatically
- Display overall coverage and breakdown (lines, branches, functions)
- Consider showing coverage trends over time
- Configure coverage thresholds in test configuration
- Exclude test files and non-critical code from coverage
- Explain how to run tests with coverage in README.md

## Common Issues

### Coverage Command Not Found
**Solution**: Add coverage script to package.json: `"test:coverage": "vitest run --coverage"`.

### README.md Update Fails
**Solution**: Verify write permissions, check sed command syntax, ensure README.md exists.

### Badge Not Displaying
**Solution**: Verify badge URL format, check color variable, test URL in browser.

## References

- Jest Configuration: https://jestjs.io/docs/configuration
- Vitest Configuration: https://vitest.dev/guide/coverage
- pytest-cov Documentation: https://pytest-cov.readthedocs.io/
- Shields.io Badges: https://shields.io/
