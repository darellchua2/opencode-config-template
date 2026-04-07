# Plan: Update pr-workflow-subagent to integrate Python linting and pytest as quality gates

## Overview

Enhance the `pr-workflow-subagent` (`agents/pr-workflow-subagent.md`) to include Python-specific linting and testing skills as mandatory quality gates during the PR workflow. Replace raw `ruff check . && pytest` commands with dedicated skill invocations (`python-ruff-linter`, `python-pytest-creator`, `test-generator-framework`) for intelligent error resolution, breaking change detection, and test generation fallback.

## Issue Reference

- Issue: #146
- URL: https://github.com/darellchua2/opencode-config-template/issues/146
- Labels: enhancement, minor, subagent

## Files to Modify

1. `agents/pr-workflow-subagent.md` — Add skill permissions, update Python workflow section with dedicated skill integrations

## Approach

### Phase 1: Update Skill Permissions (Frontmatter)

1. Add `python-ruff-linter: allow` to the `permission.skill` section
2. Add `python-pytest-creator: allow` to the `permission.skill` section
3. Add `test-generator-framework: allow` to the `permission.skill` section
4. Add `python-docstring-generator: allow` to the `permission.skill` section

### Phase 2: Update Python Workflow Section

Replace the current Python section:
```
Python:
  - Run: ruff check . && pytest
  - Coverage via coverage-framework
  - Docstring validation via docstring-generator (covers Python PEP 257)
  - Changelog generation via changelog-python-cliff
```

With a detailed Python section that:

1. **Detects Python projects** — Check for `pyproject.toml`, `requirements.txt`, `setup.py`
2. **Runs `python-ruff-linter` skill** — Mandatory linting gate using the dedicated skill instead of raw `ruff check`
3. **Handles breaking changes** — If a linting fix would introduce breaking changes (e.g., removing dynamically-used imports, changing public API signatures), prompt the end user for confirmation before applying
4. **Runs `pytest`** — Mandatory testing gate for all Python projects
5. **Offers test generation fallback** — If tests fail, use `python-pytest-creator` skill to generate/fix tests
6. **Runs `python-docstring-generator`** — PEP 257 docstring validation
7. **Runs `changelog-python-cliff`** — Changelog generation
8. **Gates PR creation** — Only proceed if ALL quality gates pass

### Phase 3: Update Main Workflow Steps

Update the numbered workflow section to reference the enhanced Python workflow with dedicated skill invocations instead of raw commands.

## Success Criteria

- [ ] `python-ruff-linter` skill is added to skill permissions in frontmatter
- [ ] `python-pytest-creator` skill is added to skill permissions in frontmatter
- [ ] `test-generator-framework` skill is added to skill permissions in frontmatter
- [ ] Python linting uses `python-ruff-linter` skill instead of raw `ruff check` command
- [ ] Breaking change detection with user prompting is documented in the workflow
- [ ] Pytest is a mandatory quality gate with test generation fallback
- [ ] All quality gates must pass before PR creation
- [ ] Updated workflow steps are clear and sequential

## Notes

- The `changelog-python-cliff` permission already exists in the frontmatter — no addition needed
- The `docstring-generator` permission already exists but should be explicitly replaced/added alongside `python-docstring-generator` for Python-specific use
- The `test-generator-framework` skill is a generic framework that `python-pytest-creator` extends — both should be available
- Breaking change detection is critical: some ruff auto-fixes (F401 unused imports) may remove imports used in dynamic contexts (e.g., `__all__`, lazy imports, plugin systems)
