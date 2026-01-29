---
name: docstring-generator
description: Generate language-specific docstrings for C#, Java, Python, and TypeScript following industry standards (PEP 257, Javadoc, JSDoc, XML documentation)
license: Apache-2.0
compatibility: opencode
metadata:
  audience: developers
  workflow: documentation
---

## What I do

I generate language-specific docstrings following industry standards:

- **Detect Language**: Analyze file extension and project structure
- **Detect Docstring Style**: Identify existing conventions in codebase
- **Generate Docstrings**: Create appropriate docstrings following language conventions
- **Support Multiple Formats**: Python (PEP 257), Java (Javadoc), TypeScript (JSDoc/TSDoc), C# (XML documentation)
- **Handle Various Types**: Functions, methods, classes, interfaces, properties, exceptions

## When to use me

Use when:
- Implementing new functions, classes, or methods in Python, Java, TypeScript, or C#
- Refactoring code and updating documentation
- Creating new APIs or public interfaces
- Following documentation best practices and industry standards
- Ensuring all public code has proper docstrings

**Integration**: Integrates with `pr-creation-workflow` and `linting-workflow` to enforce docstring presence in quality checks.

## Prerequisites

- Source code files (.py, .java, .ts, .tsx, .cs, .csx)
- File permissions to read and write files
- Knowledge of preferred docstring style (optional, can auto-detect)
- For workflow integration: Git repository initialized

## Supported Languages

### Python
**Standard**: PEP 257 compliant
**Styles**: Google (recommended), NumPy, Sphinx/reST
**Features**: Type hints, exception documentation, examples

### Java
**Standard**: Javadoc format
**Tags**: @param, @return, @throws, @see, @since, @deprecated, @link
**Features**: Generic types, method overloads, interfaces

### TypeScript
**Standard**: JSDoc/TSDoc format
**Tags**: @param, @returns, @throws, @type, @example, @deprecated
**Features**: Generic types, union types, optional parameters

### C#
**Standard**: XML documentation comments
**Tags**: <summary>, <param>, <returns>, <exception>, <remarks>, <example>
**Features**: Generic types, method overloads, properties

## Steps

### Step 1: Detect Language and Style

```bash
# Detect language from file extension
case "$file_ext" in
    py)    LANG="python" ;;
    java)   LANG="java" ;;
    ts|tsx) LANG="typescript" ;;
    cs|csx) LANG="csharp" ;;
esac

# Detect Python style
if [[ "$LANG" == "python" ]]; then
    if grep -q 'Args:' file.py; then STYLE="google"
    elif grep -q 'Parameters' file.py; then STYLE="numpy"
    elif grep -q ':param' file.py; then STYLE="sphinx"
    fi
fi
```

### Step 2: Analyze Function Signature

Extract function signature and determine docstring components:

```bash
# Extract function/method signature
if [[ "$LANG" == "python" ]]; then
    FUNCTION=$(grep -A 5 'def ' file.py | head -1)
elif [[ "$LANG" == "java" ]]; then
    METHOD=$(grep -B 2 'public.*(' file.java | head -1)
fi
```

### Step 3: Generate Docstring

Generate appropriate docstring based on language:

#### Python (Google Style)
```python
def calculate_sum(a: int, b: int) -> int:
    """Calculate sum of two integers.

    Args:
        a: First integer to add.
        b: Second integer to add.

    Returns:
        Sum of a and b.

    Raises:
        TypeError: If either a or b is not an integer.
    """
    return a + b
```

#### Java (Javadoc)
```java
/**
 * Calculates sum of two integers.
 *
 * @param a First integer to add
 * @param b Second integer to add
 * @return Sum of a and b
 * @throws IllegalArgumentException If inputs are invalid
 */
public int calculateSum(int a, int b) {
    return a + b;
}
```

#### TypeScript (JSDoc)
```typescript
/**
 * Calculates sum of two integers.
 *
 * @param a - First integer to add
 * @param b - Second integer to add
 * @returns Sum of a and b
 * @throws {TypeError} If inputs are invalid
 */
function calculateSum(a: number, b: number): number {
    return a + b;
}
```

#### C# (XML Documentation)
```csharp
/// <summary>
/// Calculates sum of two integers.
/// </summary>
/// <param name="a">First integer to add</param>
/// <param name="b">Second integer to add</param>
/// <returns>Sum of a and b</returns>
/// <exception cref="System.ArgumentException">
/// Thrown when inputs are invalid
/// </exception>
public int CalculateSum(int a, int b) {
    return a + b;
}
```

### Step 4: Handle Special Cases

#### Generics
**Java**:
```java
/**
 * @param <T> Type of items in list
 * @param items List of items to process
 * @return Processed list
 */
public <T> List<T> processItems(List<T> items) { }
```

**TypeScript**:
```typescript
/**
 * @type T - Type of items in array
 * @param items - Array of items
 * @returns Processed array
 */
function processItems<T>(items: T[]): T[] { }
```

**C#**:
```csharp
/// <typeparam name="T">Type of items in list</typeparam>
/// <param name="items">List of items</param>
/// <returns>Processed list</returns>
public List<T> ProcessItems<T>(List<T> items) { }
```

#### Type Hints
**Python**:
```python
def process_data(
    data: list[dict[str, Any]],
    options: dict[str, Any] | None = None
) -> dict[str, list[Any]]:
    """Process data with optional configuration.

    Args:
        data: List of data entries.
        options: Optional configuration.

    Returns:
        Dictionary with processed data.
    """
```

### Step 5: Insert Docstring

Insert docstring at correct location:

```bash
# Find function/method line
LINE_NUM=$(grep -n "^def\|^public.*(" "$FILE" | head -1 | cut -d: -f1)

# Insert after signature
sed -i "$((LINE_NUM+1))i\\$DOCSTRING" "$FILE"
```

## Best Practices

### General

- Document all public APIs (functions, classes, methods, properties)
- Use clear language - explain to another developer
- Keep descriptions concise but thorough
- Follow existing style in codebase
- Include examples for typical usage
- Document edge cases (null, empty, invalid inputs)
- Update docstrings with code changes
- Document all exceptions

### Python-Specific

- Use triple quotes (`"""`)
- Place docstring immediately after definition
- Include type hints in signatures
- Use Google style by default
- Document all parameters, including optional ones

### Java-Specific

- Use `/** ... */` format
- Place docstring before method/class
- Document all @param tags
- Include @throws for checked exceptions
- Document generics with `<T>` notation
- Add @see for related methods

### TypeScript-Specific

- Use `/** ... */` format
- Place docstring before function/class
- Include type information in @param
- Use @throws with {Type}
- Document exported members
- Include @example blocks

### C#-Specific

- Use `///` for single-line, `/** ... */` for multi-line
- Place docstring before element
- Use XML tags for structure
- Escape special characters (`<` → `&lt;`)
- Document generics with <typeparam>

## Common Issues

### Python: Indentation Errors

**Issue**: Docstring indentation doesn't match code

**Solution**:
```python
def function():
    """Docstring at same indent as code."""
    pass
```

### Java: Missing @param Tags

**Issue**: Javadoc warnings about missing parameters

**Solution**: Document all parameters, even if obvious
```java
/**
 * Method description.
 *
 * @param x First parameter
 * @param y Second parameter
 */
public void method(int x, int y) { }
```

### TypeScript: Missing Type in @throws

**Issue**: Type safety lost without exception type

**Solution**: Always include type
```typescript
/**
 * @throws {Error} When something goes wrong
 */
```

### C#: XML Escaping Issues

**Issue**: Special characters break XML

**Solution**: Use HTML entities
```csharp
/// Method with &lt;special&gt; characters
```

## Workflow Integration

### PR Creation

Check for missing docstrings:
```bash
# Find undocumented functions
for file in $(git diff --name-only); do
    case "$file" in
        *.py) UNDOC=$(grep -c 'def ' "$file") - $(grep -c '"""' "$file") ;;
        *.java) UNDOC=$(grep -c 'public.*(' "$file") - $(grep -c '/\*\*' "$file") ;;
        *.ts) UNDOC=$(grep -c 'function' "$file") - $(grep -c '/\*\*' "$file") ;;
        *.cs) UNDOC=$(grep -c 'public.*(' "$file") - $(grep -c '///' "$file") ;;
    esac
    if [[ $UNDOC -gt 0 ]]; then
        echo "Found $UNDOC undocumented items in $file"
    fi
done
```

### Linting Integration

**Python**:
```bash
pydocstyle file.py
```

**Java**:
```bash
checkstyle -c checkstyle_javadoc.xml file.java
```

**TypeScript**:
```bash
tslint --doc file.ts
```

## Code Review Checklist

- [ ] All public functions have docstrings
- [ ] All public classes have docstrings
- [ ] All parameters are documented
- [ ] Return values are documented
- [ ] Exceptions are documented
- [ ] Docstrings follow language conventions
- [ ] Docstrings are accurate and up-to-date

## References

- **PEP 257**: https://peps.python.org/pep-0257/
- **Javadoc Guide**: https://www.oracle.com/java/technologies/javase/javadoc-tool.html
- **JSDoc Guide**: https://jsdoc.app/
- **C# XML Documentation**: https://learn.microsoft.com/en-us/dotnet/csharp/programming-guide/xmldoc/
