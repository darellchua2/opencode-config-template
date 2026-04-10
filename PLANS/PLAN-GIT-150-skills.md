# Plan: Populate 4 Empty Skill Directories

## Issue Reference
- **Number**: #150 (extended scope)
- **URL**: https://github.com/nus-cee/opencode-config-template/issues/150
- **Branch**: working on current branch

## Overview

4 skill directories exist with no SKILL.md content: `continuous-learning`, `eval-harness`, `strategic-compact`, `verification-loop`. These need proper skill definitions so they're functional and included in the setup summary (49 -> 53 skills).

## Acceptance Criteria
- [ ] Each of the 4 directories has a valid SKILL.md with frontmatter (name, description, license, compatibility, metadata)
- [ ] Each skill has proper "What I do", "When to use me", and implementation sections
- [ ] `setup.sh` summary updated: SKILLS (49) -> SKILLS (53), new category added
- [ ] `setup.ps1` summary updated: SKILLS (49) -> SKILLS (53), new category added
- [ ] `README.md` Skill Categories table updated with new category and correct totals
- [ ] All skill counts mathematically verified

## Scope
- `skills/continuous-learning/SKILL.md` — new file
- `skills/eval-harness/SKILL.md` — new file
- `skills/strategic-compact/SKILL.md` — new file
- `skills/verification-loop/SKILL.md` — new file
- `setup.sh` — summary section (~lines 544-578)
- `setup.ps1` — summary section (~lines 351-385)
- `README.md` — Skill Categories table (~lines 128-142)

---

## Implementation Phases

### Phase 1: Create SKILL.md files
- [ ] Create `skills/continuous-learning/SKILL.md` — Auto-extract patterns from sessions
- [ ] Create `skills/eval-harness/SKILL.md` — Verification loop evaluation
- [ ] Create `skills/strategic-compact/SKILL.md` — Manual compaction suggestions
- [ ] Create `skills/verification-loop/SKILL.md` — Continuous verification

### Phase 2: Update setup summaries
- [ ] Update `setup.sh` skills summary: add new category "Agent Optimization (4)", total 49 -> 53
- [ ] Update `setup.ps1` skills summary: add new category "Agent Optimization (4)", total 49 -> 53

### Phase 3: Update README
- [ ] Update README.md Skill Categories table with new category
- [ ] Update total count in README.md intro paragraph

### Phase 4: Validation
- [ ] Verify all 53 skills have SKILL.md files
- [ ] Verify category totals sum to 53
- [ ] Verify setup.sh and setup.ps1 match

---

## Technical Notes

### Skill categorization
These 4 skills all relate to AI agent session optimization:
- **continuous-learning**: Extracts and stores patterns from coding sessions for future reference
- **eval-harness**: Provides evaluation framework to assess code/skill quality
- **strategic-compact**: Suggests when and how to compact conversation context
- **verification-loop**: Continuously verifies implementation against requirements

Category name: **Agent Optimization** (4 skills)

### SKILL.md template
Each SKILL.md follows the standard format:
```markdown
---
name: skill-name
description: Brief description
license: Apache-2.0
compatibility: opencode
metadata:
  audience: developers
  workflow: category
---

## What I do
...

## When to use me
...
```
