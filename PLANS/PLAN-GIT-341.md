# PLAN-GIT-341: Vendor pstack core skills + ponytail satellites, wire subagent allowlists

**Issue:** https://github.com/darellchua2/opencode-config-template/issues/341
**Branch:** GIT-341

## Dependency & Consumer Map

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---------------------|---------------------------|---------------------------------|-------------|
| `opencode_app/.opencode/skills/{unslop,technical-writing,blast-radius}-skill/` | upstream fetch (pstack @ main SHA) | registry.json, opencode.json allowlist, lean profile, doc counts | low |
| `opencode_app/.opencode/skills/ponytail-{audit,review,debt}-skill/` | upstream fetch (ponytail v4.8.4) | registry.json, opencode.json allowlist, lean profile, doc counts, ATTRIBUTION.md | low |
| `plan-execution-skill` / `plan-automation-loop-skill` bodies | none | on-demand loaders only | low |
| `opencode_app/.opencode/agents/*.md` (11 files) | new skills on disk | per-spawn subagent context | med |
| `deploy/registry.json` | all SKILL.md frontmatter final | CI drift gate | med |
| `deploy/setup.sh` / `setup.ps1` / `README.md` / `opencode_app/README.md` counts | skills on disk | users reading docs, deploy banners | low |
| `~/.config/systemd/user/opencode-job-*` (orphaned) | none (system hygiene) | nothing — jobs deleted | low |

## Implementation Phases

### Phase 0: System hygiene (no repo changes)
- [ ] **0.1** Stop, disable, and remove the 4 orphaned canvastekk dev-legacy systemd units; daemon-reload
    — **Why:** Timers reference deleted job JSONs and will fail on next fire; plugin state cannot uninstall them
    — **Done when:** `systemctl --user list-timers` shows no opencode-job entries; unit files absent from `~/.config/systemd/user/`
    — **Consumers affected:** none

- [ ] **0.2** Delete stale scheduler logs + scope dirs for canvastekk-defect-service-f2864d09a58a
    — **Why:** Logs reference the removed jobs; user approved units+logs cleanup
    — **Done when:** `~/.config/opencode/logs/scheduler/canvastekk-defect-service-f2864d09a58a/` and `~/.config/opencode/scheduler/scopes/canvastekk-defect-service-f2864d09a58a/` no longer exist
    — **Consumers affected:** none

### Phase 1: Vendor pstack core 3 (commit 1)
- [ ] **1.1** Fetch verbatim SKILL.md bodies for unslop, technical-writing, blast-radius from cursor/plugins@<pinned main SHA>; record SHA
    — **Why:** Vendored-verbatim policy requires pinned source for attribution
    — **Done when:** 3 raw bodies retrieved and SHA captured
    — **Consumers affected:** none

- [ ] **1.2** Write `opencode_app/.opencode/skills/{unslop,technical-writing,blast-radius}-skill/SKILL.md` with attribution headers, house frontmatter (MIT, compatibility: opencode, category), drafted ≤50w descriptions; neutralize blast-radius sibling refs (/arena, /why)
    — **Why:** Deliverable core — 3 new direct-copy skills
    — **Done when:** 3 files exist, frontmatter validates (name=dirname, desc ≤50w), no Cursor-only keys
    — **Consumers affected:** registry, allowlists, doc counts

- [ ] **1.3** Rebuild registry: `node deploy/build-registry.mjs`
    — **Why:** CI drift gate enforces registry == frontmatter
    — **Done when:** deploy/registry.json contains the 3 new entries
    — **Consumers affected:** CI

- [ ] **1.4** Allow 3 skills in `opencode_app/opencode.json` permission.skill + add to `deploy/skill-profiles.json` lean array
    — **Why:** Primary visibility (FULL + LEAN) per approved decision
    — **Done when:** both files list all 3; JSON parses
    — **Consumers affected:** primary session, skill_profiles.bats

- [ ] **1.5** Sync counts/listings in deploy/setup.sh, deploy/setup.ps1, README.md, opencode_app/README.md
    — **Why:** AGENTS.md sync table; hardcoded counts drift otherwise
    — **Done when:** all skill counts/listings reflect +3
    — **Consumers affected:** docs readers, deploy banners

- [ ] **1.6** Commit `feat(skills): vendor pstack core 3 (unslop, technical-writing, blast-radius)`
    — **Why:** Atomic batch boundary
    — **Done when:** git log shows the commit with registry + docs + skills together
    — **Consumers affected:** none

### Phase 2: Router patterns into plan skills (commit 2)
- [ ] **2.1** plan-execution-skill: add verbatim-playbook discipline (plan steps copied into todolist before task todos; skipped steps stay with `skip: <reason>`)
    — **Why:** pstack router anti-drift mechanism, approved enhancement
    — **Done when:** SKILL.md body contains the discipline section
    — **Consumers affected:** on-demand loaders

- [ ] **2.2** plan-automation-loop-skill: add falsifiable done-predicate to verification gate (VERIFIED / NOT VERIFIED / INCONCLUSIVE; inconclusive ≠ pass) + trim description 33w→24w
    — **Why:** Approved enhancement + folded frontmatter trim
    — **Done when:** body has predicate section; description matches drafted 24w version; registry rebuilt
    — **Consumers affected:** on-demand loaders, registry

- [ ] **2.3** Rebuild registry + commit `feat(skills): add pstack router patterns to plan skills`
    — **Why:** Description changed in 2.2 → drift gate
    — **Done when:** commit landed with rebuilt registry
    — **Consumers affected:** CI

### Phase 3: Vendor ponytail satellites (commit 3)
- [ ] **3.1** Fetch verbatim satellite bodies from DietrichGebert/ponytail@v4.8.4 (skills/ponytail-{audit,review,debt}/SKILL.md)
    — **Why:** Pinned-tag vendored-verbatim policy
    — **Done when:** 3 raw bodies retrieved
    — **Consumers affected:** none

- [ ] **3.2** Write `opencode_app/.opencode/skills/ponytail-{audit,review,debt}-skill/SKILL.md` (house frontmatter, drafted descriptions 25w/28w/23w) + extend plugins/ATTRIBUTION.md file inventory
    — **Why:** Deliverable — 3 satellite skills with attribution
    — **Done when:** 3 files + ATTRIBUTION.md updated
    — **Consumers affected:** registry, allowlists, doc counts

- [ ] **3.3** Rebuild registry; allow in opencode.json + lean profile (FULL+LEAN per user decision)
    — **Why:** Visibility decision: satellites in both profiles (+174 tok accepted)
    — **Done when:** registry + both config files updated
    — **Consumers affected:** primary session, bats

- [ ] **3.4** Sync doc counts (+3 more) + commit `feat(skills): vendor ponytail satellite skills (audit, review, debt)`
    — **Why:** Batch boundary with docs
    — **Done when:** commit landed
    — **Consumers affected:** none

### Phase 4: Subagent allowlist wiring (commit 4)
- [ ] **4.1** Apply 22 corrected wirings across agent files: unslop→{documentation, requirements-, technical-design-, discovery-specialist, pr-workflow, startup-ceo, docx-creation}; technical-writing→{documentation, requirements-, technical-design-, discovery-specialist}; blast-radius→{code-review, architecture-review, pr-workflow, loop-operator, autoresearch-code, autoresearch-ml, language-reviewer}; ponytail-audit→{architecture-review, code-review}; ponytail-review→{code-review, architecture-review}; ponytail-debt→{repo-ops-specialist}
    — **Why:** Approved corrected mapping (2 drops, 1 swap, 3 adds vs original)
    — **Done when:** 13 agent frontmatters list exactly the mapped skills
    — **Consumers affected:** per-spawn subagent context

- [ ] **4.2** Offset removals: drop horseshoe-paper-writing from documentation-subagent; drop jira-ticket-labeler from pr-workflow-subagent
    — **Why:** Net-zero token discipline approved
    — **Done when:** both allows absent
    — **Consumers affected:** those two agents

- [ ] **4.3** Rebuild registry (agent frontmatter changed) + commit `feat(agents): wire skills into subagent allowlists`
    — **Why:** Drift gate covers agent files
    — **Done when:** commit landed with registry
    — **Consumers affected:** CI

### Phase 5: Description trims (commit 5)
- [ ] **5.1** Trim descriptions: markitdown-mcp→17w, git-semantic-commits→25w, git-compact-commits→22w, horseshoe-paper-writing→22w, continuous-learning (−4w)
    — **Why:** ~150-250 tok fleet-wide savings on highest-multiplier entries
    — **Done when:** 5 SKILL.md descriptions updated; registry rebuilt
    — **Consumers affected:** all sessions spawning those agents

- [ ] **5.2** Commit `refactor(skills): trim high-multiplier skill descriptions`
    — **Why:** Atomic style-only batch
    — **Done when:** commit landed (no logic mixed)
    — **Consumers affected:** none

### Phase 6: Gates, deploy, review
- [ ] **6.1** Run gates: `node deploy/build-registry.mjs` (idempotent), `bats tests/`, count-consistency grep across setup.sh/ps1/READMEs
    — **Why:** Verification gate before deploy
    — **Done when:** bats green; zero stale counts
    — **Consumers affected:** CI

- [ ] **6.2** Deploy via `./deploy/setup.sh`; verify 6 new skills land in `~/.config/opencode/skills/`
    — **Why:** Single source of truth → deployed copies
    — **Done when:** deployed dirs exist and match source
    — **Consumers affected:** user environment

- [ ] **6.3** Independent review by opencode-tooling-subagent (task call); fix findings
    — **Why:** User-mandated reviewer sign-off
    — **Done when:** review returns success/none or findings addressed
    — **Consumers affected:** this PR

- [ ] **6.4** Push branch, update issue #341 with completion comment
    — **Why:** Traceability per workflow
    — **Done when:** remote has branch; issue has final comment
    — **Consumers affected:** none

## Step Authoring Rules
- **Atomic**: one reversible concern per step; if a step does two things, split it.
- **Rationale mandatory**: every step MUST have a **Why**; a step without rationale is malformed and blocks commit (enforced by Step 6.5 self-check; flagged by `plan-updater-skill`).
- **Completion signal**: every step MUST have an objective **Done when** check, not a subjective "done".
- **Consumers explicit**: list affected consumers so reviewers/execution know blast radius; write "none" if truly isolated.

## Technical Notes
- Vendored-verbatim policy: pinned upstream SHA (pstack main) / tag (ponytail v4.8.4) recorded in attribution headers; only frontmatter + sibling refs adapted.
- No dependency changes → no npm install / lockfile touch.
- User's pre-existing WIP stashed (stash@{0}, stash@{1}) — restore after merge if desired.
- Net primary initial-context cost accepted: FULL +~365 tok (+8.4%), LEAN +~365 tok (+23%).

## Dependencies
- Upstream availability: cursor/plugins repo (pstack), DietrichGebert/ponytail v4.8.4 tag.
- gh authenticated (darellchua2); systemd user session for Batch 0.

## Risks & Mitigation
- **Upstream body fetch fails** → fall back to documented summaries, mark partial, surface to user.
- **Count drift across 7+ hardcoded locations** (known anti-pattern, LEARNINGS) → grep-verify every count after final batch.
- **Registry parser edge** (block scalars) → rebuild after each frontmatter change, diff before commit.

## Success Metrics
- 6 new skills deployed and invocable; bats suite green; CI registry gate green; zero stale counts; review sign-off.
