# Design Rationale: Template-Agnostic Engine + `template-modifier-skill`

> **Capability A** (template-agnostic filling) + **Capability B**
> (`template-modifier-skill`).
>
> This document is the **agreed development plan** for breaking the
> single-fixed-template assumption. The engine currently binds 8 slide types to
> 8 hardcoded layout names; this work makes it accept **any** `.pptx`, introspect
> its structure into a JSON contract, and render within that template's own
> constraints — plus a new skill that extends a template with cloned layouts when
> content exceeds its limits.

---

## 0. Origin (stakeholder requirements)

The stakeholder's requirements, verbatim intent:

1. `template.pptx` is **not fixed** — the agent must take in **ANY** template.
2. Work within **the template's own** constraints:
   - accept any template;
   - process it and turn it into **JSON**;
   - with that JSON's constraint, create slides.
3. A separate skill — `template-modifier-skill` — for when the template must be
   updated/extended:
   - read from the provided `template.pptx`;
   - read the Slide Master;
   - understand the requirements from the prompt;
   - if they exceed the template's allowable sizes, create a new template slide
     (layout), then use the new template slide.

---

## 1. Confirmed decisions

| # | Decision |
|---|----------|
| 1 | Introspection runs **automatically** before render; the contract is cached in `template.contract.json` and invalidated by the template's `mtime`. |
| 2 | The ideal `slide_type` → placeholder **fingerprint** map is a **built-in engine constant** (8 types); it can be overridden by the contract or `default.config.json`. When a template lacks a needed type, the engine **degrades** (skips that slide with a warning) — accepted. |
| 3 | Layout creation uses **Approach 2 only — pure dynamic cloning** (deep-copy a donor layout's `<p:sldLayout>` + part + relationships, register under the master's `<p:sldLayoutIdLst>`, then resize placeholders per the computed dimensions). **No** external "layout library" file (Approach 3 was rejected). |
| 4 | The default template is `template/default.pptx` (repo root); a user template is passed via `template_path`/`--template` (path pass-through, default untouched — US-4.7). When the base cannot satisfy a layout requirement, a derived `template_new.pptx` is produced — see the state machine in §4. |

### Why not python-pptx public API for layout creation

Empirically verified against **python-pptx 1.0.2**:

- `SlideLayouts` exposes only `element / get_by_name / index / parent / part /
  remove` — **there is no `add` method.**
- A layout is registered on the master via `<p:sldLayoutIdLst>` entries
  (`<p:sldLayoutId id="…" r:id="rIdN"/>`); its own XML is `cSld` (shapes /
  placeholders) + `clrMapOvr`; its only relationship is `slideMaster`
  (it inherits the master's visual style).

Therefore "create a new template slide" is **not possible** via the public API.
The only viable path is **XML/part cloning** (Approach 2). Approach 1 (pure API)
is impossible; Approach 3 (cross-template layout import) was considered and
**rejected** in favor of keeping a single dynamic mechanism.

---

## 2. Current state (code locations)

| Current behaviour | Location | Problem |
|---|---|---|
| Hardcoded default template | `ppt_builder.py` `_TEMPLATE_FILE` | Defaults to repo-root `template/default.pptx` (overridable via `template_path` / `--template`) |
| `template_path` param exists | `ppt_builder.py:533` | Present, but the workflow does not drive it |
| Hardcoded layout-name map | `ppt_builder.py:60-69` `_LAYOUT_NAME_MAP` | Different template ⇒ names mismatch ⇒ slides skipped |
| Layout match by **name only** | `ppt_builder.py:147-170` `_build_layout_index` / `_resolve_layout` | No placeholder-composition fingerprint |
| Config overrides only 2 types | `default.config.json` (title / content) | Coverage too narrow |
| Introspection scattered | `research_layouts.py` / `research_theme.py` | One-off scripts, not productized |
| `template-modifier-skill` | does not exist | Entirely missing |

**Core pain point:** constraints (layout names, placeholder structure) are
**hardcoded constants**, not **derived** from the supplied template.

---

## 3. Target architecture

```
            user supplies any template.pptx  (single path, replaces previous)
                          │
                          ▼
              ┌────────────────────────────┐
              │  template_introspector.py  │  ★ new (Capability A foundation; shared by A & B)
              │   → template.contract.json │  full contract: layouts + placeholder size/pos
              │                            │            + slide size + theme
              └─────────────┬──────────────┘
                            │
          ┌─────────────────┴────────────────────┐
          ▼                                      ▼
  ┌────────────────────┐               ┌─────────────────────────┐
  │ generate-slide-skill│               │ template-modifier-skill │ ★ new (Capability B)
  │  (Capability A)    │               │  read Slide Master       │
  │  fingerprint match │               │  over-limit → clone new  │
  │  constraint-aware  │               │  layout → template_new   │
  └────────────────────┘               └─────────────────────────┘
```

---

## 4. The JSON contract (`template.contract.json`)

Full granularity (per confirmed decision). Shape:

```json
{
  "source_file": "template.pptx",
  "source_mtime": 1750000000.0,
  "slide_size": {
    "width_emu": 12192000, "height_emu": 6858000,
    "width_in": 13.33, "height_in": 7.5, "ratio": "16:9"
  },
  "theme": {
    "colors": {"accent1": "#4472C4", "dk2": "#44546A", "lt2": "#E7E6E6"},
    "fonts": {"major_latin": "Calibri Light", "minor_latin": "Calibri"}
  },
  "layouts": [
    {
      "index": 1,
      "name": "Title and Content",
      "placeholders": [
        {"idx": 0, "name": "Title 1", "type": "TITLE",
         "left_in": 0.5, "top_in": 0.3, "width_in": 12.3, "height_in": 1.0},
        {"idx": 1, "name": "Content Placeholder 2", "type": "OBJECT",
         "left_in": 0.5, "top_in": 1.5, "width_in": 12.3, "height_in": 5.5}
      ],
      "fingerprint": ["TITLE", "OBJECT"],
      "content_area_in2": 67.65
    }
  ]
}
```

- **`fingerprint`** — placeholder-type composition signature (e.g.
  `["TITLE","OBJECT"]`); the key to matching `slide_type` to a layout **without**
  relying on hardcoded names.
- **`content_area_in2`** — body/content placeholder area in square inches; reused
  for over-limit checks (Capability B) and density-budget calibration (Capability A).
- **`source_mtime`** — drives the cache-invalidation rule: re-introspect only when
  the template file's mtime changes.

---

## 5. Template-resolution state machine (`template_new.pptx` lifecycle)

Two file roles:

- `template.pptx` — **immutable base** (user-supplied, single authoritative path).
- `template_new.pptx` — **derived / ephemeral** (engine-managed; produced only
  when the base cannot satisfy a layout requirement).

Entry logic on **every** generation request:

```
generation request begins
   │
   ① template_new.pptx exists? ──yes──▶ delete it  (force freshness; discard last run's leftover)
   │ no
   ② introspect template.pptx ──(mtime-cached)──▶ contract
   ③ scan this request's slide_data_list:
      └─ for each slide: its fingerprint + content size vs contract
           if any slide's layout is missing OR its content is over-limit
              └─▶ clone-produce template_new.pptx  (base + new layout(s))
                   active_template = template_new.pptx
   ④ render ALL slides ← based on active_template
   ⑤ if template_new.pptx was used ──▶ inform the user:
        "Rendered from template_new.pptx (added layout: <name>) because
         template.pptx could not fit <reason>."
   ⑥ request ends. template_new.pptx is kept (reused by "subsequent" generations);
      the NEXT new request loops back to ① and is re-judged against the
      then-current template.pptx.
```

### Guarantees

- **① Always delete on next request** — even if `template.pptx` is unchanged, the
  base is re-evaluated every request so the base always stays authoritative
  (the user may have edited `template.pptx` between requests).
- **③ Cloning is a pre-render planning step** — all slide requirements are
  inspected once before rendering, not cloned mid-loop, so a single request
  renders against a single template.
- **⑤ Mandatory user notification** — whenever `template_new.pptx` is used, the
  agent tells the user which template was used and why (stakeholder requirement).
- **Contract cache** — `template.contract.json` caches only the **base**
  `template.pptx`. `template_new.pptx` is derived and introspected on the fly
  after cloning (no cross-request cache — it is deleted on the next request anyway).

---

## 6. Capability A — template-agnostic filling (change points)

| Step | Change | File |
|------|--------|------|
| A1 | New introspection engine → emits `template.contract.json` (productize `research_*.py`) | `scripts/template_introspector.py` |
| A2 | New **fingerprint matcher**: `slide_type` → closest layout by placeholder composition (names are fallback; contract/config override wins) | `ppt_builder.py` — new `_resolve_layout_by_fingerprint()`, coexists with `_resolve_layout` |
| A3 | `generate_ppt_from_data` runs introspection automatically before render; if a contract exists, use fingerprint match, else fall back to name match (**backward compatible**) | `ppt_builder.py:531` |
| A4 | SKILL/agent workflow: when the user supplies a template, it replaces `template.pptx` (same path) then auto-introspects; the available `slide_type` set + placeholder constraints are fed back to the content layer | `SKILL.md` + `pptx-subagent.md` |
| A5 | Density budget calibrated by placeholder `content_area_in2` (downshift mode on small areas) | `density_mode.py` |

**Invariant:** A2/A3 keep **backward compatibility** — without a contract the
engine follows the original name-based matching, so the existing 120 tests stay green.

---

## 7. Capability B — `template-modifier-skill` (new)

```
.opencode/skills/template-modifier-skill/
├── SKILL.md
└── scripts/
    ├── template_reader.py      # read Slide Master (reuses the introspector)
    ├── constraint_checker.py   # requirement vs template size → over-limit verdict
    ├── layout_creator.py       # over-limit → clone a new layout into template_new.pptx
    └── tests/
```

The 4 stakeholder steps map onto the pipeline:

1. **Read template** — reuse `template_introspector` to get the contract.
2. **Read Slide Master** — master-level placeholders + theme.
3. **Understand the prompt** — parse the requirement (e.g. "a layout that fits a
   6-column table"), compute the required content-area size.
4. **Over-limit check + create** — if required > template allows, clone a donor
   layout per the 7-step procedure, write `template_new.pptx`; Capability A then
   renders against it.

### Cloning procedure (Approach 2 — 7 steps)

```
1. pick a donor layout (fingerprint closest to the requirement)
2. deepcopy the donor <p:sldLayout> element → a new SlideLayoutPart
3. copy the donor's non-master rels (background images, etc.)
4. master.part.relate_to(new_layout_part, slideLayout relationship type)
5. append <p:sldLayoutId id=<new>, r:id=<new>> to <p:sldLayoutIdLst>
6. resize the clone's placeholders (<p:ph> + <a:off>/<a:ext>) per the dimensions
   computed by constraint_checker
7. save as template_new.pptx → reload & verify the new layout is findable by
   get_by_name; on failure roll back (delete) so the base is never corrupted
```

**Output:** a `template_new.pptx` (base + new layout(s)), handed to Capability A.

---

## 8. Phased delivery

| Phase | Scope | Key deliverable | Depends on |
|-------|-------|-----------------|------------|
| **P0** | `template_introspector.py` + contract schema + tests; mtime cache | introspection engine (shared foundation of A & B) | nothing |
| **P1** | fingerprint constant table + `_resolve_layout_by_fingerprint()` + degradation; `generate_ppt_from_data` auto-introspects before render; contract ⇒ fingerprint match, else name-match fallback (**backward compatible**) | any-template filling | P0 |
| **P2** | `pptx-subagent.md` / SKILL: "user supplies template → replace `template.pptx` (same path) → auto-introspect" branch | end-to-end Capability A | P1 |
| **P3** | `template-modifier-skill`: `template_reader.py` + `constraint_checker.py` (requirement vs `content_area_in2` over-limit verdict); implement the state machine ①③⑤ (delete/create/notify for `template_new.pptx`) | Capability B read + judge + lifecycle | P0 |
| **P4** | `layout_creator.py`: Approach-2 cloning (7 steps); overwrite-write `template_new.pptx`; reload-verify findable by `get_by_name`; rollback on failure | Capability B full loop | P3 |

Every phase ships with pytest. From P1 onward, **backward compatibility** is
verified (existing 120 tests stay green). P4 verifies "clone → render → output
opens in PowerPoint".

---

## 9. Risks & safeguards

- **OPC package manipulation** (P4) is the highest-risk step: part-name conflicts,
  dangling rels, broken `sldLayoutIdLst`. Safeguards: reload-verify after clone,
  rollback-on-failure (never corrupt the base), and a "clone → render → reopen"
  end-to-end test.
- **Fingerprint ambiguity** — a template may have several layouts with the same
  placeholder composition. Resolution: prefer the layout with the largest
  `content_area_in2` for content types; allow contract/config to pin a layout
  name explicitly.
- **Degradation transparency** — when a needed `slide_type` is absent in the
  template, the engine must skip with a **clear** warning (slide index + reason),
  never fail silently.
