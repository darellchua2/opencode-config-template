# Plan: Standardize Semantic Commit, PR, Merge, Release Convention & GitHub Actions

## Issue Reference
- **Number**: #158
- **URL**: https://github.com/darellchua2/opencode-config-template/issues/158
- **Labels**: enhancement, documentation

## Overview
Formalize a single standardized approach for semantic commit messages, PR conventions, merge strategies, and release tagging across all skills and agents. Create a new governance skill (`semantic-release-convention`) as the single source of truth for the entire commit → PR → merge → release → CI/CD pipeline.

## Acceptance Criteria
- [x] New `semantic-release-convention` skill created with full convention definitions
- [x] Skill defines: commit rules, PR title rules, PR label rules, merge strategy, release tag format, GitHub Actions requirements
- [x] Skill includes branch-aware release tag mapping table
- [x] All existing PR/workflow skills updated to reference the governance skill
- [x] Both agents (`pr-workflow-subagent`, `ticket-creation-subagent`) updated with new skill permission
- [x] Documentation synced (setup.sh, setup.ps1, README.md, AGENTS.md)
- [x] Skill follows OpenCode skill naming conventions and frontmatter standards
- [x] New agents (`pptx-specialist-subagent`, `startup-ceo-subagent`) added to README tables
- [x] Primary agents (`business-development-primary-agent`, `startup-founder-primary-agent`) set to `mode: all`

## Scope
- `skills/semantic-release-convention/SKILL.md` (NEW - DONE)
- `skills/git-semantic-commits/SKILL.md` (UPDATE - DONE)
- `skills/git-pr-creator/SKILL.md` (UPDATE - DONE)
- `skills/pr-creation-workflow/SKILL.md` (UPDATE - DONE)
- `skills/nextjs-pr-workflow/SKILL.md` (UPDATE - DONE)
- `skills/git-issue-labeler/SKILL.md` (UPDATE - DONE)
- `skills/changelog-python-cliff/SKILL.md` (UPDATE - DONE)
- `agents/pr-workflow-subagent.md` (UPDATE - DONE)
- `agents/ticket-creation-subagent.md` (UPDATE - DONE)
- `agents/business-development-primary-agent.md` (UPDATE - DONE: mode primary → all)
- `agents/startup-founder-primary-agent.md` (UPDATE - DONE: mode primary → all, startup-ceo delegation)
- `setup.sh` (UPDATE - DONE)
- `setup.ps1` (UPDATE - DONE)
- `README.md` (UPDATE - DONE)
- `AGENTS.md` (no change needed)

---

## Implementation Phases

### Phase 1: Create Governance Skill — DONE
- [x] Create `skills/semantic-release-convention/SKILL.md` with OpenCode skill frontmatter
- [x] Define commit message convention section (Conventional Commits spec)
- [x] Define PR title convention section
- [x] Define PR label rules section (major/minor/patch as single decision factor)
- [x] Define merge message convention section (squash merge strategy)
- [x] Define release tag convention section with branch-aware mapping table
- [x] Define GitHub Actions requirements section (4 workflows)
- [x] Include reference links to Conventional Commits v1.0.0 and SemVer 2.0.0 specs
- [x] Make skill consumable by agents/skills that create commits, PRs, or releases
- [x] Verify skill naming conventions with `opencode-skills-maintainer`

### Phase 2: Update Existing Skills — DONE
- [x] Update `skills/git-semantic-commits/SKILL.md` — add reference to governance skill, remain as formatting utility
- [x] Update `skills/git-pr-creator/SKILL.md` — add Governance section referencing conventions
- [x] Update `skills/pr-creation-workflow/SKILL.md` — add Governance section + skill to Frameworks Used
- [x] Update `skills/nextjs-pr-workflow/SKILL.md` — add governance note to Frameworks Used
- [x] Update `skills/git-issue-labeler/SKILL.md` — add Governance section referencing conventions
- [x] Update `skills/changelog-python-cliff/SKILL.md` — add Governance section + dependency

### Phase 3: Update Agents — DONE
- [x] Update `agents/pr-workflow-subagent.md` — add `semantic-release-convention: allow` to permissions
- [x] Update `agents/ticket-creation-subagent.md` — add `semantic-release-convention: allow` to permissions

### Phase 4: Documentation Sync — DONE
- [x] Increment total skill count in setup.sh (51→52) and setup.ps1 (51→52)
- [x] Add `semantic-release-convention` to Git/Workflow category in both setup files (8→9)
- [x] Update README.md skill categories table (51→52 skills, Git/Workflow 8→9)
- [x] Update banner skill counts in setup.sh (50→52) and setup.ps1 (50→52)
- [x] Add `pptx-specialist-subagent` and `startup-ceo-subagent` to README.md Subagents table
- [x] Add trigger phrases for both new agents to README.md
- [x] Update README.md agent count (4 primary + 26 subagents → 4 primary + 28 subagents)

### Phase 5: Agent Updates — DONE
- [x] Add `startup-ceo-subagent` to `startup-founder-primary-agent.md` delegation table
- [x] Update `startup-founder-primary-agent.md` presentations workflow to reference both agents
- [x] Change `business-development-primary-agent.md` mode: primary → all
- [x] Change `startup-founder-primary-agent.md` mode: primary → all

### Phase 6: Validation — DONE
- [x] Verify all cross-references between skills are correct
- [x] Verify frontmatter standards are met for the new skill
- [x] Verify no duplicate conventions across skills
- [x] Verify all 6 skills reference `semantic-release-convention`
- [x] Verify both agents have `semantic-release-convention: allow` permission
- [x] Verify documentation counts match (52 skills)
- [x] Final review of all changed files

---

## Technical Notes

### Key Specifications
- **Conventional Commits v1.0.0**: https://www.conventionalcommits.org/
- **Semantic Versioning 2.0.0**: https://semver.org/

### Label Colors
| Label | Color | Hex |
|-------|-------|-----|
| major | Red | #d73a4a |
| minor | Yellow | #fbca04 |
| patch | Green | #0e8a16 |

### Branch-Aware Release Tag Mapping
| Branch Pattern | Tag Format | Example |
|---------------|------------|---------|
| main/master/production | `vX.Y.Z` | v1.0.0 |
| uat | `vX.Y.Z-uat.N` | v1.0.0-uat.1 |
| staging | `vX.Y.Z-staging.N` | v1.0.0-staging.1 |
| dev | `vX.Y.Z-dev.N` | v1.0.0-dev.1 |
| pre-dev | `vX.Y.Z-pre-dev.N` | v1.0.0-pre-dev.1 |

### GitHub Actions Required
1. **Commit Lint** — Enforce Conventional Commits on push
2. **PR Title Validation** — Validate PR title follows Conventional Commits
3. **Semver Label Enforcement** — Ensure exactly 1 semver label per PR
4. **Automated Release** — Auto-version, tag, and create GitHub Release on merge

### Skills Dependency Graph
```
semantic-release-convention (governance)
├── git-semantic-commits (formatting utility)
├── git-pr-creator (label enforcement)
├── pr-creation-workflow (merge/release conventions)
│   └── nextjs-pr-workflow (inherits)
├── git-issue-labeler (semver label definitions)
└── changelog-python-cliff (release tag format)
```

### Agent Mode Changes
| Agent | Before | After | Reason |
|-------|--------|-------|--------|
| business-development-primary-agent | mode: primary | mode: all | Allows invocation as subagent via @mention or Task tool |
| startup-founder-primary-agent | mode: primary | mode: all | Allows invocation as subagent via @mention or Task tool |

## Dependencies
- None — this is a foundational governance change

## Risks & Mitigation
| Risk | Mitigation |
|------|------------|
| Circular references between skills | Clearly define governance as top-level; others only reference, don't implement |
| Breaking existing workflows | Keep `git-semantic-commits` as-is, only add reference to governance skill |
| Documentation drift | Use `documentation-sync-workflow` for all doc updates |
| Version conflict in conventions | Governance skill is the single source of truth; all others defer to it |

## Success Metrics
- Single source of truth for all semantic conventions established
- All 6 existing skills consistently reference the governance skill
- Both agents have proper skill permissions
- Documentation is fully synchronized across all 4 files
- Zero convention conflicts between skills
- Both primary agents accessible as subagents (mode: all)
