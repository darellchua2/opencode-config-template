---
name: pptx-generate-template-skill
description: "Extract a PowerPoint (.pptx) into a normalized template-schema JSON and return a self-describing 'templated' PPTX with that JSON embedded at ppt/template_schema.json. Use when the user wants to extract/generate a template, fingerprint a deck, learn its layouts/components/fonts, or produce a reusable templated PPTX. Do NOT use for filling a template with content (use pptx-generate-slide-skill) or extending a template's layouts (use pptx-template-modifier-skill)."
license: Apache-2.0
compatibility: opencode
metadata:
  audience: developers
  workflow: template-extraction
---

## What I do

I am the **pptx-generate-template-skill** (US-3.1). I take any `.pptx`, run the full extraction pipeline, and return a **templated PPTX** �?the original file plus an embedded `ppt/template_schema.json` that describes every layout, component, font, and theme color. The embedded JSON "travels with the file" so it can be queried or reused later.

I orchestrate the existing `schema_extractor` engine end-to-end:

`extract �?validate �?(title confirm) �?embed �?return templated PPTX + summary`

I do **not** fill templates, generate slides, or build decks. Those are `pptx-generate-slide-skill` and `pptx-subagent`. I only **extract and package** a template definition.

## When to use me

Use this skill when the user wants to:

- "extract the template from this PPTX"
- "generate a template" / "make a templated PPTX"
- "what layouts / components / fonts does this template have?"
- "fingerprint this deck" / "describe this template's structure"
- produce a reusable, self-describing `.pptx` for later slide generation

Do **NOT** use me for:

- Filling a template with content �?`pptx-generate-slide-skill`
- Extending a template's layouts (cloning) �?`pptx-template-modifier-skill`
- Generating a presentation / slides �?`pptx-subagent`

## Engine

The engine lives in the shared `_common/scripts` package (PLAN-GIT-72). I call its functions directly (so I can inspect the extracted schema mid-pipeline for the title-confirmation step):

| Function | Purpose |
|----------|---------|
| `extract_schema(path) -> dict` | Read the PPTX, emit the proposed-schema JSON (US-1.1�?.5, US-2.1 header/footer detection). |
| `validate_template_schema(dict) -> ValidationResult` | Structural validation (incl. `title_source` enum, MAJOR-2). |
| `needs_header_footer_prompt(schema) -> bool` | True when the template has neither header nor footer (US-2.1 AC2). |
| `inject_default_header_zone(schema)` | Inject a default header zone into the schema metadata (US-2.1 AC3, schema-only). |
| `embed_schema(pptx, schema, out) -> EmbeddedSchemaResult` | Write `ppt/template_schema.json` into a PPTX copy (US-1.5). |
| `build_extraction_summary(dict) -> str` | Human-readable summary (US-3.3 AC2). |

## Workflow

```
Stage 0  Receive + validate the PPTX path
Stage 1  extract_schema  �?schema dict  (catch TemplateExtractionError -> AC3)
         validate_template_schema(schema)  �?must be valid before continuing
Stage 2  Title confirmation + header/footer check  (US-3.2 AC2/AC3, US-2.1 AC2/AC3)
Stage 3  embed_schema  �?templated PPTX at output/<stem>.templated.pptx  (US-3.3 AC1)
Stage 4  print(build_extraction_summary(schema))  �?return absolute path  (US-3.3 AC2)
```

### Stage 0 �?Receive + validate the path

Confirm the input `.pptx` exists and is readable. If not, report the problem clearly with an actionable fix (AC3) and stop �?do not proceed.

### Stage 1 �?Extract + validate

```bash
python -c "
import sys, json; sys.path.insert(0,'.opencode/skills/_common/scripts')
from schema_extractor import extract_schema, validate_template_schema, TemplateExtractionError
try:
    schema = extract_schema('<INPUT.pptx>')
except TemplateExtractionError as exc:
    print('EXTRACTION_FAILED:', exc); sys.exit(2)
res = validate_template_schema(schema)
print('VALID' if res.is_valid else 'INVALID')
for m in res.error_messages(): print('  -', m)
if not res.is_valid:
    print('VALIDATION_FAILED'); sys.exit(1)  # hard stop �?never embed an invalid schema
# stash the schema to a temp JSON for the next stages
import tempfile, os
p = os.path.join(tempfile.gettempdir(), 'gen_tpl_schema.json')
open(p,'w',encoding='utf-8').write(json.dumps(schema, ensure_ascii=False))
print('SCHEMA_TMP:', p)
print('TITLE:', schema['template_metadata']['title'])
print('TITLE_SOURCE:', schema['template_metadata']['title_source'])
hf = schema['template_metadata'].get('header_footer', {})
print('HAS_HEADER:', hf.get('has_header'))
print('HAS_FOOTER:', hf.get('has_footer'))
"
```

If extraction raised `TemplateExtractionError` (e.g. **"no slide master found"**, unreadable/non-PPTX input) �?restate the error to the user structurally and stop (AC3). If validation is `INVALID` �?list the errors and stop (these indicate an engine bug or a corrupt deck, not user-fixable content).

### Stage 2 �?Title confirmation + header/footer check (US-3.2 AC2/AC3, US-2.1 AC2/AC3)

The schema carries `template_metadata.title`, `title_source` (`core_xml` | `slide1` | `filename`), and `template_metadata.header_footer.{has_header, has_footer}`.

**Title (US-3.2):**
- If `title_source == "filename"` �?the title was NOT found in the deck; it is just the file name. **Prompt the user to name the template** (single `question` call, offering the inferred filename as the default). On a custom answer, overwrite `title` and set `title_source = "user"` in the schema.
- **Always** display the final title to the user for confirmation (AC3), regardless of source.

**Header/footer (US-2.1):**
- If both `HAS_HEADER` and `HAS_FOOTER` printed in Stage 1 are `False` �?ask the user whether to add a default header zone. If the user says yes, call `inject_default_header_zone` on the schema (AC3 �?schema-only, never touches the PPTX):

```bash
python -c "
import sys, json; sys.path.insert(0,'.opencode/skills/_common/scripts')
from schema_extractor import inject_default_header_zone
schema = json.load(open('<SCHEMA_TMP>',encoding='utf-8'))
inject_default_header_zone(schema)
open('<SCHEMA_TMP>','w',encoding='utf-8').write(json.dumps(schema, ensure_ascii=False))
print('Header zone injected into schema')
"
```

**Batching (arch-review M2):** when BOTH the title-source==filename condition AND the header/footer-absent condition fire, batch them into a **single** `question` call (project convention).

**Headless / subagent mode:** skip both prompts; accept filename fallback; do not inject. Never hang.

After any user overrides (title and/or header), persist the changes back into the temp schema JSON so Stage 3 embeds them.

### Stage 3 �?Embed �?templated PPTX (US-3.3 AC1)

```bash
python -c "
import sys, json; sys.path.insert(0,'.opencode/skills/_common/scripts')
from schema_extractor import embed_schema, TemplateExtractionError
schema = json.load(open('<SCHEMA_TMP>',encoding='utf-8'))
try:
    result = embed_schema('<INPUT.pptx>', schema, 'output/<STEM>.templated.pptx')
except (OSError, TemplateExtractionError) as exc:
    print('EMBED_FAILED:', exc); sys.exit(2)
print('OUTPUT:', result.output_path, result.original_bytes, '->', result.new_bytes, '(%+d)' % result.delta_bytes)
"
```

Output goes to `output/<input_stem>.templated.pptx` (matches the project's `output/` convention). The original input is **never modified** �?always a copy.

### Stage 4 �?Summary + return (US-3.3 AC2)

```bash
python -c "
import sys, json; sys.path.insert(0,'.opencode/skills/_common/scripts')
from schema_extractor import build_extraction_summary
schema = json.load(open('<SCHEMA_TMP>',encoding='utf-8'))
print(build_extraction_summary(schema))
"
```

Print the human-readable summary (title + source, slide size, layout count + names, component counts, theme colors, font palette, missing fonts), then return the **absolute path** of the templated PPTX.

## Output Path

Templated PPTX �?`output/<input_stem>.templated.pptx`. Schema JSON (optional side copy) �?`output/<input_stem>.schema.json`.

## Error Handling

| Scenario | Behavior |
|----------|----------|
| Input file missing / not a PPTX | `TemplateExtractionError` �?restate clearly + fix, stop (AC3). |
| No slide master found | `TemplateExtractionError` �?restate clearly, stop (AC3). |
| Schema validation `INVALID` | List errors, stop (engine/deck issue, not user content). |
| Embed write failure (disk/permission) | `OSError` �?restate + fix, stop. |
| `title_source == "filename"` (primary-agent mode) | Prompt user to name the template (Stage 2). |
| Headless / subagent mode | Skip the title prompt; accept filename fallback (never hang). |

Extraction and validation errors map to the engine's exit-code semantics (1 = validation, 2 = runtime); the skill surfaces them as structured messages, not raw tracebacks.

## Coexistence

I produce the embedded `ppt/template_schema.json`. Since US-4.1 the renderer **prefers that embedded JSON** (via `get_render_contract` �?`contract_adapter`), falling back to the sidecar introspection contract (`template_introspector.py`) for legacy/non-templated templates �?the two paths coexist (GAP-ANALYSIS §5 Decision 1). I do **not** touch the renderer.

## Reference

- Plan: `PLANS/PLAN-GIT-56.md`.
- Engine: `.opencode/skills/_common/scripts/schema_extractor.py` (`extract_schema`, `validate_template_schema`, `embed_schema`, `build_extraction_summary`, `TITLE_SOURCES`, `TitleInference`).
- Peer skills: `pptx-generate-slide-skill` (fill), `pptx-template-modifier-skill` (extend).
- Requirements: `docs/user-stories/chenyu-user-stories.md` �?Epic 3 (US-3.1�?.3).
