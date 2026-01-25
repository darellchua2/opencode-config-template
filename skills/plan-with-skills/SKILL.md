---
name: plan-with-skills
description: Creates skill-prioritized PLAN.md files by identifying relevant skills and incorporating skill-based workflows
license: Apache-2.0
compatibility: opencode
metadata:
  audience: developers
  workflow: planning
---

## What I do

I create skill-prioritized PLAN.md files by analyzing tasks, identifying relevant skills, and incorporating skill-based workflows. My approach ensures that the planning phase is as skill-aware as the Build-With-Skills agent is for the building phase.

### Core Process

1. **Analyze User's Request**: Determine task type and requirements
2. **Find Matching Skills**: Search through available framework and specialized skills
3. **Prioritize Skills**: Select primary and supporting skills with rationale
4. **Generate PLAN.md**: Create a comprehensive plan with skill-based structure
5. **Document Handoff**: Provide clear criteria for transitioning to Build-With-Skills

## When to use me

Use this agent when:
- You need to create a PLAN.md for a new development task
- You want to ensure your plan leverages existing best practices
- You need to identify which skills to use before building
- You want a skill-first planning approach (similar to Build-With-Skills for execution)
- You're starting a task and need guidance on which workflows to follow

**Key Difference**: Unlike Build-With-Skills (which executes skills), I focus on **planning** with skills. Use me to create the plan, then invoke Build-With-Skills to execute it.

## Prerequisites

- OpenCode framework installed and configured
- Available skills in the skills/ directory
- Clear understanding of the task at hand
- Git repository initialized (optional, for PLAN.md commits)

## Steps

### Step 1: Analyze the Task

**Purpose**: Understand the task requirements and identify keywords

**Analysis Checklist**:
- What is the task type? (test generation, PR creation, JIRA workflow, linting, etc.)
- What are the key requirements?
- What is the expected outcome?
- Are there any constraints or dependencies?

**Example Keywords**:
- "test", "pytest", "unit test" → test-generator-framework
- "PR", "pull request", "merge" → pr-creation-workflow, git-pr-creator
- "JIRA", "ticket", "issue" → jira-git-integration, jira-git-workflow
- "lint", "format", "style" → linting-workflow, python-ruff-linter, javascript-eslint-linter
- "Next.js", "React", "frontend" → nextjs-pr-workflow, nextjs-unit-test-creator

### Step 2: Find Matching Skills

**Purpose**: Identify the most relevant skills from the available pool

**Framework Skills** (use as base):
```bash
# List available framework skills
ls skills/ | grep -E "workflow|framework"
```

- **test-generator-framework**: For generating tests in any language
- **jira-git-integration**: For JIRA-specific operations
- **pr-creation-workflow**: For generic pull request workflows
- **ticket-branch-workflow**: For ticket-to-branch-to-PLAN patterns
- **linting-workflow**: For multi-language linting

**Specialized Skills** (use for specific tasks):
```bash
# List specialized skills
ls skills/ | grep -v -E "workflow|framework"
```

- **ascii-diagram-creator**: For ASCII diagrams
- **git-issue-creator**: GitHub issues with tag detection
- **git-pr-creator**: GitHub pull requests
- **jira-git-workflow**: JIRA ticket + branch + PLAN
- **nextjs-pr-workflow**: Next.js PR with JIRA integration
- **nextjs-unit-test-creator**: Next.js unit/E2E tests
- **opencode-agent-creation**: Creating OpenCode agents
- **opencode-skill-creation**: Creating OpenCode skills
- **python-pytest-creator**: Python pytest tests
- **python-ruff-linter**: Python linting with Ruff
- **typescript-dry-principle**: TypeScript DRY refactoring

### Step 3: Prioritize Skills

**Purpose**: Select primary and supporting skills with clear rationale

**Skill Selection Criteria**:

| Task Type | Primary Skill | Supporting Skills |
|-----------|---------------|-------------------|
| Test generation | test-generator-framework | python-pytest-creator, nextjs-unit-test-creator |
| PR creation | pr-creation-workflow | git-pr-creator, nextjs-pr-workflow |
| JIRA operations | jira-git-integration | jira-git-workflow |
| GitHub issues | git-issue-creator | ticket-branch-workflow |
| Linting | linting-workflow | python-ruff-linter, javascript-eslint-linter |
| Next.js app | nextjs-standard-setup | nextjs-unit-test-creator, nextjs-pr-workflow |
| OpenCode meta | opencode-agent-creation | opencode-skill-creation |

**Prioritization Logic**:
1. **Primary Skill**: The skill that directly addresses the core requirement
2. **Supporting Skills**: Skills that enhance or complement the primary skill
3. **Rationale**: Explain why each skill was selected
4. **Compatibility**: Ensure skills can work together without conflicts

### Step 4: Generate PLAN.md

**Purpose**: Create a comprehensive PLAN.md with skill-prioritized structure

**PLAN.md Template**:
```markdown
# Plan: [Task Title]

## Overview
[Brief description of what this task implements]

## Ticket Reference
- Ticket: <TICKET-KEY>
- URL: <ticket-url>

## Skills to Use
### Primary Skill
- **Skill Name**: [skill-name]
- **Rationale**: [Why this skill is primary for this task]

### Supporting Skills
- **Skill Name**: [skill-name] - [How it supports the primary skill]
- **Skill Name**: [skill-name] - [How it supports the primary skill]

## Files to Modify
1. `src/path/to/file1.ts` - Description of changes
2. `src/path/to/file2.tsx` - Description of changes
3. `config.json` - Configuration updates (if applicable)

## Approach (Based on Skills)
### Step 1: [Primary Skill Workflow]
[Detailed steps using primary skill]
- Use `skill-name` to accomplish X
- Follow skill's workflow for Y

### Step 2: [Supporting Skill Workflow]
[Detailed steps using supporting skill]
- Apply `skill-name` to accomplish Z
- Integrate with primary skill output

### Step 3: [Integration and Testing]
[How skills work together]
- Ensure compatibility between skill outputs
- Run validation checks

## Handoff to Build-With-Skills
[Clear criteria for transitioning to building phase]

After PLAN.md is created:
1. Invoke Build-With-Skills with this plan
2. Build-With-Skills will execute the skills identified above
3. Monitor skill execution and report progress

## Success Criteria
- [ ] Primary skill executed successfully
- [ ] Supporting skills integrated properly
- [ ] All files modified correctly
- [ ] Tests pass (if applicable)
- [ ] Code is linted and follows standards
- [ ] Documentation updated (if applicable)

## Related Work
- **Build-With-Skills**: Will execute the skills in this plan
- **Primary Skill**: [skill-name]
- **Supporting Skills**: [skill-name], [skill-name]
```

**Implementation**:
```bash
# Create PLAN.md
cat > PLAN.md <<'EOF'
[Paste template with task-specific content]
EOF

echo "✅ Created PLAN.md"
```

### Step 5: Document Handoff to Build-With-Skills

**Purpose**: Provide clear transition criteria to the building phase

**Handoff Criteria**:
1. **PLAN.md is Complete**: All sections populated, skills identified
2. **Skills are Prioritized**: Primary and supporting skills with rationale
3. **Approach is Clear**: Step-by-step instructions using skills
4. **Success Criteria Defined**: Measurable outcomes listed
5. **Handoff Instructions**: Clear directive to invoke Build-With-Skills

**Handoff Message Template**:
```markdown
---

## Handoff to Build-With-Skills

This PLAN.md is ready for the building phase. Invoke Build-With-Skills with:

```
opencode --agent build-with-skills "Follow the PLAN.md for this task"
```

**Expected Execution Flow**:
1. Build-With-Skills will read this PLAN.md
2. It will identify the skills listed in "Skills to Use"
3. It will execute skills in the order specified in "Approach"
4. It will validate against the "Success Criteria"
5. It will report completion and next steps

---

```

## Best Practices

### Skill Identification
- **Start Broad**: Use framework skills for general categories
- **Narrow Down**: Apply specialized skills for specific requirements
- **Check Compatibility**: Ensure skills can work together
- **Document Rationale**: Always explain why skills were selected

### PLAN.md Structure
- **Skills First**: Always start with "Skills to Use" section
- **Clear Hierarchy**: Distinguish between primary and supporting skills
- **Skill-Based Approach**: Structure the "Approach" around skill execution
- **Explicit Handoff**: Make the transition to Build-With-Skills unmistakable

### Planning Quality
- **Specific and Actionable**: Each step should be implementable
- **Measurable Success**: Criteria should be testable
- **Realistic Timeline**: Consider skill complexity and integration
- **Dependencies Clear**: List any prerequisites or constraints

### Integration with Build-With-Skills
- **Complementary Roles**: Plan-With-Skills plans, Build-With-Skills builds
- **Shared Vocabulary**: Use consistent skill names and terminology
- **Clear Transition**: Handoff should be explicit and immediate
- **No Overlap**: Don't duplicate skill execution logic

## Common Issues

### No Skills Match

**Issue**: Cannot find relevant skills for the task

**Solution**:
1. Re-analyze the task for broader keywords
2. Check if a framework skill applies as a base
3. Fall back to default planning approach:
   ```markdown
   ## Skills to Use
   ### Primary Approach
   - **Method**: Default planning approach
   - **Rationale**: No specific skills identified for this task

   ### Supporting Skills
   - **linting-workflow** - To ensure code quality during implementation
   - **test-generator-framework** - To add tests if applicable
   ```

### Multiple Skills Match

**Issue**: Several skills seem equally relevant

**Solution**: List all with priorities and rationale:
```markdown
## Skills to Use
### Primary Skill Options
- **Option A**: test-generator-framework
  - **Rationale**: Generic test generation, works for any language
  - **Pros**: Flexible, widely applicable
  - **Cons**: Less specialized than language-specific skills

- **Option B**: python-pytest-creator
  - **Rationale**: Specialized for Python pytest tests
  - **Pros**: Python-specific best practices, comprehensive
  - **Cons**: Only works for Python projects

**Recommendation**: Use **Option B** (python-pytest-creator) since this is a Python project

### Supporting Skills
- **linting-workflow** - Ensure code quality
```

### Skills Conflict

**Issue**: Selected skills have conflicting requirements

**Solution**:
1. Re-evaluate skill compatibility
2. Prioritize based on task requirements
3. Document conflict and resolution:
   ```markdown
   ### Skill Conflict Resolution
   **Conflict**: Both `linting-workflow` and `python-ruff-linter` apply

   **Resolution**: Use `python-ruff-linter` as primary because:
   - Task is Python-specific
   - Ruff is faster and more modern
   - `linting-workflow` will be used as fallback if Ruff fails
   ```

### Build-With-Skills Confusion

**Issue**: Unclear how to transition to building phase

**Solution**: Make handoff explicit:
```markdown
## Handoff to Build-With-Skills

**Immediate Action**: Invoke Build-With-Skills now with:
```bash
opencode --agent build-with-skills "Implement following PLAN.md"
```

**What Build-With-Skills Will Do**:
1. Read this PLAN.md
2. Load the skills: [skill-name], [skill-name]
3. Execute skills in the order specified below
4. Validate against success criteria
5. Report completion

**Do Not**: Start building manually - let Build-With-Skills execute the skills
```

## Troubleshooting Checklist

Before creating PLAN.md:
- [ ] Task requirements are clear
- [ ] Task type is identified
- [ ] Key keywords are extracted
- [ ] Available skills are listed

During skill selection:
- [ ] Primary skill is identified
- [ ] Supporting skills are identified
- [ ] Rationale is documented for each skill
- [ ] Skill compatibility is verified

During PLAN.md creation:
- [ ] Skills section is prioritized
- [ ] Approach is skill-based
- [ ] Success criteria are measurable
- [ ] Handoff is explicit

After PLAN.md creation:
- [ ] PLAN.md follows the template
- [ ] All sections are populated
- [ ] Handoff to Build-With-Skills is clear
- [ ] Document is ready for building phase

## Example Usage

### Example 1: Test Generation Task

**User Request**: "Create unit tests for the user authentication module"

**Skills Identified**:
- Primary: test-generator-framework
- Supporting: python-pytest-creator (if Python project)

**PLAN.md Structure**:
```markdown
## Skills to Use
### Primary Skill
- **Skill Name**: test-generator-framework
- **Rationale**: Generic framework for generating comprehensive unit tests

### Supporting Skills
- **python-pytest-creator** - Provides Python-specific pytest patterns and best practices

## Approach (Based on Skills)
### Step 1: Load test-generator-framework
Use the framework to identify test requirements:
- Functions to test
- Edge cases
- Mock scenarios

### Step 2: Apply python-pytest-creator
Generate Python-specific pytest tests using the framework's requirements:
- Use pytest fixtures
- Apply parameterized testing
- Include assertions for all scenarios
```

### Example 2: JIRA Workflow Task

**User Request**: "Create a JIRA ticket for this bug and set up the branch"

**Skills Identified**:
- Primary: jira-git-workflow (full ticket+branch+PLAN workflow)
- Supporting: jira-git-integration (for JIRA operations)

**PLAN.md Structure**:
```markdown
## Skills to Use
### Primary Skill
- **Skill Name**: jira-git-workflow
- **Rationale**: Provides complete JIRA ticket creation, branching, and PLAN workflow

### Supporting Skills
- **jira-git-integration** - Handles specific JIRA operations within the workflow

## Approach (Based on Skills)
### Step 1: Execute jira-git-workflow
Follow the workflow to:
1. Identify JIRA project
2. Create JIRA ticket with proper issue type
3. Create git branch from ticket
4. Generate initial PLAN.md
```

### Example 3: Next.js PR Task

**User Request**: "Create a pull request for this Next.js feature"

**Skills Identified**:
- Primary: nextjs-pr-workflow
- Supporting: nextjs-unit-test-creator, linting-workflow

**PLAN.md Structure**:
```markdown
## Skills to Use
### Primary Skill
- **Skill Name**: nextjs-pr-workflow
- **Rationale**: Specialized for Next.js PRs with JIRA integration

### Supporting Skills
- **nextjs-unit-test-creator** - Add unit tests for the feature
- **linting-workflow** - Ensure code follows Next.js and TypeScript standards

## Approach (Based on Skills)
### Step 1: Use nextjs-pr-workflow
Follow the workflow to create PR with JIRA integration

### Step 2: Apply nextjs-unit-test-creator
Generate comprehensive unit tests for the feature

### Step 3: Run linting-workflow
Ensure code quality before PR submission
```

## Related Skills

### Framework Skills
- **test-generator-framework**: For generating tests
- **jira-git-integration**: For JIRA operations
- **pr-creation-workflow**: For PR workflows
- **ticket-branch-workflow**: For ticket-to-branch patterns
- **linting-workflow**: For code quality

### Specialized Skills
- **ascii-diagram-creator**: For creating diagrams in plans
- **git-issue-creator**: For GitHub issues
- **git-pr-creator**: For GitHub PRs
- **nextjs-pr-workflow**: For Next.js-specific PRs
- **opencode-agent-creation**: For creating agents
- **opencode-skill-creation**: For creating skills

### Complementary Agents
- **Build-With-Skills**: Executes the skills identified in the plan
- **Explore**: For codebase exploration during planning
- **Diagram-Creator**: For creating visual diagrams in PLAN.md

## Validation Commands

```bash
# Test agent invocation
opencode --agent plan-with-skills "Create a plan for adding tests to user authentication"

# Verify PLAN.md structure
cat PLAN.md | grep -E "## Skills to Use|## Approach|## Handoff to Build-With-Skills"

# Check if skills are listed
cat PLAN.md | grep -A 10 "## Skills to Use"
```

## Output Format

Always provide:
1. **Skills Summary**: List of skills with their roles
2. **PLAN.md**: Complete skill-prioritized plan document
3. **Handoff Instructions**: Clear directive to invoke Build-With-Skills
4. **Next Steps**: Guidance for the building phase

**Example Output**:
```
I've identified the following skills for your task:

**Primary Skill**: test-generator-framework
- Rationale: Provides comprehensive test generation framework for any language

**Supporting Skills**:
- python-pytest-creator: Python-specific pytest patterns
- linting-workflow: Ensure code quality

I've created PLAN.md with a skill-prioritized structure.

**Next Step**: Invoke Build-With-Skills to execute the skills:
```bash
opencode --agent build-with-skills "Follow the PLAN.md"
```

Build-With-Skills will:
1. Load test-generator-framework
2. Apply python-pytest-creator for Python-specific tests
3. Run linting-workflow for code quality
4. Validate against success criteria
```
