# PLAN: Provider Packs — Deploy-time MCP Server Toggle

**Issue:** #268 → https://github.com/darellchua2/opencode-config-template/issues/268
**Branch:** `feature/provider-packs`
**Type:** `enhancement` (semantic version: `minor` — opt-in feature, default-off, no breaking change)
**Labels:** `enhancement`, `minor`, `documentation`

---

## Overview

The repo's `opencode_app/opencode.json` declares 26 MCP servers; 20 are `enabled: false` with matching `tools.<ns>*: false`. Enabling a logical group (e.g. "all 4 Autodesk servers") currently needs 8 manual JSON edits. This feature adds **provider packs** — deploy-time JSON partials in `deploy/packs/` (autodesk, microsoft, google, markitdown, nextjs, zai) that a user enables with a single `setup.sh --enable-pack autodesk,microsoft` flag (and `docker compose build --build-arg OPENCODE_PACKS=...` for Docker). A new `deploy/merge-packs.mjs` deep-merges selected packs into the target config. Research confirmed OpenCode plugins cannot register MCP servers (no hooks exist), so config-merge is the correct mechanism, not plugins.

> **Review-applied revisions (post opencode-tooling-subagent review):**
> - **B1 (blocker)**: merge-packs dry-run must target `$DRY_RUN_PREVIEW_DIR/opencode.json` (matching the resolver), not `$CONFIG_FILE`. See Phase 4.1.
> - **M1**: added `pack-zai.json` (Phase 2.6) to cover `zai-web-search-prime` — 6 packs now cover all 20 disabled servers.
> - **M2**: empty `--packs ""` is a true no-op (`split(",").filter(Boolean)`); see Phase 3.
> - **M3**: Regression Guard R.1 extended to cover the `tools.*` map, not just `mcp.*.enabled`.
> - Minors: idempotency AC added; mode-interaction note added; malformed-pack-JSON handling specified; `--rollback` recovery noted.

## Approved Scope (user-confirmed decisions)

1. **Toggle point**: deploy-time via `setup.sh --enable-pack` (NOT Docker runtime env var, NOT a plugin).
2. **Remove** the redundant `command.goal` block from `opencode_app/opencode.json` (the npm `opencode-goal-plugin`, already in the `plugin` array, provides it).
3. **Packs toggle MCP servers ONLY** — skills/agents stay always-available (no symlink logic).

## Out of Scope

- `markitdown-local-mcp` stays a Python MCP (not plugin-able — different runtime).
- System packages (chromium, LibreOffice, pip libs) stay in Dockerfile.
- Model-resolver, `docker-entrypoint.sh`, agent overrides — untouched.
- No new OpenCode plugins created (research confirmed plugins can't register MCP servers).
- Skills/agents are NOT toggled by packs (MCP servers only).

---

## Dependency & Consumer Map

| Step | Depends on | Consumers affected |
|------|-----------|-------------------|
| 1.1 Remove `command.goal` | — | All config consumers (MCP servers, agents) — no functional impact since plugin provides it |
| 2.1–2.5 Create pack partials | — | `merge-packs.mjs` (Phase 3), `setup.sh --enable-pack` (Phase 4), Dockerfile (Phase 5) |
| 3.1 `merge-packs.mjs` | — | `setup.sh` (Phase 4), `Dockerfile` (Phase 5) |
| 4.1 Wire `--enable-pack` in `setup.sh` | 2.x (packs exist), 3.x (merge script exists) | End users (deploy) |
| 4.2 Mirror in `setup.ps1` | 4.1 | Windows users |
| 5.1 Dockerfile `ARG OPENCODE_PACKS` | 3.x (merge script), 2.x (packs) | Docker users |
| 6.1–6.4 Docs sync | 4.x, 5.x (feature complete) | All repo readers |
| R.1 Regression guard | All phases | All existing deployments |

---

## Phase 1 — Remove duplicate `command.goal`

- [x] **1.1** Delete the `command` block (lines 18–24) from `opencode_app/opencode.json`
  — **Why:** The `opencode-goal-plugin` (already in the `plugin` array, line 14) provides the same `command.goal` capability; the inline `command` block is redundant and can shadow/conflict with the plugin.
  — **Done when:** `jq '.command' opencode_app/opencode.json` returns `null` (key absent) AND `jq '.plugin | index("opencode-goal-plugin")' opencode_app/opencode.json` returns a non-null index.
  — **Consumers affected:** All MCP servers and agents (they read the resolved config; removing the duplicate block has no functional impact since the plugin provides the capability).

  - [x] AC: `command.goal` block removed; `opencode-goal-plugin` still present in `plugin` array.

---

## Phase 2 — Create `deploy/packs/` partials

- [x] **2.1** Create `deploy/packs/pack-autodesk.json` (autodesk-revit, autodesk-model-data, autodesk-fusion, autodesk-help)
  — **Why:** Groups the 4 Autodesk MCP servers into a single toggle unit.
  — **Done when:** File exists, valid JSON, sets `mcp.*.enabled: true` + `tools.*: true` for exactly those 4 servers.
  — **Consumers affected:** `merge-packs.mjs` (Phase 3), `setup.sh --enable-pack autodesk` (Phase 4).
- [x] **2.2** Create `deploy/packs/pack-microsoft.json` (microsoft-teams, -mail, -calendar, -sharepoint, -onedrive, -user, -word, -copilot, -dataverse — 9 servers)
  — **Why:** Groups the 9 Microsoft 365 MCP servers into a single toggle unit.
  — **Done when:** File exists, valid JSON, 9 server entries with `enabled: true` + `tools.*: true`.
  — **Consumers affected:** `merge-packs.mjs`, `setup.sh --enable-pack microsoft`.

- [x] **2.3** Create `deploy/packs/pack-google.json` (google-bigquery, google-maps, google-gce, google-gke)
  — **Why:** Groups the 4 Google Cloud MCP servers into a single toggle unit.
  — **Done when:** File exists, valid JSON, 4 server entries.
  — **Consumers affected:** `merge-packs.mjs`, `setup.sh --enable-pack google`.

- [x] **2.4** Create `deploy/packs/pack-markitdown.json` (markitdown)
  — **Why:** Isolates the markitdown MCP server as a standalone pack (Python MCP, not plugin-able).
  — **Done when:** File exists, valid JSON, 1 server entry.
  — **Consumers affected:** `merge-packs.mjs`, `setup.sh --enable-pack markitdown`.

- [x] **2.5** Create `deploy/packs/pack-nextjs.json` (next-devtools)
  — **Why:** Isolates the Next.js devtools MCP server as a standalone pack.
  — **Done when:** File exists, valid JSON, 1 server entry.
  — **Consumers affected:** `merge-packs.mjs`, `setup.sh --enable-pack nextjs`.

- [x] **2.6** Create `deploy/packs/pack-zai.json` (zai-web-search-prime)
  — **Why:** Covers the one remaining disabled server not in any other pack. `zai-web-search-prime` is `enabled: false` (the other `zai-*` servers are enabled by default). Without this pack, 19 of 20 disabled servers would be pack-covered — defeating the feature's "no manual JSON edits" goal.
  — **Done when:** File exists, valid JSON, 1 server entry (`mcp.zai-web-search-prime.enabled: true` + `tools.zai-web-search-prime*: true`). Note: the base `tools` map currently has no `zai-web-search-prime*` key, so this pack ADDS it (set to `true`).
  — **Consumers affected:** `merge-packs.mjs`, `setup.sh --enable-pack zai`.

  - [x] AC: `deploy/packs/` contains 6 valid JSON partials (autodesk, microsoft, google, markitdown, nextjs, zai) covering all 20 `enabled: false` servers.

---

## Phase 3 — New helper `deploy/merge-packs.mjs`

- [x] **3.1** Implement `deploy/merge-packs.mjs` (Node, no deps)
  — **Why:** Provides the deep-merge engine that combines selected pack partials into the target config; mirrors code style of existing `deploy/resolve-models.mjs` (ES modules, `node:fs/promises`, async `main`, `readJsonMaybe`/`stripJsonComments` helpers, camelCase arg parsing).
  — **Done when:** Script runs via `node deploy/merge-packs.mjs --config <path> --packs-dir <dir> --packs autodesk,microsoft [--dry-run]` with these exact semantics:
    - **Deep-merge**: last-wins on scalars; objects merged recursively; arrays left untouched (documented limitation — no current pack needs array mutation; the `plugin` array is never touched).
    - **Empty-string no-op (M2)**: if `--packs` is empty string or whitespace-only, the script filters via `packs.split(",").map(s=>s.trim()).filter(Boolean)` → empty list → exits `0` immediately WITHOUT reading or writing any file. This is the Docker `ARG OPENCODE_PACKS=""` default path. Must NOT treat `""` as a single pack named `""`.
    - **Pack-name validation**: each requested pack must have a matching `pack-<name>.json` in `--packs-dir`. Unknown pack → exit non-zero with a clear error listing available packs; write nothing.
    - **Malformed pack JSON**: if a pack file fails `JSON.parse`, exit non-zero with the file path + parse error (mirror `resolve-models.mjs` line 73's `throw new Error("Failed to parse JSON ...")`).
    - **`--dry-run`**: print the would-be-merged result (or a diff summary) to stdout; do not write. The caller (`setup.sh`) is responsible for pointing `--config` at the right path (see Phase 4.1 B1).
    - **Idempotent**: running the same pack list twice produces identical output.
  — **Consumers affected:** `setup.sh` (Phase 4), `Dockerfile` (Phase 5).

  - [x] AC: `merge-packs.mjs` exists, runs via `node`, deep-merges correctly, errors on unknown pack, supports `--dry-run`.

---

## Phase 4 — Wire `--enable-pack <csv>` into `deploy/setup.sh` (+ mirror in setup.ps1)

- [x] **4.1** Add `--enable-pack` option to `deploy/setup.sh`
  — **Why:** Gives users a single-flag deploy-time toggle for MCP server groups.
  — **Done when:**
    - `--enable-pack <csv>` is parsed in `parse_arguments()` (alongside `--quick`, `--skills-only`, etc.); help text and banner entry added.
    - After `run_resolver()` returns (which is what writes/copies the resolved config), invoke `merge-packs.mjs` with the selected packs.
    - **B1 (critical) — dry-run path**: the `--config` argument to `merge-packs.mjs` MUST be path-aware, mirroring `run_resolver()` (setup.sh lines 2568–2571):
      - Normal mode → `--config "$CONFIG_FILE"` (`~/.config/opencode/config.json`).
      - Dry-run mode → `--config "$DRY_RUN_PREVIEW_DIR/opencode.json"` (the resolver stages there via `--preview-dir`; `$CONFIG_FILE` is never written in dry-run because `run_cmd cp` is a no-op at line 937–939).
      - If `--enable-pack` is set but `DRY_RUN_PREVIEW_DIR/opencode.json` does not exist in dry-run, that's a setup-orchestration bug — log a clear error rather than silently merging a stale/absent file.
    - Pack names validated against `deploy/packs/` contents; unknown pack → non-zero exit + clear error + writes nothing.
    - **Mode interactions**: `--enable-pack` is honored in `--quick`, `--skills-only`, and full interactive modes. It is **ignored** (with a log_info) in `--models-only` mode (config is not copied there, so there is nothing to merge). It is also ignored in `--update`, `--rollback`, `--migrate`, and `--check-update` modes (those don't deploy a config).
    - **Recovery**: if a pack merge produces unexpected results, `setup.sh --rollback` restores the pre-deploy backup (existing feature).
  — **Consumers affected:** End users running `setup.sh` deploy.

- [x] **4.2** Mirror `-EnablePack` parameter in `deploy/setup.ps1`
  — **Why:** Windows parity is required by `AGENTS.md` sync rules.
  — **Done when:** `setup.ps1` has `-EnablePack` parameter with identical behavior to `setup.sh --enable-pack`.
  — **Consumers affected:** Windows users running `setup.ps1`.

  - [x] AC: `setup.sh --enable-pack autodesk --dry-run` enables exactly the 4 Autodesk servers (verified via `jq` against `$DRY_RUN_PREVIEW_DIR/opencode.json`, NOT `$CONFIG_FILE`).
  - [x] AC: `setup.sh --enable-pack autodesk,microsoft,zai --dry-run` enables 14 servers (4 + 9 + 1).
  - [x] AC: `setup.sh --enable-pack bogus` exits non-zero, clear error, writes nothing.
  - [x] AC: `setup.sh --enable-pack ""` (empty) is a no-op — exits 0, no merge, config unchanged.
  - [x] AC: Idempotency — running `--enable-pack autodesk` twice yields byte-identical output config.
  - [x] AC: `setup.ps1` has matching `-EnablePack` parameter (Windows parity).

---

## Phase 5 — Docker parity (build-arg)

- [x] **5.1** Extend `opencode_app/Dockerfile` with `ARG OPENCODE_PACKS=""`
  — **Why:** Gives Docker users the same pack-toggle capability via build-time arg.
  — **Done when:** Dockerfile declares `ARG OPENCODE_PACKS=""`; runs `node /app/deploy/merge-packs.mjs --config /app/opencode.json --packs-dir /app/deploy/packs --packs "$OPENCODE_PACKS"` immediately after the existing `resolve-models.mjs` step (Dockerfile lines 52–61); empty `OPENCODE_PACKS` is a no-op per Phase 3's empty-string rule (`.filter(Boolean)` → exit 0 without touching the file).
  — **Consumers affected:** Docker users building custom images.

  - [x] AC: `Dockerfile` accepts `ARG OPENCODE_PACKS` and applies merge after `resolve-models.mjs`.
  - [x] AC: `docker compose build --build-arg OPENCODE_PACKS=google .` → `jq '.mcp["google-bigquery"].enabled' /app/opencode.json` returns `true`.

---

## Phase 6 — Docs sync

- [x] **6.1** Add "Provider Packs" subsection to `README.md` (near MCP servers section)
  — **Why:** Users need to discover the feature and know the pack names + usage syntax.
  — **Done when:** `README.md` has a "Provider Packs" subsection documenting `setup.sh --enable-pack <csv>` and listing the 5 pack names (autodesk, microsoft, google, markitdown, nextjs).
  — **Consumers affected:** All repo readers.

- [x] **6.2** Add Docker build-arg usage to `opencode_app/README.md`
  — **Why:** Docker users need to know the `--build-arg OPENCODE_PACKS=...` syntax.
  — **Done when:** `opencode_app/README.md` documents `docker compose build --build-arg OPENCODE_PACKS=...` and references the `--enable-pack` flag.
  — **Consumers affected:** Docker users.

- [x] **6.3** Update banner/help text in `deploy/setup.sh` + `deploy/setup.ps1`
  — **Why:** Discoverability of the new flag in CLI help output.
  — **Done when:** Both scripts list `--enable-pack` / `-EnablePack` in their help/banner output.
  — **Consumers affected:** CLI users.

- [x] **6.4** Add brief note to `MIGRATION.md` (optional)
  — **Why:** Records the new deploy-time capability for migration tracking.
  — **Done when:** `MIGRATION.md` has a short note about provider packs (or explicitly marked N/A if no migration impact).
  — **Consumers affected:** Migration readers.

  - [x] AC: `README.md` and `opencode_app/README.md` document the feature.

---

## Regression Guard

- [x] **R.1** Verify no existing `enabled: true` server regresses AND no intentionally-`false` `tools.*` key flips
  — **Why:** Packs only toggle servers ON; they must never turn an already-on server OFF, and must never flip a `tools.*` key that the base config intentionally sets to `false` (e.g. `zai-vision-mcp-server*` and `zai-zread*` are `false` even though those MCP servers are `enabled: true` — they're scoped to subagents). Default state of every pack is "off" = today's `enabled: false` defaults.
  — **Done when:** After applying any combination of packs, ALL of:
    1. `jq '[.mcp | to_entries[] | select(.value.enabled == true) | .key]' opencode.json` includes at minimum: codegraph, atlassian, zai-web-reader, zai-vision-mcp-server, zai-zread, mermaid.
    2. **`tools.*` diff (M3)**: snapshot the base `tools` object before merge and the post-merge `tools` object; assert that the ONLY keys that changed value are those a selected pack explicitly set to `true`. No `false`→`true` drift from `zai-vision-mcp-server*`, `zai-zread*`, `markitdown*`, or any other intentionally-disabled namespace unless a pack explicitly owns it. No `true`→`false` drift anywhere.
    3. The `plugin` array and `agent` block are byte-identical pre/post merge.
  — **Consumers affected:** All existing deployments (must remain unaffected by default).

  - [x] AC: No existing `enabled: true` server regresses (codegraph, atlassian, zai-*, mermaid stay on).

---

## Verification

Run these commands after implementation to confirm acceptance criteria:

```bash
# 1. Single pack — exactly 4 Autodesk servers enabled in preview
./deploy/setup.sh --enable-pack autodesk --dry-run
jq '[.mcp | to_entries[] | select(.value.enabled == true) | .key]' ~/.config/opencode/.dry-run-preview/opencode.json

# 2. Multi pack — 14 servers (4 Autodesk + 9 Microsoft + 1 ZAI) in preview
./deploy/setup.sh --enable-pack autodesk,microsoft,zai --dry-run

# 3. Empty pack — no-op, exit 0, config unchanged
./deploy/setup.sh --enable-pack "" --dry-run

# 4. Unknown pack — non-zero exit, clear error, writes nothing
./deploy/setup.sh --enable-pack bogus

# 5. Docker build-arg — google-bigquery enabled in container
docker compose build --build-arg OPENCODE_PACKS=google .
docker compose run --rm opencode jq '.mcp["google-bigquery"].enabled' /app/opencode.json
# Expected output: true

# 6. tools.* regression check (M3) — no intentional-false key flipped
jq '.tools | to_entries | map(select(.value == false)) | from_entries' ~/.config/opencode/.dry-run-preview/opencode.json
# Expected: zai-vision-mcp-server*, zai-zread*, markitdown* (and disabled provider packs) still false
```

---

## Notes

- This PLAN is for implementation tracking only. The ticket-creation workflow created issue #268, branch `feature/provider-packs`, and this `PLAN.md`. **Implementation is a separate follow-up — do not implement during ticket creation.**
- Default state of every pack is "off" = today's `enabled: false` defaults. Existing deployments are unaffected unless a user explicitly passes `--enable-pack`.
- Semantic version: **minor** (new opt-in feature, no breaking change).
- Conventional Commits scope: `feat(provider-packs)`.
