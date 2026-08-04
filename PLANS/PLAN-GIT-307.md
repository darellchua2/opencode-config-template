# PLAN-GIT-307: Remove Google Cloud + Microsoft 365 MCP Integrations

**Issue:** https://github.com/darellchua2/opencode-config-template/issues/307
**Branch:** `chore/remove-google-microsoft-mcp`
**Status:** In Progress

## Dependency & Consumer Map

| What's removed | Consumers affected | Impact |
|---|---|---|
| 4 `google-*` MCP server defs | `opencode_app/opencode.json`, `deploy/setup.sh`, `deploy/setup.ps1` | 13→7 opt-in MCP servers in Docker |
| 9 `microsoft-*` MCP server defs | Same as above | Same |
| `google-mcp-specialist-subagent` | `deploy/agent-tiers.json`, `AGENTS.md` tier table, `deploy/.AGENTS.md` subagent counts | 38→36 agents |
| `microsoft-m365-specialist-subagent` | Same + `office-document-primary-agent.md` (routing row + permission) | Same |
| `microsoft-m365-config-skill` | `deploy/dependency-map.json`, `opencode_app/opencode.json` (permission.skill) | 128→127 skills |
| `pack-google.json`, `pack-microsoft.json` | `deploy/setup.sh` ENABLE_PACK validation (dynamic glob — auto-handles) | Packs removed |
| `pack-integrations.json` preset | `README.md` preset table | Preset removed |

## Phase A — Delete files (no edits, pure removal)

- [ ] **A.1** Delete `opencode_app/.opencode/agents/google-mcp-specialist-subagent.md`
  — **Why:** Google MCP specialist is unused by most users; requires GCP service account auth.
  — **Done when:** File is gone from git tracking; `git status` shows deletion.
  — **Consumers affected:** `deploy/agent-tiers.json`, `AGENTS.md`, `deploy/.AGENTS.md`, `README.md` (counts updated in later phases).

- [ ] **A.2** Delete `opencode_app/.opencode/agents/microsoft-m365-specialist-subagent.md`
  — **Why:** M365 specialist requires Copilot license; rarely used by template consumers.
  — **Done when:** File is gone from git tracking; `git status` shows deletion.
  — **Consumers affected:** `deploy/agent-tiers.json`, `AGENTS.md`, `deploy/.AGENTS.md`, `office-document-primary-agent.md` (permission + routing row updated in Phase D), `README.md` (counts updated in Phase G).

- [ ] **A.3** Delete `opencode_app/.opencode/skills/microsoft-m365-config-skill/` (entire directory)
  — **Why:** 452-line M365 config skill with no remaining consumers after agent removal.
  — **Done when:** Directory is gone; `ls` confirms absence.
  — **Consumers affected:** `deploy/dependency-map.json` (edges removed in Phase C), `opencode_app/opencode.json` (permission.skill entry removed in Phase B).

- [ ] **A.4** Delete `deploy/packs/pack-google.json`
  — **Why:** Google provider pack; no Google MCP servers remain after removal.
  — **Done when:** File gone; setup.sh dynamic glob auto-rejects `google` as unknown pack.
  — **Consumers affected:** `deploy/setup.sh`, `opencode_app/README.md` (pack table in Phase H).

- [ ] **A.5** Delete `deploy/packs/pack-microsoft.json`
  — **Why:** M365 provider pack; no Microsoft MCP servers remain after removal.
  — **Done when:** File gone; setup.sh dynamic glob auto-rejects `microsoft` as unknown pack.
  — **Consumers affected:** `deploy/setup.sh`, `opencode_app/README.md` (pack table in Phase H).

- [ ] **A.6** Delete `deploy/presets/pack-integrations.json`
  — **Why:** `integrations` preset only contained `google` + `microsoft`; empty after removal.
  — **Done when:** File gone.
  — **Consumers affected:** `README.md` (preset row removed in Phase G).

## Phase B — `opencode_app/opencode.json` (source of truth)

- [ ] **B.1** Delete the 4 `google-*` MCP server blocks (~lines 227-278)
  — **Why:** Removes BigQuery, Cloud Storage, Cloud Run, GKE server definitions from config.
  — **Done when:** `node -e "const c=require('./opencode_app/opencode.json'); console.log(Object.keys(c.mcp).length)"` prints a number 4 less than before.
  — **Consumers affected:** All downstream count references (README, Docker README, deploy scripts).

- [ ] **B.2** Delete the 9 `microsoft-*` MCP server blocks (~lines 316-363)
  — **Why:** Removes Teams, Mail, Calendar, SharePoint, OneDrive, Word, Copilot, Excel, Dataverse server definitions.
  — **Done when:** Same node one-liner prints a number 13 less than original (target: 13).
  — **Consumers affected:** All downstream count references (README, Docker README, deploy scripts).

- [ ] **B.3** Delete the 13 `permission.tool` deny entries for `google-*` and `microsoft-*` (~lines 126-129, 135-143)
  — **Why:** Tool deny rules reference MCP servers being removed; orphaned entries are dead config.
  — **Done when:** Grep for `google-bigquery` / `microsoft-teams` in opencode.json returns zero matches.
  — **Consumers affected:** None (these are leaf entries).

- [ ] **B.4** Delete `"microsoft-m365-config-skill": "allow"` from `permission.skill` (~line 85)
  — **Why:** Skill is deleted in A.3; permission entry is orphaned.
  — **Done when:** Grep for `microsoft-m365-config-skill` in opencode.json returns zero matches.
  — **Consumers affected:** None (leaf entry).

## Phase C — Deploy metadata (3 files)

- [ ] **C.1** `deploy/agent-tiers.json` — delete `google-mcp-specialist-subagent` and `microsoft-m365-specialist-subagent` entries from `fast` tier
  — **Why:** Tier map must match actual agent files; deleted agents must be removed.
  — **Done when:** Grep for both agent names in agent-tiers.json returns zero matches.
  — **Consumers affected:** `deploy/build-registry.mjs` (reads tiers for registry output).

- [ ] **C.2** `deploy/dependency-map.json` — delete `microsoft-m365-config-skill` entry and its 9 MCP `impliesMcp` edges
  — **Why:** Dependency edges reference removed skill and MCP servers.
  — **Done when:** Grep for `microsoft-m365-config-skill` in dependency-map.json returns zero matches.
  — **Consumers affected:** `deploy/build-registry.mjs` (reads dep map for registry output).

- [ ] **C.3** `deploy/.AGENTS.md` — update subagent counts: `"36 of 39"` → `"35 of 37"`, unscooped list: remove `google-mcp-specialist`
  — **Why:** Deployed AGENTS.md documents agent totals; must reflect post-removal count.
  — **Done when:** `grep "36 of 39"` returns zero; `grep "35 of 37"` matches.
  — **Consumers affected:** `deploy/setup.sh` copies this to `~/.config/opencode/AGENTS.md`.

## Phase D — `office-document-primary-agent.md` (downstream delegate)

- [ ] **D.1** Remove `microsoft-m365-specialist-subagent: allow` from `permission.task`
  — **Why:** Agent is deleted; permission grant is orphaned and would error at runtime.
  — **Done when:** Grep for `microsoft-m365-specialist-subagent` in the file returns zero matches.
  — **Consumers affected:** None (leaf permission entry).

- [ ] **D.2** Remove the `| M365 cloud operations | microsoft-m365-specialist-subagent |` routing row from the delegation table
  — **Why:** Routing references a deleted agent; removing prevents runtime delegation failures.
  — **Done when:** Grep for `M365 cloud operations` in the file returns zero matches.
  — **Consumers affected:** None (documentation row in the agent itself).

## Phase E — `deploy/setup.sh` + `deploy/setup.ps1` (parity)

- [ ] **E.1** Drop `microsoft,google` from all `ENABLE_PACK` help/validation strings in `setup.sh`
  — **Why:** Packs are deleted; listing them in help/validation is misleading.
  — **Done when:** Grep for `microsoft,google` in setup.sh returns zero matches.
  — **Consumers affected:** CLI help output for `--pack` flag.

- [ ] **E.2** Delete the Google Cloud + Microsoft 365 sections from the MCP server listing in `setup.sh`
  — **Why:** Listing section documents MCP servers; removed servers must be unlisted.
  — **Done when:** Grep for `Google Cloud` and `Microsoft 365` in the MCP listing section returns zero.
  — **Consumers affected:** Setup banner/status output.

- [ ] **E.3** Apply identical changes to `deploy/setup.ps1` (Windows parity)
  — **Why:** setup.ps1 must mirror setup.sh to prevent platform-specific drift.
  — **Done when:** Same grep checks pass on setup.ps1.
  — **Consumers affected:** Windows users running setup.ps1.

## Phase F — `AGENTS.md` (repo-level)

- [ ] **F.1** Update tier table: `"specialists (nextjs/cad/m365/google/office-docs)"` → `"specialists (nextjs/cad/office-docs)"`
  — **Why:** Tier table lists agent categories; removed agents must be unlisted.
  — **Done when:** Grep for `m365/google` in AGENTS.md returns zero matches.
  — **Consumers affected:** None (documentation-only).

## Phase G — `README.md` (count sync)

- [ ] **G.1** Update agent counts: `38` → `36` (~lines 26, 241, 528)
  — **Why:** 2 agents deleted; counts must match actual file count.
  — **Done when:** `grep "38" README.md` no longer matches agent count lines.
  — **Consumers affected:** None (documentation-only).

- [ ] **G.2** Update skill counts: `126` → `127` (actual post-removal count; pre-existing drift noted)
  — **Why:** Removing 1 skill from 128 actual → 127. Pre-existing drift (README said 126, actual 128) is flagged but only the -1 from this change is corrected.
  — **Done when:** Skill count references in README show `127`.
  — **Consumers affected:** None (documentation-only).

- [ ] **G.3** Update MCP server count: `26` → `13` (~line 329)
  — **Why:** 13 MCP server definitions removed.
  — **Done when:** Grep for `26 MCP` in README.md returns zero matches.
  — **Consumers affected:** None (documentation-only).

- [ ] **G.4** Delete the `integrations` preset row (~line 258)
  — **Why:** Preset file is deleted in A.6; README row is orphaned.
  — **Done when:** Grep for `integrations` in README.md preset table returns zero matches.
  — **Consumers affected:** None (documentation-only).

- [ ] **G.5** Delete `google-mcp-specialist` + `microsoft-m365-specialist` agent rows (~lines 562, 564)
  — **Why:** Agents are deleted; rows are orphaned.
  — **Done when:** Grep for both agent names in README.md returns zero matches.
  — **Consumers affected:** None (documentation-only).

- [ ] **G.6** Remove `microsoft-m365-config-skill` from Configuration skills category row (~line 517)
  — **Why:** Skill is deleted; table row entry is orphaned.
  — **Done when:** Grep for `microsoft-m365-config-skill` in README.md returns zero matches.
  — **Consumers affected:** None (documentation-only).

## Phase H — `opencode_app/README.md` + `Dockerfile`

- [ ] **H.1** Pack table: delete `microsoft` + `google` rows (~lines 82-83)
  — **Why:** Pack files deleted; table rows are orphaned.
  — **Done when:** Grep for `microsoft` and `google` in pack table returns zero matches.
  — **Consumers affected:** Docker documentation.

- [ ] **H.2** Update MCP server count: `"20 opt-in MCP servers"` → `7` (~line 68); update build-arg example to drop `microsoft` (~line 72)
  — **Why:** Docker config only includes non-disabled MCP servers; removal changes the opt-in count.
  — **Done when:** Grep for `20 opt-in` in opencode_app/README.md returns zero matches.
  — **Consumers affected:** Docker build documentation.

- [ ] **H.3** Delete the `google-bigquery` enabled-check example (~line 91)
  — **Why:** Example references a removed MCP server.
  — **Done when:** Grep for `google-bigquery` in opencode_app/README.md returns zero matches.
  — **Consumers affected:** Docker documentation.

- [ ] **H.4** `Dockerfile` (~line 66): change `autodesk,microsoft` → `autodesk`
  — **Why:** Comment lists enabled packs; microsoft pack is deleted.
  — **Done when:** Grep for `microsoft` in Dockerfile returns zero matches.
  — **Consumers affected:** Docker build.

## Phase I — Regenerate registry (generated artifact)

- [ ] **I.1** Run `node deploy/build-registry.mjs`
  — **Why:** Registry is a generated artifact from frontmatter; must be regenerated after deletions.
  — **Done when:** Command exits 0, `counts.agents` in `deploy/registry.json` shows 36, deleted agent/skill entries are gone.
  — **Consumers affected:** `docs/registry.json` (must be re-copied).

- [ ] **I.2** Copy `deploy/registry.json` → `docs/registry.json`
  — **Why:** Docs copy must stay identical to source.
  — **Done when:** `diff deploy/registry.json docs/registry.json` shows no differences.
  — **Consumers affected:** Documentation site.

## Phase J — Live deployed config cleanup

- [ ] **J.1** Re-run `./deploy/setup.sh` (or `--prune`) to clean `~/.config/opencode/`
  — **Why:** Deployed config in user-space still contains deleted agents/skills/MCP blocks.
  — **Done when:** `~/.config/opencode/` no longer contains google/microsoft agent files, skill dir, or MCP blocks.
  — **Consumers affected:** User's live opencode config.

## Verification Gate (post-edit)

- [ ] **V.1** `node -e "const c=require('./opencode_app/opencode.json'); console.log(Object.keys(c.mcp).length)"` → prints **13**
- [ ] **V.2** `node deploy/build-registry.mjs` → exits 0, no drift error
- [ ] **V.3** `./deploy/setup.sh --dry-run` → no google/microsoft in banner/listing
- [ ] **V.4** `grep -rn "google-mcp-specialist\|microsoft-m365-specialist\|microsoft-m365-config\|google-bigquery\|microsoft-teams" opencode_app/ deploy/ README.md AGENTS.md` → only matches in `research/` + `PLANS/` (historical, leave)
