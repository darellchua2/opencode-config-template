# PLAN-GIT-170: Investigate: Can subagents invoke other subagents as tasks?

**GitHub Issue**: [#170](https://github.com/darellchua2/opencode-config-template/issues/170)
**Branch**: `GIT-170`
**Status**: Ready to begin execution

---

## Overview

Research whether custom subagents (defined in `agents/*.md`) can delegate work to other subagents using the Task tool. This would enable subagent chaining / orchestration patterns where specialized agents can leverage each other's capabilities.

## Acceptance Criteria

- [ ] Research whether OpenCode subagents have access to the Task tool
- [ ] Document which subagent types (built-in vs custom) support Task tool access
- [ ] If supported, provide an example of one subagent calling another
- [ ] If not supported, document the limitation and suggest alternatives

---

## Implementation Phases

### Phase 1: Research & Documentation Review
- [ ] Review OpenCode documentation for Task tool availability in subagents
- [ ] Review existing subagent definitions in `opencode_app/.opencode/agents/` for tool configurations
- [ ] Check if custom subagent `.md` files can specify tool access (including Task tool)
- [ ] Review the AGENTS.md routing rules for any references to subagent chaining

### Phase 2: Built-in Subagent Testing
- [ ] Test if the built-in `explore` subagent can invoke the `general` subagent via Task tool
- [ ] Test if the built-in `general` subagent can spawn custom subagents
- [ ] Document tool availability for each built-in subagent type

### Phase 3: Custom Subagent Testing
- [ ] Configure a test custom subagent with explicit Task tool access
- [ ] Attempt to invoke another custom subagent from within the test subagent
- [ ] Test nesting depth (subagent A spawns B, which spawns C)
- [ ] Document any depth limits or resource constraints

### Phase 4: Documentation & Recommendations
- [ ] Document findings in a structured report
- [ ] If supported: Create example of subagent calling another (e.g., code-review spawning testing)
- [ ] If not supported: Document limitation and suggest alternative patterns
- [ ] Update AGENTS.md or relevant documentation with findings
- [ ] Update subagent definitions if configuration changes are needed

### Phase 5: Final Validation
- [ ] Verify all acceptance criteria are met
- [ ] Ensure documentation is complete and accurate
- [ ] Close issue with findings summary

---

## Technical Notes

Key investigation areas:
1. **Tool availability**: Does the Task tool appear in custom subagent tool lists?
2. **Execution context**: When a subagent spawns another subagent, what's the execution hierarchy?
3. **Depth limits**: Are there limits on nesting depth (subagent spawning subagent spawning subagent)?
4. **Resource considerations**: Memory/context implications of chained subagent calls
5. **Error handling**: What happens when a chained subagent call fails?

## Scope

- `opencode_app/.opencode/agents/` — Custom subagent definitions
- OpenCode documentation and Task tool capabilities
- Subagent configuration and routing patterns

## Dependencies

- OpenCode version and its Task tool implementation
- Access to subagent execution logs for debugging

## Risks & Mitigation

| Risk | Mitigation |
|------|-----------|
| Task tool not available in subagents | Document limitation; suggest hub-and-spoke pattern as alternative |
| Nesting depth causes context overflow | Test with shallow nesting; document practical limits |
| Documentation gaps in OpenCode | Rely on empirical testing as primary research method |

---

*Tracking progress with ticket-plan-workflow-skill*
