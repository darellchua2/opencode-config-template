# PLAN: Playwright responsive audit skill + slope mobile fix

**Ticket**: [DA-1421](https://betekk.atlassian.net/browse/DA-1421)
**Branch**: `DA-1421`
**Status**: In Progress
**Type**: Story
**Priority**: Medium
**Labels**: frontend, playwright, responsive, tooling

---

## Summary

Establish a Playwright-driven **checker-and-fixer** capability for responsive UI, then apply it to make `canvastekk-frontend-nextjs` fully mobile-responsive — starting with the **slope inspection** pages, which are currently not mobile-responsive.

The repo has a mature Playwright E2E setup but it is **desktop-only** (`playwright.config.ts:126-133` — the mobile project is commented out). 32 components live under the slope report path; only ~9 use responsive breakpoints. There is currently no systematic way to detect or prevent responsive regressions.

### Design Decisions

| # | Decision | Rationale |
| --- | --- | --- |
| 1 | Architecture = Skill + Subagent (extract-then-delegate pattern) | Matches conventions in `opencode-config-template` configurator repo |
| 2 | Scope = GLOBAL & GENERIC for Next.js projects | Skill + subagent live in configurator repo's source-of-truth dir; deployed globally to `~/.config/opencode/`. Each Next.js repo consumes them. Repo-specifics discovered at runtime |
| 3 | Behavior = AUDIT + FIX + REGRESSION SPEC (full closed loop) | Subagent detects defects, fixes components, re-verifies, emits permanent Playwright regression spec |
| 4 | Baseline = wireframer-skill (ported to opencode format) | Lo-fi wireframe output as structural layout baseline per breakpoint — avoids "lock in broken pixels" problem of screenshot-diff. Port from Claude/Cursor format to opencode-native |
| 5 | Fix tiering by confidence | Tier 1 (auto-fix): mechanical Tailwind breakpoints, `flex-col`, tap-target >=44px. Tier 2 (propose+verify): table->card, dialog resize. Tier 3 (report only): complex restructures. Closed detect->fix->re-verify loop re-checks ALL viewports each iteration, caps iterations |

### Architecture

```
                        +-------------------------------------+
                        |  responsive-audit-subagent (glm-5.1) |
                        |  bash:allow  edit:allow              |
                        +---------------+---------------------+
           loads skill  |               | delegates screenshot review
  +---------------------v--+    +-------v----------------------+
  | playwright-responsive-  |    | image-analyzer-             |
  | audit-skill (method)    |    | subagent (vision)           |
  +------------+------------+    +-----------------------------+
      references| (baseline source)
  +-------------v-----------+
  | wireframer-skill        |  <- ported to opencode format
  | (lo-fi layout baseline) |
  +-------------------------+
```

---

## Dependency & Consumer Map

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---------------------|---------------------------|---------------------------------|-------------|
| `wireframer-skill/SKILL.md` | — | playwright-responsive-audit-skill, responsive-audit-subagent | low |
| `playwright-responsive-audit-skill/SKILL.md` | wireframer-skill | responsive-audit-subagent | medium |
| `responsive-audit-subagent.md` | playwright-responsive-audit-skill | primary session (consumer repo) | medium |
| `deploy/setup.sh` | all 3 above created | deploy pipeline | low |
| `deploy/setup.ps1` | all 3 above created | deploy pipeline (Windows parity) | low |
| `README.md` | all 3 above created | documentation surface | low |
| `playwright.config.ts` (frontend repo) | — | all E2E + responsive specs | high |
| `e2e/baselines/slope/` | playwright.config.ts viewport matrix | slope.responsive.spec.ts | medium |
| slope components (`src/app/(secured)/.../slope/**`) | wireframer baselines | slope.responsive.spec.ts, end users | high |
| `e2e/responsive/slope.responsive.spec.ts` | fixed slope components | CI pipeline (regression lock) | medium |

---

## Implementation Phases

### Phase 1: Build Generic Capability in Configurator Repo

- [ ] **1.1** Port `wireframer-skill` to opencode format (from Claude/Cursor `agilek/wireframer-skill` source)
    — **Why:** Provides the lo-fi layout baseline per breakpoint that the audit skill references; avoids screenshot-diff's "lock in broken pixels" problem. Must exist before the audit skill can reference it.
    — **Done when:** `opencode_app/.opencode/skills/wireframer-skill/SKILL.md` exists with valid opencode frontmatter (name, description, triggers), lo-fi wireframe output methodology, and breakpoint parameterization
    — **Consumers affected:** playwright-responsive-audit-skill (references as baseline source)

- [ ] **1.2** Create `playwright-responsive-audit-skill` methodology SKILL.md
    — **Why:** Defines the audit/fix/regression methodology (6 detection assertions, 3 fix-confidence tiers, closed detect->fix->re-verify loop). The subagent consumes this skill for its operational method.
    — **Done when:** `opencode_app/.opencode/skills/playwright-responsive-audit-skill/SKILL.md` exists documenting: 6 detection assertions (horizontal overflow, element clipping, breakpoint visibility toggle, tap-target >=44px, text truncation, layout-shift), 3 fix tiers, and the closed-loop iteration pattern
    — **Consumers affected:** responsive-audit-subagent (loads this skill)

- [ ] **1.3** Create `responsive-audit-subagent` agent definition
    — **Why:** The executable agent that runs the audit in a target Next.js repo. Needs `bash:allow` (for `npm run test:e2e`) and `edit:allow` (to apply fixes). Model = `glm-5.1` for sound reasoning on component fixes.
    — **Done when:** `opencode_app/.opencode/agents/responsive-audit-subagent.md` exists with model `zai-coding-plan/glm-5.1`, `bash:allow` + `edit:allow` permissions, delegates screenshot review to `image-analyzer-subagent`, and follows Return Contract convention
    — **Consumers affected:** primary session in consumer repos (canvastekk-frontend-nextjs)

- [ ] **1.4** Sync README + deploy scripts (counts, banner, category listing)
    — **Why:** Keeps the configurator repo's documentation in sync with the new skill/agent additions. Required by the repo's Sync Rules — every new skill/agent must update `deploy/setup.sh`, `deploy/setup.ps1`, and `README.md`.
    — **Done when:** skill count incremented by 2 (wireframer-skill + playwright-responsive-audit-skill), agent count incremented by 1 (responsive-audit-subagent), new "Responsive & Visual Testing" category added to all three files, `opencode_app/README.md` updated if relevant
    — **Consumers affected:** deploy pipeline, documentation readers

### Phase 2: Consume on canvastekk-frontend-nextjs (Slope Inspection = First Target)

- [ ] **2.1** Fix `playwright.config.ts` viewport matrix (mobile + tablet + desktop with auth)
    — **Why:** Unblocks all responsive testing. Currently lines 126-133 have the mobile project commented out; all tests run at 1280x720 only. Must enable multi-viewport projects before any audit can run.
    — **Done when:** `playwright.config.ts` has working `desktop-chromium` (1280x720), `mobile-chrome` (375x667, hasTouch), and `tablet` (768x1024, iPad) projects, all wired with `storageState: "e2e/.auth/user.json"` and auth setup
    — **Consumers affected:** all existing E2E specs (may need viewport-aware adjustments), responsive audit specs

- [ ] **2.2** Generate wireframer baselines for slope report page at 4 breakpoints
    — **Why:** Establishes the structural layout baseline that the audit compares against. Without baselines, the audit has no "correct" reference to detect deviation from.
    — **Done when:** Baseline files exist under `e2e/baselines/slope/` for mobile (375px), tablet (768px), desktop (1280px), and large-desktop (1920px) breakpoints, committed to the repo
    — **Consumers affected:** slope.responsive.spec.ts (consumes baselines for assertions), responsive-audit-subagent

- [ ] **2.3** Audit slope pages — identify all responsive defects (~23 components lacking breakpoints)
    — **Why:** Produces the defect inventory that drives fix prioritization. Must run the full audit (6 assertions across all breakpoints) before fixing to establish complete scope.
    — **Done when:** Defect report generated listing every component with responsive issues, classified by fix-confidence tier (Tier 1: mechanical breakpoint additions; Tier 2: table->card, dialog resize; Tier 3: complex restructures)
    — **Consumers affected:** fix implementation steps (2.4)

- [ ] **2.4** Apply responsive fixes (Tailwind breakpoints, table->card transforms) + re-audit verify
    — **Why:** Closes the detect->fix->re-verify loop. Applies Tier 1 auto-fixes, proposes+verifies Tier 2 transforms, and reports Tier 3 items. Re-audits ALL viewports after each fix iteration.
    — **Done when:** All Tier 1 + Tier 2 defects fixed; confirmed defects (e.g. `TekkSlopeCardElements.tsx:51` table->card) resolved; re-audit passes with 0 horizontal-overflow, 0 clipping, tap-targets >=44px at all breakpoints; Tier 3 items documented as follow-up
    — **Consumers affected:** end users (mobile UX improvement), slope.responsive.spec.ts (regression lock targets fixed state)

- [ ] **2.5** Emit `slope.responsive.spec.ts` regression lock spec
    — **Why:** Prevents future regressions. The spec locks in the fixed responsive state by running the 6 detection assertions across all breakpoints on every CI run. This is the permanent artifact that makes the audit capability self-sustaining.
    — **Done when:** `e2e/responsive/slope.responsive.spec.ts` exists, committed, and passing in CI; covers all 6 assertions at mobile/tablet/desktop breakpoints for the slope report pages
    — **Consumers affected:** CI pipeline (regression gate)

---

## Acceptance Criteria

- [ ] Generic `wireframer-skill` + `playwright-responsive-audit-skill` + `responsive-audit-subagent` created in configurator repo, opencode-format, with README/setup.sh/setup.ps1 sync'd
- [ ] `playwright.config.ts` has a working viewport matrix (mobile + tablet + desktop projects with auth state)
- [ ] Slope inspection pages pass the responsive audit at all breakpoints (no horizontal overflow, no clipping, tap-targets >=44px, breakpoint-visibility toggles correct)
- [ ] Confirmed defects (e.g. `TekkSlopeCardElements.tsx` table->card) fixed and verified
- [ ] `e2e/responsive/slope.responsive.spec.ts` regression spec committed and passing
- [ ] Wireframer baselines committed under `e2e/baselines/slope/`

---

## Scope

**Configurator repo** (`opencode-config-template/opencode_app/.opencode/`): skills, agents, deploy scripts
**Frontend repo** (`canvastekk-frontend-nextjs`): `playwright.config.ts`, `src/app/(secured)/projects/[projectId]/reports/slope/**`, `e2e/` fixtures and specs

---

## Technical Notes

- `playwright.config.ts:126-133`: uncomment `mobile-chrome`, add `tablet` (iPad), wire `storageState: "e2e/.auth/user.json"` + `hasTouch: true`
- 6 detection assertions: horizontal overflow, element clipping, breakpoint visibility toggle, tap-target >=44px @touch, text truncation, layout-shift
- Fix confidence tiers: Tier 1 (auto-fix), Tier 2 (propose+verify), Tier 3 (report only)
- Closed detect->diagnose->fix->re-verify loop uses `loop-operator-subagent` + `verification-loop-skill` from configurator
- `bash:allow` on subagent is deliberate (required for `npm run test:e2e`), precedent from `repo-ops`/`pr-workflow` agents
- wireframer-skill source: `https://github.com/agilek/wireframer-skill` (Claude/Cursor format -> port to opencode)
- Reference pattern for correct responsive: `TekkSlopeStatisticsCards.tsx:20` uses `grid-cols-1 sm:grid-cols-2 lg:grid-cols-4`
- Confirmed defect example: `TekkSlopeCardElements.tsx:51` renders `<table>` with `overflow-x-auto` -> should become card-list on mobile

---

## Risks & Mitigation

| Risk | Likelihood | Mitigation |
|------|-----------|------------|
| Existing E2E specs break with new viewport projects | Medium | Run full suite after viewport matrix change; add `viewport` guard to specs that are desktop-only by design |
| Wireframer port introduces format incompatibilities | Low | Validate against opencode skill schema; test-load in a sandbox before deploy |
| Tier 2 fixes (table->card) are non-trivial | Medium | Propose+verify pattern with screenshot review via image-analyzer-subagent; cap iterations |
| Frontend repo access/permissions | Low | Verify git remote + branch access before Phase 2 |

---

## Dependencies

- Source repo for wireframer-skill: `https://github.com/agilek/wireframer-skill`
- Configurator repo conventions: `opencode-config-template/AGENTS.md` (Sync Rules, Subagent Model Tiering)
- Frontend repo: `canvastekk-frontend-nextjs` (must be accessible for Phase 2)

---

*Created by ticket-plan-workflow-skill*
