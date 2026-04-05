# Plan: Add changelog implementation skill for Python using git-cliff

## Issue Reference
- **Number**: #142
- **URL**: https://github.com/darellchua2/opencode-config-template/issues/142
- **Labels**: enhancement, minor

## Overview
Create a new OpenCode skill (`changelog-python-cliff`) that implements automated changelog generation for Python projects using [git-cliff](https://git-cliff.org) as the implementation method. The skill should follow existing repository conventions and integrate with the deployment workflow.

## Acceptance Criteria
- [ ] Skill directory exists at `skills/changelog-python-cliff/SKILL.md`
- [ ] SKILL.md follows existing repository skill conventions (frontmatter, sections, formatting)
- [ ] cliff.toml template included with Python-specific formatting
- [ ] setup.sh updated with new skill listing and correct counts
- [ ] setup.ps1 updated with new skill listing and correct counts
- [ ] README.md Skill Categories table updated with new skill and correct counts
- [ ] Documentation sync workflow passes without errors

## Scope
- `skills/changelog-python-cliff/` (new directory)
- `setup.sh` (skill listings and counts - Language-Specific category)
- `setup.ps1` (skill listings and counts - Language-Specific category)
- `README.md` (Skill Categories table and intro paragraph count)

---

## Implementation Phases

### Phase 1: Create Skill Directory and SKILL.md
- [ ] Create directory `skills/changelog-python-cliff/`
- [ ] Create `SKILL.md` with proper frontmatter (name, description, license, compatibility, metadata)
- [ ] Include "What I do" section describing git-cliff based changelog generation workflow
- [ ] Include "When to use me" section with trigger scenarios
- [ ] Include "Prerequisites" section (git-cliff installed, conventional commits, Python project)
- [ ] Include detailed steps for:
  - Analyzing Python project version (from `pyproject.toml`, `__init__.py`, or `setup.py`)
  - Generating/updating `cliff.toml` with Python-specific configuration
  - Running `git cliff` to generate changelogs
  - PEP 440 versioning support (e.g., `1.0.0a1`, `1.0.0rc1`, `1.0.0.post1`)
  - Conventional commits parsing via git-cliff built-in parser
- [ ] Include "When NOT to use me" section (non-Python projects, non-git repos)
- [ ] Include "Dependencies" section referencing related skills
- [ ] Include cliff.toml template as a reference section within SKILL.md

### Phase 2: Include cliff.toml Template Configuration
- [ ] Create inline cliff.toml template within SKILL.md reference section
- [ ] Configure Python-specific changelog formatting:
  - PEP 440 version regex pattern
  - Python release types (alpha, beta, rc, post, dev)
  - Proper version ordering for Python packages
- [ ] Configure conventional commits categories:
  - `feat` → Features
  - `fix` → Bug Fixes
  - `docs` → Documentation
  - `refactor` → Refactoring
  - `perf` → Performance
  - `test` → Testing
  - `build` → Build System
  - `ci` → CI/CD
  - `chore` → Miscellaneous
- [ ] Include CI/CD integration guidance (GitHub Actions, GitLab CI)
- [ ] Include guidance on integrating with Python release workflows (`bump-my-version`, `semantic-release`, manual)

### Phase 3: Update Deployment Scripts
- [ ] Update `setup.sh`:
  - Line ~541: Increment SKILLS count from 49 to 50
  - Line ~547: Add `changelog-python-cliff` to Language-Specific list (3 → 4)
  - Lines ~1825-1826: Update Language-Specific count and listing
  - Lines ~2459-2460: Update Language-Specific count and listing
  - Line ~2573: Update summary counts if applicable
- [ ] Update `setup.ps1`:
  - Line ~311: Increment SKILLS count from 47 to 48
  - Line ~317: Add `changelog-python-cliff` to Language-Specific list (3 → 4)
  - Lines ~1426-1427: Update Language-Specific count and listing
  - Lines ~1464-1465: Update Language-Specific count and listing
  - Lines ~1939/1946: Update summary counts if applicable

### Phase 4: Update README.md
- [ ] Line ~128: Update total skill count from 50 to 51
- [ ] Line ~135: Update Language-Specific category from 3 to 4 skills
- [ ] Add `changelog-python-cliff` to Language-Specific skills list
- [ ] Verify Skill Categories table totals are consistent

### Phase 5: Run Documentation Sync Workflow
- [ ] Run `documentation-sync-workflow` skill to verify synchronization
- [ ] Fix any discrepancies found during sync
- [ ] Verify all 4 files (setup.sh, setup.ps1, README.md, AGENTS.md) are consistent
- [ ] Verify skill counts match across all files

### Phase 6: Final Validation
- [ ] Verify SKILL.md is valid and follows existing conventions
- [ ] Verify cliff.toml template is syntactically correct
- [ ] Verify all skill count increments are consistent
- [ ] Run `./setup.sh --dry-run` to verify deployment would work
- [ ] Review all changes for consistency with repository patterns

---

## Technical Notes

### Existing Repository Conventions
- Skills use YAML frontmatter with: `name`, `description`, `license` (Apache-2.0), `compatibility` (opencode), `metadata` (audience, workflow)
- SKILL.md follows standard sections: "What I do", "When to use me", "Prerequisites", detailed steps, "When NOT to use me", "Dependencies"
- Language-Specific skills reference the language they target (e.g., `python-pytest-creator` references Python/pytest)
- Skills are designed to be composable and may reference framework skills

### git-cliff Key Concepts
- git-cliff parses conventional commits from git history
- Configuration is stored in `cliff.toml` at project root
- Supports custom regex patterns for version detection
- Can generate changelogs for specific version ranges
- Supports multiple output formats (markdown, JSON, etc.)

### PEP 440 Versioning Considerations
- PEP 440 versions differ from semver: `1.0.0a1`, `1.0.0b2`, `1.0.0rc1`, `1.0.0.post1`, `1.0.0.dev1`
- The cliff.toml template should include a regex pattern matching PEP 440
- Version detection should check multiple sources: `pyproject.toml`, `__init__.py`, `setup.py`, `setup.cfg`
- git-cliff's built-in semver parser may need custom configuration for PEP 440 compliance

### Current Count State (Pre-Change)
| File | Current Total | Language-Specific | Category |
|------|--------------|-------------------|----------|
| `setup.sh` line 541 | 49 | 3 | Line 547 |
| `setup.ps1` line 311 | 47 | 3 | Line 317 |
| `README.md` line 128 | 50 | 3 | Line 135 |

### Target Count State (Post-Change)
| File | New Total | New Language-Specific | Category |
|------|-----------|----------------------|----------|
| `setup.sh` | 50 | 4 | Language-Specific |
| `setup.ps1` | 48 | 4 | Language-Specific |
| `README.md` | 51 | 4 | Language-Specific |

### Possible Subagent Assignment
Consider delegating to `documentation-subagent` or `opencode-tooling-subagent` for SKILL.md creation, as they handle documentation and skill creation respectively.

## Dependencies
- git-cliff must be referenced as external prerequisite (not bundled)
- Follows conventions established by existing Language-Specific skills (`python-pytest-creator`, `python-ruff-linter`)
- May reference `git-semantic-commits` skill for conventional commit conventions

## Risks & Mitigation
| Risk | Mitigation |
|------|------------|
| PEP 440 version regex complexity | Test with common Python version patterns; provide fallback to semver |
| Count discrepancies across files | Use documentation-sync-workflow for validation |
| setup.ps1 count already out of sync (47 vs 49 vs 50) | Investigate and resolve during Phase 5 |
| git-cliff TOML template syntax errors | Validate template against git-cliff documentation |

## Success Metrics
- SKILL.md follows existing repository skill conventions (matching python-pytest-creator style)
- cliff.toml template supports PEP 440 versioning
- All 4 deployment files show consistent skill counts
- `setup.sh --dry-run` completes without errors referencing the new skill
- GitHub issue #142 acceptance criteria are fully met
