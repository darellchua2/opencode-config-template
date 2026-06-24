# PLAN: Playwright responsive audit skill + slope mobile fix

**Ticket**: [DA-1421](https://betekk.atlassian.net/browse/DA-1421)
**Branch**: `DA-1421`
**Status**: In Progress
**Type**: Story
**Priority**: Medium
**Labels**: frontend, playwright, responsive, tooling

---

## Summary

Establish a Playwright-driven **checker-and-fixer** capability for responsive UI as a generic skill + subagent in this configurator repo. The capability is deployed globally to `~/.config/opencode/` and consumed by any Next.js project at runtime — repo-specific implementation (e.g. fixing slope pages in `canvastekk-frontend-nextjs`) is tracked in a separate ticket in that repo.

### Design Decisions

| # | Decision | Rationale |
| --- | --- | --- |
| 1 | Architecture = Skill-restricted subagent (subagent loads its own skill via `permission.skill`) | Matches conventions in this repo (`loop-operator-subagent`, `repo-ops-specialist-subagent`, `pr-workflow-subagent` all embed their methodology skill). Not extract-then-delegate — the subagent owns its own skill access and method. |
| 2 | Scope = GLOBAL & GENERIC for Next.js projects | Skill + subagent live in configurator repo's source-of-truth dir; deployed globally to `~/.config/opencode/`. Each Next.js repo consumes them. Repo-specifics discovered at runtime |
| 3 | Behavior = AUDIT + FIX + REGRESSION SPEC (full closed loop) | Subagent detects defects, fixes components, re-verifies, emits permanent Playwright regression spec |
| 4 | Baseline = wireframer-skill (ported to opencode format) | Lo-fi wireframe output as structural layout baseline per breakpoint — avoids "lock in broken pixels" problem of screenshot-diff. Port from Claude/Cursor format to opencode-native |
| 5 | Fix tiering by confidence | Tier 1 (auto-fix): mechanical Tailwind breakpoints, `flex-col`, tap-target >=44px. Tier 2 (propose+verify): table->card, dialog resize. Tier 3 (report only): complex restructures. Closed detect->fix->re-verify loop re-checks ALL viewports each iteration, caps iterations |
| 6 | Closed-loop orchestration = **primary session** (not subagent) | The primary session orchestrates the detect->fix->re-verify loop using `loop-operator-subagent` + `verification-loop-skill`. The `responsive-audit-subagent` performs individual audit/fix cycles; the primary session chains them and manages iteration. This keeps the subagent lightweight — it does NOT need `permission.task: loop-operator-subagent` or `permission.skill: verification-loop-skill`. |
| 7 | Image/screenshot delegation = **both paths** (primary + subagent) | The primary session AND the `responsive-audit-subagent` can delegate visual analysis to `image-analyzer-subagent`. Primary session routing is already in `deploy/.AGENTS.md` (Image/video analysis row). The subagent gains access via `permission.task: image-analyzer-subagent: allow`. This ensures screenshots captured during responsive audits always reach the vision model regardless of which session captures them. The `deploy/.AGENTS.md` routing table must include explicit guidance that ANY image, screenshot, PDF, or non-text document encountered during a session should be delegated to `image-analyzer-subagent` — not processed inline by the text-only primary model. |

### Architecture

```
                        +-----------------------------------------+
                        |  PRIMARY SESSION (orchestrator)         |
                        |  loops via loop-operator-subagent       |
                        |  + verification-loop-skill              |
                        |  ALSO delegates images/screenshots      |
                        |  to image-analyzer-subagent directly    |
                        +-----+-----------+---------------+-------+
                              |           |               |
              +---------------v---+       |               v
              |  responsive-audit-|       |        +------+----------+
              |  subagent (glm-5.1)|       |        | image-analyzer |
              |  bash:allow        |       |        | -subagent      |
              |  edit:allow        |       |        | (glm-5v-turbo) |
              |  permission.skill: |       |        | (vision)       |
              |    playwright-     |       |        +------+----------+
              |    responsive-     |       |               ^
              |      audit-skill:  |       |               |
              |      allow         |       |               |
              |  permission.task:  |       |               |
              |    "*": deny       |       |               |
              |    explore: allow  |       |               |
              |    general: allow  |-------+---------------+
              |    image-analyzer: |  delegates screenshots for review
              |      allow         |       | (subagent path)
              +-----+-------+------+-------+
        loads skill|       |
  +---------------v---+   |
  | playwright-        |   |
  | responsive-audit-  |   |
  | skill (method)     |   |
  +---------+----------+   |
     references|           |
  +-----------v-----------+ |
  | wireframer-skill      | |
  | (lo-fi layout baseline)| |
  +-----------------------+ |
```
**Two delegation paths to image-analyzer-subagent:**
1. **Primary session** -> `image-analyzer-subagent` (direct, when primary captures/receives screenshots)
2. **responsive-audit-subagent** -> `image-analyzer-subagent` (via `permission.task`, during audit cycles)

---

## Dependency & Consumer Map

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---------------------|---------------------------|---------------------------------|-------------|
| `wireframer-skill/SKILL.md` | — | playwright-responsive-audit-skill, responsive-audit-subagent, primary session (standalone baseline generation) | low |
| `playwright-responsive-audit-skill/SKILL.md` | wireframer-skill | responsive-audit-subagent | medium |
| `responsive-audit-subagent.md` | playwright-responsive-audit-skill | primary session (consumer repo) | medium |
| `deploy/setup.sh` | all 3 above created | deploy pipeline | low |
| `deploy/setup.ps1` | all 3 above created | deploy pipeline (Windows parity) | low |
| `README.md` | all 3 above created | documentation surface | low |
| `opencode_app/README.md` | all 3 above created | Docker-specific docs | low |
| `deploy/.AGENTS.md` | responsive-audit-subagent created | primary session routing (subagent discoverability) | low |
| `playwright.config.ts` (frontend repo) | — | all E2E + responsive specs | high |
| `e2e/baselines/slope/` | playwright.config.ts viewport matrix | slope.responsive.spec.ts | medium |
| slope components (`src/app/(secured)/.../slope/**`) | wireframer baselines | slope.responsive.spec.ts, end users | high |
| `e2e/responsive/slope.responsive.spec.ts` | fixed slope components | CI pipeline (regression lock) | medium |

---

## Pre-existing Count Verification

- **Skills**: Declared count in `deploy/setup.sh`/`setup.ps1`: **86** | Actual skill dirs (excl `_archived/`, `scripts/`): **86** — in sync
- **Agents**: Actual agent count: **35** (declared in deploy scripts)
- **`opencode_app/README.md`**: Pre-existing drift — says "82 skill directories" but actual is **86**. Must be corrected to **88** during this work (86 + 2 new).
- **Counting convention**: Exclude `_archived/` and `scripts/` directories when counting skills.

---

## Implementation Phases

### Phase 1: Build Generic Capability in Configurator Repo

- [x] **1.1** Port `wireframer-skill` to opencode format (from Claude/Cursor `agilek/wireframer-skill` source)
    — **Why:** Provides the lo-fi layout baseline per breakpoint that the audit skill references; avoids screenshot-diff's "lock in broken pixels" problem. Must exist before the audit skill can reference it. Also usable standalone by the primary session for baseline generation in Phase 2.
    — **Done when:** `opencode_app/.opencode/skills/wireframer-skill/SKILL.md` exists with:
      - Valid opencode frontmatter: `name`, `description` (1-1024 chars), `license`, `compatibility`, `metadata.audience`, `metadata.workflow`
      - Lo-fi wireframe output methodology and breakpoint parameterization
      - Trigger metadata: **auto-trigger** (include responsive/layout/baseline trigger phrases in `description`) so the primary session can discover and load it standalone for Phase 2 baseline generation
      - Use `opencode-skill-creation-skill` as the authoritative creation guide during authoring
    — **Consumers affected:** playwright-responsive-audit-skill (references as baseline source), primary session (standalone use in Phase 2)
    — **Pre-check:** Verify source URL `https://github.com/agilek/wireframer-skill` exists and check its license before porting. If URL is invalid or license incompatible, document an alternative approach.

- [x] **1.2** Create `playwright-responsive-audit-skill` methodology SKILL.md
    — **Why:** Defines the audit/fix/regression methodology (6 detection assertions, 3 fix-confidence tiers, closed detect->fix->re-verify loop). The subagent consumes this skill for its operational method.
    — **Done when:** `opencode_app/.opencode/skills/playwright-responsive-audit-skill/SKILL.md` exists with:
      - Valid opencode frontmatter: `name`, `description` (1-1024 chars), `license`, `compatibility`, `metadata.audience`, `metadata.workflow`
      - 6 detection assertions documented: horizontal overflow, element clipping, breakpoint visibility toggle, tap-target >=44px @touch, text truncation, layout-shift
      - 3 fix-confidence tiers: Tier 1 (auto-fix), Tier 2 (propose+verify), Tier 3 (report only)
      - Closed-loop iteration pattern (detect -> diagnose -> fix -> re-verify, caps iterations)
      - Trigger metadata: **model-invoked only** (no auto-trigger phrases in `description` — this skill is loaded exclusively via `permission.skill` by the subagent, not discovered by the primary session)
      - Use `opencode-skill-creation-skill` as the authoritative creation guide during authoring
    — **Consumers affected:** responsive-audit-subagent (loads this skill)

- [x] **1.3** Create `responsive-audit-subagent` agent definition
    — **Why:** The executable agent that runs the audit in a target Next.js repo. Needs `bash:allow` (for `npm run test:e2e`) and `edit:allow` (to apply fixes). Model = `glm-5.1` for sound reasoning on component fixes.
    — **Done when:** `opencode_app/.opencode/agents/responsive-audit-subagent.md` exists with:
      - Model: `zai-coding-plan/glm-5.1` (correctness-critical tier per AGENTS.md)
      - `bash: allow` + `edit: allow` permissions
      - `permission.skill`: `playwright-responsive-audit-skill: allow` (required for subagent to load its own methodology)
      - `permission.task`: `"*": deny`, `explore: allow`, `general: allow`, `image-analyzer-subagent: allow` (last one required for screenshot review delegation)
      - Delegates screenshot review to `image-analyzer-subagent`
      - Follows Return Contract convention (Status / Output / Summary / Issues)
      - Does NOT need `loop-operator-subagent` or `verification-loop-skill` permissions — the **primary session** orchestrates the closed loop (Decision #6)
      - Use `opencode-agent-creation-skill` as the authoritative creation guide during authoring
    — **Consumers affected:** primary session in consumer repos (canvastekk-frontend-nextjs)

- [x] **1.4** Update `deploy/setup.sh` (skill count, agent count, banner, category listing)
    — **Why:** Keeps the deploy script in sync with new artifacts. Required by repo Sync Rules.
    — **Done when:** Skill count 86 -> 88, agent count 35 -> 36, new "Responsive & Visual Testing" category added to help text + Deploy-Skills summary + banner
    — **Consumers affected:** deploy pipeline

- [x] **1.5** Update `deploy/setup.ps1` (Windows parity mirror of 1.4)
    — **Why:** Windows parity — must match setup.sh exactly per repo convention.
    — **Done when:** Same changes as 1.4 applied to PowerShell script
    — **Consumers affected:** deploy pipeline (Windows)

- [x] **1.6** Update `README.md` (Skill Categories table, Subagents table)
    — **Why:** Keeps the root README in sync with new skill/agent additions.
    — **Done when:** Skill Categories table has new "Responsive & Visual Testing" row (count + description), Subagents table includes `responsive-audit-subagent` row
    — **Consumers affected:** documentation readers

- [x] **1.7** Update `opencode_app/README.md` + `deploy/.AGENTS.md` routing table
    — **Why:** Corrects pre-existing count drift in `opencode_app/README.md` (currently says 82, actual is 86) and adds the new subagent to the primary-session routing table for discoverability.
    — **Done when:**
      - `opencode_app/README.md`: skill count corrected from stale **82** -> **88** (86 actual + 2 new)
      - `deploy/.AGENTS.md` Subagent Routing Preferences table: add row `| Responsive/visual audit | responsive-audit-subagent | — | Playwright responsive UI audit + fix closed loop |`
      - `deploy/.AGENTS.md` MCP Tool Routing table: verify the existing `image-analyzer-subagent` row explicitly states that the **primary session** must delegate ANY image, screenshot, PDF, or non-text document to `image-analyzer-subagent` — never attempt to process visual content inline. Add explicit guidance: "When the primary session encounters an image, screenshot, PDF, or any non-text document, delegate analysis to `image-analyzer-subagent`. Do NOT attempt to interpret visual content inline — the primary model is text-only and will hallucinate or skip visual details."
    — **Consumers affected:** documentation readers, primary session (subagent routing + image delegation clarity)

- [x] **1.8** Validate all new artifacts (frontmatter, schema, test-load)
    — **Why:** Prevents silent deploy-time failures. A skill with invalid frontmatter (wrong name regex, missing `description`, directory name mismatch) or a subagent with a syntax error would fail at deploy time. Must validate before Phase 2 consumes the capability.
    — **Done when:**
      - Skill frontmatter validated: `name` matches directory name, `description` is 1-1024 chars, `license`/`compatibility`/`metadata` fields present
      - Agent frontmatter validated: `mode`/`model`/`permission` structure is correct
      - Run `opencode-skills-maintainer-skill` audit or `documentation-sync-workflow-skill` to verify cross-references resolve and counts are consistent across all sync files
      - Verify no broken skill-to-skill or agent-to-skill references
    — **Consumers affected:** Phase 2 (validation gate — cannot proceed without passing)

### Phase 2: Consume on canvastekk-frontend-nextjs (Slope Inspection = First Target)

> **Removed from this PLAN** — Phase 2 targets a different repo (`canvastekk-frontend-nextjs`) and will be tracked in a separate ticket created in that repo. This configurator repo only builds and ships the generic capability. The frontend repo ticket will cover: viewport matrix fix, wireframer baselines, slope component audit, responsive fixes, and regression spec emission.

---

## Acceptance Criteria

- [x] Generic `wireframer-skill` + `playwright-responsive-audit-skill` + `responsive-audit-subagent` created in configurator repo, opencode-format, with README/setup.sh/setup.ps1 sync'd
- [x] All new skills/agents pass frontmatter validation (Step 1.8)

---

## Scope

**Configurator repo** (`opencode-config-template/opencode_app/.opencode/`): skills, agents, deploy scripts, README files, AGENTS.md routing

> **Out of scope**: Frontend repo implementation (viewport matrix fix, slope component audit, responsive fixes, regression spec) — tracked in a separate ticket in the consuming repo.

---

## Technical Notes

- 6 detection assertions: horizontal overflow, element clipping, breakpoint visibility toggle, tap-target >=44px @touch, text truncation, layout-shift
- Fix confidence tiers: Tier 1 (auto-fix), Tier 2 (propose+verify), Tier 3 (report only)
- Closed detect->diagnose->fix->re-verify loop: **primary session orchestrates** using `loop-operator-subagent` + `verification-loop-skill`; the `responsive-audit-subagent` performs individual audit/fix cycles only
- `bash:allow` on subagent is deliberate (required for `npm run test:e2e`), precedent from `repo-ops`/`pr-workflow` agents
- wireframer-skill source: `https://github.com/agilek/wireframer-skill` (Claude/Cursor format -> port to opencode) — verified MIT license
- Skill creation guides: use `opencode-skill-creation-skill` (for skills) and `opencode-agent-creation-skill` (for agents) as authoritative references during authoring
- Skill counting convention: exclude `_archived/` and `scripts/` directories
- **Image delegation**: The primary session is text-only (`glm-5.2`). When it encounters images, screenshots, PDFs, or any non-text document, it MUST delegate analysis to `image-analyzer-subagent` (vision model `glm-5v-turbo`). The `deploy/.AGENTS.md` routing table enforces this convention. Two delegation paths exist: primary -> image-analyzer (direct) and responsive-audit-subagent -> image-analyzer (via `permission.task`).

---

## Risks & Mitigation

| Risk | Likelihood | Mitigation |
|------|-----------|------------|
| Wireframer port introduces format incompatibilities | Low | Validated against opencode skill schema (Step 1.8) |
| Subagent permission misconfiguration (silent denial) | Medium | Step 1.3 Done-when explicitly lists all required `permission.skill` + `permission.task` entries; Step 1.8 validated |
| Pre-existing count drift in `opencode_app/README.md` | Low | Step 1.7 corrected 82 -> 88 |

---

## Dependencies

- Source repo for wireframer-skill: `https://github.com/agilek/wireframer-skill` (verified, MIT)
- Configurator repo conventions: `opencode-config-template/AGENTS.md` (Sync Rules, Subagent Model Tiering)
- Creation guides: `opencode-skill-creation-skill`, `opencode-agent-creation-skill`
- Validation tools: `opencode-skills-maintainer-skill`, `documentation-sync-workflow-skill`

---

*Created by ticket-plan-workflow-skill — reviewed by opencode-tooling-subagent (PASS-WITH-FIXES). Phase 2 (frontend repo consumption) removed — tracked in separate ticket in consuming repo.*
