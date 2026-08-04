# PLAN-BT-157 — Dynamic skill-counts in deploy scripts + rebuild stale debug-echo category listing

**Issue:** darellchua2/opencode-config-template#299
**JIRA:** [BT-157](https://betekk.atlassian.net/browse/BT-157) (BETEKK / Task)
**Branch:** `BT-157` (off `main` @ v4.11.0)
**Origin:** Split from #297 / PR #298 (Phase 6.4 + 6.5)
**Revision:** v2 — corrected after opencode-tooling-subagent review (see "Review corrections" below)

## Review corrections (v1 → v2)

The review caught 3 critical defects + major gaps in v1. Corrected here:
1. **v1 said "reality = 132" — WRONG.** Naive `find` counts 6 **archived** skills in `_archived/`. Active count (what the deploy ships, `rsync --exclude='_archived'` at `setup.sh:2533`) = **126**. So the `126` literals are coincidentally *correct*; only `123` is stale. All dynamic computations must use `-not -path "*/_archived/*"`.
2. **v1 Phase 1.1 "lift to function scope" — unworkable.** The 3 consumers live in 3 *different* functions (`show_help`:465, `print_summary`:3341, `print_next_steps`:3599). A `local` in one is invisible to the others. **Fix:** a `count_skills <dir>` helper called by each.
3. **v1 Phase 3.3 "categories are editorial, not disk-derivable" — FALSE.** 126/126 active skills carry a `category:` frontmatter field (21 categories). Per-category counts ARE auto-derivable via one `grep | sort | uniq -c` pipeline. **Reversed:** auto-derive (drift-proof) instead of hand-maintain.
4. **v1 missed:** `README.md` (2 stale `126` literals), a **second** category listing at `setup.sh:3632-3637` (`print_next_steps`), the **source-vs-deployed** semantic (banner needs SOURCE count, shown on `--help` before deploy; `--status` needs DEPLOYED count), and the `init.bats`/`registry.json` code path (`126` is correct there but pinned to a literal).

## Context — verified current state (main v4.11.0)

| Location | Literal | Correct active count | Verdict |
|----------|---------|----------------------|---------|
| `setup.sh:685` `SKILLS (126):` banner (`show_help`) | 126 | 126 | coincidentally right, but **hardcoded → will drift** |
| `setup.sh:3629` `📦 123 Skills Available` (`print_next_steps`) | 123 | 126 | **stale (−3)** |
| `setup.sh:3632-3637` category breakdown (`print_next_steps`) | sums 109 | 126 | **stale + incomplete** |
| `setup.sh:3447` `--status` compute (`print_summary`) | dynamic | deployed | ✓ correct (deployed dir excludes `_archived`) |
| `setup.sh:3449+` `--status` category listing | sums 102 | 126 | **stale + incomplete (omits 6 cats)** |
| `setup.ps1:924` `SKILLS (126):` banner | 126 | 126 | hardcoded → will drift |
| `setup.ps1:2707` `123 Skills Available` | 123 | 126 | **stale (−3)** |
| `README.md:175` "126 skills" | 126 | 126 | hardcoded → will drift |
| `README.md:459` "126 skills ... 21 categories" | 126 | 126 | hardcoded → will drift |
| `deploy/registry.json` skills array | 126 | 126 | ✓ correct (opencode-init source) |
| `tests/init.bats:28,43` `[ "$skills" = "126" ]` | 126 | 126 | ✓ value correct, but **pinned literal** → will drift |

**Root cause:** every count is a hardcoded literal that must be hand-updated on each skill add (3rd drift cycle: PLAN-GIT-237 → #297 → now). Fix: derive from disk once, interpolate everywhere, exclude `_archived`.

**Key paths (setup.sh):** `REPO_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"` (`:70`); source skills `${REPO_DIR}/opencode_app/.opencode/skills`; deployed `${SKILLS_DIR}` = `${CONFIG_DIR}/skills`.

## Dependency & Consumer Map

| Node | Depends on | Consumers | Risk |
|------|-----------|-----------|------|
| `count_skills <dir>` helper (new) | `${REPO_DIR}` set (`:70`) | show_help, print_next_steps, print_summary | low |
| `print_skill_categories <dir>` helper (new) | source skills dir exists | print_next_steps (`:3632`), print_summary (`:3449`) | low |
| `show_help` banner `:685` | `count_skills` + SOURCE path | every `--help` / `-h` invocation | low |
| `print_next_steps` total `:3629` | `count_skills` + SOURCE path | post-deploy summary | low |
| `print_next_steps` cats `:3632` | `print_skill_categories` | post-deploy summary | low |
| `print_summary` `:3447` total | `count_skills` + DEPLOYED dir | `--status` | low — refactor existing find to helper |
| `print_summary` cats `:3449` | `print_skill_categories` | `--status` | low |
| `setup.ps1` parity helpers | `$RepoDir` set | ps1 banner/summary/--status | low |
| `README.md` literals `:175,:459` | manual edit (markdown, no interp) | readers | low |
| `init.bats:28,43` | registry.json length | CI | low — make dynamic |

## Implementation Phases

### Phase 1: `setup.sh` — `count_skills` helper + wire 3 consumers (source vs deployed)
- [x] **1.1** Add a `count_skills()` helper near the other utility functions (after `REPO_DIR` is defined, ~`:85`): `count_skills() { find "$1" -type f -name "SKILL.md" -not -path "*/_archived/*" 2>/dev/null | wc -l; }`.
    — **Why:** the 3 consumers are in 3 different functions (`show_help`, `print_summary`, `print_next_steps`); a `local` can't span them. A helper is the DRY, scope-safe way to share one computation. `-not -path "*/_archived/*"` matches the deploy's `rsync --exclude='_archived'` so the count reflects **active** skills only.
    — **Done when:** `grep -nE "^count_skills\(\)" deploy/setup.sh` finds the helper; calling `count_skills "${REPO_DIR}/opencode_app/.opencode/skills"` returns 126.
    — **Consumers affected:** 1.2, 1.3, 1.4, Phase 3.
- [x] **1.2** In `show_help()` replace `SKILLS (126):` at `:685` with `SKILLS ($(count_skills "${REPO_DIR}/opencode_app/.opencode/skills")):` — **SOURCE** count (banner shown on `--help` before any deploy, must advertise what's shipped, not what's deployed).
    — **Why:** `show_help` runs pre-deploy; using the DEPLOYED dir would show `0` on a fresh machine. Source count is the advertising number.
    — **Done when:** `grep -nE "SKILLS \([0-9]+\)" deploy/setup.sh` returns no literal; `--help` shows the active source count.
    — **Consumers affected:** every `setup.sh --help` user.
- [x] **1.3** In `print_next_steps()` replace `📦 123 Skills Available` at `:3629` with `📦 $(count_skills "${REPO_DIR}/opencode_app/.opencode/skills") Skills Available` — SOURCE count.
    — **Why:** post-deploy summary advertises what's available; source count is stable regardless of deploy success. Fixes the stale `123` (−3).
    — **Done when:** `grep -nE "[0-9]+ Skills Available" deploy/setup.sh` returns no literal.
    — **Consumers affected:** post-deploy summary output.
- [x] **1.4** Refactor `print_summary()` `:3447` to use the helper: replace `local skill_count=$(find "${SKILLS_DIR}" -type f -name "SKILL.md" ...)` with `local skill_count=$(count_skills "${SKILLS_DIR}")` — **DEPLOYED** count.
    — **Why:** dedupe the computation into the helper; `--status` legitimately reports the DEPLOYED state (what the user actually has), which differs from source if a deploy is partial. Deployed dir already excludes `_archived` (rsync), so the helper's `-not -path` is harmless here.
    — **Done when:** `:3447` calls `count_skills`; no standalone `find ... SKILL.md | wc -l` remains outside the helper.
    — **Consumers affected:** `--status` headline (unchanged value, cleaner source).

### Phase 2: `setup.ps1` — parity helpers + wire consumers
- [x] **2.1** Add a `Get-SkillCount` function near the other utilities: `function Get-SkillCount { param([string]$Path) if (-not (Test-Path $Path)) { return 0 }; return @(Get-ChildItem -Path $Path -Recurse -Filter "SKILL.md" -ErrorAction SilentlyContinue | Where-Object { $_.FullName -notmatch "[\\/​]_archived[\\/​]" }).Count }`.
    — **Why:** Windows parity with 1.1; `setup.ps1` currently has NO correct SKILL.md-file count (its `:1811`/`:2649` count *directories* including non-skill subdirs — a different, wrong metric). Excludes `_archived` to match deploy (`:1802`).
    — **Done when:** `grep -nE "function Get-SkillCount" deploy/setup.ps1` finds it; `Get-SkillCount (Join-Path $RepoDir "opencode_app\.opencode\skills")` returns 126.
    — **Consumers affected:** 2.2, 2.3, 2.4.
- [x] **2.2** Replace `SKILLS (126):` at `:924` with `SKILLS ($(Get-SkillCount (Join-Path $RepoDir 'opencode_app\.opencode\skills'))):` — SOURCE count.
    — **Why:** Windows parity with 1.2.
    — **Done when:** `grep -nE "SKILLS \([0-9]+\)" deploy/setup.ps1` returns no literal.
    — **Consumers affected:** Windows `--help` users.
- [x] **2.3** Replace `123 Skills Available` at `:2707` with `$(Get-SkillCount (Join-Path $RepoDir 'opencode_app\.opencode\skills')) Skills Available` — SOURCE count.
    — **Why:** Windows parity with 1.3.
    — **Done when:** `grep -nE "[0-9]+ Skills Available" deploy/setup.ps1` returns no literal.
    — **Consumers affected:** Windows post-deploy summary.
- [x] **2.4** Wire `Get-SkillCount` into the ps1 `--status` total (find the ps1 equivalent of `:3447`'s dir-count) — DEPLOYED count.
    — **Why:** parity with 1.4; replace the directory-count metric with the correct SKILL.md-file count.
    — **Done when:** ps1 `--status` headline uses `Get-SkillCount $SkillsDir` (deployed).
    — **Consumers affected:** Windows `--status`.

### Phase 3: Auto-derive category breakdown (REVERSES v1's "hand-maintain" — categories ARE disk-derivable)
- [x] **3.1** Add a `print_skill_categories()` helper (bash) that auto-derives per-category counts from frontmatter and prints them: `find "$1" -type f -name "SKILL.md" -not -path "*/_archived/*" -exec grep -hE '^[[:space:]]*category:' {} + 2>/dev/null | sed -E 's/^[[:space:]]*category:[[:space:]]*//' | sort | uniq -c | sort -rn | while read n c; do echo "    - $c ($n)"; done`.
    — **Why:** v1 Phase 3.3 claimed categories aren't disk-derivable — **FALSE**: 126/126 active skills carry a `category:` field (21 categories). Auto-derive is drift-proof; hand-maintenance is the bug we're fixing. One pipeline replaces two stale hardcoded listings.
    — **Done when:** `grep -nE "^print_skill_categories\(\)" deploy/setup.sh` finds the helper; running it on the source dir prints 21 categories summing to 126.
    — **Consumers affected:** 3.2, 3.3.
- [x] **3.2** Replace the hardcoded `--status` category listing at `setup.sh:3449+` with a call `print_skill_categories "${SKILLS_DIR}"` (DEPLOYED) — removes ~115 lines of stale echo.
    — **Why:** the listing omits 6 categories and sums to 102 vs the 126 headline — internally contradictory. Auto-derive fixes both the omissions and the sum.
    — **Done when:** the `--status` listing sums to the `--status` headline total; `grep -cE "Framework \(19\)|Language-Specific \(8\)" setup.sh` drops (those literals removed).
    — **Consumers affected:** operators running `--status`.
- [x] **3.3** Replace the hardcoded `print_next_steps` category listing at `setup.sh:3632-3637` with `print_skill_categories "${REPO_DIR}/opencode_app/.opencode/skills"` (SOURCE).
    — **Why:** this second listing (sums 109) was missed by v1; it re-drifts immediately after 1.3 fixes the total. SOURCE dir because it advertises what's shipped.
    — **Done when:** `print_next_steps` category section is a single helper call; no hardcoded `Framework (N)` literals remain.
    — **Consumers affected:** post-deploy summary.
- [x] **3.4** Mirror `Get-SkillCategories` + the two call sites in `setup.ps1` (Windows parity for 3.1-3.3).
    — **Why:** keep both scripts' diagnostics consistent.
    — **Done when:** ps1 `--status` and post-deploy listings auto-derive and sum to 126.
    — **Consumers affected:** Windows operators.

### Phase 4: README.md + registry.json + init.bats (sync-rule targets v1 missed)
- [x] **4.1** Update `README.md:175` ("126 skills") and `:459` ("126 skills organized across 21 categories") — README is markdown (no interpolation), so update the literal to the current active count **and add a `<!-- count: hand-maintained, see BT-157 -->` comment** flagging it as a known sync target.
    — **Why:** the repo's own sync rule (AGENTS.md "Sync Rules") lists README.md as mandatory; v1 omitted it entirely. Markdown can't interpolate, so a flag comment is the laziest way to surface it for the next sync.
    — **Done when:** both literals match the active count; a comment marks them.
    — **Consumers affected:** README readers, documentation-sync-workflow.
- [x] **4.2** Regenerate `deploy/registry.json` skill list from disk (excluding `_archived`) so it stays at 126/active; verify `jq '.skills | length' deploy/registry.json` = 126 and each entry resolves to a real skill dir.
    — **Why:** registry.json is the opencode-init source-of-truth; it's currently correct (126) but was hand-built. A regeneration guarantees no orphans/stale entries. If a generator script exists, run it; else diff-current and only fix discrepancies.
    — **Done when:** `jq '.skills|length' deploy/registry.json` = active count; no entry points to a missing/nonexistent skill.
    — **Consumers affected:** opencode-init CLI.
- [x] **4.3** Make `tests/init.bats:28,43` count-agnostic: assert against the registry's own length (`[ "$skills" = "$(jq '.skills|length' "$REG")" ]`) instead of the literal `"126"`.
    — **Why:** the current `126` is correct, but pinning a literal means the test silently rots on the next skill add (the exact drift cycle this ticket kills). Asserting against the registry's own length makes the test self-healing. Note `:43`'s line has no "skill" word, so v1's grep missed it.
    — **Done when:** `grep -nE '"126"|"123"' tests/init.bats` returns no literal count assertions (both :28 and :43 dynamic).
    — **Consumers affected:** CI Release workflow.

### Phase 5: Verification gate
- [x] **5.1** Run the full gate: `bash -n deploy/setup.sh`; `pwsh -nop -c '…parse setup.ps1…'` or manual brace check; `python3 -m json.tool deploy/registry.json >/dev/null`; `python3 -m json.tool opencode_app/opencode.json >/dev/null`; all skill frontmatter parses; `bats tests/` green (if installed).
    — **Why:** every prior change ships through this gate; green = done.
    — **Done when:** all commands exit 0; `bats tests/` shows 0 failures.
    — **Consumers affected:** PR merge / Release workflow.
- [x] **5.2** Confirm the drift surface is eliminated: `grep -rnE "SKILLS \([0-9]+\)|[0-9]+ Skills Available" deploy/setup.sh deploy/setup.ps1` → **zero** matches; `grep -rnE "Framework \(19\)|Language-Specific \(8\)|CAD & Hardware Design \(14\)" deploy/setup.sh deploy/setup.ps1` → **zero** (no hardcoded category literals).
    — **Why:** this is the acceptance signal — no hardcoded count literals remain in either deploy script.
    — **Done when:** both greps return zero.
    — **Consumers affected:** future skill-add cycles (the drift can't recur).

## Acceptance Criteria (summary)

- [x] No hardcoded total skill-count literals in `setup.sh`/`setup.ps1` — all via `count_skills`/`Get-SkillCount` (excluding `_archived`).
- [x] `grep -rnE "SKILLS \([0-9]+\)|[0-9]+ Skills Available" deploy/setup.sh deploy/setup.ps1` → **zero**.
- [x] No hardcoded category literals — both listings auto-derive from frontmatter; sums match totals.
- [x] Source-vs-deployed semantics correct: `show_help`/`print_next_steps` = SOURCE; `--status` = DEPLOYED.
- [x] `README.md` literals current + flagged; `registry.json` regenerated; `init.bats` count-agnostic.
- [x] `bash -n` clean; bats green; JSON valid.

## Risks & Mitigation

- **Risk:** auto-derive grep is slow on `--help` (132-file scan). **Mitigation:** `show_help` uses only `count_skills` (find|wc -l, ~10ms); the heavier category grep runs only in `print_summary`/`print_next_steps` (once per deploy/status, acceptable).
- **Risk:** a skill lacks `category:` → auto-derive sum < total. **Mitigation:** verified 126/126 active skills have `category:`; if a future skill omits it, the listing sum will visibly fall short of the total (a self-announcing discrepancy, not a silent drift).
- **Risk:** PowerShell regex for `_archived` path matching varies by separator. **Mitigation:** match `[\\/]_archived[\\/]` (both separators).
- **Risk:** registry.json regeneration drops/renames an entry. **Mitigation:** 4.2 diffs against current; only fix discrepancies, don't rebuild blindly.

## Out of scope

- The `38 agents` count (`setup.sh:2484`, `README.md:175`) — same drift class but agents, not skills; separate ticket.
- The devmain divergence that caused the original stale `123` (resolved via the v4.11.0 rebase).

---
*PLAN-BT-157 v2 — revised after opencode-tooling-subagent review. Update checkboxes as phases complete.*
