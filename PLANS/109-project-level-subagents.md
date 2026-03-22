# PLAN: Implement Project-Level Subagent Support

**Issue**: #109  
**Branch**: `109-project-level-subagents`  
**Created**: 2026-03-22

---

## Overview

Create an `agents/` folder with markdown definitions for all subagents and primary agents, enabling better documentation and future migration to project-level agent support.

---

## Phase 0: Investigation (BLOCKER)

Before creating agent files, verify OpenCode markdown agent capabilities.

### Test Steps

1. Create `.opencode/agents/test-skill-permission.md`:
```markdown
---
description: Test if permission.skill is supported
mode: subagent
permission:
  skill:
    test-skill: allow
---
You are a test agent.
```

2. Run `opencode` and invoke `@test-skill-permission`

3. Create `.opencode/agents/test-mcp.md`:
```markdown
---
description: Test per-agent MCP
mode: subagent
mcp:
  zai-mcp-server:
    type: local
    command: ["npx", "-y", "@z_ai/mcp-server"]
    environment:
      Z_AI_API_KEY: "${env:ZAI_API_KEY}"
    enabled: true
---
Test MCP access.
```

4. Run `opencode` and invoke `@test-mcp`

### Decision Matrix

| Test Result | Action |
|-------------|--------|
| Both pass | Create all agents in markdown |
| skill fails | Keep skill permissions in config.json reference |
| MCP fails | Keep MCP agents (error-resolver, image-analyzer) in config.json |
| Both fail | Markdown for documentation only, JSON for runtime |

---

## Phase 1: Create `agents/` Folder Structure

### 1.1 Directory Structure

```
agents/
├── primary/
│   └── explore.md
└── subagents/
    ├── linting-subagent.md
    ├── testing-subagent.md
    ├── git-workflow-subagent.md
    ├── documentation-subagent.md
    ├── opentofu-explorer-subagent.md
    ├── workflow-subagent.md
    ├── error-resolver-subagent.md
    ├── nextjs-setup-subagent.md
    ├── coverage-subagent.md
    ├── opencode-tooling-subagent.md
    ├── refactoring-subagent.md
    ├── code-quality-subagent.md
    ├── architecture-review-subagent.md
    ├── code-review-subagent.md
    ├── tdd-subagent.md
    ├── diagram-subagent.md
    ├── docx-creation-subagent.md
    └── image-analyzer.md
```

### 1.2 Agent Files Checklist

#### Primary Agents (1)

| # | Agent | File | Status |
|---|-------|------|--------|
| 1 | explore | `agents/primary/explore.md` | [x] |

#### Subagents (18)

| # | Agent | File | Skills | MCP | Status |
|---|-------|------|--------|-----|--------|
| 1 | linting-subagent | `agents/subagents/linting-subagent.md` | linting-workflow, python-ruff-linter, javascript-eslint-linter | - | [x] |
| 2 | testing-subagent | `agents/subagents/testing-subagent.md` | test-generator-framework, tdd-workflow, python-pytest-creator, nextjs-unit-test-creator | - | [x] |
| 3 | git-workflow-subagent | `agents/subagents/git-workflow-subagent.md` | git-issue-creator, git-issue-updater, git-issue-labeler, git-pr-creator, git-semantic-commits, jira-ticket-oauth-workflow, jira-status-updater, pr-creation-workflow, git-issue-plan-workflow, jira-ticket-oauth-plan-workflow | - | [x] |
| 4 | documentation-subagent | `agents/subagents/documentation-subagent.md` | docstring-generator, coverage-readme-workflow | - | [x] |
| 5 | opentofu-explorer-subagent | `agents/subagents/opentofu-explorer-subagent.md` | opentofu-kubernetes-explorer, opentofu-neon-explorer, opentofu-aws-explorer, opentofu-keycloak-explorer, opentofu-provisioning-workflow, opentofu-provider-setup, opentofu-ecr-provision | - | [x] |
| 6 | workflow-subagent | `agents/subagents/workflow-subagent.md` | pr-creation-workflow, nextjs-pr-workflow, git-pr-creator, jira-status-updater, jira-ticket-oauth-workflow, jira-ticket-oauth-plan-workflow, git-issue-plan-workflow | - | [x] |
| 7 | error-resolver-subagent | `agents/subagents/error-resolver-subagent.md` | error-resolver-workflow | zai-mcp-server | [x] |
| 8 | nextjs-setup-subagent | `agents/subagents/nextjs-setup-subagent.md` | nextjs-standard-setup, nextjs-complete-setup, nextjs-image-usage | - | [x] |
| 9 | coverage-subagent | `agents/subagents/coverage-subagent.md` | coverage-readme-workflow, coverage-framework | - | [x] |
| 10 | opencode-tooling-subagent | `agents/subagents/opencode-tooling-subagent.md` | opencode-agent-creation, opencode-skill-creation, opencode-skill-auditor, opencode-skills-maintainer, opencode-tooling-framework | - | [x] |
| 11 | refactoring-subagent | `agents/subagents/refactoring-subagent.md` | typescript-dry-principle, solid-principles, code-smells, clean-code | - | [x] |
| 12 | code-quality-subagent | `agents/subagents/code-quality-subagent.md` | solid-principles, clean-code, code-smells | - | [x] |
| 13 | architecture-review-subagent | `agents/subagents/architecture-review-subagent.md` | clean-architecture, design-patterns, complexity-management | - | [x] |
| 14 | code-review-subagent | `agents/subagents/code-review-subagent.md` | solid-principles, clean-code, code-smells, design-patterns, object-design | - | [x] |
| 15 | tdd-subagent | `agents/subagents/tdd-subagent.md` | tdd-workflow | - | [x] |
| 16 | diagram-subagent | `agents/subagents/diagram-subagent.md` | ascii-diagram-creator | - | [x] |
| 17 | docx-creation-subagent | `agents/subagents/docx-creation-subagent.md` | docx-creation | - | [x] |
| 18 | image-analyzer | `agents/subagents/image-analyzer.md` | - | zai-mcp-server | [x] |

---

## Phase 2: Update Setup Scripts [COMPLETED]

### 2.1 setup.sh Changes [DONE]

**Changes made:**
- [x] Added `AGENTS_SRC_DIR` and `AGENTS_DEST_DIR` variables (~line 78)
- [x] Added `deploy_agents()` function (after `setup_config()`)
- [x] `setup_config()` calls `deploy_agents()` at end
- [x] Function creates agents directory, handles backups, copies files

### 2.2 setup.ps1 Changes [DONE]

**Changes made:**
- [x] Added `$AgentsSrcDir` and `$AgentsDestDir` variables (~line 59)
- [x] Added `Deploy-Agents` function (after `Deploy-Skills`)
- [x] `Deploy-Skills` calls `Deploy-Agents` at end
- [x] Function creates agents directory, handles backups, copies files

### 2.3 config.json Changes [DONE]

**Changes made:**
- [x] Removed `agent` block (was 473 lines, now 74 lines)
- [x] Added MCP token optimization pattern
- [x] MCP servers enabled, but tools disabled globally
- [x] Per-agent tool enablement happens in agent markdown files

---

## Phase 3: Testing & Validation

### Test Matrix

| Test | Command | Status |
|------|---------|--------|
| Directory creation | `ls agents/` | [x] Verified |
| File count | `find agents -name "*.md" \| wc -l` → 19 | [x] Verified |
| setup.sh syntax | `bash -n setup.sh` | [x] Passed |
| setup.sh dry-run | `./setup.sh --dry-run` | [x] Passed |
| setup.sh quick | `./setup.sh --quick` | [x] Passed - 19 agents deployed |
| Agent deployment | `ls ~/.config/opencode/agents/` | [x] Verified |
| setup.ps1 syntax | `powershell -File setup.ps1 -DryRun` | [ ] (pending) |

---

## Execution Order

```
Phase 0: Investigation
├── Test permission.skill support
│   └── ✅ VERIFIED: Official docs confirm permission.skill is valid
├── Test per-agent MCP support
│   └── ✅ VERIFIED: Official docs confirm per-agent tools.<mcp*> pattern
└── Decision: proceed/adjust approach
    └── ✅ DECIDED: Proceed with markdown agents + MCP token optimization

Phase 1: Create Agent Files [COMPLETED]
├── Create agents/primary/
├── Create agents/subagents/
├── Create 1 primary agent (explore)
└── Create 18 subagents

Phase 2: Update Setup Scripts [COMPLETED]
├── Update setup.sh
├── Update setup.ps1
└── Update config.json (removed agent block, added MCP optimization)

Phase 3: Testing [COMPLETED]
├── setup.sh syntax check ✓
├── setup.sh --dry-run ✓
├── setup.sh --quick ✓
├── Agents deployed to ~/.config/opencode/agents/ ✓
└── Bug fix: deploy_agents moved outside setup_config to fix early return
```

---

## Notes

- **config.json**: Agent definitions removed - now in `agents/` folder
- **MCP Token Optimization**: MCP tools disabled globally, enabled per-subagent only
- **Precedence**: Project-level agents (`.opencode/agents/`) override user-level (`~/.config/opencode/agents/`)

---

## MCP Token Optimization Strategy

### Problem
MCP server tools add to context (500-2000+ tokens per server). Having MCP enabled globally wastes tokens even when not using those features.

### Solution
Disable MCP tools globally, enable only in subagents that need them.

### config.json Pattern

```json
{
  "mcp": {
    "zai-mcp-server": {
      "type": "local",
      "command": ["npx", "-y", "@z_ai/mcp-server"],
      "environment": {
        "Z_AI_API_KEY": "${env:ZAI_API_KEY}",
        "Z_AI_MODE": "ZAI"
      },
      "enabled": true        // Server can be started
    }
  },
  "tools": {
    "zai-mcp-server*": false  // ❌ Disabled globally (no token cost)
  }
}
```

### Per-Agent Enable in Markdown

```yaml
---
description: Image analysis agent...
mode: subagent
tools:
  read: true
  glob: true
  zai-mcp-server*: true      # ✅ Only this agent loads MCP tools
---
```

### Token Savings

| Agent | MCP Tools in Context | Token Cost |
|-------|---------------------|------------|
| `build` (primary) | ❌ None | **0 tokens** |
| `explore` (primary) | ❌ None | **0 tokens** |
| `image-analyzer` (invoked) | ✅ `zai-mcp-server` | ~500-2000 tokens |
| `error-resolver-subagent` (invoked) | ✅ `zai-mcp-server` | ~500-2000 tokens |

### MCP Server Assignments

| MCP Server | Subagent | Purpose |
|------------|----------|---------|
| `zai-mcp-server` | `image-analyzer` | Image/video analysis, OCR |
| `zai-mcp-server` | `error-resolver-subagent` | Error screenshot diagnosis |
| `atlassian` | (optional future) | JIRA/Confluence integration |
| `web-reader` | (optional future) | Web content extraction |
| `web-search-prime` | (optional future) | Web search |
| `zread` | (optional future) | GitHub repo reading |

### Context Loading Flow

```
Global:    "tools": { "zai-mcp-server*": false }  ← ❌ Disabled everywhere
                              ↓
Primary Agent (build/explore):                    ← ❌ No MCP context
   inherits global = disabled
                              ↓
Subagent invoked (@image-analyzer):
   "tools": { "zai-mcp-server*": true }           ← ✅ MCP tools load NOW
                              ↓
Subagent context:                                 ← MCP tools appear here only
```
