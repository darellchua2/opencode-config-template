---
name: coverage-framework
description: Framework for test coverage reporting and documentation workflows
license: Apache-2.0
compatibility: opencode
metadata:
  audience: developers, QA engineers
  workflow: testing
  type: framework
---

## What I do

Framework for test coverage reporting and documentation. Extended by language-specific coverage skills.

## Extensions

| Skill | Language | Purpose |
|-------|----------|---------|
| `coverage-readme-workflow` | All | Add coverage badges to README |

## Workflow Steps

### 1. Generate Coverage
- Run tests with coverage flag
- Generate report (HTML, XML, JSON)
- Calculate percentage

### 2. Analyze Results
- Identify uncovered code paths
- Find missing test cases
- Review branch coverage

### 3. Report Coverage
- Add badge to README
- Update documentation
- Track coverage trends

### 4. Improve Coverage
- Target low-coverage areas
- Add missing tests
- Remove dead code

## Language-Specific Commands

| Language | Coverage Command |
|----------|------------------|
| Python | `pytest --cov=src --cov-report=xml` |
| JavaScript | `jest --coverage` |
| TypeScript | `vitest --coverage` |
| Go | `go test -coverprofile=coverage.out` |

## Coverage Report Formats

| Format | Tool | Output |
|--------|------|--------|
| XML | Cobertura | `coverage.xml` |
| HTML | Built-in | `htmlcov/` |
| JSON | Custom | `coverage.json` |
| LCOV | Generic | `lcov.info` |

## Badge Format

```markdown
![Coverage](https://img.shields.io/badge/coverage-85%25-brightgreen)
```

| Coverage | Color |
|----------|-------|
| 90-100% | brightgreen |
| 80-89% | green |
| 70-79% | yellowgreen |
| 60-69% | yellow |
| <60% | red |

## Best Practices

1. Aim for 80%+ coverage minimum
2. Focus on critical paths first
3. Track coverage over time
4. Add badges to README
5. Fail CI on coverage drop

## Related Skills

- `coverage-readme-workflow` - README badges
- `test-generator-framework` - Test generation
- `tdd-workflow` - Test-driven development
