# Plan: Standardize PLAN file and git branch naming convention for GitHub issues

## Issue Reference
- **Number**: #131
- **URL**: https://github.com/darellchua2/opencode-config-template/issues/131
- **Labels**: enhancement, minor

## Overview

The current workflow for creating PLAN files and git branches from GitHub issues needs cleanup and standardization. Branch naming and PLAN file naming conventions are inconsistent across related skills and subagents. This plan establishes a unified convention.

## Acceptance Criteria
- [x] Git branches created from issues use `GIT-{issue_number}` naming
- [x] PLAN files are placed in `PLANS/` folder at repository root
- [x] Workflow checks if `PLANS/` folder exists before creating PLAN file
- [x] Workflow auto-creates `PLANS/` folder if it doesn't exist
- [x] PLAN file naming pattern: `PLANS/PLAN-GIT-{issue_number}.md`
- [x] All related skills are updated and synchronized

## Scope
- `skills/git-issue-plan-workflow/`
- `skills/git-issue-creator/`
- `skills/plan-updater/`
- `skills/jira-ticket-plan-workflow/`

---

## Implementation Phases

### Phase 1: Audit & Analysis
- [x] Review current branch naming logic in `git-issue-plan-workflow` skill
- [x] Review current branch naming logic in `ticket-branch-workflow` skill
- [x] Review `git-issue-creator` skill for branch references
- [x] Review `git-workflow-framework` skill for convention references
- [x] Review `plan-updater` skill for PLAN file naming patterns
- [x] Scan all agents/subagents for branch naming references
- [x] Document current naming patterns and inconsistencies

### Phase 2: Core Implementation
- [x] Update branch naming convention to `GIT-{issue_number}` across all skills
- [x] Ensure PLAN file is placed in `PLANS/` folder (not root)
- [x] Add logic to check if `PLANS/` folder exists before PLAN file creation
- [x] Add logic to auto-create `PLANS/` folder if it doesn't exist
- [x] Ensure PLAN file naming uses `PLANS/PLAN-GIT-{issue_number}.md` consistently
- [x] Update `git-issue-plan-workflow/SKILL.md` with new branch naming and folder logic
- [x] Update `jira-ticket-plan-workflow/SKILL.md` with PLANS folder check (ticket-branch-workflow not in repo)
- [x] Update `git-issue-creator/SKILL.md` with new branch naming
- [x] Update `plan-updater/SKILL.md` with consistent naming patterns and folder path

### Phase 3: Documentation & Synchronization
- [x] Verify no stale references to `issue-{number}` pattern remain (only legacy detection in plan-updater)

### Phase 4: Validation
- [ ] Create a test issue and verify branch is named `GIT-{number}`
- [ ] Verify PLAN file is created in `PLANS/` folder
- [ ] Verify PLAN file is named `PLAN-GIT-{number}.md`
- [ ] Verify workflow handles missing `PLANS/` folder gracefully
- [ ] Verify all related skills produce consistent output
- [ ] Cross-check all skills for synchronized conventions

### Phase 5: Cleanup & Closure
- [ ] Remove any debug or temporary files
- [ ] Final review of all changed files
- [ ] Close issue #131 upon completion

---

## Technical Notes

- Current branch naming uses `issue-{number}` pattern — must change to `GIT-{number}`
- PLAN files currently use `PLAN-GIT-{number}.md` — verify this is already consistent
- Multiple skills reference branch naming conventions — all must be synchronized
- Consider whether any existing branches need to be renamed (backward compatibility)

## Dependencies
- None (internal refactoring only)

## Risks & Mitigation

| Risk | Mitigation |
|------|-----------|
| Breaking existing branch references | Document migration path for existing branches |
| Inconsistent updates across skills | Use `documentation-sync-workflow` for validation |
| Existing PRs referencing old branch names | Leave existing branches as-is, apply new convention going forward |

## Success Metrics
- All skills use `GIT-{number}` for GitHub issue branches
- All skills use `PLAN-GIT-{number}.md` for GitHub issue PLAN files
- Zero references to old `issue-{number}` pattern in skill files
- Documentation accurately reflects new convention
