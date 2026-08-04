# PLAN-BT-157 — Dynamic skill-counts in deploy scripts + rebuild stale debug-echo category listing

**Issue:** darellchua2/opencode-config-template#299
**JIRA:** [BT-157](https://betekk.atlassian.net/browse/BT-157) (BETEKK / Task)
**Branch:** `BT-157` (off `main` @ v4.11.0)
**Origin:** Split from #297 / PR #298 (Phase 6.4 + 6.5)

## Context — verified current state (main v4.11.0)

The deploy scripts hardcode the skill total in **multiple** locations with **three different stale values** — triple drift:

| Location | Hardcoded value | Reality |
|----------|-----------------|---------|
| `setup.sh:685` `SKILLS (126):` banner | 126 | disk = **132** |
| `setup.sh:3629` `📦 123 Skills Available` summary | 123 | disk = **132** |
| `setup.ps1:924` `SKILLS (126):` banner | 126 | disk = **132** |
| `setup.ps1:2707` `123 Skills Available` summary | 123 | disk = **132** |

Meanwhile `setup.sh:3447` **already computes** `skill_count=$(find ${SKILLS_DIR} -name "SKILL.md" | wc -l)` — but only the `--status` debug headline uses it. `setup.ps1` has **no** dynamic computation at all.

Additionally, the `--status` category listing (`setup.sh:3449+`) is internally contradictory: its headline reports the dynamic count, but the per-category breakdown omits ~6 categories (Agent Optimization, Startup/Business, Configuration, Security, DevOps + Autoresearch) so the listing sums to far less than the headline.

## Dependency & Consumer Map

| Node (file/section) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---------------------|---------------------------|---------------------------------|-------------|
| `setup.sh` banner @ `:685` (`SKILLS (N):`) | dynamic `skill_count` var in scope | every user running `setup.sh` (first-impression banner) | low |
| `setup.sh` summary @ `:3629` (`📦 N Skills Available`) | dynamic `skill_count` var in scope | user-visible summary on completion | low |
| `setup.sh` dynamic compute @ `:3447` | `${SKILLS_DIR}` populated | `--status` headline (already) + banners (after this work) | low — already exists, just lift scope |
| `setup.sh` `--status` category listing `:3449+` | none | `--status` diagnostic output (operators/debug) | low — editorial mapping |
| `setup.ps1` banner @ `:924` | new `$skillCount` compute | every Windows user running `setup.ps1` | low |
| `setup.ps1` summary @ `:2707` | new `$skillCount` compute | Windows user-visible summary | low |
| `tests/test_*.bats` count assertions | depends on which assert a hardcoded total | CI (Release workflow) | med — may need updating if a test pins a literal |

## Implementation Phases

### Phase 1: `setup.sh` — interpolate dynamic total into banners
- [ ] **1.1** Compute `skill_count` once at function scope (top of the deploy/banner function) from disk: `local skill_count=$(find "${SKILLS_DIR}" -type f -name "SKILL.md" 2>/dev/null | wc -l)`, so it is in scope for both banner locations.
    — **Why:** the computation already exists at `:3447` but only inside the `--status` block; lifting it to function scope makes it available to the main banner (`:685`) and summary (`:3629`) without duplicating the `find`.
    — **Done when:** a single `skill_count` assignment is reachable by all three consumers; no second `find ... | wc -l` is added.
    — **Consumers affected:** `:685` banner, `:3629` summary, `:3447` `--status` headline (reuse same var).
- [ ] **1.2** Replace the hardcoded `SKILLS (126):` literal at `:685` with interpolation `SKILLS (${skill_count}):`.
    — **Why:** removes the primary drift surface (first-impression banner); the heredoc/echo context is interpolation-capable.
    — **Done when:** `grep -nE "SKILLS \([0-9]+\)" deploy/setup.sh` returns no literal-number matches.
    — **Consumers affected:** user banner output.
- [ ] **1.3** Replace the hardcoded `📦 123 Skills Available` at `:3629` with `📦 ${skill_count} Skills Available`.
    — **Why:** second drift surface; same var, different (wrong) literal today.
    — **Done when:** `grep -nE "[0-9]+ Skills Available" deploy/setup.sh` returns no literal-number matches.
    — **Consumers affected:** completion summary output.

### Phase 2: `setup.ps1` — add dynamic compute + interpolate
- [ ] **2.1** Add a `$skillCount` computation near the top of the deploy function: `$skillCount = (Get-ChildItem -Path $SkillsDir -Recurse -Filter "SKILL.md" -ErrorAction SilentlyContinue | Measure-Object).Count` (guard for missing dir).
    — **Why:** `setup.ps1` has no dynamic count today — both banner literals are pure guesses; this is the Windows-parity fix.
    — **Done when:** a single `$skillCount` variable is assigned and reachable by both banner locations; missing-dir case yields 0 without error.
    — **Consumers affected:** `:924` banner, `:2707` summary.
- [ ] **2.2** Replace `SKILLS (126):` at `:924` with `SKILLS ($skillCount):`.
    — **Why:** Windows parity with 1.2; removes the same drift on PowerShell.
    — **Done when:** `grep -nE "SKILLS \([0-9]+\)" deploy/setup.ps1` returns no literal-number matches.
    — **Consumers affected:** Windows user banner output.
- [ ] **2.3** Replace `123 Skills Available` at `:2707` with `$skillCount Skills Available`.
    — **Why:** Windows parity with 1.3.
    — **Done when:** `grep -nE "[0-9]+ Skills Available" deploy/setup.ps1` returns no literal-number matches.
    — **Consumers affected:** Windows completion summary output.

### Phase 3: `--status` category listing reconciliation (item 6.4)
- [ ] **3.1** Rebuild the `setup.sh` `--status` per-category breakdown (`:3449+`) to include all current categories (add the ~6 missing: Agent Optimization, Startup/Business, Configuration, Security, DevOps, Autoresearch) so the listing's sum matches the dynamic headline.
    — **Why:** the diagnostic is internally contradictory today (headline says 132, listing sums to ~90); a wrong diagnostic is worse than none.
    — **Done when:** the sum of all category counts in the listing equals the dynamic `skill_count` headline above it.
    — **Consumers affected:** operators running `setup.sh --status` (debug only).
- [ ] **3.2** Mirror the rebuilt category listing in `setup.ps1` `--status` equivalent.
    — **Why:** Windows parity; keep both scripts' diagnostics consistent.
    — **Done when:** `setup.ps1` `--status` listing sums to the same total as `setup.sh`.
    — **Consumers affected:** Windows operators.
- [ ] **3.3** (per-category counts stay human-maintained) — explicitly do NOT auto-derive categories; only the **total** is dynamic. Add a one-line comment at the listing stating categorization is an editorial mapping.
    — **Why:** categorization is editorial (a skill's category is a human judgement), not disk-derivable; auto-deriving would introduce a different drift. Documenting this prevents the next cycle from "fixing" it the wrong way.
    — **Done when:** a comment explains per-category numbers are hand-maintained and only the total is computed.
    — **Consumers affected:** future maintainers (next remediation cycle).

### Phase 4: Tests + verification gate
- [ ] **4.1** Audit `tests/*.bats` for any assertion that pins a hardcoded skill total; update to compute from disk (or assert `>=` a floor) instead of a literal.
    — **Why:** a test that pins `123` would now fail (disk=132) and re-introduce the drift as a "fix the test to 132" cycle; make the test count-agnostic.
    — **Done when:** `grep -rnE "123|126" tests/ | grep -i skill` returns no count-pinning assertions (or they are dynamic).
    — **Consumers affected:** CI Release workflow.
- [ ] **4.2** Run the full gate: `bash -n deploy/setup.sh`; `python3 -m json.tool opencode_app/opencode.json >/dev/null`; all skill frontmatter parses; `bats tests/` green (if bats installed).
    — **Why:** every prior change in this repo ships through this gate; a green gate is the completion signal.
    — **Done when:** all commands exit 0.
    — **Consumers affected:** PR merge / Release workflow.

## Acceptance Criteria (summary)

- [ ] No hardcoded total skill-count literals in `setup.sh` or `setup.ps1` — all interpolated from a single disk-derived computation.
- [ ] `grep -nE "SKILLS \([0-9]+\)|[0-9]+ Skills Available" deploy/setup.sh deploy/setup.ps1` → **zero** matches.
- [ ] `--status` category listing sums to the dynamic total in both scripts.
- [ ] Per-category counts remain human-maintained (documented), not auto-derived.
- [ ] `bash -n` clean; bats tests green; count-assertion tests made dynamic.

## Risks & Mitigation

- **Risk:** a category count in the listing is itself wrong (stale). **Mitigation:** Phase 3 reconciles the listing to the total; any residual per-category inaccuracy is editorial and out of scope (documented).
- **Risk:** a bats test pins a literal and breaks. **Mitigation:** Phase 4.1 makes count-assertions dynamic before running the gate.

## Out of scope

- Auto-deriving categories from disk (categorization is editorial).
- The devmain divergence that caused the original stale counts (resolved separately via the v4.11.0 rebase).

---
*Generated by ticket-plan-workflow-skill for BT-157. Update checkboxes as phases complete.*
