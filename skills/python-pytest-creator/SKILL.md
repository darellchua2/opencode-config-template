---
name: python-pytest-creator
description: Generate comprehensive pytest test files for Python applications with scenario validation, supporting both Poetry and pip environments
license: Apache-2.0
compatibility: opencode
metadata:
  audience: developers
  workflow: python-testing
---

## What I do

I implement a complete pytest test generation workflow:

1. **Analyze Python Codebase**: Scan the Python application to identify functions, classes, and modules that need testing
2. **Detect Pytest Configuration**: Read `pyproject.toml` or `requirements.txt` to determine pytest version and dependencies
3. **Detect Poetry Installation**: Check if Poetry is installed and available
4. **Generate Test Scenarios**: Create comprehensive test scenarios covering:
   - Happy paths (normal operation)
   - Edge cases (boundary conditions)
   - Error handling (exceptions and failures)
   - Input validation
   - Performance scenarios
   - Integration scenarios
5. **Prompt User Confirmation**: Display all generated scenarios and ask for user approval before proceeding
6. **Create Test Files**: Generate pytest test files with proper structure and assertions
7. **Ensure Executability**: Verify tests run with `poetry run pytest <test_files>` (if Poetry) or `pytest <test_files>` (if no Poetry)

## When to use me

Use this workflow when:
- You need to create comprehensive pytest test files for a Python application
- You want to ensure all edge cases and error conditions are covered
- You need tests that integrate with Poetry environments
- You prefer a systematic approach to test generation with user confirmation
- You want to ensure tests run correctly with your project's pytest version

## Prerequisites

- Python project with Poetry (`pyproject.toml`) or pip (`requirements.txt`)
- Pytest installed and configured in the project
- Python source code to test
- Appropriate file permissions to create test files

Note: Poetry is optional. If Poetry is installed and `pyproject.toml` exists, tests will use `poetry run pytest`. Otherwise, tests will use `pytest` directly.

## Steps

### Step 1: Analyze Python Codebase
- Use glob patterns to find Python files: `**/*.py`
- Exclude test files: `**/test_*.py`, `**/*_test.py`, `**/tests/**/*.py`
- Read each Python file to identify:
  - Functions: `def function_name(parameters):`
  - Classes: `class ClassName:`
  - Methods: `def method_name(self, parameters):`
  - Async functions: `async def async_function():`
- Identify import statements to understand dependencies

### Step 2: Detect Pytest Configuration
- Check for `pyproject.toml`:
  ```bash
  # Check if pyproject.toml exists
  ls pyproject.toml

  # Extract pytest version
  grep -A 10 "^\[tool.poetry.dev-dependencies\]" pyproject.toml | grep pytest
  ```
- Check for `requirements.txt`:
  ```bash
  # Check if requirements.txt exists
  ls requirements.txt

  # Extract pytest version
  grep pytest requirements.txt
  ```
- Determine pytest-specific configurations:
  - Test discovery patterns
  - Coverage requirements
  - Custom pytest plugins

### Step 3: Detect Poetry Installation
- Check if Poetry is installed:
  ```bash
  poetry --version 2>/dev/null
  ```
- Determine which command to use:
  - If Poetry is installed AND `pyproject.toml` exists → use `poetry run pytest`
  - Otherwise → use `pytest` directly
- Store the appropriate pytest command for use in later steps:
  ```bash
  if command -v poetry &>/dev/null && [ -f pyproject.toml ]; then
      PYTEST_CMD="poetry run pytest"
      echo "Using Poetry: $PYTEST_CMD"
  else
      PYTEST_CMD="pytest"
      echo "Using pytest directly: $PYTEST_CMD"
  fi
  ```

### Step 4: Generate Test Scenarios
For each function/class identified, generate scenarios:

#### Function Scenarios
- **Happy Path**: Normal inputs with expected outputs
- **Edge Cases**: Minimum/maximum values, empty inputs, None values
- **Error Cases**: Invalid inputs, type mismatches, exceptions
- **Boundary Conditions**: Zero, negative numbers, string length limits

#### Class Scenarios
- **Initialization**: Constructor with valid/invalid parameters
- **Method Behavior**: Public/private method testing
- **State Management**: Instance variable changes
- **Inheritance**: Subclass behavior testing

#### Async Function Scenarios
- **Awaitable Results**: Normal async execution
- **Concurrency**: Multiple async calls
- **Error Handling**: Async exceptions

### Step 5: Display Scenarios for Confirmation
Display formatted output:
```
📋 Generated Test Scenarios for <module_name>.py

**Functions to Test:**
1. function_name(param1, param2)
   - Happy path: Valid inputs return expected result
   - Edge case: Empty param1 returns default
   - Error case: Invalid type raises ValueError
   - Boundary: Maximum param2 size handled

2. another_function(param)
   - Happy path: Valid param returns success
   - Edge case: None param raises TypeError
   - Error case: Negative param raises ValueError

**Classes to Test:**
1. ClassName
   - Initialization: Valid params create instance
   - Method behavior: method_name() returns expected
   - State: Instance variables updated correctly

**Total Scenarios: <number>**
**Estimated Test Lines: <number>**

Are these scenarios acceptable? (y/n/suggest)
```

Wait for user response:
- **y**: Proceed to create test files
- **n**: Ask for modifications or cancel
- **suggest**: Ask user to add/remove scenarios

### Step 6: Create Test Files
- Create `tests/` directory if not exists
- Generate test file structure:
  ```python
  """
  Test suite for <module_name>.py
  Generated by python-pytest-creator skill
  """
  
  import pytest
  from <module_path> import <function_name>, <ClassName>
  
  # Test function_name
  def test_function_name_happy_path():
      """
      Test that function_name works with valid inputs
      """
      result = function_name(param1, param2)
      assert result == expected_result
  
  def test_function_name_edge_case_empty():
      """
      Test that function_name handles empty param1
      """
      result = function_name("", param2)
      assert result is None
  
  def test_function_name_error_invalid_type():
      """
      Test that function_name raises ValueError for invalid type
      """
      with pytest.raises(ValueError):
          function_name(invalid_param, param2)
  
  # Test ClassName
  def test_class_name_initialization():
      """
      Test that ClassName initializes correctly
      """
      instance = ClassName(param1, param2)
      assert instance.attribute == expected_value
  
  def test_class_name_method():
      """
      Test that ClassName.method_name works correctly
      """
      instance = ClassName(param1, param2)
      result = instance.method_name(param)
      assert result == expected_result
  ```
- Use pytest fixtures for common setup:
  ```python
  @pytest.fixture
  def sample_instance():
      """Create a sample instance for testing"""
      return ClassName(param1, param2)
  
  @pytest.fixture
  def sample_data():
      """Provide sample test data"""
      return {"key": "value"}
  ```
- Use pytest.mark for categorization:
  ```python
  @pytest.mark.unit
  def test_unit_scenario():
      pass
  
  @pytest.mark.integration
  def test_integration_scenario():
      pass
  
  @pytest.mark.slow
  def test_performance_scenario():
      pass
  ```

### Step 7: Verify Executability
- Ensure tests can be run with the appropriate pytest command:
  ```bash
  # If Poetry is installed and pyproject.toml exists:
  poetry run pytest tests/test_<module_name>.py -v

  # Otherwise:
  pytest tests/test_<module_name>.py -v

  # Run all tests
  [poetry run] pytest -v

  # Run with coverage
  [poetry run] pytest --cov=<module_name> tests/
  ```
- Verify no import errors or syntax issues
- Check that all tests are discoverable by pytest

### Step 8: Display Summary
```
✅ Test files created successfully!

**Test Files Created:**
- tests/test_<module_name1>.py (<number> tests)
- tests/test_<module_name2>.py (<number> tests)

**Total Tests Generated: <number>**
**Test Categories:**
- Unit tests: <number>
- Integration tests: <number>
- Edge case tests: <number>
- Error handling tests: <number>

**To run tests:**
```bash
# If Poetry is installed and pyproject.toml exists:
poetry run pytest -v
poetry run pytest tests/test_<module_name>.py -v
poetry run pytest --cov=<module_name> tests/

# Otherwise:
pytest -v
pytest tests/test_<module_name>.py -v
pytest --cov=<module_name> tests/
```

**Next Steps:**
1. Review generated test files
2. Adjust test data and expected values
3. Run tests to verify they pass
4. Add any missing scenarios
```

## Scenario Generation Rules

### Happy Path Tests
- Use realistic, valid inputs
- Verify expected outputs
- Test common use cases
- Include multiple valid input combinations

### Edge Case Tests
- Test boundary values (0, 1, -1, max, min)
- Empty strings, empty lists, empty dictionaries
- None values
- Single-character strings, single-item lists
- Maximum/minimum allowed values

### Error Handling Tests
- Invalid data types
- Out of range values
- Missing required parameters
- Invalid file paths or URLs
- Network errors (for I/O operations)
- Permission errors (for file operations)

### Performance Tests
- Large input sizes
- Multiple iterations
- Time complexity checks
- Memory usage (if applicable)

### Integration Tests
- Multiple functions working together
- Class interactions
- Module dependencies
- External API calls (with mocking)

## Examples

### Example 1: Simple Function
**Input Code:**
```python
def calculate_discount(price, discount_percent):
    if discount_percent < 0 or discount_percent > 100:
        raise ValueError("Discount must be between 0 and 100")
    if price < 0:
        raise ValueError("Price cannot be negative")
    return price * (1 - discount_percent / 100)
```

**Generated Scenarios:**
```
1. Happy path: Valid price and discount
2. Edge case: 0% discount
3. Edge case: 100% discount
4. Error case: Negative discount (-10%)
5. Error case: Discount > 100 (150%)
6. Error case: Negative price
7. Boundary: Large price value
8. Boundary: Decimal discount (12.5%)
```

**Generated Test File:**
```python
import pytest
from discount_module import calculate_discount


def test_calculate_discount_happy_path():
    """Test normal discount calculation"""
    result = calculate_discount(100, 20)
    assert result == 80.0


def test_calculate_discount_zero_percent():
    """Test zero discount"""
    result = calculate_discount(100, 0)
    assert result == 100.0


def test_calculate_discount_full_discount():
    """Test 100% discount"""
    result = calculate_discount(100, 100)
    assert result == 0.0


@pytest.mark.parametrize("discount,expected", [
    (12.5, 87.5),
    (33.33, 66.67),
])
def test_calculate_discount_decimal_discount(discount, expected):
    """Test decimal discount values"""
    result = calculate_discount(100, discount)
    assert abs(result - expected) < 0.01


def test_calculate_discount_negative_discount():
    """Test negative discount raises error"""
    with pytest.raises(ValueError, match="Discount must be"):
        calculate_discount(100, -10)


def test_calculate_discount_excessive_discount():
    """Test discount > 100 raises error"""
    with pytest.raises(ValueError, match="Discount must be"):
        calculate_discount(100, 150)


def test_calculate_discount_negative_price():
    """Test negative price raises error"""
    with pytest.raises(ValueError, match="Price cannot be negative"):
        calculate_discount(-100, 20)
```

### Example 2: Class with Methods
**Input Code:**
```python
class User:
    def __init__(self, username, email):
        self.username = username
        self.email = email
        self.is_active = False
    
    def activate(self):
        self.is_active = True
    
    def deactivate(self):
        self.is_active = False
    
    def update_email(self, new_email):
        if "@" not in new_email:
            raise ValueError("Invalid email format")
        self.email = new_email
```

**Generated Scenarios:**
```
1. Initialization: Valid username and email
2. Initialization: Empty username
3. Method: activate() sets is_active to True
4. Method: deactivate() sets is_active to False
5. Method: update_email() with valid email
6. Error: update_email() with invalid email (missing @)
7. State: Multiple activation/deactivation cycles
```

**Generated Test File:**
```python
import pytest
from user_module import User


@pytest.fixture
def user():
    """Create a test user instance"""
    return User("testuser", "test@example.com")


def test_user_initialization():
    """Test user initializes correctly"""
    user = User("testuser", "test@example.com")
    assert user.username == "testuser"
    assert user.email == "test@example.com"
    assert user.is_active is False


def test_user_initialization_empty_username(user):
    """Test user with empty username"""
    user = User("", "test@example.com")
    assert user.username == ""


def test_user_activate(user):
    """Test user activation"""
    user.activate()
    assert user.is_active is True


def test_user_deactivate(user):
    """Test user deactivation"""
    user.activate()
    user.deactivate()
    assert user.is_active is False


def test_user_update_email_valid(user):
    """Test email update with valid email"""
    user.update_email("newemail@example.com")
    assert user.email == "newemail@example.com"


def test_user_update_email_invalid(user):
    """Test email update with invalid format"""
    with pytest.raises(ValueError, match="Invalid email format"):
        user.update_email("invalidemail")


def test_user_activation_cycle(user):
    """Test multiple activation/deactivation cycles"""
    assert user.is_active is False
    user.activate()
    assert user.is_active is True
    user.deactivate()
    assert user.is_active is False
    user.activate()
    assert user.is_active is True
```

### Example 3: Async Function
**Input Code:**
```python
import asyncio

async def fetch_data(url, timeout=30):
    await asyncio.sleep(1)
    if timeout < 1:
        raise ValueError("Timeout must be at least 1 second")
    return {"status": "success", "data": "sample"}
```

**Generated Scenarios:**
```
1. Happy path: Valid URL and default timeout
2. Edge case: Minimum timeout (1 second)
3. Error case: Timeout < 1
4. Error case: Invalid URL
```

**Generated Test File:**
```python
import pytest
from data_module import fetch_data


@pytest.mark.asyncio
async def test_fetch_data_happy_path():
    """Test successful data fetch"""
    result = await fetch_data("https://api.example.com/data")
    assert result["status"] == "success"
    assert "data" in result


@pytest.mark.asyncio
async def test_fetch_data_minimum_timeout():
    """Test fetch with minimum timeout"""
    result = await fetch_data("https://api.example.com/data", timeout=1)
    assert result["status"] == "success"


@pytest.mark.asyncio
async def test_fetch_data_invalid_timeout():
    """Test fetch with invalid timeout"""
    with pytest.raises(ValueError, match="Timeout must be"):
        await fetch_data("https://api.example.com/data", timeout=0)


@pytest.mark.asyncio
async def test_fetch_data_concurrent():
    """Test multiple concurrent fetches"""
    results = await asyncio.gather(
        fetch_data("https://api.example.com/data1"),
        fetch_data("https://api.example.com/data2"),
        fetch_data("https://api.example.com/data3"),
    )
    assert len(results) == 3
    assert all(r["status"] == "success" for r in results)
```

## Best Practices

- **Test Organization**: Keep test files in a `tests/` directory
- **Naming**: Use `test_<module_name>.py` format for test files
- **Fixtures**: Use pytest fixtures for common test setup
- **Parametrize**: Use `@pytest.mark.parametrize` for similar test cases
- **Clear Messages**: Add descriptive messages to assertions
- **Isolation**: Each test should be independent and can run alone
- **Coverage**: Aim for 80%+ code coverage
- **Fast Tests**: Keep unit tests fast (< 0.1s each)
- **Readable**: Test names should describe what is being tested
- **Arrange-Act-Assert**: Structure tests in AAA pattern

## Common Issues

### Poetry Not Installed
**Issue**: `poetry run pytest` command not found

**Solution**: Use `pytest` directly instead, or install Poetry:
```bash
# Use pytest directly
pytest tests/

# Or install Poetry
curl -sSL https://install.python-poetry.org | python3 -
```

### Pytest Not Configured
**Issue**: Tests not discovered by pytest

**Solution**: Ensure pytest is in `pyproject.toml` or `requirements.txt`:

In `pyproject.toml`:
```toml
[tool.poetry.dev-dependencies]
pytest = "^7.0.0"
```

In `requirements.txt`:
```
pytest>=7.0.0
```

### Import Errors
**Issue**: Cannot import module to test

**Solution**: Add source directory to Python path or use `src/` layout:
```bash
# Add source to PYTHONPATH
export PYTHONPATH="${PYTHONPATH}:$(pwd)"

# Or install in development mode
pip install -e .
```

### Async Tests Not Running
**Issue**: Async tests are collected but not executed

**Solution**: Install pytest-asyncio:

With Poetry:
```bash
poetry add --group dev pytest-asyncio
```

With pip:
```bash
pip install pytest-asyncio
```

### Missing Fixtures
**Issue**: Tests fail due to undefined fixtures

**Solution**: Define fixtures in `conftest.py` or in the test file

### Test Data Issues
**Issue**: Tests fail due to incorrect expected values

**Solution**: Review generated test data and update expected values based on actual behavior

## Troubleshooting Checklist

Before generating tests:
- [ ] Python source files exist and are syntactically correct
- [ ] `pyproject.toml` or `requirements.txt` exists
- [ ] Pytest is installed as a dev dependency
- [ ] Poetry is installed (if using pyproject.toml)
- [ ] Project structure follows Python conventions

After generating tests:
- [ ] Test files are created in `tests/` directory
- [ ] Test files follow `test_*.py` naming convention
- [ ] All imports are correct and resolve
- [ ] Fixtures are properly defined
- [ ] Tests are discoverable: `[poetry run] pytest --collect-only`
- [ ] Tests can be executed: `[poetry run] pytest -v`
- [ ] No syntax errors in test files
- [ ] Test coverage is adequate

## Related Commands

```bash
# Install dependencies
# With Poetry:
poetry install

# With pip:
pip install -r requirements.txt

# Run all tests
# With Poetry:
poetry run pytest -v

# With pip:
pytest -v

# Run specific test file
# With Poetry:
poetry run pytest tests/test_module.py -v

# With pip:
pytest tests/test_module.py -v

# Run specific test function
# With Poetry:
poetry run pytest tests/test_module.py::test_function_name -v

# With pip:
pytest tests/test_module.py::test_function_name -v

# Run with coverage
# With Poetry:
poetry run pytest --cov=module_name --cov-report=html

# With pip:
pytest --cov=module_name --cov-report=html

# Run only failed tests
# With Poetry:
poetry run pytest --lf

# With pip:
pytest --lf

# Run only tests marked as slow
# With Poetry:
poetry run pytest -m slow

# With pip:
pytest -m slow

# Show detailed output
# With Poetry:
poetry run pytest -v -s

# With pip:
pytest -v -s

# Stop on first failure
# With Poetry:
poetry run pytest -x

# With pip:
pytest -x

# Run tests in parallel
# With Poetry:
poetry run pytest -n auto

# With pip:
pytest -n auto

# Check test collection without running
# With Poetry:
poetry run pytest --collect-only

# With pip:
pytest --collect-only
```

## Test File Template

```python
"""
Test suite for <module_name>.py
Generated by python-pytest-creator skill
"""

import pytest
from <module_path> import <function_name>, <ClassName>


@pytest.fixture
def sample_instance():
    """Create a sample instance for testing"""
    return ClassName(param1, param2)


@pytest.fixture
def sample_data():
    """Provide sample test data"""
    return {
        "key1": "value1",
        "key2": "value2",
    }


# Happy path tests
def test_<function_name>_happy_path():
    """
    Test that <function_name> works correctly with valid inputs
    """
    result = <function_name>(param1, param2)
    assert result == expected_value


# Edge case tests
def test_<function_name>_edge_case():
    """
    Test that <function_name> handles edge cases
    """
    result = <function_name>(edge_case_input)
    assert result == expected_value


# Error handling tests
def test_<function_name>_error_case():
    """
    Test that <function_name> raises appropriate errors
    """
    with pytest.raises(ValueError):
        <function_name>(invalid_input)


# Parametrized tests
@pytest.mark.parametrize("input,expected", [
    (1, "one"),
    (2, "two"),
    (3, "three"),
])
def test_<function_name>_parametrized(input, expected):
    """
    Test <function_name> with multiple inputs
    """
    result = <function_name>(input)
    assert result == expected
```

## Related Skills

- `python-ruff-linter`: For ensuring code quality before testing
- `opencode-skill-creation`: For creating additional Python-related skills
