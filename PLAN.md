# Plan: Remove Primary Agent References and Add Parallel Task Execution

## Issue Reference
- **Number**: #71
- **URL**: https://github.com/darellchua2/opencode-config-template/issues/71
- **Labels**: enhancement
- **Branch**: issue-71-remove-primary-agents-add-parallel-execution

## Overview
Remove all references to `build-with-skills` and `plan-with-skills` primary agents from the codebase. Update fallback logic to prioritize skills and add parallel task execution decision logic with user confirmation.

## Acceptance Criteria
- [x] All `build-with-skills` and `plan-with-skills` references removed (26 occurrences)
- [x] `.AGENTS.md` updated with skill-based fallback logic
- [x] Parallel task execution policy documented (max 3-5 subagents)
- [x] User confirmation required before parallel execution (manual mode)
- [x] Task list source: user prompt OR PLAN*.md files when explicitly referenced
- [x] Dependency detection rules defined
- [x] Skills updated to remove primary agent mentions
- [x] Documentation files updated

## Scope

### Files Modified

| File | Occurrences | Status |
|------|-------------|--------|
| `.AGENTS.md` | 5 | ✅ Complete |
| `skills/opencode-skills-maintainer/SKILL.md` | 7 | ✅ Complete |
| `skills/opencode-skill-creation/SKILL.md` | 6 | ✅ Complete |
| `SKILLS_IMPLEMENTATION.md` | 7 | ✅ Complete |
| `README.md` | 2 | ✅ Complete |
| `CHANGELOG.md` | 1 | ✅ Complete |

---

## Implementation Phases

### Phase 1: Update .AGENTS.md (Core Policy) ✅ COMPLETE
- [x] Remove `build-with-skills` and `plan-with-skills` from Task Type → Agent table
- [x] Update Delegation Decision Tree (7 steps)
- [x] Update Routing Priority section (5 steps with skill match)
- [x] Rename "Primary Agents" to "Default Agent"
- [x] Add Skill Matching Fallback section
- [x] Add Parallel Task Execution section with:
  - Decision process
  - Dependency detection rules table
  - Max 3-5 parallel subagents
  - User confirmation requirement
  - Task list sources (prompt or PLAN*.md)

### Phase 2: Update opencode-skills-maintainer/SKILL.md ✅ COMPLETE
- [x] Remove agent prompt update functionality
- [x] Remove all `build-with-skills` and `plan-with-skills` references
- [x] Repurpose as Skill Consistency Validator
- [x] Keep skill scanning and validation
- [x] Update verification commands

### Phase 3: Update opencode-skill-creation/SKILL.md ✅ COMPLETE
- [x] Remove Step 8 (Update Agents section)
- [x] Remove agent update commands
- [x] Update verification commands
- [x] Update troubleshooting section

### Phase 4: Update Documentation Files ✅ COMPLETE
- [x] Update SKILLS_IMPLEMENTATION.md - remove agent references
- [x] Update README.md - remove agent descriptions
- [x] Update CHANGELOG.md - remove reference

### Phase 5: Validation & Testing ✅ COMPLETE
- [x] Verify all 26 occurrences removed
- [x] Verify no broken references remain
- [x] Skill loading works correctly
- [x] JSON validity maintained

---

## Technical Specifications

### New Delegation Decision Tree
```
1. Does task match routing pattern? → Delegate to matching subagent
2. Is task within subagent's domain? → Delegate to that subagent
3. Multiple subagents applicable? → Delegate to most specific one
4. No subagent match? → Analyze for skill match
5. Skill found? → Load and execute skill workflow
6. Multiple independent tasks? → Ask user confirmation, then execute in parallel
7. No skill match? → Handle directly with available tools
```

### Parallel Execution Configuration
- **Mode**: Manual (user confirmation required)
- **Max Subagents**: 3-5 (avoid resource exhaustion)
- **Task Sources**: User prompt OR PLAN*.md files when explicitly referenced

### Dependency Detection Rules
| Dependency Type | Example | Must Wait For |
|-----------------|---------|---------------|
| File creation | "Edit auth.ts" | "Create auth.ts" |
| Test execution | "Run tests" | "Write tests", "Implement feature" |
| Documentation | "Update README" | "Implement feature" |
| Build/deploy | "Deploy to EKS" | "Run tests", "Build image" |
| Lint/format | "Lint code" | "Write code" |

### Skill Matching Examples
| User Prompt | Skill Match | Reason |
|-------------|-------------|--------|
| "create a Next.js app" | `nextjs-standard-setup` | Matches nextjs* and setup* |
| "generate Python tests" | `python-pytest-creator` | Matches python* and test* |
| "lint TypeScript code" | `javascript-eslint-linter` | Matches lint* and TypeScript |

---

## Risks & Mitigation
- **Risk**: Breaking existing workflows that depend on primary agents
  - **Mitigation**: Skills and subagents handle all delegated work
- **Risk**: Parallel execution causing conflicts
  - **Mitigation**: Dependency detection and max 3-5 limit
- **Risk**: User confusion with confirmation prompts
  - **Mitigation**: Clear messaging about parallel execution benefits

## Success Metrics
- [x] All primary agent references removed
- [x] Skill-based delegation documented
- [x] Parallel execution policy documented
- [x] No regression in existing functionality

## Conclusion

**Issue #71 is RESOLVED.** All implementation phases complete:
- 6 files modified
- 26 occurrences removed
- Skill-based fallback logic implemented
- Parallel task execution policy documented
