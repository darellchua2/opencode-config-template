# Plan: Clean up skills and add proper subagents

## Issue Reference
- **Number**: #66
- **URL**: https://github.com/darellchua2/opencode-config-template/issues/66
- **Labels**: enhancement

## Overview
Refactor and organize the skills structure, ensuring proper subagent configurations with correct tool restrictions and routing rules.

## Acceptance Criteria
- [ ] Review and clean up existing skills in skills/ directory
- [ ] Ensure all subagents have proper tool restrictions defined
- [ ] Validate subagent routing rules in AGENTS.md
- [ ] Remove duplicate or redundant skills
- [ ] Add missing subagent configurations where needed
- [ ] Document subagent tool access levels clearly

## Scope
- `skills/` directory
- `.AGENTS.md` subagent routing rules
- `config.json` agent definitions
- Subagent tool restrictions and permissions

---

## Implementation Phases

### Phase 1: Analysis & Inventory
- [ ] List all existing skills in skills/ directory
- [ ] Identify duplicate or overlapping skills
- [ ] Review current subagent definitions in config.json
- [ ] Audit AGENTS.md routing rules for completeness
- [ ] Document current state and gaps

### Phase 2: Skill Cleanup
- [ ] Remove or merge duplicate skills
- [ ] Update skill descriptions and metadata
- [ ] Ensure consistent skill structure across all files
- [ ] Validate skill prerequisites and dependencies
- [ ] Test skill loading for each subagent type

### Phase 3: Subagent Configuration
- [ ] Review tool restrictions for each subagent
- [ ] Ensure MCP server access is properly scoped
- [ ] Add missing subagent definitions if needed
- [ ] Validate skill isolation per subagent type
- [ ] Update permission filters in config.json

### Phase 4: Documentation & Validation
- [ ] Update AGENTS.md with final subagent rules
- [ ] Document tool access levels clearly
- [ ] Add examples for each subagent type
- [ ] Create troubleshooting guide
- [ ] Test routing patterns work correctly

### Phase 5: Final Review
- [ ] Verify all acceptance criteria met
- [ ] Test subagent routing with sample tasks
- [ ] Ensure backward compatibility
- [ ] Review with stakeholder
- [ ] Update README if applicable

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
