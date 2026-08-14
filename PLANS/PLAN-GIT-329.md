# PLAN-GIT-329 — Add privacy-hardened chrome-devtools MCP server for frontend agents/skills

**Issue:** https://github.com/darellchua2/opencode-config-template/issues/329
**Branch:** `feat/329-chrome-devtools-mcp`
**Labels:** enhancement, mcp, privacy, frontend, size: L

## Overview

The official Chrome DevTools MCP server (`chrome-devtools-mcp`) exposes 50+ tools for live-browser automation: input/navigation/emulation, performance traces, network/console debugging, Lighthouse audits, heap snapshots, and screencasts. This plan adds it as an opt-in MCP, privacy-hardened, AND wires complementary live-site diagnostics into the two Playwright-based frontend agents so they can use **both** tools together.

Privacy concern (the reason this plan is "privacy-hardened"): by default the server sends data to Google — usage statistics (telemetry), CrUX API (performance traces send page URLs to Google's Chrome User Experience Report), and update checks hit npm. It also exposes ALL browser content (cookies/session/DOM) to the MCP client. This repo's privacy ethos (vibeguard, local-only markitdown) is the opposite of that default, so the config MUST ship with every opt-out enabled.

## Complementary-use decision (drives scope — revised)

Two agents already drive **Playwright** via `bash`/PTY against live sites:

| Agent | Playwright role | chrome-devtools MCP adds |
|---|---|---|
| `responsive-audit-subagent` | 6 detection assertions at mobile/tablet/desktop breakpoints | `list_console_messages` (JS errors during a breakpoint flow), `list_network_requests` (failed/4xx/5xx affecting layout), `lighthouse_audit`, `performance_*_trace` (CLS/LCP to corroborate assertion #6 layout-shift) |
| `uiux-reviewer-subagent` | capture protocol per `uiux-review-skill` §2 (screenshots + a11y tree + computed styles at 3 breakpoints) | `lighthouse_audit` (backs axis 10 Accessibility, axis 11 Performance perception), `list_console_messages`/`list_network_requests` to corroborate visual findings with runtime evidence |

**Decision:** Playwright stays the assertion/capture engine (reproducible, CI-bound). chrome-devtools MCP is the **complementary live-diagnostics layer** — runtime data Playwright does not expose. Do NOT remove Playwright; do NOT duplicate screenshot capture in chrome-devtools MCP. Both tools available so the agents can cross-corroborate a finding against live-site evidence.

Out of scope: no new agent/skill; no Playwright removal; `nextjs-specialist-subagent` already has `next-devtools` MCP (browser-level chrome-devtools would be a separate later issue).

## Acceptance Criteria

- `chrome-devtools` MCP block present in `opencode_app/opencode.json`, `enabled: false`, with `--no-usage-statistics --no-performance-crux --isolated` baked into the `command` array.
- `deploy/packs/pack-chrome-devtools.json` exists and mirrors `pack-nextjs.json` structure (`mcp.chrome-devtools.enabled: true` + `tools.chrome-devtools*": true`).
- `./setup.sh --enable-pack chrome-devtools` validates and deep-merges without error; `./setup.sh --enable-pack bogus` still fails fast.
- `deploy/setup.sh` banner shows `MCP SERVERS (15:)` and lists `chrome-devtools` under opt-in with a privacy note; the `--enable-pack` allowlist string (2 occurrences) is updated.
- `deploy/setup.ps1` mirrors setup.sh.
- `README.md` + `opencode_app/README.md` MCP listings updated.
- `responsive-audit-subagent` + `uiux-reviewer-subagent` each have a "Complementary live-site diagnostics" note documenting conditional chrome-devtools MCP use alongside Playwright (no frontmatter change expected — see Technical Notes).
- `./setup.sh --dry-run` completes cleanly; agent/skill counts unchanged from `main`.

## Scope

- `opencode_app/opencode.json` — add `mcp.chrome-devtools` block (disabled, privacy flags baked in)
- `deploy/packs/pack-chrome-devtools.json` — NEW pack partial
- `deploy/setup.sh` — pack allowlist (2 spots), help text, MCP count `14 → 15`, banner opt-in listing
- `deploy/setup.ps1` — Windows parity mirror
- `README.md` — MCP servers table
- `opencode_app/README.md` — Docker MCP docs if enumerated
- `opencode_app/.opencode/agents/responsive-audit-subagent.md` — complementary chrome-devtools MCP note
- `opencode_app/.opencode/agents/uiux-reviewer-subagent.md` — complementary chrome-devtools MCP note
- `PLANS/PLAN-GIT-329.md` — this file

## Dependency & Consumer Map

_Blast radius before steps. Config + shell + agent prompts — no application code imports them._

| Node (file) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---|---|---|---|
| `opencode_app/opencode.json` (mcp block) | — | opencode (loads MCP), `--enable-pack` consumers, the 2 frontend agents | low — additive, disabled by default |
| `deploy/packs/pack-chrome-devtools.json` | mcp block (Phase 1) | `merge-packs.mjs`, `--enable-pack` flag | low — new partial, mirrors existing pattern |
| `deploy/setup.sh` (allowlist + banner) | — | users running `./setup.sh --enable-pack` | low — string + count edits |
| `deploy/setup.ps1` | setup.sh parity (Phase 4) | Windows users | low — comment mirror |
| `README.md` / `opencode_app/README.md` | — | readers | low — doc only |
| 2 frontend agents (MCP note) | mcp block (Phase 1) | primary session; `uiux-reviewer` → `responsive-audit` pipeline | low — additive prompt note; conditional on pack enabled |

## Implementation Phases

_Every step is atomic (one reversible concern) and carries Why / Done when / Consumers affected._

### Phase 1: Source config — mcp block (privacy flags baked in)

- [x] **1.1** Add to `opencode_app/opencode.json` mcp block, placed after `docling` (end of the opt-in cluster), disabled by default:
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
    — **Consumers affected:** opencode loads it (disabled); `--enable-pack` (Phase 2) flips it on; the 2 frontend agents (Phase 6) reference it conditionally.
    — **Done:** added `mcp.chrome-devtools` block after `docling` with multi-line `command` array (`npx -y chrome-devtools-mcp@latest --no-usage-statistics --no-performance-crux --isolated`), `enabled: false`; files: opencode_app/opencode.json; fixes: none

### Phase 2: Provider pack

- [x] **2.1** Create `deploy/packs/pack-chrome-devtools.json` mirroring `deploy/packs/pack-nextjs.json`:
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
    — **Done:** created pack with `mcp.chrome-devtools.enabled: true` + `tools."chrome-devtools*": true`; top-level keys match `pack-nextjs.json` (`$comment`/`mcp`/`tools`); file discoverable in `deploy/packs/`; files: deploy/packs/pack-chrome-devtools.json; fixes: none

### Phase 3: setup.sh — allowlist, help, count, banner

- [x] **3.1** Update the two `autodesk,markitdown,nextjs,zai,docling` occurrences in `deploy/setup.sh` (line ~343 comment + line ~859 error message) to include `chrome-devtools`.
    — **Why:** `validate_enable_pack()` fail-fast checks pack names against `deploy/packs/`; the help/error strings must match or users get a misleading "unknown pack" message for a pack that exists.
    — **Done when:** `rg -n 'chrome-devtools' deploy/setup.sh` matches the allowlist comment + the error message (2 spots minimum, plus banner from 3.2).
    — **Consumers affected:** users running `--enable-pack`.
    — **Done:** appended `,chrome-devtools` to the 2 scoped occurrences (comment + error msg); also fixed 2 stale status-echo lines (2438 opt-in list + 2439 enable-pack group syntax) and the help-text packs line (576) found during the sweep; files: deploy/setup.sh; fixes: none

- [x] **3.2** Bump the banner MCP count `MCP SERVERS (14):` → `MCP SERVERS (15):` (line ~667) and add under the "Available but disabled (opt-in)" block:
```
      chrome-devtools    Live Chrome automation: perf traces, network/console, Lighthouse, heap snapshots
                          (privacy-hardened: telemetry + CrUX OFF; throwaway profile; enable via --enable-pack chrome-devtools)
```
    — **Why:** the banner is the source of truth users read for what's configured; counts must not drift from the actual mcp block (AGENTS.md §Adding Skills or Subagents sync rule).
    — **Done when:** `rg -n 'MCP SERVERS \(15\)' deploy/setup.sh` matches; `rg -n 'chrome-devtools' deploy/setup.sh` shows the banner line + allowlist lines.
    — **Consumers affected:** readers of `./setup.sh -h` / status output.
    — **Done:** banner `MCP SERVERS (14)` → `(15)`; added 2-line chrome-devtools entry under opt-in (description + privacy note); files: deploy/setup.sh; fixes: none

### Phase 4: setup.ps1 — Windows parity mirror

- [x] **4.1** Update the `deploy/setup.ps1` allowlist comment (line ~62: `# (autodesk,markitdown,nextjs,zai,docling). Empty = no-op.`) to include `chrome-devtools`, and mirror the banner count/listing if setup.ps1 enumerates MCP servers.
    — **Why:** repo convention — setup.sh and setup.ps1 must stay in sync (AGENTS.md).
    — **Done when:** `rg -n 'chrome-devtools' deploy/setup.ps1` matches the allowlist (and banner if present).
    — **Consumers affected:** Windows users.
    — **Done:** updated 3 stale spots mirroring setup.sh — allowlist comment (62), help-text packs list (912), status echo opt-in list (1731); setup.ps1 has no `MCP SERVERS (N)` count banner so no count bump; pwsh absent so syntax relied on string-edit verification (pure additions); files: deploy/setup.ps1; fixes: none

### Phase 5: README doc sync

- [x] **5.1** Update `README.md` MCP servers table/subagents section to list `chrome-devtools` (opt-in, privacy-hardened), and `opencode_app/README.md` Docker docs if it enumerates MCP servers.
    — **Why:** AGENTS.md sync rule — README MCP listings must match deployed config.
    — **Done when:** `rg -n 'chrome-devtools' README.md` matches; `rg -n 'chrome-devtools' opencode_app/README.md` matches if that file enumerates servers (skip if it does not).
    — **Consumers affected:** readers.
    — **Done:** README.md — count 14→15, opt-in list 8→9 (added chrome-devtools), packs table row added, frontend preset MCP list gained chrome-devtools; opencode_app/README.md — opt-in 8→9, available-packs comment, packs table row added; no stale MCP counts remain; files: README.md, opencode_app/README.md; fixes: none

### Phase 6: Frontend agent prompt wiring — complementary live-site diagnostics

- [x] **6.1** Add a "Complementary Live-Site Diagnostics (chrome-devtools MCP)" section to `responsive-audit-subagent.md`, placed after the "Screenshot Delegation" section. Content: Playwright remains the engine for the 6 detection assertions; when the `chrome-devtools*` tool namespace is enabled (via `--enable-pack chrome-devtools`), you MAY also use chrome-devtools MCP tools to enrich each defect with live-site data Playwright cannot expose — `list_console_messages` (JS errors thrown during a breakpoint flow), `list_network_requests` (failed/4xx/5xx or blocked assets affecting layout), `lighthouse_audit` (a11y/perf/SEO at the target breakpoint), `performance_start_trace`/`performance_stop_trace` (CLS/LCP deltas corroborating assertion #6 layout-shift). Include a conditional MCP-dependency note mirroring `nextjs-specialist-subagent.md:77` (requires `chrome-devtools*` true in the tools block).
    — **Why:** the agent already tests live sites via Playwright; console/network/Lighthouse data cross-corroborates a responsive defect with runtime evidence, turning "element clipped" into "element clipped AND 2 console errors + a 404 on the breakpoint stylesheet."
    — **Done when:** `rg -n 'chrome-devtools' opencode_app/.opencode/agents/responsive-audit-subagent.md` matches (section header + dependency note); the section states Playwright stays the assertion engine.
    — **Consumers affected:** primary session reading audit output; the `uiux-reviewer` → `responsive-audit` pipeline.
    — **Done:** added "Complementary Live-Site Diagnostics (chrome-devtools MCP)" section after Screenshot Delegation; lists list_console_messages/list_network_requests/lighthouse_audit/performance_*_trace as cross-corroboration tools; states Playwright stays the assertion engine; includes MCP-dependency note + no-frontmatter-change statement (6.3); files: opencode_app/.opencode/agents/responsive-audit-subagent.md; fixes: none

- [x] **6.2** Add a "Complementary Live-Site Diagnostics (chrome-devtools MCP)" note to `uiux-reviewer-subagent.md`, placed near "Step 2: Capture Evidence" or as its own section after the rubric. Content: Playwright stays the capture/screenshot engine per `uiux-review-skill` §2; when `chrome-devtools*` is enabled, for live URLs enrich axis 10 (Accessibility basics) and axis 11 (Performance perception) with `lighthouse_audit` (a11y/perf/SEO scores), and corroborate visual findings with `list_console_messages`/`list_network_requests`. Include the same conditional MCP-dependency note.
    — **Why:** axes 10 and 11 currently rely on inference from markup/screenshot; `lighthouse_audit` gives objective runtime scores, strengthening those findings with verified data instead of assumptions.
    — **Done when:** `rg -n 'chrome-devtools' opencode_app/.opencode/agents/uiux-reviewer-subagent.md` matches (note + dependency note); the note states Playwright stays the capture engine.
    — **Consumers affected:** primary session reading review output.
    — **Done:** added "Complementary Live-Site Diagnostics (chrome-devtools MCP)" section after Step 5; ties lighthouse_audit to axes 10 & 11, console/network to corroborating findings; states Playwright stays the capture engine; includes MCP-dependency note + no-frontmatter-change statement (6.3); files: opencode_app/.opencode/agents/uiux-reviewer-subagent.md; fixes: none

- [x] **6.3** Confirm no frontmatter `permission` change is required for either agent. Both currently have `read."mcp:*": deny`, which blocks only MCP **resource** reads (`read_mcp_resource`); `chrome-devtools-mcp` is tools-only (no resources), so its tools are callable via the global `tools` map once the pack is enabled — exactly the pattern `nextjs-specialist-subagent` uses (no per-agent entry). State this explicitly in each note so future readers understand why no permission key was added.
    — **Why:** prevents a future contributor from mistakenly adding a per-agent gate, or from thinking the tools are unreachable.
    — **Done when:** both notes contain a one-line statement that access requires no frontmatter change and is gated only by the global `tools` map.
    — **Consumers affected:** future maintainers.
    — **Done:** both agent notes contain the no-frontmatter-change statement (read."mcp:*":deny blocks only MCP resource reads; chrome-devtools-mcp is tools-only, gated by global tools map, mirroring nextjs-specialist); frontmatter YAML re-validated for both agents (parse OK); no permission edits made; files: (covered by 6.1/6.2); fixes: none

### Phase 7: Verification

- [x] **7.1** Run `./setup.sh --dry-run` — completes cleanly, no errors. Run `./setup.sh --enable-pack chrome-devtools --dry-run` — pack validates, deep-merge preview shows `mcp.chrome-devtools.enabled: true` and `tools."chrome-devtools*": true`. Run `./setup.sh --enable-pack bogus --dry-run` — still fails fast with the unknown-pack message.
    — **Why:** the dry-run is the non-destructive gate that the pack mechanism + banner edits are internally consistent.
    — **Done when:** all three commands behave as specified.
    — **Consumers affected:** none (verification only).
    — **Done:** all 3 commands behave as specified — bogus pack fails fast (exit 1, "unknown pack(s): bogus"); chrome-devtools pack validates + "Merged 1 pack(s)"; staged dry-run-preview opencode.json shows mcp.chrome-devtools.enabled=true, tools."chrome-devtools*"=true, all 3 privacy flags preserved; plain --dry-run exits 0; files: (verification only); fixes: none

- [x] **7.2** Confirm no agent/skill count drift: agent and skill counts in README/setup.sh unchanged from `main`. Confirm JSON validity of `opencode.json` and `pack-chrome-devtools.json` (`python3 -m json.tool` or `node -e` parse). Confirm frontmatter of both edited agents is still valid YAML.
    — **Why:** catches malformed JSON (which would break opencode load), YAML breakage (which would hide an agent), and count drift.
    — **Done when:** counts match `main`; both JSON files parse; both agent frontmatter blocks parse as valid YAML.
    — **Consumers affected:** none.
    — **Done:** agent count 36=36 (HEAD vs main), skill count 130=130 (excl _archived, identical git method) — no drift; opencode.json + pack-chrome-devtools.json both parse as valid JSON; both edited agents' frontmatter parse as valid YAML (Phase 6 check); files: (verification only); fixes: none

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
- **MCP tool access model (Phase 6.3):** opencode gates MCP *tool* calls via the global `tools` map in `opencode.json` (`tools: { "chrome-devtools*": true }`). The per-agent `read."mcp:*": deny` blocks only MCP *resource* reads; `chrome-devtools-mcp` is tools-only (no resources), so no per-agent frontmatter entry is needed — mirroring `nextjs-specialist-subagent`'s pattern. Verify this assumption empirically in Phase 7.2; if a per-agent gate turns out to be required, add `permission` entries then.
- No new agent/skill → no README/setup.sh agent/skill count sync; only the MCP count + listing.
- `.opencode/branch-workflow-skipped` present → no branch-workflow setup.

## Dependencies

External: `chrome-devtools-mcp@latest` via npx at runtime (no install step — npx fetches on first use). Requires a locally installed Chrome stable.

## Risks & Mitigation

| Risk | Mitigation |
|---|---|
| Privacy flag missed on a future edit reintroduces telemetry | flags baked into source `opencode.json` command array, not a deploy-time toggle; AGENTS.md §Secret Hygiene + this plan's AC enshrine them |
| Two browser-driver paths (Playwright + chrome-devtools) drive conflicting browser instances | complementary-use decision recorded: Playwright = assertions/capture, chrome-devtools = diagnostics only; no screenshot-capture duplication in chrome-devtools |
| `npx -y chrome-devtools-mcp@latest` network egress in air-gapped env | server stays `enabled: false` by default; only `--enable-pack` turns it on |
| JSON breakage hides/renames MCP server | Phase 7.2 JSON parse check |
| Count drift (14 vs 15) | Phase 3.2 banner bump + Phase 7.2 count check |
| Agent YAML breakage hides an agent after Phase 6 edits | Phase 7.2 frontmatter YAML validity check |
| MCP tool-access assumption wrong (per-agent gate needed) | Phase 7.2 empirical verification; fallback = add `permission` entries |

## Success Metrics

- `chrome-devtools` is available and opt-in via `--enable-pack chrome-devtools`.
- Zero Google-bound data by default (telemetry OFF, CrUX OFF, isolated profile).
- Banner + README counts consistent with deployed config.
- `responsive-audit-subagent` + `uiux-reviewer-subagent` can cross-corroborate findings with live console/network/Lighthouse data alongside Playwright.
- No Playwright regression; no agent/skill count drift.
