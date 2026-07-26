# Plan: Integrate ponytail via scoped wrapper plugin with agent-type-aware injection

## Ticket Reference
- Platform: GitHub
- ID: #266
- URL: https://github.com/darellchua2/opencode-config-template/issues/266
- Branch: GIT-266

## Acceptance Criteria
- [ ] `opencode_app/.opencode/plugins/ponytail-scoped.mjs` auto-loads in Docker — `/ponytail-help` returns help text in the running container
- [ ] `build` agent reports ponytail active at mode `full`; `/ponytail ultra` persists across turns within the session
- [ ] Read-only/research agents (`explore`, `general`, `autoresearch-research-subagent`, `explorer-subagent`, `requirements-specialist-subagent`, `discovery-specialist-subagent`, `technical-design-specialist-subagent`) do NOT receive ruleset injection (verified via log: "ponytail skipped: agent in off-set")
- [ ] `PONYTAIL_SUBAGENT_OFF` env var overrides the default off-set regex (custom regex excludes additional agents)
- [ ] `./deploy/setup.sh --quick` deploys the wrapper to `~/.config/opencode/plugins/` and it loads in user-space OpenCode
- [ ] No double-injection — stock `@dietrichgebert/ponytail` NOT present in `opencode.json` `plugins` array
- [ ] MIT attribution file present at `opencode_app/.opencode/plugins/ATTRIBUTION.md`
- [ ] `README.md` + `opencode_app/README.md` document the ponytail feature (dedicated section + features row)

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

- [ ] **0.1** Add temporary debug logging to a scratch plugin that logs the full `experimental.chat.system.transform` argument shape (keys, nested objects, any agent/session metadata)
    — **Why:** The transform hook's arg shape is undocumented for OpenCode; the stock ponytail adapter assumes Claude Code's structure. We must discover the actual OpenCode shape to implement agent-type resolution.
    — **Done when:** Scratch plugin logs a representative arg object (from at least one `build` session and one `explore` session) to the container stdout; the arg contains a field or path that identifies the active agent type.
    — **Consumers affected:** Phase 2.2 (scoping logic depends on the resolved agent-type field).
- [ ] **0.2** Build + run the Docker container with the scratch plugin, trigger chats in `build` and `explore` agents, inspect logs for the agent-type field
    — **Why:** The agent-type field name found in 0.1 must be confirmed against at least two agent types (one in the default off-set, one out) to validate the off-set regex.
    — **Done when:** Logs show distinct agent-type values for `build` vs `explore` sessions; the field path is stable across both.
    — **Consumers affected:** Phase 2.2 (off-set regex construction); Phase 5.3 (verification log assertions).
- [ ] **0.3** Fallback decision gate — if spike fails (no agent-type field discoverable), set `SPIKE_RESULT = "fallback"` and switch Phase 2 to global injection + mode banner (scoping becomes a fast-follow ticket)
    — **Why:** Avoid blocking the entire feature on an unknown API surface. A globally-injected ponytail with a working mode banner is still a net improvement over no ponytail.
    — **Done when:** Either (a) `SPIKE_RESULT = "scoped"` with the field path recorded, or (b) `SPIKE_RESULT = "fallback"` recorded with a note that Phase 2.2's scoping branch is stubbed to `return input` and a fast-follow issue is filed.
    — **Consumers affected:** Phase 2.2 (branching on `SPIKE_RESULT`); fast-follow ticket if fallback.

### Phase 1: Vendor ponytail core

Vendor the ponytail ruleset and adapt the instruction builder so the wrapper plugin has zero runtime npm dependency (works air-gapped). Pin to ponytail v4.8.4.

- [ ] **1.1** Create `opencode_app/.opencode/skills/ponytail/SKILL.md` — copy the ponytail v4.8.4 ruleset markdown verbatim from the pinned source
    — **Why:** The ruleset is the value ponytail provides. Vendoring (vs `require("@dietrichgebert/ponytail")`) keeps the container air-gapped and removes the stock adapter from the dependency tree (double-injection guard, locked decision #2).
    — **Done when:** `SKILL.md` exists with the full v4.8.4 ruleset content; a pinned-version comment header records the source commit/SHA.
    — **Consumers affected:** Phase 1.2 (instruction builder reads it); Phase 2.1 (wrapper reads it via the builder).
- [ ] **1.2** Create `opencode_app/.opencode/skills/ponytail/instructions.cjs` — adapt `getPonytailInstructions` and `filterSkillBodyForMode` (~80 LoC) from the ponytail source
    — **Why:** The instruction builder turns the raw ruleset markdown into the system-prompt suffix per mode (ultra/full/lite/off). Adapting (vs importing) lets us drop the stock adapter's Claude-Code-specific code paths and align with our vendored SKILL.md.
    — **Done when:** `.cjs` exports `getPonytailInstructions(mode)` returning the mode-filtered instruction string, and `filterSkillBodyForMode(body, mode)`; modes `ultra`, `full`, `lite`, `off` all return distinct output; `off` returns empty string.
    — **Consumers affected:** Phase 2.1 (wrapper calls `getPonytailInstructions`); Phase 5.2 (mode-switch verification).
- [ ] **1.3** Create `opencode_app/.opencode/plugins/ATTRIBUTION.md` — MIT attribution for the vendored ponytail code
    — **Why:** Locked acceptance criterion + MIT license requires preserving attribution when redistributing/adapting.
    — **Done when:** `ATTRIBUTION.md` present, names the ponytail project, upstream URL, MIT license text, pinned version v4.8.4, and source commit SHA.
    — **Consumers affected:** license compliance; acceptance criterion check.

### Phase 2: Build wrapper plugin

Implement `ponytail-scoped.mjs` with 3 hooks (config, experimental.chat.system.transform, command.execute.before) and 6 inline commands. Agent-type scoping is the core value.

- [ ] **2.1** Implement the `config` hook — registers 6 commands inline: `/ponytail`, `/ponytail-help`, `/ponytail-ultra`, `/ponytail-full`, `/ponytail-lite`, `/ponytail-off`
    — **Why:** Embedding command definitions in the plugin means only `plugins/` needs deploying (locked decision #5). The 6 commands cover status, help, and the 4 modes.
    — **Done when:** `/ponytail-help` returns help text listing all 6 commands; each mode command is registered and callable.
    — **Consumers affected:** Phase 5.1 (help verification); Phase 5.2 (mode switching).
- [ ] **2.2** Implement the `experimental.chat.system.transform` hook with agent-type scoping + per-agent mode map + off-set regex
    — **Why:** This is the core value — scope injection by agent type so read-only/research agents (locked off-set: `explore`, `general`, `autoresearch-research-subagent`, `explorer-subagent`, `requirements-specialist-subagent`, `discovery-specialist-subagent`, `technical-design-specialist-subagent`) do NOT receive the ruleset. `PONYTAIL_SUBAGENT_OFF` overrides the default regex; `PONYTAIL_AGENT_MODE_MAP` JSON provides per-agent default modes. If `SPIKE_RESULT = "fallback"`, this hook stubs to global injection (no scoping).
    — **Done when:** (a) For agents in the off-set, the transform returns input unchanged and logs "ponytail skipped: agent in off-set"; (b) for agents not in the off-set, the transform appends `getPonytailInstructions(mode)` to the system prompt exactly once (idempotent — no double-injection on re-entry); (c) the resolved agent-type field from Phase 0 drives the decision.
    — **Consumers affected:** Phase 5.3 (off-set verification); acceptance criteria for scoping + no-double-injection.
- [ ] **2.3** Implement the `command.execute.before` hook — persists mode changes within the session
    — **Why:** `/ponytail ultra` must persist across turns within the session (acceptance criterion). The `command.execute.before` hook intercepts mode commands and updates the in-session mode variable that the transform hook reads.
    — **Done when:** After `/ponytail ultra`, subsequent transforms use `ultra` mode for that session; `/ponytail` (status) reports the current persisted mode.
    — **Consumers affected:** Phase 5.2 (mode persistence verification).
- [ ] **2.4** Implement the off-set default regex + `PONYTAIL_SUBAGENT_OFF` override + `PONYTAIL_AGENT_MODE_MAP` parsing
    — **Why:** Locked decision #3 — read-only/research agents default OFF. The default regex matches the 7 agent names; `PONYTAIL_SUBAGENT_OFF` lets users override (e.g., add `code-review-subagent`). `PONYTAIL_AGENT_MODE_MAP` (JSON) lets users set per-agent modes (e.g., `{"build":"full","code-review-subagent":"lite"}`).
    — **Done when:** (a) Default regex string embedded in the plugin matches the 7 off-set agent names; (b) if `PONYTAIL_SUBAGENT_OFF` is set, that string is used as the regex instead; (c) if `PONYTAIL_AGENT_MODE_MAP` parses as JSON, per-agent mode overrides take precedence over `PONYTAIL_DEFAULT_MODE`; (d) invalid JSON falls back to `PONYTAIL_DEFAULT_MODE` with a logged warning.
    — **Consumers affected:** Phase 3.1 (env vars wire into these); Phase 5.3/5.4 (override verification).

### Phase 3: Wire env vars

Export the 3 ponytail env vars in `docker-entrypoint.sh` and document them in `.env.example`.

- [ ] **3.1** Add `export` lines to `opencode_app/docker-entrypoint.sh` for `PONYTAIL_DEFAULT_MODE=full`, `PONYTAIL_SUBAGENT_OFF` (default off-set regex string), and optional `PONYTAIL_AGENT_MODE_MAP` (JSON, unset by default)
    — **Why:** The wrapper reads these at load time. Exporting in the entrypoint (vs hardcoding in the plugin) keeps configuration external and overridable per-deploy. `PONYTAIL_DEFAULT_MODE=full` is locked decision #4.
    — **Done when:** `docker-entrypoint.sh` exports all 3 vars with safe defaults (`PONYTAIL_DEFAULT_MODE` defaults to `full`; `PONYTAIL_SUBAGENT_OFF` defaults to the 7-agent regex; `PONYTAIL_AGENT_MODE_MAP` left unset unless provided).
    — **Consumers affected:** Phase 2.4 (plugin reads the env vars); Phase 5.1 (container must load with these set).
- [ ] **3.2** Document the 3 env vars in `.env.example` with comments explaining each
    — **Why:** `.env.example` is the discoverable configuration reference for Docker/CI developers. Each var needs a one-line purpose + example value so users can override without reading the plugin source.
    — **Done when:** `.env.example` contains 3 documented entries (key, example value, `# comment`) grouped under a `# Ponytail` header.
    — **Consumers affected:** developers configuring local Docker; CI env files.

### Phase 4: Docs sync

Update `opencode_app/README.md` and `README.md` to document the ponytail feature per AGENTS.md sync rules.

- [ ] **4.1** Add a "Ponytail Plugin" section to `opencode_app/README.md` covering: what it does, the 6 commands, the 3 env vars, the agent off-set, and the MIT attribution pointer
    — **Why:** `opencode_app/README.md` is the Docker-mode reference; users running the container need the command list and env-var reference at hand. Locked acceptance criterion requires this doc.
    — **Done when:** Section exists with: purpose paragraph, command table (6 commands), env var table (3 vars), off-set agent list, link to `ATTRIBUTION.md`.
    — **Consumers affected:** Docker users; acceptance criterion.
- [ ] **4.2** Add a ponytail row to the features section of `README.md` (repo-level)
    — **Why:** `README.md` is the repo-level feature index; the ponytail integration is a user-visible feature. Locked acceptance criterion requires this.
    — **Done when:** Features section includes a one-line ponytail entry (name + one-sentence description + MIT note).
    — **Consumers affected:** repo-level doc readers; acceptance criterion.
- [ ] **4.3** Invoke `documentation-sync-workflow` skill or delegate to `opencode-tooling-subagent` per repo convention to verify no cross-file drift introduced
    — **Why:** AGENTS.md "Adding Skills or Subagents — Sync Rules" requires cross-file consistency checks when adding new plugin/skill surfaces. This is the repo-mandated sync step.
    — **Done when:** Sync skill/agent confirms no count/structure drift introduced by the new plugin + skill directory; any required `setup.sh`/`setup.ps1` count updates applied.
    — **Consumers affected:** repo documentation consistency; future contributors.

### Phase 5: Verification

End-to-end verification across Docker and user-space deploy paths.

- [ ] **5.1** Docker rebuild + `/ponytail-help` returns help text in the running container
    — **Why:** Confirms the plugin auto-loads in Docker (acceptance criterion). Build catches syntax/import errors in the `.mjs` before runtime.
    — **Done when:** `docker compose up -d` succeeds; `/ponytail-help` in a `build`-agent chat returns the help text listing all 6 commands.
    — **Consumers affected:** acceptance criterion; downstream users.
- [ ] **5.2** Mode switching works — `build` agent reports ponytail active at mode `full` by default; `/ponytail ultra` persists across turns
    — **Why:** Acceptance criterion — default mode is `full` (locked #4) and mode commands must persist within the session.
    — **Done when:** (a) `/ponytail` (status) in a fresh `build` session reports mode `full`; (b) after `/ponytail ultra`, a subsequent turn's status reports `ultra`; (c) transform log shows `ultra` instructions appended.
    — **Consumers affected:** acceptance criterion.
- [ ] **5.3** Off-set agents skip injection — log check confirms `explore`, `general`, `autoresearch-research-subagent`, `explorer-subagent`, `requirements-specialist-subagent`, `discovery-specialist-subagent`, `technical-design-specialist-subagent` log "ponytail skipped: agent in off-set"
    — **Why:** Acceptance criterion — read-only/research agents must NOT receive the ruleset. The log line is the mechanical proof.
    — **Done when:** For each of the 7 off-set agents, triggering a chat produces the "ponytail skipped" log line and the system prompt does NOT contain ponytail instructions.
    — **Consumers affected:** acceptance criterion; scoping correctness.
- [ ] **5.4** `PONYTAIL_SUBAGENT_OFF` override verification — set a custom regex, rebuild, confirm an additional agent is excluded
    — **Why:** Acceptance criterion — the env var must override the default off-set. Verifying with an agent NOT in the default set (e.g., `code-review-subagent`) proves the override path.
    — **Done when:** With `PONYTAIL_SUBAGENT_OFF` set to include `code-review-subagent`, a `code-review-subagent` chat logs "ponytail skipped" (excluded); reverting the env var restores default behavior.
    — **Consumers affected:** acceptance criterion.
- [ ] **5.5** User-space deploy verification — `./deploy/setup.sh --quick` deploys the wrapper to `~/.config/opencode/plugins/` and it loads in user-space OpenCode
    — **Why:** Acceptance criterion — both Docker + user-space deploy paths must work (locked #5). The `deploy_plugins()` function already handles `plugins/` → `~/.config/opencode/plugins/`; this confirms the path resolves and the plugin loads outside Docker.
    — **Done when:** `./deploy/setup.sh --quick` completes; `~/.config/opencode/plugins/ponytail-scoped.mjs` exists; user-space OpenCode `/ponytail-help` returns help text.
    — **Consumers affected:** acceptance criterion; user-space users.
- [ ] **5.6** No double-injection check — confirm stock `@dietrichgebert/ponytail` is NOT in `opencode.json` `plugins` array; the transform hook appends instructions exactly once per session
    — **Why:** Acceptance criterion + locked #6 — double-injection would duplicate the ruleset in the system prompt, degrading quality. The guard is both config-level (stock not in array) and runtime-level (idempotent transform).
    — **Done when:** (a) `grep ponytail opencode.json` returns only the wrapper path (no npm package); (b) triggering two consecutive transforms in one session produces the instructions string appended exactly once (idempotency check in the hook).
    — **Consumers affected:** acceptance criterion; prompt quality.

### Phase 6: Cleanup

Remove spike artifacts and run final checks.

- [ ] **6.1** Remove all spike debug logging (the scratch plugin from Phase 0.1 and any `console.log` debug lines added during the spike)
    — **Why:** Debug logging in production spams container stdout and may leak the transform arg shape (which could include session metadata). Must be removed before merge.
    — **Done when:** No `console.log` debug statements remain in `ponytail-scoped.mjs` or any committed scratch plugin; the scratch plugin file is deleted.
    — **Consumers affected:** production container cleanliness; acceptance criterion.
- [ ] **6.2** Final lint/typecheck if applicable — run any repo linter (e.g., `npx tsc --noEmit` if a tsconfig exists for plugins, or the project's standard lint command) against the new `.mjs`/`.cjs` files
    — **Why:** Mechanical guard against syntax errors the spike might have masked.
    — **Done when:** Linter exits 0 (or reports only pre-existing warnings unrelated to the new files).
    — **Consumers affected:** merge gate; CI.

## Open Questions (locked — do not re-litigate)

1. **Locked:** Wrapper plugin approach (not stock npm plugin) — agent-type scoping is the core value.
2. **Locked:** Vendored ruleset (zero runtime npm dependency, works air-gapped).
3. **Locked:** Read-only/research agents default OFF (the 7 agents listed in acceptance criteria).
4. **Locked:** Default mode: `full`.
5. **Locked:** Both Docker + user-space deploy (`setup.sh deploy_plugins()` handles `plugins/` → `~/.config/opencode/plugins/`).
6. **Locked:** Stock ponytail MUST NOT be in `opencode.json` plugin array (double-injection guard).
7. **Deferred to Phase 0 spike:** Exact agent-type field path in the `experimental.chat.system.transform` arg — resolved during the spike; fallback (global injection + mode banner) if undiscoverable.
8. **Deferred to fast-follow (if spike fallback):** Per-agent mode map advanced tuning beyond the 7-agent off-set.
