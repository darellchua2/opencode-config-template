**Issue**: #297
**Title**: Remediate verified opencode-config drift (skill-count, category table, deprecated `tools:` block)
**Branch**: `fix/297-audit-remediation`
**Status**: Open

> **Provenance note.** This PLAN supersedes the initial audit report that informed issue #297. A re-audit (grounded in verbatim command output) refuted 4 of the original 5 items: `zai-vision-analysis-skill` was already retired; the agent count is genuinely 39 (not 38); the fabricated `deploy/agent-tiers.json` and "long-context tier" do not exist; and `pptx-specialist` is correctly on `glm-5-turbo`. Only the `tools:` block survived. The re-audit additionally surfaced real skill-count drift (113→115) and a category table that omits 3 skills — those are the primary work here.

## Dependency & Consumer Map

| Node (file) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|--------------|---------------------------|---------------------------------|-------------|
| `README.md` (counts + category table) | Verified disk inventory (115 skills) | Repo consumers, onboarding, `setup.sh`/`setup.ps1` parity | low — docs only |
| `deploy/setup.sh:586` | Disk inventory | User-space deployments (banner counts) | low |
| `deploy/setup.ps1:382` | Disk inventory | Windows user deployments (banner counts) | low |
| `opencode_app/opencode.json` (`tools:` → `permission`) | opencode v1.1.1+ deprecation (confirmed via opencode.ai/docs/permissions) | Ships to every user deploy; Docker standalone | medium — shipped config template, must preserve behavior |
| `AGENTS.md` (tier table) | `responsive-audit-subagent.md` model frontmatter (`glm-5.1`) | Repo conventions doc | low — cosmetic listing |

## Ground Truth (measured, reproducible)

- Agent count: `ls opencode_app/.opencode/agents/*.md | wc -l` → **39** (docs already correct — no agent-count work).
- Skill count: `ls -d opencode_app/.opencode/skills/*/ | grep -vE "_archived|_common" | wc -l` → **115** (docs say 113 — drift).
- README category table parentheticals sum to **112**; 3 skills on disk are absent from the table:
  - `deprecated-code-cleanup-skill` → Code Quality category
  - `pptx-generate-slide-skill` → Framework category (pptx pipeline)
  - `pptx-template-modifier-skill` → Framework category (pptx pipeline)
- Category rows: 18 (prose says "17 categories" — drift).
- `opencode_app/opencode.json:245` opens a top-level `"tools": {` block (booleans) — deprecated per https://opencode.ai/docs/permissions/ ("As of v1.1.1, the legacy `tools` boolean config is deprecated and has been merged into `permission`").
- `responsive-audit-subagent.md:4` → `model: zai-coding-plan/glm-5.1`; `AGENTS.md:34` (glm-5.1 tier row) does not name it.

## Implementation Phases

### Phase 1: Fix skill-count drift (113 → 115)

- [ ] **1.1** `README.md:24` — `# 113 skill directories` → `# 115 skill directories`
    — **Why:** Onboarding file-tree comment; must match disk so contributors trust it.
    — **Done when:** `grep -n "113 skill" README.md` exits 1 (zero matches); `grep -n "115 skill" README.md` shows the new value.
    — **Consumers affected:** All repo readers.
- [ ] **1.2** `README.md:280` — `with 113 skills organized across 17 categories` → `with 115 skills organized across 18 categories`
    — **Why:** Prose summary of the modularization section; both numbers drifted (skills +2 net, categories +1).
    — **Done when:** `grep -nE "113 skills|17 categories" README.md` exits 1; `grep -nE "115 skills|18 categories" README.md` shows the new values.
    — **Consumers affected:** All repo readers.
- [ ] **1.3** `deploy/setup.sh:586` — `SKILLS (113):` → `SKILLS (115):`
    — **Why:** Deploy banner ships a stale count to every user running `setup.sh`.
    — **Done when:** `grep -nE "SKILLS \(113\)" deploy/setup.sh` exits 1; `grep -nE "SKILLS \(115\)" deploy/setup.sh` shows the new value.
    — **Consumers affected:** All user-space deployments via `deploy/setup.sh`.
- [ ] **1.4** `deploy/setup.ps1:382` — `SKILLS (113):` → `SKILLS (115):`
    — **Why:** Windows parity with setup.sh — stale count breaks the PowerShell banner.
    — **Done when:** `grep -nE "SKILLS \(113\)" deploy/setup.ps1` exits 1; `grep -nE "SKILLS \(115\)" deploy/setup.ps1` shows the new value.
    — **Consumers affected:** All Windows users running `deploy/setup.ps1`.

### Phase 2: Reconcile README category table (add 3 missing skills)

- [ ] **2.1** `README.md:286` (Framework row) — append `pptx-generate-slide-skill, pptx-template-modifier-skill` to the skill list; bump `(20)` → `(22)`
    — **Why:** Both are part of the pptx-specialist 3-skill pipeline (generate-slide → template-modifier → specialist) and belong with `pptx-specialist` already in this row. Currently absent from the table entirely.
    — **Done when:** Row lists all original 20 + the 2 new skills; parenthetical reads `(22)`; the 2 skill names appear in the row.
    — **Consumers affected:** Repo readers discovering the pptx pipeline.
- [ ] **2.2** `README.md:294` (Code Quality row) — append `deprecated-code-cleanup-skill` to the skill list; bump `(7)` → `(8)`
    — **Why:** `deprecated-code-cleanup-skill` (TypeScript @deprecated dependency-traced removal) fits the Code Quality category (solid-principles, clean-code, code-smells). Currently absent from the table.
    — **Done when:** Row lists all original 7 + the new skill; parenthetical reads `(8)`.
    — **Consumers affected:** Repo readers discovering cleanup tooling.
- [ ] **2.3** Verify the category table parentheticals now sum to 115
    — **Why:** Atomicity gate — the whole point is that table-count == disk-count (115).
    — **Done when:** Sum of all 18 rows' parentheticals equals 115 (recompute manually or via `grep -oE "\([0-9]+\)"` on the table lines and sum). Cross-check: `ls -d opencode_app/.opencode/skills/*/ | grep -vE "_archived|_common" | wc -l` → 115.
    — **Consumers affected:** All downstream consumers — this is the release quality gate for the table.

### Phase 3: Migrate deprecated `tools:` block to `permission`

- [ ] **3.1** `opencode_app/opencode.json:245-271` — convert the top-level `"tools": { ... }` boolean block into a top-level `"permission": { ... }` block, mapping `true` → `"allow"`, `false` → `"deny"` (key-for-key)
    — **Why:** The `tools` boolean config is deprecated as of opencode v1.1.1 (confirmed: https://opencode.ai/docs/permissions/ — "the legacy `tools` boolean config is deprecated and has been merged into `permission`"). This repo is a **configurator** — the template ships to every user deploy, so it should model current syntax. Behavior is preserved (the docs state the merge is equivalent).
    — **Done when:** (a) `grep -n '"tools"' opencode_app/opencode.json` exits 1 (no top-level `tools` key); (b) a top-level `"permission"` object exists containing all 25 former keys with `allow`/`deny` string values; (c) `python3 -c "import json; json.load(open('opencode_app/opencode.json'))"` exits 0 (valid JSON).
    — **Consumers affected:** Every user deploy + Docker standalone (shipped config template).
    — **Note:** Verify no top-level `permission` key already exists before adding (re-audit confirmed it does not — top keys are `$schema, model, default_agent, plugin, command, instructions, provider, mcp, tools, agent`). If a `permission` key is introduced elsewhere later, merge rather than duplicate.
- [ ] **3.2** Spot-check that the 4 `allow` entries (`codegraph*`, `atlassian*`, `mermaid*`, `zai-web-reader*`) and the 21 `deny` entries map 1:1
    — **Why:** Prevents accidental semantic drift during migration (e.g. flipping a value).
    — **Done when:** Count of `"allow"` values == 4 and `"deny"` values == 21 in the new `permission` block; the keys match the former `tools` block exactly.
    — **Consumers affected:** MCP server availability at runtime.

### Phase 4: Add responsive-audit to tier table (cosmetic)

- [ ] **4.1** `AGENTS.md:34` (glm-5.1 tier row) — add `responsive-audit` to the comma-separated agent list
    — **Why:** `responsive-audit-subagent.md:4` declares `model: zai-coding-plan/glm-5.1`, but the tier table omits it. Tier choice is correct (sound-reasoning Playwright audit); only the listing is incomplete.
    — **Done when:** `responsive-audit` appears in the glm-5.1 row; `grep -n "responsive-audit" AGENTS.md` returns ≥1 match.
    — **Consumers affected:** Repo readers consulting tier assignments.

### Phase 5: Verification Gate

- [ ] **5.1** Skill-count consistency sweep — no stale `113` remains anywhere:
    ```bash
    grep -rnE "113 skill|SKILLS \(113\)|17 categories" README.md deploy/setup.sh deploy/setup.ps1
    ```
    — **Done when:** Exits 1 (zero matches).
    — **Consumers affected:** All downstream — release quality gate.
- [ ] **5.2** Category-table sum == disk count:
    ```bash
    ls -d opencode_app/.opencode/skills/*/ | grep -vE "_archived|_common" | wc -l   # must be 115
    ```
    Manually sum the 18 row parentheticals — must equal 115.
    — **Done when:** Both equal 115.
- [ ] **5.3** opencode.json valid + tools block gone:
    ```bash
    python3 -c "import json; json.load(open('opencode_app/opencode.json'))" && echo VALID
    grep -n '"tools"' opencode_app/opencode.json   # must exit 1
    ```
    — **Done when:** JSON parses; no top-level `tools` key.
- [ ] **5.4** Agent count still correct (regression check — no accidental agent edits):
    ```bash
    ls opencode_app/.opencode/agents/*.md | wc -l   # must be 39
    grep -n "39 subagent\|39 agent" README.md       # must still match
    ```
    — **Done when:** Count is 39; README still says 39.

## Acceptance Criteria

- [ ] All skill-count references across `README.md`, `deploy/setup.sh`, `deploy/setup.ps1` read **115** (and `18 categories`).
- [ ] README category table lists all 115 skills (sum of parentheticals == 115); the 3 previously-missing skills (`deprecated-code-cleanup-skill`, `pptx-generate-slide-skill`, `pptx-template-modifier-skill`) are placed in appropriate rows.
- [ ] `opencode_app/opencode.json` has no top-level `tools` key; an equivalent top-level `permission` object holds all 25 former entries with `allow`/`deny` values; JSON parses.
- [ ] `AGENTS.md` tier table names `responsive-audit` under glm-5.1.
- [ ] Agent count remains 39 (unchanged) — no regression.

## Out of Scope (explicitly NOT done — verified non-issues)

- `zai-vision-analysis-skill` retirement — **already complete** (0 references repo-wide).
- Agent count "39 → 38" — **39 is correct**; no work.
- `deploy/agent-tiers.json` / `deploy/models.default.json` edits — **files do not exist** (fabricated by the initial audit).
- autoresearch-* / pptx-specialist tier "mismatches" — **none exist**; all match the AGENTS.md table.
