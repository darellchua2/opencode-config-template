---
name: tdd-workflow
description: Guide developers through Test Driven Development workflow with red-green-refactor cycle, supporting multiple languages and frameworks
license: Apache-2.0
compatibility: opencode
metadata:
  audience: developers, QA engineers
  workflow: testing
---

## What I do
- Explain TDD principles and the red-green-refactor cycle
- Provide language-specific TDD workflows (Python/pytest, JavaScript/Jest/Vitest, Next.js)
- Define test structure for TDD (failing tests first, minimal implementation, refactoring)
- Guide through Write Test → Run Test (Red) → Write Minimal Code → Run Test (Green) → Refactor cycle
- Provide concrete TDD examples with before/after code comparisons
- Integrate with test-generator-framework, python-pytest-creator, nextjs-unit-test-creator

## When to use me

Use when:
- Adopting Test Driven Development methodology for a new feature
- Need guidance on TDD workflow for a specific language or framework
- Teaching or mentoring developers on TDD practices
- Refactoring existing code using TDD techniques
- Verifying test coverage follows TDD principles
- Setting up testing standards for a new project

**Use before**: test-generator-framework, python-pytest-creator, nextjs-unit-test-creator

## Prerequisites

- Basic understanding of unit testing concepts
- Access to testing framework for your language (pytest, Jest, Vitest, etc.)
- Knowledge of programming language you're working with
- Familiarity with project structure and build tools
- Optional: Existing test generation skills for your language

## TDD Principles

### The Red-Green-Refactor Cycle

TDD follows a continuous cycle:

```
┌─────────────────────────────────────────┐
│  1. Write a failing test (RED)      │
└─────────────────────────────────────────┘
                 ↓
┌─────────────────────────────────────────┐
│  2. Run test and see it fail (RED)   │
└─────────────────────────────────────────┘
                 ↓
┌─────────────────────────────────────────┐
│  3. Write minimal code to pass (GREEN)│
└─────────────────────────────────────────┘
                 ↓
┌─────────────────────────────────────────┐
│  4. Run test and see it pass (GREEN)  │
└─────────────────────────────────────────┘
                 ↓
┌─────────────────────────────────────────┐
│  5. Refactor code (REFACTOR)         │
└─────────────────────────────────────────┘
                 ↓
      (Return to step 1)
```

### Core TDD Rules

1. **Never write production code without a failing test**
2. **Write minimal amount of code to make test pass**
3. **Refactor only after all tests pass**
4. **Keep tests small and focused**
5. **Write one test at a time**
6. **Test behavior, not implementation details**

## Steps

### Step 1: Choose Your Feature

**Example**: "User login functionality"

**Break down into behaviors**:
- Validate email format
- Check if user exists
- Verify password matches
- Return authentication token on success
- Return error message on failure

### Step 2: Write First Failing Test (RED)

**Python/pytest Example**:
```python
def test_login_with_valid_credentials():
    """User should be able to login with valid credentials."""
    response = auth.login("user@example.com", "password123")
    assert response.success is True
    assert "token" in response.data
```

**JavaScript/Jest Example**:
```javascript
test('user can login with valid credentials', () => {
  const response = auth.login('user@example.com', 'password123');
  expect(response.success).toBe(true);
  expect(response.data).toHaveProperty('token');
});
```

**Verify test fails**: Run test and ensure it fails with an error.

### Step 3: Write Minimal Production Code (GREEN)

**Python/pytest Example**:
```python
# auth.py
class AuthResponse:
    def __init__(self, success, data):
        self.success = success
        self.data = data

def login(email, password):
    return AuthResponse(success=True, data={"token": "dummy_token"})
```

**JavaScript/Jest Example**:
```javascript
// auth.js
const login = (email, password) => {
  return {
    success: true,
    data: { token: 'dummy_token' }
  };
};
```

**Verify test passes**: Run test and ensure it passes (1 passed).

### Step 4: Refactor (REFACTOR)

**Refactoring guidelines**:
- Extract constants
- Improve variable names
- Remove code duplication
- Improve readability
- Add input validation

**Python Refactored Example**:
```python
# auth.py
DUMMY_TOKEN = "dummy_token"

class AuthResponse:
    def __init__(self, success, data):
        self.success = success
        self.data = data

def login(email, password):
    if not email or not password:
        raise ValueError("Email and password are required")
    return AuthResponse(success=True, data={"token": DUMMY_TOKEN})
```

### Step 5: Repeat for Next Behavior

Continue TDD cycle for each behavior:
1. Write failing test for next behavior
2. Implement minimal code
3. Refactor when all tests pass

## Best Practices

- Write the simplest possible test first
- Focus on one behavior at a time
- Keep test names descriptive
- Run tests frequently (after each change)
- Refactor continuously, not just at the end
- Use test doubles (mocks, stubs) for dependencies
- Keep tests independent (no dependencies between tests)
- Use descriptive test names
- Test behavior, not implementation details

## Common Issues

### Test Won't Fail Initially
**Solution**: Ensure test setup is correct, check test assertions, verify dependencies are mocked.

### Too Much Code Written
**Solution**: Follow YAGNI (You Aren't Gonna Need It) principle, write only what's needed to pass the test.

### Tests Become Flaky
**Solution**: Remove dependencies between tests, use proper setup/teardown, mock external dependencies.

### Hard to Understand Refactored Code
**Solution**: Refactor in small increments, ensure tests pass after each refactoring step.

## References

- pytest Documentation: https://docs.pytest.org/
- Jest Documentation: https://jestjs.io/docs/getting-started
- TDD Best Practices: https://martinfowler.com/bliki/TestDrivenDevelopment
