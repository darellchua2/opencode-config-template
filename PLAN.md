# Plan: Refactor all skills and AGENTS.md to implement OpenCode best practices

## Overview

This issue implements a comprehensive refactor of all 30+ skills and AGENTS.md documentation to align with OpenCode best practices. The refactor focuses on standardizing documentation structure, adding comprehensive examples, troubleshooting checklists, and improving overall consistency while maintaining backward compatibility with existing OpenCode installations.

## Issue Reference

- Issue: #54
- URL: https://github.com/darellchua2/opencode-config-template/issues/54
- Labels: enhancement, documentation, good first issue

## Files to Modify

1. `AGENTS.md` - Expand with agent orchestration patterns, code quality principles, testing standards
2. `skills/linting-workflow/SKILL.md` - Add comprehensive examples and troubleshooting checklist
3. `skills/test-generator-framework/SKILL.md` - Add verification patterns and common issues
4. `skills/ticket-branch-workflow/SKILL.md` - Add step-by-step examples with outputs
5. `skills/pr-creation-workflow/SKILL.md` - Add quality check examples
6. `skills/git-issue-labeler/SKILL.md` - Add label detection examples
7. `skills/git-semantic-commits/SKILL.md` - Add commit message examples
8. `skills/git-issue-updater/SKILL.md` - Add issue update examples
9. `skills/python-pytest-creator/SKILL.md` - Add pytest-specific examples
10. `skills/nextjs-unit-test-creator/SKILL.md` - Add Next.js testing examples
11. `skills/python-ruff-linter/SKILL.md` - Add ruff linting examples
12. `skills/javascript-eslint-linter/SKILL.md` - Add ESLint examples
13. `skills/nextjs-pr-workflow/SKILL.md` - Add complete workflow examples
14. `skills/jira-git-integration/SKILL.md` - Add JIRA-specific examples
15. `skills/jira-git-workflow/SKILL.md` - Add end-to-end workflow examples
16. All other skills (15+ remaining) - Standardize structure and add missing sections

## Approach

### Phase 1: Skills Audit and Template Creation

1. **Audit Current Skills**
   - Review all 30+ skills for documentation completeness
   - Identify skills missing: "Common Issues", "Troubleshooting Checklist", "Related Skills"
   - Create spreadsheet tracking each skill's compliance status

2. **Create Comprehensive Skill Template**
   - Base template on git-issue-creator/SKILL.md (most complete)
   - Define required sections: frontmatter, "What I do", "When to use me", "Prerequisites", "Steps", "Examples", "Best Practices", "Common Issues", "Troubleshooting Checklist", "Related Skills"
   - Define formatting standards: code block language specifiers, example output formats, verification commands

### Phase 2: Skills Refactoring (Framework Skills First)

1. **Framework Skills** (Highest Priority - used by other skills)
   - `linting-workflow/SKILL.md` - Add comprehensive examples, verification commands
   - `test-generator-framework/SKILL.md` - Add testing patterns, coverage examples
   - `ticket-branch-workflow/SKILL.md` - Add workflow examples with outputs
   - `pr-creation-workflow/SKILL.md` - Add PR creation examples, quality checks
   - `git-issue-labeler/SKILL.md` - Add label detection examples, keyword matching
   - `git-semantic-commits/SKILL.md` - Add commit message examples
   - `git-issue-updater/SKILL.md` - Add issue update examples with formatting

2. **Enhance Framework Skills**
   - Add "Examples" section with 2-3 real-world use cases
   - Include expected outputs for all commands
   - Add verification commands to test skill functionality
   - Create troubleshooting checklists for before/after execution
   - Add "Related Skills" section linking framework dependencies

### Phase 3: Skills Refactoring (Specialized Skills)

1. **Language-Specific Test Generators**
   - `python-pytest-creator/SKILL.md` - Add pytest patterns, fixture examples
   - `nextjs-unit-test-creator/SKILL.md` - Add Next.js App Router testing examples
   - Maintain consistency with test-generator-framework

2. **Language-Specific Linters**
   - `python-ruff-linter/SKILL.md` - Add ruff configuration examples
   - `javascript-eslint-linter/SKILL.md` - Add ESLint configuration examples
   - Maintain consistency with linting-workflow

3. **Project-Specific Skills**
   - `nextjs-pr-workflow/SKILL.md` - Add complete workflow example
   - `nextjs-standard-setup/SKILL.md` - Add setup verification steps
   - Add framework-specific examples and patterns

4. **Git/JIRA Workflow Skills**
   - `git-issue-creator/SKILL.md` - Add issue creation examples
   - `git-pr-creator/SKILL.md` - Add PR creation examples
   - `jira-git-workflow/SKILL.md` - Add JIRA integration examples
   - Add end-to-end workflow examples with expected outputs

5. **OpenCode Meta Skills**
   - `opencode-agent-creation/SKILL.md` - Add agent creation examples
   - `opencode-skill-creation/SKILL.md` - Add skill creation examples
   - `opencode-skill-auditor/SKILL.md` - Add audit examples
   - `opencode-skills-maintainer/SKILL.md` - Add maintenance examples

6. **OpenTofu/Infrastructure Skills**
   - `opentofu-provider-setup/SKILL.md` - Add provider configuration examples
   - `opentofu-provisioning-workflow/SKILL.md` - Add provisioning examples
   - `opentofu-*-explorer/SKILL.md` - Add exploration examples
   - Add infrastructure-specific patterns and examples

7. **Code Quality/Documentation Skills**
   - `docstring-generator/SKILL.md` - Add docstring examples for each language
   - `typescript-dry-principle/SKILL.md` - Add DRY refactoring examples
   - `coverage-readme-workflow/SKILL.md` - Add coverage badge examples
   - Add code quality patterns and examples

8. **Utility Skills**
   - `ascii-diagram-creator/SKILL.md` - Add diagram creation examples
   - Add utility-specific examples and patterns

### Phase 4: AGENTS.md Enhancement

1. **Add New Sections**
   - "Available Skills" table with purpose and when-to-use columns
   - "Agent Orchestration Patterns" - when to delegate to which agent
   - "Parallel Execution Guidelines" - how to use multiple agents simultaneously
   - "Code Quality Principles" - readability, immutability, DRY, YAGNI
   - "Testing Standards" - verification patterns, coverage requirements
   - "Performance Optimization" - context management, model selection
   - "Agent Design Patterns" table with examples
   - "Troubleshooting" - common issues and solutions
   - "Related Commands" - quick reference for common operations

2. **Expand Existing Sections**
   - "Code Style Guidelines" - add specific patterns (immutability, error handling)
   - "Agent Design Patterns" - add detailed examples and use cases
   - "Error Handling" - add more comprehensive scenarios
   - "Testing Changes" - add more validation steps

### Phase 5: Validation and Testing

1. **Validate Configuration Files**
   - Run `jq . config.json` on all JSON configs
   - Run `bash -n setup.sh` to validate shell script syntax
   - Verify no syntax errors or schema violations

2. **Test Skills Auto-Discovery**
   - Run `./setup.sh --skills-only` to regenerate skills
   - Verify skills are injected into agent prompts correctly
   - Check `{{SKILLS_SECTION_PLACEHOLDER}}` is replaced

3. **Test Agent Invocation**
   - Run `opencode --agent build-with-skills "test prompt"`
   - Verify agent can access all skills
   - Check skill invocation works correctly

4. **Test Skills List**
   - Run `opencode --list-skills`
   - Verify all 30+ skills are listed
   - Check metadata is correct

5. **Test Verification Commands**
   - Run all verification commands mentioned in skills
   - Verify expected outputs match documentation
   - Fix any broken commands

### Phase 6: Documentation Updates

1. **Update README.md**
   - Document new skill structure and sections
   - Add section on creating new skills with template
   - Include migration guide for existing skill creators

2. **Create CONTRIBUTING.md (if needed)**
   - Document skill creation guidelines
   - Include skill template and best practices
   - Add testing and validation requirements

3. **Update AGENTS.md**
   - Document new sections and patterns
   - Include examples of agent orchestration
   - Add troubleshooting guidance

## Success Criteria

- [ ] All 30+ skills have comprehensive frontmatter with name, description, license, compatibility, metadata
- [ ] All skills include "What I do", "When to use me", "Prerequisites" sections
- [ ] All skills have "Steps" section with detailed workflow instructions
- [ ] All skills have "Best Practices" section with specific guidelines
- [ ] All skills have "Common Issues" section with problems and solutions
- [ ] All skills have "Troubleshooting Checklist" for before/after task execution
- [ ] All skills have "Related Skills" section with framework relationships
- [ ] All code blocks use proper language specifiers (bash, typescript, python, etc.)
- [ ] All examples include verification commands and expected outputs
- [ ] AGENTS.md has "Available Skills" table with all 30+ skills
- [ ] AGENTS.md has "Agent Orchestration Patterns" section
- [ ] AGENTS.md has "Parallel Execution Guidelines" section
- [ ] AGENTS.md has "Code Quality Principles" section
- [ ] AGENTS.md has "Testing Standards" section
- [ ] AGENTS.md has "Performance Optimization" section
- [ ] AGENTS.md has "Agent Design Patterns" table
- [ ] AGENTS.md has "Troubleshooting" section
- [ ] AGENTS.md has "Related Commands" section
- [ ] All JSON configs validated with `jq . config.json`
- [ ] All shell scripts validated with `bash -n setup.sh`
- [ ] Skills auto-discovery tested with `./setup.sh --skills-only`
- [ ] Agent invocation tested with `opencode --agent build-with-skills`
- [ ] Skills list verified with `opencode --list-skills`
- [ ] All verification commands work and produce expected outputs
- [ ] Documentation builds without errors
- [ ] No breaking changes to existing OpenCode installations
- [ ] Backward compatibility maintained (config.json, setup.sh unchanged)

## Notes

- **OpenCode-Specific Focus**: All patterns must align with OpenCode best practices, not generic patterns
- **Backward Compatibility**: Must preserve auto-discovery mechanism via `scripts/generate-skills.py`
- **Schema Compliance**: All changes must follow OpenCode config schema at https://opencode.ai/config.json
- **Naming Conventions**: Maintain kebab-case for skills, agents, and files
- **Environment Variables**: All sensitive data must use environment variables
- **Documentation Quality**: Examples must include verification commands and expected outputs
- **Testing**: All verification commands must be tested and working
- **Consistency**: All skills must follow same structure and formatting standards
- **Framework Skills**: Refactor framework skills first as they are dependencies for specialized skills
- **Reference Material**: Use affaan-m/everything-claude-code for inspiration, but adapt to OpenCode context

## Related Skills

- **Frameworks**:
  - `git-issue-labeler` - For GitHub default label assignment (bug, enhancement, documentation, etc.)
  - `git-semantic-commits` - For semantic commit message formatting (Conventional Commits)
  - `git-issue-updater` - For issue progress updates with user, date, time
  - `ticket-branch-workflow` - For core workflow (branch creation, PLAN.md, commit, push)

- **Related Workflows**:
  - `pr-creation-workflow` - For creating PRs after completing skills refactor
  - `jira-git-integration` - For JIRA-integrated workflows (if applicable)
  - `linting-workflow` - For ensuring code quality in skill files
