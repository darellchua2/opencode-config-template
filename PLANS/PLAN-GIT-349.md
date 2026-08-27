# PLAN-GIT-349 — Vision tier → zai-coding-plan/glm-5.3-flash (native models.dev)

**Issue:** https://github.com/darellchua2/opencode-config-template/issues/349
**Branch:** feat/GIT-349 (from origin/main @ 16c8cb3)
**Worktree:** /home/silentx/VSCODE/worktrees/GIT-349

## Overview

models.dev now natively registers `glm-5.3-flash` under `zai-coding-plan` (verified live 2026-08-27: 1M ctx, input text/image/video/pdf, tool_call). Switch the `vision` tier from custom-registered `zai-coding-plan/glm-5v-turbo` (128k on `zai` provider semantics) to native `zai-coding-plan/glm-5.3-flash`, and delete the custom `provider.zai-coding-plan.models` block so no picker entry shows "(custom)".

## Dependency & Consumer Map

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---------------------|---------------------------|---------------------------------|-------------|
| `deploy/models.default.json` | — | resolve-models.mjs (deploy-time tier resolution), setup.sh | low |
| `opencode_app/opencode.json` (provider block removal) | — | OpenCode runtime model picker, Docker build | med — picker entries change |
| `deploy/provider-models.json` | models.default.json swap | resolve-models.mjs --provider-models fail-fast guard | low |
| `deploy/agent-tiers.json` ($comment) | — | docs only | low |
| `AGENTS.md` / `README.md` | — | humans, doc-consistency tests | low |
| `image-analyzer-subagent.md` / `error-resolver-subagent.md` (prose + description) | models.default.json swap | deploy/registry.json, build-registry.mjs | med — registry regen required |
| `deploy/registry.json` | agent .md description edits | build-registry.mjs --check gate | low |

## Implementation Phases

### Phase 1: Tier + provider config swap

- [x] **1.1** `deploy/models.default.json`: `tiers.vision` → `"zai-coding-plan/glm-5.3-flash"`
    — **Why:** single source of truth for tier resolution; every deploy derives vision pins from here
    — **Done when:** `jq -r '.tiers.vision' deploy/models.default.json` prints the new value
    — **Consumers affected:** resolve-models.mjs, all vision-tier agents at deploy time
- [x] **1.2** `opencode_app/opencode.json`: remove the entire `provider.zai-coding-plan.models` block (both `glm-5v-turbo` and `glm-5.3-flash` custom entries, plus the now-empty `models` key)
    — **Why:** models.dev now serves `glm-5.3-flash` natively under `zai-coding-plan`; nothing pins `glm-5v-turbo` after the swap — custom registration is dead weight and the source of "(custom)" picker labels
    — **Done when:** `jq '.provider["zai-coding-plan"]' opencode_app/opencode.json` is null or has no `models` key; `node --check`-style JSON parse passes
    — **Consumers affected:** OpenCode runtime picker, Docker standalone build
- [x] **1.3** `deploy/provider-models.json`: remove `"glm-5v-turbo"` from the `zai-coding-plan` array (keep `glm-5.3-flash`); rewrite the `$comment` EXCEPTIONS sentence: `glm-5.3-flash` natively mapped by models.dev under `zai-coding-plan` (verified 2026-08-27, no custom registration); `glm-5v-turbo` remains listed only under `zai` (pay-as-you-go escape hatch)
    — **Why:** this array is the fail-fast guard input; it must track what the provider actually serves or deploys warn/skip
    — **Done when:** array reads `["glm-4.7", "glm-5-turbo", "glm-5.3", "glm-5.3-flash"]` and comment reflects native mapping
    — **Consumers affected:** resolve-models.mjs guard

- [x] **1.4** Docs tier swap (user-requested mid-execution, folded into this PR): `deploy/models.default.json` `tiers.docs` → `"zai-coding-plan/glm-5.3-flash"`; same for the Z.AI entry in `deploy/provider-presets.json` (~line 9); `AGENTS.md` docs row (~42) → `glm-5.3-flash` (1M); `opencode-agent-creation-skill/SKILL.md:52` tier table `glm-4.7` (docs/lint) → `glm-5.3-flash`. MIGRATION.md untouched (illustrative hand-mix example). `glm-4.7` stays in `provider-models.json` arrays (still served/valid)
    — **Why:** docs-tier agents (documentation, linting, coverage) benefit from the 1M-ctx flash model; keeps all subagent tiers on glm-5.3/flash generation
    — **Done when:** all four files reference glm-5.3-flash for docs; no presented-as-current `glm-4.7` tier pin remains
    — **Consumers affected:** coverage-subagent, documentation-subagent, linting-subagent, Z.AI provider preset deploys

### Phase 2: Doc + agent prose sync

- [x] **2.1** Root `AGENTS.md`: vision tier row (line ~43) → `zai-coding-plan/glm-5.3-flash` (1M ctx, multimodal); rewrite the Vision-fallback paragraph (~line 47) precisely: agents run `glm-5.3-flash` natively; when native perception is unavailable, the fallback calls `glm-5v-turbo` — a DIFFERENT model — via the zai-vision-analysis-skill direct API (drop "the same glm-5v-turbo" phrasing and any identical-quality claim)
    — **Why:** AGENTS.md is injected into every session; stale model ids misroute future work, and the fallback now uses a different model than native
    — **Done when:** `grep -n "glm-5v-turbo" AGENTS.md` returns only the fallback-path references that correctly name it as a different model
    — **Consumers affected:** all sessions in this repo
- [x] **2.2** `README.md` lines ~103 and ~618: same swap (vision tier table row + image-analyzer row)
    — **Why:** public-facing accuracy; doc-consistency tests read these tables
    — **Done when:** no README row presents `zai/glm-5v-turbo` as the active vision model
    — **Consumers affected:** readers, count-drift tests
- [x] **2.3** `deploy/agent-tiers.json` `$comment`: update the #294 note — vision tier is now `zai-coding-plan/glm-5.3-flash` (native multimodal, models.dev-verified); `glm-5v-turbo` no longer custom-registered under zai-coding-plan. ALSO delete the trailing false sentence "Nothing uses glm-4.6v-flash or zai-vision-analysis-skill anymore (the skill is now orphaned and can be retired)" — the skill is the documented fallback (AGENTS.md, opencode.json allowlist)
    — **Why:** the comment explains the tier registry to future maintainers; the orphan claim contradicts the kept fallback and would invite retiring a live escape hatch
    — **Done when:** comment mentions glm-5.3-flash + verification date AND contains no "orphaned"/"can be retired" sentence
    — **Consumers affected:** maintainers
- [x] **2.4** `opencode_app/.opencode/agents/image-analyzer-subagent.md` (4 refs) and `error-resolver-subagent.md` (2 refs): swap `zai/glm-5v-turbo` → `zai-coding-plan/glm-5.3-flash` in frontmatter `description` and body prose for the agent's OWN runtime model. Fallback references (direct-API path, incl. the line-78 snippet sending `"model": "glm-5v-turbo"`) stay mechanically intact, but the comparative claim at image-analyzer-subagent.md:51 "(same `glm-5v-turbo` model, so quality is identical to native)" MUST be reworded — the fallback is now a different model (e.g. "via `glm-5v-turbo` on the pay-as-you-go API — a different model from the native one")
    — **Why:** agent prompts must name the model they actually run on; descriptions feed registry.json; "identical quality" is false post-swap
    — **Done when:** no occurrence presents `zai/glm-5v-turbo` as this agent's runtime model AND no prose claims the fallback model is "the same" as the native model
    — **Consumers affected:** image-analyzer-subagent, error-resolver-subagent, registry.json
- [x] **2.5** `opencode_app/.opencode/skills/error-resolver-workflow-skill/SKILL.md` (lines ~97-98: "runs on the `zai/glm-5v-turbo` vision tier", "same `glm-5v-turbo` model") and `opencode_app/.opencode/skills/opencode-agent-creation-skill/SKILL.md` (line ~52 tier table row): update body prose to `zai-coding-plan/glm-5.3-flash`; fix the "same model" comparative claim. No frontmatter/description changes → no registry impact
    — **Why:** these files actively route future work (agent-creation is the template for every new subagent); leaving them pins new agents to the retired model
    — **Done when:** neither file presents `zai/glm-5v-turbo` as the current vision tier; `git diff deploy/registry.json` after regen (3.1) shows only the two agent-description changes
    — **Consumers affected:** future subagent creation, error-resolver workflow routing

### Phase 3: Registry + gates + commit

- [x] **3.1** Run `node deploy/build-registry.mjs` in the worktree; verify `deploy/registry.json` diff only touches the two agent descriptions; commit regenerated file
    — **Why:** AGENTS.md frontmatter contract requires registry regen after ANY frontmatter change; CI `--check` gate fails on drift
    — **Done when:** `node deploy/build-registry.mjs --check` exits 0
    — **Consumers affected:** CI, installer registry
- [x] **3.2** Full verification gate: (a) JSON parse guards — `python3 -c "import json; json.load(open(f))"` for `deploy/models.default.json`, `deploy/provider-models.json`, `opencode_app/opencode.json`; (b) `bats tests/` (count-drift + MCP-consistency suites); (c) stale-model grep: no `glm-5v-turbo` presented-as-current outside the exemption list (research/, CHANGELOG.md, registry.json:2057 skill entry, setup.sh:3393 built-in `zai` example, zai-vision-analysis-skill/SKILL.md fallback internals)
    — **Why:** Verification Gates rule; JSON typos in deploy inputs would propagate to every deploy; the grep makes the success metric enforceable
    — **Done when:** all parse guards exit 0, all bats suites pass, grep exemption-audited clean
    — **Consumers affected:** CI reliability
- [x] **3.3** Semantic commits (atomic): `feat(models): switch vision tier to native zai-coding-plan/glm-5.3-flash` (config), `docs: sync vision model references to glm-5.3-flash` (prose+registry); push `feat/GIT-349` to origin
    — **Why:** conventional-commit repo style; separates config from prose for reviewability
    — **Done when:** `git push -u origin feat/GIT-349` succeeds; `git log origin/main..HEAD` shows 2 clean commits
    — **Consumers affected:** reviewers, PR flow

## Risks & Mitigation

- **Risk:** models.dev catalog regression (glm-5.3-flash delisted from zai-coding-plan). Mitigation: `deploy/provider-models.json` guard fail-fasts at next deploy; escape hatch `zai/glm-5v-turbo` via `/models`.
- **Risk:** Docker build injects primary only; vision pin resolves at deploy — stale `~/.config/opencode/agent-overrides.json` could pin old model. Mitigation: precedence documented; note in PR description to re-run `setup.sh --models-only`.

## Success Metrics

- No "(custom)" label for vision-tier models in the OpenCode picker
- `build-registry.mjs --check` + full bats suite + JSON parse guards green
- Zero stale presented-as-current `glm-5v-turbo` references in shipped files (enforced by the 3.2 grep; exemptions: research/, CHANGELOG.md, registry.json skill entry, setup.sh `zai` example, zai-vision-analysis-skill fallback internals)

## Decisions

- **Fallback model identity (from plan review):** `zai-vision-analysis-skill` KEEPS `glm-5v-turbo` as its direct-API model (mechanism untouched — SKILL.md:64); only the "same model / identical quality" comparative prose is corrected. Retirement of the skill, if ever, is a separate decision.
