# Plan: Update .AGENTS.md with default subagent delegation policy

## Issue Reference
- **Number**: #70
- **URL**: https://github.com/darellchua2/opencode-config-template/issues/70
- **Labels**: enhancement, documentation
- **Branch**: issue-70-update-agents-delegation-policy

## Overview
Add a default subagent delegation policy section to `.AGENTS.md` that instructs the primary agent to always delegate tasks to appropriate subagents when the user prompt matches a subagent's specialization.

## Acceptance Criteria
- [x] Default subagent delegation policy documented at top of file
- [x] Delegation decision tree clearly defined
- [x] Example delegation scenarios table provided
- [x] Emphasis on consistent behavior through specialized skills

## Scope
- `.AGENTS.md` - Added delegation policy section

---

## Implementation Phases

### Phase 1: Analysis ✅ COMPLETE
- [x] Review existing .AGENTS.md structure
- [x] Identify optimal placement for delegation policy
- [x] Determine content structure based on git-issue-plan-workflow skill

### Phase 2: Implementation ✅ COMPLETE
- [x] Add "Default Subagent Delegation Policy" section
- [x] Include delegation decision tree
- [x] Add example delegation scenarios table

### Phase 3: Validation
- [ ] Verify formatting is correct
- [ ] Commit with semantic message
- [ ] Push to remote
- [ ] Update issue with progress

## Technical Notes
- Placement: Top of file, before Task Type → Agent table
- Ensures agents read delegation policy first
- Aligns with git-issue-plan-workflow best practices

## Success Metrics
- Primary agents consistently delegate to specialized subagents
- Reduced code duplication across agent implementations
- Improved maintainability through modular task handling
