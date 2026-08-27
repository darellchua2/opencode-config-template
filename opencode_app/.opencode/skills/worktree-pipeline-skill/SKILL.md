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
(`ticket-plan-workflow-skill`, `plan-automation-loop-skill`,
`pr-workflow-subagent`) — I own sequencing, worktree lifecycle, and
re-validation.

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
   `ticket-plan-workflow-skill`). New work → create the ticket first (same
   guard; GitHub issue or JIRA per ref format — tracker-agnostic).
4. **Worktree**: locate the **main** checkout via
   `git worktree list --porcelain | sed -n 's/^worktree //p' | head -1`
   (NOT `$(git rev-parse --show-toplevel)` — that nests when invoked from a
   worktree). Create `git worktree add <main-repo>/../worktrees/<KEY> feat/<KEY>`
   — **always, even when the ticket is in this repo**. Worktrees-root is
   user-overridable. Pre-flight `git worktree list` for stale `<KEY>` entries.
5. **Re-validate**: cross-check the ticket description once more against the
   latest `origin/<base>` content **in the worktree**; if stale, update the
   ticket and note deltas before proceeding.
6. **PLAN** — drive `ticket-plan-workflow-skill` with this entry contract:
   - That skill has **no branch-creation step and never sets
     `$BRANCH_NAME`** — it only *uses* it (its Step 7 pushes
     `git push -u origin "$BRANCH_NAME"`). We cut `feat/<KEY>` in Step 2
     above and export `BRANCH_NAME=feat/<KEY>` before entering.
   - Enter at **Step 5.5** (adopt/rename existing PLAN).
   - Run 5.5 → 5.6 (BRD/SRS draft linking) → 6 (generate) → 6.5 (atomicity
     gate). Note: 5.5 searches `PLANS/` relative to the worktree cwd — drafts
     must be **committed to `<base>`** to be adoptable here; uncommitted
     main-worktree drafts are invisible by design.
   - Then run its **Step 7 yourself**: commit + push the PLAN on
     `feat/<KEY>`. /run-plan commits implementation phases, not the PLAN —
     an untracked PLAN file would be lost on worktree removal.
   - Skip its Step 8 (initial ticket progress comment — execution follows
     immediately here; ticket updates flow through Step 5 re-validation and
     pr-workflow), its Step 7.5 branch-workflow setup signal, and its Step 9
     interactive prompt.
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

## Guarantees

- Sequential execution across tickets; one worktree live per ticket.
- Every ticket re-validated against latest `origin/<base>` before execution.
- The main working tree is never checked out on a feat branch.
- Delegation is hub-and-spoke from the primary session (build agent allows
  `task: {"*": allow}`); bash-denied delegates receive precomputed diffs.

## Return Contract

**Status:** success | partial | failed
**Output:** per ticket — PR URL + merge SHA; one line each
**Summary:** 2-3 sentences max
**Issues:** blockers, skipped (`blocked-by:`) tickets, or "None"
