# PLAN-GIT-204: Add documentation-consistency-skill — audit + auto-fix doc drift

**Issue**: [#204](https://github.com/darellchua2/opencode-config-template/issues/204)
**Branch**: `GIT-204`
**Status**: Completed

---

## Problem

The repo manages 73+ skills, 29+ subagents, and multiple config files that cross-reference each other (setup scripts, README tables, AGENTS.md routing tables, PLAN files). After repeated changes:

- Skill/agent counts in deploy scripts silently drift from reality
- PLAN.md checkboxes may not reflect actual implementation state
- Structural sections get dropped or malformed
- References to removed skills/agents linger as orphans

The existing `documentation-sync-workflow-skill` handles **add/remove** workflows but not ongoing drift detection.

## Solution

Create a new `documentation-consistency-skill` that performs 4 audit categories with auto-fix: cross-file count sync, PLAN vs reality drift, structural integrity, and orphan/stale reference detection.

---

## Phase 1: Create Skill Definition

- [x] Create `opencode_app/.opencode/skills/documentation-consistency-skill/SKILL.md`
- [x] Include frontmatter (name, description, metadata)
- [x] Include "What I do" section covering all 4 audit categories
- [x] Include "When to use me" with trigger phrases
- [x] Include audit category details (checks per category)
- [x] Include auto-fix strategy per category
- [x] Include validation commands (bash for each check type)
- [x] Include validation report template
- [x] Include validation levels (quick, standard, thorough, targeted)
- [x] Include integration with related skills section
- [x] Include common issues and best practices

## Phase 2: Sync Deploy Scripts

- [x] Update `deploy/setup.sh` — increment skill count (73 → 74), add to "OpenCode Meta" category (3 → 4)
- [x] Update `deploy/setup.ps1` — mirror setup.sh changes

## Phase 3: Sync Documentation

- [x] Update `README.md` Skill Categories table — add documentation-consistency-skill to OpenCode Meta row
- [x] Update `README.md` total skill count (73 → 74)
- [x] Update `AGENTS.md` skill count references (73 → 74)

---

## Acceptance Criteria

- [x] `documentation-consistency-skill/SKILL.md` exists with valid frontmatter
- [x] Skill covers all 4 audit categories (cross-file counts, PLAN drift, structural integrity, orphan references)
- [x] Supports 4 validation levels: quick, standard, thorough, targeted
- [x] Provides both audit (report-only) and auto-fix (guided edits) modes
- [x] Cross-references 5 related skills (documentation-sync, plan-updater, plan-execution, verification-loop, skills-maintainer)
- [x] Deploy scripts updated with accurate skill count and category listing
- [x] README.md and AGENTS.md updated with new counts

## Scope

| File | Action |
|------|--------|
| `opencode_app/.opencode/skills/documentation-consistency-skill/SKILL.md` | Create |
| `deploy/setup.sh` | Update (skill count 73→74 + category) |
| `deploy/setup.ps1` | Update (skill count 73→74 + category) |
| `README.md` | Update (Skill Categories table) |
| `AGENTS.md` | Update (skill count references) |

## Risks & Mitigation

| Risk | Severity | Mitigation |
|------|----------|-----------|
| Overlap with documentation-sync-workflow | Medium | Clear separation: sync = add/remove workflow, consistency = drift detection |
| Skill content too long | Low | Use validation command blocks and tables for conciseness |
| PLAN drift checks too noisy | Low | Validation levels allow scoped checks (quick vs thorough) |
