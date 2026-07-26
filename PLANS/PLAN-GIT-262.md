# Plan: Add privacy-hardened markitdown MCP server (local-only converters, opt-in)

## Ticket Reference
- Platform: GitHub
- ID: #262
- URL: https://github.com/darellchua2/opencode-config-template/issues/262
- Branch: GIT-262

## Acceptance Criteria
- [ ] `opencode_app/mcp-servers/markitdown-local-mcp/` exists with `pyproject.toml`, `src/markitdown_local_mcp/{__main__.py,__init__.py}`, `README.md`, `LICENSE`
- [ ] `pyproject.toml` depends ONLY on `markitdown[pdf,docx,pptx,xlsx,xls,outlook]>=0.1.1,<0.2` + `mcp>=1.0`; explicitly lists what's NOT included (version cap prevents trust-boundary bypass on future bump)
- [ ] Launcher constructs `MarkItDown()` with no cloud kwargs (`docintel_endpoint`, `cu_endpoint`, `llm_client` all absent) and `enable_plugins=False` (constructor arg, not env var)
- [ ] Single MCP tool `convert_to_markdown(uri: str) -> str` exposed via stdio transport
- [ ] `LICENSE` is MIT with markitdown copyright attribution (derivative work)
- [ ] `opencode_app/opencode.json` has new `markitdown` MCP entry with `enabled: false`, plus `"markitdown*": false` in `tools` block (env block contains ONLY `MARKITDOWN_ENABLE_PLUGINS=false` — no empty-string API keys)
- [ ] `deploy/setup.sh` has new `install_local_mcp_launchers()` function that runs `pip install --user --force-reinstall "$APP_DIR/mcp-servers/markitdown-local-mcp"` (uses `pip`, not `uv` — `uv` is not a repo dependency)
- [ ] `deploy/setup.ps1` mirrors the install hook for Windows parity
- [ ] `opencode_app/Dockerfile` has build-time `RUN /opt/python-env/bin/pip install /app/mcp-servers/markitdown-local-mcp` (binary lands in `/opt/python-env/bin`, already on PATH)
- [ ] `README.md` MCP Servers section: count `25 → 26` (corrects pre-existing off-by-one where docs claimed 26), add table row for `markitdown`, opt-in count `19 → 20`
- [ ] `deploy/setup.sh` help text: `MCP SERVERS (26)` → `(27)` AFTER pre-existing-drift fix in Phase 6 (which corrects 26 → 25 first); listing updated; banner auto-start count stays at 6 (markitdown is opt-in)
- [ ] `deploy/setup.ps1` Windows parity: status section listing updated with markitdown opt-in row (line ~1725)
- [ ] `deploy/.AGENTS.md` MCP Tool Routing table has new markitdown row (user-level routing doc tells the model when to call it)
- [ ] `THIRD_PARTY_LICENSES.md` updated with markitdown MIT entry (hand-maintained; `tests/test_autoresearch_skills.bats` greps this file)
- [ ] **Security verification:** `python -c "import azure"` fails inside the launcher's isolated venv (proves Azure SDK absent)
- [ ] **Security verification:** `ss -tnp` during a local PDF conversion shows zero established TCP connections
- [ ] **Security verification:** launcher startup registers zero Plugin converters (assert via `MarkItDown()._converter_registry` or equivalent — proves `enable_plugins=False` works)
- [ ] **Functional verification:** converting a sample PDF/DOCX/PPTX/XLSX returns valid Markdown
- [ ] **PATH verification:** `markitdown-local-mcp --help` resolves on PATH inside the Docker container as the `opencode` user (no entrypoint changes needed)
- [ ] Cross-file MCP count consistency verified via explicit grep checklist (see Phase 4.5 — `documentation-sync-workflow` skill only covers skills/subagents, NOT MCP counts)

---

## Dependency & Consumer Map

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---------------------|---------------------------|---------------------------------|-------------|
| `opencode_app/mcp-servers/markitdown-local-mcp/` (launcher) | — | `opencode_app/opencode.json`, `deploy/setup.{sh,ps1}`, `opencode_app/Dockerfile` | med — new MCP server, privacy-critical |
| `opencode_app/opencode.json` (mcp+tools entries) | Launcher exists | OpenCode runtime (all sessions); `deploy/setup.sh` copy step; **`deploy/resolve-models.mjs`** which read-modify-writes this file at Docker build (round-trips via `JSON.stringify` — non-breaking but must re-verify after build); deployed to `~/.config/opencode/opencode.json` | low — additive, opt-in (`enabled: false`) |
| `deploy/setup.sh` (install hook + help text + status listing) | Launcher exists | User-space deploy workflow; `--help` output | low — new function + count sync |
| `deploy/setup.ps1` (Windows parity: install + status listing) | Launcher exists | Windows deploy workflow | low — mirror of setup.sh |
| `opencode_app/Dockerfile` (build-time `pip install`) | Launcher exists | Docker standalone build (`/opt/python-env/bin` already on PATH via line 33) | low — single RUN line, no `uv` introduction |
| `deploy/.AGENTS.md` (MCP Tool Routing table) | Config changes complete | User-level agent routing (deployed to `~/.config/opencode/AGENTS.md`) | low — additive table row |
| `README.md` (MCP table + count) | Config changes complete; Phase 6 count fix | Documentation readers | low — count/table sync |
| `deploy/setup.sh` help text | Config changes complete; Phase 6 count fix | `--help` output | low — count sync |
| `THIRD_PARTY_LICENSES.md` | — | License compliance; `tests/test_autoresearch_skills.bats` grep | low — additive |
| `deploy/resolve-models.mjs` (NO direct edit) | — | Mutates `opencode.json` `model`/`agent` fields at Docker build only | n/a — non-breaking round-trip; just verify markitdown survives a build |

## Implementation Phases

### Phase 1: Vendor the hardened launcher

Create the vendored launcher package under `opencode_app/mcp-servers/markitdown-local-mcp/` (5 files). This is the trust boundary — it must depend ONLY on local converter libraries and construct `MarkItDown()` with zero cloud kwargs.

- [x] **1.1** Create `pyproject.toml` with constrained deps (no `[all]`, no azure/speech/youtube), **version-capped**
    — **Why:** Pinning to specific local-only extras prevents the `markitdown[all]` metastate from pulling cloud SDKs (`azure-ai-documentintelligence`, `azure-ai-contentunderstanding`, `SpeechRecognition`, `youtube-transcript-api`) onto disk — the root of the privacy concern. The cap (`<0.2`) prevents a future `uv tool install --force` from silently pulling a markitdown version that defaults `enable_plugins=True`, adds a telemetry converter, or pulls a new cloud extra — an open floor would defeat the hardening.
    — **Done when:** `pyproject.toml` declares `markitdown[pdf,docx,pptx,xlsx,xls,outlook]>=0.1.1,<0.2` + `mcp>=1.0` only; a comment block lists every excluded extra by name.
    — **Consumers affected:** launcher venv (build/install), `deploy/setup.sh` install hook, Dockerfile build step.
- [x] **1.2** Create `src/markitdown_local_mcp/__main__.py` (~60 LOC) — sanitized MCP wrapper, single tool, no cloud kwargs, `enable_plugins=False` (constructor arg)
    — **Why:** The wrapper is the trust boundary — it must construct `MarkItDown()` with zero cloud kwargs and hard-disable plugins so no third-party converter can ever run. The authoritative control is the `enable_plugins=False` constructor arg; the `MARKITDOWN_ENABLE_PLUGINS` env var is belt-and-suspenders only (markitdown may not even read it).
    — **Done when:** Module exposes a single `convert_to_markdown(uri: str) -> str` tool over stdio; `MarkItDown()` is instantiated with no `docintel_endpoint`/`cu_endpoint`/`llm_client` kwargs and `enable_plugins=False`; `os.environ["MARKITDOWN_ENABLE_PLUGINS"]="false"` is set before the markitdown import as defense-in-depth.
    — **Consumers affected:** MCP runtime (all OpenCode sessions that opt in), `opencode.json` `markitdown` entry.
- [x] **1.3** Create `src/markitdown_local_mcp/__init__.py` — version export
    — **Why:** Standard package marker + `__version__` for `pip install` metadata and future upgrade checks.
    — **Done when:** File exports `__version__ = "0.1.0"` and the package imports cleanly under `python -c "import markitdown_local_mcp"`.
    — **Consumers affected:** pyproject build, install hook.
- [x] **1.4** Create `README.md` — privacy rationale, what's removed vs upstream, MIT attribution, link to upstream repo, version-pin policy
    — **Why:** Documenting the deliberate removals gives auditors and future maintainers a clear record of why each cloud extra was excluded, where the trust boundary sits, and why the version cap exists.
    — **Done when:** README covers privacy rationale, a "Removed vs upstream" table, MIT attribution, link to `microsoft/markitdown`, and a note that version bumps require explicit review.
    — **Consumers affected:** documentation readers, security reviewers.
- [x] **1.5** Create `LICENSE` — MIT with microsoft/markitdown copyright notice (derivative work clause)
    — **Why:** markitdown is MIT-licensed; our launcher is a derivative work and must preserve the upstream copyright notice to stay license-compliant.
    — **Done when:** `LICENSE` is MIT text with microsoft/markitdown copyright attribution and a derivative-work note.
    — **Consumers affected:** license compliance, `THIRD_PARTY_LICENSES.md` sync.

### Phase 2: Register MCP in opencode config

Add the `markitdown` server to `opencode_app/opencode.json` as opt-in (`enabled: false`) and deny its tools by default. Env block contains ONLY `MARKITDOWN_ENABLE_PLUGINS=false` — no empty-string API keys (the launcher never reads them; structural dep exclusion is the real guarantee, and existing entries use `${env:VAR}` syntax, not literal empty strings).

- [ ] **2.1** Add `markitdown` entry to `opencode_app/opencode.json` `mcp` block (after `mermaid`, line 239): `type: local`, `command: ["markitdown-local-mcp"]`, env block with `MARKITDOWN_ENABLE_PLUGINS=false` ONLY, `enabled: false`
    — **Why:** Registers the server as opt-in (disabled by default) so it never starts unless the user explicitly enables it. The empty-string `AZURE_API_KEY`/`OPENAI_API_KEY` env vars from the prior draft are dropped: they are NOT real `DefaultAzureCredential` env vars (DAC probes `AZURE_CLIENT_ID`/`AZURE_TENANT_ID`/`AZURE_CLIENT_SECRET` + IMDS, not `AZURE_API_KEY`), the launcher never reads them, and they break the existing `${env:VAR}` interpolation convention. Structural dep exclusion (Phase 1.1) is the real neutralization.
    — **Done when:** A `markitdown` object exists in the `mcp` block after `mermaid` with `enabled: false`, `MARKITDOWN_ENABLE_PLUGINS=false` env var, and valid JSON.
    — **Consumers affected:** all OpenCode sessions (user-space + Docker); deployed to `~/.config/opencode/opencode.json`; round-tripped by `resolve-models.mjs` at Docker build.
- [ ] **2.2** Add `"markitdown*": false` to `tools` block (after `"mermaid*": true`, line 244)
    — **Why:** Even when the server is enabled, tools default to denied unless explicitly granted — defense in depth so the MCP tool isn't callable until the user opts in at the tools layer too.
    — **Done when:** `"markitdown*": false` present in the `tools` block and JSON parses.
    — **Consumers affected:** all sessions that enable the server.

### Phase 3: Deploy hooks

Wire the launcher install into user-space setup, Windows setup, and the Docker build. **Uses `pip` (not `uv`)** — `uv` is not a repo dependency, is not installed in the Docker image, and introducing it would require new prerequisite checks. `pip` is already available everywhere Python is.

- [ ] **3.1** Add `install_local_mcp_launchers()` to `deploy/setup.sh` — verifies `pip`/`python3` exists, runs `pip install --user --force-reinstall "$APP_DIR/mcp-servers/markitdown-local-mcp"`, logs result, warns if `~/.local/bin` not on PATH. Call it after config-copy step.
    — **Why:** User-space deploy must install the vendored launcher onto PATH so `markitdown-local-mcp` is invocable; `--force-reinstall` ensures upgrades overwrite stale installs. Uses `pip` (already available user-space) rather than `uv` (which would need its own install step and is not a repo dependency). `--user` mode places the console-script in `~/.local/bin/` (Python 3.12+ auto-adds to PATH on most distros). Network required — if offline, log a clear warning and skip (not fatal).
    — **Done when:** Function exists, is invoked after config copy, runs `pip install --user --force-reinstall "$APP_DIR/mcp-servers/markitdown-local-mcp"`, logs success/failure, and emits a PATH warning if `~/.local/bin` is not on PATH.
    — **Consumers affected:** user-space deploy workflow.
- [ ] **3.2** Mirror in `deploy/setup.ps1`
    — **Why:** Windows parity — setup.ps1 must perform the same install so Windows users get the launcher on PATH.
    — **Done when:** `deploy/setup.ps1` has an equivalent install step using `pip install --user --force-reinstall`; documents the Windows bin location (`%APPDATA%\Python\Scripts`) and PATH requirement.
    — **Consumers affected:** Windows deploy workflow.
- [ ] **3.3** Add `RUN /opt/python-env/bin/pip install /app/mcp-servers/markitdown-local-mcp` to `opencode_app/Dockerfile` after the opencode_app COPY step
    — **Why:** Docker standalone bakes the launcher into the image at build time so the container doesn't need network access at runtime. Uses `/opt/python-env/bin/pip` (the existing Python env per Dockerfile line 33) so the console-script lands in `/opt/python-env/bin` — already on PATH via `ENV PATH="/opt/python-env/bin:${PATH}"`. **Do NOT use `uv`** — it is not installed in the image, and installing it would add ~50MB and a new upstream dependency for no benefit.
    — **Done when:** Dockerfile contains the `RUN /opt/python-env/bin/pip install` line after the `COPY` of `opencode_app`, placed LATE in the file (cache-friendly — so source-only changes don't invalidate early layers) and the image builds.
    — **Consumers affected:** Docker standalone build.
- [ ] **3.4** Verify `markitdown-local-mcp` resolves on PATH inside a built container as the `opencode` user (no entrypoint changes needed)
    — **Why:** Replaces the prior "verify no entrypoint change needed" hand-wave with a real check. `/opt/python-env/bin` is on PATH via ENV directive, so the entrypoint should need no special handling — but this must be verified by actually running `which markitdown-local-mcp` in a built container, not assumed.
    — **Done when:** `docker run --rm <image> which markitdown-local-mcp` returns `/opt/python-env/bin/markitdown-local-mcp`; if a different path is returned, document it and add an `ENV PATH` directive.
    — **Consumers affected:** Docker runtime.

### Phase 4: Documentation sync

Update all documentation surfaces so counts and listings match the new server. Counts span README, setup.sh help text, setup.ps1, and `deploy/.AGENTS.md`. Note: `documentation-sync-workflow` skill only covers skills/subagents — it does NOT know about MCP counts, so verification uses an explicit grep checklist.

- [ ] **4.1** `README.md` line ~243: AFTER Phase 6 corrects the latent off-by-one (25 entries documented as 26), bump to "26 MCP server entries" reflecting markitdown addition; add table row `| markitdown | local (pip) | Document → Markdown conversion (opt-in) |`; update "remaining N" opt-in count (`19 → 20`)
    — **Why:** The MCP count and table must reflect the new server so docs match reality. NOTE: the repo currently has a pre-existing off-by-one — README claims 26 entries but `opencode.json` actually has 25. Phase 6 fixes the latent bug first (26 → 25 in docs); this task then adds markitdown (25 → 26) with correct math.
    — **Done when:** Line 243 reads "26 MCP server entries" (post-Phase-6 + post-markitdown), the table has a `markitdown` row, and the "remaining 20 opt-in" count is correct.
    — **Consumers affected:** documentation readers.
- [ ] **4.2** `deploy/setup.sh` help text line 627: AFTER Phase 6 corrects `MCP SERVERS (26)` → `(25)`, bump to `(26)`; add `markitdown         Document-to-markdown (local-only, opt-in)` to the disabled/opt-in listing; auto-start count stays at 6 (markitdown is NOT in auto-start)
    — **Why:** `--help` output must show the correct count and list the new opt-in server.
    — **Done when:** Line 627 reads `MCP SERVERS (26):` (post-Phase-6), the opt-in listing includes the markitdown row, and auto-start count is unchanged.
    — **Consumers affected:** `--help` output, deploy verification.
- [ ] **4.3** `opencode_app/README.md` — add Docker note that launcher is baked into the image
    — **Why:** Docker users should know the converter is available without a separate install step.
    — **Done when:** `opencode_app/README.md` notes the markitdown launcher is installed at build time via `/opt/python-env/bin/pip`.
    — **Consumers affected:** Docker documentation readers.
- [ ] **4.4** `THIRD_PARTY_LICENSES.md` — add markitdown MIT entry
    — **Why:** License compliance requires listing all vendored third-party dependencies and their licenses. This file is hand-maintained and grepped by `tests/test_autoresearch_skills.bats:159-166` — keep format consistent.
    — **Done when:** `THIRD_PARTY_LICENSES.md` has a markitdown MIT entry with upstream attribution.
    — **Consumers affected:** license compliance, bats test.
- [ ] **4.5** Run explicit grep checklist to verify cross-file MCP count consistency (do NOT rely on `documentation-sync-workflow` skill — it only handles skills/subagents, not MCP counts)
    — **Why:** Counts and listings span README, setup.sh, setup.ps1, and opencode.json — drift is easy to miss. The `documentation-sync-workflow` skill (`SKILL.md:13-18`) explicitly scopes itself to skills/subagents. A direct grep is the mechanical guarantee.
    — **Done when:** All of the following return consistent counts (post-markitdown: 26 total, 6 auto-start, 20 opt-in):
        ```
        rg -n "MCP SERVERS \(" deploy/
        rg -n "MCP Servers \(" deploy/ README.md opencode_app/README.md
        rg -n "remaining.*opt-in" README.md
        rg -n "markitdown" deploy/ README.md opencode_app/ opencode_app/opencode.json
        ```
    — **Consumers affected:** all documentation surfaces.
- [ ] **4.6** `deploy/setup.ps1:1722-1725` status section — add `markitdown` to opt-in listing
    — **Why:** Windows deploy prints a "Configured MCP servers" status block (line ~1722) listing auto-start servers on line 1723 and opt-in servers on line 1725. The sync-table row "New/removed MCP server → MCP count, auto-start listing, help text" requires this update.
    — **Done when:** `deploy/setup.ps1` opt-in listing (around line 1725) includes `markitdown`.
    — **Consumers affected:** Windows deploy status output.
- [ ] **4.7** `deploy/.AGENTS.md` MCP Tool Routing table (lines 74-85) — add markitdown row
    — **Why:** This is the user-level routing doc (deployed to `~/.config/opencode/AGENTS.md`) that tells the model WHEN to call each MCP server. Without a row, markitdown is invisible to the model even when enabled. Peer entries: codegraph, atlassian, mermaid, zai-web-reader, zai-zread, image-analyzer.
    — **Done when:** Table has a new row: `| Document → Markdown conversion | markitdown (opt-in) | manual | Local-only converters; no cloud/telemetry; allows user-supplied http(s) URIs |`.
    — **Consumers affected:** all agents (routing logic).
- [ ] **4.8** `deploy/setup.sh` status sections (lines ~1722, ~2416, ~3144) — add `markitdown` to opt-in listings
    — **Why:** Three separate status sections in setup.sh enumerate MCP servers; all three need the markitdown opt-in row to satisfy the repo's sync-table requirements.
    — **Done when:** All three status sections (`log_info` calls around lines 1722, 2416, 3144) include `markitdown` in the opt-in/disabled list.
    — **Consumers affected:** `setup.sh` deploy status output.

### Phase 5: Security & functional verification

Mechanically prove the privacy guarantees (no Azure bytes, no TCP connections during local conversion, no Plugin converters registered) and confirm the converter works for all supported formats.

- [ ] **5.1** Run `pip install` locally; confirm `markitdown-local-mcp --help` works
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
- [ ] **5.8** Assert zero Plugin converters registered at startup
    — **Why:** The authoritative plugin control is the `enable_plugins=False` constructor arg (not the env var). This task mechanically proves it works — indirect checks (5.2 single tool, 5.6 no azure) don't cover this directly. A future markitdown version could rename the env var; the constructor arg is the structural guarantee.
    — **Done when:** After launcher startup, dump `MarkItDown()._converter_registry` (or equivalent) and assert no converter's class name contains "Plugin".
    — **Consumers affected:** trust model verification.
- [ ] **5.9** Docker build smoke test — `docker run --rm <image> which markitdown-local-mcp` and confirm resolution
    — **Why:** Phase 3.4's PATH verification — proves the binary is invocable inside the container as the `opencode` user without entrypoint changes.
    — **Done when:** `which markitdown-local-mcp` returns `/opt/python-env/bin/markitdown-local-mcp` inside a built container.
    — **Consumers affected:** Docker runtime.

### Phase 6: Fix pre-existing MCP count drift (latent bug)

The repo currently has a pre-existing documentation bug: `opencode_app/opencode.json` actually contains **25** MCP entries, but `README.md` (line 243) and `deploy/setup.sh` (line 627) both claim **26**. This off-by-one predates this ticket and must be corrected BEFORE Phase 4's markitdown additions (otherwise Phase 4's math inherits the error: `26 → 27` would propagate the bug instead of correcting it). Phase 4 then cleanly takes the corrected count `25 → 26` with markitdown.

- [ ] **6.1** Recount `opencode.json` MCP entries programmatically and document the canonical number
    — **Why:** Establishes ground truth before touching any doc. The recount must be reproducible (a one-liner), not hand-counted.
    — **Done when:** A `jq '.mcp | length' opencode_app/opencode.json` (or `python -c "import json; print(len(json.load(open('opencode_app/opencode.json'))['mcp']))"`) returns 25; the canonical count is recorded in the Phase 4 task descriptions.
    — **Consumers affected:** all downstream count edits.
- [ ] **6.2** Correct `README.md` line 243 from "26 MCP server entries" to "25 MCP server entries" (interim state — Phase 4.1 then bumps it back to 26 with markitdown)
    — **Why:** Removes the pre-existing off-by-one. Without this, Phase 4.1's "26 → 27" math would be wrong (the real sequence is 25 → 26).
    — **Done when:** README line 243 reads "25 MCP server entries" and the "remaining N opt-in" count matches (19 — six auto-start: codegraph, atlassian, zai-vision-mcp-server, mermaid, zai-web-reader, zai-zread).
    — **Consumers affected:** documentation readers.
- [ ] **6.3** Correct `deploy/setup.sh` line 627 from `MCP SERVERS (26):` to `MCP SERVERS (25):` (interim — Phase 4.2 then bumps to 26)
    — **Why:** Same off-by-one as 6.2 — `setup.sh --help` must match reality before markitdown is added.
    — **Done when:** Line 627 reads `MCP SERVERS (25):`.
    — **Consumers affected:** `--help` output.
- [ ] **6.4** Correct `deploy/setup.ps1` MCP count (line ~2479 banner) from `26` to `25` (interim)
    — **Why:** Windows parity — same off-by-one.
    — **Done when:** `setup.ps1` banner reads `MCP Servers (5)` for auto-start (or whatever the real auto-start count is — verify with recount) and the total matches.
    — **Consumers affected:** Windows `--help` output.
- [ ] **6.5** Add bats test (or extend `tests/test_autoresearch_skills.bats`) to assert MCP count consistency
    — **Why:** Mechanical prevention of future drift — the existing bats test already greps `THIRD_PARTY_LICENSES.md`, so the pattern is established. A new assertion that `jq '.mcp | length' opencode_app/opencode.json` equals the README/setup.sh/setup.ps1 counts prevents this exact bug from recurring.
    — **Done when:** A bats test (or shellcheck hook in CI) fails if `opencode.json` MCP count disagrees with README/setup.sh/setup.ps1.
    — **Consumers affected:** CI, future contributors.

## Open Questions (need user decision before execution)

1. **Skill creation:** Add a `markitdown-mcp-skill` (peer to `codegraph-setup-skill`, `nextjs-devtools-mcp-skill`, `mermaid-diagram-creator-skill`)? Precedent exists; the launcher is simple but a skill would document the opt-in flow, privacy guarantees, and which agents should call it. **Recommendation:** defer to a follow-up ticket — keep this PR focused on the MCP integration.
2. **Per-agent tool grants:** Should specific agents (e.g., `office-document-primary-agent`, `documentation-subagent`) get `markitdown*` granted when enabled? Today the repo uses only the coarse global `tools` block (no per-agent MCP grants in `opencode.json:267-290`). **Recommendation:** keep the coarse model — users who enable the server can grant per-agent in their own override.
3. **Audio/Image scope expansion:** The PLAN currently installs Office essentials only (PDF/DOCX/PPTX/XLSX/XLS/Outlook MSG + EXIF-only images). If users need HTML/CSV/JSON/XML/EPUB/IPYNB/ZIP converters later, that's a `pyproject.toml` extras bump — not a structural change. Defer.
