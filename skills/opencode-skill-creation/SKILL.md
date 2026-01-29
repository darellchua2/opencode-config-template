---
name: opencode-skill-creation
description: Generate OpenCode skills following official documentation best practices
license: Apache-2.0
compatibility: opencode
metadata:
  audience: developers
  workflow: skill-development
---

## What I do

I guide you through creating a new OpenCode skill from scratch:

- **Collect Requirements**: Prompt for skill name, description, purpose, audience, workflow type
- **Generate Frontmatter**: Create proper YAML frontmatter with required fields
- **Structure Content**: Build complete skill documentation following standards
- **Validate**: Ensure skill meets naming rules and guidelines
- **Create Files**: Write SKILL.md to appropriate directory
- **Update Agents**: Always run opencode-skills-maintainer to update Build-With-Skills and Plan-With-Skills agents

## When to use me

Use when:
- Creating a new OpenCode skill without manually formatting SKILL.md
- Ensuring skill follows official documentation standards
- Avoiding repetitive setup when creating multiple skills
- Ensuring agents are automatically updated with new skills

## Prerequisites

- Write access to skills/ directory
- Understanding of OpenCode skill structure
- Knowledge of skill's purpose and requirements

## Steps

### Step 1: Gather Requirements

Prompt for required and optional information:

**Required Fields**:
- **Name**: Unique identifier (1-64 chars, lowercase alphanumeric with single hyphens)
- **Description**: Brief description (1-1024 chars) specific enough for skill selection

**Optional Fields**:
- **License**: Usually "Apache-2.0"
- **Compatibility**: Usually "opencode"
- **Audience**: Target users (developers, DevOps, QA, etc.)
- **Workflow**: Workflow type (testing, linting, deployment, etc.)

### Step 2: Validate Skill Name

```bash
# Check name length (1-64 characters)
if [ ${#skill_name} -lt 1 ] || [ ${#skill_name} -gt 64 ]; then
    echo "Error: Skill name must be 1-64 characters"
    exit 1
fi

# Check for valid characters (lowercase alphanumeric and single hyphens)
if [[ ! $skill_name =~ ^[a-z0-9]+(-[a-z0-9]+)*$ ]]; then
    echo "Error: Skill name must be lowercase alphanumeric with single hyphens"
    exit 1
fi

# Check for double hyphens
if [[ $skill_name =~ -- ]]; then
    echo "Error: Skill name cannot contain double hyphens"
    exit 1
fi

# Check for leading/trailing hyphens
if [[ $skill_name =~ ^- || $skill_name =~ -$ ]]; then
    echo "Error: Skill name cannot start or end with hyphens"
    exit 1
fi
```

### Step 3: Generate YAML Frontmatter

```yaml
---
name: <skill-name>
description: <skill-description>
license: <license-type>
compatibility: <compatibility>
metadata:
  audience: <target-audience>
  workflow: <workflow-type>
---
```

### Step 4: Build Skill Content

Structure documentation with these sections:

#### Required Sections
- **"## What I do"**: List primary capabilities (3-7 items)
- **"## When to use me"**: List usage scenarios

#### Recommended Sections
- **"## Prerequisites"**: Requirements to run skill
- **"## Steps"**: Detailed workflow steps
- **"## Best Practices"**: Recommended approaches
- **"## Common Issues"**: Troubleshooting guide

### Step 5: Create Directory and File

```bash
# Create skill directory
mkdir -p "skills/<skill-name>"

# Create SKILL.md file
touch "skills/<skill-name>/SKILL.md"
```

### Step 6: Write Skill Documentation

**IMPORTANT: Always use `read` tool before using `write` or `edit` on existing files.**

This prevents accidental data loss when updating existing documentation.

For NEW files (created in Step 5), write directly:
```bash
cat > "skills/<skill-name>/SKILL.md" << 'EOF'
---
name: <skill-name>
description: <skill-description>
license: <license-type>
compatibility: <compatibility>
metadata:
  audience: <target-audience>
  workflow: <workflow-type>
---

## What I do

- [Capability 1]
- [Capability 2]

## When to use me

Use when:
- [Scenario 1]
- [Scenario 2]
EOF
```

For EXISTING files, always read first:
```bash
# 1. Read the file
read filePath="skills/<skill-name>/SKILL.md"

# 2. Now use edit to make targeted changes
edit filePath="skills/<skill-name>/SKILL.md" oldString="old content" newString="new content"
```

### Step 7: Validate Created Skill

```bash
# Check file exists
if [ ! -f "skills/<skill-name>/SKILL.md" ]; then
    echo "Error: SKILL.md was not created"
    exit 1
fi

# Validate YAML syntax (requires python3 and pyyaml)
python3 -c "import yaml; yaml.safe_load(open('skills/<skill-name>/SKILL.md'))" 2>&1

# Check frontmatter fields
grep -q "^name:" "skills/<skill-name>/SKILL.md" || echo "Warning: Missing 'name' field"
grep -q "^description:" "skills/<skill-name>/SKILL.md" || echo "Warning: Missing 'description' field"
```

### Step 8: Update Agents (CRITICAL)

**ALWAYS execute this final step** to ensure agents know about the new skill:

```bash
# Use Build-With-Skills agent
opencode --agent build-with-skills "Use opencode-skills-maintainer to update agents with new skill"
```

**Why This Step is Critical**:
- Build-With-Skills and Plan-With-Skills use hardcoded skill lists
- Without this step, agents won't know about the new skill
- The skill will be created but unavailable to agents
- This ensures consistency between skills/ folder and agent prompts

**What opencode-skills-maintainer Does**:
1. Scans skills/ folder for all SKILL.md files
2. Extracts skill metadata from frontmatter
3. Updates both Build-With-Skills and Plan-With-Skills agent prompts
4. Validates config.json with jq
5. Generates a maintenance report

## Best Practices

### Naming Conventions

- Use descriptive names: `python-pytest-creator` (good), `skill-1` (bad)
- Include workflow type: `-test`, `-lint`, `-setup`, `-workflow`
- Follow lowercase: `nextjs-standard-setup` (good), `NextJS-Standard-Setup` (bad)
- Single hyphens only: `git-pr-creator` (good), `git--pr-creator` (bad)
- No underscores: `python-pytest` (bad), `python-pytest-creator` (good)

### Description Guidelines

- Be specific: "Generate pytest tests" (good), "Create tests" (vague)
- Include framework: "using test-generator-framework" (good)
- Mention capabilities: "for Next.js 16 with App Router" (good)
- Length: 50-150 characters (optimal)

### Content Structure

- Start with capabilities: "## What I do" section first
- Follow with scenarios: "## When to use me" section
- Add details: Optional sections based on complexity
- Use code blocks: Include examples with triple backticks
- Be thorough: More detail is better than less

### File Safety

- **ALWAYS read before writing**: Use `read` tool before `write` or `edit` on any existing file
- Never assume content: Always check current file content before modifying
- Check file existence: Use `glob` or `read` to verify file exists
- Required when updating: PLAN.md, README.md, or existing documentation

## Common Issues

### Invalid Skill Name

**Issue**: Skill name doesn't follow naming rules

**Solution**: Use valid examples: `python-pytest-creator`, `linting-workflow`, `git-pr-creator`

### YAML Validation Errors

**Issue**: Frontmatter has invalid YAML syntax

**Solution**:
- Check indentation (2 spaces for lists)
- Ensure quotes around special characters
- Verify no trailing spaces after colons
- Use Python YAML validator: `python3 -c "import yaml; yaml.safe_load(open('SKILL.md'))"`

### Description Too Vague

**Issue**: Agents can't determine when to use skill

**Solution**:
- Include specific frameworks or tools
- Mention target languages or domains
- Specify workflow type
- Keep description between 50-150 characters

### Agents Can't Find New Skill

**Issue**: New skill created but agents don't recognize it

**Solution**:
- **Did you run Step 8?** Always run opencode-skills-maintainer as final step
- Check if config.json was updated: `jq '.agent["build-with-skills"].prompt' config.json | grep "<skill-name>"`
- Manually invoke opencode-skills-maintainer if automated step failed
- Verify skill name matches frontmatter exactly

## Verification

After creating a skill, verify:

```bash
# 1. Check skill directory exists
ls -la skills/<skill-name>/

# 2. Verify SKILL.md exists
test -f skills/<skill-name>/SKILL.md && echo "✓ SKILL.md exists"

# 3. Validate YAML frontmatter
python3 -c "import yaml; yaml.safe_load(open('skills/<skill-name>/SKILL.md'))" && echo "✓ YAML valid"

# 4. Check required fields
grep "^name:" skills/<skill-name>/SKILL.md && echo "✓ Name field present"
grep "^description:" skills/<skill-name>/SKILL.md && echo "✓ Description field present"

# 5. Verify agents updated (CRITICAL!)
jq '.agent["build-with-skills"].prompt' config.json | grep -q "<skill-name>" && echo "✓ Build-With-Skills updated" || echo "❌ Build-With-Skills NOT updated"
jq '.agent["plan-with-skills"].prompt' config.json | grep -q "<skill-name>" && echo "✓ Plan-With-Skills updated" || echo "❌ Plan-With-Skills NOT updated"
```

## Related Skills

- **opencode-skills-maintainer**: Used as final step to update agents with new skills
- **opencode-agent-creation**: For creating new agents with similar best practices
- **opencode-skill-auditor**: For auditing and modularizing existing skills
