---
name: zai-vision-analysis-skill
description: Analyze images/screenshots/PDFs by calling the Z.AI vision API directly (free glm-4.6v-flash). Bypasses the OpenCode provider catalog (models.dev) so the free vision model is usable. Use when an agent needs image/screenshot content but runs on a text model. Triggers on image analysis, screenshot analysis, vision, describe image, OCR, diagram understanding.
license: Apache-2.0
compatibility: opencode
metadata:
  audience: agents
  workflow: vision
  requires: ZAI_API_KEY
---

## What I do

I provide the exact recipe for an agent to obtain **image/screenshot content** by calling the
**Z.AI vision API directly**, using the **free `glm-4.6v-flash`** model. This bypasses the
OpenCode provider/model catalog (models.dev), which does not list `glm-4.6v-flash` — so the
free vision model is reachable only via this direct HTTP call. The calling agent (a text model)
executes the call with its `bash` tool, then interprets the returned text description.

## Why a direct API call

OpenCode resolves provider models from models.dev, and the `zai` provider does not expose
`glm-4.6v-flash` (only paid `glm-4.6v`, `glm-4.5v`, `glm-5v-turbo`). A direct call to the Z.AI
OpenAI-compatible endpoint serves `glm-4.6v-flash` (free) regardless, so this is the only way to
get **free** vision. Paid models (`glm-4.6v`, `glm-5v-turbo`) can be substituted in the recipe if
explicitly requested.

## Prerequisite

- `ZAI_API_KEY` environment variable must be set. If empty/missing, **stop and report**:
  "ZAI_API_KEY is not set — authenticate via `opencode auth login` (Z.AI) or export ZAI_API_KEY."

## Recipe

Set two shell variables and run the curl. The `python3` helper takes the image source and
prompt as **arguments** (no `export` needed) and reads + base64-encodes the image **itself**, so
large images never round-trip through the shell (avoids `ARG_MAX` limits and `base64 -w0`
portability issues):

```bash
IMG="/abs/path/to/image.png"     # OR a remote URL: IMG="https://example.com/img.png"
PROMPT="Describe this image in detail — text, UI elements, errors, layout, colors, anything actionable."

curl -sS --max-time 120 -X POST "https://api.z.ai/api/paas/v4/chat/completions" \
  -H "Authorization: Bearer $ZAI_API_KEY" \
  -H "Content-Type: application/json" \
  -d "$(python3 -c '
import json, sys, base64, subprocess
src = sys.argv[1]
prompt = (sys.argv[2] if len(sys.argv) > 2 else "") or "Describe this image in detail."
if src.startswith("http"):
    img = src
else:
    mime = subprocess.check_output(["file", "-b", "--mime-type", src]).decode().strip() or "image/png"
    with open(src, "rb") as f:
        img = "data:%s;base64,%s" % (mime, base64.b64encode(f.read()).decode())
print(json.dumps({"model": "glm-4.6v-flash", "messages": [{"role": "user", "content": [
    {"type": "text", "text": prompt},
    {"type": "image_url", "image_url": {"url": img}}]}]}))
' "$IMG" "$PROMPT")"
```

- `$IMG` — a **local file path** OR a remote `http(s)://` URL (the helper auto-detects).
- `$PROMPT` — optional; defaults to a detailed description.
- For very large images (>10 MB), downscale first to avoid request-size limits.

### 3. Parse the response

The description is at `choices[0].message.content`:
```bash
# pipe the curl output:
... | python3 -c 'import sys,json; print(json.load(sys.stdin)["choices"][0]["message"]["content"])'
```

## Error handling

| Condition | Detect | Action |
|-----------|--------|--------|
| Missing `ZAI_API_KEY` | `[ -z "$ZAI_API_KEY" ]` | Stop; tell caller to auth (`opencode auth login` Z.AI or export `ZAI_API_KEY`) |
| HTTP non-200 / API error | response has `"error"` or curl exit != 0 | Print the error body; report `Status: failed` with the message |
| Empty/invalid image | `file` reports non-image, or base64 empty | Report path + detected type; ask for a valid image |
| Oversized payload | curl/HTTP 413 or timeout | Downscale the image and retry once |
| Rate limited (429) | HTTP 429 | Wait and retry once; otherwise report |

## Using a paid model instead (explicit request only)

Substitute `"model"` with a models.dev-valid `zai` vision model — `glm-4.6v` (cheapest, $0.30/$0.90)
or `glm-5v-turbo` ($1.20/$4.00) — only when the caller explicitly requests the paid path. The
default remains free `glm-4.6v-flash`.

## Caller contract

After executing the recipe, return the vision model's text description to the calling agent, which
interprets/reasons over it (the calling agent is a text model and cannot see the image directly).
Do not echo the raw base64 or the full JSON response — return only `choices[0].message.content`.
