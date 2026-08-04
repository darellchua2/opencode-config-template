# PLAN-GIT-312: Improve Skills & Subagents from Cross-Repo LEARNINGS + Research Validation

**Issue:** https://github.com/darellchua2/opencode-config-template/issues/312
**Branch:** `feat/skills-subagents-improvement`
**Status:** Planning

## Goal

Extract cross-repo patterns from `LEARNINGS/` directories across 15 `~/VSCODE/*` repos into new skills, split an oversized skill, enrich existing skills, and harden reviewer subagents with LEARNINGS recall and typed Return Contract fields. Validated against Anthropic Agent Skills 500-line heuristic, CodeRabbit reinforcement rule, Google A2A typed Parts, and OpenAI Agents SDK `input_type` precedent.

## Locked Decisions

| # | Decision | Choice |
|---|----------|--------|
| 1 | A1 global skill allowlist | **Primary-visible** (`permission.skill: "allow"` in opencode.json) — backend patterns are broadly useful |
| 2 | A4 merged A5 | **Single skill** `aws-iac-safety-skill` covers both AWS IaC and GitHub Actions patterns |
| 3 | B1 split rationale | **Hooks vs render** — co-use criterion: patterns trigger in mutually exclusive review contexts; Anthropic 500-line heuristic |
| 4 | C1 recall rule wording | *"Before responding, recall LEARNINGS via the `memory` tool (scope: project, query: the review topic) AND read any `LEARNINGS/*.md` surfaced by the autoinject manifest. Do not skip patterns that apply."* |
| 5 | C4 field format | `Patterns applied/violated: [{id, status, evidence}]` — `id` = LEARNINGS slug, `evidence` = file:line or section ref |
| 6 | D1 scope | **Agent count only** — mirror `count_skills()`; MCP SERVERS (14) stays hardcoded (pack-conditional, would double-count) |
| 7 | Branch source | **`main`** — `dev` is even with `main` (zero commits ahead) |
| 8 | Provenance convention | HTML-comment block at top of each new SKILL.md (invisible to model, greppable for maintainers) |

## Dependency & Consumer Map

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---|---|---|---|
| `opencode_app/.opencode/skills/fastapi-pydantic-orm-patterns-skill/SKILL.md` (new, Phase 5) | Phase 3 pattern brief | `python-reviewer-subagent` (C2), primary `permission.skill`, `deploy/setup.sh` listing | med (new skill — frontmatter required) |
| `opencode_app/.opencode/skills/aws-iac-safety-skill/SKILL.md` (new, Phase 5) | Phase 3 pattern brief | primary `permission.skill`, `opentofu-aws-explorer-skill` cross-ref (B3), `deploy/setup.sh` listing | med (new skill — frontmatter required) |
| `opencode_app/.opencode/skills/react-hooks-antipatterns-skill/SKILL.md` (new, Phase 4) | Phase 3 overlap scan | `typescript-reviewer-subagent` (C3), primary `permission.skill`, replaces half of old skill | med (split — must cover full hooks pattern set) |
| `opencode_app/.opencode/skills/react-render-antipatterns-skill/SKILL.md` (new, Phase 4) | Phase 3 overlap scan | `typescript-reviewer-subagent` (C3), primary `permission.skill`, replaces half of old skill | med (split — must cover full render pattern set) |
| `react-nextjs-antipatterns-skill/SKILL.md` (removed, Phase 4) | — | — | med (deletion — verify all patterns migrated to split skills) |
| `threejs-nextjs-skill/SKILL.md` (enriched, Phase 4) | Phase 3 scan | primary `permission.skill` (already allowed) | low (additive) |
| `opentofu-aws-explorer-skill/SKILL.md` (enriched, Phase 4) | Phase 3 scan, A4 exists | primary `permission.skill` (already allowed) | low (additive + cross-ref) |
| `python-layered-naming-skill/SKILL.md` (enriched, Phase 4) | Phase 3 scan, A1 exists | primary `permission.skill` (already allowed) | low (additive cross-ref) |
| `authentication-authorization-skill/SKILL.md` (enriched, Phase 4) | Phase 3 scan | primary `permission.skill` (already allowed) | low (additive — Keycloak patterns) |
| 7 reviewer subagent .md files (C1, Phase 7) | — | all review workflows | med (7-file frontmatter body edit — identical prose, different files) |
| `python-reviewer-subagent.md` (C2, Phase 8) | A1 skill exists (Phase 5) | python review workflows | low (allowlist + 1-line prose) |
| `typescript-reviewer-subagent.md` (C3, Phase 8) | B1 split skills exist (Phase 4) | typescript review workflows | low (allowlist + prose) |
| `AGENTS.md` Return Contract (C4, Phase 8) | — | all subagents that follow the convention | med (convention change — all 7 reviewers must match) |
| 7 reviewer .md files C4 field (Phase 8) | AGENTS.md C4 update (same phase) | all review outputs | med (typed field addition to each) |
| `deploy/setup.sh` count_agents() (D1, Phase 2) | — | setup banner, `--dry-run`, print_summary | med (function + 3 interpolation sites) |
| `deploy/setup.ps1` Get-AgentCount (D1, Phase 2) | — | Windows setup banner, runtime echo | med (function + 2 interpolation sites) |
| `tests/test_count_drift.bats` (D2, Phase 2) | D1 count_agents() exists | CI bats suite | low (new test) |
| **`deploy/setup.sh` + `setup.ps1` + `README.md` + `opencode_app/README.md`** (Phase 9) | All skills created/enriched (Phases 4-6) | end users, CI, `opencode-init` | **high if missed** — doc-sync is the final consistency gate |
| **`opencode_app/opencode.json`** `permission.skill` (Phase 9) | All new global skills exist | primary session visibility | **high if missed** — skills invisible without allowlist entry |
| **`deploy/registry.json`** (Phase 9) | All new global skills exist | `opencode-init --list/--describe/--expand`, README category table | **high if missed** — generated file, must rebuild via `build-registry.mjs` |

---

## Phase 1 — Baseline Counts

_Owner: `general` delegate_

- [ ] **1.1** Capture baseline skill count: `find opencode_app/.opencode/skills -name SKILL.md | wc -l`
    — **Why:** Establishes the "before" number for D1 verification and Phase 9 doc-sync; any drift between this number and the setup.sh banner is a bug.
    — **Done when:** Baseline count recorded in PLAN Phase 1 completion comment (or worklog).
    — **Consumers affected:** Phase 2 (D1 verification), Phase 9 (doc-sync target), Phase 10 (dry-run comparison).

- [ ] **1.2** Capture baseline agent count: `ls opencode_app/.opencode/agents/*.md | wc -l`
    — **Why:** Establishes the "before" number for D1 — the current hardcoded `36`/`38` mismatch in setup.sh vs setup.ps1 is the bug D1 fixes.
    — **Done when:** Baseline count recorded alongside Phase 1 completion.
    — **Consumers affected:** Phase 2 (D1 — dynamic function target), Phase 10 (verification).

- [ ] **1.3** Capture current banner values: grep the hardcoded agent/skill counts in setup.sh (lines ~621, ~2403, ~3372) and setup.ps1 (lines ~909, ~1697).
    — **Why:** Documents the exact drift that D1 must correct; without this, Phase 2 can't verify the fix is correct.
    — **Done when:** All 5 hardcoded locations logged with their current literal values.
    — **Consumers affected:** Phase 2 (D1 — what to replace), Phase 10 (verification).

---

## Phase 2 — Tooling Fixes: D1 Agent Count + D2 Drift Test

_Owner: `opencode-tooling-subagent`_

- [ ] **2.1** Add `count_agents()` function to `deploy/setup.sh` mirroring existing `count_skills()` (lines 410–413)
    — **Why:** `count_skills()` is already dynamic; agent count is still hardcoded at 3 locations causing drift (36 vs 38 mismatch with setup.ps1). A matching function eliminates manual updates forever.
    — **Done when:** Function exists, counts `*.md` files in `agents/` directory (excluding non-agent files), and returns the count. Matches `count_skills()` style (recursive find or ls + wc).
    — **Consumers affected:** setup.sh banner (step 2.2), runtime echo (step 2.3), print_summary (step 2.4).

- [ ] **2.2** Interpolate `count_agents()` into setup.sh banner heredoc (line ~621, currently `AGENTS (38):`)
    — **Why:** Replaces hardcoded `38` with `$(count_agents ...)` so the banner always matches reality.
    — **Done when:** Banner line reads `AGENTS ($(count_agents ...)):` instead of a literal number.
    — **Consumers affected:** Setup banner output, Phase 10 `--dry-run` check.

- [ ] **2.3** Interpolate `count_agents()` into setup.sh runtime echo (line ~2403, currently `✓ Configured 36 agents:`)
    — **Why:** Same drift — hardcoded `36` doesn't match the actual count; dynamic interpolation fixes it.
    — **Done when:** Echo reads `✓ Configured $(count_agents ...) agents:` instead of literal.
    — **Consumers affected:** Runtime setup output, Phase 10 verification.

- [ ] **2.4** Interpolate `count_agents()` into setup.sh print_summary echo (line ~3372, currently `✓ Configured 36 agents:`)
    — **Why:** Third hardcoded location — all three must be dynamic to prevent future drift.
    — **Done when:** Summary echo uses `$(count_agents ...)` instead of literal.
    — **Consumers affected:** Summary output, Phase 10 verification.

- [ ] **2.5** Add `Get-AgentCount` PowerShell function to `deploy/setup.ps1` mirroring `Get-SkillCount`
    — **Why:** Windows parity — setup.ps1 currently hardcodes `36` at 2 locations AND mismatches setup.sh's `38`. A matching function eliminates manual updates.
    — **Done when:** Function exists, counts `*.md` files in agents directory, returns integer. Matches `Get-SkillCount` style.
    — **Consumers affected:** setup.ps1 banner (step 2.6), runtime echo (step 2.7).

- [ ] **2.6** Interpolate `Get-AgentCount` into setup.ps1 banner (line ~909, currently `AGENTS (36):`)
    — **Why:** Replaces hardcoded `36` (which already mismatches setup.sh's `38`) with dynamic count.
    — **Done when:** Banner uses `$(Get-AgentCount)` instead of literal.
    — **Consumers affected:** Windows setup banner, Phase 10 cross-platform verification.

- [ ] **2.7** Interpolate `Get-AgentCount` into setup.ps1 runtime echo (line ~1697, currently `Write-Host "Configured 36 agents:"`)
    — **Why:** Second hardcoded location in setup.ps1 — must be dynamic for consistency.
    — **Done when:** Echo uses `Get-AgentCount` instead of literal.
    — **Consumers affected:** Windows runtime output, Phase 10 verification.

- [ ] **2.8** Create `tests/test_count_drift.bats` asserting banner skill/agent counts match directory counts
    — **Why:** Without a gate test, future drift will go undetected until a user notices the mismatch. This test catches count drift at CI time.
    — **Done when:** Bats test exists that: (1) counts `SKILL.md` files in skills dir, (2) counts `*.md` files in agents dir, (3) runs setup.sh banner generation or greps the interpolated values, (4) asserts counts match. Follows existing bats test conventions in `tests/`.
    — **Consumers affected:** CI bats suite, Phase 10 verification.

---

## Phase 3 — Pattern Briefs for A1, A4, B1 (Parallel Explore)

_Owner: 3 parallel `explore` agents_

- [ ] **3.1** Generate pattern brief for A1 `fastapi-pydantic-orm-patterns-skill` from `canvastekk-workflow-engine/LEARNINGS/` + `canvastekk-defect-service/LEARNINGS/`
    — **Why:** Extracts the concrete pattern content that Phase 5 will write into the SKILL.md — without a brief, Phase 5 would write a generic skill.
    — **Done when:** Brief lists all 10+ patterns with: pattern name, source file path, one-line description, and applicable code context. Scanned for overlap with existing skills in `opencode_app/.opencode/skills/`.
    — **Consumers affected:** Phase 5 (A1 skill authoring).

- [ ] **3.2** Generate pattern brief for A4 `aws-iac-safety-skill` from `canvastekk-devops/LEARNINGS/` + `betekk-keycloak/LEARNINGS/` + `canvastekk-floor-flatness-app/LEARNINGS/`
    — **Why:** Merged A5 into A4 — the brief must cover both AWS IaC and GitHub Actions patterns from 3 repos.
    — **Done when:** Brief lists all 11 patterns with provenance, scanned for overlap vs existing `opentofu-aws-explorer-skill` and any security/infrastructure skills.
    — **Consumers affected:** Phase 5 (A4 skill authoring), Phase 4 (B3 cross-reference).

- [ ] **3.3** Generate pattern brief for B1 split from `canvastekk-frontend-nextjs/LEARNINGS/` — partition into hooks patterns vs render patterns
    — **Why:** The split must be lossless — every pattern in the original `react-nextjs-antipatterns-skill` must land in exactly one of the two new skills. The brief validates the partition is correct before Phase 4 edits.
    — **Done when:** Two lists: (1) hooks patterns (~20) destined for `react-hooks-antipatterns-skill`, (2) render patterns (~17) destined for `react-render-antipatterns-skill`. Cross-checked that union = original set (no gaps, no duplicates). Scanned for overlap with existing `threejs-nextjs-skill`.
    — **Consumers affected:** Phase 4 (B1 split execution).

---

## Phase 4 — B1 Split + B2/B3/B4 Enrichments + Auth Skill Enrichment

_Owner: `opencode-tooling-subagent`_

- [ ] **4.1** Create `opencode_app/.opencode/skills/react-hooks-antipatterns-skill/SKILL.md` with ~20 hooks patterns from Phase 3.3 brief
    — **Why:** Replaces the hooks half of `react-nextjs-antipatterns-skill` with a focused skill (useMemo/useRef/StrictMode/derived-state/JSON.parse handlers). Anthropic 500-line heuristic justifies the split; co-use criterion ensures hooks patterns never co-trigger with render patterns in the same review.
    — **Done when:** SKILL.md exists with frontmatter (`name`, `description`, `category`, `license`, `compatibility`, `metadata`), HTML-comment provenance block, all hooks patterns from Phase 3.3 list, and category set (likely `Frontend` or `Code Quality`).
    — **Consumers affected:** `typescript-reviewer-subagent` (C3), primary allowlist (Phase 9).

- [ ] **4.2** Create `opencode_app/.opencode/skills/react-render-antipatterns-skill/SKILL.md` with ~17 render patterns from Phase 3.3 brief
    — **Why:** Replaces the render half (fragment-key/status-mapping/z-index/etc.) with a focused skill.
    — **Done when:** SKILL.md exists with frontmatter, provenance block, all render patterns from Phase 3.3 list, and category set.
    — **Consumers affected:** `typescript-reviewer-subagent` (C3), primary allowlist (Phase 9).

- [ ] **4.3** Delete `opencode_app/.opencode/skills/react-nextjs-antipatterns-skill/SKILL.md`
    — **Why:** Replaced by the two new split skills. Must be removed to avoid pattern duplication and confusion.
    — **Done when:** File deleted; Phase 9 doc-sync removes it from setup.sh/setup.ps1/README listings. Any references in other skills/subagents updated to point to the appropriate new skill.
    — **Consumers affected:** All consumers of the old skill (setup scripts, README, registry, any cross-references).

- [ ] **4.4** Enrich `threejs-nextjs-skill/SKILL.md` with memory-leak patterns (B2)
    — **Why:** Three patterns from `canvastekk-frontend-nextjs/LEARNINGS/` — material clone leak, line-not-disposed-in-overlay-cleanup, perspectivecamera-cast-after-swap — are missing from the skill and caused real production bugs.
    — **Done when:** Three new patterns added with provenance HTML comments. Category/frontmatter unchanged.
    — **Consumers affected:** Three.js review workflows, frontend review workflows.

- [ ] **4.5** Enrich `opentofu-aws-explorer-skill/SKILL.md` with neon `connection_uri_pooler` attribute + A4 cross-reference (B3)
    — **Why:** `connection_uri_pooler` is a recently-discovered attribute needed for Neon/Supabase OpenTofu configs. Cross-reference to A4 ensures users know the broader IaC safety skill exists.
    — **Done when:** Attribute documented; cross-reference line added pointing to `aws-iac-safety-skill` (which won't exist until Phase 5 — reference by skill name, not file path).
    — **Consumers affected:** OpenTofu exploration workflows, IaC reviews.

- [ ] **4.6** Enrich `python-layered-naming-skill/SKILL.md` with cross-reference to A1 (B4)
    — **Why:** Python layered naming and FastAPI/Pydantic patterns are complementary — developers using one benefit from knowing the other exists.
    — **Done when:** Cross-reference line added pointing to `fastapi-pydantic-orm-patterns-skill` (Phase 5 — reference by name).
    — **Consumers affected:** Python development workflows.

- [ ] **4.7** Enrich `authentication-authorization-skill/SKILL.md` with Keycloak two-layer authorization + one-policy-per-role-type patterns (A3 fold-in)
    — **Why:** Two patterns from `betekk-keycloak/LEARNINGS/` — two-layer authorization (resource + realm) and one-policy-per-role-type — are missing and caused configuration confusion in a production Keycloak deployment.
    — **Done when:** Two new patterns added with provenance HTML comments from `betekk-keycloak/LEARNINGS/`.
    — **Consumers affected:** Auth review workflows, Keycloak configuration tasks.

---

## Phase 5 — A1 + A4 New Global Skills

_Owner: `opencode-tooling-subagent`_

- [ ] **5.1** Create `opencode_app/.opencode/skills/fastapi-pydantic-orm-patterns-skill/SKILL.md` with all patterns from Phase 3.1 brief
    — **Why:** 10+ cross-repo patterns (Pydantic-on-JSONB, detached ORM, Alembic JSONB+asyncpg, enum strategy, instance check, defensive enum mapping, Pydantic v2 idioms, inline imports, broad except) need a permanent home in the skill ecosystem. Currently scattered across 2 repos' LEARNINGS only.
    — **Done when:** SKILL.md exists with: (a) frontmatter with `name`, `description`, `category: backend` (or `Python`), `license`, `compatibility`, `metadata: { audience: developers, workflow: backend-api-development }`; (b) HTML-comment provenance block listing source LEARNINGS files per pattern; (c) all patterns from Phase 3.1 brief with code examples and context; (d) skill is under 500 lines (Anthropic heuristic).
    — **Consumers affected:** `python-reviewer-subagent` (C2), primary allowlist (Phase 9), `python-layered-naming-skill` cross-ref (B4), Phase 10 verification.

- [ ] **5.2** Create `opencode_app/.opencode/skills/aws-iac-safety-skill/SKILL.md` with all patterns from Phase 3.2 brief (merged A5)
    — **Why:** 11 cross-repo patterns (ECR lowercase, cross-module ECR lifecycle, GHA resources gating, Lambda Function URL CNAME, public Lambda posture reversal, Lambda Web Adapter vs Mangum, local state for prod, GHA artifact mismatch, SSM parameter doc convention, hardcoded dev SSM paths) need a home. Merges A5 GitHub Actions patterns into a single IaC safety skill.
    — **Done when:** SKILL.md exists with frontmatter, provenance block, all 11 patterns with examples, category set (likely `DevOps` or `Infrastructure`).
    — **Consumers affected:** primary allowlist (Phase 9), `opentofu-aws-explorer-skill` cross-ref (B3), Phase 10 verification.

---

## Phase 6 — A8 Project-Scoped Skill

_Owner: `opencode-tooling-subagent`_

- [ ] **6.1** Create `canvastekk-workflow-nodes/.opencode/skills/workflow-node-sdk-skill/SKILL.md` with version duo/triad, CDS normalization, async-blocking-poll, ZAI client + node mixin patterns
    — **Why:** 4 patterns specific to the workflow-nodes SDK are captured in LEARNINGS but have no skill. Project-scoped (not global) because only this repo uses the SDK.
    — **Done when:** SKILL.md exists at the project-scoped path with frontmatter, provenance, all 4 patterns. No global sync needed (Phase 9 skips this).
    — **Consumers affected:** `canvastekk-workflow-nodes` development workflows only.

---

## Phase 7 — C1: Imperative LEARNINGS Recall Rule in 7 Reviewers

_Owner: `opencode-tooling-subagent`_

- [ ] **7.1** Add C1 recall rule prose to `architecture-review-subagent.md` frontmatter body
    — **Why:** Architecture reviews currently miss patterns captured in LEARNINGS because reviewers don't explicitly recall them. CodeRabbit's reinforcement rule pattern validates: explicitly instructing recall improves pattern application.
    — **Done when:** Frontmatter body contains: *"Before responding, recall LEARNINGS via the `memory` tool (scope: project, query: the review topic) AND read any `LEARNINGS/*.md` surfaced by the autoinject manifest. Do not skip patterns that apply."*
    — **Consumers affected:** architecture review workflows.

- [ ] **7.2** Add C1 recall rule prose to `code-review-subagent.md` frontmatter body
    — **Why:** Same rationale as 7.1 — code reviews benefit equally from LEARNINGS recall.
    — **Done when:** Identical recall rule prose present in frontmatter body.
    — **Consumers affected:** code review workflows.

- [ ] **7.3** Add C1 recall rule prose to `python-reviewer-subagent.md` frontmatter body
    — **Why:** Python-specific LEARNINGS (Pydantic, ORM, Alembic) are directly relevant to Python reviews.
    — **Done when:** Identical recall rule prose present in frontmatter body.
    — **Consumers affected:** Python review workflows.

- [ ] **7.4** Add C1 recall rule prose to `typescript-reviewer-subagent.md` frontmatter body
    — **Why:** TypeScript-specific LEARNINGS (hooks, render, Next.js) directly relevant.
    — **Done when:** Identical recall rule prose present in frontmatter body.
    — **Consumers affected:** TypeScript review workflows.

- [ ] **7.5** Add C1 recall rule prose to `java-reviewer-subagent.md` frontmatter body
    — **Why:** Java-specific LEARNINGS may exist in repos; recall ensures they're checked.
    — **Done when:** Identical recall rule prose present in frontmatter body.
    — **Consumers affected:** Java review workflows.

- [ ] **7.6** Add C1 recall rule prose to `go-reviewer-subagent.md` frontmatter body
    — **Why:** Go-specific LEARNINGS may exist; recall ensures pattern coverage.
    — **Done when:** Identical recall rule prose present in frontmatter body.
    — **Consumers affected:** Go review workflows.

- [ ] **7.7** Add C1 recall rule prose to `rust-reviewer-subagent.md` frontmatter body
    — **Why:** Rust-specific LEARNINGS may exist; recall ensures pattern coverage.
    — **Done when:** Identical recall rule prose present in frontmatter body.
    — **Consumers affected:** Rust review workflows.

---

## Phase 8 — C2/C3 Allowlists + C4 Strict Return Contract Field

_Owner: `opencode-tooling-subagent`_

- [ ] **8.1** Add `fastapi-pydantic-orm-patterns-skill: allow` to `python-reviewer-subagent.md` `permission.skill` block + 1-line awareness prose (C2)
    — **Why:** Python reviewer needs to load A1 skill during reviews; without allowlist entry, the skill is invisible to the subagent.
    — **Done when:** `permission.skill` block contains the allow entry; awareness prose mentions the skill covers Pydantic-on-JSONB, detached ORM, and enum strategy patterns.
    — **Consumers affected:** Python review workflows.

- [ ] **8.2** Add `react-hooks-antipatterns-skill: allow` + `react-render-antipatterns-skill: allow` to `typescript-reviewer-subagent.md` `permission.skill` block + awareness prose (C3)
    — **Why:** TypeScript reviewer needs both B1 split skills; the old `react-nextjs-antipatterns-skill` is deleted in Phase 4.
    — **Done when:** Both entries present in allowlist; awareness prose mentions hooks vs render pattern separation.
    — **Consumers affected:** TypeScript/React review workflows.

- [ ] **8.3** Add C4 strict `Patterns applied/violated` field to Return Contract Convention in repo `AGENTS.md`
    — **Why:** Without a strict required field, reviewers may omit LEARNINGS pattern citations from their output. Google A2A typed `Part` and OpenAI Agents SDK `input_type` precedent validate that typed fields improve output compliance.
    — **Done when:** Return Contract Convention section includes:
      > **Patterns applied/violated:** `[{id: <LEARNINGS-slug>, status: applied|violated, evidence: <file:line or review-section ref>}]`
      > - **Required** for all reviewer subagents on every review.
      > - If no LEARNINGS pattern applied or was violated, emit `Patterns applied/violated: []` (empty list, never omit).
    — **Consumers affected:** All 7 reviewer subagents, review output consumers.

- [ ] **8.4** Add C4 `Patterns applied/violated` field to `architecture-review-subagent.md` Return Contract
    — **Why:** Each reviewer must have the field in its own Return Contract section for the convention to be enforceable per-subagent.
    — **Done when:** Field specification present, matching the AGENTS.md convention wording.
    — **Consumers affected:** Architecture review outputs.

- [ ] **8.5** Add C4 `Patterns applied/violated` field to `code-review-subagent.md` Return Contract
    — **Why:** Same rationale as 8.4.
    — **Done when:** Field specification present.
    — **Consumers affected:** Code review outputs.

- [ ] **8.6** Add C4 `Patterns applied/violated` field to `python-reviewer-subagent.md` Return Contract
    — **Why:** Same rationale as 8.4.
    — **Done when:** Field specification present.
    — **Consumers affected:** Python review outputs.

- [ ] **8.7** Add C4 `Patterns applied/violated` field to `typescript-reviewer-subagent.md` Return Contract
    — **Why:** Same rationale as 8.4.
    — **Done when:** Field specification present.
    — **Consumers affected:** TypeScript review outputs.

- [ ] **8.8** Add C4 `Patterns applied/violated` field to `java-reviewer-subagent.md` Return Contract
    — **Why:** Same rationale as 8.4.
    — **Done when:** Field specification present.
    — **Consumers affected:** Java review outputs.

- [ ] **8.9** Add C4 `Patterns applied/violated` field to `go-reviewer-subagent.md` Return Contract
    — **Why:** Same rationale as 8.4.
    — **Done when:** Field specification present.
    — **Consumers affected:** Go review outputs.

- [ ] **8.10** Add C4 `Patterns applied/violated` field to `rust-reviewer-subagent.md` Return Contract
    — **Why:** Same rationale as 8.4.
    — **Done when:** Field specification present.
    — **Consumers affected:** Rust review outputs.

---

## Phase 9 — Doc-Sync (setup.sh, setup.ps1, README.md, opencode_app/README.md, opencode.json, registry.json)

_Owner: `opencode-tooling-subagent` using `documentation-sync-workflow-skill`_

- [ ] **9.1** Update `deploy/setup.sh` — add A1, A4, B1 split skills to per-category listing; remove deleted `react-nextjs-antipatterns-skill`; verify `count_skills()` + new `count_agents()` are used in banner/echoes
    — **Why:** Setup.sh is the primary install script — skill/agent listings must match directory reality. Adding 3 new skills (A1, A4, and the 2 B1 split skills minus the 1 deleted = net +3) changes the counts.
    — **Done when:** Category listings updated; old skill removed; banner uses dynamic counts; `bash -n setup.sh` passes.
    — **Consumers affected:** All users running `deploy/setup.sh`.

- [ ] **9.2** Update `deploy/setup.ps1` — Windows parity for step 9.1 changes
    — **Why:** setup.ps1 must mirror setup.sh changes (same skill adds/removes, same dynamic counts).
    — **Done when:** Listings updated; old skill removed; `Get-AgentCount` used; `pwsh -n setup.ps1` passes.
    — **Consumers affected:** Windows users running setup.ps1.

- [ ] **9.3** Update `README.md` — Skill Categories table + intro total
    — **Why:** README is the public-facing documentation; counts and table must match the installed skills.
    — **Done when:** Skill Categories table includes A1 (backend/python), A4 (devops/iac), B1 split skills (hooks + render); removed old skill; total count correct.
    — **Consumers affected:** All repo visitors and `opencode-init` users.

- [ ] **9.4** Update `opencode_app/README.md` — Docker-specific docs if relevant
    — **Why:** Docker docs may reference skill counts or categories; must stay in sync.
    — **Done when:** Any skill/agent count references updated; or confirmed no changes needed.
    — **Consumers affected:** Docker users.

- [ ] **9.5** Update `opencode_app/opencode.json` — add A1 + A4 + B1 split skills to `permission.skill` allowlist
    — **Why:** Without allowlist entries, new skills are invisible to the primary session. This is the gate that makes skills "available."
    — **Done when:** `"fastapi-pydantic-orm-patterns-skill": "allow"`, `"aws-iac-safety-skill": "allow"`, `"react-hooks-antipatterns-skill": "allow"`, `"react-render-antipatterns-skill": "allow"` present. Old skill entry removed if it existed.
    — **Consumers affected:** Primary session (skill visibility).

- [ ] **9.6** Rebuild `deploy/registry.json` via `node deploy/build-registry.mjs`
    — **Why:** Registry is a generated file — manual edits are overwritten. Must rebuild to include new skills and their `category:` frontmatter.
    — **Done when:** `node deploy/build-registry.mjs` completes without error; new skills appear in registry with correct categories.
    — **Consumers affected:** `opencode-init --list/--describe/--expand`, README category table derivation.

---

## Phase 10 — Verification

_Owner: `general` delegate_

- [ ] **10.1** Run `bash -n deploy/setup.sh` — syntax check
    — **Why:** Catches shell syntax errors (unterminated strings, bad interpolation) introduced by D1 edits.
    — **Done when:** Exits 0 with no errors.
    — **Consumers affected:** CI, all users.

- [ ] **10.2** Run `pwsh -n deploy/setup.ps1` — syntax check
    — **Why:** Catches PowerShell syntax errors introduced by D1 edits.
    — **Done when:** Exits 0 with no errors.
    — **Consumers affected:** Windows CI, Windows users.

- [ ] **10.3** Run `node deploy/build-registry.mjs --check` (or equivalent validation)
    — **Why:** Validates registry.json consistency after rebuild.
    — **Done when:** Exits 0; registry contains all skills including new ones.
    — **Consumers affected:** opencode-init, README.

- [ ] **10.4** Run full bats suite (including new `test_count_drift.bats`)
    — **Why:** End-to-end verification that all tests pass including the new drift gate.
    — **Done when:** All bats tests pass, including test_count_drift.bats.
    — **Consumers affected:** CI.

- [ ] **10.5** Run `deploy/setup.sh --dry-run` (or equivalent) and verify banner counts match directory counts
    — **Why:** Final integration check — the banner the user sees must match reality. This is the "done" signal for D1.
    — **Done when:** Banner shows correct skill count and agent count, both matching `find`/`ls` directory counts.
    — **Consumers affected:** End user experience.

---

## Step Authoring Rules

- **Atomic**: one reversible concern per step; if a step does two things, split it.
- **Rationale mandatory**: every step MUST have a **Why**; a step without rationale is malformed and blocks commit.
- **Completion signal**: every step MUST have an objective **Done when** check, not a subjective "done".
- **Consumers explicit**: list affected consumers so reviewers/execution know blast radius; write "none" if truly isolated.

## Provenance Convention

Each new SKILL.md carries an HTML-comment provenance block at the top (invisible to consuming model, greppable for maintainers):

```markdown
<!-- Provenance (maintainer-only, not rendered to model context):
  - <Pattern name> : <repo>/LEARNINGS/<category>/<file>.md
-->
```

## Risks & Mitigation

| Risk | Mitigation |
|------|-----------|
| B1 split loses patterns | Phase 3.3 brief validates union = original; Phase 10 can grep-check |
| C4 field ignored by reviewers | C1 recall rule creates the habit; C4 is a strict required field in Return Contract |
| D1 count_agents() breaks setup | Phase 10 runs `bash -n` + `pwsh -n` before merge |
| Doc-sync misses a file | Phase 9 uses `documentation-sync-workflow-skill` which automates the touch-list |
| Registry not rebuilt | Phase 9.6 is a dedicated step; Phase 10.3 validates it |
