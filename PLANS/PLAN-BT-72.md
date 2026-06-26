# PLAN: Restructure Document Workflow into a Proper Software-House Document Ladder

**JIRA**: [BT-72](https://betekk.atlassian.net/browse/BT-72)
**Branch**: `BT-72`
**Created**: 2026-06-26
**Status**: Created 2026-06-26 · Revised per joint review (16 findings) + step-budget revision (discovery 30→60, requirements 30→40)

## Overview

Split the single `prd-specialist-subagent` into a **proper software-house document ladder** with distinct customer-facing and internal stages, each owned by a single-responsibility subagent, backed by a shared document-rendering standard and the existing Excel/PowerPoint tooling.

This is **Phase 1 only**. It establishes the discovery (customer) + requirements (internal) subagents and the shared rendering skill. BRD and Technical Design Doc are Phase 2.

### Decisions locked (from discovery interview)

| Decision | Choice |
|---|---|
| Architecture | **B-variant** — `discovery-specialist` (customer, standalone) + `requirements-specialist` (internal, BRD+SRS merged) |
| Internal BA→dev doc name | **SRS (IEEE 830)**, not PRD |
| SRS template depth | **Full IEEE 830 restructure** (Intro / Overall Description / Specific Requirements / Supporting) |
| Routing | Subagent **self-detects** doc type from trigger phrase |
| Wireframe storage | `docs/vision/{slug}/` (co-located with Vision doc) |
| Discovery interactive HTML | **Living doc**, updated through the session |
| Excel/tabular artifacts | Wired in Phase 1 (permission + clause), on-demand |
| PowerPoint | Wired into **discovery-specialist only**, on-demand |

### Net impact

- **Agents**: +1 (discovery-specialist), 1 renamed (prd→requirements). Source count 34 → 35.
- **Skills**: +2 (vision-creation-skill, interactive-document-rendering-skill), 1 renamed (prd-creation-skill → srs-creation-skill). **Deployable** count 102 → 104 (total incl `_archived/`: 108 → 110).

> **Count note (verified):** `find ... -name SKILL.md` = 108 total (incl `_archived/`); deployable (excl `_archived/`) = 102. setup.sh/setup.ps1/README banners use the **deployable** number (102→104); the `find` gate in step 5.3 uses the **total** (108→110).

---

## Dependency & Consumer Map

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---|---|---|---|
| `skills/interactive-document-rendering-skill/SKILL.md` | — | vision-creation-skill, srs-creation-skill (reference it), discovery + requirements subagents (permit it) | high |
| `skills/vision-creation-skill/SKILL.md` | rendering skill exists (references it) | discovery-specialist-subagent | med |
| `skills/srs-creation-skill/SKILL.md` (renamed from prd-creation-skill) | rendering skill exists (references it) | requirements-specialist-subagent, ticket-creation-subagent (permit + dir convention) | high |
| `agents/discovery-specialist-subagent.md` | vision + rendering + wireframer skills exist | Primary agent routing (AGENTS.md), setup.sh | high |
| `agents/requirements-specialist-subagent.md` (renamed from prd-specialist) | srs + rendering skills exist | Primary agent routing (AGENTS.md), setup.sh | high |
| `agents/ticket-creation-subagent.md` (EDIT) | srs-creation-skill renamed | ticket-creation flow (docs/srs/ detection) | med |
| `skills/ticket-plan-workflow-skill/SKILL.md` (EDIT) | srs rename | PLAN header injection | low |
| `deploy/setup.sh` | All agent/skill files finalized | setup.ps1 mirror, deployment | high |
| `deploy/setup.ps1` | setup.sh changes | Windows deployment | med |
| `README.md` | All skills/agents finalized | Documentation consumers | med |
| `AGENTS.md` (repo) | — | Model-tier routing | low |
| `deploy/.AGENTS.md` | — | Primary agent routing table | med |

---

## Implementation Phases

### Phase 1: Create & Rename Skills (foundation — agents depend on skills)

- [ ] **1.1** Create `interactive-document-rendering-skill`
    - **Why:** Shared rendering standard prevents per-skill inconsistency (the user's explicit "consistent styling" requirement); both vision and srs reference it, so it must exist first
    - **Done when:** `opencode_app/.opencode/skills/interactive-document-rendering-skill/SKILL.md` exists with: HTML standard (left sidebar nav auto-generated from H1–H3, dark-mode toggle, color-aware `::selection`, self-contained no external deps), DOCX standard (auto TOC field, hyperlinked headers/bookmarks, heading style map, section page-breaks), SCOPE clause ("HTML + DOCX only; .xlsx/.pptx are peer deliverables linked not embedded"), image-routing clause ("image interpretation → delegate to image-analyzer-subagent"), living-vs-snapshot regen guidance, and naming/placement (`docs/{type}/{slug}/{NAME}.interactive.html` + `docs/{type}/{NAME}.docx`)
    - **Consumers affected:** vision-creation-skill (1.2), srs-creation-skill (1.3), discovery-specialist (2.1), requirements-specialist (2.2)

- [ ] **1.2** Create `vision-creation-skill`
    - **Why:** Customer-facing Vision Document template (IIBA "Business Need / Solution Vision") — the discovery output artifact; does not exist today
    - **Done when:** `opencode_app/.opencode/skills/vision-creation-skill/SKILL.md` exists with: Vision Doc template (problem/opportunity, target outcomes, proposed solution summary, success measures, assumptions/constraints, scope boundaries, open questions), `docs/vision/VISION-{slug}.md` naming convention, **no** ticket/PLAN linkage (Vision is upstream of tickets), "Render dual outputs per interactive-document-rendering-skill (living interactive HTML through session, docx on wrap)", optional "distill to customer presentation deck via pptx-specialist" clause, wireframe co-location note (`docs/vision/{slug}/wireframe-*.html`)
    - **Consumers affected:** discovery-specialist-subagent (2.1)

- [ ] **1.3** Rename `prd-creation-skill` → `srs-creation-skill` + restructure to IEEE 830
    - **Why:** PRD is the wrong label for BA→dev handoff; IEEE 830 SRS is the proper-software-house standard; rename preserves git history
    - **Done when:** `git mv opencode_app/.opencode/skills/prd-creation-skill opencode_app/.opencode/skills/srs-creation-skill` executed; `SKILL.md` `name:` field updated to `srs-creation-skill`; template restructured to IEEE 830 (1. Introduction [Purpose/Scope/Definitions/References/Overview], 2. Overall Description [Product perspective/Functions/User characteristics/Constraints/Assumptions], 3. Specific Requirements [External interfaces/Functional/Performance/Design constraints/Software system attributes], 4. Supporting Information [Appendices/Traceability]); valuable existing sections preserved by mapping (acceptance criteria→3.x, NFRs→3.4-3.5, MoSCoW priorities→3.2, risks→2.5, user stories/personas→2.3 User characteristics); dir convention updated to `docs/srs/SRS-draft-{slug}.md` → `docs/srs/SRS-{key}.md`; **all body `docs/prd/` references** (Discovery Interview Workflow, Naming Convention, Return Contract sections) updated to `docs/srs/`; **L351/L375 `prd-specialist-subagent` → `requirements-specialist-subagent`**; back-compat note ("create prd" trigger routes to SRS); added xlsx clause ("large tabular deliverables — RTM, data dictionary, requirement register — exported as .xlsx via xlsx-specialist at `docs/srs/{slug}/{NAME}-{artifact}.xlsx`, linked from doc; small tables stay inline"); "Render dual outputs per interactive-document-rendering-skill (snapshot for SRS)"
    - **Consumers affected:** requirements-specialist-subagent (2.2), ticket-creation-subagent (3.1)

### Phase 2: Create & Rename Agents

- [ ] **2.1** Create `discovery-specialist-subagent`
    - **Why:** Customer-facing discovery is a distinct mode (live workshop, wireframes on the fly, client-relayed feedback) that shouldn't be merged with internal SRS authoring — single-responsibility, self-explanatory
    - **Done when:** `opencode_app/.opencode/agents/discovery-specialist-subagent.md` exists with: `mode: subagent`, `model: zai-coding-plan/glm-5-turbo`, `steps: 60` (highest in repo — justified: live iterative living-doc workflow; each discovery loop ≈ 8-9 steps × ~5 iterations + synthesis/render/optional pptx ≈ ~60; 30 truncates mid-session), Prompt Defense Baseline, description covering triggers ("create vision", "vision document", "concept brief", "discovery session", "start discovery"), purpose (customer-facing, wireframer-driven, live loop), permission block (`read/edit/glob/grep/bash: allow`; `task: image-analyzer-subagent allow, xlsx-specialist-subagent allow, explore allow, "*": deny`; `skill: vision-creation-skill, interactive-document-rendering-skill, wireframer-skill, domain-modeling-skill, grilling-skill, docx-creation-skill, xlsx-specialist-skill, pptx-specialist-skill: allow`), prompt-first workflow (gather title/overview → discovery interview loop with wireframe generation mid-session → capture client feedback verbatim → synthesize living Vision Doc → optional pptx deck), Return Contract
    - **Consumers affected:** Primary agent routing (AGENTS.md 4.x), setup.sh

- [ ] **2.2** Rename `prd-specialist-subagent` → `requirements-specialist-subagent`
    - **Why:** Subagent now owns internal SRS (IEEE 830) only; name must reflect SRS not PRD; rename preserves git history. Note: the permission block also *expands* capabilities (+interactive-document-rendering-skill, docx-creation-skill, xlsx-specialist-skill, image-analyzer-subagent task) per the document-ladder design
    - **Done when:** `git mv opencode_app/.opencode/agents/prd-specialist-subagent.md opencode_app/.opencode/agents/requirements-specialist-subagent.md` executed; `steps:` bumped **30→40** (the IEEE 830 interview already consumes ~30; added rendering + optional xlsx + search-first + image-analyzer need headroom — matches business-ops-primary-agent tier); description rewritten (triggers: "create srs", "software requirements", "functional spec", "specification", plus back-compat "create prd"/"product requirement"→route to SRS); purpose scoped to internal-only (NO customer mode); permission block updated (`skill: srs-creation-skill, interactive-document-rendering-skill, domain-modeling-skill, grilling-skill, docx-creation-skill, xlsx-specialist-skill, search-first-skill: allow`; `task: image-analyzer-subagent allow, xlsx-specialist-subagent allow, explore allow, "*": deny`) — `search-first-skill` retained from the current prd-specialist (research-before-authoring is useful for SRS); self-detect doc-type workflow note (Phase 2 adds BRD; for now SRS only); output path `docs/srs/`; Return Contract updated
    - **Consumers affected:** Primary agent routing (AGENTS.md 4.x), setup.sh, deploy/.AGENTS.md

### Phase 3: Update Dependent Consumers

- [ ] **3.1** Update `ticket-creation-subagent.md`
    - **Why:** It detects `docs/prd/PRD-draft-*` and permits `prd-creation-skill` — both renamed; broken refs will fail the PRD→PLAN linkage step
    - **Done when:** L25 `prd-creation-skill: allow` → `srs-creation-skill: allow`; L147 skill table description updated; L147/217/221/224/231 all `docs/prd/` → `docs/srs/`, `PRD-draft` → `SRS-draft`, `PRD-{key}` → `SRS-{key}`, `PRD_PATH` → `SRS_PATH`, `**PRD**:` → `**SRS**:`; **L225** `PRD_PATH="" (skip PRD steps — backward-compatible)` → `SRS_PATH="" (skip SRS steps — backward-compatible)`; **L228** `**PRD header injection**: If PRD_PATH is set, add **PRD**: {PRD_PATH}` → `**SRS header injection**: If SRS_PATH is set, add **SRS**: {SRS_PATH}`; the `prd-creation-skill` row in "Skills Used" table → `srs-creation-skill`
    - **Consumers affected:** Full-workflow ticket creation (PRD/SRS draft detection)

- [ ] **3.2** Update `ticket-plan-workflow-skill/SKILL.md`
    - **Why:** PLAN header template injects `**PRD**: $PRD_PATH` with `docs/prd/` reference — must track the renamed doc
    - **Done when:** L255 full line → `**SRS**: $SRS_PATH _(optional — present only when an SRS was linked via docs/srs/)_` — variable name, path, AND prose ("a PRD" → "an SRS")
    - **Consumers affected:** PLAN header generation in full workflow

### Phase 4: Sync Documentation

- [ ] **4.1** Update `README.md`
    - **Why:** README is primary docs; must reflect new agent + skills + renamed items
    - **Done when:** Skill table (~L286) entry `prd-creation-skill` → `srs-creation-skill`, add `vision-creation-skill` + `interactive-document-rendering-skill`, recount Framework/Document skills (deployable 102→104); Subagent table (~L329) row `prd-specialist-subagent` → `requirements-specialist-subagent`, add `discovery-specialist-subagent` row; **L280 stale total `88 skills` → `104 skills` (deployable — already stale pre-BT-72)** and verify the category count
    - **Consumers affected:** Documentation readers

- [ ] **4.2** Update `AGENTS.md` (repo root)
    - **Why:** Model-tier list names `prd-specialist` in the glm-5-turbo group
    - **Done when:** L34 `prd-specialist` → `requirements-specialist`; add `discovery-specialist` to the same tier line
    - **Consumers affected:** Model-tier assignment

- [ ] **4.3** Update `deploy/.AGENTS.md`
    - **Why:** Routing table has a single "PRD creation | prd-specialist-subagent" row that no longer matches reality
    - **Done when:** L39 row split/rewritten to: "Vision/discovery (customer-facing) | discovery-specialist-subagent" and "Requirements/SRS (internal) | requirements-specialist-subagent"
    - **Consumers affected:** Primary agent routing decisions

- [ ] **4.4** Update `deploy/setup.sh`
    - **Why:** Banner + listing must match deployed files; setup is the deploy entrypoint
    - **Done when:** Agent listing (+discovery-specialist, rename prd-specialist→requirements-specialist) at ~L541, ~L1666, ~L2393; skill listing (+vision-creation-skill, +interactive-document-rendering-skill, rename prd-creation-skill→srs-creation-skill) at ~L592, ~L2254; skill COUNT headers **L585 `SKILLS (102):` → `SKILLS (104):`** and **L2400 `102 Skills Available` → `104 Skills Available`** (banners use the DEPLOYABLE count); agent banner "38 agents"→"39 agents" in ALL 3 locations (L1661, L2215, L2388) with **"34 more agents"→"35 more agents"**
    - **Consumers affected:** Anyone running setup.sh / --help

- [ ] **4.5** Mirror all setup.sh changes in `deploy/setup.ps1`
    - **Why:** Windows parity — setup.ps1 must match setup.sh exactly
    - **Done when:** All changes from 4.4 mirrored in PowerShell syntax at ~L376, ~L388, ~L1177, ~L1249, ~L1748; skill COUNT headers **L381 `SKILLS (102):` → `SKILLS (104):`** and **L1755 `102 Skills Available` → `104 Skills Available`**
    - **Consumers affected:** Windows users

- [ ] **4.6** Verify/update `opencode_app/README.md`
    - **Why:** Docker docs may reference prd; must not break
    - **Done when:** Grep `opencode_app/README.md` for `prd`; if found, update; if absent, no-op. ALSO recount the agent total at **~L102 (`36 agents` → `37 agents`)** — the `prd` grep alone would no-op and miss this stale count
    - **Consumers affected:** Docker users

### Phase 5: Verification

- [ ] **5.1** Grep-confirm zero stale `prd` references in source
    - **Why:** Any leftover `prd-specialist` / `prd-creation-skill` / `docs/prd` / `PRD_PATH` will cause routing failures or broken deploy scripts
    - **Done when:** `grep -rn "prd-specialist\|prd-creation-skill\|docs/prd\|PRD-draft\|PRD_PATH\|\*\*PRD\*\*" opencode_app/ deploy/ README.md AGENTS.md` returns zero matches EXCEPT `CHANGELOG.md` history rows (which are intentionally preserved). Pattern now includes `PRD_PATH` and `**PRD**:` so L225/L228-class refs are caught.
    - **Consumers affected:** All consumers (correctness gate)

- [ ] **5.2** Run `documentation-sync-workflow` skill (or delegate to opencode-tooling-subagent)
    - **Why:** Repo AGENTS.md mandates doc sync after skill/agent changes; validates cross-file count consistency
    - **Done when:** Skill confirms setup.sh, setup.ps1, README, AGENTS.md counts/listings are mutually consistent
    - **Consumers affected:** Documentation integrity

- [ ] **5.3** Verify agent/skill counts are internally consistent
    - **Why:** Inconsistent counts between setup.sh banner, README tables, and actual files confuse users and break deploy verification
    - **Done when:** `ls opencode_app/.opencode/agents/ | wc -l` == 35; TOTAL `find opencode_app/.opencode/skills -name SKILL.md | wc -l` == 110 (incl `_archived/`); DEPLOYABLE `find opencode_app/.opencode/skills -name SKILL.md -not -path '*/_archived/*' | wc -l` == 104; setup.sh + setup.ps1 + README banners show 104 (deployable)
    - **Consumers affected:** All deployment consumers

- [ ] **5.4** Validate `interactive-document-rendering-skill` structure
    - **Why:** A malformed rendering skill silently breaks both vision and srs HTML/DOCX output; count/stale-ref checks won't catch a structurally invalid template
    - **Done when:** `opencode_app/.opencode/skills/interactive-document-rendering-skill/SKILL.md` contains a complete HTML standard (sidebar nav generation from H1–H3, dark-mode toggle, color-aware `::selection`) and a DOCX standard with an explicit TOC field reference; no placeholder TODOs remain
    - **Consumers affected:** discovery-specialist, requirements-specialist (all rendering output)

---

## Acceptance Criteria

- [ ] `interactive-document-rendering-skill/` exists with HTML + DOCX standard (sidebar nav, dark-mode-aware, color-aware selection, TOC, linked headers) + image-analyzer routing clause
- [ ] `vision-creation-skill/` exists (IIBA Vision template, `docs/vision/`, no ticket linkage)
- [ ] `srs-creation-skill/` exists (renamed from prd-creation-skill, IEEE 830 structure, `docs/srs/`, xlsx clause, body refs + L351/L375 updated)
- [ ] `discovery-specialist-subagent.md` exists (glm-5-turbo, **steps: 60**, customer-facing, permits vision+rendering+wireframer+domain-modeling+grilling+docx+xlsx+pptx skills, task image-analyzer+xlsx allow)
- [ ] `requirements-specialist-subagent.md` exists (renamed from prd-specialist, glm-5-turbo, **steps: 40**, internal, permits srs+rendering+domain-modeling+grilling+docx+xlsx+**search-first** skills, task image-analyzer+xlsx allow)
- [ ] `ticket-creation-subagent.md` references `docs/srs/` + `srs-creation-skill` + `SRS_PATH` (zero `docs/prd`/`PRD_PATH`/`**PRD**:`)
- [ ] `ticket-plan-workflow-skill/SKILL.md` uses `**SRS**:` + `docs/srs/` + "an SRS was linked" in PLAN header
- [ ] README.md, AGENTS.md, deploy/.AGENTS.md, setup.sh, setup.ps1 reflect new agent + 2 skills + rename (counts consistent: 35 agents / 104 deployable skills / 110 total skills)
- [ ] Zero stale `prd-specialist` / `prd-creation-skill` / `docs/prd` / `PRD_PATH` / `**PRD**:` in source (CHANGELOG history excluded)
- [ ] `documentation-sync-workflow` validation passes
- [ ] `interactive-document-rendering-skill` structurally valid (step 5.4)

---

## Risks & Mitigation

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| IEEE 830 restructure drops a valuable existing section | med | med | Step 1.3 maps every current section into IEEE structure explicitly; preserve acceptance criteria, NFRs, MoSCoW, risks |
| Back-compat "create prd" trigger not carried forward | med | med | Step 2.2 explicitly keeps "create prd"/"product requirement" triggers routing to SRS |
| setup.sh line numbers drift during editing | high | med | Use string matching for edits, not line numbers; re-grep after each change |
| Agent count mismatch (banner says 38 agents but source ls says 34) | high | med | Step 5.3 reconciles; treat source ls as authoritative for the +1 delta |
| Skill count: total (108 incl `_archived`) vs deployable (102) conflated in banner | high | high | Steps 4.4/4.5 set banner to 104 (deployable); step 5.3 checks BOTH find==110 (total) AND deployable==104 |
| ticket-creation-subagent edits missed (L225/L228 + PRD_PATH/**PRD**: not in grep) | med | high | Step 3.1 enumerates L225/L228; step 5.1 grep pattern now includes `PRD_PATH` + `**PRD**:` |
| CHANGELOG accidentally edited | low | low | Step 5.1 explicitly excludes CHANGELOG.md |

---

## Technical Notes

- All source-of-truth edits go in `opencode_app/.opencode/` (repo AGENTS.md rule); **never** edit deployed `~/.config/opencode/` copies — redeploy handles those
- Use `git mv` for renames to preserve git history
- `CHANGELOG.md` history rows (L20, L27) are intentionally NOT edited — they are historical record
- Discovery subagent uses `bash: allow` (wireframer writes HTML files to disk); same as prd-specialist baseline
- Technical-design-specialist subagent (Phase 2) will be `glm-5.1` (sound-reasoning), unlike the 5-turbo document subagents — different model tier justifies its own subagent
- The `interactive-document-rendering-skill` is deliberately HTML+DOCX scoped; `.xlsx` (RTM/data-dict) and `.pptx` (customer deck) are peer deliverables handled by their existing specialist skills/subagents
- **Migration note:** Existing `docs/prd/PRD-draft-*.md` files in any project are NOT auto-migrated by this change. After deploy, ticket-creation-subagent scans `docs/srs/`; users with unlinked PRD drafts must manually `mv docs/prd/ docs/srs/` or they will be silently ignored.
- **Complexity hotspot:** discovery-specialist maintains a *living* interactive HTML (`docs/vision/{slug}/{NAME}.interactive.html`) updated across multiple step cycles within its 30-step budget — non-trivial file-state management, justified by the live-customer-workshop use case.
- **Step-budget rationale:** discovery-specialist=60, requirements-specialist=40 (calibrated against the repo's 5–40 range; both exceed the prior prd-specialist=30 because the new workflows add live iteration / rendering+xlsx). **Fallback if a discovery session routinely exceeds 60 steps:** do NOT just raise the ceiling — re-architect to per-iteration invocation (the primary session re-invokes discovery-specialist once per wireframe+feedback round, each updating the same living files). This keeps per-invocation cost bounded and matches the hub-and-spoke model.

---

## Phase 2 Preview (NOT in this ticket)

- **BRD**: create `brd-creation-skill` (BABOK standard), add to `requirements-specialist-subagent` permissions + self-detect (no new agent). Phase 2 must also define an explicit doc-type routing decision tree (trigger-phrase self-detect is fragile once BRD and SRS coexist).
- **Technical Design Doc**: create `technical-design-specialist-subagent` (`glm-5.1`, sound-reasoning) + `technical-design-creation-skill` — named to **avoid collision** with the existing `tdd-subagent` (Test Driven Development) and `tdd-workflow-skill`; wire CodeGraph/architecture tools; separate subagent justified by model tier + design-authoring workflow.

---

*Created by ticket-creation-subagent full workflow — BT-72. Revised per architecture-review-subagent + opencode-tooling-subagent joint review (4 major / 7 minor / 5 nit findings applied).*
