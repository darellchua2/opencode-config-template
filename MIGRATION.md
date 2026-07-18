# Migration Guide: v1.x → v2.0.0

## Overview

v2.0.0 is a **major refactor release**. This guide covers breaking changes, new features, and how to migrate existing deployments.

## Breaking changes

### 1. Stale agent cleanup
v2.0.0 removes 12 agents that were previously deployed but never present in configurator source. If you depend on any of these, pin to v1.76.0 before upgrading:
- `autodesk-specialist-subagent` → use `cad-specialist-subagent`
- `business-development-primary-agent` → use `startup-founder-primary-agent`
- `business-ops-primary-agent` → use `office-document-primary-agent`
- `civil-3d-specialist-subagent` → use `cad-specialist-subagent`
- `code-quality-subagent` → use `code-review-subagent` or `architecture-review-subagent`
- `diagram-subagent` → use `mermaid-diagram-creator-skill`
- `mermaid-diagram-subagent` → use `mermaid-diagram-creator-skill`
- `nextjs-mcp-advisor-subagent` → consolidated into `nextjs-specialist-subagent`
- `nextjs-setup-subagent` → consolidated into `nextjs-specialist-subagent`
- `open3d-specialist-subagent` → use `cad-specialist-subagent`
- `prd-specialist-subagent` → use `requirements-specialist-subagent`
- `refactoring-subagent` → use `code-review-subagent`

**Action required:** Before upgrading, audit `~/.config/opencode/agents/` for these files. The v2.0.0 setup script will NOT delete them automatically — they will just become orphaned (unused by routing).

### 2. Backup format change
v2.0.0 setup creates BOTH flat-file backup (unchanged) AND a `.zip` archive. Existing flat-file backups remain compatible.

### 3. Agent count math
Counts updated to reflect consolidated state: 39 agents (was 36 in v1.75.x), 113 skills (was 108).

## New features

### `--rollback` flag
Restore previous deployment state:
- `./setup.sh --rollback list` — show available backups
- `./setup.sh --rollback latest` — restore most recent
- `./setup.sh --rollback TIMESTAMP` — restore specific (e.g., `20260719_070926`)
- `./setup.sh --rollback VERSION` — restore closest backup at/before a version tag

Safety: always creates a pre-rollback backup first; confirmation prompt (skip with `--yes`).

### Zip backups
Every deploy now creates `${HOME}/.opencode-backup-YYYYMMDD_HHMMSS.zip` alongside the flat-file directory. Disable with `--no-zip-backup`.

### Autoresearch iteration protocol
v2.0.0 ships 4 new autonomous-research skills + 3 new subagents. 30 existing skills are retrofitted with an opt-in iteration protocol (off by default). Enable with `AUTORESEARCH_PROTOCOL=1` or the `ar-enable` shell helper.

See `README.md` § Iteration Protocol (opt-in) for details.

## Migration steps

1. **Audit your deployment:** `./setup.sh --rollback list` (after upgrading) to see your backup history.
2. **Backup current state:** `cp -r ~/.config/opencode ~/.config/opencode-v1.x-backup`
3. **Pull v2.0.0** and run `./setup.sh --quick --yes`
4. **Verify:** `./setup.sh --rollback list` shows new zip backups.
5. **Test rollback:** pick any old backup, run `./setup.sh --rollback TIMESTAMP --dry-run --yes` to dry-run restore.
6. **(Optional) Clean orphans:** remove any of the 12 stale agents listed above from `~/.config/opencode/agents/` if present.

## Rollback to v1.x

If v2.0.0 breaks your workflow:
```bash
./setup.sh --rollback <v1.x-timestamp>
```
Or restore from your manual backup:
```bash
rm -rf ~/.config/opencode
cp -r ~/.config/opencode-v1.x-backup ~/.config/opencode
```

## Questions

Open an issue: https://github.com/darellchua2/opencode-config-template/issues
