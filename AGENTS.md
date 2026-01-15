# Agent Guidelines for OpenCode Agentic Development Framework

This repository is an **agentic development framework** for building and orchestrating coding agents locally. The `config.json` file defines agents, their capabilities, and how they collaborate to create an ever-extending agentic approach for app development.

## Repository Structure

- `config.json` - Central configuration defining agents, models, providers, and MCP servers
- `setup.sh` - Interactive setup script for environment configuration
- `README.md` - Setup and usage documentation

## Build/Lint/Test Commands

**No traditional build, lint, or test commands.** This is an agentic configuration framework.

To verify changes:
- Validate JSON syntax: `jq . config.json` or `python3 -m json.tool config.json`
- Check shell script syntax: `bash -n setup.sh`
- Test setup script: `bash setup.sh` (in sandbox environment first)
- Test agent invocation: Run OpenCode and verify agents load correctly

## Code Style Guidelines

### Configuration Files (config.json)

- **Schema**: Follows OpenCode config schema at https://opencode.ai/config.json
- **Environment Variables**: Use `${VAR_NAME}` syntax for sensitive values (never hardcode API keys)
- **MCP Servers**: Define all MCP servers under `mcp` section with proper type (local/remote)
  - **GitHub MCP Server**: Use remote type with OAuth for authentication
    ```json
    "github": {
      "type": "remote",
      "url": "https://api.githubcopilot.com/mcp/",
      "oauth": {}
    }
    ```
    Authenticate with: `opencode mcp auth github`
  - Alternatively, use GitHub PAT with `oauth: false` and `headers` for Authorization
- **Agent Configuration**: Each agent under `agent` section must include:
  - `description`: Clear agent purpose in the agentic workflow
  - `mode`: "subagent" for specialized agents that can be called by others
  - `model`: Provider and model identifier (consider capability vs cost tradeoffs)
  - `prompt`: Detailed behavior instructions including:
    - When to invoke other agents
    - What information to gather before acting
    - How to format outputs for agent-to-agent communication
    - Error handling and recovery strategies
  - `tools`: Explicit tool permissions (read, write, edit, specific MCP servers)
  - `mcp`: MCP server dependencies with `enabled` status

### Agent Design Patterns

- **Single Responsibility**: Each agent should have one primary capability
- **Composability**: Design agents to work together in chains (e.g., researcher → planner → coder → reviewer)
- **Clear Handoffs**: Explicitly state how/when to delegate to other agents
- **State Awareness**: Agents should understand their role in the larger workflow
- **Idempotency**: Agent operations should be safe to retry
- **Tool Minimization**: Grant only necessary tools to reduce risk
- **GitHub Integration**: Use GitHub MCP tools for repository operations, issue management, PR reviews, Actions workflows. Note: GitHub MCP can add significant context overhead

### Shell Scripts (setup.sh)

- **Shebang**: Always `#!/bin/bash`
- **Error Handling**: Start with `set -e` to exit on errors
- **User Interaction**: All destructive operations require confirmation prompts (y/n)
- **Version Checks**: Compare installed vs latest versions before updates
- **Idempotency**: Scripts should be safe to run multiple times
- **Output**: Use `echo` with clear section headers (`=== Section ===`)
- **Security**: Never echo raw API keys; always mask: `${VAR:0:8}...${VAR: -4}`

### Documentation (README.md)

- **Prerequisites**: List all required tools with installation commands
- **Code Blocks**: Use triple backticks with bash language specifier
- **Environment Variables**: Document required variables with setup instructions
- **Troubleshooting**: Include common issues and resolution steps

## Naming Conventions

- Files: lowercase with hyphens (kebab-case): `config.json`, `setup.sh`
- JSON keys: camelCase for standard fields, lowercase for MCP/server names
- Environment variables: UPPERCASE with underscores: `ZAI_API_KEY`, `NVM_DIR`

## Error Handling

- Shell scripts: Use `set -e` and check command existence before execution
- User prompts: Provide clear confirmation options for destructive operations
- Missing dependencies: Check for required tools (nvm, node, npm) and provide installation guidance
- Configuration: Validate config.json exists and is valid JSON before use

## Making Changes

- **config.json**: Update MCP server URLs, model names, or agent prompts only
- **setup.sh**: Modify installation logic or add new setup steps as needed
- **README.md**: Keep documentation in sync with configuration changes
- **Security**: Never commit actual API keys or sensitive data

## Testing Changes

1. Validate JSON syntax: `jq . config.json`
2. Check shell script: `bash -n setup.sh`
3. Dry-run setup script in test environment
4. Verify config schema follows https://opencode.ai/config.json
5. Test actual deployment to `~/.config/opencode/`

## Important Notes

- This is a **template repository** - contents are deployed to user config directory
- No package.json, build system, or test framework exists
- Changes should preserve backward compatibility
- Always use environment variables for sensitive configuration
- Document any breaking changes in README.md
