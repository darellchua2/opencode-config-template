# Repository-Specific Agent Instructions

Project-specific behavioral rules for agents working in this repository. Usage docs (install, deploy commands, file tree, CodeGraph, subagent chaining syntax) live in `README.md` and the user-level `deploy/.AGENTS.md` — do not duplicate them here.

## Repository Purpose

`opencode-config-template` is a **multi-mode OpenCode configurator**:
1. **User-space deploy** — `./deploy/setup.sh` copies config, agents, and skills to `~/.config/opencode/`
2. **Docker standalone** — `docker compose up -d` launches OpenCode as a web endpoint via `opencode_app/`
3. **Individual install (npx)** — `npx github:darellchua2/opencode-config-template add <name>` pulls a single skill or agent into your config (shadcn-style copy model). Default target is `~/.config/opencode/` (auto-discovered, no config touch); `--project` opts into `./.opencode/`; `--format claude|both` writes to `~/.claude/skills/` for Claude Code compat (same Agent Skills open standard). See [issue #304](https://github.com/darellchua2/opencode-config-template/issues/304).

This repo-level `AGENTS.md` defines repo-specific conventions. User-level routing (subagent/skill selection, MCP tool routing) is in `deploy/.AGENTS.md` (deployed to `~/.config/opencode/AGENTS.md`).

## Source of Truth

`opencode_app/.opencode/` is the **single source** for agents and skills. Never edit deployed `~/.config/opencode/` copies directly — edit the source, then redeploy.

## Secret Masking

Vibeguard (`opencode-vibeguard@0.1.0`) masks `.env` secrets in provider-bound traffic via regex patterns (`opencode_app/.opencode/vibeguard.config.json`). Behavioral rules for all agents are in `deploy/.AGENTS.md` §Secret Hygiene; verification + per-project overlay procedure is in `security-audit-skill`. Residual risks (`/share` plaintext, no fail-closed, session DB stores plaintext) are documented there.

## Dependency Management

`package-lock.json` is committed. Dependency changes MUST run `npm install` and commit the regenerated lockfile — `npm ci` hard-fails on drift.

## Subagent Locations

| Location | Scope | Deployed? |
|----------|-------|-----------|
| `opencode_app/.opencode/agents/*.md` | Global (all projects) | Yes — copied by `deploy/setup.sh` |
| `.opencode/agents/*.md` | Project-only | No — stays in repo |

Project-level agents must NOT be counted in setup scripts or README.

## Subagent Model Tiering (v2.0)

Subagents are right-sized by purpose into **4 tiers**. The tier for each agent
lives in `deploy/agent-tiers.json`; concrete models are **resolved at deploy
time** from `deploy/models.default.json` (Z.AI defaults) and are **provider-
agnostic** — swap to Anthropic/OpenAI/OpenRouter/LM Studio via
`deploy/provider-presets.json` without editing agent files. See `MIGRATION.md`.

| Tier | Default model (Z.AI) | Use for |
|------|----------------------|---------|
| `primary` | `glm-5.2` (1M ctx) | **Primary session only** — holds the long orchestrator context. No subagent uses this. |
| `reasoning` | `glm-5.2` (200k) | Correctness-critical: reviewers (code/architecture/language incl. java/uiux), repo-ops-specialist, tdd, opentofu-explorer, loop-operator, opencode-tooling, technical-design-specialist, discovery-specialist, requirements-specialist, autoresearch-ml, autoresearch-code |
| `fast` | `glm-5-turbo` (200k) | Exploratory / low-impact / coordination: explorer, testing, specialists (nextjs/cad/office-docs), document creators, pr-workflow, autoresearch-research |
| `docs` | `glm-4.7` (204k) | Docs/lint/reporting: documentation, linting, coverage. |
| `vision` | `zai/glm-5v-turbo` (128k) | **Native multimodal** — `image-analyzer-subagent` + `error-resolver-subagent` use this tier and see images/screenshots directly (no external vision API / no skill). The `zai` provider (per models.dev) exposes `glm-4.6v` ($0.30/$0.90), `glm-4.5v`, `glm-5v-turbo`. |

Pick the tier by what the agent *does*: correctness-critical → `reasoning`;
exploratory/low-impact → `fast`; docs/lint → `docs`; native image perception → `vision`. **Never
default a subagent to the `primary` tier.**

> **Image / screenshot analysis:** `image-analyzer-subagent` and `error-resolver-subagent` are
> **native multimodal** — they run on `zai/glm-5v-turbo` (vision tier) and perceive images directly.
> When native perception is unavailable (vision MCP server not connected, "model does not support
> image input", or a text-only session), they fall back to a **direct Z.AI vision API call** to the
> same `glm-5v-turbo` model via `zai-vision-analysis-skill` (coding-plan endpoint preferred, PAAS
> fallback). Requires Z.AI auth / `ZAI_API_KEY`. The free `glm-4.6v-flash` endpoint remains
> available as a cost-constrained option but is no longer the default.

### Resolution precedence (highest wins)
1. `<project>/.opencode/agent-overrides.json` (per-agent, project-local)
2. `~/.config/opencode/agent-overrides.json` (per-agent, global)
3. `<project>/.opencode/models.json` (tier map, project-local)
4. `~/.config/opencode/models.json` (tier map, global)
5. `deploy/models.default.json` (Z.AI defaults)

Swap provider: `./deploy/setup.sh --provider anthropic` (or interactive).
**Mix providers per category**: `./deploy/setup.sh --mix` — each of
`primary`/`reasoning`/`fast`/`docs`/`vision` can use a different provider's model
(e.g. Z.AI everywhere except `vision` on OpenAI); stored in `models.json`, so
resolve without `--provider`. Each referenced provider must be authenticated in
OpenCode. Re-resolve: `./deploy/setup.sh --models-only`. Per-agent pin: edit
`~/.config/opencode/agent-overrides.json`. Built-in agents `explore`→`fast` and
`general`→`reasoning` are patched in `opencode.json`, not via the tier registry.

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

### Reviewer Additions (architecture, code, python, typescript, java, go, rust, uiux)

**Patterns applied/violated:** `[{id: <LEARNINGS-slug>, status: applied|violated, evidence: <file:line or review-section ref>}]`
- **Required** for all reviewer subagents on every review.
- If no LEARNINGS pattern applied or was violated, emit `Patterns applied/violated: []` (empty list, never omit).

## Project Learnings

`LEARNINGS/` is a template in this repo. In target projects (where skills are deployed), check `LEARNINGS/` for existing patterns before reviewing or planning. Primary storage: `memory` tool (searchable). Secondary: `LEARNINGS/*.md` (git-committed). The `learnings-autoinject` plugin auto-surfaces a `LEARNINGS/*.md` manifest into the system prompt each session (on by default; `/learnings-off` to disable, `/learnings-refresh` after adding files mid-session), so manual `glob`+`read` is a fallback, not the primary discovery path.

## Extract-then-Delegate Pattern

When a subagent needs domain knowledge, the primary agent loads the skill, extracts relevant parameters, and passes ONLY those params to the subagent. This keeps heavy knowledge in the compactable primary context rather than the subagent's isolated context.

## Office Document Extraction Routing

Binary office docs (`.docx`, `.pptx`, `.xlsx`, born-digital `.pdf`) need an extraction engine — `Read` cannot parse them. Route by content type, escalating only when the cheaper tier is insufficient. **This section is the single source of truth** — skills and subagents reference it rather than duplicating the decision tree.

| Tier | Engine | Best for | Enable |
|------|--------|----------|--------|
| 1 | **markitdown** (MCP) | Fast text dumps of born-digital docs (~1s/50 pages, no cloud calls) | `--enable-pack markitdown` |
| 2 | **docling** (CLI-on-demand or MCP) | Layout-aware extraction: complex tables, multi-column, scanned PDFs where markitdown returns garbage | CLI: `pip install --user docling` (ask consent — ~3-4 GB); MCP: `--enable-pack docling` |
| 3 | **image-analyzer-subagent** | Visual understanding: charts, diagrams, screenshots, "what does this look like" | always available (native multimodal) |
| 4 | **pdf-specialist-skill** | Structured PDF data: forms, fillable fields, OCR-as-purpose, post-edit | load skill |

**Default state:** markitdown and docling are both opt-in (disabled). When markitdown is disabled, tell the user to run `--enable-pack markitdown`. When markitdown output is insufficient (complex layout, scanned), escalate to docling — if absent, ask consent via `question` for the heavy install (never auto-install 3-4 GB). In headless/CI contexts, soft-fail to markitdown's best-effort output.
