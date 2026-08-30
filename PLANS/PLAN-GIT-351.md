# PLAN-GIT-351 — `/run-worktree-pipeline` command + `worktree-pipeline-skill`

**Issue:** #351 · **Branch:** `feat/GIT-351` (from `origin/main` @ bb1650e) · **Worktree:** `/home/silentx/VSCODE/worktrees/GIT-351`
**Labels:** skills, feature, size: M · **Depends:** #350 (merged via #353 — non-blocking, satisfied)

## Re-validation summary (vs issue, @ bb1650e)

| Issue claim | Verified |
|---|---|
| `run-plan` command block pattern at opencode.json:139-143 (description/template `$ARGUMENTS`/`agent: "build"`) | TRUE — mirror it |
| Skill count 133, Git/Workflow category (13) | TRUE (registry: 133 skills / 32 agents; README:568) |
| Sync needed in `deploy/setup.sh` + `deploy/setup.ps1` | **FALSE (stale)** — both derive counts/categories dynamically (`count_skills()`, `print_skill_categories()` setup.sh:414,427,719-721; ps1 :185-211). `test_count_drift.bats` bans hardcoded literals. → No setup-script edits required; deviation documented here |
| Lean profile (`deploy/skill-profiles.json`) = 36 keys; `tests/skill_profiles.bats` pins **36** in 5 occurrences (:5 stale "30" comment, :7 comment, :25/:27 test, :46/:60 assertion `"36 deny-ok"`) | TRUE — issue omits the bats literals; adding to lean requires 36→37 in all, plus fixing the stale :5 comment |
| `ticket-plan-workflow-skill` Steps 5.5/5.6/6/6.5 exist | TRUE (:265, :313, :426) |
| Issue body steps 1/4/9 say `origin/dev` / "PR target dev" | **STALE** — contradicts issue's own Usage line (`origin/HEAD` default) + user directives: base-branch arg sets pull-from AND PR target; default = repo default branch (`origin/HEAD` = `main` here). Implement per AC/user directives |

## Files touched (7)

1. `opencode_app/opencode.json` — command block + `permission.skill` allow
2. `opencode_app/.opencode/skills/worktree-pipeline-skill/SKILL.md` — new
3. `deploy/skill-profiles.json` — lean += worktree-pipeline-skill (36→37)
4. `tests/skill_profiles.bats` — 36→37 (5 occurrences incl. stale :5 "30" comment)
5. `README.md` + `opencode_app/README.md` — count literals 133→134, lean 36→37, allows 93→94, Git/Workflow (13)→(14) row, `/run-worktree-pipeline` mention
6. `deploy/registry.json` — regen (commit with sources)
7. `PLANS/PLAN-GIT-351.md` — this file

## Phase 1 — Config + skill

### 1.1 Command block (opencode.json)
Insert after `run-plan` (:139-143), mirroring its shape:
```json
"run-worktree-pipeline": {
    "description": "Tracker-ticket-to-merged-PR pipeline via git worktrees — sync, plan, 3-subagent review, /run-plan, code review, PR merge. Usage: /run-worktree-pipeline [base-branch] <ticket-refs...>",
    "template": "Load the skill `worktree-pipeline-skill` and run it with the arguments: $ARGUMENTS",
    "agent": "build"
}
```
**Why:** command wiring identical to `/run-plan`; `build` agent already allows `task: {"*": allow}` (opencode.json:273-279) so the subagent chain works (chain depth primary→pr-workflow→documentation = 2 ≤ `subagent_depth: 3`).
**Done when:** block parses (python3 json.load) and mirrors run-plan keys exactly (description/template/agent).
**Consumers:** opencode command picker; primary session.
*(Authored before 1.2 but depends on it — both land in the same commit 3.2#1, so the map stays satisfiable.)*

### 1.2 Skill file (new SKILL.md)
Frontmatter per contract: `name: worktree-pipeline-skill` (= dir), `description` ≤50 words with triggers (`run-worktree-pipeline, worktree pipeline, ticket to PR pipeline, tracker ticket pipeline`), `license: Apache-2.0`, `compatibility: opencode`, `category: Git/Workflow`. No `permission.skill` key in frontmatter.

**Arg grammar (step 1 of the skill):** first token is a base-branch **iff** it fails the ticket regex `^(#\d+|[\w.-]+/[\w.-]+#\d+|[A-Z][A-Z0-9]+-\d+)$`; bare numerics (e.g. `351`) auto-normalize to `#351`; zero ticket refs → print usage and stop. Tickets execute in **argument order** (order = execution order; additionally skip-and-report any ticket whose body carries `blocked-by: <ref>` naming a later/failed ticket — no JIRA link traversal in v1).

Body implements steps 1-10 (sequential; NO parallel worktree spawning):
1. **Parse args** per grammar above. Base-branch sets BOTH pull-from and PR target; default = repo default branch (`git symbolic-ref refs/remotes/origin/HEAD` → short name; fallback `main`).
2. **Sync + branch**: `git fetch origin <base>`; per ticket `git branch feat/<KEY> origin/<base>` (fresh cut; if the branch or worktree already exists, report state and ask: prune / resume / refuse — never clobber silently).
3. **Ticket fetch/create**: existing ref → fetch description (`gh issue view` / JIRA via atlassian MCP **Availability Guard**: tools present → use; absent → REST fallback via token; headless → degrade with clear report — same policy as `ticket-plan-workflow-skill`). New work → create ticket first (same guard).
4. **Worktree**: locate the **main** checkout via `git worktree list --porcelain | sed -n 's/^worktree //p' | head -1` and use `<main-repo>/../worktrees/<KEY>` as root (NOT `$(git rev-parse --show-toplevel)/..`, which nests when invoked from a worktree); worktrees-root overridable by user. `git worktree add <root>/<KEY> feat/<KEY>` — ALWAYS, even same-repo. Pre-flight: `git worktree list` for stale `<KEY>` entries (mid-pipeline failure leaves them behind) → offer prune/resume/refuse.
5. **Re-validate**: cross-check ticket description against latest `origin/<base>` content in the worktree; if stale, update ticket + note deltas before proceeding.
6. **PLAN** (drives `ticket-plan-workflow-skill` from the worktree — entry contract): enter at **Step 5.5** with `BRANCH_NAME=feat/<KEY>` (the skill assumes branch=`<KEY>` and Step 5 defines the var — skipped here); run 5.5 adopt-draft (NOTE: it searches `PLANS/` relative to the worktree cwd, so drafts must be **committed to `<base>`** to be adoptable in pipeline mode — uncommitted main-worktree drafts are invisible, by design) → 5.6 BRD-SRS → 6 generate → 6.5 atomicity gate → **Step 7 commit+push PLAN on `feat/<KEY>` (owned by this skill — /run-plan commits implementation phases, not the PLAN; untracked PLAN files would be lost on worktree removal)**; skip Step 5, the Step 7.5 release-tooling signal, and the Step 9 interactive prompt.
7. **Plan review**: Task-delegate the PLAN file to `requirements-specialist-subagent` + `coverage-subagent` + `architecture-review-subagent` (all have `bash: allow`); apply findings to the PLAN; re-review only if findings were structural.
8. **Execute**: `/run-plan` (`plan-automation-loop-skill`) inside the worktree (per-phase lint+build+test gate, commit+push).
9. **Code review**: `code-review-subagent` has `bash: deny` — the **primary computes the diff** (`git diff origin/<base>...feat/<KEY>` + `--stat`) and embeds it (or file list + hunks) in the Task prompt; fix findings (severity ≥ Major mandatory; Minor judgment).
10. **PR + cleanup**: `pr-workflow-subagent` PR target `<base>` (includes docstring sweep step 2.5, PLAN.md sync, JIRA/GH linkage), merge when CI green; then `git worktree remove` + delete remote branch + `git fetch` in the main checkout (fetch-only — never `pull` in the user's main worktree; uncommitted state may conflict).

**Why:** this is the whole feature — the encoded pipeline the user runs daily.
**Done when:** SKILL.md exists with valid frontmatter (name=dir, description ≤50 words — verify with `awk '/^description:/{f=1;next}/^[a-z]+:/{f=0}f' | wc -w`, Apache-2.0, compatibility, category); steps 1-10 present; arg grammar + `origin/HEAD` default explicit; re-validation step explicit; MCP guard present; ticket-plan entry contract (5.5 entry, BRANCH_NAME, PLAN commit ownership, skips) explicit; sequential execution stated.
**Consumers:** `/run-worktree-pipeline` command template; registry build; lean profile.
*(Deviation note: `--reuse`/prune-resume-refuse valve in step 2 is a micro-extension beyond issue text, documented here for audit.)*

### 1.3 Permission gate (opencode.json `permission.skill`)
Insert `"worktree-pipeline-skill": "allow"` in the git-/plan- cluster (after `version-bump-standard-skill`).
**Why:** Skill Allowlist rule — new skills default hidden; primary visibility requires opencode.json allow.
**Done when:** key present, JSON parses; counting convention stated: **allow keys 92→93, block 93→94 total incl. `"*": "deny"`**.
**Consumers:** primary session skill loading; lean⊆shipped bats test.

### 1.4 Lean profile (deploy/skill-profiles.json + tests/skill_profiles.bats)
Add `worktree-pipeline-skill` to `lean` (peer of `plan-automation-loop-skill`, same visibility class). Bump **all five** 36-literals to 37 in `tests/skill_profiles.bats`: stale header comment :5 ("lean count == 30" → 37), comment :7, test name+assert :25/:27, apply-profile test :46 and :60 `"36 deny-ok"`→`"37 deny-ok"`.
**Why:** lean is the deploy default; a pipeline command invisible in default deploys is dead on arrival. Tests pin the count, so they move with it.
**Done when:** lean length 37, every key matches a disk dir, `apply-skill-profile.mjs` lean run outputs 37 allows, bats suite green, `rg -c '36 primary-visible' README.md` returns nothing (see 2.1).
**Consumers:** `setup.sh --skill-profile lean`; skill_profiles.bats.

## Phase 2 — Docs + registry

### 2.1 README.md + opencode_app/README.md (count literals — ALL surfaces)
- README.md:27 "133 skill director**ies**" → 134 (singular form — plural-only regex misses it)
- opencode_app/README.md:26 same → 134
- README.md:243 "32 agents + 133 skills" → 134
- README.md:388 "(93 allows)" — **verified during execution**: pre-change block had 92 allow keys (text was off-by-one); post-insert it has exactly 93 → the existing text is NOW CORRECT, no edit made (deviation from review finding; truth over bump)
- README.md:388 + :391 "only **36** primary-visible skills" / "lean (**36** …)" → 37
- README.md:400 "All 133 skills" → 134
- README.md:551 "133 skills organized across 22 categories" → 134
- README.md:555 history blockquote append: `Post-GIT-351: +1 worktree-pipeline-skill (Git/Workflow — /run-worktree-pipeline tracker-to-merged-PR pipeline via git worktrees) → 134.` (the blockquote's earlier "133" stays — historical)
- README.md:568 Git/Workflow row: (13)→(14), add `worktree-pipeline-skill` to listing (after `plan-automation-loop-skill`), extend description: `...via /run-plan` → `...via /run-plan; and the tracker-ticket-to-merged-PR worktree pipeline via /run-worktree-pipeline`
**Why:** AGENTS.md sync table obligation (count + category listing + command mention); this drift class bit the repo twice (GIT-237, GIT-297).
**Done when:** `! rg -n '\b133\b' README.md opencode_app/README.md | grep -v ':555:'` (history blockquote exempt) AND `! rg -n '\b36\b (primary-visible|keys)' README.md` AND Git/Workflow row lists 14 including the new skill AND `/run-worktree-pipeline` appears in README. Each numeric claim re-verified against the actual JSON before commit.
**Consumers:** README readers; documentation-consistency audits.

### 2.2 Registry regen
`node deploy/build-registry.mjs` → expect diff = 1 new skill entry (`worktree-pipeline-skill`, category Git/Workflow, requiredByAgents []) + `generatedAt`; skills count 133→134. Commit atomically with 1.2/1.3 sources.
**Why:** frontmatter contract requires regen on ANY skill add.
**Done when:** `--check` exits 0 "no drift"; diff contains nothing but the new entry + timestamp.
**Consumers:** init.mjs resolver (:173-178 dynamic); build-site.mjs (:44-47,89,97 dynamic); CI gate.

## Phase 3 — Gates + closeout

### 3.1 Gates
- `node deploy/build-registry.mjs --check`
- `python3` json.load on: opencode.json, skill-profiles.json, registry.json
- `export PATH="$PWD/tests/lib/bats-core/bin:$PATH" && bats tests/` (all suites)
- Frontmatter spot-check: description word count ≤50, name=dirname (done-when of 1.2)
**Why:** prove config/doc/test surfaces are consistent before review; CI runs the same gates.
**Done when:** all green, zero failed.
**Consumers:** PR CI (same commands).
*(Runtime smoke of the command itself is deferred to the pipeline's first real ticket run — recorded in Decisions.)*

### 3.2 Commits + push
1. `feat(command): add /run-worktree-pipeline with worktree-pipeline-skill` — opencode.json + SKILL.md + skill-profiles.json + skill_profiles.bats + README.md ×2 + registry.json (atomic: source + generated + docs + tests; Closes #351)
2. `docs(plan): add PLAN-GIT-351` (this file, progress noted in headers)
**Why:** conventional atomic commits; generated artifact travels with its sources.
**Done when:** both commits pushed to `origin/feat/GIT-351`; working tree clean.
**Consumers:** code-review-subagent (reviews the diff); PR CI.

## Dependency & Consumer Map

| Step | Depends on | Consumers |
|---|---|---|
| 1.1 command block | 1.2 skill exists (template references it; same commit) | command picker |
| 1.2 skill | — | 1.1, 1.3, 1.4, 2.2 |
| 1.3 permission allow | 1.2 | primary session, lean⊆shipped test |
| 1.4 lean + bats | 1.2, 1.3 (subset) | setup.sh lean deploy |
| 2.1 READMEs | 1.2, 1.4 (lean count) | docs audits |
| 2.2 registry | 1.2 frontmatter final | init.mjs, CI |
| 3.1 gates | all above | CI parity |
| 3.2 commits | 3.1 green | code review, PR |

## Risks

- **Command-template `$ARGUMENTS` forwarding**: run-plan passes a plan path; here args are ticket refs — template wording "run it with the arguments" keeps the skill (not the command) as arg parser. Mitigated by skill step 1 grammar.
- **Stale issue text**: steps 1/4/9 say `dev` — superseded by AC-4 + user directives (base-branch arg, `origin/HEAD` default). Deviation documented in Re-validation.
- **setup.sh/ps1 untouched** despite issue Scope listing them — dynamic derivation makes edits impossible without violating test_count_drift.bats no-hardcode rules. Documented.
- **Lean count bump touches tests + README prose** the issue didn't list — required by pinned literals and count surfaces; covered in 1.4/2.1.
- **Runtime behavior unverified by static gates** — first real ticket run is the smoke test.

## Decisions

- Skill goes in lean (visibility parity with `/run-plan`'s skill).
- Skill body keeps pipeline knowledge; heavy knowledge stays in referenced skills (ticket-plan-workflow, plan-automation-loop) — hub-and-spoke, no duplication.
- Subagent delegation happens from the primary session running the skill (build agent allows task:*), not skill→skill chaining; bash-deny delegates (code-review) receive precomputed diffs.
- Ticket ordering: argument order = execution order; `blocked-by:` ticket-body field parsed as a skip signal (no JIRA link traversal in v1).
- Runtime smoke deferred to first real ticket run.
