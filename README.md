# OpenCode Configuration Template

This repository contains a pre-configured OpenCode configuration file with support for local LM Studio, Jira/Confluence integration via Atlassian MCP, and Z.AI services. It also includes reusable workflow skills for common development tasks.

## Prerequisites

- **Node.js v24** and **npm** installed (required for MCP servers)
  - Node.js v20+ is minimum requirement (setup script installs v24)
- **LM Studio** running locally on port 1234 (for local LLM)
- **Z.AI API Key** (required for Z.AI MCP services)
- **Draw.io Browser Extension** (optional, for diagram creation - see Draw.io Integration section)

### Install Node.js using nvm

```bash
# Install nvm (Node Version Manager)
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash

# Reload shell configuration
source ~/.bashrc

## Configuration Overview

This repository uses a **custom configuration schema** that differs from official Crush schema. It implements a skill system with per-agent permissions for fine-grained control.

### Key Differences from Official Crush

| Aspect | Custom Template | Official Crush |
|---------|----------------|----------------|
| **Skills** | Hardcoded in agent prompts | Discovered from SKILL.md files |
| **Permissions** | Custom `permission` field per agent | Same (standardized) |
| **Config Schema** | Custom (divergent) | Official Crush schema |
| **Discovery** | Manual (must edit prompts) | Automatic (scans `skills_paths`) |
| **Maintenance** | Edit agent prompts directly | Create/edit SKILL.md files |

### Skill Permission System

This template implements **skill permissions** to control which skills agents can access. See [SKILL-PERMISSIONS.md](./SKILL-PERMISSIONS.md) for detailed documentation.

**Current configuration:**
- **build-with-skills**: All skills enabled, Atlassian MCP enabled
- **plan-with-skills**: All skills enabled, no MCP (read-only planning)

**Benefits of this approach:**
- ✅ Predictable behavior - Skills always available in prompts
- ✅ Explicit control - Per-agent permission management
- ✅ Works with custom workflows - Designed for this skill set
- ✅ Minimal discovery latency - No file scanning needed

**Trade-offs:**
- ⚠️ Not Crush-compatible - Uses custom schema
- ⚠️ Manual maintenance required - Adding skills requires editing agent prompts

### Agent Configuration

See [SKILL-PERMISSIONS.md](./SKILL-PERMISSIONS.md) for detailed permission examples and use cases.

