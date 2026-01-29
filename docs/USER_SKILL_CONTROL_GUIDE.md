# USER Level Skill Control Guide

This guide explains how to configure and control skills at the USER level in opencode-ai.

## Overview

opencode-ai supports USER level skill control, allowing you to:
- Enable or disable specific skills
- Set skill priorities for conflict resolution
- Define custom skills paths
- Control skill auto-loading and caching
- Configure skill categories

**Configuration File:** `~/.config/opencode/user/config.user.json`

---

## Skill Configuration Structure

```json
{
  "skills": {
    "enabled": ["*"],
    "disabled": [],
    "priorities": {},
    "customSkillsPath": "/path/to/custom/skills",
    "autoLoad": true,
    "cacheEnabled": true,
    "cacheDuration": 3600,
    "categories": {}
  }
}
```

---

## Enabling and Disabling Skills

### Enable All Skills

```json
{
  "skills": {
    "enabled": ["*"],
    "disabled": []
  }
}
```

### Enable Specific Skills

```json
{
  "skills": {
    "enabled": [
      "test-generator-framework",
      "python-pytest-creator",
      "linting-workflow",
      "python-ruff-linter"
    ],
    "disabled": []
  }
}
```

### Disable Specific Skills

```json
{
  "skills": {
    "enabled": ["*"],
    "disabled": [
      "deprecated-skill",
      "experimental-feature"
    ]
  }
}
```

### Use Glob Patterns

```json
{
  "skills": {
    "enabled": [
      "python-*",       // All Python skills
      "test-*",        // All testing skills
      "linting-*"      // All linting skills
    ],
    "disabled": [
      "*-experimental", // All experimental skills
      "deprecated-*"   // All deprecated skills
    ]
  }
}
```

---

## Skill Priorities

When multiple skills can handle a task, priority determines which is used. Higher priority skills override lower priority skills.

### Setting Priorities

```json
{
  "skills": {
    "priorities": {
      "git-workflow-framework": 10,
      "test-generator-framework": 9,
      "linting-workflow": 8,
      "pr-creation-workflow": 7,
      "jira-git-integration": 6,
      "issue-framework": 5,
      "documentation-framework": 4,
      "opentofu-framework": 3
    }
  }
}
```

### Priority Guidelines

| Priority | Usage | Example Skills |
|-----------|---------|---------------|
| 10 | Critical frameworks | git-workflow-framework, test-generator-framework |
| 9-7 | Common workflows | linting-workflow, pr-creation-workflow |
| 6-4 | Specialized frameworks | jira-git-integration, issue-framework |
| 3-1 | Optional features | opentofu-framework, documentation-framework |

---

## Custom Skills Path

Add your own custom skills directory that takes precedence over default skills.

### Configure Custom Path

```json
{
  "skills": {
    "customSkillsPath": "/home/user/opencode-custom-skills"
  }
}
```

### Custom Skills Structure

```
/home/user/opencode-custom-skills/
├── my-custom-test-generator/
│   └── SKILL.md
├── my-company-linter/
│   └── SKILL.md
└── my-workflow/
    └── SKILL.md
```

**Note:** Custom skills in this path override default skills with the same name.

---

## Skill Categories

Control entire categories of skills at once.

### Enable/Disable Categories

```json
{
  "skills": {
    "categories": {
      "framework": {
        "enabled": true,
        "skills": [
          "test-generator-framework",
          "linting-workflow",
          "pr-creation-workflow"
        ]
      },
      "language": {
        "enabled": true,
        "skills": [
          "python-pytest-creator",
          "python-ruff-linter",
          "javascript-eslint-linter"
        ]
      },
      "opentofu": {
        "enabled": false,
        "skills": [
          "opentofu-aws-explorer",
          "opentofu-kubernetes-explorer",
          "opentofu-neon-explorer"
        ]
      }
    }
  }
}
```

### Category Reference

| Category | Skills | Purpose |
|-----------|---------|---------|
| `framework` | 5 skills | Generic workflows and patterns |
| `language` | 3 skills | Language-specific test and linting |
| `framework-specific` | 4 skills | Next.js and TypeScript workflows |
| `opencode-meta` | 3 skills | Agent and skill creation |
| `opentofu` | 7 skills | Infrastructure as code |
| `git` | 6 skills | Git operations and workflows |
| `documentation` | 2 skills | Documentation generation |
| `jira` | 1 skill | JIRA integration |

---

## Skill Auto-Load and Caching

### Auto-Load

Control whether skills are automatically loaded on startup.

```json
{
  "skills": {
    "autoLoad": true
  }
}
```

- **true**: Load all skills at startup (default)
- **false**: Manually load skills when needed

**Use Cases:**
- **true**: Faster task execution, higher memory usage
- **false**: Lower memory usage, slower first execution

### Skill Caching

Cache loaded skills to reduce startup time.

```json
{
  "skills": {
    "cacheEnabled": true,
    "cacheDuration": 3600
  }
}
```

- **cacheEnabled**: Enable/disable skill caching (default: true)
- **cacheDuration**: Cache duration in seconds (default: 3600 = 1 hour)

**Use Cases:**
- **true**: Faster startup, skills may be outdated if changed
- **false**: Always load fresh skills, slower startup

---

## Configuration Examples

### Example 1: Python-Only Setup

```json
{
  "skills": {
    "enabled": [
      "python-*",
      "test-generator-framework",
      "linting-workflow"
    ],
    "disabled": [
      "javascript-*",
      "nextjs-*",
      "typescript-*",
      "opentofu-*",
      "jira-*"
    ],
    "priorities": {
      "test-generator-framework": 10,
      "linting-workflow": 9
    }
  }
}
```

### Example 2: Development-Only Setup

```json
{
  "skills": {
    "enabled": [
      "test-*",
      "lint-*",
      "git-*",
      "coverage-readme-workflow",
      "docstring-generator"
    ],
    "disabled": [
      "opentofu-*",
      "jira-*",
      "opencode-agent-creation",
      "opencode-skill-creation"
    ]
  }
}
```

### Example 3: Minimal Setup

```json
{
  "skills": {
    "enabled": [
      "test-generator-framework",
      "linting-workflow",
      "pr-creation-workflow"
    ],
    "disabled": [],
    "autoLoad": false,
    "cacheEnabled": false
  }
}
```

### Example 4: Custom Skills Setup

```json
{
  "skills": {
    "enabled": ["*"],
    "disabled": [],
    "customSkillsPath": "/home/user/my-company-skills",
    "priorities": {
      "my-company-linter": 10,
      "my-company-test": 9,
      "test-generator-framework": 8
    }
  }
}
```

---

## Skill Discovery Order

Skills are discovered and loaded in this order:

1. **Framework Skills** (`~/.config/opencode/skills/`)
2. **Project Skills** (`./skills/`)
3. **USER Custom Skills** (`customSkillsPath` if configured)

**Priority:**
1. USER custom skills (highest priority)
2. Project skills
3. Framework skills (lowest priority)

Skills found later override earlier skills with the same name.

---

## Validating Skill Configuration

### Check Configuration

```bash
# Validate USER skill configuration
./setup.sh --validate-config
```

### Common Issues

#### Issue: Skill Not Found

**Error:** `Skill not found: my-custom-skill`

**Solution:**
1. Check skill name matches directory name
2. Verify skill path is correct
3. Check skill has SKILL.md file

#### Issue: Priority Conflict

**Error:** `Multiple skills with same priority`

**Solution:**
1. Adjust skill priorities
2. Use higher priority for preferred skills

#### Issue: Disabled Skill Still Loading

**Error:** Disabled skill still available

**Solution:**
1. Check skill name matches exactly
2. Verify configuration file syntax
3. Restart opencode after changing config

---

## Performance Tuning

### For Faster Startup

```json
{
  "skills": {
    "autoLoad": true,
    "cacheEnabled": true,
    "cacheDuration": 3600
  }
}
```

### For Lower Memory Usage

```json
{
  "skills": {
    "autoLoad": false,
    "cacheEnabled": false
  }
}
```

### For Minimal Skill Set

```json
{
  "skills": {
    "enabled": [
      "test-generator-framework",
      "linting-workflow"
    ],
    "disabled": ["*"]
  }
}
```

---

## Best Practices

### 1. Use Wildcards for Groups

**Good:**
```json
{
  "enabled": ["python-*", "test-*"]
}
```

**Bad:**
```json
{
  "enabled": ["python-pytest-creator", "python-ruff-linter", ...]
}
```

### 2. Set Clear Priorities

**Good:**
```json
{
  "priorities": {
    "test-generator-framework": 10,
    "python-pytest-creator": 9
  }
}
```

**Bad:**
```json
{
  "priorities": {
    "test-generator-framework": 10,
    "python-pytest-creator": 10  // Same priority as framework
  }
}
```

### 3. Use Categories for Organization

**Good:**
```json
{
  "categories": {
    "language": {
      "enabled": true
    }
  }
}
```

**Bad:**
```json
{
  "enabled": ["python-pytest-creator", "python-ruff-linter", "javascript-eslint-linter", ...]
}
```

### 4. Document Custom Skills

**Good:**
- Create SKILL.md with proper frontmatter
- Include description and use cases
- Document dependencies

**Bad:**
- Create skill without documentation
- No clear purpose or use cases
- Undefined dependencies

---

## Troubleshooting

### Skills Not Loading

**Symptoms:**
- Skills not appearing in list
- Custom skills ignored

**Solutions:**
1. Check configuration file path: `~/.config/opencode/user/config.user.json`
2. Validate JSON syntax: `jq . config.user.json`
3. Check file permissions: `chmod 644 config.user.json`
4. Restart opencode after configuration changes

### Wrong Skill Used

**Symptoms:**
- Unexpected skill invoked for task
- Preferred skill not being used

**Solutions:**
1. Check skill priorities
2. Verify skill is enabled (not in disabled list)
3. Check glob patterns match skill name

### Performance Issues

**Symptoms:**
- Slow startup
- High memory usage

**Solutions:**
1. Disable skill caching: `"cacheEnabled": false`
2. Disable auto-load: `"autoLoad": false`
3. Reduce enabled skills list
4. Increase cache duration

---

## Advanced Configuration

### Dynamic Skill Loading

Load skills based on project needs:

```json
{
  "skills": {
    "autoLoad": false,
    "enabled": ["*"],
    "dynamicLoad": {
      "python": ["python-*", "test-generator-framework"],
      "javascript": ["javascript-*", "test-generator-framework"],
      "opentofu": ["opentofu-*"]
    }
  }
}
```

### Skill Aliases

Create custom aliases for skills:

```json
{
  "aliases": {
    "mytest": "python-pytest-creator",
    "mylint": "python-ruff-linter",
    "mypr": "pr-creation-workflow"
  }
}
```

---

## Getting Help

- **Validate Configuration:** `./setup.sh --validate-config`
- **View Skills:** `opencode --list-skills`
- **Skill Documentation:** See `skills/<skill-name>/SKILL.md`
- **Configuration Guide:** `templates/USER_CONFIG.md`
- **Migration Guide:** `docs/SKILL_MIGRATION_GUIDE.md`

---

**Last Updated:** 2026-01-29
**Version:** 1.0.0
