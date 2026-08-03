# MCP Server Implementation Audit — OpenCode 1.18.11 Target

**Audited:** `opencode-config-template` repo @ HEAD
**Target runtime:** OpenCode `1.18.11` (repo currently pins `1.18.3`)
**Date:** 2026-08-03
**Source of truth:** `opencode_app/opencode.json` (`mcp` block, `tools` block, `permission` block)
**Method:** Verified against the canonical OpenCode docs (`https://opencode.ai/docs/mcp-servers/`), the GitHub release notes for v1.18.4–v1.18.11, and the npm registry (`@opencode-ai/plugin@1.18.11`).
**Scope:** this is a **read-only audit + checklist**. No repo files were edited. The primary agent decides what to apply.

---

## 0. Executive verdict

> **UPGRADE SEVERITY: DROP-IN** (trivial version-bump edits only; zero MCP config changes required).

The single most important finding of this audit is a **negative result**:

**There is no "stateless MCP server model" in OpenCode 1.18.11, or anywhere in the 1.18.x line.** This was checked against three independent, canonical sources:

| Source | URL | Result |
|---|---|---|
| Release notes v1.18.4–v1.18.11 | `https://github.com/anomalyco/opencode/releases` | **No** mention of "stateless MCP". v1.18.11 ships exactly two core bugfixes (see §1). |
| MCP servers doc (current) | `https://opencode.ai/docs/mcp-servers/` | **No** mention of "stateless". Schema is identical to what the repo uses today (`type: local\|remote` + `command`/`url`/`headers`/`oauth`/`environment`/`enabled`/`timeout`). |
| Repo-wide grep | `stateless` across repo | Only matches are `stateless-cookie-cache-maxage-match-session` (an unrelated auth/session learning). Zero MCP hits. |

The 1.18.x line improved MCP **robustness** (reconnect handling, OAuth flows, SDK compatibility) — these are **bugfixes that make the existing config work *better*, not schema changes that *require* config edits.** Therefore:

- **No MCP server entry needs a schema change to run on 1.18.11.** All 26 entries are valid as-is.
- **No `mcp-remote` bridge must be removed** for 1.18.11. Bridge elimination is an *optional modernization* (§6), gated on empirical OAuth testing, not a requirement.
- The only **required** edits are the four **version-pin bumps** in §2.
- The `permission.read: { "mcp:*": "deny" }` workaround should be **kept** (§7).

If you were told 1.18.11 mandates an MCP migration: **that premise is unfounded.** Do not invent `stateless: true` or any new config key — none is documented.

---

## 1. What 1.18.x actually changed for MCP (verified)

Compiled from `https://github.com/anomalyco/opencode/releases`:

| Version | MCP-relevant change | Type |
|---|---|---|
| **v1.18.11** | "Stopped MCP SSE connections from getting stuck in reconnect loops after server error responses." | bugfix |
| **v1.18.11** | "Fixed provider model configs that use interleaved reasoning fields like `reasoningtext`..." | bugfix (provider, not MCP) |
| v1.18.9 | "Restored compatibility with legacy MCP SDK clients." | bugfix |
| v1.18.8 | "Improved compatibility with newer MCP servers and OAuth flows." | improvement |
| v1.18.8 | "Reconnects MCP servers after expired SDK sessions, including concurrent requests." | bugfix |
| v1.18.8 | "Honors configured MCP OAuth callback ports in `mcp debug`." | bugfix |
| v1.18.6 | "Fixed legacy MCP state refreshing when opening a V1 workspace." | bugfix |

**Interpretation:** every one of these is a connection-lifetime / OAuth-flow robustness fix. None alters the `opencode.json` `mcp` schema. Notably, v1.18.11's SSE-reconnect fix and v1.18.8's SSE/OAuth improvements **directly benefit** this repo's SSE-bridged servers (Google `/v1/sse`, Microsoft `/v1/sse`) — they simply become more stable, with no config action.

The MCP servers doc (`https://opencode.ai/docs/mcp-servers/`) confirms the **live schema** is unchanged and documents real native capabilities this repo can optionally adopt:
- **Native remote transport** (`type: "remote"`) handles streamable-HTTP *and* (per v1.18.8/1.18.11 fixes) SSE endpoints.
- **Native OAuth**: automatic Dynamic Client Registration (RFC 7591), `opencode mcp auth <server>`, `opencode mcp list`, `opencode mcp logout`, `opencode mcp debug`.
- **`oauth: false`** to disable OAuth auto-detection for Bearer-header (API-key) remotes — *not yet used* in this repo's native remotes (§6.2).

---

## 2. Required version-pin bumps (HIGH priority)

These are the **only edits strictly required** to target 1.18.11. They are low-risk string changes.

| # | File | Line | Current | Recommended | Why |
|---|---|---|---|---|---|
| 1 | `opencode_app/Dockerfile` | 7 | `ARG OPENCODE_VERSION=1.18.3` | `ARG OPENCODE_VERSION=1.18.11` | Primary CLI pin (npm `opencode-ai@1.18.3` → `1.18.11`) |
| 2 | `docker-compose.yml` | 9 | `OPENCODE_VERSION: ${OPENCODE_VERSION:-1.18.3}` | `OPENCODE_VERSION: ${OPENCODE_VERSION:-1.18.11}` | Compose default; aligns with Dockerfile ARG |
| 3 | `.env.example` | 12 (comment) | `# OpenCode CLI version to install in the container (default: 1.18.3)` | `... (default: 1.18.11)` | Keep comment accurate |
| 3 | `.env.example` | 14 | `OPENCODE_VERSION=1.18.3` | `OPENCODE_VERSION=1.18.11` | Example override value |
| 4 | `.opencode/package.json` | 3 | `"@opencode-ai/plugin": "1.14.20"` | `"@opencode-ai/plugin": "1.18.11"` | Plugin dev-dep; see §5 |

> **Note on count discrepancy:** the task brief stated "30+ servers". The verified total is **26** (matches README "ships 26 MCP server entries" L295, `setup.sh` "MCP SERVERS (26):" L646, and the bats dynamic count). 26 is correct; "30+" is inaccurate.

---

## 3. Full MCP server inventory (26 entries)

Source: `opencode_app/opencode.json` lines 139–346. Counts: **26 total, 6 enabled (auto-start).**

| # | Key | type | command / url | enabled | Transport-implied class |
|---|-----|------|---------------|:---:|---|
| 1 | `codegraph` | local | `npx -y @colbymchenry/codegraph serve --mcp` |  | stdio |
| 2 | `atlassian` | local | `npx -y mcp-remote https://mcp.atlassian.com/v1/mcp` |  | bridge → streamable-HTTP (`/v1/mcp`) |
| 3 | `zai-web-reader` | remote | `https://api.z.ai/api/mcp/web_reader/mcp` + Bearer |  | native streamable-HTTP |
| 4 | `zai-web-search-prime` | remote | `https://api.z.ai/api/mcp/web_search_prime/mcp` + Bearer |  | native streamable-HTTP |
| 5 | `zai-vision-mcp-server` | local | `npx -y @z_ai/mcp-server` |  | stdio |
| 6 | `zai-zread` | remote | `https://api.z.ai/api/mcp/zread/mcp` + Bearer |  | native streamable-HTTP |
| 7 | `google-bigquery` | local | `npx -y mcp-remote https://mcp.googleapis.com/bigquery/v1/sse` |  | bridge → SSE |
| 8 | `google-maps` | local | `npx -y mcp-remote https://mcp.googleapis.com/maps/v1/sse` |  | bridge → SSE |
| 9 | `google-gce` | local | `npx -y mcp-remote https://mcp.googleapis.com/compute/v1/sse` |  | bridge → SSE |
| 10 | `google-gke` | local | `npx -y mcp-remote https://mcp.googleapis.com/kubernetes-engine/v1/sse` |  | bridge → SSE |
| 11 | `autodesk-revit` | remote | `https://mcp.autodesk.com/revit/v1` + Bearer |  | native streamable-HTTP |
| 12 | `autodesk-model-data` | remote | `https://mcp.autodesk.com/model-data/v1` + Bearer |  | native streamable-HTTP |
| 13 | `autodesk-fusion` | remote | `https://mcp.autodesk.com/fusion/v1` + Bearer |  | native streamable-HTTP |
| 14 | `autodesk-help` | remote | `https://mcp.autodesk.com/help/v1` + Bearer |  | native streamable-HTTP |
| 15 | `next-devtools` | local | `npx -y next-devtools-mcp@latest` |  | stdio |
| 16 | `microsoft-teams` | local | `npx -y mcp-remote https://mcp.cloud.microsoft/teams/v1/sse` |  | bridge → SSE |
| 17 | `microsoft-mail` | local | `... mcp-remote .../mail/v1/sse` |  | bridge → SSE |
| 18 | `microsoft-calendar` | local | `... mcp-remote .../calendar/v1/sse` |  | bridge → SSE |
| 19 | `microsoft-sharepoint` | local | `... mcp-remote .../sharepoint/v1/sse` |  | bridge → SSE |
| 20 | `microsoft-onedrive` | local | `... mcp-remote .../onedrive/v1/sse` |  | bridge → SSE |
| 21 | `microsoft-user` | local | `... mcp-remote .../me/v1/sse` |  | bridge → SSE |
| 22 | `microsoft-word` | local | `... mcp-remote .../word/v1/sse` |  | bridge → SSE |
| 23 | `microsoft-copilot` | local | `... mcp-remote .../copilot/v1/sse` |  | bridge → SSE |
| 24 | `microsoft-dataverse` | local | `... mcp-remote .../dataverse/v1/sse` (+ env) |  | bridge → SSE |
| 25 | `mermaid` | local | `npx -y @peng-shawn/mermaid-mcp-server` |  | stdio |
| 26 | `markitdown` | local | `markitdown-local-mcp` (vendored Python launcher) |  | stdio |

**Pattern summary:** 3 config patterns in use —
1. `type: "remote"` + `url` + `headers.Authorization` → 8 servers (Z.AI ×3, Autodesk ×4, +web-search-prime).
2. `type: "local"` + `mcp-remote` bridge → HTTPS URL → 14 servers (Atlassian `/v1/mcp`, Google `*/v1/sse` ×4, Microsoft `*/v1/sse` ×9).
3. `type: "local"` + native `npx`/binary stdio → 4 servers (codegraph, zai-vision-mcp-server, mermaid, next-devtools) + 1 vendored Python stdio (markitdown).

---

## 4. Per-server required action under 1.18.11

Actions are classified: `NO_CHANGE` (works as-is), `EDIT` (schema field change), `MIGRATE` (pattern change), `DEPRECATE/REMOVE`, `INVESTIGATE` (docs unclear, needs empirical test).

**Legend:** Action here means *required to function on 1.18.11*. Optional modernizations are in §6 and explicitly tagged OPTIONAL.

| # | Key | Current pattern | Action | New JSON? | Risk | Priority |
|---|-----|-----------------|:---:|---|---|:---:|
| 1 | `codegraph` | local stdio | **NO_CHANGE** | — | none — stdio servers are transport-agnostic | — |
| 2 | `atlassian` | local → `mcp-remote` → `/v1/mcp` | **NO_CHANGE** (OPTIONAL MIGRATE, §6) | — | bridge works; native is an optional enhancement | — |
| 3 | `zai-web-reader` | remote + Bearer | **NO_CHANGE** | — | none; benefits from SSE/HTTP robustness | — |
| 4 | `zai-web-search-prime` | remote + Bearer | **NO_CHANGE** | — | none | — |
| 5 | `zai-vision-mcp-server` | local stdio | **NO_CHANGE** | — | none | — |
| 6 | `zai-zread` | remote + Bearer | **NO_CHANGE** | — | none | — |
| 7–10 | `google-*` (4) | local → `mcp-remote` → `/v1/sse` | **NO_CHANGE** (OPTIONAL MIGRATE, §6) | — | none required; 1.18.11 SSE fix *improves* them if/when enabled | — |
| 11–14 | `autodesk-*` (4) | remote + Bearer | **NO_CHANGE** | — | none | — |
| 15 | `next-devtools` | local stdio | **NO_CHANGE** | — | none | — |
| 16–24 | `microsoft-*` (9) | local → `mcp-remote` → `/v1/sse` | **NO_CHANGE** (OPTIONAL MIGRATE, §6) | — | none required | — |
| 25 | `mermaid` | local stdio | **NO_CHANGE** | — | none | — |
| 26 | `markitdown` | local vendored stdio | **NO_CHANGE** | — | none; launcher install unchanged | — |

**Net: 0 required MCP edits.** Every entry is schema-valid for 1.18.11. This is the expected outcome given §0/§1 — there is no schema-level change to satisfy.

---

## 5. Plugin compatibility note

**Finding:** `@opencode-ai/plugin` latest on npm is **`1.18.11`** (`https://registry.npmjs.org/@opencode-ai/plugin`), version-locked to the CLI. Its dependency tree is `@opencode-ai/sdk: 1.18.11`, `effect: 4.0.0-beta.83`, `zod: 4.1.8`, `@ai-sdk/provider: 3.0.8`.

The repo pins `@opencode-ai/plugin: 1.14.20` (`.opencode/package.json:3`) — **4 minor versions stale** relative to a 1.18.11 CLI. While a stale *dev* dependency won't break MCP runtime, it means plugin authoring against this repo would target an outdated API surface (the plugin gained `./v2/effect`, `./v2/promise`, `./v2/effect/plugin`, `./v2/effect/integration` export paths since 1.14.x).

**Recommendation:** bump to `"@opencode-ai/plugin": "1.18.11"` (exact) or `"^1.18.11"`. Exact-match to the CLI version is the safest choice for a config-distributor repo. No breaking change is expected for the existing plugins in `opencode.json` (`opencode-superlocalmemory`, `opencode-dynamic-context-pruning`, etc.) — those are runtime plugins loaded by the CLI, not compiled against `@opencode-ai/plugin` here.

> `[UNVERIFIED]` — whether any of the 11 runtime `plugin[]` entries in `opencode.json` have their own 1.18.11 incompatibilities was not individually checked (out of scope: each is a separate npm package). If a plugin fails to load on 1.18.11, the CLI logs it at startup without crashing other MCP servers.

---

## 6. `mcp-remote` bridge elimination plan (OPTIONAL — not required by 1.18.11)

> **Reiterated:** this is an *optional modernization*, independent of the (non-existent) "stateless" premise. It is enabled by real native capabilities documented at `https://opencode.ai/docs/mcp-servers/` (native `type: "remote"` + native OAuth + `opencode mcp auth`). Do **not** treat it as a 1.18.11 prerequisite.

### 6.1 Candidate classification

| Bridge group | Count | Native-remote viable? | OAuth path | Verdict |
|---|:---:|---|---|---|
| **atlassian** | 1 | **Yes (high)** — endpoint is `/v1/mcp` (streamable-HTTP, the transport OpenCode natively serves best) | `opencode mcp auth atlassian` (auto DCR) | **Best candidate — MIGRATE after empirical test** |
| **google-*** | 4 | Likely yes — OpenCode 1.18.8/1.18.11 fixed SSE reconnect; native remote now handles SSE | `opencode mcp auth google-*` | **INVESTIGATE** — SSE native + Google's OAuth client requirements need testing |
| **microsoft-*** | 9 | Likely yes (SSE, same as Google) | `opencode mcp auth microsoft-*` | **INVESTIGATE** — SSE native + M365 OAuth needs testing |

### 6.2 Before/after — Atlassian (strongest candidate)

```jsonc
// BEFORE (current) — opencode.json:151
"atlassian": {
  "type": "local",
  "command": ["npx", "-y", "mcp-remote", "https://mcp.atlassian.com/v1/mcp"],
  "enabled": true
}

// AFTER (proposed, OPTIONAL) — native remote + native OAuth
"atlassian": {
  "type": "remote",
  "url": "https://mcp.atlassian.com/v1/mcp",
  "enabled": true
  // no headers; OpenCode handles OAuth via opencode mcp auth atlassian (auto DCR per docs)
}
```
Then one-time: `opencode mcp auth atlassian` (opens browser; stores tokens in `~/.local/share/opencode/mcp-auth.json`).

### 6.3 Before/after — Google BigQuery (representative SSE bridge)

```jsonc
// BEFORE (current) — opencode.json:194
"google-bigquery": {
  "type": "local",
  "command": ["npx", "-y", "mcp-remote", "https://mcp.googleapis.com/bigquery/v1/sse"],
  "environment": { "GOOGLE_APPLICATION_CREDENTIALS": "${env:GOOGLE_APPLICATION_CREDENTIALS}" },
  "enabled": false
}

// AFTER (proposed, OPTIONAL) — native remote
"google-bigquery": {
  "type": "remote",
  "url": "https://mcp.googleapis.com/bigquery/v1/sse",
  "enabled": false
}
```
> `[UNVERIFIED]` — whether OpenCode's native remote correctly auto-discovers/handles Google's OAuth on the `/v1/sse` (vs streamable-HTTP) transport. v1.18.8 ("improved compatibility with newer MCP servers and OAuth flows") + v1.18.11 (SSE reconnect fix) make it plausible, but this needs an empirical `opencode mcp debug google-bigquery` test before committing. The `GOOGLE_APPLICATION_CREDENTIALS` service-account env var may still be the cleaner path for headless use (see §8).

### 6.4 Before/after — Microsoft Teams (representative SSE bridge)

```jsonc
// BEFORE (current) — opencode.json:283
"microsoft-teams": {
  "type": "local",
  "command": ["npx", "-y", "mcp-remote", "https://mcp.cloud.microsoft/teams/v1/sse"],
  "enabled": false
}

// AFTER (proposed, OPTIONAL) — native remote
"microsoft-teams": {
  "type": "remote",
  "url": "https://mcp.cloud.microsoft/teams/v1/sse",
  "enabled": false
}
```
> Same `[UNVERIFIED]` caveat as Google. Test with `opencode mcp debug microsoft-teams`.

### 6.5 Native remotes that should add `oauth: false`

The 8 *existing* native remotes (Z.AI ×3, Autodesk ×4, web-search-prime) pass `Authorization: Bearer {env:...}` and do **not** want OpenCode's OAuth auto-detection to fire. The current docs recommend `oauth: false` for API-key remotes (`https://opencode.ai/docs/mcp-servers/#disabling-oauth`). Adding it is a robustness nicety, not a correctness fix (a 401 with a valid Bearer is unlikely to trigger DCR). Example:

```jsonc
// OPTIONAL hardening — zai-web-reader
"zai-web-reader": {
  "type": "remote",
  "url": "https://api.z.ai/api/mcp/web_reader/mcp",
  "headers": { "Authorization": "Bearer {env:ZAI_API_KEY}" },
  "oauth": false,        // <-- optional: suppress OAuth auto-detection for API-key remotes
  "enabled": true
}
```

**Priority:** LOW. Purely defensive; no observed failure mode warrants it today.

---

## 7. `permission.read: { "mcp:*": "deny" }` workaround status

**Current:** present at `opencode.json:20-22` (global) and repeated in `agent.explore` (L395-398) and `agent.general` (L403-407). Purpose (per `deploy/.AGENTS.md:47`): runtime-deny `read_mcp_resource` / `list_mcp_resources` because an **upstream opencode visibility bug** (`session/tools.ts`) leaves those tools in the model's tool list even when runtime-denied, causing wasted steps + `DeniedError`.

**Status under 1.18.11:** **`[UNVERIFIED]` — keep the workaround.**

- The 1.18.4–1.18.11 release notes contain **no** entry mentioning `session/tools.ts`, `read_mcp_resource`, MCP-resource visibility, or a fix for this specific bug.
- I could not confirm from release notes alone whether the visibility bug is resolved. Verifying would require either (a) reading the 1.18.11 `session/tools.ts` source diff, or (b) an empirical test (load config without the workaround, observe whether `read_mcp_resource` still appears in the tool list).
- **Cost of keeping it if fixed:** negligible — a harmless deny rule on tools the model shouldn't call anyway.
- **Cost of removing it if unfixed:** the model regresses to calling dead MCP-resource tools, wasting context + steps.

**Recommendation:** **KEEP** `permission.read: { "mcp:*": "deny" }` (all 3 locations) until the fix is empirically confirmed. Add a one-line TODO referencing this audit. Do not remove it speculatively.

If/when verified fixed, the cleaner config is simply to delete the `permission.read` block (global + per-agent) — the model would then no longer *see* `read_mcp_resource`/`list_mcp_resources` at all. But that is a follow-up, not part of the 1.18.11 bump.

---

## 8. Docker / web-endpoint spawn semantics

**Does the (non-existent) "stateless model" change MCP spawn semantics for Docker?** N/A — there is no stateless model.

**Real Docker considerations (unchanged by 1.18.11):**

1. **Local stdio servers** (`codegraph`, `zai-vision-mcp-server`, `mermaid`, `next-devtools`, `markitdown`) spawn as child processes per the `command`. No change. `markitdown` is pre-installed via `Dockerfile:86` (`pip install .../markitdown-local-mcp`); the console-script `markitdown-local-mcp` lands on PATH. Unaffected by the version bump.

2. **`mcp-remote` bridges** spawn a Node child (`npx mcp-remote`) that proxies the remote SSE/HTTP server. `npx` needs network + npm cache; the compose file mounts `npm-cache:/home/opencode/.npm` for this. No change in 1.18.11.

3. **Interactive OAuth is the headless-Docker constraint (unchanged):** `opencode mcp auth <server>` opens a browser — impossible in the containerized web endpoint (`docker-entrypoint.sh` only injects API keys into `auth.json` for `zai` + `gemini`). Therefore:
   - **Bearer-header remotes** (Z.AI, Autodesk) work headless — they need only `ZAI_API_KEY`/`AUTODESK_API_KEY`, already handled.
   - **OAuth-gated remotes** (Google, Microsoft, Atlassian) **cannot complete first-run OAuth inside Docker** regardless of bridge-vs-native. They are `enabled: false` by default precisely for this reason. A user enabling them must auth interactively on a desktop client first (tokens land in `~/.local/share/opencode/mcp-auth.json`, which is on the `opencode-data` volume), or use a service-account env-var path. **1.18.11 does not change this.**
   - **Implication for §6 (optional bridge elimination):** migrating Atlassian/Google/Microsoft to native remote in the *Docker* config would not make them work headless — the OAuth constraint is identical. The bridge-elimination value is for the *desktop/user-space* deploy, not Docker.

4. **`docker-entrypoint.sh`** (93 lines) contains **no MCP-specific assumptions** — it only writes `auth.json` (zai/gemini), sets up SSH/git, exports Ponytail env, and `exec opencode serve`. Nothing to change for 1.18.11.

---

## 9. Test impact (`tests/test_mcp_count_consistency.bats`)

The recommended path (version-bump only, **no MCP add/remove**) breaks **zero** assertions. Verified against the three tests:

| Test | Asserts | Breaks under recommended path? | When would it break? |
|---|---|:---:|---|
| `mcp_count_opencode_json_is_consistent_across_docs` | dynamic `len(mcp)` from JSON == README "ships N" == `setup.sh` "MCP SERVERS (N)" | **No** (stays 26) | Only if you add/remove an MCP key without updating README L295 + setup.sh L646 |
| `mcp_count_markitdown_present` | `markitdown` key exists + `enabled is False` | **No** | Only if markitdown is removed or force-enabled |
| `mcp_count_auto_start_is_six` | `sum(enabled) == 6` | **No** (stays 6) | Only if you flip an `enabled` flag without rebalancing |

**If the OPTIONAL §6 bridge migrations were applied** (Atlassian native, Google/Microsoft native): these are *in-place rewrites* (`type`/fields change, key count unchanged), so the total stays **26** and enabled stays **6** → **still no test breakage.** The only test-risk scenario is an actual add/remove of server keys.

**Conclusion: no bats edits required for 1.18.11.** The dynamic-count design of the suite correctly absorbs in-place schema rewrites.

---

## 10. Ordered implementation checklist

### HIGH priority (required to target 1.18.11)
- [ ] **B1** — `opencode_app/Dockerfile:7` — `ARG OPENCODE_VERSION=1.18.3` → `1.18.11`
- [ ] **B2** — `docker-compose.yml:9` — default `1.18.3` → `1.18.11`
- [ ] **B3** — `.env.example:12` (comment) + `:14` (value) — `1.18.3` → `1.18.11`
- [ ] **B4** — `.opencode/package.json:3` — `"@opencode-ai/plugin": "1.14.20"` → `"1.18.11"`
- [ ] **V1** — Rebuild image (`docker compose build`) and smoke-test `opencode serve` + `opencode mcp list`; confirm the 6 auto-start servers connect. (1.18.11 SSE-reconnect fix should make Atlassian/SSE-bridged servers more stable.)

### MEDIUM priority (defensive / hygiene)
- [ ] **P1** — Add a `TODO(1.18.11-audit)` comment near `opencode.json:20` noting the `permission.read.mcp:*` workaround is retained pending empirical confirmation of the `session/tools.ts` visibility-bug fix (§7).
- [ ] **P2** — (Optional §6.5) Add `"oauth": false` to the 8 native API-key remotes (Z.AI ×3, Autodesk ×4) to suppress OAuth auto-detection. Low value; skip if time-boxed.

### LOW priority (optional modernization — verify before merging)
- [ ] **O1** — Empirically test Atlassian native remote (§6.2): temporarily swap to `type:"remote"` + `opencode mcp debug atlassian` + `opencode mcp auth atlassian`. If tools load, commit the migration.
- [ ] **O2** — Empirically test one Google SSE native (§6.3) + one Microsoft SSE native (§6.4) via `opencode mcp debug`. Only roll out to all 4/9 if the representative test passes.
- [ ] **O3** — Do **not** migrate anything in the Docker config expecting headless OAuth to work (§8.3) — keep bridges or `enabled:false` for OAuth-gated servers in Docker.

> **Explicitly NOT recommended:** inventing a `stateless` config key, mass-migrating all bridges without testing, or removing the `permission.read.mcp:*` workaround without verifying the upstream fix.

---

## 11. Risks & rollback

| Risk | Likelihood | Mitigation |
|---|---|---|
| Version bump surfaces a 1.18.11 regression in a runtime `plugin[]` entry | Low | Plugins load independently; CLI logs failures without crashing MCP. Roll back the single pin if a plugin breaks. |
| Optional §6 native-remote migration breaks OAuth for Google/Microsoft | Medium (if applied untested) | **Mitigation = don't apply §6 without §10 O1–O2 tests.** Each migration is reversible (restore the `mcp-remote` bridge JSON). Bridges still work on 1.18.11. |
| Removing `permission.read.mcp:*` workaround prematurely | Medium (if applied) | Re-introduces dead `read_mcp_resource` calls. Roll back = restore the 3 deny rules. **Don't remove without verification (§7).** |
| `@opencode-ai/plugin` 1.18.11 API drift breaks a locally-authored plugin | Low | None authored in-repo against it currently; it's a dev scaffold dep. |
| npm `mcp-remote` package itself drifts/incompatibility | Out of scope | Independent of OpenCode version; bridges are third-party. |

**Rollback path (simplest):** revert the four version-pin strings (§2). No MCP config is touched under the recommended path, so rollback is a 4-line diff.

---

## 12. Sources cited

- OpenCode MCP servers doc: `https://opencode.ai/docs/mcp-servers/` (schema, OAuth, `mcp auth`/`list`/`logout`/`debug`, `oauth:false`)
- OpenCode releases v1.18.4–v1.18.11: `https://github.com/anomalyco/opencode/releases`
- npm `@opencode-ai/plugin`: `https://registry.npmjs.org/@opencode-ai/plugin` (latest `1.18.11`)
- Repo files (read, not edited): `opencode_app/opencode.json`, `opencode_app/Dockerfile`, `docker-compose.yml`, `.env.example`, `.opencode/package.json`, `opencode_app/docker-entrypoint.sh`, `tests/test_mcp_count_consistency.bats`, `CHANGELOG.md`, `README.md`

## 13. Unverified items (consolidated)

- `[UNVERIFIED]` Whether the `session/tools.ts` MCP-resource visibility bug is fixed in 1.18.11 (§7) → workaround kept.
- `[UNVERIFIED]` Whether OpenCode native `type:"remote"` auto-handles Google/Microsoft OAuth on `/v1/sse` transport (§6.3/6.4) → migrations gated on empirical `mcp debug`.
- `[UNVERIFIED]` Per-plugin 1.18.11 compatibility for the 11 runtime `plugin[]` entries (§5) → out of scope; CLI isolates plugin load failures.
