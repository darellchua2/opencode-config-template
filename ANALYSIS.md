# Phase 1 Analysis Report: Skills & Subagents Audit

**Generated**: 2025-02-12
**Issue**: #66

---

## Executive Summary

Analysis identified **38 skills** across **9 categories** with **9 subagents**. Key findings include:
- 1 mode inconsistency (`explore` marked as primary, not subagent)
- Missing subagent for OpenCode tooling skills
- Incomplete routing rules in AGENTS.md
- Several skill overlaps that should be documented or consolidated

---

## Skills Inventory (38 Total)

### By Category

| Category | Count | Skills |
|----------|-------|--------|
| Next.js | 6 | nextjs-tsdoc-documentor, nextjs-complete-setup, nextjs-image-usage, nextjs-standard-setup, nextjs-pr-workflow, nextjs-unit-test-creator |
| Git/JIRA | 9 | git-issue-plan-workflow, git-semantic-commits, git-issue-updater, git-issue-labeler, git-pr-creator, git-issue-creator, jira-git-integration, jira-ticket-plan-workflow, jira-status-updater |
| OpenTofu | 7 | opentofu-provisioning-workflow, opentofu-kubernetes-explorer, opentofu-ecr-provision, opentofu-neon-explorer, opentofu-aws-explorer, opentofu-provider-setup, opentofu-keycloak-explorer |
| Python | 3 | python-docstring-generator, python-pytest-creator, python-ruff-linter |
| Linting/Testing | 4 | linting-workflow, test-generator-framework, tdd-workflow, javascript-eslint-linter |
| Meta/OpenCode | 4 | opencode-skill-auditor, opencode-skill-creation, opencode-agent-creation, opencode-skills-maintainer |
| Documentation | 2 | docstring-generator, coverage-readme-workflow |
| TypeScript | 1 | typescript-dry-principle |
| Other | 2 | ascii-diagram-creator, pr-creation-workflow |

---

## Subagent Inventory (9 Total)

| Subagent | Mode | MCP Access | Skills Allowed |
|----------|------|------------|----------------|
| image-analyzer | subagent | zai-mcp-server | None |
| explore | **primary** ⚠️ | None | None |
| diagram-creator | subagent | drawio | None |
| linting-subagent | subagent | None | 3 skills |
| testing-subagent | subagent | None | 4 skills |
| git-workflow-subagent | subagent | atlassian | 11 skills |
| documentation-subagent | subagent | None | 2 skills |
| opentofu-explorer-subagent | subagent | None | 7 skills |
| workflow-subagent | subagent | atlassian | 6 skills |

---

## Issues Identified

### 🔴 Critical Issues

#### 1. `explore` Mode Inconsistency
- **Problem**: `explore` has `mode: "primary"` in config.json but is listed as a subagent in AGENTS.md
- **Impact**: May get incorrect tool permissions
- **Fix**: Change to `mode: "subagent"` in config.json

### 🟡 Medium Issues

#### 2. Missing Subagent for OpenCode Tooling
- **Problem**: 4 skills (`opencode-skill-auditor`, `opencode-skill-creation`, `opencode-agent-creation`, `opencode-skills-maintainer`) have no dedicated subagent
- **Impact**: These skills are only accessible via primary agents
- **Fix**: Create `opencode-tooling-subagent` or route to existing subagent

#### 3. Incomplete AGENTS.md Routing Rules
- **Missing patterns**:
  - `skill*`, `agent*` → should route to tooling subagent
  - `coverage*` → currently routes to testing-subagent but not documented
  - `dry*`, `refactor*` → should route to linting-subagent
- **Fix**: Add routing rules for these patterns

#### 4. Skill Overlaps (Need Documentation)
| Skill 1 | Skill 2 | Overlap Type |
|---------|---------|--------------|
| docstring-generator | python-docstring-generator | Generic vs language-specific |
| docstring-generator | nextjs-tsdoc-documentor | Generic vs language-specific |
| pr-creation-workflow | git-pr-creator | Generic vs specific |
| pr-creation-workflow | nextjs-pr-workflow | Generic vs framework-specific |
| git-issue-plan-workflow | jira-ticket-plan-workflow | Platform-specific variants |

**Recommendation**: **No action needed** - Overlaps are intentional:
- `docstring-generator` is a **framework skill** extended by language-specific versions
- `pr-creation-workflow` is a **framework skill** extended by `git-pr-creator` and `nextjs-pr-workflow`
- Platform-specific skills (`git-*` vs `jira-*`) exist for different project tracking systems

### 🟢 Minor Issues

#### 5. Subagent Prompts Missing Some Skills
- `linting-subagent` prompt doesn't mention `typescript-dry-principle`
- `testing-subagent` prompt doesn't mention all allowed skills clearly
- **Fix**: Update prompts to list all allowed skills

#### 6. AGENTS.md Table Incomplete
- `explore` not fully documented in subagent table
- Missing tool restrictions for `explore`
- **Fix**: Add full entry for `explore` in table

---

## Recommendations

### Immediate Actions (Phase 2)

1. **Fix `explore` mode** - Change to subagent in config.json
2. **Create `opencode-tooling-subagent`** - New subagent for skill/agent management
3. **Add missing routing rules** - Update AGENTS.md

### Skill Cleanup (Phase 2)

1. **Document overlaps** - Add notes explaining why similar skills exist
2. **Consider consolidation** - Evaluate if any skills should be merged
3. **Standardize naming** - Ensure consistent naming conventions

### Documentation Updates (Phase 4)

1. **Complete AGENTS.md table** - Add missing subagent details
2. **Add routing examples** - More examples for edge cases
3. **Update subagent prompts** - List all allowed skills explicitly

---

## Next Steps

Proceed to **Phase 2: Skill Cleanup**:
- [ ] Fix `explore` mode in config.json
- [ ] Create `opencode-tooling-subagent` definition
- [ ] Update AGENTS.md with missing routing rules
- [ ] Document skill overlaps
