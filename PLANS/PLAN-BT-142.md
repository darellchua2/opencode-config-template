# PLAN-BT-142 — Migrate pptx-specialist-* to chenyu JSON-in-PPTX architecture

**JIRA:** https://betekk.atlassian.net/browse/BT-142
**Branch:** `BT-142-pptx-json-migration`
**Created:** 2026-07-21
**Reference review:** `/tmp/opencode/chenyu-pptx-review.md`

## Goal

Port chenyu's 3-skill + 1-agent PPTX architecture (embedded JSON-in-PPTX schema + always-slide-master rendering) from `reference/chenyu-pptx-subagent/` into `opencode_app/.opencode/`. Replace the current html2pptx-first default with a Slide-Master-first approach that requires user-supplied templates and embeds a normalized JSON schema inside PPTX files for consistency.

**Three invariants enforced everywhere:**

1. **No bundled default template.** The engine never ships or falls back to a `default.pptx`. A user-supplied template path is required; absent one, the agent errors with an actionable message.
2. **Always review embedded JSON if present.** When the user supplies a PPTX, the orchestrator MUST probe for `ppt/template_schema.json` via `read_embedded_schema()` before any other action. The result drives routing: `TEMPLATED` → consume the JSON as authoritative layout reference; `NOT_TEMPLATED` → auto-extract-then-embed via the engine's `auto_template=True` path; absent or malformed → never silently fall through.
3. **Decompose the misnamed `pptx-specialist-skill`.** Audit revealed the current skill bundles 3 distinct concerns under a PPTX-misleading name: generic Office OOXML tooling, DOCX-specific helpers (misplaced), and PPTX-specific html2pptx (retired by chenyu). It must be **refactored into single-responsibility skills** — not retained as an "escape hatch" monolith. See Phase 7.

## Architecture Summary

| Layer            | Chenyu component                                                                                                                   | Our target location                                                                                   |
| ---------------- | ----------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------- |
| Shared           | `_common/scripts/{schema_extractor,layout_contract,contract_adapter,geometry,errors,master_repairer,template_introspector}.py` + `schemas/template_schema.json` | `opencode_app/.opencode/skills/_common/scripts/` (NEW shared dir)                                     |
| Extract          | `generate-template-skill/`                                                                                                         | `opencode_app/.opencode/skills/generate-template-skill/`                                               |
| Fill             | `generate-slide-skill/` (incl. `ppt_builder.py`)                                                                                   | `opencode_app/.opencode/skills/generate-slide-skill/`                                                  |
| Extend           | `template-modifier-skill/`                                                                                                         | `opencode_app/.opencode/skills/template-modifier-skill/`                                                |
| Orchestrator     | `agents/pptx-subagent.md` (thin rewrite)                                                                                           | `opencode_app/.opencode/agents/pptx-specialist-subagent.md` (REWRITE)                                  |

**New skills created by Phase 7 decomposition** (split out of the misnamed `pptx-specialist-skill`):

| New skill                  | Source files (from `pptx-specialist-skill/scripts/`)                                                       | Responsibility                                        |
| -------------------------- | ----------------------------------------------------------------------------------------------------------- | ----------------------------------------------------- |
| `ooxml-editing-skill`        | `unpack.py`, `pack.py`, `validate.py`, `clean.py`, `validators/base.py`, `validators/pptx.py`                  | Generic Office OOXML unpack/pack/validate — surgical edits, supports all .docx/.pptx/.xlsx |
| `office-thumbnail-skill`     | `thumbnail.py`, `soffice.py`                                                                                  | Visual analysis — thumbnail grids + PDF/image conversion via LibreOffice              |
| (merge into `docx-creation-skill`) | `validators/docx.py`, `validators/redlining.py`, `helpers/merge_runs.py`, `helpers/simplify_redlines.py` | DOCX-specific helpers — were misplaced under a PPTX-named skill                       |
| (merge into `generate-slide-skill`) | `add_slide.py` (PPTX-specific OOXML slide add)                                                                | PPTX surgical-edit escape hatch — lives next to the python-pptx engine                |
| **DELETE**                   | `pptx-specialist-skill/SKILL.md` html2pptx workflow section                                                    | Retired by chenyu's stack; 1-paragraph stub retained only for explicit "html→pptx" requests routed by the orchestrator |

## Dependency & Consumer Map

```
                    ┌──────────────────────────┐
                    │  pptx-specialist-subagent │  (orchestrator — routes to skills)
                    └──┬───────┬───────┬────┬───┘
                       │       │       │    │
         ┌─────────────▼┐ ┌───▼────┐ ┌─▼───┴──────────┐ ┌▼────────────────────┐
         │ generate-     │ │template│ │ generate-slide │ │ ooxml-editing-skill │
         │ template-skill│ │modifier│ │  -skill        │ │ (surgical edits)    │
         └──────┬────────┘ │ -skill │ └─┬──────────┬───┘ └─────────────────────┘
                │          └───┬────┘   │          │              ▲
                │              │        │          │              │ (was pptx-
                ▼              ▼        ▼          ▼              │  specialist-
         ┌────────────────────────────────────────────────┐     │  skill)
         │     _common/scripts/                           │     │
         │  schema_extractor, layout_contract,            │     │
         │  contract_adapter, geometry,                   │     │
         │  master_repairer, text_fit, etc.               │     │
         └────────────────────────────────────────────────┘     │
                                                                  │
         ┌──────────────────────────────┐                        │
         │ office-thumbnail-skill       │ ← (also from pptx-     │
         │ (thumbnail + soffice)        │    specialist-skill)   │
         └──────────────────────────────┘                        │
                                                                  │
         ┌──────────────────────────────┐                        │
         │ docx-creation-skill          │ ← (absorbs docx-       │
         │ (+misplaced docx helpers)    │    specific files)     │
         └──────────────────────────────┘                        │
```

**Skill count math (verified 2026-07-21):** 118 (current, confirmed via `ls -d opencode_app/.opencode/skills/*/ | wc -l`) + 3 (chenyu) − 1 (pptx-specialist-skill removed) + 2 (new: ooxml-editing-skill, office-thumbnail-skill) = **122**. Note: raw `ls -d */` post-migration yields 123 because `_common/` is a shared library directory (no `SKILL.md`), not a skill. Banner/README must use 122.

**Consumers affected (direct — must update `permission.skill` + prose):**
- `deploy/setup.sh` / `deploy/setup.ps1` — skill count 118 → 122; banner + listing updates
- `README.md` — Skill Categories table; Subagents table
- `opencode_app/README.md` — Docker-specific docs (Python-only PPTX workflow)
- `opencode_app/.opencode/agents/pptx-specialist-subagent.md` — REPLACE `pptx-specialist-skill: allow` with `generate-slide-skill/generate-template-skill/template-modifier-skill/ooxml-editing-skill/office-thumbnail-skill: allow`
- `opencode_app/.opencode/agents/office-document-primary-agent.md` — REPLACE `pptx-specialist-skill: allow`; route PPTX ops to the orchestrator subagent instead
- `opencode_app/.opencode/agents/startup-ceo-subagent.md` — REPLACE skill delegation; route to `pptx-specialist-subagent` for deck creation
- `opencode_app/.opencode/agents/discovery-specialist-subagent.md` — REPLACE skill delegation; route to `pptx-specialist-subagent`
- `opencode_app/.opencode/skills/vision-creation-skill/SKILL.md` — Update peer-deliverable reference (lines 40, 170)
- `opencode_app/.opencode/skills/startup-pitch-deck-skill/SKILL.md` — Update skill reference (line 306)
- `opencode_app/.opencode/skills/interactive-document-rendering-skill/SKILL.md` — Update peer-deliverable reference (lines 25, 201)
- `opencode_app/.opencode/skills/docx-creation-skill/SKILL.md` — Add references to the absorbed helpers (merge_runs, simplify_redlines, redlining validator)
- All downstream projects consuming `pptx-specialist-subagent.md`

## Phases

### Phase 1 — Shared Infrastructure (deps for everything else)

- [ ] **1.1** Port `_common/scripts/` to `opencode_app/.opencode/skills/_common/scripts/`
  — **Why:** All three new skills depend on shared schema extraction, layout contracts, geometry helpers, error types, and template introspection. Must land first.
  — **Done when:** All `_common/scripts/*.py` files exist in target dir and `python -c "import sys; sys.path.insert(0,'opencode_app/.opencode/skills/_common/scripts'); import schema_extractor, layout_contract, contract_adapter, geometry, errors, master_repairer, template_introspector"` exits 0.
  — **Consumers affected:** `generate-template-skill`, `generate-slide-skill`, `template-modifier-skill`

- [ ] **1.2** Port `schemas/template_schema.json` to `opencode_app/.opencode/skills/_common/schemas/`
  — **Why:** The canonical JSON schema that defines what gets embedded in PPTX files. Referenced by schema_extractor and schema_validator.
  — **Done when:** JSON file validates against its own `$schema` key (if present) and `schema_validator.py` can load it.
  — **Consumers affected:** `generate-template-skill`, `generate-slide-skill`

- [ ] **1.3** Run ported `_common` tests under pytest; verify green
  — **Why:** Catch import errors, path issues, and Python version mismatches early before downstream skills are built on top.
  — **Done when:** `pytest opencode_app/.opencode/skills/_common/` passes with zero failures.
  — **Consumers affected:** CI pipeline (once tests are added to repo)

- [ ] **1.4** **Blocker fix:** Add schema version drift handling to `read_embedded_schema` (`schema_extractor.py:1378-1415`)
  — **Why:** Currently `SCHEMA_VERSION = "1.1.0"` is written on embed but never validated on read. A schema change could silently produce broken slides.
  — **Done when:** `read_embedded_schema` compares `major.minor.patch` — warns on minor mismatch, raises `SchemaVersionError` on major mismatch, auto-upgrades patch mismatches.
  — **Consumers affected:** All skills that call `read_embedded_schema` (generate-template, generate-slide)

- [ ] **1.5** **Blocker fix:** Embed in-code minimal theme XML in `master_repairer.py` (drops default.pptx dependency for L3)
  — **Why:** `master_repairer.py` L2/L3 currently falls back to `default.pptx` to source theme XML. Per user constraint, no `default.pptx` shall exist. Replace with ~30 lines of in-code minimal theme XML (12 OPC color roles + major/minor fonts).
  — **Done when:** `master_repairer.py` has no import or path reference to `default.pptx`; L3 repair uses in-code theme XML; existing tests pass with updated fixtures.
  — **Consumers affected:** `generate-slide-skill`, `template-modifier-skill`

### Phase 2 — Extract + Fill Skills (coupled via embedded JSON contract)

- [ ] **2.1** Port `generate-template-skill/` (SKILL.md + wraps `schema_extractor`)
  — **Why:** First half of the workflow — extracts layout fingerprints from user PPTX and produces `template_schema.json` for embedding. The "Extract" leg of the Extract→Fill pipeline.
  — **Done when:** Skill file exists with correct trigger phrases; `grep -c "schema_extractor" opencode_app/.opencode/skills/generate-template-skill/SKILL.md` returns ≥1; SKILL.md `_common/scripts/schema_extractor.py` path reference resolves.
  — **Consumers affected:** `pptx-specialist-subagent.md` (routing)

- [ ] **2.2** Port `generate-slide-skill/` (SKILL.md + `ppt_builder.py` + `text_fit.py` + `density_mode.py` + `schema_validator.py` + `outline_store.py` + `coordinate_placer.py` + `resolvers/`)
  — **Why:** The core "Fill" skill — takes a templated PPTX + user content spec and produces new slides using Slide Master layouts. This is the primary value-delivery skill.
  — **Done when:** Skill file exists with correct trigger phrases; all Python modules import cleanly; `ppt_builder.py` uses `add_slide(layout)` invariant.
  — **Consumers affected:** `pptx-specialist-subagent.md` (routing), end users generating slides

- [ ] **2.3** **Blocker fix:** Remove `default.pptx` fallback at `ppt_builder.py:102, 1301` → raise `TemplateError`
  — **Why:** Violates user's "no default.pptx" constraint. The builder must fail loudly if no template path is provided rather than silently falling back.
  — **Done when:** `template_path is None` at lines 102 and 1301 raises `TemplateError("template_path is required — provide a user-supplied PPTX template")`. No import/reference to `default.pptx` in `ppt_builder.py`.
  — **Consumers affected:** `generate-slide-skill`, `generate-template-skill`

- [ ] **2.4** **Interactive overflow handling** — replace silent auto-shrink with a `question()`-based decision when a slide's content exceeds its placeholder space
  — **Why:** Per user direction: when the slide's initial content would overflow, the agent should NOT silently shrink text. Instead, it should pause and ask the user via the `question` tool to choose between two explicit paths. This also addresses the underlying `text_fit.py` defect (review §3.3 — estimator returns ~70-85% of real rendered height) by surfacing the overflow rather than under-shrinking it.
  — **Detection mechanism:** `text_fit.py` keeps its pure estimator but is wrapped by a new `overflow_check(slide_data, template_contract)` function that returns one of `{FIT, OVERFLOW}`. `OVERFLOW` triggers the question; `FIT` proceeds silently. The estimator stays "best-effort" — when in doubt, default to `OVERFLOW` (safer to ask than to silently mis-render).
  — **Question presented to user** (single-select, in the language of the user's prompt; option `label`s stay English because they map to engine params):
    ```
    question(questions=[{
      "header": "<translated: Slide N overflow — choose an approach>",
      "question": "<translated: The content for slide N (\"<title>\") exceeds the available space. How would you like to handle it?>",
      "multiple": false,
      "options": [
        {
          "label": "Squeeze into 1 slide",
          "description": "<translated: Keep it as a single slide; the engine will reduce per-placeholder font sizes (e.g., −2pt steps down to an 8pt floor) to fit the content within the original placeholder boundaries.>"
        },
        {
          "label": "Split into 2 slides (Recommended)",
          "description": "<translated: Split the content across two slides. The agent will propose a split point and draft a connecting story so the two slides flow naturally (e.g., 'On slide N: problem + market size; on slide N+1: solution + traction, with a transition line that bridges them').>"
        }
      ]
    }])
    ```
  — **Execution paths:**
    - User picks **Squeeze** → engine calls existing `text_fit.fit_font_size(...)` (verified: chenyu's `text_fit.py` exposes `fit_font_size`, `fits_at_size`, `estimate_lines`, `estimate_height_in` — there is **no** `apply_font_shrink` function) with the new calibrated constants (see 2.4a below); no content rewrite; slide count unchanged; render report sidecar records `overflow_handled: "squeeze"`.
    - User picks **Split** → agent rewrites the overflowing slide into two `slide_data` entries: (a) preserves the user's original speaker message verbatim across both, (b) proposes a content split at a natural breakpoint (paragraph/section boundary), (c) drafts a connecting story (1-line transition on slide N pointing to slide N+1), (d) re-validates with `schema_validator`, (e) renders both. Render report records `overflow_handled: "split"`.
  — **Headless subagent fallback:** when no interactive session is available (no TTY / non-interactive context), the agent applies the **Split** path with safe defaults and emits a notice in the return contract (`Issues:` field). Squeeze is never auto-chosen silently.
  — **Done when:** (a) `overflow_check` function exists and is called by `ppt_builder` before render; (b) interactive sessions present the `question` above; (c) both execution paths are implemented and tested; (d) headless fallback documented and tested; (e) render report sidecar gains an `overflow_handled` field per slide.
  — **Consumers affected:** `generate-slide-skill`, `pptx-specialist-subagent.md` (must allow this one exception to the "never `question()` before first output" rule — overflow questions fire AFTER the first `.pptx` is attempted, during refinement, never before initial render).

- [ ] **2.4a** **Supporting recalibration** of `text_fit.py` constants (powers the Squeeze path of 2.4)
  — **Why:** The Squeeze option in 2.4 still needs `text_fit.py` to produce a valid fit. The current estimator underestimates height (~70-85% of real) and must be calibrated so that when the user picks Squeeze, the resulting font reduction actually makes the text fit.
  — **Done when:** (a) `LINE_SPACING_DEFAULT` raised from 1.2→1.3, (b) `DEFAULT_PARA_SPACING_FACTOR` raised from 0.4→0.7, (c) longest-word overflow term added to height calc (prevents a single long word from breaking the wrap estimate), (d) bullet-indent allowance (~0.25-0.5in) subtracted for body role. All `text_fit.py` tests updated to reflect new estimates.
  — **Consumers affected:** `generate-slide-skill` (Squeeze path only; Split path doesn't depend on text_fit accuracy)

- [ ] **2.4b** **Visual verification via `image-analyzer-subagent`** — use the vision subagent as the "render oracle" chenyu's review §3.3 identified as missing (closes GAP-ANALYSIS Rev 19 deferred AC1: "no overflow guarantee")
  — **Why:** python-pptx has no layout engine, so `text_fit.py`'s estimator is fundamentally best-effort. The only way to truly verify that text fits, sizing is correct, and no overflow/overlap occurs is to **render the slide to an image and have a vision-capable model inspect it**. The user explicitly requested this: "include using image-analyzer-subagent to review screenshots of the pptx to ensure that the sizing all works." This converts the "no overflow" AC from deferred to achievable.
  — **Pipeline (runs AFTER every render, BEFORE returning the file to the user):**
    1. `office-thumbnail-skill` (or `soffice` directly) converts each generated slide to a PNG/JPG at 150 DPI
    2. `pptx-specialist-subagent` dispatches each slide image to `image-analyzer-subagent` via Task tool with a structured prompt (see below)
    3. `image-analyzer-subagent` returns a per-slide verdict: `{sizing_ok: bool, issues: [...], confidence: 0-1}`
    4. Orchestrator decides: all slides `sizing_ok=true` → return file to user; any slide `sizing_ok=false` → route through Phase 2.4 interactive overflow handler (Squeeze/Split question) using the image-derived issues as context
  — **Image-analyzer prompt template** (passed to the subagent for each slide):
    ```
    You are verifying a PowerPoint slide render for sizing correctness.

    Slide image: [attached PNG/JPG]
    Slide title (expected): "<title>"
    Slide type: <slide_type>
    Template content area: <content_area_in2> square inches
    Density mode: <concise|standard|text-heavy>

    Check for these defects (return JSON):
    - text_overflow: Does any text extend beyond its placeholder boundary or the slide edge?
    - text_overlap: Does any text overlap with another element (image, shape, other text)?
    - text_cutoff: Is any text truncated (e.g., last line missing, ellipsis where none expected)?
    - chart_overflow: Does any chart extend beyond its placeholder?
    - image_overflow: Does any image extend beyond its placeholder or the slide edge?
    - visual_balance: Is the content visually balanced within the slide (no large empty regions, no cramped regions)?

    Return: {"sizing_ok": <bool>, "issues": [<list of defects with severity: critical|warning>], "confidence": <0-1>}
    ```
  — **Performance budget:** vision analysis adds ~5-15 seconds per slide (varies by model). For a 10-slide deck, that's ~60-120 seconds of additional latency. Acceptable for the quality guarantee; documented in the return contract's `Issues:` field when slow.
  — **Headless subagent:** the visual verification pipeline STILL RUNS in headless mode (it does not require user interaction). If `image-analyzer-subagent` returns `sizing_ok=false`, the headless fallback applies the Phase 2.4 Split path silently.
  — **Cost governance:** if the user explicitly says "skip visual check" or "fast mode" or "no vision check", the orchestrator MUST honor the opt-out and skip step 2.4b. The return contract must then carry `Issues: visual verification skipped per user request — overflow risk unverified`.
  — **Done when:** (a) post-render pipeline renders each slide to image via `office-thumbnail-skill`; (b) `pptx-specialist-subagent` has `permission.task: image-analyzer-subagent: allow`; (c) `image-analyzer-subagent` is dispatched with the structured prompt above; (d) verdict JSON is parsed and routed correctly (ok→return, fail→Phase 2.4 question); (e) headless path verified; (f) opt-out path verified.
  — **Consumers affected:** `generate-slide-skill`, `pptx-specialist-subagent.md` (permission.task update — Phase 4.1), `image-analyzer-subagent` (load remains unchanged — it already accepts arbitrary images)

- [ ] **2.5** Port + run generate-slide tests; verify green
  — **Why:** Validate the ported skill works end-to-end with the interactive overflow handler, recalibrated text_fit, image-analyzer visual verification, and removed default.pptx dependency.
  — **Done when:** `pytest` for `generate-slide-skill/` passes with zero failures. All tests use `tmp_path` fixtures (no `default.pptx` references). New tests cover: (a) `overflow_check` returns `OVERFLOW` on known-overflowing content; (b) Squeeze path shrinks fonts to fit; (c) Split path produces 2 valid slides with a connecting transition; (d) headless fallback picks Split silently; (e) **post-render image verification pipeline mocked** (real `image-analyzer-subagent` dispatch tested in Phase 6.10, not in unit tests — it requires a live vision model).
  — **Consumers affected:** CI pipeline

### Phase 3 — Extend Skill

- [ ] **3.1** Port `template-modifier-skill/` (`state_machine.py`, `master_cloner.py`, `layout_creator.py`, `constraint_checker.py`)
  — **Why:** The "Extend" skill — adds new layout types to a PPTX's slide master when the user requests a slide type not already present. Powers the "template-modifier → generate-slide" chain.
  — **Done when:** Skill file exists with correct trigger phrases; all Python modules import cleanly (`python -c "import state_machine, master_cloner, layout_creator, constraint_checker"` exits 0 from the skill's scripts dir); `pytest` for state machine transitions passes.
  — **Consumers affected:** `pptx-specialist-subagent.md` (routing)

- [ ] **3.2** **Blocker fix:** `master_cloner.py:86` — fail loudly if no donor available (no default.pptx fallback)
  — **Why:** Currently falls back to `default.pptx` when no donor slide master is available. Per user constraint, must raise an actionable error instead.
  — **Done when:** Line 86 raises `TemplateError("No donor slide master available — provide a template with a slide master or use generate-template-skill first")`. No reference to `default.pptx` in `master_cloner.py`.
  — **Consumers affected:** `template-modifier-skill`

- [ ] **3.3** Port + run template-modifier tests; verify green
  — **Why:** Validate the extend skill works without default.pptx dependency.
  — **Done when:** `pytest` for `template-modifier-skill/` passes with zero failures. All tests use `tmp_path` fixtures.
  — **Consumers affected:** CI pipeline

### Phase 4 — Orchestrator Rewrite

- [ ] **4.1** Rewrite `opencode_app/.opencode/agents/pptx-specialist-subagent.md` with:
  - Conditional trigger matrix (from review §6.2)
  - Relaxed constraints (multilingual OK; preserve original speaker message + suggest transition)
  - `permission.skill:` block updated to allow the 5 routed skills (`generate-slide-skill`, `generate-template-skill`, `template-modifier-skill`, `ooxml-editing-skill`, `office-thumbnail-skill`); REMOVE the now-deleted `pptx-specialist-skill: allow`
  - **`permission.task:` block MUST include `image-analyzer-subagent: allow`** (powers Phase 2.4b post-render visual verification — without this, the orchestrator cannot dispatch the vision subagent to verify slide screenshots)
  - Surgical-edit and html2pptx escape hatches routed to `ooxml-editing-skill` (NOT to a non-existent `pptx-specialist-skill`)
  — **Why:** The current orchestrator assumes html2pptx-first and single-skill routing. Must be rewritten for the multi-skill conditional trigger matrix, the user's relaxed constraints, and the post-decomposition skill set (no more `pptx-specialist-skill` reference). The `image-analyzer-subagent` permission is mandatory to enable the post-render sizing verification the user requested.
  — **Done when:** Agent file contains the full conditional trigger matrix; references all five routed skills by name; `permission.task` includes `image-analyzer-subagent: allow`; multilingual and speaker-note policies documented; `pptx-specialist-skill` is NOT referenced anywhere; escape-hatch routing points to `ooxml-editing-skill` + `office-thumbnail-skill`.
  — **Consumers affected:** All PPTX-related user prompts routed through this agent

- [ ] **4.2** Update tier: stay on `reasoning` (`glm-5.1`) per repo AGENTS.md
  — **Why:** The orchestrator performs conditional routing with 6+ decision paths — correctness-critical reasoning tier is appropriate.
  — **Done when:** Agent's model tier entry in `deploy/agent-tiers.json` or project overrides confirms `reasoning` tier.
  — **Consumers affected:** Model selection at deploy time

### Phase 5 — Documentation & Dependent Sync (per AGENTS.md)

- [ ] **5.1** `deploy/setup.sh` — add 3 chenyu skills + 2 new decomposition skills to listing + banner; update count → 122
  — **Why:** AGENTS.md mandates sync: new skills/agents must be reflected in deploy scripts. Count includes the 5 new skills: `generate-slide-skill`, `generate-template-skill`, `template-modifier-skill`, `ooxml-editing-skill`, `office-thumbnail-skill`. Note `_common/` is shared lib, not a skill.
  — **PRE-EXISTING DRIFT (verified):** `setup.sh` line 666 currently shows `SKILLS (116)` — already stale vs actual 118. Must be corrected to 122, not incremented from 116. The skill listing is a **hardcoded** category-grouped text block (not dynamically computed); update both the count and the category listings. Note: `rsync` at line 2446 deploys ALL dirs including `_common/` — that's correct (shared lib needs deploying), but `_common/` must NOT appear in the skill listing or count.
  — **Done when:** `setup.sh` skill listing contains all 5 new skills; banner shows count 122; `pptx-specialist-skill` is removed from listing; `grep -c "SKILLS (122)" deploy/setup.sh` returns 1.
  — **Consumers affected:** Deploy pipeline, `deploy/setup.ps1` parity

- [ ] **5.2** `deploy/setup.ps1` — Windows parity mirror
  — **Why:** AGENTS.md requires Windows parity for all deploy script changes.
  — **Done when:** `setup.ps1` mirrors `setup.sh` changes from 5.1.
  — **Consumers affected:** Windows deploy users

- [ ] **5.3** `README.md` — update Skill Categories + Subagents tables
  — **Why:** AGENTS.md mandates that new skills appear in the repo's README documentation.
  — **PRE-EXISTING DRIFT (verified):** `README.md` line 329 currently shows "117 skills" — already stale vs actual 118. Must be corrected to 122, not incremented from 117. Lines referencing `pptx-specialist` (Framework category line 335; Subagents table lines 397, 399; Trigger Phrases line 433) must all be updated.
  — **Done when:** README.md Skill Categories table lists the 5 new skills (consider a new "Presentation (template-driven)" category for the chenyu trio + an "Office utilities" category for ooxml-editing + office-thumbnail); Subagents table reflects updated orchestrator description; `pptx-specialist-skill` is removed; line 329 count reads "121 skills".
  — **Consumers affected:** Repository documentation readers

- [ ] **5.4** `opencode_app/README.md` — Docker-specific docs (Python-only PPTX workflow)
  — **Why:** Docker users need to know that PPTX workflows are pure python-pptx (no Node.js / Playwright in the container image). The `ooxml-editing-skill` still requires LibreOffice for some validators; document this.
  — **Done when:** Docker README mentions PPTX stack as Python-only; notes `python-pptx` + `lxml` dependencies; flags `LibreOffice` requirement for `office-thumbnail-skill` and OOXML validators.
  — **Consumers affected:** Docker / containerized deployments

- [ ] **5.5** **Update dependent agents and skills** (4 files: 3 agents + 1 skill) — replace `pptx-specialist-skill` references with new routing
  — **PREREQUISITE:** Phase 4.1 (orchestrator rewrite) must be complete first — dependent routing points to the rewritten `pptx-specialist-subagent` which must already have its new skill set defined.
  — **Why:** The decomposition removes `pptx-specialist-skill` entirely. Every agent that currently references it in `permission.skill:` or in prose must be updated, or it will reference a non-existent skill.
  — **Files to update:**
    - `opencode_app/.opencode/agents/office-document-primary-agent.md` (line 14: `pptx-specialist-skill: allow` — verified) — REPLACE with `ooxml-editing-skill: allow` + `office-thumbnail-skill: allow` + `generate-slide-skill: allow`; OR route PPTX creation through `pptx-specialist-subagent` via Task tool instead
    - `opencode_app/.opencode/agents/startup-ceo-subagent.md` (lines 14, 61, 69 — all verified) — REPLACE skill delegation; route PPTX creation through `pptx-specialist-subagent` Task call
    - `opencode_app/.opencode/agents/discovery-specialist-subagent.md` (lines 24, 114 — both verified) — REPLACE skill delegation; route through `pptx-specialist-subagent` Task call
    - `opencode_app/.opencode/skills/docx-creation-skill/SKILL.md` — ADD references to absorbed helpers (`merge_runs.py`, `simplify_redlines.py`, `validators/docx.py`, `validators/redlining.py`) now confirmed at `docx-creation-skill/scripts/{validators,helpers}/` (identical copies already present per Phase 7.3 finding)
  — **Done when:** `grep -rn "pptx-specialist-skill" opencode_app/.opencode/` returns ZERO matches (excluding historical references in CHANGELOG/migration docs); every previous dependent has a working routing path.
  — **Consumers affected:** startup-ceo, discovery-specialist, office-document workflows

- [ ] **5.6** **Update dependent skills** (3 files) — replace peer-deliverable references
  — **Why:** These skills name `pptx-specialist-skill` / `pptx-specialist-subagent` as the producer of peer presentation deliverables. References must point to the surviving orchestrator subagent (the subagent name is unchanged — only the underlying skill set changes).
  — **Files to update:**
    - `opencode_app/.opencode/skills/vision-creation-skill/SKILL.md` (lines 40, 170) — keep reference to `pptx-specialist-subagent` (subagent survives); remove any `pptx-specialist-skill` mentions
    - `opencode_app/.opencode/skills/startup-pitch-deck-skill/SKILL.md` (line 306) — replace `pptx-specialist-skill` with `pptx-specialist-subagent` (orchestrator routes to the right skill)
    - `opencode_app/.opencode/skills/interactive-document-rendering-skill/SKILL.md` (lines 25, 201) — keep reference to `pptx-specialist-subagent`; remove any `pptx-specialist-skill` mentions
  — **Done when:** All 3 files reference only `pptx-specialist-subagent` (the surviving orchestrator); no mentions of the deleted `pptx-specialist-skill`.
  — **Consumers affected:** Vision, pitch-deck, interactive-document-rendering workflows

### Phase 6 — Human Test Pass

- [ ] **6.1** Extract template from a real user PPTX → verify embedded JSON round-trip
  — **Why:** Core use case: user provides a PPTX, agent extracts its layout structure into JSON and embeds it back.
  — **Done when:** Agent reads a PPTX, produces `template_schema.json`, embeds it, and re-reading confirms identical schema.
  — **Consumers affected:** End users (primary workflow)

- [ ] **6.2** **Always-review-embedded-JSON invariant** — when user supplies any PPTX, the orchestrator probes for `ppt/template_schema.json` first; behavior differs correctly per result
  — **Why:** User invariant #2 — the embedded JSON must always be reviewed when present. It is the authoritative layout reference and drives all routing decisions.
  — **Done when:** For each of three input states: (a) `TEMPLATED` PPTX → JSON consumed as authoritative reference, no re-extraction; (b) `NOT_TEMPLATED` PPTX → "extracting first" notice fires, engine auto-extracts + embeds into output; (c) absent/malformed JSON → never silently mis-routes (clear warning or error).
  — **Consumers affected:** All end users (correctness invariant)

- [ ] **6.3** Generate deck from templated PPTX → verify Slide Master inheritance
  — **Why:** Primary value delivery: user provides templated PPTX, agent generates slides using Slide Master layouts.
  — **Done when:** Generated slides inherit layout properties from the template's Slide Master (fonts, colors, positioning).
  — **Consumers affected:** End users (primary workflow)

- [ ] **6.4** Auto-chain on non-templated PPTX → verify "extracting first" notice + templated output
  — **Why:** When user provides a PPTX without embedded JSON and asks to create a deck, the orchestrator should auto-chain: extract template first, then generate slides.
  — **Done when:** Agent logs "No embedded template found — extracting first" and produces a templated output with embedded JSON.
  — **Consumers affected:** End users (common edge case)

- [ ] **6.5** **Interactive overflow handling** — content that exceeds placeholder space triggers the `question()` tool; both Squeeze and Split paths produce valid output
  — **PREREQUISITE:** Phase 2.4 (overflow_check + question flow) and Phase 2.4a (text_fit recalibration) must be complete.
  — **Why:** New behavior added in Phase 2.4. Replaces silent auto-shrink with user-controlled choice.
  — **Done when:** (a) Deliberately overflow a content slide → `question` tool fires with both options; (b) pick Squeeze → output slide has reduced font sizes, no overflow, render sidecar shows `overflow_handled: "squeeze"`; (c) pick Split → output has 2 slides, original speaker message preserved verbatim across both, a connecting transition line bridges them, sidecar shows `overflow_handled: "split"`; (d) headless context → Split applied silently with notice in return contract.
  — **Consumers affected:** End users (presentation quality + UX)

- [ ] **6.6** Multilingual slide content (e.g., Chinese title + English body) → verify acceptance
  — **Why:** User explicitly relaxed chenyu's English-only constraint. Must verify multilingual content doesn't break layout or text fitting.
  — **Done when:** A deck with mixed-language content (e.g., Chinese title, English body text) generates without errors and text fits within placeholders.
  — **Consumers affected:** Non-English-speaking users

- [ ] **6.7** Speaker notes preserve original user message + auto-suggest transition
  — **Why:** User relaxed chenyu's 4-part mandatory speaker note structure. Agent must preserve the original speaker message verbatim and suggest a transition.
  — **Done when:** Speaker notes contain the original user-provided message unchanged, followed by a suggested transition to the next slide.
  — **Consumers affected:** End users (presentation quality)

- [ ] **6.8** No-default-template error path → user provides no template path and asks "create deck" → engine errors cleanly
  — **Why:** User invariant #1 — no bundled default. The error path must be graceful and actionable.
  — **Done when:** `template_path is None` → agent returns a clear message: "No template supplied. Provide a .pptx path to use as the Slide Master template." Does NOT silently fall back to any bundled file.
  — **Consumers affected:** End users (clear failure mode)

- [ ] **6.9** html2pptx escape hatch still works when explicitly requested
  — **Why:** Users who explicitly say "convert HTML to PPTX" still need a working path. After decomposition, this routes through `ooxml-editing-skill` (or a thin html2pptx wrapper inside it) → `generate-template-skill` (extract+embed) → `generate-slide-skill` (final render). The old `pptx-specialist-skill` no longer exists.
  — **Done when:** User says "convert this HTML to PPTX" and the orchestrator produces a valid PPTX via the routing chain above (with hidden JSON embedded after generation).
  — **Consumers affected:** Users with existing HTML content

- [ ] **6.10** **End-to-end visual verification via `image-analyzer-subagent`** (validates Phase 2.4b in a live session)
  — **Why:** Phase 2.4b specifies the post-render visual verification pipeline, but unit tests (Phase 2.5) can only mock the `image-analyzer-subagent` dispatch — they cannot verify the actual vision-model verdict on a real rendered slide. This step validates the full pipeline live.
  — **Test procedure:**
    1. Generate a deliberately overflowing deck (e.g., a content_slide with 25 bullet points at `standard` density) using a real user-supplied template
    2. Let the post-render pipeline (Phase 2.4b) render each slide to PNG via `office-thumbnail-skill`
    3. Verify `pptx-specialist-subagent` successfully dispatches each PNG to `image-analyzer-subagent` via Task tool
    4. Verify `image-analyzer-subagent` returns the structured JSON verdict (`sizing_ok`, `issues[]`, `confidence`)
    5. Verify the orchestrator correctly interprets the verdict: at least one slide returns `sizing_ok=false` with `issues` listing `text_overflow` or `text_cutoff`
    6. Verify the Phase 2.4 interactive question fires (interactive session) OR the Split fallback fires (headless session)
    7. Verify the user's opt-out signal works: send "skip visual check" before render → pipeline is skipped → `Issues:` field carries the "skipped per user request" notice
  — **Done when:** All 7 sub-steps pass. Capture sample verdict JSONs in `output/visual-verification-samples/` for regression reference.
  — **Consumers affected:** End users (sizing correctness guarantee), CI pipeline (regression baseline)

### Phase 7 — Decompose `pptx-specialist-skill` (after chenyu port is stable)

This phase runs AFTER Phases 1–4 are complete and the chenyu stack is the primary path. Decomposing first would break the existing `pptx-specialist-skill` users before the replacement is ready.

- [ ] **7.1** Create `ooxml-editing-skill/` and port generic Office OOXML files
  — **Why:** Audit revealed that `unpack.py`, `pack.py`, `validate.py`, `clean.py`, `validators/base.py`, and `validators/pptx.py` are generic Office OOXML tools, not PPTX-specific. They were misfiled under a PPTX-named skill and serve DOCX/XLSX/PPTX equally. Promoting them to their own skill makes them discoverable and reusable.
  — **Source files:** `opencode_app/.opencode/skills/pptx-specialist-skill/scripts/{unpack.py, pack.py, validate.py, clean.py}` + `validators/{base.py, pptx.py, __init__.py}`
  — **Target:** `opencode_app/.opencode/skills/ooxml-editing-skill/scripts/` + new `SKILL.md` describing the unpack→edit→pack workflow for any Office file
  — **Done when:** New skill directory exists with all 6 ported files + SKILL.md; imports resolve; `pytest` passes for any ported tests.
  — **Consumers affected:** `pptx-specialist-subagent.md` (new skill in `permission.skill`), `office-document-primary-agent.md`

- [ ] **7.2** Create `office-thumbnail-skill/` and port visual-analysis files
  — **Why:** `thumbnail.py` and `soffice.py` provide visual analysis (thumbnail grids + PDF/image conversion via LibreOffice). They are orthogonal to PPTX creation and deserve their own skill. Useful for DOCX/XLSX/PPTX visual review equally.
  — **Source files:** `opencode_app/.opencode/skills/pptx-specialist-skill/scripts/{thumbnail.py, soffice.py}`
  — **Target:** `opencode_app/.opencode/skills/office-thumbnail-skill/scripts/` + new `SKILL.md`
  — **Done when:** New skill directory exists with both ported files + SKILL.md; `thumbnail.py` runs successfully against a sample PPTX; LibreOffice wrapper handles the AF_UNIX socket restriction.
  — **Consumers affected:** `pptx-specialist-subagent.md`, any skill that generates visual grids

- [ ] **7.3** Delete DOCX-specific files from `pptx-specialist-skill/scripts/` — identical copies already exist in `docx-creation-skill`
  — **Why:** `validators/docx.py`, `validators/redlining.py`, `helpers/merge_runs.py`, `helpers/simplify_redlines.py` are DOCX-specific and were misplaced under a PPTX-named skill. **Verified (2026-07-21):** `diff -q` confirms all 4 files are byte-identical between `pptx-specialist-skill/scripts/{validators,helpers}/` and `docx-creation-skill/scripts/{validators,helpers}/`. The destination subdirectories already exist and already contain these files. This step is therefore a **DELETE from source**, not a move — no file copy is needed.
  — **Source files (to delete):** 4 DOCX-specific files under `pptx-specialist-skill/scripts/{validators,helpers}/`
  — **Target (already populated):** `opencode_app/.opencode/skills/docx-creation-skill/scripts/{validators,helpers}/` — exists and contains identical copies
  — **Done when:** `grep -rn "merge_runs\|simplify_redlines\|validators/docx\|validators/redlining" opencode_app/.opencode/skills/pptx-specialist-skill/` returns zero matches (files deleted from source); `docx-creation-skill/SKILL.md` references them.
  — **Consumers affected:** `docx-creation-skill`
  — **NOTE:** `docx-creation-skill/scripts/` also contains its own copies of `unpack.py`, `pack.py`, `validate.py`, `soffice.py` (overlapping with Phase 7.1's `ooxml-editing-skill` targets) and a full `validators/` directory (`base.py`, `pptx.py`, `__init__.py`). See Risk #9 — this broader DRY duplication is out of scope for BT-142 but should be tracked.

- [ ] **7.4** Move `add_slide.py` into `generate-slide-skill/scripts/`
  — **Why:** `add_slide.py` is a PPTX-specific OOXML surgical-edit tool that fits naturally next to chenyu's python-pptx engine. Lives as an escape hatch for "add a slide to an unpacked PPTX" workflows.
  — **Source file:** `pptx-specialist-skill/scripts/add_slide.py`
  — **Target:** `generate-slide-skill/scripts/ooxml_add_slide.py` (renamed to avoid collision with chenyu's python-pptx-based `add_slide` semantics)
  — **Done when:** File exists at new path with new name; `generate-slide-skill/SKILL.md` mentions it as the surgical-edit alternative.
  — **Consumers affected:** `generate-slide-skill`

- [ ] **7.5** DELETE `pptx-specialist-skill/` entirely
  — **Why:** After all usable files are redistributed (7.1–7.4), the remaining content is the html2pptx workflow in SKILL.md (retired by chenyu) and the directory itself. The skill name is misleading (bundles 3 concerns under a PPTX-misnomer) and conflicts with the surviving `pptx-specialist-subagent` orchestrator. Must be removed to avoid confusion and dual-skill routing ambiguity.
  — **Done when:** `opencode_app/.opencode/skills/pptx-specialist-skill/` directory no longer exists; `grep -rn "pptx-specialist-skill" opencode_app/.opencode/` returns ZERO matches (excluding historical migration docs / CHANGELOG).
  — **Consumers affected:** All Phase 5 dependents must already be updated (5.5, 5.6) before this deletion lands.

- [ ] **7.6** Preserve html2pptx as a thin documented escape hatch inside `ooxml-editing-skill`
  — **Why:** Per user direction, html2pptx is retained only for explicit "convert HTML to PPTX" requests. The Node/pptxgenjs/playwright toolchain stays installed but undocumented; surfaced only via orchestrator routing. Following the hidden-JSON-template approach (extract+embed after html2pptx generation).
  — **Done when:** A short html2pptx section in `ooxml-editing-skill/SKILL.md` documents the explicit-request-only path; toolchain installs verified working.
  — **Consumers affected:** Users with explicit HTML→PPTX conversion needs

## Conditional Trigger Matrix (embed in orchestrator)

| User provides        | User asks                              | Skill invoked                                                              |
| -------------------- | -------------------------------------- | -------------------------------------------------------------------------- |
| PPTX                 | "extract template" / "what layouts"    | `generate-template-skill`                                                    |
| Templated PPTX       | "create deck"                          | `generate-slide-skill`                                                       |
| Non-templated PPTX   | "create deck"                          | `generate-template` → `generate-slide` (chained via `auto_template=True`)      |
| Templated PPTX       | "add slide type not in master"         | `template-modifier` → `generate-slide`                                         |
| PPTX                 | "fix typo on slide 4" / surgical edit  | `ooxml-editing-skill` (unpack → edit XML → pack)                              |
| Any PPTX             | "show me thumbnails" / visual analysis | `office-thumbnail-skill` (LibreOffice → PDF → images)                         |
| HTML                 | "convert html to pptx" (explicit only) | html2pptx wrapper (inside `ooxml-editing-skill`) → `generate-template` → `generate-slide` |
| Nothing              | "create deck"                          | **ERROR**: template required                                                 |

> **Matrix gap (non-blocking):** "Non-templated PPTX + add slide type not in master" is not a separate row. The orchestrator should chain: `generate-template` (extract first) → `template-modifier` (add layout) → `generate-slide` (fill). This is implied by combining rows 3 + 4 but should be documented explicitly in the orchestrator prompt (Phase 4.1) to avoid ambiguous routing.

## Risks

1. `text_fit.py` recalibration (Phase 2.4a) may shift visual output for existing chenyu tests — snapshot update may be needed. Mitigated by the fact that the new primary path is **Split** (user choice), not silent Squeeze.
2. Removing `default.pptx` breaks 15+ chenyu tests (per review §8.4) — all must be rewritten to use `tmp_path` fixtures or in-code minimal theme.
3. Multilingual content requires auditing any English-only assertions in chenyu's test suite.
4. **Phase 7 decomposition order matters.** Phases 1–4 (chenyu port + orchestrator rewrite) MUST land before Phase 7 (decommission `pptx-specialist-skill`). Decomposing first would break existing users of `office-document-primary-agent`, `startup-ceo-subagent`, etc. before replacements are wired.
5. **3 dependent agents + 3 dependent skills (Phase 5.5/5.6) + `pptx-specialist-subagent.md` itself (Phase 4.1 rewrite) need their `pptx-specialist-skill` references updated.** Verified: `grep -rln "pptx-specialist-skill" opencode_app/.opencode/` returns 8 files. A single missed reference breaks routing silently. (Original draft incorrectly stated "5 dependent agents + 3 dependent skills" — corrected after repo audit.)
6. **Interactive overflow question (Phase 2.4) is a one-off exception to chenyu's "never `question()` before first output" rule.** The exception is scoped: the question fires only AFTER the first render attempt detects overflow, never during initial generation. Must be documented prominently in the rewritten orchestrator prompt (Phase 4.1) to prevent the agent from over-using `question()`.
7. **Headless fallback choice (Split) may surprise users** who expected Squeeze in CI/batch contexts. Mitigation: the return contract's `Issues:` field always reports which path was taken.
8. **Skill count math:** 118 (current, verified via `ls -d opencode_app/.opencode/skills/*/ | wc -l`) + 3 (chenyu) + 2 (ooxml-editing + office-thumbnail) − 1 (pptx-specialist-skill removed) = **122**. **IMPORTANT — pre-existing count drift:** `deploy/setup.sh` banner (line 666) currently shows `SKILLS (116)` and `README.md` (line 329) shows `117` — both are ALREADY stale vs the actual 118. Phase 5.1/5.3 must correct these to 122, not just bump from the stale numbers. **Directory count divergence:** post-migration `ls -d */` yields 123 (includes `_common/`), but the skill count is 122 because `_common/` has no `SKILL.md`. Banner and README must use 122 (skill count), not 123 (raw directory count).
9. **Pre-existing DRY duplication between `pptx-specialist-skill` and `docx-creation-skill`.** Verified (2026-07-21): `docx-creation-skill/scripts/` already contains byte-identical copies of ALL validators (`base.py`, `docx.py`, `pptx.py`, `redlining.py`, `__init__.py`) and helpers (`merge_runs.py`, `simplify_redlines.py`), PLUS its own `unpack.py`, `pack.py`, `validate.py`, `soffice.py`. Phase 7.1 creates `ooxml-editing-skill` from `pptx-specialist-skill`'s copies, but `docx-creation-skill` will still retain its own duplicate set. This is a **third copy** of the same OOXML tooling. Out of scope for BT-142, but must be tracked for a future deduplication pass.
10. **`python-pptx` version drift** may break ported chenyu code if the deploy target has a different version than chenyu's development environment. Mitigation: pin `python-pptx` in requirements and test against the pinned version in Phase 1.3/2.5/3.3.
11. **Corrupt or malformed user-supplied PPTX** may crash `schema_extractor` or `ppt_builder` before the overflow check or template validation runs. Mitigation: wrap `schema_extractor` entry point in a try/except that returns a structured `SchemaExtractionError` with the underlying exception message, rather than an unhandled crash.
12. **Concurrent edits to the same PPTX** (two users embedding different schemas) could produce conflicting `template_schema.json` payloads. Mitigation: document that embedded JSON is single-writer; if concurrent edit is needed, use file-level locking outside the engine's scope.
13. **Vision analysis latency adds ~5-15 seconds per slide** (Phase 2.4b). A 10-slide deck gains 60-120 seconds of additional render time. Mitigation: (a) user opt-out ("skip visual check" / "fast mode"); (b) parallel dispatch where possible (Task tool supports concurrent subagent calls); (c) return contract's `Issues:` field surfaces the time cost transparently.
14. **Vision model false positives/negatives in `image-analyzer-subagent`** could either block good renders (false overflow) or pass bad ones (missed overflow). Mitigation: (a) confidence score in the verdict JSON — below 0.7 confidence, fall through to Phase 2.4 question (let the user decide); (b) regression baseline (Phase 6.10 step 7) captures known-good verdicts for comparison; (c) the `text_fit.py` estimator (Phase 2.4a) remains the primary detector — vision is the confirmation oracle, not the only signal.
15. **`image-analyzer-subagent` availability dependency.** If the vision MCP server is down or unconfigured, Phase 2.4b cannot run. Mitigation: the orchestrator must treat vision-subagent dispatch failure as a soft error — fall back to the `text_fit.py` estimator verdict alone, emit `Issues: visual verification unavailable — sizing verified by estimator only (lower confidence)`. Never hard-fail the render due to vision-subagent unavailability.

## Open Questions (defer to primary agent)

1. ~~Confirm "keep `pptx-specialist-skill` as escape hatch" vs full retirement~~ **— RESOLVED.** Decompose into `ooxml-editing-skill` + `office-thumbnail-skill`, redistribute DOCX files to `docx-creation-skill`, delete `pptx-specialist-skill` entirely. See Phase 7.
2. ~~Confirm subagent tier (`reasoning` / `glm-5.1`) for rewritten orchestrator (review §11 Q8).~~ **— RESOLVED.** `reasoning` tier (`glm-5.1`) is confirmed: the orchestrator performs conditional routing with 6+ decision paths (correctness-critical). This matches repo AGENTS.md tier guidance and is already actioned in Phase 4.2.
3. Confirm html2pptx Node toolchain retention (review §11 Q2) — current PLAN assumes retained as undocumented escape hatch inside `ooxml-editing-skill` (Phase 7.6).
4. **NEW:** Confirm the 3-way split (ooxml-editing + office-thumbnail + absorb DOCX helpers into docx-creation) vs a 2-way merge (single `office-utils-skill` combining ooxml + thumbnail). PLAN currently assumes 3-way for single-responsibility clarity; 2-way would yield skill count 121 instead of 122.
5. **NEW:** Should `ooxml-editing-skill` cover DOCX/PPTX/XLSX uniformly, or specialize per format (split into `docx-ooxml-skill`, `pptx-ooxml-skill`, `xlsx-ooxml-skill`)? PLAN assumes uniform (one skill, format-aware validators); specialization would push skill count higher.
6. **NEW:** Should `office-thumbnail-skill` also absorb the markitdown-based content extraction (currently in `pptx-specialist-skill`'s narrative), or stay narrow (thumbnail + soffice only)? PLAN assumes narrow.
7. **NEW:** When `pptx-specialist-subagent` is rewritten (Phase 4.1), should it route deck-creation requests from peer agents (startup-ceo, discovery-specialist) via Task tool dispatch, or via direct skill invocation? PLAN currently assumes Task tool dispatch (consistent with our hub-and-spoke pattern).
