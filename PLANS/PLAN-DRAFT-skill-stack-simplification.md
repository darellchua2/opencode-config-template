# PLAN: Wayfinder vendor + reviewer simplification + ticket/plan decoupling

**Branch**: feat/skill-stack-simplification
**Source**: User-approved plan from session (m0012) — three decisions locked: full reviewer simplification, rename to ticket-creation-skill, vendor+adapt wayfinder now.

## Dependency & Consumer Map

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---------------------|---------------------------|---------------------------------|-------------|
| `skills/wayfinder-skill/` (new) | none | primary sessions (planning); upstream of ticket-creation | low |
| `agents/language-reviewer-subagent.md` | `skills/language-review-checklists-skill/` (new) exists first | code-review-subagent (delegates to it), worktree-pipeline Step 9 | med |
| `agents/*-review*` (4 files) | `skills/reviewer-baseline-skill/` (new) exists first | worktree-pipeline Steps 7/9, primary review flows | med |
| `skills/ticket-creation-skill/` (renamed from ticket-plan-workflow-skill) | none | opencode.json permission+command, 18 referencing files, worktree-pipeline Step 3 | high |
| `skills/worktree-pipeline-skill/SKILL.md` | ticket-creation-skill rename lands first (Step 3 references it) | /run-worktree-pipeline command | high |
| `opencode.json` | skill renames/additions final | every session (permissions, commands) | high |
| `deploy/skill-profiles.json`, `presets/pack-devops.json` | renames final | setup.sh --skill-profile, opencode-init presets | med |
| `registry.json` | all skill/agent file changes final | npx installer CLI | med |
| `README.md` counts/tables | all skill/agent changes final | humans, count-drift guards | med |

## Acceptance Criteria

- [x] `wayfinder-skill` exists, frontmatter-conformant (name=dir, description ≤50 words w/ triggers, license MIT, compatibility opencode, category Git/Workflow), adapted to opencode (no Claude-only keys, deps mapped to existing skills, house tracker guard)
- [x] `language-reviewer-subagent.md` ≤ ~120 lines, checklists live in `language-review-checklists-skill`
- [x] All 4 reviewer agents reference `reviewer-baseline-skill` instead of inline Prompt Defense/Epistemic blocks; zero duplicated baseline blocks remain in reviewer agents
- [x] `ticket-creation-skill` exists (dir+name match), contains ticket creation only (no branch/PLAN/commit/execute steps), ≤ ~320 lines
- [x] `worktree-pipeline-skill` self-contained PLAN authoring (adopt 5.5, BRD/SRS 5.6, template 6, atomicity 6.5, commit/push), no reference to ticket-plan-workflow-skill internals
- [x] `opencode.json` has `create-ticket` command; permission keys updated; valid JSON, no `//` comments
- [x] `grep -r "ticket-plan-workflow" opencode_app/ deploy/ README.md` returns 0 hits (exempt: `_archived/`, the intentional "Renamed from" note, README pending Phase 4)
- [x] `node deploy/build-registry.mjs` exits 0; registry diff shows +3 skills, rename reflected
- [x] Count parity: skills on disk == count_skills() == README count; agents == count_agents()
- [x] Per-phase commits pushed, PLAN ticked with Done lines

## Implementation Phases

### Phase 1: Vendor + adapt wayfinder skill
- [x] **1.1** Create `opencode_app/.opencode/skills/wayfinder-skill/SKILL.md`
    — **Why:** user decision — vendor wayfinder now, adapted to opencode
    — **Done when:** file exists, frontmatter contract met, deps mapped (grilling-skill, domain-modeling-skill, autoresearch-research-subagent, wireframer-skill), tracker section uses house MCP Availability Guard
    — **Consumers affected:** primary planning sessions
    — **Done:** adapted upstream SKILL.md (MIT credit inline): fog-of-war/index-map/claim-by-assignment/refer-by-name/out-of-scope + both invocation modes retained; deps mapped to local skills; tracker routing = gh default, JIRA guard ref, local-markdown fallback; files: opencode_app/.opencode/skills/wayfinder-skill/SKILL.md; fixes: none
- [x] **1.2** Add `wayfinder-skill: allow` to `opencode.json` permission.skill
    — **Why:** skill allowlist is deny-by-default; new skill invisible without allow
    — **Done when:** key present, JSON parses
    — **Consumers affected:** all sessions
    — **Done:** added allow key; also pre-swapped ticket-plan-workflow-skill→ticket-creation-skill permission key (file: opencode_app/opencode.json); fixes: none

### Phase 2: Reviewer simplification — DONE (verdict: VERIFIED)
- [x] **2.1** Extract language checklists → `opencode_app/.opencode/skills/language-review-checklists-skill/SKILL.md`
    — **Why:** 430 lines of knowledge in an agent file; house pattern = knowledge in skills, agents orchestrate
    — **Done when:** skill exists with Python/TS/Go/Rust/Java checklists + grep patterns; frontmatter conformant
    — **Consumers affected:** language-reviewer-subagent, code-review-subagent
    — **Done:** 5 checklists + 5 framework tables + per-language consumer-coverage grep patterns moved verbatim; files: skills/language-review-checklists-skill/SKILL.md; fixes: none
- [x] **2.2** Create `reviewer-baseline-skill` (Prompt Defense + Epistemic Honesty + learning-gate boilerplate)
    — **Why:** ~40-line identical blocks duplicated across 4 reviewers; single source removes drift
    — **Done when:** skill exists, frontmatter conformant
    — **Consumers affected:** all 4 reviewer agents
    — **Done:** canonical 3-section baseline (defense, epistemic, 5-step learning gate) + web-lookups policy; files: skills/reviewer-baseline-skill/SKILL.md; fixes: none
- [x] **2.3** Rewrite `language-reviewer-subagent.md` as thin orchestrator (~≤120 lines)
    — **Why:** 509-line agent overflows context and duplicates skill knowledge
    — **Done when:** detection table + severity rubric + consumer gate + delegation to the two new skills; no inline checklists
    — **Consumers affected:** code-review-subagent, worktree-pipeline Step 9
    — **Done:** 509→119 lines; orchestrator = detection table, severity rubric, caller gate (points at skill grep patterns), output format; fixes: removed accidentally-added `name:` frontmatter key (not in agent contract)
- [x] **2.4** Slim code-review/architecture-review/uiux-reviewer agents: replace inline baselines with one-line load of `reviewer-baseline-skill`, allow it in frontmatter permission.skill
    — **Why:** dedupe shared boilerplate
    — **Done when:** zero duplicated Prompt Defense/Epistemic blocks in reviewer agents; permission.skill updated
    — **Consumers affected:** worktree-pipeline Steps 7/9, primary review flows
    — **Done:** code-review 321→256, architecture 241→212, uiux 274→210 (total 1345→797); baseline-load sections added; permission.skill allows added (code-review also gets checklists skill); fixes: two uiux edits failed on truncated oldString — redone via python line-range replacement
- [x] **2.5** Delete stale deployed per-language reviewers from `~/.config/opencode/agents/` (python/typescript/go/rust/java — machine-local, not committable)
    — **Why:** deployed drift; consolidation shipped long ago, stale copies still spawn
    — **Done when:** 5 files gone from deployed dir; repo untouched
    — **Consumers affected:** local sessions (agent list)
    — **Done:** rm'd all 5 deployed files; fixes: none

### Phase 3: Split ticket-creation from plan/execute — DONE (verdict: VERIFIED)
- [x] **3.1** `git mv skills/ticket-plan-workflow-skill skills/ticket-creation-skill` + rewrite SKILL.md (Steps 1–4 + guard + prerequisites + common issues; delete 5–9/5.5/5.6/6/6.5/7.5 + PLAN template)
    — **Why:** user decision — ticket creation only; single responsibility
    — **Done when:** name=dir=ticket-creation-skill, ≤~320 lines, no branch/PLAN/commit/execute content
    — **Consumers affected:** 18 referencing files, opencode.json, worktree-pipeline
    — **Done:** git mv + rewrite 758→261 lines; creation-only steps retained; "Renamed from" note points movers to worktree-pipeline; fixes: none
- [x] **3.2** Absorb PLAN authoring into `worktree-pipeline-skill/SKILL.md` (adopt/rename, BRD/SRS linking, PLAN template + step-authoring rules, atomicity self-check, PLAN commit/push); Step 3 ticket-create points at ticket-creation-skill
    — **Why:** pipeline already owns branch+execute; owning plan-authoring removes two-way entry-contract coupling
    — **Done when:** self-contained Step 6; zero references to ticket-creation-skill steps 5.5–7
    — **Consumers affected:** /run-worktree-pipeline
    — **Done:** new §PLAN Authoring (6a adopt, 6b BRD/SRS, 6c template, 6d atomicity gate, 6e commit/push) — self-contained; Step 3 references ticket-creation-skill; 110→224 lines; fixes: none
- [x] **3.3** Semantic rename sweep: for each of the 18 referencing files, rename where it means "create ticket", rewrite where it describes moved planning behavior
    — **Why:** blind sed would leave false claims (e.g. "ticket-plan-workflow creates PLANs")
    — **Done when:** grep clean, no stale semantics
    — **Consumers affected:** all referencing skills/agents
    — **Done:** 16 files patched via scripted pass with per-line assertions: creation refs→ticket-creation-skill (semantic-release, maintainer, mermaid, repo-ops), PLAN/branch refs→worktree-pipeline §PLAN Authoring/§6b/§6d (plan-execution, plan-automation-loop, pr-creation, plan-updater, brd/srs-creation, requirements/discovery/technical-design agents), dual mentions where both apply (grilling, grill-with-docs, jira-git-integration); _archived exempt; fixes: none
- [x] **3.4** Add `create-ticket` command to `opencode.json`; update `run-worktree-pipeline` description if it names old skill; swap permission key
    — **Why:** user wants /create-ticket as a command for granularity
    — **Done when:** command present with description+template+agent; JSON parses; no `//` comments
    — **Consumers affected:** all sessions
    — **Done:** create-ticket command added (template loads ticket-creation-skill, agent build); permission key swapped in Phase 1 commit; run-worktree-pipeline description still accurate (no old-skill name); fixes: none

### Phase 4: Config + deploy sync — DONE (verdict: VERIFIED)
- [x] **4.1** Update `deploy/skill-profiles.json` (rename entry, add 3 new skills where lean-appropriate) + `deploy/presets/pack-devops.json` rename
    — **Why:** profiles/presets reference skills by name; rename breaks them otherwise
    — **Done when:** JSON parses, no ticket-plan-workflow references
    — **Consumers affected:** setup.sh --skill-profile, opencode-init
    — **Done:** renames landed in Phase 3 sweep; wayfinder-skill added to lean (primary-visible); checklists+baseline deliberately NOT in lean (subagent-loaded knowledge, house rule); files: deploy/skill-profiles.json, deploy/presets/pack-devops.json; fixes: none
- [x] **4.2** Run `node deploy/build-registry.mjs`; commit registry.json
    — **Why:** house rule — registry rebuild after ANY frontmatter change
    — **Done when:** exit 0; diff shows rename +3 skills
    — **Done:** rebuilt at every phase gate; registry has ticket-creation-skill, no old name; committed progressively; fixes: none
- [x] **4.3** README.md: skill count 137→140, Git/Workflow + Code Quality rows (+wayfinder-skill, +language-review-checklists-skill, +reviewer-baseline-skill, rename ticket-plan-workflow→ticket-creation), commands section +/create-ticket, subagents table language-reviewer row, migration note; `opencode_app/README.md` if it carries counts
    — **Why:** AGENTS.md sync rules; count-drift guards
    — **Done when:** counts match disk; tables list new skills
    — **Consumers affected:** docs readers, drift tests
    — **Done:** live counts 145→148 (lines 243/409 — plan's "137→140" was based on stale ledger; actual pre-existing live claim was 145, disk truth now 148); Git/Workflow 14→15 w/ wayfinder + rename + /create-ticket; Code Quality 12→14; ledger entry appended; archived-note + diagram + subagent-row updated; opencode_app/README.md has no global counts (pptx-only, skipped); fixes: none

### Phase 5: Verification gates — DONE (verdict: VERIFIED)
- [x] **5.1** Final gate sweep: registry build, JSON validation (opencode.json, skill-profiles.json, pack-devops.json), count parity (disk vs count_skills/count_agents vs README), grep sweeps (ticket-plan-workflow=0, frontmatter spot-checks: name=dir, no permission.skill in SKILL.md)
    — **Why:** never push red; falsifiable verdict per skill contract
    — **Done when:** all checks exit clean, verdict VERIFIED recorded
    — **Consumers affected:** release integrity
    — **Done:** `build-registry.mjs --check` OK (no drift); 4 JSON files parse; 148/148 skills pass frontmatter contract (name=dir, description, no permission key); counts: disk=registry=README (148 skills / 33 agents / 23 categories / 106 allows / 46 lean / review preset 31 / backend preset 25); residual greps clean; fixes: none

### Phase 6 (user mid-run addition): README.md + AGENTS.md staleness review
- [x] **6.1** Audit + fix stale numbers/rosters in README.md and AGENTS.md
    — **Why:** user request mid-run ("please also review if README.md and AGENTS.md are stale")
    — **Done when:** every count/roster claim matches disk/registry truth
    — **Consumers affected:** docs readers, drift tests
    — **Done:** README: repo-tree counts 32→33 agents / 145→148 skills; allowlist 105→106; lean 45→46; review preset 28→31; backend preset 23→25; modularization 145→148; agents section 32→33; iteration-protocol "30 existing"→29 (7+7+15). AGENTS.md: tier table dropped stale "incl. java" per-language reviewer; Return Contract reviewer list (architecture, code, python, typescript, java, go, rust, uiux)→(architecture, code, language, uiux); files: README.md, AGENTS.md; fixes: none
