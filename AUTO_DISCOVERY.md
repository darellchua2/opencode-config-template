# Automatic Skills Discovery

## Overview

OpenCode agents (Build-With-Skills and Plan-With-Skills) now use **automatic skill discovery** instead of hardcoded skill lists. Skills are dynamically discovered from the `~/.config/opencode/skills/` folder at runtime and injected into agent prompts.

## How It Works

### 1. Skills Generation (At Setup Time)

When you run `./setup.sh`, the following happens:

1. **Scans** the `skills/` folder for all `SKILL.md` files
2. **Extracts** metadata (name, description) from each skill's frontmatter
3. **Categorizes** skills based on naming patterns:
   - Framework Skills: workflow, framework
   - Test Generators: pytest, test-creator, unit-test-creator
   - Linters: linter, ruff, eslint
   - Project Setup: standard-setup, setup
   - Git/Workflow: git, issue, commit, pr-creator, jira
   - OpenCode Meta: opencode, agent-creation, skill-creation, skill-auditor, skills-maintainer
   - OpenTofu: opentofu, terraform, infrastructure
   - Documentation: docstring, coverage, dry-principle, documentation
   - Utilities: ascii-diagram, diagram

4. **Generates** markdown section with all skills organized by category
5. **Injects** the generated section into `config.json` before deployment

### 2. Agent Invocation (At Runtime)

When you invoke an agent:

1. **Agent system prompt** is loaded from `~/.config/opencode/config.json`
2. **Skills section** (already present from setup) is included in prompt
3. **Agent analyzes** your request and matches it against available skills
4. **Skill is selected** and executed

## File Structure

```
opencode-config-template/
├── config.json (template with {{SKILLS_SECTION_PLACEHOLDER}})
├── setup.sh (generates skills and injects into config.json)
├── scripts/
│   └── generate-skills.py (scans skills/ and generates markdown)
└── skills/ (all skill directories)
    ├── skill-1/
    │   └── SKILL.md
    ├── skill-2/
    │   └── SKILL.md
    └── ...
```

## Generated Skills Section Format

The auto-generated skills section in agent prompts looks like:

```markdown
## Available Skills (Auto-Generated at Runtime)

**Generated at:** 2026-01-26
**Total skills:** 32

### Framework Skills (Foundational Workflows)
- **linting-workflow**: Generic linting workflow for multiple languages...
- **test-generator-framework**: Generic test generation framework...
- **ticket-branch-workflow**: Generic ticket-to-branch-to-PLAN workflow...
- **pr-creation-workflow**: Generic pull request creation workflow...

### Language-Specific Test Generators
- **python-pytest-creator**: Generate comprehensive pytest test files...
- **nextjs-unit-test-creator**: Generate comprehensive unit tests...

[... continues for all categories]
```

## Adding New Skills

### Option 1: Simple Add

Just add a new skill directory with SKILL.md:

```bash
mkdir skills/my-new-skill
cat > skills/my-new-skill/SKILL.md << 'EOF'
---
name: my-new-skill
description: Brief description of what this skill does
license: Apache-2.0
compatibility: opencode
metadata:
  audience: developers
  workflow: workflow-type
---

## What I do

Description of skill functionality...

## When to use me

Use this skill when...

## Prerequisites

List of prerequisites...

## Steps

1. Step one...
2. Step two...
EOF
```

Then run setup to regenerate:

```bash
./setup.sh --skills-only
```

### Option 2: Using opencode-skills-maintainer

The `opencode-skills-maintainer` skill is still available and useful for **auditing** and **validating** skills, but since skills are now auto-discovered, it's not needed for updating agent prompts.

Use it to:

- Audit skill redundancy
- Validate skill metadata
- Check for missing documentation
- Identify modularization opportunities

```bash
opencode --agent build-with-skills "Use opencode-skills-auditor to check skills"
```

## Benefits of Auto-Discovery

1. **Zero Maintenance**: No need to manually update config.json when adding/removing skills
2. **Always Current**: Skills section always reflects the actual skills folder
3. **Version Control Friendly**: Just add/modify skills, run setup, done
4. **Categorized Organization**: Skills are automatically organized by category
5. **Type Safety**: Metadata extracted from YAML frontmatter reduces errors

## Manual Override

If you need to use a specific hardcoded skills list (for testing or special cases):

1. Edit `config.json`
2. Replace `{{SKILLS_SECTION_PLACEHOLDER}}` with your skills section
3. Deploy with `./setup.sh`

## Troubleshooting

### Skills Not Showing Up

**Issue**: New skills not appearing in agent prompts

**Solution**:
```bash
# Regenerate skills section
./setup.sh --skills-only

# Or verify skills are in directory
ls -la ~/.config/opencode/skills/
```

### Wrong Category

**Issue**: Skill appears in wrong category

**Solution**: The categorization is based on skill name patterns. If a skill is miscategorized, either:
1. Modify skill name to match a pattern (e.g., use "-workflow" suffix)
2. Update `scripts/generate-skills.py` categorization logic

### Generation Fails

**Issue**: Skills generation script fails

**Solution**:
```bash
# Check Python 3 is available
python3 --version

# Test script manually
python3 scripts/generate-skills.py markdown

# Check skills directory exists
ls -la skills/
```

## Migration from Hardcoded Skills

If you're upgrading from a version with hardcoded skills:

1. The old config.json is automatically backed up during setup
2. New config.json will have auto-generated skills
3. All your skills from `skills/` folder will be discovered
4. Nothing is lost - skills are read directly from your skills folder

## Verification

After setup, verify auto-discovery works:

```bash
# Check skills section exists in config
jq '.agent["build-with-skills"].prompt' ~/.config/opencode/config.json | grep "Auto-Generated"

# Test agent invocation
opencode --agent build-with-skills "List available skills"

# Verify skills count
python3 scripts/generate-skills.py markdown | grep "^- \*\*" | wc -l
```

## Performance Considerations

- **Setup Time**: +1-2 seconds to generate skills section (runs once)
- **Runtime Time**: Zero impact - skills already present in config.json
- **Memory**: Minimal - just text string in prompt
- **Scalability**: Handles unlimited skills with efficient scanning

## Future Enhancements

Potential improvements to the auto-discovery system:

1. **Skill Index Cache**: Generate `skills-index.json` for faster agent startup
2. **Dependency Graph**: Track skill relationships and dependencies
3. **Skill Versions**: Support multiple versions of the same skill
4. **Remote Skills**: Fetch skills from GitHub repositories
5. **Skill Validation**: Automated testing of skill execution paths
6. **Dynamic Categorization**: Use tags in SKILL.md frontmatter instead of pattern matching
