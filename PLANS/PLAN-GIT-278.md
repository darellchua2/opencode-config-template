# PLAN-GIT-278: Fix explore subagent calling read_mcp_resource instead of codegraph tools

**Issue**: https://github.com/darellchua2/opencode-config-template/issues/278
**Branch**: `GIT-278`
**Created**: 2026-07-30

## Problem

The built-in `explore` and `general` subagents repeatedly call `read_mcp_resource`
instead of using `codegraph_*` MCP tools. Source code analysis confirmed this is a
**tool visibility bug** in opencode upstream (`packages/opencode/src/session/tools.ts`):
MCP resource tools are added to the model's tool list unconditionally, bypassing
permission-based visibility filtering. The runtime deny works, but the model still
sees and attempts the tool.

## Root Cause (verified from opencode source)

1. **Upstream**: MCP resource tools bypass `Permission.disabled()` visibility filter
   (PR #33686 fixed only `list_mcp_resource_templates`)
2. **Our config**: All 35 custom subagents have `read` permission rules in wrong order
   (`mcp:*: deny` before `*: allow` — `*` wins as "last matching rule")
3. **Our config**: Built-in `explore`/`general` agents have no `permission.read` block
   (relies entirely on global config merge)

## Mitigation Strategy (3 layers)

| Layer | What | Why |
|-------|------|-----|
| 1. Instructions | Strengthen AGENTS.md + subagent prompts with explicit "do not call read_mcp_resource" | Tool remains visible despite deny — model needs explicit steering |
| 2. Permission ordering | Fix `read: {*: allow, mcp:*: deny}` in 35 subagent frontmatters | Good hygiene; aligns with docs ("catch-all first, specific after") |
| 3. Built-in agent permissions | Add explicit `permission.read` to `explore` and `general` in opencode.json | Defense-in-depth; doesn't rely on global merge precedence |

---

## Dependency & Consumer Map

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---------------------|---------------------------|---------------------------------|-------------|
| `opencode_app/.opencode/agents/*.md` (35 files) | — | `deploy/setup.sh` (copies to ~/.config) | low (YAML key swap) |
| `opencode_app/opencode.json` (explore/general) | — | `deploy/setup.sh` (resolves models + copies config) | low (add permission block) |
| `deploy/.AGENTS.md` | — | `~/.config/opencode/AGENTS.md` (user-space deploy) | low (text addition) |
| `opencode_app/AGENTS.md` | — | Docker container `AGENTS.md` | low (text addition) |
| `opencode_app/.opencode/agents/explorer-subagent.md` | Phase 1 (ordering fix in same file) | `deploy/setup.sh` | low (text addition) |

---

## Implementation Phases

### Phase 1: Fix permission rule ordering in all 35 custom subagents

All subagent frontmatter files have:
```yaml
read:
  "mcp:*": deny    # WRONG: evaluated first
  "*": allow        # WRONG: wins as "last matching rule"
```
Must be swapped to:
```yaml
read:
  "*": allow        # catch-all first
  "mcp:*": deny     # specific second — wins
```

- [ ] **1.1** Swap `read` permission rule order in all 35 `opencode_app/.opencode/agents/*.md` files (put `"*": allow` before `"mcp:*": deny`)
    — **Why:** The docs state "put the catch-all `*` first, specific rules after" with "last matching rule wins." Current order makes the deny dead code within the agent's own ruleset. Though global config merge handles it at runtime, fixing the order ensures correctness even if merge behavior changes.
    — **Done when:** All 35 files have `"*": allow` before `"mcp:*": deny` in their `read:` permission block; `grep -c` confirms zero files with old ordering
    — **Consumers affected:** `deploy/setup.sh` (deploys these files), all subagent sessions (correct permission enforcement)

- [ ] **1.2** Verify no subagent uses shorthand `read: allow` or `read: deny` (which would replace the object form)
    — **Why:** Shorthand form replaces the object form entirely, losing the `mcp:*` deny. Need to confirm all 35 use object syntax.
    — **Done when:** `grep` confirms all 35 files use object syntax `read:` with sub-keys, not shorthand
    — **Consumers affected:** none (validation only)

### Phase 2: Add explicit permission.read to built-in explore and general agents

- [ ] **2.1** Add `permission.read` block to `explore` agent in `opencode_app/opencode.json`
    — **Why:** The built-in explore agent has no permission block; while user config merges last and wins, adding explicit `read: {"*": "allow", "mcp:*": "deny"}` provides defense-in-depth and makes the intent visible in the agent config itself.
    — **Done when:** `jq '.agent.explore.permission.read' opencode_app/opencode.json` returns `{"*": "allow", "mcp:*": "deny"}`
    — **Consumers affected:** built-in explore subagent sessions, `deploy/setup.sh` (copies config)

- [ ] **2.2** Add `permission.read` block to `general` agent in `opencode_app/opencode.json`
    — **Why:** Same rationale as explore — the general agent also inherits from built-in defaults. Explicit deny makes intent clear.
    — **Done when:** `jq '.agent.general.permission.read' opencode_app/opencode.json` returns `{"*": "allow", "mcp:*": "deny"}`
    — **Consumers affected:** built-in general subagent sessions

- [ ] **2.3** Validate JSON syntax after edits
    — **Why:** opencode.json is the critical config file — syntax errors break everything.
    — **Done when:** `jq empty opencode_app/opencode.json` exits 0, `node -e "require('./opencode_app/opencode.json')"` succeeds
    — **Consumers affected:** entire opencode deployment

### Phase 3: Strengthen instruction-based mitigation

- [ ] **3.1** Add explicit MCP resource tool avoidance to `deploy/.AGENTS.md` CodeGraph section
    — **Why:** The upstream bug makes `read_mcp_resource` visible to all agents. Until opencode fixes the visibility filter, instruction-based mitigation is the only reliable steering. Current text says "do not call it" but doesn't explain WHY (visibility bug) or what to do instead.
    — **Done when:** CodeGraph section has a paragraph explaining the visibility bug and explicit instruction: "If you see `read_mcp_resource` in your tool list, do NOT call it — use `codegraph_*` tools or built-in `Read`/`grep`/`glob` instead."
    — **Consumers affected:** primary session, all subagents that inherit user-level AGENTS.md

- [ ] **3.2** Mirror the same guidance in `opencode_app/AGENTS.md` (Docker standalone)
    — **Why:** Docker standalone mode has its own AGENTS.md that doesn't inherit from `deploy/.AGENTS.md`. Needs the same instruction.
    — **Done when:** Docker AGENTS.md CodeGraph section has matching guidance
    — **Consumers affected:** Docker container sessions

- [ ] **3.3** Add explicit avoidance instruction to `explorer-subagent.md` prompt body
    — **Why:** The explorer-subagent is the primary agent for codebase exploration and the most likely to encounter this issue. Its prompt already has CodeGraph Integration section but doesn't explicitly say "do not call read_mcp_resource."
    — **Done when:** Explorer-subagent prompt has a line: "Do NOT call `read_mcp_resource` or `list_mcp_resources` — they are denied at runtime and will waste a step. Use `codegraph_*` tools or built-in `read`/`grep`/`glob` directly."
    — **Consumers affected:** explorer-subagent sessions

### Phase 4: Validation

- [ ] **4.1** Run documentation-consistency check (counts unchanged — no agents/skills added or removed)
    — **Why:** The sync rules require that changes to agents trigger documentation sync checks. Since we're only editing frontmatter and config (not adding/removing), counts should be unchanged.
    — **Done when:** Agent count still 38, skill count still 124 in setup.sh; README tables match
    — **Consumers affected:** none (validation only)

- [ ] **4.2** Verify deploy dry-run produces correct output
    — **Why:** Ensure the config changes don't break the deploy script.
    — **Done when:** `./deploy/setup.sh --dry-run` completes without errors
    — **Consumers affected:** deployment workflow

---

## Technical Notes

- Permission merge: `Permission.merge(defaults, agentSpecific, userConfig)` — flat array concat, last match wins
- `mcp:*` is a standard glob (not special-cased): matches `mcp:<server>:<uri>` patterns
- Source files analyzed: `packages/opencode/src/session/tools.ts`, `packages/opencode/src/permission/index.ts`, `packages/opencode/src/agent/agent.ts`
- Upstream issues: [#33686](https://github.com/anomalyco/opencode/pull/33686) (merged, partial), [#35720](https://github.com/anomalyco/opencode/issues/35720) (open), [#35721](https://github.com/anomalyco/opencode/pull/35721) (open)

## Dependencies

- None (self-contained config changes)

## Risks & Mitigation

| Risk | Likelihood | Mitigation |
|------|-----------|------------|
| JSON syntax error in opencode.json | Low | Validate with `jq` after edit (Step 2.3) |
| Wrong file edited (subagent vs built-in) | Low | File paths are distinct: `.opencode/agents/*.md` vs `opencode.json` agent block |
| Instruction too aggressive (blocks legitimate MCP resource reads) | Very Low | `mcp:*` deny is already in place; we're only strengthening visibility, not enforcement |

## Success Metrics

- Built-in `explore` subagent stops attempting `read_mcp_resource` calls
- Zero subagent frontmatter files with wrong permission ordering
- `opencode.json` explore/general agents have explicit `permission.read`
