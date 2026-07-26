# Plan: Add privacy-hardened markitdown MCP server (local-only converters, opt-in)

## Ticket Reference
- Platform: GitHub
- ID: #262
- URL: https://github.com/darellchua2/opencode-config-template/issues/262
- Branch: GIT-262

## Acceptance Criteria
- [ ] `opencode_app/mcp-servers/markitdown-local-mcp/` exists with `pyproject.toml`, `src/markitdown_local_mcp/{__main__.py,__init__.py}`, `README.md`, `LICENSE`
- [ ] `pyproject.toml` depends ONLY on `markitdown[pdf,docx,pptx,xlsx,xls,outlook]>=0.1.1` + `mcp>=1.0`; explicitly lists what's NOT included
- [ ] Launcher constructs `MarkItDown()` with no cloud kwargs (`docintel_endpoint`, `cu_endpoint`, `llm_client` all absent) and `enable_plugins=False`
- [ ] Single MCP tool `convert_to_markdown(uri: str) -> str` exposed via stdio transport
- [ ] `LICENSE` is MIT with markitdown copyright attribution (derivative work)
- [ ] `opencode_app/opencode.json` has new `markitdown` MCP entry with `enabled: false`, plus `"markitdown*": false` in `tools` block
- [ ] `deploy/setup.sh` has new `install_local_mcp_launchers()` function that runs `uv tool install --force "$APP_DIR/mcp-servers/markitdown-local-mcp"`
- [ ] `deploy/setup.ps1` mirrors the install hook for Windows parity
- [ ] `opencode_app/Dockerfile` has build-time `RUN uv tool install /app/mcp-servers/markitdown-local-mcp`
- [ ] `README.md` MCP Servers section: count `26 → 27`, add table row for `markitdown`
- [ ] `deploy/setup.sh` help text: `MCP SERVERS (26)` → `(27)`, listing updated; banner auto-start count stays at 6 (markitdown is opt-in)
- [ ] `THIRD_PARTY_LICENSES.md` updated with markitdown MIT entry
- [ ] **Security verification:** `python -c "import azure"` fails inside the launcher's isolated venv (proves Azure SDK absent)
- [ ] **Security verification:** `ss -tnp` during a local PDF conversion shows zero established TCP connections
- [ ] **Functional verification:** converting a sample PDF/DOCX/PPTX/XLSX returns valid Markdown
- [ ] `documentation-sync-workflow` skill invoked (or `opencode-tooling-subagent` delegated) to verify all counts and listings are consistent

---

## Dependency & Consumer Map

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---------------------|---------------------------|---------------------------------|-------------|
| `opencode_app/mcp-servers/markitdown-local-mcp/` (launcher) | — | `opencode_app/opencode.json`, `deploy/setup.{sh,ps1}`, `opencode_app/Dockerfile` | med — new MCP server, privacy-critical |
| `opencode_app/opencode.json` (mcp+tools entries) | Launcher exists | All OpenCode sessions (user-space + Docker); deployed to `~/.config/opencode/opencode.json` | low — additive, opt-in (`enabled: false`) |
| `deploy/setup.sh` (install hook) | Launcher exists | User-space deploy workflow | low — new function, no breaking change |
| `deploy/setup.ps1` (Windows parity) | Launcher exists | Windows deploy workflow | low — mirror of setup.sh |
| `opencode_app/Dockerfile` (build-time install) | Launcher exists | Docker standalone build | low — single RUN line |
| `README.md` (MCP table + count) | Config changes complete | Documentation readers | low — count/table sync |
| `deploy/setup.sh` help text | Config changes complete | `--help` output | low — count sync |
| `THIRD_PARTY_LICENSES.md` | — | License compliance | low — additive |

## Implementation Phases

### Phase 1: Vendor the hardened launcher

Create the vendored launcher package under `opencode_app/mcp-servers/markitdown-local-mcp/` (5 files). This is the trust boundary — it must depend ONLY on local converter libraries and construct `MarkItDown()` with zero cloud kwargs.

- [ ] **1.1** Create `pyproject.toml` with constrained deps (no `[all]`, no azure/speech/youtube)
    — **Why:** Pinning to specific local-only extras prevents the `markitdown[all]` metastate from pulling cloud SDKs (`azure-ai-documentintelligence`, `azure-ai-contentunderstanding`, `SpeechRecognition`, `youtube-transcript-api`) onto disk — the root of the privacy concern.
    — **Done when:** `pyproject.toml` declares `markitdown[pdf,docx,pptx,xlsx,xls,outlook]>=0.1.1` + `mcp>=1.0` only; a comment block lists every excluded extra by name.
    — **Consumers affected:** launcher venv (build/install), `deploy/setup.sh` install hook, Dockerfile build step.
- [ ] **1.2** Create `src/markitdown_local_mcp/__main__.py` (~60 LOC) — sanitized MCP wrapper, single tool, no cloud kwargs, `MARKITDOWN_ENABLE_PLUGINS=false` set at import
    — **Why:** The wrapper is the trust boundary — it must construct `MarkItDown()` with zero cloud kwargs and hard-disable plugins so no third-party converter can ever run.
    — **Done when:** Module exposes a single `convert_to_markdown(uri: str) -> str` tool over stdio; `MarkItDown()` is instantiated with no `docintel_endpoint`/`cu_endpoint`/`llm_client` kwargs and `enable_plugins=False`; `os.environ["MARKITDOWN_ENABLE_PLUGINS"]="false"` is set before the markitdown import.
    — **Consumers affected:** MCP runtime (all OpenCode sessions that opt in), `opencode.json` `markitdown` entry.
- [ ] **1.3** Create `src/markitdown_local_mcp/__init__.py` — version export
    — **Why:** Standard package marker + `__version__` for `uv tool install` metadata and future upgrade checks.
    — **Done when:** File exports `__version__ = "0.1.0"` and the package imports cleanly under `python -c "import markitdown_local_mcp"`.
    — **Consumers affected:** pyproject build, install hook.
- [ ] **1.4** Create `README.md` — privacy rationale, what's removed vs upstream, MIT attribution, link to upstream repo
    — **Why:** Documenting the deliberate removals gives auditors and future maintainers a clear record of why each cloud extra was excluded and where the trust boundary sits.
    — **Done when:** README covers privacy rationale, a "Removed vs upstream" table, MIT attribution, and a link to `microsoft/markitdown`.
    — **Consumers affected:** documentation readers, security reviewers.
- [ ] **1.5** Create `LICENSE` — MIT with microsoft/markitdown copyright notice (derivative work clause)
    — **Why:** markitdown is MIT-licensed; our launcher is a derivative work and must preserve the upstream copyright notice to stay license-compliant.
    — **Done when:** `LICENSE` is MIT text with microsoft/markitdown copyright attribution and a derivative-work note.
    — **Consumers affected:** license compliance, `THIRD_PARTY_LICENSES.md` sync.

### Phase 2: Register MCP in opencode config

Add the `markitdown` server to `opencode_app/opencode.json` as opt-in (`enabled: false`) and deny its tools by default.

- [ ] **2.1** Add `markitdown` entry to `opencode_app/opencode.json` `mcp` block (after `mermaid`, line 239): `type: local`, `command: ["markitdown-local-mcp"]`, env block with `MARKITDOWN_ENABLE_PLUGINS=false`, `AZURE_API_KEY=""`, `OPENAI_API_KEY=""`, `enabled: false`
    — **Why:** Registers the server as opt-in (disabled by default) so it never starts unless the user explicitly enables it; the empty API keys neutralize any ambient Azure/OpenAI env-var auto-auth.
    — **Done when:** A `markitdown` object exists in the `mcp` block after `mermaid` with `enabled: false`, the three env vars set, and valid JSON.
    — **Consumers affected:** all OpenCode sessions (user-space + Docker); deployed to `~/.config/opencode/opencode.json`.
- [ ] **2.2** Add `"markitdown*": false` to `tools` block (after `"mermaid*": true`, line 244)
    — **Why:** Even when the server is enabled, tools default to denied unless explicitly granted — defense in depth so the MCP tool isn't callable until the user opts in at the tools layer too.
    — **Done when:** `"markitdown*": false` present in the `tools` block and JSON parses.
    — **Consumers affected:** all sessions that enable the server.

### Phase 3: Deploy hooks

Wire the launcher install into user-space setup, Windows setup, and the Docker build.

- [ ] **3.1** Add `install_local_mcp_launchers()` to `deploy/setup.sh` — verifies `uv` exists, runs `uv tool install --force "$APP_DIR/mcp-servers/markitdown-local-mcp"`, logs result. Call it after config-copy step.
    — **Why:** User-space deploy must install the vendored launcher onto PATH so `markitdown-local-mcp` is invocable; `--force` ensures upgrades overwrite stale installs.
    — **Done when:** Function exists, is invoked after config copy, runs `uv tool install --force "$APP_DIR/mcp-servers/markitdown-local-mcp"`, and logs success/failure.
    — **Consumers affected:** user-space deploy workflow.
- [ ] **3.2** Mirror in `deploy/setup.ps1`
    — **Why:** Windows parity — setup.ps1 must perform the same install so Windows users get the launcher on PATH.
    — **Done when:** `deploy/setup.ps1` has an equivalent install step using `uv tool install --force`.
    — **Consumers affected:** Windows deploy workflow.
- [ ] **3.3** Add `RUN uv tool install /app/mcp-servers/markitdown-local-mcp` to `opencode_app/Dockerfile` after the opencode_app COPY step
    — **Why:** Docker standalone bakes the launcher into the image at build time so the container doesn't need network access at runtime to fetch it.
    — **Done when:** Dockerfile contains the `RUN uv tool install` line after the `COPY` of `opencode_app` and the image builds.
    — **Consumers affected:** Docker standalone build.
- [ ] **3.4** Verify `opencode_app/docker-entrypoint.sh` needs no changes (binary lands on PATH)
    — **Why:** `uv tool install` places the entry point on PATH, so the entrypoint should need no special handling — but this must be verified, not assumed.
    — **Done when:** Confirmed `markitdown-local-mcp` is on PATH inside a built container without entrypoint changes; documented if a change is actually needed.
    — **Consumers affected:** Docker runtime.

### Phase 4: Documentation sync

Update all documentation surfaces so counts and listings match the new server. Counts span README, setup.sh help text, and setup.ps1.

- [ ] **4.1** `README.md` line ~243: "26 MCP server entries" → "27 MCP server entries"; add table row `| markitdown | local (uv) | Document → Markdown conversion (opt-in) |`; update "remaining N" opt-in count (19 → 20)
    — **Why:** The MCP count and table must reflect the new server so docs match reality.
    — **Done when:** Line 243 reads "27 MCP server entries", the table has a `markitdown` row, and the "remaining N opt-in" count is updated.
    — **Consumers affected:** documentation readers.
- [ ] **4.2** `deploy/setup.sh` help text line 627: `MCP SERVERS (26):` → `(27):`; add `markitdown         Document-to-markdown (local-only, opt-in)` to the disabled/opt-in listing; auto-start count stays at 6 (markitdown is NOT in auto-start)
    — **Why:** `--help` output must show the correct count and list the new opt-in server.
    — **Done when:** Line 627 reads `MCP SERVERS (27):`, the opt-in listing includes the markitdown row, and auto-start count is unchanged.
    — **Consumers affected:** `--help` output, deploy verification.
- [ ] **4.3** `opencode_app/README.md` — add Docker note that launcher is baked into the image
    — **Why:** Docker users should know the converter is available without a separate install step.
    — **Done when:** `opencode_app/README.md` notes the markitdown launcher is installed at build time.
    — **Consumers affected:** Docker documentation readers.
- [ ] **4.4** `THIRD_PARTY_LICENSES.md` — add markitdown MIT entry
    — **Why:** License compliance requires listing all vendored third-party dependencies and their licenses.
    — **Done when:** `THIRD_PARTY_LICENSES.md` has a markitdown MIT entry with upstream attribution.
    — **Consumers affected:** license compliance.
- [ ] **4.5** Invoke `documentation-sync-workflow` skill OR delegate to `opencode-tooling-subagent` to verify cross-file consistency
    — **Why:** Counts and listings span README, setup.sh, setup.ps1, and opencode.json — a sync check catches drift that manual edits miss.
    — **Done when:** Sync verification reports zero count/listing drift across all files.
    — **Consumers affected:** all documentation surfaces.

### Phase 5: Security & functional verification

Mechanically prove the privacy guarantees (no Azure bytes, no TCP connections during local conversion) and confirm the converter works for all supported formats.

- [ ] **5.1** Run `uv tool install` locally; confirm `markitdown-local-mcp --help` works
    — **Why:** Proves the launcher installs and starts before deeper verification.
    — **Done when:** `markitdown-local-mcp --help` (or `--version`) exits 0.
    — **Consumers affected:** all downstream verification steps.
- [ ] **5.2** Send MCP `tools/list` — expect single tool `convert_to_markdown`
    — **Why:** Confirms the attack surface is exactly one tool, not the upstream's broader surface.
    — **Done when:** `tools/list` returns exactly one tool named `convert_to_markdown`.
    — **Consumers affected:** MCP consumers.
- [ ] **5.3** Convert local PDF/DOCX/PPTX/XLSX — confirm valid Markdown output
    — **Why:** Functional proof that the local-only converter set actually works for the supported formats.
    — **Done when:** Each of the four formats returns non-empty, valid Markdown.
    — **Consumers affected:** end users of the server.
- [ ] **5.4** Convert user-supplied `https:` URL — confirm fetch + conversion works (no telemetry)
    — **Why:** Verifies the allowed HTTP-fetch path works and produces output without error.
    — **Done when:** An `https:` URI converts successfully; no telemetry headers are added (confirmed via the connection inspection in 5.5).
    — **Consumers affected:** end users fetching remote docs.
- [ ] **5.5** `ss -tnp` during local conversion — assert zero established TCP connections
    — **Why:** Mechanical proof that local `file:` conversion makes no network calls — the core privacy guarantee.
    — **Done when:** `ss -tnp` (or equivalent) shows zero established TCP connections during a `file:` conversion.
    — **Consumers affected:** security verification, trust model.
- [ ] **5.6** `python -c "import azure"` in launcher venv — assert `ModuleNotFoundError`
    — **Why:** Mechanical proof that Azure SDKs are absent from the launcher's isolated environment — the bytes are not on disk.
    — **Done when:** `import azure` raises `ModuleNotFoundError` inside the launcher venv.
    — **Consumers affected:** security verification.
- [ ] **5.7** `opencode mcp list` — confirm `markitdown` shows `disabled` until user opts in
    — **Why:** Confirms the opt-in default holds end-to-end through the OpenCode runtime.
    — **Done when:** `opencode mcp list` shows `markitdown` as disabled by default.
    — **Consumers affected:** end-user opt-in flow.
