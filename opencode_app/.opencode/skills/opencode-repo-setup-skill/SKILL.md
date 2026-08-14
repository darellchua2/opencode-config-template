---
name: opencode-repo-setup-skill
description: Interactive per-repo MCP and tooling setup for a target project. Detects repo signals (manifests, .codegraph/, Jira/GitHub refs), asks the user which opt-in MCP servers to enable, merge-writes only the delta into the project's .opencode/opencode.json (project config overrides global; global config never mutated), optionally initializes CodeGraph, and reports enabled set, token cost, and revert path. Triggers on "set up mcp for this repo", "enable atlassian/jira here", "project mcp setup", "repo setup", "per-project enable", "configure project opencode".
license: Apache-2.0
compatibility: opencode
metadata:
  audience: agent
  workflow: scaffolding
category: OpenCode Meta
---

## What I do

I am the **interactive frontend for per-project MCP enablement**. The global deploy ships most MCP servers disabled (zero always-on schema cost); this skill is how a specific repo opts in. I run in the primary session of the TARGET project (not the configurator repo):

1. **Detect** — scan the repo for setup signals
2. **Ask** — present a question-tool menu of opt-in servers + extras
3. **Write** — merge-write ONLY the delta into `<repo>/.opencode/opencode.json`
4. **Init** — optionally run `codegraph init -i`
5. **Report** — enabled set, estimated token cost, revert instructions

I never edit the global `~/.config/opencode/config.json`. Opencode merges project config over global with **project wins** semantics, so a one-key delta is all that's needed.

## When to use me

- User says "set up MCP for this repo", "enable Jira/Atlassian here", "project-level opencode setup"
- A marker rule fired (user AGENTS.md may say: if a repo's AGENTS.md mentions Jira/MCP needs, offer this skill)
- First session in a repo that carries its own `.opencode/` — offer to review/extend it

## Step 1 — Detect

Cheap, read-only scans (no network):

| Signal | Check | Suggests |
|--------|-------|----------|
| Existing project config | `<repo>/.opencode/opencode.json` exists | Idempotent mode: show current overrides, offer to extend |
| CodeGraph index | `<repo>/.codegraph/` exists | codegraph already enabled locally; no action |
| Jira usage | AGENTS.md/README mentions Jira keys (`PROJ-123`), JIRA env vars, `atlassian` refs | offer `atlassian` enable |
| GitHub-centric | `.github/`, `gh` in scripts | gh CLI usually suffices; no MCP needed |
| Docs-heavy | `.docx`/`.pptx`/`.pdf` in repo | offer markitdown/docling packs |
| Frontend | `package.json` with next/react | offer next-devtools |
| Python | `pyproject.toml` | nothing MCP-specific by default |

Report findings in one table, then go to Step 2.

## Step 2 — Ask (question tool)

One multi-select question + one yes/no per extra. Options are built from the detection table — only show servers with a detected signal plus the general opt-in list:

**MCP enables** (any of):
- `atlassian` — Jira/Confluence tools (~5–6.5k tok/session when enabled; see caveats below)
- `zai-vision-mcp-server` — image analysis tools (~0.9k; native-multimodal agents may not need it)
- `zai-zread` — GitHub repo browsing tools (~0.3k)
- markitdown / docling / chrome-devtools / next-devtools — via global `--enable-pack` if not already enabled

**Extras**:
- "Initialize CodeGraph index? (`codegraph init -i`)" — only if `.codegraph/` absent and repo is code-heavy
- "Scaffold a minimal project AGENTS.md?" — repo rules only; NO MCP prose (that belongs to config + this skill)

## Step 3 — Write (merge-write, delta-only)

Target: `<repo>/.opencode/opencode.json`. Create if absent; **never clobber existing keys** — deep-merge at the top level manually (read file, add only the `mcp.<server>.enabled` keys chosen). Keep the file comment-free JSON.

Typical delta:

```json
{
  "mcp": {
    "atlassian": { "enabled": true }
  }
}
```

Rules:
- Only `enabled` keys — auth/transport stay as globally configured (Atlassian uses `mcp-remote` OAuth; see caveats)
- If the file exists, preserve every other key verbatim (byte-stable elsewhere; pretty-print 2-space)
- Never write `enabled: false` to disable something globally enabled — the project layer is for opting IN

## Step 4 — Init (CodeGraph only)

If accepted and `.codegraph/` absent: run `codegraph init -i` in the repo root. If `codegraph` is not installed or the repo is non-code/very large, soft-skip with a note. In headless/CI: skip silently unless explicitly requested.

## Step 5 — Report

State exactly:

- **Enabled here**: list (e.g. `atlassian`) — takes effect on NEXT session start (opencode reads config at startup; no lazy-start mid-session)
- **Estimated per-session cost**: atlassian ~5–6.5k tok; zai-vision ~0.9k; zread ~0.3k; codegraph ~1.2k (already default-on)
- **Revert**: delete the added `mcp.<server>` keys (or the whole file if we created it)
- **Global untouched**: `~/.config/opencode/config.json` unchanged; other repos unaffected

## Atlassian caveats (read before enabling)

- **First use opens a browser OAuth flow** (mcp-remote → mcp.atlassian.com). Fine on desktop; **fails headless/CI**.
- Headless fallback = skip MCP, use REST: token at id.atlassian.com/manage-profile/security/api-tokens (scoped tokens must use `api.atlassian.com/ex/jira/{cloudId}`; unscoped use site-direct `/rest/api/3/`), auth via `curl -u email:token`; discover cloudId unauthenticated at `https://<site>.atlassian.net/_edge/tenant_info`.
- Delegation pattern: even when enabled, route bulk Jira calls through a subagent to keep tool output out of the primary context (schemas are paid regardless of who calls).

## Governance

| Aspect | Source of truth |
|--------|----------------|
| Server inventory + default enable states | `opencode_app/opencode.json` `mcp` block of the configurator repo |
| Config layering (project wins) | opencode docs — config merge semantics |
| CodeGraph init | CodeGraph §pre-flight conventions (user AGENTS.md) |

This skill deliberately contains no server versions, URLs beyond Atlassian REST constants, or token costs beyond the estimates above — refresh from the configurator repo's README MCP table when drifting.
