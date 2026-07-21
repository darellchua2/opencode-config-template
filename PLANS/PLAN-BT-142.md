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
| Extract          | `pptx-generate-template-skill/`                                                                                                         | `opencode_app/.opencode/skills/pptx-generate-template-skill/`                                               |
| Fill             | `pptx-generate-slide-skill/` (incl. `ppt_builder.py`)                                                                                   | `opencode_app/.opencode/skills/pptx-generate-slide-skill/`                                                  |
| Extend           | `pptx-template-modifier-skill/`                                                                                                         | `opencode_app/.opencode/skills/pptx-template-modifier-skill/`                                                |
| Orchestrator     | `agents/pptx-subagent.md` (thin rewrite)                                                                                           | `opencode_app/.opencode/agents/pptx-specialist-subagent.md` (REWRITE)                                  |

**New skills created by Phase 7 decomposition** (split out of the misnamed `pptx-specialist-skill`):

| New skill                  | Source files (from `pptx-specialist-skill/scripts/`)                                                       | Responsibility                                        |
| -------------------------- | ----------------------------------------------------------------------------------------------------------- | ----------------------------------------------------- |
| `ooxml-editing-skill`        | `unpack.py`, `pack.py`, `validate.py`, `clean.py`, `validators/base.py`, `validators/pptx.py`                  | Generic Office OOXML unpack/pack/validate — surgical edits, supports all .docx/.pptx/.xlsx |
| `office-thumbnail-skill`     | `thumbnail.py`, `soffice.py`                                                                                  | Visual analysis — thumbnail grids + PDF/image conversion via LibreOffice              |
| (merge into `docx-creation-skill`) | `validators/docx.py`, `validators/redlining.py`, `helpers/merge_runs.py`, `helpers/simplify_redlines.py` | DOCX-specific helpers — were misplaced under a PPTX-named skill                       |
| (merge into `pptx-generate-slide-skill`) | `add_slide.py` (PPTX-specific OOXML slide add)                                                                | PPTX surgical-edit escape hatch — lives next to the python-pptx engine                |
| **DELETE**                   | `pptx-specialist-skill/SKILL.md` html2pptx workflow section                                                    | Retired by chenyu's stack; 1-paragraph stub retained only for explicit "html→pptx" requests routed by the orchestrator |

## Engine Hard Limits (gap analysis — discovered BT-142 session 2026-07-21)

The chenyu engine has **5 hard limits** that surface when filling designer-style templates (multiple bespoke layouts, multi-image slides, multi-body slides). These are schema/engine constraints, not bugs — chenyu designed around the 8 classical PowerPoint content types. Each must be addressed before the migrated stack can handle real-world pitch decks (e.g. BETEKK V9.1.1 — 10 distinct layouts, multi-image team/logo slides).

| #   | Limit                          | Code evidence                                                                                       | Impact                                                                                       | Workaround (interim)                                  | Permanent fix              |
| --- | ------------------------------ | --------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------- | ---------------------------------------------------- | -------------------------- |
| L1  | **8 `slide_type` enum cap**        | `schemas/slide_schemas.py:98-139` — exactly 8 types (no `team_slide`/`cover_slide`/`ask_slide`)         | Decks needing >8 semantically distinct layouts cannot be rendered in one pass                | Multi-pass render + merge (Phase 3.5a)               | Phase 3.6 — open slide_type registry |
| L2  | **One image per slide**            | `ppt_builder.py:1596-1598` — `slide_data["image_path"]` is a single string; `_add_image_to_slide` runs once | Team (4 photos), Market Validation (5 logos) under-filled                                   | Post-render backfill by placeholder index (Phase 3.5b) | Phase 3.6 — `image_paths: [...]` array field |
| L3  | **Two body placeholders max**      | `ppt_builder.py:1544-1590` — only `body_left`/`body_right` (the `_LAYOUTS_WITH_TWO_BODIES` set); no `body_3`+ | Team (4–6 bio boxes), Business Model (multi-card grid) under-filled                          | Post-render backfill by index (Phase 3.5b)            | Phase 3.6 — `body_slots: [...]` array field |
| L4  | **First PICTURE placeholder only** | `_add_image_to_slide` fills the first matching PICTURE placeholder; ignores additional ones         | Multi-picture layouts (S6 demo screenshots) under-filled                                     | Post-render backfill (Phase 3.5b)                     | Folded into L2 fix         |
| L5  | **Notes-master dependency**        | `_set_notes(slide, notes_text)` returns falsy when template's notes master lacks a notes-text placeholder | BETEKK Template V1 has no notes body placeholder → notes silently dropped                    | Probe + add notes body placeholder before fill (Phase 3.5c) | Documented contract requirement |

**Takeaway:** the engine is **single-layout-single-image-single-body** by design. Real decks violate all three assumptions simultaneously. The interim multi-pass + backfill pipeline (Phase 3.5) restores correctness without rewriting the engine; the permanent fix (Phase 3.6 — array fields + open registry) is deferred post-migration.

## Empty Slide Master Gap (gap analysis — discovered BT-142 session 2026-07-21)

**Scenario:** a user supplies a designer PPTX whose Slide Master is **empty** (one blank `DEFAULT` layout, zero placeholders, all branding baked per-shape on each of the 10 hand-crafted slides). This is the BETEKK V9.1.0 shape. Current routing:

- `pptx-generate-template-skill` extracts the schema but reports "stock Office theme, single blank layout" — useless for fill
- `pptx-generate-slide-skill` cannot fill against a blank layout
- `pptx-template-modifier-skill` borrows layouts from a **donor** template — but here the donor *is the user's own deck*, and its layouts are also blank

**End-user intent (mimic PowerPoint):** when a designer has 10 beautiful hand-crafted slides and wants reusable layouts, they open **Slide Master view → Add Layout → design the layout (or right-click an existing slide → "Add to Master")**. The slides become **children of the master**, inheriting theme/fonts/colors while exposing editable placeholders.

**Engine gap:** no skill performs this promotion. `pptx-template-modifier-skill` clones layouts *from* a donor *into* the target; it does not **reverse-engineer per-shape slide structure into named layouts with real placeholders**. Phase 3.4 adds this as Capability C.

**Container-fit sub-gap:** when layouts *are* promoted, text placeholders often extend beyond their visual container shapes (orange card, teal panel). End-user designers see this immediately in PowerPoint; the engine has no static check and the image-analyzer prompt (Phase 2.4b) does not currently look for it. Phase 2.4c adds a `container_overflow` check dimension.

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
- `opencode_app/.opencode/agents/pptx-specialist-subagent.md` — REPLACE `pptx-specialist-skill: allow` with `pptx-generate-slide-skill/pptx-generate-template-skill/pptx-template-modifier-skill/ooxml-editing-skill/office-thumbnail-skill: allow`
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

- [x] **1.1** Port `_common/scripts/` to `opencode_app/.opencode/skills/_common/scripts/`
  — **Why:** All three new skills depend on shared schema extraction, layout contracts, geometry helpers, error types, and template introspection. Must land first.
  — **Done when:** All `_common/scripts/*.py` files exist in target dir and `python -c "import sys; sys.path.insert(0,'opencode_app/.opencode/skills/_common/scripts'); import schema_extractor, layout_contract, contract_adapter, geometry, errors, master_repairer, template_introspector"` exits 0.
  — **Consumers affected:** `pptx-generate-template-skill`, `pptx-generate-slide-skill`, `pptx-template-modifier-skill`

- [x] **1.2** Port `schemas/template_schema.json` to `opencode_app/.opencode/skills/_common/schemas/`
  — **Why:** The canonical JSON schema that defines what gets embedded in PPTX files. Referenced by schema_extractor and schema_validator.
  — **Done when:** JSON file validates against its own `$schema` key (if present) and `schema_validator.py` can load it.
  — **Consumers affected:** `pptx-generate-template-skill`, `pptx-generate-slide-skill`

- [x] **1.3** Run ported `_common` tests under pytest; verify green
  — **Why:** Catch import errors, path issues, and Python version mismatches early before downstream skills are built on top.
  — **Done when:** `pytest opencode_app/.opencode/skills/_common/` passes with zero failures.
  — **Consumers affected:** CI pipeline (once tests are added to repo)

- [x] **1.4** **Blocker fix:** Add schema version drift handling to `read_embedded_schema` (`schema_extractor.py:1378-1415`)
  — **Why:** Currently `SCHEMA_VERSION = "1.1.0"` is written on embed but never validated on read. A schema change could silently produce broken slides.
  — **Done when:** `read_embedded_schema` compares `major.minor.patch` — warns on minor mismatch, raises `SchemaVersionError` on major mismatch, auto-upgrades patch mismatches.
  — **Consumers affected:** All skills that call `read_embedded_schema` (generate-template, generate-slide)

- [x] **1.5** **Blocker fix:** Embed in-code minimal theme XML in `master_repairer.py` (drops default.pptx dependency for L3)
  — **Why:** `master_repairer.py` L2/L3 currently falls back to `default.pptx` to source theme XML. Per user constraint, no `default.pptx` shall exist. Replace with ~30 lines of in-code minimal theme XML (12 OPC color roles + major/minor fonts).
  — **Done when:** `master_repairer.py` has no import or path reference to `default.pptx`; L3 repair uses in-code theme XML; existing tests pass with updated fixtures.
  — **Consumers affected:** `pptx-generate-slide-skill`, `pptx-template-modifier-skill`

### Phase 2 — Extract + Fill Skills (coupled via embedded JSON contract)

- [x] **2.1** Port `pptx-generate-template-skill/` (SKILL.md + wraps `schema_extractor`)
  — **Why:** First half of the workflow — extracts layout fingerprints from user PPTX and produces `template_schema.json` for embedding. The "Extract" leg of the Extract→Fill pipeline.
  — **Done when:** Skill file exists with correct trigger phrases; `grep -c "schema_extractor" opencode_app/.opencode/skills/pptx-generate-template-skill/SKILL.md` returns ≥1; SKILL.md `_common/scripts/schema_extractor.py` path reference resolves.
  — **Consumers affected:** `pptx-specialist-subagent.md` (routing)

- [x] **2.2** Port `pptx-generate-slide-skill/` (SKILL.md + `ppt_builder.py` + `text_fit.py` + `density_mode.py` + `schema_validator.py` + `outline_store.py` + `coordinate_placer.py` + `resolvers/`)
  — **Why:** The core "Fill" skill — takes a templated PPTX + user content spec and produces new slides using Slide Master layouts. This is the primary value-delivery skill.
  — **Done when:** Skill file exists with correct trigger phrases; all Python modules import cleanly; `ppt_builder.py` uses `add_slide(layout)` invariant.
  — **Consumers affected:** `pptx-specialist-subagent.md` (routing), end users generating slides

- [x] **2.3** **Blocker fix:** Remove `default.pptx` fallback at `ppt_builder.py:102, 1301` → raise `TemplateError`
  — **Why:** Violates user's "no default.pptx" constraint. The builder must fail loudly if no template path is provided rather than silently falling back.
  — **Done when:** `template_path is None` at lines 102 and 1301 raises `TemplateError("template_path is required — provide a user-supplied PPTX template")`. No import/reference to `default.pptx` in `ppt_builder.py`.
  — **Consumers affected:** `pptx-generate-slide-skill`, `pptx-generate-template-skill`

- [x] **2.4** **Interactive overflow handling** — replace silent auto-shrink with a `question()`-based decision when a slide's content exceeds its placeholder space
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
  — **Consumers affected:** `pptx-generate-slide-skill`, `pptx-specialist-subagent.md` (must allow this one exception to the "never `question()` before first output" rule — overflow questions fire AFTER the first `.pptx` is attempted, during refinement, never before initial render).

- [x] **2.4a** **Supporting recalibration** of `text_fit.py` constants (powers the Squeeze path of 2.4)
  — **Why:** The Squeeze option in 2.4 still needs `text_fit.py` to produce a valid fit. The current estimator underestimates height (~70-85% of real) and must be calibrated so that when the user picks Squeeze, the resulting font reduction actually makes the text fit.
  — **Done when:** (a) `LINE_SPACING_DEFAULT` raised from 1.2→1.3, (b) `DEFAULT_PARA_SPACING_FACTOR` raised from 0.4→0.7, (c) longest-word overflow term added to height calc (prevents a single long word from breaking the wrap estimate), (d) bullet-indent allowance (~0.25-0.5in) subtracted for body role. All `text_fit.py` tests updated to reflect new estimates.
  — **Consumers affected:** `pptx-generate-slide-skill` (Squeeze path only; Split path doesn't depend on text_fit accuracy)

- [x] **2.4b** **Visual verification via `image-analyzer-subagent`** — use the vision subagent as the "render oracle" chenyu's review §3.3 identified as missing (closes GAP-ANALYSIS Rev 19 deferred AC1: "no overflow guarantee")
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
    - container_overflow: Does any text extend beyond its **visual container** (colored card, accent panel, decorative shape) — i.e. text spilling outside the orange/teal box it is meant to sit inside? [Added Phase 2.4c — see BT-142 session 2026-07-21; BETEKK V9.1.1 slide 4 is the canonical example.]

    Return: {"sizing_ok": <bool>, "issues": [<list of defects with severity: critical|warning>], "confidence": <0-1>}
    ```
  — **Performance budget:** vision analysis adds ~5-15 seconds per slide (varies by model). For a 10-slide deck, that's ~60-120 seconds of additional latency. Acceptable for the quality guarantee; documented in the return contract's `Issues:` field when slow.
  — **Headless subagent:** the visual verification pipeline STILL RUNS in headless mode (it does not require user interaction). If `image-analyzer-subagent` returns `sizing_ok=false`, the headless fallback applies the Phase 2.4 Split path silently.
  — **Cost governance:** if the user explicitly says "skip visual check" or "fast mode" or "no vision check", the orchestrator MUST honor the opt-out and skip step 2.4b. The return contract must then carry `Issues: visual verification skipped per user request — overflow risk unverified`.
  — **Done when:** (a) post-render pipeline renders each slide to image via `office-thumbnail-skill`; (b) `pptx-specialist-subagent` has `permission.task: image-analyzer-subagent: allow`; (c) `image-analyzer-subagent` is dispatched with the structured prompt above; (d) verdict JSON is parsed and routed correctly (ok→return, fail→Phase 2.4 question); (e) headless path verified; (f) opt-out path verified.
  — **Consumers affected:** `pptx-generate-slide-skill`, `pptx-specialist-subagent.md` (permission.task update — Phase 4.1), `image-analyzer-subagent` (load remains unchanged — it already accepts arbitrary images)

- [x] **2.5** Port + run generate-slide tests; verify green
  — **Why:** Validate the ported skill works end-to-end with the interactive overflow handler, recalibrated text_fit, image-analyzer visual verification, and removed default.pptx dependency.
  — **Done when:** `pytest` for `pptx-generate-slide-skill/` passes with zero failures. All tests use `tmp_path` fixtures (no `default.pptx` references). New tests cover: (a) `overflow_check` returns `OVERFLOW` on known-overflowing content; (b) Squeeze path shrinks fonts to fit; (c) Split path produces 2 valid slides with a connecting transition; (d) headless fallback picks Split silently; (e) **post-render image verification pipeline mocked** (real `image-analyzer-subagent` dispatch tested in Phase 6.10, not in unit tests — it requires a live vision model).
  — **Consumers affected:** CI pipeline

### Phase 3 — Extend Skill

- [x] **3.1** Port `pptx-template-modifier-skill/` (`state_machine.py`, `master_cloner.py`, `layout_creator.py`, `constraint_checker.py`)
  — **Why:** The "Extend" skill — adds new layout types to a PPTX's slide master when the user requests a slide type not already present. Powers the "template-modifier → generate-slide" chain.
  — **Done when:** Skill file exists with correct trigger phrases; all Python modules import cleanly (`python -c "import state_machine, master_cloner, layout_creator, constraint_checker"` exits 0 from the skill's scripts dir); `pytest` for state machine transitions passes.
  — **Consumers affected:** `pptx-specialist-subagent.md` (routing)

- [x] **3.2** **Blocker fix:** `master_cloner.py:86` — fail loudly if no donor available (no default.pptx fallback)
  — **Why:** Currently falls back to `default.pptx` when no donor slide master is available. Per user constraint, must raise an actionable error instead.
  — **Done when:** Line 86 raises `TemplateError("No donor slide master available — provide a template with a slide master or use pptx-generate-template-skill first")`. No reference to `default.pptx` in `master_cloner.py`.
  — **Consumers affected:** `pptx-template-modifier-skill`

- [x] **3.3** Port + run template-modifier tests; verify green
  — **Why:** Validate the extend skill works without default.pptx dependency.
  — **Done when:** `pytest` for `pptx-template-modifier-skill/` passes with zero failures. All tests use `tmp_path` fixtures.
  — **Consumers affected:** CI pipeline

### Phase 3.4 — Capability C: Promote Designer Slides to Empty Master (NEW — BT-142 session 2026-07-21)

**Trigger:** user supplies a PPTX whose Slide Master is empty/blank (zero or one layout, no placeholders, all branding per-shape). End-user intent: turn the 10 designed slides into named layouts **attached to the slide master** (mimics PowerPoint's Slide Master view → Add Layout, or right-click slide → "Add to Master").

**Why:** current `pptx-template-modifier-skill` (Capability B) borrows a layout **from a donor template** when the target is missing one. It does not reverse-engineer a slide's per-shape structure into a **named layout with real placeholders** on the target's own master. Without Capability C, every designer deck with bespoke slides is unfillable — `pptx-generate-slide-skill` will refuse (no layouts) or produce a generic Office-looking output.

- [x] **3.4.1** New module `pptx-template-modifier-skill/scripts/designer_promoter.py`
  — **Inputs:** source PPTX path, optional layout-name map `{slide_index: "Team"}`, optional theme XML override.
  — **Outputs:** new `<source>_template.pptx` with: (a) rewritten Slide Master theme (major/minor fonts, 12 OPC color roles from the source's per-shape palette — not stock Office), (b) N named layouts (one per source slide), each with proper **text/picture/table placeholders** (not loose shapes), (c) decorative brand shapes (cards, accent bars, dividers) baked into each layout as non-placeholder shapes, (d) the original N slides stripped (template = 0 slides, N layouts).
  — **Algorithm (per source slide):**
    1. **Cluster shapes by role** — headline (largest font, top region) → TITLE placeholder; body text blocks → BODY placeholders (in reading order); image shapes → PICTURE placeholders; table shapes → TABLE placeholder; everything else → decorative (kept as shape, not placeholder).
    2. **Allocate placeholder indices** — TITLE=0, BODY=1..n by reading order, PICTURE/TABLE by position.
    3. **Promote to layout** — clone the slide as a new `SlideLayout` under the master; convert each clustered shape to its placeholder type via `python-pptx` (placeholder `type` attribute) or raw OOXML (the python-pptx API for adding placeholders to a fresh layout is limited — likely needs the `lxml`-backed escape hatch used by `layout_creator.py`).
    4. **Inherit theme from master** — placeholders pick up fonts/colors from the rewritten theme; per-shape `rPr` overrides are stripped so the layout is theme-driven (matches the end-user "Add to Master" behavior).
    5. **Strip source slide** — keep only the layouts, not the original slides (template ≠ deck).
  — **Done when:** for the BETEKK V9.1.0 source (10 slides, empty master), the output template has: (a) 10 named layouts (Cover, Story, Problem Impact, Problem, Solution/Brand, Solution/Demo, Market Validation, Business Model, Team, Ask/Closing), (b) ≥95 placeholders total across the 10 layouts, (c) theme XML uses Century Gothic + the BETEKK teal/zinc palette (verified via `grep` of `theme/theme1.xml`), (d) `pptx-specialist-subagent` can generate a deck against this template without per-shape restyling.
  — **Consumers affected:** `pptx-template-modifier-skill/SKILL.md` (new Capability C section), `pptx-specialist-subagent.md` (new routing row), end users with designer decks

- [x] **3.4.2** Pre-flight: static **container-fit check** for promoted layouts
  — **Why:** when placeholders are reverse-engineered from per-shape branding, a text placeholder's bounding box often extends beyond its visual container shape (orange card, teal panel) — exactly the BETEKK V9.1.1 slide 4 defect. A static geometry check catches this before any render.
  — **New module:** `pptx-template-modifier-skill/scripts/container_check.py`
  — **Function:** `container_violations(layout) -> List[{placeholder_idx, container_shape_id, overflow_px, severity}]`
  — **Algorithm:** for each TITLE/BODY placeholder on a layout, find the nearest decorative shape whose bounding box geometrically contains the placeholder's center point (point-in-rect). If found, verify the placeholder's rect fits inside the container's rect (with optional padding tolerance, default 4px). Report violations grouped by severity (critical > 20px overflow, warning 4–20px).
  — **Integration:** called automatically at the end of `designer_promoter.promote()`; violations emit as warnings in the build report and `Issues:` field of the subagent return contract. Critical violations block the template (raise `ContainerFitError`); warnings allow the build but flag for the orchestrator to address (extend container, shorten text, or move placeholder).
  — **Done when:** running `container_check` on the BETEKK V1 template flags slide 4's known text-vs-orange-box overflow (and any other violations); after the fix is applied, re-running returns zero critical violations.
  — **Consumers affected:** `pptx-template-modifier-skill`, downstream `pptx-specialist-subagent` visual verification

- [x] **3.4.2b** Pre-flight: static **WCAG 2.1 contrast check** for promoted layouts (NEW — BT-142 session 2026-07-21)
  — **Why:** promoted placeholders inherit theme defaults (often dark `dk1`) which can be invisible on dark cards. Even original designer slides often have implicit contrast assumptions that fail WCAG AA — e.g. BETEKK V9.1.1 surfaced 53 critical violations (mostly light text on `#2DD4BF` teal = 1.47:1 ratio, and `#FB923C` orange on orange = 1.0:1 ratio — literally invisible).
  — **New module:** `pptx-template-modifier-skill/scripts/contrast_check.py`
  — **Function:** `contrast_violations(layout, theme, auto_fix=False) -> List[ContrastViolation]` + `contrast_ratio(fg, bg) -> float` (WCAG 2.1 math)
  — **Algorithm:** for each TITLE/BODY placeholder, resolve effective foreground (explicit run rPr → theme `dk1` default) and effective background (container fill → theme `lt1` → white). Compute WCAG contrast ratio. Required: 4.5:1 (normal text <18pt), 3:1 (large text ≥18pt). Severity: <3.0 critical, <4.5 warning.
  — **Auto-fix (opt-in, default ON in `promote_designer_slides`):** override the placeholder's default run color (`<a:defRPr><a:solidFill><a:srgbClr>`) to white or black based on background luminance. The violation is still reported with `auto_fixed=True` so the orchestrator knows what changed.
  — **Done when:** running on BETEKK V9.1.1 surfaces the 53 critical violations; auto-fix resolves 43 (81%); the remaining 10 (`#FB923C` orange-on-orange) require human design decisions and are flagged in the report.
  — **Consumers affected:** `pptx-template-modifier-skill`, `designer_promoter`, downstream `pptx-specialist-subagent`

- [x] **3.4.3** Extend `image-analyzer-subagent` dispatch prompt (Phase 2.4b) with `container_overflow` dimension
  — **Why:** the static check (3.4.2) catches the geometric mismatch at build time, but rendered text can still spill due to font metrics, wrapping, or dynamic content length. The vision oracle must also look for it — defense in depth.
  — **Done when:** Phase 2.4b's image-analyzer prompt template carries the `container_overflow` bullet (already added in this session, see Phase 2.4b diff); the dispatch routing in `pptx-specialist-subagent.md` Stage 5 routes any `container_overflow: critical` verdict back to the orchestrator for Squeeze/Split re-prompt (Phase 2.4) OR a placeholder-resize pass.
  — **Consumers affected:** `pptx-specialist-subagent.md` Stage 5, `image-analyzer-subagent` (no load change — prompt is per-dispatch)

- [x] **3.4.4** Document Capability C in `pptx-template-modifier-skill/SKILL.md`
  — **Why:** Capability C is a sibling to Capability B (donor clone). SKILL.md must describe when to use C vs B and the inputs/outputs.
  — **Done when:** SKILL.md has a new "Capability C: Promote Designer Slides" section with: trigger (empty master + designed slides), inputs (source PPTX, optional name map, optional theme), outputs (templated PPTX with N named layouts), the 5-step algorithm summary, and the container-fit pre-flight note. Capability B section gains a one-line cross-link.
  — **Consumers affected:** `pptx-specialist-subagent.md` routing prose, skill discoverability

- [x] **3.4.1b** New module `pptx-template-modifier-skill/scripts/vision_extractor.py` (NEW — BT-142 session 2026-07-21)
  — **Why:** XML-based extraction is precise on geometry but loses design intent — most notably the slide background color, which designer decks encode as a large fill rectangle rather than via `<p:cSld><p:bg>`. Without vision, promoted layouts render with a white background even though every shape on them is dark.
  — **Pipeline:** `render_slides_to_pngs(pptx)` via `soffice` → PDF → `pdftoppm`; `build_image_analyzer_prompt(i, n, png, pptx_name)` returns the structured prompt; orchestrator dispatches each PNG to `image-analyzer-subagent` via Task tool; `aggregate_vision_results(raw)` coerces JSON strings / prose-wrapped JSON / dicts into typed `VisionSlideSchema`; `fallback_xml_background(slide, theme)` covers the case where soffice or subagent is unavailable — reads raw shape XML for both `srgbClr` (direct RGB) and `schemeClr` (theme reference incl. ECMA-376 aliases `tx1`/`dk1`, `bg1`/`lt1`).
  — **Integration with designer_promoter:** vision-derived `dominant_bg_hex` (confidence ≥ 0.5) overrides XML fallback for layout `<p:cSld><p:bg>` injection; XML continues to provide precise shape geometry.
  — **Done when:** `vision_extractor.py` module + 14 tests pass; orchestrator Stage -1.5 dispatches to `image-analyzer-subagent`; soft-falls to XML when subagent unavailable.
  — **Consumers affected:** `designer_promoter`, `pptx-specialist-subagent.md`

- [x] **3.4.1c** Inject Slide Master background (not just per-layout) (NEW — BT-142 session 2026-07-21)
  — **Why:** even with `<p:bg>` set on every promoted layout, the Slide Master itself (parent of all layouts) retains PowerPoint's default `<p:bgRef idx="1001"><a:schemeClr val="bg1"/></p:bgRef>` which resolves to theme `lt1` — white in a dark-mode deck. Result: the master thumbnail in PowerPoint's Slide Master view looks off-brand (white base), and any layout that doesn't override `<p:bg>` inherits white. Setting the master bg makes the 'base' consistent with the deck's brand identity.
  — **Implementation:** `_compute_dominant_master_bg(slides, theme)` tallies each source slide's dominant bg (via XML or vision) and picks the most common. `_inject_master_background(prs, hex)` replaces the master's default `<p:bgRef>` with a solid `<p:bgPr><a:solidFill><a:srgbClr val="..."/></a:solidFill></p:bgPr>`. Reuses `_inject_layout_background` (which works on any `<p:cSld>`-bearing element — Slide Master OR Slide Layout). Idempotent: re-injection replaces (not stacks).
  — **Wiring:** called once in `promote_designer_slides` between theme application and per-layout promotion (Stage A.5).
  — **Done when:** on BETEKK V9.1.1, the Slide Master's `<p:cSld><p:bg>` carries `<a:srgbClr val="09090B"/>` (dark); master thumbnail in PowerPoint Slide Master view appears dark; layouts that don't override `<p:bg>` inherit dark. 7 tests cover replacement of `<p:bgRef>`, idempotency, invalid-hex rejection, layout-element compatibility, dominant-bg tally, theme-dk1 fallback, end-to-end via `promote_designer_slides`.
  — **Consumers affected:** `designer_promoter`, `pptx-template-modifier-skill/SKILL.md` (Capability C algorithm step 0), `pptx-specialist-subagent.md` (Stage -1.5)

### Phase 3.5 — Engine Hard Limits Workaround (multi-pass + merge + backfill)

**Trigger:** a deck requires >8 distinct layouts (L1), multi-image slides (L2/L4), or multi-body slides (L3). Discovered when filling BETEKK V9.1.1 against the BETEKK Template V1.

- [x] **3.5a** Multi-pass render + merge pipeline (`pptx-generate-slide-skill/scripts/multipass_render.py`)
  — **Why:** L1 caps distinct layouts at 8 per render. Designer decks routinely have 10+.
  — **Algorithm:**
    1. **Partition** `slide_data_list` into batches of ≤8 distinct `slide_type` values (use a new pseudo-type `custom_layout:<layout_name>` for layouts beyond the 8 built-in types — the orchestrator assigns each BETEKK layout a unique pseudo-type).
    2. **Render** each batch to a separate `batch_N.pptx` via `generate_ppt_from_data(batch, template_path=TEMPLATE, ...)`.
    3. **Merge** — open `batch_0.pptx`, then for each subsequent batch use `python-pptx` + `lxml` to deep-copy every `slide` element + its `rels` + media parts into `batch_0`. Save as `<output>.pptx`. (Use the same clone-slide primitive chenyu's tests already exercise.)
  — **Done when:** a 10-layout deck renders in 2 batches and the merged output has all 10 slides on their correct distinct layouts (verified via `prs.slides[n].slide_layout.name` for each n).
  — **Consumers affected:** `pptx-specialist-subagent.md` Stage 4 (auto-detects >8 distinct layouts → switches to multi-pass)

- [x] **3.5b** Placeholder backfill (`pptx-generate-slide-skill/scripts/placeholder_backfill.py`)
  — **Why:** L2 (one image), L3 (two bodies), L4 (first picture only) leave multi-placeholder layouts under-filled.
  — **Algorithm:** after the render (or merge) completes, iterate `slide_data_list` against `prs.slides`. For each slide, look up its layout's placeholders by index; fill any TITLE/BODY/PICTURE placeholder not already filled by the engine, using extended slide_data fields:
    - `image_paths: [...]` — array of `{path, placeholder_idx, sizing: "fill"|"fit"}` for multi-image slides
    - `body_slots: [...]` — array of `{text, placeholder_idx}` for multi-body slides
    - Backfill skips placeholders the engine already populated (idempotent)
  — **Done when:** BETEKK Team slide (4 member bios + 4 photos) fills all 8 placeholders; Market Validation slide fills all 5 logo placeholders.
  — **Consumers affected:** `pptx-specialist-subagent.md` Stage 4 (always runs backfill post-render when the template contract reports multi-placeholder layouts)

- [x] **3.5c** Notes-master repair (`pptx-generate-slide-skill/scripts/notes_repair.py`)
  — **Why:** L5 — templates promoted via Capability C (or any user template missing a notes body placeholder) silently drop speaker notes.
  — **Algorithm:** before filling notes, probe `slide.notes_slide.notes_text_frame`. If `None`, locate the notes master (`prs.notes_master`), check for an existing notes-text placeholder; if absent, add one via `python-pptx` `notes_master.placeholders.add_textbox()` or raw OOXML `<p:ph type="body" idx="1"/>` under the notes master's `<p:cSld>`. Then retry `_set_notes`.
  — **Done when:** BETEKK Template V1 (no notes body placeholder) produces a deck where every slide's notes are readable in PowerPoint Presenter View.
  — **Consumers affected:** `pptx-generate-slide-skill`, all templates lacking notes body placeholders

### Phase 3.6 — Engine schema extension (DEFERRED post-migration)

**Not in scope for BT-142.** Tracked here so the interim workarounds (Phase 3.5) have a known sunset. The permanent fix replaces the 8-enum `slide_type` with an **open registry** + adds **array fields** (`image_paths`, `body_slots`) to the schema, eliminating multi-pass/backfill entirely. Estimate: 2–3 sprints. Tracked as follow-up ticket BT-143 (to be created).

### Phase 4 — Orchestrator Rewrite

- [x] **4.1** Rewrite `opencode_app/.opencode/agents/pptx-specialist-subagent.md` with:
  - Conditional trigger matrix (from review §6.2) — **including the 2 new rows added BT-142 session 2026-07-21**: empty-master promotion (Capability C) and content-migration (2-PPTX)
  - Relaxed constraints (multilingual OK; preserve original speaker message + suggest transition)
  - `permission.skill:` block updated to allow the 5 routed skills (`pptx-generate-slide-skill`, `pptx-generate-template-skill`, `pptx-template-modifier-skill`, `ooxml-editing-skill`, `office-thumbnail-skill`); REMOVE the now-deleted `pptx-specialist-skill: allow`
  - **`permission.task:` block MUST include `image-analyzer-subagent: allow`** (powers Phase 2.4b post-render visual verification — without this, the orchestrator cannot dispatch the vision subagent to verify slide screenshots)
  - Surgical-edit and html2pptx escape hatches routed to `ooxml-editing-skill` (NOT to a non-existent `pptx-specialist-skill`)
  - **Stage -1 enhanced detection (BT-142 session 2026-07-21):** probe `read_embedded_schema` AND introspect the master; if master is empty/blank (≤1 layout, zero placeholders) AND deck has ≥3 designed slides → route to Capability C (not pptx-generate-template-skill). If two PPTX paths supplied → route to content-migration workflow (extract from A, fill B). Detection logic documented inline.
  - **Engine-limits auto-routing (BT-142 session 2026-07-21):** when the slide_data_list or template contract indicates >8 distinct layouts OR multi-image/multi-body placeholders, Stage 4 transparently switches to the multi-pass + backfill pipeline (Phase 3.5) without user intervention. The switch is logged in the render report sidecar.
  — **Why:** The current orchestrator assumes html2pptx-first and single-skill routing. Must be rewritten for the multi-skill conditional trigger matrix, the user's relaxed constraints, and the post-decomposition skill set (no more `pptx-specialist-skill` reference). The `image-analyzer-subagent` permission is mandatory to enable the post-render sizing verification the user requested. The new Stage -1 detection closes the empty-master + 2-PPTX gaps surfaced by the BETEKK session.
  — **Done when:** Agent file contains the full conditional trigger matrix (all 10 rows); references all five routed skills by name; `permission.task` includes `image-analyzer-subagent: allow`; multilingual and speaker-note policies documented; `pptx-specialist-skill` is NOT referenced anywhere; escape-hatch routing points to `ooxml-editing-skill` + `office-thumbnail-skill`; Stage -1 detection logic for empty-master and 2-PPTX is documented with the three signal conditions (NOT_TEMPLATED + ≤1 layout + ≥3 designed slides).
  — **Consumers affected:** All PPTX-related user prompts routed through this agent

- [x] **4.2** Update tier: stay on `reasoning` (`glm-5.1`) per repo AGENTS.md
  — **Why:** The orchestrator performs conditional routing with 6+ decision paths — correctness-critical reasoning tier is appropriate.
  — **Done when:** Agent's model tier entry in `deploy/agent-tiers.json` or project overrides confirms `reasoning` tier.
  — **Consumers affected:** Model selection at deploy time

### Phase 5 — Documentation & Dependent Sync (per AGENTS.md)

- [x] **5.1** `deploy/setup.sh` — add 3 chenyu skills + 2 new decomposition skills to listing + banner; update count → 122
  — **Why:** AGENTS.md mandates sync: new skills/agents must be reflected in deploy scripts. Count includes the 5 new skills: `pptx-generate-slide-skill`, `pptx-generate-template-skill`, `pptx-template-modifier-skill`, `ooxml-editing-skill`, `office-thumbnail-skill`. Note `_common/` is shared lib, not a skill.
  — **PRE-EXISTING DRIFT (verified):** `setup.sh` line 666 currently shows `SKILLS (116)` — already stale vs actual 118. Must be corrected to 122, not incremented from 116. The skill listing is a **hardcoded** category-grouped text block (not dynamically computed); update both the count and the category listings. Note: `rsync` at line 2446 deploys ALL dirs including `_common/` — that's correct (shared lib needs deploying), but `_common/` must NOT appear in the skill listing or count.
  — **Done when:** `setup.sh` skill listing contains all 5 new skills; banner shows count 122; `pptx-specialist-skill` is removed from listing; `grep -c "SKILLS (122)" deploy/setup.sh` returns 1.
  — **Consumers affected:** Deploy pipeline, `deploy/setup.ps1` parity

- [x] **5.2** `deploy/setup.ps1` — Windows parity mirror
  — **Why:** AGENTS.md requires Windows parity for all deploy script changes.
  — **Done when:** `setup.ps1` mirrors `setup.sh` changes from 5.1.
  — **Consumers affected:** Windows deploy users

- [x] **5.3** `README.md` — update Skill Categories + Subagents tables
  — **Why:** AGENTS.md mandates that new skills appear in the repo's README documentation.
  — **PRE-EXISTING DRIFT (verified):** `README.md` line 329 currently shows "117 skills" — already stale vs actual 118. Must be corrected to 122, not incremented from 117. Lines referencing `pptx-specialist` (Framework category line 335; Subagents table lines 397, 399; Trigger Phrases line 433) must all be updated.
  — **Done when:** README.md Skill Categories table lists the 5 new skills (consider a new "Presentation (template-driven)" category for the chenyu trio + an "Office utilities" category for ooxml-editing + office-thumbnail); Subagents table reflects updated orchestrator description; `pptx-specialist-skill` is removed; line 329 count reads "121 skills".
  — **Consumers affected:** Repository documentation readers

- [x] **5.4** `opencode_app/README.md` — Docker-specific docs (Python-only PPTX workflow)
  — **Why:** Docker users need to know that PPTX workflows are pure python-pptx (no Node.js / Playwright in the container image). The `ooxml-editing-skill` still requires LibreOffice for some validators; document this.
  — **Done when:** Docker README mentions PPTX stack as Python-only; notes `python-pptx` + `lxml` dependencies; flags `LibreOffice` requirement for `office-thumbnail-skill` and OOXML validators.
  — **Consumers affected:** Docker / containerized deployments

- [x] **5.5** **Update dependent agents and skills** (4 files: 3 agents + 1 skill) — replace `pptx-specialist-skill` references with new routing
  — **PREREQUISITE:** Phase 4.1 (orchestrator rewrite) must be complete first — dependent routing points to the rewritten `pptx-specialist-subagent` which must already have its new skill set defined.
  — **Why:** The decomposition removes `pptx-specialist-skill` entirely. Every agent that currently references it in `permission.skill:` or in prose must be updated, or it will reference a non-existent skill.
  — **Files to update:**
    - `opencode_app/.opencode/agents/office-document-primary-agent.md` (line 14: `pptx-specialist-skill: allow` — verified) — REPLACE with `ooxml-editing-skill: allow` + `office-thumbnail-skill: allow` + `pptx-generate-slide-skill: allow`; OR route PPTX creation through `pptx-specialist-subagent` via Task tool instead
    - `opencode_app/.opencode/agents/startup-ceo-subagent.md` (lines 14, 61, 69 — all verified) — REPLACE skill delegation; route PPTX creation through `pptx-specialist-subagent` Task call
    - `opencode_app/.opencode/agents/discovery-specialist-subagent.md` (lines 24, 114 — both verified) — REPLACE skill delegation; route through `pptx-specialist-subagent` Task call
    - `opencode_app/.opencode/skills/docx-creation-skill/SKILL.md` — ADD references to absorbed helpers (`merge_runs.py`, `simplify_redlines.py`, `validators/docx.py`, `validators/redlining.py`) now confirmed at `docx-creation-skill/scripts/{validators,helpers}/` (identical copies already present per Phase 7.3 finding)
  — **Done when:** `grep -rn "pptx-specialist-skill" opencode_app/.opencode/` returns ZERO matches (excluding historical references in CHANGELOG/migration docs); every previous dependent has a working routing path.
  — **Consumers affected:** startup-ceo, discovery-specialist, office-document workflows

- [x] **5.6** **Update dependent skills** (3 files) — replace peer-deliverable references
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
  — **Why:** Users who explicitly say "convert HTML to PPTX" still need a working path. After decomposition, this routes through `ooxml-editing-skill` (or a thin html2pptx wrapper inside it) → `pptx-generate-template-skill` (extract+embed) → `pptx-generate-slide-skill` (final render). The old `pptx-specialist-skill` no longer exists.
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

- [ ] **6.11** **Empty-master promotion** (validates Phase 3.4 Capability C end-to-end)
  — **PREREQUISITE:** Phases 3.4.1–3.4.4 complete.
  — **Why:** The BETEKK V9.1.0 deck (empty master, branding per-shape) was the canonical gap. This test proves Capability C turns it into a fillable template.
  — **Test procedure:**
    1. Source deck: `/home/silentx/Downloads/BETEKK Presentation V9.1.0 - pitch.pptx` (or equivalent fixture)
    2. Run Capability C → produces `BETEKK Template V1.pptx` with 10 named layouts
    3. Verify the Slide Master's theme XML uses Century Gothic + the BETEKK teal/zinc palette (not stock Office)
    4. Verify each of the 10 layouts has ≥3 proper placeholders (TITLE/BODY/PICTURE) — not loose shapes
    5. Run `container_check` (Phase 3.4.2) → report must list zero critical violations after the build-time fix
    6. Fill the template with sample content via `pptx-generate-slide-skill` (no per-shape restyling) → output deck inherits branding from the master/layouts
    7. Visually compare the filled deck to the original BETEKK V9.1.0 — branding fidelity must be ≥90% (perceptual hash or human review)
  — **Done when:** All 7 sub-steps pass. Output template + filled deck stored under `output/capability-c-samples/` for regression reference.
  — **Consumers affected:** End users with designer decks (primary gap closed)

- [ ] **6.12** **Content migration** (validates Conditional Trigger Matrix row 6 + Phase 3.5 workarounds)
  — **PREREQUISITE:** Phases 3.4, 3.5a, 3.5b, 3.5c complete.
  — **Why:** The BETEKK V9.1.1 → BETEKK Template V1 migration was the canonical gap. This test proves the 2-PPTX workflow + multi-pass + backfill produces a correct deck.
  — **Test procedure:**
    1. Content source: `/home/silentx/Downloads/BETEKK Presentation V9.1.1.pptx`
    2. Template: `/home/silentx/Downloads/BETEKK Template V1.pptx` (from Phase 6.11)
    3. Orchestrator detects 2 PPTX paths → triggers content-migration workflow
    4. Extract content from source (text, 12 images, table data, team info)
    5. Map each source slide to a template layout (Cover, Story, Problem Impact, Problem, Solution/Brand, Solution/Demo, Market Validation, Business Model, Team, Ask/Closing)
    6. Multi-pass render (10 layouts > 8 → 2 batches) → merge → backfill (Team 4 bios/photos, Market Validation 5 logos)
    7. Notes-master repair (3.5c) — verify notes are populated on every slide
    8. Visual verification via `image-analyzer-subagent` with the extended prompt (including `container_overflow` check) — verify slide 4 (the original defect) no longer reports container overflow
    9. Slide count = 10; every slide on the correct named layout; branding inherited from template (no per-shape restyling)
  — **Done when:** All 9 sub-steps pass. The slide 4 container-overflow defect is resolved (zero critical violations). Output deck stored under `output/content-migration-samples/`.
  — **Consumers affected:** End users re-skinning decks across templates

### Phase 7 — Decompose `pptx-specialist-skill` (after chenyu port is stable)

This phase runs AFTER Phases 1–4 are complete and the chenyu stack is the primary path. Decomposing first would break the existing `pptx-specialist-skill` users before the replacement is ready.

- [x] **7.1** Create `ooxml-editing-skill/` and port generic Office OOXML files
  — **Why:** Audit revealed that `unpack.py`, `pack.py`, `validate.py`, `clean.py`, `validators/base.py`, and `validators/pptx.py` are generic Office OOXML tools, not PPTX-specific. They were misfiled under a PPTX-named skill and serve DOCX/XLSX/PPTX equally. Promoting them to their own skill makes them discoverable and reusable.
  — **Source files:** `opencode_app/.opencode/skills/pptx-specialist-skill/scripts/{unpack.py, pack.py, validate.py, clean.py}` + `validators/{base.py, pptx.py, __init__.py}`
  — **Target:** `opencode_app/.opencode/skills/ooxml-editing-skill/scripts/` + new `SKILL.md` describing the unpack→edit→pack workflow for any Office file
  — **Done when:** New skill directory exists with all 6 ported files + SKILL.md; imports resolve; `pytest` passes for any ported tests.
  — **Consumers affected:** `pptx-specialist-subagent.md` (new skill in `permission.skill`), `office-document-primary-agent.md`

- [x] **7.2** Create `office-thumbnail-skill/` and port visual-analysis files
  — **Why:** `thumbnail.py` and `soffice.py` provide visual analysis (thumbnail grids + PDF/image conversion via LibreOffice). They are orthogonal to PPTX creation and deserve their own skill. Useful for DOCX/XLSX/PPTX visual review equally.
  — **Source files:** `opencode_app/.opencode/skills/pptx-specialist-skill/scripts/{thumbnail.py, soffice.py}`
  — **Target:** `opencode_app/.opencode/skills/office-thumbnail-skill/scripts/` + new `SKILL.md`
  — **Done when:** New skill directory exists with both ported files + SKILL.md; `thumbnail.py` runs successfully against a sample PPTX; LibreOffice wrapper handles the AF_UNIX socket restriction.
  — **Consumers affected:** `pptx-specialist-subagent.md`, any skill that generates visual grids

- [x] **7.3** Delete DOCX-specific files from `pptx-specialist-skill/scripts/` — identical copies already exist in `docx-creation-skill`
  — **Why:** `validators/docx.py`, `validators/redlining.py`, `helpers/merge_runs.py`, `helpers/simplify_redlines.py` are DOCX-specific and were misplaced under a PPTX-named skill. **Verified (2026-07-21):** `diff -q` confirms all 4 files are byte-identical between `pptx-specialist-skill/scripts/{validators,helpers}/` and `docx-creation-skill/scripts/{validators,helpers}/`. The destination subdirectories already exist and already contain these files. This step is therefore a **DELETE from source**, not a move — no file copy is needed.
  — **Source files (to delete):** 4 DOCX-specific files under `pptx-specialist-skill/scripts/{validators,helpers}/`
  — **Target (already populated):** `opencode_app/.opencode/skills/docx-creation-skill/scripts/{validators,helpers}/` — exists and contains identical copies
  — **Done when:** `grep -rn "merge_runs\|simplify_redlines\|validators/docx\|validators/redlining" opencode_app/.opencode/skills/pptx-specialist-skill/` returns zero matches (files deleted from source); `docx-creation-skill/SKILL.md` references them.
  — **Consumers affected:** `docx-creation-skill`
  — **NOTE:** `docx-creation-skill/scripts/` also contains its own copies of `unpack.py`, `pack.py`, `validate.py`, `soffice.py` (overlapping with Phase 7.1's `ooxml-editing-skill` targets) and a full `validators/` directory (`base.py`, `pptx.py`, `__init__.py`). See Risk #9 — this broader DRY duplication is out of scope for BT-142 but should be tracked.

- [x] **7.4** Move `add_slide.py` into `pptx-generate-slide-skill/scripts/`
  — **Why:** `add_slide.py` is a PPTX-specific OOXML surgical-edit tool that fits naturally next to chenyu's python-pptx engine. Lives as an escape hatch for "add a slide to an unpacked PPTX" workflows.
  — **Source file:** `pptx-specialist-skill/scripts/add_slide.py`
  — **Target:** `pptx-generate-slide-skill/scripts/ooxml_add_slide.py` (renamed to avoid collision with chenyu's python-pptx-based `add_slide` semantics)
  — **Done when:** File exists at new path with new name; `pptx-generate-slide-skill/SKILL.md` mentions it as the surgical-edit alternative.
  — **Consumers affected:** `pptx-generate-slide-skill`

- [x] **7.5** DELETE `pptx-specialist-skill/` entirely
  — **Why:** After all usable files are redistributed (7.1–7.4), the remaining content is the html2pptx workflow in SKILL.md (retired by chenyu) and the directory itself. The skill name is misleading (bundles 3 concerns under a PPTX-misnomer) and conflicts with the surviving `pptx-specialist-subagent` orchestrator. Must be removed to avoid confusion and dual-skill routing ambiguity.
  — **Done when:** `opencode_app/.opencode/skills/pptx-specialist-skill/` directory no longer exists; `grep -rn "pptx-specialist-skill" opencode_app/.opencode/` returns ZERO matches (excluding historical migration docs / CHANGELOG).
  — **Consumers affected:** All Phase 5 dependents must already be updated (5.5, 5.6) before this deletion lands.

- [x] **7.6** Preserve html2pptx as a thin documented escape hatch inside `ooxml-editing-skill`
  — **Why:** Per user direction, html2pptx is retained only for explicit "convert HTML to PPTX" requests. The Node/pptxgenjs/playwright toolchain stays installed but undocumented; surfaced only via orchestrator routing. Following the hidden-JSON-template approach (extract+embed after html2pptx generation).
  — **Done when:** A short html2pptx section in `ooxml-editing-skill/SKILL.md` documents the explicit-request-only path; toolchain installs verified working.
  — **Consumers affected:** Users with explicit HTML→PPTX conversion needs

### Phase 8 — Architecture Review Findings (NEW — BT-142 review session 2026-07-21)

Read-only scenario-based review by `architecture-review-subagent` covering 17 scenarios across 5 skills + 6 new Phase 3.4-3.5 modules. Test suite at review time: 604 passed, 21 skipped.

**Scenario results:** 11 PASS, 5 PARTIAL, 1 GAP. See PLANS/PLAN-BT-142.md scenario matrix in commit `66b576e` for full breakdown.

- [x] **8.1** P0 bugs fixed (commit `66b576e`)
  — **BUG-1 (Critical):** `container_check._is_text_placeholder` had trailing `or True` defeating the type filter — every placeholder (PICTURE, TABLE, CHART) was treated as a text candidate, causing false-positive container-fit violations. **Fix:** removed `or True`; switched to `getattr(type_, 'value')` (canonical) with string-parse of `"NAME (NN)"` format as fallback for older python-pptx.
  — **BUG-2 (Critical):** `designer_promoter` `container_critical_blocks=True` / `contrast_critical_blocks=True` raised generic `RuntimeError` that was caught by the per-slide `except Exception` handler — the gate appeared to work but actually just skipped the offending slide and continued, producing a partial template without halting. **Fix:** introduced dedicated `ContainerFitBlocked` + `ContrastBlocked` exception types; the per-slide handler re-raises them via a separate `except (ContainerFitBlocked, ContrastBlocked): raise` clause placed before the generic `Exception` catch.
  — **BUG-3 (Critical):** `designer_promoter` ImportError fallback for `vision_extractor.fallback_xml_background` had signature `(slide)` but caller at `_resolve_slide_background` passed `(slide, theme=theme)` — `TypeError` whenever the import failed. **Fix:** aligned the fallback signature to `(slide, theme=None)`.
  — **Done when:** 15 regression tests in `tests/test_p0_regression.py` cover all three bugs + dual behavior (critical_blocks=True halts; =False reports-and-continues). Full suite: 619 passed.
  — **Consumers affected:** all Capability C consumers.

- [x] **8.2** Deploy drift resolved (user redeployed 2026-07-21)
  — **HIGH-2:** the deployed `~/.config/opencode/agents/pptx-specialist-subagent.md` was missing Stage -1.5 (vision extraction) because the deploy happened between commits `5b7d185` (orchestrator wiring) and `e6c378d` (master bg + vision stage). User redeployed after commit `66b576e`, picking up all current orchestrator changes.
  — **Done when:** `diff opencode_app/.opencode/agents/pptx-specialist-subagent.md ~/.config/opencode/agents/pptx-specialist-subagent.md` returns empty (or only the `model:` frontmatter line).

- [x] **8.3** Write tests for `merge_decks` / `_copy_slide` / `_relink_image_rels` (HIGH-1)
  — **Why:** the multi-pass merge primitive (used for L1 engine limit: >8 distinct layouts per deck) has ZERO test coverage. It is the riskiest untested code in the new stack. The BETEKK V9.1.1 content migration scenario (Phase 6.12) cannot be considered validated until this is tested.
  — **Test plan:**
    1. Build two minimal decks (1 slide each, distinct layouts) → merge → verify 2 slides on correct distinct layouts
    2. Build two decks with overlapping media (same image part) → merge → verify no relationship corruption
    3. Build three batches (partition of a 10-layout deck) → merge → verify all 10 slides on correct layouts
    4. Negative: merge a deck with a layout that doesn't exist on the primary master → verify graceful fallback to blank layout + warning
  — **Done when:** `pytest opencode_app/.opencode/skills/pptx-generate-slide-skill/scripts/tests/test_multipass_render_merge.py` passes with all 4 cases. Use real `ppt_builder.generate_ppt_from_data` to render batch inputs (not fakes) so the relink path is exercised end-to-end.
  — **Consumers affected:** all >8-layout decks (Phase 3.5a).

- [x] **8.4** Audit + close `master_cloner` skipped tests (HIGH-3 — pre-existing)
  — **Why:** 11 of 12 `tests/test_master_cloner.py` tests carry `@pytest.mark.skip` with reason "need multi-layout donor fixture". This is pre-existing chenyu-era debt, not introduced by BT-142, but it leaves Capability B (donor clone) effectively untested.
  — **Done when:** skipped tests either pass (fixture built) or are rewritten with explicit `tmp_path` fixtures against a synthesized multi-layout donor. Goal: zero `@pytest.mark.skip` in `test_master_cloner.py`.
  — **Consumers affected:** Capability B (template-modifier donor-clone path).

- [x] **8.5** Convert medium-severity findings to follow-ups (MED-1 through MED-5)
  — **MED-1:** `placeholder_backfill._add_picture_into_placeholder` — zero test coverage. Add 2-3 tests: real image into placeholder (fill sizing), real image (fit sizing), missing-file path.
  — **MED-2:** `vision_extractor.fallback_xml_background` schemeClr aliases (tx1, bg1) — untested. Add tests for both alias paths with theme dict.
  — **MED-3:** `contrast_check` auto-fix mutation — current tests use `_FakeRun` stubs and don't verify the actual OOXML mutation lands on the placeholder's `<a:defRPr><a:solidFill><a:srgbClr>`. Add a test using a real python-pptx placeholder shape, call `contrast_violations(..., auto_fix=True)`, reload the shape, verify the run color was changed.
  — **MED-4:** Skill count drift — docs say 122 but filesystem has 127 SKILL.md files (new skills added elsewhere). Re-audit and reconcile. May relate to Phase 9 (PPTX skill rename).
  — **MED-5:** `pptx-generate-slide-skill/SKILL.md:84` says "English only" but orchestrator line 27 says "RELAXED" — pre-existing doc contradiction. Align both to the orchestrator's relaxed policy.
  — **Done when:** each MED item has a dedicated commit OR is explicitly triaged out with rationale.

### Phase 9 — PPTX Skill Naming Convention (NEW — BT-142 session 2026-07-21)

**Why:** the three PPTX-specific skills created by BT-142 (`pptx-generate-slide-skill`, `pptx-generate-template-skill`, `pptx-template-modifier-skill`) carry generic names that don't communicate they're PPTX-only. A future contributor reading the skill list cannot tell whether `pptx-generate-slide-skill` handles Google Slides, Keynote, Reveal.js, or PPTX. Adding a `pptx-` prefix scopes discovery and avoids future name collisions when (if) other slide frameworks are added.

The two Office-wide skills keep their current names because they handle DOCX/PPTX/XLSX uniformly:
- `ooxml-editing-skill` — generic OOXML unpack/pack/validate (any Office file)
- `office-thumbnail-skill` — generic visual analysis (any Office file via LibreOffice)

**Rename map (PPTX-specific only):**

| Current name                       | New name                              |
| ---------------------------------- | ------------------------------------- |
| `pptx-generate-slide-skill`               | ` PROTpptx-generate-slide-skill `             |
| `pptx-generate-template-skill`            | ` PROTpptx-generate-template-skill `          |
| `pptx-template-modifier-skill`            | ` PROTpptx-template-modifier-skill `          |

Skill count stays at 122 — pure rename, no add/remove.

- [x] **9.1** Rename the three PPTX-specific skill directories
  — **Why:** namespacing for discoverability; prevent future collisions when other slide frameworks are considered.
  — **Done when:** `git mv opencode_app/.opencode/skills/pptx-generate-slide-skill opencode_app/.opencode/skills/ PROTpptx-generate-slide-skill ` (and the two parallel moves); old directories no longer exist; new directories retain all scripts + SKILL.md + tests unchanged.
  — **Consumers affected:** every reference to the old names (see 9.2)

- [x] **9.2** Update all cross-references
  — **Files to update (verified via `grep -rn 'pptx-generate-slide-skill\|pptx-generate-template-skill\|pptx-template-modifier-skill' opencode_app/ deploy/ README.md PLANS/`):**
    - `opencode_app/.opencode/agents/pptx-specialist-subagent.md` — routing matrix, `permission.skill:` block, Stage -1.5 + Stage 4 code samples (sys.path.insert references + skill paths)
    - `opencode_app/.opencode/agents/office-document-primary-agent.md` — `permission.skill:` if it references any of the three
    - `opencode_app/.opencode/skills/*/SKILL.md` — any cross-references between the three (e.g. `pptx-template-modifier-skill/SKILL.md` mentions `pptx-generate-slide-skill` in its scripts table)
    - `opencode_app/.opencode/skills/_common/scripts/*.py` — only docstring/comments (functional imports use relative paths or sys.path.insert with the directory name)
    - `deploy/setup.sh` — skill listing (banner + status sections)
    - `deploy/setup.ps1` — Windows parity mirror
    - `README.md` — Skill Categories table, any prose references
    - `opencode_app/README.md` — Docker docs PPTX section
    - `PLANS/PLAN-BT-142.md` — fix every reference in this file
  — **Done when:** `grep -rn '\b\(pptx-generate-slide-skill\|pptx-generate-template-skill\|pptx-template-modifier-skill\)\b' opencode_app/ deploy/ README.md PLANS/` returns zero matches (the new `pptx-` prefixed names are not flagged because the regex uses `\b` word boundaries against the old bare names).
  — **Consumers affected:** every consumer of the three skills.

- [x] **9.3** Update `sys.path.insert` calls in scripts and tests
  — **Why:** Python imports use `sys.path.insert(0, '.opencode/skills/pptx-generate-slide-skill/scripts')` (string literal containing the directory name). These literals must be updated or the imports break.
  — **Done when:** `grep -rn 'sys.path.insert.*skills/\(pptx-generate-slide-skill\|pptx-generate-template-skill\|pptx-template-modifier-skill\)' opencode_app/` returns zero matches; the new paths use the `pptx-` prefixed directory names. Verify with `python3 -m pytest opencode_app/.opencode/skills/pptx-*/scripts/tests/` — all tests pass against the new paths.
  — **Consumers affected:** all callers of the three skills' Python modules (orchestrator scripts, dependent skill scripts, tests).

- [x] **9.4** Update SKILL.md `name:` frontmatter fields
  — **Why:** each skill's YAML frontmatter has a `name:` field matching the directory name. The frontmatter name is used by skill-loader logic and must match the directory or the skill fails to load.
  — **Done when:** `head -5 opencode_app/.opencode/skills/ PROTpptx-generate-slide-skill /SKILL.md` shows `name:  PROTpptx-generate-slide-skill ` (and parallel for the other two).
  — **Consumers affected:** OpenCode skill loader.

- [x] **9.5** Update `description:` fields to reflect PPTX-specificity
  — **Why:** now that the name carries the `pptx-` prefix, the description can be tighter (no need to disambiguate framework). E.g. `pptx-generate-slide-skill`'s description "Populate the PowerPoint template..." can become "Populate a PPTX Slide Master template...".
  — **Done when:** all three renamed skills' `description:` fields explicitly say "PPTX" or "PowerPoint" (already mostly true; verify and tighten).
  — **Consumers affected:** skill discoverability in agent routing matrices.

- [x] **9.6** Sync deploy/README counts + listings
  — **Why:** the deploy scripts hardcode skill listings in category groups. The three renamed skills must appear under their new names; counts stay at 122.
  — **Done when:** `grep -c ' PROTpptx-generate-slide-skill \| PROTpptx-generate-template-skill \| PROTpptx-template-modifier-skill ' deploy/setup.sh deploy/setup.ps1 README.md` returns ≥3 in each file; the old names no longer appear.
  — **Consumers affected:** deploy pipeline, README readers.

- [x] **9.7** Validation gate: smoke-test the renamed stack end-to-end
  — **Why:** a rename touches many files in parallel; a single missed reference breaks routing silently.
  — **Done when:**
    1. `./deploy/setup.sh --dry-run` (or equivalent) lists the three new skill names + correct count (122)
    2. `python3 -m pytest opencode_app/.opencode/skills/pptx-*/scripts/tests/ opencode_app/.opencode/skills/_common/scripts/tests/` — all tests pass
    3. Smoke test from the architecture review (scenarios 1, 3, 17) re-run with new paths — all PASS
    4. Live end-to-end: invoke `pptx-specialist-subagent` against BETEKK V9.1.1 — produces the same template as before the rename

**NOTE on backward compatibility:** downstream projects that consume the deployed `~/.config/opencode/skills/{generate-slide,generate-template,template-modifier}-skill/` will break on their next deploy until they update any `sys.path.insert` or `permission.skill:` references. Mitigation: ship as a flagged breaking change in the next release notes; consider leaving symlink shims for one release cycle (deferred — out of BT-142 scope).

## Conditional Trigger Matrix (embed in orchestrator)

| User provides        | User asks                              | Skill invoked                                                              |
| -------------------- | -------------------------------------- | -------------------------------------------------------------------------- |
| PPTX                 | "extract template" / "what layouts"    | `pptx-generate-template-skill`                                                    |
| Templated PPTX       | "create deck"                          | `pptx-generate-slide-skill`                                                       |
| Non-templated PPTX   | "create deck"                          | `generate-template` → `generate-slide` (chained via `auto_template=True`)      |
| Templated PPTX       | "add slide type not in master"         | `template-modifier` (Capability B) → `generate-slide`                         |
| PPTX A (content) + PPTX B (template) | "apply A's content to B's layouts" / "re-skin deck" / "use A on B template" | **NEW** Stage 0 content extraction (from A) → `generate-slide` (against B, multi-pass if >8 layouts per Phase 3.5a) → backfill (3.5b) |
| PPTX (empty master, branding per-shape) | "make reusable template" / "create layouts from slides" / "promote slides to master" | **NEW** `template-modifier` (Capability C — `designer_promoter`) → `generate-slide` |
| PPTX                 | "fix typo on slide 4" / surgical edit  | `ooxml-editing-skill` (unpack → edit XML → pack)                              |
| Any PPTX             | "show me thumbnails" / visual analysis | `office-thumbnail-skill` (LibreOffice → PDF → images)                         |
| HTML                 | "convert html to pptx" (explicit only) | html2pptx wrapper (inside `ooxml-editing-skill`) → `generate-template` → `generate-slide` |
| Nothing              | "create deck"                          | **ERROR**: template required                                                 |

> **Matrix gap (non-blocking):** "Non-templated PPTX + add slide type not in master" is not a separate row. The orchestrator should chain: `generate-template` (extract first) → `template-modifier` (add layout) → `generate-slide` (fill). This is implied by combining rows 3 + 4 but should be documented explicitly in the orchestrator prompt (Phase 4.1) to avoid ambiguous routing.

> **Matrix gap 2 (added BT-142 session 2026-07-21):** "PPTX with empty master + branding per-shape" is row 6's trigger. This shape is detected by: (a) `read_embedded_schema` returns `NOT_TEMPLATED`, AND (b) `template_introspector` reports ≤1 layout OR zero placeholders on the master's only layout, AND (c) the deck has ≥3 designed slides. The orchestrator must NOT route this through `pptx-generate-template-skill` alone (which would extract a useless schema) — it must route through Capability C. Detection logic lives in `pptx-specialist-subagent.md` Stage -1.

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
16. **Engine hard limits surface on real-world decks (Phase 3.5).** The 8 `slide_type` cap (L1), one-image-per-slide (L2/L4), and two-bodies-max (L3) all hit the BETEKK V9.1.1 deck simultaneously. The interim multi-pass + merge + backfill pipeline (Phase 3.5) restores correctness but adds ~30–60s per render and ~150 lines of merge glue code. **Mitigation:** Phase 3.5 is opt-in (orchestrator detects >8 layouts or multi-image/body slide_data and switches paths); standard 8-type decks take the original fast path. Permanent fix deferred to BT-143 (Phase 3.6).
17. **Promoted-layout fidelity drift (Phase 3.4 Capability C).** Reverse-engineering per-shape branding into theme + placeholders can lose fidelity: gradient fills, custom shape geometry, and embedded effects (shadow/glow) may not survive the shape→placeholder conversion. **Mitigation:** (a) decorative shapes (cards, accent bars) are preserved verbatim as non-placeholder layout shapes; (b) only text/image/table shapes are promoted to placeholders; (c) the build report lists every shape and its promotion decision (placeholder vs preserved) for audit; (d) Phase 6.11 human test pass validates fidelity against the original deck.
18. **Container-fit check false positives (Phase 3.4.2).** The static geometry check may flag placeholders that intentionally extend slightly beyond their container (e.g., a headline that overhangs a card edge by design). **Mitigation:** the 4px default tolerance absorbs minor overhang; severity tiers (critical > 20px, warning 4–20px) let the orchestrator ignore warnings; critical violations trigger a clarifying `question()` to the user ("resize placeholder vs keep as intentional overhang") rather than blocking silently.
19. **Notes-master repair may alter theme inheritance (Phase 3.5c).** Adding a notes body placeholder to a notes master that lacks one could change how other notes elements render. **Mitigation:** the repair adds only the minimal `<p:ph type="body" idx="1"/>` element; no other notes-master shapes are touched; the original deck is never modified (repair applies only to a derived output).
20. **Content migration routing ambiguity (Conditional Trigger Matrix row 6).** When the user provides two PPTX paths, the orchestrator must correctly identify which is "content" and which is "template". **Mitigation:** explicit prompt parsing ("apply A to B" / "use A on B's template" → A=content, B=template); if ambiguous, ask the user via `question()` to confirm roles before proceeding (one-shot, before any extraction).
21. **Merge primitive untested (HIGH-1 from BT-142 review).** `multipass_render.merge_decks` / `_copy_slide` / `_relink_image_rels` have ZERO test coverage — the L1 engine-limit workaround (>8 distinct layouts) rests on an untested primitive. A defect here would silently corrupt multi-batch decks. **Mitigation:** Phase 8.3 adds 4 targeted tests against real `generate_ppt_from_data` batch outputs (not fakes) so the relink path is exercised end-to-end. Until landed, recommend Phase 6.12 (content migration) not be considered validated for >8-layout decks.
22. **Container-check type filter (BUG-1 fix).** The fix in commit `66b576e` changed container_check's placeholder classification — picture/table/chart placeholders are no longer treated as text candidates. **Mitigation:** re-run Capability C on BETEKK V9.1.1 after the fix to confirm the violation count is accurate (was previously inflated by false positives from non-text placeholders). Adjust orchestrator's `container_overflow: critical` verdict routing if severity distribution shifts.
23. **Policy-gate propagation (BUG-2 fix).** Pre-fix, `container_critical_blocks=True` was silently swallowed. Post-fix, it halts with `ContainerFitBlocked`. **Mitigation:** orchestrator callers that previously set `container_critical_blocks=True` expecting non-blocking behavior must explicitly switch to `=False`. The BETEKK V9.1.1 generation runs in this session used `=False` (non-blocking), so behavior is unchanged; verify any future callers know about the new blocking semantics.
24. **PPTX skill rename is a breaking change (Phase 9).** Renaming the three PPTX-specific skills will break downstream projects that reference the old names in `permission.skill:` or `sys.path.insert` calls. **Mitigation:** ship in the next minor release with explicit migration notes; consider one-cycle symlink shims (deferred — out of BT-142 scope).

## Open Questions (defer to primary agent)

1. ~~Confirm "keep `pptx-specialist-skill` as escape hatch" vs full retirement~~ **— RESOLVED.** Decompose into `ooxml-editing-skill` + `office-thumbnail-skill`, redistribute DOCX files to `docx-creation-skill`, delete `pptx-specialist-skill` entirely. See Phase 7.
2. ~~Confirm subagent tier (`reasoning` / `glm-5.1`) for rewritten orchestrator (review §11 Q8).~~ **— RESOLVED.** `reasoning` tier (`glm-5.1`) is confirmed: the orchestrator performs conditional routing with 6+ decision paths (correctness-critical). This matches repo AGENTS.md tier guidance and is already actioned in Phase 4.2.
3. Confirm html2pptx Node toolchain retention (review §11 Q2) — current PLAN assumes retained as undocumented escape hatch inside `ooxml-editing-skill` (Phase 7.6).
4. **NEW:** Confirm the 3-way split (ooxml-editing + office-thumbnail + absorb DOCX helpers into docx-creation) vs a 2-way merge (single `office-utils-skill` combining ooxml + thumbnail). PLAN currently assumes 3-way for single-responsibility clarity; 2-way would yield skill count 121 instead of 122.
5. **NEW:** Should `ooxml-editing-skill` cover DOCX/PPTX/XLSX uniformly, or specialize per format (split into `docx-ooxml-skill`, `pptx-ooxml-skill`, `xlsx-ooxml-skill`)? PLAN assumes uniform (one skill, format-aware validators); specialization would push skill count higher.
6. **NEW:** Should `office-thumbnail-skill` also absorb the markitdown-based content extraction (currently in `pptx-specialist-skill`'s narrative), or stay narrow (thumbnail + soffice only)? PLAN assumes narrow.
7. **NEW:** When `pptx-specialist-subagent` is rewritten (Phase 4.1), should it route deck-creation requests from peer agents (startup-ceo, discovery-specialist) via Task tool dispatch, or via direct skill invocation? PLAN currently assumes Task tool dispatch (consistent with our hub-and-spoke pattern).
8. **NEW (BT-142 session 2026-07-21):** Should Capability C (Phase 3.4) live in `pptx-template-modifier-skill` (sibling to Capability B donor-clone) or as a **new fourth skill** `template-promoter-skill`? PLAN currently assumes sibling-within-template-modifier (keeps skill count at 122). A separate skill would push count to 123 and give Capability C its own trigger phrases + permission surface.
9. **NEW (BT-142 session 2026-07-21):** Should the **content-migration workflow** (Conditional Trigger Matrix row 6) be its own skill (`content-migration-skill` wrapping Stage 0 extraction + multi-pass + backfill), or stay as an orchestrator-only workflow that composes existing skills? PLAN currently assumes orchestrator-only (no new skill).
10. **NEW (BT-142 session 2026-07-21):** For the engine hard limits (L1–L5), is the interim Phase 3.5 workaround acceptable for BT-142 GA, or should Phase 3.6 (open `slide_type` registry + array fields) land in-scope? PLAN currently defers 3.6 to BT-143. Defer risks forcing every real-world pitch deck through the multi-pass pipeline.
11. **NEW (BT-142 session 2026-07-21):** Should the `container_overflow` image-analyzer check (Phase 2.4c/3.4.3) be a hard gate (blocks render on critical verdict) or a soft warning (passes through to `Issues:`)? PLAN currently assumes soft for headless, hard for interactive (Phase 2.4 question).
