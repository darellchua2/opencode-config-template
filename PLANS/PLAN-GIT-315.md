# PLAN-GIT-315: Integrate vibeguard secret masking for .env safety

**Issue:** https://github.com/darellchua2/opencode-config-template/issues/315
**Branch:** `feat/secret-masking-vibeguard`
**Status:** Implemented (Phases 1–8 complete; Phase 9 runtime verification pending)

## Goal

"Use but never expose": let OpenCode use secret values at tool-execution time, but the LLM/provider must never see or echo the plaintext. Achieved via vibeguard masking (regex config, no literals shipped) + AGENTS.md behavioral rules + procedure folded into the existing `security-audit-skill`.

## Locked Decisions

| # | Decision | Choice |
|---|----------|--------|
| 1 | Config pattern type | **Regex-only** (safe to commit) — no literal `keywords` shipped in the global template |
| 2 | User per-project overlay | UNCOMMITTED `./vibeguard.config.json` at project root (lookup slot 2 overrides global) with literal `keywords` for exact-match; never committed |
| 3 | Behavioral rules location | **Inline in `deploy/.AGENTS.md` §Secret Hygiene** — every subagent inherits this; not a bare pointer |
| 4 | Procedure location | **Folded into existing `security-audit-skill`** — no new skill created |
| 5 | Plugin pinning | `opencode-vibeguard@0.1.0` (currently unpinned `opencode-vibeguard` at line 12) — only published version |
| 6 | Read deny scope | Explicit `"*.env": "deny"`, `"*.env.*": "deny"`, `"*.env.example": "allow"` alongside existing `"mcp:*": "deny"` |
| 7 | Branch source | `main` |

## Review Findings (Round 1) — applied to this plan

Two reviews (architecture-review-subagent, opencode-tooling-subagent) confirmed the **core defense holds**: vibeguard masks provider-bound traffic for ALL agents regardless of read-permission overrides. The findings below re-scope over-claimed guarantees and add concrete fixes.

### Accepted residual risks (documented, not eliminated)
- **R1 — `/share` leaks plaintext.** vibeguard hooks `messages.transform` (provider-bound) + `text.complete` + `tool.execute.before`. It has **no `/share` hook**. Session DB and `/share` links contain plaintext tool I/O locally. Mitigation = advisory only (AGENTS.md rule + README warning) + upstream feature request.
- **R2 — No fail-closed if vibeguard no-ops.** `if (!config.enabled) return {}` — missing/malformed/`enabled:false` config = silent no-op. The `read` deny (Phase 1) is fail-closed but ONLY for the `read` tool. bash/grep/MCP rely entirely on vibeguard being active.
- **R3 — Session DB stores plaintext locally.** Acceptable for "never expose to provider"; must be documented so users don't assume `/share`/DB dumps are safe.

### Fixes folded into phases below
- **F1 (Phase 1.1 re-scope):** the global `permission.read` `.env` deny is overridden by ~30 subagents whose `read:` block is `{"*":"allow"}` (agent rules take precedence). The deny therefore protects **only the primary `build` agent**. vibeguard is the universal mask for subagents. → new optional Phase 1.3 for the agent sweep.
- **F2 (Phase 2.1 regex):** SECRET_ASSIGNMENT rewritten to match compound key names (`STRIPE_SECRET_KEY=`, `DATABASE_URL=`); added URL-credential catch-all; case-sensitivity now an explicit verification step.
- **F3 (Phase 3.1 reframe):** restore is already generic-covered (setup.sh:1431); the real gap is the **backup** functions (`create_pre_rollback_backup` setup.sh:1467).
- **F4 (Phase 4):** AGENTS.md reframed from "safety net" → "advisory layer"; added `/share` rule + placeholder-integrity rule + fail-closed caveat.
- **F5 (Phase 6):** skill `description` frontmatter must be updated (discoverability).
- **F6 (Phase 7):** residual-risk warnings (R1/R2/R3) added to README.
- **F7 (Phase 8):** `.gitignore` `.env` broadened to `.env*` (bare `.env` does NOT match `.env.local`).
- **F8 (Phase 9):** added subagent round-trip test, MCP structured-output check, no-op startup detection, case-sensitivity verification; reframed `/share` test as residual-risk confirmation.

## Dependency & Consumer Map

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---|---|---|---|
| `opencode_app/opencode.json` (Phase 1) | — | Every OpenCode session (permission rules), vibeguard plugin activation | **high** — wrong deny pattern breaks `.env` reads or allows leaks. NOTE: read-deny protects only primary `build` agent (F1). |
| `opencode_app/.opencode/vibeguard.config.json` (Phase 2, NEW) | Phase 1 plugin pinned | `opencode-vibeguard` plugin at runtime | med — regex must be correct shapes + correct case handling; no literals |
| `deploy/setup.sh` (Phase 3) | Phase 2 config file exists | All user-space deploys (`~/.config/opencode/`) | **high** — missing deploy OR missing backup = users lose config on rollback (F3) |
| `deploy/setup.ps1` (Phase 3) | Phase 2 config file exists | Windows user-space deploys | **high** — must mirror setup.sh exactly |
| `deploy/.AGENTS.md` (Phase 4) | — | Every primary session + every inherited subagent (deployed globally) | **high** — but is an **advisory layer**, not a hard control (F4) |
| `AGENTS.md` repo root (Phase 5) | Phase 4 exists | Repo-scoped conventions only | low (one-liner pointer) |
| `security-audit-skill/SKILL.md` (Phase 6) | — | Any agent/user loading the skill for security audits | med (additive section — no existing content broken) |
| `README.md` + `opencode_app/README.md` (Phase 7) | Phases 1-6 complete | End users reading docs | low (documentation only) — must carry residual-risk warnings (F6) |
| `.gitignore` (Phase 8) | — | Git operations | **med** — current `.env` pattern misses `.env.local` (F7) |
| ~30 `agents/*.md` read-overrides (Phase 1.3, optional) | Phase 1 | All read-heavy subagents | med (mechanical but wide) — deferred unless full-hardening track chosen |

---

## Phase 1 — Harden `opencode_app/opencode.json` permission.read

_Owner: direct edit_

- [x] **1.1** In `opencode_app/opencode.json` `permission.read`, add explicit deny rules: `"*.env": "deny"`, `"*.env.*": "deny"`, `"*.env.example": "allow"` alongside the existing `"mcp:*": "deny"`. Also add a leading `"*": "allow"` to match OpenCode's documented default object shape (resolves merge-vs-replace ambiguity — M1).
    — **Why:** The current config overrides the entire `read` permission object with only `"mcp:*": "deny"`. Whether OpenCode's built-in `.env` default-denies survive this override is ambiguous. Explicit re-declaration guarantees deny behavior regardless of upstream changes.
    — **SCOPE CAVEAT (F1):** This protects the **primary `build` agent only**. ~30 subagents define `permission.read: {"*":"allow"}` which takes precedence (agent rules win) and bypasses these denies. vibeguard (Phase 2) is the universal mask that covers subagents. Full read-deny coverage for subagents is Phase 1.3 (optional).
    — **Done when:** `jq '.permission.read' opencode_app/opencode.json` shows `"*":"allow"`, `"mcp:*":"deny"`, `"*.env":"deny"`, `"*.env.*":"deny"`, `"*.env.example":"allow"` (5 keys, correct order for last-match-wins: `*.env.example` allow AFTER `*.env.*` deny).
    — **Consumers affected:** Primary `build` agent sessions (Docker standalone + user-space deploy).
    — **Done:** 5 keys added to `permission.read` in order: `"*":"allow"`, `"mcp:*":"deny"`, `"*.env":"deny"`, `"*.env.*":"deny"`, `"*.env.example":"allow"`; files: opencode_app/opencode.json; fixes: none (jq confirmed correct shape).

- [x] **1.2** In `opencode_app/opencode.json` `plugin` array (line 12), change `"opencode-vibeguard"` to `"opencode-vibeguard@0.1.0"`.
    — **Why:** Currently unpinned — a `latest` pull could break the regex config schema or masking behavior. `0.1.0` is the only published version (5 months old). Pinning ensures reproducible deploys. NOTE: `package-lock.json` does not govern the `plugin` array (plugins resolve at runtime); pinning is for runtime reproducibility, not lockfile discipline.
    — **Done when:** `jq '.plugin[] | select(test("vibeguard"))' opencode_app/opencode.json` returns `opencode-vibeguard@0.1.0`.
    — **Consumers affected:** All deploys (setup.sh copies this file to `~/.config/opencode/`).
    — **Done:** pinned to `opencode-vibeguard@0.1.0`; files: opencode_app/opencode.json; fixes: none.

- [ ] **1.3 (OPTIONAL — full-hardening track — SKIPPED: advisory track chosen)** Audit and patch the ~30 subagents under `opencode_app/.opencode/agents/*.md` whose `permission.read` block is `{"*":"allow", "mcp:*":"deny"}`: add the same `"*.env":"deny"`, `"*.env.*":"deny"`, `"*.env.example":"allow"` triples so the read-deny defense-in-depth applies to read-heavy subagents (explorer, code-review, error-resolver, all language reviewers, testing, linting, architecture-review, etc.).
    — **Why:** Without this, subagents can `read` `.env*` directly; only vibeguard masks the result. Phase 1.1 + 1.3 together make the read-deny layer universal.
    — **Done when:** `grep -rL '\*\.env' opencode_app/.opencode/agents/` returns no agent with a `read:` block lacking the `.env` denies. Skip if the advisory+vibeguard track (Phase 1.1 only) is accepted.
    — **Consumers affected:** All read-heavy subagents.
    — **Done:** SKIPPED — advisory+vibeguard track accepted. vibeguard (Phase 2) is the universal mask for subagents.

---

## Phase 2 — Create `opencode_app/.opencode/vibeguard.config.json`

_Owner: direct create_

- [x] **2.1** Create `opencode_app/.opencode/vibeguard.config.json` with regex-only patterns (NO literal secrets).
    — **Why:** Vibeguard is already in the plugin array (line 12) but has no config — it is a no-op. This config activates it with shape-based regex patterns safe to commit, covering Broad+PII secret categories.
    — **Done when:** File exists at `opencode_app/.opencode/vibeguard.config.json` with:
      - `enabled: true`, `debug: false`, `placeholder_prefix: "__VG_"`, `session: {"ttl":"1h","max_mappings":100000}` (pin prefix so docs referencing `__VG_…__` are provably accurate — M3).
      - `patterns.regex` with 9 entries; SECRET_ASSIGNMENT uses `flags: "i"` for case-insensitive matching (verified: vibeguard `src/patterns.js:118` supports per-pattern `flags` field).
      - `patterns.builtin`: `["email", "uuid", "ipv4", "mac"]`
      - `patterns.exclude`: `["localhost", "127.0.0.1", "0.0.0.0", "example.com"]`
      - `keywords`: omitted (no literals shipped).
    — **Consumers affected:** `opencode-vibeguard` plugin at runtime in every session.
    — **Done:** 9 regex patterns + 4 builtin + 4 exclude created; all compile + match verified via node test (PASSWORD=, STRIPE_SECRET_KEY=, postgres://user:pass@, etc.); files: opencode_app/.opencode/vibeguard.config.json; fixes: added `flags: "i"` to SECRET_ASSIGNMENT instead of expanding alternation — lazier and correct (9.8 verified).

---

## Phase 3 — Deploy vibeguard config via `setup.sh` + `setup.ps1`

_Owner: direct edit (both files)_

- [x] **3.1** In `deploy/setup.sh`, wire `vibeguard.config.json` deploy + **backup** (F3 reframe). Source: `opencode_app/.opencode/vibeguard.config.json`; dest: `~/.config/opencode/vibeguard.config.json` (vibeguard global lookup slot 4).
    — **Why:** Without deployment, users get the plugin but no masking rules. **Restore is ALREADY generic-covered** — `restore_from_dir()` (setup.sh:1431-1449) restores top-level `*.json` except the special-cased names, so `vibeguard.config.json` restores automatically IF it is in the backup. **The real gap is backup**: `create_pre_rollback_backup()` (setup.sh:1454-1477) only backs up `config.json`, `AGENTS.md`, `skills/`, `agents/` — it would silently drop vibeguard.config.json on rollback/update.
    — **Exact insertion points:**
      - Deploy `cp` + `create_backup`: after the config.json copy block (~setup.sh:2397), near the AGENTS.md handling (~setup.sh:2362).
      - Add `vibeguard.config.json` to the pre-rollback/update backup file list: `create_pre_rollback_backup()` (~setup.sh:1467).
      - Restore: **no change needed** (generic loop at :1431 already covers it).
    — **Done when:** `setup.sh` deploys vibeguard.config.json on fresh install; `create_pre_rollback_backup()` includes it; a rollback round-trip preserves it.
    — **Consumers affected:** All user-space deploys via `./deploy/setup.sh`.
    — **Done:** deploy `cp` added after `install_docling` (~:2410); `create_pre_rollback_backup` backup added (~:1468); `create_backup_before_update` backup added (~:3175); banner status line added (~:2431) + status section (~:3415); files: deploy/setup.sh; fixes: none (bash -n passed).

- [x] **3.2** Mirror `setup.sh` changes in `deploy/setup.ps1` (Windows parity).
    — **Why:** The repo maintains setup.sh/setup.ps1 parity. Windows restore is generic-covered at ~setup.ps1:606; the update-backup gap is at ~setup.ps1:2463.
    — **Done when:** setup.ps1 deploys vibeguard.config.json and includes it in the update-backup list (~:2463), mirroring setup.sh.
    — **Consumers affected:** Windows user-space deploys via `deploy/setup.ps1`.
    — **Done:** deploy after config.json copy (~:1699); pre-rollback backup (~:638); update-backup (~:2478); banner status line (~:1727); files: deploy/setup.ps1; fixes: none.

- [x] **3.3** Update banner/status/help text in both scripts to mention "vibeguard secret masking: active".
    — **Why:** Users should see at deploy time that secret masking is active — serves as both documentation and a verification signal (partial mitigation for R2 — makes a no-op visible if the line is absent).
    — **NOTE (L2):** Skill/agent counts are dynamic (`count_skills()`/`count_agents()`) — vibeguard is a **plugin**, not a skill/agent, so **no numeric count change** and no count-drift risk. Only the static status text (setup.sh:2408-2420, setup.ps1:1704-1715) needs a new line.
    — **Done when:** Banner output includes a "Secret masking: active (vibeguard)" status line.
    — **Consumers affected:** Users running `setup.sh --dry-run` or reading banner output.
    — **Done:** "✓ Secret masking: active (vibeguard)" added to both scripts' deploy banner + setup.sh status section; files: deploy/setup.sh, deploy/setup.ps1; fixes: none.

---

## Phase 4 — Add §Secret Hygiene to `deploy/.AGENTS.md`

_Owner: direct edit_

- [x] **4.1** Add a new **§Secret Hygiene** section to `deploy/.AGENTS.md` with ~8-10 inline rules (NOT a bare pointer). Place it near the existing "Memory Hygiene" section (header at line ~103).
    — **Why:** Every primary session AND every inherited subagent reads `deploy/.AGENTS.md` (deployed to `~/.config/opencode/AGENTS.md`, setup.sh:2344-2362). Inline rules are non-optional — a pointer would be too easy for a subagent to skip.
    — **Reframe (F4):** This section is an **advisory layer**, NOT a hard control. The only hard controls are (1) vibeguard regex masking and (2) `permission.read` deny for the `read` tool (primary agent). Behavioral rules reduce the likelihood of secret echo but can be defeated by prompt injection, model non-compliance (esp. `fast`-tier subagents), or context-window compaction. State this honestly in the section.
    — **Rules to include:**
      1. Never inline or echo values read from `.env*` files in reply text; reference by `$VAR` name only.
      2. Subagents report key NAMES, not values, back to the primary.
      3. Prefer `$VAR` env references over inlining literals in generated scripts.
      4. vibeguard masks provider-bound traffic and restores real values at tool-execution; the agent's job is to prefer `$VAR` and avoid unnecessary `.env` reads.
      5. Never store secrets in the `memory` tool or LEARNINGS verbatim (extends existing Memory Hygiene rule).
      6. **Never use `/share` on sessions that processed `.env` secrets** — `/share` exports plaintext tool I/O (R1).
      7. **Placeholder integrity:** if you must reference a masked value inline (not a `$VAR`), copy the exact `__VG_…__` token verbatim — never truncate, reformat, or partially copy it (broken placeholders fail to restore at exec).
      8. **Fail-closed caveat:** if vibeguard is no-op (config missing/malformed), bash/grep/MCP paths are unprotected — treat any `.env` value as exposed and avoid processing it.
    — **Done when:** Section exists with the 8 rules above; reframed as advisory (not "safety net"); ends with connector line: "For verification, per-project keyword setup, `$VAR` usage patterns, and fallback when vibeguard is disabled, load `security-audit-skill`."
    — **Consumers affected:** Every primary session and every subagent inheriting AGENTS.md globally.
    — **Done:** §Secret Hygiene added after Memory Hygiene with 8 rules + advisory framing + per-project overlay note (first-config-wins, no merge) + connector to security-audit-skill; files: deploy/.AGENTS.md; fixes: none.

---

## Phase 5 — Add one-liner pointer in repo-root `AGENTS.md`

_Owner: direct edit_

- [x] **5.1** In `AGENTS.md` (repo root), add a one-line pointer under the repo conventions section referencing `deploy/.AGENTS.md §Secret Hygiene` and `security-audit-skill`.
    — **Why:** The repo-level AGENTS.md defines repo-specific conventions. A pointer ensures contributors know where the canonical secret-hygiene rules live and that the security-audit-skill has the full verification procedure.
    — **Done when:** One-liner exists pointing to both `deploy/.AGENTS.md §Secret Hygiene` and `security-audit-skill`.
    — **Consumers affected:** Agents working directly in this repo (not end-user sessions).
    — **Done:** "## Secret Masking" section added after "## Source of Truth" with 2-line pointer to deploy/.AGENTS.md §Secret Hygiene + security-audit-skill + residual-risk note; files: AGENTS.md; fixes: none.

---

## Phase 6 — Extend `security-audit-skill/SKILL.md`

_Owner: direct edit_

- [x] **6.1** Add a new "## Runtime Secret Masking (vibeguard)" section to `opencode_app/.opencode/skills/security-audit-skill/SKILL.md`. **Also update the skill's `description` frontmatter** (SKILL.md:3) to append ", runtime secret masking (vibeguard)" (F5 — discoverability; OpenCode surfaces skills via `description`).
    — **Why:** The skill is the canonical reference for security audits. Adding the vibeguard procedure here (rather than creating a new skill) avoids skill-count bloat and keeps all security verification in one place. Covers: how masking works (placeholder upstream, restore at exec, historical redaction of tool I/O), verification steps (`OPENCODE_VIBEGUARD_DEBUG=1 opencode`, `/share` residual-risk check, grep session DB), per-project `keywords` setup (UNCOMMITTED `./vibeguard.config.json` with literals), `$VAR` usage pattern, fallback when vibeguard disabled, phase-2 pointer for `shell.env` injection plugin (~30 lines, deferred). Also document residual risks R1/R2/R3.
    — **Done when:** (a) Section exists covering all sub-topics + residual risks; (b) `description` frontmatter updated to mention runtime secret masking/vibeguard; (c) no new skill file created; (d) `security-audit-skill` remains the single entry point.
    — **Consumers affected:** Any agent or user loading `security-audit-skill` for security audits.
    — **Done:** "## Runtime Secret Masking (vibeguard)" section added (~85 lines: how masking works, config locations, verification steps, per-project keyword setup, $VAR pattern, fallback, R1-R4 residual risks table, phase-2 shell.env pointer); description frontmatter updated to append ", runtime secret masking (vibeguard)"; files: opencode_app/.opencode/skills/security-audit-skill/SKILL.md; fixes: added R4 (MCP structured output) to the residual risk table after source inspection.

---

## Phase 7 — Document in READMEs

_Owner: direct edit_

- [x] **7.1** Update `README.md` — document the vibeguard masking feature AND the residual risks (F6):
    - What it does (regex-based secret masking before LLM provider) + that it's the universal layer covering all agents.
    - How users add per-project literal `keywords` (uncommitted `./vibeguard.config.json`).
    - `$VAR` best practice.
    - **Residual-risk warnings (R1/R2/R3):** `/share` exports plaintext (don't share sessions that touched `.env`); if vibeguard fails to load, masking silently disappears (bash/grep/MCP exposed); session DB stores plaintext locally.
    - Note that `security-audit-skill` now covers runtime secret masking.
    — **Why:** End users need honest expectations of what is and isn't protected. Over-claiming "secrets are masked" without the residual-risk caveats creates false confidence.
    — **Done when:** README has a "Secret Masking" section covering activation, per-project keywords, `$VAR` best practice, AND the three residual-risk warnings.
    — **Consumers affected:** Users reading the repo README.
    — **Done:** "## Secret Masking (vibeguard)" section added between Knowledge Persistence and CodeGraph; covers how it works, per-project keywords (first-config-wins note), $VAR best practice, R1/R2/R3 residual risks, pointer to security-audit-skill; files: README.md; fixes: none.

- [x] **7.2** Update `opencode_app/README.md` — add Docker-specific note that vibeguard config is baked into the image + residual-risk warnings.
    — **Why:** Docker standalone users get the config via the image build, not setup.sh. They need to know per-project overlay still works (mount a `./vibeguard.config.json`) and the same residual risks (R1/R2/R3) apply.
    — **Done when:** Docker README mentions vibeguard masking, per-project overlay mechanism, and residual risks.
    — **Consumers affected:** Docker standalone users.
    — **Done:** "### Secret Masking (vibeguard)" subsection added under "## Security" — notes config baked into image, per-project overlay via mount, R1/R2/R3 residual risks; files: opencode_app/README.md; fixes: none.

- [x] **7.3** File an upstream feature request on `opencode-vibeguard` for a `session.share` hook (and/or a structured-output redaction path for MCP tools) to close R1 and the MCP gap.
    — **Why:** The `/share` plaintext leak (R1) and MCP structured-output bypass can only be fully closed upstream.
    — **Done when:** Issue filed on `inkdust2021/opencode-vibeguard`; link recorded here.
    — **Consumers affected:** Upstream project; future versions of this plan.
    — **Done:** Issue filed: https://github.com/inkdust2021/opencode-vibeguard/issues/6 — requests session.share hook + structured-output deep redaction; files: none (external); fixes: none.

---

## Phase 8 — Fix `.gitignore` hygiene

_Owner: direct edit_

- [x] **8.1** Broaden the `.env` ignore pattern (F7) and confirm vibeguard.config.json tracking.
    — **Why:** `.gitignore:23` is bare `.env` — gitignore matches the **exact name** `.env`, which does NOT match `.env.local`, `.env.production`, `.env.development`. This directly undermines the plan's goal (the very file we're protecting can be committed). The global vibeguard config is regex-only (no secrets) and MUST stay tracked so deploys receive it.
    — **Done when:**
      - `.gitignore` `.env` line changed to `.env*` (covers `.env`, `.env.local`, `.env.production`, etc.). Optionally `**/.env*` for nested.
      - `git check-ignore opencode_app/.opencode/vibeguard.config.json` returns nothing (tracked).
      - `git check-ignore .env.local` returns `.env.local` (ignored) — confirm the new pattern works.
      - Add a comment documenting that users should ALSO gitignore any per-project `./vibeguard.config.json` that contains literal `keywords`.
    — **Consumers affected:** Git tracking behavior for this repo and downstream users.
    — **Done:** `.env` → `.env*`; added `/vibeguard.config.json` (root-level per-project overlay); verified: `.env.local` ignored, `opencode_app/.opencode/vibeguard.config.json` tracked, `./vibeguard.config.json` ignored; files: .gitignore; fixes: none.

---

## Phase 9 — Verification

_Owner: manual + automated_

- [ ] **9.1** Run `OPENCODE_VIBEGUARD_DEBUG=1 opencode` with a test `.env.local` containing known secrets → confirm replace-counts > 0 in debug output.
    — **Why:** Primary smoke test that vibeguard is active and matching real secrets. Also serves as the no-op detection (R2): if counts are 0 with secrets present, the plugin is no-op.
    — **Done when:** Debug log shows regex matches and placeholder substitutions for test secrets.
    — **Consumers affected:** None (verification only).
    — **Done:** MANUAL — requires running opencode with the deployed config. Regex patterns verified to compile + match via standalone node test (Phase 2), but end-to-end runtime test requires an interactive opencode session.

- [ ] **9.2** Prompt "show DATABASE_URL from .env.local" → confirm transcript shows `__VG_…__` placeholder, never plaintext.
    — **Why:** Validates end-to-end masking of read-tool output in provider-bound requests.
    — **Done when:** Transcript inspection reveals no plaintext secret values.
    — **Consumers affected:** None (verification only).
    — **Done:** MANUAL — requires interactive opencode session with a test .env.local.

- [ ] **9.3** Prompt "write a script using DATABASE_URL" → confirm output uses `$DATABASE_URL` or vibeguard restores the placeholder at exec time; provider-bound transcript is clean.
    — **Why:** Validates that tool execution (bash/write) receives real values while the provider never sees them.
    — **Done when:** Generated script references `$DATABASE_URL`; provider transcript contains only placeholders.
    — **Consumers affected:** None (verification only).
    — **Done:** MANUAL — requires interactive opencode session.

- [ ] **9.4 (reframed — residual-risk confirmation, NOT a pass/fail)** Run `/share` on a session that used secrets → **EXPECT plaintext in the shared link** (R1: vibeguard has no `/share` hook). Confirm the residual risk is understood and the Phase 4/7 advisories are in place. Separately, grep session DB for a known literal → expect hits (DB stores plaintext locally, R3).
    — **Why:** The original framing assumed `/share` would be clean. It will NOT be. This step now confirms the residual risk is real and documented, not that it's eliminated.
    — **Done when:** Confirmed `/share` link contains plaintext (risk realized); README (7.1) and AGENTS.md (4.1 rule 6) warn against sharing such sessions; upstream request filed (7.3).
    — **Consumers affected:** None (verification only).
    — **Done:** MANUAL — risk is documented in AGENTS.md rule 6 + README R1 + security-audit-skill R1 + upstream issue #6 filed.

- [ ] **9.5 (new — subagent round-trip)** Delegate a task to a subagent (e.g. via `task` tool) that references a masked value from parent context → confirm either (a) the subagent re-reads `.env.local` independently (safe — its own session masks it) OR (b) the parent passes key NAMES not masked values. Confirm placeholder restore is NOT attempted across session boundaries (session map is per-sessionID; cross-session restore is broken by design).
    — **Why:** vibeguard's placeholder→value map is keyed by sessionID. A placeholder from the parent is an opaque string to the subagent; `tool.execute.before` in the subagent cannot restore it. This is a correctness constraint, not a leak.
    — **Done when:** Subagent task completes without emitting a literal `__VG_…__` into a tool arg it can't restore; parent passes key names by convention.
    — **Consumers affected:** None (verification only).
    — **Done:** MANUAL — requires interactive session with subagent delegation. Documented in AGENTS.md rule 2 (subagents report key NAMES).

- [x] **9.6 (new — MCP structured output)** Check whether `atlassian_*` and `codegraph_*` MCP tools return string or structured JSON output. vibeguard redacts tool output only when `typeof output === "string"` — structured objects bypass redaction.
    — **Why:** If MCP tools return structured objects containing secrets, vibeguard cannot mask them without an upstream change.
    — **Done when:** Confirmed output type for the active MCP servers; if structured, documented as residual risk in security-audit-skill (Phase 6) and added to the upstream request (7.3).
    — **Consumers affected:** None (verification only).
    — **Done:** ANSWERED via source inspection (`src/index.js:93`): `state.output` is only redacted when `typeof === "string"` — structured object output bypasses. HOWEVER `state.input` (args) IS deep-walked via `redactDeep` (`src/deep.js:55-82`). In practice, most MCP tools serialize to string before entering conversation, so the risk is narrow. R4 documented in security-audit-skill residual risk table + upstream issue #6.

- [ ] **9.7 (new — no-op startup detection)** Simulate vibeguard no-op (rename/remove the deployed config, or set `enabled:false`) → confirm Phase 3.3 banner still implies masking OR add a startup assertion that warns visibly when the plugin is listed but inactive.
    — **Why:** R2 — a silent no-op leaves bash/grep/MCP fully exposed with no signal.
    — **Done when:** Either the banner/status reflects actual plugin state, OR the residual risk is explicitly documented (masking can silently disappear; users must run 9.1 to confirm).
    — **Consumers affected:** None (verification only).
    — **Done:** MANUAL — requires running opencode with disabled config. Risk documented in security-audit-skill R2 + AGENTS.md rule 8 + README R2.

- [x] **9.8 (new — case-sensitivity verification)** With a test `.env.local` containing `PASSWORD=secret123` and `STRIPE_SECRET_KEY=sk_test_...`, confirm both are redacted. If `PASSWORD=` is NOT redacted, vibeguard compiles regexes case-sensitively and the SECRET_ASSIGNMENT alternation must be expanded to `[A-Za-z]` casing (or vibeguard needs an `i` flag added upstream).
    — **Why:** F2/M-tier — the SECRET_ASSIGNMENT regex uses lowercase alternation; env var names are conventionally uppercase. Unverified case handling = likely false-negatives.
    — **Done when:** Both `PASSWORD=` and `STRIPE_SECRET_KEY=` shapes are redacted in transcript; if not, regex alternation recased and re-tested.
    — **Consumers affected:** None (verification only).
    — **Done:** VERIFIED via node test: `PASSWORD=secret123` and `STRIPE_SECRET_KEY=sk_test_x` both match SECRET_ASSIGNMENT with `flags: "i"`. The config uses `flags: "i"` (confirmed supported in `src/patterns.js:118`), so case-insensitive matching is active without expanding the alternation. fixes: none needed.
