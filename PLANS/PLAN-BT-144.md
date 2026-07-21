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

**No functional `pptx-specialist-skill` references remain** in active config (`opencode_app/.opencode/agents/`, `opencode_app/.opencode/skills/`, `opencode.json`). The 25 grep matches are all historical (PLAN docs, README migration note) — acceptable.

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
  deploy/setup.sh       ← add csharp-linter-skill, java-linter-skill to Language-Specific
  deploy/setup.ps1      ← mirror setup.sh Language-Specific fix
```

## Drift Items Found (7 concrete items)

| # | File | Line(s) | Issue | Severity |
|---|------|---------|-------|----------|
| D1 | `README.md` | 26 | Directory tree says "122 skill directories" — actual is **123** | medium |
| D2 | `opencode_app/README.md` | 26 | Directory tree says "121 skill directories" — actual is **123** | medium |
| D3 | `README.md` | 337 | Framework (20) category contains stale `pptx-specialist` (removed skill) | high |
| D4 | `README.md` | 333-355 | Missing "Presentation (3)" and "Office Utilities (2)" category rows entirely | high |
| D5 | `README.md` | 329 | States "21 categories" but only 19 rows listed (D4 causes 2 missing) | medium |
| D6 | `README.md` | 339, 346 | `deprecated-code-cleanup-skill` in Framework-Specific (11) vs setup.sh Code Quality (8) — categorization mismatch | low |
| D7 | `deploy/setup.sh` + `deploy/setup.ps1` | Lang-Specific section | Language-Specific shows "(6)" — missing `csharp-linter-skill` and `java-linter-skill` (should be "(8)") | high |

## Phases

### Phase 1 — Fix directory tree skill counts (D1, D2)

- [ ] **1.1** `README.md:26` — change `# 122 skill directories` → `# 123 skill directories`
  — **Why:** The directory tree annotation must match the actual SKILL.md count (123). Off-by-1 drift from BT-142 addition of 2 new skills and decomposition math.
  — **Done when:** `grep '# 123 skill directories' README.md` returns 1 match.
  — **Consumers affected:** Users reading the repo structure overview

- [ ] **1.2** `opencode_app/README.md:26` — change `# 121 skill directories` → `# 123 skill directories`
  — **Why:** Same drift but more severe (off-by-2). The Docker README was apparently not updated during the BT-142 merge.
  — **Done when:** `grep '# 123 skill directories' opencode_app/README.md` returns 1 match.
  — **Consumers affected:** Docker/deploy users reading the opencode_app README

### Phase 2 — Fix README.md Skill Categories table (D3, D4, D5, D6)

- [ ] **2.1** Remove stale `pptx-specialist` from Framework (20) row in `README.md:337`
  — **Why:** `pptx-specialist-skill` was deleted in BT-142. It must not appear in any active skill listing. Replace with the correct categorization.
  — **Done when:** `grep 'pptx-specialist' README.md` only returns the migration note at line 331 (historical reference — acceptable).
  — **Consumers affected:** Users scanning the Skill Categories table for PPTX-related skills

- [ ] **2.2** Add "Presentation (3)" category row to `README.md` Skill Categories table (after Framework, before Language-Specific)
  — **Why:** The 3 chenyu skills (`pptx-generate-slide-skill`, `pptx-generate-template-skill`, `pptx-template-modifier-skill`) are missing from the README table entirely. They exist in setup.sh/setup.ps1.
  — **Done when:** README contains a `| **Presentation** (3) | pptx-generate-slide-skill, pptx-generate-template-skill, pptx-template-modifier-skill | Template-driven PowerPoint generation — extract, fill, extend |` row.
  — **Consumers affected:** Users looking for PPTX skills in the README table

- [ ] **2.3** Add "Office Utilities (2)" category row to `README.md` Skill Categories table (after Presentation)
  — **Why:** `ooxml-editing-skill` and `office-thumbnail-skill` are missing from the README table. They exist in setup.sh/setup.ps1.
  — **Done when:** README contains a `| **Office Utilities** (2) | ooxml-editing-skill, office-thumbnail-skill | Generic Office OOXML surgical edits and visual thumbnail/conversion |` row.
  — **Consumers affected:** Users looking for Office utility skills in the README table

- [ ] **2.4** Recalculate Framework (20) → Framework (19) after removing `pptx-specialist`
  — **Why:** With `pptx-specialist` removed and 2 new categories added (Presentation 3 + Office Utilities 2), the Framework count drops from 20 to 19, and the total category count increases from 19 to 21. The prose "21 categories" at line 329 will become correct again.
  — **Done when:** Framework row header reads `| **Framework** (19) |` and `grep 'categor' README.md` still shows "21 categories" at line 329 (now accurate with 21 rows).
  — **Consumers affected:** All category count references

- [ ] **2.5** Reconcile `deprecated-code-cleanup-skill` categorization — decide: Framework-Specific (README) or Code Quality (setup.sh)
  — **Why:** README has this skill under Framework-Specific (11) while setup.sh has it under Code Quality (8). Must pick one canonical placement and align both files. Recommendation: **Code Quality (8)** (matches setup.sh/setup.ps1 — the skill is about detecting and removing @deprecated code, which is fundamentally code quality).
  — **Done when:** Either (a) README moves `deprecated-code-cleanup-skill` to Code Quality and adjusts Framework-Specific (11→10) + Code Quality (7→8), OR (b) setup.sh/setup.ps1 moves it to Framework-Specific. Document the decision in a comment.
  — **Consumers affected:** setup.sh, setup.ps1, README.md category tables

### Phase 3 — Fix setup.sh and setup.ps1 listing (D7)

- [ ] **3.1** `deploy/setup.sh` — add `csharp-linter-skill, java-linter-skill` to Language-Specific section; change "(6)" → "(8)"
  — **Why:** Both `csharp-linter-skill` and `java-linter-skill` exist as real SKILL.md directories but are absent from the setup.sh listing. They ARE listed in README.md Language-Specific (8). The listing must be complete.
  — **Done when:** `grep 'csharp-linter' deploy/setup.sh` returns a match in the Language-Specific section; `grep 'Language-Specific (8)' deploy/setup.sh` returns 1 match.
  — **Consumers affected:** `--list-skills` output in setup.sh banner

- [ ] **3.2** `deploy/setup.ps1` — mirror setup.sh change: add `csharp-linter-skill, java-linter-skill` to Language-Specific; change "(6)" → "(8)"
  — **Why:** Windows parity — repo AGENTS.md mandates setup.ps1 mirrors setup.sh.
  — **Done when:** `grep 'csharp-linter' deploy/setup.ps1` returns a match in the Language-Specific section; `grep 'Language-Specific (8)' deploy/setup.ps1` returns 1 match.
  — **Consumers affected:** Windows `--list-skills` output in setup.ps1 banner

- [ ] **3.3** Update any summary/quick-count lines in setup.sh and setup.ps1 that reference Language-Specific count
  — **Why:** setup.ps1 has echo lines like `Write-Host "Framework (19) • Language-Specific (6)..."` that must be updated to "(8)".
  — **Done when:** `grep -n 'Language-Specific (6)' deploy/setup.sh deploy/setup.ps1` returns zero matches.
  — **Consumers affected:** Status output in both scripts

### Phase 4 — Verification

- [ ] **4.1** Re-run authoritative counts and compare to all stated counts
  — **Why:** Final gate — ensures all fixes are applied and no new drift introduced.
  — **Done when:**
    - `find opencode_app/.opencode/skills -maxdepth 2 -name SKILL.md | wc -l` = 123
    - `ls opencode_app/.opencode/agents/*.md | wc -l` = 39
    - `grep '# 123 skill directories' README.md opencode_app/README.md` = 2 matches
    - `grep -c 'pptx-specialist' README.md` returns only the migration note (line 331)
    - `grep 'Language-Specific (8)' deploy/setup.sh deploy/setup.ps1` = 2 matches
    - README.md Skill Categories table has 21 rows
    - Every category's stated count matches the number of items in that row
    - Category counts sum to 123
  — **Consumers affected:** CI verification, future audits

- [ ] **4.2** Grep for stale `pptx-specialist-skill` repo-wide (excluding PLAN/historical docs)
  — **Why:** Belt-and-suspenders check that the removed skill has no functional references.
  — **Done when:** `grep -rn 'pptx-specialist-skill' opencode_app/.opencode/ deploy/setup.sh deploy/setup.ps1 README.md opencode_app/README.md AGENTS.md deploy/.AGENTS.md` returns zero matches.
  — **Consumers affected:** All consumers of PPTX skill routing

## Acceptance Criteria

- [ ] Count of `SKILL.md` files under `opencode_app/.opencode/skills/` matches every stated skill count in setup.sh, setup.ps1, README.md, opencode_app/README.md, and AGENTS.md.
- [ ] Count of `*.md` files under `opencode_app/.opencode/agents/` matches every stated subagent count in the same files.
- [ ] Every skill name appearing in setup.sh / setup.ps1 listing sections exists as a real `SKILL.md` directory (no orphans, no missing).
- [ ] Every subagent name in README/AGENTS routing tables exists as a real `agents/*.md` file.
- [ ] No references to the removed `pptx-specialist-skill` remain anywhere (grep the whole repo).
- [ ] Category groupings in setup.sh/setup.ps1/README all agree and sum to the total skill count.
- [ ] `opencode.json` has no stale skill/MCP/agent references tied to the BT-142 rename.
- [ ] If any inconsistency is found and fixed, the fixes are committed on a dedicated branch and a PLAN file is created. If everything is already consistent, close the ticket with a comment documenting the verification.

## References

- **Epic:** [BT-142](https://betekk.atlassian.net/browse/BT-142) — Migrate pptx-specialist-* to chenyu JSON-in-PPTX architecture
- **PR:** #256
- **Merge commit:** `91a78d5`
- **PLAN:** `PLANS/PLAN-BT-142.md`
- **Release:** 4.0.0
