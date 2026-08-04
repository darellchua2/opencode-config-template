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
| 3 | B1 split rationale | **Hooks vs render vs redistribute** — 3-way partition: hooks patterns, render patterns, and ~9 misfit patterns redistributed to existing skills (`typescript-dry-principle-skill` for DRY, `security-audit-skill` for security, etc.). Anthropic 500-line heuristic; co-use criterion |
| 4 | C1 recall rule wording | *"Before responding, recall LEARNINGS via the `memory` tool (scope: project, query: the review topic) AND read any `LEARNINGS/*.md` surfaced by the autoinject manifest. Do not skip patterns that apply."* |
| 5 | C4 field format | `Patterns applied/violated: [{id, status, evidence}]` — `id` = LEARNINGS slug, `evidence` = file:line or section ref. Scoped to **reviewer subagents only** (8 reviewers: architecture, code, python, typescript, java, go, rust, uiux) |
| 6 | D1 scope | **Agent count only** — mirror `count_skills()`; MCP SERVERS (14) stays hardcoded (pack-conditional, would double-count). Includes derived "and N more agents" lines |
| 7 | Branch source | **`main`** — `dev` is even with `main` (zero commits ahead) |
| 8 | Provenance convention | HTML-comment block at top of each new SKILL.md (invisible to model, greppable for maintainers) |
| 9 | B4 DROPPED | **`python-layered-naming-skill` does not exist** — Phase 4.6 removed. No cross-reference from A1 to a phantom skill |
| 10 | B3 target corrected | **`opentofu-neon-explorer-skill`** (not `opentofu-aws-explorer-skill`) — `connection_uri_pooler` is a Neon attribute |
| 11 | C4 convention scope | **Split AGENTS.md Return Contract** into: (a) general quartet [Status/Output/Summary/Issues] for ALL subagents, (b) "Reviewer Additions" sub-section with `Patterns applied/violated` for 8 reviewers only. Avoids making 26 of 34 agents non-conformant |
| 12 | Duplicate patterns excluded | A3: only add `one-policy-per-role-type` (two-layer-keycloak-authorization already at auth skill L286). B2: clone-leak as sub-bullet under existing D2. A4: exclude `Lambda Function URL CNAME` (already in opentofu-aws-explorer L1158) |
| 13 | Category taxonomy | A1 → `Language-Specific`; A4 → `DevOps`; B1 split → `Framework-Specific` (matches existing skill categories, not guessed values) |
| 14 | uiux-reviewer included | **8th reviewer** — added to C1 (Phase 7) and C4 (Phase 8) scope |

## Dependency & Consumer Map

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---|---|---|---|
| `opencode_app/.opencode/skills/fastapi-pydantic-orm-patterns-skill/SKILL.md` (new, Phase 5) | Phase 3 pattern brief | `python-reviewer-subagent` (C2), primary `permission.skill`, `deploy/setup.sh` listing | med (new skill — frontmatter required) |
| `opencode_app/.opencode/skills/aws-iac-safety-skill/SKILL.md` (new, Phase 5) | Phase 3 pattern brief | primary `permission.skill`, `deploy/setup.sh` listing | med (new skill — frontmatter required; excludes Lambda CNAME — already in opentofu-aws-explorer:1158) |
| `opencode_app/.opencode/skills/react-hooks-antipatterns-skill/SKILL.md` (new, Phase 4) | Phase 3 overlap scan | `typescript-reviewer-subagent` (C3), primary `permission.skill`, replaces half of old skill | med (split — must cover full hooks pattern set) |
| `opencode_app/.opencode/skills/react-render-antipatterns-skill/SKILL.md` (new, Phase 4) | Phase 3 overlap scan | `typescript-reviewer-subagent` (C3), primary `permission.skill`, replaces half of old skill | med (split — must cover full render pattern set) |
| `react-nextjs-antipatterns-skill/SKILL.md` (removed, Phase 4) | — | — | med (deletion — verify all patterns migrated to split skills) |
| `threejs-nextjs-skill/SKILL.md` (enriched, Phase 4) | Phase 3 scan | primary `permission.skill` (already allowed) | low (additive) |
| `opentofu-neon-explorer-skill/SKILL.md` (enriched, Phase 4) | Phase 3 scan | primary `permission.skill` (already allowed) | low (additive — Neon pooler attribute) |
| `authentication-authorization-skill/SKILL.md` (enriched, Phase 4) | Phase 3 scan | primary `permission.skill` (already allowed) | low (additive — `one-policy-per-role-type` only; two-layer-keycloak-authorization already at L286) |
| **B1 deletion blast radius** (Phase 4.3 sub-steps) | B1 split skills exist (Phase 4.1/4.2) | 3 agent allowlists + 5 skill cross-refs + 6 bats assertions + 1 preset | **high if missed** — 6 CI tests will hard-fail; 3 dangling allowlists |
| **B1 misfit redistribution** (Phase 4.3 sub-steps) | Phase 3.3 3-way classification | `typescript-dry-principle-skill`, `security-audit-skill`, and other existing skills | med (cross-skill enrichment — each target must be verified non-duplicate) |
| 8 reviewer subagent .md files (C1, Phase 7) | — | all review workflows | med (8-file frontmatter body edit — identical prose, different files) |
| `python-reviewer-subagent.md` (C2, Phase 8) | A1 skill exists (Phase 5) | python review workflows | low (allowlist + 1-line prose) |
| `typescript-reviewer-subagent.md` (C3, Phase 8) | B1 split skills exist (Phase 4) | typescript review workflows | low (allowlist + prose) |
| `AGENTS.md` Return Contract (C4, Phase 8) | — | all subagents that follow the convention (general quartet); 8 reviewers (reviewer additions) | med (convention split — general quartet stays universal, reviewer additions scoped) |
| 8 reviewer .md files C4 field (Phase 8) | AGENTS.md C4 update (same phase) | all review outputs | med (typed field addition to each) |
| `deploy/setup.sh` count_agents() (D1, Phase 2) | — | setup banner, `--dry-run`, print_summary | med (function + 3 interpolation sites) |
| `deploy/setup.ps1` Get-AgentCount (D1, Phase 2) | — | Windows setup banner, runtime echo | med (function + 2 interpolation sites) |
| `tests/test_count_drift.bats` (D2, Phase 2) | D1 count_agents() exists | CI bats suite | low (new test) |
| **`deploy/setup.sh` + `setup.ps1` + `README.md` + `opencode_app/README.md`** (Phase 9) | All skills created/enriched (Phases 4-6) | end users, CI, `opencode-init` | **high if missed** — doc-sync is the final consistency gate |
| **`opencode_app/opencode.json`** `permission.skill` (Phase 9) | All new global skills exist | primary session visibility | **high if missed** — skills invisible without allowlist entry |
| **`deploy/registry.json`** (Phase 9) | All new global skills exist | `opencode-init --list/--describe/--expand`, README category table | **high if missed** — generated file, must rebuild via `build-registry.mjs` |

---

## Phase 1 — Baseline Counts

_Owner: `general` delegate_

- [x] **1.1** Capture baseline skill count: `find opencode_app/.opencode/skills -name SKILL.md | wc -l`
    — **Why:** Establishes the "before" number for D1 verification and Phase 9 doc-sync; any drift between this number and the setup.sh banner is a bug.
    — **Done when:** Baseline count recorded in PLAN Phase 1 completion comment (or worklog).
    — **Consumers affected:** Phase 2 (D1 verification), Phase 9 (doc-sync target), Phase 10 (dry-run comparison).
    — **Done:** Baseline = 132 skills; files: none (read-only); fixes: none

- [x] **1.2** Capture baseline agent count: `ls opencode_app/.opencode/agents/*.md | wc -l`
    — **Why:** Establishes the "before" number for D1 — the current hardcoded `36`/`38` mismatch in setup.sh vs setup.ps1 is the bug D1 fixes.
    — **Done when:** Baseline count recorded alongside Phase 1 completion.
    — **Consumers affected:** Phase 2 (D1 — dynamic function target), Phase 10 (verification).
    — **Done:** Baseline = 36 agents; files: none (read-only); fixes: none

- [x] **1.3** Capture current banner values: grep the hardcoded agent/skill counts in setup.sh (lines ~621, ~2403, ~3372) and setup.ps1 (lines ~909, ~1697).
    — **Why:** Documents the exact drift that D1 must correct; without this, Phase 2 can't verify the fix is correct.
    — **Done when:** All 5 hardcoded locations logged with their current literal values.
    — **Consumers affected:** Phase 2 (D1 — what to replace), Phase 10 (verification).
    — **Done:** Drift confirmed: setup.sh:621=38(wrong!), :2403=36, :3372=36, :2409=32more, :3377=33more(drift!), :3457=32more; setup.ps1:909=36, :1697=36, :2604=32more; files: none; fixes: none

---

## Phase 2 — Tooling Fixes: D1 Agent Count + D2 Drift Test

_Owner: `opencode-tooling-subagent`_

- [x] **2.1** Add `count_agents()` function to `deploy/setup.sh` mirroring existing `count_skills()` (lines 410–413)
    — **Why:** `count_skills()` is already dynamic; agent count is still hardcoded at 3 locations causing drift (36 vs 38 mismatch with setup.ps1). A matching function eliminates manual updates forever.
    — **Done when:** Function exists, counts `*.md` files in `agents/` directory (excluding non-agent files), and returns the count. Matches `count_skills()` style (recursive find or ls + wc).
    — **Consumers affected:** setup.sh banner (step 2.2), runtime echo (step 2.3), print_summary (step 2.4).
    — **Done:** Added count_agents() at L415 with -maxdepth 1 for agents (flat dir, no nesting); files: deploy/setup.sh; fixes: none

- [x] **2.2** Interpolate `count_agents()` into setup.sh banner heredoc (line ~621, currently `AGENTS (38):`)
    — **Why:** Replaces hardcoded `38` with `$(count_agents ...)` so the banner always matches reality.
    — **Done when:** Banner line reads `AGENTS ($(count_agents ...)):` instead of a literal number.
    — **Consumers affected:** Setup banner output, Phase 10 `--dry-run` check.
    — **Done:** Banner L626 now uses $(count_agents ...); files: deploy/setup.sh; fixes: none

- [x] **2.3** Interpolate `count_agents()` into setup.sh runtime echo (line ~2403, currently `✓ Configured 36 agents:`)
    — **Why:** Same drift — hardcoded `36` doesn't match the actual count; dynamic interpolation fixes it.
    — **Done when:** Echo reads `✓ Configured $(count_agents ...) agents:` instead of literal.
    — **Consumers affected:** Runtime setup output, Phase 10 verification.
    — **Done:** Runtime echo L2408 now dynamic; files: deploy/setup.sh; fixes: none

- [x] **2.4** Interpolate `count_agents()` into setup.sh print_summary echo (line ~3372, currently `✓ Configured 36 agents:`)
    — **Why:** Third hardcoded location — all three must be dynamic to prevent future drift.
    — **Done when:** Summary echo uses `$(count_agents ...)` instead of literal.
    — **Consumers affected:** Summary output, Phase 10 verification.
    — **Done:** Summary echo L3377 now dynamic; files: deploy/setup.sh; fixes: none

- [x] **2.5** Add `Get-AgentCount` PowerShell function to `deploy/setup.ps1` mirroring `Get-SkillCount`
    — **Why:** Windows parity — setup.ps1 currently hardcodes `36` at 2 locations AND mismatches setup.sh's `38`. A matching function eliminates manual updates.
    — **Done when:** Function exists, counts `*.md` files in agents directory, returns integer. Matches `Get-SkillCount` style.
    — **Consumers affected:** setup.ps1 banner (step 2.6), runtime echo (step 2.7).
    — **Done:** Added Get-AgentCount at L183; files: deploy/setup.ps1; fixes: none

- [x] **2.6** Interpolate `Get-AgentCount` into setup.ps1 banner (line ~909, currently `AGENTS (36):`)
    — **Why:** Replaces hardcoded `36` (which already mismatches setup.sh's `38`) with dynamic count.
    — **Done when:** Banner uses `$(Get-AgentCount)` instead of literal.
    — **Consumers affected:** Windows setup banner, Phase 10 cross-platform verification.
    — **Done:** Banner L916 now uses Get-AgentCount; files: deploy/setup.ps1; fixes: none

- [x] **2.7** Interpolate `Get-AgentCount` into setup.ps1 runtime echo (line ~1697, currently `Write-Host "Configured 36 agents:"`)
    — **Why:** Second hardcoded location in setup.ps1 — must be dynamic for consistency.
    — **Done when:** Echo uses `Get-AgentCount` instead of literal.
    — **Consumers affected:** Windows runtime output, Phase 10 verification.
    — **Done:** Runtime echo L1704 now dynamic; files: deploy/setup.ps1; fixes: none

- [x] **2.8** Create `tests/test_count_drift.bats` asserting banner skill/agent counts match directory counts
    — **Why:** Without a gate test, future drift will go undetected until a user notices the mismatch. This test catches count drift at CI time. EXTENDS existing `test_markitdown_skill.bats:70-87` skill-count coverage to agents.
    — **Done when:** Bats test exists that: (1) counts `SKILL.md` files in skills dir, (2) counts `*.md` files in agents dir, (3) runs setup.sh banner generation or greps the interpolated values, (4) asserts counts match. Follows existing bats test conventions in `tests/` (see `test_mcp_count_consistency.bats` as analog).
    — **Consumers affected:** CI bats suite, Phase 10 verification.
    — **Done:** 5 tests: agent_count_matches_disk, no_stale_hardcoded (sh+ps1), get_agentcount_exists, skill_count regression; all pass; files: tests/test_count_drift.bats; fixes: none

- [x] **2.9** Interpolate `count_agents()` into 4 derived "and N more agents" lines (setup.sh:2409, 3377, 3457; setup.ps1:2604)
    — **Why:** These lines compute `total - displayed = "and N more"` and are hardcoded (`32`/`33` — note: setup.sh:3377 already drifts, says 33 not 32). Making `count_agents()` dynamic does NOT auto-fix derived counts — they need explicit arithmetic interpolation: `$(($(count_agents ...) - <displayed_count>))`.
    — **Done when:** All 4 lines use derived arithmetic from `count_agents()`/`Get-AgentCount` instead of literal numbers. setup.sh:3377 drift (33 vs 32) corrected.
    — **Consumers affected:** Setup banner detail output, Phase 10 verification.
    — **Done:** All 4 lines now use $(($(count_agents ...) - N)) arithmetic; drift at L3382 (33→31) corrected; files: deploy/setup.sh, deploy/setup.ps1; fixes: none

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

- [ ] **3.3** Generate pattern brief for B1 split from `canvastekk-frontend-nextjs/LEARNINGS/` — **3-way partition**: hooks patterns, render patterns, redistribute-to-existing-skills
    — **Why:** The split must be lossless — every pattern in the original `react-nextjs-antipatterns-skill` (567 lines, ~37 patterns) must land in exactly one bucket. A binary hooks/render split leaves ~9 misfit patterns (revalidatepath-try-catch, fail-open-rbac-middleware, module-scope-map-cache, duplicated-status-mappings, duplicate-type-definitions, toast-promise-await, chunked-cookie-secure-prefix, browserName-routing, route-removal-runtime-nav). These must be redistributed to existing skills or they're LOST.
    — **Done when:** Three lists produced: (1) hooks patterns for `react-hooks-antipatterns-skill`, (2) render patterns for `react-render-antipatterns-skill`, (3) redistribution map: `{pattern → target_existing_skill}` for each misfit (e.g., `duplicated-status-mappings → typescript-dry-principle-skill`, `fail-open-rbac-middleware → security-audit-skill`). Cross-checked that union of all 3 = original set (no gaps, no duplicates). Each redistribution target verified non-duplicate via grep. Scanned for overlap with existing `threejs-nextjs-skill`.
    — **Consumers affected:** Phase 4 (B1 split + redistribution execution).

---

## Phase 4 — B1 Split + B2/B3 Enrichments + Auth Skill Enrichment (B4 DROPPED)

_Owner: `opencode-tooling-subagent`_

- [ ] **4.1** Create `opencode_app/.opencode/skills/react-hooks-antipatterns-skill/SKILL.md` with hooks patterns from Phase 3.3 brief
    — **Why:** Replaces the hooks half of `react-nextjs-antipatterns-skill` with a focused skill (useMemo/useRef/StrictMode/derived-state/JSON.parse handlers). Anthropic 500-line heuristic justifies the split; co-use criterion ensures hooks patterns never co-trigger with render patterns in the same review.
    — **Done when:** SKILL.md exists with frontmatter (`name`, `description`, `category: Framework-Specific`, `license`, `compatibility`, `metadata`), HTML-comment provenance block, all hooks patterns from Phase 3.3 list (bucket 1 only).
    — **Consumers affected:** `typescript-reviewer-subagent` (C3), primary allowlist (Phase 9).

- [ ] **4.2** Create `opencode_app/.opencode/skills/react-render-antipatterns-skill/SKILL.md` with render patterns from Phase 3.3 brief
    — **Why:** Replaces the render half (fragment-key/status-mapping/z-index/etc.) with a focused skill.
    — **Done when:** SKILL.md exists with frontmatter (`category: Framework-Specific`), provenance block, all render patterns from Phase 3.3 list (bucket 2 only).
    — **Consumers affected:** `typescript-reviewer-subagent` (C3), primary allowlist (Phase 9).

- [ ] **4.3** Delete `opencode_app/.opencode/skills/react-nextjs-antipatterns-skill/SKILL.md` AND clean up ALL 15+ consumers (blast radius from architecture review)
    — **Why:** The deletion blast radius extends far beyond setup.sh/README — 3 agent allowlists, 6 skill cross-refs, 6 bats assertions (CI-breaking), and 1 preset reference the deleted skill. Every one must be addressed or CI breaks.
    — **Done when:** ALL of the following completed:
      - **(a)** File `react-nextjs-antipatterns-skill/SKILL.md` deleted
      - **(b)** `nextjs-specialist-subagent.md:24` — remove `react-nextjs-antipatterns-skill` from `permission.skill` allowlist
      - **(c)** `code-review-subagent.md:32` — remove from `permission.skill` allowlist
      - **(d)** `error-resolver-subagent.md:14` — remove from `permission.skill` allowlist
      - **(e)** `nextjs-specialist-subagent.md:47,69,75` — update 3 prose cross-refs to name replacement skill(s)
      - **(f)** `code-review-subagent.md:57,168` — update 2 prose cross-refs
      - **(g)** `typescript-reviewer-subagent.md:101` — update prose (`"Use react-nextjs-antipatterns to detect runtime issues"`) to name both split skills
      - **(h)** `uiux-review-skill/SKILL.md:380` — update skill→skill cross-ref
      - **(i)** `amplify-nextjs-deployment-skill/SKILL.md:315` — update skill→skill cross-ref
      - **(j)** `threejs-nextjs-skill/SKILL.md:255,780` — update 2 skill→skill cross-refs
      - **(k)** `frontend-design-skill/SKILL.md:407` — update skill→skill cross-ref
      - **(l)** `clean-code-skill/SKILL.md:707` — update inline code-comment reference
      - **(m)** `tests/test_autoresearch_protocol.bats:274,279,284` — update 3 `@test` assertions
      - **(n)** `tests/test_default_behavior.bats:423,428,434` — update 3 `@test` assertions
      - **(o)** `deploy/presets/pack-frontend.json:20` — update preset membership
      - **(p)** Redistribute ~9 misfit patterns per Phase 3.3 bucket 3 map to existing skills (e.g., `typescript-dry-principle-skill`, `security-audit-skill`), each verified non-duplicate
      - **(q)** Clean up pre-existing copy-paste artifact at original skill L441-447 (orphaned "After (single source):" block) — do not carry forward
    — **Consumers affected:** ALL consumers listed above; CI test suite.

- [ ] **4.4** Enrich `threejs-nextjs-skill/SKILL.md` with 2 NEW memory-leak patterns + 1 sub-bullet refinement (B2)
    — **Why:** Three patterns from `canvastekk-frontend-nextjs/LEARNINGS/` caused real production bugs. BUT one (`material clone leak`) is a REFINEMENT of existing pattern D2 at L537 (`missing-dispose-memory-leak`), not a standalone new pattern. Adding it as a duplicate would be redundant.
    — **Done when:** (1) `line-not-disposed-in-overlay-cleanup` added as new top-level pattern with provenance; (2) `perspectivecamera-cast-after-swap` added as new top-level pattern; (3) `material clone leak` added as sub-bullet under existing D2 `missing-dispose-memory-leak` (L537), NOT as a new top-level pattern. All 3 verified absent via grep before adding.
    — **Consumers affected:** Three.js review workflows, frontend review workflows.

- [ ] **4.5** Enrich `opentofu-neon-explorer-skill/SKILL.md` with `connection_uri_pooler` attribute (B3 — TARGET CORRECTED)
    — **Why:** `connection_uri_pooler` is a **Neon** attribute, not AWS. The original plan targeted `opentofu-aws-explorer-skill` — wrong provider. Corrected to `opentofu-neon-explorer-skill`.
    — **Done when:** Attribute documented in Neon skill. Cross-reference to `aws-iac-safety-skill` added only if contextually relevant (A4 is safety patterns, Neon explorer is resource discovery — may not cross-reference naturally; skip if forced).
    — **Consumers affected:** OpenTofu Neon exploration workflows.

- [ ] **4.6** ~~DROPPED~~ — `python-layered-naming-skill` does not exist. Step removed per Locked Decision #9. No replacement needed.

- [ ] **4.7** Enrich `authentication-authorization-skill/SKILL.md` with `one-policy-per-role-type` pattern ONLY (A3 fold-in — duplicate excluded)
    — **Why:** Two Keycloak patterns were proposed. BUT `two-layer-keycloak-authorization` ALREADY EXISTS at L286-314 of the auth skill. Only `one-policy-per-role-type` is genuinely new.
    — **Done when:** `one-policy-per-role-type` pattern added with provenance from `betekk-keycloak/LEARNINGS/`. Verified absent via grep before adding. `two-layer-keycloak-authorization` NOT re-added (already present at L286).
    — **Consumers affected:** Auth review workflows, Keycloak configuration tasks.

---

## Phase 5 — A1 + A4 New Global Skills

_Owner: `opencode-tooling-subagent`_

- [ ] **5.1** Create `opencode_app/.opencode/skills/fastapi-pydantic-orm-patterns-skill/SKILL.md` with all patterns from Phase 3.1 brief
    — **Why:** 10+ cross-repo patterns (Pydantic-on-JSONB, detached ORM, Alembic JSONB+asyncpg, enum strategy, instance check, defensive enum mapping, Pydantic v2 idioms, inline imports, broad except) need a permanent home in the skill ecosystem. Currently scattered across 2 repos' LEARNINGS only.
    — **Done when:** SKILL.md exists with: (a) frontmatter with `name`, `description`, `category: Language-Specific`, `license`, `compatibility`, `metadata: { audience: developers, workflow: backend-api-development }`; (b) HTML-comment provenance block listing source LEARNINGS files per pattern; (c) all patterns from Phase 3.1 brief with code examples and context; (d) skill is under 500 lines (Anthropic heuristic).
    — **Consumers affected:** `python-reviewer-subagent` (C2), primary allowlist (Phase 9), Phase 10 verification.

- [ ] **5.2** Create `opencode_app/.opencode/skills/aws-iac-safety-skill/SKILL.md` with all patterns from Phase 3.2 brief (merged A5)
    — **Why:** 10 cross-repo patterns need a home (was 11 — `Lambda Function URL CNAME` EXCLUDED as duplicate; already at `opentofu-aws-explorer-skill:1158`). Remaining: ECR lowercase, cross-module ECR lifecycle, GHA resources gating, public Lambda posture reversal, Lambda Web Adapter vs Mangum, local state for prod, GHA artifact mismatch, SSM parameter doc convention, hardcoded dev SSM paths, + any non-duplicate additions. Merges A5 GitHub Actions patterns into a single IaC safety skill.
    — **Done when:** SKILL.md exists with frontmatter (`category: DevOps`), provenance block, all non-duplicate patterns with examples. Verify skill stays under 500 lines (A4 merges two domains — if it exceeds 500, split GHA patterns into a separate skill `github-actions-safety-skill`). Exclude `Lambda Function URL CNAME` (reference `opentofu-aws-explorer-skill:1158` instead of re-documenting).
    — **Consumers affected:** primary allowlist (Phase 9), Phase 10 verification.

---

## Phase 6 — A8 Project-Scoped Skill

_Owner: `opencode-tooling-subagent`_

- [ ] **6.1** Create `canvastekk-workflow-nodes/.opencode/skills/workflow-node-sdk-skill/SKILL.md` with version duo/triad, CDS normalization, async-blocking-poll, ZAI client + node mixin patterns
    — **Why:** 4 patterns specific to the workflow-nodes SDK are captured in LEARNINGS but have no skill. Project-scoped (not global) because only this repo uses the SDK.
    — **Done when:** SKILL.md exists at the project-scoped path with frontmatter, provenance, all 4 patterns. No global sync needed (Phase 9 skips this).
    — **Consumers affected:** `canvastekk-workflow-nodes` development workflows only.

---

## Phase 7 — C1: Imperative LEARNINGS Recall Rule in 8 Reviewers

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

- [ ] **7.8** Add C1 recall rule prose to `uiux-reviewer-subagent.md` frontmatter body
    — **Why:** uiux-reviewer is the 8th reviewer subagent (has a Return Contract section at L209, applies a 13-axis review rubric). Originally omitted from C1 — must be included for consistency.
    — **Done when:** Identical recall rule prose present in frontmatter body.
    — **Consumers affected:** UI/UX review workflows.

---

## Phase 8 — C2/C3 Allowlists + C4 Strict Return Contract Field (8 Reviewers)

_Owner: `opencode-tooling-subagent`_

- [ ] **8.1** Add `fastapi-pydantic-orm-patterns-skill: allow` to `python-reviewer-subagent.md` `permission.skill` block + UPDATE existing prose at L96 (C2)
    — **Why:** Python reviewer needs to load A1 skill during reviews. L96 already names the A1 patterns in prose (`"Pydantic-on-JSONB pitfalls, detached-instance bugs, enum strategy resolution patterns"`) — adding new prose would DUPLICATE. Instead, update L96 to reference the skill by name.
    — **Done when:** `permission.skill` block contains the allow entry; L96 prose updated to reference `fastapi-pydantic-orm-patterns-skill` by name (not a new prose block).
    — **Consumers affected:** Python review workflows.

- [ ] **8.2** Add `react-hooks-antipatterns-skill: allow` + `react-render-antipatterns-skill: allow` to `typescript-reviewer-subagent.md` `permission.skill` block + awareness prose (C3)
    — **Why:** TypeScript reviewer needs both B1 split skills; the old `react-nextjs-antipatterns-skill` is deleted in Phase 4.
    — **Done when:** Both entries present in allowlist; awareness prose mentions hooks vs render pattern separation.
    — **Consumers affected:** TypeScript/React review workflows.

- [ ] **8.3** Add C4 strict `Patterns applied/violated` field to Return Contract Convention in repo `AGENTS.md` — **SPLIT into general + reviewer sub-section**
    — **Why:** AGENTS.md L96 states "All subagents return this structure" — the convention governs all 34 subagents with a Return Contract section. Injecting a reviewer-required field into the general section would make 26 of 34 agents non-conformant. The fix: keep the general quartet [Status/Output/Summary/Issues] universal, and add a "Reviewer Additions" sub-section scoping `Patterns applied/violated` to the 8 reviewers only.
    — **Done when:** Return Contract Convention section restructured as:
      > **General (all subagents):** Status / Output / Summary / Issues
      >
      > **Reviewer Additions (architecture, code, python, typescript, java, go, rust, uiux):**
      > **Patterns applied/violated:** `[{id: <LEARNINGS-slug>, status: applied|violated, evidence: <file:line or review-section ref>}]`
      > - **Required** for all reviewer subagents on every review.
      > - If no LEARNINGS pattern applied or was violated, emit `Patterns applied/violated: []` (empty list, never omit).
    — **Consumers affected:** 8 reviewer subagents (explicitly scoped); 26 non-reviewer agents remain conformant with the general quartet.

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

- [ ] **8.11** Add C4 `Patterns applied/violated` field to `uiux-reviewer-subagent.md` Return Contract
    — **Why:** uiux-reviewer is the 8th reviewer (has Return Contract at L209, applies a 13-axis rubric). Originally omitted from C4 — must be included for consistency with the 8.3 convention split.
    — **Done when:** Field specification present, matching the AGENTS.md "Reviewer Additions" sub-section wording.
    — **Consumers affected:** UI/UX review outputs.

---

## Phase 9 — Doc-Sync (setup.sh, setup.ps1, README.md, opencode_app/README.md, opencode.json, registry.json, deploy/.AGENTS.md)

_Owner: `opencode-tooling-subagent` using `documentation-sync-workflow-skill`_

- [ ] **9.1** Update `deploy/setup.sh` — add A1, A4, B1 split skills to per-category listing; remove deleted `react-nextjs-antipatterns-skill`; verify `count_skills()` + new `count_agents()` are used in banner/echoes
    — **Why:** Setup.sh is the primary install script — skill/agent listings must match directory reality. Adding 3 new skills (A1, A4, and the 2 B1 split skills minus the 1 deleted = net +3) changes the counts.
    — **Done when:** Category listings updated; old skill removed; banner uses dynamic counts; `bash -n setup.sh` passes.
    — **Consumers affected:** All users running `deploy/setup.sh`.

- [ ] **9.2** Update `deploy/setup.ps1` — Windows parity for step 9.1 changes
    — **Why:** setup.ps1 must mirror setup.sh changes (same skill adds/removes, same dynamic counts).
    — **Done when:** Listings updated; old skill removed; `Get-AgentCount` used; `pwsh -n setup.ps1` passes.
    — **Consumers affected:** Windows users running setup.ps1.

- [ ] **9.3** Update `README.md` — Skill Categories table + intro total + **agent-count math at L241**
    — **Why:** README is the public-facing documentation; counts and table must match the installed skills. L241 has hand-maintained `"Not every project needs all 36 agents + 125 skills"` — the agent count must reconcile with D1's dynamic count.
    — **Done when:** Skill Categories table includes A1 (`Language-Specific`), A4 (`DevOps`), B1 split skills (`Framework-Specific`); old skill removed; total count correct. L241 agent count updated to match D1 dynamic count (or noted as approximate).
    — **Consumers affected:** All repo visitors and `opencode-init` users.

- [ ] **9.4** Update `opencode_app/README.md` — Docker-specific docs + **agent-count math at L171**
    — **Why:** L171 has `"24 of 36 agents have explicit task permissions; the remaining 12 default to full access"` — this is agent-count-conditional math (24 + 12 = 36). If the agent total changes, both summands need re-derivation.
    — **Done when:** L171 agent math reconciled with D1 dynamic count; any skill/agent count references updated.
    — **Consumers affected:** Docker users.

- [ ] **9.5** Update `opencode_app/opencode.json` — add A1 + A4 + B1 split skills to `permission.skill` allowlist
    — **Why:** Without allowlist entries, new skills are invisible to the primary session. NOTE: `react-nextjs-antipatterns-skill` is NOT in the global allowlist (confirmed — it was loaded only via 4 per-agent overrides, which are cleaned up in Phase 4.3b/c/d). No removal needed here.
    — **Done when:** `"fastapi-pydantic-orm-patterns-skill": "allow"`, `"aws-iac-safety-skill": "allow"`, `"react-hooks-antipatterns-skill": "allow"`, `"react-render-antipatterns-skill": "allow"` present in global allowlist. Old skill entry NOT present (confirm absence — no removal action).
    — **Consumers affected:** Primary session (skill visibility).

- [ ] **9.6** Rebuild `deploy/registry.json` via `node deploy/build-registry.mjs`
    — **Why:** Registry is a generated file — manual edits are overwritten. Must rebuild to include new skills and their `category:` frontmatter.
    — **Done when:** `node deploy/build-registry.mjs` completes without error; new skills appear in registry with correct categories (`Language-Specific`, `DevOps`, `Framework-Specific`).
    — **Consumers affected:** `opencode-init --list/--describe/--expand`, README category table derivation.

- [ ] **9.7** Update `deploy/.AGENTS.md` — hand-maintained skill/agent counts
    — **Why:** `deploy/.AGENTS.md` deploys to `~/.config/opencode/AGENTS.md` and contains hand-maintained counts that WILL drift after +3 net skills: L89 (`"Only the 80 explicitly-allowed skills appear... the other 44 are hidden"`) and L93 (`"34 of 36 subagents have their own permission.skill blocks"`). These must reconcile with the new skill/agent totals.
    — **Done when:** L89 allowlist count updated (80 → 83 for +3 primary-visible skills; 44 → 41 hidden). L93 agent count reconciled with D1 dynamic count. Verify deployed copy at `~/.config/opencode/AGENTS.md` matches after redeploy.
    — **Consumers affected:** All sessions (this file is injected into every opencode session's system prompt).

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
| B1 split loses patterns | Phase 3.3 brief uses 3-way classification (hooks/render/redistribute); union of all 3 = original set; Phase 10 grep-checks |
| B1 deletion blast radius missed | Phase 4.3 expanded with 17 sub-steps (a–q) covering 3 allowlists, 6 skill cross-refs, 6 bats assertions, 1 preset, prose refs, copy-paste cleanup |
| C4 field ignored by reviewers | C1 recall rule creates the habit; C4 is a strict required field in "Reviewer Additions" sub-section (scoped to 8 reviewers) |
| C4 convention scope ambiguity | AGENTS.md convention SPLIT into general quartet (all 34) + reviewer additions (8 only) — 26 non-reviewer agents stay conformant |
| D1 count_agents() breaks setup | Phase 10 runs `bash -n` + `pwsh -n` before merge |
| D1 derived counts missed | Phase 2.9 covers 4 "and N more agents" lines with explicit arithmetic interpolation |
| Doc-sync misses a file | Phase 9 expanded to 7 files including `deploy/.AGENTS.md`; uses `documentation-sync-workflow-skill` |
| Registry not rebuilt | Phase 9.6 is a dedicated step; Phase 10.3 validates it |
| A4 merged skill exceeds 500 lines | Phase 5.2 Done when includes split-if-over-500 check (fall back to separate `github-actions-safety-skill`) |
| Forward-ref dangling (Phase 5 fails) | B4 dropped (phantom skill); B3 target corrected to neon-explorer — no cross-phase forward refs remain except Phase 4.5→A4 name ref (safe: name ref, not file ref) |
| Skill count inflation (136→139) | Each new skill adds ~3 lines to primary `available_skills` listing (~9 tokens total — immaterial). No retirement plan in this PLAN; future PLAN may address `zai-vision-analysis-skill` orphan |
