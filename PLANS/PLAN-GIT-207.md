# PLAN: Replace opencode-supermemory with opencode-superlocalmemory

**Issue**: [#207 — Replace opencode-supermemory with opencode-superlocalmemory (100% local)](https://github.com/darellchua2/opencode-config-template/issues/207)
**Branch**: `issue-207`
**Status**: Completed

---

## Summary

Migrate from `opencode-supermemory` (cloud plugin requiring API key) to `opencode-superlocalmemory` (100% local, no API key). The plugin uses Orama (embedded vector DB) + Transformers.js (local embeddings).

### Key Mapping

| Aspect | Old | New |
|--------|-----|-----|
| Plugin name | `opencode-supermemory` | `opencode-superlocalmemory` |
| Tool name | `supermemory` | `memory` |
| Delete mode | `forget` | `delete` |
| API key | `SUPERMEMORY_API_KEY` required | Not needed |
| Config file | `~/.config/opencode/supermemory.jsonc` | `~/.config/opencode/superlocalmemory.json` |
| Data storage | Cloud (app.supermemory.ai) | Local (`~/.superlocalmemory/memories.json`) |

### Files Affected (9 files, 33 references)

| # | File | Changes |
|---|------|---------|
| 1 | `deploy/config.json` | Plugin name swap |
| 2 | `opencode_app/opencode.json` | Plugin name swap |
| 3 | `opencode_app/.opencode/agents/code-review-subagent.md` | Tool name + mode |
| 4 | `opencode_app/.opencode/agents/architecture-review-subagent.md` | Tool name + mode |
| 5 | `opencode_app/.opencode/skills/continuous-learning-skill/SKILL.md` | 33 tool name + mode refs |
| 6 | `AGENTS.md` | Documentation refs |
| 7 | `README.md` | Documentation refs |
| 8 | `LEARNINGS/_index.md` | Documentation refs |
| 9 | `opencode_app/.opencode/skills/strategic-compact-skill/SKILL.md` | 1 reference |

---

## Phase 1: Config Files — Plugin Name Swap

- [x] **1.1** Update `deploy/config.json:8` — change `"opencode-supermemory"` → `"opencode-superlocalmemory"`
- [x] **1.2** Update `opencode_app/opencode.json:8` — change `"opencode-supermemory"` → `"opencode-superlocalmemory"`

## Phase 2: Agent Files — Tool Rename

- [x] **2.1** Update `opencode_app/.opencode/agents/code-review-subagent.md` — change `supermemory` → `memory` tool reference
- [x] **2.2** Update `opencode_app/.opencode/agents/architecture-review-subagent.md` — change `supermemory` → `memory` tool reference

## Phase 3: Skill Files — Tool Rename (bulk)

- [x] **3.1** Update `opencode_app/.opencode/skills/continuous-learning-skill/SKILL.md` — rename all `supermemory` tool calls to `memory`, change mode `forget` → `delete` (33 references)
- [x] **3.2** Update `opencode_app/.opencode/skills/strategic-compact-skill/SKILL.md` — rename `supermemory` reference to `memory`

## Phase 4: Documentation Files — Update References

- [x] **4.1** Update `AGENTS.md` — change `supermemory` tool references to `memory` (storage strategy table, usage patterns)
- [x] **4.2** Update `README.md` — change `supermemory` tool references to `memory`
- [x] **4.3** Update `LEARNINGS/_index.md` — change `supermemory` tool reference to `memory`

## Phase 5: Verification

- [x] **5.1** Grep entire codebase for any remaining `supermemory` references (zero outside PLAN file itself)
- [x] **5.2** Verify `opencode-superlocalmemory` plugin name is consistent in both config files
- [x] **5.3** Verify `memory` tool name is used in all agent and skill files
- [x] **5.4** Verify no `SUPERMEMORY_API_KEY` references remain in any file
- [x] **5.5** Check `.env.example` for `SUPERMEMORY_API_KEY` — not present
