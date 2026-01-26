# Agent Guidelines for OpenCode Agentic Development Framework

This repository is an **agentic configuration template** for building and orchestrating coding agents locally. The `config.json` file defines agents, capabilities, and MCP servers. The `skills/` folder contains reusable workflow definitions that are **auto-discovered at setup time**.

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

# Regenerate skills section and deploy
./setup.sh --skills-only

# Test agent invocation
opencode --agent build-with-skills "test prompt"

# List available skills
opencode --list-skills
```

## Code Style Guidelines

### Configuration Files (config.json)

**Schema Compliance:** Follow OpenCode config schema at https://opencode.ai/config.json, always validate with `jq . config.json`

**Environment Variables:** Use `${VAR_NAME}` or `{env:VAR_NAME}` syntax, never hardcode API keys

**MCP Server Configuration:**
- **Type**: `local` (runs via npx) or `remote` (HTTPS endpoint)
- **Local servers**: Use `command` array with `npx -y`
- **Remote servers**: Include `url` and `headers` with Authorization
- **Enabled status**: Set `enabled: true` in config or per-agent under `mcp`

**Agent Configuration:**
- `description`: Single sentence stating agent's primary purpose
- `mode`: "primary" or "subagent"
- `model`: Provider/model string (e.g., "zai-coding-plan/glm-4.7")
- `prompt`: Detailed instructions covering delegation, output format, error handling
- `tools`: Boolean flags for read/write/edit/glob/grep
- `mcp`: Object with MCP server names and `enabled: true` status
- `permission.skill`: Object with `"*": "allow"` to grant all skills

### Shell Scripts (setup.sh)

**Header:** `#!/bin/bash`, `set -o pipefail`, `set -o nounset`

**Error Handling:** Don't use `set -e`, wrap commands in functions with error checking, use trap for cleanup

**User Interaction:** Destructive operations require confirmation, mask sensitive output, provide clear prompts with defaults

**Logging/Security:** Use color-coded output (RED/GREEN/YELLOW), include section headers, never echo raw API keys

### Skills (skills/*/SKILL.md)

**Auto-Discovery Mechanism:** Skills are automatically discovered from `skills/` folder at setup time by `scripts/generate-skills.py`. The generated markdown is injected into agent prompts via `{{SKILLS_SECTION_PLACEHOLDER}}`. Adding/removing skills requires running `./setup.sh --skills-only`.

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

**Content Structure:** "What I do", "When to use me", "Prerequisites", "Steps", "Best Practices", "Common Issues", use triple backticks with bash language specifier for code blocks

### Documentation (README.md, AGENTS.md, etc.)

**Sections:** Brief description (1-2 sentences), Prerequisites with installation commands, Setup instructions, Configuration overview, Usage examples, Troubleshooting

**Code Examples:** Always include bash language specifier, show verification commands, include output examples

**Links:** Use absolute URLs for external resources, use relative paths for internal references

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

**Configuration Errors:** Validate JSON before deployment, check environment variables, provide clear error messages with recovery steps

**Shell Script Errors:** Check command existence before execution, use conditional execution with `|| true`, implement custom error handler with trap

**Missing Dependencies:** Check for required tools (nvm, node, npm, jq, curl, python3), provide installation guidance

**Agent Skill Discovery Issues:** Verify skill is in `skills/` folder and run `./setup.sh --skills-only`, check skill name matches frontmatter exactly

## Making Changes

**config.json:** Update MCP server URLs, model names, or agent prompts, validate JSON, test with `opencode --agent <name>`. Use `{{SKILLS_SECTION_PLACEHOLDER}}` for auto-discovered skills.

**setup.sh:** Modify installation logic, validate shell syntax with `bash -n setup.sh`, test in dry-run mode first

**Skills:** Follow SKILL.md format, update metadata for compatibility, run `./setup.sh --skills-only` to regenerate agent prompts

## Security

- Never commit actual API keys or secrets
- Use environment variables for all sensitive data
- Mask values in logs and output (show only first 8 and last 4 chars)
- Validate user input before execution
- Use HTTPS for all remote connections

## Testing Changes

1. Validate JSON: `jq . config.json`
2. Check shell syntax: `bash -n setup.sh`
3. Dry-run setup: `bash setup.sh --dry-run`
4. Verify schema compliance with https://opencode.ai/config.json
5. Regenerate skills: `./setup.sh --skills-only`
6. Test agent invocation: `opencode --agent <name> "test prompt"`
7. Verify skills are available: `opencode --list-skills`

## Important Notes

- This is a **template repository** - deployed to user config directory `~/.config/opencode/`
- No package.json, build system, or test framework exists
- Changes must preserve backward compatibility
- Always use environment variables for sensitive configuration
- Document breaking changes in README.md
- Skills folder is copied recursively during setup
- **Auto-Discovery**: Skills are generated at setup time by `scripts/generate-skills.py` and injected via `{{SKILLS_SECTION_PLACEHOLDER}}`
- **Skills Maintenance**: Adding/removing skills requires running `./setup.sh --skills-only` to update agent prompts
- Agent prompts contain skills section auto-generated from actual skills folder content
