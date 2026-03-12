# Plan: Add new subagents to reduce primary agent context bloat

## Issue Reference
- **Number**: #84
- **URL**: https://github.com/darellchua2/opencode-config-template/issues/84
- **Labels**: enhancement

## Overview
Add 6 new specialized subagents to offload 13 skills (~6,390 lines) from the primary agent context. This will improve performance and reduce token usage for common tasks.

## Acceptance Criteria
- [ ] Create `nextjs-setup-subagent` for Next.js project setup skills
- [ ] Create `coverage-subagent` for test coverage documentation
- [ ] Create `opencode-tooling-subagent` for skill/agent meta-operations
- [ ] Create `refactoring-subagent` for code refactoring and DRY principle
- [ ] Create `tdd-subagent` for TDD methodology guidance
- [ ] Create `diagram-subagent` for visual documentation generation
- [ ] Update AGENTS.md with new routing patterns
- [ ] Update config.json with new agent definitions
- [ ] Verify skill-to-subagent mappings are correct

## Scope
- `.AGENTS.md` - Add routing patterns for new subagents
- `config.json` - Add agent definitions with tool restrictions

---

## Implementation Phases

### Phase 1: Define Subagent Specifications
- [ ] Document skill groupings for each new subagent
- [ ] Define tool access levels for each subagent
- [ ] Define routing patterns (regex patterns for task matching)
- [ ] Estimate context savings per subagent

### Phase 2: Create config.json Agent Definitions
- [ ] Add `nextjs-setup-subagent` definition
- [ ] Add `coverage-subagent` definition
- [ ] Add `opencode-tooling-subagent` definition
- [ ] Add `refactoring-subagent` definition
- [ ] Add `tdd-subagent` definition
- [ ] Add `diagram-subagent` definition

### Phase 3: Update AGENTS.md Routing Rules
- [ ] Add routing patterns for `nextjs-setup-subagent`
- [ ] Add routing patterns for `coverage-subagent`
- [ ] Add routing patterns for `opencode-tooling-subagent`
- [ ] Add routing patterns for `refactoring-subagent`
- [ ] Add routing patterns for `tdd-subagent`
- [ ] Add routing patterns for `diagram-subagent`
- [ ] Update "Task Type → Subagent" table
- [ ] Update "Automatic Routing Patterns" section
- [ ] Update "Subagent Tool Restrictions" table

### Phase 4: Validation
- [ ] Verify all routing patterns are non-overlapping
- [ ] Verify tool restrictions are appropriate
- [ ] Verify skill-to-subagent mappings complete
- [ ] Test routing logic with sample prompts

---

## Technical Notes

### Subagent Definitions

| Subagent | Skills | Lines Saved | Tools |
|----------|--------|-------------|-------|
| `nextjs-setup-subagent` | nextjs-standard-setup, nextjs-complete-setup, nextjs-image-usage | ~2,400 | read, write, edit, glob, grep, bash (delegated) |
| `coverage-subagent` | coverage-readme-workflow, coverage-framework | ~800 | read, write, edit, glob, grep, bash (delegated) |
| `opencode-tooling-subagent` | opencode-agent-creation, opencode-skill-creation, opencode-skill-auditor, opencode-skills-maintainer, opencode-tooling-framework | ~1,200 | read, write, edit, glob, grep |
| `refactoring-subagent` | typescript-dry-principle | ~940 | read, write, edit, glob, grep, bash (delegated) |
| `tdd-subagent` | tdd-workflow | ~650 | read, glob, grep, bash (delegated, read-only) |
| `diagram-subagent` | ascii-diagram-creator | ~400 | read, write, glob, bash (delegated) |

### Routing Patterns

```
nextjs-setup-subagent:
  - nextjs*setup*, create*nextjs*, init*nextjs*, new*nextjs*, setup*nextjs*

coverage-subagent:
  - coverage*, badge*update*, test*coverage*, readme*badge*, update*coverage*

opencode-tooling-subagent:
  - opencode*skill*, opencode*agent*, create*skill*, audit*skill*, maintain*skill*

refactoring-subagent:
  - refactor*, dry*, duplicate*, cleanup*code*, remove*duplication*, eliminate*duplicate*

tdd-subagent:
  - tdd*, red*green*, test*first*, test*driven*

diagram-subagent:
  - diagram*, flowchart*, architecture*diagram*, ascii*diagram*, create*diagram*
```

## Dependencies
- None - standalone configuration update

## Risks & Mitigation

| Risk | Impact | Mitigation |
|------|--------|------------|
| Overlapping patterns cause routing conflicts | Medium | Use specific patterns with clear precedence |
| Tool restrictions too restrictive | Low | Follow existing subagent patterns |
| Breaking existing routing | High | Test thoroughly before merging |

## Success Metrics
- 6 new subagents operational
- 13 skills offloaded from primary agent
- ~6,390 lines of skill content removed from primary context
- All routing patterns functional
- No regression in existing subagent routing
