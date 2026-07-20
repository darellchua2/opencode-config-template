---
name: java-linter-skill
description: Ensure Java code follows industry standards using Checkstyle, PMD, and SpotBugs with linting-workflow framework
license: Apache-2.0
compatibility: opencode
metadata:
  audience: developers
  workflow: code-quality
  languages: java
---

## What I do

I implement Java-specific linting by extending the `linting-workflow` framework:

1. **Detect Java Environment**: Identify Java project (Maven, Gradle, or plain)
2. **Detect Linter Tooling**: Check for Checkstyle, PMD, SpotBugs, `.editorconfig`
3. **Delegate to Linting Workflow**: Use `linting-workflow` for core linting functionality
4. **Provide Java-Specific Guidance**: Help interpret Checkstyle messages, PMD violations, SpotBugs bug categories
5. **Ensure Java Coding Conventions**: Guide on Java style standards (Google Java Style, Oracle conventions)

## When to use me

Use this workflow when:
- Writing or modifying Java code that needs to follow industry standards
- Before committing Java changes to ensure code quality
- When you see Checkstyle/PMD/SpotBugs violations and need help fixing them
- Setting up a new Java project with proper linting configuration
- You want to ensure code quality in automated workflows

**Framework**: This skill extends `linting-workflow` for generic linting, adding Java-specific Checkstyle/PMD/SpotBugs guidance.

## Steps

### Step 1: Detect Java Environment

Verify this is a Java project:
```bash
# Check for Java files
ls *.java 2>/dev/null

# Check for Maven
[ -f pom.xml ]

# Check for Gradle
[ -f build.gradle ] || [ -f build.gradle.kts ]

# Check Java version
java -version 2>&1 | head -1
```

### Step 2: Detect Linter Configuration

Check for linting tools:
```bash
# Checkstyle (style conventions)
grep -q "checkstyle" pom.xml 2>/dev/null || grep -q "checkstyle" build.gradle 2>/dev/null

# PMD (code analysis)
grep -q "pmd" pom.xml 2>/dev/null || grep -q "pmd" build.gradle 2>/dev/null

# SpotBugs (bug detection)
grep -q "spotbugs" pom.xml 2>/dev/null || grep -q "spotbugs" build.gradle 2>/dev/null

# .editorconfig (general style)
[ -f .editorconfig ]
```

### Step 3: Check for Build Tools

Check if Maven or Gradle is installed:
```bash
mvn --version 2>/dev/null
gradle --version 2>/dev/null
```

### Step 4: Delegate to Linting Workflow

Use `linting-workflow` framework for:
- Language detection (Java)
- Linter detection (Checkstyle / PMD / SpotBugs)
- Package manager detection (Maven / Gradle)
- Running linting with appropriate commands
- Auto-fix application (limited for Java — most violations need manual fixes)
- Error resolution guidance
- Verification and re-running

### Step 5: Java-Specific Linter Guidance

**Common Checkstyle Violations**:

| Rule | Description | Common Fix |
|------|-------------|-----------|
| `FileLength` | File exceeds max lines | Split into smaller classes |
| `LineLength` | Line exceeds 120/140 chars | Break into multiple lines |
| `MethodLength` | Method exceeds 150 lines | Extract methods |
| `ParameterNumber` | Method has too many params | Use parameter object |
| `UnusedImports` | Import statement not used | Remove import |
| `Indentation` | Incorrect indentation | Match project indentation level |
| `JavadocMethod` | Missing Javadoc on public method | Add `/** */` documentation |
| `FinalParameters` | Parameter should be final | Add `final` modifier |
| `EmptyBlock` | Empty code block `{}` | Add implementation or comment |
| `MagicNumber` | Unexplained numeric literal | Extract to named constant |

**Common PMD Violations**:

| Rule | Category | Description | Common Fix |
|------|----------|-------------|-----------|
| `UnusedLocalVariable` | Unused code | Remove variable |
| `GodClass` | Design | Class is too complex | Split responsibilities |
| `ExcessiveMethodLength` | Design | Method too long | Extract methods |
| `NPathComplexity` | Complexity | Too many branches | Simplify / refactor |
| `AvoidDeeplyNestedIfStmts` | Complexity | Deeply nested if statements | Use guard clauses or polymorphism |
| `ConsecutiveAppendsShouldReuse` | Performance | StringBuilder append chain | Chain `.append()` calls |
| `AvoidInstantiatingObjectsInLoops` | Performance | Object creation in loop | Move outside loop or use pool |
| `EmptyCatchBlock` | Error handling | Empty catch block | Log or rethrow exception |

**Common SpotBugs Bug Categories**:

| Pattern | Category | Description | Common Fix |
|---------|----------|-------------|-----------|
| `NP_NULL_*` | Correctness | Null pointer dereference | Add null-check |
| `EI_EXPOSE_REP*` | Malicious code | Exposes internal representation | Return defensive copy |
| `MS_*` | Malicious code | Mutable static field | Make final or use unmodifiable |
| `RCN_*` | Correctness | Redundant null-check | Simplify |
| `SBSC_USE_STRINGBUFFER` | Performance | String concatenation in loop | Use StringBuilder |
| `DM_STRING_CTOR` | Performance | Unnecessary String constructor | Use string literal |
| `EI2_*` | Bad practice | Storing reference to external object | Store defensive copy |

**Error Resolution Template**:
```
For each violation found:

1. **File**: <file>
   Line: <line>
   Error: <message>
   Tool: <Checkstyle | PMD | SpotBugs>
   Rule: <rule name>

2. **Rule Explanation**:
   - Severity: Error | Warning | Info
   - Category: Style | Design | Performance | Correctness | Security
   - Is the rule project-specific (in checkstyle.xml / pmd-rules.xml)?

3. **Fix Action**:
   - Auto-fixable? Run Maven/Gradle spotless or formatter plugin
   - Manual fix needed? See rule documentation
   - Suppress if false positive? Use `@SuppressWarnings("RuleName")` sparingly
```

### Step 6: Common Configuration

**Maven (pom.xml)**:
```xml
<build>
  <plugins>
    <plugin>
      <groupId>org.apache.maven.plugins</groupId>
      <artifactId>maven-checkstyle-plugin</artifactId>
      <version>3.5.0</version>
      <configuration>
        <configLocation>google_checks.xml</configLocation>
        <failOnViolation>true</failOnViolation>
      </configuration>
    </plugin>
    <plugin>
      <groupId>org.apache.maven.plugins</groupId>
      <artifactId>maven-pmd-plugin</artifactId>
      <version>3.24.0</version>
      <configuration>
        <rulesets>
          <ruleset>/rulesets/java/quickstart.xml</ruleset>
        </rulesets>
      </configuration>
    </plugin>
    <plugin>
      <groupId>com.github.spotbugs</groupId>
      <artifactId>spotbugs-maven-plugin</artifactId>
      <version>4.8.6.0</version>
    </plugin>
  </plugins>
</build>
```

**Gradle (build.gradle)**:
```groovy
plugins {
    id 'checkstyle'
    id 'pmd'
    id 'com.github.spotbugs' version '6.0.18'
}

checkstyle {
    toolVersion = '10.17.0'
    config = resources.text.fromFile('config/checkstyle/checkstyle.xml')
}

pmd {
    toolVersion = '7.3.0'
    ruleSetFiles = files('config/pmd/pmd-rules.xml')
}

spotbugs {
    effort = 'max'
    reportLevel = 'medium'
}
```

## Auto-Fix Commands

Java linting has limited auto-fix (most violations require manual code changes). Use these for formatting:

```bash
# Maven — run all linters
mvn checkstyle:check pmd:check spotbugs:check

# Maven — spotless formatter (if configured)
mvn spotless:apply

# Gradle — run all linters
./gradlew checkstyleMain pmdMain spotbugsMain

# Gradle — spotless formatter (if configured)
./gradlew spotlessApply

# Google Java Format (standalone)
java -jar google-java-format.jar --replace $(find . -name "*.java")
```

## Verification

After applying fixes:
```bash
# Maven — verify all linters pass
mvn checkstyle:check pmd:check spotbugs:check

# Gradle — verify all linters pass
./gradlew checkstyleMain pmdMain spotbugsMain

# Build should succeed
mvn clean install
# or
./gradlew clean build
```

## References

- [Google Java Style Guide](https://google.github.io/styleguide/javaguide.html)
- [Checkstyle documentation](https://checkstyle.sourceforge.io/)
- [PMD rules index](https://docs.pmd-code.org/pmd-doc-7.x/pmd_rules_java.html)
- [SpotBugs bug descriptions](https://spotbugs.readthedocs.io/en/stable/bugDescriptions.html)
- [Google Java Format](https://github.com/google/google-java-format)
- Framework: `linting-workflow-skill`
