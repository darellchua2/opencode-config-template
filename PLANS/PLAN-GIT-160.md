# Plan: Audit git and PR-related skills for consolidation opportunities

## Issue Reference
- **Number**: #160
- **URL**: https://github.com/darellchua2/opencode-config-template/issues/160
- **Labels**: enhancement, skills

## Overview
Audit all 12 git-related, PR-related, and JIRA+Git integration skills for potential consolidation. Several skills have overlapping functionality that could be merged to reduce maintenance burden and improve clarity.

## Acceptance Criteria
- [ ] Dependency map of all 12 skills is documented
- [ ] Each overlap identified in the issue is confirmed or debunked with evidence
- [ ] Consolidation proposal is drafted with before/after skill count
- [ ] Impact analysis on agents and other consuming skills is completed
- [ ] Decision is made on which skills to merge, which to keep separate, and which to deprecate

## Scope
- `skills/git-issue-labeler/`
- `skills/git-issue-plan-workflow/`
- `skills/git-issue-updater/`
- `skills/git-pr-creator/`
- `skills/git-semantic-commits/`
- `skills/pr-creation-workflow/`
- `skills/nextjs-pr-workflow/`
- `skills/jira-git-integration/`
- `skills/jira-ticket-plan-workflow/`
- `skills/jira-status-updater/`
- `skills/semantic-release-convention/`
- `skills/plan-updater/`

---

## Phase 1: Dependency Mapping

- [ ] Document the full dependency graph of all 12 skills
- [ ] Identify which skills are **framework** skills (consumed by others) vs **workflow** skills (standalone)
- [ ] Map which agents consume which skills
- [ ] Note: `jira-ticket-oauth-workflow` and `jira-ticket-pat-workflow` do NOT exist in the repo (mentioned in issue but already removed/never created)

### Known Dependency Graph (from skill analysis)

```
semantic-release-convention (governance)
  ├── git-semantic-commits (framework)
  │   └── consumed by: git-pr-creator, pr-creation-workflow, nextjs-pr-workflow, git-issue-plan-workflow
  ├── git-pr-creator (workflow)
  │   └── consumes: git-semantic-commits, git-issue-updater, jira-status-updater, jira-git-integration
  ├── pr-creation-workflow (framework)
  │   ├── consumed by: nextjs-pr-workflow, git-pr-creator
  │   └── consumes: git-semantic-commits, git-issue-updater, jira-status-updater, jira-git-integration
  ├── git-issue-labeler (standalone)
  │   └── consumed by: git-issue-plan-workflow
  └── git-issue-plan-workflow (workflow)
      └── consumes: git-issue-labeler, git-semantic-commits, git-issue-updater

jira-git-integration (framework)
  ├── consumed by: git-pr-creator, pr-creation-workflow, nextjs-pr-workflow, jira-ticket-plan-workflow, jira-status-updater
  └── provides: JIRA API utilities (cloud ID, projects, tickets, comments, images, branches)

jira-status-updater (framework)
  ├── consumed by: git-pr-creator, pr-creation-workflow
  └── consumes: jira-git-integration

jira-ticket-plan-workflow (workflow)
  └── consumes: jira-git-integration

git-issue-updater (framework)
  ├── consumed by: git-pr-creator, pr-creation-workflow, nextjs-pr-workflow, git-issue-plan-workflow
  └── provides: GitHub + JIRA comment updates with commit details

plan-updater (utility)
  └── consumed by: pr-workflow-subagent, refactoring-subagent, testing-subagent

nextjs-pr-workflow (framework-specific extension)
  └── consumes: pr-creation-workflow, linting-workflow, jira-git-integration, git-semantic-commits, git-issue-updater
```

### Agent Consumers

| Agent | Skills Consumed |
|-------|----------------|
| `pr-workflow-subagent` | pr-creation-workflow, plan-updater |
| `ticket-creation-subagent` | git-issue-labeler, git-semantic-commits, semantic-release-convention |

---

## Phase 2: Overlap Analysis

- [ ] **Overlap 1**: `git-pr-creator` vs `pr-creation-workflow` — confirm redundancy
- [ ] **Overlap 2**: `jira-ticket-plan-workflow` vs `git-issue-plan-workflow` — confirm parallel patterns
- [ ] **Overlap 3**: Semantic versioning label logic scattered across skills
- [ ] **Overlap 4**: `git-semantic-commits` role relative to `semantic-release-convention`
- [ ] **Overlap 5**: Image handling logic duplicated in `git-pr-creator` and `jira-git-integration`

### Overlap 1: git-pr-creator vs pr-creation-workflow

**Evidence**:
- `git-pr-creator` (638 lines): Standalone PR creation with JIRA integration, image upload, semver labels
- `pr-creation-workflow` (562 lines): Framework for PR creation with framework detection, quality checks, multi-platform
- `git-pr-creator` is listed as a consumer of `pr-creation-workflow` in pr-creation-workflow's "Relevant Skills" section
- But `git-pr-creator` does NOT actually reference `pr-creation-workflow` in its own SKILL.md
- Both duplicate: semver label detection logic, JIRA comment templates, image handling
- `pr-creation-workflow` is MORE capable (framework detection, quality checks, configurable targets)

**Verdict**: `git-pr-creator` is a superset that duplicates `pr-creation-workflow` features plus adds JIRA image handling. They should be consolidated.

### Overlap 2: git-issue-plan-workflow vs jira-ticket-plan-workflow

**Evidence**:
- `git-issue-plan-workflow` (537 lines): GitHub issues → branch GIT-123 → PLANS/PLAN-GIT-123.md
- `jira-ticket-plan-workflow` (459 lines): JIRA tickets → branch PROJ-123 → PLANS/PLAN-PROJ-123.md
- Nearly identical structure: gather requirements → determine scope → create ticket → create branch → generate PLAN → commit/push → prompt execution
- Both use the same PLAN template structure with 5 phases
- Both consume: git-semantic-commits, git-issue-updater
- `plan-updater` already supports BOTH naming conventions (PLAN-GIT-*.md and PLAN-*.md)

**Verdict**: Strong consolidation candidate. Could become a single `ticket-plan-workflow` with platform parameter.

### Overlap 3: Semantic versioning label logic

**Evidence**:
- `semantic-release-convention` defines label mapping (governance)
- `git-pr-creator` duplicates the label detection bash logic (~15 lines)
- `pr-creation-workflow` duplicates the SAME label detection bash logic (~15 lines)
- `nextjs-pr-workflow` duplicates the SAME label detection bash logic (~15 lines)
- `git-issue-labeler` defines the label descriptions and detection keywords

**Verdict**: The detection logic is duplicated 3 times. Should be defined once in `semantic-release-convention` and referenced by others. The duplication is acceptable if each skill just points to the convention, but currently they inline the full bash logic.

### Overlap 4: git-semantic-commits vs semantic-release-convention

**Evidence**:
- `git-semantic-commits` (722 lines): Detailed commit type definitions, examples, templates, validation scripts
- `semantic-release-convention` (411 lines): Governance document defining conventions for the full release pipeline
- `git-semantic-commits` states: "For the full release pipeline conventions, see semantic-release-convention"
- `semantic-release-convention` lists `git-semantic-commits` as a governed skill
- These have DIFFERENT concerns: one is a format reference, the other is governance

**Verdict**: NOT redundant. These are properly layered — governance vs implementation detail. Keep both.

### Overlap 5: Image handling in git-pr-creator vs jira-git-integration

**Evidence**:
- `git-pr-creator` has ~100 lines of image detection, categorization, and handling logic
- `jira-git-integration` has ~50 lines of the SAME image detection patterns
- `git-pr-creator` explicitly notes: "For comprehensive image handling, see jira-git-integration"
- But `git-pr-creator` still inlines the logic instead of deferring

**Verdict**: `git-pr-creator` should defer image handling to `jira-git-integration` instead of duplicating.

---

## Phase 3: Consolidation Proposal

- [ ] Draft proposed consolidated skill structure
- [ ] Identify which skills to merge, keep, or deprecate
- [ ] Calculate before/after skill count
- [ ] Document migration plan for consuming agents/skills

### Proposed Consolidation

| # | Before (Current) | After (Proposed) | Action |
|---|------------------|-------------------|--------|
| 1 | `git-pr-creator` | MERGE into `pr-creation-workflow` | Merge JIRA image handling into pr-creation-workflow |
| 2 | `pr-creation-workflow` | Keep (enhanced) | Add JIRA image handling from git-pr-creator |
| 3 | `nextjs-pr-workflow` | Keep | No change, already extends pr-creation-workflow |
| 4 | `git-issue-plan-workflow` | MERGE into `ticket-plan-workflow` | Combine with jira-ticket-plan-workflow |
| 5 | `jira-ticket-plan-workflow` | MERGE into `ticket-plan-workflow` | Combine with git-issue-plan-workflow |
| 6 | `git-semantic-commits` | Keep | Properly layered with semantic-release-convention |
| 7 | `semantic-release-convention` | Keep (enhanced) | Add shared semver label detection logic |
| 8 | `git-issue-labeler` | Keep | Unique functionality |
| 9 | `git-issue-updater` | Keep | Unique framework skill |
| 10 | `jira-git-integration` | Keep | Unique framework skill |
| 11 | `jira-status-updater` | Keep | Unique framework skill |
| 12 | `plan-updater` | Keep | Unique utility skill |

### Summary
- **Before**: 12 skills
- **After**: 9 skills (merge 3 into 2, deprecate 1)
- **Merges**: 
  - `git-pr-creator` → `pr-creation-workflow` (reduce from 2 to 1)
  - `git-issue-plan-workflow` + `jira-ticket-plan-workflow` → `ticket-plan-workflow` (reduce from 2 to 1)
- **Deprecations**: `git-pr-creator` (merged into pr-creation-workflow)
- **New skills**: `ticket-plan-workflow` (unified planning workflow)

### Migration Impact

**Agents affected**:
- `pr-workflow-subagent`: References `pr-creation-workflow` (no change needed)
- `ticket-creation-subagent`: References `git-issue-labeler`, `git-semantic-commits` (no change needed)

**Skills affected**:
- Skills referencing `git-pr-creator` need to reference `pr-creation-workflow` instead
- Skills referencing `git-issue-plan-workflow` or `jira-ticket-plan-workflow` need to reference `ticket-plan-workflow`
- `semantic-release-convention` governed skills table needs updating

**Files to update**:
- `setup.sh` — skill listings and counts
- `setup.ps1` — skill listings and counts
- `README.md` — skill categories table
- `AGENTS.md` — routing instructions
- `.AGENTS.md` — subagent routing
- `config.json` — if any agent configs reference skill names

---

## Phase 4: Implementation

- [ ] Create `ticket-plan-workflow` skill (merged from git-issue-plan-workflow + jira-ticket-plan-workflow)
- [ ] Enhance `pr-creation-workflow` with JIRA image handling from git-pr-creator
- [ ] Move `git-pr-creator` to `_archived/`
- [ ] Move `git-issue-plan-workflow` to `_archived/`
- [ ] Move `jira-ticket-plan-workflow` to `_archived/`
- [ ] Update `semantic-release-convention` governed skills table
- [ ] Update all skill cross-references (SKILL.md files that reference merged skills)
- [ ] Update `setup.sh` skill listings
- [ ] Update `setup.ps1` skill listings
- [ ] Update `README.md` tables and counts
- [ ] Update `AGENTS.md` routing

---

## Phase 5: Validation

- [ ] Verify no skill references point to deprecated skills
- [ ] Run `setup.sh` to verify deployment still works
- [ ] Verify all agent routing still functions
- [ ] Update issue #160 with final consolidation results
