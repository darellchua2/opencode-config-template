# Can we reach Z.AI `glm-5v-turbo` (vision) via OpenCode using Z.AI coding-plan access?

> Research date: 2026-08-03 · Investigator: autonomous web-research agent (Tier 2, web-only).
> All fetched content treated as untrusted data; no fabricated IDs/endpoints/prices — unknowns
> are marked `[UNVERIFIED]`. Every claim cites a fetched URL.
>
> NOTE: requested filename `research/zai-glm-5v-turbo-opencode-access.md` was blocked by
> path-restricted edit permissions (filename must match `research*.md`); written here instead.

---

## 1. Executive answer

**Conditional — and the condition is NOT bypassable with coding-plan credentials alone.**

`glm-5v-turbo` is fully reachable through OpenCode, but **only via the standard pay-as-you-go Z.AI
API** (endpoint `https://api.z.ai/api/paas/v4`, Bearer API key). It is **already listed natively**
on the OpenCode/`models.dev` `zai` provider, so selecting it requires no shim, no custom code, and no
proxy — just a *standard* Z.AI API key and `/connect` → **Z.AI** (not "Z.AI Coding Plan").

The reason OpenCode reports it "not supported" for you is that you are on the **`zai-coding-plan`**
provider (your primary model `zai-coding-plan/glm-5.2`). The `zai-coding-plan` provider catalog —
sourced from `models.dev` — contains **exactly four text/coding models** and explicitly excludes
`glm-5v-turbo`. The GLM Coding Plan subscription routes *vision* to a separate **GLM-4.6V MCP
server**, not to `glm-5v-turbo`, and its dedicated endpoint (`/api/coding/paas/v4`) is "strictly
limited to use within officially supported tools." So the coding-plan credential cannot authorize
`glm-5v-turbo`; reaching it requires a separate pay-as-you-go key.

---

## 2. Root cause of "not supported" — exact mechanism

It is a **provider-catalog / models.dev data** issue, **not** an OpenCode-side vision filter and
**not** an auth-capability rejection at selection time. Evidence chain:

1. **OpenCode builds its entire provider/model catalog from `models.dev`.**
   OpenCode docs: *"OpenCode uses the AI SDK and Models.dev to support 75+ LLM providers."*
   (https://opencode.ai/docs/providers). Source proof in
   `packages/opencode/src/provider/provider.ts`
   (https://raw.githubusercontent.com/anomalyco/opencode/dev/packages/opencode/src/provider/provider.ts):
   the provider layer runs `const modelsDev = yield* modelsDevSvc.get()` then
   `const catalog = mapValues(modelsDev, fromModelsDevProvider)` — i.e. every provider and its model
   list is derived from the `@opencode-ai/models` (models.dev) snapshot. The `custom()` loader map in
   the same file contains entries for `anthropic`, `openai`, `azure`, `amazon-bedrock`, `gitlab`,
   `cloudflare-*`, `snowflake-cortex`, `openrouter`, `nvidia`, etc. — **but no `zai` or
   `zai-coding-plan` entry**. That means both Z.AI providers are plain catalog providers straight from
   models.dev (no OpenCode-specific filter applied to them).

2. **`models.dev` defines `zai` and `zai-coding-plan` as two distinct providers.**
   - `zai` — API `https://api.z.ai/api/paas/v4`, package `@ai-sdk/openai-compatible`, **14 models
     including `glm-5v-turbo`** ($1.20 / $4.00, marked "Provider-specific").
     (https://models.dev/providers/zai)
   - `zai-coding-plan` — API `https://api.z.ai/api/coding/paas/v4`, package
     `@ai-sdk/openai-compatible`, **only 4 models**: `glm-4.7`, `glm-5-turbo`, `glm-5.2`,
     `glm-5.2-highspeed` (all $0.00, subscription). **No `glm-5v-turbo`.**
     (https://models.dev/providers/zai-coding-plan)

3. **Therefore OpenCode cannot offer `zai-coding-plan/glm-5v-turbo`.** When you ask for a model not
   in the provider's catalog, OpenCode throws `ModelNotFoundError: Model not found:
   zai-coding-plan/glm-5v-turbo` (see the `ModelNotFoundError` class in `provider.ts`, whose message
   is exactly *"Model not found: {providerID}/{modelID}"*). This is the "not supported" surface. It
   is a catalog-membership failure, not a capability/auth check.

4. **Why models.dev omits it from the coding plan** mirrors Z.AI's own product split: the GLM Coding
   Plan's vision path is the **Vision MCP Server using GLM-4.6V**
   (https://docs.z.ai/devpack/quick-start → "Vision MCP Server (Coding Plan Exclusive)": *"employs
   the flagship vision reasoning model GLM-4.6V to comprehend and analyze image content"*). `glm-5v-turbo`
   is a **standard pay-as-you-go API model** documented at
   https://docs.z.ai/guides/vlm/glm-5v-turbo against the standard endpoint, with no coding-plan
   mention anywhere. So the models.dev data accurately reflects Z.AI's product boundary.

**One-line root cause:** *`glm-5v-turbo` is not in the `zai-coding-plan` provider's models.dev model
list (only 4 coding models are), so OpenCode's catalog-driven `getModel()` rejects it; the model is
natively present only on the separate `zai` (standard pay-as-you-go) provider.*

---

## 3. Z.AI `glm-5v-turbo` API facts

Source: https://docs.z.ai/guides/vlm/glm-5v-turbo (Z.AI official guide).

| Fact | Value |
|---|---|
| Model ID | `glm-5v-turbo` |
| Standard endpoint | `https://api.z.ai/api/paas/v4/chat/completions` |
| Auth header | `Authorization: Bearer <API_KEY>` |
| Protocol | OpenAI-compatible chat completions |
| Multimodal input | OpenAI-style `content` array: `{"type":"image_url","image_url":{"url":"..."}}` + `{"type":"text","text":"..."}` (also accepts video/files) |
| Output | Text only |
| Context / max output | 200,000 / ~131,072 tokens |
| Extra params | `thinking: {"type":"enabled"}`, streaming (`stream:true`), function/tool calling |
| Pricing (Z.AI standard, via models.dev `zai`) | **$1.20 / $4.00** per 1M (input/output) — https://models.dev/providers/zai |
| Pricing (Zhipu bigmodel.cn `zhipuai`) | $5.00 / $22.00 — https://models.dev/providers/zhipuai |

Notes:
- The exact Z.AI-published list price on the Z.AI pricing page was not separately fetched; the
  `$1.20/$4.00` figure is models.dev's recorded value for the `zai` provider `[VERIFY on
  https://docs.z.ai/guides/overview/pricing if billing-critical]`.
- **No `X-Title` header** appears in any official Z.AI example. `X-Title` is an **OpenRouter-style**
  client-identification header (see §4/§5). Z.AI does not require it.

---

## 4. Auth: coding-plan vs API key — does `ZAI_API_KEY` authorize `glm-5v-turbo`?

This is the feasibility crux. Two credential classes exist, with **different endpoints and scopes**:

| Credential | Where obtained | Endpoint(s) | Serves `glm-5v-turbo`? |
|---|---|---|---|
| **GLM Coding Plan key** | "Individual Coding Plan > Plan Overview" / "Team Coding Plan > My Plan" (https://docs.z.ai/devpack/quick-start) | `https://api.z.ai/api/coding/paas/v4` (OpenAI) · `https://api.z.ai/api/anthropic` (Anthropic) | **No** — only 4 coding models; vision via GLM-4.6V MCP |
| **Standard API key** (pay-as-you-go) | "API Keys" management page, requires billing top-up (https://docs.z.ai Quick Start) | `https://api.z.ai/api/paas/v4` (and `/v4/...`) | **Yes** — `glm-5v-turbo` ($1.20/$4.00) |

Key supporting facts:
- Z.AI states the coding plan is **"strictly limited to use within officially supported tools and
  products"** and that **"The Team Plan Key is not interchangeable with other Z.AI's API Keys"**
  (https://docs.z.ai/devpack/quick-start). This confirms coding-plan keys are **scoped** and not
  equivalent to standard API keys.
- The `glm-5v-turbo` guide only ever shows the **standard** endpoint `/api/paas/v4` with a generic
  API key — it is never referenced inside the `/devpack/` (coding-plan) docs.

**About `ZAI_API_KEY`:** In this repo, `ZAI_API_KEY` is the env var the `zai-vision-analysis-skill`
uses to call the **free `glm-4.6v-flash`** model *directly* against the standard API — explicitly
because that free flash SKU *"is not in models.dev, so it is reachable only via this direct API call
(not the `zai` provider)"* (per repo `AGENTS.md`). Since the free flash lives on the **standard**
`/api/paas/v4` endpoint, the skill's documented behavior implies **`ZAI_API_KEY` is a standard
pay-as-you-go key**, not a coding-plan key.

**Conclusion:**
- A **coding-plan** credential → **cannot** reach `glm-5v-turbo`. (Two independent blockers: the
  OpenCode catalog has no such model under `zai-coding-plan`, and the `/api/coding/paas/v4` endpoint
  does not serve it.)
- A **standard pay-as-you-go** key → **can** reach `glm-5v-turbo`, natively, no shim.
- If your existing `ZAI_API_KEY` is the standard key used by the skill, **you already have what you
  need** `[UNVERIFIED for your specific key — confirm in the Z.AI console whether the key is listed
  under "API Keys" (standard) vs "Coding Plan"]`. If it is the coding-plan key, you must create a
  separate standard API key and add pay-as-you-go credit.

---

## 5. Three bypass approaches ranked

### (A) Use the built-in `zai` (standard) provider — **RECOMMENDED, viability: high, effort: trivial**

Because `glm-5v-turbo` is **already in the `zai` provider's models.dev catalog**
(https://models.dev/providers/zai), there is nothing to "bypass." You simply connect the standard
provider alongside your coding plan:

1. `opencode auth login` → select **Z.AI** (the standard entry, *not* "Z.AI Coding Plan").
2. Paste a **standard pay-as-you-go** Z.AI API key.
3. `/models` → select **`zai/glm-5v-turbo`**.

This coexists with your existing `zai-coding-plan` credential (both are stored in
`~/.local/share/opencode/auth.json`). No custom config required.

*Optional* — if you prefer to pin the key/endpoint in config (or alias the provider) instead of
`/connect`, a custom `@ai-sdk/openai-compatible` provider works (this is the exact mechanism the
repo's existing `lmstudio` provider and OpenCode's `ollama`/`Atomic Chat`/`Helicone` examples use;
the package is bundled in `provider.ts` `BUNDLED_PROVIDERS["@ai-sdk/openai-compatible"]`):

```jsonc
// opencode.json
{
  "$schema": "https://opencode.ai/config.json",
  "provider": {
    "zai-vision": {
      "npm": "@ai-sdk/openai-compatible",
      "name": "Z.AI Vision (glm-5v-turbo, pay-as-you-go)",
      "options": {
        "baseURL": "https://api.z.ai/api/paas/v4"
      },
      "models": {
        "glm-5v-turbo": { "name": "GLM-5V-Turbo" }
      }
    }
  }
}
```
The API key for a custom provider is supplied the same way as any provider (via the `env`/auth flow
or `/connect` if keyed to a known provider). `[VERIFY the exact inline-key option for arbitrary
custom provider IDs — the OpenCode docs only show `options.baseURL`/`options.headers` for custom
providers, not `options.apiKey`; the reliable path is `/connect` → Z.AI.]`

Limitations: requires a **standard** key + pay-as-you-go credit; bills per-token ($1.20/$4.00).

### (B) Local OpenAI-compatible proxy/shim (the `X-Title: "4.5V MCP Local"` idea) — viability: medium, effort: medium

A tiny local server that accepts OpenAI-shaped `/v1/chat/completions` calls, attaches
`Authorization: Bearer $ZAI_API_KEY`, forwards to `https://api.z.ai/api/paas/v4/chat/completions`,
and streams the response back. Point an `@ai-sdk/openai-compatible` provider at it:

```jsonc
{
  "$schema": "https://opencode.ai/config.json",
  "provider": {
    "zai-proxy": {
      "npm": "@ai-sdk/openai-compatible",
      "name": "Z.AI via local proxy",
      "options": { "baseURL": "http://127.0.0.1:8787/v1" },
      "models": { "glm-5v-turbo": { "name": "GLM-5V-Turbo" } }
    }
  }
}
```
Pros: lets you inject custom headers, log traffic, or share one key across tools. Cons: strictly
**more** moving parts than (A) with no added capability for this model — (A) already does
everything the shim would do, natively.

**About `X-Title`:** It is **not a Z.AI requirement.** In OpenCode's own source (`provider.ts`) and
docs, `X-Title` is the OpenRouter-style client-identification header sent to gateway/aggregator
providers — `openrouter`, `llmgateway`, `nvidia`, `vercel`, `kilo`, and `zenmux` all set
`"X-Title": "opencode"`. Z.AI's own `glm-5v-turbo` examples never include it. The snippet's
`X-Title: "4.5V MCP Local"` is simply the shim naming itself (OpenRouter convention); it is
harmless but unnecessary against Z.AI's API.

### (C) Extend `zai-vision-analysis-skill` to also call `glm-5v-turbo` — viability: high, effort: low, BUT limited role

Add a `model` parameter to the skill (default `glm-4.6v-flash`, allow `glm-5v-turbo`) so it issues
the same direct-API call pattern against `/api/paas/v4` with a standard key. Cheapest change if you
only need **occasional image analysis as a tool**.

**Critical limitation:** a skill is a **one-shot tool invocation**, not a **model provider**. The
agent cannot use `glm-5v-turbo` as its *reasoning loop* (it can't be the `model` the session runs
on). It can only be *called by* the running agent to inspect an image and return text. If your goal
is "run the agent itself on glm-5v-turbo," you need (A), not (C).

**Ranking:** **(A) > (C) > (B).** (A) is native, zero-config, and gives full provider semantics;
(C) is the right pick only for tool-style vision; (B) is unnecessary for this model.

---

## 6. Recommended path

**Use (A): connect the standard `zai` provider with a pay-as-you-go key and select
`zai/glm-5v-turbo`.** It is the only approach that (i) requires no custom code, (ii) is natively
supported by OpenCode's models.dev catalog, and (iii) lets glm-5v-turbo serve as the agent's
reasoning model.

Concrete next step:
1. In the Z.AI console (https://z.ai/manage-apikey/apikey-list), confirm you have a **standard** API
   key (not the coding-plan key) and that pay-as-you-go credit is topped up.
2. `opencode auth login` → **Z.AI** (standard) → paste the standard key.
3. `/models` → `zai/glm-5v-turbo`.

Keep the `zai-coding-plan` provider for your `glm-5.2` coding work; the two providers coexist.
If you only need vision as an occasional tool and want to reuse the existing flash-based skill,
extend the skill per (C) with a `model` switch instead.

---

## 7. models.dev contribution option

models.dev is open-source: repo **https://github.com/sst/models.dev** (also redirected from
`anomalyco/models.dev`), "data is stored in GitHub as TOML files organized by provider and canonical
model" (https://models.dev/providers/zai footer).

- For the **`zai`** provider: **not needed** — `glm-5v-turbo` is already listed.
- For the **`zai-coding-plan`** provider: you *could* PR to add `glm-5v-turbo` to its TOML, but it is
  **futile and counterproductive** — even if OpenCode then offered `zai-coding-plan/glm-5v-turbo` in
  the picker, the `/api/coding/paas/v4` endpoint would reject the call (the coding-plan subscription
  does not grant that model). You'd get a runtime 4xx instead of a clean "model not found." Do not do
  this.

So the upstream path does not solve the problem; the standard `zai` provider already carries the
model.

---

## 8. Open questions / `[UNVERIFIED]` items to test empirically

1. **Is your `ZAI_API_KEY` a standard or coding-plan key?** Check the Z.AI console listing. The skill's
   documented use of the free flash strongly implies standard, but confirm. *(Decides whether step 1
   of §6 is even needed.)*
2. **Exact Z.AI list price** for `glm-5v-turbo` on the standard API. models.dev `zai` records
   $1.20/$4.00; verify on https://docs.z.ai/guides/overview/pricing before budgeting.
3. **Mechanism of the coding-plan "supported tools only" enforcement** — likely server-side client
   identification (User-Agent / a tool header) on `/api/coding/paas/v4`. `[UNVERIFIED]`. Irrelevant
   to the recommended path (standard API), but relevant if anyone tries to force coding-plan traffic
   at vision models.
4. **Whether a coding-plan key returns a clean error** if pointed at `/api/paas/v4` or at
   `glm-5v-turbo`. Expect a 401/403/404; not tested here.
5. **Inline `options.apiKey` for arbitrary custom provider IDs** in `opencode.json` (used in §5A
   custom variant). The docs only confirm `options.baseURL`/`options.headers`; verify before relying
   on a config-only custom provider (otherwise use `/connect`).
6. **Multimodal attachment plumbing**: confirm OpenCode's image-attachment path sends the
   `content` array shape Z.AI expects (the `glm-5v-turbo` guide confirms Z.AI accepts the standard
   OpenAI multimodal array, so this should "just work" once the provider is connected).

---

## 9. References (every URL fetched + what it confirmed)

- **https://models.dev** (homepage) — GLM model families exist under lab `zhipuai`; GLM-5V-Turbo is a
  real canonical model.
- **https://models.dev/providers/zai-coding-plan** — **decisive**: `zai-coding-plan` provider has
  exactly 4 models (`glm-4.7`, `glm-5-turbo`, `glm-5.2`, `glm-5.2-highspeed`), endpoint
  `https://api.z.ai/api/coding/paas/v4`, no `glm-5v-turbo`. → root cause of "not supported".
- **https://models.dev/providers/zai** — standard `zai` provider, endpoint
  `https://api.z.ai/api/paas/v4`, **includes `glm-5v-turbo`** ($1.20/$4.00). → the native solution.
- **https://models.dev/providers/zhipuai** — Zhipu/bigmodel.cn provider; also lists `glm-5v-turbo`
  ($5.00/$22.00) at `https://open.bigmodel.cn/api/paas/v4` (separate from Z.AI international).
- **https://models.dev/models/zhipuai/glm-5v-turbo** — model page: 7 aggregator providers; specs
  (200K ctx, tools/reasoning/temperature).
- **https://docs.z.ai** (Quick Start) — standard endpoint
  `https://api.z.ai/api/paas/v4/chat/completions`, OpenAI-SDK compatibility
  (`base_url=https://api.z.ai/api/paas/v4/`); warning that GLM Coding Plan uses a **dedicated
  endpoint**.
- **https://docs.z.ai/devpack/quick-start** — coding-plan endpoints
  (`/api/anthropic`, `/api/coding/paas/v4`); **"strictly limited to officially supported tools"**;
  Team Plan key **"not interchangeable"** with other API keys; coding-plan vision = **Vision MCP
  Server (GLM-4.6V)**, not glm-5v-turbo.
- **https://docs.z.ai/devpack/tool/opencode** — official OpenCode coding-plan wiring via
  `opencode auth login` → "Z.AI Coding Plan"; `/models` to pick GLM models; vision via the MCP
  servers.
- **https://docs.z.ai/guides/vlm/glm-5v-turbo** — model ID `glm-5v-turbo`; standard endpoint; OpenAI
  multimodal `content` array; `thinking`, streaming, tool-calling; 200K context. No `X-Title`.
- **https://opencode.ai/docs/providers** — "OpenCode uses the AI SDK and Models.dev"; `baseURL`
  override, `blacklist`/`whitelist`; custom-provider pattern (`"npm":"@ai-sdk/openai-compatible"` +
  `options.baseURL` + `models` map) via LM Studio / Ollama / llama.cpp / Atomic Chat / Helicone
  examples; `options.headers` for custom headers.
- **https://opencode.ai/docs/models** — model IDs are `provider_id/model_id`; built-in names "can be
  found on Models.dev"; model-loading priority.
- **https://raw.githubusercontent.com/anomalyco/opencode/dev/packages/opencode/src/provider/provider.ts**
  — source proof: catalog = `mapValues(modelsDev, fromModelsDevProvider)`; `ModelNotFoundError`
  message = `"Model not found: {providerID}/{modelID}"`; `@ai-sdk/openai-compatible` bundled; `X-Title:
  "opencode"` set for openrouter/llmgateway/nvidia/vercel/kilo/zenmux (OpenRouter convention); no
  `zai`/`zai-coding-plan` custom loader (so they are pure catalog providers).
- **https://api.github.com/repos/anomalyco/opencode/contents/packages/opencode/src/provider** —
  located `provider.ts` as the provider-definition file.
- **https://github.com/sst/opencode** & **https://github.com/anomalyco/opencode** — confirmed
  canonical org (`anomalyco/opencode`, `sst/opencode` redirects there).
- **https://github.com/sst/models.dev** — models.dev source (TOML per provider/model); PR target for
  catalog changes.
