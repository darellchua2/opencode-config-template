# PLAN-GIT-192: Add CodeGraph priority instructions to subagent .md files

**Issue**: [#192](https://github.com/darellchua2/opencode-config-template/issues/192)
**Branch**: `issue-192-codegraph-subagent-awareness`
**Status**: Ready to begin execution

---

## Problem

Zero out of 31 custom subagent `.md` files in `opencode_app/.opencode/agents/` mention CodeGraph. Subagents run in isolated sessions and only see their own `.md` file, not the global `AGENTS.md`. Agents doing code exploration have no CodeGraph awareness despite it being configured and available.

## Solution

Add a `## CodeGraph Integration` section to 5 critical subagent `.md` files + fix the Docker `AGENTS.md` gap.

## Reusable Template

Each agent receives this base pattern, customized with role-specific guidance:

```markdown
## CodeGraph Integration

When `.codegraph/` exists in the project, prioritize CodeGraph tools over grep/glob/read:

| CodeGraph Tool | Replaces | Use For |
|---|---|---|
| `codegraph_search` | grep for symbols | Find symbols by name |
| `codegraph_callers` / `callees` | Manual import tracking | Trace call flow in/out |
| `codegraph_impact` | File-by-file search | Assess change radius |
| `codegraph_files` | glob chains | Get indexed file structure |
| `codegraph_node` | Read full file | Get one symbol's details |

For deep exploration, delegate to `explore` with instructions to use `codegraph_explore` as the primary tool.

If `.codegraph/` does not exist, fall back to grep/glob/read normally.
```

---

## Phase 1: Critical Subagents

### 1.1 `explorer-subagent.md` — CodeGraph as primary exploration tool

- [x] Add `## CodeGraph Integration` section after existing tool guidance
- [x] `codegraph_explore` replaces multi-file grep/glob chains (primary tool for exploration)
- [x] `codegraph_context` replaces manual context building
- [x] `codegraph_search` replaces grep for symbol name lookups
- [x] `codegraph_files` replaces glob for file structure queries
- [x] `codegraph_node` replaces Read for single symbol details
- [x] Document fallback to grep/glob/read when `.codegraph/` doesn't exist
- [x] Exception: remote GitHub repos use `zai-zread` (CodeGraph is local-only)

### 1.2 `code-review-subagent.md` — CodeGraph for structural reviews

- [x] Add `## CodeGraph Integration` section after existing review methodology
- [x] `codegraph_impact` on changed files before starting review
- [x] `codegraph_callers`/`callees` to verify changed symbols don't break consumers
- [x] `codegraph_search` to find similar patterns across codebase
- [x] When delegating to `explore`: request "use codegraph_explore for structural analysis"

### 1.3 `architecture-review-subagent.md` — CodeGraph for dependency analysis

- [x] Add `## CodeGraph Integration` section after existing analysis methodology
- [x] `codegraph_callers`/`callees` to map actual dependency graphs (not just imports)
- [x] `codegraph_explore` to verify dependency direction (domain -> infrastructure)
- [x] `codegraph_impact` with depth=3 to find high-coupling modules
- [x] When delegating to `explore`: request "use codegraph_explore for dependency analysis"

### 1.4 `refactoring-subagent.md` — CodeGraph for safe refactoring

- [x] Add `## CodeGraph Integration` section after existing refactoring methodology
- [x] `codegraph_callers` on symbols before changing — know ALL consumers first
- [x] `codegraph_impact` with depth=2 to assess change radius
- [x] `codegraph_search` + `codegraph_callees` to find symbols with identical call patterns
- [x] When delegating to `explore`: request "use codegraph_explore for pattern analysis"

### 1.5 `testing-subagent.md` — CodeGraph for test discovery

- [x] Add `## CodeGraph Integration` section after existing test methodology
- [x] `codegraph_files` instead of glob chains for project layout
- [x] `codegraph_search` to find test-related symbols
- [x] When delegating to `explore`: request "use codegraph_files for structure and codegraph_search for test patterns"

---

## Phase 2: Docker Mode Fix

### 2.1 `opencode_app/AGENTS.md` — Add condensed CodeGraph section

- [x] Add CodeGraph tool priority table
- [x] Document per-project setup requirement (`codegraph init -i`)
- [x] Keep section concise (Docker AGENTS.md is a summary document)

---

## Phase 3: Optional Enhancements (Low Priority)

### 3.1 `linting-subagent.md` — Brief CodeGraph mention

- [x] Add brief `codegraph_files` mention for project structure detection

### 3.2 `error-resolver-subagent.md` — Brief CodeGraph mention

- [x] Add brief `codegraph_node`/`codegraph_callers` mention for error tracing

---

## Exclusions

- **Built-in agents** (`explore`, `general`): No changes needed — they receive CodeGraph instructions via `AGENTS.md` injection
- **No code changes**: This is purely documentation in `.md` files
- **No setup.sh/setup.ps1 changes**: Agent file contents don't affect deploy scripts

## Validation

After all phases:
- [x] Grep `opencode_app/.opencode/agents/*.md` for "CodeGraph" — expect 7 files (5 critical + 2 optional)
- [x] Grep `opencode_app/AGENTS.md` for "CodeGraph" — expect at least 1 match
- [x] Verify each critical file has a tool priority table
- [x] Verify each critical file documents fallback behavior

---

## Commit Strategy

One commit per phase using conventional commits:
1. `docs(subagents): add CodeGraph integration to critical subagent .md files` (Phase 1)
2. `docs(docker): add CodeGraph section to Docker AGENTS.md` (Phase 2)
3. `docs(subagents): add CodeGraph hints to linting and error-resolver subagents` (Phase 3)
