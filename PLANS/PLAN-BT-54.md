# PLAN-BT-54: Add git-compact-commits-skill

**JIRA**: [BT-54](https://betekk.atlassian.net/browse/BT-54)
**Branch**: `feature/git-compact-commits-skill`
**Type**: Task — New Skill Creation
**Priority**: Medium
**Created**: 2026-05-24

---

## Overview

Create a new skill `git-compact-commits-skill` that addresses gaps in existing commit-related skills:
- No word count limits for commit bodies
- No semantic grouping guidance
- No compact authoring techniques
- Basic CI enforcement only (commitlint defaults)

The skill provides both CI enforcement (commitlint config + GitHub Actions) and authoring guidance (grouping strategy, length budgets, compact writing).

## Acceptance Criteria

- [ ] Skill file created at `opencode_app/.opencode/skills/git-compact-commits-skill/SKILL.md`
- [ ] All 10 sections implemented with comprehensive content
- [ ] Custom commitlint word-count plugin code included
- [ ] commitlint.config.js with extended rules included
- [ ] GitHub Actions workflow YAML included
- [ ] `deploy/setup.sh` updated with new skill count and category listing
- [ ] `deploy/setup.ps1` updated with new skill count and category listing
- [ ] `README.md` updated with new skill in Skill Categories table
- [ ] `semantic-release-convention-skill` section 6.1 updated with cross-reference

## Scope

| File | Action |
|------|--------|
| `opencode_app/.opencode/skills/git-compact-commits-skill/SKILL.md` | Create |
| `deploy/setup.sh` | Update (skill count + listing) |
| `deploy/setup.ps1` | Update (skill count + listing) |
| `README.md` | Update (Skill Categories table) |
| `opencode_app/.opencode/skills/semantic-release-convention-skill/SKILL.md` | Update (cross-reference in section 6.1) |

---

## Phase 1: Create Skill File

- [ ] 1.1 Create directory `opencode_app/.opencode/skills/git-compact-commits-skill/`
- [ ] 1.2 Write `SKILL.md` with all 10 sections:
  - [ ] Section 1: What I Do (4 capabilities)
  - [ ] Section 2: When to Use Me (trigger phrases)
  - [ ] Section 3: Semantic Grouping Strategy (decision matrix, patterns, anti-patterns)
  - [ ] Section 4: Length Budgets (subject 72/50, body 150 words, lines 100 chars)
  - [ ] Section 5: Compact Writing Techniques (active voice, bullet points, scopes, omit "how")
  - [ ] Section 6: Commit Templates (multi-file, multi-concern, phase-based)
  - [ ] Section 7: GitHub Actions Enforcement (commitlint.config.js, word-count plugin, workflow YAML)
  - [ ] Section 8: Local Git Hook (pre-commit alternative)
  - [ ] Section 9: Integration (cross-refs to git-semantic-commits-skill and semantic-release-convention-skill)
  - [ ] Section 10: Verification Commands

## Phase 2: Sync Deployment Files

- [ ] 2.1 Update `deploy/setup.sh` — increment total skill count, add `git-compact-commits-skill` to Git category listing
- [ ] 2.2 Update `deploy/setup.ps1` — increment total skill count, add `git-compact-commits-skill` to Git category listing
- [ ] 2.3 Update `README.md` — add row to Skill Categories table under Git category

## Phase 3: Update Existing Skills

- [ ] 3.1 Update `semantic-release-convention-skill/SKILL.md` section 6.1 — add note pointing to `git-compact-commits-skill` for extended length budgets and CI enforcement

## Phase 4: Validation

- [ ] 4.1 Verify skill file follows existing skill structure conventions
- [ ] 4.2 Verify deploy scripts reference the skill correctly
- [ ] 4.3 Verify README table includes the skill
- [ ] 4.4 Run `deploy/setup.sh` dry-run validation (if applicable)

---

## Dependencies

None — this is a standalone skill addition with sync updates to existing files.

## Risks

| Risk | Mitigation |
|------|-----------|
| Skill count mismatch across deploy scripts | Update both setup.sh and setup.ps1 in same commit |
| README table formatting breaks | Follow existing markdown table format exactly |
| semantic-release-convention-skill cross-reference placement unclear | Add as a note/blockquote in section 6.1, not a structural change |

## Notes

- Skill number will increment from current count (check deploy/setup.sh for current total)
- Category: Git (alongside git-semantic-commits-skill, git-issue-labeler-skill, etc.)
- The skill complements but does not replace `git-semantic-commits-skill` (which covers commit message types, scopes, breaking changes)
