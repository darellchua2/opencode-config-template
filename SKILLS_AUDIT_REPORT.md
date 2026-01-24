# Skills Audit Report: Redundancy Analysis and Optimization Plan

**Date:** 2026-01-24
**Total Skills Analyzed:** 11
**Redundancies Found:** 5 major categories

## Executive Summary

The skills directory contains 11 skills with significant overlapping functionality. Several skills duplicate workflow steps that could be extracted into reusable components. This audit identifies these redundancies and proposes optimizations to improve maintainability and reduce code duplication.

## Skills Inventory

| Skill | Purpose | Lines |
|--------|---------|--------|
| `ascii-diagram-creator` | Create ASCII diagrams | 402 |
| `git-pr-creator` | PR creation with JIRA | 533 |
| `nextjs-unit-test-creator` | Next.js testing | 1581 |
| `python-pytest-creator` | Python testing | 802 |
| `git-issue-creator` | GitHub issue + branch + PLAN.md | 390 |
| `nextjs-pr-workflow` | Next.js PR workflow | 301 |
| `python-ruff-linter` | Python linting | 28 |
| `opencode-agent-creation` | Agent creation | 27 |
| `opencode-skill-creation` | Skill creation | 27 |
| `typescript-dry-principle` | DRY refactoring | 30 |
| `jira-git-workflow` | JIRA ticket + branch + PLAN.md | 112 |

## Redundancy Categories

### 1. Test Creation Pattern Duplication

**Affected Skills:**
- `nextjs-unit-test-creator` (1581 lines)
- `python-pytest-creator` (802 lines)

**Duplicate Workflow Steps:**

| Workflow Step | nextjs-unit-test-creator | python-pytest-creator |
|--------------|----------------------|---------------------|
| Analyze codebase | ✓ Detect files via glob | ✓ Detect Python files |
| Detect framework | ✓ Check package.json for Jest/Vitest | ✓ Check pyproject.toml/requirements.txt |
| Detect environment | ✓ NPM availability | ✓ Poetry detection |
| Generate scenarios | ✓ Components, utilities, hooks | ✓ Functions, classes, async |
| User confirmation | ✓ Display scenarios, wait for y/n | ✓ Display scenarios, wait for y/n |
| Create test files | ✓ Jest/Vitest templates | ✓ Pytest fixtures |
| Verify executability | ✓ Test command execution | ✓ Poetry/pytest execution |
| Summary display | ✓ Test files created summary | ✓ Test files created summary |

**Optimization Opportunity:**
Create a reusable `test-generator-framework` skill that handles:
- Framework detection logic
- Scenario generation patterns
- User confirmation flow
- Test file template creation
- Executability verification

**Estimated Savings:** ~400 lines of duplicated documentation

---

### 2. JIRA + Git Workflow Duplication

**Affected Skills:**
- `git-pr-creator` (533 lines)
- `jira-git-workflow` (112 lines)

**Duplicate Workflow Steps:**

| Workflow Step | git-pr-creator | jira-git-workflow |
|--------------|----------------|------------------|
| JIRA integration | ✓ Get cloud ID, access resources | ✓ Get visible projects, resources |
| Branch creation | ✓ Push and checkout | ✓ Create and checkout |
| JIRA comments | ✓ Add comments with PR details | ✓ Add clarifying comments |
| Image handling | ✓ Upload local images to JIRA | ✗ Not applicable |

**Optimization Opportunity:**
Create a `jira-git-integration` skill that provides:
- JIRA resource detection (cloud ID, projects, issues)
- Branch naming conventions
- JIRA comment creation workflow
- Image upload to JIRA

**Estimated Savings:** ~200 lines of duplicated documentation

---

### 3. PR Creation Duplication

**Affected Skills:**
- `git-pr-creator` (533 lines)
- `nextjs-pr-workflow` (301 lines)

**Duplicate Workflow Steps:**

| Workflow Step | git-pr-creator | nextjs-pr-workflow |
|--------------|----------------|---------------------|
| PR creation | ✓ gh pr create with JIRA reference | ✓ gh pr create with JIRA reference |
| Quality checks | ✓ Scan for diagrams/images | ✓ npm run lint, npm run build |
| JIRA updates | ✓ Add comment with PR details | ✓ Add comment with PR details |
| Image handling | ✓ Upload to JIRA, embed in comments | ✗ Not applicable |
| Merge confirmation | ✗ Not included | ✓ Ask for merge target |

**Optimization Opportunity:**
Create a `pr-creation-workflow` skill that:
- Creates PRs with configurable base branches
- Runs configurable quality checks (lint, build, test)
- Handles JIRA/git issue integration
- Supports image attachments
- Manages merge confirmation flow

**Estimated Savings:** ~250 lines of duplicated documentation

---

### 4. Issue + Branch + PLAN.md Duplication

**Affected Skills:**
- `git-issue-creator` (390 lines)
- `jira-git-workflow` (112 lines)

**Duplicate Workflow Steps:**

| Workflow Step | git-issue-creator | jira-git-workflow |
|--------------|-------------------|------------------|
| Ticket creation | ✓ GitHub issue with tag detection | ✓ JIRA ticket creation |
| Branch creation | ✓ Named after issue number | ✓ Named after JIRA ticket |
| PLAN.md generation | ✓ Standard template | ✓ Standard template |
| Auto-checkout | ✓ git checkout -b | ✓ git checkout -b |
| Commit PLAN.md | ✓ git commit PLAN.md | ✓ git commit PLAN.md |
| Push to remote | ✓ git push -u origin | ✗ Not included |

**Optimization Opportunity:**
Create a `ticket-branch-workflow` skill that:
- Creates tickets in multiple platforms (GitHub, JIRA)
- Generates and commits PLAN.md
- Creates and checks out feature branches
- Pushes branches to remote
- Supports platform-specific tag/label assignment

**Estimated Savings:** ~300 lines of duplicated documentation

---

### 5. Linting Workflow Duplication

**Affected Skills:**
- `nextjs-pr-workflow` (301 lines, contains linting steps)
- `python-ruff-linter` (28 lines, standalone)

**Duplicate Workflow Steps:**

| Workflow Step | nextjs-pr-workflow | python-ruff-linter |
|--------------|---------------------|-------------------|
| Detect linter | ✓ npm run lint script | ✓ Poetry + ruff detection |
| Run linting | ✓ npm run lint | ✓ poetry run ruff check |
| Auto-fix | ✓ npm run lint -- --fix | ✓ poetry run ruff check --fix |
| Fix errors | ✓ Manual iteration | ✓ Manual iteration |
| Commit fixes | ✓ git commit fixes | ✗ Not included |

**Optimization Opportunity:**
Create a `linting-workflow` skill that:
- Detects language (TypeScript/JavaScript vs Python)
- Runs appropriate linter (ESLint vs Ruff)
- Applies auto-fix where available
- Guides manual error resolution
- Commits fixes as separate commit

**Estimated Savings:** ~150 lines of duplicated documentation

---

## Proposed New Reusable Skills

### 1. `test-generator-framework`
**Purpose:** Generic test generation framework supporting multiple languages

**Features:**
- Detect language/framework automatically
- Generate standard test scenarios
- User confirmation workflow
- Test file template system
- Executability verification

**Relevant Skills:**
- `nextjs-unit-test-creator`
- `python-pytest-creator`

---

### 2. `jira-git-integration`
**Purpose:** JIRA + Git workflow utilities

**Features:**
- JIRA resource detection (cloud ID, projects, issues)
- Branch naming conventions
- JIRA comment creation
- Image upload to JIRA
- Ticket retrieval and updates

**Relevant Skills:**
- `git-pr-creator`
- `jira-git-workflow`
- `nextjs-pr-workflow`

---

### 3. `pr-creation-workflow`
**Purpose:** Generic PR creation workflow

**Features:**
- Configurable base branch selection
- Pluggable quality checks (lint, build, test)
- Multi-platform integration (JIRA, GitHub issues)
- Image attachment support
- Merge confirmation flow

**Relevant Skills:**
- `git-pr-creator`
- `nextjs-pr-workflow`

---

### 4. `ticket-branch-workflow`
**Purpose:** Generic ticket-to-branch-to-PLAN workflow

**Features:**
- Multi-platform ticket creation (GitHub, JIRA)
- PLAN.md generation and commit
- Branch creation and auto-checkout
- Branch push to remote
- Platform-specific tagging/labeling

**Relevant Skills:**
- `git-issue-creator`
- `jira-git-workflow`

---

### 5. `linting-workflow`
**Purpose:** Generic linting workflow for multiple languages

**Features:**
- Language detection (TypeScript/JS vs Python)
- Linter detection (ESLint vs Ruff)
- Auto-fix application
- Error resolution guidance
- Fix commit workflow

**Relevant Skills:**
- `nextjs-pr-workflow`
- `python-ruff-linter`

---

## Skills with No Redundancy (Keep As-Is)

| Skill | Reason |
|-------|--------|
| `ascii-diagram-creator` | Unique functionality, no overlap |
| `opencode-agent-creation` | Specific to OpenCode agent creation |
| `opencode-skill-creation` | Specific to OpenCode skill creation |
| `typescript-dry-principle` | Specific refactoring pattern, unique |

---

## Optimization Strategy

### Phase 1: Create Reusable Framework Skills (High Priority)

1. **Create `test-generator-framework` skill**
   - Extract common test generation logic
   - Define test scenario patterns
   - Create template system
   - Update `nextjs-unit-test-creator` and `python-pytest-creator` to reference

2. **Create `jira-git-integration` skill**
   - Extract JIRA utilities
   - Define JIRA MCP tool patterns
   - Update `git-pr-creator`, `jira-git-workflow`, `nextjs-pr-workflow` to reference

### Phase 2: Create Workflow Skills (Medium Priority)

3. **Create `pr-creation-workflow` skill**
   - Extract PR creation logic
   - Define quality check system
   - Update `git-pr-creator` and `nextjs-pr-workflow` to reference

4. **Create `ticket-branch-workflow` skill**
   - Extract ticket/branch/PLAN workflow
   - Update `git-issue-creator` and `jira-git-workflow` to reference

5. **Create `linting-workflow` skill**
   - Extract linting logic
   - Update `nextjs-pr-workflow` and expand `python-ruff-linter` to reference

### Phase 3: Update Existing Skills (Low Priority)

6. **Refactor `nextjs-unit-test-creator`**
   - Reference `test-generator-framework` for core logic
   - Focus on Next.js-specific scenarios

7. **Refactor `python-pytest-creator`**
   - Reference `test-generator-framework` for core logic
   - Focus on Python-specific scenarios

8. **Refactor `git-pr-creator`**
   - Reference `jira-git-integration` for JIRA utilities
   - Reference `pr-creation-workflow` for PR logic

9. **Refactor `nextjs-pr-workflow`**
   - Reference `pr-creation-workflow` for PR logic
   - Reference `linting-workflow` for linting steps
   - Reference `jira-git-integration` for JIRA steps

10. **Refactor `git-issue-creator`**
    - Reference `ticket-branch-workflow` for core workflow
    - Focus on GitHub-specific logic

11. **Refactor `jira-git-workflow`**
    - Reference `ticket-branch-workflow` for core workflow
    - Focus on JIRA-specific logic

12. **Refactor `python-ruff-linter`**
    - Reference `linting-workflow` for core linting logic
    - Focus on Ruff-specific guidance

---

## Estimated Impact

### Lines of Code Savings

| Category | Current Lines | Optimized Lines | Savings |
|----------|---------------|-----------------|----------|
| Test Creation | 2383 (1581+802) | ~1200 (framework + 2 language skills) | ~1183 |
| JIRA Integration | 645 (533+112) | ~350 (framework + 2 skills) | ~295 |
| PR Creation | 834 (533+301) | ~550 (framework + 2 skills) | ~284 |
| Ticket/Branch/PLAN | 502 (390+112) | ~300 (framework + 2 skills) | ~202 |
| Linting | 329 (301+28) | ~150 (framework + 2 skills) | ~179 |

**Total Estimated Savings:** ~2,143 lines of documentation

### Maintainability Improvements

- **Reduced Duplication:** Common logic defined once
- **Easier Updates:** Fix bugs in framework skill, all dependent skills benefit
- **Better Discoverability:** Relevant skills section links to framework skills
- **Consistent UX:** Same patterns across similar workflows
- **Modular Architecture:** Easy to add new language/framework support

---

## Implementation Checklist

### Before Implementation
- [ ] Review and approve optimization plan
- [ ] Identify framework skill directory structure
- [ ] Decide on naming conventions for framework skills
- [ ] Plan migration strategy (incremental vs. batch)

### Implementation Tasks
- [ ] Create `skills/test-generator-framework/SKILL.md`
- [ ] Create `skills/jira-git-integration/SKILL.md`
- [ ] Create `skills/pr-creation-workflow/SKILL.md`
- [ ] Create `skills/ticket-branch-workflow/SKILL.md`
- [ ] Create `skills/linting-workflow/SKILL.md`
- [ ] Refactor `nextjs-unit-test-creator` to use framework
- [ ] Refactor `python-pytest-creator` to use framework
- [ ] Refactor `git-pr-creator` to use frameworks
- [ ] Refactor `nextjs-pr-workflow` to use frameworks
- [ ] Refactor `git-issue-creator` to use framework
- [ ] Refactor `jira-git-workflow` to use framework
- [ ] Refactor `python-ruff-linter` to use framework

### After Implementation
- [ ] Test all refactored skills
- [ ] Verify no functionality was lost
- [ ] Update AGENTS.md with new skill references
- [ ] Update README.md with skill overview
- [ ] Create migration guide for users

---

## Conclusion

The skills directory contains significant redundancy across multiple categories. By extracting common workflows into reusable framework skills, we can:

1. **Reduce duplication by ~2,143 lines** of documentation
2. **Improve maintainability** through single-source-of-truth patterns
3. **Enhance consistency** across similar workflows
4. **Enable easier extension** for new languages/frameworks
5. **Improve discoverability** via "Relevant Skills" sections

The proposed optimization strategy creates 5 new reusable framework skills and refactors 8 existing skills to reference them. This modular architecture aligns with DRY principles and provides a more sustainable long-term maintenance model.

---

## Appendix: Cross-Reference Matrix

```
                    +--------------+--------------+--------------+--------------+
                    | Test Create  | JIRA + Git   | PR Creation  |
+-------------------+--------------+--------------+--------------+--------------+
| nextjs-unit-test  |      ●       |              |              |
| python-pytest     |      ●       |              |              |
| git-pr-creator    |              |      ●       |      ●       |
| jira-git-workflow  |              |      ●       |              |
| nextjs-pr-workflow |              |      ●       |      ●       |
+-------------------+--------------+--------------+--------------+--------------+

                    +--------------+--------------+
                    | Ticket/Branch | Linting     |
+-------------------+--------------+--------------+
| git-issue-creator  |      ●       |              |
| jira-git-workflow  |      ●       |              |
| nextjs-pr-workflow |              |      ●       |
| python-ruff-linter |              |      ●       |
+-------------------+--------------+--------------+

Key: ● = Participates in this redundancy category
```
