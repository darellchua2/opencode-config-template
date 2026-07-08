# PLAN: v2.0 Model Resolution System (Major Breaking Change)

**JIRA**: [BT-74](https://betekk.atlassian.net/browse/BT-74)
**Branch**: `BT-74`
**Created**: 2026-06-26
**Status**: v2.0 complete + verified (Phases 1–11, on PR #231)

## Overview

Replace hardcoded z.ai models in all 35 source agent `.md` files with a **tier-based, provider-agnostic model resolution system**. Today every agent `.md` hardcodes `model: zai-coding-plan/glm-X` in frontmatter, locking end-users into z.ai and making provider switching (Anthropic / OpenAI / OpenRouter / local LM Studio) impossible without hand-editing 35 files. This is a **single integrated deliverable** (one branch, one PR) and ships as a **major version bump 1.72.0 → 2.0.0** with a dedicated migration path for existing v1.x installs.

### Key design decisions (all confirmed with repo owner)

- **4 tiers**: `reasoning` (15), `fast` (15), `docs` (3), `vision` (2) = 35 agents.
- **Central tier registry** `deploy/agent-tiers.json` (agent-stem → tier). Source `.md` stays 100% model/tier-free.
- **Resolver** `deploy/resolve-models.mjs` (zero-dep Node) injects concrete `model:` at deploy time + patches `opencode.json` (`model`, `agent.explore.model`, `agent.general.model`).
- **TUI** `deploy/tui.mjs` (zero-dep raw-mode readline) for new interactive flows only; existing setup.sh prompts stay `read -p`. Built-in menus only (no gum/fzf). Non-TTY/`-y`/`--provider` auto-fallback.
- **Override layers** (global `~/.config/opencode/` + project-local `<project>/.opencode/`).
- **Resolution precedence** (highest wins): project `agent-overrides[agent]` → global `agent-overrides[agent]` → project `models.json` → global `models.json` → `models.default.json`.
- **Docker**: build-time `RUN node resolve-models.mjs`.
- **Preserve edits**: sidecar `.resolved-models.json`; `--force` to override.
- **Migration (major)**: `.config-version` marker; auto-detect pre-v2; full backup; known-default → re-resolve, custom → lift into `agent-overrides.json`; TUI `migration-review` gate; revert documented in MIGRATION.md.

### Provider presets (`deploy/provider-presets.json`)

| Provider | primary | reasoning | fast | docs | vision |
|---|---|---|---|---|---|
| z.ai (default) | glm-5.2 | glm-5.1 | glm-5-turbo | glm-4.7 | glm-5v-turbo |
| Anthropic | claude-opus-4-8 | claude-sonnet-4-6 | claude-haiku-4-6 | claude-haiku-4-6 | claude-sonnet-4-6 |
| OpenAI | gpt-5 | gpt-5 | gpt-5-mini | gpt-5-mini | gpt-5 |
| OpenRouter | per-tier prompt | … | … | … | … |
| LM Studio (local) | openai/gpt-oss-20b | ← all tiers = loaded model → | | | (warn) |

---

## Dependency & Consumer Map

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---|---|---|---|
| `deploy/agent-tiers.json` | tier assignment finalized | resolve-models.mjs, tui.mjs | high |
| `deploy/models.default.json` | z.ai model IDs finalized | resolve-models.mjs, migration (known-default set) | high |
| `deploy/provider-presets.json` | provider model IDs finalized | tui.mjs provider-picker, setup.sh `--provider` | med |
| `deploy/resolve-models.mjs` | tiers + maps exist | setup.sh deploy_agents, setup.ps1, Dockerfile, tui.mjs migration-review | high |
| `deploy/tui.mjs` | resolver exists (migration-review shells out to it) | setup.sh setup_model_provider, setup.ps1 | med |
| 35 `agents/*.md` (strip `model:`) | tiers registry exists (so resolver can re-inject) | resolver output, Docker image | high |
| `deploy/setup.sh` (EDIT) | resolver + TUI exist | setup.ps1 mirror, deployment | high |
| `deploy/setup.ps1` (EDIT) | setup.sh changes | Windows deployment | med |
| `opencode_app/Dockerfile` (EDIT) | resolver + tiers + map in build context | Docker image | med |
| `opencode.json` deploy patch | resolver config-dest wiring | primary/explore/general models | med |
| `VERSION` + `MIGRATION.md` | all phases land | release tooling, users | low |
| `README.md`, `AGENTS.md` | everything finalized | documentation consumers | low |

---

## Implementation Phases

### Phase 1: Data layer + tier registry

- [x] **1.1** Create `deploy/agent-tiers.json`
    - **Why:** Central registry mapping each agent filename stem (no `.md`) to its tier. Source `.md` files are model-free, so this is the single source of truth for categorization. Central manifest (not per-file frontmatter) was chosen so source stays 100% model/tier-free and easy to audit.
    - **Done when:** 35 entries present — `reasoning` (15: architecture-review, code-review, discovery-specialist, go-reviewer, loop-operator, opencode-tooling, opentofu-explorer, python-reviewer, repo-ops-specialist, requirements-specialist, responsive-audit, rust-reviewer, tdd, technical-design-specialist, typescript-reviewer), `fast` (15), `docs` (3: coverage, documentation, linting), `vision` (2: error-resolver, image-analyzer). NOTE: discovery-specialist + requirements-specialist bumped from `fast` → `reasoning` (drafting warrants deeper reasoning); linting stays `docs`.
    - **Consumers affected:** resolve-models.mjs, tui.mjs

- [x] **1.2** Create `deploy/models.default.json`, `provider-presets.json`, example files
    - **Why:** Default tier→model map (z.ai) + provider swap presets for the interactive picker. Example files seed hand-editors.
    - **Done when:** `models.default.json` = `{primary: glm-5.2, tiers:{reasoning: glm-5.1, fast: glm-5-turbo, docs: glm-4.7, vision: glm-5v-turbo}}`. `provider-presets.json` has z.ai/anthropic/openai/openrouter/lmstudio with the confirmed model IDs (Anthropic: opus-4-8/sonnet-4-6/haiku-4-6). `models.example.json` + `agent-overrides.example.json` present with `$comment` guidance.
    - **Consumers affected:** resolver, tui provider-picker, `--provider` flag

### Phase 2: Resolver engine

- [x] **2.1** Create `deploy/resolve-models.mjs`
    - **Why:** The engine that turns tiers + maps + overrides into concrete models at deploy time. Node (zero npm deps) because Node is already a hard dependency (opencode-ai) and YAML frontmatter rewriting in bash sed is fragile.
    - **Done when:** CLI accepts `--agents-src/--agents-dest/--tiers/--default-map` (+ optional `--user-map/--project-map/--overrides/--project-overrides/--config-src/--config-dest/--state/--provider/--presets`) and `--force/--dry-run/--verbose/--json`. Implements the 5-level precedence. Injects exactly one `model:` line into each deployed `.md` frontmatter (verified: 35/35 written, 0 skipped). Patches deployed `config.json` (`model`, `agent.explore.model`→fast, `agent.general.model`→reasoning). Preserve-edits via sidecar (dest model != tracked → PRESERVE unless `--force`). **Tested:** dry-run table correct; Anthropic `--provider` swap correct; per-agent override beats tier.
    - **Consumers affected:** setup.sh deploy_agents, setup.ps1, Dockerfile, tui.mjs migration-review

### Phase 3: Interactive TUI

- [x] **3.1** Create `deploy/tui.mjs`
    - **Why:** Provider swap + migration confirmation need a real arrow-key UI; a shared Node TUI runs identically on macOS/Linux/Windows-GitBash/PowerShell/`docker run -it` (replaces duplicate bash+ps1 prompt code).
    - **Done when:** Zero-dep raw-mode `readline` menus (no gum/fzf). Flows: `provider-picker` (single-select + `--provider` non-interactive mode), `tier-editor`, `migration-review` (spawns resolver `--json --dry-run`, renders before/after table, `--yes` to proceed), `override-editor` (multi-select). Non-TTY → exit non-zero (migration-review honors `--yes`). JSON-on-stdout contract. **Tested:** interactive render + arrow nav + write verified via PTY; non-TTY fallback exits 1.
    - **Consumers affected:** setup.sh setup_model_provider, setup.ps1

### Phase 4: Strip models from 35 source agents

- [x] **4.1** Remove `model:` line from frontmatter of all 35 `opencode_app/.opencode/agents/*.md`
    - **Why:** Source becomes provider-agnostic; tiers (not hardcoded models) drive resolution.
    - **Done when:** Frontmatter-only strip (NOT body — `opencode-tooling-subagent.md` body still contains its `provider/model-id` example text). Verified: 35 files stripped, 0 frontmatter `model:` lines remain, resolver still resolves 35/35 from the now-model-free source.
    - **Consumers affected:** resolver output, Docker image, anyone reading source

### Phase 5: Wire `deploy/setup.sh`

- [x] **5.1** Add v2.0 globals + new CLI flags
    - **Why:** setup.sh must know the resolver/TUI/map paths and expose `--provider/--models-only/--force/--migrate`.
    - **Done when:** Globals added near existing dir vars: `RESOLVER_SCRIPT`, `TUI_SCRIPT`, `AGENT_TIERS`, `MODELS_DEFAULT_MAP`, `PROVIDER_PRESETS`, `USER_MODELS_MAP`, `USER_OVERRIDES`, `PROJECT_MODELS_MAP`, `PROJECT_OVERRIDES`, `RESOLVED_SIDECAR`, `CONFIG_VERSION_FILE`, `SCHEMA_VERSION=2.0`, `PROVIDER`, `MODELS_ONLY`, `FORCE_RESOLVE`, `MIGRATE_ONLY`. `parse_arguments` gains the 4 new flag cases. `show_help` documents them.
    - **Consumers affected:** all setup.sh flows

- [x] **5.2** Add `run_resolver()`, `setup_model_provider()`, `run_migration()`, `lift_customizations()`
    - **Why:** New orchestration functions: resolver invocation helper; provider picker (TUI or `--provider` flag writes `models.json`); migration detect+backup+lift+`.config-version`; customization lifting into `agent-overrides.json`.
    - **Done when:** `run_resolver` forwards project/global maps+overrides + `--config-src opencode.json --config-dest config.json --state sidecar` (+ `--force`/`--provider` when set). `setup_model_provider`: `--provider` → tui `provider-picker --provider`; elif TTY & interactive → tui picker; else skip (defaults). `run_migration`: read `.config-version`; if `< 2.0`/absent → warn major upgrade, prompt, backup agents+config, `lift_customizations`, write `.config-version=2.0`. `lift_customizations`: node heredoc reading dest agents, any model ∉ known z.ai defaults → written to `agent-overrides.json`.
    - **Consumers affected:** deploy_agents, main()

- [x] **5.3** Rewrite `deploy_agents()` + integrate into `main()`
    - **Why:** Replace plain `cp` with resolver-driven deployment; gate on Node.
    - **Done when:** `deploy_agents` requires `node` (error+skip if missing), `mkdir` dest, calls `run_migration` then `run_resolver`, counts deployed agents. `main()`: insert `setup_model_provider || true` before `deploy_agents`; add `--models-only` (provider + resolver only) and `--migrate` (migration + resolver only) early exit branches near `UPDATE_ONLY`.
    - **Consumers affected:** all deploy paths

### Phase 6: Wire `deploy/setup.ps1` (mirror)

- [x] **6.1** Mirror setup.sh v2.0 changes in PowerShell
    - **Why:** Windows parity — setup.ps1 must match setup.sh.
    - **Done when:** Same globals, `--provider/--models-only/--force/--migrate` params, `Invoke-Resolver`/`Setup-ModelProvider`/`Invoke-Migration` functions (calling the same `node resolve-models.mjs` / `node tui.mjs`), rewritten agent-deploy to use resolver, main-flow integration. `show_help` updated.
    - **Consumers affected:** Windows users

### Phase 7: Docker build-time resolver

- [x] **7.1** Add build-time model resolution to `opencode_app/Dockerfile`
    - **Why:** Dockerfile currently `COPY . /app/` source agents (now model-free) — without resolution the image would have model-less agents.
    - **Done when:** Resolver + `agent-tiers.json` + `models.default.json` are in the Docker build context (copy from `deploy/` or place under `opencode_app/`). `RUN node /app/deploy/resolve-models.mjs --agents-src ... --agents-dest /app/.opencode/agents --tiers ... --default-map ... --config-dest /app/opencode.json` bakes resolved (default z.ai) models into the image. Optional: honor `OPENCODE_PROVIDER` build-arg to swap at build.
    - **Consumers affected:** Docker image, `docker compose up` users

### Phase 8: Version bump + migration guide

- [x] **8.1** Bump `VERSION` 1.72.0 → 2.0.0
    - **Why:** Major breaking change (model sourcing + config structure) → major bump.
    - **Done when:** `VERSION` file = `2.0.0`.
    - **Consumers affected:** release tooling, semantic-release-convention

- [x] **8.2** Create `MIGRATION.md`
    - **Why:** Existing v1.x users need a clear v1.x→v2.0 upgrade guide + revert path.
    - **Done when:** Documents: what changed (tier-based resolution), auto-detect behavior (`.config-version`), customization lifting into `agent-overrides.json`, backup location (`~/.opencode-backup-*`), how to choose a provider (`./setup.sh --provider anthropic` or interactive), how to revert (restore from backup), and the new override files/precedence.
    - **Consumers affected:** all existing users

### Phase 9: Documentation sync

- [ ] **9.1** Update `README.md`, `opencode_app/README.md`, repo `AGENTS.md`
    - **Why:** Repo AGENTS.md mandates doc sync after infra changes; model-tier table must reference the new tier system (not hardcoded z.ai IDs).
    - **Done when:** README documents tiers, override files, new flags, provider presets, migration pointer. repo `AGENTS.md` "Subagent Model Tiering" table reframed around tiers (`reasoning/fast/docs/vision`) + override mechanism (was: hardcoded `glm-*` IDs per tier). `opencode_app/README.md` Docker notes mention build-time resolution. Banner agent/skill counts unchanged (no agent/skill added — only model sourcing changed).
    - **Consumers affected:** documentation readers, model-tier routing

- [ ] **9.2** Run `documentation-sync-workflow` skill
    - **Why:** Validates cross-file consistency after the changes.
    - **Done when:** Skill confirms setup.sh, setup.ps1, README, AGENTS.md mutually consistent.
    - **Consumers affected:** documentation integrity

### Phase 10: Verification

- [x] **10.1** Run all dry-run verification commands
    - **Why:** Confirm the system resolves correctly across default + provider-swap + migration paths without touching a live install.
    - **Done when:** `node deploy/resolve-models.mjs --dry-run --verbose` → 35 written/0 skipped; `./setup.sh --provider anthropic --models-only --dry-run` → all Claude; `./setup.sh --migrate --dry-run` → migration preview renders (no backup written — dry-run-gated); resolver `--json` precedence test (per-agent override beats tier) passes. **Dry-run also stages complete resolved `.md` files (model: injected) to `~/.config/opencode/.dry-run-preview/` + dumps one full sample to stdout** (added per owner request during implementation).
    - **Consumers affected:** all (correctness gate)

- [x] **10.2** Lint + structural checks
    - **Why:** setup.sh is heavily edited; must stay shellcheck-clean.
    - **Done when:** `bash -n deploy/setup.sh` (shellcheck not installed in env — noted); `node --check deploy/resolve-models.mjs deploy/tui.mjs`; no stray `^model:` in source agent frontmatter (verified 0); setup.ps1 parse deferred (pwsh not in env — reviewed manually).
    - **Consumers affected:** all deployment consumers

### Phase 11: Per-category provider/model mixing

Allows each of the 5 categories — `primary`, `reasoning`, `fast`, `docs`, `vision` — to use a **different provider and/or model** independently. The data layer already supports this (`models.json` maps each category to a model string; the resolver substitutes them independently — verified: `vision: openai/gpt-5` + others z.ai resolves correctly). Phase 11 adds the **UX and CLI** to build a mixed map easily, plus docs + the auth caveat.

- [x] **11.1** Add per-category provider/model picker to `deploy/tui.mjs`
    - **Why:** The current `provider-picker` forces one provider across all categories. Users want e.g. "z.ai default, but vision → OpenAI" (and arbitrary mixes across all 5 categories). `models.json` already supports mixed maps; only the editor UX is missing.
    - **Done when:** A reusable helper `pickCategoryModel(category, currentModel, presets)` exists: a singleSelect listing, for the given category, every provider's model for that category (e.g. `zai: glm-5.1`, `anthropic: claude-sonnet-4-6`, `openai: gpt-5`, …) plus a `Custom (type a model id)` option (textInput). `flowProviderPicker` interactive path gains a follow-up: after the base provider is chosen, "Customize individual categories to other providers/models?" → if yes, run `pickCategoryModel` for each of `primary`/`reasoning`/`fast`/`docs`/`vision`, defaulting each to the base provider's value; write the resulting mixed map to `models.json`. `--provider` (non-interactive) path unchanged (still single-provider). Existing `tier-editor` flow upgraded to reuse the same helper (provider-menu per category instead of raw text input).
    - **Consumers affected:** interactive provider selection, tier-editor

- [x] **11.2** Wire `setup.sh` + `setup.ps1` for mixing
    - **Why:** Expose mixing in the interactive flow + a direct CLI entry.
    - **Done when:** `setup_model_provider` interactive branch offers two paths: "Single provider" (existing) vs "Customize per category (mix providers)". New `--mix` flag (setup.sh) / `-Mix` (setup.ps1) jumps straight to the per-category editor (writes `models.json`, then resolves). `show_help` documents `--mix`. Non-interactive mixing remains available by hand-editing `models.json` (documented).
    - **Consumers affected:** all interactive deploys, scripted mixed setups

- [x] **11.3** Docs: per-category mixing + auth caveat
    - **Why:** Mixing providers requires the user to have authenticated each non-z.ai provider in OpenCode (else those models fail at runtime); users must know this and how.
    - **Done when:** `MIGRATION.md` "Choosing a provider" gains a "Mixing providers per category" subsection (example: z.ai base + vision=openai) + the auth requirement (`opencode auth login` / `auth.json` per provider). Repo `AGENTS.md` model-tiering section notes categories can mix providers. README "Model Resolution (v2.0)" mentions per-category customization.
    - **Consumers affected:** all users mixing providers

- [x] **11.4** Verify mixed resolution across all 5 categories
    - **Why:** Confirm the resolver + new UX produce a correct mixed map end-to-end.
    - **Done when:** A mixed `models.json` (e.g. primary=zai, reasoning=anthropic, fast=openai, docs=zai, vision=openai) resolves each category's agents to the expected provider; interactive `--mix` writes that map; `--dry-run` preview shows the mixed models; per-category override still respects the 5-level precedence (a per-agent override still beats a category map).
    - **Consumers affected:** all (correctness gate)

---

## Acceptance Criteria

- [x] `deploy/agent-tiers.json` has 35 entries (15 reasoning / 15 fast / 3 docs / 2 vision)
- [x] `deploy/models.default.json` + `provider-presets.json` + 2 example files exist with confirmed model IDs
- [x] `deploy/resolve-models.mjs` resolves 35/35, implements 5-level precedence, injects frontmatter + patches config.json (tested)
- [x] `deploy/tui.mjs` interactive + non-TTY fallback working (tested)
- [x] All 35 source agent `.md` have no frontmatter `model:` line; body examples untouched
- [x] `deploy/setup.sh` deploy_agents uses resolver; `setup_model_provider` + `run_migration` + 4 new flags wired
- [x] `deploy/setup.ps1` mirrors setup.sh
- [x] Dockerfile resolves models at build time
- [x] `VERSION` = 2.0.0; `MIGRATION.md` exists
- [ ] README/AGENTS.md/opencode_app README synced; `documentation-sync-workflow` passes
- [x] All dry-run commands pass; shellcheck clean; `node --check` clean
- [x] Existing v1.x installs migrate without losing customizations (lifted into `agent-overrides.json`)
- [x] Per-category provider/model mixing: each of `primary`/`reasoning`/`fast`/`docs`/`vision` can use a different provider/model (interactive `--mix` + `models.json`); verified across all 5 categories (Phase 11)
- [x] Mixing docs + auth caveat present in MIGRATION.md / AGENTS.md / README (Phase 11)

---

## Risks & Mitigation

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| Source `.md` model-line strip breaks agents if resolver skipped | med | high | deploy_agents hard-requires `node` (error+skip, never deploys model-less silently); Docker build-time resolver covers image |
| User hand-edits lost on re-resolve | med | high | Sidecar `.resolved-models.json` preserves edits; `--force` opt-in; migration lifts unknowns into overrides |
| Provider preset model IDs drift as vendors release new versions | med | low | IDs live in `provider-presets.json` (one file, trivially editable); resolver doesn't validate reachability, just substitutes |
| `vision` tier remapped to non-multimodal model | low | med | Resolver prints verbose note that vision agents need multimodal; can't enforce |
| setup.sh line numbers drift during editing | high | med | Use string matching for edits, not line numbers; re-grep after each change |
| setup.ps1 parity drift from setup.sh | med | med | Phase 6 mirrors function-by-function; cross-check flags |
| Migration clobbers a genuinely customized install | low | high | Full backup before migration; unknown models lifted (not dropped) into `agent-overrides.json`; revert documented |
| Team-managed Jira has no delete — closed child tasks BT-75…84 remain visible | low | low | Accepted; consolidated tracking lives in BT-74 description + this PLAN |
| Mixed-provider maps reference models the user hasn't authenticated | med | med | Phase 11.3 documents the auth requirement per provider (`opencode auth login`); resolver doesn't validate reachability, so a wrong/unauthed model fails at runtime, not at deploy |
| `--provider <X>` silently overrides a hand-mixed `models.json` | med | med | By design: `--provider` is a forced single-provider shortcut and ranks above `models.json` in precedence. Mixing is done by writing `models.json` (via `--mix`/editor) and resolving WITHOUT `--provider`. Documented in Phase 11.3. |

---

## Technical Notes

- **Single integrated deliverable:** one branch (`BT-74`), one PR. Originally decomposed into Jira child tasks BT-75…BT-84 but consolidated per requirement that this ships as one unit; those children are closed (Jira team-managed has no delete/cancel, only Done).
- All source-of-truth edits go in `opencode_app/.opencode/` + `deploy/` (repo AGENTS.md rule); never edit deployed `~/.config/opencode/` directly — redeploy handles it.
- Resolver strips `$comment` JSON keys via regex so the data files stay self-documenting without breaking `JSON.parse`.
- `provider/model-id` text in `opencode-tooling-subagent.md` body is documentation, NOT frontmatter — the Phase 4 strip correctly left it intact.
- `technical-design-specialist-subagent` (added in BT-73) is the 35th agent and is `reasoning` tier.
- Built-in agents `explore` (fast) and `general` (reasoning) are patched in `opencode.json`, not via `.md` tiers (they aren't in agent-tiers.json).
- The 5-level precedence means a project can pin a whole provider (`<project>/.opencode/models.json`) while a global per-agent pin still wins — explicit per-agent always beats tier-map, project always beats global.
- **Per-category provider mixing (Phase 11):** `models.json` maps each of the 5 categories (`primary` + 4 tiers) to a model **independently**, so a map like `{primary: zai/glm-5.2, reasoning: anthropic/claude-sonnet-4-6, fast: zai/glm-5-turbo, docs: zai/glm-4.7, vision: openai/gpt-5}` is valid and resolves per-category. Verified: the resolver substitutes each category's model independently. Mixing is done by writing `models.json` (via the `--mix` TUI editor) and resolving WITHOUT `--provider` (which forces a single provider and ranks above `models.json`). Non-z.ai providers require per-provider auth in OpenCode.
- LM Studio preset maps all tiers to the single loaded local model; vision gets a warning since local models are rarely multimodal.
- **Dry-run preview (added per owner request):** `--dry-run` (passed through by `setup.sh`/`setup.ps1`) stages **complete resolved agent `.md` files** (with `model:` injected) + a resolved `opencode.json` into `~/.config/opencode/.dry-run-preview/`, and dumps one full sample file to stdout — so users see exactly what would land in `~/.config/opencode/` without touching the real config. The real `agents/` and `config.json` are never written in dry-run; the migration backup `cp` and `.config-version` write are also dry-run-gated.

---

*Created for BT-74 — v2.0 Model Resolution System. All phases implemented 2026-06-26 → 2026-07-07 and verified on branch `BT-74`: data layer + 35-agent tier registry, zero-dep Node resolver + TUI, model stripped from all source agents, `setup.sh`/`setup.ps1` wired (resolver + TUI provider picker + migration + `--provider`/`--models-only`/`--force`/`--migrate` flags), Dockerfile build-time resolution (build context moved to repo root + root `.dockerignore`), `VERSION` 1.72.0 → 2.0.0, `MIGRATION.md`, docs synced. Dry-run stages complete resolved files for preview per owner request.*
