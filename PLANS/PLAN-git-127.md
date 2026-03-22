# PLAN: Consolidate direct duplicate skills - Phase 1

## Ticket Reference
- **Issue**: #127
- **URL**: https://github.com/darellchua2/opencode-config-template/issues/127
- **Labels**: refactoring, skills, phase-1
- **Branch**: refactor/127-skill-consolidation
## Overview
Consolidate 2 sets of directly redundant skills by deprecating duplicates and enhancing the primary skills.
## Changes Summary
| Before | After | Change |
|------|------|-------|
| 50 skills | 47 skills | -3 skills archived |
| `nextjs-complete-setup` | `skills/_archived/` | Archived (redundant with `nextjs-standard-setup`) |
| `python-docstring-generator` | `skills/_archived/` | Archived (redundant with `docstring-generator`) |
| `nextjs-tsdoc-documentor` | `skills/_archived/` | Archived (redundant with `docstring-generator`) |
## Tasks

### 1.1 Archive Redundant Skills
- [x] Create `skills/_archived/` directory
- [x] Move `nextjs-complete-setup/` to `skills/_archived/nextjs-complete-setup/`
- [x] Move `python-docstring-generator` into `skills/_archived/python-docstring-generator/`
- [x] Move `nextjs-tsdoc-documentor` into `skills/_archived/nextjs-tsdoc-documentor/`
- [x] Create `skills/_archived/README.md` explaining archive purpose
### 1.2 Update setup.sh
- [x] Update skill count: 50 → 47
- [x] Update skill listings:
  - Language-specific (4→3): `python-pytest-creator`, `python-ruff-linter`, `javascript-eslint-linter`
  - Framework-Specific (7→5): `nextjs-pr-workflow`, `nextjs-unit-test-creator`, `nextjs-standard-setup`, `nextjs-image-usage`, `typescript-dry-principle`
- [x] Exclude `_archived` from deployment (update `cp -r` command)
### 1.3 Update setup.ps1
- [x] Update skill count: 50 → 47
- [x] Update skill listings (same changes as setup.sh)
- [x] Exclude `_archived` from deployment
### 1.4 Update README.md
- [x] Update skill tables:
  - Total skills: 50 → 47
  - Language-specific (4→3)
  - Framework-Specific (7→5)
- [x] Update subagent references:
  - `nextjs-setup-subagent`: Remove `nextjs-complete-setup` reference
  - `documentation-subagent`: Update to reference `docstring-generator` instead of specific skills
### 1.5 Update AGENTS.md
- [x] Update skill counts in subagent routing section
### 1.6 Update nextjs-standard-setup (Optional Enhancement)
- [x] Update description to mention optional TSDoc step
- [x] Add note about using `docstring-generator` for all documentation needs
## Files Affected
- `skills/_archived/` (new directory + README.md)
- `skills/nextjs-standard-setup/SKILL.md` (optional update)
- `skills/docstring-generator/SKILL.md` (no changes needed)
- `setup.sh` (lines 534-568)
- `setup.ps1` (lines 304-336)
- `README.md` (lines 132-180)
- `AGENTS.md` (subagent routing section)
- `PLANS/PLAN-git-127.md` (this file)
## Verification Commands
```bash
npm run build     # Verify TypeScript
npm run type-check  # Verify no build errors
# Verify linting
npm run lint
# Verify README renders correctly
```
## Acceptance Criteria
- [x] All 3 redundant skills archived to `skills/_archived/`
- [x] Archive README created
- [x] setup.sh shows 47 skills (not 50)
- [x] setup.ps1 shows 47 skills (not 50)
- [x] README.md shows 47 skills (not 50)
- [x] setup.sh excludes `_archived` from deployment
- [x] setup.ps1 excludes `_archived` from deployment
- [x] All documentation synchronized
- [x] No functional loss - capabilities preserved in remaining skills
