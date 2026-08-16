# PLAN: Add Z.AI Web Search + Zread MCP servers (GIT-336)

**Issue:** https://github.com/darellchua2/opencode-config-template/issues/336
**Branch:** `GIT-336`
**Type:** feature (MCP servers, config-distributor repo)

---

## Scope Decision Analysis: Global vs Project-Specific

### Context

This repo is a **configurator** — `opencode_app/opencode.json` deploys to every user's global `~/.config/opencode/`. Enabling an MCP server globally means every session, in every project, pays its tool-definition token cost and (for enabled remote servers) a startup connection. The repo has two precedents:

| Pattern | Servers | Rationale |
|---------|---------|-----------|
| Global + enabled | `codegraph`, `zai-web-reader` | Universal need, small tool surface, existing auth |
| Global entry + `enabled: false` (per-project opt-in) | `atlassian`, `markitdown`, `docling`, `next-devtools`, `chrome-devtools` | Niche use cases, larger overhead, or per-project relevance |

### Recommendation

| Server | Decision | Rationale |
|--------|----------|-----------|
| `zai-web-search` | **Global + enabled** | (1) Fills a universal capability gap: no websearch plugin supports Z.AI/GLM (verified — `opencode-websearch-cited` supports only Google/OpenAI/OpenRouter; `opencode-websearch` supports Anthropic/Moonshot/OpenAI/Copilot). (2) Completes the search→fetch pipeline with the already-global `zai-web-reader`: search finds URLs, reader fetches them — this is the Z.AI-native replacement for cited web answers. (3) Tiny overhead: ~1–2 tools. (4) Zero new auth: reuses `{env:ZAI_API_KEY}` already required by web-reader. |
| `zai-zread` | **Global entry + `enabled: false`** (per-project opt-in) | (1) Niche: GitHub-repo docs lookup, only relevant when working against third-party repos. (2) Largest overhead of the pair: 3 tools (`search_doc`, `get_repo_structure`, `read_file`). (3) Overlaps with `codegraph` for local-repo intelligence; zread's value is *other* people's repos. (4) Exact precedent: `atlassian` ships globally-registered-but-disabled with per-project opt-in documented in AGENTS.md MCP Routing. |

**Why not both project-only?** Web search is a cross-project daily need (any debugging/versions/API question); forcing per-project opt-in would silently keep the Z.AI capability gap in fresh checkouts. The asymmetry — search on, zread opt-in — matches the repo's existing split between universal and niche servers.

### Token-Usage Impact (to be measured in Phase 1)

Estimated per-session system-prompt overhead from MCP tool definitions (before/after diff via `context-budget-skill` methodology):
- `zai-web-search` (enabled): ~300–800 tokens/session (1–2 tool defs)
- `zai-zread` (disabled): **0** — disabled servers do not inject tool definitions
- Net global-deploy overhead: the web-search figure only; measurable in Phase 1 step 1.3 and reported on the issue.

---

## Dependency & Consumer Map

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|--------------------|---------------------------|----------------------------------|-------------|
| `opencode_app/opencode.json` (mcp block) | Scope decision (Phase 1) | Every deployed session; `deploy/setup.sh` (copies verbatim, line ~2425); Docker `opencode_app/` | **med** — wrong `enabled:` flag or URL breaks sessions at startup |
| `deploy/setup.sh` (MCP count, auto-start listing, help text) | opencode.json change | Users running `setup.sh`; `--help` output; dry-run preview | **low** — text/counts only, but count drift fails doc-consistency tests |
| `deploy/setup.ps1` (Windows mirror) | opencode.json change | Windows users | **low** — must mirror setup.sh exactly |
| `README.md` (root) | opencode.json change | Repo visitors; doc-consistency tests | **low** |
| `opencode_app/README.md` | opencode.json change | Docker users | **low** |
| AGENTS.md MCP Routing section (user-level `deploy/.AGENTS.md`) | decision on zread opt-in | Primary-agent MCP routing rules | **low** — only if zread routing rules needed |
| `registry.json` | any skill/agent frontmatter change | installer (`npx … add`) | **none** — no skills/agents touched; rebuild only as verification |

---

## Implementation Phases

### Phase 1: Token Audit + Scope Decision Ratification

- [ ] **1.1** Measure current MCP tool-definition token baseline (enabled servers: codegraph, zai-web-reader) using `context-budget-skill` methodology against a fresh session's system prompt.
    — **Why:** The issue demands a token-usage note; a before/after diff is only meaningful with a measured baseline.
    — **Done when:** Baseline token count for current enabled-MCP tool definitions recorded in this PLAN's Token-Usage section.
    — **Consumers affected:** Issue #336 evidence; README documentation in Phase 3.
- [ ] **1.2** Probe both endpoints (`web_search_prime`, `zread`) with `ZAI_API_KEY` to confirm auth works and enumerate actual tool definitions (names + schema sizes).
    — **Why:** Token estimates and tool counts must be measured, not assumed from community wrappers; also verifies the URLs are live before shipping config.
    — **Done when:** Actual tool list + per-tool schema token count for each server recorded; any auth failure surfaced as a blocker.
    — **Consumers affected:** Phase 2 config entries (URL correctness); token report in 1.3.
- [ ] **1.3** Compute net overhead for the recommended split (web-search enabled, zread disabled) and finalize the scope decision memo.
    — **Why:** The decision must rest on measured numbers per the issue's acceptance criteria; if web-search overhead exceeds ~1k tokens or zread's differs materially from 3 tools, revisit the recommendation before implementation.
    — **Done when:** Memo with measured numbers appended to Scope Decision section; decision confirmed or revised.
    — **Consumers affected:** Phase 2 (which entries, which flags).

### Phase 2: Configuration

- [ ] **2.1** Add `zai-web-search` remote MCP entry (`enabled: true`) to `opencode_app/opencode.json` mirroring the `zai-web-reader` block (type remote, URL from 1.2, `{env:ZAI_API_KEY}` bearer header).
    — **Why:** Atomic config change for the enabled half of the decision; mirrors a proven pattern so review surface is minimal.
    — **Done when:** `node -e "JSON.parse(...)"` passes; diff shows only the new entry.
    — **Consumers affected:** All deployed sessions (new tools appear); setup.sh copy path; Docker container.
- [ ] **2.2** Add `zai-zread` remote MCP entry (`enabled: false`) to `opencode_app/opencode.json`, same pattern.
    — **Why:** Ships the opt-in path globally without imposing its token cost, matching `atlassian` precedent.
    — **Done when:** JSON validates; entry present with `enabled: false`.
    — **Consumers affected:** Per-project `opencode.json` overrides; AGENTS.md MCP routing docs.

### Phase 3: Sync Rules (Repo Mandate)

- [ ] **3.1** Update `deploy/setup.sh`: MCP SERVERS count 7→9, auto-start listing (add `zai-web-search`), help text, and the ZAI_API_KEY requirement note (now covers search + zread opt-in).
    — **Why:** Repo sync-rules table mandates count/listing/help-text updates on any MCP change; drift breaks doc-consistency tests.
    — **Done when:** `grep` confirms new counts in all three spots; `bash -n deploy/setup.sh` passes.
    — **Consumers affected:** setup.sh users, help output, consistency tests.
- [ ] **3.2** Mirror 3.1 in `deploy/setup.ps1` (Windows parity).
    — **Why:** setup.ps1 is the mandated Windows mirror; missing parity fails review.
    — **Done when:** Same counts/listings present; PowerShell syntax check passes.
    — **Consumers affected:** Windows users.
- [ ] **3.3** Update `README.md` and `opencode_app/README.md`: MCP server tables (9 servers, auto-start includes zai-web-search), zread opt-in instructions (project `opencode.json` override snippet), token-usage note with measured numbers from 1.3.
    — **Why:** Sync rules + the issue's token-usage acceptance criterion; documents the opt-in path so users can act on it.
    — **Done when:** Both READMEs show 9 MCP servers and the token note; doc-consistency greps pass.
    — **Consumers affected:** Repo readers, Docker users.

### Phase 4: Verification + Review Gates

- [ ] **4.1** Run verification gates: JSON validation, `bash -n deploy/setup.sh`, `node deploy/build-registry.mjs` (no-op expected), repo test suite (doc-consistency tests).
    — **Why:** AGENTS.md verification gates are mandatory before declaring done; registry rebuild confirms no unintended registry drift.
    — **Done when:** All commands exit 0; failures fixed or reported as pre-existing.
    — **Consumers affected:** CI, reviewers.
- [ ] **4.2** Post token-usage report + scope-decision rationale as a comment on issue #336.
    — **Why:** The issue explicitly asks to "take note on token usage"; the decision rationale must be reviewable from the ticket.
    — **Done when:** Comment posted with measured baseline/after numbers and the decision memo.
    — **Consumers affected:** Issue subscribers, future maintainers.
- [ ] **4.3** Delegate strong review to `opencode-tooling-subagent` covering: config correctness, sync-rule completeness, scope-decision rationale, token math.
    — **Why:** User-mandated review gate before implementation merges; tooling subagent owns repo-convention compliance.
    — **Done when:** Subagent returns success (or issues fixed and re-reviewed); Return Contract honored.
    — **Consumers affected:** Merge decision.

---

## Risks & Mitigation

| Risk | Mitigation |
|------|------------|
| `web_search_prime` URL is a paid/prime-tier endpoint (name suggests it) | 1.2 probe verifies auth+billing tier before shipping; fallback: document as opt-in if it 403s on coding-plan keys |
| Token overhead larger than estimated | 1.3 gate: revisit decision if >1k tokens |
| Remote MCP unavailable in some regions | Same risk class as existing web-reader; no new failure mode |
| Count drift across 4 files | 4.1 doc-consistency tests catch |

## Success Metrics

- Fresh deploy: search tool available, zread absent until opted in
- Measured token overhead ≤ ~1k tokens/session (web-search only)
- Zero doc-consistency test failures
- Review sign-off from opencode-tooling-subagent
