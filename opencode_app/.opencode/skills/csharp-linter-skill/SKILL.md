---
name: csharp-linter-skill
description: Ensure C# code follows industry standards using dotnet format, Roslyn analyzers, and StyleCop with linting-workflow framework
license: Apache-2.0
compatibility: opencode
metadata:
  audience: developers
  workflow: code-quality
  languages: csharp, dotnet
---

## What I do

I implement C#-specific linting by extending the `linting-workflow` framework:

1. **Detect .NET Environment**: Identify .NET/C# project (SDK version, project style)
2. **Detect Linter Tooling**: Check for `dotnet format`, Roslyn analyzers, StyleCop, `.editorconfig`
3. **Delegate to Linting Workflow**: Use `linting-workflow` for core linting functionality
4. **Provide C#-Specific Guidance**: Help interpret analyzer diagnostics (CAxxxx, SAxxxx, IDExxxx)
5. **Ensure .NET Coding Conventions**: Guide on C# style standards and framework design guidelines

## When to use me

Use this workflow when:
- Writing or modifying C# code that needs to follow industry standards
- Before committing C# changes to ensure code quality
- When you see Roslyn analyzer or StyleCop warnings and need help fixing them
- Setting up a new .NET project with proper linting configuration
- You want to ensure code quality in automated workflows

**Framework**: This skill extends `linting-workflow` for generic linting, adding C#-specific `dotnet format` and analyzer guidance.

## Steps

### Step 1: Detect .NET Environment

Verify this is a C#/.NET project:
```bash
# Check for C# files
ls *.cs 2>/dev/null

# Check for .NET project files
[ -f *.csproj ] || [ -f *.sln ] || [ -f Directory.Build.props ]

# Check .NET SDK version
dotnet --version 2>/dev/null
```

### Step 2: Detect Linter Configuration

Check for linting tools:
```bash
# dotnet format (built into .NET 6+ SDK)
dotnet format --verify-no-changes --dry-run 2>/dev/null

# .editorconfig (drives dotnet format + Roslyn analyzers)
[ -f .editorconfig ]

# StyleCop analyzers (NuGet package reference)
grep -q "StyleCop.Analyzers" *.csproj 2>/dev/null

# Roslyn analyzers (CAxxxx rules)
grep -q "AnalysisLevel" *.csproj 2>/dev/null
```

### Step 3: Check for Build Tools

Check if .NET SDK is installed:
```bash
dotnet --version 2>/dev/null
```

### Step 4: Delegate to Linting Workflow

Use `linting-workflow` framework for:
- Language detection (C#)
- Linter detection (dotnet format / Roslyn / StyleCop)
- Package manager detection (NuGet / Paket)
- Running linting with appropriate commands
- Auto-fix application (`dotnet format`)
- Error resolution guidance
- Verification and re-running

### Step 5: C#-Specific Analyzer Guidance

**Common Diagnostic IDs**:

| Diagnostic ID | Source | Description | Common Fix |
|---------------|--------|-------------|-----------|
| CA1062 | Roslyn | Validate arguments of public methods | Add null-check parameter validation |
| CA1822 | Roslyn | Mark members as static | Add `static` modifier |
| CA2007 | Roslyn | Consider configuring await | Add `ConfigureAwait(false)` |
| CA1063 | Roslyn | Implement IDisposable correctly | Follow standard dispose pattern |
| CA1031 | Roslyn | Do not catch general exception types | Catch specific exception types |
| SA1101 | StyleCop | Prefix local calls with `this.` | Add `this.` qualifier |
| SA1127 | StyleCop | Use generic constraint syntax | Use `where T : class` syntax |
| SA1200 | StyleCop | Using directive must be placed correctly | Move `using` inside/outside namespace |
| SA1600 | StyleCop | Elements must be documented | Add XML documentation comments |
| IDE0058 | IDE | Expression value is never used | Use discard `_` or assign to variable |
| IDE0090 | IDE | Use `new(...)` target-typed | Use target-typed `new()` |
| CS0168 | Compiler | Variable declared but never used | Remove unused variable |
| CS0219 | Compiler | Variable assigned but never used | Remove or use variable |

**Error Resolution Template**:
```
For each analyzer diagnostic found:

1. **File**: <file>
   Line: <line>
   Error: <message>
   Code: <CAxxxx | SAxxxx | IDExxxx | CSxxxx>

2. **Rule Explanation**:
   - Severity: Error | Warning | Info | Hidden
   - Category: Usage | Design | Performance | Style | Naming
   - Is the rule project-specific (in .editorconfig or .ruleset)?

3. **Fix Action**:
   - Auto-fixable? Run `dotnet format` to apply
   - Manual fix needed? See rule documentation
   - Suppress if false positive? Use `[SuppressMessage(...)]` sparingly
```

### Step 6: Common .editorconfig Settings

Generate or verify `.editorconfig`:
```ini
[*.cs]
# .NET coding conventions
dotnet_sort_system_directives_first = true
dotnet_separate_import_directive_groups = false

# C# coding conventions
csharp_new_line_before_open_brace = all
csharp_new_line_before_else = true
csharp_new_line_before_catch = true
csharp_new_line_before_finally = true
csharp_indent_braces = false

# Naming conventions
dotnet_naming_rule.private_fields_underscore.symbols = private_fields
dotnet_naming_rule.private_fields_underscore.style = underscore_capital
dotnet_naming_rule.private_fields_underscore.severity = warning

# Analyzer severity
dotnet_diagnostic.CA1822.severity = warning
dotnet_diagnostic.CA2007.severity = suggestion
```

## Auto-Fix Commands

```bash
# Fix all format issues (whitespace, braces, using directives)
dotnet format

# Fix only whitespace
dotnet format whitespace

# Fix only style (code style rules)
dotnet format style

# Dry-run (report issues without fixing)
dotnet format --verify-no-changes --dry-run

# Apply analyzer fixes (CAxxxx, IDExxxx)
dotnet format analyzers
```

## Verification

After applying fixes:
```bash
# Verify no remaining issues
dotnet format --verify-no-changes --dry-run

# Build should succeed without warnings
dotnet build -warnaserror
```

## References

- [.NET coding conventions](https://learn.microsoft.com/dotnet/fundamentals/code-analysis/style-rules/)
- [dotnet format documentation](https://learn.microsoft.com/dotnet/core/tools/dotnet-format)
- [StyleCop.Analyzers rules](https://github.com/DotNetAnalyzers/StyleCopAnalyzers)
- [Roslyn analyzer rules](https://learn.microsoft.com/dotnet/fundamentals/code-analysis/quality-rules/)
- Framework: `linting-workflow-skill`
