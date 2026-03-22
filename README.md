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
- **Build agent**: Full access to all tools, skills, and subagents
- **Plan agent**: Read-only access (`read`, `glob`, `grep`) + subagent delegation (`task`) - no `bash`, `write`, `edit`, or MCP tools
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

This repository implements **skill modularization** with 47 skills organized across 9 categories. Skills are designed with clear separation of concerns and explicit dependencies.

### Skill Categories

| Category | Skills | Purpose |
|-----------|---------|---------|
| **Framework** (9) | test-generator-framework, linting-workflow, pr-creation-workflow, jira-git-integration, error-resolver-workflow, tdd-workflow, docx-creation, coverage-framework, ticket-branch-workflow | Generic workflows, testing patterns, and document creation |
| **Language-Specific** (3) | python-pytest-creator, python-ruff-linter, javascript-eslint-linter | Language-specific test, linting, and documentation |
| **Framework-Specific** (5) | nextjs-pr-workflow, nextjs-unit-test-creator, nextjs-standard-setup, nextjs-image-usage, typescript-dry-principle | Next.js and TypeScript workflows |
| **OpenCode Meta** (4) | opencode-agent-creation, opencode-skill-creation, opencode-skill-auditor, opencode-skills-maintainer | Agent and skill creation/maintenance |
| **OpenTofu** (7) | opentofu-aws-explorer, opentofu-keycloak-explorer, opentofu-kubernetes-explorer, opentofu-neon-explorer, opentofu-provider-setup, opentofu-provisioning-workflow, opentofu-ecr-provision | Infrastructure as code |
| **Git/Workflow** (8) | ascii-diagram-creator, git-issue-creator, git-pr-creator, git-issue-labeler, git-issue-plan-workflow, git-issue-updater, git-semantic-commits, plan-updater | Git operations and workflows |
| **Documentation** (3) | coverage-readme-workflow, docstring-generator, documentation-sync-workflow | Documentation generation |
| **JIRA** (4) | jira-ticket-oauth-workflow, jira-ticket-plan-workflow, jira-status-updater, jira-ticket-workflow | JIRA integration workflows |
| **Code Quality** (7) | solid-principles, clean-code, clean-architecture, design-patterns, object-design, code-smells, complexity-management | Code quality analysis and patterns |

> **Note**: 3 redundant skills archived to `skills/_archived/`: `nextjs-complete-setup`, `python-docstring-generator`, `nextjs-tsdoc-documentor`. Use `docstring-generator` for all language docstrings (Python PEP 257, TypeScript TSDoc, Java Javadoc, C# XML docs). |

### Agents

23 agents provide specialized task handling (2 primary + 21 subagents):

#### Primary Agents

| Agent | Purpose | Permissions |
|-------|---------|-------------|
| **build** | Default agent for general tasks | Full access to all tools and subagents |
| **plan** | Read-only planning and analysis | `task`, `read`, `glob`, `grep` only (no write/execute) |

#### Subagents

| Subagent | Purpose | Skills |
|----------|---------|--------|
| **linting-subagent** | Code quality and style | linting-workflow, python-ruff-linter, javascript-eslint-linter |
| **testing-subagent** | Test generation and execution | test-generator-framework, python-pytest-creator, nextjs-unit-test-creator |
| **tdd-subagent** | Test-driven development workflow | tdd-workflow, test-generator-framework |
| **pr-workflow-subagent** | Pull request creation | pr-creation-workflow, nextjs-pr-workflow, git-pr-creator |
| **ticket-creation-subagent** | Issue/ticket creation | git-issue-creator, jira-ticket-plan-workflow |
| **documentation-subagent** | Documentation generation | docstring-generator, coverage-readme-workflow |
| **coverage-subagent** | Coverage reporting | coverage-framework, coverage-readme-workflow |
| **opentofu-explorer-subagent** | Infrastructure as code | 7 OpenTofu skills (AWS, K8s, Keycloak, Neon, ECR) |
| **code-quality-subagent** | SOLID, clean code, code smells | solid-principles, clean-code, code-smells |
| **architecture-review-subagent** | Architecture and design patterns | clean-architecture, design-patterns, complexity-management |
| **code-review-subagent** | Comprehensive code review | All 7 Code Quality skills |
| **refactoring-subagent** | Code refactoring | solid-principles, code-smells, clean-code |
| **error-resolver-subagent** | Error diagnosis and resolution | error-resolver-workflow |
| **nextjs-setup-subagent** | Next.js project setup | nextjs-standard-setup (also see docstring-generator for TSDoc) |
| **opencode-tooling-subagent** | Skills and agents creation | opencode-skill-creation, opencode-agent-creation |
| **docx-creation-subagent** | Word document creation | docx-creation |
| **diagram-subagent** | ASCII diagrams and images | ascii-diagram-creator |
| **image-analyzer** | Image analysis and conversion | (built-in capabilities) |
| **google-mcp-specialist-subagent** | Google Cloud MCP setup and usage | google-bigquery, google-maps, google-gce, google-gke |
| **autodesk-specialist-subagent** | Autodesk API integration | autodesk-revit, autodesk-model-data, autodesk-fusion |
| **microsoft-m365-specialist-subagent** | Microsoft 365 MCP setup and usage | microsoft-teams, microsoft-mail, microsoft-calendar, microsoft-sharepoint |

#### Trigger Phrases

Some subagents recognize natural language triggers:

| Subagent | Trigger Phrases |
|----------|-----------------|
| **pr-workflow-subagent** | "create pr", "pr merge to [branch]", "merge to main", "pull request" |
| **ticket-creation-subagent** | "create issue", "new ticket", "jira ticket" |

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
│  jira-git-workflow combines multiple skills        │
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

