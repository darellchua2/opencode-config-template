**Issue**: #297
**Title**: Remediate verified opencode-config drift (skill-count, category table, deprecated `tools:` block)
**Branch**: `fix/297-audit-remediation`
**Status**: Complete (Phases 1-7). Tech-debt items 6.4/6.5 split to #299.
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

- [x] **6.1** **[apply]** Add `uiux-reviewer` + `startup-ceo` to tier table — `AGENTS.md:33-34`
    — **Done:** `uiux-reviewer` appended to glm-5.1 row, `startup-ceo` to glm-5-turbo row. Verified both `model:` frontmatters match. (The 2 `*-primary-agent` routers also use glm-5-turbo but are intentionally grouped as "document creators"/routers — left as-is.)
- [x] **6.2** **[decision]** Prune 92%-inert `permission` block — `opencode_app/opencode.json:245-271`
    — **Done:** applied **option (b)** — pruned 23 redundant entries (19 denies on `enabled:false` servers + 4 allows restating the default), kept only the 2 active denies (`zai-vision-mcp-server*`, `zai-zread*`, both `enabled:true`). Block shrunk 25→2 entries. JSON valid; behavior preserved (no server enable/disable change). **Option (a)** (disable the 2 enabled-but-unused ZAI servers) deferred — that's a behavior change needing separate maintainer sign-off.
- [x] **6.3** **[apply]** Fix stale `permission.read` claim — `deploy/.AGENTS.md`
    — **Done (no-op on repo):** verified the `permission.read: { "*": "allow", "mcp:*": "deny" }` claim is **NOT** in source `deploy/.AGENTS.md` — it exists only in the *deployed* `~/.config/opencode/AGENTS.md`, a stale copy from an older deploy. Source is already correct; the deployed copy self-corrects on the next `setup.sh` run. No repo change needed.
- [x] **6.4** **[tech-debt]** Verbose debug-echo contradiction — `deploy/setup.sh:2248+`, `deploy/setup.ps1:1250+`
    — **Done (split):** tracked in follow-up issue **#299** with 6.5. The PLAN flag here is updated to state the contradiction explicitly (headline 115 / breakdown ~90, missing 6 categories).
- [x] **6.5** **[tech-debt]** Hardcoded-count anti-pattern root fix — `deploy/setup.sh`, `deploy/setup.ps1`
    — **Done (split):** tracked in follow-up issue **#299** — interpolate `${skill_count}` into banner headlines (mechanism already exists at `setup.sh:2246`). Out of scope for this count-drift PR (deploy-script refactor).
- [x] **6.6** **[apply]** Sync-rules table under-specifies count locations — `AGENTS.md` sync-rules table
    — **Done:** added a "Count-propagation note" after the File table stating each deploy script has multiple count surfaces (3 in setup.sh) and to grep the old number across the whole file. Cites PLAN-GIT-237/-297 as the drift class.
- [x] **6.7** **[nit]** Wildcard key style alignment — `opencode_app/opencode.json:246-270`
    — **Done (intentionally skipped):** after the 6.2 prune only the 2 active denies remain; the broader `server*` form (no underscore) is intentionally **kept** because it is a *safer* (more permissive) deny than `server_*` — it cannot accidentally let a tool slip through. Documented as a deliberate choice.
- [x] **6.8** **[nit]** pre-1.1.1 backward-compat safety net — `opencode_app/opencode.json`
    — **Done (documented):** the forward-correct decision stands — `tools` fully removed, `permission` is authoritative. The template targets current opencode; the 2 affected servers are unused. No transition window retained (would re-introduce deprecated syntax).

### Phase 7: Configurator frontmatter + deploy-quality (from the codegraph/read_mcp_resource/frontmatter investigation)

> Driven by a follow-up investigation: (a) the `read_mcp_resource` symptom was traced to a **stale deployed `AGENTS.md`** — source was already clean, but `setup.sh` defaulted to NOT overwriting an existing file; (b) a skills-doc audit found `metadata` must be a **string-to-string map** but ~28 skill metadata values were arrays.

- [x] **7.1** Convert array metadata values → quoted comma-separated strings across 27 skills (28 values)
    — **Done:** `languages: [typescript, javascript]` → `languages: "typescript, javascript"`; `frameworks: [react, nextjs]` → `"react, nextjs"`. Verified: 0 non-string metadata remaining; all converted skills YAML-valid.
- [x] **7.2** Fix `autoresearch-core-skill` `protocol-source: true` (boolean) → `"true"` (string)
    — **Done:** metadata is now fully string-to-string conformant per https://opencode.ai/docs/skills/.
- [x] **7.3** Enhance `deploy/setup.sh` AGENTS.md deploy to **detect staleness** (diff source vs dest) and warn loudly + default to overwrite
    — **Done:** `diff -q` check; if identical → silent `log_info`; if stale → 2× `log_warn` (explains risk: stale shipped instructions cause incorrect agent behavior) + prompt default `y`. Fixes the root cause of the stale-deployed-AGENTS.md / `read_mcp_resource` symptom. `bash -n` clean.
- [x] **7.4** Mirror 7.3 in `deploy/setup.ps1` (Get-FileHash comparison + stale warning + default `$true`)
    — **Done:** PowerShell parity via `Get-FileHash` SHA256 comparison.
- [ ] **7.5** **[flagged — pre-existing, NOT auto-fixed]** `git-compact-commits-skill` + `git-semantic-commits-skill` frontmatter `description` contains `says: "..."` (colon+space+quote) which breaks strict YAML (`ScannerError: mapping values are not allowed here`). opencode's parser may handle these leniently (skills load), but they are non-conformant. **Action deferred** — the fix (quote/block-scalar the description) touches skill content and warrants review; tracked here, not in #297 scope.

### Phase 7 acceptance

- [x] All shipped skill `metadata` is string-to-string (verified via `yaml.safe_load` across all SKILL.md; 0 non-string values).
- [x] `setup.sh` / `setup.ps1` warn loudly + default to overwrite when deployed AGENTS.md is stale (diff/hash-detected); silent when up-to-date.
- [ ] 7.5 — 2 pre-existing ScannerError descriptions (flagged, deferred).

## Acceptance Criteria

- [x] All skill-count references across `README.md`, `deploy/setup.sh`, `deploy/setup.ps1`, `opencode_app/README.md` read **115** (and `18 categories`).
- [x] README category table + both deploy-script main/summary banners list all 115 skills (sum == 115); the 3 previously-missing skills placed; missing Autoresearch row added to deploy scripts.
- [x] `opencode_app/opencode.json` has no top-level `tools` key; equivalent top-level `permission` object holds all 25 former entries; JSON parses.
- [x] `AGENTS.md` tier table names `responsive-audit` under glm-5.1.
- [x] Agent count remains 39 (unchanged) — no regression.

### Phase 6 acceptance (post-review)

- [x] **[apply]** 6.1 — `uiux-reviewer` + `startup-ceo` added to tier table.
- [x] **[decision]** 6.2 — option (b) applied (pruned to 2 active denies); option (a) deferred (behavior change).
- [x] **[apply]** 6.3 — no-op on repo source (claim only in stale deployed copy).
- [x] **[tech-debt]** 6.4 + 6.5 — split to follow-up issue **#299**.
- [x] **[apply]** 6.6 — sync-rules table notes multi-occurrence count propagation.
- [x] **[nit]** 6.7 + 6.8 — decisions recorded (6.7 kept broader pattern intentionally; 6.8 forward-correct, no transition window).

## Out of Scope (explicitly NOT done — verified non-issues)

- `zai-vision-analysis-skill` retirement — **already complete** (0 references repo-wide).
- Agent count "39 → 38" — **39 is correct**; no work.
- `deploy/agent-tiers.json` / `deploy/models.default.json` edits — **files do not exist** (fabricated by the initial audit).
- autoresearch-* / pptx-specialist tier "mismatches" — **none exist**; all match the AGENTS.md table.
