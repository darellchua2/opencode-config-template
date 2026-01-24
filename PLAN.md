# Plan: Implement Docstring Generation Skill for Multiple Languages

## Overview
Create a specialized OpenCode skill for generating language-specific docstrings and documentation when implementing features. This skill should support C#, Java, Python, and TypeScript, ensuring developers add proper documentation alongside their code.

## Issue Reference
- Issue: #26
- URL: https://github.com/darellchua2/opencode-config-template/issues/26
- Labels: enhancement, documentation

## Files to Create
1. `skills/docstring-generator/SKILL.md` - Main skill definition
2. `skills/docstring-generator/examples/` - Example docstrings for each language
3. `skills/docstring-generator/templates/` - Docstring templates per language

## Approach

1. **Analyze Existing Skills**: Review `opencode-skill-creation` and documentation skills for patterns
2. **Define Skill Structure**: Create SKILL.md with proper frontmatter and documentation
3. **Implement Language Detection**: Create logic to detect language from file extension:
   - `.py` → Python
   - `.java` → Java
   - `.ts`, `.tsx` → TypeScript
   - `.cs`, `.csx` → C#
4. **Implement Docstring Generators**: Create logic for each language:
   - Python: PEP 257 (Google, NumPy, Sphinx styles)
   - Java: Javadoc format with @param, @return, @throws
   - TypeScript: JSDoc/TSDoc format with @param, @returns, @throws
   - C#: XML documentation with <summary>, <param>, <returns>, <exception>
5. **Add Examples**: Include comprehensive examples for each language and style
6. **Document Patterns**: Document docstring conventions and best practices

## Success Criteria
- [ ] SKILL.md follows the required frontmatter format
- [ ] Skill detects language from file extension correctly
- [ ] Skill supports Python docstrings (Google, NumPy, Sphinx styles)
- [ ] Skill supports Java Javadoc format
- [ ] Skill supports TypeScript JSDoc/TSDoc format
- [ ] Skill supports C# XML documentation comments
- [ ] Skill generates docstrings for functions, classes, methods, properties
- [ ] Skill includes examples for each language and style
- [ ] Skill documentation covers best practices
- [ ] All generated docstrings are syntactically valid
- [ ] Skill integrates with existing workflows (PR creation, code review)

## Language-Specific Requirements

### Python
- **PEP 257 compliant** docstrings
- **Multiple styles supported**:
  - Google style (most popular)
  - NumPy style (for scientific computing)
  - Sphinx/reST style (for documentation)
- **Type hints** included for Python 3.5+
- **Exception documentation** with Raises section

### Java
- **Javadoc format** with proper tags:
  - `@param` for parameters
  - `@return` or `@returns` for return values
  - `@throws` for exceptions
  - `@see` for related references
- **Generics support** for type parameters
- **Method overloads** documentation

### TypeScript
- **JSDoc/TSDoc format** with proper tags:
  - `@param` for parameters
  - `@returns` or `@return` for return values
  - `@throws` for exceptions
  - `@type` for type definitions
  - `@example` for usage examples
- **Generic support** for type parameters
- **Interface documentation** support

### C#
- **XML documentation comments** format:
  - `<summary>` for descriptions
  - `<param name="">` for parameters
  - `<returns>` for return values
  - `<exception cref="">` for exceptions
  - `<typeparam>` for generic types
- **Method overloads** documentation
- **XML escaping** for special characters

## Key Patterns to Implement

### Function/Method Docstrings
```python
def calculate_sum(a: int, b: int) -> int:
    """
    Calculate the sum of two integers.

    Args:
        a: First integer to add.
        b: Second integer to add.

    Returns:
        The sum of a and b.

    Raises:
        TypeError: If either a or b is not an integer.
    """
    return a + b
```

### Class/Interface Docstrings
```java
/**
 * Utility class for mathematical operations.
 *
 * @author Your Name
 * @version 1.0
 */
public class MathUtils {
    // Implementation
}
```

### Property/Field Docstrings
```csharp
/// <summary>
/// Gets or sets the user's email address.
/// </summary>
public string Email { get; set; }
```

### Exception Documentation
```typescript
/**
 * Custom error for invalid input.
 *
 * @extends Error
 */
export class ValidationError extends Error {
    // Implementation
}
```

## Docstring Styles Comparison

### Python Styles

**Google Style** (Recommended):
```python
def function_name(param1: type, param2: type) -> return_type:
    """
    Brief description.

    Detailed description of function.

    Args:
        param1: Description of param1.
        param2: Description of param2.

    Returns:
        Description of return value.

    Raises:
        ErrorType: When error occurs.
    """
```

**NumPy Style** (For scientific computing):
```python
def function_name(param1, param2):
    """
    Brief description.

    Extended description.

    Parameters
    ----------
    param1 : type
        Description of param1.
    param2 : type
        Description of param2.

    Returns
    -------
    return_type
        Description of return value.

    Raises
    ------
    ErrorType
        When error occurs.

    See Also
    --------
    related_function
    """
```

**Sphinx/reST Style** (For documentation):
```python
def function_name(param1, param2):
    """
    Brief description.

    Extended description.

    :param param1: Description of param1.
    :param param2: Description of param2.
    :type param1: type
    :type param2: type
    :returns: Description of return value.
    :rtype: return_type
    :raises ErrorType: When error occurs.
    """
```

## Advanced Features

### Type Hints
- **Python**: Type hints in function signatures
- **TypeScript**: Type annotations in JSDoc
- **Java**: Generic type parameters
- **C#: Generic type parameters with `<typeparam>`

### Overloads and Generics
- Document method overloads separately
- Document generic type parameters
- Show example usage with different types

### Cross-references
- Link to related functions/classes
- Use `@see` (Java), `@link` (C#)
- Markdown links in docstrings (Python, TypeScript)

### Examples
- Include code examples in docstrings
- Show typical usage patterns
- Demonstrate edge cases
- Keep examples up-to-date

## Best Practices

### Docstring Quality
- **Clarity**: Write docstrings as if explaining to another developer
- **Conciseness**: Be clear but not overly verbose
- **Accuracy**: Ensure docstrings match code behavior
- **Completeness**: Document all public APIs
- **Consistency**: Follow existing style in codebase

### Language-Specific Best Practices

**Python**:
- Use triple quotes (`"""`) for docstrings
- Place docstring immediately after function/class definition
- Include type hints in function signature
- Document exceptions that can be raised

**Java**:
- Use `/** ... */` for Javadoc
- Place docstring immediately before method/class
- Include all relevant tags (@param, @return, @throws, @see)
- Document generics with `<T>` notation

**TypeScript**:
- Use `/** ... */` for JSDoc
- Place docstring immediately before function/class
- Include type information in tags
- Document exported members with JSDoc

**C#**:
- Use `///` or `/** */` for documentation
- Place docstring immediately before element
- Use XML tags for structured documentation
- Document generics with `<typeparam>` tags

## Workflow Integration

### PR Creation
- Check for missing docstrings in changed files
- Generate docstrings for undocumented code
- Ask user confirmation before adding
- Include docstring coverage in PR description

### Code Review
- Validate docstring syntax
- Check for missing docstrings on public APIs
- Verify docstring accuracy
- Suggest improvements

### Linting
- Add docstring validation to linters
- Enforce docstring presence
- Check docstring format compliance
- Report coverage metrics

## Notes
- Focus on language-specific conventions
- Support multiple docstring styles per language (especially Python)
- Maintain compatibility with existing code styles
- Detect existing docstring style in codebase to match
- Handle special characters in XML documentation (C#)
- Support all common docstring generators
- Allow configuration per project/language
- Integrate with existing PR/workflow tools
