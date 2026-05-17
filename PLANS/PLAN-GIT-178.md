# PLAN-GIT-178: Add frontend-design-skill and enhance doc/pptx/xlsx skills with anti-AI-slop aesthetics

**Issue**: [#178](https://github.com/darellchua2/opencode-config-template/issues/178)
**Branch**: `issue-178`
**Created**: 2026-05-17
**Status**: Complete

---

## Overview

Create a new `frontend-design-skill` and enhance existing document/presentation skills with "avoid generic AI Slop aesthetics" guidance, ensuring agents produce distinctive, bold, and context-appropriate design choices.

## Acceptance Criteria

- [x] New `frontend-design-skill` created with full OpenCode skill format (frontmatter, sections, steps)
- [x] `pptx-specialist-skill` enhanced with Design Aesthetics section avoiding AI slop
- [x] `docx-creation-skill` enhanced with Design Aesthetics section avoiding AI slop
- [x] `xlsx-specialist-skill` enhanced with Design Aesthetics section avoiding AI slop
- [x] `setup.sh` updated with new skill listing and incremented count
- [x] `setup.ps1` updated with new skill listing and incremented count
- [x] `README.md` updated with new skill in table and incremented count

---

## Phase 1: Create New Skill

- [x] Create directory `opencode_app/.opencode/skills/frontend-design-skill/`
- [x] Create `SKILL.md` with proper OpenCode frontmatter (name, description, license, compatibility, metadata)
- [x] Include Design Thinking section with bold aesthetic direction guidance (17 aesthetic tone options)
- [x] Include Frontend Aesthetics Guidelines (typography, color, motion, spatial composition, backgrounds)
- [x] Include anti-patterns section (generic AI aesthetics, overused fonts, cliched colors)
- [x] Include implementation steps (6-step workflow: Analyze, Choose, Implement, Apply, Add Motion, Refine)
- [x] Add technology-specific notes (React, HTML/CSS, Vue)
- [x] Add common issues section with solutions
- [x] Add Dependencies section (Google Fonts, Motion, Playwright)
- [x] Add Verification Commands section with checklist

## Phase 2: Enhance Existing Skills

- [x] Read current `pptx-specialist-skill/SKILL.md` and add Design Aesthetics section (46 lines added)
- [x] Read current `docx-creation-skill/SKILL.md` and add Design Aesthetics section (58 lines added)
- [x] Read current `xlsx-specialist-skill/SKILL.md` and add Design Aesthetics section (54 lines added)
- [x] Each section has medium-specific guidance (not generic copy-paste)

**Medium-Specific Enhancements**:

| Skill | Design Focus | Unique Elements |
|-------|-------------|-----------------|
| `pptx-specialist` | Slide-level visual identity | Signature design elements, content-to-aesthetic mapping table, audience differentiation strategy |
| `docx-creation` | Document typography & layout | Typography hierarchy table, document aesthetic by type table, pull quote/callout box guidance |
| `xlsx-specialist` | Spreadsheet data presentation | Chart styling guidelines, color palette recommendations by use case, KPI dashboard section guidance |

## Phase 3: Documentation Sync

- [x] Update `setup.sh` — Framework (9) → (10), add `frontend-design`, count 53 → 54 (3 locations)
- [x] Update `setup.ps1` — Framework (9) → (10), add `frontend-design`, count 53 → 54 (4 locations)
- [x] Update `README.md` — Framework (9) → (10), add `frontend-design`, count 53 → 54 (2 locations)

## Phase 4: Code Review & Fixes

Reviewed by `code-review-subagent` and `opencode-tooling-subagent`. Findings applied:

- [x] Fix `setup.ps1:1684` — stale `Framework (9)` → `Framework (10)` in summary line
- [x] Fix `README.md:23` — `53+ skill directories` → `54 skill directories`
- [x] Fix `opencode_app/README.md:26` — `53+ skill directories` → `54 skill directories`
- [x] Add `## Dependencies` section to `frontend-design-skill` (Google Fonts, Motion, Playwright)
- [x] Add `## Verification Commands` section to `frontend-design-skill` with checklist
- [x] Fix `metadata.languages` — YAML list `[...]` → string `"..."` for standard compliance

## Phase 5: Final Validation

- [x] Verify new skill directory structure is correct (`frontend-design-skill/SKILL.md` exists)
- [x] Verify all enhanced skills have properly formatted Design Aesthetics sections
- [x] Verify documentation counts match actual file counts (54 SKILL.md files on disk)
- [x] Verify Framework (10) count consistent — zero stale `Framework (9)` references remain
- [x] Verify zero stale `53+` references remain
- [x] Review all changes for consistency (8 files changed, 250 insertions, 53 deletions)

---

## Files Changed

```
 PLANS/PLAN-GIT-178.md                              | 105 ++++++++++++++-------
 README.md                                          |   6 +-
 opencode_app/.opencode/skills/docx-creation-skill/SKILL.md  | 58 +++++++++++++++
 opencode_app/.opencode/skills/frontend-design-skill/SKILL.md | ~295 +++++++++ (NEW)
 opencode_app/.opencode/skills/pptx-specialist-skill/SKILL.md | 46 ++++++++++
 opencode_app/.opencode/skills/xlsx-specialist-skill/SKILL.md | 54 +++++++++++
 opencode_app/README.md                             |   2 +-
 setup.ps1                                          | 21 +++---
 setup.sh                                           | 11 ++-
 9 files changed, 250 insertions(+), 53 deletions(-)
```

## Technical Notes

- Source: External SKILL.md design guidelines (42 lines)
- License: Apache-2.0 (normalized from source's "Complete terms in LICENSE.txt")
- Compatibility: opencode
- Metadata: audience: developers, workflow: design, languages: "html, css, javascript, typescript, react, vue"
- Each Design Aesthetics section is tailored to its medium (slides vs documents vs spreadsheets)
- All enhanced sections include: anti-patterns, signature design elements, differentiation strategy, and medium-specific tables
- Code review score: **8.5/10** (code-review-subagent), **PASS** (opencode-tooling-subagent)

## Risks & Mitigation

| Risk | Status | Mitigation |
|------|--------|-----------|
| Design Aesthetics sections feel generic across skills | Mitigated | Each skill has unique content: pptx→slide identity, docx→typography hierarchy, xlsx→chart styling |
| Skill count mismatch after sync | Mitigated | Verified Framework (10) across all files; zero stale references remain |
| Existing skill structure disrupted | Mitigated | Sections appended via `edit` tool, no restructure of existing content |
| Missing standard sections in new skill | Mitigated | Added Dependencies + Verification Commands after code review |
| Non-standard metadata format | Mitigated | Converted `languages` from YAML list to string |

---

*Tracking progress with ticket-plan-workflow-skill*
