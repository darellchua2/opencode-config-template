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

**Agent Skill Maintenance:**
```bash
# Update agents with new skills
opencode --agent build-with-skills "Use opencode-skills-maintainer skill"

# Verify agents have current skills
jq '.agent["build-with-skills"].prompt' config.json | grep "Available Skills"
jq '.agent["plan-with-skills"].prompt' config.json | grep "Available Skills"
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

### Shell Scripts (setup.sh)

**Header:** `#!/bin/bash`, `set -o pipefail`, `set -o nounset`

**Error Handling:** Don't use `set -e`, wrap commands in functions with error checking, use trap for cleanup

**User Interaction:** Destructive operations require confirmation, mask sensitive output, provide clear prompts with defaults

**Logging/Security:** Use color-coded output (RED/GREEN/YELLOW), include section headers, never echo raw API keys

### Skills (skills/*/SKILL.md)

**Skill Discovery Mechanism:** Build-With-Skills and Plan-With-Skills use **hardcoded skill lists** embedded in system prompts. Use `opencode-skills-maintainer` skill to update agents when skills change.

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

### Documentation (README.md)

**Sections:** Brief description (1-2 sentences), Prerequisites with installation commands, Setup instructions (automated + manual), Configuration overview, Usage examples, Troubleshooting

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

**Missing Dependencies:** Check for required tools (nvm, node, npm, jq, curl), provide installation guidance

**Agent Skill Discovery Issues:** Verify skill is in `skills/` folder and run `opencode-skills-maintainer`, check skill name matches frontmatter exactly

## Making Changes

**config.json:** Update MCP server URLs, model names, or agent prompts, validate JSON, test with `opencode --agent <name>`

**setup.sh:** Modify installation logic, validate shell syntax, test in dry-run mode first

**README.md:** Keep in sync with config.json, update MCP server documentation, add new agent descriptions

**Skills:** Follow SKILL.md format, update metadata for compatibility, test skill invocation

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
7. Run `opencode-skills-maintainer` after skill changes

## Important Notes

- This is a **template repository** - deployed to user config directory
- No package.json, build system, or test framework exists
- Changes must preserve backward compatibility
- Always use environment variables for sensitive configuration
- Document breaking changes in README.md
- Skills folder is copied recursively during setup
- OpenCode config directory: `~/.config/opencode/`
- **Hardcoded Skill Lists**: Build-With-Skills and Plan-With-Skills use embedded skill lists for zero-latency discovery
- **Skill Maintenance**: Use `opencode-skills-maintainer` to keep agents synchronized with available skills
