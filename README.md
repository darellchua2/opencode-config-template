# OpenCode Configuration Template

This repository contains a pre-configured OpenCode configuration file with support for local LM Studio, Jira/Confluence integration via Atlassian MCP, and Z.AI services. It also includes reusable workflow skills for common development tasks.

## Installation

Two setup scripts are provided for different platforms:

| Script | Platform | Features |
|--------|----------|----------|
| `setup.sh` | macOS, Linux, WSL, Git Bash | Full feature set including nvm, PeonPing, JIRA OAuth2 |
| `setup.ps1` | Windows (PowerShell) | Full feature set, env vars persist to `$PROFILE` |

### macOS / Linux / WSL / Git Bash

```bash
# Interactive setup (recommended for first-time)
./setup.sh

# Quick setup - config + skills only (skip dependency checks)
./setup.sh --quick

# Skills-only deployment (requires opencode-ai installed)
./setup.sh --skills-only

# Non-interactive mode
./setup.sh --yes

# Preview actions without making changes
./setup.sh --dry-run

# Update OpenCode CLI only
./setup.sh --update
```

### Windows (PowerShell)

```powershell
# Interactive setup
powershell -ExecutionPolicy Bypass -File .\setup.ps1

# Quick setup
powershell -ExecutionPolicy Bypass -File .\setup.ps1 -Quick

# Non-interactive
powershell -ExecutionPolicy Bypass -File .\setup.ps1 -Quick -Yes

# Show help with all options
powershell -ExecutionPolicy Bypass -File .\setup.ps1 -Help
```

## Prerequisites

- **Node.js v20+** and **npm** (required for MCP servers)
  - Setup scripts can install Node.js for you on all platforms
  - On macOS/Linux, nvm is recommended for version management
- **LM Studio** running locally on port 1234 (for local LLM)
- **Z.AI API Key** (required for Z.AI MCP services)
- **GitHub CLI** (recommended for GitHub MCP authentication)

### Install GitHub CLI

```bash
# macOS
brew install gh

# Windows
winget install GitHub.cli
# or: choco install gh

# Linux - see https://cli.github.com/

# After installing, authenticate:
gh auth login
```

### Install Node.js

```bash
# macOS / Linux - using nvm (recommended)
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
source ~/.bashrc
nvm install 24

# Windows - options:
# 1. nvm-windows (recommended): https://github.com/coreybutler/nvm-windows/releases
#    Then: nvm install 24 && nvm use 24
# 2. winget: winget install OpenJS.NodeJS.LTS
# 3. chocolatey: choco install nodejs
# 4. Direct download: https://nodejs.org/
```

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

This template implements **skill permissions** to control which skills agents can access.

**Current configuration:**
- **Default agent**: All skills enabled, full MCP access
- **Subagents**: Skill-restricted access based on specialization

**Benefits of this approach:**
- ✅ Predictable behavior - Skills always available in prompts
- ✅ Explicit control - Per-agent permission management
- ✅ Works with custom workflows - Designed for this skill set
- ✅ Minimal discovery latency - No file scanning needed

**Trade-offs:**
- ⚠️ Not Crush-compatible - Uses custom schema
- ⚠️ Manual maintenance required - Adding skills requires editing agent prompts

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

### Configuration Files

The setup scripts automatically:
- Copies `.AGENTS.md` to `~/.config/opencode/AGENTS.md` (renaming it)
- Copies `skills/` folder to `~/.config/opencode/skills/`
- Copies `config.json` to `~/.config/opencode/config.json`
- Backs up existing files before overwriting

### Environment Variable Persistence

| Platform | Method | Location |
|----------|--------|----------|
| macOS / Linux / WSL | Shell rc file | `~/.bashrc` or `~/.zshrc` |
| Windows (Git Bash) | `setx` (registry) | Available in new sessions |
| Windows PowerShell | `$PROFILE` | `~\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1` |

### Template Files

This repository includes inline default configurations in all setup scripts. No external template files are required.

## Code Quality Skills

This repository includes 7 new code quality skills for writing senior-engineer quality code:

### Foundation Skills
| Skill | Description |
|------|-------------|
| `solid-principles` | Enforce SOLID principles (SRP, OCP, LSP, ISP, DIP) - language-agnostic |
| `clean-code` | Naming, small functions, self-documenting code - language-agnostic |

### Architecture Skills
| Skill | Description |
|------|-------------|
| `clean-architecture` | Vertical slicing, dependency rule, layers - language-agnostic |
| `design-patterns` | GoF patterns (Creational, Structural, Behavioral) - language-agnostic |
| `object-design` | Object stereotypes, value objects, aggregates - language-agnostic |

### Analysis Skills
| Skill | Description |
|------|-------------|
| `code-smells` | Detection and refactoring of common smells - language-agnostic |
| `complexity-management` | Essential vs accidental complexity - language-agnostic |

### Code Quality Subagents
3 new subagents provide specialized code quality analysis:

| Subagent | Purpose | Skills Used |
|----------|---------|-------------|
| `code-quality-subagent` | SOLID principles, clean code, code smells | solid-principles, clean-code, code-smells |
| `architecture-review-subagent` | Architecture review and design patterns | clean-architecture, design-patterns, complexity-management |
| `code-review-subagent` | Comprehensive code review (all quality skills) | All 7 quality skills |

### Enhanced Subagent
The `refactoring-subagent` has been enhanced with new skills:

| Subagent | New Skills Added |
|----------|------------------|
| `refactoring-subagent` | solid-principles, code-smells, clean-code |

### Related Existing Skills
| New Skill | Related Existing Skills |
|-----------|------------------------|
| `solid-principles` | typescript-dry-principle |
| `clean-code` | typescript-dry-principle, docstring-generator |
| `code-smells` | linting-workflow, python-ruff-linter, javascript-eslint-linter |
| `design-patterns` | refactoring-subagent |
| `object-design` | test-generator-framework (value objects) |
| `complexity-management` | tdd-workflow |

