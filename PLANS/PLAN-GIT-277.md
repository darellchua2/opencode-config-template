# PLAN-GIT-277

> **CLOSED 2026-07-27 — No work performed on this branch.** Verification against `main` found the entire plan **already implemented by PR #275** (commit `8225352`, merged): *"refactor(agents): remove ticket-creation-subagent + tighten read perms + CodeGraph routing"*. All Part A and Part B acceptance criteria are satisfied on `main`; no agent files were edited on `GIT-277`. See `## Closure Verification` at end of file.

**Issue:** #277 — Tighten `read: allow` to object form (35 agents) + add CodeGraph routing to 6 code-centric agents
**Branch:** `GIT-277` (created off `main` for verification; original plan draft referenced `issue-273`).
**Status:** Done — no-op; already on `main` via PR #275.

## Overview

Two compounded issues discovered when `nextjs-specialist-subagent` failed with `JSON Parse error: Unrecognized token '<'` while trying to call `read_mcp_resource` against a hallucinated `codegraph://explore?query=...` URI.

**Problem A — Permission leak (systemic, 35 agents):** Global `opencode.json` has `permission.read: { "mcp:*": "deny" }`, but 35 of 38 subagents declare `read: allow` (string form) in frontmatter. String form overrides the global object form at agent scope, so every one of these agents can call `read_mcp_resource` despite the global deny. Fix: change `read: allow` → `read: { "mcp:*": deny, "*": allow }` (object form).

**Problem B — Missing CodeGraph routing (6 agents):** `codegraph*` tools are globally enabled in `opencode.json` `tools` block, so they ARE available to every agent. But 6 code-centric agents lack a `## CodeGraph Integration` body section, so the model has no routing guidance — and improvises with the wrong tool. Fix: add the section (canonical pattern from `explorer-subagent.md`), mode/scope-aware.

## Acceptance Criteria

### Part A — Permission tightening (35 agents)
- [ ] All 35 agents with `read: allow` updated to 3-line object form: `read:` newline `  "mcp:*": deny` newline `  "*": allow`
- [ ] `grep -l "^read: allow$\|^  read: allow$" opencode_app/.opencode/agents/*.md` returns zero hits
- [ ] `grep -l '"mcp:\*": deny' opencode_app/.opencode/agents/*.md | wc -l` returns 35
- [ ] Every edited file's frontmatter still parses as valid YAML
- [ ] File-read functionality preserved (object form `"*": allow` covers file paths)

### Part B — CodeGraph routing (6 agents)
- [ ] `## CodeGraph Integration` section added to: `nextjs-specialist-subagent`, `tdd-subagent`, `coverage-subagent`, `documentation-subagent`, `cad-specialist-subagent`, `opencode-tooling-subagent`
- [ ] `nextjs-specialist-subagent` section is mode-gated (skip Mode 1, use Mode 2/3)
- [ ] Each section follows `explorer-subagent.md` canonical pattern (tool → replaces → use-for table)
- [ ] `grep -l "## Codegraph Integration" opencode_app/.opencode/agents/*.md | wc -l` returns 24 (was 18 + 6 new)

### Both parts
- [ ] No semantic change to agent behavior beyond the two fixes
- [ ] Source-of-truth rule respected: edits only in `opencode_app/.opencode/agents/`
- [ ] Atomic commits: Phase 1 separate from Phase 2

## Scope

- 35 files in `opencode_app/.opencode/agents/*.md` — Part A (permission tightening)
- 6 of those 35 also get Part B (`## CodeGraph Integration` section)

Total: 35 files touched (29 permission-only, 6 permission + CodeGraph).

---
*Tracking progress with ticket-plan-workflow-skill*

---

## Dependency & Consumer Map

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---------------------|---------------------------|---------------------------------|-------------|
| 35x agent frontmatter `permission.read` | — | Primary agent (spawns subagents); every downstream project via `deploy/setup.sh` redeploy | low — object form is functionally equivalent for file reads; only blocks MCP resource tools that should already be blocked globally |
| 6x agent body `## CodeGraph Integration` | — | The 6 agents themselves; primary when routing | low — additive guidance, no behavioral change to existing flows |
| `opencode_app/opencode.json` (no edit) | — | — | — (no change; `codegraph*` already `true` globally) |

## Implementation Phases

### Phase 1 — Permission tightening (35 agents, mechanical)

- [ ] **1.1** Capture the exact `read: allow` line as it appears in each of the 35 agent files (verify indentation uniformity)
    — **Why:** All 35 `edit` calls need a unique-enough `oldString`; if some agents use `read: allow` and others use `  read: allow` (different indent), the match string must accommodate both
    — **Done when:** Sampled 3 files (one reviewer, one specialist, one primary) and confirmed the exact line format; pattern documented for batch editing
    — **Consumers affected:** none (read-only verification)

- [ ] **1.2** Apply the permission edit to all 35 agents in a single batch
    — **Why:** Uniform mechanical change; batching keeps it as one logical atomic commit per repo-root AGENTS.md commit conventions
    — **Done when:** 35 `edit` calls succeed; each replaces `read: allow` with the 3-line object form
    — **Consumers affected:** every spawned subagent after redeploy

- [ ] **1.3** Verify Part A grep checks pass
    — **Why:** Mechanical edits across 35 files risk typos / indentation errors; grep is the first-line gate before YAML parse validation
    — **Done when:** `grep -l "read: allow" opencode_app/.opencode/agents/*.md | wc -l` == 0 AND `grep -l '"mcp:\*": deny' opencode_app/.opencode/agents/*.md | wc -l` == 35
    — **Consumers affected:** none

- [ ] **1.4** Commit Phase 1 atomically
    — **Why:** Separates the mechanical permission fix from the thoughtful Part B routing work, per repo-root AGENTS.md atomic-commit rule
    — **Done when:** Commit `refactor(agents): tighten read permission to object form across 35 agents` created; only permission lines changed in diff
    — **Consumers affected:** none (commit only; not pushed unless user requests)

### Phase 2 — CodeGraph routing (6 agents, thoughtful)

- [ ] **2.1** Read `explorer-subagent.md` `## CodeGraph Integration` section as the canonical template
    — **Why:** Per issue Technical Notes, this is the established pattern; per-agent adaptations should be minimal deltas from it, not bespoke designs
    — **Done when:** Template structure captured (heading + intro sentence + table + fallback rule); ready to adapt per agent
    — **Consumers affected:** none

- [ ] **2.2** Draft 6 per-agent `## CodeGraph Integration` sections, mode/scope-aware
    — **Why:** Each agent has different use-cases (nextjs is mode-gated; tdd is test-focused; coverage is analysis-focused; etc.); pinning wording before insertion avoids iterative in-file editing
    — **Done when:** 6 drafts exist; nextjs-specialist explicitly says "skip in Mode 1 (scaffolding empty project, no `.codegraph/` yet); use in Mode 2 (impact tracing) and Mode 3 (audit/anti-pattern discovery)"
    — **Consumers affected:** none (drafting)

- [ ] **2.3** Insert each section into its agent body via `edit` tool
    — **Why:** Single atomic edit per file preserves git diff readability; placement chosen adjacent to existing tool-routing guidance if present, else before `## Return Contract`
    — **Done when:** 6 `edit` calls succeed; each section sits at a natural location in the agent's body
    — **Consumers affected:** the 6 agents when next spawned

- [ ] **2.4** Verify Part B grep check passes
    — **Why:** Confirm all 6 sections inserted correctly and no agent was missed
    — **Done when:** `grep -l "## CodeGraph Integration" opencode_app/.opencode/agents/*.md | wc -l` == 24 (was 18 + 6 new)
    — **Consumers affected:** none

- [ ] **2.5** Commit Phase 2 atomically
    — **Why:** Separates thoughtful routing work from mechanical permission fix
    — **Done when:** Commit `feat(agents): add CodeGraph routing to 6 code-centric agents` created; only 6 files changed in diff, only body sections added (no frontmatter)
    — **Consumers affected:** none (commit only)

### Phase 3 — Final verification

- [ ] **3.1** YAML parse validation on all 35 edited files
    — **Why:** YAML indentation errors silently break agent loading; this is the highest-risk failure mode for Phase 1's mechanical edits
    — **Done when:** Every file in `opencode_app/.opencode/agents/*.md` parses cleanly (use `yq` or python yaml.safe_load on frontmatter); zero parse errors
    — **Consumers affected:** none

- [ ] **3.2** Spot-check 3 representative files in full context
    — **Why:** Catch tone/flow issues that grep can't (e.g., CodeGraph section reads awkwardly next to existing sections; permission object form aligns with surrounding frontmatter style)
    — **Done when:** Read 3 files end-to-end: one reviewer (`typescript-reviewer-subagent`), one Part B agent (`nextjs-specialist-subagent`), one primary (`startup-founder-primary-agent`); all three read naturally
    — **Consumers affected:** none

- [ ] **3.3** Confirm no sync updates needed
    — **Why:** Repo-root AGENTS.md sync-rules table triggers on add/remove skill/agent/MCP — this issue edits existing agent content only, so no `setup.sh`/`README.md` updates required; verify to be safe
    — **Done when:** Sync-rules table consulted; confirmed no banner counts or listings reference `permission.read` format or CodeGraph routing presence
    — **Consumers affected:** none

## Technical Notes

- **Why object form works**: OpenCode permission semantics — agent-scope object form merges with (not replaces) global rules when keys are scoped patterns. `"mcp:*": deny` re-asserts the global block at agent scope; `"*": allow` covers everything else including `file:*`.
- **Why string form `read: allow` is wrong here**: string form is a blanket override of the entire permission category at agent scope, defeating the global deny.
- **Codegraph tools are MCP tools, not file reads**: gated by the global `tools` block (`"codegraph*": true`), NOT by `permission.read`. Tightening `permission.read` does NOT disable legitimate `codegraph_*` calls.
- **Canonical CodeGraph section pattern** (from `explorer-subagent.md`): heading → intro sentence conditioning on `.codegraph/` existence → table (CodeGraph Tool / Replaces / Use For) → fallback rule (grep/glob/read if no results).
- **Mode-gated routing for nextjs-specialist**: explicitly note "skip in Mode 1 (scaffolding empty project, no `.codegraph/` yet); use in Mode 2 (impact tracing) and Mode 3 (audit/anti-pattern discovery)".
- **Indentation consistency**: agent frontmatter is YAML — the new `read:` block must use the same 2-space indent as other permission keys (siblings of `read:` like `edit:`, `bash:`).
- **No deploy script changes**: agent files deployed via `deploy/setup.sh` copy; content edits trigger no count/banner sync per repo-root AGENTS.md sync-rules table.
- **Out of scope**: 14 agents without codegraph routing that are non-code-focused (`discovery-specialist`, `docx-creation`, `google-mcp-specialist`, `image-analyzer`, `microsoft-m365-specialist`, `pr-workflow`, `repo-ops-specialist`, `requirements-specialist`, `startup-founder-primary`, `autoresearch-research`, etc.) — adding routing would be noise.

## Dependencies

None.

## Risks & Mitigation

| Risk | Likelihood | Mitigation |
|------|------------|------------|
| YAML indentation error breaks agent loading | med | Phase 3.1 explicit YAML parse validation on all 35 files |
| Object form `"*": allow` unintentionally allows other categories | low | Object form keys are scoped to `read` permission category only — does not bleed into edit/bash/etc. |
| CodeGraph routing guidance diverges across 6 agents | low | Phase 2.1 fixes canonical template; per-agent deltas limited to use-case table |
| Larger PR (35 files) is hard to review | med | Phase 1.4 + 2.5 split into 2 atomic commits so reviewers focus per commit |
| Agent legitimately needing `read_mcp_resource` is blocked | low | No agent in this repo uses MCP resources; all configured MCP servers are tools-only |
| Wrong insertion point for `## CodeGraph Integration` in agent body | low | Phase 2.3 chooses placement adjacent to existing tool-routing guidance or before `## Return Contract` |
| Committed Phase 1 + Phase 2 accidentally get squashed | low | Two separate `git commit` calls with distinct semantic messages |

## Success Metrics

- `grep -l "read: allow" opencode_app/.opencode/agents/*.md | wc -l` == 0
- `grep -l '"mcp:\*": deny' opencode_app/.opencode/agents/*.md | wc -l` == 35
- `grep -l "## CodeGraph Integration" opencode_app/.opencode/agents/*.md | wc -l` == 24
- All 35 edited agent files parse as valid YAML frontmatter (Phase 3.1)
- After redeploy, spawning `nextjs-specialist-subagent` for Mode 3 audit produces zero `read_mcp_resource` errors (qualitative; tracked in follow-up)

## Closure Verification

Verified on branch `GIT-277` (off `main`) on 2026-07-27. **No agent files were edited** — the work was found pre-completed on `main`.

| Acceptance check | Expected | Actual | OK |
|---|---|---|---|
| `read: allow` string-form hits | 0 | 0 | yes |
| `"mcp:*": deny` object-form hits | 35 | 35 | yes |
| 6 target agents have `## CodeGraph Integration` | all 6 | all 6 (nextjs, tdd, coverage, documentation, cad-specialist, opencode-tooling) | yes |
| nextjs mode-gating (skip Mode 1, use Mode 2/3) | yes | yes — `nextjs-specialist-subagent.md:105-107` | yes |
| CodeGraph section count (informational) | 24 | 23 | n/a — plan baseline drift (actual baseline 17, not 18); every required agent present |
| YAML frontmatter parse, all 38 agent files | clean | 38/38, 0 errors | yes |

Implementing commit: `8225352` — *"refactor(agents): remove ticket-creation-subagent + tighten read perms + CodeGraph routing (#275)"*, merged to `main`.
