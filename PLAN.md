# Plan: Update setup.sh to reflect current available skill set (27 skills vs documented 16)

## Overview
Update setup.sh to accurately document all 27 available skills instead of the currently documented 16 skills. The skills directory has grown but the setup script's help text and output messages haven't been updated to reflect this.

## Issue Reference
- Issue: #40
- URL: https://github.com/darellchua2/opencode-config-template/issues/40
- Labels: enhancement, documentation

## Current State
**Documented in setup.sh (16 skills):**
- Framework Skills (5): test-generator-framework, jira-git-integration, pr-creation-workflow, ticket-branch-workflow, linting-workflow
- Specialized Skills (11): ascii-diagram-creator, git-issue-creator, git-pr-creator, jira-git-workflow, nextjs-pr-workflow, nextjs-unit-test-creator, opencode-agent-creation, opencode-skill-creation, python-pytest-creator, python-ruff-linter, typescript-dry-principle

## Actual State
**Available in skills/ directory (27 skills):**
All 16 documented skills plus 11 new skills:
1. coverage-readme-workflow - Ensure test coverage percentage is displayed in README.md
2. docstring-generator - Generate language-specific docstrings (C#, Java, Python, TypeScript)
3. javascript-eslint-linter - JavaScript/TypeScript linting with ESLint
4. nextjs-standard-setup - Create standardized Next.js 16 demo applications
5. opencode-skill-auditor - Audit existing OpenCode skills to identify modularization opportunities
6. opentofu-aws-explorer - Explore and manage AWS cloud infrastructure resources
7. opentofu-keycloak-explorer - Explore and manage Keycloak identity and access management
8. opentofu-kubernetes-explorer - Explore and manage Kubernetes clusters and resources
9. opentofu-neon-explorer - Explore and manage Neon Postgres serverless database resources
10. opentofu-provider-setup - Configure OpenTofu with cloud providers
11. opentofu-provisioning-workflow - Infrastructure as Code development patterns with OpenTofu

## Files to Modify
1. `setup.sh` - Update skill documentation in multiple sections

## Approach

1. **Identify All Sections to Update**:
   - Lines 204-239: CONFIGURED FEATURES section in show_help()
   - Lines 946-967: Deployed Skills section in setup_config()
   - Lines 1067-1068: Summary section (line 946's echo statement)
   - Lines 1136-1156: Next Steps section

2. **Organize Skills into Logical Categories**:
   - Framework Skills (5): test-generator-framework, jira-git-integration, pr-creation-workflow, ticket-branch-workflow, linting-workflow
   - Language-Specific Skills (3): python-pytest-creator, python-ruff-linter, javascript-eslint-linter
   - Framework-Specific Skills (4): nextjs-pr-workflow, nextjs-unit-test-creator, nextjs-standard-setup, typescript-dry-principle
   - OpenCode Meta Skills (3): opencode-agent-creation, opencode-skill-creation, opencode-skill-auditor
   - OpenTofu Skills (6): opentofu-aws-explorer, opentofu-keycloak-explorer, opentofu-kubernetes-explorer, opentofu-neon-explorer, opentofu-provider-setup, opentofu-provisioning-workflow
   - Git/Workflow Skills (3): ascii-diagram-creator, git-issue-creator, git-pr-creator
   - Documentation Skills (2): coverage-readme-workflow, docstring-generator
   - JIRA Skills (1): jira-git-workflow

3. **Update Each Section**:
   - Update skill count from 16 to 27
   - Add all 11 missing skills with descriptions
   - Reorganize into logical categories for better readability
   - Ensure consistent formatting across all sections

4. **Testing**:
   - Verify `./setup.sh --help` displays updated documentation
   - Verify setup output shows correct skill count and descriptions
   - Ensure shell syntax is valid: `bash -n setup.sh`

## Success Criteria
- [ ] All skill count references updated from 16 to 27
- [ ] All 11 missing skills added to relevant sections
- [ ] Skills organized into logical categories
- [ ] Help text (./setup.sh --help) reflects complete skill set
- [ ] Summary output reflects complete skill set
- [ ] Next steps output reflects complete skill set
- [ ] Shell syntax validation passes: `bash -n setup.sh`
- [ ] All skill descriptions are accurate and consistent

## Notes
- The OpenTofu skills are a new category that should be highlighted
- Language-specific skills (Python, JavaScript) should be grouped together
- Framework-specific skills (Next.js) should be grouped together
- OpenCode meta skills (agent/skill creation) should be grouped together
- Maintain the existing format and style for consistency
- Ensure descriptions are brief but informative

## Skill Organization Proposal

```
Framework Skills (5):
  - test-generator-framework: Generate tests for any language/framework
  - jira-git-integration: JIRA ticket and Git operations
  - pr-creation-workflow: Generic PR creation with quality checks
  - ticket-branch-workflow: Ticket-to-branch-to-PLAN workflow
  - linting-workflow: Multi-language linting with auto-fix

Language-Specific Skills (3):
  - python-pytest-creator: Generate pytest tests for Python
  - python-ruff-linter: Python linting with Ruff
  - javascript-eslint-linter: JavaScript/TypeScript linting with ESLint

Framework-Specific Skills (4):
  - nextjs-pr-workflow: Next.js PR workflow with JIRA integration
  - nextjs-unit-test-creator: Generate unit/E2E tests for Next.js
  - nextjs-standard-setup: Create standardized Next.js 16 demo applications
  - typescript-dry-principle: Apply DRY principle to TypeScript

OpenCode Meta Skills (3):
  - opencode-agent-creation: Generate OpenCode agents
  - opencode-skill-creation: Generate OpenCode skills
  - opencode-skill-auditor: Audit existing OpenCode skills

OpenTofu Skills (6):
  - opentofu-aws-explorer: Explore and manage AWS cloud infrastructure resources
  - opentofu-keycloak-explorer: Explore and manage Keycloak identity and access management
  - opentofu-kubernetes-explorer: Explore and manage Kubernetes clusters and resources
  - opentofu-neon-explorer: Explore and manage Neon Postgres serverless database resources
  - opentofu-provider-setup: Configure OpenTofu with cloud providers
  - opentofu-provisioning-workflow: Infrastructure as Code development patterns with OpenTofu

Git/Workflow Skills (3):
  - ascii-diagram-creator: Create ASCII diagrams from workflows
  - git-issue-creator: GitHub issue creation with tag detection
  - git-pr-creator: Create pull requests with issue linking

Documentation Skills (2):
  - coverage-readme-workflow: Ensure test coverage percentage is displayed in README.md
  - docstring-generator: Generate language-specific docstrings

JIRA Skills (1):
  - jira-git-workflow: JIRA ticket creation and branching

Total: 27 skills
```
