# PLAN: Implement Project-Level Subagent Support

**Issue**: #109  
**Branch**: `109-project-level-subagents`  
**Created**: 2026-03-22
**Status**: ✅ COMPLETED

---

## Overview

Create an `agents/` folder with markdown definitions for all subagents and primary agents, reducing config.json bloat and enabling per-agent MCP enablement for token optimization.

---

## Summary

| Metric | Before | After |
|------|--------|-------|
| config.json lines | 473 | 74 (-84%) |
| Agent definitions | In config.json | 19 agents | 0 agents |
| Subagent files | 0 | 19 markdown files |
| Setup.sh | Added deploy_agents() | +2 variables, +50 lines |

---

## Phase 0: Investigation [COMPLETED]
- ✅ `permission.skill` is officially supported (OpenCode docs)
- ✅ Per-agent MCP enablement via `tools.<mcp*>: true/false` pattern
- ✅ Decision: Proceed with markdown agents + MCP token optimization

---

## Phase 1: Create Agent Files [COMPLETED]
- Created `agents/primary/` directory with 1 primary agent (explore.md)
- Created `agents/subagents/` directory with 18 subagents
- Created `agents/primary/.gitkeep` for directory persistence
- Created `agents/subagents/.gitkeep` for directory persistence

- Refactored subagents for Single Responsibility (split git-workflow into ticket-creation + pr-workflow)

- Deleted `git-workflow-subagent.md` and `workflow-subagent.md` (70% overlap)
- Created `ticket-creation-subagent.md` for GitHub/JIRA tickets, branches
- Created `pr-workflow-subagent.md` for PRs with framework-specific quality checks
- Both new subagents have `atlassian*: true` enabled

- Updated `.AGENTS.md` routing table (git-workflow-subagent → ticket-creation-subagent, pr-workflow-subagent)

- Total: 19 agent markdown files (1 primary + 18 subagents)

- Updated config.json to remove agent block, added MCP token optimization pattern

- Updated setup.sh with deploy_agents() function and variables
- Updated setup.ps1 with Deploy-Agents function and variables
- Fixed bug where deploy_agents was called inside setup_config (early return issue)
- Updated .AGENTS.md with subagent routing table
- Tested with bash -n, --dry-run, --quick, - Verified deployment to ~/.config/opencode/agents/
- Committed all changes

- Pushed to branch: https://github.com/darellchua2/opencode-config-template/pull/new/109-project-level-subagents

- Closes #109

