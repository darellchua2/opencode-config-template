# Repository-Specific Agent Instructions

This file contains project-specific instructions for agents working in this repository.

## Repository Overview

This is `opencode-config-template` - a configurator repository that deploys user-level OpenCode configuration.

## Deployment

Run `setup.sh` to deploy configuration:
- `config.json` → `~/.config/opencode/config.json`
- `.AGENTS.md` → `~/.config/opencode/AGENTS.md`
- `skills/*` → `~/.config/opencode/skills/`



## File Structure

```
opencode-config-template/
├── config.json          # Agent definitions and MCP config
├── .AGENTS.md           # User-space subagent routing (deployed)
├── AGENTS.md            # Repo-level instructions (this file)
├── setup.sh             # Deployment script
├── setup.ps1            # Deployment script (Windows)
├── skills/              # Custom skills (deployed to user space)
├── agents/              # Global subagents (deployed to user space)
└── .opencode/
    └── agents/          # Project-level subagents (NOT deployed)
```

## Subagent Locations

| Location | Scope | Deployment |
|----------|-------|------------|
| `agents/*.md` | Global (all projects) | Copied to `~/.config/opencode/agents/` |
| `.opencode/agents/*.md` | Project-only | Stays in repo, not deployed |

**Project-Level Subagents:**
- `documentation-sync-subagent` - Ensures doc sync when skills/agents change (this repo only)

## Adding New Subagents or Skills

When adding a new subagent or skill, you MUST update these 4 files to maintain synchronization:

### Files to Update

| File | Lines | Update Type |
|------|-------|-------------|
| `setup.sh` | 523-556 | Skill listings and counts |
| `setup.ps1` | 304-337 | Skill listings and counts |
| `README.md` | 132-142, 157-176 | Skill Categories and Subagents tables |
| `AGENTS.md` | Varies | Add routing if needed (this section) |

### Quick Checklist

For new skills:
- [ ] Increment total skill count in setup.sh (line 523) and setup.ps1 (line 304)
- [ ] Add skill to appropriate category in both setup files
- [ ] Update README.md Skill Categories table
- [ ] Update total count in README.md intro paragraph

For new **global** subagents (in `agents/`):
- [ ] Add row to README.md Subagents table
- [ ] Update total subagent count in README.md
- [ ] If primary agent, update setup.sh AGENTS section

For new **project-level** subagents (in `.opencode/agents/`):
- [ ] Do NOT add to README.md (not deployed globally)
- [ ] Do NOT update setup.sh or setup.ps1 counts
- [ ] Add to "Project-Level Subagents" list above

### Use the Sync Workflow

Invoke the `documentation-sync-workflow` skill or `documentation-sync-subagent` for guided synchronization:

```
opencode --skill documentation-sync-workflow "sync docs after adding new skill"
```