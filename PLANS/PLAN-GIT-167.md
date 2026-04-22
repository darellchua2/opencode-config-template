# PLAN-GIT-167: Add Built-in Subagent Task Permissions to Top 5 Agents

## Overview

Add `task` permissions to the top 5 subagents so they can delegate codebase exploration and multi-step work to OpenCode's built-in `explore` and `general` subagents. This is P0 from the subagent integration analysis.

## Problem

Currently, 0 of 30 agents have `task` permissions configured to use built-in subagents. This means:
- Agents manually glob/grep for files when `explore` could do it faster
- Agents run sequential steps when `general` could parallelize them
- No delegation chain exists between custom agents and built-in capabilities

## Acceptance Criteria

- [ ] Top 5 agents have `task` permissions in their frontmatter
- [ ] Each agent's instructions reference when to delegate to `explore` or `general`
- [ ] No breaking changes to existing agent behavior
- [ ] Permission format follows existing patterns (see `pptx-specialist-subagent`)

## Scope

| File | Agent | Task Permission |
|------|-------|----------------|
| `agents/code-review-subagent.md` | Code Review | `explore: allow` |
| `agents/testing-subagent.md` | Testing | `explore: allow` |
| `agents/linting-subagent.md` | Linting | `explore: allow` |
| `agents/pr-workflow-subagent.md` | PR Workflow | `explore: allow`, `general: allow` |
| `agents/refactoring-subagent.md` | Refactoring | `explore: allow`, `general: allow` |

---

## Phase 1: Add Task Permissions to Agent Frontmatter

- [ ] Update `agents/code-review-subagent.md` - add `task: explore: allow`
- [ ] Update `agents/testing-subagent.md` - add `task: explore: allow`
- [ ] Update `agents/linting-subagent.md` - add `task: explore: allow`
- [ ] Update `agents/pr-workflow-subagent.md` - add `task: explore: allow, general: allow`
- [ ] Update `agents/refactoring-subagent.md` - add `task: explore: allow, general: allow`

## Phase 2: Add Delegation Instructions to Agent Bodies

- [ ] Add `explore` delegation guidance to `code-review-subagent.md` (delegate codebase scanning)
- [ ] Add `explore` delegation guidance to `testing-subagent.md` (delegate test discovery)
- [ ] Add `explore` delegation guidance to `linting-subagent.md` (delegate config detection)
- [ ] Add `explore` + `general` delegation guidance to `pr-workflow-subagent.md` (parallelize checks)
- [ ] Add `explore` + `general` delegation guidance to `refactoring-subagent.md` (parallel refactors)

## Phase 3: Validation

- [ ] Verify YAML frontmatter is valid for all 5 files
- [ ] Verify permission format matches existing patterns
- [ ] Commit with semantic message
