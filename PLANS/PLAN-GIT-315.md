# PLAN-GIT-315: Integrate vibeguard secret masking for .env safety

**Issue:** https://github.com/darellchua2/opencode-config-template/issues/315
**Branch:** `feat/secret-masking-vibeguard`
**Status:** Planning

## Goal

"Use but never expose": let OpenCode use secret values at tool-execution time, but the LLM/provider must never see or echo the plaintext. Achieved via vibeguard masking (regex config, no literals shipped) + AGENTS.md behavioral rules + procedure folded into the existing `security-audit-skill`.

## Locked Decisions

| # | Decision | Choice |
|---|----------|--------|
| 1 | Config pattern type | **Regex-only** (safe to commit) — no literal `keywords` shipped in the global template |
| 2 | User per-project overlay | UNCOMMITTED `./vibeguard.config.json` at project root (lookup slot 2 overrides global) with literal `keywords` for exact-match; never committed |
| 3 | Behavioral rules location | **Inline in `deploy/.AGENTS.md` §Secret Hygiene** — every subagent inherits this; not a bare pointer |
| 4 | Procedure location | **Folded into existing `security-audit-skill`** — no new skill created |
| 5 | Plugin pinning | `opencode-vibeguard@0.1.0` (currently unpinned `opencode-vibeguard` at line 12) |
| 6 | Read deny scope | Explicit `"*.env": "deny"`, `"*.env.*": "deny"`, `"*.env.example": "allow"` alongside existing `"mcp:*": "deny"` |
| 7 | Branch source | `main` |

## Dependency & Consumer Map

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---|---|---|---|
| `opencode_app/opencode.json` (Phase 1) | — | Every OpenCode session (permission rules), vibeguard plugin activation | **high** — wrong deny pattern breaks `.env` reads or allows leaks |
| `opencode_app/.opencode/vibeguard.config.json` (Phase 2, NEW) | Phase 1 plugin pinned | `opencode-vibeguard` plugin at runtime | med — regex must be correct shapes; no literals to worry about |
| `deploy/setup.sh` (Phase 3) | Phase 2 config file exists | All user-space deploys (`~/.config/opencode/`) | **high** — missing deploy = users get no masking despite plugin active |
| `deploy/setup.ps1` (Phase 3) | Phase 2 config file exists | Windows user-space deploys | **high** — must mirror setup.sh exactly |
| `deploy/.AGENTS.md` (Phase 4) | — | Every primary session + every inherited subagent (deployed globally) | **high** — behavioral rules are the last-resort safety net |
| `AGENTS.md` repo root (Phase 5) | Phase 4 exists | Repo-scoped conventions only | low (one-liner pointer) |
| `security-audit-skill/SKILL.md` (Phase 6) | — | Any agent/user loading the skill for security audits | med (additive section — no existing content broken) |
| `README.md` + `opencode_app/README.md` (Phase 7) | Phases 1-6 complete | End users reading docs | low (documentation only) |
| `.gitignore` (Phase 8) | — | Git operations | low (confirm-only, optional comment addition) |

---

## Phase 1 — Harden `opencode_app/opencode.json` permission.read

_Owner: direct edit_

- [ ] **1.1** In `opencode_app/opencode.json` `permission.read`, add explicit deny rules: `"*.env": "deny"`, `"*.env.*": "deny"`, `"*.env.example": "allow"` alongside the existing `"mcp:*": "deny"`.
    — **Why:** The current config overrides the entire `read` permission object with only `"mcp:*": "deny"`. Whether OpenCode's built-in `.env` default-denies survive this override is ambiguous. Explicit re-declaration guarantees deny behavior regardless of upstream changes.
    — **Done when:** `jq '.permission.read' opencode_app/opencode.json` shows all four keys (`mcp:*`, `*.env`, `*.env.*`, `*.env.example`) with correct allow/deny values.
    — **Consumers affected:** Every session using this config (Docker standalone + user-space deploy).

- [ ] **1.2** In `opencode_app/opencode.json` `plugin` array (line 12), change `"opencode-vibeguard"` to `"opencode-vibeguard@0.1.0"`.
    — **Why:** Currently unpinned — a `latest` pull could break the regex config schema or masking behavior. Pinning ensures reproducible deploys.
    — **Done when:** `jq '.plugin[] | select(test("vibeguard"))' opencode_app/opencode.json` returns the pinned string.
    — **Consumers affected:** All deploys (setup.sh copies this file to `~/.config/opencode/`).

---

## Phase 2 — Create `opencode_app/.opencode/vibeguard.config.json`

_Owner: direct create_

- [ ] **2.1** Create `opencode_app/.opencode/vibeguard.config.json` with regex-only patterns (NO literal secrets).
    — **Why:** Vibeguard is already in the plugin array (line 12) but has no config — it is a no-op. This config activates it with shape-based regex patterns safe to commit, covering Broad+PII secret categories.
    — **Done when:** File exists at `opencode_app/.opencode/vibeguard.config.json`; `enabled: true`, `debug: false`; `patterns.regex` has 9 entries (OPENAI_KEY, AWS_ACCESS_KEY, GITHUB_TOKEN, GOOGLE_KEY, SLACK_TOKEN, DB_CONNECTION_STRING, PRIVATE_KEY, SECRET_ASSIGNMENT, JWT); `patterns.builtin` has `["email", "uuid", "ipv4", "mac"]`; `patterns.exclude` has `["localhost", "127.0.0.1", "0.0.0.0", "example.com", "*.example"]`; each regex entry has a `category` field.
    — **Consumers affected:** `opencode-vibeguard` plugin at runtime in every session.

---

## Phase 3 — Deploy vibeguard config via `setup.sh` + `setup.ps1`

_Owner: direct edit (both files)_

- [ ] **3.1** In `deploy/setup.sh`, add source/dest vars for `vibeguard.config.json` (source: `opencode_app/.opencode/vibeguard.config.json`, dest: `~/.config/opencode/vibeguard.config.json` — vibeguard's global lookup slot 4). Deploy it alongside config.json/AGENTS.md.
    — **Why:** Without deployment, the config file exists in the repo but never reaches `~/.config/opencode/` where vibeguard reads it. All deployed setups would have the plugin but no masking rules.
    — **Done when:** `setup.sh` copies vibeguard.config.json to the target directory; backup list includes it; restore logic picks it up (explicit handling, not just generic `*.json`).
    — **Consumers affected:** All user-space deploys via `./deploy/setup.sh`.

- [ ] **3.2** Mirror `setup.sh` changes in `deploy/setup.ps1` (Windows parity).
    — **Why:** The repo maintains setup.sh/setup.ps1 parity per the sync rules in AGENTS.md. Windows users must also receive the vibeguard config.
    — **Done when:** setup.ps1 deploys, backs up, and restores vibeguard.config.json identically to setup.sh.
    — **Consumers affected:** Windows user-space deploys via `deploy/setup.ps1`.

- [ ] **3.3** Update banner/status/help text in both scripts to mention "vibeguard secret masking: active".
    — **Why:** Users should see at deploy time that secret masking is active — serves as both documentation and verification signal.
    — **Done when:** Banner output includes vibeguard status line; help text references secret masking.
    — **Consumers affected:** Users running `setup.sh --dry-run` or reading banner output.

---

## Phase 4 — Add §Secret Hygiene to `deploy/.AGENTS.md`

_Owner: direct edit_

- [ ] **4.1** Add a new **§Secret Hygiene** section to `deploy/.AGENTS.md` with ~6-10 inline mandatory rules (NOT a bare pointer). Place it near the existing "Memory Hygiene" section (~line 113).
    — **Why:** Every primary session AND every inherited subagent reads `deploy/.AGENTS.md` (deployed to `~/.config/opencode/AGENTS.md`). Inline rules are non-optional — a pointer would be too easy for a subagent to skip. Rules: never echo `.env*` values in reply text; subagents report key NAMES not values; prefer `$VAR` env references over literals; vibeguard masks provider-bound traffic and restores at exec; never store secrets in memory tool or LEARNINGS verbatim.
    — **Done when:** Section exists with ≥6 inline rule lines; each rule is actionable (not a pointer); section ends with connector line: "For verification, per-project keyword setup, `$VAR` usage patterns, and fallback when vibeguard is disabled, load `security-audit-skill`."
    — **Consumers affected:** Every primary session and every subagent inheriting AGENTS.md globally.

---

## Phase 5 — Add one-liner pointer in repo-root `AGENTS.md`

_Owner: direct edit_

- [ ] **5.1** In `AGENTS.md` (repo root), add a one-line pointer under the repo conventions section referencing `deploy/.AGENTS.md §Secret Hygiene` and `security-audit-skill`.
    — **Why:** The repo-level AGENTS.md defines repo-specific conventions. A pointer ensures contributors know where the canonical secret-hygiene rules live and that the security-audit-skill has the full verification procedure.
    — **Done when:** One-liner exists pointing to both `deploy/.AGENTS.md §Secret Hygiene` and `security-audit-skill`.
    — **Consumers affected:** Agents working directly in this repo (not end-user sessions).

---

## Phase 6 — Extend `security-audit-skill/SKILL.md`

_Owner: direct edit_

- [ ] **6.1** Add a new "## Runtime Secret Masking (vibeguard)" section to `opencode_app/.opencode/skills/security-audit-skill/SKILL.md`.
    — **Why:** The skill is the canonical reference for security audits. Adding the vibeguard procedure here (rather than creating a new skill) avoids skill-count bloat and keeps all security verification in one place. Covers: how masking works (placeholder upstream, restore at exec, historical redaction), verification steps (`OPENCODE_VIBEGUARD_DEBUG=1 opencode`, `/share` safety check, grep session DB), per-project `keywords` setup (UNCOMMITTED `./vibeguard.config.json` with literals), `$VAR` usage pattern, fallback when vibeguard disabled, phase-2 pointer for `shell.env` injection plugin (~30 lines, deferred).
    — **Done when:** Section exists covering all 6 sub-topics listed above; no new skill file created; `security-audit-skill` remains the single entry point.
    — **Consumers affected:** Any agent or user loading `security-audit-skill` for security audits.

---

## Phase 7 — Document in READMEs

_Owner: direct edit_

- [ ] **7.1** Update `README.md` — document the vibeguard masking feature: what it does (regex-based secret masking before LLM provider), how users add per-project literal `keywords` (uncommitted `./vibeguard.config.json`), and note that `security-audit-skill` now covers runtime secret masking.
    — **Why:** End users need to know the feature exists, how it protects them, and how to extend it with per-project literals. The README is the primary user-facing doc.
    — **Done when:** README has a section or subsection on "Secret Masking" or "vibeguard" covering activation, per-project keywords (uncommitted), and `$VAR` best practice.
    — **Consumers affected:** Users reading the repo README.

- [ ] **7.2** Update `opencode_app/README.md` — add Docker-specific note that vibeguard config is baked into the image.
    — **Why:** Docker standalone users get the config via the image build, not setup.sh. They need to know per-project overlay still works (mount a `./vibeguard.config.json`).
    — **Done when:** Docker README mentions vibeguard masking and per-project overlay mechanism.
    — **Consumers affected:** Docker standalone users.

---

## Phase 8 — Confirm `.gitignore` hygiene

_Owner: direct edit (optional)_

- [ ] **8.1** Verify `opencode_app/.opencode/vibeguard.config.json` is NOT in `.gitignore` (it is regex-only, safe to commit). Verify `.env` stays ignored (already at line 23).
    — **Why:** The global vibeguard config is regex-only with no secrets — it MUST be tracked so deploys receive it. Conversely, `.env` files must remain ignored. A misconfiguration here either leaks the config (no risk — regex only) or fails to deploy it (users unprotected).
    — **Done when:** `git check-ignore opencode_app/.opencode/vibeguard.config.json` returns nothing (tracked); `git check-ignore .env` returns `.env` (ignored). Optionally add a comment in `.gitignore` documenting that users should gitignore their per-project `./vibeguard.config.json` if it contains literal keywords.
    — **Consumers affected:** Git tracking behavior for this repo and downstream users.

---

## Phase 9 — Verification

_Owner: manual + automated_

- [ ] **9.1** Run `OPENCODE_VIBEGUARD_DEBUG=1 opencode` with a test `.env.local` containing known secrets → confirm replace-counts > 0 in debug output.
    — **Why:** This is the primary smoke test that vibeguard is active and matching real secrets.
    — **Done when:** Debug log shows regex matches and placeholder substitutions for test secrets.
    — **Consumers affected:** None (verification only).

- [ ] **9.2** Prompt "show DATABASE_URL from .env.local" → confirm transcript shows `__VG_…__` placeholder, never plaintext.
    — **Why:** Validates end-to-end masking of read-tool output in provider-bound requests.
    — **Done when:** Transcript inspection reveals no plaintext secret values.
    — **Consumers affected:** None (verification only).

- [ ] **9.3** Prompt "write a script using DATABASE_URL" → confirm output uses `$DATABASE_URL` or vibeguard restores the placeholder at exec time; provider-bound transcript is clean.
    — **Why:** Validates that tool execution (bash/write) receives real values while the provider never sees them.
    — **Done when:** Generated script references `$DATABASE_URL`; provider transcript contains only placeholders.
    — **Consumers affected:** None (verification only).

- [ ] **9.4** Run `/share` on a session that used secrets → confirm shared link contains no plaintext; grep session DB for a known literal → expect 0 hits.
    — **Why:** Validates historical redaction — the most dangerous leak vector (persisted tool outputs replayed on later turns).
    — **Done when:** Shared link inspection clean; session DB grep returns 0 matches for known test secrets.
    — **Consumers affected:** None (verification only).
