# PLAN: Consolidate language reviewers + linter skills; slim agents via skills

**Issue:** https://github.com/darellchua2/opencode-config-template/issues/338
**Branch:** GIT-338 (PR base: `main`)
**Decisions (user-confirmed):**
1. **Merge 5 language reviewers → `language-reviewer-subagent`** (36→32 agents). Config identical across all 5 (mode: subagent, steps: 25, same permission shape); only `permission.skill` differs — merged takes the 15-skill union. Framework-Specific Checks tables stay **inline** (volatile ones keep their "verify current major version" tags: Next.js/React, Quarkus, Axum) — extraction loses on token math since the agent loads per review regardless. Merged agent KEEPS receiving ponytail/learnings injection (not added to plugin off-patterns).
2. **Merge 4 linter skills → `language-linting-skill`** (~550L vs 940L across 4), absorbing linting-subagent's 122L orphaned Java Spring Boot (50L) + C# .NET 10 (72L) sections, deduped against existing java/csharp linter content. Keeps "extends `linting-workflow` framework" declaration; `category: Language-Specific`; description preserves triggers (ruff, eslint, checkstyle, dotnet format).
3. **Slim 5 agents to thin-agent pattern** (~170L removed, zero knowledge loss): linting-subagent, responsive-audit-subagent, error-resolver-subagent, docx-creation-subagent, coverage-subagent — each gets a uiux-style source-of-truth pointer line.
4. **Release as breaking** (`feat!` commits → semantic-release major): `npx add python-reviewer-subagent` etc. vanish.

**Out of scope:** autoresearch-code flip (deliberate inverted design — agent is source of truth, skill is pointer), pptx-specialist snippets (invocation glue, not duplication), test-creator dedupe (framework pattern works; verbatim dup acknowledged but excluded), reviewers' framework tables (stay inline).

## Overview

Reviewer family = 8 agents / 1,732 lines with ~58 lines of word-identical boilerplate ×5 in the language reviewers (Prompt Defense, Epistemic Honesty, Consumer Gate opening, CodeGraph fallback, Web lookups, Return Contract, Output Format). Linter skills (python-ruff 199L + javascript-eslint 308L + java 250L + csharp 183L = 940L) share ~70% skeleton via the linting-workflow framework. Five agents embed knowledge duplicated in (or orphaned from) their paired skills. This PLAN delivers the merge + slim via 4 phases, each ending with registry regen (release.yml drift gate runs `build-registry.mjs --check` on PRs) and bats verification.

---

## Dependency & Consumer Map

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---|---|---|---|
| `opencode_app/.opencode/agents/language-reviewer-subagent.md` (new) | nothing (content from 5 source files) | code-review-subagent delegation; nextjs-specialist:104; pack-review/pack-backend presets; agent-tiers.json; setup.sh/ps1 help; README tables; registry.json (regen); init.bats closures | high — frontmatter malformed = agent fails to load; breaking name change |
| `code-review-subagent.md` task+routing edits | merged agent exists | primary sessions routing reviews; init resolver (delegatesTo); init.bats counts | med |
| `language-linting-skill/` (new) | nothing | linting-subagent allowlist+body; opencode.json:113-114; pack-review:27; README 563/602/726; registry.json; merged reviewer's allowlist (java-linter-skill → language-linting-skill) | high — breaking skill name change; category must stay Language-Specific |
| linting-subagent slim | language-linting-skill exists (Phase 2) | lint invocations; registry regen | med — 122L moves, java-linter allowlist gap normalized |
| 4× agent slim (responsive-audit/error-resolver/docx-creation/coverage) | paired skills verified to contain the knowledge | agent quality (no behavior change — skills already in allowlists) | low — deletion only where verbatim dup confirmed |
| `deploy/registry.json` | regenerated after EVERY frontmatter/file change (Phases 1-3) | release.yml drift gate; init.mjs --list/--expand; docs/registry.json refresh | high — frontmatter change without regen = red CI |
| `tests/init.bats` | Phase 1+2 land | CI | med — counts 7→3, 8→4; skill count 25 must hold (pack-review swaps java-linter for language-linting) |

---

## Implementation Phases

### Phase 1: Merge 5 language reviewers → `language-reviewer-subagent`

- [x] **1.1** Create `opencode_app/.opencode/agents/language-reviewer-subagent.md` (~600L): frontmatter = `description` (preserve trigger phrases from all 5, ≤50 words), `mode: subagent`, `category: review`, `steps: 25`; permissions = read `("*": allow, "mcp:*": deny)`, glob/grep/webfetch/websearch allow, edit deny, bash deny, task `("*": deny, explore: allow, general: allow)`, skill = 15-union (solid-principles, clean-code, code-smells, design-patterns, python-backend, fastapi-pydantic-orm-patterns, database-migration, python-packaging, react-hooks-antipatterns, react-render-antipatterns, typescript-dry-principle, java-linter→language-linting-skill after Phase 2, deprecated-code-cleanup, continuous-learning, search-first — all `-skill` suffixed). Body: shared skeleton ONCE (Prompt Defense, Epistemic Honesty, Consumer Coverage Gate opening w/ per-language grep patterns, CodeGraph fallback, Web lookups, Return Contract w/ reviewer Patterns field, Output Format with `{Language}` placeholder) → language-detection dispatch table (absorbed from code-review-subagent:260-264) → five per-language checklist sections (Go 49L, Java 80L, Python 47L+backend-patterns refs, Rust 51L, TS 52L+react/DRY refs) with Framework-Specific Checks tables inline (keep version-verify tags) → unified severity table.
    — **Why:** 933L/48KB ×5 files → ~600L/30KB ×1; identical config means zero behavioral loss; registry embeds frontmatter verbatim so this must land complete
    — **Done when:** file parses as valid YAML frontmatter; `node deploy/build-registry.mjs` lists it with 15 skills; agent description retains trigger phrases; all 5 checklists + 5 framework tables present
    — **Consumers affected:** code-review-subagent routing, presets, tiers, docs, tests
    — **Done:** Created 536L merged agent (5 checklists + 5 framework tables w/ version-verify tags + per-language grep patterns + unified severity table + Language Detection & Scope table + Java Linting pointer for java-linter-skill); files: opencode_app/.opencode/agents/language-reviewer-subagent.md; fixes: none

- [x] **1.2** Update referencers: `code-review-subagent.md` frontmatter task lines 23-27 → single `language-reviewer-subagent: allow`; routing table 260-264 → single delegation row. `nextjs-specialist-subagent.md:104` rename. `deploy/agent-tiers.json`: remove lines 7/8/12/16/19, add `"language-reviewer-subagent": "reasoning"`. `deploy/presets/pack-review.json`: agents 7→3 (description line 4 drop "5 language reviewers"); `pack-backend.json:6` swap. `deploy/setup.sh:656-660` → 1 help line; `deploy/setup.ps1:963-967` → 1. `README.md`: 587 count 36→32, 630-634 → 1 row, 252 preset table `python-reviewer` → `language-reviewer`.
    — **Why:** broken references = dead delegation links and wrong CLI surfaces; presets hand-edited (gen-presets.mjs is /tmp-ephemeral, not committed)
    — **Done when:** `rg "python-reviewer|typescript-reviewer|go-reviewer|rust-reviewer|java-reviewer"` returns only historical/CHANGELOG/PLANS hits
    — **Consumers affected:** deploy flow, init CLI, docs
    — **Done:** All referencers updated: code-review-subagent task block (5→1) + delegation section rewritten; nextjs-specialist:104 renamed; agent-tiers.json 5 entries→1 (reasoning); pack-review 7→3 agents + description; pack-backend swap; setup.sh+setup.ps1 5 help lines→1; README count 36→32, 5 table rows→1 merged row, preset table review/backend rows; files: opencode_app/.opencode/agents/code-review-subagent.md, opencode_app/.opencode/agents/nextjs-specialist-subagent.md, deploy/agent-tiers.json, deploy/presets/pack-review.json, deploy/presets/pack-backend.json, deploy/setup.sh, deploy/setup.ps1, README.md; fixes: none

- [x] **1.3** Delete the 5 reviewer files; `node deploy/build-registry.mjs`; update `tests/init.bats` line 41 `7`→`3`, lines 74/83/113 `8`→`4`; run full bats suite.
    — **Why:** registry drift gate + count assertions are the safety net
    — **Done when:** `build-registry.mjs --check` passes; registry counts agents=32; bats green
    — **Consumers affected:** CI, init CLI
    — **Done:** Deleted 5 reviewer .md files; registry regenerated (agents=32, skills=130, --check OK; language-reviewer requiresSkills=15); init.bats updated: category review 7→3, expand/install/idempotent/prune 8→4, --describe delegates threshold 5→4 (code-review now delegates to 4); bats 304/304 green; files: opencode_app/.opencode/agents/{python,typescript,go,rust,java}-reviewer-subagent.md (deleted), deploy/registry.json, tests/init.bats; fixes: delegates -ge 5 → -ge 4 (registry fixture showed delegates=4 after merge)

- [x] **1.4** Commit `feat(agents)!: merge language reviewers into language-reviewer-subagent` (atomic: agent file + referencers + registry + tests in one commit).
    — **Done:** Committed + pushed with PLAN Phase 1 traceability; see git log on branch GIT-338.

### Phase 2: Merge 4 linter skills → `language-linting-skill`

- [x] **2.1** Create `opencode_app/.opencode/skills/language-linting-skill/SKILL.md` (~550L): frontmatter = name=dirname, `description` ≤50 words preserving triggers (ruff, eslint, checkstyle, dotnet format, lint), `license: Apache-2.0`, `compatibility: opencode`, `category: Language-Specific`. Body: shared skeleton once (env detect, "extends `linting-workflow` framework" declaration, delegate-to-workflow 7 bullets, 5-field error-resolution template, troubleshooting Before/After) → per-language sections (Ruff config detection, ESLint flat config, Checkstyle/SpotBugs/PMD `mvn` commands, `dotnet format` + StyleCop/Roslyn XML + .editorconfig) — merging linting-subagent's orphaned Java Spring Boot (50L) + C# .NET 10 (72L) content, deduped against the 4 source skills.
    — **Why:** 940L ×4 → ~550L ×1; orphan absorption removes the agent-embedded knowledge with no skill partner; category Language-Specific keeps installer registry grouping
    — **Done when:** SKILL.md conforms to frontmatter contract; registry lists it; triggers grep-able in description
    — **Consumers affected:** linting-subagent, merged reviewer allowlist, opencode.json, presets
    — **Done:** Created 569L SKILL.md (940L×4 → 569L×1, −39%); absorbed linting-subagent's Spring Boot checks (5 bullets), Spring rules, .NET 10 checks, spring-javaformat/mvnd commands into Java/C# sections; replaced broken vibeguard-masked version string (java-linter-skill line 176 `4.8.6.0`, corrupted since 3f368a4) with `<verify-latest>` placeholder per secret-hygiene rules; files: opencode_app/.opencode/skills/language-linting-skill/SKILL.md; fixes: none

- [x] **2.2** Update referencers: `linting-subagent.md` frontmatter 22-25 → 1 allow + body 49-50/258 rename. `opencode.json:113-114` → single `"language-linting-skill": "allow"`. `pack-review.json:27` swap (skill count stays 25 → bats:85 unchanged). `README.md:563` Language-Specific 9→6, `602` linting row, `726` tree. Merged reviewer allowlist: `java-linter-skill` → `language-linting-skill`. Delete 4 skill dirs; `node deploy/build-registry.mjs`; bats full suite.
    — **Done when:** `rg "python-ruff-linter|javascript-eslint-linter|csharp-linter|java-linter"` clean (excl. historical); registry counts skills=127; bats green incl. line 85 `25`
    — **Consumers affected:** CI, init CLI, lean/full profiles (none of the 5 in lean — verified no skill-profiles.json edit needed)
    — **Done:** linting-subagent frontmatter 3 linter allows → language-linting-skill + body tool list (49-53) + workflow step 2 renamed; opencode.json csharp+java entries → 1; pack-review.json:23 swap; README 563 (9→6), 602 linting row, 630 reviewer row, 722 tree (line drift: tree box is 722 not 726 post-Phase-1); language-reviewer-subagent allowlist + Java Linting pointer; deleted 4 skill dirs; registry regen agents=32 skills=127 no drift; rg sweep clean; bats 304/304; files: linting-subagent.md, opencode.json, pack-review.json, README.md, language-reviewer-subagent.md, 4 deleted dirs, deploy/registry.json; fixes: none

- [x] **2.3** Commit `feat(skills)!: merge per-language linter skills into language-linting-skill`.
    — **Done:** Committed + pushed with Phase 2 traceability in this commit.

### Phase 3: Agent slimming (thin-agent pattern)

- [x] **3.1** `linting-subagent.md`: delete `## Java Spring Boot Linting` + `## C# .NET 10 Linting` (76-197; content absorbed in 2.1); add pointer line: "Loaded skill: `language-linting-skill` — the source of truth for per-language linting rules, configs, and commands; this subagent orchestrates detection and workflow." Regenerate registry (skills unchanged — description/skill-list edits only if frontmatter touched).
    — **Done:** Deleted both sections (280→163 lines, −117); added uiux-style "Loaded skill" pointer; registry check no drift (frontmatter untouched); files: linting-subagent.md; fixes: none

- [x] **3.2** `responsive-audit-subagent.md`: delete 6 detection assertions + 3-tier table + Tailwind fix examples (~79-103, 23L — verbatim dup in playwright-responsive-audit-skill:780L); add source-of-truth pointer; keep PTY model, screenshot delegation, return contract.
    — **Done:** Assertion list → pointer w/ assertion names; tier table → tier-name pointer (Tier 1/2/3 semantics kept — Return Contract references them); Tier 1 examples dropped, tier actions kept (188→179 lines); PTY/screenshot/return-contract untouched; files: responsive-audit-subagent.md; fixes: none

- [x] **3.3** `error-resolver-subagent.md`: delete 5-step workflow detail (58-67 — verbatim dup in error-resolver-workflow-skill); add pointer; keep trigger phrases, multimodal note, ponytail lens.
    — **Done:** 5-step list → pointer to error-resolver-workflow-skill as source of truth (119→113 lines); trigger phrases/multimodal note/ponytail lens untouched; files: error-resolver-subagent.md; fixes: none

- [x] **3.4** `docx-creation-subagent.md`: delete Critical Rules (69-74 — dup in docx-creation-skill); add pointer.
    — **Done:** 5 docx-js rule bullets → 1 pointer line (99→96 lines); files: docx-creation-subagent.md; fixes: none

- [x] **3.5** `coverage-subagent.md`: delete badge color table (53-57 — dup in coverage-readme-workflow-skill); add pointer.
    — **Done:** 4-line badge table → 1 pointer line w/ thresholds preserved inline (94→91 lines); files: coverage-subagent.md; fixes: none
    — **Why (3.1-3.5):** repo pattern is thin-agent + fat-skill (uiux-reviewer exemplar); ~170L removed, zero knowledge loss (all content verified present in paired skills)
    — **Done when:** each slimmed agent retains routing/workflow/return-contract; paired skill contains the deleted knowledge; registry + bats green
    — **Consumers affected:** agent token footprint only (no wiring changes — skills already in allowlists)
    — **Gate:** registry --check OK (agents=32, skills=127, no drift); bats 304/304; total −138L across 5 agents

- [x] **3.6** Commit `refactor(agents): extract duplicated agent knowledge into skills`.
    — **Done:** Committed + pushed with Phase 3 traceability in this commit.

### Phase 4: Regen, verify, release

- [x] **4.1** Refresh stale `docs/registry.json` (currently 129 vs 130 — pre-existing drift) via build-site.mjs or documented regen path.
    — **Done:** `node deploy/build-site.mjs` rebuilt docs/index.html (32 agents, 127 skills) + docs/registry.json; discovered both are gitignored build artifacts (.gitignore:35-36) so the "stale" file was a local artifact, never committed — no commit needed; fixes: none

- [x] **4.2** Doc-sync sweep: counts/listings across setup.sh/ps1, README.md (agents 32, Language-Specific 6), opencode_app/README.md if affected; invoke `documentation-sync-workflow-skill` checklist or delegate to opencode-tooling-subagent.
    — **Done:** README 26 (36→32 agents), 27 (130→127 skills), 241, 399, 550, 554 (appended GIT-338 ledger entry → 127); opencode_app/README 25-26 (32/127), 185 (24/36 → 22/32 task-perm stat, counted from disk); setup.sh/ps1 need nothing (dynamic counts, listing already updated Phase 1); no stale reviewer/linter names anywhere in hand-maintained docs; files: README.md, opencode_app/README.md; fixes: none

- [x] **4.3** Full verification: `node deploy/build-registry.mjs --check`; full bats suite; `bash -n deploy/setup.sh`; commit docs `docs: sync counts after reviewer/linter consolidation`.
    — **Done:** build-registry --check OK (agents=32, skills=127, no drift); bats 304/304; bash -n OK; deploy/ sweep for deleted skill names clean (skill-profiles.json + dependency-map.json untouched, as planned); fixes: none
- [x] **4.4** Push GIT-338; open PR to main (base) referencing #338; note breaking-change major bump expectation in PR body (two `feat!` commits).
    — **Done:** PR #339 opened (base main, closes #338) with breaking-change section calling out the two feat! commits and removed `npx add` names; branch fully pushed; fixes: none

---

## Verification Gates (per AGENTS.md)

- Lint/typecheck: `bash -n deploy/setup.sh` (shell), `node deploy/build-registry.mjs --check` (frontmatter + drift), JSON validity via node (agent-tiers, presets, opencode.json — no `//` comments, see LEARNINGS anti-pattern)
- Tests: `bats tests/` (init.bats + skill_profiles.bats; jq absent locally — bats files use node one-liners already)
- Build: no deps/config entry-point changes beyond opencode.json skill keys — `node deploy/init.mjs --list agents` smoke
