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

# Install and use Node.js v24
nvm install 24
nvm use 24

# Verify installation
node --version
npm --version
```

### Install OpenCode

```bash
npm install -g opencode-ai
```

## Setup Instructions

### Option 1: Automated Setup (Recommended)

Run the automated setup script for quick installation:

```bash
# Clone this repository
git clone https://github.com/yourusername/opencode-config-template.git
cd opencode-config-template

# Run setup script
./setup.sh
```

The setup script will:
- Install/update nvm and Node.js v24
- Install/update opencode-ai
- Copy config.json to `~/.config/opencode/`
- Copy skills to `~/.config/opencode/skills/`
- Set up environment variables (ZAI_API_KEY)

**Setup script options:**
- `./setup.sh` - Interactive full setup
- `./setup.sh --quick` - Quick setup (copy config and skills only)
- `./setup.sh --update` - Update OpenCode CLI only
- `./setup.sh --help` - Show all available options

### Option 2: Manual Setup

### 1. Create Configuration Directory

```bash
mkdir -p ~/.config/opencode
```

### 2. Copy Configuration Files

```bash
# Copy configuration
cp config.json ~/.config/opencode/

# Copy skills folder
mkdir -p ~/.config/opencode/skills/
cp -r skills/* ~/.config/opencode/skills/
```

### 3. Set ZAI_API_KEY Environment Variable

Add your Z.AI API key to `~/.bashrc` for persistent access:

```bash
echo 'export ZAI_API_KEY="your-actual-api-key-here"' >> ~/.bashrc
```

Then reload your shell configuration:

```bash
source ~/.bashrc
```

### 4. Verify Installation

Check that the configuration and skills have been deployed:

```bash
"github": {
  "type": "remote",
  "url": "https://api.githubcopilot.com/mcp/",
  "oauth": false,
  "headers": {
    "Authorization": "Bearer {env:GITHUB_PAT}"
  }
}
```

### 5. Verify Setup

Confirm the configuration is in place:

```bash
# Check configuration
cat ~/.config/opencode/config.json

# Check environment variable
echo $ZAI_API_KEY

# Check skills deployment
ls -la ~/.config/opencode/skills/
```

## Configuration Overview

### Agent Skill Discovery Approach

Build-With-Skills and Plan-With-Skills agents use a **hardcoded skill list approach** for reliable, consistent skill discovery:

- **Skill lists are embedded** in agent system prompts (not from SKILL_INDEX.json)
- **27 pre-configured skills** organized into 9 logical categories
- **Zero discovery latency** - no file reads needed to find skills
- **Consistent behavior** - both agents always have identical skill lists
- **Easy to maintain** - use `opencode-skills-maintainer` skill to update agents

**When to update agents:**
- After creating new skills (use `opencode-skill-creation` skill - auto-updates agents)
- After removing skills from the repository
- After updating skill descriptions or metadata
- See "Skill Maintenance" section below for details

### Provider
- **LM Studio (local)** - Running at `http://127.0.0.1:1234/v1`
  - Model: `openai/gpt-oss-20b` (GPT-OSS 20B)

### Agents
- **image-analyzer** - Specialized agent for analyzing images and screenshots
  - Converts UI to code, extracts text, diagnoses errors
  - Understands diagrams and analyzes visualizations
- **explore** - Fast agent for codebase exploration
  - Find files by patterns, search code for keywords
  - Answer questions about codebase structure
- **diagram-creator** - Specialized agent for creating Draw.io diagrams
  - Generates architectural diagrams, flowcharts, and system designs
  - Uses Draw.io MCP server for programmatic diagram creation

### Skills Architecture

The repository follows a **framework-based skills architecture** to eliminate duplication and improve maintainability:

#### Framework Skills (Reusable Base Components)

Framework skills provide reusable workflows that multiple specialized skills can reference:

- **`test-generator-framework`** - Generic test generation supporting multiple languages
  - Framework detection (Jest, Vitest, Pytest, etc.)
  - Scenario generation patterns
  - User confirmation workflow
  - Test file template system
  - Executability verification

- **`jira-git-integration`** - JIRA + Git workflow utilities
  - JIRA resource detection (cloud ID, projects, issues)
  - Branch naming conventions
  - JIRA comment creation
  - Image upload to JIRA
  - Ticket retrieval and updates

- **`pr-creation-workflow`** - Generic pull request creation
  - Configurable base branch selection
  - Pluggable quality checks (lint, build, test)
  - Multi-platform integration (JIRA, GitHub issues)
  - Image attachment support
  - Merge confirmation flow

- **`ticket-branch-workflow`** - Generic ticket-to-branch workflow
  - Multi-platform ticket creation (GitHub, JIRA)
  - PLAN.md generation and commit
  - Branch creation and auto-checkout
  - Branch push to remote
  - Platform-specific tagging/labeling

- **`linting-workflow`** - Generic linting for multiple languages
  - Language detection (TypeScript/JavaScript vs Python)
  - Linter detection (ESLint vs Ruff)
  - Auto-fix application
  - Error resolution guidance
  - Fix commit workflow

#### Specialized Skills

Specialized skills use framework skills for core logic and add platform/language-specific functionality:

**Test Generation Skills:**
- **`nextjs-unit-test-creator`** - Next.js unit and E2E tests (uses `test-generator-framework`)
- **`python-pytest-creator`** - Python pytest tests (uses `test-generator-framework`)

**Pull Request Skills:**
- **`git-pr-creator`** - GitHub pull requests with JIRA integration (uses `pr-creation-workflow`, `jira-git-integration`)
- **`nextjs-pr-workflow`** - Complete Next.js PR workflow with JIRA (uses `pr-creation-workflow`, `linting-workflow`, `jira-git-integration`)

**Ticket/Issue Skills:**
- **`git-issue-creator`** - GitHub issues with tag detection (uses `ticket-branch-workflow`)
- **`jira-git-workflow`** - JIRA ticket creation and branching (uses `ticket-branch-workflow`, `jira-git-integration`)

**Linting Skills:**
- **`python-ruff-linter`** - Python linting with Ruff (uses `linting-workflow`)
- **`javascript-eslint-linter`** - JavaScript/TypeScript linting with ESLint (uses `linting-workflow`)

**Project Setup Skills:**
- **`nextjs-standard-setup`** - Create standardized Next.js 16 demo applications with shadcn, Tailwind v4, and Tekk-prefixed components

**OpenCode Meta Skills:**
- **`opencode-agent-creation`** - Create OpenCode agents following best practices
- **`opencode-skill-creation`** - Create OpenCode skills following documentation standards
- **`opencode-skill-auditor`** - Audit existing skills to identify modularization opportunities and eliminate redundancy
- **`opencode-skills-maintainer`** - Automatically update Build-With-Skills and Plan-With-Skills agents with new skills

**Code Quality/Documentation Skills:**
- **`docstring-generator`** - Generate language-specific docstrings for C#, Java, Python, and TypeScript
- **`typescript-dry-principle`** - Apply DRY principle to eliminate code duplication in TypeScript projects
- **`coverage-readme-workflow`** - Ensure test coverage percentage is displayed in README.md for Next.js and Python projects

**OpenTofu/Infrastructure Skills:**
- **`opentofu-provider-setup`** - Configure OpenTofu with cloud providers and authentication
- **`opentofu-provisioning-workflow`** - Infrastructure as Code development patterns and resource lifecycle management
- **`opentofu-aws-explorer`** - Explore and manage AWS cloud infrastructure resources
- **`opentofu-kubernetes-explorer`** - Explore and manage Kubernetes clusters and resources
- **`opentofu-neon-explorer`** - Explore and manage Neon Postgres serverless database resources
- **`opentofu-keycloak-explorer`** - Explore and manage Keycloak identity and access management resources

**Standalone Skills (No Framework):**
- **`ascii-diagram-creator`** - Create ASCII diagrams from workflow definitions

#### How Frameworks and Skills Interact

```
User Request → Specialized Skill → Framework Skills → Implementation
                 ↓                           ↓
            Adds           →  Provides Core Workflow  → Completes Task
            Platform/Language    Logic & Patterns
            Specific Logic
```

**Example:** Creating a GitHub issue with `git-issue-creator`
1. User requests: "Create a GitHub issue for this feature"
2. Specialized skill (`git-issue-creator`) handles:
   - GitHub-specific issue creation with `gh` CLI
   - Intelligent tag detection (feature, bug, enhancement, etc.)
3. Framework skill (`ticket-branch-workflow`) provides:
   - PLAN.md generation with standard template
   - Branch creation and checkout
   - Commit PLAN.md
   - Push to remote
4. Result: Complete issue → branch → PLAN.md workflow

**Example:** Creating Next.js tests with `nextjs-unit-test-creator`
1. User requests: "Generate tests for this Next.js project"
2. Specialized skill (`nextjs-unit-test-creator`) handles:
   - Next.js-specific detection (package.json, Jest/Vitest)
   - Component, utility, and hook test scenarios
3. Framework skill (`test-generator-framework`) provides:
   - User confirmation workflow
   - Test file template creation
   - Executability verification
4. Result: Complete test generation workflow

#### Benefits

- **Reduced Duplication**: Common workflows defined once in frameworks
- **Easier Updates**: Fix bugs in framework, all dependent skills benefit
- **Better Discoverability**: Skills reference relevant frameworks
- **Consistent UX**: Same patterns across similar workflows
- **Modular Architecture**: Easy to add new language/framework support
- **Reliable Discovery**: Hardcoded skill lists eliminate discovery failures
- **Zero Latency**: No file reads needed to find available skills
- **Auto-Update**: `opencode-skills-maintainer` keeps agents synchronized
- **Always Available**: Skills always listed in agent system prompts

Skills are deployed to `~/.config/opencode/skills/` during setup.

### Skill Maintenance

The `opencode-skills-maintainer` skill automatically keeps Build-With-Skills and Plan-With-Skills agents synchronized with available skills.

#### When to Run opencode-skills-maintainer

Run this skill when:
- You've added new skills to `skills/` folder
- You've removed skills from `skills/` folder
- You've updated skill descriptions or metadata
- Agents are unable to find skills that should be available

#### How to Run

```bash
# Use Build-With-Skills agent with the maintainer skill
opencode --agent build-with-skills "Use opencode-skills-maintainer skill to update agents with current skills"

# The maintainer skill will:
# 1. Scan skills/ folder for all SKILL.md files
# 2. Extract skill metadata from frontmatter
# 3. Update both Build-With-Skills and Plan-With-Skills prompts
# 4. Validate config.json with jq
# 5. Generate a maintenance report
```

#### Automated Maintenance

**Git Pre-Commit Hook** (auto-update when skills change):
```bash
# Add to .git/hooks/pre-commit
#!/bin/bash
if git diff --name-only --cached | grep -q "^skills/"; then
  echo "Skills changed, updating agent prompts..."
  opencode --agent build-with-skills "Use opencode-skills-maintainer skill"
fi
```

**Cron Job** (run daily):
```bash
# Add to crontab: 0 2 * * * cd /path/to/repo && opencode --agent build-with-skills "Use opencode-skills-maintainer skill"
```

#### Verification

After running `opencode-skills-maintainer`, verify:
```bash
# Validate JSON
jq . config.json

# Check Build-With-Skills has skills
jq '.agent["build-with-skills"].prompt' config.json | grep "Available Skills"

# Check Plan-With-Skills has skills
jq '.agent["plan-with-skills"].prompt' config.json | grep "Available Skills"
```

#### Creating New Skills

When creating new skills, use `opencode-skill-creation` skill which **automatically runs** `opencode-skills-maintainer` as a final step:

```bash
# Create a new skill (this will auto-update agents!)
opencode --agent build-with-skills "Use opencode-skill-creation to create a new skill"

# The skill-creation workflow:
# 1. Prompts for skill requirements
# 2. Generates SKILL.md with proper frontmatter
# 3. Creates directory structure
# 4. Validates skill naming and content
# 5. [AUTOMATICALLY] Runs opencode-skills-maintainer to update agents
```

This ensures every new skill is immediately available to both Build-With-Skills and Plan-With-Skills agents.

### MCP Servers
- **atlassian** - Jira and Confluence integration
- **web-reader** - Web content reading via Z.AI
- **web-search-prime** - Web search via Z.AI
- **zai-mcp-server** - Local Z.AI MCP server
- **zread** - Additional reading capabilities via Z.AI
- **drawio** - Draw.io diagram creation and modification

## Draw.io Integration

### Overview

The Draw.io MCP server enables AI agents to programmatically create, modify, and analyze Draw.io diagrams. This allows you to:

- Generate architectural diagrams from code analysis
- Create flowcharts and process maps
- Visualize complex relationships in codebases
- Annotate technical documentation with diagrams

### Prerequisites

- **Node.js v20+** (the setup script installs Node.js v24)
- **Draw.io web version**: https://app.diagrams.net/
- **Draw.io MCP Browser Extension** (Chrome/Firefox)

### Setup Instructions

#### 1. Install Draw.io Browser Extension

**Chrome/Edge:**
1. Visit [Chrome Web Store](https://chrome.google.com/webstore/detail/drawio-mcp-extension/okdbbjbbccdhhfaefmcmekalmmdjjide)
2. Click "Add to Chrome" or "Add to Edge"

**Firefox:**
1. Visit [Firefox Add-ons](https://addons.mozilla.org/en-US/firefox/addon/drawio-mcp-extension/)
2. Click "Add to Firefox"

#### 2. Verify Configuration

The Draw.io MCP server is already configured in `config.json`:

```json
{
  "mcp": {
    "drawio": {
      "type": "local",
      "command": [
        "npx",
        "-y",
        "drawio-mcp-server"
      ],
      "enabled": true
    }
  }
}
```

#### 3. Test Draw.io Integration

1. Open Draw.io: https://app.diagrams.net/
2. Verify the browser extension shows a green indicator (connected)
3. Test using the diagram-creator agent

### Using the Diagram Creator Agent

The `diagram-creator` agent is specialized for creating diagrams:

```bash
# Create an architecture diagram
opencode --agent diagram-creator "Create an architecture diagram showing the main components of this project"

# Create a flowchart
opencode --agent diagram-creator "Create a flowchart showing the authentication process"

# Visualize code relationships
opencode --agent diagram-creator "Create a diagram showing how these modules interact"
```

### Available Diagram Types

- **Architecture Diagrams**: System components and their relationships
- **Flowcharts**: Process flows and decision trees
- **UML Diagrams**: Class, sequence, and use case diagrams
- **ER Diagrams**: Database schemas and relationships
- **Network Diagrams**: Infrastructure topology
- **Mind Maps**: Hierarchical information structures

### Platform-Specific Notes

**Linux/macOS:**
- Uses `npx` command (works with Node.js installed)
- Browser extension available for Firefox/Chrome
- No special permissions required

**Windows:**
- Use `npx.cmd` instead of `npx` in config.json if needed
- Browser extensions available for Chrome/Edge/Firefox
- Windows Defender may need to allow Node.js network access

### Troubleshooting

**Extension Not Connecting:**
- Ensure MCP server is running: `npx -y drawio-mcp-server --help`
- Check port 3333 is available: `netstat -tuln | grep 3333`
- Refresh Draw.io page and recheck extension status

**Port Already in Use:**
- Use custom port in config.json by adding `--extension-port 8080` to command array
- Update browser extension settings to match custom port

**Node.js Version Issues:**
- Verify Node.js version: `node --version` (should be v20+)
- Update if needed: `nvm install 20 && nvm use 20`

## Release Process

This project uses automated semantic releases powered by GitHub Actions.

### Version Management

- **VERSION File**: Project version is stored in `VERSION` file (currently `2.0.0`)
- **Setup Script**: Reads version from `VERSION` file and displays it
- **GitHub Actions**: Creates releases automatically when code is pushed to `main`

### Automatic Releases

When you push code to `main` branch:

1. **GitHub Actions Workflow** runs automatically
2. **Reads VERSION** file for current version
3. **Creates Git Tag**: `vX.Y.Z` (e.g., `v2.0.0`)
4. **Creates GitHub Release** with:
   - Version tag
   - Release notes (auto-generated from commits)
   - Project files as attachments

### Version Bumping Rules

Releases follow [Semantic Versioning](https://semver.org/spec/v2.0.0.html):

| Commit Type | Version Bump | Example |
|-------------|---------------|----------|
| `feat:` | Minor (X.Y.z) | `2.0.0` → `2.1.0` |
| `fix:` | Patch (x.Y.Z) | `2.0.0` → `2.0.1` |
| `BREAKING CHANGE:` | Major (X.y.z) | `2.0.0` → `3.0.0` |
| Other types (`chore:`, `docs:`, etc.) | No release | N/A |

### Conventional Commits Format

Use conventional commits to trigger releases:

```
<type>(<scope>): <subject>

<body>

<footer>
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `chore`: Maintenance task
- `docs`: Documentation changes
- `style`: Code style changes
- `refactor`: Code refactoring
- `test`: Test additions/changes
- `perf`: Performance improvements
- `BREAKING CHANGE`: Breaking changes (major version bump)

**Examples:**
```bash
git commit -m "feat: add semantic release workflow with GitHub Actions"
git commit -m "fix: correct version reading from VERSION file"
git commit -m "docs: update README with release documentation"
git commit -m "chore: remove unused files"

# For breaking changes
git commit -m "feat: redesign skills architecture

BREAKING CHANGE: All skills must now use framework skills"
```

### Creating a Release

**Automatic (Recommended):**

```bash
# Update VERSION file
echo "2.1.0" > VERSION

# Commit with conventional message
git add VERSION CHANGELOG.md
git commit -m "feat: update version to 2.1.0 with new features"

# Push to main (triggers GitHub Actions)
git push origin main
```

GitHub Actions will:
1. Read `VERSION` file
2. Create git tag `v2.1.0`
3. Create GitHub release
4. Attach project files

**Manual (if needed):**

```bash
# Update VERSION file
echo "2.1.0" > VERSION

# Create tag manually
git tag -a v2.1.0 -m "Release v2.1.0"

# Push tag
git push origin v2.1.0
```

### Viewing Releases

- **Latest Release**: https://github.com/yourusername/opencode-config-template/releases/latest
- **All Releases**: https://github.com/yourusername/opencode-config-template/releases
- **Changelog**: See `CHANGELOG.md` for detailed changes

### CHANGELOG.md

The `CHANGELOG.md` file is automatically updated with:
- Release version and date
- Added features
- Changed items
- Removed items
- Fixed bugs
- Breaking changes

Contributors should update `CHANGELOG.md` when making significant changes.

## Important Notes

- Replace `"your-actual-api-key-here"` with your actual Z.AI API key
- LM Studio must be running locally on port 1234 before using OpenCode
- The configuration uses `${ZAI_API_KEY}` environment variable syntax for security
- Do not commit actual API keys to version control
- Update `VERSION` file when making new releases
- Use conventional commit format to trigger automatic releases

## Troubleshooting

### Z.AI services not working
- Verify `ZAI_API_KEY` is set: `echo $ZAI_API_KEY`
- Ensure you replaced the placeholder with a valid API key

### LM Studio connection failed
- Check that LM Studio is running: `curl http://127.0.0.1:1234/v1/models`
- Verify the server is listening on port 1234

### MCP servers not starting
- Ensure Node.js and npm are installed: `node --version && npm --version`
- Check internet connectivity for remote MCP servers
- Verify GitHub authentication: `opencode mcp auth list`

### Config not loading
- Verify file path: `ls -la ~/.config/opencode/config.json`
- Check JSON syntax: `jq . ~/.config/opencode/config.json` (requires `jq`)

### Skills not found by agents
- Verify skill was added to `skills/` folder
- Run `opencode-skills-maintainer` to update agents: `opencode --agent build-with-skills "Use opencode-skills-maintainer skill"`
- Check if skill is in agent prompts: `jq '.agent["build-with-skills"].prompt' config.json | grep "<skill-name>"`
- Verify skill name matches frontmatter exactly
- If using `opencode-skill-creation`, check if it auto-updated agents (should have completed Step 8)

### Agent prompts out of sync with skills
- Run `opencode-skills-maintainer` skill to synchronize: `opencode --agent build-with-skills "Use opencode-skills-maintainer skill"`
- Verify both agents have identical skill sections: `diff <(jq '.agent["build-with-skills"].prompt' config.json) <(jq '.agent["plan-with-skills"].prompt' config.json)`
- Check if JSON is valid: `jq . config.json`
- If automated maintenance failed, run manually as above


## License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.

### Attribution

Copyright 2026 OpenCode Configuration Template Contributors

When using or modifying this configuration template, please provide attribution by:
1. Retaining the LICENSE file in your distribution
2. Including a notice in your documentation that references this project
3. Not using the project name or contributors' names for endorsement without permission

### What You Can Do

✅ **Commercial Use** - Use this template in commercial projects
✅ **Modification** - Modify and customize the configuration
✅ **Distribution** - Share your modified versions
✅ **Patent Use** - Explicit patent grant included
✅ **Private Use** - Use privately without sharing

### What You Must Do

📋 **Include License** - Include a copy of the Apache 2.0 license
📋 **State Changes** - Document modifications you make
📋 **Include Notice** - Include copyright and attribution notices

### What You Cannot Do

❌ **Trademark Use** - Cannot use project trademarks without permission
❌ **Hold Liable** - No warranty provided, use at your own risk

For the full license text, see the [LICENSE](LICENSE) file.
