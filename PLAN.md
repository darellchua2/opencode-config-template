# Plan: Add default subagent delegation policy to .AGENTS.md

## Overview
Add a default subagent delegation policy section to `.AGENTS.md` that instructs the primary agent to always delegate tasks to appropriate subagents when the user prompt matches a subagent's specialization.

## Issue Reference
- Issue: #68
- URL: https://github.com/darellchua2/opencode-config-template/issues/68
- Labels: enhancement, documentation
- Branch: issue-68-add-subagent-delegation-policy

## Files to Modify
1. `.AGENTS.md` - Add default subagent delegation policy section at the top

## Approach
1. **Add Policy Section**: Insert new "Default Subagent Delegation Policy" section at the beginning of `.AGENTS.md`
2. **Define Decision Tree**: Create clear decision tree for delegation routing
3. **Add Examples**: Provide example scenarios showing when to delegate
4. **Commit Changes**: Use semantic commit format (docs: add default subagent delegation policy)

## Success Criteria
- [x] Default subagent delegation policy documented
- [x] Delegation decision tree clearly defined
- [x] Example delegation scenarios provided
- [x] File updated and committed

## Notes
- This ensures consistent behavior through specialized skills
- Enables proper tool isolation and access control
- Maintains modular, maintainable task handling
- Enforces best practices by domain experts
