# PLAN: Reduce initial context bloat from skills listing + subagent descriptions

**Issue:** https://github.com/darellchua2/opencode-config-template/issues/333
**Branch:** GIT-333 (PR base: `dev` — release.yml gates main+dev)
**Decisions (user-confirmed):**
1. **Configurator-agnostic design** — this repo ships defaults to downstream users; no opinionated hardcoded trim. New `--skill-profile lean|full` deploy-time flag, **default `full`** (non-breaking). Shipped `opencode_app/opencode.json` allowlist stays at 87.
2. Lean profile = **29 skills** (audit's 28 + `pdf-specialist-skill`, whose only documented consumer is the primary session per the Office Document Routing tables).

## Overview
Deployed sessions start with ~40k tokens of injected overhead; skills + subagent descriptions account for ~12-13k (`<available_skills>` ~8.1k for 87 allows; 36 agent descriptions ~4-5.5k). Deliver: (a) per-agent frontmatter allows so subagents are immune to any profile, (b) a lean/full skill-profile mechanism selected at deploy time, (c) slimmer agent descriptions, (d) doc/LEARNINGS/test sync. Shipped defaults unchanged; `lean` is opt-in.

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

- [ ] **1.1** Classify all 59 lean-hidden skills against the source of truth (`opencode_app/.opencode/agents/*.md` frontmatter): `has-consumer` / `needs-new-allow` / `intentionally-hidden`. Known inputs from review: 12 confirmed `has-consumer` (clean-architecture, solid-principles, docx-creation, xlsx-specialist, tdd-workflow, linting-workflow, error-resolver-workflow, verification-loop, srs-creation, vision-creation, technical-design-creation, startup-pitch-deck); also already self-scoped: brd-creation (requirements-specialist), python-backend + fastapi-pydantic-orm (python-reviewer). 17 have zero consumer anywhere (research-paper-generation, horseshoe-paper-writing, eval-harness, authentication-authorization, database-migration, docker-containerization, logging-observability, performance-optimization, ascii-diagram-creator, construction-bd, python-packaging, csharp-linter, java-linter, monorepo-management, threejs-nextjs, deprecated-code-cleanup, pdf-specialist*) — `*`pdf-specialist moves to lean keep-list instead (Phase 2). Use exact `-skill`-suffixed names throughout.
    — **Why:** the audit was parsed from deployed copies; drops must be cross-referenced against source before mutation, and the LEARNINGS 13-must-keep constraint still names 7 of the no-consumer skills — they need explicit disposition, not silent orphaning
    — **Done when:** appendix table classifies all 59 with target agent(s) for every `needs-new-allow`; every `intentionally-hidden` entry has a one-line rationale
    — **Consumers affected:** none (read-only)

- [ ] **1.2** Add `permission.skill: allow` frontmatter entries for every `needs-new-allow` skill to its consumer agent(s); run `node deploy/build-registry.mjs` and commit the regenerated `registry.json` **in the same commit**; run `tests/init.bats` and update hardcoded assertions if resolver closures changed (known: `init.bats:65` `requiresSkills == 12` for code-review-subagent, `init.bats:84` `skill_dirs -eq 18` for `--preset review --yes`)
    — **Why:** global `"*": "deny"` (lean deployment) also gates subagents without self-scoped blocks; and release.yml runs `build-registry.mjs --check` on every PR — frontmatter changes without registry regen fail CI; init resolver auto-pulls `permission.skill` requirements so closure changes shift installed counts
    — **Done when:** every `needs-new-allow` skill appears in its consumer's frontmatter; `node deploy/build-registry.mjs --check` passes; `init.bats` green with assertions updated to new closure sizes; all frontmatter parses as valid YAML
    — **Consumers affected:** subagents under lean deployments; init CLI preset sizes; `deploy/presets/pack-*.json` member sets

- [ ] **1.3** Record the `intentionally-hidden` list + rationale in `LEARNINGS/decisions/skill-permission-allowlist.md`, and note supersession of the line-15 "13 must-keep" constraint (7 of those skills are lean-hidden by design)
    — **Why:** future maintainers must see orphans are deliberate, not drift; the old must-keep list contradicts the lean profile
    — **Done when:** decision file contains hidden list + supersession note
    — **Consumers affected:** maintainers only

### Phase 2: Skill-profile mechanism (configurator-agnostic)

- [ ] **2.1** Create `deploy/skill-profiles.json`: `{ "lean": [ ...29 exact keys... ] }` — lean = openapi-contract-adherence-skill, api-design-skill, ticket-plan-workflow-skill, markitdown-mcp-skill, docling-mcp-skill, git-branch-workflow-setup-skill, git-semantic-commits-skill, git-compact-commits-skill, documentation-sync-workflow-skill, continuous-learning-skill, security-audit-skill, zai-vision-analysis-skill, zai-image-generation-skill, plan-automation-loop-skill, plan-execution-skill, plan-updater-skill, context-budget-skill, strategic-compact-skill, grilling-skill, grill-me-skill, grill-with-docs-skill, opencode-skill-creation-skill, opencode-agent-creation-skill, opencode-skills-maintainer-skill, agent-introspection-debugging-skill, documentation-consistency-skill, mermaid-diagram-creator-skill, wireframer-skill, pdf-specialist-skill. `full` is NOT duplicated — it is whatever ships in `opencode_app/opencode.json` (single source, zero drift).
    — **Why:** every lean key must match a real skill dir (review found the audit's names omitted the `-skill` suffix — a typo'd key silently hides nothing/`length` checks still pass); duplicating full would create a second copy to drift
    — **Done when:** `jq '.lean | length'` == 29; every key matches a directory under `opencode_app/.opencode/skills/`; json is comment-free
    — **Consumers affected:** setup.sh/ps1 flag

- [ ] **2.2** Add `--skill-profile lean|full` to `deploy/setup.sh` (default `full`): when `lean`, rewrite ONLY the `permission.skill` block of the DEPLOYED config (deployed copy, never the source `opencode_app/opencode.json`) to `lean` keys + `"*": "deny"`; mirror in `deploy/setup.ps1` (Windows parity, Sync Rules); banner line showing active profile
    — **Why:** agnostic support = deploy-time selection, symmetric with `--provider`/`--mix`; source stays canonical at 87 so downstream defaults are unchanged
    — **Done when:** `--dry-run` with `--skill-profile lean` previews the block swap; default run is a no-op vs today; setup.ps1 parity verified; help text updated
    — **Consumers affected:** deploy flow only

- [ ] **2.3** Add bats coverage: lean keys ⊆ skill dirs on disk; lean ⊆ full allowlist in `opencode_app/opencode.json`; `--skill-profile lean` deploy produces exactly 29 allows + `*` deny in the deployed copy (scratch target). Note: no existing test asserts allowlist size (confirmed by review — `test_count_drift`/`test_markitdown_skill` are disk-count-based, unaffected since skills stay on disk)
    — **Why:** the done-when for a data file is a test, not a hope; count tests must NOT be pointed at the allowlist
    — **Done when:** new bats test passes; full bats suite green
    — **Consumers affected:** CI

### Phase 3: Agent description slimming

- [ ] **3.1** Shorten `description` frontmatter across `opencode_app/.opencode/agents/*.md` (36 agents), longest first — keep trigger phrases verbatim, cut mechanism prose; target ≤ 2 sentences / ~40 words; regenerate `registry.json` in the same commit (descriptions are embedded verbatim at `build-registry.mjs:121`)
    — **Why:** all 36 descriptions surface in the primary's agent listing; registry drift gate embeds them verbatim — separate commits would re-drift
    — **Done when:** every description ≤ 40 words with triggers retained; `build-registry.mjs --check` passes; README tables (paraphrases, not verbatim — confirmed) still coherent
    — **Consumers affected:** agent picker, delegation routing, registry.json

### Phase 4: Doc sync + LEARNINGS update

- [ ] **4.1** Update `LEARNINGS/decisions/skill-permission-allowlist.md`: document the profile mechanism (87 shipped / 29 lean / default full), supersede the 13-must-keep list, fix stale references — title line 1 ("80 explicit allows"), line 5 math, line 10 ("36 of 39 subagents"), line 18 ("80 allows + 1 deny"). Also `LEARNINGS/_index.md:29` ("80 allows" title) and `LEARNINGS/anti-patterns/jsonc-comments-in-opencode-json.md:6` ("80-entry allowlist")
    — **Why:** decision doc + index + anti-pattern all carry the stale count; the "no residual 80 references" gate is repo-wide
    — **Done when:** `rg -n '\b80\b' LEARNINGS/` returns nothing allowlist-related; decision file documents lean/full + hidden list
    — **Consumers affected:** maintainers, future sessions

- [ ] **4.2** README skill count stays **130** (source of truth is consistent: find-based count excluding `_archived` AND `_common` = 130; registry.json says 130; the "131" was deployed-copy drift, fixed by redeploy not docs). Add `opencode_app/README.md:26` ("130 skill directories" literal) to verification scope. Add lean/full profile section to README deploy docs. Sync README Presets table member counts if Phase 1 closure changes shifted them ("9 Code Quality", "10", "26", "12", "11"…) and verify `deploy/presets/pack-*.json` `skills` arrays against regenerated registry (generator `/tmp/gen-presets.mjs` is uncommitted — sync manually or commit it)
    — **Why:** 4.2's original "130→131 fix" would itself fail `tests/test_markitdown_skill.bats:73-99` (`skill_count_consistent_across_docs` asserts README == find == count_skills); preset counts are consumer-visible
    — **Done when:** `test_markitdown_skill.bats` + `test_count_drift.bats` green; presets table matches registry
    — **Consumers affected:** README readers, doc-consistency tests

- [ ] **4.3** Update `deploy/.AGENTS.md` §Skill Permission Allowlist — guidance only (review: section contains NO counts): document the lean/full profiles, `--skill-profile` flag, and per-agent frontmatter allows as the relocation mechanism
    — **Why:** deployed to every session as `~/.config/opencode/AGENTS.md`; must teach the profile pattern, not stale counts
    — **Done when:** section reflects the mechanism
    — **Consumers affected:** every deployed session

- [ ] **4.4** Verify `deploy/setup.sh`/`setup.ps1` dynamic counts unaffected (counts computed via `count_agents`/`count_skills` — confirmed); confirm no hardcoded "80"/"87" in allowlist context; update setup help text for the new flag
    — **Why:** Sync Rules; confirm-only because counts are computed
    — **Done when:** `rg -n '\b(80|87)\b' deploy/setup.sh deploy/setup.ps1` returns nothing allowlist-related; help text shows `--skill-profile`
    — **Consumers affected:** setup banner/help

### Phase 5: Verification, commits, PR

- [ ] **5.1** Pre-flight: restore locally-deleted tracked files (`git checkout -- package.json package-lock.json` — CI-equivalent local steps incl. release.yml tarball guard need them); `git add PLANS/PLAN-GIT-333.md` (untracked — repo convention commits PLANS/)
    — **Why:** npm/registry/regen steps fail on the missing files; an untracked PLAN never reaches the PR
    — **Done when:** `git status` clean apart from intended worktree changes
    — **Consumers affected:** none

- [ ] **5.2** Smoke test: deploy to a scratch target with `--skill-profile lean --dry-run` (or scratch HOME), start a fresh opencode session there, confirm `<available_skills>` lists exactly 29; record before/after initial-token delta (expected ≈ 5.5k skills + 1-2k descriptions ≈ 6.5-7.5k)
    — **Why:** measured reduction is the whole point; claims need a number
    — **Done when:** listing == 29; delta recorded for the PR description
    — **Consumers affected:** none

- [ ] **5.3** Atomic semantic commits, each self-green for the registry drift gate (bundle `registry.json` regen with its frontmatter commit): Phase 1 `feat(agents): scope subagent-only skills via frontmatter allows` + registry + init.bats; Phase 2 `feat(deploy): add --skill-profile lean|full option` (profiles json + setup.sh/ps1 + bats); Phase 3 `refactor(agents): slim subagent descriptions` + registry; Phase 4 `docs: sync skill-profile docs and LEARNINGS`; PLAN file `docs(plan): add PLAN-GIT-333`. Push GIT-333, open PR **to `dev`** referencing #333
    — **Why:** semantic-release drives CHANGELOG/version from commit types (CHANGELOG is auto-generated — no manual entry, confirmed); intermediate commits must not trip the registry drift gate; repo workflow is dev→uat→main
    — **Done when:** PR open on dev, CI green, #333 linked
    — **Consumers affected:** reviewers, CI, semantic-release

- [ ] **5.4** Post-merge note on #333: run `./deploy/setup.sh --skill-profile lean` to redeploy (fixes the deployed 131-drift and activates lean for this machine)
    — **Why:** merged PR changes nothing for existing installs (setup.sh deploys opencode.json verbatim; deployed copies must never be hand-edited — repo rule)
    — **Done when:** comment posted on #333
    — **Consumers affected:** this machine's deployment

---

## Appendix: 1.1 Classification Table

_To be filled during execution of step 1.1 — all 59 lean-hidden skills classified (has-consumer / needs-new-allow / intentionally-hidden), exact `-skill`-suffixed names, target agent(s) for needs-new-allow, one-line rationale for hidden._

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
