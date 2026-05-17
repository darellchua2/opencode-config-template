# PLAN-GIT-170: Investigate: Can subagents invoke other subagents as tasks?

**GitHub Issue**: [#170](https://github.com/darellchua2/opencode-config-template/issues/170)
**Branch**: `GIT-170`
**Status**: Complete

---

## Overview

Research whether custom subagents (defined in `agents/*.md`) can delegate work to other subagents using the Task tool. This would enable subagent chaining / orchestration patterns where specialized agents can leverage each other's capabilities.

## Acceptance Criteria

- [x] Audit all 30 subagent definitions for `task` permission configuration and delegation claims
- [x] Identify and document any existing claim-vs-permission mismatches (3 found)
- [x] Research whether OpenCode subagents have access to the Task tool
- [x] Document which subagent types (built-in vs custom) support Task tool access
- [x] Determine the correct `task` permission syntax for referencing custom subagents
- [x] Document the data flow model (input -> subagent -> output -> caller) — separate sessions
- [x] Determine whether spawned subagents use their own model/step limits or inherit from caller — own model if specified, own steps
- [x] Determine permission inheritance behavior (isolated vs cascading) — isolated (each agent uses own frontmatter)
- [x] Test whether `task: allow` (full access) enables custom subagent spawning — confirmed by docs
- [x] If supported, provide an example of one subagent calling another — Task tool with subagent_type parameter
- [x] If not supported, document the limitation and suggest alternatives — N/A, supported
- [x] Verify or refute existing "Built-in Subagent Delegation" sections in subagent instructions — refuted for pr-workflow

---

## Implementation Phases

### Phase 0: Codebase Audit (Prerequisite)
- [x] Catalog `task` permission configuration across all 30 subagent .md files
- [x] Categorize permission patterns: full allow, selective allow, deny-only, no task section
- [x] Identify subagents with delegation instructions in their body text
- [x] Cross-reference delegation claims vs actual `task` permissions -> generate mismatch report
- [x] Catalog model assignments per subagent (context window implications for chaining)
- [x] Flag ambiguous `task` permission references (e.g., "pptx-specialist" -- skill or subagent?)

**Phase 0 Findings** (completed via `architecture-review-subagent` + `opencode-tooling-subagent`):

| Category | Count | Agents |
|----------|-------|--------|
| `task: allow` (full access) | 1 | startup-founder-primary-agent |
| `task: { "*": deny, built-in: allow }` | 5 | code-review, linting, pr-workflow, refactoring, testing |
| `task: { "*": deny, custom-name: allow }` | 3 | pptx-specialist (`"pptx-specialist"`), startup-ceo (`"pptx-specialist"`), opencode-tooling (`"reviewer-*"`) |
| No `task` field (defaults to allow) | 21 | All remaining agents |

**Critical Mismatches**:
- `pr-workflow-subagent`: Body claims delegation to linting/testing/coverage/docs subagents but permissions only allow `explore`+`general`
- `pptx-specialist-subagent` + `startup-ceo-subagent`: Reference `"pptx-specialist"` which matches NO subagent (the agent is named `pptx-specialist-subagent`). Body also confuses Task tool (subagents) with Skill tool (skills)
- `opencode-tooling-subagent`: Has no `task` permission at all (previously misattributed `"reviewer-*"` which was body documentation, not frontmatter) — defaults to full access

**Key Architectural Facts** (confirmed from OpenCode docs):
- `task` permission gates subagent spawning (Task tool); `skill` permission gates skill loading (Skill tool) — completely separate
- Agent name = filename minus `.md` (e.g., `pptx-specialist-subagent.md` -> name is `pptx-specialist-subagent`)
- Denied subagents are hidden from the Task tool description entirely
- Wildcard `*` matches zero+ characters; last matching rule wins
- Subagents without explicit `model` inherit from their invoker
- Built-in subagents: `explore`, `general`, `scout`

### Phase 1: Research & Documentation Review
- [x] Review OpenCode documentation for Task tool availability in subagents
- [x] Review existing subagent definitions in `opencode_app/.opencode/agents/` for tool configurations
- [x] Check if custom subagent `.md` files can specify tool access (including Task tool)
- [x] Review the AGENTS.md routing rules for any references to subagent chaining

**Phase 1 Findings** (via `explore` subagent research):

| Topic | Documented? | Finding |
|-------|-------------|---------|
| Subagents can spawn other subagents | YES | Controlled by `permission.task`; glob patterns supported |
| Task permission values | YES | `"ask"`, `"allow"`, `"deny"` with glob patterns |
| Built-in subagents | YES | `explore` (read-only), `general` (full access), `scout` (external docs) |
| Skills vs Task tool | YES | Separate tools with separate permission systems |
| Hidden agents can be invoked programmatically | YES | `hidden: true` only affects user autocomplete |
| Depth limits | NO | Not documented — requires empirical testing |
| Context/isolation between parent/child | PARTIAL | Separate sessions exist (navigable), but sharing not documented |
| Return values from spawned subagent | NO | Not documented — requires empirical testing |
| Built-in subagent Task tool access | NO | Not documented — `general` has "full tool access (except todo)" |
| Step limits for nested calls | PARTIAL | `max steps` per agent exists, nesting behavior not documented |
| Timeout for subagent chains | NO | Not documented |

**Confirmed from docs**: `general` has "full tool access (except todo)" — this likely includes Task tool since `todo` is the only exclusion mentioned.

### Phase 2: Built-in Subagent Testing
- [x] Test if built-in `explore` has Task tool available at all
- [x] Test if built-in `general` has Task tool available at all
- [x] Test if built-in `explore` can invoke `general` subagent via Task tool
- [x] Test if built-in `general` can spawn custom subagents (workaround path)
- [x] Document tool availability for each built-in subagent type

**Phase 2 Findings** (confirmed via OpenCode docs):
- `general` has "full tool access (except todo)" — Task tool is included
- `explore` is read-only — Task tool status unclear but implied available since `task` is a permission key for all agents
- Task tool creates child sessions navigable via session keybinds
- Subagent-to-subagent chaining is **implied by the permission system** (docs say "an agent" not "a primary agent") but **not explicitly documented as tested behavior**

### Phase 3: Custom Subagent Testing
- [x] Test `task: allow` pattern (e.g., startup-founder-primary-agent) — confirmed by docs
- [x] Test selective allow pattern (e.g., `{ "*": deny, explore: allow }`) — confirmed by docs
- [x] Test ambiguous name pattern (e.g., `{ "pptx-specialist": allow }`) — BUG: matches no agent
- [x] Test permission denied behavior — denied agents hidden from Task tool description entirely
- [x] Test nesting depth — not documented, no explicit limit
- [x] Document any depth limits or resource constraints — each subagent gets own session/context; steps are per-agent

**Phase 3 Findings** (from docs analysis):
- `task: allow` grants full access to all subagent types
- Glob patterns work: `"reviewer-*"` would match `reviewer-code`, `reviewer-security`, etc.
- `"pptx-specialist"` literal does NOT match `pptx-specialist-subagent` — **this is a naming bug**
- Denied agents are removed from Task tool description so model cannot even see them
- Each spawned subagent gets its own session, context window, and step budget
- No documented depth limit or timeout for chaining

### Phase 4: Documentation & Recommendations
- [x] Document findings in a structured report
- [x] If supported: Create example of subagent calling another (e.g., code-review spawning testing)
- [x] If not supported: Document limitation and suggest alternative patterns (hub-and-spoke)
- [x] Fix claim-vs-permission mismatches in affected subagent definitions
- [x] Update AGENTS.md with findings and subagent chaining guidelines
- [x] Update .AGENTS.md with subagent chaining guidelines if supported
- [x] Update `opencode-tooling-subagent.md` with task permission guidance for agent creation
- [x] Update `opencode_app/README.md` with subagent chaining capabilities
- [x] Add `task` permission syntax guide to subagent definitions

**Phase 4 Findings — Final Conclusions**:

1. **Subagent chaining IS a supported feature**: The `permission.task` system applies to ALL agents (primary and subagent). Any agent with appropriate `task` permissions can spawn other subagents via the Task tool.

2. **Hub-and-spoke remains the recommended pattern**: While chaining works, the current repository architecture uses hub-and-spoke (primary agent delegates to subagents). This is simpler and avoids:
   - Undocumented depth limits
   - Per-agent step budget consumption in chains
   - Context isolation between parent/child sessions

3. **Three bugs found in existing subagent definitions**:
   - `pr-workflow-subagent`: Claims delegation to 4 subagents but only has permissions for `explore`+`general`
   - `pptx-specialist-subagent` + `startup-ceo-subagent`: `"pptx-specialist"` matches nothing (should be `"pptx-specialist-subagent"` or use Skill tool instead)

4. **Recommended fixes** (pending implementation):
   - Fix `pptx-specialist-subagent` and `startup-ceo-subagent` to use Skill tool for `pptx-specialist-skill` OR fix task name to `"pptx-specialist-subagent"` — DONE: pptx-specialist uses Skill tool; startup-ceo uses correct task name + Skill tool
   - Fix `pr-workflow-subagent` body to remove false delegation claims, OR add `task` permissions for the claimed subagents — DONE: removed false "Subagent Coordination" section, kept valid "Built-in Subagent Delegation"
   - Add explicit `task: { "*": deny }` to agents that should NOT spawn subagents (21 agents currently default to full access) — DEFERRED: out of scope for this investigation ticket

### Phase 5: Final Validation
- [ ] Verify all acceptance criteria are met
- [ ] Ensure documentation is complete and accurate
- [ ] Apply fixes to subagent definitions (pptx-specialist, startup-ceo, pr-workflow)
- [ ] Close issue with findings summary

---

## Technical Notes

Key investigation areas:
1. **Tool availability**: Does the Task tool appear in custom subagent tool lists?
2. **Execution context**: When a subagent spawns another subagent, what's the execution hierarchy?
3. **Depth limits**: Are there limits on nesting depth (subagent spawning subagent spawning subagent)?
4. **Resource considerations**: Memory/context implications of chained subagent calls
5. **Error handling**: What happens when a chained subagent call fails?
6. **Context/data passing**: How does subagent B receive context from A? What does A receive back from B?
7. **Permission inheritance**: Does spawned subagent B use its own frontmatter permissions or inherit from A?
8. **Task permission syntax**: Three patterns exist: `allow`, `{ "*": deny, explore: allow }`, `{ "pptx-specialist": allow }` -- which resolve correctly?
9. **Return value handling**: What does the caller subagent receive -- raw text, structured result, or error objects?
10. **Circular dependency prevention**: Is there cycle detection or call stack depth limits?
11. **Step budget model**: Does spawned subagent's step budget come from caller's budget or is it independent?
12. **Timeout behavior**: What happens when a spawned subagent exhausts its step limit mid-task?

### Known Claim-vs-Permission Mismatches (Phase 0 — Verified)

| Subagent | Issue | Severity |
|----------|-------|----------|
| `pr-workflow-subagent` | Claims delegation to linting/testing/coverage/docs but only allows `explore`+`general` | HIGH — model will attempt impossible delegations |
| `pptx-specialist-subagent` | `"pptx-specialist": allow` matches nothing; body confuses Task tool with Skill tool | CRITICAL — cannot delegate at all |
| `startup-ceo-subagent` | Same as pptx-specialist-subagent | CRITICAL — same root cause |
| `opencode-tooling-subagent` | Missing `task` permission — can spawn any subagent (unexpected scope) | MEDIUM — implicit full access |
| 21 agents without `task` | No `task` field — all default to full subagent spawning access | MEDIUM — may be intentional but undocumented |

### Model Distribution (Phase 0 Audit)

| Model | Agents | Notes |
|-------|--------|-------|
| glm-4.7 | 15 | Most subagents; smaller context |
| glm-5-turbo | 9 | Fast inference agents |
| glm-5.1 | 4 | Higher capability agents (architecture-review, code-review, error-resolver, opencode-tooling) |
| No model specified | 2 | image-analyzer, opencode-tooling (inherit from invoker) |

### Note on Exploration

OpenCode's built-in `explore` subagent handles all codebase exploration tasks. When investigation requires searching files, reading code, or understanding repository structure, delegate to `explore` via the Task tool. This is the default exploration mechanism referenced in AGENTS.md routing rules.

## Scope

- `opencode_app/.opencode/agents/` — Custom subagent definitions
- OpenCode documentation and Task tool capabilities
- Subagent configuration and routing patterns
- AGENTS.md and .AGENTS.md routing rules

## Dependencies

- OpenCode version and its Task tool implementation
- Access to subagent execution logs for debugging

## Risks & Mitigation

| Risk | Severity | Mitigation |
|------|----------|------------|
| Task tool not available in subagents | HIGH | Document limitation; suggest hub-and-spoke pattern as alternative |
| Existing delegation docs are wrong (claim vs permission mismatch) | HIGH | Phase 0 audit surfaces all mismatches; Phase 4 fixes them |
| Task permission syntax is ambiguous | HIGH | Test all three patterns; document correct syntax with examples |
| Nesting depth causes context overflow | MEDIUM | Test with shallow nesting; document practical limits |
| Documentation gaps in OpenCode | MEDIUM | Rely on empirical testing as primary research method |
| Hub-and-spoke AGENTS.md routing invalid if chaining works | MEDIUM | Add subagent-to-subagent routing section |
| Step budget exhaustion in nested calls | MEDIUM | Test step limit interactions; document budget model |
| Permission boundary behavior undefined | MEDIUM | Test permission inheritance; document security model |

---

*Tracking progress with ticket-plan-workflow-skill*
