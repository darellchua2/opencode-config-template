# Plan: Clean up skills and add proper subagents

## Issue Reference
- **Number**: #66
- **URL**: https://github.com/darellchua2/opencode-config-template/issues/66
- **Labels**: enhancement

## Overview
Refactor and organize the skills structure, ensuring proper subagent configurations with correct tool restrictions and routing rules.

## Acceptance Criteria
- [x] Review and clean up existing skills in skills/ directory
- [x] Ensure all subagents have proper tool restrictions defined
- [x] Validate subagent routing rules in AGENTS.md
- [x] Remove duplicate or redundant skills (documented as intentional)
- [x] Add missing subagent configurations where needed
- [x] Document subagent tool access levels clearly

## Scope
- `skills/` directory
- `.AGENTS.md` subagent routing rules
- `config.json` agent definitions
- Subagent tool restrictions and permissions

---

## Implementation Phases

### Phase 1: Analysis & Inventory ✅
- [x] List all existing skills in skills/ directory
- [x] Identify duplicate or overlapping skills
- [x] Review current subagent definitions in config.json
- [x] Audit AGENTS.md routing rules for completeness
- [x] Document current state and gaps

### Phase 2: Skill Cleanup ✅
- [x] Remove or merge duplicate skills (documented as intentional)
- [x] Update skill descriptions and metadata
- [x] Ensure consistent skill structure across all files
- [x] Validate skill prerequisites and dependencies
- [x] Test skill loading for each subagent type

### Phase 3: Subagent Configuration ✅
- [x] Review tool restrictions for each subagent
- [x] Ensure MCP server access is properly scoped
- [x] Add missing subagent definitions if needed (opencode-tooling-subagent added)
- [x] Validate skill isolation per subagent type
- [x] Update permission filters in config.json

### Phase 4: Documentation & Validation ✅
- [x] Update AGENTS.md with final subagent rules
- [x] Document tool access levels clearly
- [x] Add examples for each subagent type
- [x] Create troubleshooting guide (ANALYSIS.md)
- [x] Test routing patterns work correctly

### Phase 5: Final Review ✅
- [x] Verify all acceptance criteria met
- [x] Ensure backward compatibility
- [x] Review with stakeholder

### Phase 6: Framework Restructuring ✅ (Added)
- [x] Create 5 new framework skills (opentofu, git, jira, tooling, coverage)
- [x] Update 19 existing skills to extend frameworks
- [x] Add `extends` metadata to skill frontmatter
- [x] Update subagent permissions for new frameworks
- [x] Document framework → extension pattern in SKILL_RESTRUCTURE.md

---

## Technical Notes
- Follow subagent tool restriction patterns from AGENTS.md
- Ensure MCP server access is properly scoped per subagent
- Validate skill isolation for each subagent type
- Maintain backward compatibility with existing workflows

## Dependencies
- None identified

## Risks & Mitigation
- **Risk**: Breaking existing subagent functionality
  - **Mitigation**: Test each subagent after changes, maintain rollback capability
- **Risk**: Missing tool restrictions causing security issues
  - **Mitigation**: Review against AGENTS.md specification carefully

## Success Metrics
- All skills have clear, non-overlapping purposes
- Subagents have correct tool restrictions
- Routing rules are comprehensive and documented
- No duplicate functionality across skills
