# PLAN: Add `prd-creation-skill` and `prd-specialist-subagent` with PLAN linkage

**Issue**: [#223 — feat: add prd-creation-skill and prd-specialist-subagent with PLAN linkage](https://github.com/darellchua2/opencode-config-template/issues/223)
**Branch**: `issue-223`
**Status**: Draft
**PRD**: None (this issue creates the PRD tooling itself — no PRD precedes it)

---

## Summary

Introduce an industry-standard Product Requirement Document (PRD) workflow that precedes ticket creation and feeds into the PLAN file. This creates two new artifacts: (1) `prd-creation-skill` holding the PRD template/workflow knowledge, and (2) `prd-specialist-subagent` that conducts a discovery interview and drafts the PRD. The existing `ticket-creation-subagent` is extended to auto-detect draft PRDs in `docs/prd/`, rename them to the ticket key, inject a `**PRD**:` reference into the PLAN header, and commit both files together. This strengthens the planning stage by separating product requirements (PRD) from implementation phases (PLAN).

Additionally, `image-analyzer-subagent` is reframed as a **shared utility** — its `permission.task` access is granted to deny-by-default subagents that need image interpretation (`testing-subagent`, `code-review-subagent`, `architecture-review-subagent`, `pr-workflow-subagent`, `ticket-creation-subagent`, `opencode-tooling-subagent`) so they can delegate image analysis directly without routing through the primary agent.

### Confirmed Design Decisions (from issue #223 scoping)

| Decision | Choice | Rationale |
|----------|--------|-----------|
| PRD file location | `docs/prd/` (NOT `PRDS/`) | Spec documents, not acronyms |
| Draft naming | `docs/prd/PRD-draft-{kebab-slug}.md` | Distinguishes from finalized PRDs |
| Final naming | `docs/prd/PRD-{ticket-key}.md` (via `git mv`) | Preserves git history on rename |
| Skill category | Framework (14→15) | Alongside `api-design-skill`, `docx-creation`, `frontend-design` |
| Skill + Subagent split | Both created | Mirrors `ticket-plan-workflow-skill` + `ticket-creation-subagent` |
| ticket-creation integration | Auto-detect + rename + PLAN header inject | Seamless PRD→PLAN linkage |
| PRD sections | 14 Core (always) + 3 Optional (prompted) | Comprehensive yet flexible |
| Model tier | `zai-coding-plan/glm-5-turbo` | Document-creation/coordination tier per AGENTS.md |
| image-analyzer sharing | Reframe as shared utility + grant task access to 6 subagents | Currently only reachable by primary agent + ~11 default-allow agents; deny-by-default subagents (testing, code-review, architecture-review, pr-workflow, ticket-creation, opencode-tooling) are blocked despite clear image interpretation needs |

### Architecture

```
User trigger ("create prd", "product requirement", "feature spec")
  → Primary agent delegates to prd-specialist-subagent
  → Subagent loads prd-creation-skill
  → Discovery interview (prompt-first, confirm each section)
  → Draft written to docs/prd/PRD-draft-{slug}.md
  → User later triggers ticket-creation-subagent (Full workflow)
  → Auto-detect PRD-draft-*.md → prompt user to link
  → git mv → PRD-{ticket-key}.md
  → PLAN header gains **PRD**: docs/prd/PRD-{key}.md
  → Commit both PRD + PLAN
```

---

## Dependency & Consumer Map

| Node | Depends on | Consumers | Risk |
|------|-----------|-----------|------|
| `prd-creation-skill/SKILL.md` | — | `prd-specialist-subagent`, `ticket-creation-subagent` (linkage convention), deploy scripts, README | medium |
| `prd-specialist-subagent.md` | `prd-creation-skill` exists | build/plan primary agent, README subagents table, deploy scripts, `deploy/.AGENTS.md` routing | medium |
| `ticket-creation-subagent.md` (update) | Phase 1+2 done (to reference skill/subagent) | All ticket-creation invocations | medium |
| `ticket-plan-workflow-skill/SKILL.md` (update) | Phase 3 ticket-creation changes | `ticket-creation-subagent` | low |
| `deploy/setup.sh` + `setup.ps1` | Phase 1 (skill exists) before incrementing | All deploy users | low |
| `README.md` + `opencode_app/README.md` | Phase 1+2 | Repo readers | low |
| `deploy/.AGENTS.md` + repo `AGENTS.md` | Phase 2 (subagent exists) | Primary agent routing | low |
| `image-analyzer-subagent.md` (reframe) | — | All subagents granted task access in Phase 3; primary agent; `deploy/.AGENTS.md` routing | low |
| 6 subagent `.md` files (permission update) | `image-analyzer-subagent` exists (already does) | Each updated subagent gains image interpretation capability | low |

---

## Pre-existing Count Drift

**Verified at PLAN authoring time (2026-06-21):**
- Declared skill count: **82**
- Actual skill directories (excluding `_archived/` and `scripts/`): **81**
- PLAN-GIT-221 (openapi-contract-adherence-skill) is "In Progress" — if it merges first, actual becomes 82 before this work
- **Implementation rule**: Use verification commands (`ls -d opencode_app/.opencode/skills/*/ | grep -vE "_archived|scripts" | wc -l`) rather than hardcoded numbers. After adding `prd-creation-skill`, the new actual = old actual + 1. Sync declared counts to that value.

---

## Implementation Phases

### Phase 0: Pre-flight Verification

- [ ] **0.1** Verify no skill named `prd-creation-skill` already exists in `opencode_app/.opencode/skills/`
    — **Why:** Prevents clobbering or accidental duplicate creation.
    — **Done when:** `ls opencode_app/.opencode/skills/ | grep prd-creation` returns nothing.
    — **Consumers affected:** All downstream phases.

- [ ] **0.2** Verify no agent named `prd-specialist-subagent` already exists in `opencode_app/.opencode/agents/`
    — **Why:** Prevents clobbering or accidental duplicate creation.
    — **Done when:** `ls opencode_app/.opencode/agents/ | grep prd-specialist` returns nothing.
    — **Consumers affected:** All downstream phases.

- [ ] **0.3** Confirm skill name `prd-creation-skill` matches `^[a-z][a-z0-9-]{0,63}$` (OpenCode naming rule)
    — **Why:** Invalid names break `opencode` skill loading.
    — **Done when:** Name validates against the regex.
    — **Consumers affected:** Skill loader.

- [ ] **0.4** Verify current actual skill directory count: run `ls -d opencode_app/.opencode/skills/*/ | grep -vE "_archived|scripts" | wc -l` and record the result. Also run `ls opencode_app/.opencode/agents/*.md | wc -l` for agent count. Record both in PLAN Phase 4 subtasks so the implementer uses live counts, not stale numbers.
    — **Why:** Pre-existing drift (declared 82, actual 81) means hardcoded counts are unreliable. PLAN-GIT-221 may merge first, changing the actual count. The implementer must use verification commands at execution time.
    — **Done when:** Both commands executed and results recorded; Phase 4 subtasks reference "verify live count" not a hardcoded number.
    — **Consumers affected:** Phase 4 documentation sync.

- [ ] **0.5** Confirm the new skill belongs in the **Framework** category. Current Framework listing location in `deploy/setup.sh`, `deploy/setup.ps1`, and `README.md`. Count goes from current-value → current-value + 1.
    — **Why:** Keeps document/spec-creation skills colocated in Framework. `api-design-skill`, `docx-creation-skill`, `frontend-design-skill` are all Framework.
    — **Done when:** Category decision documented; all three target files identified for count update.
    — **Consumers affected:** Phase 4 category updates.

---

### Phase 1: Create `prd-creation-skill`

- [ ] **1.1** Create directory `opencode_app/.opencode/skills/prd-creation-skill/` and `SKILL.md` with YAML frontmatter:
    - `name: prd-creation-skill`
    - `description:` Include trigger phrases: "Create, draft, and review Product Requirement Documents (PRDs) with industry-standard sections. Triggers on: create prd, product requirement, feature spec, write prd, product doc, PRD."
    - `license: Apache-2.0`
    - `compatibility: opencode`
    - `metadata.audience: developers, product managers, agents`
    - `metadata.workflow: product-planning, documentation`
    - `metadata.trigger: explicit-only`
    - `metadata.languages: [markdown]`
    — **Why:** Establishes the skill as a first-class library member with metadata that deploy scripts can ingest. Trigger phrases enable skill discovery.
    — **Done when:** Directory exists and SKILL.md frontmatter parses as valid YAML (test with `python -c "import yaml; yaml.safe_load(open('...').read().split('---')[1])"`).
    — **Consumers affected:** `prd-specialist-subagent`, deploy scripts, README.

- [ ] **1.2** Author **"What I do"** section describing: PRD template with 14 core sections, 3 optional sections with prompt-first inclusion, `docs/prd/` naming convention (draft vs final), PLAN back-linkage, and discovery interview workflow.
    — **Why:** Mirrors structure of other Framework skills for consistency; gives agents a quick capability summary.
    — **Done when:** Section present with the 5 capabilities in one-line bullets.
    — **Consumers affected:** Skill selection logic.

- [ ] **1.3** Author **"When to use me"** section with trigger phrases:
    - "create prd"
    - "product requirement"
    - "feature spec"
    - "write prd"
    - "product doc"
    - "PRD"
    — **Why:** Explicit-only trigger means skill selection depends on phrase matching; comprehensive phrases improve recall.
    — **Done when:** Section lists at least the 6 trigger phrases above.
    — **Consumers affected:** Primary agent skill loader.

- [ ] **1.4** Author **"PRD Template"** section documenting the file structure with all **14 Core sections** (always present):
    1. Problem Statement
    2. Background/Context
    3. Goals & Non-Goals
    4. User Personas
    5. User Stories/Jobs-to-be-Done
    6. Functional Requirements
    7. Non-Functional Requirements
    8. Success Metrics
    9. Scope In/Out
    10. Acceptance Criteria
    11. Risks & Dependencies
    12. Open Questions
    13. Timeline/Milestones
    14. References
    Each section must include: section heading, purpose description, template placeholders, and a worked example (at minimum for Problem Statement and Functional Requirements).
    — **Why:** The 14 sections form the industry-standard PRD backbone. Without a complete template, agents cannot produce consistent PRDs.
    — **Done when:** All 14 core sections documented with heading, purpose, template placeholder, and at least 2 sections have worked examples.
    — **Consumers affected:** `prd-specialist-subagent` (uses template to draft PRDs).

- [ ] **1.5** Author **"Optional Sections"** subsection documenting the 3 optional sections with prompt-first inclusion logic:
    - **UX/Design** — wireframes, user flows, design system alignment
    - **Technical Architecture** — system diagram, component interaction, data model, API surface
    - **Go-to-Market** — launch plan, pricing, competitive analysis, marketing channels
    For each: describe when to include it, what it contains, and the prompt-first flow ("Would you like to add the [Section Name] section? It covers [brief description].").
    — **Why:** Not all PRDs need UX/Architecture/GTM sections. Prompt-first inclusion prevents bloated PRDs for simple features while offering depth for complex ones.
    — **Done when:** All 3 optional sections documented with inclusion criteria, content description, and prompt-first inclusion text.
    — **Consumers affected:** `prd-specialist-subagent` (prompts user about optional sections).

- [ ] **1.6** Author **"docs/prd/ Naming Convention"** section:
    - Draft: `docs/prd/PRD-draft-{kebab-slug}.md` (slug derived from title, e.g., "User Authentication" → `user-authentication`)
    - Final: `docs/prd/PRD-{ticket-key}.md` (renamed via `git mv` after ticket creation)
    - PLAN back-link placeholder in PRD: `**PLAN**: PLANS/PLAN-{key}.md`
    - PRD reference in PLAN header: `**PRD**: docs/prd/PRD-{key}.md`
    — **Why:** Consistent naming enables `ticket-creation-subagent` to auto-detect draft PRDs and rename them. The bidirectional link (PRDPLAN) maintains traceability.
    — **Done when:** Section documents both naming conventions, the `git mv` rename step, and bidirectional link syntax.
    — **Consumers affected:** `ticket-creation-subagent` (auto-detect and rename), `prd-specialist-subagent` (file naming).

- [ ] **1.7** Author **"Discovery Interview Workflow"** section describing the prompt-first flow for gathering PRD content:
    - Ask for title/overview first
    - Iterate through core sections (confirm before moving to next)
    - After core sections complete, prompt for each optional section individually
    - Confirm full PRD summary before writing file
    — **Why:** Prompt-first prevents agents from hallucinating product requirements. Each section requires explicit user confirmation.
    — **Done when:** Workflow documented with step-by-step prompt sequence and example user interactions.
    — **Consumers affected:** `prd-specialist-subagent` (implements the workflow).

- [ ] **1.8** Author **Return Contract** section following repo convention:
    ```
    **Status:** [success | partial | failed]
    **Output:** docs/prd/PRD-draft-{slug}.md
    **Summary:** PRD created with N core sections and M optional sections in docs/prd/
    **Issues:** [blockers or "None"]
    ```
    — **Why:** All repo skills must follow the standardized Return Contract per AGENTS.md.
    — **Done when:** Section present with the four-line format.
    — **Consumers affected:** Primary agent (parses return).

- [ ] **1.9** Author **Related Skills** section linking to:
    - `ticket-plan-workflow-skill` (downstream consumer — PRD feeds into PLAN)
    - `ticket-creation-subagent` (auto-detects draft PRDs during Full workflow)
    - `api-design-skill` (API requirements often surface in PRD Functional Requirements)
    - `verification-loop-skill` (acceptance criteria alignment between PRD and implementation)
    - `docx-creation-skill` (PRD may be exported to Word format)
    — **Why:** Discoverability and routing hints for the primary agent. Cross-references prevent skills from evolving in isolation.
    — **Done when:** Section lists all 5 related skills with one-line descriptions of the relationship.
    — **Consumers affected:** Primary agent routing.

---

### Phase 2: Create `prd-specialist-subagent`

- [ ] **2.1** Create `opencode_app/.opencode/agents/prd-specialist-subagent.md` with YAML frontmatter:
    - `mode: subagent`
    - `model: zai-coding-plan/glm-5-turbo` (document-creation/coordination tier — NOT glm-5.2 primary-session only, NOT glm-5.1 correctness-critical)
    - `permission.task: { "*": deny, explore: allow }` (can spawn explore agent for codebase context research, but cannot chain to other specialists)
    - `description:` Include trigger phrases and purpose
    — **Why:** Establishes the subagent as a specialist with the correct model tier and restricted permissions. The extract-then-delegate pattern means the primary agent delegates to this subagent, and the subagent does NOT chain to other specialists.
    — **Done when:** File exists with valid frontmatter; model is `glm-5-turbo`; permission denies all except `explore`.
    — **Consumers affected:** Primary agent (spawns this subagent), deploy scripts.

- [ ] **2.2** Author **trigger phrases** section in the subagent:
    - "create prd"
    - "product requirement"
    - "feature spec"
    - "write prd"
    - "product doc"
    - "draft a prd"
    — **Why:** Primary agent matches trigger phrases to decide when to delegate. Phrases must overlap with `prd-creation-skill` triggers.
    — **Done when:** At least 6 trigger phrases documented.
    — **Consumers affected:** Primary agent routing.

- [ ] **2.3** Author **"Delegation Instructions"** section specifying:
    - Primary agent loads `prd-creation-skill` first (extract-then-delegate pattern)
    - Primary agent passes: title/overview (if user provided), target directory, optional-section preferences
    - Subagent conducts discovery interview following `prd-creation-skill` workflow
    - Subagent writes draft PRD to `docs/prd/PRD-draft-{slug}.md`
    - Subagent returns Return Contract with file path
    — **Why:** Extract-then-delegate pattern keeps heavy knowledge in the primary agent's context (which compacts) rather than the subagent's isolated context.
    — **Done when:** Section documents the delegation flow with input parameters and output contract.
    — **Consumers affected:** Primary agent (knows what to pass).

- [ ] **2.4** Author **prompt-first behavior** section mirroring `ticket-creation-subagent`:
    - Confirm title/overview before proceeding
    - Confirm each core section before moving to next
    - Prompt for each optional section individually ("Adding this section?")
    - Confirm full PRD summary before writing file
    - Show the user what will be written and ask "Proceed?"
    — **Why:** Prompt-first prevents hallucinating product requirements. Matches the repo's established pattern from `ticket-creation-subagent`.
    — **Done when:** Prompt-first rules documented with example interaction flow.
    — **Consumers affected:** End users (experience consistent prompting behavior).

- [ ] **2.5** Author **Return Contract** section following repo convention:
    ```
    **Status:** [success | partial | failed]
    **Output:** docs/prd/PRD-draft-{slug}.md
    **Summary:** PRD drafted with N core and M optional sections; written to docs/prd/
    **Issues:** [blockers or "None"]
    ```
    — **Why:** All repo subagents must follow the standardized Return Contract per AGENTS.md.
    — **Done when:** Section present with the four-line format.
    — **Consumers affected:** Primary agent (parses return).

---

### Phase 3: Integration — Update Existing Files

- [ ] **3.1** Update `opencode_app/.opencode/agents/ticket-creation-subagent.md` **Step 3** (Full Workflow branch/PLAN phase) with PRD auto-detect logic:
    1. After branch creation and before PLAN generation, scan for draft PRDs: `ls docs/prd/PRD-draft-*.md 2>/dev/null`
    2. If drafts found, prompt user: "Found draft PRD(s): [list]. Link to this ticket?"
    3. If user confirms: `git mv docs/prd/PRD-draft-{slug}.md docs/prd/PRD-{ticket-key}.md`
    4. If draft was never committed (on new branch): plain `mv` + `git add`
    5. Add `**PRD**: docs/prd/PRD-{ticket-key}.md` to the PLAN header
    6. After PLAN commit, commit both PRD + PLAN together (or amend)
    — **Why:** Seamless PRD→PLAN linkage. The `git mv` preserves history. If no PRD exists, steps 1-6 are silently skipped (pure additive, backward-compatible).
    — **Done when:** Step 3 of ticket-creation-subagent.md includes the 6-step PRD detection/rename/inject/commit sequence with examples for both `git mv` (committed) and `mv` + `git add` (uncommitted) cases.
    — **Consumers affected:** All Full workflow ticket-creation invocations.

- [ ] **3.2** Update `opencode_app/.opencode/agents/ticket-creation-subagent.md` skills list to include `prd-creation-skill` and update examples to show PRD-linked workflow.
    — **Why:** Skill references must be complete for agents that use them.
    — **Done when:** `prd-creation-skill` appears in the skills reference section; at least one example shows the PRD-linked Full workflow path.
    — **Consumers affected:** Agent documentation accuracy.

- [ ] **3.3** Update `opencode_app/.opencode/agents/ticket-creation-subagent.md` Return Contract to include optional `PRD` field:
    ```
    **PRD:** docs/prd/PRD-{key}.md (present when PRD was linked)
    ```
    — **Why:** Consumers (plan-updater, primary agent) need to know whether a PRD exists for this ticket.
    — **Done when:** Optional `PRD` field documented in Return Contract.
    — **Consumers affected:** Primary agent, plan-updater-skill.

- [ ] **3.4** Update `opencode_app/.opencode/skills/ticket-plan-workflow-skill/SKILL.md` PLAN template to include optional `**PRD**:` field in the header block:
    ```markdown
    **PRD**: docs/prd/PRD-{ticket-key}.md  (optional — present when PRD was linked)
    ```
    — **Why:** Maintains bidirectional traceability. When a PRD exists, the PLAN header links to it; the PRD's footer links back to the PLAN.
    — **Done when:** PLAN template has the optional `**PRD**:` field with a comment noting it's optional.
    — **Consumers affected:** `ticket-creation-subagent` (injects the field), PLAN readers.

---

### Phase 3b: Image-Analyzer Shared Utility

> **Why this phase exists:** `image-analyzer-subagent` (vision model `glm-5v-turbo`) interprets images and returns structured results. Currently it's a leaf node reachable only by the primary agent and ~11 default-allow subagents. Six deny-by-default subagents have clear, recurring image interpretation needs but are blocked by `task: { "*": deny }`. This phase reframes the subagent as a shared utility and grants access to those subagents.

- [ ] **3.5** Update `opencode_app/.opencode/agents/image-analyzer-subagent.md` description and intro to reframe as a **shared utility**:
    - Update `description:` frontmatter to clarify it serves both the primary agent AND other subagents (e.g., "Shared image analysis utility for all agents. Accepts image/video paths or URLs, interprets content, and returns structured results. Used by primary agent directly and delegable by subagents with task permission.")
    - Add a **"Shared Utility"** note after the Prompt Defense Baseline: "This subagent is a shared leaf-node utility. Other subagents delegate image paths/URLs and receive structured analysis (Analysis Type, Description, Key Findings, Confidence, Recommended Actions). It does NOT chain further — it interprets and returns."
    — **Why:** Clarifies the subagent's role as a callable service (interpret → return) rather than a standalone specialist. Sets expectations for calling subagents: pass image, get analysis back.
    — **Done when:** Description updated; "Shared Utility" note present; core functionality (tool selection, structured output, confidence scoring) unchanged.
    — **Consumers affected:** All subagents granted access in steps 3.6-3.11; primary agent.

- [ ] **3.6** Add `image-analyzer-subagent: allow` to `testing-subagent.md` `permission.task` block (after existing `loop-operator-subagent: allow` line).
    — **Why:** `testing-subagent` needs to verify UI screenshots against expected output, compare before/after renders in visual regression tests, and interpret test failure screenshots.
    — **Done when:** `image-analyzer-subagent: allow` present in `testing-subagent.md` task permissions; YAML still valid.
    — **Consumers affected:** `testing-subagent` (gains image interpretation capability).

- [ ] **3.7** Add `image-analyzer-subagent: allow` to `code-review-subagent.md` `permission.task` block (after existing `rust-reviewer-subagent: allow` line).
    — **Why:** `code-review-subagent` benefits from interpreting UI screenshots alongside code changes (e.g., "does this PR's rendered output match the design?") and reading error screenshots referenced in code comments.
    — **Done when:** `image-analyzer-subagent: allow` present in `code-review-subagent.md` task permissions; YAML still valid.
    — **Consumers affected:** `code-review-subagent` (gains image interpretation capability).

- [ ] **3.8** Add `image-analyzer-subagent: allow` to `architecture-review-subagent.md` `permission.task` block (after existing `explore: allow` line).
    — **Why:** `architecture-review-subagent` needs to interpret architecture diagrams, flowcharts, UML, ER diagrams, and system design visuals that are often provided as images rather than code.
    — **Done when:** `image-analyzer-subagent: allow` present in `architecture-review-subagent.md` task permissions; YAML still valid.
    — **Consumers affected:** `architecture-review-subagent` (gains diagram interpretation capability).

- [ ] **3.9** Add `image-analyzer-subagent: allow` to `pr-workflow-subagent.md` `permission.task` block (after the last existing allow entry).
    — **Why:** `pr-workflow-subagent` can analyze visual diffs when PRs include UI changes — comparing expected vs actual screenshots to inform review quality.
    — **Done when:** `image-analyzer-subagent: allow` present in `pr-workflow-subagent.md` task permissions; YAML still valid.
    — **Consumers affected:** `pr-workflow-subagent` (gains visual diff capability).

- [ ] **3.10** Add `image-analyzer-subagent: allow` to `ticket-creation-subagent.md` `permission.task` block (file already modified in steps 3.1-3.3 for PRD work — add after existing allow entries).
    — **Why:** `ticket-creation-subagent` benefits from interpreting bug report screenshots — when a user provides a screenshot of a bug, the subagent can use image-analyzer to extract the error text and UI context for the ticket description.
    — **Done when:** `image-analyzer-subagent: allow` present in `ticket-creation-subagent.md` task permissions; YAML still valid; no conflict with PRD-related edits from 3.1-3.3.
    — **Consumers affected:** `ticket-creation-subagent` (gains screenshot interpretation capability).

- [ ] **3.11** Add `image-analyzer-subagent: allow` to `opencode-tooling-subagent.md` `permission.task` block (after existing allow entries).
    — **Why:** `opencode-tooling-subagent` reviews agent/skill configurations and may need to interpret architecture diagrams, workflow diagrams, or mermaid renderings referenced in PLAN files or documentation.
    — **Done when:** `image-analyzer-subagent: allow` present in `opencode-tooling-subagent.md` task permissions; YAML still valid.
    — **Consumers affected:** `opencode-tooling-subagent` (gains diagram interpretation capability).

- [ ] **3.12** Update `deploy/.AGENTS.md` MCP Tool Routing table row for Image/video analysis:
    - Current: `| Image/video analysis | image-analyzer-subagent | — | Scoped to subagent with zai-vision-mcp-server tools |`
    - Updated: Add note that it's a **shared leaf-node utility** accessible by designated subagents (testing, code-review, architecture-review, pr-workflow, ticket-creation, opencode-tooling) via `permission.task`
    — **Why:** Without documenting the sharing model, future agents won't know image-analyzer is delegable by subagents — they'll assume it's primary-agent-only.
    — **Done when:** Routing table row updated to note shared utility status and list delegating subagents.
    — **Consumers affected:** Primary agent routing; all agents reading deploy/.AGENTS.md.

---

### Phase 4: Documentation Sync (MANDATORY per AGENTS.md)

> **Why non-negotiable:** AGENTS.md mandates lockstep updates across 5+ files when adding a skill AND a subagent.

- [ ] **4.1** Verify live counts before making any changes:
    ```bash
    # Skill count (excluding _archived/ and scripts/)
    ls -d opencode_app/.opencode/skills/*/ | grep -vE "_archived|scripts" | wc -l
    # Agent count
    ls opencode_app/.opencode/agents/*.md | wc -l
    # SKILL.md count (sanity)
    find opencode_app/.opencode/skills -name SKILL.md -not -path "*_archived*" | wc -l
    ```
    Record results. All subsequent subtasks use `actual + 1` as the new declared count.
    — **Why:** Pre-existing drift means declared (82) ≠ actual (81). PLAN-GIT-221 may merge first, changing actual to 82. Hardcoded counts would introduce new drift.
    — **Done when:** All three commands executed; results recorded; Phase 4 subtasks reference "actual + 1" not hardcoded numbers.
    — **Consumers affected:** All Phase 4 sync subtasks.

- [ ] **4.2** Update `deploy/setup.sh`:
    - Banner section: total skill count → actual + 1 (verify line), Framework count → current + 1, append `prd-creation-skill` to Framework listing
    - Status section: matching Framework count → current + 1, matching total → actual + 1
    - Agent section: total agent count → actual + 1 (verify line), append `prd-specialist-subagent` to agent help listing
    — **Why:** Per AGENTS.md sync rules. Both banner AND status sections must agree.
    — **Done when:** All locations updated; `Framework` count consistent across banner and status; total skill count matches `actual + 1`; agent count matches `actual + 1`; skill listed in Framework; agent listed in help text.
    — **Consumers affected:** All `./deploy/setup.sh` users.

- [ ] **4.3** Update `deploy/setup.ps1` (mirror of 4.2):
    - Mirror every change from 4.2 for Windows parity
    — **Why:** Windows deploy parity. setup.ps1 must match setup.sh exactly.
    — **Done when:** All locations match setup.sh; counts identical.
    — **Consumers affected:** All `./deploy/setup.ps1` users.

- [ ] **4.4** Update `README.md`:
    - Skill Categories table: Framework count → current + 1, total → actual + 1, `prd-creation-skill` appended to Framework cell
    - Subagents table: `prd-specialist-subagent` row added (model: `glm-5-turbo`, purpose: PRD discovery interview and drafting)
    - Any agent count references (e.g., "34 subagent .md files" → actual + 1)
    — **Why:** Discoverability for repo consumers. Both tables must reflect the new additions.
    — **Done when:** Framework cell updated; new subagent row added; all count references updated.
    — **Consumers affected:** Anyone reading README.

- [ ] **4.5** Update `opencode_app/README.md`:
    - Directory structure count: skill directories → actual + 1, agent .md files → actual + 1
    — **Why:** Docker-mode consumers rely on the directory tree for count accuracy.
    — **Done when:** Both directory counts updated to actual + 1.
    — **Consumers affected:** Docker-mode consumers.

- [ ] **4.6** Update `deploy/.AGENTS.md`:
    - Subagent Routing Preferences: add row for PRD creation → `prd-specialist-subagent`
    - Add subsection documenting PRD→PLAN linkage: when `ticket-creation-subagent` runs Full workflow, it auto-detects draft PRDs and links them
    — **Why:** Without routing entries, the primary agent may not discover the subagent when users request PRD creation. The PRD→PLAN linkage subsection documents the integration contract.
    — **Done when:** Routing row present for PRD creation; PRD→PLAN linkage subsection present.
    — **Consumers affected:** Primary agent in user-space mode.

- [ ] **4.7** Update repo `AGENTS.md`:
    - Subagent count references: "34 subagent .md files" → actual + 1 (check all occurrences)
    - Subagent Locations table: add `prd-specialist-subagent` to global list
    — **Why:** Repo-level AGENTS.md is read by all agents; stale counts cause confusion.
    — **Done when:** All subagent count references updated to actual + 1; subagent listed in locations table.
    — **Consumers affected:** All agents working in this repo.

- [ ] **4.8** Cross-verify all counts and routing entries across ALL sync files:
    ```bash
    # Verify skill count
    ls -d opencode_app/.opencode/skills/*/ | grep -vE "_archived|scripts" | wc -l
    # Verify agent count
    ls opencode_app/.opencode/agents/*.md | wc -l
    # Verify routing entry
    grep -c "prd-specialist-subagent" deploy/.AGENTS.md
    grep -c "prd-creation-skill" deploy/setup.sh
    grep -c "prd-creation-skill" deploy/setup.ps1
    grep -c "prd-creation-skill" README.md
    grep -c "prd-specialist-subagent" README.md
    grep -c "prd-creation-skill" AGENTS.md
    grep -c "prd-specialist-subagent" AGENTS.md
    # Verify image-analyzer sharing (Phase 3b)
    grep -c "image-analyzer-subagent: allow" opencode_app/.opencode/agents/testing-subagent.md
    grep -c "image-analyzer-subagent: allow" opencode_app/.opencode/agents/code-review-subagent.md
    grep -c "image-analyzer-subagent: allow" opencode_app/.opencode/agents/architecture-review-subagent.md
    grep -c "image-analyzer-subagent: allow" opencode_app/.opencode/agents/pr-workflow-subagent.md
    grep -c "image-analyzer-subagent: allow" opencode_app/.opencode/agents/ticket-creation-subagent.md
    grep -c "image-analyzer-subagent: allow" opencode_app/.opencode/agents/opencode-tooling-subagent.md
    ```
    All declared counts must equal actual counts. All files must reference both the skill and the subagent. Framework counts must be consistent across banner and status sections in both deploy scripts.
    — **Why:** `documentation-consistency-skill` audits this; any drift fails the audit. The comprehensive grep verifies every sync file references both artifacts.
    — **Done when:** All count verification commands return correct values; all grep commands return ≥ 1; Framework counts consistent across banner and status in both deploy scripts; no drift between any sync files.
    — **Consumers affected:** All deploy and documentation consumers.

---

## Acceptance Criteria

1. `opencode_app/.opencode/skills/prd-creation-skill/SKILL.md` exists with valid YAML frontmatter, name matches `^[a-z][a-z0-9-]{0,63}$`, description includes trigger phrases ("create prd", "product requirement", "feature spec", "write prd", "product doc")
2. SKILL.md contains all 14 Core sections (Problem Statement, Background/Context, Goals & Non-Goals, User Personas, User Stories/JTBD, Functional Requirements, Non-Functional Requirements, Success Metrics, Scope In/Out, Acceptance Criteria, Risks & Dependencies, Open Questions, Timeline/Milestones, References)
3. SKILL.md documents the 3 Optional sections (UX/Design, Technical Architecture, Go-to-Market) with prompt-first inclusion logic
4. SKILL.md documents the `docs/prd/` naming convention: draft = `PRD-draft-{slug}.md`, final = `PRD-{ticket-key}.md`, with PLAN back-link placeholder `**PLAN**: PLANS/PLAN-{key}.md`
5. `opencode_app/.opencode/agents/prd-specialist-subagent.md` exists with `mode: subagent`, `model: zai-coding-plan/glm-5-turbo`, prompt-first behavior, trigger phrases, and Return Contract following repo convention
6. `ticket-creation-subagent.md` Step 3 updated with PRD auto-detect (scan `docs/prd/PRD-draft-*.md`), `git mv` rename to `PRD-{key}.md`, PLAN header `**PRD**:` injection, and commit of both PRD + PLAN
7. `ticket-plan-workflow-skill/SKILL.md` PLAN template updated with optional `**PRD**:` field in header
8. `deploy/.AGENTS.md` has routing entry for PRD creation pointing to `prd-specialist-subagent`
9. `deploy/setup.sh` updated: Framework count incremented, total skill count = actual + 1, `prd-creation-skill` listed in Framework; agent count = actual + 1, `prd-specialist-subagent` in help listing — in BOTH banner AND status sections
10. `deploy/setup.ps1` mirrors setup.sh exactly
11. `README.md` Skill Categories table: Framework count incremented, total updated; Subagents table: `prd-specialist-subagent` row added; agent count references updated
12. `opencode_app/README.md` directory count updated (actual + 1)
13. `AGENTS.md` (repo) subagent count references updated to actual + 1
14. All counts synchronized across all sync files — no drift
15. `image-analyzer-subagent.md` description updated to clarify it is a shared utility callable by both primary agent and other subagents; "Shared Utility" note present
16. `image-analyzer-subagent: allow` added to `permission.task` in all 6 target subagents: `testing-subagent`, `code-review-subagent`, `architecture-review-subagent`, `pr-workflow-subagent`, `ticket-creation-subagent`, `opencode-tooling-subagent`
17. `deploy/.AGENTS.md` routing table updated to note image-analyzer is a shared leaf-node utility with designated delegating subagents

---

## Related Files

| File | Action | Phase |
|------|--------|-------|
| `opencode_app/.opencode/skills/prd-creation-skill/SKILL.md` | Create | 1 |
| `opencode_app/.opencode/agents/prd-specialist-subagent.md` | Create | 2 |
| `opencode_app/.opencode/agents/ticket-creation-subagent.md` | Update (Step 3 PRD detection/rename/commit) | 3 |
| `opencode_app/.opencode/skills/ticket-plan-workflow-skill/SKILL.md` | Update (PLAN header PRD field) | 3 |
| `opencode_app/.opencode/agents/image-analyzer-subagent.md` | Update (reframe as shared utility) | 3b |
| `opencode_app/.opencode/agents/testing-subagent.md` | Update (add image-analyzer task permission) | 3b |
| `opencode_app/.opencode/agents/code-review-subagent.md` | Update (add image-analyzer task permission) | 3b |
| `opencode_app/.opencode/agents/architecture-review-subagent.md` | Update (add image-analyzer task permission) | 3b |
| `opencode_app/.opencode/agents/pr-workflow-subagent.md` | Update (add image-analyzer task permission) | 3b |
| `opencode_app/.opencode/agents/ticket-creation-subagent.md` | Update (add image-analyzer task permission) | 3b |
| `opencode_app/.opencode/agents/opencode-tooling-subagent.md` | Update (add image-analyzer task permission) | 3b |
| `deploy/.AGENTS.md` | Update (routing entry + PRD→PLAN linkage) | 4 |
| `AGENTS.md` (repo) | Update (subagent count, routing) | 4 |
| `deploy/setup.sh` | Update (skill + agent counts/listings) | 4 |
| `deploy/setup.ps1` | Update (mirror of setup.sh) | 4 |
| `README.md` | Update (Skill Categories + Subagents tables) | 4 |
| `opencode_app/README.md` | Update (directory count) | 4 |

---

## Risks & Mitigation

| Risk | Mitigation |
|------|------------|
| Pre-existing count drift (declared 82, actual 81) causes new drift | Phase 4.1 verifies live counts before writing; all subtasks use "actual + 1" not hardcoded numbers |
| PLAN-GIT-221 merges first, changing actual count | Phase 4.1 verification commands capture the true count at execution time; no hardcoded numbers |
| `ticket-creation-subagent` breaks when no PRD exists | Phase 3.1 explicitly documents silent skip of all PRD steps when `ls docs/prd/PRD-draft-*.md` returns nothing — backward-compatible |
| `prd-specialist-subagent` hallucinates product requirements | Phase 2.4 enforces prompt-first pattern matching `ticket-creation-subagent`; every section requires user confirmation |
| Model tier wrong for subagent | Phase 2.1 explicitly sets `glm-5-turbo` (document-creation tier); NOT glm-5.2 (primary-session only) or glm-5.1 (correctness-critical) |
| Documentation sync drift across 5+ files | Phase 4.8 cross-verifies all counts and references with grep commands; matches `documentation-consistency-skill` audit expectations |
| Image-analyzer permission grants cause unintended side effects (subagents over-delegating to vision) | Each grant is scoped to `permission.task` (delegation only); image-analyzer-subagent is read-only (`edit: deny, bash: deny`) — it cannot modify files or execute commands, only interpret and return results. Calling subagents receive structured text, not actions. |
| image-analyzer model cost from increased delegation | `image-analyzer-subagent` uses `glm-5v-turbo` (200K context, same tier as other subagents); not the expensive 1M-context `glm-5.2`. Cost increase is bounded by caller's step budget. |

---

## Out of Scope

- Creating a PRD for this issue (we ARE the PRD tooling — meta-recursion avoided)
- Modifying `opencode_app/opencode.json` MCP server config (no new MCP server)
- Changing the PLAN template beyond the optional `**PRD**:` header field
- PRD-to-Word/PDF export (handled by existing `docx-creation-skill` / `pdf-specialist-skill`)
- Auto-generating PRDs from code (PRD is a pre-code artifact — by design)
- Granting image-analyzer access to subagents without clear image interpretation needs (linting, loop-operator, language reviewers — code-only agents that never encounter images)
- Modifying `error-resolver-subagent` (already has vision model `glm-5v-turbo` and no `task:` restriction — it can already delegate to image-analyzer if needed)

---

*Tracking progress with `plan-updater-skill`. Branch: `issue-223`.*
