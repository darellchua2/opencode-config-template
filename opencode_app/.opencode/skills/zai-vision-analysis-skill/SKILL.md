---
name: zai-vision-analysis-skill
description: Analyze images/screenshots/PDFs via direct Z.AI vision API call using glm-5v-turbo. Two endpoints — coding-plan (auth.json key) preferred, PAAS ($ZAI_API_KEY) fallback. Use as the API fallback when native multimodal (image-analyzer-subagent) is unavailable. Triggers on image analysis, screenshot analysis, vision, describe image, OCR.
license: Apache-2.0
compatibility: opencode
category: Responsive & Visual Testing
---

## What I do

I give an agent a single ready-to-run command that calls the **Z.AI vision API directly** with
**`glm-5v-turbo`** (the same vision model the native multimodal path uses), returning the model's
text description of an image. This is the **API fallback** for when native multimodal perception is
unavailable — e.g. the `image-analyzer-subagent` runtime reports "model does not support image
input", the vision MCP server isn't connected, or a text-model agent needs image content.

The calling agent (typically a text model) runs the command with `bash`, then reasons over the
returned description.

## Why a direct API call

OpenCode routes `zai/glm-5v-turbo` through its provider catalog for native multimodal agents, but
that path can fail at runtime (provider mis-route, MCP server not connected, text-only session). A
direct Z.AI API call works regardless of the OpenCode model layer, so it is a reliable fallback.
It also serves any text-model agent that has `bash` but no image perception.

## Prerequisite — key + endpoint

The recipe auto-resolves both, preferring the coding-plan tier:

| Source | Endpoint |
|--------|----------|
| `auth.json` → `zai-coding-plan.key` (preferred) | `https://api.z.ai/api/coding/paas/v4/chat/completions` |
| `auth.json` → `zai.key`, else `$ZAI_API_KEY` | `https://api.z.ai/api/paas/v4/chat/completions` |

If neither key is found, the command exits with an error telling the caller to authenticate
(`opencode auth login` for Z.AI, or `export ZAI_API_KEY`).

## Recipe (one command — pure stdlib, no curl/ARG_MAX issues)

`$IMG` = local file path **or** a remote `https://` URL. `$PROMPT` = analysis instruction.
Large local images are auto-downscaled to 1280px max edge (JPEG q85) when Pillow is installed;
without Pillow the raw file is sent (may hit size limits on very large images).

```bash
IMG="/abs/path/to/image.png"
PROMPT="Describe this image in detail — text, UI elements, errors, layout, colors, anything actionable."

python3 - "$IMG" "$PROMPT" <<'PY'
import sys, os, json, base64, subprocess, urllib.request, urllib.error
src, prompt = sys.argv[1], (sys.argv[2] or "Describe this image in detail.")

def load_auth():
    try:
        return json.load(open(os.path.expanduser("~/.local/share/opencode/auth.json")))
    except Exception:
        return {}
auth = load_auth()
cp = (auth.get("zai-coding-plan") or {}).get("key")
zai = (auth.get("zai") or {}).get("key") or os.environ.get("ZAI_API_KEY", "")
MODEL = "glm-5v-turbo"
if cp:
    ENDPOINT, APIKEY = "https://api.z.ai/api/coding/paas/v4/chat/completions", cp
elif zai:
    ENDPOINT, APIKEY = "https://api.z.ai/api/paas/v4/chat/completions", zai
else:
    sys.exit("ERROR: no Z.AI key — run `opencode auth login` (Z.AI) or export ZAI_API_KEY")

def img_url(src):
    if src.startswith("http"):
        return src
    try:
        from PIL import Image; import io
        im = Image.open(src).convert("RGB"); w, h = im.size
        if max(w, h) > 1280:
            im = im.resize((int(w*1280/max(w,h)), int(h*1280/max(w,h))), Image.LANCZOS)
        buf = io.BytesIO(); im.save(buf, "JPEG", quality=85)
        return "data:image/jpeg;base64,%s" % base64.b64encode(buf.getvalue()).decode()
    except ImportError:
        mime = subprocess.check_output(["file","-b","--mime-type",src]).decode().strip() or "image/png"
        with open(src,"rb") as f: return "data:%s;base64,%s" % (mime, base64.b64encode(f.read()).decode())

payload = json.dumps({"model": MODEL, "messages": [{"role": "user", "content": [
    {"type": "text", "text": prompt},
    {"type": "image_url", "image_url": {"url": img_url(src)}}]}]}).encode()
req = urllib.request.Request(ENDPOINT, data=payload, headers={
    "Authorization": "Bearer " + APIKEY, "Content-Type": "application/json"})
try:
    with urllib.request.urlopen(req, timeout=120) as r:
        print(json.loads(r.read())["choices"][0]["message"]["content"])
except urllib.error.HTTPError as e:
    sys.exit("HTTP %d: %s" % (e.code, e.read().decode()[:500]))
PY
```

The description is printed to stdout (`choices[0].message.content`).

## Error handling

| Condition | Detect | Action |
|-----------|--------|--------|
| No key (auth.json + env both empty) | command exits `ERROR: no Z.AI key` | Tell caller to `opencode auth login` (Z.AI) or `export ZAI_API_KEY` |
| HTTP error / API error | exit prints `HTTP <code>: <body>` | Report `Status: failed` + the message; for 413/timeout, ensure Pillow downscaling ran or downscale manually and retry |
| Service overloaded (Z.AI code 1305) | error body contains `1305` | Image too large or transient — downscale (Pillow) and retry once |
| Empty/invalid image | `file` reports non-image | Report path + detected type; ask for a valid image |
| Rate limited (429) | HTTP 429 | Wait and retry once; otherwise report |

## Choosing a different model

`glm-5v-turbo` is the default (same model as the native multimodal path, best quality). To cut
cost, set `MODEL = "glm-4.6v"` (cheaper, $0.30/$0.90) in the recipe. The free `glm-4.6v-flash` is
available but rate-limits frequently — use only when cost is the hard constraint.

## Caller contract

Return the vision model's text description (stdout) to the calling agent, which interprets it.
Do not echo the base64, the API key, or the full JSON — return only the printed content.
