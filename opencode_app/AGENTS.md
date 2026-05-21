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

## CodeGraph MCP Server

[CodeGraph](https://github.com/colbymchenry/codegraph) is a pre-indexed code knowledge graph MCP server. It builds a local SQLite database of symbol relationships and call graphs for instant codebase queries.

### Per-Project Setup

```bash
codegraph init -i
```

This creates a `.codegraph/` directory with an indexed database. Add `.codegraph/` to `.gitignore`.

### MCP Tool Routing

| Capability | Primary | Fallback | Reason |
|---|---|---|---|
| Codebase exploration | `codegraph_explore` / `codegraph_context` | grep/glob chains | Structured graph results, fewer tool calls |
| Symbol lookup | `codegraph_search` / `codegraph_node` | grep | Instant name-based lookup |
| Call tracing | `codegraph_callers` / `callees` | grep imports | Graph-based, transitive |
| Impact analysis | `codegraph_impact` | Manual file search | Traces dependency chains |
| File structure | `codegraph_files` | glob | Indexed, faster |

### Subagent Integration

The following subagents have CodeGraph instructions in their `.md` files and will use CodeGraph automatically when `.codegraph/` exists:

| Subagent | Key CodeGraph Tools |
|---|---|
| `explorer-subagent` | `codegraph_explore`, `codegraph_context`, `codegraph_search`, `codegraph_files` |
| `code-review-subagent` | `codegraph_impact`, `codegraph_callers`/`callees`, `codegraph_search` |
| `architecture-review-subagent` | `codegraph_callers`/`callees`, `codegraph_explore`, `codegraph_impact` |
| `refactoring-subagent` | `codegraph_callers`, `codegraph_impact`, `codegraph_search` |
| `testing-subagent` | `codegraph_files`, `codegraph_search` |
