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

**Standalone Skills (No Framework):**
- **`ascii-diagram-creator`** - Create ASCII diagrams from workflow definitions
- **`opencode-agent-creation`** - Create OpenCode agents following best practices
- **`opencode-skill-creation`** - Create OpenCode skills following documentation standards
- **`typescript-dry-principle`** - Apply DRY principle to eliminate code duplication

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

Skills are deployed to `~/.config/opencode/skills/` during setup.

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

## Important Notes

- Replace `"your-actual-api-key-here"` with your actual Z.AI API key
- LM Studio must be running locally on port 1234 before using OpenCode
- The configuration uses `${ZAI_API_KEY}` environment variable syntax for security
- Do not commit actual API keys to version control

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
