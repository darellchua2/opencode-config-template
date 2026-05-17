# Repository-Specific Agent Instructions

This file contains project-specific instructions for agents working in this repository.

## Repository Overview

This is `opencode-config-template` - a dual-mode configurator repository for OpenCode:

1. **User-Space Deploy**: Running `setup.sh` copies config, agents, and skills to `~/.config/opencode/`
2. **Docker Standalone**: A `docker-compose.yml` + `opencode_app/` launches OpenCode as a web endpoint

## Deployment Modes

### Mode 1: User-Space Deploy

Run `setup.sh` to deploy configuration:
- `config.json` → `~/.config/opencode/config.json`
- `.AGENTS.md` → `~/.config/opencode/AGENTS.md`
- `opencode_app/.opencode/skills/*` → `~/.config/opencode/skills/`
- `opencode_app/.opencode/agents/*` → `~/.config/opencode/agents/`

### Mode 2: Docker Standalone

```bash
cp .env.example .env   # Edit with your API keys
docker compose up -d   # Start OpenCode on http://localhost:4097
```

## File Structure

```
opencode-config-template/
├── config.json          # Agent definitions and MCP config (user-space)
├── .AGENTS.md           # User-space subagent routing (deployed)
├── AGENTS.md            # Repo-level instructions (this file)
├── setup.sh             # User-space deployment script
├── setup.ps1            # User-space deployment script (Windows)
├── docker-compose.yml   # Docker Compose for standalone mode
├── .env.example         # Environment variable template
├── .env                 # Local environment (git-ignored)
├── opencode_app/        # Docker standalone mode
│   ├── Dockerfile       # Container image (COPY . /app/)
│   ├── docker-entrypoint.sh  # API key injection + opencode serve
│   ├── opencode.json    # Container-specific config
│   ├── AGENTS.md        # Container-specific instructions
│   ├── README.md        # Docker usage guide
│   ├── .dockerignore    # Build exclusions
│   └── .opencode/
│       ├── agents/      # 31 subagent .md files (single source of truth)
│       └── skills/      # 57+ skill directories (single source of truth)
└── .opencode/
    └── agents/          # Project-level subagents (NOT deployed)
```

## Shared Config Strategy

Agents and skills have a **single source of truth** in `opencode_app/.opencode/`:
- `opencode_app/.opencode/agents/` — All 31 subagent definitions
- `opencode_app/.opencode/skills/` — All 57+ skill directories

For **user-space**: `setup.sh` and `setup.ps1` copy from `opencode_app/.opencode/` to `~/.config/opencode/`
For **Docker**: The Dockerfile `COPY . /app/` includes `.opencode/` in the container

## Subagent Locations

| Location | Scope | Deployment |
|----------|-------|------------|
| `opencode_app/.opencode/agents/*.md` | Global (all projects) | Copied to `~/.config/opencode/agents/` by setup.sh |
| `.opencode/agents/*.md` | Project-only | Stays in repo, not deployed |

**Project-Level Subagents:**
- `mermaid-diagram-subagent` - Creates Mermaid diagrams with PNG conversion and integrated with planning workflows

## Adding New Subagents or Skills

When adding a new subagent or skill, you MUST update these files to maintain synchronization:

### Files to Update

| File | Update Type |
|------|-------------|
| `setup.sh` | Skill/agent listings and counts |
| `setup.ps1` | Skill/agent listings and counts |
| `README.md` | Skill Categories and Subagents tables |
| `opencode_app/README.md` | Docker-specific docs if relevant |

### Quick Checklist

For new skills:
- [ ] Add skill directory to `opencode_app/.opencode/skills/`
- [ ] Increment total skill count in setup.sh and setup.ps1
- [ ] Add skill to appropriate category in both setup files
- [ ] Update README.md Skill Categories table

For new **global** subagents:
- [ ] Add `.md` file to `opencode_app/.opencode/agents/`
- [ ] Add row to README.md Subagents table
- [ ] Update total subagent count in README.md

For new **project-level** subagents (in `.opencode/agents/`):
- [ ] Do NOT add to README.md (not deployed globally)
- [ ] Do NOT update setup.sh or setup.ps1 counts

### Use the Sync Workflow

Invoke the `documentation-sync-workflow` skill or delegate to `opencode-tooling-subagent` for guided synchronization:

```
opencode --skill documentation-sync-workflow "sync docs after adding new skill"
```

## Return Contract Convention

All subagents follow a standardized return contract to minimize context bloat when reporting back to the primary agent:

**Status:** [success | partial | failed]
**Output:** [file path(s) or key result, one line]
**Summary:** [2-3 sentences max]
**Issues:** [blockers, warnings, or "None"]

On failure, subagents MAY include additional diagnostic information. This convention is documented in each subagent's `.md` file and should be followed when creating new agents.

## Extract-then-Delegate Pattern

When a subagent needs domain knowledge, prefer having the primary agent load the skill, extract relevant parameters, and pass ONLY those parameters to the subagent. This keeps heavy knowledge in the primary agent's context (which compacts) rather than the subagent's isolated context.

Example: Instead of startup-ceo loading startup-pitch-deck-skill internally, the primary agent loads the skill, extracts the deck specification, and passes only the spec to startup-ceo.

## Subagent Chaining

OpenCode supports subagent-to-subagent delegation via the Task tool. The `permission.task` frontmatter field controls which subagents an agent can spawn.

### Key Facts

- **Task tool** (subagent spawning) and **Skill tool** (skill loading) are separate systems with separate permissions
- Agent name = filename minus `.md` (e.g., `code-review-subagent.md` -> `code-review-subagent`)
- Denied subagents are hidden from the Task tool description entirely
- Wildcard `*` matches zero+ characters; last matching rule wins
- Each spawned subagent gets its own session, context, and step budget
- Hub-and-spoke (primary -> subagent) remains the recommended pattern

### Task Permission Syntax

```yaml
permission:
  task: allow                    # Full access to all subagents
  task:                          # Selective access
    "*": deny                    # Deny all by default
    explore: allow               # Allow built-in explore
    general: allow               # Allow built-in general
    "reviewer-*": allow          # Glob pattern matching
```

### Current Permission Distribution

| Pattern | Count | Notes |
|---------|-------|-------|
| `task: allow` | 1 | startup-founder-primary-agent |
| `task: { "*": deny, built-in: allow }` | 5 | code-review, linting, pr-workflow, refactoring, testing |
| No `task` field | 24 | Defaults to full access |
