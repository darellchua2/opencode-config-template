# markitdown-local-mcp

Privacy-hardened MCP wrapper around [microsoft/markitdown](https://github.com/microsoft/markitdown). Local-only document converters, stdio-only transport, no cloud or telemetry paths.

## Why this exists

The upstream [`markitdown-mcp`](https://pypi.org/project/markitdown-mcp/) PyPI package depends on `markitdown[all]`, which pre-installs cloud-capable converter libraries:

- `azure-ai-documentintelligence` (sends full document bytes to Azure)
- `azure-ai-contentunderstanding` (sends full document bytes to Azure)
- `SpeechRecognition` (hard-coded call to Google Speech API)
- `youtube-transcript-api` (contacts YouTube)

These extras are dormant unless explicitly configured at runtime, but the bytes are on disk and importable. For a privacy-sensitive deployment (e.g. company-internal documents), the right guarantee is **structural exclusion**: the libraries are not installed in the first place.

This package vendors a ~60-line MCP wrapper that depends only on the local-only markitdown extras. The upstream markitdown library itself is unchanged — we just pin which extras get pulled in.

## Trust boundary

The trust boundary is [`pyproject.toml`](pyproject.toml). It declares:

```toml
dependencies = [
  "mcp>=1.8.0,<2.0",
  "markitdown[pdf,docx,pptx,xlsx,xls,outlook]>=0.1.1,<0.2.0",
]
```

That's the complete surface. Everything else is excluded by absence.

### What's removed vs upstream

| Upstream extra                       | Purpose                          | Why excluded                                            |
| ------------------------------------ | -------------------------------- | ------------------------------------------------------- |
| `markitdown[az-doc-intel]`             | Azure Document Intelligence      | Sends full document bytes to Azure cloud endpoint       |
| `markitdown[az-content-understanding]` | Azure Content Understanding      | Sends full file bytes to Azure cloud endpoint           |
| `markitdown[audio-transcription]`      | Audio transcription             | Hard-coded call to Google Speech Recognition API        |
| `markitdown[youtube-transcription]`    | YouTube transcript fetch         | Contacts YouTube                                         |
| `markitdown[all]`                      | Superset of all extras           | Pulls in every above cloud-capable dep                  |
| `starlette` + `uvicorn` (transitive)     | `--http` / `--sse` transport modes | Network listener surface; stdio is sufficient for MCP |

### Defense-in-depth

| Control                                            | Layer                                            |
| -------------------------------------------------- | ------------------------------------------------ |
| `enable_plugins=False` constructor arg             | Runtime — authoritative                          |
| `os.environ["MARKITDOWN_ENABLE_PLUGINS"]="false"` at import | Runtime — belt-and-suspenders          |
| `pyproject.toml` excludes cloud extras             | Install — structural (strongest)                 |
| `opencode.json` sets `enabled: false`              | OpenCode — server does not start unless user opts in |
| `opencode.json` sets `"markitdown*": false`        | OpenCode — tool calls denied unless user opts in |

## Tool surface

Exactly **one** MCP tool:

```
convert_to_markdown(uri: str) -> str
```

Accepts `file:`, `data:`, `http:`, and `https:` URI schemes.

- `file:` and `data:` URIs convert entirely in-process. **Zero network calls.** (Verifiable via `ss -tnp` during conversion — see PLAN-GIT-262 Phase 5.5.)
- `http:` and `https:` URIs trigger a single `requests.get()` to fetch the resource the caller supplied. No telemetry headers, no Microsoft endpoints, no Azure SDK calls. Equivalent to built-in `webfetch` — this is user-initiated fetching, not phone-home.

## Supported formats

All converters below are **100% local** (no network calls):

| Format       | Local library                                |
| ------------ | -------------------------------------------- |
| PDF          | pdfminer.six, pdfplumber                     |
| DOCX         | mammoth, lxml                                |
| PPTX         | python-pptx                                 |
| XLSX / XLS   | openpyxl, pandas, xlrd                       |
| Outlook MSG  | olefile, extract-msg                         |
| HTML         | beautifulsoup4, markdownify                  |
| CSV / JSON / XML | stdlib / pandas                          |
| EPUB         | zipfile + html parsing                       |
| IPYNB        | nbformat                                     |
| ZIP          | zipfile (iterates contents)                  |
| Images       | local EXIF metadata only (no LLM description) |

Formats **NOT** supported (would require cloud/extra deps):

- Audio transcription (Google Speech API — excluded)
- YouTube transcripts (YouTube API — excluded)
- Azure Document Intelligence layout analysis (excluded)
- Azure Content Understanding (excluded)
- LLM-generated image descriptions (excluded — `llm_client` never passed)

## Version-pin policy

`markitdown` is pinned to `>=0.1.1,<0.2.0` (matches upstream `markitdown-mcp`'s own cap). A bump above `<0.2` is **not automatic** — it requires:

1. Re-audit of the new markitdown release for new cloud/telemetry paths
2. Update to the `Explicitly EXCLUDED` table if new extras appear
3. Update to this README's "Supported formats" table
4. Update PLAN-GIT-262 Phase 1.1 if a new converter is added to the `[pdf,docx,pptx,xlsx,xls,outlook]` extras

A new minor markitdown version could default `enable_plugins=True`, add a telemetry converter, or pull a new cloud extra. The cap is the structural guarantee that this can never happen silently.

## Install

```bash
# From repo root:
pip install --user ./opencode_app/mcp-servers/markitdown-local-mcp

# Verify:
markitdown-local-mcp --help
```

Or in a Docker build (matches `opencode_app/Dockerfile` pattern):

```dockerfile
RUN /opt/python-env/bin/pip install /app/mcp-servers/markitdown-local-mcp
```

## Security verification

Mechanical proofs (run during PLAN-GIT-262 Phase 5):

```bash
# 1. Azure SDK is structurally absent
python -c "import azure"  # must raise ModuleNotFoundError

# 2. Local file conversion makes zero TCP connections
ss -tnp  # run during a file: conversion — expect zero ESTAB connections

# 3. No Plugin converters registered at startup
python -c "from markitdown import MarkItDown; md = MarkItDown(enable_plugins=False); print([type(c).__name__ for c in md._converter_registry]); print('Plugin' in ' '.join(type(c).__name__ for c in md._converter_registry))"  # must print False
```

## Sources

- Upstream: https://github.com/microsoft/markitdown
- Upstream MCP package: https://github.com/microsoft/markitdown/tree/main/packages/markitdown-mcp
- This package's trust-boundary analysis: see `PLANS/PLAN-GIT-262.md` in this repo
