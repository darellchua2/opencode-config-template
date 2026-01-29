# USER Level Configuration Guide

This guide explains how to set up and use user-level configuration for opencode-ai.

## Overview

opencode-ai supports three levels of configuration:

1. **Global AGENTS.md** (`~/.config/opencode/AGENTS.md`) - Personal preferences and defaults
2. **Project AGENTS.md** (`.AGENTS.md`) - Team rules and project-specific settings
3. **USER Level Config** (`~/.config/opencode/user/`) - User-specific overrides and customizations

## Configuration Hierarchy

```
Global AGENTS.md (defaults)
         ↓
USER Level Config (user overrides)
         ↓
Project AGENTS.md (team rules)
         ↓
config.json (agent definitions)
         ↓
Task Execution
```

## USER Level Structure

```
~/.config/opencode/user/
├── AGENTS.md              # User-level AGENTS.md (optional)
├── config.user.json       # User-specific configuration
└── templates/
    ├── AGENTS.md.example  # Example user AGENTS.md
    └── config.user.json.example  # Example user config
```

## Creating USER Level Configuration

### Option 1: Interactive Setup

Run setup.sh with user configuration enabled:

```bash
./setup.sh --user-config
```

### Option 2: Manual Setup

1. Create user configuration directory (if it doesn't exist):
```bash
mkdir -p ~/.config/opencode/user
```

2. Copy templates:
```bash
cp templates/config.user.json.example ~/.config/opencode/user/config.user.json
cp templates/AGENTS.md.example ~/.config/opencode/user/AGENTS.md  # optional
```

3. Edit configuration files:
```bash
nano ~/.config/opencode/user/config.user.json
nano ~/.config/opencode/user/AGENTS.md  # optional
```

## Configuration Files

### config.user.json

User-specific configuration that overrides global defaults:

```json
{
  "preferences": {
    "defaultModel": "glm-4.7",
    "language": "en",
    "timezone": "UTC"
  },
  "skills": {
    "enabled": ["*"],
    "disabled": [],
    "customSkillsPath": "/path/to/custom/skills"
  },
  "agents": {
    "defaultAgent": "build-with-skills",
    "subagentTimeout": 300,
    "maxConcurrentAgents": 3
  },
  "behavior": {
    "autoLint": true,
    "autoTest": true,
    "autoDocument": false
  },
  "aliases": {
    "planning": "plan-with-skills",
    "implementation": "build-with-skills",
    "linting": "linting-subagent",
    "testing": "testing-subagent"
  }
}
```

### AGENTS.md (User Level)

Optional user-level AGENTS.md that overrides global settings:

```markdown
# USER Level AGENTS.md

This file contains user-specific preferences that override global settings.

## Personal Overrides

### Model Preferences
- Default model: glm-4.7
- Fallback model: glm-4.6v

### Agent Preferences
- Prefer build-with-skills for most tasks
- Use plan-with-skills for complex planning
- Default to testing-subagent for test generation

### Custom Behavior
- Always run tests after code changes
- Auto-fix linting issues when possible
- Prefer TypeScript over JavaScript
```

## Configuration Migration

When upgrading to USER level configuration, setup.sh will:

1. Detect existing configuration in `~/.config/opencode/`
2. Create user configuration directory structure
3. Migrate relevant settings to `config.user.json`
4. Create backup of old configuration
5. Validate new configuration

### Migration Steps

```bash
# Backup existing configuration
cp ~/.config/opencode/config.json ~/.config/opencode/config.json.backup

# Run migration
./setup.sh --migrate-config

# Verify migration
./setup.sh --validate-config
```

## Configuration Validation

Setup.sh includes validation functions to ensure configuration is correct:

```bash
# Validate all configuration
./setup.sh --validate-config

# Validate specific file
./setup.sh --validate-config ~/.config/opencode/user/config.user.json
```

### Validation Checks

- JSON syntax validation
- Required fields presence
- Agent existence verification
- Skills availability check
- AGENTS.md format validation
- Cross-reference validation

## Configuration Best Practices

### 1. Keep Global Settings Minimal
- Put essential defaults in Global AGENTS.md
- Use USER level for personal preferences
- Use Project level for team standards

### 2. Use Specific Overrides
- Only override what's necessary
- Prefer additive configuration over replacement
- Keep configuration backward compatible

### 3. Document Customizations
- Comment your changes in AGENTS.md
- Use descriptive key names in config.user.json
- Maintain a changelog of configuration changes

### 4. Test Configuration
- Validate configuration after changes
- Test with different task types
- Verify subagent routing works correctly

## Example Scenarios

### Scenario 1: Prefer TypeScript

**config.user.json**:
```json
{
  "preferences": {
    "defaultLanguage": "typescript"
  },
  "behavior": {
    "preferTypeScript": true,
    "enforceTyping": true
  }
}
```

### Scenario 2: Custom Skills Directory

**config.user.json**:
```json
{
  "skills": {
    "enabled": ["*"],
    "customSkillsPath": "/home/user/opencode-custom-skills"
  }
}
```

### Scenario 3: Personal Workflow Aliases

**config.user.json**:
```json
{
  "aliases": {
    "plan": "plan-with-skills",
    "code": "build-with-skills",
    "review": "linting-subagent",
    "test": "testing-subagent"
  }
}
```

### Scenario 4: User-Level Behavior Overrides

**AGENTS.md** (user level):
```markdown
# Personal Behavior Overrides

## My Preferences

### Workflow
- Always run tests after implementation
- Auto-fix linting issues
- Generate tests first (TDD)
- Create PR after every feature

### Code Style
- Prefer functional programming
- Use TypeScript strict mode
- Follow clean code principles
- Document complex algorithms
```

## Troubleshooting

### Configuration Not Loading

Check the order of precedence:
1. Verify config.json has `instructions` field
2. Ensure Global AGENTS.md exists
3. Check USER level files are valid
4. Verify Project AGENTS.md if exists

### Validation Errors

Run validation with verbose output:
```bash
./setup.sh --validate-config --verbose
```

Common issues:
- JSON syntax errors (check with `jq . config.user.json`)
- Missing required fields
- Invalid agent references
- Unavailable custom skills

### Migration Issues

If migration fails:
1. Check backup files in `~/.config/opencode/backup/`
2. Restore from backup: `cp ~/.config/opencode/backup/config.json.backup ~/.config/opencode/config.json`
3. Run migration again with `--force-migrate`
4. Check migration logs in `~/.config/opencode/migration.log`

## Updating Configuration

When opencode-ai updates:

1. Check if configuration format changed
2. Review migration notes in release notes
3. Update config.user.json if needed
4. Validate new configuration
5. Test with different task types

## Getting Help

- Run `./setup.sh --help` for setup options
- Check `~/.config/opencode/migration.log` for migration logs
- Review templates in `~/.config/opencode/user/templates/`
- See GitHub issues for common problems

## References

- Global configuration guide: `~/.config/opencode/AGENTS.md`
- Project configuration guide: `.AGENTS.md` (in project directory)
- Main config: `~/.config/opencode/config.json`
- Setup script: `./setup.sh`

---

*Last updated: 2026-01-29*
