# PLAN: Implement Project-Level Subagent Support

**Issue**: #109  
**Branch**: `109-project-level-subagents`  
**Created**: 2026-03-22
**Status**: ✅ COMPLETED

---

## Overview

Create an `agents/` folder with markdown definitions for all subagents and primary agents, enabling better documentation and future migration to project-level agent support.

---

## Phase 0: Investigation [COMPLETED]

Before creating agent files, verified OpenCode markdown agent capabilities.

### Findings

- ✅ `permission.skill` is officially supported per OpenCode docs
- ✅ Per-agent MCP enablement via `tools.<mcp*>: true/false` pattern is supported
- ✅ Decision: Proceed with markdown agents + MCP token optimization

---

## Phase 1: Create `agents/` Folder Structure [COMPLETED]

### 1.1 Final Directory Structure

```
agents/
├── primary/
│   └── explore.md
└── subagents/
    ├── architecture-review-subagent.md
    ├── code-quality-subagent.md
    ├── code-review-subagent.md
    ├── coverage-subagent.md
    ├── diagram-subagent.md
    ├── docx-creation-subagent.md
    ├── documentation-subagent.md
    ├── error-resolver-subagent.md
    ├── image-analyzer.md
    ├── linting-subagent.md
    ├── nextjs-setup-subagent.md
    ├── opencode-tooling-subagent.md
    ├── opentofu-explorer-subagent.md
    ├── pr-workflow-subagent.md
    ├── refactoring-subagent.md
    ├── tdd-subagent.md
    ├── testing-subagent.md
    └── ticket-creation-subagent.md
```

### 1.2 Agent Files Summary

| Type | Count |
|------|-------|
| Primary agents | 1 |
| Subagents | 18 |
| **Total** | **19** |

### 1.3 Subagent Refactoring

**Original design had overlap:**
- `git-workflow-subagent` - Git + JIRA integration
- `workflow-subagent` - PR + JIRA workflows

**Refactored for Single Responsibility:**
- `ticket-creation-subagent` - GitHub/JIRA ticket creation, branches, semantic commits
- `pr-workflow-subagent` - PRs with framework-specific quality checks (Next.js, Python, generic)

**Rationale:**
- 70% skill overlap between original subagents
- PR workflows require framework-specific handling (lint/build/test vary by framework)
- Ticket creation is framework-agnostic

---

## Phase 2: Update Setup Scripts [COMPLETED]

### 2.1 setup.sh Changes

- [x] Added `AGENTS_SRC_DIR` and `AGENTS_DEST_DIR` variables
- [x] Added `deploy_agents()` function
- [x] **Bug fix**: Moved `deploy_agents` call outside `setup_config()` to prevent early return

### 2.2 setup.ps1 Changes

- [x] Added `$AgentsSrcDir` and `$AgentsDestDir` variables
- [x] Added `Deploy-Agents` function

### 2.3 config.json Changes

- [x] Removed `agent` block (473 lines → 74 lines, **84% reduction**)
- [x] Added MCP token optimization pattern
- [x] MCP servers enabled, but tools disabled globally
- [x] Per-agent tool enablement in agent markdown files

---

## Phase 3: Testing & Validation [COMPLETED]

| Test | Command | Status |
|------|---------|--------|
| Directory creation | `ls agents/` | ✅ Verified |
| File count | `find agents -name "*.md" \| wc -l` → 19 | ✅ Verified |
| setup.sh syntax | `bash -n setup.sh` | ✅ Passed |
| setup.sh dry-run | `./setup.sh --dry-run` | ✅ Passed |
| setup.sh quick | `./setup.sh --quick` | ✅ Passed |
| Agent deployment | `ls ~/.config/opencode/agents/` | ✅ Verified |

---

## MCP Token Optimization Strategy

### Problem
MCP server tools add to context (500-2000+ tokens per server). Having MCP enabled globally wastes tokens.

### Solution
Disable MCP tools globally, enable only in subagents that need them.

### MCP Server Assignments

| MCP Server | Subagent | Purpose |
|------------|----------|---------|
| `zai-mcp-server` | `image-analyzer` | Image/video analysis, OCR |
| `zai-mcp-server` | `error-resolver-subagent` | Error screenshot diagnosis |
| `atlassian` | `ticket-creation-subagent` | JIRA ticket CRUD |
| `atlassian` | `pr-workflow-subagent` | JIRA PR integration |

### Token Savings

| Agent | MCP Tools in Context | Token Cost |
|-------|---------------------|------------|
| `build` (primary) | ❌ None | **0 tokens** |
| `explore` (primary) | ❌ None | **0 tokens** |
| `ticket-creation-subagent` (invoked) | ✅ `atlassian` | ~500-1000 tokens |
| `pr-workflow-subagent` (invoked) | ✅ `atlassian` | ~500-1000 tokens |
| `image-analyzer` (invoked) | ✅ `zai-mcp-server` | ~500-2000 tokens |

---

## Files Modified

| File | Change |
|------|--------|
| `config.json` | Removed agent block, added MCP optimization |
| `setup.sh` | Added `deploy_agents()` function |
| `setup.ps1` | Added `Deploy-Agents` function |
| `.AGENTS.md` | Updated subagent routing table |
| `agents/` | Created 19 agent markdown files |

---

## Commits

1. `565652c` - feat(agents): implement project-level subagent support (#109)
2. `e4d0099` - feat(agents): enable atlassian MCP for JIRA subagents as primary approach
3. (pending) - refactor(agents): split into ticket-creation and pr-workflow subagents
