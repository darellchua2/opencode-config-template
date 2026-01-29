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
USER Level Config (~/.config/opencode/)
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
1. Optionally create `~/.config/opencode/AGENTS.user.md` for user-level markdown overrides

#### Option 2: Manual Setup

```bash
# USER config files go directly under ~/.config/opencode/ (no nested user/ directory)
# Optionally create AGENTS.user.md
cat > ~/.config/opencode/AGENTS.user.md << 'EOF'
# USER Level AGENTS.md

This file contains user-specific preferences that override global settings.

## Personal Overrides

### Model Preferences
- Default model: (system default)
- Fallback model: (system default)

### Agent Preferences
- Prefer build-with-skills for most tasks
- Use plan-with-skills for complex planning
EOF

# Edit configuration
nano ~/.config/opencode/AGENTS.user.md
```

### USER Configuration Files

#### AGENTS.user.md

Optional user-level AGENTS.md that overrides global settings:

```markdown
# USER Level AGENTS.md

## Personal Overrides

### Model Preferences
- Default model: (system default)
- Fallback model: (system default)

### Agent Preferences
- Prefer build-with-skills for most tasks
- Use plan-with-skills for complex planning
- Default to testing-subagent for test generation

### Custom Behavior
- Always run tests after code changes
- Auto-fix linting issues when possible
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

Force migration (overwrite existing USER AGENTS.md):

```bash
./setup.sh --force-migrate
```

### Configuration Management Commands

| Command | Description |
|---------|-------------|
| `--user-config` | Setup USER level AGENTS.md interactively |
| `--validate-config` | Validate all configuration files |
| `--migrate-config` | Migrate existing configuration to USER level |
| `--force-migrate` | Force migration (overwrite existing USER AGENTS.md) |

### USER Configuration Best Practices

1. **Keep Global Settings Minimal**: Put essential defaults in Global AGENTS.md
2. **Use Specific Overrides**: Only override what's necessary in USER AGENTS.md
3. **Document Customizations**: Comment your changes in AGENTS.md
4. **Test Configuration**: Run `--validate-config` after changes
5. **Backup Before Changes**: Migration creates automatic backups

### Setup Behavior

The setup script automatically:
- Copies `.AGENTS.md` to `~/.config/opencode/AGENTS.md` (renaming it)
- Creates `~/.config/opencode/AGENTS.user.md` when USER config is enabled
- Copies `skills/` folder to `~/.config/opencode/skills/`
- Copies `config.json` to `~/.config/opencode/config.json`

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

USER level AGENTS.md can be used to configure skill preferences and behavior overrides. This is a markdown file where you can document your personal skill preferences and agent behavior.

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

This repository includes inline default configurations in setup.sh. No external template files are required.

