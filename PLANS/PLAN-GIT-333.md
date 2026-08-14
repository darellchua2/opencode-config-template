# PLAN: Reduce initial context bloat from skills listing + subagent descriptions

**Issue:** https://github.com/darellchua2/opencode-config-template/issues/333
**Branch:** GIT-333 (PR base: `dev` — release.yml gates main+dev)
**Decisions (user-confirmed):**
1. **Configurator-agnostic design** — this repo ships defaults to downstream users; no opinionated hardcoded trim. New `--skill-profile lean|full` deploy-time flag, **default `lean`** (context-lean default; `--skill-profile full` opts back in). Shipped `opencode_app/opencode.json` allowlist stays at 87 (= the `full` profile source; the default flip lives in the deploy scripts). Documented as a behavior change in `MIGRATION.md`.
2. Lean profile = **29 skills** (audit's 28 + `pdf-specialist-skill`, whose only documented consumer is the primary session per the Office Document Routing tables).

## Overview
Deployed sessions start with ~40k tokens of injected overhead; skills + subagent descriptions account for ~12-13k (`<available_skills>` ~8.1k for 87 allows; 36 agent descriptions ~4-5.5k). Deliver: (a) per-agent frontmatter allows so subagents are immune to any profile, (b) a lean/full skill-profile mechanism selected at deploy time, (c) slimmer agent descriptions, (d) doc/LEARNINGS/test sync. Default deploy profile: `lean` (opt back in with `--skill-profile full`); shipped `opencode.json` unchanged at 87.

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

---

## Appendix: 1.1 Classification Table

_To be filled during execution of step 1.1 — all 58 lean-hidden skills classified (has-consumer / needs-new-allow / intentionally-hidden), exact `-skill`-suffixed names, target agent(s) for needs-new-allow, one-line rationale for hidden._

## Technical Notes
- `opencode_app/opencode.json` must remain comment-free strict JSON (bats `json.load` gate) — and its allowlist is NOT modified by this PLAN (ships at 87 = full).
- Lean hides 58 skills from the primary's `<available_skills>` (~93 tok/description ≈ 5.4k saved); skills stay on disk and available to scoped subagents; re-exposing any skill is a one-line profiles edit.
- `pdf-specialist-skill` in lean (29th): primary is its only documented consumer (Office Document Routing Tier 4, root AGENTS.md + deploy/.AGENTS.md) — hiding it would break the routing table.
- Only command-block skill reference is `/run-plan` → `plan-automation-loop-skill` (kept in lean). docker-entrypoint/plugins reference no lean-hidden skills.
- README Subagents/Trigger-Phrases tables are paraphrases — Phase 3 won't desync them; the verbatim consumer is registry.json.

## Dependencies
- None external. Blocked-by: nothing.

## Risks & Mitigation
- **Lean hides a skill a downstream primary @-mentions** → documented tradeoff in README profile section; one-line profiles edit to re-expose.
- **Malformed agent frontmatter breaks agent loading** → 1.2 done-when requires valid YAML + registry check.
- **Init/preset count drift from closure changes** → 1.2 updates init.bats assertions; 4.2 syncs preset tables + pack files.
- **Registry drift gate red on intermediate commits** → every frontmatter commit bundles regen (5.3).
- **Description slimming drops a trigger phrase** → triggers kept verbatim (3.1); smoke-test delegation routing in 5.2.
- **setup.ps1 parity lag** → 2.2 done-when includes ps1 mirror.

## Success Metrics
- Lean deployment: initial overhead reduced ~6.5-7.5k tokens (58 fewer skill descriptions + slimmer agent descriptions); full deployment: ~1-2k (descriptions only).
- All bats suites green; `build-registry.mjs --check` green; README/LEARNINGS/registry counts consistent (zero drift).
