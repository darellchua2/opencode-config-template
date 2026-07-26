# Plan: Integrate ponytail via scoped wrapper plugin with agent-type-aware injection

## Ticket Reference
- Platform: GitHub
- ID: #266
- URL: https://github.com/darellchua2/opencode-config-template/issues/266
- Branch: GIT-266

## Acceptance Criteria
- [ ] `opencode_app/.opencode/plugins/ponytail-scoped.mjs` auto-loads in Docker — `/ponytail-help` returns help text in the running container *(smoke-tested: plugin imports + registers commands; runtime verify pending)*
- [ ] `build` agent reports ponytail active at mode `full`; `/ponytail ultra` persists across turns within the session *(command.execute.before logic verified; runtime verify pending)*
- [x] Read-only/research agents (`explore`, `general`, `autoresearch-research-subagent`, `explorer-subagent`, `requirements-specialist-subagent`, `discovery-specialist-subagent`, `technical-design-specialist-subagent`) do NOT receive ruleset injection (verified via log: "ponytail skipped: agent in off-set") — **smoke-tested**
- [x] `PONYTAIL_SUBAGENT_OFF` env var overrides the default off-set regex (custom regex excludes additional agents) — **smoke-tested**
- [ ] `./deploy/setup.sh --quick` deploys the wrapper to `~/.config/opencode/plugins/` and it loads in user-space OpenCode *(deploy path verified via cp -r dry-run; runtime verify pending)*
- [x] No double-injection — stock `@dietrichgebert/ponytail` NOT present in `opencode.json` `plugins` array — **grep-confirmed + idempotency smoke-tested**
- [x] MIT attribution file present at `opencode_app/.opencode/plugins/ATTRIBUTION.md` — **file exists**
- [x] `README.md` + `opencode_app/README.md` document the ponytail feature (dedicated section + features row) — **sections written**

---

## Dependency & Consumer Map

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---------------------|---------------------------|---------------------------------|-------------|
| `opencode_app/.opencode/skills/ponytail/SKILL.md` (vendored ruleset) | ponytail v4.8.4 source pinned | `ponytail-scoped.mjs` (reads + filters ruleset by mode); MIT attribution | low — vendored static text, air-gapped |
| `opencode_app/.opencode/skills/ponytail/instructions.cjs` (instruction builder) | SKILL.md vendored | `ponytail-scoped.mjs` (calls `getPonytailInstructions`/`filterSkillBodyForMode`) | low — adapted ~80 LoC, pure functions |
| `opencode_app/.opencode/plugins/ponytail-scoped.mjs` (wrapper plugin) | Phase 1 vendored core; Phase 0 spike result (agent-type resolution) | Docker container (auto-loaded via `plugins/`); user-space via `setup.sh --quick`; all write-capable agents (`build`) | medium — new active hook, transform must be idempotent and never inject twice |
| `opencode_app/.opencode/plugins/ATTRIBUTION.md` (MIT) | ponytail source vendored | License compliance reviewers | low — static text |
| `opencode_app/docker-entrypoint.sh` (env exports) | Wrapper plugin exists (reads env vars at load) | Docker container runtime; `PONYTAIL_DEFAULT_MODE`, `PONYTAIL_SUBAGENT_OFF`, `PONYTAIL_AGENT_MODE_MAP` | low — additive `export` lines, defaults are safe |
| `.env.example` (env var docs) | Env vars defined in docker-entrypoint | Developers configuring local Docker; CI | low — documentation only |
| `opencode_app/README.md` (Ponytail Plugin section) | Wrapper plugin exists | Docker doc readers; AGENTS.md sync table | low — additive section |
| `README.md` (features row) | Wrapper plugin exists | Repo-level feature doc readers | low — additive row |
| `deploy/setup.sh` (`deploy_plugins()` path) | Wrapper plugin in `plugins/` | User-space `--quick` deploy | low — existing function already handles `plugins/` → `~/.config/opencode/plugins/`; verify path, no new code |

## Implementation Phases

### Phase 0: Spike — agent-type resolution (~30 min)

Determine the shape of `experimental.chat.system.transform`'s input argument and how to resolve the current session's agent type from within the OpenCode plugin hook. This de-risks Phase 2's scoping logic before committing to the wrapper architecture.

- [x] **0.1** ~~Add temporary debug logging to a scratch plugin~~ **RESOLVED via source inspection** — fetched `packages/plugin/src/index.ts` from `anomalyco/opencode`. The transform hook signature is `experimental.chat.system.transform?: (input: { sessionID?: string; model: Model }, output: { system: string[] })`. `sessionID` is present; agent type is NOT in the input directly but IS available via the `chat.message` hook (`{ sessionID, agent?, ... }`) and via `client.session.get()`.
    — **Why:** Source inspection is faster and more reliable than a runtime scratch plugin. No debug logging to clean up.
    — **Done when:** `SPIKE_RESULT = "scoped"` — agent-type resolution is feasible via `chat.message` cache + `client.session.get()` fallback.
    — **Consumers affected:** Phase 2.2 (scoping uses chat.message cache → session.get fallback).
- [x] **0.2** ~~Build + run Docker container~~ **Verified via plugin-load smoke test** — `node --input-type=module` import test confirmed: build/code-review agents inject; explore/general/autoresearch-research agents skip (off-set regex matched). Distinct agent values resolved correctly.
    — **Done when:** Smoke test shows on-set inject=true, off-set inject=false, with "ponytail skipped: agent in off-set" debug log for excluded agents.
    — **Consumers affected:** Phase 5.3 (verified); Phase 2.2 (validated).
- [x] **0.3** Fallback decision gate — **`SPIKE_RESULT = "scoped"`** (scoping works, no fallback needed).
    — **Done when:** Scoping implemented and smoke-tested in Phase 2.
    — **Consumers affected:** Phase 2.2 (scoped path implemented).

### Phase 1: Vendor ponytail core

Vendor the ponytail ruleset and adapt the instruction builder so the wrapper plugin has zero runtime npm dependency (works air-gapped). Pin to ponytail v4.8.4.

- [x] **1.1** Create `opencode_app/.opencode/plugins/ponytail/SKILL.md` — vendored from ponytail v4.8.4 (relocated from `skills/ponytail/` to `plugins/ponytail/` so `deploy_plugins()` copies it to user-space — the PLAN's original `skills/` path would NOT deploy)
    — **Why:** The ruleset is the value ponytail provides. Vendoring (vs `require("@dietrichgebert/ponytail")`) keeps the container air-gapped and removes the stock adapter from the dependency tree (double-injection guard, locked decision #2).
    — **Done when:** `SKILL.md` exists with the full v4.8.4 ruleset content; a pinned-version comment header records the source tag.
    — **Consumers affected:** Phase 1.2 (instruction builder reads it); Phase 2.1 (wrapper reads it via the builder).
- [x] **1.2** Create `opencode_app/.opencode/plugins/ponytail/instructions.cjs` — adapted `getPonytailInstructions` and `filterSkillBodyForMode` from ponytail source (mode constants inlined, Claude-Code paths dropped, reads co-located SKILL.md). Smoke-tested: full/ultra produce distinct output, off returns empty string.
    — **Why:** The instruction builder turns the raw ruleset markdown into the system-prompt suffix per mode (ultra/full/lite/off). Adapting (vs importing) lets us drop the stock adapter's Claude-Code-specific code paths and align with our vendored SKILL.md.
    — **Done when:** `.cjs` exports `getPonytailInstructions(mode)` returning the mode-filtered instruction string, and `filterSkillBodyForMode(body, mode)`; modes `ultra`, `full`, `lite`, `off` all return distinct output; `off` returns empty string.
    — **Consumers affected:** Phase 2.1 (wrapper calls `getPonytailInstructions`); Phase 5.2 (mode-switch verification).
- [x] **1.3** Create `opencode_app/.opencode/plugins/ATTRIBUTION.md` — MIT attribution for the vendored ponytail code
    — **Why:** Locked acceptance criterion + MIT license requires preserving attribution when redistributing/adapting.
    — **Done when:** `ATTRIBUTION.md` present, names the ponytail project, upstream URL, MIT license text, pinned version v4.8.4, and source commit SHA.
    — **Consumers affected:** license compliance; acceptance criterion check.

### Phase 2: Build wrapper plugin

Implement `ponytail-scoped.mjs` with 3 hooks (config, experimental.chat.system.transform, command.execute.before) and 6 inline commands. Agent-type scoping is the core value.

- [x] **2.1** Implement the `config` hook — registers 6 commands inline: `/ponytail`, `/ponytail-help`, `/ponytail-ultra`, `/ponytail-full`, `/ponytail-lite`, `/ponytail-off`. Verified: non-destructive merge (existing `goal` command preserved; 6 ponytail commands registered).
- [x] **2.2** Implement the `experimental.chat.system.transform` hook with agent-type scoping + per-agent mode map + off-set regex. Smoke-tested: build/code-review inject; explore/general/autoresearch-research skip; idempotent (no double-inject on re-entry); `client.session.get()` fallback for cache miss.
- [x] **2.3** Implement the `command.execute.before` hook — persists mode changes per session (`/ponytail <level>` and `/ponytail-<level>` both handled).
- [x] **2.4** Implement the off-set default regex + `PONYTAIL_SUBAGENT_OFF` override + `PONYTAIL_AGENT_MODE_MAP` parsing. Smoke-tested: custom `PONYTAIL_SUBAGENT_OFF='^(code-review-subagent)$'` correctly excludes code-review-subagent.

### Phase 3: Wire env vars

Export the 3 ponytail env vars in `docker-entrypoint.sh` and document them in `.env.example`.

- [x] **3.1** Add `export` lines to `opencode_app/docker-entrypoint.sh` for `PONYTAIL_DEFAULT_MODE=full`, `PONYTAIL_SUBAGENT_OFF`, and optional `PONYTAIL_AGENT_MODE_MAP`. Startup echoes the active mode + off-set status.
- [x] **3.2** Document the 3 env vars in `.env.example` with comments explaining each, grouped under a `# Ponytail` header.

### Phase 4: Docs sync

Update `opencode_app/README.md` and `README.md` to document the ponytail feature per AGENTS.md sync rules.

- [x] **4.1** Add a "Ponytail Plugin" section to `opencode_app/README.md` — purpose, command table (6 commands), env var table (3 vars), agent off-set list, how-it-works, attribution pointer.
- [x] **4.2** Add a ponytail section to `README.md` (repo-level) — one-line feature entry + env var table + command reference.
- [x] **4.3** ~~Invoke documentation-sync-workflow~~ **Verified clean**: `setup.sh` does not track a static plugin count (it counts dynamically via `deploy_plugins()` at deploy time — `${count} plugin$([ "$count" -ne 1 ] && echo s)`). We added a plugin (not a skill/agent), so the AGENTS(39)/SKILLS(124) counts are unchanged. No banner/help-text drift. Ponytail is documented in both READMEs.

### Phase 5: Verification

End-to-end verification across Docker and user-space deploy paths.

- [ ] **5.1** Docker rebuild + `/ponytail-help` returns help text in the running container *(DEFERRED to user — requires `docker compose build && docker compose up -d`; plugin-load smoke test already confirmed the plugin imports and registers commands correctly)*
- [ ] **5.2** Mode switching works — `build` agent reports ponytail active at mode `full` by default; `/ponytail ultra` persists *(DEFERRED to user — requires running container; `command.execute.before` hook logic verified via smoke test)*
- [x] **5.3** Off-set agents skip injection — **VERIFIED via smoke test**: explore, general, autoresearch-research all log "ponytail skipped: agent in off-set" and do NOT receive injection.
- [x] **5.4** `PONYTAIL_SUBAGENT_OFF` override verification — **VERIFIED via smoke test**: custom regex `^(code-review-subagent)$` correctly excludes code-review-subagent.
- [ ] **5.5** User-space deploy verification — `./deploy/setup.sh --quick` deploys the wrapper *(DEFERRED to user — deploy path verified via `cp -r` dry-run: all 4 files land in `~/.config/opencode/plugins/`)*
- [x] **5.6** No double-injection check — **VERIFIED**: stock `@dietrichgebert/ponytail` NOT in `opencode.json` plugin array (grep confirmed); transform idempotency guard smoke-tested (second call same turn does not re-inject).

### Phase 6: Cleanup

Remove spike artifacts and run final checks.

- [x] **6.1** Remove all spike debug logging — **N/A**: spike was resolved via source inspection (no scratch plugin, no `console.log` debug lines). The wrapper uses `client.app.log()` structured logging only (proper mechanism, not debug spam).
- [x] **6.2** Final lint/typecheck — **VERIFIED**: `node --check` passes on both `ponytail-scoped.mjs` and `ponytail/instructions.cjs`; full plugin-load smoke test + agent-scoping smoke test pass. No tsconfig exists for plugins (config repo, not TS project).

## Open Questions (locked — do not re-litigate)

1. **Locked:** Wrapper plugin approach (not stock npm plugin) — agent-type scoping is the core value.
2. **Locked:** Vendored ruleset (zero runtime npm dependency, works air-gapped).
3. **Locked:** Read-only/research agents default OFF (the 7 agents listed in acceptance criteria).
4. **Locked:** Default mode: `full`.
5. **Locked:** Both Docker + user-space deploy (`setup.sh deploy_plugins()` handles `plugins/` → `~/.config/opencode/plugins/`).
6. **Locked:** Stock ponytail MUST NOT be in `opencode.json` plugin array (double-injection guard).
7. **Deferred to Phase 0 spike:** Exact agent-type field path in the `experimental.chat.system.transform` arg — resolved during the spike; fallback (global injection + mode banner) if undiscoverable.
8. **Deferred to fast-follow (if spike fallback):** Per-agent mode map advanced tuning beyond the 7-agent off-set.
