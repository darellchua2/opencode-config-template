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

## USER Level Configuration

This repository supports **USER level configuration** for personal overrides and customizations. The configuration hierarchy is:

```
Global AGENTS.md (~/.config/opencode/AGENTS.md)
    ↓ (defaults and personal preferences)
USER Level Config (~/.config/opencode/user/)
    ↓ (user-specific overrides)
Project AGENTS.md (.AGENTS.md)
    ↓ (team rules and project-specific settings)
config.json (~/.config/opencode/config.json)
    ↓ (agent definitions and tool permissions)
Task Execution
```

### Setting Up USER Configuration

#### Option 1: Interactive Setup (Recommended)

Run setup.sh with user configuration:

```bash
./setup.sh --user-config
```

This will:
1. Create `~/.config/opencode/user/` directory
2. Generate `config.user.json` from template
3. Optionally create `AGENTS.md` for user-level overrides
4. Update `config.json` to reference USER configuration

#### Option 2: Manual Setup

```bash
# Create user config directory
mkdir -p ~/.config/opencode/user

# Copy templates
cp templates/config.user.json.example ~/.config/opencode/user/config.user.json
cp templates/AGENTS.md.example ~/.config/opencode/user/AGENTS.md  # optional

# Edit configuration
nano ~/.config/opencode/user/config.user.json
nano ~/.config/opencode/user/AGENTS.md  # optional
```

### USER Configuration Files

#### config.user.json

User-specific configuration that overrides global defaults:

```json
{
  "preferences": {
    "defaultModel": "glm-4.7",
    "language": "en",
    "timezone": "UTC"
  },
  "skills": {
    "enabled": ["*"],
    "disabled": [],
    "customSkillsPath": "/path/to/custom/skills"
  },
  "agents": {
    "defaultAgent": "build-with-skills",
    "subagentTimeout": 300
  },
  "behavior": {
    "autoLint": true,
    "autoTest": true,
    "autoDocument": false
  }
}
```

#### AGENTS.md (User Level)

Optional user-level AGENTS.md that overrides global settings:

```markdown
# USER Level AGENTS.md

## Personal Overrides

### Model Preferences
- Default model: glm-4.7
- Fallback model: glm-4.6v

### Agent Preferences
- Prefer build-with-skills for most tasks
- Use plan-with-skills for complex planning
```

### Configuration Validation

Validate all configuration files:

```bash
./setup.sh --validate-config
```

Validate with verbose output:

```bash
./setup.sh --validate-config --verbose
```

### Configuration Migration

Migrate existing configuration to USER level:

```bash
./setup.sh --migrate-config
```

Force migration (overwrite existing USER config):

```bash
./setup.sh --force-migrate
```

### Configuration Management Commands

| Command | Description |
|---------|-------------|
| `--user-config` | Setup USER level configuration interactively |
| `--validate-config` | Validate all configuration files |
| `--migrate-config` | Migrate existing configuration to USER level |
| `--force-migrate` | Force migration (overwrite existing USER config) |

### USER Configuration Best Practices

1. **Keep Global Settings Minimal**: Put essential defaults in Global AGENTS.md
2. **Use Specific Overrides**: Only override what's necessary in USER config
3. **Document Customizations**: Comment your changes in AGENTS.md
4. **Test Configuration**: Run `--validate-config` after changes
5. **Backup Before Changes**: Migration creates automatic backups

### Template Files

Template files are available in `templates/` directory:

- `USER_CONFIG.md` - Complete USER configuration guide
- `config.user.json.example` - Example USER config with all options
- `config.skills.json.example` - Example USER skill configuration
- `AGENTS.md.example` - Example USER AGENTS.md with common overrides

For detailed documentation, see `templates/USER_CONFIG.md`.

## Skill Modularization

This repository implements **skill modularization** with 33 skills organized across 8 categories. Skills are designed with clear separation of concerns and explicit dependencies.

### Skill Categories

| Category | Skills | Purpose |
|-----------|---------|---------|
| **Framework** (5) | test-generator-framework, linting-workflow, pr-creation-workflow, jira-git-integration, ticket-branch-workflow | Generic workflows and patterns |
| **Language-Specific** (3) | python-pytest-creator, python-ruff-linter, javascript-eslint-linter | Language-specific test and linting |
| **Framework-Specific** (4) | nextjs-pr-workflow, nextjs-unit-test-creator, nextjs-standard-setup, typescript-dry-principle | Next.js and TypeScript workflows |
| **OpenCode Meta** (3) | opencode-agent-creation, opencode-skill-creation, opencode-skill-auditor | Agent and skill creation |
| **OpenTofu** (7) | opentofu-aws-explorer, opentofu-keycloak-explorer, opentofu-kubernetes-explorer, opentofu-neon-explorer, opentofu-provider-setup, opentofu-provisioning-workflow, opentofu-ecr-provision | Infrastructure as code |
| **Git/Workflow** (6) | ascii-diagram-creator, git-issue-creator, git-issue-labeler, git-issue-updater, git-pr-creator, git-semantic-commits | Git operations and workflows |
| **Documentation** (2) | coverage-readme-workflow, docstring-generator | Documentation generation |
| **JIRA** (1) | jira-git-workflow | JIRA integration |

### USER Level Skill Control

Configure skills at USER level in `~/.config/opencode/user/config.user.json`:

```json
{
  "skills": {
    "enabled": ["*"],
    "disabled": [],
    "priorities": {
      "test-generator-framework": 10,
      "linting-workflow": 9
    },
    "customSkillsPath": "/path/to/custom/skills",
    "autoLoad": true,
    "cacheEnabled": true
  }
}
```

**Features:**
- Enable/disable specific skills or skill patterns (wildcards supported)
- Set skill priorities for conflict resolution
- Define custom skills paths
- Configure skill auto-loading and caching
- Organize skills by category

**For details:** See `docs/USER_SKILL_CONTROL_GUIDE.md`

### Subagents

6 subagents provide specialized task handling:

| Subagent | Purpose | Skills |
|-----------|---------|---------|
| **linting-subagent** | Code quality and style | linting-workflow, python-ruff-linter, javascript-eslint-linter |
| **testing-subagent** | Test generation and execution | test-generator-framework, python-pytest-creator, nextjs-unit-test-creator |
| **git-workflow-subagent** | Git operations and version control | ticket-branch-workflow, git-issue-creator, git-pr-creator, git-semantic-commits |
| **documentation-subagent** | Documentation generation | docstring-generator, coverage-readme-workflow |
| **opentofu-explorer-subagent** | Infrastructure as code | 7 OpenTofu skills (AWS, K8s, Keycloak, Neon, ECR) |
| **workflow-subagent** | Workflow automation | pr-creation-workflow, jira-git-workflow, jira-status-updater |

**For details:** See `docs/SUBAGENT_DOCUMENTATION.md`

### Skill Architecture

Skills follow a modular architecture:

```
┌─────────────────────────────────────────────────────┐
│              Framework Skills (Base)               │
│  test-generator-framework, linting-workflow, etc. │
└─────────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────┐
│          Specialized Skills (Extension)            │
│  python-pytest-creator, python-ruff-linter, etc. │
└─────────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────┐
│           Composite Skills (Workflow)               │
│  jira-git-workflow combines multiple skills       │
└─────────────────────────────────────────────────────┘
```

### Documentation

- **Skill Modularization Audit:** `docs/SKILL_MODULARIZATION_AUDIT.md` - Complete skill analysis
- **Skill Modularization Design:** `docs/SKILL_MODULARIZATION_DESIGN.md` - Framework architecture
- **Subagent Documentation:** `docs/SUBAGENT_DOCUMENTATION.md` - Subagent details and skills
- **USER Skill Control Guide:** `docs/USER_SKILL_CONTROL_GUIDE.md` - Skill configuration
- **Skill Migration Guide:** `docs/SKILL_MIGRATION_GUIDE.md` - Upgrade instructions

### Migration

No migration required - backward compatible. Optionally enable USER level skill control:

```bash
# Enable USER level configuration
./setup.sh --user-config

# Or migrate existing configuration
./setup.sh --migrate-config

# Validate configuration
./setup.sh --validate-config
```

**For details:** See `docs/SKILL_MIGRATION_GUIDE.md`


### Template Files

Template files are available in the `templates/` directory:

- `USER_CONFIG.md` - Complete USER configuration guide
- `config.user.json.example` - Example USER config with all options
- `AGENTS.md.example` - Example USER AGENTS.md with common overrides

For detailed documentation, see `templates/USER_CONFIG.md`.

