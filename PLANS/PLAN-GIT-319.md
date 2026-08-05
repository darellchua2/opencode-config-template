# PLAN — Enforce OpenAPI Authoring Quality via api-design-skill (Authoring) + reactive split

**Issue:** https://github.com/darellchua2/opencode-config-template/issues/319
**Branch:** `GIT-319`
**Review:** architecture-review + opencode-tooling (both flagged the original single-bullet-on-`openapi-contract-adherence-skill` design as an SRP inversion — `api-design-skill` is the documented authoring counterpart per `openapi-contract-adherence-skill` SKILL.md:507). This PLAN reflects the agreed redesign.

## Overview

The `openapi-contract-adherence-skill` is reactive-only (diffs a changed spec for breaking
changes). Its `deploy/.AGENTS.md` routing exception fired only on post-change review
phrases, so LLM-assisted sessions AUTHORING a spec — or editing code that generates one —
never loaded any skill and never enforced authoring good practices (descriptions, examples).

The original implementation widened `openapi-contract-adherence-skill`'s bullet to cover
authoring. **Review rejected this** as an SRP inversion: the repo already ships
`api-design-skill` as the authoring skill (cross-referenced at
`openapi-contract-adherence-skill` SKILL.md:507). The redesign restores the documented
author/review split:

- **Authoring** (file + framework signals) → route to `api-design-skill`; add a
  §Authoring Quality Gate to its body (description + example on every op/schema; `redocly lint`).
- **Reactive review** (breaking-change phrases) → `openapi-contract-adherence-skill`, unchanged.

## Acceptance Criteria

- [x] `openapi-contract-adherence-skill` routing bullet restored to reactive-only (no authoring signals)
- [x] New terse authoring bullet in `deploy/.AGENTS.md` routes file + framework signals to `api-design-skill`
- [x] `api-design-skill` body gains §Authoring Quality Gate: description + example mandate (framework-agnostic), per-framework mapping table, `redocly lint` gate, missing-ruleset flag
- [x] `express-zod` dropped (it is a validator, not a spec generator); Spring+springdoc-openapi and DRF+drf-spectacular/drf-yasg added
- [x] Authoring-vs-review classification reconciliation documented (description *presence* at authoring ≠ description *change* classification as Cosmetic at review)
- [x] Existing reactive breaking-change flow preserved
- [x] (Separate issue) pre-commit hook running `redocly lint` as the hard enforcement net — filed as its own issue (#320), not deferred-without-link

## Dependency & Consumer Map

| Node (file/module)                                      | Depends on | Consumers                                              | Change risk |
|---------------------------------------------------------|------------|--------------------------------------------------------|-------------|
| `deploy/.AGENTS.md` (OpenAPI routing bullets)           | —          | deploys to `~/.config/opencode/AGENTS.md`; read by every primary session | low — restored + added one terse bullet |
| `opencode_app/.opencode/skills/api-design-skill/SKILL.md` | —        | loaded by primary session on authoring triggers       | low — additive section (Step 4.5) |
| `openapi-contract-adherence-skill`                      | —          | reactive review; body unchanged                        | none |
| `deploy/setup.sh` / `README.md` counts                  | —          | documentation-sync                                     | none — no skill/agent/MCP count changed (opencode-tooling review verified) |

## Implementation Phases

### Phase 1: Restore SRP Split — Routing Bullets
- [x] **1.1** Revert the OpenAPI routing-exception bullet in `deploy/.AGENTS.md` to reactive-only (original triggers: "openapi diff", "api contract", "breaking change", "consumer update plan", "spec changed"); add a "Reactive only" clarifier
    — **Why:** the widened bullet inverted the documented author/review split (SKILL.md:507); restoring reactive-only removes the trigger collision with `api-design-skill`
    — **Done when:** `openapi-contract-adherence-skill`'s bullet contains no authoring signals
    — **Consumers affected:** every primary session post-deploy (restores prior reactive behavior)
    — **Done:** reverted bullet to original triggers + added "Reactive only" clarifier; files: deploy/.AGENTS.md; fixes: none
- [x] **1.2** Add a new terse authoring bullet routing file signals (`openapi.yaml`/`.json`/`swagger.yaml`) + framework signals (FastAPI, NestJS, tsoa, zod-to-openapi, Spring+springdoc, DRF+drf-spectacular) to `api-design-skill`; bullet points to §Authoring Quality Gate rather than inlining the rule
    — **Why:** `api-design-skill` is the documented authoring home; the cue must stay terse (rule lives in the skill body, not the cue) per the file's "terse by design" philosophy
    — **Done when:** a distinct bullet loads `api-design-skill` on authoring signals and references the skill section
    — **Consumers affected:** primary sessions touching spec/code-gen files
    — **Done:** added new bullet routing file+framework signals to api-design-skill, referencing §Authoring Quality Gate (no inline rule); files: deploy/.AGENTS.md; fixes: none

### Phase 2: Authoring Quality Gate in api-design-skill Body
- [x] **2.1** Add §Authoring Quality Gate (Step 4.5) to `opencode_app/.opencode/skills/api-design-skill/SKILL.md`: description + example mandate on every operation and schema
    — **Why:** the rule belongs in the authoring skill body (DRY, single source) so it is delivered when the skill loads, not split into a routing cue that drifts
    — **Done when:** the section states the framework-agnostic mandate
    — **Consumers affected:** sessions loading `api-design-skill`
    — **Done:** added Step 4.5 §Authoring Quality Gate with framework-agnostic description+example mandate; files: opencode_app/.opencode/skills/api-design-skill/SKILL.md; fixes: none
- [x] **2.2** Add the per-framework mapping table (FastAPI/NestJS/tsoa/zod-to-openapi/Spring+springdoc/DRF) showing where description + example live in source (docstrings/JSDoc/`Field(description=)`/`@ApiProperty`/`@Operation`/`@extend_schema`)
    — **Why:** the mandate is only actionable if each framework knows its source annotation; the table is the teaching surface for end users
    — **Done when:** the table covers all frameworks named in the routing bullet
    — **Consumers affected:** framework-specific authoring sessions
    — **Done:** added 6-row mapping table (FastAPI/NestJS/tsoa/zod-to-openapi/Spring+springdoc/DRF) with description+example source columns; files: opencode_app/.opencode/skills/api-design-skill/SKILL.md; fixes: none
- [x] **2.3** Mandate `redocly lint` before done; flag (not silently skip) a missing `redocly.yaml`/`.spectral.yaml`; acknowledge the redocly-default `operation-description` overlap so the inline mandate isn't mistaken for load-bearing
    — **Why:** the lint gate is the real net; the missing-ruleset flag prevents silent no-op; the overlap note prevents a future maintainer from duplicating effort
    — **Done when:** the section names the command, the flag-don't-skip rule, and the overlap caveat
    — **Consumers affected:** repos touched by future authoring sessions
    — **Done:** added redocly lint mandate, missing-ruleset flag-don't-skip rule, and operation-description overlap caveat + authoring-vs-review classification reconciliation; files: opencode_app/.opencode/skills/api-design-skill/SKILL.md; fixes: none

### Phase 3: Framework List Correctness
- [x] **3.1** Drop `express-zod` from the framework signal list (it is a request validator, not a spec generator) in both the routing bullet and the mapping table
    — **Why:** correctness — `express-zod` does not emit OpenAPI; only `@asteasolutions/zod-to-openapi` does. Listing it caused over-triggering on validation edits.
    — **Done when:** no reference to `express-zod` as a spec generator remains
    — **Consumers affected:** none (fixes false triggers)
    — **Done:** removed express-zod from routing bullet and mapping table (kept only @asteasolutions/zod-to-openapi); files: deploy/.AGENTS.md, opencode_app/.opencode/skills/api-design-skill/SKILL.md; fixes: none
- [x] **3.2** Add Spring + springdoc-openapi and Django DRF + drf-spectacular/drf-yasg to the framework signal list and mapping table
    — **Why:** coverage — these are mainstream enterprise OpenAPI generators omitted from the original conservative set
    — **Done when:** both appear in the routing bullet and the mapping table
    — **Consumers affected:** Spring/DRF authoring sessions
    — **Done:** added Spring+springdoc-openapi and Django DRF+drf-spectacular/drf-yasg to routing bullet and mapping table; files: deploy/.AGENTS.md, opencode_app/.opencode/skills/api-design-skill/SKILL.md; fixes: none

### Phase 4: Verify Deploy Sync (No Count Drift)
- [x] **4.1** Confirm no skill/agent/MCP count changed and `documentation-sync-workflow-skill` is NOT required (text edits + one additive skill section only)
    — **Why:** no skill/agent/MCP was added or removed; opencode-tooling review verified `setup.sh`/`setup.ps1`/`README.md`/`registry.json` are unaffected
    — **Done when:** no sync commit needed (verified by opencode-tooling reviewer)
    — **Consumers affected:** none
    — **Done:** opencode-tooling review verified setup.sh/setup.ps1/README.md/registry.json unaffected; registry gate `node deploy/build-registry.mjs --check` → OK (agents=36, skills=129, no drift); files: none; fixes: none

### Phase 5: Hard Enforcement Net (Separate Issue)
- [x] **5.1** File the pre-commit hook (`redocly lint` + committed `redocly.yaml` template) as its own GitHub issue and link it here
    — **Why:** AGENTS.md is a soft nudge; the hook is the deterministic net that catches drift when the LLM forgets or a human edits the spec directly. A deferred net without an issue link is a net that doesn't get built.
    — **Done when:** a follow-up issue exists and is referenced below
    — **Consumers affected:** end-user repos adopting the hook (opt-in)
    — **Done:** filed follow-up issue #320 (pre-commit hook + redocly.yaml template) and linked it in Phase 5; files: none (GitHub issue); fixes: none

**Follow-up issue:** https://github.com/darellchua2/opencode-config-template/issues/320

## Technical Notes

- Files changed: `deploy/.AGENTS.md` (routing bullets), `opencode_app/.opencode/skills/api-design-skill/SKILL.md` (Step 4.5 section).
- No skill/agent/MCP add or remove → no count sync (verified).
- Source-of-truth respected: skill edit is in `opencode_app/.opencode/`, not the deployed `~/.config/opencode/` copy.

## Risks & Mitigation

| Risk | Mitigation |
|------|------------|
| Soft nudge drifts under context compaction | Honesty Caveat stands; Phase 5 hook is the deterministic net (filed as separate issue) |
| Framework signal over-triggering on bare route edits | Acceptable — `api-design-skill` load is the correct authoring context; bullet is terse |
| Authoring/review trigger ambiguity | Eliminated — two distinct bullets, two distinct skills, explicit split |
| redocly not installed in target repo | Missing-ruleset flag instructs the LLM to flag, not silently skip |

## Success Metrics

- An LLM session editing a FastAPI route or `openapi.yaml` loads `api-design-skill` and applies the §Authoring Quality Gate without the user saying "openapi"
- Reactive breaking-change flow on `openapi-contract-adherence-skill` unchanged
- Missing-ruleset repos get flagged, not silently skipped
- No trigger collision between the two skills
