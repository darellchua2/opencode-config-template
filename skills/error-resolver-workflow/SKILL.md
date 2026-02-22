---
name: error-resolver-workflow
description: Diagnose and resolve errors, exceptions, and stack traces with intelligent analysis
license: Apache-2.0
compatibility: opencode
metadata:
  audience: developers
  workflow: debugging
  trigger: explicit-only
---

## What I do

I diagnose and help resolve errors, exceptions, and stack traces:
- Analyze error messages from various sources (runtime, compilation, tests)
- Parse stack traces to identify root causes
- Provide actionable solutions and fixes
- Handle error screenshots via MCP integration

## When to use me

**IMPORTANT**: This skill is ONLY triggered by EXPLICIT user invocation. I am NOT automatically triggered for general error handling.

Use when user explicitly requests:
- "use error resolver" / "error resolver" / "resolve this error"
- "fix this error" / "fix error" (when explicitly invoking the resolver)
- "diagnose this error" / "diagnose error"
- "analyze this exception" / "analyze error"

**Do NOT auto-trigger** for:
- General debugging without explicit request
- Automatic error detection during development
- Implicit error handling in other workflows

## Steps

### Step 1: Identify Error Source

**Error Types**:
| Type | Indicators | Common Sources |
|------|------------|----------------|
| Runtime | Exception, Error, crash | Application logs, terminal |
| Compilation | SyntaxError, TypeError | Build output, IDE |
| Test | AssertionError, pytest failures | Test runner output |
| Infrastructure | Connection refused, timeout | Server logs, cloud console |
| Screenshot | Visual error display | User-provided image |

### Step 2: Parse Error Information

**Extract Key Data**:
- Error type/class (e.g., `TypeError`, `NullPointerException`)
- Error message (the descriptive text)
- Stack trace (file paths, line numbers, function calls)
- Context (what operation triggered it)
- Environment (OS, runtime version, dependencies)

### Step 3: Analyze Root Cause

**Analysis Patterns**:

**Runtime Errors**:
- `TypeError: X is not a function` → Check if variable is correct type
- `ReferenceError: X is not defined` → Check variable scope/declaration
- `NullPointerException` → Check for null/undefined values
- `IndexError/IndexOutOfBounds` → Check array bounds

**Compilation Errors**:
- Syntax errors → Fix syntax at indicated line
- Type mismatches → Check type annotations
- Missing imports → Add required imports

**Test Failures**:
- Assertion failures → Check expected vs actual values
- Fixture errors → Check test setup/teardown
- Mock issues → Verify mock configuration

### Step 4: Provide Solution

**Solution Structure**:
1. **Summary**: One-line description of the issue
2. **Root Cause**: Why the error occurs
3. **Fix**: Step-by-step solution with code examples
4. **Prevention**: How to avoid this error in the future
5. **Related Issues**: Common related problems

### Step 5: Verify Fix

**Verification Steps**:
1. Apply suggested fix
2. Reproduce the original scenario
3. Confirm error is resolved
4. Run related tests if applicable

## MCP Tool Integration

### Error Screenshot Diagnosis

When user provides an error screenshot:
```
Use zai-mcp-server diagnose_error_screenshot:
- image_source: Path or URL to screenshot
- prompt: "Diagnose this error and provide solution"
- context: Optional context about when error occurred
```

### Text Extraction

For screenshots containing error text:
```
Use zai-mcp-server extract_text_from_screenshot:
- image_source: Path or URL to screenshot
- prompt: "Extract error message and stack trace"
- programming_language: Optional language hint
```

## Error Categories

### JavaScript/TypeScript
```
TypeError: Cannot read property 'X' of undefined
→ Check object exists before accessing property

SyntaxError: Unexpected token
→ Check for missing brackets, parentheses, commas

ReferenceError: X is not defined
→ Import or declare the variable
```

### Python
```
TypeError: 'NoneType' object is not subscriptable
→ Check for None before indexing

ModuleNotFoundError: No module named 'X'
→ Install missing package or fix import path

IndentationError: expected an indented block
→ Fix indentation (use consistent spaces/tabs)
```

### Infrastructure
```
ECONNREFUSED
→ Check if service is running, verify port/host

ETIMEDOUT
→ Check network connectivity, firewall rules

ENOENT: no such file or directory
→ Verify file path exists, check permissions
```

## Best Practices

- Always provide complete error messages
- Include relevant code context around the error
- Mention recent changes that might have caused the error
- Provide environment details (OS, versions, etc.)
- For screenshots, ensure error text is readable

## Delegation

When resolution requires:
- **Code changes**: Delegate to parent agent for implementation
- **File operations**: Delegate to parent agent (no write access)
- **System commands**: Delegate to parent agent (no bash access)

## Related Skills

- `image-analyzer`: General image analysis (includes error screenshots)
- `linting-workflow`: Fix linting-related errors
- `testing-subagent`: Fix test failures
- `opentofu-explorer-subagent`: Infrastructure error resolution
