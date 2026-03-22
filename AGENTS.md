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
└── skills/              # Custom skills (deployed to user space)
```