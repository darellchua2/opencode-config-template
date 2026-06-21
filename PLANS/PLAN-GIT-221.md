# PLAN: Add `openapi-contract-adherence-skill` for API contract evolution workflow

**Issue**: [#221 — feat: add openapi-contract-adherence-skill for API contract evolution workflow](https://github.com/darellchua2/opencode-config-template/issues/221)
**Branch**: `issue-221`
**Status**: In Progress
**Revision**: v2 — incorporates opencode-tooling-subagent review (C-1, C-2, M-1..M-3, m-1..m-5, n-1..n-3)

---

## Summary

The existing `api-design-skill` covers API **authoring** (REST conventions, OpenAPI spec generation, GraphQL schema design) but does not address API **evolution** — detecting breaking changes between spec revisions, mapping those changes to consumer-side code, and generating machine-readable migration plans. As codebases evolve, every OpenAPI spec change ripples to generated clients and direct fetch/axios callers; without an automated contract-adherence workflow, these ripples are discovered at runtime, not at PR time.

This plan creates a new **`openapi-contract-adherence-skill`** that closes that gap using the industry-standard toolchain:

- **`oasdiff`** (Tufin) — primary diffing tool; native breaking/non-breaking/additive classification, semver-bump detection, JSON/markdown/text output
- **`@redocly/cli`** / **`spectral`** — spec validation/linting before diffing
- **`openapi-generator-cli`** / **`@hey-api/openapi-ts`** / **`orval`** — client SDK regeneration
- **Pact** — consumer-driven contract testing (referenced for advanced cases)

The skill produces two artifacts: `CONTRACT_DIFF.md` (human-readable migration report) and `CONTRACT_DIFF.json` (machine-readable, consumable by `pr-creation-workflow-skill` as a PR quality gate).

### Confirmed Decisions (from issue #221 scoping)

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Skill approach | New dedicated skill | Clean separation: `api-design-skill` = authoring, `openapi-contract-adherence-skill` = evolution |
| Language scope | Language-agnostic core + TS-first examples | Core workflow neutral; TS is the dominant consumer stack in this repo's target projects |
| Primary diffing tool | `oasdiff` | De-facto standard, single Go binary, docker image available, native semver detection |
| PR gate integration | Yes — emit `CONTRACT_DIFF.json` | Enables automated label selection and breaking-change block rules in PR workflow |
| Output format | Markdown + JSON | Human review + machine consumption; aligns with existing artifact conventions |

### Architecture

The skill is invoked by the primary agent when a user mentions OpenAPI changes, contract diffing, or breaking changes. It runs end-to-end (discover → validate → diff → classify → impact-map → report) and emits artifacts at the repo root (or a configurable `CONTRACT_REPORT_DIR`):

```
User trigger ("openapi diff", "breaking change", "consumer update plan")
  → Primary agent loads openapi-contract-adherence-skill
  → Step 1: Discover baseline (git merge-base) + current spec
  → Step 2: Validate both specs (redocly lint)
  → Step 3: Diff with oasdiff (changelog + breaking --format json)
  → Step 4: Classify (Severity / Semver / Consumer Action matrix)
  → Step 5: Map consumers (SDK configs + direct fetch/axios sites)
  → Step 6: Emit CONTRACT_DIFF.md + CONTRACT_DIFF.json
  → Step 7 (optional): pr-creation-workflow-skill consumes JSON for PR gate
```

**Key principle:** The skill is `trigger: explicit-only` — it never runs unless the user or a calling workflow asks. It does not modify specs or consumer code; it produces reports and recommendations only.

---

## Dependency & Consumer Map

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---------------------|---------------------------|---------------------------------|-------------|
| `openapi-contract-adherence-skill/SKILL.md` | No new deps; references existing `api-design-skill` as related | Primary agent (loads it); `deploy/setup.sh`, `deploy/setup.ps1` (count); `README.md` (table); `pr-creation-workflow-skill` (optional Phase 3) | medium |
| `deploy/setup.sh` | New skill must exist before incrementing count | User-space deploy consumers | low |
| `deploy/setup.ps1` | New skill must exist before incrementing count | Windows deploy consumers | low |
| `README.md` | New skill must exist before table update | Repo consumers reading docs | low |
| `pr-creation-workflow-skill/SKILL.md` | Phase 1+2 complete (skill exists, counts synced) | `pr-workflow-subagent` (consumes JSON) | low (additive) |

---

## Implementation Phases

### Phase 0: Pre-flight Verification

> **Why first:** Verify the target category, current counts, and naming conventions before authoring. Avoids drift and naming collisions discovered late.

- [ ] **0.1** Verify no skill named `openapi-contract-adherence-skill` already exists in `opencode_app/.opencode/skills/`
    — **Why:** Prevents clobbering or accidental duplicate creation.
    — **Done when:** `ls opencode_app/.opencode/skills/ | grep openapi-contract` returns nothing.
    — **Consumers affected:** All downstream phases.

- [ ] **0.2** Confirm skill name matches `^[a-z][a-z0-9-]{0,63}$` (OpenCode naming rule from `opencode-skill-creation-skill`)
    — **Why:** Invalid names break `opencode` skill loading.
    — **Done when:** `openapi-contract-adherence-skill` validates against the regex.
    — **Consumers affected:** Skill loader.

- [ ] **0.3** Verify current actual skill directory count (excluding `_archived/`): **81** directories, but **80 actual SKILL.md files** — the `scripts/` subdirectory inflates the count by 1 (it's a support directory, not a skill). Confirm pre-existing drift:
    - `deploy/setup.sh` line 586 banner says `SKILLS (82)`, line 2357 banner says `82 Skills Available` (drift +1 over real dirs, +2 over real SKILL.md files)
    - `deploy/setup.ps1` has matching drift at line 382 (banner) and line 1727 (banner)
    - **CRITICAL — additional drift:** `deploy/setup.sh:2226` deploy-status section says `Framework (11)` while banner says `Framework (13)`. `deploy/setup.ps1:1228` has the same. These sections also miss `api-design-skill` and `performance-optimization-skill` from their Framework listing and show `Language-Specific (4)` instead of `(6)`.
    - `README.md` line 280 says "82 skills" and line 26 of `opencode_app/README.md` says "82 skill directories" (both coincidentally correct after this plan adds 1).
    - After Phase 1 adds 1 skill and Phase 2 fixes drift, banner counts stay at **82** (now correct vs real dirs), Framework banner goes 13→14, Framework status section goes 11→14.
    — **Why:** Pre-existing count drift must be fixed in the same PR (per `documentation-consistency-skill` rules). PLAN-GIT-218 had to fix similar multi-location drift (ISSUE-9); this plan must do the same. The `scripts/` directory inflation is acknowledged here so verification commands exclude it.
    — **Done when:** Every drift location catalogued (banner + status sections of both deploy scripts, README total line, opencode_app/README line). Phase 2 subtasks reference exact lines.
    — **Consumers affected:** Phase 2 sync tasks.

- [ ] **0.4** Confirm the new skill belongs in the **Framework** category alongside `api-design-skill` (current home at `deploy/setup.sh:587`, `deploy/setup.ps1:383`, `README.md:286`). Framework count goes **13 → 14** in all three files.
    — **Why:** Keeps API-related skills colocated; avoids introducing a 15th category that complicates the table. `api-design-skill` (authoring) and `openapi-contract-adherence-skill` (evolution) form a natural pair.
    — **Done when:** Category decision documented; all three target files identified for the 13→14 update.
    — **Consumers affected:** Phase 2 category updates.

---

### Phase 1: Create `openapi-contract-adherence-skill`

- [ ] **1.1** Create directory `opencode_app/.opencode/skills/openapi-contract-adherence-skill/` and `SKILL.md` with frontmatter:
    - `name: openapi-contract-adherence-skill`
    - `description:` Mention triggers explicitly: "Detect OpenAPI contract changes, classify breaking vs additive, map consumer impact, and generate migration plans using oasdiff. Triggers on: openapi diff, api contract, breaking change, consumer update plan, contract review."
    - `license: Apache-2.0`
    - `compatibility: opencode`
    - `metadata.audience: developers, API engineers, agents`
    - `metadata.workflow: contract-management, api-evolution`
    - `metadata.trigger: explicit-only`
    - `metadata.languages: [openapi, typescript, python]`
    — **Why:** Establishes the skill as a first-class library member with metadata that deploy scripts can ingest.
    — **Done when:** Directory exists and `SKILL.md` frontmatter parses as valid YAML.
    — **Consumers affected:** `deploy/setup.sh`, `deploy/setup.ps1`, `README.md` (Phase 2 sync).

- [ ] **1.2** Author **"What I do"** section listing the 6 capabilities: validate specs, diff with oasdiff, classify changes, map consumer impact, generate dual-format report, emit PR-gate artifact.
    — **Why:** Mirrors the structure of `api-design-skill` for consistency.
    — **Done when:** Section present with the 6 capabilities in one-line bullets.
    — **Consumers affected:** Skill selection logic (description match).

- [ ] **1.3** Author **"When to use me"** section with trigger phrases:
    - "openapi diff"
    - "api contract"
    - "breaking change"
    - "consumer update plan"
    - "contract review"
    - "spec changed"
    - "regenerate client"
    — **Why:** Explicit-only trigger means skill selection depends on phrase matching; broader phrases improve recall.
    — **Done when:** Section lists at least the 6 trigger phrases above.
    — **Consumers affected:** Primary agent skill loader.

- [ ] **1.4** Author **"Prerequisites"** section documenting install commands:
    - **oasdiff binary**: `go install github.com/oasdiff/oasdiff@latest` OR `brew install oasdiff` (repo moved from `tufin/oasdiff` → `oasdiff/oasdiff` in 2024)
    - **oasdiff Docker** (fallback, no local install): `docker pull tufin/oasdiff:stable` — **use `:stable` or a pinned version tag** (e.g., `:v1.19.1`); avoid bare `:latest` which tracks main and may contain unreleased commits
    - **Version pinning**: pin to a specific release (e.g., `go install github.com/oasdiff/oasdiff@v1.19.1` or `docker pull tufin/oasdiff:v1.19.1`) to keep binary/Docker output schemas consistent. As of 2026-06-14, latest stable is **v1.19.1**.
    - **Node.js requirement**: oasdiff itself is Go-based (no Node), but the SDK generators below require Node ≥22.x
    - **redocly** (primary linter): `npm i -g @redocly/cli` (latest `2.34.0`; requires Node ≥22.12.0)
    - **spectral** (alternative linter): `npm i -g @stoplight/spectral-cli` (latest `6.16.0`)
    - **SDK generators** (TS): `npm i -D @hey-api/openapi-ts` (latest `0.98.2`; Node ≥22.18.0) / `orval` (latest `8.18.0`; Node ≥22.18.0) / `@openapitools/openapi-generator-cli` (latest `2.39.0`; Node ≥22.0.0)
    - **SDK generators** (Python): `@openapitools/openapi-generator-cli generate -g python` (CLI is Node-based but generates Python output); `fastapi-code-generator` (PyPI, latest `0.7.0` — NOT `fastapi-codegen` which does not exist)
    — **Why:** Skill assumes these tools are installed; documenting them up front prevents runtime failures. Pinning versions avoids output schema drift between the local binary and the Docker fallback. Node version requirements prevent silent install failures on older runtimes.
    — **Done when:** Section contains install commands for oasdiff (binary + docker + version pinning note) and at least 2 SDK generators, with latest version numbers and Node requirements noted.
    — **Consumers affected:** All downstream steps.

- [ ] **1.5** Author **Step 1: Discover Specs** — baseline spec resolution via `git show $(git merge-base HEAD main):openapi.yaml` (or user-supplied path); current spec from working tree. Include fallback for non-git contexts (user-supplied baseline path).
    - **Monorepo handling**: support glob discovery `**/openapi.{yaml,yml,json}` for repos with multiple services; iterate over each (baseline, revision) pair and produce per-service reports `CONTRACT_DIFF.<service>.md` / `CONTRACT_DIFF.<service>.json`, plus an aggregated summary.
    — **Why:** Establishes the comparison basis before any diff can run. Monorepos with per-service specs (e.g., `services/auth/openapi.yaml`, `services/orders/openapi.yaml`) need batch handling or the skill silently processes only one.
    — **Done when:** Step documents git-based and manual baseline resolution with shell examples, plus a monorepo glob pattern and per-service output naming convention.
    — **Consumers affected:** Step 3 (diff).

- [ ] **1.6** Author **Step 2: Validate** — run `redocly lint` (or `spectral lint`) on both specs *before* diffing. Surface validation errors as a hard stop.
    — **Why:** oasdiff on malformed specs produces misleading diffs. Linting first guarantees a trustworthy comparison.
    — **Done when:** Step contains the redocly command with `--format github-actions` and an alternative spectral invocation.
    — **Consumers affected:** Step 3 (diff).

- [ ] **1.7** Author **Step 3: Diff** — three oasdiff invocations producing **intermediate** artifacts that Step 6 assembles into final deliverables:
    ```bash
    # (1) All changes (additive + breaking) in markdown — feeds the human report
    oasdiff changelog base.yaml revision.yaml --format markdown > .oasdiff-changelog.md

    # (2) All changes in JSON — feeds summary.nonBreaking / summary.cosmetic counts
    oasdiff changelog base.yaml revision.yaml --format json > .oasdiff-changelog.json

    # (3) Breaking changes only, in JSON — feeds summary.breaking + breakingChanges[]
    oasdiff breaking base.yaml revision.yaml --format json > .oasdiff-breaking.json
    ```
    Include the Docker fallback form: `docker run --rm -t -v $(pwd):/specs tufin/oasdiff breaking /specs/base.yaml /specs/revision.yaml --format json`.
    - **Naming convention**: intermediate files use a leading `.` (e.g., `.oasdiff-changelog.md`) to distinguish them from final deliverables (`CONTRACT_DIFF.md`, `CONTRACT_DIFF.json`) produced in Step 6. Add `.oasdiff-*` to `.gitignore`.
    — **Why (M-2):** Step 3 produces intermediate oasdiff outputs; Step 6 produces the final assembled deliverables. Naming them distinctly prevents confusion and avoids committing raw oasdiff dumps. **Why (M-3):** The Step 6 JSON schema has `summary.nonBreaking` and `summary.cosmetic` counts; only `oasdiff changelog --format json` provides all changes in machine-countable form, so command (2) is mandatory.
    — **Done when:** Step has all three commands, the Docker fallback, the intermediate-vs-final naming convention, and an explicit mapping of which intermediate feeds which final artifact field.
    — **Consumers affected:** Steps 4, 6 (classify + report).

- [ ] **1.8** Author **Step 4: Classify Changes** — a mapping table with **at least 16 change types** spanning the realistic oasdiff check catalog:

    | Change Type | Severity | Semver Impact | Consumer Action |
    |-------------|----------|---------------|-----------------|
    | Operation removed (e.g., `DELETE /users/{id}`) | Breaking | Major | Remove/replace call site |
    | Required request field added | Breaking | Major | Send the new field in requests |
    | Request/response field type changed | Breaking | Major | Update type annotations + parsing |
    | Response field removed | Breaking | Major | Stop relying on the field |
    | Enum value removed | Breaking | Major | Remove branches relying on that value |
    | Required response field added | Breaking (server→client) | Major | Update consumer null-checks |
    | Operation path/parameter renamed | Breaking | Major | Update route construction |
    | **Response status code removed/changed** | **Breaking** | **Major** | **Update success/error branching** |
    | **Security scheme removed or changed** | **Breaking** | **Major** | **Update auth headers / token flow** |
    | **Required header removed** | **Breaking** | **Major** | **Stop sending or update request builder** |
    | **Parameter `format` changed (e.g., int32→int64)** | **Breaking** | **Major** | **Update parser / type width** |
    | **Constraint tightened (min/max/maxLength)** | **Breaking** | **Major** | **Re-validate inputs client-side** |
    | Optional request field added | Non-breaking | Minor | Optional adoption |
    | Optional response field added | Non-breaking | Minor | Optional adoption |
    | New operation added | Additive | Minor | Optional adoption |
    | New response field (additive) | Additive | Minor | Optional adoption |
    | Description/title/summary updated | Cosmetic | Patch | None |
    | Tag/category renamed | Cosmetic | Patch | None |
    - **`semverBump` rollup rule (n-2)**: `major` if any breaking; else `minor` if any additive; else `patch` if any cosmetic; else `none`.
    — **Why:** A complete classification table is the single most-referenced part of the skill — agents and humans consult it to decide what action a change demands. The original 10-row table missed realistic change types oasdiff detects natively (status codes, security schemes, headers, constraints); the expanded table covers the full oasdiff check catalog. Rollup rule prevents ambiguity in `summary.semverBump` derivation.
    — **Done when:** Table has at least 16 rows spanning Breaking / Non-breaking / Additive / Cosmetic severities with semver mapping, AND a rollup rule for `semverBump`.
    — **Consumers affected:** Step 5 (impact), Step 6 (report), PR gate.

- [ ] **1.9** Author **Step 5: Consumer Impact Mapping** — three sub-operations:
    1. **Locate SDK generators**: `rg -l "openapi-generator|hey-api|orval" --glob "*.{json,js,ts,yaml,yml,rc}"` to find generator configs.
    2. **Find direct call sites**: for each changed operation path, run a concrete grep. Example for `DELETE /api/v1/users/{id}`:
       ```bash
       # TypeScript: brace-escape the {id} and pin to quoted strings
       rg -n --type ts "(fetch|axios)\(['\"\`][^'\"]*/api/v1/users/[^'\"]+['\"\`]"
       # Python: httpx/requests
       rg -n --type py "(httpx|requests)\.(get|post|put|patch|delete)\(['\"\`][^'\"]*/api/v1/users/[^'\"]+"
       ```
       For path parameters with `{id}` braces, escape them in the regex (`\{id\}`) since ripgrep treats `{}` as quantifier syntax in some modes.
    3. **Identify generated client files**: typical locations `src/api/*`, `src/generated/*`, `client/sdk/*`. Add a `.openapi-generator-ignore` (or `.swagger-codegen-ignore`) recommendation so regeneration doesn't clobber hand-edited wrapper files.
    - **Zero-result fallback**: if all three sub-operations return empty (no generator config, no direct call sites, no generated client dirs), emit a warning that consumers may use a custom HTTP wrapper or dynamically-constructed URLs — recommend manual review of `src/services/`, `src/lib/api/`, and `src/api/client/` directories.
    — **Why:** Without impact mapping, the migration report has no teeth — consumers can't tell which of their files need updating. The concrete regex form (with brace escaping) avoids greedy matches and ripgrep quirks; the zero-result fallback prevents silent failure when consumers don't fit the standard patterns.
    — **Done when:** Step documents all three sub-operations with concrete ripgrep examples (including brace-escape for path params), the `.openapi-generator-ignore` recommendation, the zero-result fallback, and output → `affectedConsumers[]` JSON shape.
    — **Consumers affected:** Step 6 (report generation).

- [ ] **1.10** Author **Step 6: Migration Report Generation** — provide full templates for both artifacts:

    **`CONTRACT_DIFF.md` (human-readable)** — sections:
    - Summary (baseline/revision refs, breaking count, additive count, cosmetic count, semver bump)
    - Breaking Changes (each with `BC-N` ID, severity badge, change description, affected consumers with file:line, numbered migration steps)
    - Additive Changes
    - Cosmetic Changes
    - SDK Regeneration Commands

    **`CONTRACT_DIFF.json` (machine-readable)** — schema:
    ```json
    {
      "baseline": "<git-sha-or-path>",
      "revision": "<git-sha-or-path>",
      "generatedAt": "ISO-8601",
      "summary": {
        "breaking": <int>,
        "nonBreaking": <int>,
        "cosmetic": <int>,
        "semverBump": "major" | "minor" | "patch" | "none"
      },
      "breakingChanges": [
        {
          "id": "BC-1",
          "method": "DELETE",
          "path": "/api/v1/users/{id}",
          "changeType": "operation-removed",
          "severity": "MAJOR",
          "affectedConsumers": [
            { "file": "<path>", "line": <int>, "snippet": "<one-line code excerpt>" }
          ],
          "migrationSteps": ["step 1", "step 2"]
        }
      ],
      "additiveChanges": [...],
      "cosmeticChanges": [...]
    }
    ```
    — **Why:** Two formats serve two audiences — humans reviewing a PR diff, and machines gating the PR. The JSON schema must be stable for `pr-creation-workflow-skill` to consume reliably.
    — **Done when:** SKILL.md contains both templates verbatim with placeholder values and a worked example.
    — **Consumers affected:** PR gate (Phase 3).

- [ ] **1.11** Author **Step 7: PR Gate Integration** — document which `CONTRACT_DIFF.json` fields `pr-creation-workflow-skill` consumes:
    - `summary.semverBump` → selects PR label (`major` / `minor` / `patch`)
    - `summary.breaking > 0` → blocks auto-merge when `--require-approval` is set
    - `breakingChanges[].affectedConsumers[]` → included in reviewer prompt for informed review
    — **Why:** Makes the integration contract explicit so future changes to either skill remain backward-compatible.
    — **Done when:** Step lists all three consumed fields with their downstream effects.
    — **Consumers affected:** Phase 3 (PR workflow patch).

- [ ] **1.12** Author **Step 8: SDK Regeneration** — command table:

    | Generator | Command | Output Location | Notes |
    |-----------|---------|-----------------|-------|
    | `@hey-api/openapi-ts` (config-file, recommended) | Create `openapi-ts.config.ts` (NOT `hey-api.config.ts`) with `input: 'openapi.yaml'`, `output: 'src/api/generated'`, `plugins: ['@hey-api/sdk', '@hey-api/client-fetch']` (plugins are an array of strings or `{ name, ...options }` objects per the official docs at heyapi.dev); run `npx @hey-api/openapi-ts` | `src/api/generated/**` | Current plugin-based config (verified vs `@hey-api/openapi-ts` 0.98.2 docs at heyapi.dev/docs/openapi/typescript/configuration); TanStack Query integration is via a separate plugin — verify the exact plugin name against the plugin catalog when authoring |
    | `orval` | `npx orval --config ./orval.config.ts` | `src/api/**` | TS + react-query/swr |
    | `openapi-generator-cli` (TS) | `openapi-generator-cli generate -i openapi.yaml -g typescript-fetch -o src/api` | `src/api/**` | TS fetch client |
    | `openapi-generator-cli` (Python) | `openapi-generator-cli generate -i openapi.yaml -g python -o ./client` | `./client/**` | Python httpx-based client |
    | `fastapi-code-generator` (Python, server) | `fastapi-codegen --input openapi.yaml --output app/` (installed via `pip install fastapi-code-generator`; the CLI binary is named `fastapi-codegen`) | `app/**` | Server-side stubs. **Note**: PyPI package is `fastapi-code-generator` (with `-rator`); there is no `fastapi-codegen` package on PyPI |
    - **File-protection note**: regeneration overwrites generated dirs. Document `.openapi-generator-ignore` / `.swagger-codegen-ignore` for hand-edited wrapper files outside generated dirs.
    — **Why:** After migration, regenerating clients is the most common follow-up action; a command table saves users from docs lookups. The current `@hey-api/openapi-ts` uses a config-file + plugins model, not the `-c <client>` shorthand from older versions.
    — **Done when:** Table covers at least 4 generators with TS and Python representation, and uses the current `@hey-api/openapi-ts` config-file form as the canonical example.
    — **Consumers affected:** End users executing migration.

- [ ] **1.13** Author **Return Contract** section following repo convention:
    ```
    **Status:** [success | partial | failed]
    **Output:** CONTRACT_DIFF.md, CONTRACT_DIFF.json
    **Summary:** N breaking changes detected across M consumer files; semver bump: <major|minor|patch>
    **Issues:** [blockers or "None"]
    ```
    — **Why:** All repo skills must follow the standardized Return Contract per AGENTS.md.
    — **Done when:** Section present with the four-line format.
    — **Consumers affected:** Primary agent (parses return).

- [ ] **1.14** Author **Related Skills** section linking to:
    - `api-design-skill` (authoring counterpart)
    - `pr-creation-workflow-skill` (PR gate consumer)
    - `verification-loop-skill` (general verification)
    - `documentation-sync-workflow-skill` (deploy sync)
    — **Why:** Discoverability and routing hints for the primary agent.
    — **Done when:** Section lists all 4 related skills with one-line descriptions.
    — **Consumers affected:** Primary agent routing.

---

### Phase 2: Documentation Sync (MANDATORY per AGENTS.md)

> **Why this phase is non-negotiable:** AGENTS.md "Adding New Subagents or Skills" mandates lockstep updates across **5 files** when any skill is added:
> 1. `deploy/setup.sh` — banner + status sections, category listing
> 2. `deploy/setup.ps1` — mirror of setup.sh for Windows parity
> 3. `README.md` — Skill Categories table (repo-level discoverability)
> 4. `opencode_app/README.md` — directory structure count (Docker-mode)
> 5. `deploy/.AGENTS.md` — primary routing document for user-space mode (ensures the primary agent discovers the skill)

- [ ] **2.1** Update `deploy/setup.sh`:
    - Line 586: `SKILLS (82)` stays at **82** (Phase 0.3 confirms pre-existing drift means current real count is 81, adding the new skill brings real count to 82 — so this number is now correct, not changed).
    - Line 587: `Framework (13):` → `Framework (14):` and append `openapi-contract-adherence-skill` to the listing (after `api-design-skill` to keep the API pair adjacent).
    - Line 2357: `82 Skills Available` stays at **82**.
    - Line 2360: `Framework (13)` → `Framework (14)` in the category one-liner.
    - **[C-1 — CRITICAL] Line 2226 deploy-status section**: `Framework (11)` → `Framework (14)`. Also append the three missing skills to the listing (`api-design-skill`, `performance-optimization-skill`, `openapi-contract-adherence-skill`). Verify and fix `Language-Specific (4)` → `(6)` in the same status section since both have pre-existing drift (matches PLAN-GIT-218 ISSUE-9 precedent). Reference lines 2226-2237.
    — **Why:** Per AGENTS.md sync rules; preserves Windows/Unix deploy parity. The deploy-status section runs on `--status` invocation and must match the banner section — a self-contradicting file fails the `documentation-consistency-skill` audit.
    — **Done when:** All five locations updated; `Framework (14)` consistent across banner AND status sections; `Language-Specific (6)` matches reality.
    — **Consumers affected:** All `./deploy/setup.sh` users.

- [ ] **2.2** Update `deploy/setup.ps1` (mirror of 2.1):
    - Line 382: `SKILLS (82)` stays at **82**.
    - Line 383: `Framework (13):` → `Framework (14):` and append `openapi-contract-adherence-skill`.
    - **[C-2 — CRITICAL] Line 1727**: `82 Skills Available` stays at **82** (corrected from earlier "line 1725" — line 1725 contains `Write-Host ""`, the actual banner is at 1727).
    - Line 1730: `Framework (13)` → `Framework (14)`.
    - **[C-1 — CRITICAL] Line 1228 deploy-status section**: `Framework (11)` → `Framework (14)`. Also append the three missing skills (`api-design-skill`, `performance-optimization-skill`, `openapi-contract-adherence-skill`). Fix `Language-Specific (4)` → `(6)` to match setup.sh. Reference lines 1228-1233.
    — **Why:** Windows deploy parity. Line number correction prevents the implementer from editing the wrong line.
    — **Done when:** All five locations updated; matches setup.sh exactly including the deploy-status section fix.
    — **Consumers affected:** All `deploy/setup.ps1` users.

- [ ] **2.3** Update `README.md`:
    - Line 280: "82 skills organized across 14 categories" stays at **82 skills, 14 categories**.
    - Line 286: `**Framework** (13)` → `**Framework** (14)` and append `openapi-contract-adherence-skill` to the cell after `api-design-skill`. Update the category purpose text to mention "API design and contract adherence".
    — **Why:** Discoverability for repo consumers.
    — **Done when:** Row updated; category count reads 14; skill listed adjacent to `api-design-skill`.
    — **Consumers affected:** Anyone reading README.

- [ ] **2.4** Update `opencode_app/README.md` — **line 26** says `82 skill directories (single source of truth)` in the directory structure tree. After adding the new skill, real skill directories (excluding `_archived/` and `scripts/`) go from 81 → **82**, so this number is now correct (it was previously inflated by +1 due to pre-existing drift). No count change needed at line 26. **However**, update the parenthetical to `(82 skill directories + scripts/ support + _archived/ legacy)` to clarify what the directory count includes and prevent future drift confusion. Verify no other skill counts or category listings exist elsewhere in this file (confirmed: the Docker README does not enumerate skills by category).
    — **Why:** AGENTS.md lists `opencode_app/README.md` as a sync target. The directory count at line 26 is the only skill-related reference and must be verified correct. Adding the parenthetical clarifies the count methodology for future contributors.
    — **Done when:** Line 26 reads `82 skill directories + scripts/ support + _archived/ legacy` (or similar clarification); no other skill counts remain stale.
    — **Consumers affected:** Docker-mode consumers reading the directory structure.

- [ ] **2.5** Update `deploy/.AGENTS.md` — this file is deployed to `~/.config/opencode/AGENTS.md` and serves as the primary routing document for user-space mode. It currently has NO mention of OpenAPI/contract capabilities. Add a brief routing note so the primary agent discovers the new skill when API contract tasks arise:
    - In the **"Subagent Routing Preferences"** section, append a new row to the routing table OR add a short subsection immediately after the table:
      ```
      | OpenAPI contract review / breaking change detection | Load `openapi-contract-adherence-skill` directly | — | No subagent for this; the primary agent loads the skill when trigger phrases appear ("openapi diff", "api contract", "breaking change", "consumer update plan") |
      ```
    - Keep it minimal — one row or a 2-line note. Do NOT duplicate the skill's content; just provide a routing pointer.
    — **Why:** Without a routing entry, the primary agent may not discover the skill exists when users ask about API contract changes. The `deploy/.AGENTS.md` is the primary agent's behavioral instruction file; adding a routing pointer ensures the skill is loaded at the right time. This mirrors how the Branch Workflow Setup Signal section was added for `git-branch-workflow-setup-skill` (PLAN-GIT-218 Phase 2.1).
    — **Done when:** `deploy/.AGENTS.md` Subagent Routing Preferences section has a routing entry for OpenAPI contract review pointing to the skill, OR a brief subsection documenting when to load the skill.
    — **Consumers affected:** Primary agent in user-space mode (all users running `./deploy/setup.sh`).

- [ ] **2.6** Cross-verify all counts and routing entries across **all 5 sync files**: `deploy/setup.sh` (Framework 14 banner AND Framework 14 status, total 82), `deploy/setup.ps1` (Framework 14 banner AND Framework 14 status, total 82), `README.md` (Framework 14, total 82), `opencode_app/README.md` (line 26 count = 82 with clarification parenthetical), `deploy/.AGENTS.md` (routing entry for OpenAPI contract review present), and actual directories excluding `_archived/` AND `scripts/` (**81 → 82** after Phase 1). All must agree.
    - Verification command: `ls -d opencode_app/.opencode/skills/*/ | grep -vE "_archived|scripts" | wc -l` returns **82**.
    - SKILL.md count check: `find opencode_app/.opencode/skills -name SKILL.md -not -path "*_archived*" | wc -l` also returns **82** (sanity check that scripts/ isn't being counted as a skill).
    - Routing check: `grep -c "openapi-contract-adherence-skill" deploy/.AGENTS.md` returns ≥ 1.
    — **Why:** `documentation-consistency-skill` audits this; drift breaks the audit. The `scripts/` subdirectory is a support dir without SKILL.md and inflates the count by 1; excluding it gives the true skill count. The routing entry in deploy/.AGENTS.md ensures the primary agent discovers the skill.
    — **Done when:** Both count verification commands return 82, all five documentation sources have correct Framework/total counts, AND deploy/.AGENTS.md has at least one reference to `openapi-contract-adherence-skill`.
    — **Consumers affected:** All deploy and documentation consumers.

---

### Phase 3: Optional PR Gate Integration (separable scope)

> **Why optional:** Phase 3 touches another skill (`pr-creation-workflow-skill`). It can ship in this PR for completeness or split into a follow-up issue if the user prefers to keep the PR small. The new skill from Phases 1-2 is fully functional standalone.

- [ ] **3.1** (Optional — confirm with user before executing) Update `pr-creation-workflow-skill/SKILL.md` — add a new subsection "Consuming Contract Diff Reports" under the quality-checks area:
    - Detect `CONTRACT_DIFF.json` in the repo root (or `CONTRACT_REPORT_DIR`).
    - If present, read `summary.semverBump` and select the matching PR label (`major` / `minor` / `patch`).
    - If `summary.breaking > 0`, emit a warning in the PR body and (when `--require-approval` is set) block auto-merge.
    - Include `breakingChanges[].affectedConsumers` in the reviewer-assignment prompt so reviewers see the file list.
    — **Why:** Closes the loop between contract detection and PR enforcement.
    — **Done when:** Subsection present with field-mapping table and a worked example.
    — **Consumers affected:** `pr-workflow-subagent`.

- [ ] **3.2** (Optional) Add a "Contract Gate" trigger phrase to `pr-creation-workflow-skill/SKILL.md` so users can invoke "pr with contract check" to force the integration even when `CONTRACT_DIFF.json` isn't auto-detected.
    — **Why:** Lets users opt into the gate explicitly when the report lives in a non-default location.
    — **Done when:** Trigger phrase listed.
    — **Consumers affected:** End users invoking PR workflow.

---

## Acceptance Criteria

1. `opencode_app/.opencode/skills/openapi-contract-adherence-skill/SKILL.md` exists with valid YAML frontmatter and skill name matches `^[a-z][a-z0-9-]{0,63}$`
1.5. SKILL.md frontmatter parses successfully via a YAML linter (e.g., `npx yaml-lint opencode_app/.opencode/skills/openapi-contract-adherence-skill/SKILL.md` or `python -c "import yaml; yaml.safe_load(open('SKILL.md').read().split('---')[1])"`)
2. SKILL.md contains all 8 steps with working example commands for `oasdiff`, `redocly lint`, and at least 4 SDK generators (2 TS, 1 Python, 1 server-side). **"Working" verified by**: running each command with `--help` or against a minimal sample spec (`tests/fixtures/openapi-minimal.yaml`) to confirm the flag syntax is accepted — no runtime errors.
3. SKILL.md includes both `CONTRACT_DIFF.md` and `CONTRACT_DIFF.json` output templates with the JSON schema specified in Phase 1.10, AND the schema documents the `semverBump` rollup rule (n-2)
4. SKILL.md documents the PR gate integration fields consumed by `pr-creation-workflow-skill` (Phase 1.11)
5. Classification table (Phase 1.8) has at least 16 change types spanning all 4 severity tiers, including status-code, security-scheme, header, and constraint changes (m-1)
6. `deploy/setup.sh` updated: `Framework (14)` in BOTH banner (line 587) AND status (line 2226) sections, total 82, skill listed adjacent to `api-design-skill`; `Language-Specific (6)` in status section (C-1)
7. `deploy/setup.ps1` mirrors setup.sh exactly: `Framework (14)` in BOTH banner (line 383) AND status (line 1228) sections, `82 Skills Available` at line 1727 (C-2), `Language-Specific (6)` in status section
8. `README.md` Skill Categories table updated: Framework (14), total 82, skill listed
9. `opencode_app/README.md` line 26 directory count clarified (82 + scripts/ + _archived/ parenthetical)
10. `deploy/.AGENTS.md` has a routing entry for OpenAPI contract review pointing to `openapi-contract-adherence-skill`
11. All counts and routing entries synchronized across **all 5 sync files** — no drift between deploy scripts (banner + status), README, opencode_app/README, and deploy/.AGENTS.md; both verification commands from Phase 2.6 return 82; `grep -c "openapi-contract-adherence-skill" deploy/.AGENTS.md` ≥ 1
12. (If Phase 3 executed) `pr-creation-workflow-skill/SKILL.md` has the "Consuming Contract Diff Reports" subsection
13. (Monorepo, m-4) Step 1 documents multi-spec glob discovery and per-service output naming
14. (Resilience, m-3 + M-2) `.oasdiff-*` is added to `.gitignore`; intermediate artifacts are not committed

---

## Related Files

| File | Action | Phase |
|------|--------|-------|
| `opencode_app/.opencode/skills/openapi-contract-adherence-skill/SKILL.md` | Create | 1 |
| `deploy/setup.sh` | Update (Framework 13→14 banner + status, skill listing, Language-Specific fix) | 2 |
| `deploy/setup.ps1` | Update (Framework 13→14 banner + status, skill listing, Language-Specific fix) | 2 |
| `README.md` | Update (Skill Categories table: Framework 14, purpose text) | 2 |
| `opencode_app/README.md` | Update (line 26 directory count clarification) | 2 |
| `deploy/.AGENTS.md` | Update (routing entry for OpenAPI contract review) | 2 |
| `pr-creation-workflow-skill/SKILL.md` | Optional update (PR gate consumer section) | 3 |

---

## References

- **Authoring counterpart:** `api-design-skill/SKILL.md` — REST conventions, OpenAPI generation, GraphQL schemas, versioning, pagination, error formats
- **PR workflow target:** `pr-creation-workflow-skill/SKILL.md` — framework-aware quality checks, semver labels, JIRA integration
- **Skill creation standard:** `opencode-skill-creation-skill/SKILL.md` — naming rules, frontmatter requirements
- **Sync rules:** repo `AGENTS.md` → "Adding New Subagents or Skills" → mandatory sync triggers
- **Tooling docs:**
  - [oasdiff](https://github.com/oasdiff/oasdiff) — breaking change detection (repo moved from `tufin/oasdiff` in 2024)
  - [redocly CLI](https://redocly.com/docs/cli/) — spec linting
  - [openapi-generator](https://openapi-generator.tech/) — multi-language SDK generation
  - [@hey-api/openapi-ts](https://heyapi.vercel.app/) — TypeScript-first generation with react-query
  - [Pact](https://pact.io/) — consumer-driven contract testing
- **Industry references:**
  - [APIs, AI, and the Future of API Ops](https://nordicapis.com/apis-ai-and-the-future-of-api-ops/) — full lifecycle automation
  - [The Pain of Breaking Changes in APIs](https://apievangelist.com/2024/01/15/the-pain-of-breaking-changes-in-apis/) — taxonomy of breaking changes

---

## Risks & Mitigation

| Risk | Mitigation |
|------|------------|
| Skill duplicates content from `api-design-skill` | Phase 1.14 cross-references the authoring skill; `openapi-contract-adherence-skill` focuses exclusively on evolution/diff/consumer impact — no overlap with authoring concerns |
| `oasdiff` not installed in user environment | Phase 1.4 documents three install paths (go install, brew, docker pull); Docker form works without local install |
| oasdiff version drift between local binary and Docker image (M-1) | Phase 1.4 recommends version pinning (`@vX.Y.Z` / `tufin/oasdiff:vX.Y.Z`) so output schemas stay consistent across the two invocation forms |
| Count drift across deploy scripts and README | Phase 2.5 cross-verifies all four sources at 82/14 in BOTH banner and status sections; Phase 0.3 captures pre-existing drift so it gets fixed in the same pass; deploy-status section drift (C-1) is now explicitly targeted |
| Classification table incomplete (m-1) | Phase 1.8 mandates 16+ change types covering all 4 severities AND status-code/security/header/constraint changes from the oasdiff check catalog |
| `CONTRACT_DIFF.json` schema unstable, breaking PR gate | Phase 1.10 fixes the schema explicitly with types; Phase 1.11 documents consumed fields as a contract; future changes must be additive (new fields allowed, no field removals) |
| Intermediate oasdiff artifacts get committed to repo (M-2) | Phase 1.7 introduces `.oasdiff-*` naming convention with leading dot; Phase 2 / AC #12 add `.oasdiff-*` to `.gitignore` |
| `nonBreaking`/`cosmetic` counts cannot be derived from breaking-only diff (M-3) | Phase 1.7 adds a third command `oasdiff changelog --format json` to provide machine-countable totals |
| Phase 3 scope creep inflates PR size | Phase 3 explicitly marked optional; can be deferred to a follow-up issue if the user prefers a focused PR |
| New skill does not get auto-loaded when expected | `trigger: explicit-only` is intentional; Phase 1.3 lists 6+ trigger phrases for high recall; no auto-loading required |
| Pre-existing drift (declared 82, actual 81) gets masked | Phase 0.3 documents the drift explicitly AND the `scripts/` inflation; Phase 2.1-2.3 leave the declared total at 82 (now correct after the new skill brings the real count to 82) |
| Monorepo with multiple OpenAPI specs only processes one (m-4) | Phase 1.5 documents glob discovery `**/openapi.{yaml,yml,json}` and per-service output naming (`CONTRACT_DIFF.<service>.{md,json}`) |
| Generated client regeneration overwrites hand-edited wrappers | Phase 1.9 sub-op #3 and Phase 1.12 both recommend `.openapi-generator-ignore` / `.swagger-codegen-ignore` patterns |
| Consumer with no SDK generator and no direct call sites (zero-result fallback) | Phase 1.9 documents a zero-result fallback that recommends manual review of common wrapper directories |
| `@hey-api/openapi-ts` flag drift (m-2) | Phase 1.12 uses the current config-file + plugins model as the canonical form; legacy `-c` shorthand is explicitly noted as potentially broken on latest versions |

---

## Dependency Version Audit (Pre-Implementation)

Verified against package registries on 2026-06-21. All findings below are addressed in the relevant phases.

| Dependency | Latest Version | PLAN Fix |
|-----------|----------------|----------|
| `oasdiff` (binary/brew) | `v1.19.1` (2026-06-14) | Phase 1.4 — corrected pinning example from `@v1.1.16` → `@v1.19.1` (transposed digits) |
| `oasdiff` (Docker) | `:stable` / `:v1.19.1` (2026-06-14); `:latest` tracks unreleased main | Phase 1.4 — recommend `tufin/oasdiff:stable` over bare `:latest` |
| `@redocly/cli` | `2.34.0` (Node ≥22.12.0) | Phase 1.4 — version noted, Node requirement added |
| `@stoplight/spectral-cli` | `6.16.0` | Phase 1.4 — version noted |
| `@hey-api/openapi-ts` | `0.98.2` (Node ≥22.18.0) | Phase 1.12 — config filename corrected `hey-api.config.ts` → `openapi-ts.config.ts`; plugins format documented as string-or-object array per official docs |
| `orval` | `8.18.0` (Node ≥22.18.0) | Phase 1.4 — version noted, Node requirement added |
| `@openapitools/openapi-generator-cli` | `2.39.0` (Node ≥22.0.0) | Phase 1.4 — version noted, Node requirement added |
| `fastapi-code-generator` | `0.7.0` (PyPI) | Phase 1.12 — corrected package name `fastapi-codegen` → `fastapi-code-generator` (PyPI 404 on the short name); CLI binary is still `fastapi-codegen` |

---

## Architecture Review Issues Addressed

| Issue | Severity | Phase | Resolution |
|-------|----------|-------|------------|
| C-1: Deploy-status section `Framework (11)` drift missed | Critical | 0.3, 2.1, 2.2 | Added explicit subtask for `deploy/setup.sh:2226` and `deploy/setup.ps1:1228`; also fixes `Language-Specific (4)` → `(6)` |
| C-2: Wrong line number in setup.ps1 | Critical | 2.2 | Corrected line 1725 → 1727 (line 1725 contains blank `Write-Host ""`) |
| M-1: Outdated oasdiff Go install path | Major | 1.4, References | Changed `github.com/tufin/oasdiff` → `github.com/oasdiff/oasdiff`; added version-pinning recommendation |
| M-2: Artifact filename inconsistency | Major | 1.7 | Renamed intermediate artifacts to `.oasdiff-*` with leading dot; documented intermediate-vs-final mapping |
| M-3: JSON schema nonBreaking/cosmetic unpopulatable | Major | 1.7 | Added third command `oasdiff changelog --format json` to provide machine-countable totals |
| m-1: Classification table incomplete | Minor | 1.8 | Expanded from 10 to 16+ rows; added status-code, security-scheme, header, parameter-format, constraint changes |
| m-2: `@hey-api/openapi-ts -c` flag outdated | Minor | 1.12 | Replaced with current config-file + plugins model as canonical form |
| m-3: `scripts/` directory inflates count | Minor | 0.3, 2.5 | Updated verification command to exclude `scripts/` via `grep -vE "_archived|scripts"`; added SKILL.md count sanity check |
| m-4: No monorepo multi-spec handling | Minor | 1.5 | Added glob discovery `**/openapi.{yaml,yml,json}` and per-service output naming |
| m-5: AC #2 lacks verification path | Minor | Acceptance Criteria | Added AC #1.5 (YAML lint) and verification note in AC #2 (`--help` or sample spec check) |
| n-1: Reference URL/title mismatch | Nit | References | Fixed Nordic APIs title to match URL slug |
| n-2: semverBump rollup rule unstated | Nit | 1.8, 1.10 | Added explicit rollup rule: `major` if any breaking; else `minor` if any additive; else `patch` if any cosmetic; else `none` |
| n-3: Phase 1.9 regex too abstract | Nit | 1.9 | Replaced with concrete TS and Python regex examples including brace-escape for path params |
| D-1: oasdiff pinning example had transposed digits (`v1.1.16` → `v1.19.1`) | Critical | 1.4 | Corrected to `v1.19.1`; added explicit latest-stable reference |
| D-2: `@hey-api/openapi-ts` config filename and plugins format wrong | Critical | 1.12 | Filename → `openapi-ts.config.ts`; plugins format → string or object array per heyapi.dev/docs |
| D-3: `fastapi-codegen` does not exist on PyPI | Critical | 1.12 | Corrected package name to `fastapi-code-generator` (CLI binary stays `fastapi-codegen`); added install clarification |
| D-4: Docker `:latest` tag tracks unreleased commits | Major | 1.4 | Recommend `tufin/oasdiff:stable` or pinned version tags; documented the `:latest` risk |
| D-5: Node ≥22.x requirements undocumented | Minor | 1.4 | Added Node version requirements per tool in Prerequisites |

---

## Out of Scope

- Auto-running the skill on every commit (would require hook integration; deferred)
- Generating client SDKs in languages beyond TS/Python (referenced via `openapi-generator-cli` docs only)
- Consumer-driven contract testing with Pact (mentioned in references but not implemented as a step)
- Migrating the skill to `trigger: automatic` (would change behavior; out of scope for this PR)
- Updating `opencode_app/opencode.json` MCP server config (no new MCP server introduced)

---

*Tracking progress with `plan-updater-skill`. Branch: `issue-221`.*
