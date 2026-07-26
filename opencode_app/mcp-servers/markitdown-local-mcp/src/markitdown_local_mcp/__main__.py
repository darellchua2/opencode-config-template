"""Privacy-hardened markitdown MCP server (stdio-only).

Mirrors the upstream markitdown-mcp tool surface (single `convert_to_markdown`
tool over stdio) but with these deliberate removals — see README.md:

  - NO `--http` / `--sse` modes (eliminates starlette/uvicorn deps and any
    network-listener surface; stdio is the only transport).
  - NO cloud converters (Azure Doc Intelligence, Azure Content Understanding,
    Google Speech, YouTube, LLM image description) — the launcher constructs
    `MarkItDown()` with zero cloud kwargs, and the pyproject.toml does not
    install the cloud-capable extras in the first place.
  - `enable_plugins=False` is hard-coded (the authoritative control); the
    `MARKITDOWN_ENABLE_PLUGINS=false` env var is belt-and-suspenders only.
"""

import os

# Defense-in-depth: set the env var BEFORE importing markitdown so any module
# that consults it at import time sees the disabled state. The authoritative
# control is the `enable_plugins=False` constructor arg below.
os.environ.setdefault("MARKITDOWN_ENABLE_PLUGINS", "false")

from mcp.server.fastmcp import FastMCP

from markitdown import MarkItDown
from . import __version__


# Module-level singleton — no cloud kwargs, plugins disabled.
# Constructed once at import; MCP tool calls reuse this instance.
_md = MarkItDown(enable_plugins=False)

mcp = FastMCP("markitdown-local-mcp")


@mcp.tool()
async def convert_to_markdown(uri: str) -> str:
    """Convert a resource at the given URI to Markdown.

    Accepts file:, data:, http:, and https: URI schemes.

    Privacy characteristics:
    - file: and data: URIs are converted entirely in-process; zero network
      calls (verifiable via `ss -tnp` during conversion).
    - http: and https: URIs trigger a single requests.get() to fetch the
      resource the caller supplied. No telemetry headers, no Microsoft
      endpoints, no Azure SDK calls — equivalent to built-in webfetch.

    Supported formats (all local-only): PDF, DOCX, PPTX, XLSX, XLS, Outlook
    MSG, HTML, CSV, JSON, XML, EPUB, IPYNB, ZIP, plus image EXIF metadata.
    """
    return _md.convert(uri).markdown


def main() -> None:
    """Entry point — stdio transport only (no http/sse modes)."""
    mcp.run()


if __name__ == "__main__":
    main()
