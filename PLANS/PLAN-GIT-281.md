# PLAN-GIT-281: Fix models.default.json tier→model pins the zai-coding-plan provider doesn't expose (20 of 38 subagents fail to spawn)

**Issue**: https://github.com/darellchua2/opencode-config-template/issues/281
**Branch**: `GIT-281`
**Created**: 2026-08-02
**Revised**: 2026-08-02 (incorporates opencode-tooling review — see Revision Log)

## Problem

`deploy/models.default.json` maps the **`reasoning`** and **`vision`** tiers to models
the configured `zai-coding-plan` provider does **not** expose, so every subagent on those
two tiers fails to spawn at runtime with `Model not found`. The agent `.md` sources are
model-free and compliant — the defect is purely in the tier→model map (plus a few stale
hardcoded pins — see Root Cause #4).

- `reasoning` → `zai-coding-plan/glm-5.1`   not exposed (coding plan exposes only `glm-4.7`, `glm-5-turbo`, `glm-5.2`) → **18 agents** fail
- `vision` → `zai-coding-plan/glm-5v-turbo`  not exposed (no vision model is on the coding-plan subscription) → **2 agents** fail

**20 of 38 subagents are non-functional** (the issue's "~20 of ~39" rounds the 38 total),
blocking all code/architecture reviews, requirements/discovery work, ticket-creation chains
that delegate to reviewers, and all image/screenshot analysis.

## Root Cause (verified)

1. `zai-coding-plan` is OpenCode's flat Z.AI coding-plan **subscription**; it exposes exactly
   three text models: `glm-4.7`, `glm-5-turbo`, `glm-5.2`. Neither `glm-5.1` nor any vision
   model is served by it.
2. Vision models (incl. the free `glm-4.6v-flash`) live only on the **pay-/free-tier Z.AI API**
   provider (`zai`), authenticated by a separate Z.AI API key — not on the coding-plan subscription.
3. `resolve-models.mjs` performs **no validation** that a resolved tier model is actually
   exposed by its provider, so the bad pins surfaced at first subagent spawn instead of at deploy.
4. **Stale hardcoded pins** (not caught by the original plan — found in review): the `general`
   built-in agent is pinned `zai-coding-plan/glm-5.1` in `opencode_app/opencode.json:401`
   (used directly by the **Docker standalone** path, which does not run the resolver), and the
   `opencode-agent-creation-skill` teaches the broken `glm-5.1`/`glm-5v-turbo` pins — a
   propagation source that re-creates the bug on every agent it generates.

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
| GLM-4.6V-Flash  | **Free / Free**       |    ✓    |
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
| `opencode_app/opencode.json:401` (`general`) | —                     | Docker standalone uses it **directly** (no resolver); user-space deploy is patched by resolver | low |
| `opencode_app/opencode.json` (`provider.zai` block) | —          | vision agent spawn needs `zai` provider resolvable + authed              | med (auth)  |
| `opencode_app/.opencode/skills/opencode-agent-creation-skill/SKILL.md` | — | generates new agents — stale pins propagate the bug                  | low         |
| `deploy/provider-models.json` (NEW)      | —                         | `resolve-models.mjs` guard (validates exposed set)                       | low         |
| `deploy/resolve-models.mjs`              | `provider-models.json` (Phase 3) | `deploy/setup.sh`, `deploy/setup.ps1` (invoke at deploy)            | med (logic) |
| `deploy/setup.sh` / `setup.ps1`          | resolver changes          | end-user deploy                                                          | low         |
| `AGENTS.md` (repo root, lines 26-43)     | tier-map changes          | **only file** with the Subagent Model Tiering table                      | low         |
| `README.md` / `opencode_app/README.md`   | tier-map changes          | user docs (verify `opencode_app/README.md` has tier content first)       | low         |
| `deploy/.AGENTS.md`                      | —                         | routing/rules only — **NO tier table, NO model refs**; optional auth note at line 16 | low |

> **Note:** `deploy/.AGENTS.md` (92 lines) contains only routing/rules sections and references
> `image-analyzer-subagent` solely at line 16 (delegation routing). It has no model-tier table,
> so it is **not** a tier-table edit target — at most it gets an optional one-line `zai` auth note.

---

## Implementation Phases

### Phase 1: Repoint broken tiers + stale hardcoded pins

- [ ] **1.1** Edit `deploy/models.default.json`: set `tiers.reasoning` → `zai-coding-plan/glm-5.2` and `tiers.vision` → `zai/glm-4.6v-flash`; keep `primary`/`fast`/`docs`/`long-context` unchanged; refresh `$comment` if it mentions glm-5.1/glm-5v-turbo.
    — **Why:** These two pins are the core defect; all other tiers are exposed and working.
    — **Done when:** `node -e "console.log(Object.entries(require('./deploy/models.default.json').tiers))"` prints no `glm-5.1`/`glm-5v-turbo`.
    — **Consumers affected:** `resolve-models.mjs`, `provider-presets.json` (mirrored next).

- [ ] **1.2** Edit `deploy/provider-presets.json` `zai` preset: set `tiers.reasoning` → `zai-coding-plan/glm-5.2` and `tiers.vision` → `zai/glm-4.6v-flash` to mirror `models.default.json`.
    — **Why:** The `--provider zai` / `--mix` flows write user `models.json` from this preset; it must not reintroduce the bad pins.
    — **Done when:** `jq '.zai.tiers' deploy/provider-presets.json` shows the two new values and no glm-5.1/glm-5v-turbo.
    — **Consumers affected:** `setup.sh --provider/--mix`, `resolve-models.mjs --provider`.

- [ ] **1.3** Repoint the `general` built-in agent in `opencode_app/opencode.json:401` from `zai-coding-plan/glm-5.1` → `zai-coding-plan/glm-5.2` (leave `explore` at `:392` = `glm-5-turbo`, already correct; leave top-level `model` at `:3` = `glm-5.2`).
    — **Why:** The Docker standalone path consumes this source file directly without running the resolver, so the `general` agent stays broken in Docker unless the source pin is fixed. (User-space deploy is patched at runtime by the resolver, but the source must be correct for Docker parity.)
    — **Done when:** `grep -n '"model"' opencode_app/opencode.json` shows `glm-5.2`, `glm-5-turbo`, `glm-5.2` (no `glm-5.1`).
    — **Consumers affected:** Docker standalone `general` agent; user-space `general` (already patched, now source-consistent).

- [ ] **1.4** Repoint the stale pins in `opencode_app/.opencode/skills/opencode-agent-creation-skill/SKILL.md`: update the 4 `glm-5.1` references (lines 54, 81, 153, 387) and the `glm-5v-turbo` reference (line 54) to the new tier models (`reasoning`→`glm-5.2`, `vision`→`zai/glm-4.6v-flash`).
    — **Why:** This skill **generates new agents**; leaving it stale re-creates the bug on every agent it produces — a propagation source, not a passive doc.
    — **Done when:** `grep -nE 'glm-5\.1|glm-5v-turbo' opencode_app/.opencode/skills/opencode-agent-creation-skill/SKILL.md` returns nothing.
    — **Consumers affected:** all future agents created via this skill.

- [ ] **1.5** Sweep for remaining stale references and **edit** (not annotate) any runtime/prose/doc hit: at minimum `technical-design-specialist-subagent.md:54` ("runs at `glm-5.1`" → `glm-5.2` or make model-agnostic) and `README.md:461` ("(glm-5.1)" → `glm-5.2`). `MIGRATION.md:133` is an *example* block — update for consistency (optional but recommended); other MIGRATION.md mentions are historical and left as-is.
    — **Why:** A stale reference anywhere (banner, help text, agent prose, README) misleads users or contradicts the live config; prose like "runs at glm-5.1" is factually wrong post-repoint.
    — **Done when:** `grep -rn --exclude-dir=.git -E 'glm-5\.1|glm-5v-turbo' .` returns only intentional historical mentions in `MIGRATION.md` (and the PLAN's own before/after table).
    — **Consumers affected:** none (docs/prose consistency).

### Phase 2: Make the `zai` API provider available + documented

- [ ] **2.1** Add an explicit `provider.zai` block to `opencode_app/opencode.json` using the Z.AI OpenAI-compatible endpoint (`npm: "@ai-sdk/openai-compatible"`, `baseURL: "https://api.z.ai/api/paas/v4/"`, `apiKey` from `$ZAI_API_KEY`). Confirm the provider id + base URL at execution via `opencode auth login`'s provider list or the Z.AI OpenAI-SDK doc page before writing.
    — **Why:** Whether `zai` is a built-in OpenCode provider is unconfirmed (the config currently only declares `lmstudio` as custom; `zai-coding-plan` is built-in but serves no vision model). An **explicit block works regardless** of built-in status and is self-documenting — the robust default. Vision tier resolves to `zai/glm-4.6v-flash`; without an authenticatable `zai` provider, vision agents fail with a provider-auth error instead of model-not-found.
    — **Done when:** After `opencode auth login` (Z.AI) or `ZAI_API_KEY=…`, `image-analyzer-subagent` spawns without a provider/model error; `provider.zai` block is present in `opencode_app/opencode.json`.
    — **Consumers affected:** `image-analyzer-subagent`, `error-resolver-subagent`.

- [ ] **2.2** Document the prerequisite in `README.md`, repo-root `AGENTS.md` (the **only** file with the Subagent Model Tiering table, lines 26-43), and `opencode_app/README.md` (verify it has tier content first; if not, skip). State: vision tier uses `zai/glm-4.6v-flash` (free) and requires a one-time Z.AI API auth separate from the coding-plan subscription. **Do NOT** edit `deploy/.AGENTS.md` for a tier table (it has none) — optionally add a one-line `zai` auth note near `deploy/.AGENTS.md:16` where image-analysis routing to `image-analyzer-subagent` is mentioned.
    — **Why:** Users will otherwise hit an opaque auth failure with no guidance; the repo tier table currently advertises `glm-5v-turbo`. (`deploy/.AGENTS.md` was incorrectly listed as a tier-table target in the original plan — corrected: it has no model/tier content.)
    — **Done when:** Repo `AGENTS.md` + `README.md` (and `opencode_app/README.md` if applicable) show `vision → zai/glm-4.6v-flash` and mention the API-key prerequisite; no file falsely claims `deploy/.AGENTS.md` has a tier table.
    — **Consumers affected:** end-user onboarding/deploy.

### Phase 3: Add the deploy-time exposed-model guard (issue fix #3)

- [ ] **3.1** Create `deploy/provider-models.json` mapping provider-prefix → exposed model id array, seeding `zai-coding-plan: [glm-4.7, glm-5-turbo, glm-5.2]` and `zai: [glm-4.6v-flash, glm-4.5-flash, glm-4.7-flash, …]` (free-tier + key Z.AI API models).
    — **Why:** Gives the resolver a static, offline source of truth for "is this model actually served by its provider?" without a live network probe (fragile in offline/CI deploys).
    — **Done when:** File exists, is valid JSON, and lists `glm-4.6v-flash` under `zai` and `glm-5.2` under `zai-coding-plan`.
    — **Consumers affected:** `resolve-models.mjs` guard (3.2).

- [ ] **3.2** Extend `deploy/resolve-models.mjs`: after resolving each agent model **and** the primary/explore/general models (computed at `:265-288`), split `provider/model`, look the provider up in `provider-models.json` (loaded via a new `--provider-models <file>` arg), and collect any model not in the exposed set; if non-empty, print `error: tier <T> pins <model> which is not exposed by provider <P>` per offender and `process.exit(1)`. The guard MUST also validate the **source** `opencode_app/opencode.json` pins (primary + explore + general), not only per-agent tier models, so a stale source pin is caught. Edge cases: (a) a model string with no `/` → skip-with-warning (don't crash on split); (b) a provider prefix **absent** from `provider-models.json` (e.g. `anthropic`/`openai`/`openrouter` presets) → warn-and-skip (cannot validate unknown providers; avoids false-positive deploy failures). Skip the whole check when the arg is absent (back-compat) or `--force` is set (flag already exists + is wired).
    — **Why:** Surfaces bad pins at deploy (fail-fast) instead of at first subagent spawn, preventing a regression like this from ever shipping silently again. Source-config validation closes the Docker gap (Root Cause #4).
    — **Done when:** `node deploy/resolve-models.mjs … --provider-models deploy/provider-models.json` exits non-zero when a tier is deliberately repinned to an unexposed model (verified by a temporary bad pin), and exits 0 on the corrected map; a deliberately stale `opencode_app/opencode.json` source pin is also flagged.
    — **Consumers affected:** `setup.sh`, `setup.ps1`.

- [ ] **3.3** Wire the guard into `deploy/setup.sh` and `deploy/setup.ps1`: pass `--provider-models deploy/provider-models.json` to the resolver invocation (apply + dry-run paths — resolver script var at `setup.sh:98` / `setup.ps1:102`), so every deploy runs the check.
    — **Why:** The guard only protects users if it actually runs during their deploy flow.
    — **Done when:** `grep -n provider-models deploy/setup.sh deploy/setup.ps1` shows the flag passed on the resolver call in both scripts.
    — **Consumers affected:** all deploys.

### Phase 4: Sync docs + verify

- [ ] **4.1** Update counts/listings if any changed (model-tier banner in `setup.sh`/`setup.ps1` — confirmed they do NOT hardcode model names, so likely no banner edit) and add a one-line `MIGRATION.md` note: "vision tier moved to free `zai/glm-4.6v-flash`; reasoning moved to `glm-5.2`".
    — **Why:** Keeps the documentation-sync invariant (repo convention) intact; the migration note explains the behavior change to existing deployers.
    — **Done when:** No doc still advertises `glm-5v-turbo`/`glm-5.1` as a current tier pin; `MIGRATION.md` has the note.
    — **Consumers affected:** none (docs).

- [ ] **4.2** Verify end-to-end: run the resolver dry-run with `--provider-models` and confirm 0 unexposed-model errors, all `reasoning` agents resolve to `zai-coding-plan/glm-5.2`, and both `vision` agents resolve to `zai/glm-4.6v-flash`; confirm the source `opencode_app/opencode.json` pins pass the guard; optionally spawn `image-analyzer-subagent` on a sample image once `zai` is authenticated.
    — **Why:** Proves the defect is fixed and the guard is green before opening the PR.
    — **Done when:** Dry-run table shows the expected models, `Summary: N written, 0 skipped(unresolved)`, and no guard error (including for source-config pins).
    — **Consumers affected:** none (verification).

---

## Risks & Mitigation

- **Vision provider not authenticated** → vision agents fail with a *different* (auth) error. Mitigation: Phase 2.2 docs + a one-line warning in the resolver when a `zai/*` model is resolved but `ZAI_API_KEY` is absent (non-fatal hint).
- **`zai` provider id / base URL wrong** → explicit block doesn't connect. Mitigation: Phase 2.1 confirms via `opencode auth login` provider list / Z.AI OpenAI-SDK doc before writing; explicit block is still safer than relying on an unconfirmed built-in.
- **Mixed-provider default surprises users** → the shipped `models.default.json` now spans two Z.AI auth methods. Mitigation: this matches the existing `--mix` capability and stays "Z.AI everywhere"; documented in Phase 2.2.
- **Guard false-positive on a legitimate new model / unknown provider** → deploy blocked. Mitigation: warn-and-skip for unknown provider prefixes; `--force` bypass; single source file (`provider-models.json`) trivial to update as Z.AI exposes more models; `knownDefaults` preserve logic (`resolve-models.mjs:210-211,247`) is unaffected since new model strings are just different values, not new keys.
- **Reasoning agents share the primary model (glm-5.2)** → slightly less specialized than glm-5.1. Mitigation: acceptable per the issue; revisit when coding plan exposes glm-5.1.

## Success Metrics

- All 38 subagents spawn without a `Model not found` error.
- `resolve-models.mjs --provider-models …` exits 0 on the corrected map (incl. source `opencode_app/opencode.json` pins) and non-zero on a deliberately bad pin.
- Zero doc/banner/prose references advertising `glm-5.1`/`glm-5v-turbo` as current tier pins (except intentional `MIGRATION.md` history).

## Dependencies

- User obtains a Z.AI API key and authenticates the `zai` provider (one-time, user action) for the vision tier to function.

---

## Revision Log

**2026-08-02 (post opencode-tooling review)** — review could not delegate to `opencode-tooling-subagent`
(reasoning-tier victim of #281 itself); performed in primary session. Findings applied:
- **M1** (new 1.3): repoint `general` pin at `opencode_app/opencode.json:401` (Docker uses source directly).
- **M2** (new 1.4): repoint stale pins in `opencode-agent-creation-skill/SKILL.md` (propagation source).
- **M3** (2.2 + map): `deploy/.AGENTS.md` has no tier table — removed as a tier-table target; optional auth note at its line 16 instead.
- **M4** (2.1): resolved the `zai` built-in-vs-custom hedge → add an explicit `provider.zai` block (robust default), confirm id/URL at execution.
- **m1/m2** (1.5): `technical-design-specialist-subagent.md:54` prose + `README.md:461` edited, not annotated.
- **m3/m4** (3.2): guard edge cases (no-slash model, unknown provider → warn-skip) + source-config pin validation.
- **n1**: counts corrected to 38 total / 20 broken.
- **n2**: `MIGRATION.md:133` example block flagged for optional update.
