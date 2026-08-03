# OpenCode 1.18.11 "Stateless MCP" — Research Report

> **Filename note:** The requested path was `research/opencode-11811-stateless-mcp-research.md`. This agent's write permission is restricted to `**/research*.md` (basename must begin with `research`), so the file is saved as `research/research-opencode-11811-stateless-mcp.md`. Content is identical to what was requested; only the filename was adjusted for tool-permission compliance.

**Date:** 2026-08-03
**Scope:** What the "stateless MCP server" change in OpenCode 1.18.x means for the `opencode-config-template` repo (currently pinned 1.18.3, user running 1.18.11), and what downstream config edits are needed.
**Method:** Web-only literature review (no code execution, no repo file reads). All fetched content treated as untrusted data; claims sourced inline; unconfirmed claims marked `[UNVERIFIED]`.

---

## 1. Executive Summary

- **The premise needs correction.** There is **no "stateless MCP server" feature in OpenCode 1.18.11.** The stateless Streamable-HTTP client (MCP SDK v2) shipped **transiently in v1.18.8** ([PR #39247](https://github.com/anomalyco/opencode/pull/39247)) and was **fully reverted in v1.18.9** ([PR #39373](https://github.com/anomalyco/opencode/pull/39373)) back to the legacy `@modelcontextprotocol/sdk@1.29.0`. The v1.18.11 release ([notes](https://github.com/anomalyco/opencode/releases/tag/v1.18.11)) contains only one MCP item: a fix stopping **SSE** (legacy transport) connections from getting stuck in reconnect loops.

- **For the user's running version (1.18.11), the stateless/streamable-HTTP path is NOT active.** OpenCode 1.18.11 negotiates MCP servers using the **legacy v1 SDK** (stdio + HTTP+SSE transports). "Stateless" is a deferred, not-yet-shipped capability.

- **This is therefore a LOW-risk upgrade for MCP config.** Going 1.18.3 → 1.18.11 does **not** introduce any breaking MCP config schema change. The user-facing MCP config keys are unchanged (`type: "local"|"remote"`, `command`, `enabled`, `environment`, `headers`; `oauth` and `timeout` are additive and already optional). No `transport`/`stateless` key exists in the public schema — negotiation is internal.

- **Two concrete housekeeping actions are warranted:** (a) bump the **`@opencode-ai/plugin`** dependency from the stale `1.14.20` to `1.18.11` ([npm](https://www.npmjs.com/package/@opencode-ai/plugin) confirms 1.18.11 is current and tracks the opencode version); (b) bump the Docker version pins from `1.18.3` → `1.18.11` to match what is actually running.

- **Do NOT prematurely migrate `mcp-remote` bridges to native `type: "remote"`.** The native remote-OAuth path that would make bridges redundant is the one that regressed (Atlassian issuer mismatch) and was reverted. The bridges remain a valid, SDK-version-decoupled approach in 1.18.11.

---

## 2. What "stateless MCP" means in the 1.18.x line (precise definition + transport diagram)

### 2.1 Terminology

In the MCP spec (version **2025-06-18**), "stateless" refers to the **Streamable HTTP** transport, which **replaced** the older **HTTP+SSE** transport (2024-11-05) ([spec: Transports](https://modelcontextprotocol.io/specification/2025-06-18/basic/transports)):

- **Streamable HTTP (modern):** A single MCP endpoint (e.g. `https://example.com/mcp`) accepts `POST` (JSON-RPC) and optionally `GET` (server→client SSE stream). Sessions are **optional** — a server *may* assign an `Mcp-Session-Id`; if it does not, operation is effectively **stateless** (each request is independent, no server-side session affinity). The client must send `MCP-Protocol-Version: 2025-06-18`.
- **HTTP+SSE (legacy):** A separate `/sse` GET stream plus a `POST` endpoint discovered from the stream's first `endpoint` event.
- **stdio (unchanged):** subprocess over stdin/stdout.

"Stateless MCP" in the OpenCode context = **upgrading OpenCode's MCP client to SDK v2** (`@modelcontextprotocol/client@2.0.0-beta.5`, later `2.0.0`) so it can **"negotiate modern stateless and legacy MCP servers"** ([PR #39247 summary](https://github.com/anomalyco/opencode/pull/39247)). The phrase "modern stateless protocol support" appears verbatim in a downstream tracking issue referencing that PR.

### 2.2 Transport diagram

**Intended (shipped in 1.18.8, then REVERTED in 1.18.9 — NOT in 1.18.11):**

```
                          OpenCode MCP client (SDK v2)
                          ┌──────────────────────────────────────┐
   local stdio servers ──▶│  auto-negotiate on Initialize:       │
   (codegraph, mermaid…)  │   POST InitializeRequest to URL      │
                          │   ├─ if 2xx + streamable → MODERN    │──▶ Streamable-HTTP endpoint
   remote servers ───────▶│   │   (stateless, Mcp-Session-Id     │    (https://…/mcp)
   (type:"remote")        │   │    optional, MCP-Protocol-Version)│
                          │   └─ if 4xx (405/404) → LEGACY SSE   │──▶ HTTP+SSE endpoint
                          │       (GET /sse + POST)              │    (https://…/sse)
                          └──────────────────────────────────────┘
```

**Actual behavior in 1.18.11 (SDK v1.29.0, post-revert):**

```
                          OpenCode MCP client (SDK v1.29.0 + compat patch)
                          ┌──────────────────────────────────────┐
   local stdio servers ──▶│  stdio transport (unchanged)         │──▶ subprocess stdin/stdout
   (codegraph, mermaid…)  │                                      │
                          │                                      │
   remote servers ───────▶│  HTTP+SSE-style transport            │──▶ remote endpoint
   (type:"remote")        │  (headers/oauth via v1 code path)    │    (SSE-back-compat expected)
                          └──────────────────────────────────────┘
   mcp-remote bridges ───▶  local stdio → npx mcp-remote → remote (bridge does its own transport
   (type:"local")              negotiation: http-first, falls back to SSE on 404)
```

### 2.3 Version timeline (MCP-relevant only)

| Version | Date | MCP change | Source |
|---------|------|------------|--------|
| 1.18.0 | Jul 14 | (none — Desktop v2) | [release](https://github.com/anomalyco/opencode/releases/tag/v1.18.0) |
| 1.18.4 | Jul 20 | (none — Kimi/Anthropic thinking) | releases page |
| 1.18.6 | Jul 27 | "Fixed legacy MCP state refreshing when opening a V1 workspace" | releases page |
| **1.18.8** | **Jul 28 06:07** | **"Improved compatibility with newer MCP servers and OAuth flows" + expired-session reconnect + `mcp debug` callback ports — = MCP SDK v2 / stateless landed** | [PR #39247](https://github.com/anomalyco/opencode/pull/39247) |
| **1.18.9** | **Jul 28 18:15** | **"Restored compatibility with legacy MCP SDK clients" — = REVERT of SDK v2 → v1.29.0. Stateless/streamable-HTTP REMOVED.** | [PR #39373](https://github.com/anomalyco/opencode/pull/39373) |
| 1.18.10 | Jul 30 | (none — Modal models, Desktop) | releases page |
| **1.18.11** | **Aug 1** | **"Stopped MCP SSE connections from getting stuck in reconnect loops after server error responses" — v1-era SSE stability fix only.** | [release](https://github.com/anomalyco/opencode/releases/tag/v1.18.11) |

> Net: from 1.18.3 → 1.18.11 the MCP subsystem returns to the **same v1 SDK family** it started on. The stateless detour was a same-day add+revert (1.18.8 → 1.18.9).

---

## 3. Per-pattern impact table

Rows = the repo's three MCP config patterns. "Action" reflects the 1.18.11 reality (legacy SDK).

| # | Pattern | Current behavior (1.18.3) | 1.18.11 behavior | Action needed | Risk |
|---|---------|---------------------------|------------------|---------------|------|
| 1 | **`type:"remote"` + `headers.Authorization`** (Z.AI web-reader/zread, Autodesk, etc.) | Native remote via v1 SDK; sends headers on each request. | **Same** v1 SDK (reverted). The modern stateless auto-negotiation is NOT active. Works via established remote transport. | **None** (keep as-is). | **LOW**. *Caveat:* if any endpoint has dropped SSE back-compat and is streamable-HTTP-only, it could fail — verify per endpoint `[UNVERIFIED per-endpoint]`. |
| 2 | **`type:"local"` + `npx -y mcp-remote <https URL>`** (Atlassian `/v1/mcp`, Google `*.sse`, Microsoft `mcp.cloud.microsoft/*/v1/sse`) | Local stdio subprocess; `mcp-remote` bridges to remote SSE/HTTP and owns the OAuth browser flow + token store (`~/.mcp-auth`). | **Same.** OpenCode still on v1 SDK; the bridge does its **own** transport negotiation (`http-first`, SSE fallback) independent of OpenCode's SDK. The bridge actually **shields** these servers from OpenCode SDK churn. | **None required.** Optional future modernization to native `type:"remote"` + `oauth:{}` is **not recommended now** (see §8) because the native OAuth path regressed under SDK v2 and was reverted. | **LOW** (keep). **MED** only if you migrate. |
| 3 | **`type:"local"` + `npx -y <pkg>`** (codegraph, mermaid, next-devtools, `@z_ai/mcp-server`, markitdown-local-mcp) | Subprocess stdio transport. | **Identical** — stdio is unaffected by the SDK v2 detour. | **None.** | **LOW** (simplest, most stable). |

---

## 4. Breaking changes 1.18.3 → 1.18.11 affecting MCP / config / plugin

Based on the [release list](https://github.com/anomalyco/opencode/releases), [MCP docs](https://opencode.ai/docs/mcp-servers/), and [config docs](https://opencode.ai/docs/config/):

- **MCP transport / config schema:** **No breaking change.** The public MCP schema is unchanged in shape: `type` (`local`/`remote`), `command` (array), `enabled`, `environment`, `headers`. The docs additionally document `oauth` (object | `false`), `timeout` (ms, default 5000), and `cwd` (local) — these are **additive/optional**, not removals. Nothing the repo currently uses was renamed or removed.
- **`mcp` CLI:** `opencode mcp auth <name>`, `mcp list`, `mcp logout <name>`, `mcp auth list`, `mcp debug <name>` are present and stable. v1.18.8 added "Honors configured MCP OAuth callback ports in `mcp debug`" — an enhancement, not a break.
- **The only real "breakage" in the window was self-inflicted and self-healed:** SDK v2 (1.18.8) caused Atlassian OAuth issuer mismatch, Draft-07 schema rejection, ReUI OAuth failure, `server/discover` probe rejection with no `initialize` fallback, and Xcode MCP timeout ([PR #39373 rationale](https://github.com/anomalyco/opencode/pull/39373)). All were fixed by the 1.18.9 revert. If the user briefly ran 1.18.8 they may have hit these; 1.18.11 does not have them.
- **`@opencode-ai/plugin` API:** see §5.
- **Server/config:** no changes to `OPENCODE_SERVER_PORT` (still 4096 default) or `OPENCODE_SERVER_PASSWORD` ([server docs](https://opencode.ai/docs/server/)).

> Bottom line: **1.18.3 → 1.18.11 is a non-breaking MCP upgrade.** The risk is in stale *dependencies* (the plugin), not in the MCP config.

---

## 5. `@opencode-ai/plugin` compatibility

- **Current npm version: `1.18.11`** ([npm page](https://www.npmjs.com/package/@opencode-ai/plugin), published ~2 days ago, MIT, 4 deps / ~1486 dependents). The plugin package **version-tracks the opencode release** — i.e. the matching plugin for opencode 1.18.11 is `@opencode-ai/plugin@1.18.11`.
- The repo pins **`1.14.20`** in `.opencode/package.json`. That is **stale by ~4 minor versions** and predates the 1.18 line. This is a real (if low-severity) drift: the plugin SDK is the contract local plugins and custom tools compile against (e.g. `import type { Plugin } from "@opencode-ai/plugin"` and the `tool()`/`tool.schema` helpers per [plugins docs](https://opencode.ai/docs/plugins/)).
- **Recommended version for 1.18.11: `@opencode-ai/plugin@1.18.11`** (or `^1.18.11`).
- **Caveat `[UNVERIFIED]`:** whether any hook/type name changed between 1.14.20 and 1.18.11 in a way that breaks the repo's *own* plugin code cannot be confirmed without reading the repo's plugins (out of scope per instructions). The current documented API surface (`Plugin` type, `tool`/`tool.schema`, event hooks incl. `experimental.session.compacting`, `tool.execute.before/after`) should be diffed against the repo's plugin sources after bumping. Treat as **MED** priority and verify with a `bun install` + typecheck.

---

## 6. `permission.read` / `mcp:*` deny + the `read_mcp_resource` visibility bug

- The repo sets `permission.read: { "mcp:*": "deny" }` to runtime-deny `read_mcp_resource` / `list_mcp_resources`, citing an upstream opencode visibility bug that leaves those tools in the model's tool list even when denied.
- **What the 1.18.11 docs say:** the [Tools page](https://opencode.ai/docs/tools/) lists the built-in tools — `bash, edit, write, read, grep, glob, lsp, apply_patch, skill, todowrite, webfetch, websearch, question` — and **does not list `read_mcp_resource` or `list_mcp_resources`.** The [MCP servers page](https://opencode.ai/docs/mcp-servers/) documents MCP servers as surfacing **only as tools** (prefixed `<servername>_*`); it does not document MCP `resources` or `prompts` primitives at all. This *suggests* the resources-prompts tool surface is de-emphasized/undocumented in the current model.
- **Bug-fix status in 1.18.11: `[UNVERIFIED]`.** I found **no release note, PR, or commit** in 1.18.4–1.18.11 that explicitly fixes the "denied MCP resource tools still appear in the tool list" visibility bug. Its presence/absence in 1.18.11 is not confirmed by documentation.
- **Recommendation:** **keep** `permission.read: { "mcp:*": "deny" }`. It is harmless (defense-in-depth) whether or not the bug persists, and removing it has no upside until the bug is confirmed fixed. Re-test empirically after bumping (see §9).

---

## 7. Docker / web-endpoint implications

- `opencode serve` / `opencode web` expose the HTTP server; default **port 4096**, hostname `127.0.0.1`, optional `OPENCODE_SERVER_PASSWORD` (basic auth) and `OPENCODE_SERVER_USERNAME` ([server docs](https://opencode.ai/docs/server/)). These match the repo's `OPENCODE_SERVER_PORT=4096`. **No stateless-related env-var changes** exist.
- **Spawn model unchanged:** local MCP servers are subprocesses (stdio) of the opencode server process; remote MCP servers are in-process HTTP clients. The SDK version (v1 in 1.18.11) does **not** change this spawn/connect model, and the SDK v2 detour (which also did not change the spawn model) is reverted anyway.
- **Net Docker impact: none beyond the version bump.** The only required Docker edits are the version pins in `opencode_app/Dockerfile` (`ARG OPENCODE_VERSION=1.18.3` → `1.18.11`) and `docker-compose.yml` (`OPENCODE_VERSION: ${OPENCODE_VERSION:-1.18.3}` → `1.18.11`) so the image matches the user's actual runtime.
- `[UNVERIFIED]` whether the bundled base image / Node-Bun runtime in the 1.18.11 release artifacts differs from 1.18.3 in a way that affects the Dockerfile's install step — re-check the build after bumping.

---

## 8. Recommended actions (ordered, with file paths + priority)

> These are advisory; the repo's own files were not read per instructions. Paths are taken from the task's repo summary.

| # | Priority | Action | File(s) | Rationale |
|---|----------|--------|---------|-----------|
| 1 | **HIGH** | Bump OpenCode version pin `1.18.3` → `1.18.11`. | `opencode_app/Dockerfile` (`ARG OPENCODE_VERSION`); `docker-compose.yml` (`OPENCODE_VERSION` default) | Match the user's actual runtime; pick up the SSE reconnect-loop fix and expired-session reconnect. Non-breaking for MCP. |
| 2 | **HIGH** | Bump `@opencode-ai/plugin` `1.14.20` → `^1.18.11`. | `.opencode/package.json` | Plugin version must track opencode; 1.14.20 is ~4 minors stale. Run `bun install` + typecheck afterward. |
| 3 | **MED** | After bumping, verify the repo's own plugins still typecheck against the current plugin API (`Plugin`, `tool`/`tool.schema`, hook names). | `.opencode/plugins/*` | API drift between 1.14 and 1.18 is plausible `[UNVERIFIED]`. |
| 4 | **MED** | Verify Atlassian MCP still authenticates after the bump (the SDK v2 Atlassian OAuth issuer mismatch was reverted, so 1.18.11 should be fine — confirm empirically). Re-auth via `opencode mcp auth <atlassian-name>` if needed. | `opencode.json` (Atlassian entry); `~/.mcp-auth` | The `/v1/mcp` endpoint is reached through the `mcp-remote` bridge, which is unaffected by the OpenCode SDK version. |
| 5 | **LOW** | **Do NOT** migrate the `mcp-remote` bridges (Atlassian/Google/Microsoft) to native `type:"remote"` yet. Defer until OpenCode re-lands MCP SDK v2 with working OAuth. | `opencode.json` | The native remote-OAuth path is the one that regressed and was reverted; bridges remain the robust choice in 1.18.11. |
| 6 | **LOW** | Keep `permission.read: { "mcp:*": "deny" }`. | `opencode.json` | Harmless defense-in-depth; bug-fix status unconfirmed (§6). |
| 7 | **LOW** | Optionally add `timeout` keys to long-startup MCP servers if you see 5s default timeouts (e.g. markitdown-local-mcp, next-devtools). | `opencode.json` | `timeout` is a documented (ms, default 5000) additive key; not required. |

---

## 9. Open questions / things to verify empirically

1. **`read_mcp_resource` / `list_mcp_resources` visibility bug in 1.18.11 `[UNVERIFIED]`.** Docs neither confirm nor deny a fix. Test: with the `mcp:*` deny removed, check whether those tools still leak into the model's tool list; if not, the deny can eventually be dropped.
2. **Whether any Pattern-1 `type:"remote"` endpoint has dropped SSE back-compat** (streamable-HTTP-only) and therefore breaks under the v1 SDK in 1.18.11. Per-endpoint; confirm Autodesk / Z.AI endpoints still respond to the v1 client.
3. **Atlassian `/v1/mcp` via the bridge** post-bump — confirm OAuth + tool listing works (the bridge does transport negotiation, but token refresh after long uptime should be exercised).
4. **`@opencode-ai/plugin` API drift 1.14.20 → 1.18.11** — whether any hook/type the repo's plugins use was renamed/removed.
5. **Docker base/runtime artifact differences** 1.18.3 → 1.18.11 that might affect the Dockerfile install step.
6. **When OpenCode will re-land MCP SDK v2 / stateless support.** PR #39373 says "until those interoperability gaps are resolved." No public target date found `[UNVERIFIED]`. Watch future 1.19.x releases for a re-attempt; *that* is when the bridge→native migration question becomes live.

---

## 10. References (every URL fetched + what it confirmed)

1. `https://opencode.ai/docs/mcp/` — **404.** Wrong path; correct MCP page is `/docs/mcp-servers/` (found via docs nav).
2. `https://github.com/anomalyco/opencode/releases` — Release list v1.18.0–v1.18.11. Confirmed v1.18.11 notes contain **no "stateless" mention**; only an SSE reconnect-loop fix. Confirmed canonical org is **`anomalyco`** (the old `sst/...` redirects here).
3. `https://www.npmjs.com/package/@opencode-ai/plugin` — Confirms **`@opencode-ai/plugin@1.18.11`** is current (published ~2 days ago); version tracks opencode.
4. `https://opencode.ai/docs/` — Docs nav; locates MCP page at `/docs/mcp-servers/`, server page at `/docs/server/`, plugins at `/docs/plugins/`.
5. `https://opencode.ai/docs/server/` — `opencode serve` defaults (port 4096, 127.0.0.1), `OPENCODE_SERVER_PASSWORD`. No stateless-related env vars.
6. `https://github.com/anomalyco/opencode/issues?q=stateless+mcp` — Surfaced the SDK v2 PRs (#39247, #38673) and session-recovery PRs; **no direct "stateless" issue exists** — the term comes from the SDK v2 "modern stateless protocol" work.
7. `https://github.com/anomalyco/opencode/releases/tag/v1.18.0` — v1.18.0 notes (Desktop v2 only); no MCP transport change.
8. `https://opencode.ai/docs/mcp-servers/` — **Authoritative MCP config schema:** `type` local/remote; local keys (`command`, `cwd`, `environment`, `enabled`, `timeout`); remote keys (`url`, `enabled`, `headers`, `oauth` (object|false), `timeout`); OAuth via Dynamic Client Registration; `mcp auth/list/logout/debug` CLI. **No `transport`/`stateless` user-facing key.** Confirms MCP surfaced as tools only.
9. `https://opencode.ai/docs/config/` — Full config schema + 8-tier precedence; confirms MCP `oauth`/`timeout` are additive; no removed keys.
10. `https://opencode.ai/docs/plugins/` — Plugin API (`Plugin` type, `tool`/`tool.schema`, hooks incl. `experimental.session.compacting`); plugins installed via Bun at startup into `~/.cache/opencode/node_modules`.
11. `https://github.com/anomalyco/opencode/pull/39247` — **The stateless feature.** "replace `@modelcontextprotocol/sdk@1.29.0` … with `@modelcontextprotocol/client@2.0.0-beta.5` … negotiate **modern stateless** and legacy MCP servers." Merged Jul 28 → **v1.18.8**.
12. `https://modelcontextprotocol.io/specification/2025-06-18/basic/transports` — MCP spec: Streamable HTTP (modern, sessions optional ⇒ stateless) **replaces** HTTP+SSE (2024-11-05); backwards-compat negotiation (POST Initialize → 2xx = streamable; 4xx = legacy SSE+GET). Defines `MCP-Protocol-Version` and `Mcp-Session-Id`.
13. `https://www.npmjs.com/package/mcp-remote` — `mcp-remote@0.1.38`, "experimental proof-of-concept," transport strategies (`http-first` default w/ SSE fallback, `sse-first`, `http-only`, `sse-only` via `--transport`). README: "As soon as your chosen MCP client supports remote, authorized servers, you can remove it."
14. `https://opencode.ai/docs/tools/` — Built-in tools list; **`read_mcp_resource`/`list_mcp_resources` are NOT documented** as built-in tools; MCP exposed only as `<servername>_*` tools.
15. `https://github.com/anomalyco/opencode/pull/39373` — **The revert.** "revert the MCP client SDK v2 migration from #39247 … restore `@modelcontextprotocol/sdk` 1.29.0." Rationale: "SDK v2 client is not quite ready for production use." Fixed Atlassian OAuth issuer mismatch (#39332), Draft-07 schema rejection (#39333), `server/discover` no-fallback (#39354), ReUI OAuth (#39343), Xcode timeout (#39315). Merged Jul 28 → **v1.18.9**.

---

*End of report. All findings sourced; unconfirmed items flagged `[UNVERIFIED]`. No version numbers or config keys were fabricated — where the docs are silent, §9 says so explicitly.*
