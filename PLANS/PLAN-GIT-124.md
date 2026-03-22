# Plan: Add PLAN.md sync habit to all code-implementing subagents

## Issue Reference
- **Number**: #124
- **URL**: https://github.com/darellchua2/opencode-config-template/issues/124
- **Labels**: enhancement, documentation

## Overview

Create a reusable `plan-updater` skill and add PLAN.md synchronization to all code-implementing subagents (pr-workflow-subagent, refactoring-subagent, testing-subagent, ticket-creation-subagent). The skill updates branch-specific PLAN.md files before key workflow milestones.

## Acceptance Criteria
- [x] `plan-updater` skill created with PLAN detection/update logic
- [x] pr-workflow-subagent invokes plan-updater before PR creation
- [x] refactoring-subagent invokes plan-updater after code changes
- [x] testing-subagent invokes plan-updater after test creation
- [x] ticket-creation-subagent invokes plan-updater (initial PLAN already handled)
- [x] All subagents skip gracefully when no PLAN.md exists
- [x] Skill handles both GitHub (`PLAN-GIT-*`) and JIRA (`PLAN-*`) conventions

## Scope
- `skills/plan-updater/SKILL.md` — New skill (primary)
- `agents/pr-workflow-subagent.md` — Add plan-updater invocation
- `agents/refactoring-subagent.md` — Add plan-updater invocation
- `agents/testing-subagent.md` — Add plan-updater invocation
- `agents/ticket-creation-subagent.md` — Add plan-updater invocation
- `setup.sh`, `setup.ps1`, `README.md` — Documentation sync

---

## Implementation Phases

### Phase 1: Create plan-updater Skill
- [x] Create `skills/plan-updater/SKILL.md` with:
  - Branch name detection (GitHub + JIRA patterns)
  - PLAN file discovery logic
  - Progress update workflow
  - Semantic commit format
  - Graceful skip behavior

### Phase 2: Update Subagents
- [x] Add `plan-updater` skill permission to pr-workflow-subagent
- [x] Add `plan-updater` skill permission to refactoring-subagent
- [x] Add `plan-updater` skill permission to testing-subagent
- [x] Add `plan-updater` skill permission to ticket-creation-subagent
- [x] Update workflow sections to include PLAN.md sync step

### Phase 3: Update Documentation
- [x] Update setup.sh skill count (49 -> 50)
- [x] Update setup.ps1 skill count (49 -> 50)
- [x] Update README.md skill categories table
- [x] Add plan-updater to Git/Workflow category

### Phase 4: Verification
- [ ] Test end-to-end: make changes -> invoke subagent -> verify PLAN updated
- [ ] Verify graceful skip when no PLAN exists
- [ ] Verify semantic commit format
