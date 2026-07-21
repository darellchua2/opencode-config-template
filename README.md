# OpenCode Configuration Template

A dual-mode OpenCode configurator repository:

1. **User-Space Deploy** — Run `./deploy/setup.sh` to copy config, agents, and skills to `~/.config/opencode/` for global use
2. **Docker Standalone** — Run `docker compose up -d` to launch OpenCode as a web endpoint

> **v2.0.0 upgrade?** See [`MIGRATION.md`](./MIGRATION.md) for breaking changes (stale agent cleanup, zip backup format, new `--rollback` / `--no-zip-backup` flags) and rollback instructions.

## Repository Structure

```
opencode-config-template/
├── deploy/                      # User-space deployment files
│   ├── config.json              # User-space config (agents, MCP servers, providers)
│   ├── .AGENTS.md               # User-space subagent routing (deployed)
│   ├── setup.sh / setup.ps1     # User-space deployment scripts
├── opencode_app/                # Docker standalone mode
│   ├── Dockerfile               # Container image
│   ├── docker-entrypoint.sh     # API key injection + opencode serve
│   ├── opencode.json            # Container-specific config
│   ├── AGENTS.md                # Container-specific instructions
│   ├── .dockerignore
│   ├── .opencode/
│   │       ├── agents/              # 39 subagent .md files
│   │       └── skills/              # 122 skill directories
│   └── README.md                # Docker usage guide
├── docker-compose.yml           # Docker Compose service definition
├── .env.example                 # Environment variable template
├── PLANS/                       # Execution plans (git-committed)
├── LEARNINGS/                   # Knowledge persistence template (auto-provisioned in target projects)
│   ├── _index.md                # Auto-generated index
│   ├── patterns/                # Reusable code/architecture patterns
│   ├── decisions/               # Architectural decisions (ADR-lite)
│   ├── anti-patterns/           # Things to avoid
│   ├── solutions/               # Non-obvious fixes
│   └── conventions/             # Team coding standards
└── .env                         # Local environment (git-ignored)
```

## Installation

Two setup scripts are provided for different platforms:

| Script | Platform | Features |
|--------|----------|----------|
| `setup.sh` | macOS, Linux, WSL, Git Bash | Full feature set including nvm, PeonPing |
| `setup.ps1` | Windows (PowerShell) | Full feature set, env vars persist to `$PROFILE` |

### macOS / Linux / WSL / Git Bash

```bash
# Interactive setup (recommended for first-time)
./deploy/setup.sh

# Quick setup - config + skills only (skip dependency checks)
./deploy/setup.sh --quick

# Skills-only deployment (requires opencode-ai installed)
./deploy/setup.sh --skills-only

# Non-interactive mode
./deploy/setup.sh --yes

# Preview actions without making changes
./deploy/setup.sh --dry-run

# Update OpenCode CLI only
./deploy/setup.sh --update

# v2.0 model resolution
./deploy/setup.sh --provider anthropic      # swap provider (zai|anthropic|openai|openrouter|lmstudio)
./deploy/setup.sh --mix                     # mix providers per category (e.g. vision on OpenAI, rest on Z.AI)
./deploy/setup.sh --models-only             # re-resolve models only
./deploy/setup.sh --migrate                 # run v1.x -> v2.0 migration
./deploy/setup.sh --force                   # re-resolve, ignoring preserved hand-edits
```

### Model Resolution (v2.0)

Agent models are **tier-based and provider-agnostic**. Source agent files contain
no hardcoded model — instead each agent is categorized into a tier
(`reasoning` / `fast` / `docs` / `vision`) in `deploy/agent-tiers.json`, and the
concrete model is resolved at deploy time. Swap providers without editing agent
files:

```bash
./deploy/setup.sh --provider anthropic      # or: openai, openrouter, lmstudio, zai (default)
```

Override files (precedence highest-first; see `MIGRATION.md`):

| File | Scope |
|------|-------|
| `<project>/.opencode/agent-overrides.json` | per-agent pin, project-local |
| `~/.config/opencode/agent-overrides.json` | per-agent pin, global |
| `<project>/.opencode/models.json` | tier map, project-local |
| `~/.config/opencode/models.json` | tier map, global (written by `--provider`) |
| `deploy/models.default.json` | Z.AI defaults |

### Windows (PowerShell)

```powershell
# Interactive setup
powershell -ExecutionPolicy Bypass -File .\deploy\setup.ps1

# Quick setup
powershell -ExecutionPolicy Bypass -File .\deploy\setup.ps1 -Quick

# Non-interactive
powershell -ExecutionPolicy Bypass -File .\deploy\setup.ps1 -Quick -Yes

# v2.0 model resolution
powershell -ExecutionPolicy Bypass -File .\deploy\setup.ps1 -Provider anthropic
powershell -ExecutionPolicy Bypass -File .\deploy\setup.ps1 -ModelsOnly

# Show help with all options
powershell -ExecutionPolicy Bypass -File .\deploy\setup.ps1 -Help
```

### Common Options

| Option (bash) | Option (PowerShell) | Description |
|----------------|----------------------|-------------|
| `--quick` | `-Quick` | Copy config + skills only (skip dependency checks) |
| `--skills-only` | `-SkillsOnly` | Deploy skills only (requires opencode-ai installed) |
| `--update` | `-Update` | Update OpenCode CLI to latest version |
| `--dry-run` | `-DryRun` | Preview all actions without making changes |
| `--yes` | `-Yes` | Auto-accept all prompts (non-interactive) |
| `--rollback [TARGET]` | `-Rollback [-RollbackTarget\|-RollbackArg <T>]` | Restore `~/.config/opencode/` from a previous backup. `TARGET`: `list`, `latest`, `TIMESTAMP` (e.g. `20260719_070926`), or `VERSION` (e.g. `1.76.0`). Always creates a pre-rollback safety backup first. |
| `--no-zip-backup` | `-NoZipBackup` | Skip zip archive creation (zip is created by default alongside the flat-file backup for portability) |
| `--keep-backups <N>` | `-KeepBackups <N>` | Keep only N most recent backups (default: 5; 0 = delete all; negative = keep all) |
| `--help` | `-Help` | Show detailed help with all options and examples |

### Docker Standalone

Run OpenCode as a standalone web endpoint accessible through the browser:

```bash
# 1. Copy environment template and add your API keys
cp .env.example .env
# Edit .env and set ZAI_API_KEY=your-key-here

# 2. Start the container
docker compose up -d

# 3. Access OpenCode at http://localhost:4097
```

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `ZAI_API_KEY` | Yes | — | Z.AI API key (primary LLM provider) |
| `GEMINI_API_KEY` | No | — | Gemini API key (secondary provider) |
| `OPENCODE_PORT` | No | `4097` | External port mapping |

```bash
# View logs
docker compose logs -f

# Stop
docker compose down

# Rebuild after changes
docker compose build --no-cache
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

### MCP Servers

The configuration ships 26 MCP server entries. **6 are enabled by default:**

| Server | Type | Purpose |
|--------|------|---------|
| `codegraph` | local (npx) | Pre-indexed code knowledge graph |
| `atlassian` | local (npx) | JIRA and Confluence |
| `zai-vision-mcp-server` | local (npx) | Image/video analysis |
| `mermaid` | local (npx) | Mermaid diagram rendering (SVG) |
| `zai-web-reader` | remote | Web page content extraction |
| `zai-zread` | remote | GitHub repository search/reading |

The remaining 20 (Microsoft 365, Autodesk, Google Cloud, `filesystem`, `next-devtools`, `web-search-prime`, etc.) are `enabled: false` and opt-in. To enable one, set `"enabled": true` (and grant its tools in the `tools` block) in `config.json`.

> **Note — `filesystem` MCP is intentionally disabled.** OpenCode's built-in `read`/`write`/`edit`/`glob`/`grep`/`bash` tools already provide full file I/O, so `@modelcontextprotocol/server-filesystem` is redundant. Enable it per-project **only** if a specific tool requires MCP filesystem access — and note the server command requires allowed-directory path arguments (e.g. append your project root), so it would start broken without them.

## Knowledge Persistence

Skills like `continuous-learning` persist knowledge across sessions using a dual strategy:

| Storage | Scope | Purpose |
|---------|-------|---------|
| `memory` tool | Primary, searchable by relevance | Quick facts, decisions, anti-patterns |
| `LEARNINGS/` in target projects | Curated, git-committed | Detailed patterns, ADRs, team conventions |
| `~/.config/opencode/learnings/` | User-level, cross-project | Personal preferences and patterns |

**How it works:**
- `deploy/setup.sh` / `deploy/setup.ps1` creates `~/.config/opencode/learnings/` with 5 subfolders at user level
- When `continuous-learning` skill runs in a target project, it auto-provisions a `LEARNINGS/` directory in that project root
- Review agents (architecture-review, code-review) save findings to both memory tool and markdown files
- Agents discover learnings via AGENTS.md instructions (auto-loaded) + explicit file reads

## CodeGraph

[CodeGraph](https://github.com/colbymchenry/codegraph) is a pre-indexed code knowledge graph MCP server that enables agents to query symbol relationships, call graphs, and code structure instantly instead of scanning files with grep/glob/Read.

### Performance

| Metric | Without CodeGraph | With CodeGraph |
|--------|-------------------|----------------|
| Tool calls per exploration | 30-50+ | 1-6 |
| Exploration time | 1-2 minutes | 15-35 seconds |
| File reads | 10-20 | 0 |
| API key required | — | No (100% local) |

### Setup

CodeGraph is enabled by default in `opencode_app/opencode.json`. No API keys needed — it uses a local SQLite database.

**Per-project initialization** (required before tools work):

```bash
cd your-project
codegraph init -i
```

This creates a `.codegraph/` directory with an indexed SQLite database. Add `.codegraph/` to `.gitignore`. A file watcher auto-syncs changes as you code.

### MCP Tools

| Tool | Purpose |
|------|---------|
| `codegraph_search` | Find symbols by name across the codebase |
| `codegraph_explore` | Full exploration with source code sections (explore agents only) |
| `codegraph_context` | Build relevant code context for a task (explore agents only) |
| `codegraph_callers` | Find what calls a function |
| `codegraph_callees` | Find what a function calls |
| `codegraph_impact` | Analyze what code is affected by changing a symbol |
| `codegraph_node` | Get details about a specific symbol |
| `codegraph_files` | Get indexed file structure |
| `codegraph_status` | Check index health and statistics |

### Supported Languages

TypeScript, JavaScript, Python, Go, Rust, Java, C#, PHP, Ruby, C, C++, Swift, Kotlin, Dart, Svelte, Liquid, Pascal/Delphi, Scala, Vue (19+ languages).

### Subagent Benefits

| Subagent | CodeGraph Benefit |
|----------|-------------------|
| `explore` (built-in) | `codegraph_explore` replaces grep/glob chains |
| `code-review-subagent` | `codegraph_impact` assesses change radius before review |
| `architecture-review-subagent` | Call graph analysis for design evaluation |
| `testing-subagent` | `codegraph_affected` finds impacted tests by changed files |

## Skill Modularization

This repository implements **skill modularization** with 122 skills organized across 20 categories. Skills are designed with clear separation of concerns and explicit dependencies.

> **Migration Complete (BT-142):** The `pptx-specialist-*` stack has been migrated to chenyu's JSON-in-PPTX architecture. Final skill count is **122** (−1 `pptx-specialist-skill` decomposed, +3 chenyu skills, +2 new decomposition skills). See `PLANS/PLAN-BT-142.md` for the full plan. The legacy `pptx-specialist-skill` has been removed; all PPTX operations now route through `pptx-specialist-subagent` → `generate-slide-skill` / `generate-template-skill` / `template-modifier-skill`.

### Skill Categories

| Category | Skills | Purpose |
|-----------|---------|---------|
| **Framework** (20) | test-generator-framework, linting-workflow, pr-creation-workflow, pr-merge-workflow, error-resolver-workflow, tdd-workflow, docx-creation, pptx-specialist, xlsx-specialist, pdf-specialist, frontend-design, uiux-review-skill, api-design-skill, openapi-contract-adherence-skill, performance-optimization-skill, srs-creation-skill, brd-creation-skill, technical-design-creation-skill, vision-creation-skill, interactive-document-rendering-skill | Generic workflows, testing patterns, document creation, UI design + review, API design, contract adherence, performance, and the document ladder (BRD/SRS/vision + technical design documents) |
| **Language-Specific** (8) | python-pytest-creator, python-ruff-linter, javascript-eslint-linter, changelog-python-cliff, python-backend-skill, python-packaging-skill, csharp-linter-skill, java-linter-skill | Language-specific test, linting, project scaffolding, and packaging |
| **Framework-Specific** (11) | nextjs-pr-workflow, nextjs-unit-test-creator, nextjs-standard-setup, nextjs-image-usage, nextjs-devtools-mcp, amplify-nextjs-deployment, typescript-dry-principle, accessibility-a11y-skill, react-nextjs-antipatterns-skill, threejs-nextjs-skill, deprecated-code-cleanup-skill | Next.js 16, React 19, TypeScript, accessibility, Three.js integration, AWS Amplify deployment, and @deprecated code cleanup workflows |
| **OpenCode Meta** (4) | opencode-agent-creation, opencode-skill-creation, opencode-skills-maintainer, documentation-consistency-skill | Agent and skill creation/maintenance, documentation consistency auditing |
| **OpenTofu** (7) | opentofu-aws-explorer, opentofu-keycloak-explorer, opentofu-kubernetes-explorer, opentofu-neon-explorer, opentofu-provider-setup, opentofu-provisioning-workflow, opentofu-ecr-provision | Infrastructure as Code |
| **Git/Workflow** (12) | ascii-diagram-creator, mermaid-diagram-creator, ticket-plan-workflow-skill, plan-execution-skill, git-issue-labeler, git-issue-updater, git-semantic-commits, semantic-release-convention, git-compact-commits, plan-updater, version-bump-standard, git-branch-workflow-setup-skill | Diagrams, git operations, release conventions, version bumping, compact commits, and branch workflow orchestration |
| **Documentation** (3) | coverage-readme-workflow, docstring-generator, documentation-sync-workflow | Documentation generation |
| **JIRA** (3) | jira-status-updater, jira-git-integration, jira-ticket-labeler | JIRA integration via MCP server |
| **Code Quality** (7) | solid-principles, clean-code, clean-architecture, design-patterns, object-design, code-smells, complexity-management | Code quality analysis and patterns |
| **Agent Optimization** (7) | continuous-learning, eval-harness, strategic-compact, verification-loop, search-first, context-budget, agent-introspection-debugging | AI agent session optimization, research-first workflow, context auditing, and agent debugging |
| **Autoresearch** (4) | autoresearch-core-skill, autoresearch-ml-skill, autoresearch-code-skill, autoresearch-research-skill | Autonomous research loops: 5-stage Understand→Hypothesize→Experiment→Evaluate→Log methodology. ML training (GPU), code optimization, literature review. Evaluated by mechanical `{"pass":bool,"score":N}` — no LLM self-judgment. Ported from uditgoenka/autoresearch + karpathy/autoresearch (MIT). |
| **Startup/Business** (3) | startup-pitch-deck-skill, startup-business-docs-skill, construction-bd-skill | Startup pitch decks, business documentation, construction proposals |
| **Configuration** (2) | microsoft-m365-config-skill, codegraph-setup-skill | Microsoft 365 MCP and CodeGraph setup |
| **Security** (2) | security-audit-skill, authentication-authorization-skill | Security auditing, vulnerability scanning, and auth implementation |
| **DevOps** (4) | docker-containerization-skill, monorepo-management-skill, database-migration-skill, logging-observability-skill | Containerization, monorepos, database migrations, and observability |
| **Planning & Alignment** (4) | grilling-skill, domain-modeling-skill, grill-with-docs-skill, grill-me-skill | Relentless interview/grilling sessions and domain model (CONTEXT.md glossary + ADR) capture |
| **Responsive & Visual Testing** (2) | wireframer-skill, playwright-responsive-audit-skill | Low-fidelity wireframe/prototype generation and Playwright-driven responsive UI audit + fix methodology |
| **CAD & Hardware Design** (14) | cad-generation-skill, cad-viewer-skill, cad-step-parts-skill, cad-dxf-skill, cad-urdf-skill, cad-srdf-skill, cad-sdf-skill, cad-sendcutsend-skill, cad-gcode-skill, cad-bambu-labs-skill, cad-implicit-skill, autodesk-aps-skill, civil-3d-skill, open3d-skill | Parametric CAD generation (STEP/STL/3MF/GLB), CAD Viewer previews, off-the-shelf parts, DXF drawings, robot descriptions (URDF/SRDF/SDF), G-code slicing, 3D printing (Bambu Labs), SendCutSend validation, implicit CAD, Autodesk APS API integration, Civil 3D workflows, Open3D 3D data processing |

> **Note**: 6 redundant skills archived to `skills/_archived/`: `nextjs-complete-setup`, `python-docstring-generator`, `nextjs-tsdoc-documentor`, `git-pr-creator`, `git-issue-plan-workflow`, `jira-ticket-plan-workflow`. Use `docstring-generator` for all language docstrings (Python PEP 257, TypeScript TSDoc, Java Javadoc, C# XML docs). Use `ticket-plan-workflow-skill` for unified GitHub/JIRA ticket planning. 

### Agents

39 agent `.md` files (plus 4 config-builtin agents defined directly in `config.json`: `build`, `plan`, `explore`, `general`) provide specialized task handling. Note: the 2 `*-primary-agent` files (`startup-founder`, `office-document`) are routing hubs but are declared with `mode: subagent`.

#### Primary Agents

| Agent | Purpose | Permissions |
|-------|---------|-------------|
| **build** | Default agent for general tasks | Full access to all tools and subagents |
| **plan** | Read-only planning and analysis | `task`, `read`, `glob`, `grep` only (no write/execute) |
| **startup-founder-primary-agent** | Business docs - reports, quotations, spreadsheets, presentations | Full access (`read`, `edit`, `bash`, `webfetch`, `task`) |
| **office-document-primary-agent** | Office document specialist: Word, PowerPoint, Excel | Full access (`read`, `edit`, `bash`, `webfetch`, `task`) |

#### Subagents

| Subagent | Purpose | Skills | Built-in Delegation |
|----------|---------|--------|---------------------|
| **linting-subagent** | Code quality and style (Python, JS/TS, Java Spring Boot, C# .NET) | linting-workflow, python-ruff-linter, javascript-eslint-linter | `explore` |
| **testing-subagent** | Test generation and execution | test-generator-framework, python-pytest-creator, nextjs-unit-test-creator | `explore` |
| **tdd-subagent** | Test-driven development workflow | tdd-workflow, test-generator-framework | — |
| **pr-workflow-subagent** | Pull request creation | pr-creation-workflow, nextjs-pr-workflow | `explore`, `general` |
| **ticket-creation-subagent** | Issue/ticket creation | ticket-plan-workflow-skill | `explore` |
| **discovery-specialist-subagent** | Customer-facing discovery: Vision docs + wireframes | vision-creation-skill | `explore`, `image-analyzer-subagent`, `xlsx-specialist-subagent` |
| **requirements-specialist-subagent** | BRD + SRS drafting (BABOK/IIBA + IEEE 830) | brd-creation-skill, srs-creation-skill | `explore`, `image-analyzer-subagent`, `xlsx-specialist-subagent` |
| **technical-design-specialist-subagent** | Technical design + ADRs (engineering 'how' stage, glm-5.1) | technical-design-creation-skill | `explore`, `image-analyzer-subagent`, `architecture-review-subagent` |
| **documentation-subagent** | Documentation generation | docstring-generator, coverage-readme-workflow | — |
| **coverage-subagent** | Coverage reporting | coverage-readme-workflow | — |
| **opentofu-explorer-subagent** | Infrastructure as code | 7 OpenTofu skills (AWS, K8s, Keycloak, Neon, ECR) | — |
| **architecture-review-subagent** | Architecture and design patterns | clean-architecture, design-patterns, complexity-management, continuous-learning, verification-loop | `explore` |
| **code-review-subagent** | Comprehensive code review | All 7 Code Quality skills + continuous-learning, complexity-management | `explore`, `general` |
| **repo-ops-specialist-subagent** | Git repository operations | version-bump-standard, semantic-release-convention, pr-creation-workflow, pr-merge-workflow, git-issue-labeler | `explore`, `general` |
| **error-resolver-subagent** | Error diagnosis and resolution | error-resolver-workflow | — |
| **nextjs-specialist-subagent** | Next.js scaffolding + runtime MCP diagnosis + project audit | nextjs-standard-setup, nextjs-devtools-mcp, docstring-generator, nextjs-image-usage, react-nextjs-antipatterns, amplify-nextjs-deployment | — |
| **opencode-tooling-subagent** | Skills, agents, and rules creation + doc sync | opencode-skill-creation, opencode-agent-creation, opencode-skills-maintainer, documentation-sync-workflow | — |
| **docx-creation-subagent** | Word document creation | docx-creation | — |
| **image-analyzer-subagent** | Image analysis and conversion | (built-in capabilities) | — |
| **responsive-audit-subagent** | Responsive UI audit and fix | playwright-responsive-audit-skill | `explore`, `general`, `image-analyzer-subagent` |
| **google-mcp-specialist-subagent** | Google Cloud MCP setup and usage | google-bigquery, google-maps, google-gce, google-gke | — |
| **cad-specialist-subagent** | CAD, robotics, hardware design — orchestrates 14 CAD/engineering skills | cad-generation, cad-viewer, cad-step-parts, cad-dxf, cad-urdf, cad-srdf, cad-sdf, cad-sendcutsend, cad-gcode, cad-bambu-labs, cad-implicit, autodesk-aps-skill, civil-3d-skill, open3d-skill | — |
| **microsoft-m365-specialist-subagent** | Microsoft 365 MCP setup and usage | microsoft-teams, microsoft-mail, microsoft-calendar, microsoft-sharepoint | — |
| **explorer-subagent** | Fast codebase exploration and analysis | (built-in search capabilities) | — |
| **pptx-specialist-subagent** | PowerPoint presentations (read, create, edit, analyze) | pptx-specialist | — |
| **xlsx-specialist-subagent** | Spreadsheets (read, create, edit, analyze) | xlsx-specialist | — |
| **startup-ceo-subagent** | Startup presentations (pitch decks, investor slides, board updates) | pptx-specialist | — |
| **loop-operator-subagent** | Autonomous loop execution with self-correction | verification-loop, continuous-learning, strategic-compact | `explore`, `general` |
| **autoresearch-ml-subagent** | Autonomous ML training loop (Karpathy-style). Requires NVIDIA GPU. | autoresearch-core, autoresearch-ml, strategic-compact | `explore`, `general` |
| **autoresearch-code-subagent** | Autonomous code optimization (test coverage, bundle size, runtime) | autoresearch-core, autoresearch-code, continuous-learning, strategic-compact | `explore`, `general` |
| **autoresearch-research-subagent** | Literature review / paper synthesis (Tier 2 web-only, no Bash) | autoresearch-core, autoresearch-research, search-first, strategic-compact | `explore`, `general` |
| **python-reviewer-subagent** | Python-specific code review (PEP 8, type hints, async) | solid-principles, clean-code, code-smells, continuous-learning | `explore`, `general` |
| **typescript-reviewer-subagent** | TypeScript/JS code review (type safety, React, Next.js) | solid-principles, clean-code, code-smells, continuous-learning | `explore`, `general` |
| **go-reviewer-subagent** | Go code review (idioms, concurrency, error handling) | solid-principles, clean-code, code-smells, continuous-learning | `explore`, `general` |
| **rust-reviewer-subagent** | Rust code review (ownership, unsafe safety, Result/Option) | solid-principles, clean-code, code-smells, continuous-learning | `explore`, `general` |
| **java-reviewer-subagent** | Java code review (Effective Java, concurrency, Spring) | solid-principles, clean-code, code-smells, continuous-learning | `explore`, `general` |
| **uiux-reviewer-subagent** | UI/UX design review (13-axis rubric: 6 AslanMazhidov + 5 RNT56 + Nielsen's 10 + anti-default AI cluster detection) | uiux-review-skill, frontend-design-skill, accessibility-a11y-skill, wireframer-skill | `explore`, `general`, `image-analyzer-subagent` |

> **Built-in Delegation**: Subagents with `explore` can delegate codebase scanning to the built-in `explore` subagent. Subagents with `general` can delegate parallelizable multi-step work to the built-in `general` subagent. Access is controlled via `task` permissions in each agent's frontmatter (`"*": deny` by default, explicit allowlist).

##### Subagent Nesting Depth

`opencode_app/opencode.json` sets `subagent_depth: 3` (opencode's default is `1`). This is required for nested delegation chains used by the autoresearch subagents and other deep workflows:

| Depth | Chain | Example |
|-------|-------|---------|
| `1` (opencode default) | primary → subagent | Blocks nesting entirely — autoresearch loops fail with "Subagent depth limit reached" |
| `2` | primary → subagent → 1 nested | Minimum for autoresearch to delegate research/exploration |
| `3` (set here) | primary → subagent → nested → one more | Comfortable headroom for autoresearch-code/ml/research loops |

Each extra level multiplies token cost (every nested subagent runs its own full context). Lower it to `2` for tighter runs; raise it only if a deeper chain hits the wall again. See the [Subagent depth docs](https://opencode.ai/docs/config#subagent-depth).

#### Trigger Phrases

Some subagents recognize natural language triggers:

| Subagent | Trigger Phrases |
|----------|-----------------|
| **pr-workflow-subagent** | "create pr", "pr merge to [branch]", "merge to main", "pull request" |
| **ticket-creation-subagent** | "create issue", "new ticket", "jira ticket" |
| **pptx-specialist-subagent** | "PowerPoint", ".pptx", "presentation", "slides", "deck", "html to pptx" |
| **startup-ceo-subagent** | "pitch deck", "investor deck", "board update", "fundraising", "demo day" |
| **uiux-reviewer-subagent** | "design review", "UI audit", "UX review", "visual review", "review UI design" |

### Iteration Protocol (opt-in)

The repository ships an **autoresearch iteration protocol** — a 5-stage loop (Understand → Hypothesize → Experiment → Evaluate → Log & Iterate) that 30 existing skills can opt into. The protocol is **off by default**; enable it via:

| Method | How |
|--------|-----|
| Environment variable | `export AUTORESEARCH_PROTOCOL=1` |
| Shell helper (after `setup.sh`) | `ar-enable` / `ar-disable` |
| Per-invocation | Set the env var inline before invoking the skill |

When enabled, retrofitted skills emit mechanical evaluator output `{"pass":bool,"score":N}` (no LLM self-judgment), append to `<skill>-results.tsv` audit trails, and auto-revert failed experiments via Git-as-memory. See `opencode_app/.opencode/skills/autoresearch-core-skill/references/iteration-safety.md` for safety blocks and prompt-injection boundaries.

**Retrofitted skills (30 total):**
- **Tier 1 (full loop, 7)**: verification-loop, tdd-workflow, eval-harness, continuous-learning, deprecated-code-cleanup, linting-workflow, coverage-readme-workflow
- **Tier 2 (partial, 8)**: documentation-consistency, error-resolver-workflow, opencode-skills-maintainer, plan-execution, pr-creation-workflow, pr-merge-workflow, react-nextjs-antipatterns, playwright-responsive-audit
- **Tier 3 (light safety, 15)**: search-first, api-design, security-audit, code-smells, performance-optimization, typescript-dry-principle, solid-principles, clean-code, test-generator-framework, python-pytest-creator, nextjs-unit-test-creator, nextjs-pr-workflow, mermaid-diagram-creator, wireframer, frontend-design

**Maintenance:** `opencode-skills-maintainer-skill` includes a Citation drift audit rule that flags skills with iteration-keyword mentions lacking proper `autoresearch-core-skill/references/` citations.

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
│  ticket-plan-workflow-skill combines multiple skills │
└─────────────────────────────────────────────────────┘
```

### Configuration Files

The setup scripts automatically:
- Copies `deploy/.AGENTS.md` to `~/.config/opencode/AGENTS.md` (renaming it)
- Copies `opencode_app/.opencode/skills/` folder to `~/.config/opencode/skills/`
- Copies `opencode_app/opencode.json` to `~/.config/opencode/config.json` (single source of truth — model resolver patches primary/explore/general in-place during deploy)
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
2 subagents provide specialized code quality analysis:

| Subagent | Purpose | Skills Used | Built-in Delegation |
|----------|---------|-------------|---------------------|
| `architecture-review-subagent` | Architecture review and design patterns | clean-architecture, design-patterns, complexity-management, continuous-learning, verification-loop | `explore` |
| `code-review-subagent` | Comprehensive code review (all quality skills) | All 7 quality skills + continuous-learning, complexity-management | `explore`, `general` |

### Enhanced Subagent
The `repo-ops-specialist-subagent` is a git repository operations specialist with comprehensive git/gh skills and built-in subagent delegation:

| Subagent | Key Skills | Built-in Delegation |
|----------|------------|---------------------|
| `repo-ops-specialist-subagent` | version-bump-standard, semantic-release-convention, pr-creation-workflow, pr-merge-workflow, git-issue-labeler | `explore`, `general` |

### Related Existing Skills
| New Skill | Related Existing Skills |
|-----------|------------------------|
| `solid-principles` | typescript-dry-principle |
| `clean-code` | typescript-dry-principle, docstring-generator |
| `code-smells` | linting-workflow, python-ruff-linter, javascript-eslint-linter |
| `design-patterns` | code-review-subagent |
| `object-design` | test-generator-framework (value objects) |
| `complexity-management` | tdd-workflow |

