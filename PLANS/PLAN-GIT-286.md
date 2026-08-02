# PLAN-GIT-286: Project-scoped selective installer CLI + TUI (`opencode-init`)

**Issue**: https://github.com/darellchua2/opencode-config-template/issues/286
**Branch**: `feat/286-opencode-init-cli`
**Created**: 2026-08-02

## Problem

`setup.sh` deploys **all 38 agents + 127 skills globally** to `~/.config/opencode/` with no
selectivity for agents/skills (the existing pack system only toggles MCP servers). Not all users
want everything installed globally — many want a **curated subset** applied to a **specific target
project** (project-scoped, isolated), and want to **choose** what they install. The installer must
also be **invokable through the LLM**: the user asks the agent "install review agents here" and the
agent understands and runs the command.

OpenCode already natively loads project-level config from `<project>/.opencode/{agents,skills,opencode.json}`
(project overrides global), so no opencode changes are required — this is purely a new install tool
that writes to the target project's `.opencode/` instead of `~/.config/opencode/`.

## Solution

A new standalone CLI — `deploy/init.mjs` — that installs a curated subset of agents + skills into a
target project's `.opencode/` directory, driven by an interactive TUI for humans AND flag-based
non-interactive invocation for the LLM/CI. The existing global `setup.sh` stays untouched (plus one
additive symlink line). The **flag-based path is the PRIMARY contract** (LLM-driven); the TUI is
secondary (human in a real terminal). Both share one core (registry → presets → resolver → writer);
only the input layer differs.

```
end user (in an opencode session) → "install review agents here"
   │  LLM reads routing rule in deployed AGENTS.md, introspects, runs
   ▼
opencode-init --project . --preset review --yes
   │  init.mjs reads registry.json → expands preset → resolves deps → writes
   ▼
<project>/.opencode/{opencode.json, models.json, agents/*.md, skills/*/, AGENTS.md}
```

### Locked design decisions (from planning session)

1. **CLI shape** — New standalone `deploy/init.mjs`; `setup.sh` global deploy untouched (+1 additive symlink line).
2. **Selection UX** — Presets + manual multi-select (TUI); flags + `--list` (LLM/CI).
3. **Target opencode.json** — Generate minimal project json with a scoped `permission.task` allowlist.
4. **Distribution** — Run from this repo; the LLM invokes the CLI via `opencode-init` symlinked onto PATH.
5. **Category source** — Add `category:` frontmatter to all agents + skills (single source of truth; also feeds the README category table, eliminating sync drift).
6. **Project AGENTS.md** — Generate a slim derived AGENTS.md (only routing rules relevant to the selected agents/skills).
7. **Task perms** — Scoped allowlist of selected subagent stems in `agent.build.permission.task`.
8. **`--yes` semantics** — Auto-resolve all `requiresSkills` AND all transitive `delegatesTo` subagents, with the default model tier — zero prompts.

### Key enablers (already exist in the repo — low risk)

- **TUI primitives** in `deploy/tui.mjs`: `singleSelect`, `multiSelect`, `textInput`, `confirm` (zero-dependency, cross-platform) — reused directly.
- **Pack + deep-merge pattern** (`deploy/packs/` + `deploy/merge-packs.mjs`) — same pattern extends to agent/skill selection.
- **Dependency data is already in frontmatter** — every agent's `permission.task.*` (subagents it spawns) and `permission.skill.*` (skills it needs) IS the dependency graph; no manual mapping required.
- **Model resolution** already supports project scope via `deploy/resolve-models.mjs --project-map` / `--agents-dest`.

---

## Dependency & Consumer Map

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
| ------------------ | ------------------------- | ------------------------------- | ----------- |
| `category:` frontmatter on all agents + skills | — | `build-registry.mjs`, README category table | low (1 line each, additive) |
| `deploy/build-registry.mjs` (NEW) | frontmatter categories | `init.mjs` (--list, TUI, resolver) | med (frontmatter parsing correctness) |
| `deploy/registry.json` (generated) | build-registry.mjs | init.mjs (all modes); README regen | low (committed artifact) |
| `deploy/presets/*.json` (NEW) | registry.json | init.mjs preset expansion | low (data) |
| `deploy/dependency-map.json` (NEW) | — | init.mjs `impliesMcp` + non-frontmatter deps | low (data) |
| `deploy/init.mjs` (NEW) | registry, presets, dep-map, resolve-models.mjs | LLM (via AGENTS.md routing); human TUI | high (core new tool) |
| `deploy/.AGENTS.md` (edit: new routing section) | init.mjs exists | deployed `~/.config/opencode/AGENTS.md` → LLM routing | low (docs) |
| `deploy/setup.sh` / `setup.ps1` (edit: 1 symlink line) | init.mjs exists | `opencode-init` on PATH | low (additive) |
| `README.md` (edit) | registry categories | users, docs sync | low |
| `tests/init.bats` (NEW) | init.mjs | CI | med (test coverage) |

---

## Implementation Phases

### Phase 1: Foundation — frontmatter categories + registry generator

- [ ] **1.1** Add a `category:` field to the YAML frontmatter of every agent file in `opencode_app/.opencode/agents/*.md` (38 files). Derive the category from the README's existing agent groupings: review (code-review + architecture-review + 5 language reviewers), frontend (nextjs-specialist, uiux-reviewer, responsive-audit), backend (none currently — skip or tag N/A), docs (documentation, coverage, docx, pptx, xlsx), devops (repo-ops, opentofu-explorer), business (startup-founder, startup-ceo, discovery, requirements, office-document), research (autoresearch-{ml,code,research}, loop-operator, technical-design), cad (cad-specialist), integrations (google-mcp, microsoft-m365), meta (opencode-tooling, explorer, error-resolver, image-analyzer, testing, linting, tdd, pr-workflow). One line per file; place after `description:`.
    — **Why:** `category:` becomes the single source of truth for grouping in the TUI + `--list` output AND the README category table (kills the sync-drift problem `AGENTS.md` "Sync Rules" warns about).
    — **Done when:** Every agent `.md` has a non-empty `category:` key in frontmatter; values come from a fixed taxonomy; no two agents use inconsistent casing/spelling of the same category.
    — **Consumers affected:** build-registry.mjs, README category table.

- [ ] **1.2** Add a `category:` field to the YAML frontmatter of every `SKILL.md` in `opencode_app/.opencode/skills/*/SKILL.md` (127 files), using the README's existing 21 skill categories as the fixed taxonomy (Framework, Presentation, Office Utilities, Language-Specific, Framework-Specific, OpenCode Meta, OpenTofu, Git/Workflow, Documentation, Academic & Research Writing, JIRA, Code Quality, Agent Optimization, Autoresearch, Startup/Business, Configuration, Security, DevOps, Planning & Alignment, Responsive & Visual Testing, CAD & Hardware Design). One line per file; place after `metadata:` block.
    — **Why:** Same single-source-of-truth rationale as 1.1; lets the TUI group 127 skills into scannable buckets and lets `--list skills --category <x>` filter precisely.
    — **Done when:** Every `SKILL.md` has a `category:` key whose value matches one of the 21 canonical categories; `grep -L "^category:" opencode_app/.opencode/skills/*/SKILL.md` returns nothing.
    — **Consumers affected:** build-registry.mjs, README category table.

- [ ] **1.3** Create `deploy/build-registry.mjs` (ESM, zero-dependency, mirrors `merge-packs.mjs`/`resolve-models.mjs` conventions). It walks `opencode_app/.opencode/agents/*.md` and `opencode_app/.opencode/skills/*/SKILL.md`, parses YAML frontmatter (minimal hand-rolled parser tolerating the existing `permission:` nested blocks — no `js-yaml` dependency), and emits `deploy/registry.json` with this shape: agent entries `{stem, description, mode, tier (from agent-tiers.json), category, requiresSkills[], delegatesTo[], requiredBy[]}` and skill entries `{name, description, category, audience, workflow, requiredByAgents[]}`. `requiresSkills` = keys under `permission.skill`; `delegatesTo` = keys under `permission.task` excluding `*`; `requiredBy`/`requiredByAgents` = computed reverse edges. Tolerate agents/skills with no `category:` (emit `category: "uncategorized"` + warn on stderr) so the generator never hard-fails on legacy data.
    — **Why:** The registry is the single data source the TUI and `--list` read at runtime; generating (not hand-maintaining) avoids drift and keeps TUI startup instant.
    — **Done when:** `node deploy/build-registry.mjs` writes `deploy/registry.json`; `jq '.agents | length' registry.json` = 38; `jq '.skills | length'` = 127; every agent entry has non-empty `requiresSkills` or `delegatesTo` populated from its real frontmatter; spot-check `code-review-subagent` shows its 11 skills + 5 language-reviewer delegates.
    — **Consumers affected:** init.mjs (all modes).

- [ ] **1.4** Run the generator and commit `deploy/registry.json`. Add `deploy/registry.json` to the repo (NOT gitignored — it's a committed artifact others rely on). Document the regen command (`node deploy/build-registry.mjs`) in a top-of-file `$comment` in registry.json.
    — **Why:** A committed, version-pinned registry means the TUI/LLM see consistent data without each user regenerating; the `$comment` prevents "where did this come from" confusion.
    — **Done when:** `registry.json` committed; `git diff --stat` shows it as a new tracked file; the `$comment` names the generator + regen command.
    — **Consumers affected:** all downstream phases.

### Phase 2: `--list` introspection + presets (LLM-usable, pure-read)

- [ ] **2.1** Create `deploy/init.mjs` skeleton (ESM, zero-dependency, mirrors `tui.mjs` arg-parsing/camelCase conventions). Implement arg parsing for all flags (`--project`, `--preset`, `--agents`, `--skills`, `--mcps`, `--provider`, `--yes`, `--dry-run`, `--list`, `--describe`, `--category`, `--help`) and a dispatch that, for now, only handles `--list` + `--describe` + `--help` (writer/TUI come in later phases). Resolve the source tree (repo root) via `import.meta.url` so cwd is irrelevant.
    — **Why:** Establishes the CLI contract and the LLM's primary introspection surface before any write logic; `--list`/`--describe` are pure reads, safe to ship first.
    — **Done when:** `node deploy/init.mjs --help` prints usage; `--list presets/agents/skills/categories` and `--describe <name>` work and exit 0; unknown flags exit non-zero with a clear error.
    — **Consumers affected:** LLM introspection loop.

- [ ] **2.2** Implement `--list` subcommands emitting JSON to stdout: `--list presets` (after 2.3), `--list agents` (array of `{stem, description, category, tier}`), `--list agents --category review` (filtered), `--list skills` (array of `{name, description, category}`), `--list skills --category code-quality` (filtered), `--list categories` (sorted unique category list with counts). All read from `registry.json`. JSON is the LLM-friendly format (machine-parseable); a `--human` flag may add a table later but JSON is the default.
    — **Why:** The LLM can't read a TUI — it needs structured output to decide what to install. JSON is the contract.
    — **Done when:** Each `--list` variant prints valid JSON; `--category` filters correctly; `jq` parses every output; empty-filter results print `[]` not an error.
    — **Consumers affected:** LLM decision loop, TUI category display.

- [ ] **2.3** Create `deploy/presets/*.json` — one file per preset (`core`, `review`, `frontend`, `backend`, `docs`, `devops`, `business`, `research`, `cad`, `integrations`). Each preset file: `{ "name", "description", "agents": [...stems], "skills": [...names], "mcps": [...server keys] }`. Derive contents from the README's category/agent tables (e.g. `review` = code-review + architecture-review + 5 language reviewers + 8 code-quality skills; `core` = explorer + general task-perms + git-semantic-commits skill; `integrations` = microsoft-m365 + google-mcp agents + m365/google/markitdown config skills + the relevant MCP servers). Validate at load time that every listed agent/skill exists in `registry.json` (fail loud on a stale preset).
    — **Why:** Presets are the fast-path UX — one flag installs a coherent bundle; they also seed the TUI's pre-checked multi-select.
    — **Done when:** 10 preset files exist; each validates against the registry (no orphan references); `--list presets` prints all 10 with their member counts.
    — **Consumers affected:** init.mjs preset expansion, TUI.

- [ ] **2.4** Implement `--describe <name>`: given an agent stem or skill name, print a JSON object with the full registry entry (description, category, tier, requiresSkills, delegatesTo, requiredBy) — everything the LLM needs to decide whether to install it and what it pulls in transitively.
    — **Why:** Closes the LLM's "what does this thing need?" loop before it commits to `--agents X --yes`.
    — **Done when:** `--describe code-review-subagent` prints its 11 skills + 5 delegates + reverse edges; unknown name exits non-zero with "not found, try --list".
    — **Consumers affected:** LLM decision loop.

- [ ] **2.5** Create `deploy/dependency-map.json` with an `impliesMcp` map (skill name → MCP server key) for skills that imply an MCP server: `nextjs-devtools-mcp-skill` → `next-devtools`, `markitdown-mcp-skill` → `markitdown`, `microsoft-m365-config-skill` → the 9 microsoft-* servers, `codegraph-setup-skill` → `codegraph`. Add a `$comment` documenting that frontmatter (`permission.skill`/`permission.task`) remains the primary dep source; this map only covers the skill→MCP edge that frontmatter can't express.
    — **Why:** MCP selection should auto-derive from chosen skills so the user/LLM doesn't have to specify MCPs manually when a skill needs one.
    — **Done when:** JSON valid; every value matches a real MCP key in `opencode_app/opencode.json`; init.mjs loads it (used in Phase 3).
    — **Consumers affected:** init.mjs MCP derivation (Phase 3).

### Phase 3: Resolver + writer (the install — `--agents X --yes` end-to-end)

- [ ] **3.1** Implement the **selection resolver** in `init.mjs`: given `--agents`/`--skills`/`--mcps`/`--preset` inputs, compute the final install set. Algorithm: (a) expand presets into their agent/skill/mcp lists; (b) union with explicit `--agents`/`--skills`/`--mcps`; (c) for each final agent, union its `requiresSkills` (silent auto-include — they're required); (d) walk each agent's `delegatesTo` excluding built-ins `explore`/`general` (always available) → with `--yes` auto-include those subagents (and recurse); without `--yes` defer to the TUI prompt (Phase 4); (e) derive MCPs from chosen skills via `dependency-map.json` `impliesMcp`, union with explicit `--mcps`; (f) compute reverse `requiredBy` warnings for any agent/skill the user tried to remove that another selected item needs. Emit a resolved-set object `{agents:[], skills:[], mcps:[], warnings:[]}`.
    — **Why:** This is the brain that turns "I picked code-review" into "install code-review + its 11 skills + its 5 reviewer delegates + codegraph MCP" — the value-add over a dumb copy.
    — **Done when:** Resolving `--agents code-review-subagent --yes` yields code-review + 5 language reviewers + image-analyzer (its delegate) + the union of all their skills + codegraph MCP; unit-testable as a pure function (no I/O).
    — **Consumers affected:** writer (3.2), TUI (Phase 4).

- [ ] **3.2** Implement the **writer**: copy selected agent files from `opencode_app/.opencode/agents/<stem>.md` → `<project>/.opencode/agents/`, and selected skill dirs `opencode_app/.opencode/skills/<name>/` → `<project>/.opencode/skills/`. Create the target `.opencode/` tree if missing. Never overwrite an existing different file without `--force` (diff-check; on conflict, warn + skip unless `--force`). Respect `--dry-run` (print the full file manifest instead of writing).
    — **Why:** This is the actual install; the conflict-guard prevents clobbering a user's hand-edited project agents.
    — **Done when:** `--agents explorer-subagent --dry-run` lists exactly `agents/explorer-subagent.md` (+ its zero skills); without `--dry-run` the file appears under `<project>/.opencode/agents/`; re-running is idempotent; a pre-existing differing file is skipped with a warning unless `--force`.
    — **Consumers affected:** the target project's `.opencode/`.

- [ ] **3.3** Implement **minimal `opencode.json` generation** at `<project>/.opencode/opencode.json`: include `$schema`, `subagent_depth: 3`, `instructions: ["AGENTS.md"]`, `permission.skill: {"*":"deny", "<each selected skill>":"allow"}` (scoped allowlist — only chosen skills visible to primary), `agent.build.permission.task` = scoped allowlist of selected subagent stems + `explore` + `general` (NOT wildcard — decision 7), `agent.explore` + `agent.general` blocks (copied from the repo's `opencode.json` since nearly every subagent delegates to them), `mcp` = only selected servers each with `enabled:true`, `tools` = corresponding `"<ns>*": true` entries. If the project already has an `opencode.json`, refuse + point the user at it (do NOT auto-merge — decision 3 was "generate fresh"); offer `--force` to overwrite.
    — **Why:** The generated config is what makes the installed subset actually work — scoped skill visibility + scoped task perms mean the primary can only spawn/see what was chosen.
    — **Done when:** Generated JSON validates against the opencode schema (parse + key sanity); `permission.skill` contains exactly the selected skills + the deny default; `agent.build.permission.task` contains exactly the selected subagent stems + built-ins; only selected MCPs appear; `--dry-run` prints the would-be JSON.
    — **Consumers affected:** the target project's opencode session.

- [ ] **3.4** Wire **model resolution** for the project-scoped agents: invoke `deploy/resolve-models.mjs` with `--agents-src <repo agents> --agents-dest <project agents> --tiers agent-tiers.json --default-map models.default.json --project-map <project>/.opencode/models.json --config-src <repo opencode.json>` so each copied agent `.md` gets its `model:` frontmatter injected per its tier, and `<project>/.opencode/models.json` is written (tier→model map for the selected agents only). Honor `--provider`/`--mix` by delegating to the existing `flowProviderPicker` to choose the map first.
    — **Why:** Project-scoped agents still need concrete models; the resolver already supports `--project-map`/`--agents-dest` — reuse it, don't reinvent.
    — **Done when:** After install, each `<project>/.opencode/agents/*.md` has a `model:` line; `<project>/.opencode/models.json` exists with only the tiers used by the selected agents; `--provider anthropic` swaps the map before resolving.
    — **Consumers affected:** the target project's agent spawning.

- [ ] **3.5** Implement **slim project `AGENTS.md` generation** (decision 6): derive a project-level `<project>/AGENTS.md` containing only the routing rules + MCP/tool notes relevant to the selected agents/skills (extract the relevant fragments from the repo's `AGENTS.md`/`deploy/.AGENTS.md` — e.g. if `image-analyzer-subagent` selected, include the vision-delegation rule; if codegraph MCP selected, include the codegraph-routing rule; always include the Task Delegation Order preamble trimmed to the selected subagents). Keep it under ~2KB. Skip sections whose referenced agents/skills aren't selected.
    — **Why:** The primary session in the target project needs routing guidance to actually USE the installed subset correctly, without the full 7KB global file's irrelevant rules.
    — **Done when:** Generated AGENTS.md references only selected agents/skills/MCPs; is valid Markdown; `--dry-run` shows it; re-running with a different selection regenerates it.
    — **Consumers affected:** the target project's primary agent behavior.

- [ ] **3.6** Add a **summary + confirm** step before writing (non-`--yes` path): print a table (agents / skills / MCPs to install, deps auto-pulled, files to write, MCPs implied) and `confirm()` before proceeding. With `--yes`, skip the prompt and write directly (decision 8).
    — **Why:** A human running the CLI without `--yes` should see exactly what lands before it does; `--yes` is the LLM/CI fast path.
    — **Done when:** Non-`--yes` run prints the table + prompts; `--yes` run writes immediately; both honor `--dry-run` (table only, no write).
    — **Consumers affected:** UX safety.

### Phase 4: Interactive TUI flows (human-in-terminal path)

- [ ] **4.1** Implement the interactive flow in `init.mjs` (reusing `deploy/tui.mjs` primitives via dynamic import or refactor into a shared module — prefer importing `tui.mjs`'s `singleSelect`/`multiSelect`/`textInput`/`confirm` without duplicating). Flow: (1) `textInput` target project (default cwd); (2) `singleSelect` choose-a-preset-or-skip; (3) if preset, `confirm` its expansion; (4) `multiSelect` adjust agents (preset agents pre-checked); (5) `multiSelect` adjust skills (required skills locked as checked + disabled-toggle — render with a lock marker); (6) `multiSelect` adjust MCPs (auto-derived ones pre-checked); (7) delegate to `flowProviderPicker` for per-tier model selection; (8) summary table + `confirm`; (9) write. Non-TTY → exit non-zero with "re-run with flags" message (same contract as existing tui.mjs flows).
    — **Why:** The TUI is the secondary path for humans who prefer arrow keys; it must reuse the proven primitives rather than reinvent raw-mode handling.
    — **Done when:** Running `node deploy/init.mjs` with no flags in a real TTY walks all 9 steps; arrow keys / space / enter behave as in `tui.mjs`; required skills cannot be unchecked; Esc at any step cancels cleanly (terminal restored); non-TTY exits non-zero with a clear message.
    — **Consumers affected:** human users.

- [ ] **4.2** Implement the **transitive-subagent prompt** (the non-`--yes` branch of resolver step 3.1d): after the user adjusts agents, for each selected agent's `delegatesTo` (excluding built-ins), if the delegate isn't already selected, `confirm("X can spawn Y — include Y?")`; on yes, add Y (and recurse its delegates). This is the human counterpart to `--yes`'s silent auto-include.
    — **Why:** Without this, a human who picks code-review but declines the language reviewers gets a broken delegation chain silently; the prompt makes the dependency explicit.
    — **Done when:** Selecting code-review in the TUI prompts to include each of its 5 reviewer delegates; accepting one prompts for ITS delegates; declining leaves it unselected with no crash.
    — **Consumers affected:** human users.

### Phase 5: LLM discoverability + setup wiring + docs + tests

- [ ] **5.1** Add a `## Project-Scoped Install` routing section to `deploy/.AGENTS.md` (deploys to `~/.config/opencode/AGENTS.md`, so the LLM knows the command in ANY project). Document: trigger phrases ("install subagents here", "set up agents for this repo", "add review agents", "project-level opencode config", "apply agents to this project"); the `opencode-init` command; the introspection pattern (`--list categories` → `--list agents --category X` → `--describe <name>` → `--agents <stems> --yes`); the guidance "prefer presets; fall back to `--agents` for specifics; use `--describe` to see what a choice pulls in transitively". Mirror the style of the existing `## Task Delegation Order` / `## Branch Workflow Setup Signal` sections.
    — **Why:** This is the entry point that makes "ask the LLM to run it" actually work — without it the LLM doesn't know the command exists.
    — **Done when:** Section present in `deploy/.AGENTS.md`; covers triggers + command + introspection loop + preset-first guidance; consistent with sibling routing sections.
    — **Consumers affected:** the primary LLM session in every target project.

- [ ] **5.2** Add one additive symlink line to `deploy/setup.sh` (and mirror in `deploy/setup.ps1`): after the global deploy, symlink `<repo>/deploy/init.mjs` → `~/.local/bin/opencode-init` (Windows: create a wrapper). `setup.sh` already manages `~/.local/bin` for markitdown (~line 2587), so reuse that PATH-check pattern. Make it idempotent (skip if the symlink already points correctly; refresh if stale). Do NOT change any existing setup.sh behavior — purely additive.
    — **Why:** Puts `opencode-init` on PATH so the LLM (and humans) can call it from any directory; the CLI resolves its own source tree via `import.meta.url` so cwd doesn't matter.
    — **Done when:** After `./deploy/setup.sh`, `command -v opencode-init` resolves; `opencode-init --list categories` works from `/tmp`; re-running setup.sh doesn't error on the existing symlink.
    — **Consumers affected:** every system that runs global deploy.

- [ ] **5.3** Update `README.md`: add a `## Project-Scoped Install` section documenting the CLI (usage, presets table, the LLM-invocation model, `--list` introspection, `--dry-run`), and note that the global `setup.sh` deploy and the project-scoped `opencode-init` are complementary (global = personal defaults; project = isolated per-repo subset). Cross-link issue #286.
    — **Why:** Users need to discover the new install mode alongside the existing global deploy docs.
    — **Done when:** Section exists with a presets table + examples; clearly states the two modes are complementary; links the issue.
    — **Consumers affected:** users reading the README.

- [ ] **5.4** Create `tests/init.bats` (the repo already uses bats-core under `tests/lib/`): cover (a) `--list` variants produce valid JSON + correct counts; (b) `--describe` of a known agent returns its skills/delegates; (c) preset expansion resolves to the expected agent/skill set; (d) resolver `--agents code-review-subagent --yes` auto-pulls the 5 language reviewers + image-analyzer + the union of skills + codegraph MCP; (e) `--dry-run` writes nothing and prints the manifest; (f) non-TTY with no selection flags exits non-zero; (g) generated `opencode.json` has a scoped `permission.skill` allowlist matching the selection + scoped `agent.build.permission.task`; (h) re-running is idempotent; (i) conflict-on-existing-file is skipped without `--force`. Prefer testing via the flag path (deterministic) over the TUI.
    — **Why:** The flag path is the primary contract and deterministic; bats gives CI a real gate (per the AGENTS.md "Verification & Quality Gates" rule — CLI is the source of truth).
    — **Done when:** `bats tests/init.bats` passes all cases in CI; cases run without a TTY.
    — **Consumers affected:** CI, future maintainers.

### Phase 6: Docs sync + verification

- [ ] **6.1** Invoke the `documentation-sync-workflow-skill` (or delegate to `opencode-tooling-subagent`) to sync: README skill/agent counts, the category tables (now derivable from frontmatter via `build-registry.mjs` — add a note that the README table is regenerated from the registry), and any deploy-script banners that mention counts. Confirm the new `category:` frontmatter is the single source feeding both the registry and the README.
    — **Why:** Per `AGENTS.md` "Adding Skills or Subagents — Sync Rules", counts/listings must stay consistent; this phase makes the new frontmatter field earn its keep by becoming the README's source too.
    — **Done when:** README category table matches `registry.json` categories exactly; no stale counts; a one-line note states the table is registry-derived.
    — **Consumers affected:** docs consistency.

- [ ] **6.2** End-to-end verification: in a scratch temp project, run `opencode-init --project /tmp/oc-test --preset review --provider zai --yes`, then validate (a) `/tmp/oc-test/.opencode/agents/` contains exactly the review-preset agents + auto-pulled delegates; (b) `/tmp/oc-test/.opencode/skills/` contains exactly the required skills; (c) `/tmp/oc-test/.opencode/opencode.json` has the scoped allowlists + codegraph MCP; (d) `/tmp/oc-test/.opencode/models.json` + each agent's `model:` frontmatter resolve to real selectable models; (e) `/tmp/oc-test/AGENTS.md` is slim + references only review agents. Clean up the scratch dir.
    — **Why:** Proves the whole pipeline (preset → resolve → write → models → AGENTS.md) works end-to-end before merge.
    — **Done when:** All five checks pass on the scratch project; scratch dir removed.
    — **Consumers affected:** none (verification).

---

## Risks & Mitigation

- **Frontmatter churn (165 one-line edits)** → mechanical, additive, low-risk; a single grep verifies completeness; if an agent/skill lacks `category:`, the registry generator warns (doesn't fail).
- **Hand-rolled YAML parser fragility** (avoiding a `js-yaml` dependency to match the zero-dep convention) → the parser only needs to read flat keys + the known `permission.skill`/`permission.task` nested maps; unit-test against all 38 agent files as fixtures in Phase 1.3.
- **Transitive-dependency explosion** (`--yes` pulling a large closure) → `--describe` + the summary table (3.6) surface the closure before install; `--dry-run` is the default on first run; `core` preset stays minimal.
- **Conflicting existing project agents** → writer skips-with-warning unless `--force` (3.2); generated `opencode.json` refuses to overwrite an existing one without `--force` (3.3).
- **`setup.sh` scope creep** → only ONE additive symlink line (5.2); no behavior change to global deploy; if the user rejects even that, document a manual alias as fallback.
- **Registry staleness** → `registry.json` is committed + regenerated via `build-registry.mjs`; add the regen to the existing pre-commit/CI check for agent/skill changes (or document it as a manual step).
- **Built-in agent `model:` keys differ from file agents** → built-ins (`build`/`plan`/`explore`/`general`) live in `opencode.json` `agent:` block, not files; the generator skips them and the writer copies their blocks from the repo `opencode.json` into the generated project config (3.3).

## Success Metrics

- `opencode-init --list categories` works from any cwd after global deploy (symlink on PATH).
- `opencode-init --project <scratch> --preset review --yes` produces a fully-functional isolated `.opencode/` with scoped skill/task permissions and resolved models.
- `--describe` + `--list` give the LLM enough to choose + install a subset without human lookup of names.
- Re-running the same install is idempotent; conflicting files are guarded.
- README category table is registry-derived (no more hand-maintained counts).
- `tests/init.bats` passes in CI.

## Dependencies

- Node.js v20+ (already required by the repo's other `.mjs` tooling).
- `gh` for issue linkage (already used).
- Existing `deploy/resolve-models.mjs`, `deploy/tui.mjs`, `deploy/merge-packs.mjs` (reused, not modified).

## Open confirmations

- None remaining — all 8 design decisions locked in the planning session.

---

## Revision Log

**(empty — to be filled during execution)**
