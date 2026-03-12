# Plan: Add new subagents to reduce primary agent context bloat

## Issue Reference
- **Number**: #84
- **URL**: https://github.com/darellchua2/opencode-config-template/issues/84
- **Labels**: enhancement

## Overview
Add 6 new specialized subagents to offload 13 skills (~6,390 lines) from the primary agent context. This will improve performance and reduce token usage for common tasks.

## Acceptance Criteria
- [x] Create `nextjs-setup-subagent` for Next.js project setup skills
- [x] Create `coverage-subagent` for test coverage documentation
- [x] Create `opencode-tooling-subagent` for skill/agent meta-operations
- [x] Create `refactoring-subagent` for code refactoring and DRY principle
- [x] Create `tdd-subagent` for TDD methodology guidance
- [x] Create `diagram-subagent` for visual documentation generation
- [x] Update AGENTS.md with new routing patterns
- [x] Update config.json with new agent definitions
- [ ] Verify skill-to-subagent mappings are correct

## Scope
- `.AGENTS.md` - Add routing patterns for new subagents
- `config.json` - Add agent definitions with tool restrictions

---

## Implementation Phases

### Phase 1: Define Subagent Specifications ✅
- [x] Document skill groupings for each new subagent
- [x] Define tool access levels for each subagent
- [x] Define routing patterns (regex patterns for task matching)
- [x] Estimate context savings per subagent

### Phase 2: Create config.json Agent Definitions ✅
- [x] Add `nextjs-setup-subagent` definition
- [x] Add `coverage-subagent` definition
- [x] Add `opencode-tooling-subagent` definition
- [x] Add `refactoring-subagent` definition
- [x] Add `tdd-subagent` definition
- [x] Add `diagram-subagent` definition

### Phase 3: Update AGENTS.md Routing Rules ✅
- [x] Add routing patterns for `nextjs-setup-subagent`
- [x] Add routing patterns for `coverage-subagent`
- [x] Add routing patterns for `opencode-tooling-subagent`
- [x] Add routing patterns for `refactoring-subagent`
- [x] Add routing patterns for `tdd-subagent`
- [x] Add routing patterns for `diagram-subagent`
- [x] Update "Task Type → Subagent" table
- [x] Update "Automatic Routing Patterns" section
- [x] Update "Subagent Tool Restrictions" table

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
| `nextjs-setup-subagent` | nextjs-standard-setup, nextjs-complete-setup, nextjs-image-usage | ~2,400 | read, write, edit, glob, grep |
| `coverage-subagent` | coverage-readme-workflow, coverage-framework | ~800 | read, write, edit, glob, grep |
| `opencode-tooling-subagent` | opencode-agent-creation, opencode-skill-creation, opencode-skill-auditor, opencode-skills-maintainer, opencode-tooling-framework | ~1,200 | read, write, edit, glob, grep |
| `refactoring-subagent` | typescript-dry-principle | ~940 | read, write, edit, glob, grep |
| `tdd-subagent` | tdd-workflow | ~650 | read, glob, grep (read-only) |
| `diagram-subagent` | ascii-diagram-creator | ~400 | read, write, glob |

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
- 6 new subagents operational ✅
- 13 skills offloaded from primary agent ✅
- ~6,390 lines of skill content removed from primary context
- All routing patterns functional
- No regression in existing subagent routing
