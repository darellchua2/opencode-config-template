# PLAN: Build out version-bump-standard-skill with workflow templates and onboarding scripts

**Issue**: [#216 — feat: build out version-bump-standard-skill with workflow templates and onboarding scripts](https://github.com/darellchua2/opencode-config-template/issues/216)
**Branch**: `GIT-216`
**Status**: In Progress

---

## Summary

The `version-bump-standard-skill` currently contains only a `SKILL.md` documentation file describing the CanvasTekk release standard (dev → uat → main branch flow with PR-label-driven semantic versioning). This plan builds out the skill with reusable supporting assets so it is **actionable and deployable**, not just informational:

1. **3 workflow YAML templates** — extracted verbatim from SKILL.md into standalone, reusable files under `templates/`.
2. **4 helper scripts** — onboarding runner, audit runner, branch-protection setup, and label creation, all POSIX-bash with `set -euo pipefail`, `--help`, and `<org>/<repo>` argument handling.
3. **SKILL.md update** — reference the new `templates/` and `scripts/` directories with usage examples.
4. **Deploy sync** — `deploy/setup.sh`, `deploy/setup.ps1`, and `README.md` updated with the new skill listing/count per AGENTS.md conventions.
5. **Validation** — `bash -n` syntax checks and YAML validation gate the work.

### Source-of-truth references (in existing SKILL.md)

| Asset | SKILL.md source lines | Target file |
|-------|----------------------|-------------|
| `bump-version-and-push-tag.yml` | 81-160 | `templates/bump-version-and-push-tag.yml` |
| `enforce-dev-to-uat.yml` | 164-185 | `templates/enforce-dev-to-uat.yml` |
| `enforce-uat-to-main.yml` | 189-210 | `templates/enforce-uat-to-main.yml` |
| Branch protection JSON | 219-253 | wrapped in `scripts/setup-branch-protection.sh` |
| Label creation commands | 260-263 | wrapped in `scripts/create-labels.sh` |
| Onboarding checklist | 266-277 | logic for `scripts/onboard-repo.sh` |
| Audit checklist | 279-290 | logic for `scripts/audit-repo.sh` |

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
| 8 | `opencode_app/.opencode/skills/version-bump-standard-skill/SKILL.md` | update | 4 |
| 9 | `deploy/setup.sh` | update (skill listing + count) | 4 |
| 10 | `deploy/setup.ps1` | update (skill listing + count) | 4 |
| 11 | `README.md` | update (Skill Categories table) | 4 |

---

## Dependency & Execution Order

Execution flows top-to-bottom (Phase 1 → 5).

- **Phase 1** (analysis) must precede Phase 2 & 3 — source-line extraction depends on reading SKILL.md and reference patterns.
- **Phase 2** (templates) and **Phase 3** (scripts) are independent of each other and may be interleaved.
- **Phase 4** (docs/deploy sync) must follow Phase 2 & 3 — SKILL.md references the new directories, and deploy counts assume the skill is complete.
- **Phase 5** (validation) gates completion — syntax + YAML checks + count consistency.

---

## Phase 1: Setup & Analysis

- [ ] **1.1** Read existing `version-bump-standard-skill/SKILL.md` and extract the 3 workflow YAML blocks (lines 81-210), branch protection JSON (219-253), and label commands (260-263)
    — **Why:** Verbatim extraction is the source of truth for templates and script payloads; must be captured before authoring new files.
    — **Done when:** All 7 source blocks are captured into working notes / staging.
- [ ] **1.2** Review the multi-file skill pattern from `pdf-specialist-skill` (SKILL.md + scripts/) and `docx-creation-skill` (SKILL.md + scripts/)
    — **Why:** Ensures new scripts match repo conventions for structure, shebangs, and `--help` handling.
    — **Done when:** Conventions documented (shebang, `set -euo pipefail`, usage function, arg parsing).
- [ ] **1.3** Review AGENTS.md "Adding New Subagents or Skills" sync requirements and current counts in `deploy/setup.sh`, `deploy/setup.ps1`, `README.md`
    — **Why:** Phase 4 deploy sync must produce consistent counts; baseline must be known before incrementing.
    — **Done when:** Current skill count recorded for each of the 3 deploy/doc files.
- [ ] **1.4** Create directory structure: `version-bump-standard-skill/templates/` and `version-bump-standard-skill/scripts/`
    — **Why:** Container directories for Phase 2 and Phase 3 outputs.
    — **Done when:** Both directories exist.

---

## Phase 2: Workflow Templates

- [ ] **2.1** Create `templates/bump-version-and-push-tag.yml` — extract verbatim from SKILL.md lines 81-160
    — **Why:** Standalone reusable version-bump + tag-push workflow consumers can copy into `.github/workflows/`.
    — **Done when:** File exists and `python3 -c "import yaml; yaml.safe_load(...)"` validates.
- [ ] **2.2** Create `templates/enforce-dev-to-uat.yml` — extract verbatim from SKILL.md lines 164-185
    — **Why:** Enforces dev → uat PR flow as a copy-paste template.
    — **Done when:** File exists and YAML validates.
- [ ] **2.3** Create `templates/enforce-uat-to-main.yml` — extract verbatim from SKILL.md lines 189-210
    — **Why:** Enforces uat → main PR flow as a copy-paste template.
    — **Done when:** File exists and YAML validates.

---

## Phase 3: Onboarding & Audit Scripts

- [ ] **3.1** Create `scripts/onboard-repo.sh` — implements onboarding checklist (SKILL.md lines 266-277); accepts `<org>/<repo>` arg; `set -euo pipefail`; `--help`; idempotent
    — **Why:** Interactive/scripted runner that executes the onboarding checklist end-to-end.
    — **Done when:** `bash -n` passes; `--help` prints usage; accepts and validates `<org>/<repo>`.
- [ ] **3.2** Create `scripts/audit-repo.sh` — implements audit checklist (SKILL.md lines 279-290); non-destructive; prints pass/fail report
    — **Why:** Read-only audit consumers can run against any repo to check standard compliance.
    — **Done when:** `bash -n` passes; prints per-check pass/fail; exits non-zero on any failure.
- [ ] **3.3** Create `scripts/setup-branch-protection.sh` — wraps `gh api` calls for uat + main (SKILL.md lines 219-253) using `gh api ... --method PUT --input -`
    — **Why:** Automates branch protection rule creation for both gated branches.
    — **Done when:** `bash -n` passes; applies protection to uat and main via `gh api`.
- [ ] **3.4** Create `scripts/create-labels.sh` — wraps `gh label create` for `patch`/`minor`/`major` (SKILL.md lines 260-263); idempotent (skip if label exists)
    — **Why:** Ensures the 3 semantic-versioning labels exist for the PR-label-driven flow.
    — **Done when:** `bash -n` passes; creates labels idempotently.

> **Convention for all 4 scripts:** POSIX-compatible bash; `set -euo pipefail`; `usage()` function; `--help` flag; first positional arg is `<org>/<repo>`; idempotent (safe to re-run).

---

## Phase 4: Documentation & Deploy Sync

- [ ] **4.1** Update `version-bump-standard-skill/SKILL.md` to reference `templates/` and `scripts/` directories with usage examples (how to copy templates; how to run each script)
    — **Why:** Makes the skill actionable rather than purely informational; consumers learn the asset layout.
    — **Done when:** SKILL.md has a section documenting `templates/` and `scripts/` with examples.
- [ ] **4.2** Update `deploy/setup.sh`: add version-bump-standard-skill to skill listing and increment total skill count
    — **Why:** User-space deploy must include the new skill; count must stay accurate per AGENTS.md sync checklist.
    — **Done when:** Skill appears in listing; count incremented by 1.
- [ ] **4.3** Update `deploy/setup.ps1`: add version-bump-standard-skill to skill listing and increment total skill count
    — **Why:** Windows deploy parity with setup.sh.
    — **Done when:** Skill appears in listing; count incremented by 1.
- [ ] **4.4** Update `README.md`: add version-bump-standard-skill to Skill Categories table
    — **Why:** Discoverability for repo consumers.
    — **Done when:** Row added to Skill Categories table.

---

## Phase 5: Validation

- [ ] **5.1** Run `bash -n` syntax check on all 4 new scripts (onboard-repo.sh, audit-repo.sh, setup-branch-protection.sh, create-labels.sh) — must pass
    — **Why:** Catches syntax errors before consumers run the scripts.
    — **Done when:** All 4 pass with no output.
- [ ] **5.2** Validate all 3 YAML templates with `python3 -c "import yaml; yaml.safe_load(...)"`
    — **Why:** Ensures templates are parseable before they're copied into workflows.
    — **Done when:** All 3 parse without error.
- [ ] **5.3** Verify `deploy/setup.sh` and `deploy/setup.ps1` skill counts are consistent with each other and with README.md
    — **Why:** Count drift breaks the documentation-consistency-skill audit.
    — **Done when:** All three counts match.
- [ ] **5.4** Verify README.md Skill Categories table includes version-bump-standard-skill
    — **Why:** Confirms 4.4 took effect.
    — **Done when:** Row present and correctly categorized.

---

## Risks & Mitigation

| Risk | Mitigation |
|------|------------|
| YAML extraction introduces subtle whitespace/format drift | Extract verbatim; validate with `yaml.safe_load` in Phase 5 |
| Script incompatibility with non-bash shells | Restrict to `#!/usr/bin/env bash`; POSIX-compatible constructs only |
| Deploy count drift across setup.sh / setup.ps1 / README.md | Phase 5.3 cross-checks all three counts |
| Branch protection `gh api` payload differs from SKILL.md doc | Use exact JSON from SKILL.md lines 219-253; test against a throwaway repo if uncertain |
| `gh label create` fails on pre-existing label | Make `create-labels.sh` idempotent — check existence before create |

---

*Tracking progress with ticket-plan-workflow-skill*
