# PLAN-GIT-274

**Issue:** #274 — Add Memory Hygiene section to deploy/.AGENTS.md for automatic recall+capture
**Branch:** `issue-273` (working on existing branch per user instruction; no new branch); NOTE: plan-updater-skill will not auto-match (extracts 273 ≠ 274) — checkboxes must be flipped manually during execution.
**Status:** Complete — Memory Hygiene section shipped in 5b52c89 (deploy/.AGENTS.md:82); all AC met

## Overview

The `opencode-superlocalmemory` plugin provides the `memory` tool natively but has **no auto-trigger** — it fires only when an agent voluntarily calls it. This wastes the plugin's capability and makes the documented "check `memory` before reviewing or planning" convention unreliable.

`deploy/.AGENTS.md` is deployed to `~/.config/opencode/AGENTS.md` and injected into every session. Adding a terse `## Memory Hygiene` section turns recall+capture into a **cross-project convention** — zero code, provider-agnostic, immediate effect. This is **tier 2 (AGENTS.md instructions)** automation.

## Acceptance Criteria

- `## Memory Hygiene` section added to `deploy/.AGENTS.md`
- Section defines: (a) when to recall, (b) when to capture, (c) guardrails
- Terse — matches existing tone of `deploy/.AGENTS.md`
- `scope: project` / `scope: user` used correctly
- No plugin code changes, no `opencode.json` changes, no repo-root `AGENTS.md` changes
- Section placement minimizes disruption
- `grep -n "Memory Hygiene" deploy/.AGENTS.md` returns exactly one hit

## Scope

- `deploy/.AGENTS.md` (ADD `## Memory Hygiene` section)

---
*Tracking progress with ticket-plan-workflow-skill*

---

## Dependency & Consumer Map

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---------------------|---------------------------|---------------------------------|-------------|
| `deploy/.AGENTS.md` | — | Primary agent + inherited subagents (loaded into every session after `deploy/setup.sh`); every downstream project via `~/.config/opencode/AGENTS.md` | low — additive section, no removal of existing rules |

## Implementation Phases

### Phase 1: Draft and insert Memory Hygiene section

- [x] **1.1** Draft the `## Memory Hygiene` block content (recall triggers, capture triggers, scope guidance, guardrails)
    — **Why:** Pin wording before insertion so the edit is a single atomic write, not iterative in-file editing
    — **Done when:** Draft text exists in working memory with: (a) recall-on rule, (b) capture-on rule, (c) one-add-per-decision noise guard, (d) no-secrets guard
    — **Consumers affected:** none (drafting step)

- [x] **1.2** Choose insertion point in `deploy/.AGENTS.md` (immediately after `## Commit Conventions`, at end of file — confirmed Commit Conventions is the last `##` section)
    — **Why:** `## Commit Conventions` is the file's terminal section; appending Memory Hygiene after it groups soft-convention rules together (Commit + Memory) and is least disruptive — no existing section is split or reordered.
    — **Done when:** Section boundary identified and confirmed non-disruptive to surrounding `##` headers
    — **Consumers affected:** none

- [x] **1.3** Insert the section via the `edit` tool
    — **Why:** Single atomic edit preserves git diff readability
    — **Done when:** `edit` tool returns success; `grep -n "## Memory Hygiene" deploy/.AGENTS.md` returns exactly one hit
    — **Consumers affected:** every future session (after redeploy)

### Phase 2: Self-verify tone, structure, and correctness

- [x] **2.1** Re-read the inserted section in context (5 lines above + 5 below)
    — **Why:** Confirm the new section matches the terse-by-design tone of `deploy/.AGENTS.md` and flows naturally with surrounding sections
    — **Done when:** Visual confirmation that tone, indentation, and `##` heading level match neighbors; no duplicated content with existing sections
    — **Consumers affected:** none

- [x] **2.2** Validate the `memory` tool invocation examples in the section against the plugin's actual API
    — **Why:** `memory` has specific modes (`add`, `search`, `list`, `delete`, `profile`) and parameter names (`content`, `type`, `scope`, `query`, `limit`); wrong names make the convention unexecutable
    — **Done when:** Every `mode:` and parameter name in the section matches `memory` help output
    — **Consumers affected:** none

- [x] **2.3** Confirm no other repo files require sync
    — **Why:** Repo-root `AGENTS.md` "Adding Skills or Subagents — Sync Rules" table lists files to update for skill/agent/MCP changes; this issue is a content edit to an existing file (not adding a skill/agent/MCP), so sync is unnecessary — but verify to be safe
    — **Done when:** Confirmed via the sync-rules table that `deploy/setup.sh`, `README.md`, `opencode_app/README.md` need no changes for an AGENTS.md content edit
    — **Consumers affected:** none

## Technical Notes

- **Trigger reliability disclosure**: tier 2 is soft automation. If guaranteed recall in CI/headless is later required, tier 1 (plugin hooks in `opencode-superlocalmemory`) is the path — tracked separately, not in this issue.
- **Avoid memory pollution**: the section must explicitly state "one `memory add` per decision, not per routine commit" to prevent noise.
- **Type taxonomy**: reuse plugin's built-in types (`error-solution`, `architecture`, `learned-pattern`, `preference`, `project-config`, `conversation`) — do not invent new types in the section text.
- **Scope discipline**: `scope: project` for repo-scoped learnings; `scope: user` for cross-project preferences only.
- **No deploy script changes**: `deploy/setup.sh` already copies `deploy/.AGENTS.md` → `~/.config/opencode/AGENTS.md`; content edits require no sync (per repo-root AGENTS.md sync-rules table).
- **Relationship to continuous-learning-skill**: this section is the always-on trigger; for detailed capture procedure (instinct model, confidence scoring, LEARNINGS/ markdown), load `continuous-learning-skill`. Omit full `memory()` invocation syntax; reference parameter names in prose only to stay ≤15 lines.

## Dependencies

None.

## Risks & Mitigation

| Risk | Likelihood | Mitigation |
|------|------------|------------|
| Model ignores the soft convention (tier 2 weakness) | med | Document explicitly; pair with `continuous-learning-skill` (tier 3) for stronger triggers later |
| Section too verbose, diluting the terse-by-design file | low | Phase 2.1 visual check; target ≤15 lines |
| Wrong `memory` parameter names in examples | low | Phase 2.2 explicit validation against plugin API |
| User redeploys before commit | low | Section is local-only until committed; user controls deploy timing |
| Section guidance diverges from `continuous-learning-skill` | low | Phase 2.1 cross-check; keep section as trigger-only, defer detail to the skill |

## Success Metrics

- `grep -c "## Memory Hygiene" deploy/.AGENTS.md` == 1
- Section ≤ 15 lines
- All `memory` invocations in the section use parameter names that exist in `memory` help output
- After redeploy, a fresh session's behavior shows proactive `memory search` at review/plan start (qualitative; tracked in follow-up)
- Heading count: `grep -c "^## " deploy/.AGENTS.md` == 10 (was 9)
