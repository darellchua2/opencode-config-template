# PLAN-GIT-184: Add LEARNINGS/ Infrastructure with Dual-Strategy Knowledge Persistence

**Issue**: [#184](https://github.com/darellchua2/opencode-config-template/issues/184)
**Branch**: `feat/184-learnings-infrastructure`
**Type**: feat (infrastructure)
**Priority**: major

## Overview

Implement a structured knowledge persistence system using a dual strategy: `LEARNINGS/` directory for curated, git-committed markdown artifacts and `supermemory` for searchable cross-session insights. Also integrate `continuous-learning` skill into architecture-review and code-review subagents.

## Key Finding

OpenCode does NOT auto-scan `.opencode/learnings/`. Only `agents/`, `skills/`, `plugins/`, `commands/`, `tools/`, `modes/`, `themes/` are auto-loaded. All other paths require explicit `read`/`glob`/`grep` tool calls. Agents discover files via AGENTS.md instructions (auto-loaded) + explicit tool calls.

## Dual Strategy

| Knowledge Type | Storage | Access Pattern |
|---------------|---------|---------------|
| Searchable cross-session memory | `supermemory` tool (already configured) | On-demand search by relevance |
| Curated, reviewable knowledge | `LEARNINGS/` at repo root (git-committed) | Explicit `glob`/`read` guided by AGENTS.md |
| Agent awareness | AGENTS.md instructions (auto-loaded at session start) | Always available in system prompt |

## Scope

| File | Change |
|------|--------|
| `LEARNINGS/_index.md` | Create index template |
| `LEARNINGS/patterns/.gitkeep` | Seed subfolder |
| `LEARNINGS/decisions/.gitkeep` | Seed subfolder |
| `LEARNINGS/anti-patterns/.gitkeep` | Seed subfolder |
| `LEARNINGS/solutions/.gitkeep` | Seed subfolder |
| `LEARNINGS/conventions/.gitkeep` | Seed subfolder |
| `opencode_app/.opencode/skills/continuous-learning-skill/SKILL.md` | Rewrite with dual strategy |
| `AGENTS.md` | Add learnings discovery section |
| `opencode_app/.opencode/agents/architecture-review-subagent.md` | Add continuous-learning skill + behavior |
| `opencode_app/.opencode/agents/code-review-subagent.md` | Add continuous-learning skill + behavior |
| `setup.sh` | Add user-level learnings directory creation |
| `setup.ps1` | Add user-level learnings directory creation |
| `README.md` | Add learnings section |

## Phases

### Phase 1: Directory Structure
- [x] Create `LEARNINGS/` with 5 subfolders and `.gitkeep` files
- [x] Create `LEARNINGS/_index.md` with auto-generated index template

### Phase 2: Continuous-Learning Skill Rewrite
- [x] Update SKILL.md with dual-strategy storage (supermemory + markdown)
- [x] Update storage paths: `LEARNINGS/` (project) and `~/.config/opencode/learnings/` (user)
- [x] Add `_index.md` auto-generation workflow
- [x] Add folder structure specification
- [x] Add supermemory integration instructions
- [x] Add auto-provisioning behavior (creates LEARNINGS/ in target projects)

### Phase 3: Agent Integration
- [x] Add `continuous-learning` skill permission to architecture-review-subagent
- [x] Add post-review learning behavior to architecture-review-subagent
- [x] Add `continuous-learning` skill permission to code-review-subagent
- [x] Add post-review learning behavior to code-review-subagent
- [x] Add `steps: 20` to architecture-review-subagent
- [x] Add `task: explore: allow` to architecture-review-subagent
- [x] Add Return Contract to architecture-review-subagent
- [x] Add `complexity-management` skill to code-review-subagent
- [x] Add `general` task delegation to code-review-subagent
- [x] Add severity scoring rubric to code-review-subagent
- [x] Add risk-based depth classification to code-review-subagent
- [x] Add scope assessment behavior to both agents

### Phase 4: Infrastructure Updates
- [x] Update AGENTS.md with learnings discovery section
- [x] Update setup.sh to create `~/.config/opencode/learnings/` subfolders
- [x] Update setup.ps1 to create `~/.config/opencode/learnings/` subfolders
- [x] Update README.md with LEARNINGS/ documentation
