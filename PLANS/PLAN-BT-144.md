# PLAN-BT-144 — Audit skills & subagents consistency across repo docs and config (post-BT-142 drift check)

**JIRA:** https://betekk.atlassian.net/browse/BT-144
**Branch:** `audit/BT-144-skills-subagents-consistency`
**Created:** 2026-07-21
**Parent Epic:** [BT-142](https://betekk.atlassian.net/browse/BT-142)

## Goal

Verify that every place skills and subagents are listed, counted, or cross-referenced matches the actual files on disk in `opencode_app/.opencode/`. Fix any drift introduced by the BT-142 breaking PPTX migration and subsequent additions.

## Audit Results Summary

**Sources of truth (verified 2026-07-21):**

| Metric | Value | Command |
|--------|-------|---------|
| SKILL.md files | **123** | `find opencode_app/.opencode/skills -maxdepth 2 -name SKILL.md \| wc -l` |
| Skill directories (excl. `_common/`, `_archived/`) | **123** | `ls -d opencode_app/.opencode/skills/*/ \| grep -v '_common\|_archived\|scripts' \| wc -l` |
| Agent .md files | **39** | `ls opencode_app/.opencode/agents/*.md \| wc -l` |
| Categories (setup.sh) | **21** | Counted from SKILLS banner listing |

**No `pptx-specialist-skill` (with `-skill` suffix) references remain** in active config (`opencode_app/.opencode/agents/`, `opencode_app/.opencode/skills/`, `opencode.json`). However, review found **bare `pptx-specialist` references (no suffix)** in 3 functional locations — see D8/D9/D10 below. The `pptx-specialist-skill` matches (with suffix) are all historical (PLAN docs, README migration note) — acceptable.

**Agent counts are consistent everywhere** at 39 — no drift.

**`opencode.json`** has no skill/agent references — no drift.

**`MIGRATION.md`** has no skill count references — no drift.

**`AGENTS.md`** and **`deploy/.AGENTS.md`** — no stale count references found.

## Dependency & Consumer Map

```
  README.md:26          ← fix skill directory count (122 → 123)
  opencode_app/README.md:26  ← fix skill directory count (121 → 123)
  README.md:329         ← states "21 categories" but only 19 listed — fix
  README.md:337         ← remove stale pptx-specialist from Framework
  README.md:333-355     ← add missing Presentation + Office Utilities rows
  README.md:339,346     ← reconcile deprecated-code-cleanup-skill placement
  README.md:400,402     ← fix stale pptx-specialist in Subagents table (D9/D10)
  startup-business-docs-skill/SKILL.md:382,397  ← fix functional pptx-specialist ref (D8)
  deploy/setup.sh       ← add csharp-linter-skill, java-linter-skill to Language-Specific
  deploy/setup.ps1      ← mirror setup.sh Language-Specific fix
```

## Drift Items Found (11 concrete items)

| # | File | Line(s) | Issue | Severity |
|---|------|---------|-------|----------|
| D1 | `README.md` | 26 | Directory tree says "122 skill directories" — actual is **123** | medium |
| D2 | `opencode_app/README.md` | 26 | Directory tree says "121 skill directories" — actual is **123** | medium |
| D3 | `README.md` | 337 | Framework (20) category contains stale `pptx-specialist` (removed skill) | high |
| D4 | `README.md` | 333-355 | Missing "Presentation (3)" and "Office Utilities (2)" category rows entirely | high |
| D5 | `README.md` | 329 | States "21 categories" but only 19 rows listed (D4 causes 2 missing) | medium |
| D6 | `README.md` | 339, 346 | `deprecated-code-cleanup-skill` in Framework-Specific (11) vs setup.sh Code Quality (8) — categorization mismatch | low |
| D7 | `deploy/setup.sh` + `deploy/setup.ps1` | Lang-Specific section | Language-Specific shows "(6)" — missing `csharp-linter-skill` and `java-linter-skill` (should be "(8)") | high |
| D8 | `startup-business-docs-skill/SKILL.md` | 382, 397 | **Functional** bare `pptx-specialist` reference in Integration table + References list — tells agents to use a deleted skill | high |
| D9 | `README.md` | 400 | Subagents table: `pptx-specialist-subagent` Skills column says `pptx-specialist` (stale — should reference the 3 chenyu skills or routing) | medium |
| D10 | `README.md` | 402 | Subagents table: `startup-ceo-subagent` Skills column says `pptx-specialist` (same staleness as D9) | medium |
| D11 | `vision-creation-skill/SKILL.md` | 3 | **Functional** bare `pptx-specialist` in skill description (used for routing) — discovered during Phase 4 verification; lines 40/170 already correct | medium |

## Phases

### Phase 1 — Fix directory tree skill counts (D1, D2)

- [x] **1.1** `README.md:26` — change `# 122 skill directories` → `# 123 skill directories`
  — **Why:** The directory tree annotation must match the actual SKILL.md count (123). Off-by-1 drift from BT-142 addition of 2 new skills and decomposition math.
  — **Done when:** `grep '# 123 skill directories' README.md` returns 1 match.
  — **Consumers affected:** Users reading the repo structure overview

- [x] **1.2** `opencode_app/README.md:26` — change `# 121 skill directories` → `# 123 skill directories`
  — **Why:** Same drift but more severe (off-by-2). The Docker README was apparently not updated during the BT-142 merge.
  — **Done when:** `grep '# 123 skill directories' opencode_app/README.md` returns 1 match.
  — **Consumers affected:** Docker/deploy users reading the opencode_app README

### Phase 2 — Fix README.md tables + stale `pptx-specialist` references (D3, D4, D5, D6, D8, D9, D10)

- [x] **2.1** Remove stale `pptx-specialist` from Framework (20) row in `README.md:337`
  — **Why:** `pptx-specialist-skill` was deleted in BT-142. It must not appear in any active skill listing. Replace with the correct categorization.
  — **Done when:** `grep 'pptx-specialist' README.md` returns only: (a) migration note at line 331 (historical — acceptable), and (b) Subagents table entries at lines 400/402 (fixed by D9/D10 in Phase 2.7/2.8).
  — **Consumers affected:** Users scanning the Skill Categories table for PPTX-related skills

- [x] **2.2** Add "Presentation (3)" category row to `README.md` Skill Categories table (after Framework, before Language-Specific)
  — **Why:** The 3 chenyu skills (`pptx-generate-slide-skill`, `pptx-generate-template-skill`, `pptx-template-modifier-skill`) are missing from the README table entirely. They exist in setup.sh/setup.ps1.
  — **Done when:** README contains a `| **Presentation** (3) | pptx-generate-slide-skill, pptx-generate-template-skill, pptx-template-modifier-skill | Template-driven PowerPoint generation — extract, fill, extend |` row.
  — **Consumers affected:** Users looking for PPTX skills in the README table

- [x] **2.3** Add "Office Utilities (2)" category row to `README.md` Skill Categories table (after Presentation)
  — **Why:** `ooxml-editing-skill` and `office-thumbnail-skill` are missing from the README table. They exist in setup.sh/setup.ps1.
  — **Done when:** README contains a `| **Office Utilities** (2) | ooxml-editing-skill, office-thumbnail-skill | Generic Office OOXML surgical edits and visual thumbnail/conversion |` row.
  — **Consumers affected:** Users looking for Office utility skills in the README table

- [x] **2.4** Recalculate Framework (20) → Framework (19) after removing `pptx-specialist`
  — **Why:** With `pptx-specialist` removed and 2 new categories added (Presentation 3 + Office Utilities 2), the Framework count drops from 20 to 19, and the total category count increases from 19 to 21. The prose "21 categories" at line 329 will become correct again.
  — **Done when:** Framework row header reads `| **Framework** (19) |` and `grep 'categor' README.md` still shows "21 categories" at line 329 (now accurate with 21 rows).
  — **Consumers affected:** All category count references

- [x] **2.5** Reconcile `deprecated-code-cleanup-skill` categorization — decide: Framework-Specific (README) or Code Quality (setup.sh)
  — **Why:** README has this skill under Framework-Specific (11) while setup.sh has it under Code Quality (8). Must pick one canonical placement and align both files. Recommendation: **Code Quality (8)** (matches setup.sh/setup.ps1 — the skill is about detecting and removing @deprecated code, which is fundamentally code quality).
  — **Done when:** Either (a) README moves `deprecated-code-cleanup-skill` to Code Quality and adjusts Framework-Specific (11→10) + Code Quality (7→8), OR (b) setup.sh/setup.ps1 moves it to Framework-Specific. Document the decision in a comment.
  — **Consumers affected:** setup.sh, setup.ps1, README.md category tables

- [x] **2.6** Fix functional `pptx-specialist` reference in `startup-business-docs-skill/SKILL.md` (D8)
  — **Why:** Lines 382 (`| pptx-specialist | Primary skill for general presentations |`) and 397 (`- pptx-specialist - PowerPoint presentation creation`) tell agents to use a deleted skill. These are in an active Integration table and References list — functional routing, not historical docs. The correct reference is `pptx-specialist-subagent` (the surviving orchestrator).
  — **Done when:** `grep 'pptx-specialist' opencode_app/.opencode/skills/startup-business-docs-skill/SKILL.md` returns zero matches (or only `pptx-specialist-subagent` references).
  — **Consumers affected:** `startup-business-docs-skill` execution (any startup/business doc workflow that routes to PPTX)

- [x] **2.7** Fix stale `pptx-specialist` in `README.md` Subagents table for `pptx-specialist-subagent` (D9)
  — **Why:** Line 400 (`| **pptx-specialist-subagent** | ... | pptx-specialist | — |`) lists `pptx-specialist` as the subagent's skill. That skill no longer exists — the subagent now routes to `pptx-generate-slide-skill` / `pptx-generate-template-skill` / `pptx-template-modifier-skill`.
  — **Done when:** README.md line ~400 Skills column reads `pptx-generate-slide, pptx-generate-template, pptx-template-modifier` (or equivalent).
  — **Consumers affected:** Users reading the Subagents table for PPTX routing

- [x] **2.8** Fix stale `pptx-specialist` in `README.md` Subagents table for `startup-ceo-subagent` (D10)
  — **Why:** Line 402 (`| **startup-ceo-subagent** | ... | pptx-specialist | — |`) has the same staleness as D9. The subagent delegates to `pptx-specialist-subagent` (which routes to the chenyu skills).
  — **Done when:** README.md line ~402 Skills column reads `pptx-specialist-subagent` (or `pptx-generate-slide, pptx-generate-template, pptx-template-modifier`).
  — **Consumers affected:** Users reading the Subagents table for startup presentation routing

### Phase 3 — Fix setup.sh and setup.ps1 listing (D7)

- [x] **3.1** `deploy/setup.sh` — add `csharp-linter-skill, java-linter-skill` to Language-Specific section; change "(6)" → "(8)"
  — **Why:** Both `csharp-linter-skill` and `java-linter-skill` exist as real SKILL.md directories but are absent from the setup.sh listing. They ARE listed in README.md Language-Specific (8). The listing must be complete.
  — **Done when:** `grep 'csharp-linter' deploy/setup.sh` returns a match in the Language-Specific section; `grep 'Language-Specific (8)' deploy/setup.sh` returns 1 match.
  — **Consumers affected:** `--list-skills` output in setup.sh banner

- [x] **3.2** `deploy/setup.ps1` — mirror setup.sh change: add `csharp-linter-skill, java-linter-skill` to Language-Specific; change "(6)" → "(8)"
  — **Why:** Windows parity — repo AGENTS.md mandates setup.ps1 mirrors setup.sh.
  — **Done when:** `grep 'csharp-linter' deploy/setup.ps1` returns a match in the Language-Specific section; `grep 'Language-Specific (8)' deploy/setup.ps1` returns 1 match.
  — **Consumers affected:** Windows `--list-skills` output in setup.ps1 banner

- [x] **3.3** Update any summary/quick-count lines in setup.sh and setup.ps1 that reference Language-Specific count
  — **Why:** setup.ps1 has echo lines like `Write-Host "Framework (19) • Language-Specific (6)..."` that must be updated to "(8)".
  — **Done when:** `grep -n 'Language-Specific (6)' deploy/setup.sh deploy/setup.ps1` returns zero matches.
  — **Consumers affected:** Status output in both scripts

### Phase 4 — Verification

- [x] **4.1** Re-run authoritative counts and compare to all stated counts
  — **Why:** Final gate — ensures all fixes are applied and no new drift introduced.
  — **Done when:**
    - `find opencode_app/.opencode/skills -maxdepth 2 -name SKILL.md | wc -l` = 123
    - `ls opencode_app/.opencode/agents/*.md | wc -l` = 39
    - `grep '# 123 skill directories' README.md opencode_app/README.md` = 2 matches
    - `grep 'pptx-specialist' README.md` returns only the migration note (line 331) — lines 400/402 fixed by D9/D10
    - `grep -rn 'pptx-specialist' opencode_app/.opencode/skills/startup-business-docs-skill/SKILL.md` returns zero matches (D8 fixed)
    - `grep 'Language-Specific (8)' deploy/setup.sh deploy/setup.ps1` = 2 matches
    - README.md Skill Categories table has 21 rows
    - Every category's stated count matches the number of items in that row
    - Category counts sum to 123
  — **Consumers affected:** CI verification, future audits

- [x] **4.2** Grep for stale `pptx-specialist` references repo-wide (both `-skill` suffix and bare)
  — **Why:** Belt-and-suspenders check that the removed skill has no functional references. Must check BOTH `pptx-specialist-skill` (old name with suffix) AND bare `pptx-specialist` (D8/D9/D10 use the bare form).
  — **Done when:**
    - `grep -rn 'pptx-specialist-skill' opencode_app/.opencode/ deploy/setup.sh deploy/setup.ps1 README.md opencode_app/README.md AGENTS.md deploy/.AGENTS.md` returns zero matches.
    - `grep -rn 'pptx-specialist[^-]' opencode_app/.opencode/skills/ opencode_app/.opencode/agents/ deploy/setup.sh deploy/setup.ps1 README.md` returns zero matches (bare `pptx-specialist` not followed by `-subagent` or `-skill` — historical PLAN docs and README migration note excluded from scope).
  — **Consumers affected:** All consumers of PPTX skill routing

## Acceptance Criteria

- [x] Count of `SKILL.md` files under `opencode_app/.opencode/skills/` matches every stated skill count in setup.sh, setup.ps1, README.md, opencode_app/README.md, and AGENTS.md.
- [x] Count of `*.md` files under `opencode_app/.opencode/agents/` matches every stated subagent count in the same files.
- [x] Every skill name appearing in setup.sh / setup.ps1 listing sections exists as a real `SKILL.md` directory (no orphans, no missing).
- [x] Every subagent name in README/AGENTS routing tables exists as a real `agents/*.md` file.
- [x] No **functional** references to the removed `pptx-specialist-skill` (or bare `pptx-specialist` used as a skill name) remain in active config files (`opencode_app/.opencode/`, `deploy/`, `README.md`, `opencode_app/README.md`, `AGENTS.md`, `deploy/.AGENTS.md`). Historical references in `PLANS/` docs and the README migration note (line 331) are explicitly acceptable.
- [x] Category groupings in setup.sh/setup.ps1/README all agree and sum to the total skill count.
- [x] `opencode.json` has no stale skill/MCP/agent references tied to the BT-142 rename.
- [x] If any inconsistency is found and fixed, the fixes are committed on a dedicated branch and a PLAN file is created. If everything is already consistent, close the ticket with a comment documenting the verification.

## References

- **Epic:** [BT-142](https://betekk.atlassian.net/browse/BT-142) — Migrate pptx-specialist-* to chenyu JSON-in-PPTX architecture
- **PR:** #256
- **Merge commit:** `91a78d5`
- **PLAN:** `PLANS/PLAN-BT-142.md`
- **Release:** 4.0.0

## Completion Log

**All phases complete — 2026-07-21.**

- **Phase 1 ✓** (D1, D2): Directory tree counts fixed in README.md (122→123) and opencode_app/README.md (121→123).
- **Phase 2 ✓** (D3–D6, D8–D10): README Skill Categories table fixed — removed stale `pptx-specialist` from Framework (20→19), added Presentation (3) + Office Utilities (2) rows, moved `deprecated-code-cleanup-skill` from Framework-Specific (11→10) to Code Quality (7→8). Fixed functional `pptx-specialist` ref in `startup-business-docs-skill/SKILL.md` (D8) and stale Skills columns in README Subagents table (D9/D10).
- **Phase 3 ✓** (D7): Added `csharp-linter-skill` + `java-linter-skill` to Language-Specific (6→8) in setup.sh (3 locations) and setup.ps1 (3 locations).
- **Phase 4 ✓**: Verified — skills=123, agents=39, categories sum to 123, `bash -n deploy/setup.sh` clean, zero functional stale `pptx-specialist` refs.
- **D11 (bonus)**: During verification, found and fixed a functional `pptx-specialist` reference in `vision-creation-skill/SKILL.md:3` description (lines 40/170 were already correct). Not in original audit or review — caught by Phase 4.2 grep.

**Acceptance criteria:** all 8 satisfied. Remaining `pptx-specialist` (bare) matches are all acceptable: short agent display names in setup.sh/ps1 banner (convention) and illustrative mistake examples in `opencode-tooling-subagent.md`.
