# Agent Guidelines for OpenCode Agentic Development Framework

This repository is an **agentic configuration framework** for building and orchestrating coding agents locally. The `config.json` file defines agents, capabilities, and MCP servers. The `skills/` folder contains reusable workflow definitions.

## Build/Lint/Test Commands

**No traditional build, lint, or test commands.** This is a configuration template repository.

**Validation Commands:**
```bash
# Validate JSON syntax (required after config.json changes)
jq . config.json

# Validate shell script syntax (required after setup.sh changes)
bash -n setup.sh

# Test setup script in dry-run mode
bash setup.sh --dry-run

# Test agent invocation
opencode --agent diagram-creator "test prompt"
```

## Code Style Guidelines

### Configuration Files (config.json)

**Schema Compliance:**
- Follows OpenCode config schema at https://opencode.ai/config.json
- Always validate with `jq . config.json` after changes

**Environment Variables:**
- Use `${VAR_NAME}` or `{env:VAR_NAME}` syntax
- Never hardcode API keys or secrets

**MCP Server Configuration:**
- **Type**: `local` (runs via npx) or `remote` (HTTPS endpoint)
- **Local servers**: Use `command` array with `npx -y`
- **Remote servers**: Include `url` and `headers` with Authorization
- **Enabled status**: Set `enabled: true` in config or per-agent under `mcp`

**Agent Configuration:**
- `description`: Single sentence stating agent's primary purpose
- `mode`: "primary" or "subagent"
- `model`: Provider/model string (e.g., "zai-coding-plan/glm-4.6v")
- `prompt`: Detailed instructions covering delegation, output format, error handling
- `tools`: Boolean flags for read/write/edit/glob/grep
- `mcp`: Object with MCP server names and `enabled: true` status

### Shell Scripts (setup.sh)

**Header:**
```bash
#!/bin/bash
set -o pipefail
set -o nounset
```

**Error Handling:**
- Don't use `set -e` (implement custom error handling)
- Wrap commands in functions with error checking
- Use trap for cleanup on failure

**User Interaction:**
- Destructive operations require confirmation: `prompt_yes_no "Proceed?" "n"`
- Mask sensitive output: `${VAR:0:8}...${VAR: -4}`
- Provide clear prompts with defaults

**Logging/Security:**
- Use color-coded output: RED (errors), GREEN (success), YELLOW (warnings)
- Include section headers: `echo "=== Section Name ==="`
- Never echo raw API keys, validate user input, create backups

### Skills (skills/*/SKILL.md)

**Skill Discovery Mechanism:**
After running `setup.sh`, skills are deployed to `~/.config/opencode/skills/` and a `SKILL_INDEX.json` file is generated for optimized skill discovery. Both `build-with-skills` and `plan-with-skills` agents must use `SKILL_INDEX.json` as the primary method for discovering available skills.

**Verification Commands:**
```bash
# Check if SKILL_INDEX.json exists
ls -la ~/.config/opencode/skills/SKILL_INDEX.json

# View skill index contents
cat ~/.config/opencode/skills/SKILL_INDEX.json | jq '.skills[].name'

# View full index
cat ~/.config/opencode/skills/SKILL_INDEX.json | jq '.'
```

**Skill Discovery Workflow:**
1. **Primary Method**: Read `~/.config/opencode/skills/SKILL_INDEX.json` to get all skill metadata
2. **Fallback**: If SKILL_INDEX.json doesn't exist, use glob discovery on local `skills/` folder with a warning
3. **Skill Loading**: Once a skill is identified, load its full SKILL.md from `~/.config/opencode/skills/[skill-path]/SKILL.md`

**Frontmatter Format:**
```yaml
---
name: skill-name
description: Brief description
license: Apache-2.0
compatibility: opencode
metadata:
  audience: developers
  workflow: workflow-type
---
```

**Content Structure:**
- "What I do", "When to use me", "Prerequisites", "Steps", "Best Practices", "Common Issues"
- Use triple backticks with bash language specifier for code blocks
- Include example commands with context

### Documentation (README.md)

**Sections:**
1. Brief description (1-2 sentences)
2. Prerequisites with installation commands
3. Setup instructions (automated + manual)
4. Configuration overview
5. Usage examples
6. Troubleshooting

**Code Examples:**
- Always include bash language specifier
- Show verification commands
- Include output examples

**Links:**
- Use absolute URLs for external resources
- Use relative paths for internal references

## Agent Design Patterns

- **Single Responsibility**: Each agent has one primary capability
- **Composability**: Design chains (researcher → planner → coder → reviewer)
- **Clear Handoffs**: Explicit delegation criteria in prompts
- **State Awareness**: Agents understand their role in workflow
- **Idempotency**: Safe to retry operations
- **Tool Minimization**: Grant minimal permissions to reduce risk
- **Error Recovery**: Include fallback strategies in prompts
- **Context Budgeting**: Limit scope for performance

## Naming Conventions

- **Files**: kebab-case: `config.json`, `setup.sh`, `skill-name.md`
- **Directories**: kebab-case: `skills/`, `skills/jira-git-workflow/`
- **JSON keys**: camelCase for standard fields, lowercase for MCP names
- **Environment variables**: UPPERCASE_WITH_UNDERSCORES: `ZAI_API_KEY`, `NVM_DIR`
- **Agents**: kebab-case: `diagram-creator`, `image-analyzer`, `explore`
- **Skills**: kebab-case: `jira-git-workflow`, `nextjs-pr-workflow`

## Error Handling

**Configuration Errors:**
- Validate JSON before deployment: `jq . config.json`
- Check environment variables: `echo $VAR_NAME`
- Provide clear error messages with recovery steps

**Shell Script Errors:**
- Check command existence before execution: `command_exists node`
- Use conditional execution with `|| true` for non-critical steps
- Implement custom error handler with trap

**Missing Dependencies:**
- Check for required tools (nvm, node, npm, jq, curl)
- Provide installation guidance
- Offer to skip optional components

**Agent Skill Discovery Issues:**
- **SKILL_INDEX.json missing**: Re-run setup.sh to regenerate index
- **Agents not finding skills**: Verify `~/.config/opencode/skills/SKILL_INDEX.json` exists
- **Incorrect path references**: Ensure agents use `~/.config/opencode/skills/SKILL_INDEX.json` not relative paths
- **Outdated index**: Run `bash setup.sh --skills-only` to refresh skills and index
- **Permission issues**: Check read permissions on `~/.config/opencode/skills/` directory

## Making Changes

**config.json:**
- Update MCP server URLs, model names, or agent prompts only
- Validate JSON after any changes
- Test with `opencode --agent <name>`

**setup.sh:**
- Modify installation logic or add setup steps
- Validate shell syntax: `bash -n setup.sh`
- Test in dry-run mode first

**README.md:**
- Keep in sync with config.json changes
- Update MCP server documentation
- Add new agent descriptions

**Skills:**
- Follow SKILL.md format strictly
- Update metadata for compatibility
- Test skill invocation with opencode

## Security

- Never commit actual API keys or secrets
- Use environment variables for all sensitive data
- Mask values in logs and output
- Validate user input before execution
- Use HTTPS for all remote connections

## Testing Changes

1. Validate JSON: `jq . config.json`
2. Check shell syntax: `bash -n setup.sh`
3. Dry-run setup: `bash setup.sh --dry-run`
4. Verify schema compliance with https://opencode.ai/config.json
5. Test deployment to `~/.config/opencode/`
6. Test agent invocation: `opencode --agent <name> "test prompt"`

## Important Notes

- This is a **template repository** - deployed to user config directory
- No package.json, build system, or test framework exists
- Changes must preserve backward compatibility
- Always use environment variables for sensitive configuration
- Document breaking changes in README.md
- Skills folder is copied recursively during setup
- OpenCode config directory: `~/.config/opencode/`
- **SKILL_INDEX.json**: Generated by setup.sh at `~/.config/opencode/skills/SKILL_INDEX.json` for optimized skill discovery
- **Skill Discovery**: Agents must use SKILL_INDEX.json as primary discovery method, with fallback to glob
- **Path Resolution**: Skills are loaded from `~/.config/opencode/skills/[skill-path]/SKILL.md`
