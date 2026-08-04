# PLAN-GIT-307: Remove Google Cloud + Microsoft 365 MCP Integrations

**Issue:** https://github.com/darellchua2/opencode-config-template/issues/307
**Branch:** `chore/remove-google-microsoft-mcp`
**Status:** Complete — all phases implemented, verification gate green
**Amended:** Architecture-review + opencode-tooling review (2 blockers + 7 missed sync points fixed)
**Implemented:** All phases A–K + verification gate V.1–V.6 passed

## Dependency & Consumer Map

| What's removed | Consumers affected | Impact |
|---|---|---|
| 4 `google-*` MCP server defs (BigQuery, Maps, GCE, GKE) | `opencode_app/opencode.json`, `deploy/setup.sh`, `deploy/setup.ps1` | 13→7 opt-in MCP servers in Docker |
| 9 `microsoft-*` MCP server defs (Teams, Mail, Calendar, SharePoint, OneDrive, User, Word, Copilot, Dataverse) | Same as above | Same |
| `google-mcp-specialist-subagent` | `deploy/agent-tiers.json`, `AGENTS.md` tier table, `deploy/.AGENTS.md`, `README.md`, plugin regexes (2 .ts files) | 38→36 agents |
| `microsoft-m365-specialist-subagent` | Same + `office-document-primary-agent.md` (routing row + permission) | Same |
| `microsoft-m365-config-skill` | `deploy/dependency-map.json`, `opencode_app/opencode.json` (permission.skill) | 126→125 skills |
| `pack-google.json`, `pack-microsoft.json` | `deploy/setup.sh` ENABLE_PACK validation (dynamic glob — auto-handles), `deploy/merge-packs.mjs` (stale comment) | Packs removed |
| `pack-integrations.json` preset | `README.md` preset table, `deploy/init.mjs` printHelp() string | Preset removed |

## Phase A — Delete files (no edits, pure removal)

- [x] **A.1** Delete `opencode_app/.opencode/agents/google-mcp-specialist-subagent.md`
  — **Why:** Google MCP specialist is unused by most users; requires GCP service account auth.
  — **Done when:** File is gone from git tracking; `git status` shows deletion.
  — **Consumers affected:** `deploy/agent-tiers.json`, `AGENTS.md`, `deploy/.AGENTS.md`, `README.md`, plugin regexes (counts/regex updated in later phases).

- [x] **A.2** Delete `opencode_app/.opencode/agents/microsoft-m365-specialist-subagent.md`
  — **Why:** M365 specialist requires Copilot license; rarely used by template consumers.
  — **Done when:** File is gone from git tracking; `git status` shows deletion.
  — **Consumers affected:** `deploy/agent-tiers.json`, `AGENTS.md`, `deploy/.AGENTS.md`, `office-document-primary-agent.md` (Phase D), `README.md`, plugin regexes (Phase K).

- [x] **A.3** Delete `opencode_app/.opencode/skills/microsoft-m365-config-skill/` (entire directory)
  — **Why:** 452-line M365 config skill with no remaining consumers after agent removal.
  — **Done when:** Directory is gone; `ls` confirms absence.
  — **Consumers affected:** `deploy/dependency-map.json` (Phase C), `opencode_app/opencode.json` (Phase B), `README.md` Configuration category (Phase G).

- [x] **A.4** Delete `deploy/packs/pack-google.json`
  — **Why:** Google provider pack; no Google MCP servers remain after removal.
  — **Done when:** File gone; setup.sh dynamic glob auto-rejects `google` as unknown pack.
  — **Consumers affected:** `deploy/setup.sh`, `opencode_app/README.md` (Phase H).

- [x] **A.5** Delete `deploy/packs/pack-microsoft.json`
  — **Why:** M365 provider pack; no Microsoft MCP servers remain after removal.
  — **Done when:** File gone; setup.sh dynamic glob auto-rejects `microsoft` as unknown pack.
  — **Consumers affected:** `deploy/setup.sh`, `opencode_app/README.md` (Phase H).

- [x] **A.6** Delete `deploy/presets/pack-integrations.json`
  — **Why:** `integrations` preset only contained `google` + `microsoft`; empty after removal.
  — **Done when:** File gone.
  — **Consumers affected:** `README.md` (Phase G), `deploy/init.mjs` printHelp() (Phase E.6).

## Phase B — `opencode_app/opencode.json` (source of truth)

- [x] **B.1** Delete the 4 `google-*` MCP server blocks (~lines 227-278)
  — **Why:** Removes BigQuery, Maps, Compute Engine (GCE), GKE server definitions from config.
  — **Done when:** `node -e "const c=require('./opencode_app/opencode.json'); console.log(Object.keys(c.mcp).length)"` prints a number 4 less than before.
  — **Consumers affected:** All downstream count references (README, Docker README, deploy scripts).

- [x] **B.2** Delete the 9 `microsoft-*` MCP server blocks (~lines 316-363)
  — **Why:** Removes Teams, Mail, Calendar, SharePoint, OneDrive, User (Me), Word, Copilot, Dataverse server definitions.
  — **Done when:** Same node one-liner prints a number 13 less than original (target: 13).
  — **Consumers affected:** All downstream count references (README, Docker README, deploy scripts).

- [x] **B.3** Delete the 13 `permission.tool` deny entries for `google-*` and `microsoft-*` (~lines 126-129, 135-143) **AND strip the trailing comma on line 134**
  — **Why:** Tool deny rules reference MCP servers being removed; orphaned entries are dead config. **Blocker:** the 9 Microsoft deny entries (135-143) are the LAST properties in `permission.tool`; line 134 `"next-devtools*": "deny",` has a trailing comma that becomes orphaned after removal → invalid JSON. Must also strip that comma: `"next-devtools*": "deny",` → `"next-devtools*": "deny"`.
  — **Done when:** `node -e "JSON.parse(require('fs').readFileSync('opencode_app/opencode.json','utf8'))"` exits 0 (valid JSON); grep for `google-bigquery` / `microsoft-teams` in opencode.json returns zero matches.
  — **Consumers affected:** None (these are leaf entries).

- [x] **B.4** Delete `"microsoft-m365-config-skill": "allow"` from `permission.skill` (~line 85)
  — **Why:** Skill is deleted in A.3; permission entry is orphaned.
  — **Done when:** Grep for `microsoft-m365-config-skill` in opencode.json returns zero matches.
  — **Consumers affected:** None (leaf entry).

## Phase C — Deploy metadata (3 files)

- [x] **C.1** `deploy/agent-tiers.json` — delete `google-mcp-specialist-subagent` and `microsoft-m365-specialist-subagent` entries from `fast` tier
  — **Why:** Tier map must match actual agent files; deleted agents must be removed.
  — **Done when:** Grep for both agent names in agent-tiers.json returns zero matches.
  — **Consumers affected:** `deploy/build-registry.mjs` (reads tiers for registry output).

- [x] **C.2** `deploy/dependency-map.json` — delete `microsoft-m365-config-skill` entry and its 9 MCP `impliesMcp` edges
  — **Why:** Dependency edges reference removed skill and MCP servers.
  — **Done when:** Grep for `microsoft-m365-config-skill` in dependency-map.json returns zero matches.
  — **Consumers affected:** `deploy/build-registry.mjs` (reads dep map for registry output).

- [x] **C.3** `deploy/.AGENTS.md` — update subagent counts **recomputed from disk (not delta-patched)**: `"36 of 39 subagents"` → `"34 of 36 subagents"`; unscooped list: remove `google-mcp-specialist` → `"2 unscooped (explorer, image-analyzer)"`
  — **Why:** Deployed AGENTS.md documents agent totals; must reflect post-removal count. Arithmetic: 38 .md files all `mode:subagent`; removing 2 → 36 total; unscooped was 3 (explorer, google-mcp-specialist, image-analyzer) → 2; scoped = 36 − 2 = 34. (Current "39" was already off-by-one vs disk's 38 — recompute from disk, don't patch the drifted number.)
  — **Done when:** `grep "36 of 39"` returns zero; `grep "34 of 36"` matches; `grep "35 of 37"` returns zero.
  — **Consumers affected:** `deploy/setup.sh` copies this to `~/.config/opencode/AGENTS.md`.

## Phase D — `office-document-primary-agent.md` (downstream delegate)

- [x] **D.1** Remove `microsoft-m365-specialist-subagent: allow` from `permission.task`
  — **Why:** Agent is deleted; permission grant is orphaned and would error at runtime.
  — **Done when:** Grep for `microsoft-m365-specialist-subagent` in the file returns zero matches.
  — **Consumers affected:** None (leaf permission entry).

- [x] **D.2** Remove the `| M365 cloud operations | microsoft-m365-specialist-subagent |` routing row from the delegation table
  — **Why:** Routing references a deleted agent; removing prevents runtime delegation failures.
  — **Done when:** Grep for `M365 cloud operations` in the file returns zero matches.
  — **Consumers affected:** None (documentation row in the agent itself).

## Phase E — `deploy/setup.sh` + `deploy/setup.ps1` + `deploy/init.mjs` (parity + banners)

- [x] **E.1** Drop `microsoft,google` from all `ENABLE_PACK` help/validation strings in `setup.sh` (~lines 343, 571-572, 589-592, 873, 2431, 3518)
  — **Why:** Packs are deleted; listing them in help/validation is misleading.
  — **Done when:** `grep -n 'google\|microsoft' deploy/setup.sh` returns zero matches in ENABLE_PACK/help/banner lines (broadened — literal `microsoft,google` misses standalone `google` / `microsoft` references at lines 591, 2430, 2431).
  — **Consumers affected:** CLI help output for `--enable-pack` flag.

- [x] **E.2** Delete the Google Cloud + Microsoft 365 sections from the MCP server listing in `setup.sh` (~lines 653-654, 681-702) **AND update the MCP count banner header**
  — **Why:** Listing section documents MCP servers; removed servers must be unlisted. **Also:** line 665 `MCP SERVERS (26):` header must become `MCP SERVERS (13):`.
  — **Done when:** `grep -n 'google-\|microsoft-\|Google Cloud\|Microsoft 365\|MCP SERVERS (26)' deploy/setup.sh` returns zero matches (broadened — section headers alone don't catch individual `microsoft-teams`/`google-bigquery` entries at 682-702).
  — **Consumers affected:** Setup banner/status output.

- [x] **E.3** Apply identical changes to `deploy/setup.ps1` (Windows parity) — E.1 + E.2 equivalent references (~line 62, 2571)
  — **Why:** setup.ps1 must mirror setup.sh to prevent platform-specific drift.
  — **Done when:** Same broadened grep checks pass on setup.ps1. NOTE: setup.ps1 has no `(26)` MCP count banner (pre-existing parity asymmetry) — only the ENABLE_PACK strings + agent-count echoes apply.
  — **Consumers affected:** Windows users running setup.ps1.

- [x] **E.4** Update hardcoded agent-count banners in `setup.sh` (lines 2418, 2424, 3358, 3363, 3443) and `setup.ps1` (lines 1695, 2571)
  — **Why:** Static "38 agents" banners (setup.sh:2418,3358 / setup.ps1:1695) and "and N more agents" echoes (setup.sh:2424,3363,3443 / setup.ps1:2571) contradict the runtime dynamic counters which already emit 36. "38 agents" → "36 agents"; each "N more agents" decremented by 2.
  — **Done when:** `grep -n '38 agents\|and 3[0-9] more agents' deploy/setup.sh deploy/setup.ps1` shows "36 agents" and decremented "more agents" values.
  — **Consumers affected:** Setup banner/status output.

- [x] **E.5** `deploy/init.mjs` (~line 915) — drop `integrations` from the `printHelp()` preset list string
  — **Why:** A.6 deletes `pack-integrations.json`; runtime is safe (dynamic glob discovery + graceful `die()` on unknown preset), but the hardcoded help text advertises a dead preset.
  — **Done when:** `grep 'integrations' deploy/init.mjs` returns zero in the FLAGS/help section.
  — **Consumers affected:** `opencode-init` CLI help output.

- [x] **E.6** `deploy/merge-packs.mjs` (~line 32) — refresh the stale comment example `--packs autodesk,microsoft` → `--packs autodesk`
  — **Why:** Comment references a deleted pack.
  — **Done when:** Grep for `microsoft` in merge-packs.mjs returns zero.
  — **Consumers affected:** None (comment-only).

## Phase F — `AGENTS.md` (repo-level)

- [x] **F.1** Update tier table (~line 43): `"specialists (nextjs/cad/m365/google/office-docs)"` → `"specialists (nextjs/cad/office-docs)"`
  — **Why:** Tier table lists agent categories; removed agents must be unlisted.
  — **Done when:** `grep 'm365/google' AGENTS.md` returns zero matches.
  — **Consumers affected:** None (documentation-only).

## Phase G — `README.md` (count sync)

- [x] **G.1** Update agent counts: `38` → `36` (~lines 26, 241, 528)
  — **Why:** 2 agents deleted; counts must match actual file count.
  — **Done when:** `grep -n '38 agents\|38 subagent' README.md` returns zero matches.
  — **Consumers affected:** None (documentation-only).

- [x] **G.2** Update skill counts: `126` → `125` (~lines 27, 241, 492)
  — **Why:** Disk = 128 skill dirs MINUS `_archived/` + `_common/` utility dirs = **126 leaf skills** (README's current "126" was already correct — no pre-existing drift). Removing `microsoft-m365-config-skill` → **125**. (Earlier draft said 127 based on a false "actual 128" that double-counted the `_`-prefixed dirs — corrected.)
  — **Done when:** `grep -n '126 skill\|126 skills' README.md` returns zero; `grep -n '125 skill' README.md` matches.
  — **Consumers affected:** None (documentation-only).

- [x] **G.3** Update MCP server count: `26` → `13` (~line 329)
  — **Why:** 13 MCP server definitions removed.
  — **Done when:** `grep '26 MCP' README.md` returns zero matches.
  — **Consumers affected:** None (documentation-only).

- [x] **G.4** Delete the `integrations` preset row (~line 258)
  — **Why:** Preset file is deleted in A.6; README row is orphaned.
  — **Done when:** `grep 'integrations' README.md` preset table returns zero matches.
  — **Consumers affected:** None (documentation-only).

- [x] **G.5** Delete `google-mcp-specialist` + `microsoft-m365-specialist` agent rows (~lines 562, 564)
  — **Why:** Agents are deleted; rows are orphaned.
  — **Done when:** Grep for both agent names in README.md returns zero matches.
  — **Consumers affected:** None (documentation-only).

- [x] **G.6** Remove `microsoft-m365-config-skill` from Configuration skills category row **AND decrement the category count** (~line 517): `**Configuration** (3)` → `**Configuration** (2)`
  — **Why:** Skill is deleted; table row entry + header count are orphaned.
  — **Done when:** `grep 'microsoft-m365-config-skill' README.md` returns zero; `grep 'Configuration (2)' README.md` matches.
  — **Consumers affected:** None (documentation-only).

## Phase H — `opencode_app/README.md` + `Dockerfile`

- [x] **H.1** Pack table: delete `microsoft` + `google` rows (~lines 82-83)
  — **Why:** Pack files deleted; table rows are orphaned.
  — **Done when:** Grep for `microsoft` and `google` in pack table returns zero matches.
  — **Consumers affected:** Docker documentation.

- [x] **H.2** Update MCP server count: `"20 opt-in MCP servers"` → `7` (~line 68); update build-arg example to drop `microsoft` (~line 72); **drop "Microsoft 365, Google Cloud" from line 68 parenthetical and `microsoft, google,` from line 75 available-packs list**
  — **Why:** Docker config only includes non-disabled MCP servers; removal changes the opt-in count. The parenthetical (line 68) and available-packs comment (line 75) still name the removed suites/packs.
  — **Done when:** `grep '20 opt-in' opencode_app/README.md` returns zero; `grep -n 'Microsoft 365\|Google Cloud\|microsoft, google' opencode_app/README.md` returns zero.
  — **Consumers affected:** Docker build documentation.

- [x] **H.3** Delete the `google-bigquery` enabled-check example (~line 91)
  — **Why:** Example references a removed MCP server.
  — **Done when:** `grep 'google-bigquery' opencode_app/README.md` returns zero matches.
  — **Consumers affected:** Docker documentation.

- [x] **H.4** `Dockerfile` (~line 66): change `autodesk,microsoft` → `autodesk`
  — **Why:** Comment lists enabled packs; microsoft pack is deleted.
  — **Done when:** `grep 'microsoft' Dockerfile` returns zero matches.
  — **Consumers affected:** Docker build.

- [x] **H.5** Update skill directory count in `opencode_app/README.md` (~line 26): `126 skill directories` → `125 skill directories`
  — **Why:** Removing 1 skill → 125 (same ground truth as G.2: 128 dirs − 2 utility = 126 leaf, −1 = 125).
  — **Done when:** `grep '126 skill' opencode_app/README.md` returns zero; `grep '125 skill' opencode_app/README.md` matches.
  — **Consumers affected:** Docker documentation.

## Phase I — Regenerate registry (generated artifact)

- [x] **I.1** Run `node deploy/build-registry.mjs`
  — **Why:** Registry is a generated artifact from frontmatter; must be regenerated after deletions. Reads `agent-tiers.json` (Phase C.1) + `dependency-map.json` (Phase C.2) + agent frontmatter `permission.task` keys (Phase D.1) — correctly ordered AFTER C + D.
  — **Done when:** Command exits 0, `counts.agents` in `deploy/registry.json` shows 36, `counts.skills` shows 125, deleted agent/skill entries are gone.
  — **Consumers affected:** `docs/registry.json` (must be re-copied in I.2).

- [x] **I.2** Copy `deploy/registry.json` → `docs/registry.json`
  — **Why:** Docs copy must stay identical to source.
  — **Done when:** `diff deploy/registry.json docs/registry.json` shows no differences.
  — **Consumers affected:** Documentation site.

## Phase J — Live deployed config cleanup

- [x] **J.1** Re-run `./deploy/setup.sh` (or `--prune`) to clean `~/.config/opencode/`
  — **Why:** Deployed config in user-space still contains deleted agents/skills/MCP blocks.
  — **Done when:** `~/.config/opencode/` no longer contains google/microsoft agent files, skill dir, or MCP blocks.
  — **Consumers affected:** User's live opencode config.

## Phase K — Plugin off-set regexes (new consumers from review)

- [x] **K.1** Remove `google-mcp-specialist-subagent|` and `microsoft-m365-specialist-subagent|` alternation branches from `opencode_app/.opencode/plugins/ponytail-scoped.ts` (~line 70, `DEFAULT_OFF_PATTERN`)
  — **Why:** Both deleted agents are named in the ponytail off-set regex (agents excluded from ponytail injection). Dead alternation branches create maintenance confusion. Harmless at runtime (never matches deleted agents) but leaves stale agent names in "baked agents" regexes.
  — **Done when:** `grep 'microsoft-m365-specialist\|google-mcp-specialist' opencode_app/.opencode/plugins/ponytail-scoped.ts` returns zero.
  — **Consumers affected:** None (dead branches).

- [x] **K.2** Remove the same two alternation branches from `opencode_app/.opencode/plugins/learnings-autoinject.ts` (~line 66)
  — **Why:** Identical regex, and the file header explicitly states *"Reuse ponytail's off-set verbatim... Keeping the two regexes in sync is intentional."* Must fix BOTH in the same phase step — fixing K.1 without K.2 violates the documented sync contract.
  — **Done when:** `grep 'microsoft-m365-specialist\|google-mcp-specialist' opencode_app/.opencode/plugins/learnings-autoinject.ts` returns zero.
  — **Consumers affected:** None (dead branches).

## Verification Gate (post-edit)

- [x] **V.1** `node -e "const c=require('./opencode_app/opencode.json'); console.log(Object.keys(c.mcp).length)"` → prints **13**
- [x] **V.2** `node deploy/build-registry.mjs` → exits 0, no drift error
- [x] **V.3** `./deploy/setup.sh --dry-run` → no google/microsoft in banner/listing
- [x] **V.4** `grep -rn 'google-mcp-specialist\|microsoft-m365-specialist\|microsoft-m365-config\|google-bigquery\|google-maps\|google-gce\|google-gke\|microsoft-teams\|microsoft-mail\|microsoft-calendar\|microsoft-sharepoint\|microsoft-onedrive\|microsoft-user\|microsoft-word\|microsoft-copilot\|microsoft-dataverse' opencode_app/ deploy/ README.md AGENTS.md` → only matches in `research/` + `PLANS/` (historical, leave). Broadened to cover all 13 MCP keys + 2 agents + 1 skill (earlier draft covered only 5 tokens).
- [x] **V.5** `node deploy/build-registry.mjs --check` → exits 0 (CI drift guard — catches any registry drift manual edits missed)
- [x] **V.6** `node -e "JSON.parse(require('fs').readFileSync('opencode_app/opencode.json','utf8'))"` → exits 0 (confirms B.3 trailing-comma fix produced valid JSON)
