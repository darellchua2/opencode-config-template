# PLAN: Enhance worktree-pipeline — adaptive review, failure policy, CI gate

**Branch**: feat/366
**Issue**: https://github.com/darellchua2/opencode-config-template/issues/366
**Base**: main

## Acceptance Criteria

- [ ] Base-branch validated via `git ls-remote --exit-code --heads origin <base>` at parse; `--dry-run` flag present (prints order/skips/branches/worktrees, touches nothing)
- [ ] Merged-ticket skip: `gh pr list --state merged --head feat/<KEY>` non-empty → skip with note
- [ ] Worktree root overridable via `WORKTREE_PIPELINE_ROOT` env var (default `<main>/../worktrees/`)
- [ ] §Adaptive Review replaces fixed trio; coverage-subagent removed; triage rules stated; parallel Task calls; re-review only on structural findings
- [ ] Step 8 invokes `/run-plan PLANS/PLAN-${KEY}.md` explicitly with upstream-review note
- [ ] Step 9 review-fix loop bounded at 2 iterations
- [ ] Step 10 CI gate: `gh pr checks <num> --watch` + 30-min timeout; zero-checks fallback; explicit post-merge ticket transition
- [ ] §Failure Policy section: halt triggers (`[goal:blocked]`, review-fix exhaustion, CI red past timeout), keep failed worktree+branch, abort-remaining default, Status: partial
- [ ] plan-automation-loop-skill integration row notes explicit path + upstream review
- [ ] `node deploy/build-registry.mjs` zero drift; `./deploy/setup.sh` redeploy; source↔deployed diff clean

## Dependency & Consumer Map

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---------------------|---------------------------|---------------------------------|-------------|
| `opencode_app/.opencode/skills/worktree-pipeline-skill/SKILL.md` | — | `/run-worktree-pipeline` invocations; step 8→plan-automation-loop-skill; step 9→code-review-subagent; step 10→pr-workflow-subagent | med |
| `opencode_app/.opencode/skills/plan-automation-loop-skill/SKILL.md` | worktree-pipeline-skill step 8 wording | `/run-plan` users; worktree-pipeline step 8 | low |
| `registry.json` (generated) | both SKILL.md frontmatter | installer (`build-registry.mjs`, init.mjs, setup.sh counts) | low |

Phase ordering follows the map: pipeline-skill edits first (phases 1-3), then the one-line cross-reference (phase 4), then generated-registry + deploy verification last (phase 5).

## Implementation Phases

### Phase 1: Parse-time guards (worktree-pipeline-skill Steps 1-4)

- [ ] **1.1** Add base-branch validation to Step 1: after resolving base (explicit token or default), run `git ls-remote --exit-code --heads origin <base>`; non-zero exit → abort with clear error listing attempted base
    — **Why:** a typo'd base currently surfaces as a cryptic branch-cut failure at Step 2 instead of a parse-time error
    — **Done when:** Step 1 text contains the ls-remote validation command and the abort instruction
    — **Consumers affected:** all `/run-worktree-pipeline` invocations (new fail-fast path)
- [ ] **1.2** Add `--dry-run` flag to Step 1 usage line and parsing: when set, print resolved base, ticket order, per-ticket skip predictions (merged/blocked-by), and would-be branch/worktree names, then stop before Step 2
    — **Why:** lets users preview a batch run without side effects (branches, worktrees, remote calls beyond reads)
    — **Done when:** usage string documents `--dry-run` and Step 1 states it exits after printing
    — **Consumers affected:** none (purely additive flag)
- [ ] **1.3** Add merged-ticket skip to Step 2: before branch cut, `gh pr list --state merged --head feat/<KEY>` non-empty → report skip and advance to next ticket
    — **Why:** re-running a batch after partial merge currently fails at branch creation (branch/PR already merged)
    — **Done when:** Step 2 contains the gh pr list check and the skip-with-note behavior
    — **Consumers affected:** batch reruns (idempotency)
- [ ] **1.4** Name the worktree-root override in Step 4: `WORKTREE_PIPELINE_ROOT` env var replaces the worktree root; default stays `<main>/../worktrees/`
    — **Why:** Step 4 says "user-overridable" without naming a mechanism — an env var is the zero-code override
    — **Done when:** Step 4 text names `WORKTREE_PIPELINE_ROOT` and its default
    — **Consumers affected:** users with non-default worktree locations

### Phase 2: Review redesign (worktree-pipeline-skill Steps 7-9)

- [ ] **2.1** Rewrite Step 7 as §Adaptive Review: primary agent triages from ticket + Dependency & Consumer Map + touched paths, then parallel Task calls for selected reviewers only — requirements-specialist iff PLAN freshly generated (not adopted draft); architecture-review-subagent iff Consumer Map has cross-module nodes; uiux-reviewer-subagent iff frontend signal (tsx/jsx/vue/svelte/css files, components/pages/app paths, UI keywords). Remove coverage-subagent (duplicate of /run-plan's own coverage gate). Re-review only when findings were structural; zero selected reviewers → skip delegation
    — **Why:** fixed trio wastes tokens on isolated backend tickets with adopted drafts and duplicates coverage spend; triage is zero-delegation
    — **Done when:** Step 7 contains the three iff-conditions, the coverage removal rationale, parallel-call instruction, and structural-only re-review rule
    — **Consumers affected:** reviewer subagents (fewer invocations); /run-plan downstream (coverage no longer double-run)
- [ ] **2.2** Amend Step 8: invoke `/run-plan PLANS/PLAN-${KEY}.md` with explicit path (never bare); add one-line note that plan review happened upstream in Step 7 and the executor must not re-review
    — **Why:** bare invocation relies on branch-name auto-detect that expects GIT-123-style branches → mid-pipeline STOP-and-ask on feat/366-style names; explicit re-review double-spends
    — **Done when:** Step 8 shows the explicit-path invocation and the no-re-review note
    — **Consumers affected:** plan-automation-loop-skill (receives explicit path; contract noted in 4.1)
- [ ] **2.3** Amend Step 9: bound the review-fix loop at 2 iterations; exhaustion → halt per §Failure Policy
    — **Why:** unbounded fix loops can churn tokens without converging
    — **Done when:** Step 9 states "max 2 iterations" and names §Failure Policy as the halt path
    — **Consumers affected:** code-review-subagent loop; §Failure Policy (3.2)

### Phase 3: Merge gate + failure policy (worktree-pipeline-skill Step 10 + new section)

- [ ] **3.1** Amend Step 10 with a concrete CI gate and post-merge ticket transition: `gh pr checks <num> --watch` with 30-minute timeout; zero configured checks → merge directly with a "no CI configured" note; after merge, close/transition the ticket (GitHub: closing keyword in PR body; JIRA: jira-status-updater)
    — **Why:** "merge when CI is green" names no mechanism, timeout, or no-CI fallback; post-merge transition was implicit
    — **Done when:** Step 10 contains the gh pr checks command, 30-min timeout, zero-checks fallback, and explicit transition instructions
    — **Consumers affected:** pr-workflow-subagent invocation; ticket state after pipeline runs
- [ ] **3.2** Add §Failure Policy section (before §Guarantees): halt triggers — executor `[goal:blocked]` terminal marker, review-fix exhaustion (2.3), CI red past timeout (3.1), PR creation failure; on halt keep the failed ticket's worktree + feat branch for inspection; default = abort remaining tickets with per-ticket report; pipeline Return Contract resolves to Status: partial
    — **Why:** the skill previously had no continue-vs-abort policy — halt behavior was improvised per run
    — **Done when:** §Failure Policy section exists with all four triggers, keep-worktree rule, abort-remaining default, and partial-status mapping
    — **Consumers affected:** multi-ticket batch runs; Return Contract readers

### Phase 4: Cross-reference (plan-automation-loop-skill)

- [ ] **4.1** Amend the integration-table row for worktree-pipeline-skill (line ~509) to note: pipeline passes the explicit PLAN path (`PLANS/PLAN-${KEY}.md`) and plan review happens upstream — /run-plan never re-reviews
    — **Why:** keeps the bidirectional contract explicit on both sides of the boundary
    — **Done when:** the row mentions explicit path + upstream review
    — **Consumers affected:** /run-plan users reading the integration table

### Phase 5: Registry + deploy verification

- [ ] **5.1** Run `node deploy/build-registry.mjs`; confirm `registry.json` has zero drift (skill names/descriptions unchanged → expect no diff)
    — **Why:** repo contract requires registry rebuild + commit after any frontmatter change; zero-drift proof closes that obligation
    — **Done when:** command exits 0 and `git status` shows no registry.json diff
    — **Consumers affected:** installer registry consumers
- [ ] **5.2** Redeploy via `./deploy/setup.sh` and diff `opencode_app/.opencode/skills/` against `~/.config/opencode/skills/` — must be clean
    — **Why:** deployed copies must track source of truth; hand-edits are forbidden
    — **Done when:** setup.sh exits 0 and diff is empty for the two touched skills
    — **Consumers affected:** all sessions using the deployed skills

## Technical Notes

- Frontmatter/descriptions of both skills are unchanged → no README counts, no doc-sync workflow, no banner updates (sync rules trigger only on add/remove).
- Adaptive review is pipeline-only; standalone `/run-plan` keeps gates-only behavior (no plan review) — the boundary is deliberate.
- ci gate timeout: use `timeout 1800 gh pr checks <num> --watch` or equivalent so the pipeline cannot hang forever.
- YAGNI-deferred (do not implement): parallel worktrees, session lockfiles, JIRA link traversal, merge-strategy param, persistent state file.

## Dependencies

None. Single-ticket batch; no `blocked-by:` refs.

## Risks & Mitigation

- **Risk:** §Adaptive Review wording could be read as making uiux/architecture mandatory → Mitigation: keep strict iff-conditions and the zero-reviewer skip case explicit.
- **Risk:** CI gate changes pr-workflow-subagent expectations → Mitigation: gate lives in pipeline Step 10 (orchestration), not inside the subagent's own steps.
- **Risk:** doc drift between source and deployed copies → Mitigation: 5.2 diff gate.
