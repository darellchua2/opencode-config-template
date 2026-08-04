**Issue**: #297
**Title**: Remediate verified opencode-config drift (skill-count, category table, deprecated `tools:` block)
**Branch**: `fix/297-audit-remediation`
**Status**: Phases 1-5 complete; Phase 6 (post-review findings) — open
**PR**: #298 (→ `dev`)

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

- [x] **1.1** `README.md:24` — `# 113 skill directories` → `# 115 skill directories`
    — **Done:** updated; verified `grep "113 skill" README.md` empty.
- [x] **1.2** `README.md:280` — `with 113 skills organized across 17 categories` → `with 115 skills organized across 18 categories`
    — **Done:** both numbers updated.
- [x] **1.3** `deploy/setup.sh:586` — `SKILLS (113):` → `SKILLS (115):`
    — **Done:** updated.
- [x] **1.4** `deploy/setup.ps1:382` — `SKILLS (113):` → `SKILLS (115):`
    — **Done:** updated.
- [x] **1.5** *(scope expansion)* `deploy/setup.sh:2425` — `📦 113 Skills Available` → `115`; `deploy/setup.ps1:1781` — `113 Skills Available` → `115`; `opencode_app/README.md:26` — `# 113 skill directories` → `# 115`
    — **Done:** 3 additional count locations discovered during execution (not in original PLAN); all fixed. fixes: original PLAN missed these — same drift class documented in PLAN-GIT-237.

### Phase 2: Reconcile README category table (add 3 missing skills)

- [x] **2.1** `README.md:286` (Framework row) — added `pptx-generate-slide-skill, pptx-template-modifier-skill`; `(20)` → `(22)`
    — **Done:** row now lists 22 skills.
- [x] **2.2** `README.md:294` (Code Quality row) — added `deprecated-code-cleanup-skill`; `(7)` → `(8)`
    — **Done:** row now lists 8 skills.
- [x] **2.3** Category table parentheticals sum to 115
    — **Done:** verified `sed -n '286,303p' README.md | sum = 115`; disk = 115.
- [x] **2.4** *(scope expansion)* Reconciled category blocks in `deploy/setup.sh` (main banner 587-662 + summary banner 2432-2438) and `deploy/setup.ps1` (main 383-449 + summary 1788-1794) — added the 3 new skills + the missing **Autoresearch (4)** row (#239 sync miss); both main + summary banners now sum to 115.
    — **Done:** all four deploy-script banners verified at 115. fixes: deploy-script category blocks were also stale (missing Autoresearch + 3 skills); not in original PLAN.
    — **Flagged tech debt (NOT fixed):** the verbose debug-echo function (`setup.sh:2248+`, `setup.ps1:1250+`) is a *pre-existing broken* listing missing 5 entire categories (Agent Optimization, Startup/Business, Configuration, Security, DevOps) + Autoresearch. Rebuilding it is out of scope for count-drift; tracked separately.

### Phase 3: Migrate deprecated `tools:` block to `permission`

- [x] **3.1** `opencode_app/opencode.json:245-271` — converted top-level `"tools": {bool}` → top-level `"permission": {allow/deny}` (25 entries, `true`→`"allow"`, `false`→`"deny"`)
    — **Done:** `python3 -c json.load` VALID; `grep '"tools"'` empty; 4 allow + 21 deny entries map 1:1.
- [x] **3.2** Spot-check 4 allow / 21 deny 1:1 mapping
    — **Done:** verified; behavior preserved per opencode.ai/docs/permissions (tools boolean merged into permission v1.1.1).

### Phase 4: Add responsive-audit to tier table (cosmetic)

- [x] **4.1** `AGENTS.md:34` (glm-5.1 row) — added `responsive-audit` to the agent list
    — **Done:** `grep "responsive-audit" AGENTS.md` matches; matches actual `responsive-audit-subagent.md:4 model: glm-5.1`.

### Phase 5: Verification Gate

- [x] **5.1** `grep -rniE "113 skill|SKILLS \(113\)|17 categor"` → CLEAN (zero matches) ✓
- [x] **5.2** disk count == table sum == **115** ✓
- [x] **5.3** opencode.json VALID, no top-level `tools` key ✓
- [x] **5.4** agent count == 39 (no regression) ✓

### Phase 6: Post-Review Findings (PR #298 — architecture + opencode-tooling review)

> Both reviewers returned **APPROVE WITH NITS**. No blockers; the migration is verified behavior-preserving and counts are correct end-to-end. The findings below are tracked for resolution. Disposition tags: **[apply]** safe to apply now · **[decision]** maintainer judgment needed · **[tech-debt]** systemic/pre-existing, separate scope · **[nit]** optional.

- [ ] **6.1** **[apply]** Add `uiux-reviewer` + `startup-ceo` to tier table — `AGENTS.md:33-34`
    — **Finding (opencode-tooling Minor-4, broadened audit):** `uiux-reviewer-subagent.md:4` = `glm-5.1` and `startup-ceo-subagent.md:4` = `glm-5-turbo`, but neither is named in its tier row. Same class as the `responsive-audit` fix (4.1).
    — **Action:** append `uiux-reviewer` to the glm-5.1 row, `startup-ceo` to the glm-5-turbo row.
    — **Done when:** both names appear in their tier rows; `grep -H "^model:" agents/*.md` cross-check shows no remaining unlisted subagent.
- [ ] **6.2** **[decision]** Prune 92%-inert `permission` block — `opencode_app/opencode.json:245-271`
    — **Finding (opencode-tooling Minor-1):** 23 of 25 entries are no-ops — 19 denies duplicate `mcp.*.enabled:false`; 4 allows restate the `allow` default. Only `zai-vision-mcp-server` + `zai-zread` denies are active (`enabled:true`, denied, no agent overrides). Migration was faithful; this is pre-existing redundancy.
    — **Action (options):** (a) set those 2 servers to `enabled:false` + delete the entire `permission` block; (b) keep the 2 active denies, prune the 23 redundant; (c) keep the faithful migration as-is.
    — **Decision needed:** option (a) disables 2 currently-enabled-but-unused ZAI servers (loaded into context, permanently unusable) — a behavior change, not just cleanup.
- [ ] **6.3** **[apply]** Fix stale `permission.read` claim — `deploy/.AGENTS.md`
    — **Finding (opencode-tooling Minor-3):** deployed AGENTS.md claims `permission.read: { "*": "allow", "mcp:*": "deny" }` exists in opencode.json; the actual `permission` block has **no `read` key**. Stale doc adjacent to the migration.
    — **Action:** either remove the stale claim or add the `read` rule to `opencode.json`.
- [ ] **6.4** **[tech-debt]** Verbose debug-echo contradiction — `deploy/setup.sh:2248+`, `deploy/setup.ps1:1250+`
    — **Finding (architecture):** the deferred listing (PLAN §2.4 flag) prints a **correct dynamic headline** (`✓ skills: 115`) followed by a per-category breakdown summing to **90** (missing 6 categories). Internally contradictory diagnostic for anyone running `--status`.
    — **Action:** rebuild the listing to include all 18 categories (separate task), OR at minimum update the PLAN flag to state the contradiction explicitly (not just "pre-existing broken").
- [ ] **6.5** **[tech-debt]** Hardcoded-count anti-pattern root fix — `deploy/setup.sh`, `deploy/setup.ps1`
    — **Finding (architecture):** 3rd remediation cycle of count drift (PLAN-GIT-237, now -297). `setup.sh:2246` already computes `skill_count` dynamically; the main banner heredoc (`:414`, unquoted) supports `${var}` interpolation, yet headlines hardcode `115` as a literal.
    — **Action:** compute the total once at function entry and interpolate `${skill_count}` into all banner headlines. Per-category breakdowns stay hardcoded (categorization is a human-maintained mapping). Eliminates the total-count drift surface.
- [ ] **6.6** **[apply]** Sync-rules table under-specifies count locations — `AGENTS.md` sync-rules table
    — **Finding (opencode-tooling Minor-5):** the table names the right files but doesn't signal that each deploy script has **multiple** count surfaces (setup.sh alone has 3: main banner, summary banner, verbose debug-echo). This is why the PLAN missed 3 of 7 locations during scoping.
    — **Action:** add a note that count changes must be propagated to **every** banner/summary occurrence (grep the old number across the file), not just the first found.
- [ ] **6.7** **[nit]** Wildcard key style alignment — `opencode_app/opencode.json:246-270`
    — **Finding (opencode-tooling Nit-1):** repo uses `codegraph*` (no underscore); the docs' canonical example is `mymcp_*` (with underscore). Both valid (`*` matches zero+ chars); no collision today.
    — **Action:** optional — align to the `<server>_*` form to match the documented convention.
- [ ] **6.8** **[nit]** pre-1.1.1 backward-compat safety net — `opencode_app/opencode.json`
    — **Finding (architecture Nit):** removing `tools` entirely drops the safety net for opencode <1.1.1 (where `permission` tool-name patterns may not be recognized → denies default to `allow`). Low probability — the template targets current opencode, and the 2 affected servers are unused.
    — **Action:** document the forward-correct decision, or temporarily keep both `tools` + `permission` during a transition window.

## Acceptance Criteria

- [x] All skill-count references across `README.md`, `deploy/setup.sh`, `deploy/setup.ps1`, `opencode_app/README.md` read **115** (and `18 categories`).
- [x] README category table + both deploy-script main/summary banners list all 115 skills (sum == 115); the 3 previously-missing skills placed; missing Autoresearch row added to deploy scripts.
- [x] `opencode_app/opencode.json` has no top-level `tools` key; equivalent top-level `permission` object holds all 25 former entries; JSON parses.
- [x] `AGENTS.md` tier table names `responsive-audit` under glm-5.1.
- [x] Agent count remains 39 (unchanged) — no regression.

### Phase 6 acceptance (post-review)

- [ ] **[apply]** 6.1 — `uiux-reviewer` + `startup-ceo` added to tier table; no subagent model left unlisted.
- [ ] **[decision]** 6.2 — maintainer decides on the inert `permission` block (prune / disable-2-servers / keep-as-is); decision recorded.
- [ ] **[apply]** 6.3 — stale `permission.read` claim in `deploy/.AGENTS.md` reconciled (removed or rule added).
- [ ] **[tech-debt]** 6.4 + 6.5 — either fixed here or split into a follow-up issue (the debug-echo rebuild + dynamic-count root fix).
- [ ] **[apply]** 6.6 — sync-rules table notes multi-occurrence count propagation.
- [ ] **[nit]** 6.7 + 6.8 — decision recorded (apply or explicitly skip).

## Out of Scope (explicitly NOT done — verified non-issues)

- `zai-vision-analysis-skill` retirement — **already complete** (0 references repo-wide).
- Agent count "39 → 38" — **39 is correct**; no work.
- `deploy/agent-tiers.json` / `deploy/models.default.json` edits — **files do not exist** (fabricated by the initial audit).
- autoresearch-* / pptx-specialist tier "mismatches" — **none exist**; all match the AGENTS.md table.
