# Plan: Rename skill and agent folders with type-suffix conventions

## Issue Reference
- **Number**: #162
- **URL**: https://github.com/darellchua2/opencode-config-template/issues/162
- **Labels**: enhancement, refactoring, documentation, minor

## Overview

Rename all 51 skill folders with a `-skill` suffix and normalize 3 agent file suffixes for clearer type differentiation. Update all references across config, documentation, and cross-reference files.

## Acceptance Criteria
- [x] GitHub issue created (#162)
- [x] Branch created (GIT-162)
- [ ] All 51 skill folders renamed with `-skill` suffix
- [ ] 3 agent files renamed with `-subagent` suffix
- [ ] All references updated in setup.sh, setup.ps1, README.md, AGENTS.md, .AGENTS.md, config.json
- [ ] Cross-references inside SKILL.md and agent .md files updated
- [ ] No broken references remain (grep validation)
- [ ] setup.sh runs successfully

## Scope
- `skills/` — 51 folders (renamed)
- `agents/` — 3 files (renamed)
- `setup.sh`, `setup.ps1` — deploy scripts
- `README.md`, `AGENTS.md`, `.AGENTS.md` — documentation
- `config.json` — agent definitions
- Internal `SKILL.md` and agent `.md` files — cross-references

---

## Implementation Phases

### Phase 1: Rename Skill Folders
- [ ] Create batch rename script for 51 skill folders
- [ ] Execute `git mv` for each skill folder (e.g., `ascii-diagram-creator/` → `ascii-diagram-creator-skill/`)
- [ ] Exclude `_archived/` from renaming
- [ ] Verify all 51 folders renamed correctly with `ls skills/`

### Phase 2: Rename Agent Files
- [ ] `git mv agents/civil-3d-specialist.md agents/civil-3d-specialist-subagent.md`
- [ ] `git mv agents/image-analyzer.md agents/image-analyzer-subagent.md`
- [ ] `git mv agents/open3d-specialist.md agents/open3d-specialist-subagent.md`
- [ ] Verify all 30 agent files have correct suffixes

### Phase 3: Update Deployment Scripts
- [ ] Update `setup.sh` — all skill folder names in copy commands, counts, category listings
- [ ] Update `setup.ps1` — all skill folder names in copy commands, counts, category listings
- [ ] Validate syntax of both scripts

### Phase 4: Update Documentation Files
- [ ] Update `README.md` — Skill Categories table with new names
- [ ] Update `README.md` — Subagents table (agent renames)
- [ ] Update `AGENTS.md` — project-level subagent references
- [ ] Update `.AGENTS.md` — skill/agent references
- [ ] Update `config.json` — agent file references if any use folder names

### Phase 5: Update Internal Cross-References
- [ ] Search all `SKILL.md` files for references to other skills and update
- [ ] Search all agent `.md` files for references to skills/agents and update
- [ ] Grep validation: search for old skill/agent names without `-skill`/`-subagent` suffix

### Phase 6: Validation & Cleanup
- [ ] Run `rg` to find any remaining old-name references without `-skill` suffix
- [ ] Run `rg` to find any remaining old agent names without `-subagent` suffix
- [ ] Run `setup.sh` dry-run or syntax check
- [ ] Review all changes with `git diff --stat`
- [ ] Stage and commit all renames and reference updates

---

## Technical Notes
- Use `git mv` exclusively to preserve git history for each rename
- Batch script pattern: `for dir in skills/*/; do git mv "$dir" "${dir%/}-skill"; done` (excluding _archived)
- Validate with: `rg "ascii-diagram-creator[^-]"` style patterns after rename
- Order of operations matters: rename first, then update references, then validate
- The `_archived/` folder must NOT be renamed

## Dependencies
- None — this is a self-contained refactoring task

## Risks & Mitigation
| Risk | Mitigation |
|------|-----------|
| Missed cross-references | Comprehensive grep validation in Phase 6 |
| Broken deployment scripts | Test `setup.sh` after updates |
| Git history loss | Use `git mv` not `mv` |
| Large diff noise | Commit renames separately from reference updates |

## Success Metrics
- All 51 skill folders have `-skill` suffix
- All 30 agent files have consistent type suffixes (`-subagent`, `-primary-agent`)
- Zero broken references detected by grep
- `setup.sh` executes without errors
