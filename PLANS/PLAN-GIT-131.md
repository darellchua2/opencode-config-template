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
- [x] Redundant `git-issue-creator` skill removed (merged into `git-issue-plan-workflow`)
- [x] `git-issue-plan-workflow` uses framework skills (`git-issue-labeler`, `git-semantic-commits`, `git-issue-updater`)
- [x] Documentation updated (setup.sh, setup.ps1, README.md)

## Scope
- `skills/git-issue-plan-workflow/` - enhanced with framework integration
- `skills/git-issue-creator/` - **TO BE REMOVED** (redundant)
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

### Phase 3: Consolidate Redundant git-issue-creator Skill
- [x] Enhance `git-issue-plan-workflow` to use framework skills:
  - [x] Use `git-issue-labeler` for label assignment (replace inline detection logic)
  - [x] Use `git-semantic-commits` for commit message formatting
  - [x] Use `git-issue-updater` for progress comments to issues
- [x] Remove broken `ticket-branch-workflow` dependency reference from `git-issue-creator`
- [x] Delete `skills/git-issue-creator/` directory
- [x] Update `setup.sh` - remove from skill listings, decrement count (47→46)
- [x] Update `setup.ps1` - remove from skill listings, decrement count
- [x] Update `README.md` - remove from Git/Workflow table, update counts
- [x] Clean up phantom `jira-git-workflow` references across all files

### Phase 4: Documentation & Synchronization
- [x] Verify no stale references to `issue-{number}` pattern remain (only legacy detection in plan-updater)

### Phase 5: Validation
- [x] Create a test issue and verify branch is named `GIT-{number}`
- [x] Verify PLAN file is created in `PLANS/` folder
- [x] Verify PLAN file is named `PLAN-GIT-{number}.md`
- [x] Verify workflow handles missing `PLANS/` folder gracefully
- [x] Verify all related skills produce consistent output
- [x] Cross-check all skills for synchronized conventions
- [x] Verify `git-issue-plan-workflow` uses framework skills correctly

### Phase 6: Cleanup & Closure
- [x] Remove "Integration with Other Skills" sections from all skills (not part of OpenCode docs)
- [x] Clean up remaining phantom `ticket-branch-workflow` references (2 files)
- [x] Final review of all changed files
- [ ] Close issue #131 upon completion

---

## Technical Notes

- Current branch naming uses `issue-{number}` pattern — must change to `GIT-{number}`
- PLAN files currently use `PLAN-GIT-{number}.md` — verify this is already consistent
- Multiple skills reference branch naming conventions — all must be synchronized
- Consider whether any existing branches need to be renamed (backward compatibility)

### Redundancy Found (Phase 3)
- `git-issue-creator` and `git-issue-plan-workflow` are **functionally identical**
- Both create GitHub issues → branch → PLAN file → commit → push → update issue
- `git-issue-creator` has broken dependency on `ticket-branch-workflow` (not in repo)
- `git-issue-plan-workflow` has inline label detection that duplicates `git-issue-labeler`
- Solution: Merge `git-issue-creator` into `git-issue-plan-workflow`, use framework skills

## Dependencies
- None (internal refactoring only)

---

## OpenCode Tooling Skills Improvement

### Issues Found

| Skill | Issue |
|-------|-------|
| `opencode-tooling-framework` | **MISSING** - Referenced in subagent and maintainer but doesn't exist |
| `opencode-skill-auditor` | Overlaps with maintainer - both do skill analysis |
| `opencode-agent-creation` | **Incomplete** - Only 27 lines, missing Steps/Best Practices sections |
| `opencode-skill-creation` | Well-structured (538 lines) ✓ |

### Phase 7: Consolidate OpenCode Tooling Skills
- [x] Merge `opencode-skill-auditor` into `opencode-skills-maintainer`
  - [x] Extract redundancy detection logic from auditor
  - [x] Add to maintainer as new section "Redundancy & Modularization Analysis"
  - [x] Delete `skills/opencode-skill-auditor/` directory
- [x] Remove reference to non-existent `opencode-tooling-framework`
  - [x] Remove from `opencode-skills-maintainer/SKILL.md` (line 110)
  - [x] Remove from `agents/opencode-tooling-subagent.md` permissions
- [x] Expand `opencode-agent-creation` to match `opencode-skill-creation` quality
  - [x] Add detailed Steps section (7+ steps)
  - [x] Add Best Practices section
  - [x] Add Common Issues section
  - [x] Add Verification Commands section
  - [x] Add Example Output section
- [x] Update documentation
  - [x] Update `setup.sh` - decrement skill count, remove auditor from listings
  - [x] Update `setup.ps1` - decrement skill count, remove auditor from listings
  - [x] Update `README.md` - remove auditor from OpenCode Meta table

### Phase 8: Validate OpenCode Tooling Skills
- [x] Verify `opencode-skills-maintainer` handles both validation and redundancy detection
- [x] Verify `opencode-agent-creation` has comprehensive documentation
- [x] Verify no references to deleted `opencode-skill-auditor` remain
- [x] Verify no references to non-existent `opencode-tooling-framework` remain
- [x] Test merged maintainer skill

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
- `git-issue-creator` removed, `git-issue-plan-workflow` uses framework skills
- Skill count reduced from 47 to 46
