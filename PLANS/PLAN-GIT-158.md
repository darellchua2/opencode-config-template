# Plan: Standardize Semantic Commit, PR, Merge, Release Convention & GitHub Actions

## Issue Reference
- **Number**: #158
- **URL**: https://github.com/darellchua2/opencode-config-template/issues/158
- **Labels**: enhancement, documentation

## Overview
Formalize a single standardized approach for semantic commit messages, PR conventions, merge strategies, and release tagging across all skills and agents. Create a new governance skill (`semantic-release-convention`) as the single source of truth for the entire commit → PR → merge → release → CI/CD pipeline.

## Acceptance Criteria
- [ ] New `semantic-release-convention` skill created with full convention definitions
- [ ] Skill defines: commit rules, PR title rules, PR label rules, merge strategy, release tag format, GitHub Actions requirements
- [ ] Skill includes branch-aware release tag mapping table
- [ ] All existing PR/workflow skills updated to reference the governance skill
- [ ] Both agents (`pr-workflow-subagent`, `ticket-creation-subagent`) updated with new skill permission
- [ ] Documentation synced (setup.sh, setup.ps1, README.md, AGENTS.md)
- [ ] Skill follows OpenCode skill naming conventions and frontmatter standards

## Scope
- `skills/semantic-release-convention/SKILL.md` (NEW)
- `skills/git-semantic-commits/SKILL.md` (UPDATE)
- `skills/git-pr-creator/SKILL.md` (UPDATE)
- `skills/pr-creation-workflow/SKILL.md` (UPDATE)
- `skills/nextjs-pr-workflow/SKILL.md` (UPDATE)
- `skills/git-issue-labeler/SKILL.md` (UPDATE)
- `skills/changelog-python-cliff/SKILL.md` (UPDATE)
- `agents/pr-workflow-subagent.md` (UPDATE)
- `agents/ticket-creation-subagent.md` (UPDATE)
- `setup.sh` (UPDATE)
- `setup.ps1` (UPDATE)
- `README.md` (UPDATE)
- `AGENTS.md` (UPDATE)

---

## Implementation Phases

### Phase 1: Create Governance Skill
- [ ] Create `skills/semantic-release-convention/SKILL.md` with OpenCode skill frontmatter
- [ ] Define commit message convention section (Conventional Commits spec)
- [ ] Define PR title convention section
- [ ] Define PR label rules section (major/minor/patch as single decision factor)
- [ ] Define merge message convention section (squash merge strategy)
- [ ] Define release tag convention section with branch-aware mapping table
- [ ] Define GitHub Actions requirements section (4 workflows)
- [ ] Include reference links to Conventional Commits v1.0.0 and SemVer 2.0.0 specs
- [ ] Make skill consumable by agents/skills that create commits, PRs, or releases
- [ ] Verify skill naming conventions with `opencode-skills-maintainer`

### Phase 2: Update Existing Skills
- [ ] Update `skills/git-semantic-commits/SKILL.md` — add reference to governance skill, remain as formatting utility
- [ ] Update `skills/git-pr-creator/SKILL.md` — load governance skill for label enforcement rules
- [ ] Update `skills/pr-creation-workflow/SKILL.md` — load governance skill for merge/release conventions
- [ ] Update `skills/nextjs-pr-workflow/SKILL.md` — inherits via pr-creation-workflow, verify cascade
- [ ] Update `skills/git-issue-labeler/SKILL.md` — load governance skill for semver label definitions
- [ ] Update `skills/changelog-python-cliff/SKILL.md` — load governance skill for release tag format

### Phase 3: Update Agents
- [ ] Update `agents/pr-workflow-subagent.md` — add `semantic-release-convention: allow` to permissions
- [ ] Update `agents/ticket-creation-subagent.md` — add `semantic-release-convention: allow` to permissions

### Phase 4: Documentation Sync
- [ ] Run `documentation-sync-workflow` to update setup.sh, setup.ps1, README.md, AGENTS.md
- [ ] Increment total skill count in setup.sh and setup.ps1
- [ ] Add skill to appropriate category in both setup files
- [ ] Update README.md skill categories table
- [ ] Update README.md total counts
- [ ] Add routing info to AGENTS.md if needed

### Phase 5: Validation
- [ ] Verify all cross-references between skills are correct
- [ ] Verify frontmatter standards are met for the new skill
- [ ] Verify no duplicate conventions across skills
- [ ] Run `opencode-skills-maintainer` to validate skill consistency
- [ ] Test that the governance skill can be loaded by other skills
- [ ] Final review of all changed files

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
