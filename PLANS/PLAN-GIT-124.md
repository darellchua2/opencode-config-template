# Plan: Update pr-workflow-subagent to sync PLAN.md before PR creation

## Issue Reference
- **Number**: #124
- **URL**: https://github.com/darellchua2/opencode-config-template/issues/124
- **Labels**: enhancement, documentation

## Overview

Add a PLAN.md synchronization step to the pr-workflow-subagent's workflow so that every PR accurately reflects the planning state of the branch. The subagent should check for branch-specific PLAN.md files, update progress checkboxes based on completed work, and commit changes before PR creation.

## Acceptance Criteria
- [ ] pr-workflow-subagent checks for `PLANS/PLAN-GIT-{issue-number}.md` before creating a PR
- [ ] Issue number is extracted from the current branch name (e.g., `issue-123`)
- [ ] PLAN.md progress checkboxes are updated to reflect completed work on the branch
- [ ] PLAN.md changes are committed with a semantic commit message (e.g., `docs(plan): update PLAN-GIT-123.md with current progress`)
- [ ] Workflow skips gracefully when no PLAN.md exists for the branch
- [ ] The new step is documented in the subagent's workflow section in `agents/pr-workflow-subagent.md`
- [ ] The implementation approach (rule/skill/subagent) is chosen and implemented consistently

## Scope
- `agents/pr-workflow-subagent.md` — Primary file to update
- Potentially: `skills/` — If implemented as a skill
- Potentially: `agents/` — If implemented as a subagent

---

## Implementation Phases

### Phase 1: Decision & Design
- [ ] Decide on implementation approach (rule vs skill vs subagent)
- [ ] If skill: Define skill interface, inputs, and outputs
- [ ] If subagent: Define subagent scope and permissions
- [ ] Document decision in issue comments

### Phase 2: Implementation
- [ ] Create plan-updater skill (or inline rule in subagent)
- [ ] Implement PLAN.md file discovery logic (branch name -> issue number -> PLAN path)
- [ ] Implement progress update logic (analyze commits, changed files, acceptance criteria)
- [ ] Implement graceful skip when no PLAN.md exists
- [ ] Add commit step with semantic message format

### Phase 3: Subagent Integration
- [ ] Update `agents/pr-workflow-subagent.md` workflow section (insert new step between quality checks and PR creation)
- [ ] Add skill permission to subagent if using skill approach
- [ ] Update subagent coordination section if applicable

### Phase 4: Cross-Workflow Consistency
- [ ] Verify git-issue-plan-workflow skill is compatible with the new plan-updater
- [ ] Verify jira-ticket-plan-workflow skill is compatible
- [ ] Ensure PLAN.md naming conventions match existing patterns

### Phase 5: Documentation & Validation
- [ ] Update pr-workflow-subagent.md with clear documentation of the new step
- [ ] Test end-to-end: create issue -> branch -> PLAN.md -> make changes -> create PR
- [ ] Verify PLAN.md is updated before PR is created
- [ ] Verify workflow skips when no PLAN.md exists

---

## Technical Notes

### Implementation Approach Options

| Approach | Pros | Cons |
|----------|------|------|
| **Rule** (instruction in subagent) | Lightweight, no extra files, simple to maintain | Limited reusability, logic embedded in subagent |
| **Skill** (e.g., `plan-updater`) | Reusable across multiple subagents, consistent behavior | Requires skill creation and maintenance, adds indirection |
| **Subagent** (e.g., `plan-sync-subagent`) | Maximum specialization, isolated behavior | Overkill for this scope, adds complexity |

**Recommendation**: A **skill** (`plan-updater`) is likely the best fit.

### PLAN.md Location Convention
- GitHub issues: `PLANS/PLAN-GIT-{ISSUE_NUMBER}.md`
- JIRA tickets: `PLANS/PLAN-{PROJECT_KEY}-{NUMBER}.md`

### Branch Name to Issue Number Parsing
- Pattern: `issue-{number}` -> extract `{number}`
- Pattern: `feature/issue-{number}` -> extract `{number}`
- Pattern: `{PROJECT-KEY}-{number}` -> extract for JIRA

## Dependencies
- None (self-contained improvement)

## Risks & Mitigation
- **Risk**: PLAN.md update could fail if file is malformed
  - **Mitigation**: Validate PLAN.md structure before updating, skip on parse errors
- **Risk**: Commit step adds noise to PR diff
  - **Mitigation**: Use dedicated `docs(plan):` commit prefix to keep changes organized

## Success Metrics
- All PRs created via pr-workflow-subagent include up-to-date PLAN.md when applicable
- No PRs fail due to missing PLAN.md (graceful skip)
- PLAN.md updates are consistent and accurate across different project frameworks
