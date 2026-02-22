---
name: opencode-skills-maintainer
description: Scan and validate skill consistency across the skills/ folder, generating reports on skill metadata, categories, and structure
license: Apache-2.0
compatibility: opencode
metadata:
  audience: developers
  workflow: maintenance
---

## What I do

I maintain skill consistency and quality by:

1. **Discover All Skills**: Scan the `skills/` folder to discover all available skills
2. **Extract Skill Metadata**: Read frontmatter from each SKILL.md file (name, description, category)
3. **Validate Skill Structure**: Ensure all skills have required fields and valid frontmatter
4. **Categorize Skills**: Organize skills into logical categories (Framework, Test Generators, Linters, etc.)
5. **Generate Report**: Provide a summary of all skills with metadata validation status

## When to use me

Use this skill when:
- You want to audit all skills in the repository
- You need to validate skill metadata consistency
- You're checking for missing required fields in SKILL.md files
- You want a categorized list of all available skills
- You're debugging skill discovery issues

## Prerequisites

- Access to the repository root directory
- `jq` tool installed for JSON validation
- Python 3+ installed for YAML parsing

## Steps

### Step 1: Discover All Skills

Scan the `skills/` folder to find all skill directories:

```bash
# Find all skill directories
find skills/ -name "SKILL.md" -type f | sort
```

### Step 2: Extract Skill Metadata

For each skill, read the frontmatter to extract:

```bash
# Extract name and description from frontmatter
for skill_dir in skills/*/; do
  echo "=== $(basename "$skill_dir") ==="
  head -10 "$skill_dir/SKILL.md" | grep -E "(name:|description:)" | head -2
  echo
done
```

**Required Fields**:
- `name`: The skill identifier
- `description`: Brief description of what the skill does
- Optional: `category`, `workflow`, `audience` (from metadata section)

### Step 3: Validate Skill Structure

Check all skills for required fields and valid frontmatter:

```bash
# Validate all SKILL.md files
for dir in skills/*/; do
  skill_name=$(basename "$dir")
  echo "Validating: $skill_name"
  
  # Check for required fields
  if ! grep -q "^name:" "$dir/SKILL.md"; then
    echo "  ❌ Missing 'name:' field"
  else
    echo "  ✓ Has 'name:' field"
  fi
  
  if ! grep -q "^description:" "$dir/SKILL.md"; then
    echo "  ❌ Missing 'description:' field"
  else
    echo "  ✓ Has 'description:' field"
  fi
  
  # Validate YAML syntax (requires python3 and pyyaml)
  if python3 -c "import yaml; yaml.safe_load(open('$dir/SKILL.md'))" 2>&1; then
    echo "  ✓ Valid YAML frontmatter"
  else
    echo "  ❌ Invalid YAML frontmatter"
  fi
done
```

### Step 4: Categorize Skills

Organize skills into logical categories:

```bash
# Framework Skills (Foundational Workflows)
- linting-workflow
- test-generator-framework
- ticket-branch-workflow
- pr-creation-workflow
- coverage-framework
- jira-workflow-framework
- opentofu-framework
- opencode-tooling-framework

# Language-Specific Test Generators
- python-pytest-creator
- nextjs-unit-test-creator

# Language-Specific Linters
- python-ruff-linter
- javascript-eslint-linter

# Project Setup
- nextjs-standard-setup
- nextjs-complete-setup

# Git/Workflow
- git-issue-creator
- git-pr-creator
- git-issue-labeler
- git-issue-updater
- git-semantic-commits
- git-pr-creator
- jira-git-integration
- jira-git-workflow
- nextjs-pr-workflow
- git-issue-plan-workflow
- jira-ticket-plan-workflow
- jira-ticket-workflow
- ticket-branch-workflow
- pr-creation-workflow
- jira-status-updater

# OpenCode Meta
- opencode-agent-creation
- opencode-skill-creation
- opencode-skill-auditor
- opencode-skills-maintainer

# OpenTofu/Infrastructure
- opentofu-provider-setup
- opentofu-provisioning-workflow
- opentofu-aws-explorer
- opentofu-kubernetes-explorer
- opentofu-neon-explorer
- opentofu-keycloak-explorer
- opentofu-ecr-provision

# Code Quality/Documentation
- docstring-generator
- python-docstring-generator
- nextjs-tsdoc-documentor
- typescript-dry-principle
- coverage-readme-workflow

# Utilities
- ascii-diagram-creator
- tdd-workflow
```

### Step 5: Generate Report

Create a summary of all skills:

```markdown
# Skills Maintenance Report

## Skills Found: {total_count}

### Validation Summary
- ✓ Valid skills: {count}
- ❌ Invalid skills: {count}
- ⚠️ Missing optional fields: {count}

### Categories
- Framework Skills: {count}
- Language-Specific Test Generators: {count}
- Language-Specific Linters: {count}
- Project Setup: {count}
- Git/Workflow: {count}
- OpenCode Meta: {count}
- OpenTofu/Infrastructure: {count}
- Code Quality/Documentation: {count}
- Utilities: {count}

### Issues Found (if any)
- [skill-name]: Missing required field 'description'
- [skill-name]: Invalid YAML frontmatter

## Validation
✓ All required fields present
✓ All YAML frontmatter valid
✓ All skills categorized correctly
```

## Best Practices

### Categorization Logic

**Framework Skills**: Skills that provide foundational workflows used by other skills
- Test framework, linting framework, PR workflow, ticket workflow

**Language-Specific**: Skills for specific programming languages or frameworks
- Test generators, linters, project setup

**Meta Skills**: Skills that create/audit other skills or agents
- opencode-agent-creation, opencode-skill-creation, opencode-skill-auditor

**Domain-Specific**: Skills for specific domains
- OpenTofu infrastructure, Git/DevOps, documentation

### Validation Rules

1. **Required Fields**: Every SKILL.md must have `name` and `description` in frontmatter
2. **YAML Syntax**: Frontmatter must be valid YAML
3. **File Naming**: Skill directory name should match the skill name (lowercase, hyphens)
4. **Description Length**: Keep descriptions between 50-150 characters

### Consistency Checks

- Skill names and descriptions should match across all references
- Maintain alphabetical ordering within categories
- Use consistent formatting (bold names, descriptions after colon)
- All skills should have `## What I do` and `## When to use me` sections

## Common Issues

### SKILL.md Not Found

**Issue**: Cannot find SKILL.md in a skill directory

**Solution**:
```bash
# Verify SKILL.md exists for all skills
for dir in skills/*/; do
  if [ ! -f "$dir/SKILL.md" ]; then
    echo "Missing SKILL.md in: $dir"
  fi
done
```

### Invalid Frontmatter

**Issue**: SKILL.md has missing or malformed frontmatter

**Solution**:
```bash
# Check for required frontmatter fields
for dir in skills/*/; do
  if ! grep -q "^name:" "$dir/SKILL.md"; then
    echo "Missing 'name:' field in: $dir/SKILL.md"
  fi
  if ! grep -q "^description:" "$dir/SKILL.md"; then
    echo "Missing 'description:' field in: $dir/SKILL.md"
  fi
done
```

### YAML Parse Errors

**Issue**: Python YAML parser fails on SKILL.md

**Solution**:
- Check for unclosed quotes in frontmatter
- Ensure proper indentation
- Verify no trailing spaces in YAML keys
- Check for special characters that need escaping

## Verification Commands

After running this skill, verify with these commands:

```bash
# Count total skills
find skills/ -name "SKILL.md" -type f | wc -l

# List all skill names
for dir in skills/*/; do
  grep "^name:" "$dir/SKILL.md" | head -1
done | sort

# Validate all YAML frontmatter
for dir in skills/*/; do
  python3 -c "import yaml; yaml.safe_load(open('$dir/SKILL.md'))" 2>&1 && echo "✓ $(basename $dir)"
done
```

**Verification Checklist**:
- [ ] All skill directories have SKILL.md files
- [ ] All SKILL.md files have valid YAML frontmatter
- [ ] All skills have required `name` field
- [ ] All skills have required `description` field
- [ ] Skill names match directory names
- [ ] All skills are categorized correctly
- [ ] Descriptions are concise and accurate

## Example Output

**Skills Found: 42**

### Validation Summary
- ✓ Valid skills: 42
- ❌ Invalid skills: 0
- ⚠️ Missing optional fields: 3

### Categories
- Framework Skills: 8
- Language-Specific Test Generators: 2
- Language-Specific Linters: 2
- Project Setup: 2
- Git/Workflow: 14
- OpenCode Meta: 4
- OpenTofu/Infrastructure: 7
- Code Quality/Documentation: 5
- Utilities: 2

### Skills Missing Optional Fields
- opencode-skill-auditor: Missing 'audience' metadata
- ascii-diagram-creator: Missing 'workflow' metadata
- tdd-workflow: Missing 'audience' metadata

## Validation
✓ All required fields present
✓ All YAML frontmatter valid
✓ All skills categorized correctly

## Related Skills

- `opencode-agent-creation`: For creating new agents
- `opencode-skill-creation`: For creating new skills
- `opencode-skill-auditor`: For auditing skill redundancy
