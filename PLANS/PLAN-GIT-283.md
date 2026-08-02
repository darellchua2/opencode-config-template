# PLAN-GIT-283: Free vision via direct-API skill; move image subagents to a text tier

**Issue**: https://github.com/darellchua2/opencode-config-template/issues/283
**Branch**: `GIT-283`
**Created**: 2026-08-02
**Supersedes**: the vision-tier approach from #281 (reasoning-tier fix in #281 stands).

## Problem

`#281`'s vision-tier repoint to `zai/glm-4.6v-flash` is **non-functional**: OpenCode's
model catalog is sourced from **models.dev**, and models.dev's `zai` provider does **not**
list `glm-4.6v-flash` — only paid `glm-4.6v`, `glm-4.5v`, `glm-5v-turbo`. So
`image-analyzer-subagent` and `error-resolver-subagent` (the `vision` tier) still cannot
spawn. Additionally, the deploy guard shipped in #281 gave a **false positive**:
`deploy/provider-models.json` listed `glm-4.6v-flash` under `zai` (taken from the Z.AI
pricing page), but models.dev — what OpenCode can actually select — does not expose it.

## Root Cause (verified)

1. OpenCode resolves provider models from the **models.dev** catalog (`@opencode-ai/models`).
   The free `glm-4.6v-flash` exists on the Z.AI API but is **absent from models.dev**, so it
   is unselectable through the `zai` provider — regardless of the resolver pin.
2. A **direct API call** to Z.AI bypasses the provider catalog, so `glm-4.6v-flash` (free)
   *is* reachable via `POST https://api.z.ai/api/paas/v4/chat/completions`.
3. `provider-models.json` was hand-seeded from the Z.AI pricing page, not models.dev → the
   guard's `zai` list drifted from OpenCode's real catalog.

## Solution (refined design — see #283 maintainer comment)

Keep the image subagents but move them to a **text** model, and do the actual image work via a
**direct-API skill** the subagent invokes:

```
image-analyzer-subagent / error-resolver-subagent  (text: zai-coding-plan/glm-4.7 — selectable, spawns)
   │  invokes
   ▼
zai-vision-analysis-skill  →  DECLARES the API-call recipe:
   endpoint = https://api.z.ai/api/paas/v4/chat/completions
   model    = glm-4.6v-flash   (FREE — served by direct API; not in models.dev)
   auth     = Bearer $ZAI_API_KEY
   payload  = multimodal messages (image base64 data-URL OR remote URL + prompt)
   │  subagent executes the call via its bash tool
   ▼
Z.AI vision API → text description of the image
   ▼
subagent (glm-4.7) interprets / reasons over the description → returns analysis
```

**Convention (maintainer):** image/screenshot/PDF analysis delegates through this
subagent→skill path by default. The `vision`-tier provider model (`glm-5v-turbo` et al.) is
used **only on explicit request**.

`glm-4.7` is chosen per the maintainer's decision — it is on the coding plan AND models.dev
(selectable, free under subscription), and is adequate to interpret the vision API's text
output. (Alternative: bump to the `reasoning` tier `glm-5.2` if interpretation quality is
insufficient — note in Phase 2.)

---

## Dependency & Consumer Map

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
| ------------------ | ------------------------- | ------------------------------- | ----------- |
| `opencode_app/.opencode/skills/zai-vision-analysis-skill/SKILL.md` (NEW) | — | image-analyzer + error-resolver subagents invoke it | med (API recipe correctness) |
| `opencode_app/.opencode/agents/image-analyzer-subagent.md` | skill (P1) | routing; AGENTS.md | med (behavior rewrite) |
| `opencode_app/.opencode/agents/error-resolver-subagent.md` | skill (P1) | routing; AGENTS.md | med (behavior rewrite) |
| `deploy/agent-tiers.json` | — | `resolve-models.mjs` | low |
| `deploy/models.default.json` | — | resolver; provider-presets mirrors it | low |
| `deploy/provider-presets.json` | models.default.json | `--provider`/`--mix` flows | low |
| `deploy/provider-models.json` | — | resolver exposed-model guard | low (data) |
| `AGENTS.md` + `deploy/.AGENTS.md` | tier/skill changes | routing docs | low |

---

## Implementation Phases

### Phase 1: Create the vision skill (direct-API recipe)

- [x] **1.1** Create `opencode_app/.opencode/skills/zai-vision-analysis-skill/SKILL.md` declaring the recipe for a direct Z.AI vision API call: `POST https://api.z.ai/api/paas/v4/chat/completions`, header `Authorization: Bearer $ZAI_API_KEY`, body `{ "model": "glm-4.6v-flash", "messages": [ { "role": "user", "content": [ { "type": "text", "text": "<prompt>" }, { "type": "image_url", "image_url": { "url": "<base64 data-URL OR remote URL>" } } ] } ] }`. Include a ready-to-run `curl` template, response parsing (`choices[0].message.content`), input handling (local file → base64 `data:<mime>;base64,…`; remote URL → pass through), and error handling (missing `ZAI_API_KEY`, non-200, oversized images, malformed JSON).
    — **Why:** This is the core artifact that delivers free vision by bypassing the provider catalog; it must be a correct, copy-pasteable recipe the subagent can execute via bash.
    — **Done when:** The skill file exists, documents endpoint/model/auth/payload + curl template + error cases, and the recipe matches the Z.AI OpenAI-compatible schema (verified against docs.z.ai).
    — **Consumers affected:** image-analyzer-subagent, error-resolver-subagent.

### Phase 2: Move the image subagents off the broken `vision` tier → `glm-4.7` (text) and rewrite them to use the skill

- [x] **2.1** In `deploy/agent-tiers.json`, reassign `image-analyzer-subagent` and `error-resolver-subagent` from `vision` → `docs` (resolves to `zai-coding-plan/glm-4.7`, which is on the coding plan AND models.dev → selectable, spawns). Add an inline comment explaining they are now text-based vision-via-skill agents (not multimodal).
    — **Why:** Gets both agents spawning on a selectable text model; `glm-4.7` is the maintainer-chosen model for interpreting the API result.
    — **Done when:** `node -e "const t=require('./deploy/agent-tiers.json').tiers; console.log(t['image-analyzer-subagent'], t['error-resolver-subagent'])"` prints `docs docs`; no agent remains on `vision` by default.
    — **Consumers affected:** resolver, AGENTS.md tier counts.

- [x] **2.2** Rewrite `opencode_app/.opencode/agents/image-analyzer-subagent.md`: state it runs on a **text** model (`glm-4.7`) and **cannot see images directly** — it MUST obtain image content by invoking `zai-vision-analysis-skill` (which performs the free `glm-4.6v-flash` API call), then interpret/reason over the returned description. Provide the delegation procedure + output expectations.
    — **Why:** Without this the agent would assume multimodal capability it no longer has; the skill is its only path to image content.
    — **Done when:** The agent .md documents the text-model constraint + skill-invocation procedure; no claim of native image vision remains.
    — **Consumers affected:** any caller that delegates image analysis.

- [x] **2.3** Apply the same rewrite to `opencode_app/.opencode/agents/error-resolver-subagent.md` (screenshot-based diagnosis) — text model + skill for screenshots. _(Per the refined-design comment; confirm error-resolver is in scope — if not, drop this step.)_
    — **Why:** error-resolver is the other `vision`-tier agent and would otherwise stay broken.
    — **Done when:** error-resolver .md documents text-model + skill-invocation for screenshot diagnosis.
    — **Consumers affected:** error-resolver callers.

### Phase 3: Make the `vision` tier honest + align the guard to models.dev

- [x] **3.1** In `deploy/models.default.json`, repoint the `vision` tier from the non-selectable `zai/glm-4.6v-flash` → `zai/glm-4.6v` (the cheapest **models.dev-valid** `zai` vision model, $0.30/$0.90) so the tier is functional for explicit opt-in use. (No default agent uses it after Phase 2.)
    — **Why:** Leaves a working, selectable vision-tier model for the "explicit paid request" convention; removes the broken pin.
    — **Done when:** `models.default.json` `tiers.vision` = `zai/glm-4.6v`; `glm-4.6v-flash` no longer appears as a tier pin.
    — **Consumers affected:** provider-presets.json (mirrored next), resolver guard.

- [x] **3.2** Mirror in `deploy/provider-presets.json`: `zai` preset `tiers.vision` → `zai/glm-4.6v`. (Other providers' vision entries — anthropic/openai/etc. — are already models.dev-valid; leave them.)
    — **Why:** Keeps `--provider zai`/`--mix` consistent with the default map; prevents re-introducing the broken pin.
    — **Done when:** `jq '.zai.tiers.vision' deploy/provider-presets.json` = `"zai/glm-4.6v"`.
    — **Consumers affected:** setup `--provider`/`--mix`.

- [x] **3.3** Align `deploy/provider-models.json` `zai` list to **models.dev**: **remove `glm-4.6v-flash`** (not selectable via provider) and ensure the models.dev vision set (`glm-4.6v`, `glm-4.5v`, `glm-5v-turbo`) is present. Add/refresh the `$comment` to state this file MUST track the models.dev `zai` catalog (not the Z.AI pricing page) so the guard never false-positives again.
    — **Why:** The guard is only trustworthy if its exposed-set matches OpenCode's real (models.dev) catalog; this fixes the #281 false-positive root cause.
    — **Done when:** `glm-4.6v-flash` absent from `provider-models.json`; `glm-4.6v`/`glm-4.5v`/`glm-5v-turbo` present under `zai`; `$comment` documents the models.dev source-of-truth rule.
    — **Consumers affected:** resolve-models.mjs guard.

### Phase 4: Routing docs + verify

- [x] **4.1** Update routing docs: repo `AGENTS.md` + `deploy/.AGENTS.md` — image/screenshot/PDF analysis delegates to `image-analyzer-subagent` (now text, `glm-4.7`) which invokes `zai-vision-analysis-skill` (free `glm-4.6v-flash` via direct API). Update the tier table: `vision` tier = opt-in paid (`glm-4.6v`); the two image agents are now `docs` tier. State the convention: vision-tier provider model only on explicit request.
    — **Why:** Otherwise callers/routing still assume a multimodal vision subagent; the tier counts and default image path must reflect the new architecture.
    — **Done when:** Both docs describe the subagent→skill path and the opt-in vision-tier convention; tier counts match `agent-tiers.json`.
    — **Consumers affected:** agent routing.

- [x] **4.2** Verify end-to-end: resolver dry-run with `--provider-models` shows `image-analyzer-subagent` + `error-resolver-subagent` → `zai-coding-plan/glm-4.7`, `vision` tier → `zai/glm-4.6v`, and the guard is green (exit 0); confirm `glm-4.6v-flash` is absent from `provider-models.json`; optionally execute the skill's curl recipe live against a sample image with `ZAI_API_KEY` set to confirm a free `glm-4.6v-flash` response.
    — **Why:** Proves both subagents spawn on a selectable model, the vision tier is honest, the guard no longer false-positives, and the skill recipe actually returns free vision results.
    — **Done when:** Dry-run table shows the expected models, guard exit 0, and (if live-tested) the API returns an image description from `glm-4.6v-flash`.
    — **Consumers affected:** none (verification).

---

## Risks & Mitigation

- **`glm-4.7` weaker at interpreting complex scenes than a native vision model** → the API returns a rich description first; if interpretation quality is insufficient, bump the two agents to the `reasoning` tier (`glm-5.2`) — one-line tier change.
- **Direct API call adds latency + a bash/curl dependency** → acceptable for sporadic use; skill documents timeouts and retries.
- **`ZAI_API_KEY` required** → already wired (`.env.example`, `setup.sh`, `docker-entrypoint.sh`); skill fails fast with a clear message if absent.
- **Local-image base64 sizing** → skill caps/pads oversized images and documents the limit.
- **`provider-models.json` drift** → the Phase 3.3 `$comment` rule (track models.dev) prevents a repeat of the #281 false positive.
- **error-resolver scope** → Phase 2.3 is conditional on maintainer confirmation; if dropped, error-resolver stays broken and needs its own follow-up.

## Success Metrics

- `image-analyzer-subagent` and `error-resolver-subagent` spawn on `zai-coding-plan/glm-4.7`.
- The vision skill returns a free `glm-4.6v-flash` image description via direct API (live-tested).
- `provider-models.json` `zai` list matches models.dev (no `glm-4.6v-flash`); the guard exits 0 on the corrected map.
- `vision` tier (`zai/glm-4.6v`) is functional for opt-in, and routing docs reflect the subagent→skill default.

## Dependencies

- `ZAI_API_KEY` set (existing) for the skill's direct API call.

## Open confirmations

- **error-resolver-subagent** — apply the same `glm-4.7` + skill pattern (Phase 2.3)? Assumed yes per the refined-design comment; confirm to keep, or drop 2.3.

---

## Revision Log

**2026-08-02 (execution — all phases applied, COMPLETE)** —
- **Phase 1:** `zai-vision-analysis-skill` created. **Live-tested** against free `glm-4.6v-flash` — returned an accurate description of a test image (green + "Hi" text), proving the direct-API recipe works.
- **Recipe bug-fix (caught by the live test):** the original `python3 -c` helper read `PROMPT`/`DATA_URL` from `os.environ`, but those were un-exported shell vars → `KeyError` → empty body → API 400. Rewrote the helper to take the image source + prompt as **argv** and read/base64-encode the image inside python (also avoids `ARG_MAX` + `base64 -w0` portability issues).
- **Phase 2:** `image-analyzer-subagent` + `error-resolver-subagent` reassigned `vision`→`docs` (→ `glm-4.7`); both rewrites make them text-based + skill-driven; `bash: deny`→`allow` (needed for curl); skill added to the global allowlist (image-analyzer is unscooped) and to error-resolver's `permission.skill`. **error-resolver confirmed in scope.**
- **Phase 3:** `vision` tier → `zai/glm-4.6v` (models.dev-valid, opt-in); `provider-models.json` `zai` list re-aligned to exactly models.dev's 14-model catalog (removed `glm-4.6v-flash`, `glm-4.6v-flashx`, `glm-ocr`, `glm-4.5-x`, `glm-4.5-airx`, `glm-4-32b-0414-128k`); `$comment` documents the models.dev source-of-truth rule (fixes the #281 guard false-positive class).
- **Phase 4:** routing docs (AGENTS.md tier table + vision note, deploy/.AGENTS.md line 16), skill-count sync (README 123→124, Configuration category 3→4); de-staled `glm-4.6v-flash` references in opencode-agent-creation-skill + MIGRATION.md.
- **Verified:** resolver dry-run green (image-analyzer + error-resolver → `glm-4.7`; 0 agents on `vision` tier); guard exit 0; `glm-4.6v-flash` is no longer a provider pin anywhere (only in explanatory `$comment`s + the skill).
