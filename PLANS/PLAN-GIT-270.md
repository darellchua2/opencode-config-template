# Skill Permission Scoping Optimization

**Issue**: https://github.com/darellchua2/opencode-config-template/issues/270
**Branch**: issue-270
**Type**: enhancement
**Labels**: enhancement, documentation

## Overview

Optimize initial-context token consumption by implementing skill permission scoping. The opencode primary session loads every skill's `description` into the `<available_skills>` listing at startup ([docs-confirmed](https://opencode.ai/docs/skills/#recognize-tool-description)). Skills that are **only ever loaded by a specific subagent** (never by the primary directly) don't need their descriptions in the primary's listing — hiding them via `permission.skill: deny` removes them from `<available_skills>` and saves those tokens on every primary session. The consumer subagent re-`allow`s them in its frontmatter.

**Doc basis (verified):**
- [Skills §Configure permissions](https://opencode.ai/docs/skills/#configure-permissions): `"deny"` → "Skill hidden from agent."
- [Skills §Override per agent](https://opencode.ai/docs/skills/#override-per-agent): per-agent frontmatter `permission.skill` can re-`allow`.
- Mechanism: global `permission.skill` deny in `opencode.json` + `permission.skill: { "<skill>": "allow" }` in the consumer subagent's frontmatter.

This enforces hub-and-spoke routing (already the repo's pattern per `deploy/.AGENTS.md`): the primary delegates to the subagent, which loads the skill. Consistent, not a behavior break — but should be documented so direct-load attempts aren't surprising.

## Acceptance Criteria

- [x] GitHub issue created (#270)
- [x] Branch created (issue-270)
- [x] PLAN file generated with atomic steps + rationale + Dependency & Consumer Map
- [ ] Add global `permission.skill` deny block to `opencode_app/opencode.json`
- [ ] Confirm/add `allow` overrides in consumer subagent frontmatters
- [ ] Resolve open questions (uiux-review, playwright)
- [ ] Verify no consumer subagent is missed
- [ ] Document hub-and-spoke enforcement in `deploy/.AGENTS.md`
- [ ] Verify denied skills absent from primary's `<available_skills>`

## Scope

- `opencode_app/opencode.json` (global deny block)
- `opencode_app/.opencode/agents/cad-specialist-subagent.md` (already has allow block — confirm it stays)
- `opencode_app/.opencode/agents/autoresearch-{code,ml,research}-subagent.md` (add `autoresearch-core-skill: allow`)
- `opencode_app/.opencode/agents/testing-subagent.md` (add `test-generator-framework-skill: allow`)
- `opencode_app/.opencode/agents/{discovery,requirements,technical-design}-specialist-subagent.md` (add `interactive-document-rendering-skill: allow`)
- `deploy/.AGENTS.md` (documentation)

## Technical Notes

### Subagent-only skills (DENY globally in opencode.json, ALLOW in consumer subagent frontmatter):

| Skill(s) | Consumer subagent(s) (add `allow` here) | Notes |
| --- | --- | --- |
| **CAD cluster (14)**: `cad-generation`, `cad-viewer`, `cad-step-parts`, `cad-dxf`, `cad-urdf`, `cad-srdf`, `cad-sdf`, `cad-sendcutsend`, `cad-gcode`, `cad-bambu-labs`, `cad-implicit`, `autodesk-aps`, `civil-3d`, `open3d` | `cad-specialist-subagent` (already has the allow block — confirm it stays) | Note: `cad-*` glob catches 11; `autodesk-aps`/`civil-3d`/`open3d` need explicit entries (not cad- prefixed) |
| `autoresearch-core` | `autoresearch-code-subagent`, `autoresearch-ml-subagent`, `autoresearch-research-subagent` | Loaded via the derivative autoresearch skills |
| `test-generator-framework` | `testing-subagent` | |
| `interactive-document-rendering` | `discovery-specialist-subagent`, `requirements-specialist-subagent`, `technical-design-specialist-subagent` | Loaded by brd/srs/vision/technical-design-creation skills |

### Explicitly PRIMARY-available (NO change — do not deny):
- `grilling` — user-invoked orchestrator, primary loads it directly.
- `linting-workflow` — primary may load directly.

### Open questions (flag, don't decide):
- `uiux-review-skill` — routed via `uiux-reviewer-subagent`; user did not explicitly classify. Recommend subagent-only (same pattern as CAD); flag for confirmation.
- `playwright-responsive-audit-skill` — ALREADY configured: `responsive-audit-subagent.md` has `playwright-responsive-audit-skill: allow`. Verify whether the global deny already exists; if not, add it for consistency. Its own description says "invoked exclusively via permission.skill by the audit subagent."

### Implementation Details:

**Global deny location:** `opencode_app/opencode.json` already has a `permission` key (lines 271, 278 — verify these are top-level vs per-agent). Add a `permission.skill` block:
```jsonc
"permission": {
  "skill": {
    "cad-generation-skill": "deny",
    "cad-viewer-skill": "deny",
    // ... all 14 CAD cluster skills ...
    "autoresearch-core-skill": "deny",
    "test-generator-framework-skill": "deny",
    "interactive-document-rendering-skill": "deny"
  }
}
```
(Investigate whether the existing `permission` keys at L271/L278 are the right insertion point or if a new top-level `permission.skill` is needed. The file is JSONC — comments allowed.)

**Consumer subagent allow-overrides:** add/confirm `permission.skill: { "<skill>": "allow" }` in:
- `opencode_app/.opencode/agents/cad-specialist-subagent.md` — **already has** the full cad allow block (14 entries). Confirm it remains.
- `opencode_app/.opencode/agents/autoresearch-{code,ml,research}-subagent.md` — add `autoresearch-core-skill: allow`.
- `opencode_app/.opencode/agents/testing-subagent.md` — add `test-generator-framework-skill: allow`.
- `opencode_app/.opencode/agents/{discovery,requirements,technical-design}-specialist-subagent.md` — add `interactive-document-rendering-skill: allow`.

**Verification:** after changes, `opencode debug config` (if available) should show the denied skills absent from the primary's resolved `<<available_skills>>`. At minimum, grep confirms the deny entries exist in opencode.json and allow entries exist in each consumer subagent.

---
*Tracking progress with ticket-plan-workflow-skill*
---

## Dependency & Consumer Map

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---------------------|---------------------------|---------------------------------|-------------|
| `opencode_app/opencode.json` | — | Primary session (via skill loading), all subagents | medium (breaks all skill loading if malformed) |
| `opencode_app/.opencode/agents/cad-specialist-subagent.md` | — | CAD operations | low (already has allow block — confirm only) |
| `opencode_app/.opencode/agents/autoresearch-code-subagent.md` | — | Autoresearch code optimization | low (add allow override) |
| `opencode_app/.opencode/agents/autoresearch-ml-subagent.md` | — | Autoresearch ML training | low (add allow override) |
| `opencode_app/.opencode/agents/autoresearch-research-subagent.md` | — | Autoresearch literature review | low (add allow override) |
| `opencode_app/.opencode/agents/testing-subagent.md` | — | Test generation | low (add allow override) |
| `opencode_app/.opencode/agents/discovery-specialist-subagent.md` | — | Discovery sessions | low (add allow override) |
| `opencode_app/.opencode/agents/requirements-specialist-subagent.md` | — | Requirements gathering | low (add allow override) |
| `opencode_app/.opencode/agents/technical-design-specialist-subagent.md` | — | Technical design creation | low (add allow override) |
| `deploy/.AGENTS.md` | `opencode_app/opencode.json` changes | Future developers reading patterns | low (documentation only) |

## Implementation Phases

### Phase 1: Audit and Preparation

- [ ] **1.1** Read `opencode_app/opencode.json` to locate existing `permission` keys and understand structure
    — **Why:** Need to verify where to insert the new `permission.skill` block (top-level or merge with existing permissions)
    — **Done when:** File content is read and lines 271/278 are examined to determine insertion point
    — **Consumers affected:** None (read-only audit step)

- [ ] **1.2** Read `opencode_app/.opencode/agents/cad-specialist-subagent.md` to confirm existing CAD skill allow block
    — **Why:** Verify the CAD allow block already exists (per user note) and identify exact syntax to match for other subagents
    — **Done when:** File content is read and the 14 CAD skill allow entries are confirmed present
    — **Consumers affected:** None (read-only audit step)

- [ ] **1.3** Grep all subagent files for references to each target skill to verify consumer mapping
    — **Why:** Ensure no consumer subagent is missed before adding deny entries; catch any unexpected direct consumers
    — **Done when:** Output shows 14 CAD skills → cad-specialist-subagent; autoresearch-core → 3 autoresearch subagents; test-generator-framework → testing-subagent; interactive-document-rendering → 3 specialist subagents
    — **Consumers affected:** None (read-only audit step)

### Phase 2: Add Global Deny Block to opencode.json

- [ ] **2.1** Add top-level `permission.skill` block to `opencode_app/opencode.json` with 14 CAD skill deny entries
    — **Why:** Hides CAD cluster skills from primary session's `<available_skills>` to save tokens; enforces hub-and-spoke routing via cad-specialist-subagent
    — **Done when:** File contains `"permission": { "skill": { "cad-generation-skill": "deny", ..., "open3d-skill": "deny" } }` with all 14 skills
    — **Consumers affected:** Primary session (loses CAD skill descriptions from startup context); cad-specialist-subagent (already has allow override — no impact)

- [ ] **2.2** Add `autoresearch-core-skill: deny` to the `permission.skill` block
    — **Why:** Hides autoresearch-core from primary session; it's only ever loaded by autoresearch subagents via derivative skills
    — **Done when:** File contains `"autoresearch-core-skill": "deny"` within the `permission.skill` object
    — **Consumers affected:** Primary session (loses autoresearch-core description); autoresearch subagents (will add allow overrides in Phase 3)

- [ ] **2.3** Add `test-generator-framework-skill: deny` to the `permission.skill` block
    — **Why:** Hides test-generator-framework from primary session; it's only ever loaded by testing-subagent
    — **Done when:** File contains `"test-generator-framework-skill": "deny"` within the `permission.skill` object
    — **Consumers affected:** Primary session (loses test-generator-framework description); testing-subagent (will add allow override in Phase 3)

- [ ] **2.4** Add `interactive-document-rendering-skill: deny` to the `permission.skill` block
    — **Why:** Hides interactive-document-rendering from primary session; it's only ever loaded by document-creation skills which are themselves only loaded by specialist subagents
    — **Done when:** File contains `"interactive-document-rendering-skill": "deny"` within the `permission.skill` object
    — **Consumers affected:** Primary session (loses interactive-document-rendering description); specialist subagents (will add allow overrides in Phase 3)

- [ ] **2.5** Resolve open question for `uiux-review-skill` — add deny if subagent-only (recommended)
    — **Why:** Completes the scoping work; uiux-review-skill is routed via uiux-reviewer-subagent per pattern analysis — should follow same CAD/autoresearch pattern
    — **Done when:** Decision is made (deny or not) and implemented if deny chosen; flagged as user-decision if deferred
    — **Consumers affected:** Primary session (if denied, loses uiux-review-skill description); uiux-reviewer-subagent (would need allow override if denied)

- [ ] **2.6** Resolve open question for `playwright-responsive-audit-skill` — verify/confirm global deny exists
    — **Why:** Ensures consistency; skill description says "invoked exclusively via permission.skill by the audit subagent" but global deny may be missing
    — **Done when:** Grep confirms deny entry exists in opencode.json or it's added if missing
    — **Consumers affected:** Primary session (if deny was missing, loses playwright-responsive-audit-skill description); responsive-audit-subagent (already has allow override)

- [ ] **2.7** Validate `opencode_app/opencode.json` syntax (JSONC)
    — **Why:** Prevent JSON parsing errors that would break opencode startup; JSONC allows comments but still requires valid syntax
    — **Done when:** File parses as valid JSONC with no syntax errors
    — **Consumers affected:** All of opencode (malformed opencode.json breaks entire system)

### Phase 3: Add Allow Overrides to Consumer Subagents

- [ ] **3.1** Confirm `permission.skill` block in `cad-specialist-subagent.md` includes all 14 CAD skills with `allow`
    — **Why:** Ensure cad-specialist-subagent can still access CAD cluster skills after global deny is added; user noted it already exists — just verify
    — **Done when:** File contains `"permission": { "skill": { "cad-generation-skill": "allow", ..., "open3d-skill": "allow" } }` with all 14 skills
    — **Consumers affected:** cad-specialist-subagent (regains access to CAD skills); CAD operations (functionality restored)

- [ ] **3.2** Add `autoresearch-core-skill: allow` to `autoresearch-code-subagent.md` frontmatter
    — **Why:** Restores autoresearch-core access to autoresearch-code-subagent after global deny is added
    — **Done when:** File contains `"autoresearch-core-skill": "allow"` within its `permission.skill` object
    — **Consumers affected:** autoresearch-code-subagent (regains access to autoresearch-core); autoresearch code optimization (functionality restored)

- [ ] **3.3** Add `autoresearch-core-skill: allow` to `autoresearch-ml-subagent.md` frontmatter
    — **Why:** Restores autoresearch-core access to autoresearch-ml-subagent after global deny is added
    — **Done when:** File contains `"autoresearch-core-skill": "allow"` within its `permission.skill` object
    — **Consumers affected:** autoresearch-ml-subagent (regains access to autoresearch-core); autoresearch ML training (functionality restored)

- [ ] **3.4** Add `autoresearch-core-skill: allow` to `autoresearch-research-subagent.md` frontmatter
    — **Why:** Restores autoresearch-core access to autoresearch-research-subagent after global deny is added
    — **Done when:** File contains `"autoresearch-core-skill": "allow"` within its `permission.skill` object
    — **Consumers affected:** autoresearch-research-subagent (regains access to autoresearch-core); autoresearch literature review (functionality restored)

- [ ] **3.5** Add `test-generator-framework-skill: allow` to `testing-subagent.md` frontmatter
    — **Why:** Restores test-generator-framework access to testing-subagent after global deny is added
    — **Done when:** File contains `"test-generator-framework-skill": "allow"` within its `permission.skill` object
    — **Consumers affected:** testing-subagent (regains access to test-generator-framework); test generation (functionality restored)

- [ ] **3.6** Add `interactive-document-rendering-skill: allow` to `discovery-specialist-subagent.md` frontmatter
    — **Why:** Restores interactive-document-rendering access to discovery-specialist-subagent after global deny is added (skill is loaded by vision-creation-skill which discovery-specialist loads)
    — **Done when:** File contains `"interactive-document-rendering-skill": "allow"` within its `permission.skill` object
    — **Consumers affected:** discovery-specialist-subagent (regains access to interactive-document-rendering); discovery sessions (functionality restored)

- [ ] **3.7** Add `interactive-document-rendering-skill: allow` to `requirements-specialist-subagent.md` frontmatter
    — **Why:** Restores interactive-document-rendering access to requirements-specialist-subagent after global deny is added (skill is loaded by brd/srs-creation-skills which requirements-specialist loads)
    — **Done when:** File contains `"interactive-document-rendering-skill": "allow"` within its `permission.skill` object
    — **Consumers affected:** requirements-specialist-subagent (regains access to interactive-document-rendering); requirements gathering (functionality restored)

- [ ] **3.8** Add `interactive-document-rendering-skill: allow` to `technical-design-specialist-subagent.md` frontmatter
    — **Why:** Restores interactive-document-rendering access to technical-design-specialist-subagent after global deny is added (skill is loaded by technical-design-creation-skill which technical-design-specialist loads)
    — **Done when:** File contains `"interactive-document-rendering-skill": "allow"` within its `permission.skill` object
    — **Consumers affected:** technical-design-specialist-subagent (regains access to interactive-document-rendering); technical design creation (functionality restored)

- [ ] **3.9** Add `uiux-review-skill: allow` to `uiux-reviewer-subagent.md` frontmatter (if uiux-review-skill was denied in 2.5)
    — **Why:** Restores uiux-review-skill access to uiux-reviewer-subagent after global deny is added (if deny was chosen in 2.5)
    — **Done when:** File contains `"uiux-review-skill": "allow"` within its `permission.skill` object (only if denied in 2.5)
    — **Consumers affected:** uiux-reviewer-subagent (regains access to uiux-review-skill if denied); UI/UX review sessions (functionality restored if denied)

- [ ] **3.10** Verify all modified subagent frontmatters are valid markdown
    — **Why:** Prevent markdown parsing errors in frontmatter which would break subagent loading
    — **Done when:** All modified files parse as valid markdown with no syntax errors
    — **Consumers affected:** All modified subagents (malformed frontmatter breaks subagent loading)

### Phase 4: Documentation and Verification

- [ ] **4.1** Add "Skill Permission Scoping" subsection to `deploy/.AGENTS.md` documenting the hub-and-spoke enforcement
    — **Why:** Documents the pattern so future developers understand why direct skill loads are denied; prevents confusion when trying to load a skill directly
    — **Done when:** File contains a new subsection explaining the global deny + per-agent allow override pattern, with examples from this work
    — **Consumers affected:** Future developers (documentation only; no functional impact)

- [ ] **4.2** Run `opencode debug config` to verify denied skills are absent from primary's `<available_skills>`
    — **Why:** Confirms the optimization is working; denied skills should not appear in the primary session's resolved skill listing
    — **Done when:** Command output shows the 16-17 denied skills are NOT in the primary's `<available_skills>` listing but ARE in their respective consumer subagents
    — **Consumers affected:** None (verification step)

- [ ] **4.3** Grep `opencode_app/opencode.json` to verify all deny entries exist
    — **Why:** Quick verification that all intended deny entries are present in the file
    — **Done when:** Grep output shows 17 deny entries (14 CAD + autoresearch-core + test-generator-framework + interactive-document-rendering + uiux-review if denied + playwright if added)
    — **Consumers affected:** None (verification step)

- [ ] **4.4** Grep consumer subagent files to verify all allow overrides exist
    — **Why:** Quick verification that all consumer subagents have their required allow overrides
    — **Done when:** Grep output shows each consumer subagent has the expected allow entries (CAD subagent: 14; autoresearch subagents: 1 each; testing-subagent: 1; 3 specialist subagents: 1 each; uiux-reviewer-subagent: 1 if uiux-review was denied)
    — **Consumers affected:** None (verification step)

- [ ] **4.5** Test loading a denied skill from primary session to confirm denial works
    — **Why:** End-to-end verification that the permission system is working as expected; ensures the optimization actually blocks skill access
    — **Done when:** Attempting to load a denied skill from primary session fails with expected error, while loading from consumer subagent succeeds
    — **Consumers affected:** None (verification step)

- [ ] **4.6** Document verification commands and acceptance criteria in this PLAN file
    — **Why:** Provides future developers with a clear checklist for validating similar permission scoping work
    — **Done when:** This section contains the verification commands list and acceptance criteria table
    — **Consumers affected:** Future developers (documentation only)

## Verification Commands

```bash
# 1. Verify global deny entries exist in opencode.json
grep -c "deny" opencode_app/opencode.json  # Should match 17 (16-17 depending on uiux-review/playwright decisions)

# 2. Verify allow overrides exist in consumer subagents
grep -A 5 "permission.skill" opencode_app/.opencode/agents/cad-specialist-subagent.md | grep -c "allow"  # Should be 14
grep "permission.skill" opencode_app/.opencode/agents/autoresearch-*-subagent.md | grep -c "autoresearch-core-skill: allow"  # Should be 3
grep "permission.skill" opencode_app/.opencode/agents/testing-subagent.md | grep "test-generator-framework-skill: allow"  # Should be 1
grep "permission.skill" opencode_app/.opencode/agents/*-specialist-subagent.md | grep "interactive-document-rendering-skill: allow"  # Should be 3

# 3. Verify opencode.json syntax is valid
jq empty opencode_app/opencode.json  # Should exit with 0 if valid

# 4. Run opencode debug config to verify primary's <available_skills>
opencode debug config  # Check that denied skills are absent from primary's listing

# 5. Test denied skill access from primary vs consumer subagent
# (Manual test: try loading cad-generation-skill from primary, should fail; try from cad-specialist-subagent, should succeed)
```

## Dependencies

None (self-contained optimization work)

## Risks & Mitigation

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| JSONC syntax error in opencode.json breaks opencode startup | Low | Critical (system unusable) | Validate JSONC syntax with `jq` before committing; Phase 2.7 requires validation |
| Missed consumer subagent causes skill access failure | Medium | Medium (specific functionality broken) | Phase 1.3 requires comprehensive grep audit; Phase 4.4 verifies all allow overrides exist |
| Documentation incomplete leads to future confusion | Low | Low (developer confusion) | Phase 4.1 adds documentation; Phase 4.6 documents verification commands |
| uiux-review or playwright decisions deferred cause incomplete scope | Low | Low (partial optimization) | Flag open questions in Phase 2.5/2.6; document decisions clearly |

## Success Metrics

- **Primary session startup**: Reduced initial-context token consumption (measure `<available_skills>` size before/after)
- **Deny verification**: All 17 deny entries present in `opencode_app/opencode.json` (verified via grep)
- **Allow verification**: All consumer subagents have required allow overrides (verified via grep)
- **Functional verification**: Loading denied skills from primary fails; loading from consumer subagents succeeds
- **Documentation**: `deploy/.AGENTS.md` contains Skill Permission Scoping subsection explaining the pattern
- **Syntax validation**: `jq` validation passes on modified `opencode_app/opencode.json`

## Notes

- This optimization is opt-in with no breaking changes; it enforces existing hub-and-spoke patterns already in use
- The `permission.skill` mechanism is opencode-native and supported by the docs; this is not a hack or workaround
- Subagent-only skills are those with `permission.task: deny` in their frontmatter or documented as "invoked exclusively via permission.skill"
- The CAD cluster (14 skills) is the largest token savings opportunity; autoresearch-core, test-generator-framework, and interactive-document-rendering are moderate savings
- This work should be replicated for any future subagent-only skills to maintain the optimization
- Token savings should be measurable by comparing `<available_skills>` listing size before and after changes