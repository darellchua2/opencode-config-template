# PLAN-GIT-286: Project-scoped selective installer CLI + TUI (`opencode-init`)

**Issue**: https://github.com/darellchua2/opencode-config-template/issues/286
**Branch**: `feat/286-opencode-init-cli`
**Created**: 2026-08-02
**Revised**: 2026-08-02 (after opencode-tooling review — see Revision Log)

## Problem

`setup.sh` deploys **all 38 agents + 127 skills globally** to `~/.config/opencode/` with no
selectivity for agents/skills (the existing pack system only toggles MCP servers). Not all users
want everything installed globally — many want to apply a **curated subset** to a **specific target
project** and choose what they install. The installer must also be **invokable through the LLM**:
the user asks the agent "install review agents here" and the agent understands and runs the command.

## Solution

A new standalone CLI — `deploy/init.mjs` — that copies a curated subset of agents + skills into a
target project and writes a project `opencode.json` configuring that subset, driven by an interactive
TUI for humans AND flag-based invocation for the LLM/CI (the flag path is primary). The existing
global `setup.sh` stays untouched (plus one additive symlink line). Both input paths share one core
(registry → presets → resolver → writer); only the input layer differs.

```
end user (in an opencode session) → "install review agents here"
   │  LLM reads routing rule in deployed AGENTS.md, introspects, runs
   ▼
opencode-init --project . --preset review --yes
   │  init.mjs reads registry.json → expands preset → resolves deps → writes
   ▼
<project>/opencode.json            ← generated config (project ROOT, not .opencode/)
<project>/AGENTS.md                ← slim derived instructions
<project>/.opencode/agents/*.md    ← only selected agents (resolved models injected)
<project>/.opencode/skills/<name>/ ← only selected skills
<project>/.opencode/models.json    ← tier→model map (deploy-side artifact, consumed by resolver)
```

###  Critical opencode semantics (verified against opencode.ai/docs)

These shape every design decision below and were the subject of the review's BLOCKER findings:

1. **Configs MERGE, they do not replace** ([config#locations](https://opencode.ai/docs/config#precedence-order)):
   *"Configuration files are merged together, not replaced… Non-conflicting settings from all configs
   are preserved."* Later sources override earlier ones **only for conflicting scalar keys**.
2. **Agents/skills are ADDITIVE across all locations** — `~/.config/opencode/{agents,skills}/` and
   `<project>/.opencode/{agents,skills}/` are **unioned**. Project agents do NOT shadow/replace global
   ones; they are added on top. → The "curated subset" outcome is only achieved on a **clean slate**
   (no global agent/skill deploy). If the user ran `setup.sh` globally, a project install is additive.
3. **`permission.skill` merges as a UNION** — a project `{"*":"deny", "<subset>":"allow"}` merged with
   a global allowlist yields the **union** of allows. → Scoped skill visibility only restricts on a
   clean slate; it cannot hide globally-allowed skills.
4. **`permission.task` CAN restrict** — project `"*":"deny"` overrides global `"*":"allow"` for that
   conflicting key, and task rules are last-match-wins ([agents#task-permissions](https://opencode.ai/docs/agents#task-permissions)).
   So scoped subagent-spawn restriction works even with a global deploy — but a user can still
   `@`-mention any globally-installed subagent directly (docs: *"Users can always invoke any subagent
   directly via the @ autocomplete menu"*). Acceptance criterion is "the model won't auto-spawn
   unselected subagents", not "the user can never invoke them".
5. **Project config path is the project ROOT** — `opencode.json` at `<project>/opencode.json`, NOT
   `<project>/.opencode/opencode.json` ([config#per-project](https://opencode.ai/docs/config#per-project):
   *"Place project specific config in the root of your project."*). The `.opencode/` directory holds
   agents/commands/plugins/skills only. The repo itself follows this (`opencode_app/opencode.json` at
   root; `.opencode/` for agents/skills/plugins).

### Locked design decisions (from planning session + review revisions)

1. **CLI shape** — New standalone `deploy/init.mjs`; `setup.sh` global deploy untouched (+1 additive symlink line).
2. **Selection UX** — Presets + manual multi-select (TUI); flags + `--list`/`--expand` (LLM/CI).
3. **Target config** — Generate `<project>/opencode.json` (ROOT) with a scoped `permission.task` allowlist. **Clean-slate caveat:** scoped `permission.skill` visibility + agent isolation only hold when no global agent/skill deploy exists; the CLI detects + warns if `~/.config/opencode/agents/` is non-empty.
4. **Distribution** — Run from this repo; the LLM invokes the CLI via `opencode-init` symlinked onto PATH.
5. **Category source** — Add `category:` frontmatter to all agents + skills (single source of truth; also feeds the README category table, eliminating sync drift).
6. **Project AGENTS.md** — Generate a slim derived `<project>/AGENTS.md` (only routing rules relevant to the selection).
7. **Task perms** — Scoped allowlist: emit `permission.task` as `{ "*": "deny" }` **FIRST**, then every **transitively-reachable** selected subagent stem + `explore` + `general` as `"allow"` (last-match-wins requires `"*"` first). Document the `@`-mention bypass.
8. **`--yes` semantics** — Auto-resolve all `requiresSkills` AND the transitive closure of `delegatesTo` subagents, with the default model tier — zero prompts.

### Key enablers (already exist in the repo — low risk; verified by review)

- **TUI primitives** in `deploy/tui.mjs` — BUT it has top-level dispatch that fires on import (Phase 4.0 extracts them into `deploy/tui-primitives.mjs`).
- **Pack + deep-merge pattern** (`deploy/merge-packs.mjs:87-103` `deepMerge`) — generic, reusable for preset/permission merging.
- **Dependency data is already in frontmatter** — every agent's `permission.task.*` (subagents it spawns) and `permission.skill.*` (skills it needs) IS the dependency graph (verified on code-review/architecture-review/explorer/startup-founder).
- **Model resolution** (`deploy/resolve-models.mjs`) supports `--agents-src/--agents-dest/--project-map/--config-src/--tiers/--default-map/--provider/--json/--dry-run` (verified, lines 39-62); iterates the dest dir, so pointing `--agents-dest` at the copied-subset dir resolves only selected agents.

---

## Dependency & Consumer Map

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
| ------------------ | ------------------------- | ------------------------------- | ----------- |
| `category:` frontmatter on all agents + skills | — | `build-registry.mjs`, README category table | low (1 line each, additive) |
| `deploy/build-registry.mjs` (NEW) | frontmatter categories | `init.mjs` (--list, --expand, TUI, resolver) | med (frontmatter parsing — 3 shapes) |
| `deploy/registry.json` (generated) | build-registry.mjs | init.mjs (all modes); README regen | low (committed artifact) |
| `deploy/presets/*.json` (NEW) | registry.json | init.mjs preset expansion | low (data) |
| `deploy/dependency-map.json` (NEW) | — | init.mjs `impliesMcp` + non-frontmatter deps | low (data) |
| `deploy/tui-primitives.mjs` (NEW, extracted) | tui.mjs | init.mjs TUI flows; tui.mjs (re-imports) | low (mechanical refactor) |
| `deploy/init.mjs` (NEW) | registry, presets, dep-map, tui-primitives, resolve-models.mjs | LLM (via AGENTS.md routing); human TUI | high (core new tool) |
| `deploy/.AGENTS.md` (edit: new routing section) | init.mjs exists | deployed `~/.config/opencode/AGENTS.md` → LLM routing | low (docs) |
| `deploy/setup.sh` / `setup.ps1` (edit: 1 symlink line) | init.mjs exists | `opencode-init` on PATH | low (additive) |
| `<project>/opencode.json` (generated, ROOT) | init.mjs writer | target project's opencode session | med (merge-semantics correctness) |
| `README.md` (edit) | registry categories | users, docs sync | low |
| `tests/init.bats` (NEW) | init.mjs | CI | med (test coverage) |

---

## Implementation Phases

### Phase 0: Verify the foundational assumptions (BLOCKER gates)

- [x] **0.1** Confirm the project-config read-path empirically: in a scratch temp project, create BOTH `<tmp>/opencode.json` (root) and `<tmp>/.opencode/opencode.json`, each setting a distinguishable `model` value, then run `opencode debug config` inside `<tmp>` and inspect which value wins. Document the result in this plan's Revision Log. Per the docs the ROOT file is authoritative; verify `.opencode/opencode.json` is NOT also read (or note if it is).
    — **Why:** The whole writer target depends on this; the docs imply root but the plan must not ship on an assumption.
    — **Done when:** `opencode debug config` output recorded; the plan's `<project>/opencode.json` (root) target confirmed as the read-path; if `.opencode/opencode.json` is ALSO read, note it as a fallback location.
    — **Consumers affected:** Phase 3.3, all writer specs.

- [x] **0.2** Confirm clean-slate detection signal: verify `~/.config/opencode/agents/` is the correct global-deploy marker (check what `setup.sh` actually populates — agents land in `${CONFIG_DIR}/agents` per `setup.sh:91`). Decide the warning text the CLI emits when a global deploy is detected ("project install is additive to your 38 global agents; for isolation, run on a machine/profile without a global deploy").
    — **Why:** Sets honest user expectations given merge semantics (review BLOCKER #1).
    — **Done when:** Detection logic spec written (check `~/.config/opencode/agents/` + `~/.config/opencode/skills/` non-empty); warning copy drafted.
    — **Consumers affected:** init.mjs startup, README.

### Phase 1: Foundation — frontmatter categories + registry generator

- [x] **1.1** Add a `category:` field to the YAML frontmatter of every agent file in `opencode_app/.opencode/agents/*.md` (38 files). Derive the category from the README's existing agent groupings (review, frontend, backend, docs, devops, business, research, cad, integrations, meta). One line per file; place after `description:`.
    — **Why:** `category:` becomes the single source of truth for grouping in the TUI + `--list` output AND the README category table.
    — **Done when:** Every agent `.md` has a non-empty `category:` key; values from a fixed taxonomy; consistent casing/spelling.
    — **Consumers affected:** build-registry.mjs, README category table.

- [x] **1.2** Add a `category:` field to every `SKILL.md` in `opencode_app/.opencode/skills/*/SKILL.md` (127 files), using the README's 21 skill categories as the fixed taxonomy. One line per file; place after the `metadata:` block.
    — **Why:** Lets the TUI group 127 skills into scannable buckets and lets `--list skills --category <x>` filter precisely.
    — **Done when:** Every `SKILL.md` has a `category:` matching one of the 21 canonical categories; `grep -L "^category:" opencode_app/.opencode/skills/*/SKILL.md` returns nothing.
    — **Consumers affected:** build-registry.mjs, README category table.

- [x] **1.3** Create `deploy/build-registry.mjs` (ESM, zero-dependency). The hand-rolled YAML frontmatter parser MUST handle the **3 shapes** verified in the repo: (a) scalar values (`task: allow`, `edit: allow`, `bash: deny` — e.g. `startup-founder-primary-agent.md`, `explorer-subagent.md`); (b) one-level-nested maps (`permission.task: { "*": deny, explore: allow, … }`, `permission.skill: { … }` — e.g. `code-review-subagent.md`, `architecture-review-subagent.md`); (c) **absent keys** (e.g. `explorer-subagent.md` has no `task`). Descriptions are single-line (verified). Emit `deploy/registry.json`: agent entries `{stem, description, mode, tier (from agent-tiers.json), category, requiresSkills[], delegatesTo[], requiredBy[]}` and skill entries `{name, description, category, audience, workflow, requiredByAgents[]}`. `requiresSkills` = keys under `permission.skill`; `delegatesTo` = keys under `permission.task` excluding `*`; reverse edges computed. Tolerate missing `category:` → emit `"uncategorized"` + stderr warn (never hard-fail).
    — **Why:** The registry is the single runtime data source; the parser must cover all real frontmatter shapes or it will silently drop deps for scalar-style agents.
    — **Done when:** `node deploy/build-registry.mjs` writes `registry.json`; `jq '.agents|length'` = 38, `jq '.skills|length'` = 127; **fixture round-trip**: re-parse all 38 agent files and assert `requiresSkills`+`delegatesTo` for 5 sample agents (code-review, architecture-review, explorer, startup-founder, tdd) match a manual check; scalar-style `task: allow` agents parse without error.
    — **Consumers affected:** init.mjs (all modes).

- [x] **1.4** Run the generator, commit `deploy/registry.json` (tracked, NOT gitignored). Add a top-of-file `$comment` naming the generator + regen command (`node deploy/build-registry.mjs`). Add a **registry-drift guard** note for Phase 5 (CI diff frontmatter vs registry).
    — **Why:** A committed, version-pinned registry means consistent data without per-user regen.
    — **Done when:** `registry.json` committed as a new tracked file; `$comment` present.
    — **Consumers affected:** all downstream phases.

### Phase 2: `--list` / `--expand` introspection + presets (LLM-usable, pure-read)

- [x] **2.1** Create `deploy/init.mjs` skeleton (ESM, zero-dependency, mirrors `tui.mjs` arg-parsing/camelCase conventions). Arg parsing for all flags (`--project`, `--preset`, `--agents`, `--skills`, `--mcps`, `--provider`, `--yes`, `--dry-run`, `--force`, `--prune`, `--list`, `--expand`, `--describe`, `--category`, `--help`). Dispatch handles `--list`/`--expand`/`--describe`/`--help` now (writer/TUI in later phases). Resolve the source tree via `import.meta.url` so cwd is irrelevant.
    — **Why:** Establishes the CLI contract + LLM's primary introspection surface before any write logic.
    — **Done when:** `--help` prints usage; `--list`/`--expand`/`--describe` work + exit 0; unknown flags exit non-zero with a clear error.
    — **Consumers affected:** LLM introspection loop.

- [x] **2.2** Implement `--list` subcommands emitting JSON: `--list agents` (`[{stem,description,category,tier}]`), `--list agents --category review`, `--list skills` (`[{name,description,category}]`), `--list skills --category code-quality`, `--list categories` (sorted unique + counts), `--list mcps` (from `opencode_app/opencode.json`). Read from `registry.json`. `--list presets` resolves after 2.4.
    — **Why:** The LLM needs structured output to decide what to install.
    — **Done when:** Each variant prints valid JSON; `--category` filters; `jq` parses all outputs; empty filters print `[]`.
    — **Consumers affected:** LLM decision loop, TUI category display.

- [x] **2.3** Create `deploy/dependency-map.json` with an `impliesMcp` map (skill → MCP server key): `nextjs-devtools-mcp-skill`→`next-devtools`, `markitdown-mcp-skill`→`markitdown`, `microsoft-m365-config-skill`→the 9 microsoft-* servers, `codegraph-setup-skill`→`codegraph`. `$comment` documents that frontmatter remains the primary dep source; this covers only skill→MCP.
    — **Why:** MCP selection should auto-derive from chosen skills.
    — **Done when:** JSON valid; every value matches a real MCP key in `opencode_app/opencode.json`.
    — **Consumers affected:** init.mjs MCP derivation (Phase 3).

- [x] **2.4** Create `deploy/presets/*.json` — one per preset (`core`, `review`, `frontend`, `backend`, `docs`, `devops`, `business`, `research`, `cad`, `integrations`): `{ "name", "description", "agents":[…stems], "skills":[…names], "mcps":[…keys] }`. Derive from the README category/agent tables. Validate at load that every listed agent/skill exists in `registry.json` (fail loud on stale preset). Order note: presets must exist before `--list presets` (2.2) and `--expand` (2.5) resolve them — execute 2.4 before wiring those outputs.
    — **Why:** Presets are the fast-path UX and seed the TUI's pre-checked multi-select.
    — **Done when:** 10 files exist; each validates against the registry; `--list presets` prints all 10 with member counts.
    — **Consumers affected:** init.mjs preset expansion, TUI, `--expand`.

- [x] **2.5** Implement `--expand <preset>`: print the FULL resolved set the preset would install — agents (incl. transitive `delegatesTo` closure), skills (incl. all `requiresSkills`), MCPs (incl. `impliesMcp`-derived) — WITHOUT writing. This is the LLM's "what will this actually pull in?" introspection that `--describe` (per-agent) and `--list presets` (names only) don't provide.
    — **Why:** Closes the gap between "I see a preset name" and "I commit to installing it"; the LLM can preview the closure before `--yes`.
    — **Done when:** `--expand review` prints the complete agent+skill+mcp closure as JSON; matches what `--preset review --yes --dry-run` would write.
    — **Consumers affected:** LLM decision loop.

- [x] **2.6** Implement `--describe <name>`: print a JSON object with the full registry entry (description, category, tier, requiresSkills, delegatesTo, requiredBy) PLUS a `modelAvailable` check — warn (in the JSON, as a field) if the agent's resolved tier model is NOT in `deploy/provider-models.json` (prevents the `glm-5.1`-not-selectable class of bug from PLAN-GIT-283).
    — **Why:** Gives the LLM everything needed to decide + flags a known failure mode before install.
    — **Done when:** `--describe code-review-subagent` shows 11 skills + 5 delegates + reverse edges + `modelAvailable: true`; an agent on a stale tier shows `modelAvailable: false` + the missing model.
    — **Consumers affected:** LLM decision loop.

### Phase 3: Resolver + writer (the install — `--agents X --yes` end-to-end)

- [x] **3.1** Implement the **selection resolver** (pure function, no I/O): given `--agents`/`--skills`/`--mcps`/`--preset`, compute the final set. Algorithm: (a) expand presets; (b) union explicit inputs; (c) for each final agent, union its `requiresSkills` (silent auto-include); (d) walk `delegatesTo` excluding built-ins `explore`/`general` → with `--yes` auto-include the **transitive closure** (recurse); without `--yes` defer to the TUI prompt (Phase 4); (e) derive MCPs from chosen skills via `dependency-map.json`, union with explicit `--mcps`; (f) compute `requiredBy` reverse-edge warnings for removals. Emit `{agents:[], skills:[], mcps:[], warnings:[]}`.
    — **Why:** The brain that turns "I picked code-review" into "code-review + 5 reviewers + image-analyzer + all their skills + codegraph MCP".
    — **Done when:** Resolving `--agents code-review-subagent --yes` yields code-review + 5 language reviewers + image-analyzer + union of all skills + codegraph MCP; unit-testable as a pure function.
    — **Consumers affected:** writer (3.2), TUI (Phase 4).

- [x] **3.2** Implement the **writer** with manifest tracking: copy selected agent files → `<project>/.opencode/agents/`, skill dirs → `<project>/.opencode/skills/`. Create the `.opencode/` tree if missing. Write a **manifest** at `<project>/.opencode/.opencode-init.manifest.json` recording every path installed (agent stems, skill names, mcp keys, config-path, models-path, AGENTS.md-path) with a timestamp — this enables `--prune` (3.7) to remove only what THIS tool wrote. Never overwrite an existing DIFFERENT file without `--force` (diff-check; on conflict warn + skip unless `--force`). Respect `--dry-run` (print manifest, write nothing).
    — **Why:** The manifest makes re-runs safe (only opencode-init-owned files are prunable) and the conflict-guard prevents clobbering hand-edited project agents.
    — **Done when:** `--agents explorer-subagent --dry-run` lists exactly the agent file + writes nothing; without `--dry-run` the file + manifest appear; re-running is idempotent; a pre-existing differing file is skipped unless `--force`.
    — **Consumers affected:** the target project's `.opencode/`, `--prune` (3.7).

- [x] **3.3** Implement **`<project>/opencode.json` generation at the project ROOT** (NOT `.opencode/opencode.json` — verified in Phase 0.1). Include: `$schema`; `subagent_depth: 3`; `instructions: ["AGENTS.md"]`; `permission.skill: {"*":"deny", "<each selected skill>":"allow"}` (note: only restricts on clean slate — see semantics #3); `agent.build` block with `permission.task` = `{ "*": "deny" }` **FIRST** then every **transitively-reachable** selected subagent stem + `explore` + `general` as `"allow"` (last-match-wins; see decision 7 + semantics #4); `agent.plan`, `agent.explore`, `agent.general` blocks (copied/adapted from `opencode_app/opencode.json:375-410` — the primary session needs build+plan); `mcp` = only selected servers each `enabled:true`; `tools` = corresponding `"<ns>*": true`. If `<project>/opencode.json` already exists, refuse + point at it (no auto-merge — merge semantics make this dangerous); offer `--force` to overwrite. Document the `@`-mention bypass in a generated comment.
    — **Why:** The generated config makes the subset actually work; ROOT path is what opencode reads; build/plan blocks are required for the primary to function on a clean slate.
    — **Done when:** `opencode debug config` in the scratch project shows the resolved config reflects the generated file; `permission.task` has `"*":"deny"` first; `agent.build`+`agent.plan`+`agent.explore`+`agent.general` all present; only selected MCPs appear; `--dry-run` prints the would-be JSON; `@`-mention-bypass noted.
    — **Consumers affected:** the target project's opencode session.

- [x] **3.4** Wire **model resolution**: invoke `deploy/resolve-models.mjs --agents-src <repo agents> --agents-dest <project>/.opencode/agents --tiers agent-tiers.json --default-map models.default.json --project-map <project>/.opencode/models.json --config-src opencode_app/opencode.json [--provider X]` so each copied agent `.md` gets its `model:` injected per tier, and `<project>/.opencode/models.json` is written (tier→model map for selected agents only; a deploy-side artifact, not read by opencode directly). Honor `--provider`/`--mix` via the existing `flowProviderPicker` (now in `tui-primitives.mjs` after 4.0).
    — **Why:** Project-scoped agents need concrete models; reuse the resolver (verified flags, lines 39-62).
    — **Done when:** Each `<project>/.opencode/agents/*.md` has a `model:` line; `<project>/.opencode/models.json` exists with only the selected tiers; `--provider anthropic` swaps the map first.
    — **Consumers affected:** the target project's agent spawning.

- [x] **3.5** Implement **slim `<project>/AGENTS.md` generation** (decision 6): derive a project-level instructions file with only the routing rules + MCP/tool notes relevant to the selection (extract fragments from the repo's `AGENTS.md`/`deploy/.AGENTS.md` — e.g. vision-delegation rule iff `image-analyzer-subagent` selected; codegraph-routing iff codegraph MCP selected; always include a trimmed Task Delegation Order covering selected subagents). Keep under ~2KB. Skip sections whose referenced agents/skills aren't selected.
    — **Why:** The primary needs routing guidance to USE the subset correctly, without the full 7KB global file's irrelevant rules.
    — **Done when:** Generated AGENTS.md references only selected agents/skills/MCPs; valid Markdown; `--dry-run` shows it; re-running with a different selection regenerates it.
    — **Consumers affected:** the target project's primary agent behavior.

- [x] **3.6** Add a **summary + confirm** step (non-`--yes` path): print a table (agents/skills/MCPs to install, deps auto-pulled, files to write, MCPs implied, clean-slate status) and `confirm()` before proceeding. With `--yes`, skip the prompt (decision 8). Both honor `--dry-run`.
    — **Why:** A human without `--yes` should see exactly what lands first.
    — **Done when:** Non-`--yes` prints table + prompts; `--yes` writes immediately; both honor `--dry-run`.
    — **Consumers affected:** UX safety.

- [x] **3.7** Implement **`--prune`**: using the manifest (3.2), remove `<project>/.opencode/{agents,skills}` entries that THIS tool previously installed but are NOT in the current resolved set. Never touch files absent from the manifest (user-owned agents/skills are safe). Regenerate `opencode.json`/`AGENTS.md`/`models.json` for the new set. Default OFF; on a normal re-run with a different selection, WARN that orphans exist and suggest `--prune`.
    — **Why:** Without prune, re-running with a different selection orphans the previous install (and given opencode unions directories, orphans accumulate and bloat the visible set).
    — **Done when:** Install `review`, then `--preset docs --prune` removes review agents/skills (only those in the manifest) and leaves docs; user-owned agents untouched; manifest regenerated.
    — **Consumers affected:** re-run safety.

### Phase 4: Interactive TUI flows (human-in-terminal path)

- [x] **4.0** **Extract `deploy/tui-primitives.mjs`** from `deploy/tui.mjs`: move `singleSelect`, `multiSelect`, `textInput`, `confirm`, the TTY/ANSI helpers (`isTTY`, `hide`/`show`, `clearN`), `readJsonMaybe`, `parseArgs`, and the flow functions (`flowProviderPicker` etc.) into the new module. Rewrite `tui.mjs` to `import` from `tui-primitives.mjs` and keep only its top-level dispatch. **Why this is mandatory:** `tui.mjs:411-428` runs `switch(process.argv[2])` + `process.exit(0)` at module top level — importing it directly crashes the caller. Verify `tui.mjs`'s existing flows still work after the refactor.
    — **Why:** init.mjs cannot import tui.mjs as-is (process exits on import); the extraction is the only safe way to reuse the proven primitives.
    — **Done when:** `node deploy/tui.mjs provider-picker --presets deploy/provider-presets.json` still works; `node -e "import('./deploy/tui-primitives.mjs').then(m=>console.log(typeof m.singleSelect))"` prints `function` without exiting.
    — **Consumers affected:** init.mjs TUI (4.1), tui.mjs.

- [x] **4.1** Implement the interactive flow in `init.mjs` importing from `tui-primitives.mjs`. Flow: (1) `textInput` target project (default cwd); (2) `singleSelect` preset-or-skip; (3) if preset, `confirm` its expansion; (4) `multiSelect` adjust agents (preset pre-checked); (5) `multiSelect` adjust skills (required skills locked as checked + un-toggleable — lock marker); (6) `multiSelect` adjust MCPs (auto-derived pre-checked); (7) delegate to `flowProviderPicker`; (8) summary table + `confirm`; (9) write. Non-TTY → exit non-zero with "re-run with flags" (same contract as existing tui.mjs flows). Depends on 4.0.
    — **Why:** The TUI is the secondary human path; must reuse the proven primitives (now extracted).
    — **Done when:** `node deploy/init.mjs` (no flags) in a real TTY walks all 9 steps; arrow/space/enter behave as in `tui.mjs`; required skills can't be unchecked; Esc cancels cleanly (terminal restored); non-TTY exits non-zero with a clear message.
    — **Consumers affected:** human users.

- [x] **4.2** Implement the **transitive-subagent prompt** (non-`--yes` branch of 3.1d): after the user adjusts agents, for each selected agent's `delegatesTo` (excluding built-ins) not already selected, `confirm("X can spawn Y — include Y?")`; on yes, add Y + recurse its delegates.
    — **Why:** Without this, a human who picks code-review but declines reviewers gets a broken delegation chain silently.
    — **Done when:** Selecting code-review prompts for each of its 5 reviewer delegates; accepting one prompts for THAT delegate's delegates; declining leaves it unselected, no crash.
    — **Consumers affected:** human users.

### Phase 5: LLM discoverability + setup wiring + docs + tests

- [x] **5.1** Add a `## Project-Scoped Install` routing section to `deploy/.AGENTS.md` (deploys to `~/.config/opencode/AGENTS.md` → LLM knows the command in ANY project). Document: trigger phrases ("install subagents here", "set up agents for this repo", "add review agents", "project-level opencode config", "apply agents to this project"); the `opencode-init` command; the introspection pattern (`--list categories` → `--list agents --category X` → `--describe <name>` → `--expand <preset>` → `--agents <stems> --yes`); preset-first guidance; **the clean-slate caveat** (isolation requires no global agent/skill deploy). Mirror the style of `## Task Delegation Order` / `## Branch Workflow Setup Signal`.
    — **Why:** The entry point that makes "ask the LLM to run it" work — including honest expectations about merge semantics.
    — **Done when:** Section present; covers triggers + command + introspection loop + preset-first + clean-slate caveat.
    — **Consumers affected:** the primary LLM session in every target project.

- [x] **5.2** Add one additive symlink line to `deploy/setup.sh` (mirror in `deploy/setup.ps1`): after global deploy, symlink `<repo>/deploy/init.mjs` → `~/.local/bin/opencode-init`. Reuse the `~/.local/bin` PATH-check pattern at `setup.sh:~2587`. Idempotent (skip if symlink already correct; refresh if stale). Windows (`setup.ps1`): create a `opencode-init.cmd` wrapper shim in `%APPDATA%`\…\ (do NOT rely on `mklink` which needs Developer Mode/admin) — the shim invokes `node "<repo>\deploy\init.mjs" %*`. Do NOT change existing setup.sh behavior — purely additive.
    — **Why:** Puts `opencode-init` on PATH so the LLM/humans can call it from any cwd; the wrapper avoids Windows symlink privilege issues.
    — **Done when:** After `./deploy/setup.sh`, `command -v opencode-init` resolves + `opencode-init --list categories` works from `/tmp`; re-running setup.sh doesn't error on the existing symlink; `setup.ps1` creates the `.cmd` shim.
    — **Consumers affected:** every system that runs global deploy.

- [x] **5.3** Update `README.md`: add a `## Project-Scoped Install` section documenting the CLI (usage, presets table, the LLM-invocation model, `--list`/`--expand`/`--describe`, `--dry-run`, `--prune`). **State plainly that global `setup.sh` and project `opencode-init` are MUTUALLY EXCLUSIVE for isolation** (not complementary) — opencode merges/unions config + agents/skills, so a project subset only yields a curated experience on a clean slate (no global deploy); with a global deploy present, project install is additive. Document the clean-slate detection warning. Cross-link issue #286.
    — **Why:** Users must discover the new mode AND understand the merge-semantics interaction to set correct expectations (review BLOCKER #1).
    — **Done when:** Section exists with presets table + examples; mutually-exclusive-for-isolation stated; clean-slate warning documented; links the issue.
    — **Consumers affected:** users reading the README.

- [x] **5.4** Create `tests/init.bats` (bats-core under `tests/lib/`): cover (a) `--list` variants → valid JSON + counts; (b) `--describe` returns skills/delegates + `modelAvailable`; (c) `--expand <preset>` matches `--preset <p> --yes --dry-run`; (d) resolver `--agents code-review-subagent --yes` pulls 5 reviewers + image-analyzer + skill union + codegraph MCP; (e) `--dry-run` writes nothing + prints manifest; (f) non-TTY no-selection exits non-zero; (g) generated `opencode.json` at project ROOT has scoped `permission.task` (`"*":"deny"` first) + `agent.build`/`plan`/`explore`/`general`; (h) re-run idempotent; (i) conflict skipped without `--force`; (j) `--prune` removes only manifest-owned files; (k) clean-slate warning fires when `~/.config/opencode/agents/` is non-empty. Test via the flag path (deterministic), not the TUI.
    — **Why:** The flag path is the primary contract + deterministic; bats gives CI a real gate.
    — **Done when:** `bats tests/init.bats` passes all cases in CI without a TTY.
    — **Consumers affected:** CI, future maintainers.

- [x] **5.5** Add a **registry-drift CI guard**: a small check (CI workflow or pre-commit) that re-runs `build-registry.mjs` and fails if `deploy/registry.json` would change — prevents the registry from lying when someone edits agent/skill frontmatter and forgets to regen.
    — **Why:** The registry is committed; undetected drift makes `--list`/`--describe` silently wrong (review "Missing" #5).
    — **Done when:** CI step present; editing an agent's `category:` without regen fails the check.
    — **Consumers affected:** CI, registry integrity.

### Phase 6: Docs sync + verification

- [x] **6.1** Invoke `documentation-sync-workflow-skill` (or delegate to `opencode-tooling-subagent`) to sync: README skill/agent counts, the category tables (now registry-derived — add a note), `deploy/setup.sh`/`setup.ps1` banner help text (mention `opencode-init` as the project-scoped companion command), and confirm `opencode_app/README.md` (Docker) is N/A (Docker standalone is a containerized global instance, not a project-scope target). Confirm the new `category:` frontmatter is the single source feeding both registry + README.
    — **Why:** Per `AGENTS.md` "Sync Rules"; covers the sync table files the review flagged (setup.sh banner, setup.ps1 parity, opencode_app/README.md N/A check).
    — **Done when:** README category table matches `registry.json`; setup.sh/ps1 banner mentions opencode-init; opencode_app/README.md confirmed N/A (or updated if needed); no stale counts.
    — **Consumers affected:** docs consistency.

- [x] **6.2** End-to-end verification — **TWO scenarios** (review BLOCKER #1): **(A) Clean slate:** in a scratch project with NO global deploy, run `opencode-init --project /tmp/oc-clean --preset review --provider zai --yes`; validate (a) `/tmp/oc-clean/opencode.json` at ROOT with scoped allowlists + codegraph MCP + build/plan/explore/general blocks; (b) `.opencode/agents/` = review preset agents + transitive delegates ONLY; (c) `.opencode/skills/` = required skills ONLY; (d) `opencode debug config` shows ONLY the review subset visible/spawnable (isolation achieved); (e) each agent's `model:` resolves to a selectable model; (f) `AGENTS.md` is slim + review-only. **(B) Additive (global deploy present):** populate `~/.config/opencode/agents/` (or simulate), re-run into a second scratch project; validate + DOCUMENT that global agents remain visible (union) and that scoped `permission.task` still prevents auto-spawning unselected subagents (but `@`-mention still works). Clean up both scratch dirs.
    — **Why:** Proves the pipeline works AND honestly characterizes both real-world deployment scenarios rather than overclaiming isolation.
    — **Done when:** Scenario A passes all 6 checks with isolation confirmed; Scenario B passes with the additive behavior documented (no isolation, but task-perm restriction works).
    — **Consumers affected:** none (verification).

---

## Risks & Mitigation

- **opencode MERGES config + unions agents/skills** (review BLOCKER) → isolation only on clean slate; CLI detects + warns; README states mutually-exclusive-with-global-deploy; `permission.task` still restricts auto-spawning even with a global deploy.
- **`@`-mention bypasses `permission.task`** → accepted (docs-documented opencode behavior); acceptance criterion is "model won't auto-spawn", not "user can't invoke"; noted in generated config comment + README.
- **Project config path** → ROOT `<project>/opencode.json` per docs, verified in Phase 0.1; `.opencode/` holds agents/skills/models.json only.
- **tui.mjs import crashes the caller** (top-level dispatch + `process.exit`) → Phase 4.0 extracts `tui-primitives.mjs` (mandatory, not optional).
- **Frontmatter variety (scalar / nested-map / absent)** → parser specified for all 3 shapes + fixture round-trip (1.3); zero-dep hand-rolled is adequate (single-line values, small YAML subset).
- **Registry drift** → committed `registry.json` + CI guard (5.5) fails if frontmatter changed without regen.
- **Orphan accumulation on re-run** → `--prune` + manifest (3.7); warn on re-run with a different selection.
- **Conflicting existing project agents/config** → writer skips-with-warning unless `--force` (3.2); generated `opencode.json` refuses to overwrite without `--force` (3.3).
- **Transitive-dependency explosion under `--yes`** → `--expand` (2.5) + summary table (3.6) surface the closure before install; `--dry-run` default on first run; `core` preset stays minimal.
- **Built-in build/plan agents missing from generated config** → 3.3 emits `agent.build`/`plan`/`explore`/`general` blocks so the primary functions on a clean slate.
- **Model not selectable on user's provider** (the `glm-5.1`/PLAN-GIT-283 class) → `--describe` shows `modelAvailable` (2.6) flagging stale tiers before install.
- **opencode version compatibility** → project `.opencode/` loading + top-level `permission.skill` require a recent opencode; note a min-version in README (confirm exact version during 6.2).
- **`setup.sh` scope creep** → only ONE additive symlink line (5.2); no behavior change to global deploy.
- **Stale `react-nextjs-antipatterns-skill` worry** → moot; verified it exists at `opencode_app/.opencode/skills/react-nextjs-antipatterns-skill/` (just not in the primary allowlist).
- **Skill→skill body references not walked** → resolver only walks agent→skill; documented as a known limitation (a skill mentioning another skill in prose won't auto-pull it).

## Success Metrics

- `opencode-init --list categories` / `--expand` / `--describe` work from any cwd after global deploy (symlink on PATH).
- **Clean slate:** `opencode-init --project <scratch> --preset review --yes` produces an isolated `.opencode/` where `opencode debug config` shows ONLY the review subset visible/spawnable.
- **Additive (global present):** re-run is additive (documented); scoped `permission.task` still prevents auto-spawning unselected subagents.
- `--describe` + `--list` + `--expand` give the LLM enough to choose + preview a subset without human lookup of names.
- Re-running is idempotent; `--prune` removes only opencode-init-owned files; conflicts are guarded.
- README category table is registry-derived (no hand-maintained counts); registry-drift CI guard is green.
- `tests/init.bats` passes in CI.

## Dependencies

- Node.js v20+ (already required by the repo's other `.mjs` tooling).
- `gh` for issue linkage (already used).
- Existing `deploy/resolve-models.mjs`, `deploy/merge-packs.mjs` (reused, not modified); `deploy/tui.mjs` (refactored in 4.0 to extract primitives).
- A recent opencode version (exact min confirmed in 6.2) for project `.opencode/` loading + top-level `permission.skill`.

## Open confirmations

- None remaining — all 8 design decisions locked; review BLOCKERs/MAJORs resolved into the phases above.

---

## Revision Log

**2026-08-02 (post-review revision — applied after opencode-tooling review)** —
The review (performed by the primary session after both `opencode-tooling-subagent` and `general` failed to spawn — reasoning tier mis-resolved to unavailable `zai-coding-plan/glm-5.1`) found 3 BLOCKERs + 4 MAJORs against opencode semantics and repo realities. Revisions applied:
- **BLOCKER #1 (merge semantics):** Rewrote Problem/Solution + added a "Critical opencode semantics" block (5 verified points from opencode.ai/docs/config + /docs/agents). Reframed the value prop: isolation holds ONLY on a clean slate (no global deploy); added Phase 0.2 clean-slate detection; decision 3 + 5.3 + 6.2 now state global-vs-project are mutually-exclusive-for-isolation; added `permission.task` last-match-wins + `"*":"deny"`-first ordering (decision 7) + `@`-mention bypass note; added Scenario A/B dual verification in 6.2.
- **BLOCKER #2 (config path):** Changed all `<project>/.opencode/opencode.json` → `<project>/opencode.json` (ROOT) per docs; added Phase 0.1 to verify the read-path empirically; `models.json` stays in `.opencode/` (deploy-side artifact). Updated writer diagram + dependency map + 3.3/3.4/6.2.
- **BLOCKER #3 (tui.mjs import):** Added Phase 4.0 (mandatory extraction of `deploy/tui-primitives.mjs`); reworded 4.1 to depend on 4.0; updated dependency map.
- **MAJOR (frontmatter parser):** Reworded 1.3 to specify the 3 shapes (scalar/nested-map/absent) + fixture round-trip; verified `startup-founder-primary-agent.md` (`task: allow` scalar), `explorer-subagent.md` (no `task`), `code-review`/`architecture-review` (nested maps).
- **MAJOR (no uninstall):** Added task 3.7 `--prune` + `.opencode-init.manifest.json` (3.2 now writes a manifest); added test 5.4(j).
- **MAJOR (built-in agents):** 3.3 now emits `agent.build`/`plan`/`explore`/`general` blocks.
- **Minor:** reordered 2.3/2.4 (presets before `--list presets`/`--expand`); added 2.5 `--expand` + 2.6 `modelAvailable`; added 5.5 registry-drift CI guard; added setup.ps1 `.cmd` shim guidance (Windows symlink privilege); updated sync rules coverage (setup.sh banner, opencode_app/README.md N/A) in 6.1; added 4 new risks; verified-correct claims noted (resolve-models flags, merge-packs pattern, frontmatter dep graph, react-nextjs-antipatterns-skill exists, agent-tiers shape, setup.sh ~/.local/bin pattern).
- Verified-correct (no change needed): resolve-models.mjs flags (`--agents-src/--agents-dest/--project-map/--config-src/--tiers/--default-map/--provider/--json/--dry-run`, lines 39-62); `merge-packs.mjs:87-103` deepMerge; dependency data in frontmatter; `agent-tiers.json` shape; `setup.sh:~2587` `~/.local/bin` pattern.

**(execution log — to be filled as phases complete)**

**2026-08-02 — Phase 0 COMPLETE.** Findings (override conflicting plan body text):
- **0.1 config path — DECISION: use `<project>/.opencode/opencode.json`** (NOT root). Empirically verified via `opencode debug config` (opencode 1.18.11): root `opencode.json` IS read (TEST 1: root-only → `ROOT-MARKER` resolved); `.opencode/opencode.json` IS ALSO read AND has HIGHER precedence (TEST 2: both present → `DOTOPENCODE-MARKER` wins; TEST 3: `subagent_depth:7` + custom model in `.opencode/opencode.json` both applied). → Reverts the review's BLOCKER #2 path change. `.opencode/opencode.json` is preferable: higher precedence, co-located with agents/skills/models.json under one `.opencode/` tree (cleaner prune/gitignore). **All plan references to `<project>/opencode.json` (root) are superseded — the writer targets `<project>/.opencode/opencode.json`.**
- **0.2 clean-slate signal — CONFIRMED.** `~/.config/opencode/agents/` (51 files on this machine) + `~/.config/opencode/skills/` (136 files) are the correct non-empty markers. Warning copy: "Global deploy detected (N agents, M skills in ~/.config/opencode/). Project install will be ADDITIVE — isolation requires a clean slate. See opencode config merge semantics." This machine has a global deploy → warning will fire.

**2026-08-02 — Phases 1–6 COMPLETE. All 276 bats tests pass (0 failures, 9 suites). Implementation log:**

- **Phase 1 (DONE):** Added `category:` frontmatter to all **38 agents + 125 skills** (note: actual skill count is 125, not 127 — the README's 125 is correct; `_archived`/`_common` excluded). Wrote `deploy/build-registry.mjs` (zero-dep, indentation-stack YAML parser handling all 3 verified shapes: scalar `task: allow`, nested maps `permission.task.*`, absent keys). `registry.json` emitted (38 agents, 125 skills). Fixture spot-checks correct: code-review (11 skills/8 delegates), architecture-review (8/2), explorer (0/0), startup-founder (2 skills/0 delegates via scalar task), tdd (2/0). `--check` drift guard verified (exit 1 on drift, 0 in-sync).
- **Phase 2 (DONE):** `deploy/init.mjs` skeleton + `--list {agents,skills,categories,mcps,presets}` + `--describe` (with `modelAvailable` check — splits `provider/model` to match `provider-models.json`; flags the PLAN-GIT-283 stale-tier class) + `--expand` (full transitive closure) + `--help`. `deploy/presets/pack-{core,review,frontend,backend,docs,devops,business,research,cad,integrations}.json` generated + validated against registry. `deploy/dependency-map.json` (skill→MCP `impliesMcp`).
- **Phase 3 (DONE):** Selection resolver (transitive `delegatesTo` closure excl. builtins; `requiresSkills` auto-include; `impliesMcp` derivation). Writer copies exact subset + writes `.opencode-init.manifest.json`. `opencode.json` generated at `.opencode/opencode.json` (Phase 0.1 decision) with scoped `permission.task` (`"*":"deny"` FIRST + reachable stems + explore/general), `permission.skill` allowlist, `agent.{build,plan,explore,general}` blocks, selected MCPs. **DEVIATION from plan 3.4:** model injection done INLINE in init.mjs (`injectModelLine`) rather than shelling to `resolve-models.mjs` — the resolver does src→dest bulk copy (would install all 38 agents); inline injection keeps the subset precise + writes `models.json` tier map. `--provider` honored via `provider-presets.json`. Slim `<project>/AGENTS.md` generated. Summary→stderr (keeps `--dry-run` stdout clean JSON). `--prune` removes only manifest-owned entries. **Caught + fixed a real opencode bug:** `$comment` is rejected by opencode's schema validator → removed from generated config.
- **Phase 4 (DONE):** Extracted `deploy/tui-primitives.mjs` (all primitives + flows exported; `tui.mjs` reduced to a thin dispatcher — verified it still works + primitives import without firing dispatch). Wired `init.mjs` interactive flow (project → preset → multi-select agents/skills/mcps with locked required-skills → provider → confirm). **Caught + fixed a real bug:** `tui-primitives`' `process.on("exit")` ANSI handler leaked `[?25h` to stdout, corrupting JSON read-mode output → guarded with a `_rawEntered` flag (only restores terminal if a select actually engaged raw mode).
- **Phase 5 (DONE):** `## Project-Scoped Install` routing section in `deploy/.AGENTS.md` (triggers + `--list`/`--describe`/`--expand` introspection loop + clean-slate caveat). `setup_opencode_init_symlink` in `setup.sh` + `Setup-OpencodeInitShim` in `setup.ps1` (Windows `.cmd` wrapper, avoids `mklink`). `opencode-init` on PATH verified from `/tmp`. README `## Project-Scoped Install` section (presets table + mutually-exclusive-with-global caveat). `tests/init.bats` (17 tests, all pass). CI drift guard added to `.github/workflows/release.yml` test job (`node deploy/build-registry.mjs --check`).
- **Phase 6 (DONE):** README Skill-Modularization note (registry-derived categories). `opencode_app/README.md` confirmed N/A (Docker = containerized global instance, not a project-scope target). **Scenario A (clean slate, isolated HOME):** `permission.skill` allows = **16** (isolated — NOT unioned); task = 10 scoped; isolation holds. **Scenario B (additive, real HOME with 51 global agents):** `permission.skill` allows = **82** (UNIONED with global — isolation does NOT hold, additive); task still scopes to 10. Both behaviors match the documented clean-slate caveat exactly.
- **Final gate:** `bash -n setup.sh` OK; `node --check` on all 6 .mjs OK; `opencode debug config` accepts generated config (exit 0); **276 bats passed / 0 failed** across 9 suites (no regressions from the tui.mjs refactor or the 165 `category:` frontmatter additions). `opencode-init` invokable from any cwd via PATH symlink.

**Deviations from plan (all recorded for traceability):**
1. Config path = `.opencode/opencode.json` (NOT root) — empirically verified higher precedence; reverts review BLOCKER #2.
2. Model injection inline (not via `resolve-models.mjs`) — resolver's bulk-copy would install all 38 agents; inline keeps the subset precise.
3. `--describe` `modelAvailable` matches `provider/model` split (provider-models.json keys are providers, lists are bare ids).
4. Removed `$comment` from generated `opencode.json` (opencode schema rejects it; note moved to generated AGENTS.md).
5. `tui-primitives` exit-handler guarded by `_rawEntered` (prevents ANSI leak corrupting JSON stdout).
6. Skill count is 125 (not 127) — README's 125 is the correct figure.
