# Repository-Specific Agent Instructions

Project-specific behavioral rules for agents working in this repository. Usage docs (install, deploy commands, file tree, CodeGraph, subagent chaining syntax) live in `README.md` and the user-level `deploy/.AGENTS.md` — do not duplicate them here.

## Repository Purpose

`opencode-config-template` is a **dual-mode OpenCode configurator**:
1. **User-space deploy** — `./deploy/setup.sh` copies config, agents, and skills to `~/.config/opencode/`
2. **Docker standalone** — `docker compose up -d` launches OpenCode as a web endpoint via `opencode_app/`

This repo-level `AGENTS.md` defines repo-specific conventions. User-level routing (subagent/skill selection, MCP tool routing) is in `deploy/.AGENTS.md` (deployed to `~/.config/opencode/AGENTS.md`).

## Source of Truth

`opencode_app/.opencode/` is the **single source** for agents and skills. Never edit deployed `~/.config/opencode/` copies directly — edit the source, then redeploy.

## Subagent Locations

| Location | Scope | Deployed? |
|----------|-------|-----------|
| `opencode_app/.opencode/agents/*.md` | Global (all projects) | Yes — copied by `deploy/setup.sh` |
| `.opencode/agents/*.md` | Project-only | No — stays in repo |

Project-level agents must NOT be counted in setup scripts or README.

## Subagent Model Tiering

Subagents are right-sized by purpose; only the primary session uses the 1M-context model. All IDs are `zai-coding-plan/<id>` (verified against [models.dev](https://models.dev/providers/zai-coding-plan/)).

| Model | Context | Use for |
|-------|---------|---------|
| `glm-5.2` | 1,000,000 | **Primary session only** — holds the long orchestrator context. No subagent uses this. |
| `glm-5.1` | 200,000 | Sound-reasoning (17): reviewers (code-review, architecture-review, python/java/go/rust/typescript-reviewer), repo-ops-specialist, tdd, opentofu-explorer, loop-operator, opencode-tooling, technical-design-specialist, autoresearch-ml, autoresearch-code, uiux-reviewer, responsive-audit |
| `glm-5-turbo` | 200,000 | Exploratory / low-impact / coordination (17): explorer, testing, pr-workflow, ticket-creation, discovery-specialist, requirements-specialist, autoresearch-research, nextjs-specialist, cad-specialist, microsoft-m365-specialist, google-mcp-specialist, docx-creation, xlsx-specialist, pptx-specialist, startup-ceo, startup-founder-primary, office-document-primary |
| `glm-5v-turbo` | 200,000 | **Vision required**: image-analyzer, error-resolver. No structured output. |
| `glm-4.7` | 204,800 | Docs/lint/reporting: documentation, linting, coverage |

Pick the tier by what the agent *does*: correctness-critical → 5.1; exploratory/low-impact → 5-turbo; vision → 5v-turbo; docs/lint → 4.7. **Never default a subagent to `glm-5.2`.**

## Adding Skills or Subagents — Sync Rules

When adding/removing a skill or subagent, update these files to maintain synchronization:

| Trigger | What to Update |
|---------|---------------|
| New/removed MCP server | MCP count, auto-start listing, help text |
| New/removed skill | Skill count, category listing, banner |
| New/removed agent | Agent count, help text listing |
| Config changes (`opencode.json`) | MCP server entries if added/removed |

| File | Update Type |
|------|-------------|
| `deploy/setup.sh` | Skill/agent listings and counts (banner + status sections) |
| `deploy/setup.ps1` | Mirror of setup.sh (Windows parity) |
| `README.md` | Skill Categories and Subagents tables |
| `opencode_app/README.md` | Docker-specific docs if relevant |

After changes, invoke the `documentation-sync-workflow` skill or delegate to `opencode-tooling-subagent` for guided synchronization.

## Return Contract Convention

All subagents return this structure to minimize context bloat:

**Status:** [success | partial | failed]
**Output:** [file path(s) or key result, one line]
**Summary:** [2-3 sentences max]
**Issues:** [blockers, warnings, or "None"]

Additive signal fields (e.g., `NEEDS_GIT_BRANCH_SETUP: true`) are allowed beyond the required quartet but never replace the required fields.

## Project Learnings

`LEARNINGS/` is a template in this repo. In target projects (where skills are deployed), check `LEARNINGS/` for existing patterns before reviewing or planning. Primary storage: `memory` tool (searchable). Secondary: `LEARNINGS/*.md` (git-committed).

## Extract-then-Delegate Pattern

When a subagent needs domain knowledge, the primary agent loads the skill, extracts relevant parameters, and passes ONLY those params to the subagent. This keeps heavy knowledge in the compactable primary context rather than the subagent's isolated context.
