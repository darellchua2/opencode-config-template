# PLAN-GIT-329 — Add privacy-hardened chrome-devtools MCP server for frontend agents/skills

**Issue:** https://github.com/darellchua2/opencode-config-template/issues/329
**Branch:** `feat/329-chrome-devtools-mcp`
**Labels:** enhancement, mcp, privacy, size: M

## Overview

The official Chrome DevTools MCP server (`chrome-devtools-mcp`) exposes 50+ tools for live-browser automation: input/navigation/emulation, performance traces, network/console debugging, Lighthouse audits, heap snapshots, and screencasts. It pairs naturally with this repo's existing Playwright-based frontend agents (`responsive-audit-subagent`, `uiux-reviewer-subagent`, `accessibility-a11y-skill`).

Privacy concern (the reason this plan is "privacy-hardened"): by default the server sends data to Google — usage statistics (telemetry), CrUX API (performance traces send page URLs to Google's Chrome User Experience Report), and update checks hit npm. It also exposes ALL browser content (cookies/session/DOM) to the MCP client. This repo's privacy ethos (vibeguard, local-only markitdown) is the opposite of that default, so the config MUST ship with every opt-out enabled.

No Playwright removal, no new agent, no new skill. A second browser-driver path is added as opt-in; the overlap decision is recorded below.

## Overlap decision (recorded, drives scope)

These agents already depend on Playwright (via `bash`/PTY, not an MCP server):
- `responsive-audit-subagent` + `playwright-responsive-audit-skill`
- `uiux-reviewer-subagent` + `uiux-review-skill`
- `accessibility-a11y-skill` (axe-core/Lighthouse via CLI)

**Decision:** keep Playwright for code-level test assertions and CI reproducibility. Use `chrome-devtools` MCP only for live-site visual capture + native `lighthouse_audit`. Do NOT rip out Playwright in this plan. Agent prompt edits to mention the new MCP are out of scope here (separate issue if desired).

## Acceptance Criteria

- `chrome-devtools` MCP block present in `opencode_app/opencode.json`, `enabled: false`, with `--no-usage-statistics --no-performance-crux --isolated` baked into the `command` array.
- `deploy/packs/pack-chrome-devtools.json` exists and mirrors `pack-nextjs.json` structure (`mcp.chrome-devtools.enabled: true` + `tools.chrome-devtools*: true`).
- `./setup.sh --enable-pack chrome-devtools` validates and deep-merges without error; `./setup.sh --enable-pack bogus` still fails fast.
- `deploy/setup.sh` banner shows `MCP SERVERS (15:)` and lists `chrome-devtools` under opt-in with a privacy note; the `--enable-pack` allowlist string (2 occurrences) is updated.
- `deploy/setup.ps1` mirrors setup.sh (allowlist comment + banner if present).
- `README.md` + `opencode_app/README.md` MCP listings updated if they enumerate servers.
- `./setup.sh --dry-run` completes cleanly after changes.
- No new agent/skill added → agent/skill counts in README/setup.sh unchanged.

## Scope

- `opencode_app/opencode.json` — add `mcp.chrome-devtools` block (disabled, privacy flags baked in)
- `deploy/packs/pack-chrome-devtools.json` — NEW pack partial
- `deploy/setup.sh` — pack allowlist (2 spots), help text, MCP count `14 → 15`, banner opt-in listing
- `deploy/setup.ps1` — Windows parity mirror (allowlist comment; banner if enumerated)
- `README.md` — MCP servers table
- `opencode_app/README.md` — Docker MCP docs if enumerated
- `PLANS/PLAN-GIT-329.md` — this file

## Dependency & Consumer Map

_Blast radius before steps. Config + shell scripts — no application code imports them._

| Node (file) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---|---|---|---|
| `opencode_app/opencode.json` (mcp block) | — | opencode (loads MCP), `--enable-pack` consumers | low — additive, disabled by default |
| `deploy/packs/pack-chrome-devtools.json` | mcp block must exist (Phase 1) | `merge-packs.mjs`, `--enable-pack` flag | low — new partial, mirrors existing pattern |
| `deploy/setup.sh` (allowlist + banner) | — | users running `./setup.sh --enable-pack` | low — string + count edits |
| `deploy/setup.ps1` | setup.sh parity (Phase 3) | Windows users | low — comment mirror |
| `README.md` / `opencode_app/README.md` | — | readers | low — doc only |

## Implementation Phases

_Every step is atomic (one reversible concern) and carries Why / Done when / Consumers affected._

### Phase 1: Source config — mcp block (privacy flags baked in)

- [ ] **1.1** Add to `opencode_app/opencode.json` mcp block, placed after `docling` (end of the opt-in cluster), disabled by default:
```json
"chrome-devtools": {
  "type": "local",
  "command": [
    "npx", "-y", "chrome-devtools-mcp@latest",
    "--no-usage-statistics",
    "--no-performance-crux",
    "--isolated"
  ],
  "enabled": false
}
```
    — **Why:** the three flags ARE the privacy guarantee: `--no-usage-statistics` stops Google telemetry, `--no-performance-crux` stops page URLs being sent to the CrUX API, `--isolated` uses a throwaway temp profile so no real browsing state (cookies/session) is exposed to the MCP client. Baking them into the source command array (not setup.sh env logic) makes the guarantee self-contained and visible at a glance. `enabled: false` matches the opt-in convention of `next-devtools`/`markitdown`/`docling`.
    — **Done when:** `rg -n '"chrome-devtools"' opencode_app/opencode.json` finds the key; the `command` array contains all three flags; `"enabled": false` is set.
    — **Consumers affected:** opencode loads it (disabled); `--enable-pack` (Phase 2) flips it on.

### Phase 2: Provider pack

- [ ] **2.1** Create `deploy/packs/pack-chrome-devtools.json` mirroring `deploy/packs/pack-nextjs.json`:
```json
{
  "$comment": "Provider pack: Chrome DevTools MCP server for frontend agents. Deep-merged by deploy/merge-packs.mjs when --enable-pack chrome-devtools. Privacy flags (no telemetry, no CrUX, isolated profile) are baked into the source opencode.json command array, so this pack only flips enabled + tools. Requires Chrome stable installed locally.",
  "mcp": { "chrome-devtools": { "enabled": true } },
  "tools": { "chrome-devtools*": true }
}
```
    — **Why:** `--enable-pack <name>` is the repo's existing automation for flipping opt-in MCP servers on/off at deploy time. A pack keeps the toggle consistent with `autodesk`/`markitdown`/`nextjs`/`zai`/`docling` and requires zero new CLI flag.
    — **Done when:** the file exists; `./setup.sh --enable-pack chrome-devtools` does not fail validation; `ls deploy/packs/pack-chrome-devtools.json` succeeds.
    — **Consumers affected:** `merge-packs.mjs` (deep-merges it), `validate_enable_pack()` in setup.sh.

### Phase 3: setup.sh — allowlist, help, count, banner

- [ ] **3.1** Update the two `autodesk,markitdown,nextjs,zai,docling` occurrences in `deploy/setup.sh` (line ~343 comment + line ~859 error message) to include `chrome-devtools`.
    — **Why:** `validate_enable_pack()` fail-fast checks pack names against `deploy/packs/`; the help/error strings must match or users get a misleading "unknown pack" message for a pack that exists.
    — **Done when:** `rg -n 'autodesk,markitdown,nextjs,zai,docling,chrome-devtools|chrome-devtools,autodesk' deploy/setup.sh` matches both spots (or the equivalent reordered string with `chrome-devtools` present).
    — **Consumers affected:** users running `--enable-pack`.

- [ ] **3.2** Bump the banner MCP count `MCP SERVERS (14):` → `MCP SERVERS (15):` (line ~667) and add under the "Available but disabled (opt-in)" block:
```
      chrome-devtools    Live Chrome automation: perf traces, network/console, Lighthouse, heap snapshots
                          (privacy-hardened: telemetry + CrUX OFF; throwaway profile; enable via --enable-pack chrome-devtools)
```
    — **Why:** the banner is the source of truth users read for what's configured; counts must not drift from the actual mcp block (AGENTS.md §Adding Skills or Subagents sync rule).
    — **Done when:** `rg -n 'MCP SERVERS \(15\)' deploy/setup.sh` matches; `rg -n 'chrome-devtools' deploy/setup.sh` shows the banner line + allowlist lines.
    — **Consumers affected:** readers of `./setup.sh -h` / status output.

### Phase 4: setup.ps1 — Windows parity mirror

- [ ] **4.1** Update the `deploy/setup.ps1` allowlist comment (line ~62: `# (autodesk,markitdown,nextjs,zai,docling). Empty = no-op.`) to include `chrome-devtools`, and mirror the banner count/listing if setup.ps1 enumerates MCP servers.
    — **Why:** repo convention — setup.sh and setup.ps1 must stay in sync (AGENTS.md).
    — **Done when:** `rg -n 'chrome-devtools' deploy/setup.ps1` matches the allowlist (and banner if present).
    — **Consumers affected:** Windows users.

### Phase 5: README doc sync

- [ ] **5.1** Update `README.md` MCP servers table/subagents section to list `chrome-devtools` (opt-in, privacy-hardened), and `opencode_app/README.md` Docker docs if it enumerates MCP servers.
    — **Why:** AGENTS.md sync rule — README MCP listings must match deployed config.
    — **Done when:** `rg -n 'chrome-devtools' README.md` matches; `rg -n 'chrome-devtools' opencode_app/README.md` matches if that file enumerates servers (skip if it does not).
    — **Consumers affected:** readers.

### Phase 6: Verification

- [ ] **6.1** Run `./setup.sh --dry-run` — completes cleanly, no errors. Run `./setup.sh --enable-pack chrome-devtools --dry-run` — pack validates, deep-merge preview shows `mcp.chrome-devtools.enabled: true`. Run `./setup.sh --enable-pack bogus --dry-run` — still fails fast with the unknown-pack message.
    — **Why:** the dry-run is the non-destructive gate that the pack mechanism + banner edits are internally consistent.
    — **Done when:** all three commands behave as specified.
    — **Consumers affected:** none (verification only).

- [ ] **6.2** Confirm no agent/skill count drift: `count_agents`/`count_skills` (or the README counts) unchanged from `main`. Confirm JSON validity of `opencode.json` and `pack-chrome-devtools.json` (`python3 -m json.tool` or `node -e` parse).
    — **Why:** catches malformed JSON (which would break opencode load) and count drift.
    — **Done when:** counts match `main`; both JSON files parse.
    — **Consumers affected:** none.

## Step Authoring Rules

- **Atomic**: one reversible concern per step; if a step does two things, split it.
- **Rationale mandatory**: every step has a **Why**; a step without one is malformed and blocks commit.
- **Completion signal**: every step has an objective **Done when** check, not a subjective "done".
- **Consumers explicit**: list affected consumers; write "none" if truly isolated.

## Technical Notes

- `chrome-devtools-mcp` opt-out flags: `--no-usage-statistics`, `--no-performance-crux`, `--no-update-checks` (or env `CHROME_DEVTOOLS_MCP_NO_UPDATE_CHECKS=1`). The first two are in the command array; update-check opt-out is optional (npm-only, no Google egress) — left to user env if desired.
- `--isolated` creates a temp user-data-dir cleaned up after browser close; prevents the MCP client seeing real browsing state.
- `CI` env var also disables usage statistics (irrelevant for opt-in deploy, but noted).
- Provider pack mechanism: `deploy/packs/pack-<name>.json` deep-merged by `deploy/merge-packs.mjs`; validated by `validate_enable_pack()` in setup.sh.
- `next-devtools` (existing, disabled) is the structural template for this addition.
- No new agent/skill → no README/setup.sh agent/skill count sync; only the MCP count + listing.
- `.opencode/branch-workflow-skipped` present → no branch-workflow setup.

## Dependencies

External: `chrome-devtools-mcp@latest` via npx at runtime (no install step — npx fetches on first use). Requires a locally installed Chrome stable.

## Risks & Mitigation

| Risk | Mitigation |
|---|---|
| Privacy flag missed on a future edit reintroduces telemetry | flags baked into source `opencode.json` command array, not a deploy-time toggle; AGENTS.md §Secret Hygiene + this plan's AC enshrine them |
| Second browser-driver path (Playwright + chrome-devtools) confuses agents | Overlap decision recorded above: Playwright for code assertions, chrome-devtools for live + Lighthouse; no agent prompt edits in scope |
| `npx -y chrome-devtools-mcp@latest` network egress in air-gapped env | server stays `enabled: false` by default; only `--enable-pack` turns it on |
| JSON breakage hides/renames MCP server | Phase 6.2 JSON parse check |
| Count drift (14 vs 15) | Phase 3.2 banner bump + Phase 6.2 count check |

## Success Metrics

- `chrome-devtools` is available and opt-in via `--enable-pack chrome-devtools`.
- Zero Google-bound data by default (telemetry OFF, CrUX OFF, isolated profile).
- Banner + README counts consistent with deployed config.
- No Playwright regression; no agent/skill count drift.
