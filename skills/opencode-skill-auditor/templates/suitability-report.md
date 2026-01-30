# Subagent Suitability Report

**Generated**: {{GENERATION_DATE}}
**Auditor Version**: opencode-skill-auditor v{{VERSION}}
**Skills Analyzed**: {{NUM_SKILLS}}

---

## Executive Summary

This report analyzes the compatibility of {{NUM_SKILLS}} OpenCode skills across {{NUM_AGENTS}} agent/subagent configurations. The analysis identifies which skills can be safely loaded by subagents based on tool restrictions defined in `.AGENTS.md`.

### Key Findings

- **Primary Agent Compatible**: {{PRIMARY_COMPATIBLE}} skills ({{PRIMARY_PERCENT}}%)
- **Linting Subagent Compatible**: {{LINTING_COMPATIBLE}} skills ({{LINTING_PERCENT}}%)
- **Testing Subagent Compatible**: {{TESTING_COMPATIBLE}} skills ({{TESTING_PERCENT}}%)
- **Git Workflow Subagent Compatible**: {{GIT_COMPATIBLE}} skills ({{GIT_PERCENT}}%)
- **Documentation Subagent Compatible**: {{DOCS_COMPATIBLE}} skills ({{DOCS_PERCENT}}%)
- **OpenTofu Subagent Compatible**: {{OPENTOFU_COMPATIBLE}} skills ({{OPENTOFU_PERCENT}}%)
- **Workflow Subagent Compatible**: {{WORKFLOW_COMPATIBLE}} skills ({{WORKFLOW_PERCENT}}%)

### Tool Requirements Summary

| Tool/Resource | Skills Requiring | Percentage |
|---------------|----------------|------------|
| Bash commands | {{BASH_COUNT}} | {{BASH_PERCENT}}% |
| Task tool | {{TASK_COUNT}} | {{TASK_PERCENT}}% |
| Atlassian MCP | {{ATLASSIAN_COUNT}} | {{ATLASSIAN_PERCENT}}% |
| Draw.io MCP | {{DRAWIO_COUNT}} | {{DRAWIO_PERCENT}}% |
| ZAI MCP Server | {{ZAI_COUNT}} | {{ZAI_PERCENT}}% |
| Question interactions | {{QUESTION_COUNT}} | {{QUESTION_PERCENT}}% |

---

## Detailed Suitability Matrix

| Skill | Primary | Linting | Testing | Git | Docs | OpenTofu | Workflow | Issues |
|-------|---------|---------|---------|-----|------|----------|----------|--------|
{{SKILL_MATRIX_ROWS}}

---

## Subagent-Specific Recommendations

### Primary Agents

**Capabilities**: Full access to all tools and MCP servers
**Recommended Skills**: All {{PRIMARY_COMPATIBLE}} skills
**Loading Strategy**: Load on-demand based on task requirements

**Notes**:
{{PRIMARY_NOTES}}

---

### Linting Subagent

**Capabilities**: read, write, edit, glob, grep
**MCP Access**: None
**Tool Restrictions**: No bash, task, todowrite/todoread, question
**Recommended Skills**: {{LINTING_RECOMMENDED}}

**Recommended Loading Pattern**:
```bash
# Load framework + language-specific linters
load_skill linting-workflow
load_skill python-ruff-linter
load_skill javascript-eslint-linter
```

**Constraints**:
{{LINTING_CONSTRAINTS}}

**Notes**:
{{LINTING_NOTES}}

---

### Testing Subagent

**Capabilities**: read, write, edit, glob, grep
**MCP Access**: None
**Tool Restrictions**: No bash, task, todowrite/todoread, question
**Recommended Skills**: {{TESTING_RECOMMENDED}}

**Recommended Loading Pattern**:
```bash
# Load framework + language-specific test generators
load_skill test-generator-framework
load_skill python-pytest-creator
load_skill nextjs-unit-test-creator
```

**Constraints**:
{{TESTING_CONSTRAINTS}}

**Notes**:
{{TESTING_NOTES}}

---

### Git Workflow Subagent

**Capabilities**: read, write, edit, glob, grep
**MCP Access**: atlassian
**Tool Restrictions**: No bash, task, todowrite/todoread, question
**Recommended Skills**: {{GIT_RECOMMENDED}}

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
{{GIT_CONSTRAINTS}}

**Notes**:
{{GIT_NOTES}}

---

### Documentation Subagent

**Capabilities**: read, write, edit, glob, grep
**MCP Access**: None
**Tool Restrictions**: No bash, task, todowrite/todoread, question
**Recommended Skills**: {{DOCS_RECOMMENDED}}

**Recommended Loading Pattern**:
```bash
# Load on-demand per task
load_skill docstring-generator
load_skill coverage-readme-workflow
```

**Constraints**:
{{DOCS_CONSTRAINTS}}

**Notes**:
{{DOCS_NOTES}}

---

### OpenTofu Explorer Subagent

**Capabilities**: read, write, edit, glob, grep
**MCP Access**: None
**Tool Restrictions**: No bash, task, todowrite/todoread, question
**Recommended Skills**: {{OPENTOFU_RECOMMENDED}}

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
{{OPENTOFU_CONSTRAINTS}}

**Notes**:
{{OPENTOFU_NOTES}}

---

### Workflow Subagent

**Capabilities**: read, write, edit, glob, grep
**MCP Access**: atlassian
**Tool Restrictions**: No bash, task, todowrite/todoread, question
**Recommended Skills**: {{WORKFLOW_RECOMMENDED}}

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
{{WORKFLOW_CONSTRAINTS}}

**Notes**:
{{WORKFLOW_NOTES}}

---

## Incompatible Skills by Subagent

### Linting Subagent Incompatible Skills

{{LINTING_INCOMPATIBLE}}

**Reason**: These skills require bash, task, or MCP access not available to linting-subagent.

---

### Testing Subagent Incompatible Skills

{{TESTING_INCOMPATIBLE}}

**Reason**: These skills require bash, task, or MCP access not available to testing-subagent.

---

### Git Workflow Subagent Incompatible Skills

{{GIT_INCOMPATIBLE}}

**Reason**: These skills require tools or MCP servers not available to git-workflow-subagent.

---

### Documentation Subagent Incompatible Skills

{{DOCS_INCOMPATIBLE}}

**Reason**: These skills require bash, task, or MCP access not available to documentation-subagent.

---

### OpenTofu Explorer Subagent Incompatible Skills

{{OPENTOFU_INCOMPATIBLE}}

**Reason**: These skills require tools or MCP servers not available to opentofu-explorer-subagent.

---

### Workflow Subagent Incompatible Skills

{{WORKFLOW_INCOMPATIBLE}}

**Reason**: These skills require tools or MCP servers not available to workflow-subagent.

---

## Token Budget Allocations

| Subagent | Recommended Budget | Optimal Skill Load | Remaining Budget |
|----------|-------------------|-------------------|------------------|
| Linting | 2500 tokens | {{LINTING_OPTIMAL_LOAD}} | {{LINTING_REMAINING}} |
| Testing | 2500 tokens | {{TESTING_OPTIMAL_LOAD}} | {{TESTING_REMAINING}} |
| Git Workflow | 3000 tokens | {{GIT_OPTIMAL_LOAD}} | {{GIT_REMAINING}} |
| Documentation | 2000 tokens | {{DOCS_OPTIMAL_LOAD}} | {{DOCS_REMAINING}} |
| OpenTofu | 3000 tokens | {{OPENTOFU_OPTIMAL_LOAD}} | {{OPENTOFU_REMAINING}} |
| Workflow | 3000 tokens | {{WORKFLOW_OPTIMAL_LOAD}} | {{WORKFLOW_REMAINING}} |

---

## Optimization Recommendations

### Immediate Actions

1. **Refactor High-Incompatibility Skills**
   {{HIGH_INCOMPATIBILITY_REFACTOR}}

2. **Extract Common Patterns**
   {{COMMON_PATTERNS_EXTRACT}}

3. **Improve Subagent Efficiency**
   {{SUBAGENT_EFFICIENCY}}

### Long-term Improvements

1. **Skill Modularization**
   {{SKILL_MODULARIZATION}}

2. **Tool Access Optimization**
   {{TOOL_ACCESS_OPTIMIZATION}}

3. **MCP Server Consolidation**
   {{MCP_CONSOLIDATION}}

---

## Appendix: Tool Requirements by Skill

{{TOOL_REQUIREMENTS_TABLE}}

---

## Conclusion

The subagent suitability analysis reveals {{PRIMARY_COMPATIBLE}} skills compatible with primary agents, with varying compatibility across subagents. Key recommendations include:

1. **Primary Agent Load**: {{PRIMARY_RECOMMENDATION}}
2. **Subagent Specialization**: {{SUBAGENT_RECOMMENDATION}}
3. **Token Optimization**: {{TOKEN_RECOMMENDATION}}

Overall, the skill ecosystem is {{OVERALL_ASSESSMENT}}.

---

**Report Generation Time**: {{GENERATION_TIME}}
**Analysis Engine**: opencode-skill-auditor
**Reference**: [.AGENTS.md]({{AGENTS_MD_PATH}})
