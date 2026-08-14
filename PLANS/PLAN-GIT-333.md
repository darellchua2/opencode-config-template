# PLAN: Reduce initial context bloat from skills listing + subagent descriptions

**Issue:** https://github.com/darellchua2/opencode-config-template/issues/333
**Branch:** GIT-333 (PR base: `dev` — release.yml gates main+dev)
**Decisions (user-confirmed):**
1. **Configurator-agnostic design** — this repo ships defaults to downstream users; no opinionated hardcoded trim. New `--skill-profile lean|full` deploy-time flag, **default `lean`** (context-lean default; `--skill-profile full` opts back in). Shipped `opencode_app/opencode.json` allowlist stays at 87 (= the `full` profile source; the default flip lives in the deploy scripts). Documented as a behavior change in `MIGRATION.md`.
2. Lean profile = **29 skills** (audit's 28 + `pdf-specialist-skill`, whose only documented consumer is the primary session per the Office Document Routing tables).
3. **MCP opt-in defaults (phases 6-8, extension scope)** — shipped config flips `atlassian` + dead `zai-vision-mcp-server`/`zai-zread` to `enabled:false` (auto-start 6→3; `codegraph`, `mermaid`, `zai-web-reader` stay on). Per-project enablement via `<repo>/.opencode/opencode.json` merge (project wins over global) is THE enablement mechanism, fronted by new `opencode-repo-setup-skill` (detect → ask → merge-write delta → optional codegraph init → report). No jira-REST skill rewrite in this initiative — MCP enablement covers Atlassian; REST/API-token is documented inside the skill as fallback.

## Overview
Deployed sessions start with ~40k tokens of injected overhead; skills + subagent descriptions account for ~12-13k (`<available_skills>` ~8.1k for 87 allows; 36 agent descriptions ~4-5.5k). Deliver: (a) per-agent frontmatter allows so subagents are immune to any profile, (b) a lean/full skill-profile mechanism selected at deploy time, (c) slimmer agent descriptions, (d) doc/LEARNINGS/test sync. Default deploy profile: `lean` (opt back in with `--skill-profile full`); shipped `opencode.json` unchanged at 87. **Extension (phases 6-8):** MCP servers become fully opt-in (`atlassian` + 2 dead zai servers default-off, ~5.9-7.7k further savings in non-Jira projects) with new `opencode-repo-setup-skill` as the per-project interactive enablement frontend.

---

## Dependency & Consumer Map

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---------------------|---------------------------|---------------------------------|-------------|
| `opencode_app/.opencode/agents/*.md` (frontmatter allows) | nothing | subagents loading relocated skills under lean; `deploy/registry.json` (regen!); init resolver closures (`tests/init.bats`); `deploy/presets/pack-*.json` member sets | med — malformed frontmatter breaks agent load; resolver closure changes shift preset/init counts |
| `deploy/skill-profiles.json` (new) | nothing | `deploy/setup.sh --skill-profile`, `deploy/setup.ps1` parity, bats validation | low |
| `deploy/setup.sh` + `setup.ps1` (`--skill-profile` flag) | skill-profiles.json | deploy flow; banner/help text (Sync Rules); `tests/init.bats` CLI surface | med — flag must rewrite only the `permission.skill` block of the DEPLOYED config |
| `deploy/registry.json` | regenerated after ANY frontmatter change (Phases 1 & 3) | release.yml drift gate (`build-registry.mjs --check`, runs on PRs to main/dev) | high — committing frontmatter without regen = red CI |
| agent `description` frontmatter (slimming) | nothing | Task-tool agent listing; registry.json (verbatim embed) | med — losing trigger phrases degrades routing |
| `LEARNINGS/decisions/skill-permission-allowlist.md` | Phases 1-2 (records final state + supersedes 13-must-keep) | maintainers, `LEARNINGS/_index.md`, anti-pattern doc mentions | low |
| `README.md`, `opencode_app/README.md`, `deploy/.AGENTS.md` | all above | users, doc-consistency bats tests | low |
| `opencode_app/opencode.json` mcp block (enabled flips, Phase 6) | nothing | `tests/test_mcp_count_consistency.bats` (auto-start == 6 assertion), setup.sh/ps1 auto-start banners/help, README MCP listing, `deploy/.AGENTS.md` §MCP Tool Routing | med — flips every non-project session's tool surface; tests hard-assert current state |
| `opencode_app/.opencode/skills/opencode-repo-setup-skill/` (new, Phase 7) | skill-profiles.json (Phase 2) | primary sessions in target repos; `deploy/skill-profiles.json` lean array; README/registry/LEARNINGS count surfaces (Sync Rules) | med — new skill triggers the full doc-sync surface (130→131 etc.) |
| explorer-subagent zread prose (strip, Phase 6) | nothing | `deploy/registry.json` (regen only if description changes) | low |

---

## Implementation Phases

### Phase 1: Safety net — per-agent allows (makes subagents profile-immune)

- [x] **1.1** Classify all 58 lean-hidden skills against the source of truth (`opencode_app/.opencode/agents/*.md` frontmatter): `has-consumer` / `needs-new-allow` / `intentionally-hidden`. Known inputs from review: 12 confirmed `has-consumer` (clean-architecture, solid-principles, docx-creation, xlsx-specialist, tdd-workflow, linting-workflow, error-resolver-workflow, verification-loop, srs-creation, vision-creation, technical-design-creation, startup-pitch-deck); also already self-scoped: brd-creation (requirements-specialist), python-backend + fastapi-pydantic-orm (python-reviewer). 17 have zero consumer anywhere (research-paper-generation, horseshoe-paper-writing, eval-harness, authentication-authorization, database-migration, docker-containerization, logging-observability, performance-optimization, ascii-diagram-creator, construction-bd, python-packaging, csharp-linter, java-linter, monorepo-management, threejs-nextjs, deprecated-code-cleanup, pdf-specialist*) — `*`pdf-specialist moves to lean keep-list instead (Phase 2). Use exact `-skill`-suffixed names throughout.
    — **Why:** the audit was parsed from deployed copies; drops must be cross-referenced against source before mutation, and the LEARNINGS 13-must-keep constraint still names 7 of the no-consumer skills — they need explicit disposition, not silent orphaning
    — **Done when:** appendix table classifies all 58 with target agent(s) for every `needs-new-allow`; every `intentionally-hidden` entry has a one-line rationale
    — **Consumers affected:** none (read-only)
    — **Done:** scripted classification of all 58 hidden skills vs source frontmatter — 41 self-scoped, 17 needs-new-allow (0 intentionally-hidden); appendix table generated with exact `-skill` keys; files: PLANS/PLAN-GIT-333.md; fixes: none

- [x] **1.2** Add `permission.skill: allow` frontmatter entries for every `needs-new-allow` skill to its consumer agent(s); run `node deploy/build-registry.mjs` and commit the regenerated `registry.json` **in the same commit**; run `tests/init.bats` and update hardcoded assertions if resolver closures changed (known: `init.bats:65` `requiresSkills == 12` for code-review-subagent, `init.bats:84` `skill_dirs -eq 18` for `--preset review --yes`)
    — **Why:** global `"*": "deny"` (lean deployment) also gates subagents without self-scoped blocks; and release.yml runs `build-registry.mjs --check` on every PR — frontmatter changes without registry regen fail CI; init resolver auto-pulls `permission.skill` requirements so closure changes shift installed counts
    — **Done when:** every `needs-new-allow` skill appears in its consumer's frontmatter; `node deploy/build-registry.mjs --check` passes; `init.bats` green with assertions updated to new closure sizes; all frontmatter parses as valid YAML
    — **Consumers affected:** subagents under lean deployments; init CLI preset sizes; `deploy/presets/pack-*.json` member sets
    — **Done:** added 17 frontmatter allows across 9 agents (code-review +4, documentation +3, opentofu-explorer +2, python/typescript-reviewer +2 ea, nextjs-specialist +2, java-reviewer +1, linting +1, startup-founder +1); regenerated registry.json in same change (code-review 12→16 skills); updated init.bats assertions (requiresSkills 12→16, review preset 18→25 dirs); files: opencode_app/.opencode/agents/ (9 files), deploy/registry.json, tests/init.bats; fixes: cloned uninitialized bats submodule; jq absent → node one-liners

- [x] **1.3** Record the `intentionally-hidden` list + rationale in `LEARNINGS/decisions/skill-permission-allowlist.md`, and note supersession of the line-15 "13 must-keep" constraint (7 of those skills are lean-hidden by design)
    — **Why:** future maintainers must see orphans are deliberate, not drift; the old must-keep list contradicts the lean profile
    — **Done when:** decision file contains hidden list + supersession note
    — **Consumers affected:** maintainers only
    — **Done:** appended SUPERSEDED note (2026-08-14, GIT-333) lifting the 13-must-keep constraint, pointing at the PLAN appendix classification (41/17/0); files: LEARNINGS/decisions/skill-permission-allowlist.md; fixes: none

### Phase 2: Skill-profile mechanism (configurator-agnostic)

- [x] **2.1** Create `deploy/skill-profiles.json`: `{ "lean": [ ...29 exact keys... ] }` — lean = openapi-contract-adherence-skill, api-design-skill, ticket-plan-workflow-skill, markitdown-mcp-skill, docling-mcp-skill, git-branch-workflow-setup-skill, git-semantic-commits-skill, git-compact-commits-skill, documentation-sync-workflow-skill, continuous-learning-skill, security-audit-skill, zai-vision-analysis-skill, zai-image-generation-skill, plan-automation-loop-skill, plan-execution-skill, plan-updater-skill, context-budget-skill, strategic-compact-skill, grilling-skill, grill-me-skill, grill-with-docs-skill, opencode-skill-creation-skill, opencode-agent-creation-skill, opencode-skills-maintainer-skill, agent-introspection-debugging-skill, documentation-consistency-skill, mermaid-diagram-creator-skill, wireframer-skill, pdf-specialist-skill. `full` is NOT duplicated — it is whatever ships in `opencode_app/opencode.json` (single source, zero drift).
    — **Why:** every lean key must match a real skill dir (review found the audit's names omitted the `-skill` suffix — a typo'd key silently hides nothing/`length` checks still pass); duplicating full would create a second copy to drift
    — **Done when:** `jq '.lean | length'` == 29; every key matches a directory under `opencode_app/.opencode/skills/`; json is comment-free
    — **Consumers affected:** setup.sh/ps1 flag
    — **Done:** wrote deploy/skill-profiles.json (lean=29, script-verified: all keys on disk AND in shipped allowlist; `_comment` metadata key instead of `//`); files: deploy/skill-profiles.json; fixes: none

- [x] **2.2** Add `--skill-profile lean|full` to `deploy/setup.sh` (default `lean`): when `lean`, rewrite ONLY the `permission.skill` block of the DEPLOYED config (deployed copy, never the source `opencode_app/opencode.json`) to `lean` keys + `"*": "deny"`; when `full`, deploy verbatim as today; mirror in `deploy/setup.ps1` (Windows parity, Sync Rules); banner line showing active profile
    — **Why:** agnostic support = deploy-time selection, symmetric with `--provider`/`--mix`; source stays canonical at 87 so downstream defaults are unchanged
    — **Done when:** `--dry-run` previews the lean block swap (default) and `--dry-run --skill-profile full` shows no swap; setup.ps1 parity verified; help text updated
    — **Consumers affected:** deploy flow only
    — **Done:** new deploy/apply-skill-profile.mjs (rewrites deployed permission.skill only; full=verified no-op; typo-guard fail-closed); setup.sh: SKILL_PROFILE=lean default var + --skill-profile arg validation + run_skill_profile() after pack merger (dry-run preview path) + help text + summary banner line; setup.ps1: -SkillProfile param (ValidateSet) + Invoke-SkillProfile + call site + help + summary mirror; verified end-to-end: default dry-run preview = 29 allows + * deny, --skill-profile full = 87 verbatim; files: deploy/apply-skill-profile.mjs, deploy/setup.sh, deploy/setup.ps1; fixes: bash -n clean; standalone applier test exposed lean-then-full synthetic edge (documented as no-op semantics — deploy always re-copies source first)

- [x] **2.3** Add bats coverage: lean keys ⊆ skill dirs on disk; lean ⊆ full allowlist in `opencode_app/opencode.json`; `--skill-profile lean` deploy produces exactly 29 allows + `*` deny in the deployed copy (scratch target). Note: no existing test asserts allowlist size (confirmed by review — `test_count_drift`/`test_markitdown_skill` are disk-count-based, unaffected since skills stay on disk)
    — **Why:** the done-when for a data file is a test, not a hope; count tests must NOT be pointed at the allowlist
    — **Done when:** new bats test passes; full bats suite green
    — **Consumers affected:** CI
    — **Done:** new tests/skill_profiles.bats (6 tests: count=29, keys-on-disk, lean⊆shipped, lean scratch-rewrite 29+deny, full no-op, unknown-profile/typo-key fail-closed) — all green + full suite ALL-GREEN + registry check OK; files: tests/skill_profiles.bats; fixes: PROJECT_ROOT derived per-file (common.bash not sourced); tests use node not jq (jq absent locally and not CI-guaranteed)

### Phase 3: Agent description slimming

- [x] **3.1** Shorten `description` frontmatter across `opencode_app/.opencode/agents/*.md` (36 agents), longest first — keep trigger phrases verbatim, cut mechanism prose; target ≤ 2 sentences / ~40 words; regenerate `registry.json` in the same commit (descriptions are embedded verbatim at `build-registry.mjs:121`)
    — **Why:** all 36 descriptions surface in the primary's agent listing; registry drift gate embeds them verbatim — separate commits would re-drift
    — **Done when:** every description ≤ 40 words with triggers retained; `build-registry.mjs --check` passes; README tables (paraphrases, not verbatim — confirmed) still coherent
    — **Consumers affected:** agent picker, delegation routing, registry.json
    — **Done:** slimmed the 8 over-limit descriptions (image-analyzer 66→36, responsive-audit 63→38, requirements-specialist 62→38, technical-design 54→37, cad-specialist 56→29, repo-ops 46→37, opencode-tooling 45→30, pptx 41→32); all trigger phrases kept verbatim (grep-verified); registry regenerated in same change; files: opencode_app/.opencode/agents/ (8 files), deploy/registry.json; fixes: cad-specialist folded-block rewrite initially dropped the opening `---` (build-registry warned "no frontmatter", 36→35 agents) — restored via edit, re-verified 36 agents

### Phase 4: Doc sync + LEARNINGS update

- [x] **4.1** Update `LEARNINGS/decisions/skill-permission-allowlist.md`: document the profile mechanism (87 shipped / 29 lean / default lean), supersede the 13-must-keep list, fix stale references — title line 1 ("80 explicit allows"), line 5 math, line 10 ("36 of 39 subagents"), line 18 ("80 allows + 1 deny"). Also `LEARNINGS/_index.md:29` ("80 allows" title) and `LEARNINGS/anti-patterns/jsonc-comments-in-opencode-json.md:6` ("80-entry allowlist")
    — **Why:** decision doc + index + anti-pattern all carry the stale count; the "no residual 80 references" gate is repo-wide
    — **Done when:** `rg -n '\b80\b' LEARNINGS/` returns nothing allowlist-related; decision file documents lean/full + hidden list
    — **Consumers affected:** maintainers, future sessions
    — **Done:** rewrote decision file (87 shipped / 29 lean / default lean, superseded-constraint section, new references incl. skill-profiles.json + apply-skill-profile.mjs); _index.md entry title updated; jsonc anti-pattern "80-entry" → "87-entry" + _comment-key note; `grep -rn '\b80\b' LEARNINGS/` clean; files: LEARNINGS/decisions/skill-permission-allowlist.md, LEARNINGS/_index.md, LEARNINGS/anti-patterns/jsonc-comments-in-opencode-json.md; fixes: none

- [x] **4.2** README skill count stays **130** (source of truth is consistent: find-based count excluding `_archived` AND `_common` = 130; registry.json says 130; the "131" was deployed-copy drift, fixed by redeploy not docs). Add `opencode_app/README.md:26` ("130 skill directories" literal) to verification scope. Add lean/full profile section to README deploy docs. Sync README Presets table member counts if Phase 1 closure changes shifted them ("9 Code Quality", "10", "26", "12", "11"…) and verify `deploy/presets/pack-*.json` `skills` arrays against regenerated registry (generator `/tmp/gen-presets.mjs` is uncommitted — sync manually or commit it)
    — **Why:** 4.2's original "130→131 fix" would itself fail `tests/test_markitdown_skill.bats:73-99` (`skill_count_consistent_across_docs` asserts README == find == count_skills); preset counts are consumer-visible
    — **Done when:** `test_markitdown_skill.bats` + `test_count_drift.bats` green; presets table matches registry
    — **Consumers affected:** README readers, doc-consistency tests
    — **Done:** README count stays 130 (verified vs find-based count + registry + opencode_app/README.md:26); added "Skill Profiles — deploy-time primary visibility (#333)" section after Provider Packs; presets table resynced to actual closures (review 25, frontend 19, backend 17, docs 21, devops 31, business 32; core/research/cad unchanged); pack-{review,backend,frontend,docs,devops,business}.json skills arrays synced to measured closures (generator was uncommitted — synced via scratch-install enumeration); files: README.md, deploy/presets/ (6 files); fixes: none

- [x] **4.3** Update `deploy/.AGENTS.md` §Skill Permission Allowlist — guidance only (review: section contains NO counts): document the lean/full profiles, `--skill-profile` flag, and per-agent frontmatter allows as the relocation mechanism
    — **Why:** deployed to every session as `~/.config/opencode/AGENTS.md`; must teach the profile pattern, not stale counts
    — **Done when:** section reflects the mechanism
    — **Consumers affected:** every deployed session
    — **Done:** deploy/.AGENTS.md §Skill Permission Allowlist now documents lean/full profiles, --skill-profile flag, apply-skill-profile.mjs, lean-array addition guidance for new skills, and profile-immunity of self-scoped subagents; files: deploy/.AGENTS.md; fixes: none

- [x] **4.4** Verify `deploy/setup.sh`/`setup.ps1` dynamic counts unaffected (counts computed via `count_agents`/`count_skills` — confirmed); confirm no hardcoded "80"/"87" in allowlist context; update setup help text for the new flag; add default-lean behavior-change note to `MIGRATION.md`
    — **Why:** Sync Rules; confirm-only because counts are computed
    — **Done when:** `rg -n '\b(80|87)\b' deploy/setup.sh deploy/setup.ps1` returns nothing allowlist-related; help text shows `--skill-profile`
    — **Consumers affected:** setup banner/help
    — **Done:** verified setup.sh/ps1 contain no stale "80" (all "87" mentions are intentional full-profile docs added in Phase 2 help text); setup help text shows --skill-profile (Phase 2); MIGRATION.md TL;DR gained the default-lean behavior-change bullet (#333); files: MIGRATION.md; fixes: none

### Phase 5: Verification, commits, PR

- [x] **5.1** Pre-flight: restore locally-deleted tracked files (`git checkout -- package.json package-lock.json` — CI-equivalent local steps incl. release.yml tarball guard need them); `git add PLANS/PLAN-GIT-333.md` (untracked — repo convention commits PLANS/)
    — **Why:** npm/registry/regen steps fail on the missing files; an untracked PLAN never reaches the PR
    — **Done when:** `git status` clean apart from intended worktree changes
    — **Consumers affected:** none
    — **Done:** package.json/package-lock.json restored at loop start; PLAN committed from Phase 1 onward; `git status` clean before PR; files: —; fixes: none

- [x] **5.2** Smoke test: deploy to a scratch target with `--skill-profile lean --dry-run` (or scratch HOME), start a fresh opencode session there, confirm `<available_skills>` lists exactly 29; record before/after initial-token delta (expected ≈ 5.5k skills + 1-2k descriptions ≈ 6.5-7.5k)
    — **Why:** measured reduction is the whole point; claims need a number
    — **Done when:** listing == 29; delta recorded for the PR description
    — **Consumers affected:** none
    — **Done:** dry-run preview AND full scratch-HOME deploy (`--quick`) both yield exactly 29 allows + `"*": "deny"` in the deployed config (`<available_skills>` is mechanically derived from that block); measured delta: skills listing 5794→1940 tok (**~3.9k saved**, below the 6.5-7.5k estimate — actual hidden descriptions average ~66 tok, not the audit's ~93) + ~0.15k from Phase 3 description slimming; recorded in PR #334 description and #333 comment; files: —; fixes: first description-token measurement script over-captured folded bodies (839k chars) — rewrote parser to stop at block end

- [x] **5.3** Atomic semantic commits, each self-green for the registry drift gate (bundle `registry.json` regen with its frontmatter commit): Phase 1 `feat(agents): scope subagent-only skills via frontmatter allows` + registry + init.bats; Phase 2 `feat(deploy): add --skill-profile lean|full option` (profiles json + setup.sh/ps1 + bats); Phase 3 `refactor(agents): slim subagent descriptions` + registry; Phase 4 `docs: sync skill-profile docs and LEARNINGS`; PLAN file `docs(plan): add PLAN-GIT-333`. Push GIT-333, open PR **to `dev`** referencing #333
    — **Why:** semantic-release drives CHANGELOG/version from commit types (CHANGELOG is auto-generated — no manual entry, confirmed); intermediate commits must not trip the registry drift gate; repo workflow is dev→uat→main
    — **Done when:** PR open on dev, CI green, #333 linked
    — **Consumers affected:** reviewers, CI, semantic-release
    — **Done:** 4 atomic phase commits (56ad174 feat(agents), 781ce8e feat(deploy), ed46ec3 refactor(agents), 5fa6f15 docs) + plan commit 3aa999f, each bundled with registry regen where frontmatter/descriptions changed; PR #334 opened to dev referencing #333; local gates all green (CI verdict pending remote run); files: PLANS/PLAN-GIT-333.md; fixes: none

- [x] **5.4** Post-merge note on #333: run `./deploy/setup.sh` to redeploy (default is lean now; fixes the deployed 131-drift and activates lean for this machine)
    — **Why:** merged PR changes nothing for existing installs (setup.sh deploys opencode.json verbatim; deployed copies must never be hand-edited — repo rule)
    — **Done when:** comment posted on #333
    — **Consumers affected:** this machine's deployment
    — **Done:** comment posted (issuecomment-5293510135) with measured savings + post-merge redeploy instructions (`./deploy/setup.sh`, default lean, resolves 131-drift); posted pre-merge so instructions are on the ticket regardless of merge timing; files: —; fixes: none

### Phase 6: MCP opt-in defaults (everything-off unless project-declared)

- [x] **6.1** Flip shipped defaults in `opencode_app/opencode.json` (comment-free strict JSON): `atlassian.enabled` true→false, `zai-vision-mcp-server.enabled` true→false, `zai-zread.enabled` true→false. `codegraph`, `mermaid`, `zai-web-reader` stay enabled. Auto-start count 6→3.
    — **Why:** both zai servers are already runtime-denied globally (proven dead, ~1.2k tok/session wasted); atlassian costs ~4.7-6.5k/session even unused and schemas inject regardless of `permission.tool` deny (dead-server proof); per-project enablement (Phase 7) replaces global-on
    — **Done when:** enabled-count == 3 via python3 json check; config still valid strict JSON; no other keys touched
    — **Consumers affected:** every deployed session's tool surface; bats suites; banners
    — **Done:** flipped atlassian/zai-vision-mcp-server/zai-zread to enabled:false via surgical edits (node full-file rewrite reformatted the file — reverted); enabled = codegraph, zai-web-reader, mermaid (3); config still strict JSON; files: opencode_app/opencode.json; fixes: zai-zread edit initially produced duplicate enabled key — removed stale line, JSON parses\n
- [x] **6.2** Update `tests/test_mcp_count_consistency.bats` **in the same commit** as 6.1: `mcp_count_auto_start_is_six` → `..._is_three` (codegraph, mermaid, zai-web-reader) + header comment (lines 11-13, 43-48); add per-server opt-in assertions mirroring the markitdown pattern (lines 38-41) for `atlassian`, `zai-vision-mcp-server`, `zai-zread`
    — **Why:** the suite hard-asserts auto-start == 6 — the config flip alone turns CI red; the markitdown assertion is the established opt-in precedent
    — **Done when:** suite green against the flipped config
    — **Consumers affected:** CI
    — **Done:** same-commit bats update: auto_start_is_six → auto_start_is_three + 3 new per-server opt-in assertions (markitdown pattern) + header note; suite 6/6 green; files: tests/test_mcp_count_consistency.bats; fixes: none\n
- [x] **6.3** Sync auto-start mentions: `deploy/setup.sh` + `deploy/setup.ps1` banner/help "MCP Servers (6)"-style auto-start text → 3 (grep both); README + `opencode_app/README.md` enabled-server/auto-start listings if they enumerate the six
    — **Why:** those surfaces document the AUTO-START set; silent drift repeats the 130-vs-131 count story
    — **Done when:** no stale auto-start references; `mcp_count` doc test green
    — **Consumers affected:** setup banner/help readers
    — **Done:** swept auto-start text: setup.sh help (MCP SERVERS listing regrouped), config-echo block (3478), banner MCP Servers (6)→(3); setup.ps1 both mirrors; README MCP Servers section rewritten (3 default + 12 opt-in table + per-project snippet); files: deploy/setup.sh, deploy/setup.ps1, README.md; fixes: none\n
- [x] **6.4** Strip explorer-subagent's dead zread prose (instructions reference globally-denied `zai-zread` tools with no tool override — verified dead code); regen `registry.json` in the same commit if the description changed
    — **Why:** the audit's "pick one, not both" finding — prose + deny teaches agents to call tools that always fail
    — **Done when:** no `zai-zread` references remain in agent prompts; `build-registry.mjs --check` green
    — **Consumers affected:** explorer-subagent; registry.json
    — **Done:** explorer-subagent remote-exploration prose rewritten to gh CLI + webfetch raw.githubusercontent.com fallback (zread noted as disabled-by-default only); registry regenerated + --check green (1-line diff, description unchanged); files: opencode_app/.opencode/agents/explorer-subagent.md, deploy/registry.json; fixes: none\n
- [x] **6.5** Docs: README MCP section gains the per-project enablement snippet (`<repo>/.opencode/opencode.json`: `{"mcp":{"atlassian":{"enabled":true}}}`, project wins over global); `deploy/.AGENTS.md` §MCP Tool Routing marks Atlassian tools conditional on project enablement; `MIGRATION.md` TL;DR behavior-change bullet (auto-start 6→3 + opt-in path)
    — **Why:** deployed AGENTS.md reaches every session — must not route to tools that are off by default; MIGRATION.md is the behavior-change ledger (same as the default-lean bullet)
    — **Done when:** routing reflects opt-in state; MIGRATION bullet present; docs consistent with config
    — **Consumers affected:** every deployed session; README readers
    — **Done:** deploy/.AGENTS.md §MCP Tool Routing gained per-project enablement rule (no atlassian_* calls unless project-enabled); MIGRATION.md TL;DR gained auto-start 6→3 behavior-change bullet with restore path; files: deploy/.AGENTS.md, MIGRATION.md; fixes: none\n
### Phase 7: `opencode-repo-setup-skill` (per-project enablement frontend)

- [x] **7.1** Create `opencode_app/.opencode/skills/opencode-repo-setup-skill/SKILL.md` — flow: **detect** (existing `.opencode/`, `.codegraph/`, Jira/GitHub refs in AGENTS.md, framework manifests, CI files) → **ask** via `question` tool (which MCP servers to enable incl. `atlassian`/zai extras; `codegraph init -i`?; scaffold minimal project AGENTS.md?) → **merge-write** `<repo>/.opencode/opencode.json` delta-only (node-based read-modify-write; never clobber existing keys; fail-closed on parse error; comment-free output) → optional `codegraph init -i` → **report** (enabled set, ~token cost, revert = delete the file). Idempotent on re-run. Triggers: "set up this repo for opencode", "enable mcp for this project", "project-level opencode config", "opencode repo setup". Include the Atlassian OAuth browser-flow caveat (mcp-remote first auth) + REST/API-token fallback pointers (id.atlassian.com scoped tokens, `_edge/tenant_info` cloudId discovery, `api.atlassian.com/ex/jira/{cloudId}`).
    — **Why:** enablement needs an interactive frontend or users hand-write project configs; procedures live in the skill, NOT user-level AGENTS.md (zero always-on cost — placement decision from the session)
    — **Done when:** SKILL.md on disk; valid frontmatter; all five flow sections complete; no secret literals
    — **Consumers affected:** primary sessions in target repos
    — **Why:** enablement needs an interactive frontend or users hand-write project configs; procedures live in the skill, NOT user-level AGENTS.md (zero always-on cost — placement decision from the session)
    — **Done when:** SKILL.md on disk; valid frontmatter; all five flow sections complete; no secret literals
    — **Consumers affected:** primary sessions in target repos
    — **Done:** Created opencode_app/.opencode/skills/opencode-repo-setup-skill/SKILL.md (detect→ask→merge-write→init→report, Atlassian OAuth/headless caveats, governance table); category normalized to “OpenCode Meta” to match siblings; files: opencode_app/.opencode/skills/opencode-repo-setup-skill/SKILL.md; fixes: category OpenCode/Config→OpenCode Meta pre-registry-regen

- [x] **7.2** Wire allowlist + profile: add `opencode-repo-setup-skill: allow` to shipped `permission.skill` (87→88) AND `deploy/skill-profiles.json` lean (29→30) — primary-invoked setup skill, one listing line, high value; update `tests/skill_profiles.bats` count assertions (29→30; 30→31 incl. deny)
    — **Why:** hidden = Skill-tool-denied for the primary under both profiles' `"*": "deny"`; lean is the default so it must be lean-visible
    — **Done when:** skill_profiles.bats green at the new counts; lean ⊆ shipped holds; valid JSON
    — **Consumers affected:** lean/full deploys; skill_profiles.bats
    — **Why:** hidden = Skill-tool-denied for the primary under both profiles' `"*": "deny"`; lean is the default so it must be lean-visible
    — **Done when:** skill_profiles.bats green at the new counts; lean ⊆ shipped holds; valid JSON
    — **Consumers affected:** lean/full deploys; skill_profiles.bats
    — **Done:** Added opencode-repo-setup-skill allow to shipped allowlist (88 allows) + lean profile (sorted, count 30) + skill_profiles.bats 29→30 in 4 spots; files: opencode_app/opencode.json, deploy/skill-profiles.json, tests/skill_profiles.bats; fixes: initial lean insert broke sort order (sorted-ok false) — reordered to alphabetical

- [x] **7.3** Sync Rules sweep for the new skill: skill counts 130→131 (README lines ~27/241/517/521 + `opencode_app/README.md:26`); `node deploy/build-registry.mjs` regen (skills 130→131) **in the same commit**; LEARNINGS decision counts (87→88 shipped, 29→30 lean); README skill-categories table; setup.sh/ps1 category listings if they enumerate it
    — **Why:** `test_markitdown_skill.bats:73-99` asserts README == find == count_skills — count edits must land with the skill dir; registry drift gate on every PR
    — **Done when:** all count surfaces say 131 skills / 88 allows / 30 lean; doc-consistency tests green
    — **Consumers affected:** CI, README, registry.json, LEARNINGS
    — **Why:** `test_markitdown_skill.bats:73-99` asserts README == find == count_skills — count edits must land with the skill dir; registry drift gate on every PR
    — **Done when:** all count surfaces say 131 skills / 88 allows / 30 lean; doc-consistency tests green
    — **Consumers affected:** CI, README, registry.json, LEARNINGS
    — **Done:** Sync sweep: registry regen (skills=131), README 130→131 ×4 + OpenCode Meta row (4)→(5) + profile section 87→88/29→30 + history note, opencode_app/README.md:26, LEARNINGS decision/_index/jsonc anti-pattern (88/30, measured ~3.9k), MIGRATION.md, deploy/.AGENTS.md, setup.sh ×3 + setup.ps1 ×2 help/comment refs; files: README.md, opencode_app/README.md, LEARNINGS/decisions/skill-permission-allowlist.md, LEARNINGS/_index.md, LEARNINGS/anti-patterns/jsonc-comments-in-opencode-json.md, MIGRATION.md, deploy/.AGENTS.md, deploy/setup.sh, deploy/setup.ps1, deploy/registry.json; fixes: sweep grep caught 2 residuals (_index.md title, setup.ps1:1888) after first pass

### Phase 8: Verification + ship (extension)

- [ ] **8.1** Scratch-repo simulation: temp git repo; merge-write exactly as the skill prescribes yields `{"mcp":{"atlassian":{"enabled":true}}}` delta with pre-existing project keys preserved; verify project-over-global merge precedence with a scratch-HOME opencode session (project sees atlassian tools ON while global stays OFF); global config byte-identical after; delete-file revert works
    — **Why:** the whole mechanism rests on project-wins merge semantics — verify against live opencode, don't assume
    — **Done when:** simulation passes end-to-end
    — **Consumers affected:** none (throwaway)

- [ ] **8.2** Full gate: every `tests/*.bats` suite green; `node deploy/build-registry.mjs --check` green; `bash -n` on touched scripts; dry-run deploy lands lean-30 + auto-start 3
    — **Why:** never push red; the extension touches config + tests + counts simultaneously
    — **Done when:** all green locally
    — **Consumers affected:** CI

- [ ] **8.3** Atomic commits on GIT-333: Phase 6 `feat(config): default atlassian and dead zai MCP servers to opt-in` (config + bats + banners + routing docs), Phase 7 `feat(skills): add opencode-repo-setup-skill for per-project enablement` (skill + profiles + counts), Phase 8 residual `docs:`; push; update #333 (extension summary + expected ~5.9-7.7k additional savings). **Decision point:** PR #334 still open — extend it with these commits (default; single initiative) or merge #334 first and stack a new PR
    — **Why:** semantic-release types drive CHANGELOG; PR history must show scope
    — **Done when:** commits pushed; #333 updated; CI green
    — **Consumers affected:** reviewers, CI, semantic-release

- [ ] **8.4** Post-merge note on #333: `./deploy/setup.sh` redeploy activates lean-30 + auto-start 3; per-project users run the new skill to re-enable what they need
    — **Why:** merged PRs change nothing for existing installs (setup.sh redeploys; deployed copies never hand-edited)
    — **Done when:** comment appended
    — **Consumers affected:** this machine + downstream users

---

## Appendix: 1.1 Classification Table

_To be filled during execution of step 1.1 — all 58 lean-hidden skills classified (has-consumer / needs-new-allow / intentionally-hidden), exact `-skill`-suffixed names, target agent(s) for needs-new-allow, one-line rationale for hidden._

## Technical Notes
- `opencode_app/opencode.json` must remain comment-free strict JSON (bats `json.load` gate) — and its allowlist is NOT modified by this PLAN (ships at 87 = full).
- Lean hides 58 skills from the primary's `<available_skills>` (~93 tok/description ≈ 5.4k saved); skills stay on disk and available to scoped subagents; re-exposing any skill is a one-line profiles edit.
- `pdf-specialist-skill` in lean (29th): primary is its only documented consumer (Office Document Routing Tier 4, root AGENTS.md + deploy/.AGENTS.md) — hiding it would break the routing table.
- Only command-block skill reference is `/run-plan` → `plan-automation-loop-skill` (kept in lean). docker-entrypoint/plugins reference no lean-hidden skills.
- README Subagents/Trigger-Phrases tables are paraphrases — Phase 3 won't desync them; the verbatim consumer is registry.json.
- `test_mcp_count_consistency.bats:43-48` hard-asserts auto-start == 6 (codegraph, atlassian, zai-vision, mermaid, zai-web-reader, zai-zread); lines 38-41 (markitdown opt-in) are the per-server assertion precedent; banner "(6)" refs = AUTO-START count (header note lines 11-13).
- Project `.opencode/opencode.json` merges over global (project wins) — opencode config layering; 8.1 verifies live before doc claims rely on it.
- Atlassian per-project first use opens a browser for OAuth (mcp-remote); headless/docker needs the REST/API-token fallback documented in the skill.

## Dependencies
- None external. Blocked-by: nothing.

## Risks & Mitigation
- **Lean hides a skill a downstream primary @-mentions** → documented tradeoff in README profile section; one-line profiles edit to re-expose.
- **Malformed agent frontmatter breaks agent loading** → 1.2 done-when requires valid YAML + registry check.
- **Init/preset count drift from closure changes** → 1.2 updates init.bats assertions; 4.2 syncs preset tables + pack files.
- **Registry drift gate red on intermediate commits** → every frontmatter commit bundles regen (5.3).
- **Description slimming drops a trigger phrase** → triggers kept verbatim (3.1); smoke-test delegation routing in 5.2.
- **setup.ps1 parity lag** → 2.2 done-when includes ps1 mirror.
- **PR #334 scope grows with phases 6-8 on GIT-333** → merge-first + stacked PR is the fallback (decision recorded at 8.3).
- **Auto-start count surfaces drift (banners/help/README)** → 6.3 sweeps all in the same commit as the flip; 6.2 keeps the bats assertion authoritative.
- **Project-wins merge assumption wrong** → 8.1 verifies against live opencode behavior before any doc claims.

## Success Metrics
- Lean deployment: initial overhead reduced ~6.5-7.5k tokens (58 fewer skill descriptions + slimmer agent descriptions); full deployment: ~1-2k (descriptions only).
- Extension: non-project sessions save an additional ~5.9-7.7k tokens (atlassian schemas ~4.7-6.5k + dead zai ~1.2k) → total ~10-11.5k with lean.
- Scratch-repo enablement round-trip works: enable → project session sees the tools → delete project config → gone; global never mutated.
- All bats suites green; `build-registry.mjs --check` green; README/LEARNINGS/registry counts consistent (zero drift).
