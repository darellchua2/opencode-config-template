# PLAN: Complete Document-Ladder Phase 2 (BRD + Technical Design Specialist) + Reconcile Business-Development Agent Drift

**JIRA**: [BT-73](https://betekk.atlassian.net/browse/BT-73)
**Branch**: `BT-73`
**Created**: 2026-06-26
**Status**: Created 2026-06-26

## Overview

Three remaining items deferred from BT-72's document-ladder restructure:

1. **BRD (Business Requirements Document)** — Create `brd-creation-skill` (BABOK/IIBA template) and wire it into `requirements-specialist-subagent` with an explicit doc-type routing decision tree. Now that BRD and SRS coexist in one agent, trigger-phrase self-detect is no longer sufficient — a structured routing tree must define when to produce a BRD vs. an SRS.
2. **Technical Design Document** — Create `technical-design-specialist-subagent` (`glm-5.1`, sound-reasoning tier — NOT 5-turbo) + `technical-design-creation-skill`. Named `technical-design-specialist` (not `tdd-specialist`) to avoid collision with the existing `tdd-subagent` (Test Driven Development) and `tdd-workflow-skill`. Separate subagent is justified by model tier and design-authoring workflow.
3. **Reconcile business-development-primary-agent drift** — `business-development-primary-agent.md` exists in deployed `~/.config/opencode/agents/` but NOT in source `opencode_app/.opencode/agents/`, violating the repo AGENTS.md source-of-truth rule. It will be silently wiped on the next `deploy/setup.sh`. Requires a user decision: bring into source as a distinct agent, or remove as redundant (compare against `startup-founder-primary-agent` and `office-document-primary-agent`).

### Net impact

- **Skills**: +2 (brd-creation-skill, technical-design-creation-skill). **Deployable** count 104 → 106 (total incl `_archived/`: 110 → 112).
- **Agents**: +1 (technical-design-specialist-subagent) + conditional ±1 (business-development — bring into source or remove). **34 → 35 or 36** depending on user decision in Phase 3.

> **Count note (verified):** `ls opencode_app/.opencode/agents/ | wc -l` = 34; `find opencode_app/.opencode/skills -name SKILL.md | wc -l` = 110 total (incl `_archived/`); deployable (excl `_archived/`) = 104. setup.sh/setup.ps1/README banners use the **deployable** number (104→106); any `find` gates use the **total** (110→112).

---

## Dependency & Consumer Map

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---|---|---|---|
| `skills/brd-creation-skill/SKILL.md` | interactive-document-rendering-skill exists (references it) | requirements-specialist-subagent, ticket-creation-subagent (draft-detect + PLAN-link) | high |
| `skills/technical-design-creation-skill/SKILL.md` | interactive-document-rendering-skill exists (references it) | technical-design-specialist-subagent | high |
| `agents/requirements-specialist-subagent.md` (EDIT) | brd-creation-skill exists | Primary agent routing (AGENTS.md) | med |
| `agents/technical-design-specialist-subagent.md` | technical-design-creation-skill + CodeGraph tools exist | Primary agent routing (AGENTS.md), deploy/.AGENTS.md, setup.sh | high |
| `agents/ticket-creation-subagent.md` (EDIT) | brd-creation-skill exists + routing decision | Full-workflow ticket creation (BRD draft detection + PLAN-link) | med |
| `skills/ticket-plan-workflow-skill/SKILL.md` (EDIT) | BRD naming convention finalized | PLAN header generation | low |
| `deploy/.AGENTS.md` (EDIT) | All agent metadata finalized | Primary agent routing table | med |
| `AGENTS.md` (repo) (EDIT) | technical-design-specialist model tier | Model-tier routing | low |
| `deploy/setup.sh` | All agent/skill files finalized | setup.ps1 mirror, deployment | high |
| `deploy/setup.ps1` | setup.sh changes | Windows deployment | med |
| `README.md` | All skills/agents finalized | Documentation consumers | med |

---

## Implementation Phases

### Phase 1: BRD (Phase 2 of document ladder)

- [ ] **1.1** Create `brd-creation-skill`
    - **Why:** BRD is the recognized BA artifact between customer Vision and internal SRS; the document ladder is incomplete without it. BABOK/IIBA defines BRD as the sponsor-level "why" document (business requirements + stakeholder requirements + solution requirements summary + transition requirements).
    - **Done when:** `opencode_app/.opencode/skills/brd-creation-skill/SKILL.md` exists with: BABOK/IIBA BRD template sections (Business Requirements [from sponsor: business problem/opportunity, objectives/success criteria, business value], Stakeholder Requirements [from stakeholders: needs/expectations, stakeholder map], Solution Requirements Summary [high-level capability summary — NOT detailed functional spec], Transition Requirements [data migration, training, organizational change, parallel-run]), `docs/brd/BRD-draft-{slug}.md` → `docs/brd/BRD-{key}.md` naming convention (ticket-linked, like SRS), reference to `interactive-document-rendering-skill` for snapshot HTML+DOCX dual output, no back-compat trigger alias (BRD is new — no "create brd" confusion with prd→srs rename).
    - **Consumers affected:** requirements-specialist-subagent (1.2), ticket-creation-subagent (1.3)

- [ ] **1.2** Wire BRD into `requirements-specialist-subagent`
    - **Why:** BRD + SRS now coexist in one agent (requirements-specialist). Trigger-phrase self-detect (used in BT-72 Phase 1 when only SRS existed) is fragile — both are "requirements" documents and phrase overlap is inevitable. An explicit doc-type routing decision tree prevents mis-routing.
    - **Done when:** `opencode_app/.opencode/agents/requirements-specialist-subagent.md` updated: `skill:` permission block gains `brd-creation-skill: allow`; `steps:` bumped if needed (BRD interview is similar length to SRS interview — +10 steps is a reasonable increment, 40→50); prompt-first workflow gains an **explicit doc-type routing decision tree** defined as: (a) "business requirements" / "stakeholder requirements" / "brd" / "business need" → BRD path; (b) "functional spec" / "software requirements" / "srs" / "create srs" / "specification" / back-compat "create prd" → SRS path; (c) ambiguous or user unsure → ask "Are you looking for a business-level BRD (sponsor/stakeholder scope) or a detailed SRS (functional/technical scope)?" before proceeding. Tree is surfaced early in the workflow (step 1–2), not buried deep.
    - **Consumers affected:** Primary agent routing (no change — still routes to requirements-specialist), users invoking the subagent

- [ ] **1.3** Update consumers for BRD ticket-linkage
    - **Why:** BRD, like SRS, should be draft-detected and PLAN-linked during full-workflow ticket creation. This ensures BRD drafts authored before a ticket exists get properly renamed and tracked (matching the SRS convention established in BT-72 step 3.1).
    - **Done when:** `opencode_app/.opencode/agents/ticket-creation-subagent.md` updated: `skill:` permission block gains `brd-creation-skill: allow`; BRD draft detection added (parallel to SRS detection): scan `docs/brd/BRD-draft-*.md`, rename to `BRD-{ticket-key}.md`, set `BRD_PATH=docs/brd/BRD-{ticket-key}.md`; PLAN header injection: if `BRD_PATH` is set, add `**BRD**: {BRD_PATH}` after the `**SRS**:` line. `PLANS/PLAN-BT-73.md` template demonstrates the header placement. `skills/ticket-plan-workflow-skill/SKILL.md` updated: PLAN header template gains `**BRD**: $BRD_PATH _(optional — present only when a BRD was linked via docs/brd/)_` after the SRS line.
    - **Consumers affected:** Full-workflow ticket creation (BRD draft detection + PLAN linking)

### Phase 2: Technical Design Document (Phase 2 of document ladder)

- [ ] **2.1** Create `technical-design-specialist-subagent`
    - **Why:** The document ladder's engineering "how" stage — converts SRS (functional requirements) into architecture, data model, API contracts, and ADRs. Justified as a separate subagent by model tier (`glm-5.1` sound-reasoning — design authoring needs deeper reasoning than document transcription) and by its design-authoring workflow (CodeGraph impact analysis, architecture pattern evaluation, ADR authoring — not just template fill-in). Name MUST be `technical-design-specialist-subagent` (NOT `tdd-specialist` / `tdd-subagent`) to avoid collision with the existing Test Driven Development subagent and `tdd-workflow-skill`.
    - **Done when:** `opencode_app/.opencode/agents/technical-design-specialist-subagent.md` exists with: `mode: subagent`, `model: zai-coding-plan/glm-5.1` (sound-reasoning tier), `steps: 50` (design-authoring workflow is multi-phase: scope assessment → CodeGraph exploration → architecture decisions → data model → API surface → ADRs → render), Prompt Defense Baseline, description covering triggers ("technical design", "architecture document", "system design", "technical design doc", "design spec", "create technical design"), purpose (engineering "how" stage — produces design artifacts from SRS or feature specs), permission block (`read/edit/glob/grep/bash: allow`; `task: image-analyzer-subagent allow, explore allow, architecture-review-subagent allow, "*": deny`; `skill: technical-design-creation-skill, interactive-document-rendering-skill, clean-architecture-skill, design-patterns-skill, domain-modeling-skill, codegraph-setup-skill, api-design-skill, openapi-contract-adherence-skill: allow`), CodeGraph guidance clause (explicit: prefer `codegraph_explore` for architecture exploration, `codegraph_impact` for change-radius analysis before design decisions, `codegraph_callers`/`codegraph_callees` for dependency tracing), output path `docs/technical-design/`, Return Contract.
    - **Consumers affected:** Primary agent routing (AGENTS.md), setup.sh, deploy/.AGENTS.md

- [ ] **2.2** Create `technical-design-creation-skill`
    - **Why:** Template for the engineering design document — fills the gap between SRS (requirements) and implementation. Without a standardized template, each design doc would be ad-hoc and inconsistent.
    - **Done when:** `opencode_app/.opencode/skills/technical-design-creation-skill/SKILL.md` exists with: TDD template sections (System Context [boundaries, external integrations, deployment context], Architecture [high-level component diagram description, technology stack rationale, layering strategy], Data Model [entities, relationships, schema — notation: Mermaid ERD or similar], API Surface [REST/GraphQL endpoints, event contracts, internal APIs — reference `api-design-skill` for OpenAPI patterns], Architecture Decision Records [ADR format: context → decision → consequences, numbered ADR-NNN], Sequence/Interaction Diagrams [key flows as Mermaid sequences], Non-Functional Design [performance targets, scalability, security, observability — per logging-observability-skill patterns]), `docs/technical-design/TDD-{key}.md` naming convention (ticket-linked), reference to `interactive-document-rendering-skill` for snapshot HTML+DOCX dual output, ADR clause ("ADR-NNN numbering auto-increments; first ADR in a new project starts at ADR-001"), CodeGraph integration clause ("before finalizing architecture, run codegraph_impact against the target codebase to validate assumptions about existing boundaries").
    - **Consumers affected:** technical-design-specialist-subagent (2.1)

- [ ] **2.3** Wire routing for technical-design-specialist
    - **Why:** Primary agent routing tables (AGENTS.md, deploy/.AGENTS.md) must include the new subagent; model-tier lists must place it in the correct tier (glm-5.1, NOT glm-5-turbo).
    - **Done when:** `deploy/.AGENTS.md` routing table gains row: "Technical design / Architecture document | technical-design-specialist-subagent" (sound-reasoning tier). `AGENTS.md` (repo root) model-tier list: `technical-design-specialist` added to the `glm-5.1` row (alongside code-review, architecture-review, python-reviewer, etc.), NOT to the glm-5-turbo row. No edit to deploy/setup.sh listing yet (count changes deferred to Phase 4).
    - **Consumers affected:** Primary agent routing decisions, model-tier assignment

### Phase 3: Reconcile business-development-primary-agent drift

- [ ] **3.1** Investigate the drift — compare `business-development-primary-agent.md` against source agents
    - **Why:** `business-development-primary-agent.md` exists in deployed `~/.config/opencode/agents/` but NOT in source `opencode_app/.opencode/agents/`, violating the repo AGENTS.md source-of-truth rule. It will be silently wiped on the next `deploy/setup.sh`. Leaving it drifts source/deployed state further and masks potential capability gaps.
    - **Done when:** Read `~/.config/opencode/agents/business-development-primary-agent.md` and compare its capabilities (triggers, skills, task permissions) against `startup-founder-primary-agent.md` and `office-document-primary-agent.md` in source. Produce a comparison summary: (a) capabilities unique to business-development (not covered by existing source agents), (b) capabilities fully redundant with existing agents, (c) recommendation: **bring into source** (if unique capabilities exist) OR **remove from deployed** (if fully redundant). Surface this comparison to the user and ask for a decision — do NOT assume.
    - **Consumers affected:** setup.sh/setup.ps1 agent listing, README, AGENTS.md (count changes depend on decision)

- [ ] **3.2** Execute the chosen resolution for business-development-primary-agent
    - **Why:** After the user decides in 3.1, the resolution must be applied and all downstream counts/listings updated consistently. Failure to sync leads to another drift cycle.
    - **Done when:** **If brought into source:** `cp ~/.config/opencode/agents/business-development-primary-agent.md opencode_app/.opencode/agents/business-development-primary-agent.md` + `git add`; verify it does NOT collide with `startup-founder-primary-agent` or `office-document-primary-agent` triggers (update trigger phrases if overlap detected). Agent count target: 34 → 36 (assuming 3.1 recommends "bring into source"). **If removed from deployed:** `rm ~/.config/opencode/agents/business-development-primary-agent.md`; also check `business-ops-primary-agent.md` (also exists in deployed — BT-72 removed from source but the deployed copy may linger) and remove it if still present. Agent count target: 34 → 35. **Both paths** require Phase 4 sync (setup.sh, setup.ps1, README, AGENTS.md counts).
    - **Consumers affected:** setup.sh, setup.ps1, README.md, AGENTS.md, deploy/.AGENTS.md (agent counts/listings)

### Phase 4: Sync Documentation (repo AGENTS.md mandatory sync rule)

- [ ] **4.1** Update `deploy/setup.sh`
    - **Why:** Banner + listing must match deployed files; setup is the deploy entrypoint. Agent and skill counts must be updated to reflect all additions from Phases 1–3.
    - **Done when:** Agent listing updated (+technical-design-specialist-subagent, ±business-development-primary-agent per 3.2 decision). Skill listing updated (+brd-creation-skill, +technical-design-creation-skill). Skill COUNT headers: `SKILLS (104):` → `SKILLS (106):` (deployable count). Agent COUNT headers reconciled to authoritative `ls | wc -l` — 35 or 36 per Phase 3 decision. All "N more" secondary counts recomputed so inline-listed + more = total.
    - **Consumers affected:** Anyone running setup.sh / --help

- [ ] **4.2** Mirror all setup.sh changes in `deploy/setup.ps1`
    - **Why:** Windows parity — setup.ps1 must match setup.sh exactly.
    - **Done when:** All changes from 4.1 mirrored in PowerShell syntax. Skill COUNT headers: `SKILLS (104):` → `SKILLS (106):`. Agent count reconciled to match setup.sh (35 or 36).
    - **Consumers affected:** Windows users

- [ ] **4.3** Update `README.md`
    - **Why:** README is primary docs; must reflect new agent(s) + 2 skills.
    - **Done when:** Skill table gains `brd-creation-skill` + `technical-design-creation-skill` rows; recount Framework/Document skills (deployable 104→106). Subagent table gains `technical-design-specialist-subagent` row; if business-development brought into source, also add `business-development-primary-agent` row to the `*-primary-agent` note (currently 2 hubs; becomes 3). Stale totals corrected if any.
    - **Consumers affected:** Documentation readers

- [ ] **4.4** Update `AGENTS.md` (repo root)
    - **Why:** Model-tier list must include technical-design-specialist in the correct tier (glm-5.1); any agent count references must be accurate.
    - **Done when:** Step 2.3 already adds `technical-design-specialist` to the glm-5.1 row. If any other agent-count or skill-count mentions exist, update them. Grep to verify no stale references remain.
    - **Consumers affected:** Model-tier assignment

- [ ] **4.5** Update `deploy/.AGENTS.md`
    - **Why:** Routing table must include new agent; skill counts should be accurate.
    - **Done when:** Step 2.3 already adds the routing row. Grep for any stale skill/agent count references and update if found.
    - **Consumers affected:** Primary agent routing table

- [ ] **4.6** Verify/update `opencode_app/README.md`
    - **Why:** Docker docs may reference agent/skill counts; must not break.
    - **Done when:** Grep `opencode_app/README.md` for stale agent/skill counts. If found, update to match source `ls | wc -l` and `find | wc -l`. If absent, no-op.
    - **Consumers affected:** Docker users

### Phase 5: Verification

- [ ] **5.1** Grep-confirm zero stale or inconsistent references in source
    - **Why:** Any leftover pre-BT-73 references or count mismatches will confuse users and break deploy verification. This ticket adds "BRD" and "technical-design" as new terms — must not create collisions.
    - **Done when:** `grep -rn "tdd-specialist\|tdd-creation-skill" opencode_app/ deploy/ README.md AGENTS.md` returns zero matches in new file contexts (existing `tdd-subagent.md` / `tdd-workflow-skill` references are fine — those are Test Driven Development). All agent/skill counts in setup.sh, setup.ps1, README.md, opencode_app/README.md are mutually consistent (deployable vs total distinguished correctly).
    - **Consumers affected:** All consumers (correctness gate)

- [ ] **5.2** Verify agent/skill counts are internally consistent
    - **Why:** Inconsistent counts between setup.sh banner, README tables, and actual files confuse users and break deploy verification.
    - **Done when:** `ls opencode_app/.opencode/agents/ | wc -l` == 35 or 36 (per Phase 3 decision); TOTAL `find opencode_app/.opencode/skills -name SKILL.md | wc -l` == 112 (incl `_archived/`); DEPLOYABLE `find opencode_app/.opencode/skills -name SKILL.md -not -path '*/_archived/*' | wc -l` == 106; setup.sh + setup.ps1 + README banners show 106 (deployable).
    - **Consumers affected:** All deployment consumers

- [ ] **5.3** Run `documentation-sync-workflow` skill (or delegate to opencode-tooling-subagent)
    - **Why:** Repo AGENTS.md mandates doc sync after skill/agent changes; validates cross-file count consistency.
    - **Done when:** Skill confirms setup.sh, setup.ps1, README, AGENTS.md counts/listings are mutually consistent.
    - **Consumers affected:** Documentation integrity

- [ ] **5.4** Validate `brd-creation-skill` and `technical-design-creation-skill` structure
    - **Why:** Malformed skill templates will silently break the subagent workflows. Count/stale-ref checks don't catch structural issues.
    - **Done when:** `opencode_app/.opencode/skills/brd-creation-skill/SKILL.md` contains complete BABOK sections (Business Requirements, Stakeholder Requirements, Solution Requirements Summary, Transition Requirements) with `docs/brd/` naming convention and rendering-skill reference. `opencode_app/.opencode/skills/technical-design-creation-skill/SKILL.md` contains complete TDD template (System Context, Architecture, Data Model, API Surface, ADRs, Sequence Diagrams, Non-Functional Design) with `docs/technical-design/` naming convention, CodeGraph integration clause, and rendering-skill reference. No placeholder TODOs remain in either.
    - **Consumers affected:** requirements-specialist, technical-design-specialist (all skill output)

---

## Acceptance Criteria

- [ ] `brd-creation-skill/` exists (BABOK/IIBA BRD template, `docs/brd/BRD-draft-{slug}.md` → `BRD-{key}.md`, rendering-skill reference)
- [ ] `requirements-specialist-subagent.md` has `brd-creation-skill: allow`, doc-type routing decision tree (BRD vs SRS), bumped steps
- [ ] `ticket-creation-subagent.md` has BRD draft detection + PLAN-link (`BRD_PATH`, `**BRD**:`)
- [ ] `ticket-plan-workflow-skill/SKILL.md` has `**BRD**: $BRD_PATH` in PLAN header template
- [ ] `technical-design-specialist-subagent.md` exists (glm-5.1, steps: 50, CodeGraph guidance clause, design-authoring workflow, NOT named tdd-specialist)
- [ ] `technical-design-creation-skill/` exists (TDD template with ADR, data model, API surface, rendering-skill reference, CodeGraph integration clause)
- [ ] `deploy/.AGENTS.md` routing table has technical-design-specialist row; `AGENTS.md` model-tier has it in glm-5.1 row
- [ ] business-development-primary-agent drift reconciled (source and deployed state consistent per user decision in 3.1)
- [ ] README.md, AGENTS.md, deploy/.AGENTS.md, setup.sh, setup.ps1 reflect all additions (agents: 35 or 36 / 106 deployable skills / 112 total skills)
- [ ] Zero stale "tdd-specialist" / "tdd-creation-skill" references (excluding existing tdd-subagent/tdd-workflow-skill — Test Driven Development)
- [ ] `documentation-sync-workflow` validation passes
- [ ] Both new skills structurally valid (step 5.4)

---

## Risks & Mitigation

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| BRD + SRS routing ambiguity causes mis-routing | med | high | Step 1.2 defines explicit decision tree with disambiguation fallback; tested against common trigger phrases |
| `tdd-specialist` name collision with existing `tdd-subagent` (TDD) | high | high | Step 2.1 explicitly uses `technical-design-specialist-subagent`; step 5.1 greps for the collision name |
| technical-design-specialist at glm-5.1 adds cost vs. glm-5-turbo | med | med | Model tier is intentional — design authoring requires deeper reasoning; justified in step 2.1 rationale |
| business-development-primary-agent drift resolution stalls on user decision | med | med | Step 3.1 surfaces comparison + explicit question; Phase 4 count updates are parameterized (35 or 36) |
| setup.sh line numbers drift during editing | high | med | Use string matching for edits, not line numbers; re-grep after each change |
| Deployable vs total skill counts conflated in banners | med | high | Steps 4.1/4.2 set banner to 106 (deployable); step 5.2 checks BOTH total==112 AND deployable==106 |
| BRD is overkill for small projects (only need SRS) | low | low | Routing tree gives users explicit choice; SRS-only path unchanged from BT-72 |

---

## Technical Notes

- All source-of-truth edits go in `opencode_app/.opencode/` (repo AGENTS.md rule); **never** edit deployed `~/.config/opencode/` copies — redeploy handles those
- `technical-design-specialist-subagent` is the FIRST subagent at `glm-5.1` that is NOT a reviewer (code-review, architecture-review, language-reviewers are all reviewers). This is justified: design **authoring** requires the same depth as design **review**.
- The BRD→SRS→TDD flow maps to BABOK's Knowledge Area progression (Business Analysis → Requirements Analysis → Solution Evaluation/Design), providing an industry-standard document ladder.
- BRD draft detection in ticket-creation-subagent follows the exact same pattern as SRS draft detection (scan `docs/brd/BRD-draft-*.md`, rename to `BRD-{key}.md`, set BRD_PATH).
- `interactive-document-rendering-skill` is referenced by both new skills for dual output (HTML+DOCX). No changes to the rendering skill itself are needed.
- **Migration note:** Projects with pre-existing `docs/prd/` files should have already migrated to `docs/srs/` per BT-72. No additional migration is needed for this ticket.
- **Step-budget rationale:** technical-design-specialist=50 (design-authoring requires scope assessment + CodeGraph exploration + architecture decisions + data model + API surface + ADRs + render — comparable to code-review complexity which uses the same tier).
- Phase 3 is a **user-decision gate** — implementation of 3.2 and Phase 4 counts depend on the outcome of 3.1.

---

*Created by ticket-creation-subagent full workflow — BT-73.*
