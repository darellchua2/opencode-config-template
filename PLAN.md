# Plan: Add C# and Java linter skills to the framework

## Overview
This issue implements the addition of C# and Java linter skills to the OpenCode framework to extend code quality support to these popular programming languages, following the same patterns as existing linter skills (python-ruff-linter, javascript-eslint-linter).

## Ticket Reference
- Issue: #49
- URL: https://github.com/darellchua2/opencode-config-template/issues/49
- Labels: enhancement (via git-issue-labeler)

## Files to Create
1. `skills/csharp-linter/SKILL.md` - C# linter skill definition
2. `skills/java-linter/SKILL.md` - Java linter skill definition

## Files to Modify
1. `config.json` - Update build-with-skills and plan-with-skills agents with new skills (via opencode-skills-maintainer)
2. `README.md` - Document new skills (optional, if applicable)
3. `AGENTS.md` - Update agent guidelines if needed

## Approach

### Phase 1: Research and Analysis
- Review existing linter skills (python-ruff-linter, javascript-eslint-linter) for structure and patterns
- Identify appropriate linting tools for C#:
  - Consider: Roslyn Analyzers, StyleCop, dotnet format
  - Evaluate tool maturity, community adoption, and ease of use
- Identify appropriate linting tools for Java:
  - Consider: Checkstyle, PMD, SpotBugs
  - Evaluate tool maturity, community adoption, and ease of use
- Determine tool-specific configuration and installation requirements

### Phase 2: C# Linter Skill Implementation
- Create `skills/csharp-linter/SKILL.md` following SKILL.md format:
  - Include frontmatter (name, description, license, compatibility, metadata)
  - Document "What I do", "When to use me", "Prerequisites"
  - Document "Steps" for C# linting workflow
  - Include "Best Practices" and "Common Issues"
  - Add troubleshooting and verification commands
- Ensure skill extends `linting-workflow` framework
- Include tool-specific instructions and auto-fix capabilities
- Add examples of C# linting scenarios

### Phase 3: Java Linter Skill Implementation
- Create `skills/java-linter/SKILL.md` following SKILL.md format:
  - Include frontmatter (name, description, license, compatibility, metadata)
  - Document "What I do", "When to use me", "Prerequisites"
  - Document "Steps" for Java linting workflow
  - Include "Best Practices" and "Common Issues"
  - Add troubleshooting and verification commands
- Ensure skill extends `linting-workflow` framework
- Include tool-specific instructions and auto-fix capabilities
- Add examples of Java linting scenarios

### Phase 4: Integration and Testing
- Run `opencode-skills-maintainer` skill to update build-with-skills and plan-with-skills agents
- Verify agents have the new skills in their available skills lists:
  ```bash
  jq '.agent["build-with-skills"].prompt' config.json | grep "csharp-linter"
  jq '.agent["plan-with-skills"].prompt' config.json | grep "java-linter"
  ```
- Test skill invocation with sample C# and Java projects (if available)
- Verify skills follow existing patterns and work correctly with linting-workflow framework

### Phase 5: Documentation and Validation
- Update README.md with new skills documentation (if applicable)
- Validate SKILL.md format compliance
- Ensure all skills follow OpenCode skill best practices
- Test setup script to ensure skills are copied correctly

## Success Criteria
- [ ] `skills/csharp-linter/SKILL.md` created with proper structure and content
- [ ] `skills/java-linter/SKILL.md` created with proper structure and content
- [ ] Both skills extend `linting-workflow` framework
- [ ] Skills include tool-specific instructions, best practices, and troubleshooting
- [ ] Skills handle auto-fix and error resolution (via linting-workflow)
- [ ] build-with-skills and plan-with-skills agents updated via opencode-skills-maintainer
- [ ] Skills appear in agents' available skills lists
- [ ] Documentation updated (README.md or other relevant docs)
- [ ] JSON syntax validated: `jq . config.json`
- [ ] Skills follow same patterns as python-ruff-linter and javascript-eslint-linter
- [ ] No existing linting skills are broken or modified

## Notes
- Both new linter skills should follow the exact same structure as existing linter skills
- Use the `linting-workflow` framework as the foundation for both skills
- Ensure tools are widely adopted and well-maintained in their respective communities
- Consider IDE integration compatibility (VS Code for C#, IntelliJ IDEA for Java)
- Include clear installation and configuration instructions
- Maintain consistency with existing skill documentation style

## Dependencies
- [ ] `linting-workflow` framework available in skills/ directory (already exists)
- [ ] C# linting tool selected and documented (Roslyn Analyzers recommended)
- [ ] Java linting tool selected and documented (Checkstyle or PMD recommended)
- [ ] `opencode-skills-maintainer` skill available for agent updates (already exists)

## Risks
- **Tool Selection Risk**: Choosing tools that may become unmaintained
  - Mitigation: Select widely-adopted, community-backed tools with active development
- **Integration Complexity**: Tools may require complex configuration
  - Mitigation: Start with basic configurations and document advanced options
- **Framework Compatibility**: New skills must work seamlessly with linting-workflow
  - Mitigation: Follow existing skill patterns closely, test thoroughly
- **Agent Update Failure**: opencode-skills-maintainer may not update agents correctly
  - Mitigation: Verify agent prompts manually, update if needed

## Testing Plan
1. Verify SKILL.md files are syntactically correct (YAML frontmatter, markdown content)
2. Test skill invocation with `opencode --agent build-with-skills "Use csharp-linter skill"`
3. Test skill invocation with `opencode --agent build-with-skills "Use java-linter skill"`
4. Verify agents have new skills in their prompts
5. Test with sample C# and Java projects (if available)
6. Validate that no existing skills are affected

## References
- Existing Python linter: `skills/python-ruff-linter/SKILL.md`
- Existing JavaScript linter: `skills/javascript-eslint-linter/SKILL.md`
- Linting framework: `skills/linting-workflow/SKILL.md`
- Skill maintenance: `skills/opencode-skills-maintainer/SKILL.md`
