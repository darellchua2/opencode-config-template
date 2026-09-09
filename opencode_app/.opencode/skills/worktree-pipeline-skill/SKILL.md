---
name: worktree-pipeline-skill
description: >-
  Tracker-ticket-to-merged-PR pipeline via git worktrees — sync, plan,
  3-subagent review, /run-plan, code review, PR merge. Triggers:
  run-worktree-pipeline, worktree pipeline, ticket to PR pipeline,
  tracker ticket pipeline.
license: Apache-2.0
compatibility: opencode
metadata:
  pattern: hub-and-spoke
category: Git/Workflow
---

## What I do

I run the **full ticket-to-merged-PR pipeline**, one ticket at a time, each in
its own **git worktree** so the main working tree stays free. I am the
orchestrator: heavy knowledge lives in the skills/subagents I drive
(`ticket-creation-skill` for new tickets, `plan-automation-loop-skill` for
execution, `pr-workflow-subagent` for the PR) — I own sequencing, PLAN
authoring, worktree lifecycle, and re-validation.

Usage: `/run-worktree-pipeline [base-branch] <ticket-refs...>`

## Step 1 — Parse arguments

- First token is a **base-branch** iff it fails the ticket regex
  `^(#\d+|[\w.-]+/[\w.-]+#\d+|[A-Z][A-Z0-9]+-\d+)$` **and is not purely
  numeric**.
- Bare numerics (`351`) auto-normalize to GitHub issue refs (`#351`).
- Zero ticket refs → print usage and stop.
- The base-branch sets **both** where feat branches are cut from AND the PR
  target. Default (omitted): repo default branch via
  `git symbolic-ref --short refs/remotes/origin/HEAD` (yields
  `origin/<base>`; strip the prefix; fallback `main`).
- **Ticket order = execution order** (sequential; never parallel worktrees).
  Before starting a ticket, if its body contains `blocked-by: <ref>` naming a
  ticket that is not yet merged, skip it and report why (no JIRA link
  traversal in v1).

## Steps 2-10 — per ticket (in order)

2. **Sync + branch**: `git fetch origin <base>`; cut
   `git branch feat/<KEY> origin/<base>`. If the branch or worktree already
   exists (mid-pipeline failure leftovers), report state and ask:
   prune / resume / refuse — never clobber silently.
3. **Ticket fetch/create**: existing ref → fetch its description
   (`gh issue view` / JIRA). JIRA access follows the **MCP Availability
   Guard**: `atlassian_*` tools present → use them; absent → REST fallback
   via API token; headless → degrade with a clear report (same policy as
   `ticket-creation-skill` §MCP Availability Guard). New work → create the
   ticket first via `ticket-creation-skill` (`/create-ticket`), then
   continue.
4. **Worktree**: locate the **main** checkout via
   `git worktree list --porcelain | sed -n 's/^worktree //p' | head -1`
   (NOT `$(git rev-parse --show-toplevel)` — that nests when invoked from a
   worktree). Create `git worktree add <main-repo>/../worktrees/<KEY> feat/<KEY>`
   — **always, even when the ticket is in this repo**. Worktrees-root is
   user-overridable. Pre-flight `git worktree list` for stale `<KEY>` entries.
5. **Re-validate**: cross-check the ticket description once more against the
   latest `origin/<base>` content **in the worktree**; if stale, update the
   ticket and note deltas before proceeding.
6. **PLAN authoring** (self-contained — this skill owns it; see §PLAN
   Authoring): adopt/generate the ticket-scoped PLAN in the worktree, run the
   atomicity self-check, commit and push it on `feat/<KEY>`.
7. **Plan review**: Task-delegate the PLAN file to
   `requirements-specialist-subagent` + `coverage-subagent` +
   `architecture-review-subagent`; apply findings to the PLAN; re-review only
   if findings were structural.
8. **Execute**: run `/run-plan` (`plan-automation-loop-skill`) **inside the
   worktree** — per-phase lint+build+test gate, commit + push per phase.
9. **Code review**: `code-review-subagent` has `bash: deny` — **you compute
   the diff** (`git diff origin/<base>...feat/<KEY>` and `--stat`) and embed
   it (file list + hunks) in the Task prompt. Fix findings: severity ≥
   Major mandatory; Minor by judgment.
10. **PR + cleanup**: `pr-workflow-subagent` creates the PR **target
    `<base>`** (its step 2.5 docstring sweep and PLAN.md sync run as part of
    it); merge when CI is green. Then `git worktree remove <root>/<KEY>`,
    delete the remote branch, and `git fetch` in the main checkout
    (**fetch-only** — never `pull` in the user's main worktree; uncommitted
    state may conflict). Advance to the next ticket.

## PLAN Authoring (Step 6 detail)

All commands run **in the worktree** (`worktrees/<KEY>`), on `feat/<KEY>`.
`$TICKET_ID` is the normalized ref (`#123` or `PROJ-123`); `$KEY` is its
alphanumeric form (`123` or `PROJ-123`).

### 6a. Adopt or rename an existing PLAN draft

Before generating from scratch, check whether an existing draft should be
adopted (avoids duplicate plans, preserves git history). Canonical filename:
`PLANS/PLAN-GIT-<issue-number>.md` (GitHub) or `PLANS/PLAN-<TICKET_KEY>.md`
(JIRA).

1. **Search candidates in `PLANS/` only** (never repo root — a root
   `PLAN.md` may belong to unrelated active work):
   `ls PLANS/PLAN.md PLANS/PLAN-DRAFT-*.md PLANS/TODO-*.md 2>/dev/null`
   Also prior-iteration canonical names (`PLANS/PLAN-GIT-*.md` etc.).
2. **Already adopted?** Canonical name exists → skip to 6d.
3. **Single candidate → auto-adopt** via `git mv` (preserves history):
   `git mv "PLANS/PLAN-DRAFT-<slug>.md" "PLANS/PLAN-${KEY}.md"`.
   Before auto-adopting a generic `PLANS/PLAN.md`, verify its `**Issue:**`
   header matches this ticket; mismatch → non-candidate + warn.
4. **Multiple candidates → prompt the user** which to adopt.
5. **Non-adopted candidates → left in place with a warning** (user cleans up).
6. **No candidate / no `PLANS/` dir** → `mkdir -p PLANS`, continue to 6b.

> Note: 6a searches relative to the worktree cwd — drafts must be
> **committed to `<base>`** to be adoptable here; uncommitted main-worktree
> drafts are invisible by design.

### 6b. BRD/SRS draft linking

Document-ladder order: **BRD first, then SRS**. For each:

```bash
ls docs/brd/BRD-draft-*.md 2>/dev/null   # then docs/srs/SRS-draft-*.md
```

If drafts found, ask the user (via `question`) whether to link one:
- Rename: `git mv docs/brd/BRD-draft-{slug}.md docs/brd/BRD-{key}.md`
  (plain `mv` + `git add` if untracked); same for SRS.
- Update the doc header `**PLAN**:` placeholder to `PLANS/PLAN-{key}.md`.
- Record `BRD_PATH` / `SRS_PATH` for header injection in 6c.
- Declined/absent → empty path (skip — backward-compatible).

### 6c. Generate the PLAN

Write `PLANS/PLAN-${KEY}.md` using this template:

```markdown
# PLAN: <title>

**Branch**: feat/<KEY>
**Issue**: <ticket URL>          ← + `**BRD**: <path>` / `**SRS**: <path>` lines when linked
**Base**: <base>

## Acceptance Criteria
- [ ] <checkable criteria from the ticket>

## Dependency & Consumer Map

_Before writing steps, list each touched file/module and who consumes it. Use `codegraph_callers` (code) or `tofu graph` + grep (IaC)._

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---------------------|---------------------------|---------------------------------|-------------|
| `path/to/file`      | —                         | caller-A, module-B              | low/med/high |

## Implementation Phases

_Every step MUST be atomic and carry rationale. Reject any step missing a "Why"._

### Canonical step format
- [ ] **N.M** <single atomic action — verb + target + outcome>
    — **Why:** <what this unblocks / why it must precede others>
    — **Done when:** <objective, checkable completion signal>
    — **Consumers affected:** <who depends on this; none if N/A>

### Phase 1: <name>
- [ ] **1.1** <atomic action> (per canonical format)
…

## Technical Notes
<from ticket>

## Dependencies
<external dependencies / blocked-by tickets>

## Risks & Mitigation
<risks + mitigations>
```

**Step authoring rules** (enforced by 6d):
- **Atomic**: one reversible concern per step; two concerns → split.
- **Rationale mandatory**: every step has **Why**; a step without it is malformed.
- **Completion signal**: objective **Done when**, never subjective "done".
- **Consumers explicit**: blast radius visible to reviewers; "none" if isolated.

### 6d. Atomicity self-check (commit gate)

1. Read the PLAN back from disk.
2. For every `- [ ] **N.M**` / `- [x] **N.M**` step, confirm the three
   rationale lines follow it: `— **Why:**`, `— **Done when:**`,
   `— **Consumers affected:**`.
3. **Any step missing any field → do NOT commit.** Surface malformed steps
   (line number + text), fix, re-check. Gate must pass with zero malformed
   steps.
4. Also verify: Dependency & Consumer Map section exists; phase ordering
   matches the map's constraints.

### 6e. Commit and push the PLAN

```bash
git add "PLANS/PLAN-${KEY}.md" docs/brd/ docs/srs/ 2>/dev/null
git commit -m "docs(plan): add PLAN-${KEY}.md for ${TICKET_ID}"
git push -u origin "feat/${KEY}"
```

`/run-plan` commits implementation phases, not the PLAN — an untracked PLAN
file would be lost on worktree removal, which is why this step pushes it.

> Skipped by design in pipeline context: initial ticket progress comment
> (execution follows immediately; ticket updates flow through Step 5
> re-validation and pr-workflow) and the branch-workflow setup signal
> (pipeline runs assume an established repo; run `/create-ticket` standalone
> if you want that signal).

## Guarantees

- Sequential execution across tickets; one worktree live per ticket.
- Every ticket re-validated against latest `origin/<base>` before execution.
- The main working tree is never checked out on a feat branch.
- Every PLAN passes the atomicity self-check before commit.
- Delegation is hub-and-spoke from the primary session (build agent allows
  `task: {"*": allow}`); bash-denied delegates receive precomputed diffs.

## Return Contract

**Status:** success | partial | failed
**Output:** per ticket — PR URL + merge SHA; one line each
**Summary:** 2-3 sentences max
**Issues:** blockers, skipped (`blocked-by:`) tickets, or "None"
