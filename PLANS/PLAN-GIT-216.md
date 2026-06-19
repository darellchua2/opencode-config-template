# PLAN: Build out version-bump-standard-skill with workflow templates and onboarding scripts

**Issue**: [#216 — feat: build out version-bump-standard-skill with workflow templates and onboarding scripts](https://github.com/darellchua2/opencode-config-template/issues/216)
**Branch**: `GIT-216`
**Status**: In Progress

---

## Summary

The `version-bump-standard-skill` currently contains only a `SKILL.md` documentation file describing the CanvasTekk release standard (dev → uat → main branch flow with PR-label-driven semantic versioning). This plan builds out the skill with reusable supporting assets so it is **actionable and deployable**, not just informational:

1. **Governance alignment** — fix label-color inconsistency (patch/minor use wrong hex vs `semantic-release-convention-skill`); establish version-bump-standard as a governed consumer, not a redefining source of truth; add bidirectional cross-references.
2. **3 workflow YAML templates** — extracted from SKILL.md (with corrected label colors) into standalone, reusable files under `templates/`.
3. **4 helper scripts** — onboarding runner, audit runner, branch-protection setup, and label creation, all POSIX-bash with `set -euo pipefail`, `--help`, `chmod +x`, and `<org>/<repo>` argument handling.
4. **SKILL.md update** — reference the new `templates/` and `scripts/` directories with usage examples; add Governance section citing `semantic-release-convention-skill`.
5. **Deploy & subagent sync** — `deploy/setup.sh`, `deploy/setup.ps1`, `README.md`, `opencode_app/README.md` (if applicable), and `pr-workflow-subagent.md` (skill permission) updated per AGENTS.md conventions.
6. **Validation** — `bash -n` syntax checks, YAML validation, executable-bit checks, and GitHub Action version verification gate the work.

### Source-of-truth references (in existing SKILL.md)

| Asset | SKILL.md source lines | Target file |
|-------|----------------------|-------------|
| `bump-version-and-push-tag.yml` | 81-160 | `templates/bump-version-and-push-tag.yml` |
| `enforce-dev-to-uat.yml` | 164-185 | `templates/enforce-dev-to-uat.yml` |
| `enforce-uat-to-main.yml` | 189-210 | `templates/enforce-uat-to-main.yml` |
| Branch protection JSON | 219-253 | wrapped in `scripts/setup-branch-protection.sh` |
| Label creation commands | 260-263 | wrapped in `scripts/create-labels.sh` (with corrected colors — see Phase 1.5) |
| Onboarding checklist | 266-277 | logic for `scripts/onboard-repo.sh` |
| Audit checklist | 279-290 | logic for `scripts/audit-repo.sh` |

### Label color correction (Phase 1.5)

SKILL.md lines 260-263 use colors inconsistent with the governance standard (`semantic-release-convention-skill`). Correct **before** extraction:

| Label | SKILL.md (WRONG) | Governance standard (CORRECT) |
|-------|------------------|-------------------------------|
| `patch` | `#0075ca` (blue) | `#0e8a16` (green) |
| `minor` | `#a2eeef` (light-blue) | `#fbca04` (yellow) |
| `major` | `#d73a4a` (red) | `#d73a4a` (red) — already correct |

Correct color source: `git-issue-labeler-skill` (auto-create LABELS array), confirmed against `semantic-release-convention-skill`.

### Reference patterns (multi-file skills)

- `pdf-specialist-skill` — SKILL.md + `scripts/`
- `docx-creation-skill` — SKILL.md + `scripts/`

---

## Files Affected

| # | File | Action | Phase |
|---|------|--------|-------|
| 1 | `opencode_app/.opencode/skills/version-bump-standard-skill/templates/bump-version-and-push-tag.yml` | new | 2 |
| 2 | `opencode_app/.opencode/skills/version-bump-standard-skill/templates/enforce-dev-to-uat.yml` | new | 2 |
| 3 | `opencode_app/.opencode/skills/version-bump-standard-skill/templates/enforce-uat-to-main.yml` | new | 2 |
| 4 | `opencode_app/.opencode/skills/version-bump-standard-skill/scripts/onboard-repo.sh` | new | 3 |
| 5 | `opencode_app/.opencode/skills/version-bump-standard-skill/scripts/audit-repo.sh` | new | 3 |
| 6 | `opencode_app/.opencode/skills/version-bump-standard-skill/scripts/setup-branch-protection.sh` | new | 3 |
| 7 | `opencode_app/.opencode/skills/version-bump-standard-skill/scripts/create-labels.sh` | new | 3 |
| 8 | `opencode_app/.opencode/skills/version-bump-standard-skill/SKILL.md` | update (label colors + asset refs + governance section) | 1.5, 4 |
| 9 | `opencode_app/.opencode/skills/semantic-release-convention-skill/SKILL.md` | update (Governed Skills table + cross-ref) | 4 |
| 10 | `opencode_app/.opencode/agents/pr-workflow-subagent.md` | update (add `version-bump-standard-skill: allow` to skill permissions) | 4 |
| 11 | `deploy/setup.sh` | update (skill listing + count) | 4 |
| 12 | `deploy/setup.ps1` | update (skill listing + count) | 4 |
| 13 | `README.md` | update (Skill Categories table) | 4 |
| 14 | `opencode_app/README.md` | update (if Docker README lists skills) | 4 |

---

## Dependency & Execution Order

Execution flows top-to-bottom (Phase 1 → 5).

- **Phase 1** (analysis) must precede Phase 1.5, 2 & 3 — source-line extraction depends on reading SKILL.md and reference patterns.
- **Phase 1.5** (governance alignment) must precede Phase 3.4 — label colors must be corrected before extraction into `create-labels.sh`.
- **Phase 2** (templates) and **Phase 3** (scripts) are independent of each other and may be interleaved.
- **Phase 4** (docs/deploy sync) must follow Phase 2 & 3 — SKILL.md references the new directories, and deploy counts assume the skill is complete.
- **Phase 5** (validation) gates completion — syntax + YAML checks + executable bits + count consistency + action version verification.

---

## Phase 1: Setup & Analysis

- [x] **1.1** Read existing `version-bump-standard-skill/SKILL.md` and extract the 3 workflow YAML blocks (lines 81-210), branch protection JSON (219-253), and label commands (260-263)
    — **Why:** Verbatim extraction is the source of truth for templates and script payloads; must be captured before authoring new files.
    — **Done when:** All 7 source blocks are captured into working notes / staging.
- [x] **1.2** Review the multi-file skill pattern from `pdf-specialist-skill` (SKILL.md + scripts/) and `docx-creation-skill` (SKILL.md + scripts/)
    — **Why:** Ensures new scripts match repo conventions for structure, shebangs, and `--help` handling.
    — **Done when:** Conventions documented (shebang, `set -euo pipefail`, usage function, arg parsing).
- [x] **1.3** Review AGENTS.md "Adding New Subagents or Skills" sync requirements and current counts in `deploy/setup.sh`, `deploy/setup.ps1`, `README.md`
    — **Why:** Phase 4 deploy sync must produce consistent counts; baseline must be known before incrementing.
    — **Done when:** Current skill count recorded for each of the 3 deploy/doc files.
- [x] **1.4** Create directory structure: `version-bump-standard-skill/templates/` and `version-bump-standard-skill/scripts/`
    — **Why:** Container directories for Phase 2 and Phase 3 outputs.
    — **Done when:** Both directories exist.

---

## Phase 1.5: Governance Alignment

- [x] **1.5.1** Fix label colors in SKILL.md (lines 260-263): `patch` `#0075ca` → `#0e8a16`, `minor` `#a2eeef` → `#fbca04` (matching `semantic-release-convention-skill` and `git-issue-labeler-skill`)
    — **Why:** Current colors use GitHub-default blue/light-blue; governance standard requires green/yellow. Extracting verbatim would propagate the bug into `create-labels.sh`.
    — **Done when:** SKILL.md label commands use `#0e8a16`/`#fbca04`/`#d73a4a`.
- [x] **1.5.2** Read `semantic-release-convention-skill/SKILL.md` to confirm version-bump-standard implements (not redefines) the conventions
    — **Why:** `semantic-release-convention` declares itself "single source of truth...consumed by 5 skills and 2 agents." version-bump-standard must be a governed consumer.
    — **Done when:** Confirmed no conflicting definitions; noted areas where version-bump-standard adds operational specifics (workflow templates, scripts) beyond the convention layer.
- [x] **1.5.3** Add version-bump-standard-skill to `semantic-release-convention-skill/SKILL.md` Governed Skills table
    — **Why:** Establishes the governance relationship; prevents future duplicate-source-of-truth drift.
    — **Done when:** Row added to the Governed Skills table in semantic-release-convention.

---

## Phase 2: Workflow Templates

- [x] **2.1** Create `templates/bump-version-and-push-tag.yml` — extract verbatim from SKILL.md lines 81-160
    — **Why:** Standalone reusable version-bump + tag-push workflow consumers can copy into `.github/workflows/`.
    — **Done when:** File exists and `python3 -c "import yaml; yaml.safe_load(...)"` validates.
- [x] **2.2** Create `templates/enforce-dev-to-uat.yml` — extract verbatim from SKILL.md lines 164-185
    — **Why:** Enforces dev → uat PR flow as a copy-paste template.
    — **Done when:** File exists and YAML validates.
- [x] **2.3** Create `templates/enforce-uat-to-main.yml` — extract verbatim from SKILL.md lines 189-210
    — **Why:** Enforces uat → main PR flow as a copy-paste template.
    — **Done when:** File exists and YAML validates.

---

## Phase 3: Onboarding & Audit Scripts

- [x] **3.1** Create `scripts/onboard-repo.sh` — implements onboarding checklist (SKILL.md lines 266-277); accepts `<org>/<repo>` arg; `set -euo pipefail`; `--help`; idempotent
    — **Why:** Interactive/scripted runner that executes the onboarding checklist end-to-end.
    — **Done when:** `bash -n` passes; `--help` prints usage; accepts and validates `<org>/<repo>`.
- [x] **3.2** Create `scripts/audit-repo.sh` — implements audit checklist (SKILL.md lines 279-290); non-destructive; prints pass/fail report
    — **Why:** Read-only audit consumers can run against any repo to check standard compliance.
    — **Done when:** `bash -n` passes; prints per-check pass/fail; exits non-zero on any failure.
- [x] **3.3** Create `scripts/setup-branch-protection.sh` — wraps `gh api` calls for uat + main (SKILL.md lines 219-253) using `gh api ... --method PUT --input -`
    — **Why:** Automates branch protection rule creation for both gated branches.
    — **Done when:** `bash -n` passes; applies protection to uat and main via `gh api`.
- [x] **3.4** Create `scripts/create-labels.sh` — wraps `gh label create` for `patch`/`minor`/`major` with **corrected governance colors** (`#0e8a16`/`#fbca04`/`#d73a4a`); idempotent (skip if label exists)
    — **Why:** Ensures the 3 semantic-versioning labels exist for the PR-label-driven flow with governance-standard colors.
    — **Done when:** `bash -n` passes; creates labels idempotently with correct colors.

> **Convention for all 4 scripts:** POSIX-compatible bash; `set -euo pipefail`; `usage()` function; `--help` flag; first positional arg is `<org>/<repo>`; idempotent (safe to re-run); **`chmod +x`** (executable bit required for `./script.sh` invocation after deploy).

---

## Phase 4: Documentation & Deploy Sync

- [x] **4.1** Update `version-bump-standard-skill/SKILL.md` to reference `templates/` and `scripts/` directories with usage examples (how to copy templates; how to run each script); add a **Governance** section citing `semantic-release-convention-skill` as the convention authority
    — **Why:** Makes the skill actionable rather than purely informational; establishes governance relationship.
    — **Done when:** SKILL.md has a section documenting `templates/` and `scripts/` with examples + a Governance cross-reference.
- [x] **4.2** Update `deploy/setup.sh`: add version-bump-standard-skill to skill listing and increment total skill count
    — **Why:** User-space deploy must include the new skill; count must stay accurate per AGENTS.md sync checklist.
    — **Done when:** Skill appears in listing; count incremented by 1.
- [x] **4.3** Update `deploy/setup.ps1`: add version-bump-standard-skill to skill listing and increment total skill count
    — **Why:** Windows deploy parity with setup.sh.
    — **Done when:** Skill appears in listing; count incremented by 1.
- [x] **4.4** Update `README.md`: add version-bump-standard-skill to Skill Categories table
    — **Why:** Discoverability for repo consumers.
    — **Done when:** Row added to Skill Categories table.
- [x] **4.5** Add `version-bump-standard-skill: allow` to `opencode_app/.opencode/agents/pr-workflow-subagent.md` skill permissions
    — **Why:** Without this, the pr-workflow subagent (primary consumer for release-setup tasks) cannot invoke the deployed skill.
    — **Done when:** Permission entry added to frontmatter.
- [x] **4.6** Check if `opencode_app/README.md` (Docker README) lists skills; if so, add version-bump-standard-skill
    — **Why:** AGENTS.md line 181 lists `opencode_app/README.md` as a sync target "if relevant."
    — **Done when:** Verified and updated (or confirmed not applicable).
- [x] **4.7** Verify `scripts/` files have executable bit (`chmod +x`)
    — **Why:** Scripts without the executable bit won't run via `./script.sh` after deploy.
    — **Done when:** All 4 scripts are executable (`ls -la` shows `-rwx`).

---

## Phase 5: Validation

- [x] **5.1** Run `bash -n` syntax check on all 4 new scripts (onboard-repo.sh, audit-repo.sh, setup-branch-protection.sh, create-labels.sh) — must pass
    — **Why:** Catches syntax errors before consumers run the scripts.
    — **Done when:** All 4 pass with no output.
- [x] **5.2** Validate all 3 YAML templates with `python3 -c "import yaml; yaml.safe_load(...)"`
    — **Why:** Ensures templates are parseable before they're copied into workflows.
    — **Done when:** All 3 parse without error.
- [x] **5.3** Verify `deploy/setup.sh` and `deploy/setup.ps1` skill counts are consistent with each other and with README.md
    — **Why:** Count drift breaks the documentation-consistency-skill audit.
    — **Done when:** All three counts match.
- [x] **5.4** Verify README.md Skill Categories table includes version-bump-standard-skill
    — **Why:** Confirms 4.4 took effect.
    — **Done when:** Row present and correctly categorized.
- [x] **5.5** Verify GitHub Action versions pinned in templates are current and exist: `actions/checkout@v6`, `mathieudutour/github-tag-action@v6.2`, `ncipollo/release-action@v1.21.0`, `actions/github-script@v7`
    — **Why:** Stale or non-existent action versions break the release workflow when consumers copy templates.
    — **Done when:** All 4 actions confirmed to exist at pinned versions; add maintenance comment in each template noting "update action versions periodically."
- [x] **5.6** Verify all 4 scripts have executable bit set (`test -x`)
    — **Why:** Confirms 4.7; scripts must be runnable via `./script.sh`.
    — **Done when:** `test -x` passes for all 4 scripts.

---

## Risks & Mitigation

| Risk | Mitigation |
|------|------------|
| YAML extraction introduces subtle whitespace/format drift | Extract verbatim; validate with `yaml.safe_load` in Phase 5 |
| **Label color mismatch propagated** (`patch`/`minor` use wrong hex) | **Phase 1.5.1 corrects SKILL.md before Phase 3.4 extraction; use `#0e8a16`/`#fbca04`/`#d73a4a`** |
| **Undocumented overlap with `semantic-release-convention-skill`** | **Phase 1.5 establishes governance; Phase 4.1 adds bidirectional cross-reference** |
| Script incompatibility with non-bash shells | Restrict to `#!/usr/bin/env bash`; POSIX-compatible constructs only |
| **Scripts lack executable bit after deploy** | **Phase 4.7 runs `chmod +x`; Phase 5.6 verifies with `test -x`** |
| Deploy count drift across setup.sh / setup.ps1 / README.md | Phase 5.3 cross-checks all three counts |
| Branch protection `gh api` payload differs from SKILL.md doc | Use exact JSON from SKILL.md lines 219-253; test against a throwaway repo if uncertain |
| `gh label create` fails on pre-existing label | Make `create-labels.sh` idempotent — check existence before create |
| **Stale GitHub Action versions in templates** | **Phase 5.5 verifies `checkout@v6`, `github-tag-action@v6.2`, `release-action@v1.21.0`, `github-script@v7` exist and are current** |
| **`pr-workflow-subagent` cannot invoke deployed skill** | **Phase 4.5 adds `version-bump-standard-skill: allow` to subagent permissions** |

---

*Tracking progress with ticket-plan-workflow-skill*
