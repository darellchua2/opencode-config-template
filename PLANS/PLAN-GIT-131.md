# Plan: Standardize PLAN file and git branch naming convention for GitHub issues

## Issue Reference
- **Number**: #131
- **URL**: https://github.com/darellchua2/opencode-config-template/issues/131
- **Labels**: enhancement, minor

## Overview

The current workflow for creating PLAN files and git branches from GitHub issues needs cleanup and standardization. Branch naming and PLAN file naming conventions are inconsistent across related skills and subagents. This plan establishes a unified convention.

## Acceptance Criteria
- [ ] Git branches created from issues use `GIT-{issue_number}` naming
- [ ] PLAN files follow a consistent naming pattern
- [ ] All related skills are updated and synchronized

## Scope
- `skills/git-issue-plan-workflow/`
- `skills/ticket-branch-workflow/`
- `skills/git-issue-creator/`
- `skills/git-workflow-framework/`
- `skills/plan-updater/`
- `agents/` (any subagents referencing branch naming)
- Documentation files (`README.md`, `AGENTS.md`)

---

## Implementation Phases

### Phase 1: Audit & Analysis
- [ ] Review current branch naming logic in `git-issue-plan-workflow` skill
- [ ] Review current branch naming logic in `ticket-branch-workflow` skill
- [ ] Review `git-issue-creator` skill for branch references
- [ ] Review `git-workflow-framework` skill for convention references
- [ ] Review `plan-updater` skill for PLAN file naming patterns
- [ ] Scan all agents/subagents for branch naming references
- [ ] Document current naming patterns and inconsistencies

### Phase 2: Core Implementation
- [ ] Update branch naming convention to `GIT-{issue_number}` across all skills
- [ ] Ensure PLAN file naming uses `PLAN-GIT-{issue_number}.md` consistently
- [ ] Update `git-issue-plan-workflow/SKILL.md` with new branch naming
- [ ] Update `ticket-branch-workflow/SKILL.md` with new branch naming
- [ ] Update `git-issue-creator/SKILL.md` with new branch naming
- [ ] Update `git-workflow-framework/SKILL.md` with new convention
- [ ] Update `plan-updater/SKILL.md` with consistent naming patterns

### Phase 3: Documentation & Synchronization
- [ ] Update `README.md` if it references branch naming conventions
- [ ] Update `AGENTS.md` routing instructions if affected
- [ ] Run `documentation-sync-workflow` to ensure counts and listings are accurate
- [ ] Verify no stale references to `issue-{number}` pattern remain

### Phase 4: Validation
- [ ] Create a test issue and verify branch is named `GIT-{number}`
- [ ] Verify PLAN file is named `PLAN-GIT-{number}.md`
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
