# OpenCode Docker Standalone Configuration

This file contains instructions for OpenCode running in Docker standalone mode.

## Environment

This is a **containerized OpenCode instance** running as a web endpoint. Key differences from user-space mode:

- No local filesystem access beyond `/app` and mounted volumes
- MCP servers that require local GUI apps (LM Studio, etc.) are disabled
- API keys are injected at runtime via `docker-entrypoint.sh`
- All agents and skills are loaded from `.opencode/` within the container

## Task Delegation Order

1. **Agents/Subagents (First Priority)** - Delegate to specialized subagents
2. **Skills (Second Priority)** - Load skills when no matching subagent exists
3. **Direct Handling (Last Resort)** - Handle directly only when necessary

## Available Agents

Agents are loaded from `.opencode/agents/` — these are symlinked from the repository's `agents/` directory at build time.

## Available Skills

Skills are loaded from `.opencode/skills/` — these are symlinked from the repository's `skills/` directory at build time.

## Docker-Specific Notes

- Port: 4096 (internal), mapped to 4097 by default
- Health check: `GET /global/health`
- Auth keys: Injected from environment variables via entrypoint
- Data persistence: `/home/opencode/.local/share/opencode` (named volume)
