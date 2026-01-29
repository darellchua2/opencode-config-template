# Plan: Create AGENTS.md configuration (project and global level)

## Overview
Create project-level and global AGENTS.md configuration files to establish team and personal rules for OpenCode agent behavior and skill routing. This follows opencode.ai/docs best practices for agent configuration hierarchy.

## Issue Reference
- Issue: #56
- URL: https://github.com/darellchua2/opencode-config-template/issues/56
- Labels: enhancement, documentation, good first issue

## Background

Following the completion of Phase 1 (adding 6 subagents to config.json), Phase 2 focuses on establishing proper AGENTS.md configuration:

### What are AGENTS.md files?

AGENTS.md files control OpenCode agent behavior and provide:
- Team/personal rules and conventions
- Default agent selection for different task types
- Subagent routing rules
- Project-specific instructions and patterns

### Configuration Hierarchy
```
Global AGENTS.md (~/.config/opencode/AGENTS.md)
    ↓ (defaults)
Project AGENTS.md (.AGENTS.md)
    ↓ (project overrides)
config.json
    ↓ (agent definitions)
Task Execution
```

### Why This Matters

1. **Team Consistency**: Project AGENTS.md ensures all team members follow the same conventions
2. **Personalization**: Global AGENTS.md allows individual preferences
3. **Behavior Control**: Direct how agents respond to different types of tasks
4. **Subagent Routing**: Automatically route tasks to appropriate subagents based on task patterns

## Files to Create/Modify

### Files to Create

1. **`.AGENTS.md`** (project level)
   - Location: Repository root
   - Purpose: Team rules and project-specific agent behavior
   - Priority: High

2. **`~/.config/opencode/AGENTS.md`** (global level)
   - Location: User's home directory
   - Purpose: Personal rules and preferences
   - Priority: High

### Files to Modify

3. **`config.json`**
   - Add `instructions` field referencing both AGENTS.md files
   - Purpose: Integrate AGENTS.md into OpenCode configuration
   - Priority: High

4. **`README.md`** (optional update)
   - Document AGENTS.md usage and configuration hierarchy
   - Purpose: User documentation
   - Priority: Medium

## Approach

### Phase 2.1: Create Project AGENTS.md

**Step 1: Research AGENTS.md Format**
- Review opencode.ai/docs for AGENTS.md structure
- Examine example AGENTS.md files if available
- Identify required sections and configuration options

**Step 2: Create .AGENTS.md**
- Create `.AGENTS.md` in repository root
- Include sections:
  - Team Rules and Conventions
  - Default Agent Mappings
  - Subagent Routing Rules
  - Project-Specific Instructions
  - Code Style Preferences

**Step 3: Define Team Rules**
- Coding standards and conventions
- Commit message guidelines
- Testing requirements
- Documentation standards
- Review processes

**Step 4: Configure Default Agents**
- Map task types to primary agents:
  - Planning tasks → plan-with-skills
  - Implementation tasks → build-with-skills
  - Image analysis → image-analyzer
  - Diagram creation → diagram-creator
  - Linting tasks → linting-subagent
  - Testing tasks → testing-subagent
  - Git/JIRA tasks → git-workflow-subagent
  - Documentation tasks → documentation-subagent
  - Infrastructure tasks → opentofu-explorer-subagent
  - Workflow tasks → workflow-subagent

**Step 5: Configure Subagent Routing**
- Define patterns for automatic subagent selection
- Example routing rules:
  - `lint*`, `fix*style*`, `format*` → linting-subagent
  - `test*`, `spec*`, `coverage*` → testing-subagent
  - `branch*`, `commit*`, `pr*`, `issue*` → git-workflow-subagent
  - `doc*`, `readme*`, `comment*` → documentation-subagent
  - `infra*`, `terraform*`, `tofu*`, `k8s*` → opentofu-explorer-subagent
  - `workflow*`, `automation*` → workflow-subagent

### Phase 2.2: Create Global AGENTS.md

**Step 1: Create Directory Structure**
- Create `~/.config/opencode/` directory if not exists
- Ensure proper permissions

**Step 2: Create AGENTS.md**
- Create `~/.config/opencode/AGENTS.md`
- Include sections:
  - Personal Rules and Preferences
  - Personal Default Agent Settings
  - Personal Subagent Preferences
  - Personal Coding Standards
  - Environment-Specific Settings

**Step 3: Define Personal Rules**
- Coding style preferences (tabs vs spaces, line length, etc.)
- Preferred programming languages
- Personal commit message style
- Documentation preferences
- Testing preferences

**Step 4: Configure Personal Defaults**
- Override project defaults where needed
- Set personal preferences that apply across all projects
- Define favorite agents and workflows

### Phase 2.3: Update config.json Instructions

**Step 1: Add instructions Field**
- Add top-level `instructions` field to config.json
- Reference both AGENTS.md files:
  ```json
  {
    "instructions": [
      "~/.config/opencode/AGENTS.md",
      ".AGENTS.md"
    ]
  }
  ```

**Step 2: Document Configuration Priority**
- Explain that global AGENTS.md provides defaults
- Project AGENTS.md overrides global settings
- config.json agent definitions take precedence

**Step 3: Validate Configuration**
- Test configuration loading
- Verify hierarchy works correctly
- Ensure no conflicts or errors

### Phase 2.4: Documentation (Optional)

**Step 1: Update README.md**
- Add section on AGENTS.md configuration
- Document configuration hierarchy
- Provide examples and usage patterns

**Step 2: Create Examples**
- Show example .AGENTS.md
- Show example global AGENTS.md
- Explain configuration priority

## Success Criteria

- [ ] Project AGENTS.md (`.AGENTS.md`) exists in repository root
- [ ] Global AGENTS.md exists at `~/.config/opencode/AGENTS.md`
- [ ] Both files follow opencode.ai/docs AGENTS.md format
- [ ] config.json has `instructions` field referencing both AGENTS.md files
- [ ] Configuration hierarchy works (global defaults overridden by project)
- [ ] Subagent routing rules are properly configured
- [ ] Documentation explains configuration hierarchy and usage
- [ ] All task types map to appropriate agents
- [ ] Configuration loads without errors
- [ ] Team rules and conventions are clearly defined

## AGENTS.md Structure Template

### Project AGENTS.md (.AGENTS.md)

```markdown
# Project AGENTS.md

## Team Rules

### Coding Standards
- Python: Follow PEP 8, use 4 spaces indentation
- JavaScript/TypeScript: Use 2 spaces, ESLint configuration
- Commit messages: Follow Conventional Commits

### Testing Requirements
- All code must have unit tests
- Minimum 80% code coverage
- Tests must pass before merging PRs

### Documentation Standards
- All public APIs must have docstrings
- README.md must be updated for new features
- Complex logic requires inline comments

## Default Agent Mappings

### Task Type → Agent

- Planning and strategy: `plan-with-skills`
- Implementation: `build-with-skills`
- Code linting: `linting-subagent`
- Testing: `testing-subagent`
- Git operations: `git-workflow-subagent`
- Documentation: `documentation-subagent`
- Infrastructure: `opentofu-explorer-subagent`
- Workflows: `workflow-subagent`

## Subagent Routing Rules

### Automatic Routing Patterns

- `lint*`, `fix*style*`, `format*`, `quality*` → linting-subagent
- `test*`, `spec*`, `coverage*`, `assert*` → testing-subagent
- `branch*`, `commit*`, `pr*`, `issue*`, `merge*` → git-workflow-subagent
- `doc*`, `readme*`, `comment*`, `example*` → documentation-subagent
- `infra*`, `terraform*`, `tofu*`, `k8s*`, `aws*`, `kubernetes*` → opentofu-explorer-subagent
- `workflow*`, `automation*`, `pipeline*` → workflow-subagent

### Specialized Routing

- Image analysis → image-analyzer
- Diagram creation → diagram-creator
- Codebase exploration → explore

## Project-Specific Instructions

### Workflow Preferences
- Always create PLAN.md before implementation
- Use semantic branches from tickets
- Update JIRA/GitHub issues with progress

### Code Review Process
- All PRs require at least one approval
- PR must pass CI/CD checks
- Review comments must be addressed

### Deployment Strategy
- Use feature branches
- Merge through pull requests
- Tag releases with semantic versioning
```

### Global AGENTS.md (~/.config/opencode/AGENTS.md)

```markdown
# Global AGENTS.md

## Personal Rules

### Coding Preferences
- Indentation: 2 spaces (can be overridden by project)
- Line length: 100 characters
- Preferred languages: Python, TypeScript, Go

### Commit Preferences
- Use present tense in commit messages
- Reference issue/PR numbers when applicable
- Keep commits atomic and focused

### Testing Preferences
- Write tests before implementation (TDD when possible)
- Prefer integration tests over unit tests
- Test edge cases thoroughly

### Documentation Preferences
- Prefer inline comments for complex logic
- Use examples in docstrings
- Keep README.md up-to-date

## Personal Default Agent Settings

### Override Project Defaults

# Uncomment to override project defaults
# - Prefer linting-subagent for all code quality tasks
# - Prefer testing-subagent for all test-related tasks
# - Always use plan-with-skills for planning

## Personal Subagent Preferences

### Favorite Subagents
- linting-subagent: Always available for code quality
- testing-subagent: Use for comprehensive test generation
- git-workflow-subagent: Integrate with JIRA

### Workflow Preferences
- Always create issues for new features
- Use semantic commits consistently
- Update issues with progress

## Personal Coding Standards

### Python
- Use type hints where appropriate
- Prefer dataclasses for data structures
- Use context managers for resource management

### TypeScript/JavaScript
- Use strict mode
- Prefer const over let
- Use arrow functions for callbacks

### Git
- Keep commits atomic
- Write descriptive commit messages
- Use feature branches from tickets

## Environment-Specific Settings

### Local Development
- Use local LLM when available
- Enable verbose logging for debugging
- Auto-save work sessions

### Production Mode
- Use production LLM endpoints
- Minimize logging
- Disable auto-save
```

## Notes

### Configuration Hierarchy

1. **Global AGENTS.md** (`~/.config/opencode/AGENTS.md`)
   - Applies to all projects
   - Provides default settings
   - Personal preferences

2. **Project AGENTS.md** (`.AGENTS.md`)
   - Project-specific settings
   - Overrides global defaults
   - Team rules and conventions

3. **config.json**
   - Agent definitions
   - Tool permissions
   - MCP configurations

### Best Practices

- Keep AGENTS.md files focused and readable
- Use clear section headers
- Provide examples for complex configurations
- Document routing rules with examples
- Test configuration changes before committing

### Common Issues

1. **Configuration Not Loading**
   - Check file paths in config.json instructions field
   - Ensure files exist and are readable
   - Verify JSON syntax in config.json

2. **Hierarchy Not Working**
   - Project AGENTS.md should override global defaults
   - Check that files are in correct locations
   - Verify file permissions

3. **Subagent Routing Not Working**
   - Check routing pattern syntax
   - Ensure subagent names match config.json
   - Test patterns with various task descriptions

## Related Issues

- Parent issue: #55 - Apply OpenCode best practices and optimize configuration structure
- Phase 1: Completed - Added 6 subagents to config.json
- Phase 3: Pending - Optimize setup.sh with macOS ~/.zshrc support

## Prerequisites

- config.json has 6 subagents from Phase 1
- Access to opencode.ai/docs for reference
- Git repository initialized
- Write permissions for ~/.config/opencode/ directory
