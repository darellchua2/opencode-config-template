# Skill Migration Guide

This guide helps users migrate to the new skill modularization structure introduced in Phase 4.

---

## Overview

Phase 4 introduces skill modularization with:
- Framework skills for common operations
- USER level skill control
- Skill priority configuration
- Custom skill paths
- Skill categorization

**Migration Status:** Documentation phase (no breaking changes)

**Breaking Changes:** None (backward compatible)

**Required Actions:** Optional (new features available, not required)

---

## What's New

### 1. Framework Skills

New framework skills provide common operations:

| Framework | Purpose | Skills Using It |
|-----------|---------|----------------|
| `git-workflow-framework` | Common Git operations | (planned) |
| `documentation-framework` | Documentation operations | (planned) |
| `issue-framework` | Issue management | (planned) |
| `opentofu-framework` | OpenTofu operations | (planned) |

**Note:** Framework skills are planned for future phases. Current skills work without changes.

### 2. USER Level Skill Control

New configuration options in `~/.config/opencode/user/config.user.json`:

```json
{
  "skills": {
    "enabled": ["*"],
    "disabled": [],
    "priorities": {},
    "customSkillsPath": "/path/to/custom/skills",
    "autoLoad": true,
    "cacheEnabled": true
  }
}
```

### 3. Skill Categorization

Skills organized into 8 categories:

- Framework (5 skills)
- Language-Specific (3 skills)
- Framework-Specific (4 skills)
- OpenCode Meta (3 skills)
- OpenTofu (7 skills)
- Git/Workflow (6 skills)
- Documentation (2 skills)
- JIRA (1 skill)

---

## Migration Steps

### Step 1: Verify Current Installation

Check your current opencode version:

```bash
opencode --version
```

Check setup.sh version:

```bash
./setup.sh --version
```

**Required Versions:**
- opencode-ai: v1.0.0 or higher
- setup.sh: v1.11.0 or higher

### Step 2: Update setup.sh

If your setup.sh is older than v1.11.0, update:

```bash
# Pull latest changes
git pull origin main

# Or re-run setup
./setup.sh
```

### Step 3: Enable USER Level Configuration (Optional)

If you haven't set up USER level configuration:

```bash
# Interactive setup
./setup.sh --user-config

# Or migrate existing configuration
./setup.sh --migrate-config
```

This creates `~/.config/opencode/user/` directory with:
- `config.user.json` - USER configuration
- `AGENTS.md` - USER level AGENTS.md (optional)

### Step 4: Configure Skills (Optional)

Create or update `~/.config/opencode/user/config.user.json`:

```json
{
  "skills": {
    "enabled": ["*"],
    "disabled": [],
    "priorities": {
      "test-generator-framework": 10,
      "linting-workflow": 9
    },
    "autoLoad": true,
    "cacheEnabled": true
  }
}
```

See `templates/config.skills.json.example` for full configuration.

### Step 5: Validate Configuration

Validate your USER configuration:

```bash
./setup.sh --validate-config
```

This checks:
- JSON syntax
- Configuration structure
- Skill references
- AGENTS.md format

### Step 6: Test Configuration

Test with a simple task:

```bash
# Test linting
opencode lint the Python code

# Test testing
opencode test generate tests for this function

# Test Git operations
opencode create a feature branch
```

---

## Configuration Options

### Option A: No Changes (Recommended for Most Users)

**Description:** Continue using default configuration

**Steps:** None

**Pros:**
- No changes required
- All skills work as before
- Zero risk

**Cons:**
- No USER customization
- Default behavior only

**When to Choose:**
- Default behavior is fine
- Don't need customization
- Want to minimize risk

### Option B: USER Level Control (Recommended for Power Users)

**Description:** Enable USER level skill control

**Steps:**
1. Run `./setup.sh --user-config`
2. Edit `~/.config/opencode/user/config.user.json`
3. Configure skills as needed

**Pros:**
- Custom skill control
- Priority configuration
- Custom skill paths
- Better performance with caching

**Cons:**
- Requires configuration
- Learning curve

**When to Choose:**
- Want skill customization
- Need custom skills
- Want better performance

### Option C: Minimal Configuration (Recommended for New Users)

**Description:** Minimal setup with only essential features

**Steps:**
1. Run `./setup.sh --user-config`
2. Keep default config.user.json
3. Enable only skills you use

**Pros:**
- Simple setup
- Minimal configuration
- Faster startup

**Cons:**
- Limited features
- May need to enable skills later

**When to Choose:**
- New to opencode-ai
- Want minimal setup
- Don't need advanced features

---

## Configuration Examples

### Example 1: Python Developer

```json
{
  "skills": {
    "enabled": [
      "python-*",
      "test-generator-framework",
      "linting-workflow",
      "coverage-readme-workflow",
      "docstring-generator"
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

### Example 2: Full Stack Developer

```json
{
  "skills": {
    "enabled": ["*"],
    "disabled": [],
    "priorities": {
      "test-generator-framework": 10,
      "linting-workflow": 9,
      "git-workflow-framework": 8
    }
  }
}
```

### Example 3: DevOps Engineer

```json
{
  "skills": {
    "enabled": [
      "opentofu-*",
      "git-*",
      "jira-*",
      "pr-creation-workflow"
    ],
    "disabled": [
      "python-*",
      "javascript-*",
      "nextjs-*",
      "typescript-*"
    ],
    "priorities": {
      "opentofu-framework": 10
    }
  }
}
```

### Example 4: Custom Skills

```json
{
  "skills": {
    "enabled": ["*"],
    "disabled": [],
    "customSkillsPath": "/home/user/my-company-skills",
    "priorities": {
      "my-company-linter": 10,
      "test-generator-framework": 9
    }
  }
}
```

---

## Common Migration Scenarios

### Scenario 1: From Old Configuration to USER Config

**Before:** No USER configuration, all defaults

**After:** USER configuration enabled

**Steps:**
```bash
# Migrate existing configuration
./setup.sh --migrate-config

# Verify
./setup.sh --validate-config

# Test
opencode list skills
```

### Scenario 2: Adding Custom Skills

**Before:** No custom skills

**After:** Custom skills in user path

**Steps:**
```bash
# Create custom skills directory
mkdir -p ~/my-custom-skills/my-linter

# Create SKILL.md
cat > ~/my-custom-skills/my-linter/SKILL.md <<EOF
---
name: my-linter
description: My custom linter
license: MIT
---

My custom linter description here...
EOF

# Configure in USER config
echo '"customSkillsPath": "/home/user/my-custom-skills"' >> ~/.config/opencode/user/config.user.json

# Restart opencode
```

### Scenario 3: Disabling Unused Skills

**Before:** All 33 skills enabled

**After:** Only essential skills enabled

**Steps:**
```json
{
  "skills": {
    "enabled": [
      "test-generator-framework",
      "linting-workflow",
      "pr-creation-workflow"
    ],
    "disabled": ["*"]
  }
}
```

### Scenario 4: Setting Skill Priorities

**Before:** Default priorities

**After:** Custom priorities

**Steps:**
```json
{
  "skills": {
    "priorities": {
      "test-generator-framework": 10,
      "linting-workflow": 9,
      "python-pytest-creator": 8,
      "python-ruff-linter": 7
    }
  }
}
```

---

## Troubleshooting

### Issue: Configuration Not Loading

**Symptoms:**
- USER config ignored
- Default config used

**Solutions:**
1. Check config path: `~/.config/opencode/user/config.user.json`
2. Validate JSON: `jq . ~/.config/opencode/user/config.user.json`
3. Check file permissions: `chmod 644 ~/.config/opencode/user/config.user.json`
4. Restart opencode

### Issue: Skills Not Found

**Symptoms:**
- Skill not available
- Error: "Skill not found"

**Solutions:**
1. Check skill name matches directory name
2. Verify skill in enabled list
3. Check skill not in disabled list
4. Verify skill path is correct

### Issue: Wrong Skill Used

**Symptoms:**
- Unexpected skill invoked
- Priority not respected

**Solutions:**
1. Check skill priorities
2. Verify skill is enabled
3. Check routing patterns
4. Review subagent skill selection

### Issue: Performance Degradation

**Symptoms:**
- Slow startup
- High memory usage

**Solutions:**
1. Disable skill caching: `"cacheEnabled": false`
2. Disable auto-load: `"autoLoad": false`
3. Reduce enabled skills
4. Increase cache duration

---

## Rollback Procedure

If you need to rollback to previous configuration:

### Step 1: Disable USER Configuration

```bash
# Backup current config
cp ~/.config/opencode/user/config.user.json ~/.config/opencode/user/config.user.json.backup

# Delete or rename USER config
rm ~/.config/opencode/user/config.user.json
```

### Step 2: Restore Previous Config

```bash
# Restore from backup
cp ~/.config/opencode/backup/config.json.backup ~/.config/opencode/config.json
```

### Step 3: Restart opencode

```bash
# Restart opencode to load new config
opencode --restart
```

---

## Validation Checklist

After migration, validate:

- [ ] setup.sh version is 1.11.0 or higher
- [ ] USER config directory exists: `~/.config/opencode/user/`
- [ ] config.user.json is valid JSON
- [ ] Skills are correctly configured
- [ ] `./setup.sh --validate-config` passes
- [ ] Test tasks work correctly
- [ ] No performance issues
- [ ] Documentation is accessible

---

## Next Steps

After migration:

1. **Explore New Features**
   - Try USER level skill control
   - Configure skill priorities
   - Add custom skills if needed

2. **Optimize Configuration**
   - Disable unused skills
   - Set appropriate priorities
   - Enable caching if needed

3. **Learn New Patterns**
   - Read skill modularization audit
   - Review subagent documentation
   - Understand framework design

4. **Provide Feedback**
   - Report any issues
   - Suggest improvements
   - Share your configuration

---

## Additional Resources

### Documentation

- **Skill Modularization Audit:** `docs/SKILL_MODULARIZATION_AUDIT.md`
- **Skill Modularization Design:** `docs/SKILL_MODULARIZATION_DESIGN.md`
- **Subagent Documentation:** `docs/SUBAGENT_DOCUMENTATION.md`
- **USER Skill Control Guide:** `docs/USER_SKILL_CONTROL_GUIDE.md`
- **USER Configuration Guide:** `templates/USER_CONFIG.md`

### Configuration

- **Config Template:** `templates/config.skills.json.example`
- **AGENTS.md Template:** `templates/AGENTS.md.example`
- **USER Config:** `~/.config/opencode/user/config.user.json`

### Tools

- **Validate Config:** `./setup.sh --validate-config`
- **List Skills:** `opencode --list-skills`
- **List Agents:** `opencode --list-agents`
- **Help:** `./setup.sh --help`

---

## FAQ

### Q: Is migration required?

**A:** No. Migration is optional. All features work with default configuration.

### Q: Will existing workflows break?

**A:** No. Phase 4 is backward compatible. No breaking changes.

### Q: Can I use both old and new configuration?

**A:** No. Use either USER config or default config, not both.

### Q: How do I add custom skills?

**A:** Create skills directory and set `customSkillsPath` in USER config.

### Q: What if I don't want to use USER config?

**A:** Don't create USER config. Default config will be used.

### Q: Can I disable framework skills?

**A:** Not recommended. Framework skills are used by specialized skills.

### Q: How do I know which skill to use?

**A:** Let subagent select skills. Subagents choose based on task type.

### Q: What's the difference between priority and routing?

**A:** Priority resolves conflicts when multiple skills match. Routing selects subagent based on task pattern.

### Q: Can I change skill priorities?

**A:** Yes. Edit `priorities` in `~/.config/opencode/user/config.user.json`.

### Q: How do I enable custom skills?

**A:** Set `customSkillsPath` and place skills in that directory.

---

**Migration Guide Version:** 1.0
**Last Updated:** 2026-01-29
**Phase:** Phase 4 - Skill Modularization
