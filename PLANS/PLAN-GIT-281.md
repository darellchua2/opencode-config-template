# PLAN-GIT-281: Fix models.default.json tier→model pins the zai-coding-plan provider doesn't expose (~20 subagents fail to spawn)

**Issue**: https://github.com/darellchua2/opencode-config-template/issues/281
**Branch**: `GIT-281`
**Created**: 2026-08-02

## Problem

`deploy/models.default.json` maps the **`reasoning`** and **`vision`** tiers to models
the configured `zai-coding-plan` provider does **not** expose, so every subagent on those
two tiers fails to spawn at runtime with `Model not found`. The agent `.md` sources are
model-free and compliant — the defect is purely in the tier→model map.

- `reasoning` → `zai-coding-plan/glm-5.1`   not exposed (coding plan exposes only `glm-4.7`, `glm-5-turbo`, `glm-5.2`) → **18 agents** fail
- `vision` → `zai-coding-plan/glm-5v-turbo`  not exposed (no vision model is on the coding-plan subscription) → **2 agents** fail

**~20 of ~39 subagents are non-functional**, blocking all code/architecture reviews,
requirements/discovery work, ticket-creation chains that delegate to reviewers, and all
image/screenshot analysis.

## Root Cause (verified)

1. `zai-coding-plan` is OpenCode's flat Z.AI coding-plan **subscription**; it exposes exactly
   three text models: `glm-4.7`, `glm-5-turbo`, `glm-5.2`. Neither `glm-5.1` nor any vision
   model is served by it.
2. Vision models (incl. the free `glm-4.6v-flash`) live only on the **pay-/free-tier Z.AI API**
   provider (`zai`), authenticated by a separate Z.AI API key — not on the coding-plan subscription.
3. `resolve-models.mjs` performs **no validation** that a resolved tier model is actually
   exposed by its provider, so the bad pins surfaced at first subagent spawn instead of at deploy.

## Model Selection (authoritative source: https://docs.z.ai/guides/overview/pricing)

### Vision tier → `zai/glm-4.6v-flash`
Z.AI's official pricing lists exactly **one free vision model**: `GLM-4.6V-Flash`
(Input/Output/Cached = Free). It is a recent 4.6V-series model (128k ctx), adequate for the
sporadic image/screenshot analysis done by `image-analyzer-subagent` and `error-resolver-subagent`.
No `glm-4.5v-flashx` / `glm-4.6v-flashx` exists (the `flashx` suffix is text-only); the free
vision model is `glm-4.6v-flash`. models.dev omits it (stale) — the Z.AI pricing page is the
source of truth.

| Vision model   | Price (in/out per 1M) | Chosen? |
| --------------- | --------------------: | :-----: |
| GLM-4.6V-Flash  | **Free / Free**       |       |
| GLM-4.6V-FlashX | $0.04 / $0.40         |         |
| GLM-4.6V        | $0.30 / $0.90         |         |
| GLM-4.5V        | $0.60 / $1.80         |         |
| GLM-5V-Turbo    | $1.20 / $4.00         |         |

### Reasoning tier → `zai-coding-plan/glm-5.2`
`glm-5.1` (the canonical reasoning model) is not on the coding plan and is pay-per-token on the
API ($1.4/$4.4) — too costly for 18 heavily-used agents. `glm-5.2` is exposed by the coding-plan
subscription, has the strongest reasoning of the three exposed models, and matches the issue's
suggested fix. Reasoning agents will share the primary model, which is acceptable.

## Resolution

| Tier           | Before (broken)                  | After                                 | Provider        |
| -------------- | -------------------------------- | ------------------------------------- | --------------- |
| `primary`      | `zai-coding-plan/glm-5.2`        | `zai-coding-plan/glm-5.2` (unchanged) | coding plan     |
| `reasoning`    | `zai-coding-plan/glm-5.1`      | `zai-coding-plan/glm-5.2`             | coding plan     |
| `fast`         | `zai-coding-plan/glm-5-turbo`    | unchanged                             | coding plan     |
| `docs`         | `zai-coding-plan/glm-4.7`        | unchanged                             | coding plan     |
| `vision`       | `zai-coding-plan/glm-5v-turbo` | `zai/glm-4.6v-flash`                  | Z.AI API (free) |
| `long-context` | `zai-coding-plan/glm-5.2`        | unchanged                             | coding plan     |

**Prerequisite (user action):** authenticate the `zai` API provider once — `opencode auth login`
(select Z.AI) or export `ZAI_API_KEY`. This is separate from the coding-plan subscription and is
required only because the free vision model is not on the subscription.

---

## Dependency & Consumer Map

| Node (file/module)                       | Depends on (must precede) | Consumers (who depends on this)                                          | Change risk |
| ---------------------------------------- | ------------------------- | ------------------------------------------------------------------------ | ----------- |
| `deploy/models.default.json`             | —                         | `resolve-models.mjs` (reads tier map); `provider-presets.json` mirrors it | low         |
| `deploy/provider-presets.json`           | —                         | `setup.sh --provider/--mix` (writes user `models.json`); `resolve-models.mjs --provider` | low |
| `deploy/provider-models.json` (NEW)      | —                         | `resolve-models.mjs` guard (validates exposed set)                       | low         |
| `deploy/resolve-models.mjs`              | `provider-models.json` (Phase 3) | `deploy/setup.sh`, `deploy/setup.ps1` (invoke at deploy)            | med (logic) |
| `deploy/setup.sh` / `setup.ps1`          | resolver changes          | end-user deploy                                                          | low         |
| `opencode_app/opencode.json`             | —                         | vision agent spawn needs `zai` provider resolvable (built-in)            | low         |
| `README.md` / `opencode_app/README.md`   | tier-map changes          | user docs                                                                | low         |
| `AGENTS.md` (repo) + `deploy/.AGENTS.md` | tier-map changes          | agent routing docs (tier table)                                          | low         |

---

## Implementation Phases

### Phase 1: Repoint broken tiers

- [ ] **1.1** Edit `deploy/models.default.json`: set `tiers.reasoning` → `zai-coding-plan/glm-5.2` and `tiers.vision` → `zai/glm-4.6v-flash`; keep `primary`/`fast`/`docs`/`long-context` unchanged; refresh `$comment` if it mentions glm-5.1/glm-5v-turbo.
    — **Why:** These two pins are the defect; all other tiers are exposed and working.
    — **Done when:** `node -e "console.log(Object.entries(require('./deploy/models.default.json').tiers))"` prints no `glm-5.1`/`glm-5v-turbo`.
    — **Consumers affected:** `resolve-models.mjs`, `provider-presets.json` (mirrored next).

- [ ] **1.2** Edit `deploy/provider-presets.json` `zai` preset: set `tiers.reasoning` → `zai-coding-plan/glm-5.2` and `tiers.vision` → `zai/glm-4.6v-flash` to mirror `models.default.json`.
    — **Why:** The `--provider zai` / `--mix` flows write user `models.json` from this preset; it must not reintroduce the bad pins.
    — **Done when:** `jq '.zai.tiers' deploy/provider-presets.json` shows the two new values and no glm-5.1/glm-5v-turbo.
    — **Consumers affected:** `setup.sh --provider/--mix`, `resolve-models.mjs --provider`.

- [ ] **1.3** Grep the whole repo for residual `glm-5.1` / `glm-5v-turbo` references in deploy/config/docs; repoint or annotate any found (excluding `MIGRATION.md` history notes).
    — **Why:** A stale reference anywhere (banner, help text, AGENTS table) would mislead users or re-break a re-resolve.
    — **Done when:** `rg -n 'glm-5\.1|glm-5v-turbo' deploy/ opencode_app/ README.md AGENTS.md MIGRATION.md` returns only intentional historical mentions.
    — **Consumers affected:** none.

### Phase 2: Make the `zai` API provider available + documented

- [ ] **2.1** Confirm `zai` is a built-in OpenCode provider (no custom block needed) OR add an explicit minimal `provider.zai` entry to `opencode_app/opencode.json` using the Z.AI OpenAI-compatible endpoint (`https://api.z.ai/api/paas/v4/`) keyed off a `ZAI_API_KEY` env var.
    — **Why:** Vision tier now resolves to `zai/glm-4.6v-flash`; without an authenticatable `zai` provider, vision agents fail with a provider-auth error instead of the model-not-found error.
    — **Done when:** After `opencode auth login` (Z.AI) or `ZAI_API_KEY=…`, `image-analyzer-subagent` spawns without a provider/model error.
    — **Consumers affected:** `image-analyzer-subagent`, `error-resolver-subagent`.

- [ ] **2.2** Document the prerequisite in `README.md`, `opencode_app/README.md`, and the Subagent Model Tiering table in both `AGENTS.md` (repo) and `deploy/.AGENTS.md`: vision tier uses `zai/glm-4.6v-flash` (free) and requires a one-time Z.AI API auth separate from the coding-plan subscription.
    — **Why:** Users will otherwise hit an opaque auth failure with no guidance; the tiering table currently advertises `glm-5v-turbo`.
    — **Done when:** All four docs show `vision → zai/glm-4.6v-flash` and mention the API-key prerequisite.
    — **Consumers affected:** end-user onboarding/deploy.

### Phase 3: Add the deploy-time exposed-model guard (issue fix #3)

- [ ] **3.1** Create `deploy/provider-models.json` mapping provider-prefix → exposed model id array, seeding `zai-coding-plan: [glm-4.7, glm-5-turbo, glm-5.2]` and `zai: [glm-4.6v-flash, glm-4.5-flash, glm-4.7-flash, …]` (free-tier + key Z.AI API models).
    — **Why:** Gives the resolver a static, offline source of truth for "is this model actually served by its provider?" without a live network probe (fragile in offline/CI deploys).
    — **Done when:** File exists, is valid JSON, and lists `glm-4.6v-flash` under `zai` and `glm-5.2` under `zai-coding-plan`.
    — **Consumers affected:** `resolve-models.mjs` guard (3.2).

- [ ] **3.2** Extend `deploy/resolve-models.mjs`: after resolving each agent model and the primary/explore/general models, split `provider/model`, look the provider up in `provider-models.json` (loaded via a new `--provider-models <file>` arg), and collect any model not in the exposed set; if non-empty, print a clear `error: tier <T> pins <model> which is not exposed by provider <P>` per offender and `process.exit(1)`. Skip when the arg is absent (back-compat) or `--force` is set.
    — **Why:** Surfaces bad pins at deploy (fail-fast) instead of at first subagent spawn, preventing a regression like this from ever shipping silently again.
    — **Done when:** `node deploy/resolve-models.mjs … --provider-models deploy/provider-models.json` exits non-zero when a tier is deliberately repinned to an unexposed model (verified by a temporary bad pin), and exits 0 on the corrected map.
    — **Consumers affected:** `setup.sh`, `setup.ps1`.

- [ ] **3.3** Wire the guard into `deploy/setup.sh` and `deploy/setup.ps1`: pass `--provider-models deploy/provider-models.json` to the resolver invocation (apply + dry-run paths), so every deploy runs the check.
    — **Why:** The guard only protects users if it actually runs during their deploy flow.
    — **Done when:** A `grep provider-models deploy/setup.sh deploy/setup.ps1` shows the flag passed on the resolver call in both scripts.
    — **Consumers affected:** all deploys.

### Phase 4: Sync docs + verify

- [ ] **4.1** Update counts/listings if any changed (model-tier banner in `setup.sh`/`setup.ps1`, README tier table) and add a one-line `MIGRATION.md` note: "vision tier moved to free `zai/glm-4.6v-flash`; reasoning moved to `glm-5.2`".
    — **Why:** Keeps the documentation-sync invariant (repo convention) intact; the migration note explains the behavior change to existing deployers.
    — **Done when:** No doc still advertises `glm-5v-turbo`/`glm-5.1` as a current tier pin; `MIGRATION.md` has the note.
    — **Consumers affected:** none (docs).

- [ ] **4.2** Verify end-to-end: run the resolver dry-run and confirm 0 unexposed-model errors, all `reasoning` agents resolve to `zai-coding-plan/glm-5.2`, and both `vision` agents resolve to `zai/glm-4.6v-flash`; optionally spawn `image-analyzer-subagent` on a sample image once `zai` is authenticated.
    — **Why:** Proves the defect is fixed and the guard is green before opening the PR.
    — **Done when:** Dry-run table shows the expected models and `Summary: N written, 0 skipped(unresolved)` with no guard error.
    — **Consumers affected:** none (verification).

---

## Risks & Mitigation

- **Vision provider not authenticated** → vision agents fail with a *different* (auth) error. Mitigation: Phase 2.2 docs + a one-line warning in the resolver when a `zai/*` model is resolved but `ZAI_API_KEY` is absent (non-fatal hint).
- **Mixed-provider default surprises users** → the shipped `models.default.json` now spans two Z.AI auth methods. Mitigation: this matches the existing `--mix` capability and stays "Z.AI everywhere"; documented in Phase 2.2.
- **Guard false-positive on a legitimate new model** → deploy blocked. Mitigation: `--force` bypass and a single source file (`provider-models.json`) that's trivial to update as Z.AI exposes more models.
- **Reasoning agents share the primary model (glm-5.2)** → slightly less specialized than glm-5.1. Mitigation: acceptable per the issue; revisit when coding plan exposes glm-5.1.

## Success Metrics

- All ~39 subagents spawn without a `Model not found` error.
- `resolve-models.mjs --provider-models …` exits 0 on the corrected map and non-zero on a deliberately bad pin.
- Zero doc/banner references advertising `glm-5.1`/`glm-5v-turbo` as current tier pins.

## Dependencies

- User obtains a Z.AI API key and authenticates the `zai` provider (one-time, user action) for the vision tier to function.

