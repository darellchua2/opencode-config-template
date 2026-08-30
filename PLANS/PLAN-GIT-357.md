# PLAN: Custom Z.AI Coding Plan provider + media skills + zai-media-subagent

**Issue:** https://github.com/darellchua2/opencode-config-template/issues/357
**Branch:** GIT-357 (PR base: `dev` — release.yml gates main+dev)

**Decisions (refining issue #357's approved design to house mechanisms):**
1. **New provider key `zai-custom-plan`** in `opencode_app/opencode.json` (openai-compatible → coding-plan endpoint, `{env:ZAI_API_KEY}`) — honors the issue's "custom, deliberately NOT models.dev defaults" declaration. Key keeps the `zai` substring so opencode's GLM `thinking:{type:"enabled"}` injection applies.
2. **Vision tier repoints to `zai-custom-plan/glm-5.3-flash`** (replacing `zai-coding-plan/glm-5v-turbo`, an unverified model ID whose shipped entry lacks `attachment: true` — the original vision failure). Affects `image-analyzer-subagent` + `error-resolver-subagent`; flash is Z.AI's verified multimodal plan model. Other tiers (primary/reasoning/fast/docs/long-context) stay on `zai-coding-plan` — out of scope, working today.
3. **`small_model` is NOT shipped** — the resolver (`resolve-models.mjs`) has no small_model support and local deploys deliberately omit top-level model keys. Documented as a post-deploy personal line instead.
4. **New MCP entries follow GIT-333 direction**: `zai-web-search-prime` enabled (matches `zai-web-reader` precedent; auto-start 2→3, test updated), `zai-vision-mcp` shipped **enabled:false** (native multimodal subagents already replaced the vision-MCP path; opt-in only).
5. **House naming**: skills get the `-skill` suffix (`zai-video-skill`, `zai-asr-skill`, `zai-ocr-skill` — consistent with `zai-image-generation-skill`); the subagent is `zai-media-subagent.md`. Skills are SKILL.md-recipe style (curl recipes inline, no script files — matches `zai-image-generation-skill`). Category: `Media Generation`.
6. **Skills are NOT added to the lean profile** (lean stays 30): they are consumer-scoped to `zai-media-subagent`, which gets `permission.skill` frontmatter allows per the GIT-333 pattern. Full-profile count grows 87→90.

## Overview

Deliver the issue #357 design through this repo's deploy mechanism: a self-defined `zai-custom-plan` provider (glm-5.3 main, glm-5.3-flash small+vision), attachment.image overrides exploiting Z.AI's full 6000px/5MB allowance, plan-exclusive MCP (web_search_prime, web_reader already shipped, vision opt-in), three media skills (video submit/poll, ASR, OCR), and a `zai-media-subagent` on the vision tier for context/key isolation. Everything edits source of truth under `opencode_app/` + `deploy/`, never deployed copies.

---

## Dependency & Consumer Map

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---------------------|---------------------------|---------------------------------|-------------|
| `opencode_app/opencode.json` `provider.zai-custom-plan` block | nothing | models.default.json vision tier, provider-presets zai preset, `zai-media-subagent`, image-analyzer + error-resolver (via tier) | med — malformed block breaks provider load |
| `opencode_app/opencode.json` `attachment.image` | provider block (flash modalities) | all image uploads | low |
| `deploy/models.default.json` + `deploy/provider-presets.json` vision lines | provider block | image-analyzer-subagent, error-resolver-subagent, zai-media-subagent (resolve-models.mjs injects at deploy) | med — bad model string breaks deploy resolution |
| `opencode_app/opencode.json` mcp entries (zai-web-search-prime, zai-vision-mcp) | `{env:ZAI_API_KEY}` | all sessions (search, auto-start 2→3); opt-in vision users | low — `tests/test_mcp_count_consistency.bats:73` asserts auto-start count |
| `opencode_app/.opencode/skills/zai-{video,asr,ocr}-skill/` (new) | `{env:ZAI_API_KEY}` at runtime | zai-media-subagent (frontmatter allows), `deploy/registry.json` (regen), full-profile count 87→90 | low |
| `opencode_app/.opencode/agents/zai-media-subagent.md` (new) | provider block (via tier), 3 skills (frontmatter allows) | primary sessions (Task tool) | low |
| `deploy/agent-tiers.json` (+zai-media-subagent: vision, $comment update) | agent file | resolve-models.mjs | low |
| `deploy/registry.json` | ANY frontmatter change (skills, agent) | `tests/init.bats` counts, init.mjs, release.yml `build-registry.mjs --check` | high — committing frontmatter without regen = red CI |
| `deploy/setup.sh` / `setup.ps1` / `README.md` / `opencode_app/README.md` (Sync Rules counts) | skills + agent landed | doc-consistency bats tests, users | low |

---

## Implementation Phases

### Phase 1: Provider, attachment, vision tier, MCP (shipped config + deploy data)

- [x] **1.1** Add `provider.zai-custom-plan` block to `opencode_app/opencode.json`: `npm: "@ai-sdk/openai-compatible"`, `name: "Z.AI (custom)"`, `options.baseURL: "https://api.z.ai/api/coding/paas/v4"`, `options.apiKey: "{env:ZAI_API_KEY}"`, `models`: `glm-5.3` `{limit:{context:1000000,output:131072}}` and `glm-5.3-flash` `{limit:{context:1000000,output:131072}, attachment:true, modalities:{input:["text","image"],output:["text"]}}`. Leave the existing `zai-coding-plan` block untouched.
    — **Why:** provider is the base node every other step references; explicit `attachment:true` is the fix for the vision failure (custom entries default to false); "zai" substring keeps opencode's GLM thinking injection.
    — **Done when:** `node -e "require('./opencode_app/opencode.json')"` parses; `provider['zai-custom-plan'].models` has both models with attachment/modalities on flash.
    — **Consumers affected:** vision tier lines (1.3), zai-media-subagent (3.1), image-analyzer + error-resolver (via 1.3).

- [x] **1.2** Add `"attachment": {"image": {"max_width": 6000, "max_height": 6000, "max_base64_bytes": 7000000}}` to `opencode_app/opencode.json`.
    — **Why:** opencode defaults (2000px / 5 MiB base64 ≈ 3.75 MB raw) are stricter than Z.AI vision limits (≤6000×6000px, ≤5MB); override exploits the full allowance.
    — **Done when:** `attachment.image` present in shipped config with the three values.
    — **Consumers affected:** all sessions attaching images.

- [x] **1.3** Repoint vision tier: `deploy/models.default.json` `"vision": "zai-coding-plan/glm-5v-turbo"` → `"zai-custom-plan/glm-5.3-flash"`; same line in `deploy/provider-presets.json` `zai` preset (currently `zai/glm-4.6v`); update the `agent-tiers.json` `$comment` vision note (5v-turbo replaced; zai-media-subagent joins vision tier in Phase 3).
    — **Why:** the current vision default is an unverified model ID and its shipped entry lacks `attachment:true` — the documented root cause of the original vision failure; flash is the verified plan multimodal model.
    — **Done when:** `node deploy/resolve-models.mjs` output maps image-analyzer-subagent, error-resolver-subagent to `zai-custom-plan/glm-5.3-flash`.
    — **Consumers affected:** image-analyzer-subagent, error-resolver-subagent (model swap — smoke-test one image analysis in Phase 5).

- [x] **1.4** Add two MCP entries to `opencode_app/opencode.json`: `zai-web-search-prime` `{type:"remote", url:"https://api.z.ai/api/mcp/web_search_prime/mcp", headers:{Authorization:"Bearer {env:ZAI_API_KEY}"}, enabled:true}` (mirror `zai-web-reader`) and `zai-vision-mcp` `{type:"local", command:["npx","-y","@z_ai/mcp-server"], environment:{Z_AI_API_KEY:"{env:ZAI_API_KEY}", Z_AI_MODE:"ZAI"}, enabled:false}`. Update `tests/test_mcp_count_consistency.bats` auto-start assertion 2→3 (codegraph, zai-web-reader, zai-web-search-prime).
    — **Why:** plan-exclusive MCP (1.2 credits/call); search enabled matches web_reader precedent, vision shipped-but-off respects GIT-333's native-multimodal direction.
    — **Done when:** `bats tests/test_mcp_count_consistency.bats` green with the updated assertion.
    — **Consumers affected:** all sessions gain webSearchPrime auto-start; vision MCP only when opted in.

### Phase 2: Media skills (SKILL.md-recipe style, category `Media Generation`)

- [x] **2.1** Create `opencode_app/.opencode/skills/zai-video-skill/SKILL.md`: frontmatter per contract (`name: zai-video-skill`, description ≤50 words with trigger phrases "video generation / generate video / text to video", `license: Apache-2.0`, `compatibility: opencode`, `category: Media Generation`). Body: submit recipe `curl POST https://api.z.ai/api/paas/v4/videos/generations` (model `cogvideox-3`, Bearer `$ZAI_API_KEY`, returns `id`) + poll recipe `GET /paas/v4/async-result/{id}` until `task_status` success, then download; include the PTY `notifyOnExit` polling pattern (spawn `watch`/sleep-poll under pty so the agent isn't blocked).
    — **Why:** video generation is async; the submit/poll split plus PTY background polling is the only non-blocking agent pattern.
    — **Done when:** frontmatter validates against the house contract; `node deploy/build-registry.mjs` includes the skill (run before committing this step).
    — **Consumers affected:** zai-media-subagent (3.1); registry.json.

- [x] **2.2** Create `opencode_app/.opencode/skills/zai-asr-skill/SKILL.md` (same contract; category `Media Generation`): recipe `curl POST https://api.z.ai/api/paas/v4/audio/transcriptions` with `model: glm-asr-2512`, file ≤25MB ≤30s wav/mp3, `Authorization: Bearer $ZAI_API_KEY` → transcript text.
    — **Why:** opencode has no voice input path; file-based ASR covers transcription via the PAYG endpoint.
    — **Done when:** frontmatter validates; registry includes it.
    — **Consumers affected:** zai-media-subagent; registry.json.

- [x] **2.3** Create `opencode_app/.opencode/skills/zai-ocr-skill/SKILL.md` (same contract; category `Media Generation`): recipe `curl POST https://api.z.ai/api/paas/v4/layout_parsing` with `model: glm-ocr` for image/PDF layout-aware extraction.
    — **Why:** layout-aware OCR goes beyond vision-chat description; dedicated endpoint returns structured layout.
    — **Done when:** frontmatter validates; registry includes it.
    — **Consumers affected:** zai-media-subagent; registry.json.

### Phase 3: zai-media-subagent

- [x] **3.1** Create `opencode_app/.opencode/agents/zai-media-subagent.md`: house frontmatter (rich `description` with media triggers, `mode: subagent`, `permission: {bash: ask, skill: {zai-video-skill: allow, zai-asr-skill: allow, zai-ocr-skill: allow, zai-image-generation-skill: allow}}`, NO `model:` key — tier-injected). Body: media-task playbook (which skill per artifact type, endpoints, file-saving rule), the repo Return Contract, and secret rule (`$ZAI_API_KEY` env only, never echo). Add `"zai-media-subagent": "vision"` to `deploy/agent-tiers.json`.
    — **Why:** isolates large base64 payloads and key usage from primary context; vision tier routes it to the multimodal flash model via the house resolver mechanism (no hardcoded model).
    — **Done when:** `node deploy/build-registry.mjs` includes the agent; `resolve-models.mjs` resolves it to the vision tier model; run registry regen + commit in the same change as 2.1-2.3 if staged together.
    — **Consumers affected:** primary sessions (new Task delegate); agent count surfaces in Sync Rules (4.1).

- [x] **3.2** Run `node deploy/build-registry.mjs` (if not already run per-step) and the full bats suite: `tests/init.bats` (registry counts auto-derive — should stay green), `tests/skill_profiles.bats` (lean must remain exactly 30 — new skills are full-profile only), `tests/test_mcp_count_consistency.bats` (updated in 1.4). Fix any assertion drift this work introduced; do not touch pre-existing failures.
    — **Why:** release.yml runs `build-registry.mjs --check` on every PR to main/dev — an un-regenerated registry is a guaranteed red CI.
    — **Done when:** full bats suite green (or failures demonstrably pre-existing on `origin/dev`).
    — **Consumers affected:** CI; anyone running `--list` / init.

### Phase 4: Sync rules + docs

- [x] **4.1** Sync counts and listings per house Sync Rules: `deploy/setup.sh` + `deploy/setup.ps1` (skill count 87→90 wherever hardcoded incl. line ~346 banner "full = shipped 87 verbatim"→90, Media Generation category listing, agent count + help-text listing + zai-media-subagent), `README.md` (Skill Categories + Subagents tables), `opencode_app/README.md` (only if Docker-relevant surfaces list skills/agents).
    — **Why:** doc-consistency bats tests and the deploy banners hard-assert these counts; drift = broken tests and lying docs.
    — **Done when:** `grep -rn "87" deploy/setup.sh deploy/setup.ps1` shows no stale skill-count usages; doc-consistency bats green.
    — **Consumers affected:** deploy flow, README readers.

- [x] **4.2** Document the deploy-time personal settings in `MIGRATION.md` (or README deploy section): after `setup.sh`, optionally add `"small_model": "zai-custom-plan/glm-5.3-flash"` to `~/.config/opencode/opencode.json` (resolver doesn't ship small_model); and the vision fallback note — if the coding-plan endpoint ever rejects image parts, point the vision tier at the PAYG model (`zai/glm-5.3-flash`) via `models.json` instead of config surgery.
    — **Why:** the issue's small_model + fallback provisions map to deploy-time personal config in this repo's mechanism, not shipped defaults.
    — **Done when:** section present with both notes.
    — **Consumers affected:** deploy users.

### Phase 5: Deploy + end-to-end verification

- [x] **5.1** Deploy to global (`./deploy/setup.sh` with current profile flags) and verify: `opencode debug config` shows `zai-custom-plan` (both models), `attachment.image` overrides, new MCP entries; `/models` lists `zai-custom-plan/glm-5.3` and `glm-5.3-flash`.
    — **Why:** the repo deploys; source-only edits prove nothing until the deployed config parses in a real session.
    — **Done when:** debug config output shows all three surfaces; no provider-load errors.
    — **Consumers affected:** user's global opencode (the point of the ticket).

- [x] **5.2** Smoke-test the vision path end-to-end: attach a screenshot in a session on `zai-custom-plan/glm-5.3-flash` and confirm correct description; run one ASR + one OCR recipe from the new skills against a real sample file (video submit optional — billable; at minimum verify submit returns an `id` then cancel/ignore). Delegation check: one Task call to `zai-media-subagent` exercising a skill.
    — **Why:** image-attach-on-flash was the original failure; skills and subagent are unproven until exercised; cheap tests first, billable video last.
    — **Done when:** screenshot described correctly; transcript + OCR output returned; subagent delegation completes with Return Contract fields.
    — **Consumers affected:** none (verification gate).

---

## Technical Notes

- Endpoints (Z.AI docs, fetched 2026-08-30): coding plan chat `https://api.z.ai/api/coding/paas/v4`; PAYG media base `https://api.z.ai/api/paas/v4` — videos/generations (cogvideox-3, async) + async-result/{id}; audio/transcriptions (glm-asr-2512, ≤25MB, ≤30s, wav/mp3); layout_parsing (glm-ocr). MCP: web_search_prime + web_reader remote (Bearer), vision local `npx -y @z_ai/mcp-server` (Z_AI_API_KEY, Z_AI_MODE=ZAI), 1.2 credits/call.
- Key hygiene: `{env:ZAI_API_KEY}` in shipped config; skills read `$ZAI_API_KEY`; nothing hardcodes or echoes the key. Vibeguard masks `.env` secrets — keep key in `.env`/process env.
- GLM Coding Plan ToS: opencode is on the supported-tools list; plan endpoint covers chat (incl. multimodal flash) only — media skills intentionally use PAYG endpoints.
- `glm-5v-turbo` and `glm-5-turbo` are models.dev catalog entries absent from Z.AI's official enums (unverified server-side). This plan removes 5v-turbo from the vision path; `glm-5-turbo` (fast tier) is left as-is — out of scope.
- `glm-4.7` on the coding plan auto-routes server-side to glm-5.3-flash; docs tier keeps working.

## Dependencies

- `ZAI_API_KEY` present in the deploy environment (user-level `.env`/process env) for Phase 5 verification and all skill runtimes.
- Blocked-by: none. Related: GIT-333 (lean/profile + MCP opt-in direction this plan follows).

## Risks & Mitigation

| Risk | Mitigation |
|------|------------|
| Coding-plan endpoint rejects image parts on flash (multimodal-on-plan is docs-verified but untested here) | Phase 5.2 gate; fallback = vision tier → `zai/glm-5.3-flash` via models.json (4.2 documents it) |
| Vision tier swap degrades image-analyzer / error-resolver | Same-model-family swap to the verified multimodal flagship; 5.2 smoke-tests analysis; `glm-5v-turbo` entry stays in `zai-coding-plan` block as rollback |
| MCP auto-start +1 raises baseline context | web_search_prime is one tool description; GIT-333 accepted the same trade for web_reader |
| Billable media endpoints (video $0.2/video, MCP 1.2 credits/call) | Skills document costs; video smoke test is submit-only and optional |
| Registry/CI drift | Regen + `--check` gates in 2.x/3.x Done-whens; 3.2 runs full bats before docs phase |

## Success Metrics

- `opencode debug config` + `/models` show the custom provider with both models; vision attach works on flash (the original failure is fixed).
- Lean profile still 30; full 90; auto-start MCP 3; all bats suites green; `build-registry.mjs --check` passes CI.
- `zai-media-subagent` delegation completes a media task end-to-end without touching primary context.
