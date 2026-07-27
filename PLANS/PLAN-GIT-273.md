# PLAN-GIT-273

**Issue:** #273 — Remove ticket-creation-subagent; route to workflow skill directly
**Branch:** `issue-273`
**Status:** Ready

## Overview

The `ticket-creation-subagent` runs headless (`question: deny`) but its backing `ticket-plan-workflow-skill` is inherently interactive (Steps 1–4 and 9 all prompt the user). This is an architectural mismatch causing pure indirection in interactive sessions: the primary gathers all input upfront, then delegates to a headless runner that cannot execute the skill's interactive steps. Remove the subagent, migrate its 3 unique behaviors into the skill, and add a routing-exception in `deploy/.AGENTS.md` so the primary loads `ticket-plan-workflow-skill` directly on ticket trigger phrases — mirroring the existing `openapi-contract-adherence-skill` exception pattern.

## Acceptance Criteria

- `opencode_app/.opencode/agents/ticket-creation-subagent.md` is deleted
- Atomicity self-check commit-gate migrated into `ticket-plan-workflow-skill/SKILL.md`
- BRD/SRS doc auto-detect migrated into the skill
- `NEEDS_GIT_BRANCH_SETUP` signal emission migrated into the skill
- Skill line 365 wording updated from "enforced by `ticket-creation-subagent`" → "enforced by this skill's Step 6.5 self-check"
- Routing-exception bullet added to `deploy/.AGENTS.md`
- `deploy/agent-tiers.json` line 39 removed
- `deploy/setup.sh` agent listing removed; count decrements
- `deploy/setup.ps1` Windows parity listing removed
- `README.md` subagent row + trigger row removed
- Repo root `AGENTS.md` fast-tier example updated
- Subagent count 39 → 38 consistent across all files
- `grep -rn "ticket-creation-subagent" .` returns zero hits
- No `opencode.json` permission change needed
- No test changes needed

## Scope

- `opencode_app/.opencode/agents/ticket-creation-subagent.md` (DELETE)
- `opencode_app/.opencode/skills/ticket-plan-workflow-skill/SKILL.md` (MIGRATE 3 behaviors + fix line 365)
- `deploy/.AGENTS.md` (ADD routing exception)
- `deploy/agent-tiers.json` (REMOVE entry)
- `deploy/setup.sh` (REMOVE listing + decrement count)
- `deploy/setup.ps1` (REMOVE listing)
- `README.md` (REMOVE rows)
- `AGENTS.md` (REMOVE from fast-tier list)

---
*Tracking progress with ticket-plan-workflow-skill*

---

## Dependency & Consumer Map

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---------------------|---------------------------|---------------------------------|-------------|
| `ticket-plan-workflow-skill/SKILL.md` | — | Primary agent (direct skill load), all ticket/issue creation flows | med — skill is always loaded for ticket work |
| `deploy/.AGENTS.md` | — | Primary agent (loaded into every session) | low — additive bullet |
| `ticket-creation-subagent.md` | — | Nothing after removal | low — deletion |
| `deploy/agent-tiers.json` | — | `deploy/setup.sh`, `deploy/setup.ps1` (read at deploy time) | low — entry removal |
| `deploy/setup.sh` | `agent-tiers.json` (count) | Users running `./deploy/setup.sh` | med — count math must match |
| `deploy/setup.ps1` | `agent-tiers.json` (count) | Windows users running setup | med — count math must match |
| `README.md` | — | Repository consumers, onboarding | low — table row removal |
| `AGENTS.md` | — | Primary agent (loaded into every session) | low — list item removal |

## Implementation Phases

### Phase 1: Migrate behaviors into ticket-plan-workflow-skill

- [ ] **1.1** Add Step 6.5 "Atomicity Self-Check" between PLAN generation (Step 6) and commit (Step 7): reads PLAN back, verifies every `- [ ] **N.M**` step carries `— Why:`, `— Done when:`, `— Consumers affected:`; refuses `git commit` if any malformed step is found, surfacing the list to the user for correction.
    — **Why:** This commit-gate currently lives only in the subagent; without it, malformed plans (missing rationale) can be committed. Moving it into the skill ensures every PLAN is validated regardless of invocation path.
    — **Done when:** Step 6.5 is present in SKILL.md with clear instructions for reading the PLAN file, parsing checkbox lines with regex, checking for the three required rationale fields, and blocking commit on failure.
    — **Consumers affected:** Primary agent (when loading skill directly), plan-execution-skill (relies on well-formed plans).

- [ ] **1.2** Add BRD/SRS doc auto-detect logic between Steps 5.5 and 6: scans `docs/brd/BRD-draft-*.md` then `docs/srs/SRS-draft-*.md`, offers to link via `question` tool, renames via `git mv` to `BRD-{ticket-key}.md` / `SRS-{ticket-key}.md`, sets `BRD_PATH`/`SRS_PATH` variables for PLAN header injection.
    — **Why:** The subagent's Step 9 handled BRD/SRS linking; this must be preserved so document-traceability works when the skill is loaded directly by the primary.
    — **Done when:** New Step 5.6 (or integrated into Step 5.5) contains the full scan-prompt-rename-inject flow with both BRD and SRS sub-steps, matching the subagent's existing behavior.
    — **Consumers affected:** Primary agent (interactive sessions), brd-creation-skill, srs-creation-skill (linked documents).

- [ ] **1.3** Add `NEEDS_GIT_BRANCH_SETUP` signal emission after Step 7 (commit/push): runs `git-branch-workflow-setup-skill` detection logic (checks for existing release tooling + `.opencode/branch-workflow-skipped` marker), emits `NEEDS_GIT_BRANCH_SETUP: true` in the return contract if signals absent.
    — **Why:** The subagent's Step 14 emitted this signal for the primary to offer branch-workflow setup; without it, new projects would miss the setup prompt entirely.
    — **Done when:** Post-push step includes the detection checks and return-contract signal emission, matching the subagent's existing logic verbatim.
    — **Consumers affected:** Primary agent (reads return contract), git-branch-workflow-setup-skill (triggered by primary on signal).

- [ ] **1.4** Update line 365 wording from "enforced by `ticket-creation-subagent`" to "enforced by this skill's Step 6.5 self-check".
    — **Why:** The old reference points to a deleted agent; leaving it creates a dangling reference that would confuse future readers and break documentation consistency.
    — **Done when:** `grep -n 'ticket-creation-subagent' opencode_app/.opencode/skills/ticket-plan-workflow-skill/SKILL.md` returns zero hits.
    — **Consumers affected:** documentation-consistency-skill (audits cross-references).

### Phase 2: Delete ticket-creation-subagent

- [ ] **2.1** Delete `opencode_app/.opencode/agents/ticket-creation-subagent.md`.
    — **Why:** The agent is being removed entirely; its behaviors are now in the skill. Leaving the file would cause a ghost agent entry.
    — **Done when:** File does not exist on disk and `git status` shows the deletion as staged.
    — **Consumers affected:** No runtime consumers (agent is gone), documentation-sync-workflow-skill (count tracking).

### Phase 3: Add routing exception

- [ ] **3.1** Add routing-exception bullet to `deploy/.AGENTS.md` under "Non-obvious routing exceptions" after the openapi entry (line 14): `Ticket / issue creation (GitHub or JIRA): **no subagent** — load ticket-plan-workflow-skill directly when trigger phrases appear.`
    — **Why:** Without this exception, the primary agent would continue to delegate to a now-deleted subagent on ticket trigger phrases, causing failures.
    — **Done when:** The new bullet is present in `deploy/.AGENTS.md` and matches the openapi exception pattern (bold no-subagent directive + trigger phrase list).
    — **Consumers affected:** Primary agent (routing decisions), all future ticket/issue creation flows.

### Phase 4: Sync subagent count and listings

- [ ] **4.1** Remove `"ticket-creation-subagent": "fast"` entry from `deploy/agent-tiers.json` (line 39).
    — **Why:** The tier registry must not reference a deleted agent. Leaving it would cause setup scripts to reference a non-existent agent.
    — **Done when:** `grep 'ticket-creation-subagent' deploy/agent-tiers.json` returns zero hits.
    — **Consumers affected:** deploy/setup.sh, deploy/setup.ps1 (read this file at deploy time).

- [ ] **4.2** Remove `ticket-creation-subagent` listing line from `deploy/setup.sh` (line 631) and decrement the agent count variable by 1 (39 → 38).
    — **Why:** Setup script must list only existing agents and display the correct count in its banner/status output.
    — **Done when:** Agent listing block no longer contains `ticket-creation-subagent` and the count variable equals 38.
    — **Consumers affected:** Users running `./deploy/setup.sh` (banner accuracy).

- [ ] **4.3** Remove `ticket-creation-subagent` listing line from `deploy/setup.ps1` (line 909) — Windows parity.
    — **Why:** Windows setup script must mirror the Unix script's agent list for cross-platform consistency.
    — **Done when:** `grep 'ticket-creation-subagent' deploy/setup.ps1` returns zero hits.
    — **Consumers affected:** Windows users running `setup.ps1`.

- [ ] **4.4** Remove `ticket-creation-subagent` row from `README.md` Subagents table (line 459) and trigger-phrases row (line 514).
    — **Why:** README must reflect the current set of subagents; stale entries mislead repository consumers.
    — **Done when:** `grep 'ticket-creation-subagent' README.md` returns zero hits and table formatting is intact.
    — **Consumers affected:** Repository consumers, onboarding documentation.

- [ ] **4.5** Remove `ticket-creation` from fast-tier examples in repo root `AGENTS.md` (line 38).
    — **Why:** The fast-tier example list references the subagent by short name; leaving it creates a dangling reference in per-session agent instructions.
    — **Done when:** `grep 'ticket-creation' AGENTS.md` returns zero hits (or only matches unrelated context like `ticket-plan-workflow-skill`).
    — **Consumers affected:** Primary agent (loaded into every session).

- [ ] **4.6** Run final verification: `grep -rn 'ticket-creation-subagent' .` returns zero hits.
    — **Why:** This is the ultimate consistency check — if any file still references the deleted agent, something was missed in the sync steps above.
    — **Done when:** Command returns exit code 1 (no matches) with zero output lines.
    — **Consumers affected:** None (verification gate).

## Technical Notes

- Atomic commits recommended: (1) `refactor(ticket-skill): migrate atomicity gate, BRD/SRS auto-detect, branch signal into workflow skill`, (2) `chore(agents): remove ticket-creation-subagent`, (3) `docs(routing): add ticket-creation routing exception for primary skill invocation`, (4) `docs: sync subagent count (39→38) and listings across deploy scripts + README`.
- `opencode.json` skill permission for `ticket-plan-workflow-skill` is already `allow`-ed — no change needed.
- No tests reference the agent name or count — no test changes needed.
- Built-in agents `explore`→`fast` and `general`→`reasoning` are patched in `opencode.json`, not the tier registry — leave them alone.

## Dependencies

- None (self-contained refactor within this repository)

## Risks & Mitigation

| Risk | Impact | Mitigation |
|------|--------|------------|
| Missing a file that references the deleted agent | Stale references, broken setup | Final `grep -rn` verification (Step 4.6) |
| Skill migration breaks interactive flows | Ticket creation fails for users | Test the skill load path manually after changes |
| Count math error in setup scripts | Banner shows wrong number | Verify count = 38 across setup.sh and setup.ps1 |

## Success Metrics

- `grep -rn 'ticket-creation-subagent' .` returns zero hits
- `ticket-plan-workflow-skill` loads directly on trigger phrases without subagent delegation
- All 3 migrated behaviors (atomicity gate, BRD/SRS auto-detect, branch signal) function correctly
- Subagent count is 38 consistently across all listing files
