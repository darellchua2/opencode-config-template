# LEARNINGS Index

<!-- AUTO-GENERATED — manual edits to the listing below will be overwritten on next learning write -->
<!-- To add context manually, edit above this comment or in individual learning files -->

## Folder Structure

| Folder | Purpose | Example |
|--------|---------|---------|
| `patterns/` | Reusable code/architecture patterns worth replicating | `event-driven-modules.md` |
| `decisions/` | Architectural decisions with rationale (ADR-lite) | `sqlite-over-postgres-local.md` |
| `anti-patterns/` | Things to avoid, with explanations | `mutable-default-args-python.md` |
| `solutions/` | Non-obvious fixes and workarounds worth remembering | `race-condition-mutex-fix.md` |
| `conventions/` | Team-agreed coding standards and naming rules | `kebab-case-files.md` |

## Entries

<!-- Entries are appended here automatically when new learnings are saved -->

### opencode.json // comments break CI

- **Category**: anti-pattern
- **File**: `anti-patterns/jsonc-comments-in-opencode-json.md`
- **Confidence**: 0.9
- **Scope**: project
- **Summary**: Never add // comments to opencode_app/opencode.json — CI bats tests use Python json.load() which can't parse JSONC
- **Date**: 2026-07-26

### Skill permission allowlist — "*":"deny" + 80 allows

- **Category**: decision
- **File**: `decisions/skill-permission-allowlist.md`
- **Confidence**: 0.9
- **Scope**: project
- **Summary**: Allowlist strategy hides 44 subagent-only skills from primary's available_skills, cutting ~44 descriptions per session
- **Date**: 2026-07-26

### Plugins need both plugin array + command block

- **Category**: solution
- **File**: `solutions/plugin-needs-command-block.md`
- **Confidence**: 0.9
- **Scope**: project
- **Summary**: opencode-goal-plugin requires BOTH plugin array entry AND command.goal config block — removing either breaks /goal
- **Date**: 2026-07-26

---

**Storage paths:**
- Project-level: `LEARNINGS/` (this directory, git-committed)
- User-level: `~/.config/opencode/learnings/` (personal, cross-project)
- Searchable memory: `memory` tool (primary for quick retrieval)

**Naming convention:** Use descriptive slugs (e.g., `event-driven-modules.md`), not dated or numbered prefixes. The category is determined by the subfolder.
