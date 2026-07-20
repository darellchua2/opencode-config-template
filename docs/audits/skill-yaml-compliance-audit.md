# Skill YAML Frontmatter Compliance Audit

**Date:** 2026-07-20
**Scope:** Every `SKILL.md` under `opencode_app/.opencode/skills/` (configurator repo source of truth)
**Mode:** Read-only audit — no files were modified
**Canonical reference:** https://opencode.ai/docs/skills (section "Write frontmatter")

---

## 1. Summary

| Metric | Count |
|---|---|
| `SKILL.md` files scanned | **121** |
| 　• Active skills | 115 |
| 　• Archived skills (`_archived/*/`) | 6 |
| Files with valid `---` frontmatter | 121 (100%) |
| **Files with NON-STANDARD top-level fields** | **0** |
| **Files requiring field relocation (move to body)** | **0** |
| Files with optional-field gaps (NOT a violation) | 2 |
| Files flagged for value-type human review (UNKNOWN) | 28 |

**Headline:** The skill library is **fully frontmatter-compliant**. Every top-level YAML key across all 121 files is one of the five canonical fields (`name`, `description`, `license`, `compatibility`, `metadata`). There are **no non-standard fields to relocate**. The two items the audit hypothesis suspected as offenders — the nested `metadata:` block and `compatibility:` — are both **explicitly canonical** per the official docs.

The only actionable findings are:
1. **2 files** omit optional fields (`license`/`compatibility`/`metadata`) — optional, not a violation.
2. **28 files** use YAML *array* values inside `metadata:` (e.g. `languages: [typescript, python]`); the docs specify `metadata` is a "string-to-string map", so array values are a value-type nuance flagged for human review (see §6).

---

## 2. Canonical Schema (with citation)

**Source:** https://opencode.ai/docs/skills — section *“Write frontmatter”* (retrieved 2026-07-20). The sub-page `/docs/skills/creating-skills` returns 404; the canonical page contains the full schema.

> Each `SKILL.md` must start with YAML frontmatter. Only these fields are recognized:
> - `name` (required)
> - `description` (required)
> - `license` (optional)
> - `compatibility` (optional)
> - `metadata` (optional, string-to-string map)
>
> Unknown frontmatter fields are ignored.

Supporting constraints from the same page:
- `name`: 1–64 chars, lowercase alphanumeric, single hyphens only, regex `^[a-z0-9]+(-[a-z0-9]+)*$`, must match the enclosing directory name.
- `description`: 1–1024 chars.
- `metadata`: a **flat string-to-string map** — arbitrary user-defined keys whose values are strings.

| Field | Status | Required | Notes |
|---|---|---|---|
| `name` | CANONICAL | yes | Must match directory name; regex-validated |
| `description` | CANONICAL | yes | 1–1024 chars |
| `license` | CANONICAL | no | e.g. `MIT`, `Apache-2.0` |
| `compatibility` | CANONICAL | no | e.g. `opencode` |
| `metadata` | CANONICAL | no | **Nested string-to-string map**; sub-keys are arbitrary |

---

## 3. Field Classification Table

Every distinct **top-level** key found across all 121 `SKILL.md` files, classified against the canonical schema:

| Top-level field | Occurrences | Classification |
|---|---|---|
| `name` | 121 / 121 | **CANONICAL** (required) |
| `description` | 121 / 121 | **CANONICAL** (required) |
| `metadata` | 120 / 121 | **CANONICAL** (optional) |
| `license` | 119 / 121 | **CANONICAL** (optional) |
| `compatibility` | 119 / 121 | **CANONICAL** (optional) |

**No other top-level fields exist in any file.** There are zero NON-STANDARD and zero UNKNOWN top-level fields.

### 3a. Nested `metadata:` sub-keys (all valid arbitrary map entries)

The docs define `metadata` as a free-form string-to-string map, so the sub-key names themselves are not schema-constrained — any key is permitted. The following sub-keys are in use:

| `metadata.*` sub-key | Files | Notes |
|---|---|---|
| `audience` | 113 | String value (canonical usage) |
| `workflow` | 113 | String value (canonical usage) |
| `protocol` | 33 | String value |
| `languages` | 27 |  **Array value** — see §6 |
| `trigger` | 18 | String value |
| `version` | 5 | String value |
| `scope` | 3 | String value |
| `pattern` | 3 | String value |
| `frameworks` | 2 |  **Array value** — see §6 |
| `protocol-source` | 1 | String value |

> The originally-suspect `metadata:` nested block (e.g. `autoresearch-code-skill` with `audience`/`workflow`/`protocol`) is **CANONICAL** — confirmed verbatim by the docs example, which itself shows `metadata: { audience: maintainers, workflow: github }`.

> `compatibility: opencode` is **CANONICAL** — listed explicitly as an optional field.

---

## 4. Per-File Remediation Table (non-compliant only)

**Empty — no files require relocation of a non-standard field.**

| File | Non-standard field(s) | Recommended target section |
|---|---|---|
| _(none)_ | — | — |

Of the 121 files audited, **0** contain a top-level YAML key outside the canonical set `{name, description, license, compatibility, metadata}`. Consequently no field needs to be moved to body prose, and no information needs to be preserved elsewhere. The audit hypothesis (non-standard fields present) is **rejected**.

For completeness, the two adjacent observations that are NOT violations:

### 4a. Optional-field gaps (NOT violations; all fields are optional except `name`/`description`)

| File | Missing optional field(s) | Recommendation |
|---|---|---|
| `codegraph-setup-skill/SKILL.md` | `metadata`, `license`, `compatibility` | Consider adding for consistency (has only `name` + `description`) |
| `pr-merge-workflow-skill/SKILL.md` | `license`, `compatibility` | Consider adding `license`/`compatibility` to match sibling skills |

These are **optional** fields per the docs; their absence does not break loading. Listed only so a standardization pass can decide whether to normalize them.

---

## 5. Recommended Body-Section Conventions

Because **no field relocation is needed**, no body-section convention is mandated by this audit. The following convention is recorded for **future** skill authoring so that any genuinely non-standard metadata (if introduced later) has a deterministic home:

- If a future field is purely descriptive metadata (audience, author, version, etc.) and is *not* a valid `metadata:` sub-key, place it under a `## Metadata` heading in the body.
- Do **not** invent new top-level YAML keys — per the docs, *"Unknown frontmatter fields are ignored."* An unknown key is silently dropped, so any value placed there is effectively lost to the runtime.

### Already-compliant note (§7 of the request)

No skill currently stores metadata in a `## Metadata` body heading or inline comments — every skill keeps its metadata inside the canonical YAML `metadata:` map, which is the **correct** pattern per the docs. There is therefore nothing to call out as "already compliant via an alternative convention"; the canonical convention is already universally adopted.

---

## 6. Open Questions for Human Review

### Q1 (UNKNOWN — value type): Array values inside `metadata:`

The docs state `metadata` is a **"string-to-string map"**. The docs example uses scalar string values (`audience: maintainers`). However, **28 skills** encode list-like data as YAML inline arrays:

| File | Offending line(s) |
|---|---|
| `accessibility-a11y-skill` | `languages: [typescript, javascript, html, css]` |
| `api-design-skill` | `languages: [typescript, python, openapi, graphql]` |
| `authentication-authorization-skill` | `languages: [typescript, python]` |
| `brd-creation-skill` | `languages: [markdown]` |
| `clean-architecture-skill` | `languages: [language-agnostic]` |
| `clean-code-skill` | `languages: [language-agnostic]` |
| `code-smells-skill` | `languages: [language-agnostic]` |
| `complexity-management-skill` | `languages: [language-agnostic]` |
| `database-migration-skill` | `languages: [sql, typescript, python]` |
| `design-patterns-skill` | `languages: [language-agnostic]` |
| `docker-containerization-skill` | `languages: [dockerfile, yaml]` |
| `interactive-document-rendering-skill` | `languages: [html, markdown]` |
| `logging-observability-skill` | `languages: [typescript, python]` |
| `monorepo-management-skill` | `languages: [typescript, javascript]` |
| `object-design-skill` | `languages: [language-agnostic]` |
| `openapi-contract-adherence-skill` | `languages: [openapi, typescript, python]` |
| `performance-optimization-skill` | `languages: [typescript, python, javascript]` |
| `pr-creation-workflow-skill` | `languages: [language-agnostic]` |
| `python-backend-skill` | `languages: [python]` |
| `python-packaging-skill` | `languages: [python]` |
| `react-nextjs-antipatterns-skill` | `languages: [typescript, javascript]`; `frameworks: [react, nextjs]` |
| `security-audit-skill` | `languages: [language-agnostic]` |
| `solid-principles-skill` | `languages: [language-agnostic]` |
| `srs-creation-skill` | `languages: [markdown]` |
| `technical-design-creation-skill` | `languages: [markdown]` |
| `threejs-nextjs-skill` | `languages: [typescript, javascript]`; `frameworks: [three.js, react-three-fiber, next.js, react]` |
| `uiux-review-skill` | `languages: [typescript, javascript, html, css, tsx, jsx]` |
| `vision-creation-skill` | `languages: [markdown]` |

**Why this is flagged:** the key names (`languages`, `frameworks`) are perfectly valid arbitrary `metadata` sub-keys — they are **not** non-standard fields. The concern is purely the **value type**: a YAML inline array deserializes to a list, not a string. The documented contract is "string-to-string map". OpenCode's behavior here is **not specified in the docs** — it may (a) coerce the array to a string, (b) accept it as-is, (c) drop/ignore the entry, or (d) error.

**Recommended action for the remediation ticket (decision required):**
- **Option A (normalize to string):** convert each array to a comma-joined string, e.g. `languages: typescript, python`. This is unambiguously spec-compliant. Lossless and mechanical.
- **Option B (verify runtime tolerance first):** load one of these skills in a live OpenCode session and confirm whether the `languages`/`frameworks` value survives. If the runtime accepts arrays, no change is needed; if it drops them, apply Option A.

This is the **single most impactful** remediation item, but it is a value-type question, not a field-relocation question, so it does not populate the §4 table.

### Q2 (minor): Standardize optional fields on the 2 gap files?

Should `codegraph-setup-skill` and `pr-merge-workflow-skill` be given `license`/`compatibility`/`metadata` to match the rest of the library? This is a style/consistency decision, not a compliance fix. Default recommendation: yes, add `license: Apache-2.0`, `compatibility: opencode`, and a `metadata:` block to match the library norm.

### Q3 (informational): Archived skills

Six skills live under `_archived/`. They are also fully compliant (same 5 canonical keys). No action required unless the team wants to strip archived skills from deployment — that is out of scope for a frontmatter audit.

---

## Methodology

1. Fetched the canonical schema from https://opencode.ai/docs/skills (the `/skills/creating-skills` sub-page returns 404; the main page is authoritative).
2. Enumerated all `SKILL.md` files via filesystem walk (the `glob` tool skips `.opencode/` dot-directories, so directory listing + `find` were used instead).
3. Parsed each file's YAML frontmatter (text between the first two `---` lines) with a Python extractor, recording every top-level key and every nested `metadata:` sub-key.
4. **Cross-validated** the Python parser with an independent `awk`-based extraction — both tools agreed on the exact field set, ruling out parser blind spots.
5. Verified no file uses quoted keys, no file omits the opening `---`, and no file contains agent-style fields (`tools`, `permission`, `mode`, `model`, `steps`, etc.) in its frontmatter.
6. Flagged value-type nuances (array values) separately from field-presence findings.

**Audit artifacts (ephemeral, outside repo):** `/tmp/skill_audit/audit.py`, `/tmp/skill_audit/results.json`.

---

## Resolution

**Date:** 2026-07-20
**Decided by:** implementation pass of PLAN-GIT-254 (issue #254)

### Decision

**Option A — normalize all array values in `metadata:` to comma-joined strings.**

### Rationale

The OpenCode docs explicitly specify `metadata` as a **"string-to-string map"** (see §2). YAML inline arrays (`[a, b, c]`) deserialize to a list, not a string, which is **not** the documented contract. Runtime tolerance of array values is **undocumented** — relying on it would be fragile and could silently break if the runtime tightens validation.

Comma-joined strings are:
- **Unambiguously spec-compliant** — strings are the documented value type.
- **Lossless** — no information is lost; the comma-separated form carries the same data.
- **Mechanical** — applied via a single regex transform, no judgement calls.
- **Forward-compatible** — if the runtime later adds explicit array support, the comma-string form continues to work; the reverse is not guaranteed.

Option B (verify runtime tolerance first) was rejected because even if the runtime tolerates arrays today, the docs do not guarantee this behavior across versions. Spec-compliance is the safer anchor.

### What was changed

- **27 files** had `languages: [...]` converted to `languages: ...` (comma-joined, brackets removed).
- **1 file** (`react-nextjs-antipatterns-skill`) also had `frameworks: [react, nextjs]` converted to `frameworks: react, nextjs`.
- **Total files touched:** 27 of the 28 flagged in §6.

### Reconciliation: 27 of 28 (not 28 of 28)

The §6 table lists 28 skills. Only **27** were found and modified during the implementation pass. The missing entry is **`threejs-nextjs-skill`** — the directory does not exist under `opencode_app/.opencode/skills/` (verified via `find . -type d -name "*threejs*"` → 0 results, and `find . -name "SKILL.md" -path "*three*"` → 0 results). This is an **audit enumeration error**: the §6 row for `threejs-nextjs-skill` references a file that is not present in the repo. The system-prompt skill catalog still references `threejs-nextjs-skill`, so it may have been deleted from the source tree without updating the catalog, or it may exist in a different deploy target outside this configurator repo.

**Net effect on compliance:** zero. The 27 skills that did exist and used array values are all normalized. The phantom 28th entry has no file to be non-compliant.

### Verification

- `grep -lE "^[[:space:]]*(languages|frameworks):[[:space:]]*\[" */SKILL.md` → 0 matches.
- Broader scan for any `key: [...]` pattern inside any SKILL.md frontmatter → 0 matches.
- No `languages:` or `frameworks:` value was lost; every entry round-trips losslessly.

### Out of scope

- §Q2 (optional-field gaps on `codegraph-setup-skill` and `pr-merge-workflow-skill`) — deferred; style decision, not a compliance fix.
- §Q3 (archived skills) — no action required per the audit.
