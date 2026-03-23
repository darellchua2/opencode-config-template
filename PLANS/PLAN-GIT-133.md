# Plan: Update .AGENTS.md with skill-broker pattern and convert skill-broker-subagent to skills/ format

## Issue Reference
- **Number**: #133
- **URL**: https://github.com/darellchua2/opencode-config-template/issues/133
- **Labels**: enhancement

## Overview
Integrate the skill-broker pattern from `AGENTS_to_add.md` into `.AGENTS.md` and convert `skill-broker-subagent.md` to be compatible with the `skills/` directory format.

## Acceptance Criteria
- [ ] `.AGENTS.md` updated with primary agent pattern from `AGENTS_to_add.md`
- [ ] `skill-broker-subagent.md` converted to `skills/skill-broker/SKILL.md` format
- [ ] `setup.sh` updated with new skill listing and count
- [ ] `setup.ps1` updated with new skill listing and count
- [ ] `README.md` updated with new skill in appropriate category
- [ ] All changes follow existing patterns and conventions

## Scope
- `.AGENTS.md` - Target file to update with primary agent pattern
- `AGENTS_to_add.md` - Source content for the updates
- `skill-broker-subagent.md` - Current location, needs conversion
- `skills/` - Target directory for converted skill
- `setup.sh`, `setup.ps1`, `README.md` - Documentation sync updates

---

## Implementation Phases

### Phase 1: Setup & Analysis
- [ ] Review `AGENTS_to_add.md` for primary agent pattern content
- [ ] Review current `.AGENTS.md` to understand existing structure
- [ ] Review `skill-broker-subagent.md` for conversion source
- [ ] Review existing `skills/*/SKILL.md` files for format reference
- [ ] Review `setup.sh`, `setup.ps1`, and `README.md` for sync requirements

### Phase 2: Update .AGENTS.md
- [ ] Incorporate primary agent role definition (delegate, don't execute)
- [ ] Add intent parsing workflow
- [ ] Add skill-broker invocation pattern (always use skill-broker before delegating)
- [ ] Add delegation to specialist workflow
- [ ] Add skills table reference
- [ ] Add tone and style guidelines
- [ ] Ensure existing content is preserved or properly merged

### Phase 3: Convert skill-broker-subagent to skills/ format
- [ ] Create `skills/skill-broker/SKILL.md` directory structure
- [ ] Convert content to SKILL.md format matching existing skills
- [ ] Ensure all relevant instructions from the subagent are preserved
- [ ] Validate skill format follows project conventions

### Phase 4: Documentation Sync
- [ ] Increment total skill count in `setup.sh`
- [ ] Add skill to appropriate category in `setup.sh`
- [ ] Increment total skill count in `setup.ps1`
- [ ] Add skill to appropriate category in `setup.ps1`
- [ ] Update `README.md` Skill Categories table with new skill
- [ ] Update total count in `README.md` intro paragraph

### Phase 5: Validation & Cleanup
- [ ] Run `setup.sh` dry-run to verify no errors
- [ ] Verify README.md formatting is correct
- [ ] Ensure all acceptance criteria are met
- [ ] Remove or archive original `skill-broker-subagent.md` if appropriate

---

## Technical Notes
- Follow the AGENTS.md "Files to Update" checklist for documentation sync
- The skill-broker acts as a routing layer - it should NOT execute tasks directly
- Maintain backward compatibility with existing agent/skill invocations

## Dependencies
- `AGENTS_to_add.md` must exist and contain the primary agent pattern
- `skill-broker-subagent.md` must exist for conversion

## Risks & Mitigation
- **Risk**: Merging content into `.AGENTS.md` may conflict with existing instructions
  - **Mitigation**: Carefully merge, preserving existing essential instructions
- **Risk**: Skill format conversion may lose nuance from subagent format
  - **Mitigation**: Review all content and preserve critical behavior rules

## Success Metrics
- `.AGENTS.md` includes all pattern elements from `AGENTS_to_add.md`
- `skills/skill-broker/SKILL.md` follows same format as other skills
- All 4 documentation files are updated and consistent
- Setup scripts run without errors
