# opencode_app — Docker Standalone Mode

This directory contains everything needed to run OpenCode as a standalone Docker container accessible via web browser.

## Quick Start

```bash
# From the repository root:
cp .env.example .env
# Edit .env — set ZAI_API_KEY=your-key-here
docker compose up -d
# Access at http://localhost:4097
```

## Directory Structure

```
opencode_app/
├── Dockerfile             # Multi-stage: node:24 + opencode-ai + python3
├── docker-entrypoint.sh   # Injects API keys, starts opencode serve
├── opencode.json          # Container-specific config (providers, agents)
├── AGENTS.md              # Agent instructions for container mode
├── .dockerignore          # Excludes _archived, .env, node_modules
└── .opencode/
    ├── agents/            # 31 agent .md files (single source of truth)
    └── skills/            # 60 skill directories (single source of truth)
```

## How It Works

1. **Build**: `docker compose build` uses `opencode_app/` as build context. The Dockerfile copies everything (including `.opencode/agents/` and `.opencode/skills/`) into `/app/`.
2. **Runtime**: `docker-entrypoint.sh` reads API keys from environment variables, writes them to `auth.json`, then runs `opencode serve --port 4096 --hostname 0.0.0.0`.
3. **Access**: Port 4096 inside the container maps to 4097 on the host (configurable via `OPENCODE_PORT` in `.env`).

## Environment Variables

Set these in the root `.env` file (copied from `.env.example`):

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `ZAI_API_KEY` | Yes | — | Z.AI API key (primary LLM provider) |
| `GEMINI_API_KEY` | No | — | Gemini API key (secondary provider) |
| `OPENCODE_PORT` | No | `4097` | External host port |

## Docker Commands

```bash
# Start in background
docker compose up -d

# View logs
docker compose logs -f

# Stop
docker compose down

# Rebuild after changes to agents/skills/config
docker compose build --no-cache

# Verify container contents
docker run --rm --entrypoint ls opencode_app-opencode /app/.opencode/agents/
docker run --rm --entrypoint ls opencode_app-opencode /app/.opencode/skills/
docker run --rm --entrypoint whoami opencode_app-opencode
```

## Security

- Container runs as non-root `opencode` user
- No secrets baked into the image — API keys injected at runtime via entrypoint
- `.dockerignore` excludes `.env`, `_archived/`, and dev files
- Health check: `GET /global/health` every 30s

## Updating Agents and Skills

Agents and skills live in `.opencode/agents/` and `.opencode/skills/`. These are the **single source of truth** shared with the user-space deployment (`setup.sh` copies from these same directories).

After modifying agents or skills:

```bash
docker compose build --no-cache
docker compose up -d
```

## CodeGraph

CodeGraph is a pre-indexed code knowledge graph MCP server enabled by default. It provides instant symbol search, call graph tracing, and impact analysis — reducing exploration tool calls by ~94%.

- **No API keys** — 100% local SQLite
- **Auto-sync** — file watcher keeps the index fresh
- **Per-project setup** required: `codegraph init -i` in each project directory

See the main `README.md` for full details on MCP tools, supported languages, and subagent integration.

## Subagent Chaining

OpenCode supports subagent-to-subagent delegation via the Task tool, controlled by the `permission.task` frontmatter field in each agent `.md` file. Key points:

- **Task tool** (subagent spawning) and **Skill tool** (skill loading) are separate systems with separate permissions
- Agent name = filename minus `.md` (e.g., `code-review-subagent.md` -> `code-review-subagent`)
- Each spawned subagent gets its own session, context window, and step budget
- Hub-and-spoke (primary agent -> subagent) remains the recommended pattern
- 9 of 30 agents have explicit `task` permissions; the remaining 21 default to full access
