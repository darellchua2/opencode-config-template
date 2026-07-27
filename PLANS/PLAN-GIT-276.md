# PLAN-GIT-276

**Issue:** #276 — Standardize continuous-learning-skill on `scope: user` (replace `global`)
**Branch:** `issue-273` (working on existing branch per user instruction; no new branch); NOTE: plan-updater-skill will not auto-match (extracts 273 ≠ 276) — checkboxes must be flipped manually during execution.
**Status:** Ready

## Overview

`continuous-learning-skill/SKILL.md` uses `scope: "global"` (and the conceptual term "global scope") in 9 places, but the actual `memory` tool API enum is `scope: user|project`. The author confirmed `global` was intended as a colloquial synonym for `user` — standardize on the real enum value. Discovered during #274 review (the new `## Memory Hygiene` section in `deploy/.AGENTS.md` already uses `scope: user` correctly; users following the cross-reference to this skill currently encounter the inconsistent label).

This is a **single-file label fix** with no behavioral change — `scope: user` already means "cross-project / applies globally to the user" in the `memory` plugin API.

## Acceptance Criteria

- All 3 literal `scope: global` API-value occurrences updated to `scope: user` (lines 164, 266, 545)
- All 6 conceptual "global scope" / "global instincts" references updated to consistent "user scope" / "user-level instincts" phrasing (lines 30, 152, 156, 345, 459, 539)
- `grep -in "scope.*global\|global.*scope" opencode_app/.opencode/skills/continuous-learning-skill/SKILL.md` returns zero hits
- `grep -in "global" opencode_app/.opencode/skills/continuous-learning-skill/SKILL.md` returns zero hits (or every remaining hit is verified as unrelated, e.g. "global config" — none expected)
- No semantic change to the skill's behavior
- Heading count unchanged (`grep -c "^## " …` before == after)
- Source-of-truth rule respected: edit `opencode_app/.opencode/` only, never `~/.config/opencode/`

## Scope

- `opencode_app/.opencode/skills/continuous-learning-skill/SKILL.md` (EDIT 9 occurrences across 9 lines)

---
*Tracking progress with ticket-plan-workflow-skill*

---

## Dependency & Consumer Map

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---------------------|---------------------------|---------------------------------|-------------|
| `opencode_app/.opencode/skills/continuous-learning-skill/SKILL.md` | — | Primary agent + subagents that load the skill via trigger phrases; downstream users after `./deploy/setup.sh` redeploy | low — pure label swap, no structural/behavioral change |

## Implementation Phases

### Phase 1: Reconnaissance — capture exact match strings

- [ ] **1.1** Read the source file at each of the 9 line locations (30, 152, 156, 164, 266, 345, 459, 539, 545) with ±2 lines of context
    — **Why:** Each `edit` call requires a unique `oldString`; conceptual occurrences like "global scope" may appear multiple times, so surrounding context is needed to disambiguate
    — **Done when:** All 9 line contexts captured; each occurrence classified as literal-API or conceptual; unique match string drafted per occurrence
    — **Consumers affected:** none (read-only)

- [ ] **1.2** Decide final replacement phrasing for the 6 conceptual occurrences
    — **Why:** "global scope" → "user scope" reads awkwardly in some prose contexts (e.g. "Global fallback — if no project detected" needs rephrasing to "User-level fallback — if no project detected"); pin wording before editing
    — **Done when:** Replacement text chosen for each of lines 30, 152, 156, 345, 459, 539; each reads naturally in context
    — **Consumers affected:** none

### Phase 2: Apply edits — literal API values first, then conceptual

- [ ] **2.1** Replace the 3 literal `scope: global` occurrences with `scope: user` (lines 164, 266, 545)
    — **Why:** Literal API values are the correctness-critical subset — fix these first so even if Phase 2.2 is interrupted, the skill's `memory` invocations are valid against the API enum
    — **Done when:** Three `edit` calls succeed; `grep -n 'scope: global\|scope: "global"' opencode_app/.opencode/skills/continuous-learning-skill/SKILL.md` returns zero hits
    — **Consumers affected:** any agent executing the skill's capture/promote procedures

- [ ] **2.2** Replace the 6 conceptual "global" references with the phrasing pinned in 1.2 (lines 30, 152, 156, 345, 459, 539)
    — **Why:** Eliminates the inconsistent terminology that confuses users following the cross-reference chain from `deploy/.AGENTS.md` `## Memory Hygiene`
    — **Done when:** Six `edit` calls succeed; `grep -in "global" opencode_app/.opencode/skills/continuous-learning-skill/SKILL.md` returns zero hits (or every remaining hit verified as unrelated)
    — **Consumers affected:** readers of the skill documentation

### Phase 3: Verification

- [ ] **3.1** Re-read each edited line in context (±3 lines)
    — **Why:** Confirm prose still flows naturally after the swap; catch awkward phrasing introduced by 1.2 decisions
    — **Done when:** All 9 edited locations read grammatically; no broken sentences or stale references
    — **Consumers affected:** none

- [ ] **3.2** Structural integrity check
    — **Why:** Ensure no heading/markdown corruption from the edits
    — **Done when:** `grep -c "^## " opencode_app/.opencode/skills/continuous-learning-skill/SKILL.md` matches the pre-edit count; file renders correctly
    — **Consumers affected:** none

- [ ] **3.3** Confirm no sync updates needed
    — **Why:** Repo-root `AGENTS.md` sync-rules table triggers on "New/removed skill" — this is a content edit to an existing skill, so no `setup.sh`/`README.md` updates are required; verify to be safe
    — **Done when:** Sync-rules table consulted; confirmed no banner counts or listings reference this skill's scope terminology
    — **Consumers affected:** none

## Technical Notes

- **Source of truth rule** (repo-root `AGENTS.md`): edit `opencode_app/.opencode/` source only — never `~/.config/opencode/` deployed copies. Redeploy via `./deploy/setup.sh` after merge (redeploy is out of scope for this issue).
- **API enum** (verified via `memory mode: help`): `add` accepts `scope` of `user|project`; `search` accepts `scope` of `user|project`. There is no `global` value.
- **No behavioral change**: in the `memory` plugin, `scope: user` already means "cross-project / applies globally to the user" — this is purely a label fix.
- **Occurrence inventory** (verified via grep):
  | Line | Type | Current text |
  |------|------|--------------|
  | 30   | conceptual | table row "All learnings global" / "Project-scoped + global instincts" |
  | 152  | conceptual | "Global fallback — if no project detected, instincts go to global scope" |
  | 156  | conceptual | "promote to global scope" |
  | 164  | **literal API** | "re-save with `scope: global`" |
  | 266  | **literal API** | `scope: global` (in code example) |
  | 345  | conceptual | "promoted to global scope" |
  | 459  | conceptual | "global instincts apply everywhere" |
  | 539  | conceptual | "Promote … to global scope" (in quote/example) |
  | 545  | **literal API** | "Re-save with `scope: global`" |
- **Relationship to #274**: the new `## Memory Hygiene` section in `deploy/.AGENTS.md` cross-references this skill ("for the full capture procedure, load `continuous-learning-skill`"). #276 closes the terminology loop so the chain is consistent end-to-end.
- **No deploy script changes**: content edit to existing skill → no sync per repo-root AGENTS.md sync-rules table.

## Dependencies

None.

## Risks & Mitigation

| Risk | Likelihood | Mitigation |
|------|------------|------------|
| Miss a `global` occurrence | low | Phase 3 final grep check (`grep -in global` == 0) |
| Conceptual phrasing reads awkwardly after swap | low | Phase 1.2 pre-pins wording; Phase 3.1 re-reads in context |
| Edit collision — `oldString` not unique across the 9 occurrences | med | Phase 1.1 captures ±2 lines of context per occurrence to guarantee unique match strings |
| Deployed copy at `~/.config/opencode/` diverges from source | low | Redeploy via `./deploy/setup.sh` after merge (out of scope for this issue) |
| Unrelated "global" substrings caught by final grep (e.g. "global config") | low | None expected — verify each remaining hit manually if any |

## Success Metrics

- `grep -cin "global" opencode_app/.opencode/skills/continuous-learning-skill/SKILL.md` == 0
- `grep -c "^## " opencode_app/.opencode/skills/continuous-learning-skill/SKILL.md` unchanged (before == after)
- All 9 edited lines read grammatically in context (Phase 3.1)
- After redeploy, `diff opencode_app/.opencode/skills/continuous-learning-skill/SKILL.md ~/.config/opencode/skills/continuous-learning-skill/SKILL.md` returns empty
