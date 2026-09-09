# PLAN: Remove zai-vision skill + MCP; native multimodal vision suffices

**Branch**: feat/GIT-364
**Issue**: https://github.com/darellchua2/opencode-config-template/issues/364
**Base**: main

## Acceptance Criteria

- [ ] `opencode_app/.opencode/skills/zai-vision-analysis-skill/` deleted
- [ ] `zai-vision-mcp` MCP entry + permission allowlist entries removed from `opencode_app/opencode.json`
- [ ] Agent files keep their inline API fallback but no longer cite the removed skill as "canonical"
- [ ] `error-resolver-workflow-skill` and `opencode-agent-creation-skill` references updated
- [ ] `deploy/skill-profiles.json` entry removed; `deploy/registry.json` regenerated via `node deploy/build-registry.mjs`
- [ ] `deploy/setup.sh` + `setup.ps1`: opt-in pack listings/help text updated (zai-vision-mcp dropped)
- [ ] `README.md`: MCP count 9→8, MCP table row, glm-5v-turbo note, Responsive & Visual Testing category updated
- [ ] Root `AGENTS.md` Vision-fallback paragraph rewritten (no skill reference)
- [ ] `tests/test_mcp_count_consistency.bats` assertions updated; `bats tests/` green
- [ ] Historical docs (CHANGELOG.md, MIGRATION.md, PLANS/, research/, LEARNINGS/) left untouched

## Dependency & Consumer Map

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---------------------|---------------------------|---------------------------------|-------------|
| `opencode_app/opencode.json` (mcp + permission entries) | — | opencode runtime, `tests/test_mcp_count_consistency.bats`, README count | low |
| `opencode_app/.opencode/skills/zai-vision-analysis-skill/` (delete) | — | registry.json (regen), skill-profiles.json, README category table, disk-derived setup.sh counts | low |
| `deploy/registry.json` (regen) | skill dir deletion | `tests/init.bats` count assertions, `npx add` installer | med |
| `deploy/skill-profiles.json` | skill dir deletion | `setup.sh --skill-profile` lean/full lists | low |
| Agent `.md` fallback prose (image-analyzer, error-resolver) | skill deletion (prose must not dangle) | `deploy/registry.json` descriptions (regen after), users of the fallback path | low |
| `error-resolver-workflow-skill`, `opencode-agent-creation-skill` prose | skill deletion | agents routing screenshot work; new-agent templates | low |
| `deploy/setup.sh` / `setup.ps1` opt-in listings | mcp entry removal | `--status`/help readers, bats parse_arguments? (no — text only) | low |
| `deploy/agent-tiers.json` / `provider-models.json` `$comment` prose | skill deletion | resolve-models.mjs (reads JSON only; prose is documentation) | low |
| `README.md` + root `AGENTS.md` | all of the above | humans; `tests/test_mcp_count_consistency.bats` asserts README MCP count | low |
| `tests/test_mcp_count_consistency.bats` | mcp entry removal | CI gate | low |

## Implementation Phases

### Phase 1: Source config + skill removal
- [ ] **1.1** Delete `opencode_app/.opencode/skills/zai-vision-analysis-skill/` directory
    — **Why:** The skill is the primary removal target; every later edit removes references to it, so it must go first so stale-reference greps are meaningful.
    — **Done when:** `ls opencode_app/.opencode/skills/zai-vision-analysis-skill` fails; `git status` shows the deletion.
    — **Consumers affected:** registry.json, skill-profiles.json, README category table, agents citing it (all handled in later steps).
- [ ] **1.2** Remove `zai-vision-mcp` MCP entry (~line 323) and the `"zai-vision-analysis-skill": "allow"` + `"zai-vision-mcp*": "allow"` permission entries from `opencode_app/opencode.json`
    — **Why:** Opt-in server with zero enabled-by-default consumers; permission entries for a removed skill/server are dead config.
    — **Done when:** `python3 -c "import json; d=json.load(open('opencode_app/opencode.json')); assert 'zai-vision-mcp' not in d['mcp']"` passes and no `zai-vision` string remains in the file.
    — **Consumers affected:** tests/test_mcp_count_consistency.bats (updated in Phase 4), README MCP count (Phase 4).
- [ ] **1.3** Remove `"zai-vision-analysis-skill"` from `deploy/skill-profiles.json` (fix trailing comma) and regenerate `deploy/registry.json` via `node deploy/build-registry.mjs`
    — **Why:** Lean profile lists a now-deleted skill; registry must match disk or CI `--check` drift gate fails (AGENTS.md frontmatter contract).
    — **Done when:** `node deploy/build-registry.mjs --check` exits 0; `grep zai-vision deploy/skill-profiles.json deploy/registry.json` is empty.
    — **Consumers affected:** `npx add` installer registry, `tests/init.bats` count assertions, `tests/skill_profiles.bats`.

### Phase 2: Agent + skill prose (fallback path stays, skill citation goes)
- [ ] **2.1** Rewrite `image-analyzer-subagent.md` §Fallback (~lines 47-55): drop "the vision MCP server isn't connected" clause and the "Run the recipe from `zai-vision-analysis-skill` (canonical, with full error handling)" sentence — present the inline bash recipe as the fallback itself
    — **Why:** The inline recipe is self-contained and is the actual mechanism; citing a deleted skill as "canonical" strands readers on a 404.
    — **Done when:** `grep -n "zai-vision-analysis-skill\|vision MCP" opencode_app/.opencode/agents/image-analyzer-subagent.md` is empty; inline recipe block untouched.
    — **Consumers affected:** `deploy/registry.json` description regen (rerun build-registry in 2.4 gate if description changes — it must not; only body prose changes).
- [ ] **2.2** Rewrite `error-resolver-subagent.md` (~line 67): replace "`zai-vision-analysis-skill` (`glm-5v-turbo`, different model) remains the fallback for text-only sessions" with a reference to the inline direct-API fallback recipe (glm-5v-turbo, a different model) embedded in the agent files
    — **Why:** Same dangling-reference risk; the "different model" disambiguation is a documented pattern requirement (LEARNINGS tier-model-swap-blast-radius).
    — **Done when:** `grep -n "zai-vision-analysis-skill" opencode_app/.opencode/agents/error-resolver-subagent.md` is empty; "different model" phrase retained.
    — **Consumers affected:** none outside prose.
- [ ] **2.3** Rewrite `error-resolver-workflow-skill/SKILL.md` §Image Input Routing (~lines 94-99): path 2 becomes "direct Z.AI vision API call via bash (inline recipe in `image-analyzer-subagent`; glm-5v-turbo — a different model)" and path 3 (project-added vision MCP) is deleted
    — **Why:** The routing table is the executable instruction for screenshot handling; it must not route to a deleted skill or presuppose an unshipped MCP server.
    — **Done when:** `grep -n "zai-vision-analysis-skill\|zai-vision-mcp" opencode_app/.opencode/skills/error-resolver-workflow-skill/SKILL.md` is empty; two-path routing remains coherent.
    — **Consumers affected:** error-resolver-subagent (references this skill as source of truth).
- [ ] **2.4** Update `opencode-agent-creation-skill/SKILL.md` line ~52 model note: drop the "`zai-vision-analysis-skill` calling `glm-5v-turbo` … direct-API fallback" clause; state that vision agents embed an inline direct-API fallback recipe
    — **Why:** This skill templates new agents — a stale citation replicates into every future agent (documented pattern risk).
    — **Done when:** `grep -n "zai-vision-analysis" opencode_app/.opencode/skills/opencode-agent-creation-skill/SKILL.md` is empty.
    — **Consumers affected:** future agent authoring only.

### Phase 3: Deploy-script + tier-registry prose
- [ ] **3.1** Remove `zai-vision-mcp` from the three `deploy/setup.sh` listings: help text line ~718, opt-in list ~2501, opt-in global packs line ~4234
    — **Why:** Help/status text advertising a removed server misleads users into trying to enable it.
    — **Done when:** `grep -n "zai-vision" deploy/setup.sh` is empty (line ~575/3390/3713 "vision tier" hits are unrelated tier prose — retain).
    — **Consumers affected:** users reading `--help`/`--status`; no scripts parse these strings.
- [ ] **3.2** Remove `zai-vision-mcp` from the two `deploy/setup.ps1` listings (~lines 1764, 2738)
    — **Why:** Windows mirror of 3.1 — the two scripts must not drift.
    — **Done when:** `grep -n "zai-vision" deploy/setup.ps1` is empty.
    — **Consumers affected:** Windows users only.
- [ ] **3.3** Update `$comment` prose in `deploy/agent-tiers.json` (#294 note: "zai-vision-analysis-skill remains the direct-API fallback" → "agents embed an inline direct-API fallback recipe (glm-5v-turbo via the pay-as-you-go `zai` path)") and `deploy/provider-models.json` ("only reachable via the zai-vision-analysis-skill direct API call" → "only reachable via the agents' inline direct-API fallback call")
    — **Why:** `$comment` fields document guard behavior; stale prose claims a deleted skill is the fallback path (pattern surface #3).
    — **Done when:** `grep -n "zai-vision-analysis" deploy/agent-tiers.json deploy/provider-models.json` is empty; both files still `python3 -m json.tool` cleanly.
    — **Consumers affected:** resolve-models.mjs (JSON-only consumer — unaffected); documentation readers.

### Phase 4: Docs + tests + verification gate
- [ ] **4.1** Update `README.md`: MCP count line ~330 "ships 9 MCP server entries" → 8; delete MCP table row ~347 (`zai-vision-mcp`); rewrite glm-5v-turbo note ~106 to describe the agents' inline fallback (no skill name); category table ~590 "Responsive & Visual Testing (3)" → (2), drop the skill column entry and its description clause
    — **Why:** README is the asserted doc surface for the MCP count gate and the human-facing catalog; stale entries fail CI and mislead adoption.
    — **Done when:** `grep -n "ships 8 MCP server entries" README.md` matches; `grep -n "zai-vision" README.md` returns only the historical BT-142 blockquote (~line 564).
    — **Consumers affected:** `tests/test_mcp_count_consistency.bats` (asserts README count = opencode.json mcp length).
- [ ] **4.2** Rewrite root `AGENTS.md` Vision-fallback paragraph (~line 47): fallback is the inline direct Z.AI vision API call to `glm-5v-turbo` (a different model from the native `glm-5.3-flash`) embedded in the agent files (coding-plan endpoint preferred, PAAS fallback; requires `ZAI_API_KEY`)
    — **Why:** Root AGENTS.md is injected into every session; it must not route to the deleted skill.
    — **Done when:** `grep -n "zai-vision-analysis" AGENTS.md` is empty; "different model" phrase retained.
    — **Consumers affected:** all future sessions reading the vision-fallback rule.
- [ ] **4.3** Update `tests/test_mcp_count_consistency.bats`: rewrite `mcp_count_zai_zread_removed_vision_opt_in` to assert `zai-vision-mcp` NOT in `d['mcp']` (rename test accordingly); update header comments (drop GIT-357 re-add note, note GIT-364 removal; auto-start stays 3)
    — **Why:** The test currently asserts the removed server MUST exist opt-in — CI fails until the assertion inverts.
    — **Done when:** `bats tests/test_mcp_count_consistency.bats` passes.
    — **Consumers affected:** CI gate only.
- [ ] **4.4** Full verification gate: `bats tests/`; `node deploy/build-registry.mjs --check`; JSON parse guards for `opencode_app/opencode.json`, `deploy/agent-tiers.json`, `deploy/provider-models.json`, `deploy/skill-profiles.json`; stale-reference grep — `grep -rn "zai-vision-analysis\|zai-vision-mcp" . --exclude-dir=node_modules --exclude-dir=.git` with every hit classified as historical-exempt (CHANGELOG.md, MIGRATION.md, PLANS/, research/, LEARNINGS/, README:564 blockquote) or stale (must be zero)
    — **Why:** Blast-radius pattern (LEARNINGS tier-model-swap-blast-radius) requires proving no live surface still routes to the removed artifacts; the bat suites prove counts did not drift elsewhere.
    — **Done when:** all commands exit 0 and the stale grep shows only exempt files.
    — **Consumers affected:** release confidence for #364.

## Technical Notes

- The agents' inline bash fallback recipe (glm-5v-turbo direct API) is the fallback mechanism and STAYS — only citations to the deleted skill are rewritten.
- setup.sh skill counts/categories are disk-derived (`count_skills` / `print_skill_categories`, BT-157) — no hardcoded skill totals to edit; `test_count_drift.bats` re-derives from disk.
- glm-5v-turbo remains registered under the `zai` provider in models.dev/provider-models.json — the fallback stays functional; no provider-models array change (prose only).
- Historical documents (CHANGELOG.md, MIGRATION.md, PLANS/*, research/*, LEARNINGS/*) are exempt from edits per repo convention.

## Dependencies

None — no blocked-by tickets.

## Risks & Mitigation

- **Fallback path regression**: after prose edits the fallback recipe could read as removed → mitigation: Done-when greps in 2.1/2.2 explicitly require the recipe block untouched and "different model" phrasing retained.
- **Count drift in derived surfaces**: registry/skill-profiles/disk counts must agree → mitigation: `build-registry.mjs --check` + full `bats tests/` in 4.4.
- **Silent consumers of the opt-in MCP**: a project opencode.json enabling `zai-vision-mcp` would now reference a non-shipped server → acceptable: it was never enabled by default; opencode ignores unknown entries with a warning.
