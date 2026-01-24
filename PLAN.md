# Plan: Create OpenCode Skill Auditor for Modularization and Optimization

## Overview
This issue implements the opencode-skill-auditor skill to analyze existing OpenCode skills for redundancy, overlap, and opportunities for modularization. The skill will identify granular functionality that can be extracted into reusable components following DRY principles.

## Ticket Reference
- Issue: #34
- URL: https://github.com/darellchua2/opencode-config-template/issues/34
- Labels: enhancement, documentation

## Files to Modify
1. `skills/opencode-skill-auditor/SKILL.md` - Main skill definition (already created)
2. `README.md` - Update to include skill auditor documentation
3. `AGENTS.md` - Add skill auditor guidelines if needed
4. `config.json` - Add skill auditor agent configuration

## Approach
### Phase 1: Skill Implementation
- Review existing skill auditor implementation
- Ensure skill follows OpenCode best practices
- Validate skill metadata and structure

### Phase 2: Skill Audit Execution
- Run skill auditor against existing skills directory
- Identify redundant functionality and overlap
- Document opportunities for modularization

### Phase 3: Documentation Updates
- Update README.md with skill auditor information
- Create examples of modular skill architecture
- Document best practices for skill creation

### Phase 4: Integration
- Test skill auditor in workflow
- Validate audit results
- Implement feedback mechanisms

## Success Criteria
- [ ] Skill auditor implementation is complete and functional
- [ ] Skill audit identifies at least 3 areas for modularization
- [ ] Documentation is updated with skill auditor usage
- [ ] All existing skills pass audit validation
- [ ] Skill auditor follows OpenCode framework guidelines

## Notes
This is part of a broader initiative to improve the OpenCode skill ecosystem. The skill auditor will help maintain clean, modular, and reusable skill architecture following DRY principles.

## Dependencies
- OpenCode framework v2.0+
- Existing skills in skills/ directory
- Valid config.json schema compliance

## Risks
- Risk: Skill auditor may generate false positives for redundancy
  Mitigation: Include manual review process in audit workflow
- Risk: Modularization may break existing skill dependencies
  Mitigation: Implement backward compatibility testing before refactoring

## Next Steps
1. Review skill auditor implementation
2. Execute audit on existing skills
3. Create modularization plan
4. Implement identified improvements
5. Update documentation