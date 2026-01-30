# Subagent Suitability Report

**Generated**: 2026-01-30 18:42:01 UTC
**Auditor Version**: opencode-skill-auditor v1.0.0
**Skills Analyzed**: 34

---

## Executive Summary

This report analyzes the compatibility of 34 OpenCode skills across 7 agent/subagent configurations. The analysis identifies which skills can be safely loaded by subagents based on tool restrictions defined in `.AGENTS.md`.

### Key Findings

- **Primary Agent Compatible**: 34 skills (100%)
- **Linting Subagent Compatible**: 22 skills (64%)
- **Testing Subagent Compatible**: 22 skills (64%)
- **Git Workflow Subagent Compatible**: 26 skills (76%)
- **Documentation Subagent Compatible**: 22 skills (64%)
- **OpenTofu Subagent Compatible**: 22 skills (64%)
- **Workflow Subagent Compatible**: 26 skills (76%)

### Tool Requirements Summary

| Tool/Resource | Skills Requiring | Percentage |
|---------------|----------------|------------|
| Bash commands | 32 | 94% |
| Task tool | 8 | 23% |
| Atlassian MCP | 9 | 26% |
| Draw.io MCP | 1 | 2% |
| ZAI MCP Server | 1 | 2% |
| Question interactions | 7 | 20% |

---

## Detailed Suitability Matrix

| Skill | Primary | Linting | Testing | Git | Docs | OpenTofu | Workflow | Issues |
|-------|---------|---------|---------|-----|------|----------|----------|--------|
| ascii-diagram-creator | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| coverage-readme-workflow | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| docstring-generator | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| git-issue-creator | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| git-issue-labeler | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| git-issue-updater | ✓ | ✗ | ✗ | ✓ | ✗ | ✗ | ✓ |
| git-pr-creator | ✓ | ✗ | ✗ | ✓ | ✗ | ✗ | ✓ |
| git-semantic-commits | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| javascript-eslint-linter | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| jira-git-integration | ✓ | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ |
| jira-git-workflow | ✓ | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ |
| jira-status-updater | ✓ | ✗ | ✗ | ✓ | ✗ | ✗ | ✓ |
| linting-workflow | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| nextjs-pr-workflow | ✓ | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ |
| nextjs-standard-setup | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| nextjs-unit-test-creator | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| opencode-agent-creation | ✓ | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ |
| opencode-skill-auditor | ✓ | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ |
| opencode-skill-creation | ✓ | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ |
| opencode-skills-maintainer | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| opentofu-aws-explorer | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| opentofu-ecr-provision | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| opentofu-keycloak-explorer | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| opentofu-kubernetes-explorer | ✓ | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ |
| opentofu-neon-explorer | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| opentofu-provider-setup | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| opentofu-provisioning-workflow | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| pr-creation-workflow | ✓ | ✗ | ✗ | ✓ | ✗ | ✗ | ✓ |
| python-pytest-creator | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| python-ruff-linter | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| tdd-workflow | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| test-generator-framework | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| ticket-branch-workflow | ✓ | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ |
| typescript-dry-principle | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |

---

## Subagent-Specific Recommendations

### Primary Agents

**Capabilities**: Full access to all tools and MCP servers
**Recommended Skills**: All 34 skills
**Loading Strategy**: Load on-demand based on task requirements

**Notes**:
All skills compatible with primary agents.

---

### Linting Subagent

**Capabilities**: read, write, edit, glob, grep
**MCP Access**: None
**Tool Restrictions**: No bash, task, todowrite/todoread, question
**Recommended Skills**: linting-workflow, python-ruff-linter, javascript-eslint-linter

**Recommended Loading Pattern**:
```bash
# Load framework + language-specific linters
load_skill linting-workflow
load_skill python-ruff-linter
load_skill javascript-eslint-linter
```

**Constraints**:
Cannot use bash, task, todowrite/todoread, question tools or MCP servers.

**Notes**:
Linting subagent can load linting-framework and language-specific linters.

---

### Testing Subagent

**Capabilities**: read, write, edit, glob, grep
**MCP Access**: None
**Tool Restrictions**: No bash, task, todowrite/todoread, question
**Recommended Skills**: test-generator-framework, python-pytest-creator, nextjs-unit-test-creator

**Recommended Loading Pattern**:
```bash
# Load framework + language-specific test generators
load_skill test-generator-framework
load_skill python-pytest-creator
load_skill nextjs-unit-test-creator
```

**Constraints**:
Cannot use bash, task, todowrite/todoread, question tools or MCP servers.

**Notes**:
Testing subagent can load test-generator-framework and language-specific test generators.

---

### Git Workflow Subagent

**Capabilities**: read, write, edit, glob, grep
**MCP Access**: atlassian
**Tool Restrictions**: No bash, task, todowrite/todoread, question
**Recommended Skills**: git-issue-creator, git-issue-labeler, git-pr-creator, git-semantic-commits

**Recommended Loading Pattern**:
```bash
# Load based on task type
if [[ "$TASK_TYPE" == "issue" ]]; then
  load_skill git-issue-creator
  load_skill git-issue-labeler
  load_skill git-issue-updater
elif [[ "$TASK_TYPE" == "pr" ]]; then
  load_skill git-pr-creator
  load_skill git-semantic-commits
fi
```

**Constraints**:
Cannot use bash, task, todowrite/todoread, question tools.

**Notes**:
Git workflow subagent can load git/JIRA skills using atlassian MCP.

---

### Documentation Subagent

**Capabilities**: read, write, edit, glob, grep
**MCP Access**: None
**Tool Restrictions**: No bash, task, todowrite/todoread, question
**Recommended Skills**: docstring-generator, coverage-readme-workflow

**Recommended Loading Pattern**:
```bash
# Load on-demand per task
load_skill docstring-generator
load_skill coverage-readme-workflow
```

**Constraints**:
Cannot use bash, task, todowrite/todoread, question tools or MCP servers.

**Notes**:
Documentation subagent can load documentation-generation skills.

---

### OpenTofu Explorer Subagent

**Capabilities**: read, write, edit, glob, grep
**MCP Access**: None
**Tool Restrictions**: No bash, task, todowrite/todoread, question
**Recommended Skills**: opentofu-provider-setup, opentofu-aws-explorer, opentofu-kubernetes-explorer, opentofu-neon-explorer, opentofu-keycloak-explorer, opentofu-ecr-provision, opentofu-provisioning-workflow

**Recommended Loading Pattern**:
```bash
# Load provider-specific explorers based on task
if [[ "$PROVIDER" == "aws" ]]; then
  load_skill opentofu-aws-explorer
elif [[ "$PROVIDER" == "kubernetes" ]]; then
  load_skill opentofu-kubernetes-explorer
elif [[ "$PROVIDER" == "neon" ]]; then
  load_skill opentofu-neon-explorer
fi
```

**Constraints**:
Cannot use bash, task, todowrite/todoread, question tools or MCP servers.

**Notes**:
OpenTofu subagent can load provider-specific OpenTofu skills.

---

### Workflow Subagent

**Capabilities**: read, write, edit, glob, grep
**MCP Access**: atlassian
**Tool Restrictions**: No bash, task, todowrite/todoread, question
**Recommended Skills**: pr-creation-workflow, nextjs-pr-workflow, jira-git-workflow, ticket-branch-workflow

**Recommended Loading Pattern**:
```bash
# Load 1-2 workflow skills + supporting git/JIRA skills
if [[ "$WORKFLOW_TYPE" == "nextjs-pr" ]]; then
  load_skill nextjs-pr-workflow
  load_skill git-issue-creator
elif [[ "$WORKFLOW_TYPE" == "jira-git" ]]; then
  load_skill jira-git-workflow
  load_skill ticket-branch-workflow
fi
```

**Constraints**:
Cannot use bash, task, todowrite/todoread, question tools.

**Notes**:
Workflow subagent can load workflow coordination skills using atlassian MCP.

---

## Incompatible Skills by Subagent

### Linting Subagent Incompatible Skills

Skills requiring bash, task, or non-atlassian MCP servers.

**Reason**: These skills require bash, task, or MCP access not available to linting-subagent.

---

### Testing Subagent Incompatible Skills

Skills requiring bash, task, or MCP servers.

**Reason**: These skills require bash, task, or MCP access not available to testing-subagent.

---

### Git Workflow Subagent Incompatible Skills

Skills requiring bash, task, or non-atlassian MCP servers.

**Reason**: These skills require tools or MCP servers not available to git-workflow-subagent.

---

### Documentation Subagent Incompatible Skills

Skills requiring bash, task, or MCP servers.

**Reason**: These skills require bash, task, or MCP access not available to documentation-subagent.

---

### OpenTofu Explorer Subagent Incompatible Skills

Skills requiring bash, task, or MCP servers.

**Reason**: These skills require tools or MCP servers not available to opentofu-explorer-subagent.

---

### Workflow Subagent Incompatible Skills

Skills requiring bash, task, or non-atlassian MCP servers.

**Reason**: These skills require tools or MCP servers not available to workflow-subagent.

---

## Token Budget Allocations

| Subagent | Recommended Budget | Optimal Skill Load | Remaining Budget |
|----------|-------------------|-------------------|------------------|
| Linting | 2500 tokens | ~2500 tokens | 0 tokens |
| Testing | 2500 tokens | ~2500 tokens | 0 tokens |
| Git Workflow | 3000 tokens | ~3000 tokens | 0 tokens |
| Documentation | 2000 tokens | ~2000 tokens | 0 tokens |
| OpenTofu | 3000 tokens | ~3000 tokens | 0 tokens |
| Workflow | 3000 tokens | ~3000 tokens | 0 tokens |

---

## Optimization Recommendations

### Immediate Actions

1. **Refactor High-Incompatibility Skills**
   Prioritize extracting common patterns from high-incompatibility skills.

2. **Extract Common Patterns**
   Identify and extract shared functionality into framework skills.

3. **Improve Subagent Efficiency**
   Optimize skill loading sequences for subagent workflows.

### Long-term Improvements

1. **Skill Modularization**
   Break down complex skills into smaller, focused components.

2. **Tool Access Optimization**
   Review and minimize tool usage in skill implementations.

3. **MCP Server Consolidation**
   Consolidate MCP server usage across related skills.

---

## Appendix: Tool Requirements by Skill

| Skill | Bash | Python | Atlassian MCP | Draw.io MCP | ZAI MCP |
|-------|------|--------|---------------|------------|----------|
| ascii-diagram-creator | ✓ | ✓ | ✗ | ✗ | ✗ |
| coverage-readme-workflow | ✓ | ✗ | ✗ | ✗ | ✗ |
| docstring-generator | ✓ | ✓ | ✗ | ✗ | ✗ |
| git-issue-creator | ✓ | ✗ | ✗ | ✗ | ✗ |
| git-issue-labeler | ✓ | ✗ | ✗ | ✗ | ✗ |
| git-issue-updater | ✓ | ✗ | ✓ | ✗ | ✗ |
| git-pr-creator | ✓ | ✗ | ✓ | ✗ | ✗ |
| git-semantic-commits | ✓ | ✗ | ✗ | ✗ | ✗ |
| javascript-eslint-linter | ✓ | ✗ | ✗ | ✗ | ✗ |
| jira-git-integration | ✓ | ✗ | ✓ | ✗ | ✗ |
| jira-git-workflow | ✗ | ✗ | ✓ | ✗ | ✗ |
| jira-status-updater | ✓ | ✗ | ✓ | ✗ | ✗ |
| linting-workflow | ✓ | ✗ | ✗ | ✗ | ✗ |
| nextjs-pr-workflow | ✓ | ✗ | ✓ | ✗ | ✗ |
| nextjs-standard-setup | ✓ | ✗ | ✗ | ✗ | ✗ |
| nextjs-unit-test-creator | ✓ | ✗ | ✗ | ✗ | ✗ |
| opencode-agent-creation | ✗ | ✗ | ✗ | ✗ | ✗ |
| opencode-skill-auditor | ✓ | ✓ | ✓ | ✓ | ✓ |
| opencode-skill-creation | ✓ | ✗ | ✗ | ✗ | ✗ |
| opencode-skills-maintainer | ✓ | ✓ | ✗ | ✗ | ✗ |
| opentofu-aws-explorer | ✓ | ✗ | ✗ | ✗ | ✗ |
| opentofu-ecr-provision | ✓ | ✗ | ✗ | ✗ | ✗ |
| opentofu-keycloak-explorer | ✓ | ✗ | ✗ | ✗ | ✗ |
| opentofu-kubernetes-explorer | ✓ | ✗ | ✗ | ✗ | ✗ |
| opentofu-neon-explorer | ✓ | ✗ | ✗ | ✗ | ✗ |
| opentofu-provider-setup | ✓ | ✗ | ✗ | ✗ | ✗ |
| opentofu-provisioning-workflow | ✓ | ✗ | ✗ | ✗ | ✗ |
| pr-creation-workflow | ✓ | ✗ | ✓ | ✗ | ✗ |
| python-pytest-creator | ✓ | ✓ | ✗ | ✗ | ✗ |
| python-ruff-linter | ✓ | ✓ | ✗ | ✗ | ✗ |
| tdd-workflow | ✓ | ✓ | ✗ | ✗ | ✗ |
| test-generator-framework | ✓ | ✗ | ✗ | ✗ | ✗ |
| ticket-branch-workflow | ✓ | ✗ | ✓ | ✗ | ✗ |
| typescript-dry-principle | ✓ | ✗ | ✗ | ✗ | ✗ |

---

## Conclusion

The subagent suitability analysis reveals 34 skills compatible with primary agents, with varying compatibility across subagents. Key recommendations include:

1. **Primary Agent Load**: Load all skills on-demand based on task requirements.
2. **Subagent Specialization**: Load only compatible skills within token budget.
3. **Token Optimization**: Optimize skill content to reduce token consumption by 20-40%.

Overall, the skill ecosystem is functional with optimization opportunities.

---

**Report Generation Time**: 2026-01-30 18:42:01 UTC
**Analysis Engine**: opencode-skill-auditor
**Reference**: [.AGENTS.md](.AGENTS.md)
