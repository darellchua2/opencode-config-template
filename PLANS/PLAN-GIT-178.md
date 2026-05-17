# PLAN-GIT-178: Add frontend-design-skill and enhance doc/pptx/xlsx skills with anti-AI-slop aesthetics

**Issue**: [#178](https://github.com/darellchua2/opencode-config-template/issues/178)
**Branch**: `issue-178`
**Created**: 2026-05-17
**Status**: Ready

---

## Overview

Create a new `frontend-design-skill` and enhance existing document/presentation skills with "avoid generic AI Slop aesthetics" guidance, ensuring agents produce distinctive, bold, and context-appropriate design choices.

## Acceptance Criteria

- [ ] New `frontend-design-skill` created with full OpenCode skill format (frontmatter, sections, steps)
- [ ] `pptx-specialist-skill` enhanced with Design Aesthetics section avoiding AI slop
- [ ] `docx-creation-skill` enhanced with Design Aesthetics section avoiding AI slop
- [ ] `xlsx-specialist-skill` enhanced with Design Aesthetics section avoiding AI slop
- [ ] `setup.sh` updated with new skill listing and incremented count
- [ ] `setup.ps1` updated with new skill listing and incremented count
- [ ] `README.md` updated with new skill in table and incremented count

---

## Phase 1: Create New Skill

- [ ] Create directory `opencode_app/.opencode/skills/frontend-design-skill/`
- [ ] Create `SKILL.md` with proper OpenCode frontmatter (name, description, license, compatibility, metadata)
- [ ] Include Design Thinking section with bold aesthetic direction guidance
- [ ] Include Frontend Aesthetics Guidelines (typography, color, motion, spatial composition, backgrounds)
- [ ] Include anti-patterns section (generic AI aesthetics, overused fonts, cliched colors)
- [ ] Include implementation steps with examples
- [ ] Add version/changelog tracking

## Phase 2: Enhance Existing Skills

- [ ] Read current `pptx-specialist-skill/SKILL.md` and add Design Aesthetics section
- [ ] Read current `docx-creation-skill/SKILL.md` and add Design Aesthetics section
- [ ] Read current `xlsx-specialist-skill/SKILL.md` and add Design Aesthetics section
- [ ] Ensure each section has medium-specific guidance (not generic copy-paste)

## Phase 3: Documentation Sync

- [ ] Update `setup.sh` — add frontend-design-skill to listing and increment skill count
- [ ] Update `setup.ps1` — add frontend-design-skill to listing and increment skill count
- [ ] Update `README.md` — add frontend-design-skill to Skill Categories table and increment total

## Phase 4: Validation

- [ ] Verify new skill directory structure is correct
- [ ] Verify all enhanced skills have properly formatted Design Aesthetics sections
- [ ] Verify documentation counts match actual file counts
- [ ] Run setup.sh dry-run to validate skill deployment
- [ ] Review all changes for consistency

---

## Technical Notes

- Source material for new skill located at `/home/silentx/Downloads/SKILL.md`
- License: Apache-2.0
- Compatibility: opencode
- Metadata: audience: developers, workflow: design
- Each Design Aesthetics section should be tailored to its medium (slides vs documents vs spreadsheets)

## Risks & Mitigation

| Risk | Mitigation |
|------|-----------|
| Design Aesthetics sections feel generic across skills | Write medium-specific guidance with unique examples |
| Skill count mismatch after sync | Verify counts against actual directory listing |
| Existing skill structure disrupted | Append sections, don't restructure existing content |
