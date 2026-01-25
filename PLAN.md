# Plan: Create Plan-With-Skills Agent/Skill

## Overview
Create a new agent/skill called "Plan-With-Skills" that prioritizes using available skills when creating PLAN.md files. This agent will ensure that the planning phase is as skill-aware as the existing Build-With-Skills agent is for the building phase.

## Ticket Reference
- **Ticket**: IBIS-109
- **URL**: https://betekk.atlassian.net/browse/IBIS-109

## Background
Currently, the default OpenCode planning approach (via the `PLAN.md` setup) doesn't prioritize using skills during planning. The Build-With-Skills agent successfully implements a skill-first approach for execution, but the planning phase lacks this prioritization. This can lead to:
- Plans that don't leverage existing best practices and workflows
- Missing opportunities to use specialized skills (test-generator-framework, jira-git-integration, etc.)
- Inconsistent planning approaches across different tasks
- Plans that need to be revised when skills are later discovered

## Requirements

### Core Functionality
1. **Analyze User's Request**: Determine the task type and identify relevant skills
2. **Find Matching Skills**: Search through available skills:
   - Framework Skills (test-generator-framework, jira-git-integration, pr-creation-workflow, ticket-branch-workflow, linting-workflow)
   - Specialized Skills (ascii-diagram-creator, git-issue-creator, git-pr-creator, nextjs-pr-workflow, etc.)
3. **Prioritize Skills**: Use skills as the primary driver for creating PLAN.md structure
4. **Generate PLAN.md**: Create a plan that incorporates skill-based workflows
5. **Document Skill Usage**: Clearly indicate which skills should be used and when

### Key Features
- **Skill-first planning approach**: Similar to Build-With-Skills, but for planning phase
- **Skill matching**: Intelligent matching between task requirements and available skills
- **Skill composition**: Support for combining multiple skills in a single plan
- **Clear handoff criteria**: Explicit instructions for transitioning to Build-With-Skills
- **Compatibility**: Works seamlessly with existing skill framework

### Agent Configuration (config.json)
Add new agent with:
- **name**: plan-with-skills
- **mode**: primary
- **description**: Creates skill-prioritized PLAN.md files by identifying relevant skills and incorporating skill-based workflows
- **prompt**: Detailed instructions covering:
  - Skill identification and matching
  - Plan structure with skill priorities
  - Handoff to Build-With-Skills
  - Error handling and fallback strategies
- **tools**: Read/glob/grep capabilities for exploring skills and codebase
- **mcp**: No specific MCP servers needed (uses existing skill framework)

## Files to Modify

### 1. config.json
- Add `plan-with-skills` agent definition
- Include comprehensive prompt with skill identification logic
- Set appropriate tool permissions (read-only for planning)

### 2. skills/plan-with-skills/SKILL.md
Create skill documentation following SKILL.md format:
```yaml
---
name: plan-with-skills
description: Creates skill-prioritized PLAN.md files by identifying relevant skills
license: Apache-2.0
compatibility: opencode
metadata:
  audience: developers
  workflow: planning
---
```

Content structure:
- "What I do", "When to use me", "Prerequisites"
- "Steps": Skill identification → Skill prioritization → PLAN.md generation
- "Best Practices": Skill-first planning, compatibility with Build-With-Skills
- "Common Issues": Skill conflicts, missing skills, etc.

### 3. AGENTS.md (Optional)
- Update agent guidelines if needed to include Plan-With-Skills workflow
- Document when to use Plan-With-Skills vs default planning

## Approach

### Phase 1: Agent Configuration (config.json)
1. Define agent structure with skill-prioritization logic
2. Create comprehensive prompt that:
   - Lists all available skills with categories
   - Provides skill selection criteria
   - Outlines PLAN.md template with skill sections
   - Includes examples of skill-based plans
3. Set tool permissions (read-only for planning phase)

### Phase 2: Skill Documentation (SKILL.md)
1. Follow SKILL.md format strictly
2. Document skill identification workflow
3. Provide examples of skill-prioritized plans
4. Include troubleshooting guide
5. Link to related skills (Build-With-Skills, ticket-branch-workflow)

### Phase 3: Integration Testing
1. Test with various task types (test generation, PR creation, JIRA workflows)
2. Verify skill matching accuracy
3. Ensure smooth handoff to Build-With-Skills
4. Validate PLAN.md quality and completeness

## PLAN.md Template Structure

The Plan-With-Skills agent should generate PLAN.md with:

```markdown
# Plan: [Task Title]

## Overview
[Brief description of task]

## Ticket Reference
[Ticket info if applicable]

## Skills to Use
### Primary Skill
- **Skill Name**: [skill-name]
- **Rationale**: [Why this skill is primary]

### Supporting Skills
- **Skill Name**: [skill-name] - [How it supports the plan]

## Files to Modify
[List files with descriptions]

## Approach (Based on Skills)
### Step 1: [Skill-based step]
[How to use specific skill]

### Step 2: [Skill-based step]
[How to use specific skill]

## Handoff to Build-With-Skills
[Clear criteria for when to transition to building]

## Success Criteria
[Specific, measurable criteria]
```

## Handoff Criteria to Build-With-Skills

The Plan-With-Skills agent should clearly indicate when to transition:

1. **Immediate Handoff**: After PLAN.md is created, invoke Build-With-Skills with the plan
2. **Skill Execution**: Build-With-Skills uses the skills identified in the plan
3. **Plan Adherence**: Build phase follows the skill-prioritized structure from planning

## Success Criteria

- [ ] Plan-With-Skills agent is added to config.json
- [ ] Agent can identify relevant skills for various task types
- [ ] Generated PLAN.md prioritizes skill usage with clear skill sections
- [ ] Integration with Build-With-Skills workflow is seamless
- [ ] SKILL.md documentation is complete and follows format
- [ ] Agent is testable with `opencode --agent plan-with-skills`
- [ ] Plans created are actionable and follow skill best practices

## Related Work

### Agents
- **Build-With-Skills**: Skill-first execution for coding/building phase (reference implementation)
- **Explore**: Codebase exploration agent (for understanding existing structure)

### Skills
- **ticket-branch-workflow**: Core workflow (branch → PLAN → commit)
- **test-generator-framework**: Test generation for multiple languages
- **jira-git-integration**: JIRA operations
- **pr-creation-workflow**: Pull request creation
- **opencode-skill-creation**: For creating this skill itself

### Frameworks
- OpenCode config schema: https://opencode.ai/config.json
- Skill documentation format: SKILL.md frontmatter requirements

## Implementation Notes

### Skill Identification Logic
The agent should:
1. Analyze task keywords (test, PR, JIRA, linting, etc.)
2. Match keywords to skill descriptions and workflows
3. Prioritize framework skills over specialized skills (or vice versa based on context)
4. Consider skill compatibility and composition

### Error Handling
- If no skills match: Fall back to default planning approach
- If multiple skills match: List all with priorities and rationale
- If skill fails during planning: Provide alternative skill options

### Compatibility
- Must work with existing Build-With-Skills agent
- Should not duplicate functionality of existing skills
- Should enhance, not replace, the planning workflow

## Timeline Estimate
- Phase 1 (config.json): 30 minutes
- Phase 2 (SKILL.md): 45 minutes
- Phase 3 (Testing): 30 minutes
- **Total**: ~2 hours

## Implementation Status

### ✅ Completed (Jan 25, 2026)

**Phase 1: Agent Configuration (config.json)**
- ✅ Added `plan-with-skills` agent definition
- ✅ Created comprehensive prompt with skill identification logic
- ✅ Set read-only tool permissions (read, glob, grep)
- ✅ Configured without MCP servers (uses existing skill framework)

**Phase 2: Skill Documentation (SKILL.md)**
- ✅ Created `skills/plan-with-skills/SKILL.md`
- ✅ Followed SKILL.md frontmatter format
- ✅ Documented skill identification workflow
- ✅ Provided examples of skill-prioritized plans
- ✅ Included troubleshooting guide
- ✅ Linked to related skills

**Phase 3: Integration Testing**
- ✅ Validated config.json syntax with `jq . config.json`
- ✅ Verified agent is listed in config
- ✅ Confirmed SKILL.md follows format
- ✅ Committed changes to branch IBIS-109
- ✅ Pushed to remote repository

**Files Modified**:
1. `config.json` - Added plan-with-skills agent
2. `skills/plan-with-skills/SKILL.md` - Created comprehensive skill documentation

**Git Commits**:
- `8475da5` - Implement Plan-With-Skills agent and skill

**Next Steps**:
- Test agent invocation: `opencode --agent plan-with-skills "Create a plan for [task]"`
- Update JIRA ticket with PR link when ready
- Consider adding to default_agent if desired
