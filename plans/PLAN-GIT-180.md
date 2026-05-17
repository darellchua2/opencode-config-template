# Architecture Review: Agent Optimization & Office Add-in Readiness

**Issue:** [#180](https://github.com/darellchua2/opencode-config-template/issues/180)
**Branch:** `refactor/180-agent-architecture-optimization`
**Date:** 2026-05-17
**Status:** Complete
**Scope:** `opencode_app/.opencode/agents/` and related skills
**Reviewed against:** opencode.ai/docs (agents, skills, permissions, config)

---

## Executive Summary

Three high-impact optimizations for the agent architecture:

1. **Extract domain knowledge from heavy agents into skills** (~780 lines saved)
2. **Demote `pptx-specialist-subagent` from `mode: all` to `mode: subagent`**
3. **Add return contracts to subagents** to reduce context bloat

Plus medium/low items for future office add-in readiness.

---

## Corrections from opencode.ai/docs Review

These corrections were identified by reviewing against official opencode documentation. They must be addressed during implementation.

### C1. Invalid permission key in `startup-founder-primary-agent` (ERROR)

```yaml
# CURRENT (line 14) — INVALID
permission:
  docx-creation: allow    # Not a valid permission key

# CORRECTED — use skill permission
permission:
  skill:
    docx-creation-skill: allow
```

Valid permission keys per docs: `read`, `edit`, `glob`, `grep`, `bash`, `task`, `skill`, `lsp`, `question`, `webfetch`, `websearch`, `external_directory`, `todowrite`, `doom_loop`. The `edit` key covers `write`, `edit`, and `patch`.

### C2. Invalid permission key in proposed `xlsx-specialist-subagent` (ERROR)

```yaml
# PROPOSED in Phase 5 — INVALID
permission:
  read: allow
  write: allow    # Not a valid permission key
  edit: allow
  bash: allow

# CORRECTED
permission:
  read: allow
  edit: allow     # Covers write, edit, and patch
  bash: allow
  skill:
    xlsx-specialist-skill: allow
```

### C3. Missing `steps` field on several agents (COST RISK)

These agents have no `steps` field, meaning unlimited iterations until the model stops or the user interrupts. Add `steps` during Phase 4:

| Agent | Proposed Steps |
|-------|---------------|
| `microsoft-m365-specialist-subagent` (473 lines) | 25 |
| `ticket-creation-subagent` (145 lines) | 20 |
| `diagram-subagent` (69 lines) | 10 |
| `code-review-subagent` (96 lines) | 15 |
| `explorer-subagent` | 10 |

### C4. Redundant `hidden: false` in agent frontmatters (CLEANUP)

`hidden: false` is the default and only applies to `mode: subagent` agents. Remove from:
- `pptx-specialist-subagent.md` line 12
- `startup-ceo-subagent.md` line 15
- `mermaid-diagram-subagent.md` line 7

### C5. Missing `hidden: true` on proposed `xlsx-specialist-subagent`

Since `xlsx-specialist-subagent` is a pure executor (only invoked through `office-document-primary-agent`), add `hidden: true` to keep the `@` autocomplete menu clean.

---

## Phase 1: Extract Domain Knowledge into Skills (HIGH)

### Problem

Agents carry 150-470 lines of domain knowledge in their `.md` definitions. Everything after the frontmatter IS the system prompt — it loads in full every time the agent is spawned. Skills, by contrast, are loaded only when the `skill` tool is invoked. Extracting domain knowledge to skills means it's loaded on-demand rather than every spawn.

### Affected Agents

| Agent | Lines | Extract To | Est. Savings |
|-------|-------|-----------|-------------|
| `startup-ceo-subagent` | 357 | `startup-pitch-deck-skill` | ~250 lines |
| `startup-founder-primary-agent` | 156 | `startup-business-docs-skill` | ~100 lines |
| `business-development-primary-agent` | 141 | `construction-bd-skill` | ~80 lines |
| `microsoft-m365-specialist-subagent` | 473 | `microsoft-m365-config-skill` | ~350 lines |

**Total estimated savings: ~780 lines from agent definitions**

### Refactoring Pattern

**Before (current):**
```
agent file = router logic + domain knowledge + workflow steps + examples
```

**After (proposed):**
```
agent file = router logic only (~40-80 lines)
skill file = domain knowledge + workflow steps + examples (loaded on demand)
```

### Detailed Plan per Agent

#### 1A. `startup-ceo-subagent` → Extract to `startup-pitch-deck-skill`

**Keep in agent (router logic, ~60 lines):**
- Frontmatter (description, mode, model, permissions)
- Trigger phrases
- Workflow decision matrix (which deck type → which structure)
- Skill delegation pattern
- What NOT to handle
- Return contract

**Extract to new skill `startup-pitch-deck-skill` (~250 lines):**
- Pitch deck structure (10-12 slide sequence)
- Board update structure
- Product launch structure
- Demo day structure
- Design principles & typography rules
- Color palette recommendations
- Common slide layouts (Problem/Solution split, Market Size Pyramid, etc.)
- Investor-readiness checklist
- Common mistakes to avoid
- Stage-specific guidance (pre-seed, Series A, etc.)

**Agent permission change:**
```yaml
permission:
  skill:
    pptx-specialist-skill: allow
    startup-pitch-deck-skill: allow   # NEW
```

#### 1B. `startup-founder-primary-agent` → Extract to `startup-business-docs-skill`

**Keep in agent (router logic, ~60 lines):**
- Frontmatter
- Core capabilities list (reports, quotations, spreadsheets, presentations, communications)
- Subagent delegation table
- Workflow patterns (condensed to 1-line summaries)
- Trigger context
- Tone & style
- Error handling

**Extract to new skill `startup-business-docs-skill` (~100 lines):**
- Detailed workflow patterns (for reports, quotations, spreadsheets, etc.)
- Output format table
- Best practices
- Report structure templates
- Quotation pricing structure
- Spreadsheet building steps
- Presentation delegation steps

**Also fix during 1B:** Replace `docx-creation: allow` with `skill: { docx-creation-skill: allow }` (Correction C1).

#### 1C. `business-development-primary-agent` → Extract to `construction-bd-skill`

**Keep in agent (router logic, ~60 lines):**
- Frontmatter
- Core capabilities summary
- Atlassian integration workflow (condensed)
- Best practices summary

**Extract to new skill `construction-bd-skill` (~80 lines):**
- Proposal summarization detailed workflow
- Quotation preparation workflow with cost categories
- Construction industry terminology list
- Detailed Atlassian integration steps
- Document generation specifications

#### 1D. `microsoft-m365-specialist-subagent` → Extract to `microsoft-m365-config-skill`

**Keep in agent (router logic, ~80 lines):**
- Frontmatter
- Trigger phrases
- Prerequisites (condensed)
- Available MCP servers table (summary only)
- Workflow (4 steps)
- Troubleshooting (condensed)

**Extract to new skill `microsoft-m365-config-skill` (~350 lines):**
- Detailed per-server tool reference
- Configuration examples (full JSON)
- Authentication methods (detailed)
- Environment setup
- Per-service example interactions (6 examples)
- Detailed troubleshooting per error type

---

## Phase 2: Fix Agent Modes (HIGH)

### 2A. Demote `pptx-specialist-subagent` to subagent-only

**Current:** `mode: all` (appears in Tab cycle, can be used as both primary and subagent)
**Proposed:** `mode: subagent` (only invoked via `@` mention or Task tool)

**Rationale:** This agent is a pure executor. It takes a task specification and produces a `.pptx` file. It should never be the entry point for a user conversation. Users should go through `startup-founder-primary-agent` or `startup-ceo-subagent` for business context, which then delegates execution.

Per docs: `"Subagents are specialized assistants that primary agents can invoke for specific tasks."` — this is exactly what pptx-specialist is.

**File change:** `pptx-specialist-subagent.md` line 3
```yaml
# Before
mode: all

# After
mode: subagent
```

**Also during 2A:** Remove redundant `hidden: false` from this file (Correction C4).

### 2B. `ticket-creation-subagent` — Review mode

**Current:** `mode: all`
**Proposed:** Keep as `all` (legitimate primary use — user may want to directly create tickets)

### 2C. `startup-founder-primary-agent` — Keep as `all`

**Current:** `mode: all`
**Proposed:** Keep as `all` (legitimate primary — users switch to it for business doc tasks)

### 2D. Cleanup: Remove redundant `hidden: false` (Correction C4)

Remove from these agents during Phase 2:
- `startup-ceo-subagent.md`
- `mermaid-diagram-subagent.md`

---

## Phase 3: Add Return Contracts to Subagents (HIGH)

### Problem

When subagents complete, they may return verbose output (full reasoning, intermediate steps, etc.) that bloats the primary agent's context. This accelerates compaction.

### Solution

Add a standardized return contract section to every subagent definition. Note: this is a **prompt engineering convention**, not a framework feature. The LLM follows these instructions voluntarily; there is no schema validation.

### Template

```markdown
## Return Contract

When your task is complete, return ONLY this structure:

**Status:** [success | partial | failed]
**Output:** [file path(s) or key result, one line]
**Summary:** [2-3 sentences max describing what was done]
**Issues:** [blockers, warnings, or "None"]

On failure (Status: failed), you MAY include additional diagnostic
information (error messages, stack traces, root cause analysis) to help
the primary agent debug. The summary should still be concise.

Do NOT return:
- Full reasoning or chain-of-thought
- Intermediate steps or exploration logs
- Raw tool outputs (reference files instead)
- Skill content that was loaded
```

### Agents to Update

| Agent | Return Contract Fields |
|-------|----------------------|
| `pptx-specialist-subagent` | File path + thumbnail path + summary |
| `docx-creation-subagent` | File path + summary |
| `startup-ceo-subagent` | Delegated status + output summary |
| `explorer-subagent` | Key findings list + file paths |
| `image-analyzer-subagent` | Analysis type + key findings + confidence |
| `testing-subagent` | Test file paths + pass/fail summary |
| `code-review-subagent` | Issue count + severity breakdown |
| `linting-subagent` | Fix count + remaining issues |
| `pr-workflow-subagent` | PR URL + status |
| `diagram-subagent` | File path + format |
| `error-resolver-subagent` | Root cause + fix applied |
| `documentation-subagent` | Files updated + summary |
| `coverage-subagent` | Coverage % + badge path |
| `opencode-tooling-subagent` | Files modified + summary |
| `microsoft-m365-specialist-subagent` | Operation result + status |
| `google-mcp-specialist-subagent` | Query result or config snippet |
| `ticket-creation-subagent` | Ticket URL/key + status |

### Convention Documentation

After adding return contracts to all agents, document this as a project convention in `AGENTS.md` so future agent authors follow the pattern.

---

## Phase 4: Step Budget Optimization (MEDIUM)

### Principle

Router-only agents (delegate to subagents, don't do execution) need fewer steps. Execution agents need more. Per docs: `"steps" controls the maximum number of agentic iterations an agent can perform before being forced to respond with text only.` Agents without `steps` have unlimited iteration budget, which is a cost risk.

### Proposed Changes

| Agent | Current Steps | Proposed Steps | Rationale |
|-------|--------------|---------------|-----------|
| `startup-ceo-subagent` | 20 | 12 | Routes to pptx-specialist + skill |
| `startup-founder-primary-agent` | 50 | 30 | Mostly delegates to subagents |
| `pptx-specialist-subagent` | 15 | 15 | Unchanged — does real execution |
| `mermaid-diagram-subagent` | 5 | 5 | Unchanged — already lean |
| `business-development-primary-agent` | 50 | 40 | Heavy doc generation but some delegation |

### Add `steps` to Agents Missing It (Correction C3)

| Agent | Proposed Steps | Rationale |
|-------|---------------|-----------|
| `microsoft-m365-specialist-subagent` | 25 | Config + active usage, moderate complexity |
| `ticket-creation-subagent` | 20 | Creates tickets, moderate complexity |
| `diagram-subagent` | 10 | Simple diagram creation |
| `code-review-subagent` | 15 | Single-pass review |
| `explorer-subagent` | 10 | Read-only exploration |

---

## Phase 5: Office Add-in Readiness (MEDIUM - Future)

### New Agent: `office-document-primary-agent`

A unified primary agent for all office document operations. This is the entry point that the future Microsoft/OnlyOffice add-in would call.

```yaml
---
description: Unified primary agent for office document operations (docx, pptx, xlsx). Routes to specialized subagents based on file type.
mode: all
model: zai-coding-plan/glm-4.7
steps: 25
permission:
  task:
    "*": deny
    pptx-specialist-subagent: allow
    docx-creation-subagent: allow
    startup-ceo-subagent: allow
    xlsx-specialist-subagent: allow
    microsoft-m365-specialist-subagent: allow
  skill:
    pptx-specialist-skill: allow
    docx-creation-skill: allow
    xlsx-specialist-skill: allow
---
```

**Model rationale:** Uses `glm-4.7` (cheaper) because this agent is a pure router — it determines file type and delegates. It never does creative document work itself. Subagents use `glm-5-turbo` for creative execution.

**Workflow:**
```
User/Add-in → office-document-primary-agent
    ├── .pptx → pptx-specialist-subagent
    ├── .pptx (startup) → startup-ceo-subagent → pptx-specialist-subagent
    ├── .docx → docx-creation-subagent
    ├── .xlsx → xlsx-specialist-subagent (NEW)
    └── M365 operations → microsoft-m365-specialist-subagent
```

### New Subagent: `xlsx-specialist-subagent`

Currently `xlsx-specialist-skill` exists but has no corresponding subagent. For parity with docx and pptx, create one.

**File:** `opencode_app/.opencode/agents/xlsx-specialist-subagent.md`

```yaml
---
description: Specialized subagent for spreadsheet operations (.xlsx, .csv). Creates, reads, edits, and converts tabular data files.
mode: subagent
hidden: true
model: zai-coding-plan/glm-5-turbo
steps: 15
permission:
  read: allow
  edit: allow
  bash: allow
  skill:
    xlsx-specialist-skill: allow
---
```

Note: `edit: allow` covers `write`, `edit`, and `patch` per docs. `hidden: true` keeps it out of `@` autocomplete since it should only be invoked through the primary agent.

### Add-in Architecture (Reference Only - Not Implementing Now)

```
[Office Add-in UI]  <--->  [OpenCode REST API (:4096)]
     Office.js                   |
                            office-document-primary-agent
                           /          |           \
                    pptx-sub     docx-sub      xlsx-sub
```

The Docker mode already provides the HTTP endpoint. Future add-in just needs:
1. Office.js ribbon button
2. HTTP POST to `localhost:4096` with task description
3. OpenCode handles routing and execution
4. Add-in polls for result / receives callback

---

## Phase 6: Compaction Strategy Improvements (LOW)

### 6A. Extract-then-Delegate Pattern

Instead of having a subagent load a skill internally (consuming the subagent's context window), the primary agent can:
1. Load the skill itself
2. Extract the relevant parameters/workflow
3. Pass ONLY those parameters to the subagent

This keeps heavy knowledge in the primary context (which compacts via `strategic-compact-skill`) rather than the subagent's isolated context.

**Example:**
```
# Current: startup-ceo loads pitch-deck-skill internally
startup-founder -> startup-ceo (loads skill, 250 lines consumed) -> pptx-specialist

# Proposed: startup-founder extracts, passes params only
startup-founder (loads skill, extracts deck spec) -> startup-ceo (receives spec, no skill load) -> pptx-specialist
```

Note: This is a prompt engineering convention, not a framework feature. Document in `AGENTS.md` as a named pattern.

### 6B. Docker Session-Aware Defaults

For the Docker mode (add-in scenario), sessions will be shorter and more task-focused. Configure in `opencode_app/opencode.json`:

```json
{
  "agent": {
    "office-document-primary-agent": {
      "steps": 20
    }
  }
}
```

---

## Implementation Order

| Order | Phase | Files Changed | New Files | Risk |
|-------|-------|--------------|-----------|------|
| 1 | Phase 2 | 3 agent files | 0 | Low — mode + cleanup |
| 2 | Phase 3 | ~17 agent files | 0 | Low — additive, no breaking changes |
| 3 | Phase 1A | 1 agent + 1 skill dir | 1 skill dir | Medium — content migration |
| 4 | Phase 1B | 1 agent + 1 skill dir | 1 skill dir | Medium — content migration |
| 5 | Phase 1C | 1 agent + 1 skill dir | 1 skill dir | Medium — content migration |
| 6 | Phase 1D | 1 agent + 1 skill dir | 1 skill dir | Medium — content migration |
| 7 | Phase 4 | 10 agent files | 0 | Low — step count tuning |
| 8 | Phase 5 | 1-2 agent files | 1-2 agent + 0-1 skill | Medium — new agents |
| 9 | Phase 6 | Config files | 0 | Low — tuning |

---

## Sync Checklist (After Implementation)

After implementing changes, update these files:

- [ ] `setup.sh` — Skill/agent listings and counts (if new skills/agents added)
- [ ] `setup.ps1` — Same as above
- [ ] `README.md` — Subagents table, skill categories table
- [ ] `opencode_app/README.md` — Docker-specific docs
- [ ] `AGENTS.md` — Subagent locations, counts, and return contract convention

---

## Resolved Questions

These questions were resolved by reviewing against opencode.ai/docs:

### Q1: Should `business-development-primary-agent` remain construction-specific?

**Answer: Extract construction knowledge to a skill, make the agent generic.** The agent's name says "business development" but its content is 100% construction-specific (concrete, steel, OSHA, MEP). Per docs, agents should be task-focused and skills should hold domain knowledge. Renaming to `business-ops-primary-agent` with a `construction-bd-skill` would let the same agent serve other industries by loading different skills. This is exactly the pattern Phase 1 proposes for other agents — apply it consistently.

### Q2: Should `startup-ceo-subagent` remain a subagent or become a skill?

**Answer: Must remain a subagent.** After Phase 1A it becomes a thin router, but it still needs to invoke the Task tool to spawn `pptx-specialist-subagent`. Per docs, **only agents can use the Task tool** — skills are instruction sets loaded into an agent's context, not independent entities. A skill cannot spawn a subagent. The delegation chain requires it to remain an agent:

```
startup-founder (primary) -> startup-ceo (subagent) -> pptx-specialist (subagent)
                                    ^ needs Task tool        ^ does execution
```

### Q3: Model for `office-document-primary-agent`?

**Answer: Use `glm-4.7` (cheaper).** Per docs, if no model is specified, subagents use the model of the primary agent that invoked them. This agent is a pure router — it determines file type and delegates. It never does creative document work itself. A cheaper model handles routing fine. The subagents (`pptx-specialist-subagent`, `docx-creation-subagent`) use `glm-5-turbo` for creative work, which is the right model for those tasks.

### Q4: Phase 1 extraction scope — global or project-only?

**Answer: Global (`opencode_app/.opencode/skills/`).** Per the skills docs, skills are discovered from project-level (`.opencode/skills/`) and global (`~/.config/opencode/skills/`). Since this repo's `setup.sh` copies from `opencode_app/.opencode/skills/` to `~/.config/opencode/skills/`, and the extracted domain knowledge (pitch deck structures, business doc workflows, M365 config) is **globally useful across any project**, it belongs in the global deployment path. Project-only skills would only be available inside this repo, which defeats the purpose.

### Q5: Return contract strictness on errors?

**Answer: Allow extra info on failure.** The return contract includes a relaxation clause (see template in Phase 3): on `Status: failed`, subagents MAY include additional diagnostic information (error messages, stack traces, root cause analysis). A rigid contract on failures would suppress the exact information needed to fix problems. Success/partial cases remain strict.

---

## Additional Recommendations from Docs Review

1. **Standardize permission style** across all agents during Phase 1 — use granular `task`/`skill` objects everywhere instead of bare `allow` or MCP tool patterns at the top level.

2. **Add `steps` to ALL agents** as a mandatory field. Agents without `steps` have unlimited iteration budget, which is a cost risk. Even a generous default is better than unlimited.

3. **`business-development-primary-agent` uses `model: glm-4.7`** while `startup-founder-primary-agent` uses `model: glm-5-turbo`. After Phase 1C extracts domain knowledge, the BD agent becomes a router and `glm-4.7` becomes more appropriate. Consider standardizing routers on `glm-4.7`.

4. **Naming convention audit:** The repo has overlapping agents — `diagram-subagent` and `mermaid-diagram-subagent`. After Phase 1, a consolidation pass might be valuable.
