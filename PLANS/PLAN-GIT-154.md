# Plan: Comprehensive Review and Enhancement of All Skills and Agents

## Issue Reference
- **Number**: #154
- **URL**: https://github.com/darellchua2/opencode-config-template/issues/154
- **Labels**: enhancement, major, skills, architecture

## Overview

Comprehensive audit and enhancement of all **48 active skills** and **27 global subagents** in the `opencode-config-template` repository to ensure quality, completeness, effectiveness, and adherence to OpenCode best practices.

## Acceptance Criteria
- [ ] Complete inventory of all active skills and subagents with status assessment
- [ ] All skills reviewed for clarity, completeness, actionability, and best practices
- [ ] Redundancy and overlap identified and resolved
- [ ] Gaps in coverage identified and new skills/agents created
- [ ] Agent routing and delegation patterns verified
- [ ] Documentation-sync-workflow run after all changes
- [ ] All changes deployed correctly via setup.sh

## Scope
- `skills/` — All 48 active skill directories
- `agents/` — All 27 global subagent files
- `.opencode/agents/` — Project-level subagents
- `setup.sh` — Deployment script
- `setup.ps1` — Windows deployment script
- `README.md` — Skill categories and subagents tables
- `AGENTS.md` — Agent routing instructions

---

## Implementation Phases

### Phase 1: Audit & Inventory
- [ ] Inventory all 48 active skills with status (active/archived/needs-update)
- [ ] Inventory all 27 global subagents with status
- [ ] Map skill-to-subagent delegation relationships
- [ ] Verify AGENTS.md routing matches actual skill/subagent inventory
- [ ] Identify redundant or overlapping skills
- [ ] Document findings in audit report

### Phase 2: Quality Review
- [ ] Review code quality skills (6): clean-code, code-smells, solid-principles, complexity-management, object-design, design-patterns
- [ ] Review testing skills (6): tdd-workflow, test-generator-framework, python-pytest-creator, nextjs-unit-test-creator, verification-loop, eval-harness
- [ ] Review linting skills (3): linting-workflow, python-ruff-linter, javascript-eslint-linter
- [ ] Review documentation skills (3): docstring-generator, documentation-sync-workflow, coverage-readme-workflow
- [ ] Review Git workflow skills (6): git-semantic-commits, git-issue-labeler, git-issue-plan-workflow, git-issue-updater, git-pr-creator, plan-updater
- [ ] Review architecture skill (1): clean-architecture
- [ ] Review Next.js skills (3): nextjs-standard-setup, nextjs-pr-workflow, nextjs-image-usage
- [ ] Review OpenTofu/Terraform skills (7): opentofu-aws-explorer, opentofu-ecr-provision, opentofu-keycloak-explorer, opentofu-kubernetes-explorer, opentofu-neon-explorer, opentofu-provider-setup, opentofu-provisioning-workflow
- [ ] Review OpenCode tooling skills (3): opencode-agent-creation, opencode-skill-creation, opencode-skills-maintainer
- [ ] Review diagram skills (2): ascii-diagram-creator, mermaid-diagram-creator
- [ ] Review document creation skills (2): docx-creation, pptx-specialist
- [ ] Review JIRA skills (5): jira-git-integration, jira-status-updater, jira-ticket-oauth-workflow, jira-ticket-pat-workflow, jira-ticket-plan-workflow
- [ ] Review remaining skills (5): pr-creation-workflow, typescript-dry-principle, error-resolver-workflow, continuous-learning, strategic-compact, changelog-python-cliff
- [ ] Verify all skills have proper trigger phrases and usage examples
- [ ] Validate cross-skill references and framework dependencies
- [ ] Ensure consistent formatting across all skills

### Phase 3: Gap Analysis
- [ ] Identify common workflows not yet covered
- [ ] Assess potential new skills/agents for value
- [ ] Determine which skills should be split, merged, or restructured
- [ ] Review integration between skills, agents, and documentation-sync-workflow
- [ ] Compile prioritized list of new skills/agents to create

### Phase 4: Enhancement Implementation
- [ ] Update skills identified during quality review
- [ ] Create new skills/agents for identified gaps
- [ ] Archive or remove deprecated/redundant skills
- [ ] Update setup.sh with corrected skill listings and counts
- [ ] Update setup.ps1 with corrected skill listings and counts
- [ ] Update README.md skill categories and subagents tables
- [ ] Update AGENTS.md routing as needed
- [ ] Run opencode-skills-maintainer validation on all updated skills
- [ ] Run documentation-sync-workflow for final synchronization

### Phase 5: Final Validation
- [ ] Verify all skills deploy correctly via setup.sh
- [ ] Verify Windows deployment via setup.ps1
- [ ] Test agent routing with updated skills
- [ ] Confirm PLANS and documentation are synchronized
- [ ] Final review of all changes before merge

---

## Technical Notes

- Use `opencode-skills-maintainer` skill to scan and validate skills for consistency
- Follow `documentation-sync-workflow` when updating setup scripts, README, and AGENTS.md
- Refer to `opencode-skill-creation` and `opencode-agent-creation` for new skill/agent best practices
- Keep `setup.sh` and `setup.ps1` synchronized at all times
- Peon Ping skills (in `~/.claude/skills/`) are out of scope

## Dependencies
- None — this is a standalone improvement initiative

## Risks & Mitigation
| Risk | Mitigation |
|------|------------|
| Large scope may take significant effort | Break into phases with clear checkpoints |
| Skill changes may break existing workflows | Test each skill change individually |
| Documentation sync drift | Use documentation-sync-workflow skill after each batch of changes |
| Scope creep from new skill ideas | Prioritize and defer lower-value additions |

## Success Metrics
- All 48 skills pass opencode-skills-maintainer validation
- Zero routing mismatches between AGENTS.md and actual inventory
- All documentation files (setup.sh, setup.ps1, README.md, AGENTS.md) synchronized
- At least 3 actionable gap improvements identified and implemented
