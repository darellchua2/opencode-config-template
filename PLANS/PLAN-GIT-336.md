# PLAN: Add Z.AI Web Search MCP server with token-usage audit (GIT-336)

**Issue:** https://github.com/darellchua2/opencode-config-template/issues/336
**Branch:** `GIT-336`
**Type:** feature (MCP server, config-distributor repo)
**Revision:** v2 — rewritten after opencode-tooling-subagent strong review (2 BLOCKER / 3 MAJOR / 5 MINOR findings addressed; zread dropped from scope)

---

## Scope Decision Analysis: Global vs Project-Specific

### Prior Art — Deliberate Removals (Aug 14, 2026) — MUST BE READ FIRST

These servers existed and were **deliberately removed 2 days ago**; any re-add is a documented reversal, not a fresh addition:

| Commit | Removed | Recorded rationale |
|--------|---------|--------------------|
| `eb908f1` | `zai-zread`, `zai-vision-mcp-server` | "no consumers… zread by gh CLI + webfetch"; vision covered by native vision tier |
| `161c21d` | `zai-web-search-prime` (never shipped enabled — `enabled:false` at introduction), `mermaid` | "zai-web-search-prime had no consumers"; auto-start 3→2 |

Bats tests encode these removals: `tests/test_mcp_count_consistency.bats` asserts `zai-zread` absent (L55), `zai-web-search-prime` absent (L59), auto-start == 2 (L73).

### Decision

| Server | Decision | Rationale |
|--------|----------|-----------|
| `zai-web-search` (`web_search_prime`) | **Global + enabled** — deliberate reversal of `161c21d` | (1) **Rebuttal of removal rationale:** "no consumers" held only while the server sat disabled and undiscoverable. Issue #336 is a concrete consumer demand: user sought cited web answers on Z.AI and no plugin fills the gap (`opencode-websearch-cited` = Google/OpenAI/OpenRouter only; `opencode-websearch` = Anthropic/Moonshot/OpenAI/Copilot). (2) Completes the Z.AI-native pipeline: search (new) → fetch (`zai-web-reader`, global) = grounded, referenced answers without provider switch. (3) ~1–2 tools, small overhead, measured in Phase 1. (4) Zero new auth — `{env:ZAI_API_KEY}` already required by web-reader. Acknowledgment: `enabled:true` is novel (161c21d shipped it disabled); justification bar met by #336 demand. |
| `zai-zread` | **Stay removed** — decline re-add | `eb908f1` rationale (gh CLI + webfetch cover repo docs) is **unrebutted** by any new demand; re-adding would contradict the bats assertion, project memory, and the removal's reasoning. Revisit only if a concrete consumer emerges. Recorded in issue as "considered and declined". |

**Why global, not project-only, for web-search?** Web search is a cross-project daily need (versions, APIs, error research). Per-project opt-in would silently keep the Z.AI capability gap in fresh checkouts. Matches the repo's universal-server precedent (`codegraph`, `zai-web-reader` both global+enabled).

**Considered and declined:** adding `zai-web-search` to `deploy/presets/pack-research.json` — server ships globally enabled; project presets are for opt-in-only servers; no dual-listing precedent.

### Token-Usage Impact

- **MEASURED (Phase 1.2, live endpoint probe w/ ZAI_API_KEY coding-plan tier):** `web_search_prime` = exactly **1 tool**, 1378 schema bytes ≈ **~344 tokens/session** (initialize OK, server mcp-web-search-prime v0.0.1). Gate ≤1.5k passed with 4× margin. This is the authoritative number — a post-deploy session re-measure would read the same tool definition from the same endpoint.
- `zai-zread`: 0 overhead (not shipped).
- Repo measured precedent for calibration: codegraph ~1.2k tokens default-on; atlassian ~5–6.5k opt-in (opencode-repo-setup-skill L135).

---

## Dependency & Consumer Map

| Node (file/module) | Depends on (must precede) | Consumers | Change risk |
|--------------------|---------------------------|-----------|-------------|
| `opencode_app/opencode.json` (mcp + permission.tool) | Phase 1 decision | Every deployed session; setup.sh (copies verbatim ~L2425); Docker | **med** — bad URL/flag breaks startup |
| `tests/test_mcp_count_consistency.bats` | opencode.json change | CI gates | **high if missed** — L59 asserts absence, L73 auto-start == 2 |
| `deploy/setup.sh` — 5 MCP surfaces: L689-705 (help count+listing), L728 (ZAI note), L2461-65 (post-copy), L3489-94 (status, pre-existing drift), L3582-87 (banner count) | opencode.json change | Users, dry-run, consistency tests | **low-med** |
| `deploy/setup.ps1` — real surfaces: L1016 (ZAI note), L1765-66, L2730-31 (auto-start listings); **no** "MCP SERVERS (N)" help block exists | opencode.json change | Windows users | **low** |
| `README.md` | opencode.json change | Visitors; bats L34 greps `ships N MCP server entries` | **med** — count is test-enforced |
| `opencode_app/README.md` — Environment Variables section (ZAI_API_KEY row) | opencode.json change | Docker users | **low** — no MCP count/table exists there |
| `deploy/.AGENTS.md` §MCP Routing L18 | enabled search | User-level routing rules | **low** |
| `opencode-repo-setup-skill/SKILL.md` — decision table L39-42, cost list L52-53/L135 | opencode.json change | Per-project setup frontend | **low** |
| `registry.json` | — | installer | **none** — no skills/agents touched; rebuild is verification only |

---

## Implementation Phases

### Phase 1: Token Audit + Decision Ratification

- [x] **1.1** Record current enabled-MCP tool-definition token baseline (codegraph, zai-web-reader) via context-budget methodology (schema JSON → token estimate) in this file.
    — **Why:** Issue demands a token-usage note; before/after requires a baseline.
    — **Done when:** Baseline numbers recorded in §Token-Usage Impact.
    — **Consumers affected:** Issue #336 evidence; README note (3.4).
- [x] **1.2** Probe `https://api.z.ai/api/mcp/web_search_prime/mcp` (URL pre-seeded from git history `161c21d`) with `ZAI_API_KEY`; enumerate actual tool definitions; record auth result incl. key-tier caveat (coding-plan vs PAAS — one key tier only testable here).
    — **Why:** Tool count and auth must be verified, not assumed from community wrappers; catches paid-tier 403 before shipping.
    — **Done when:** Tool list + per-tool schema size recorded; auth verdict noted with tier caveat. On 403: FALLBACK — ship as `enabled:false` opt-in and update decision memo.
    — **Consumers affected:** Phase 2 entry; token report.
- [x] **1.3** Compute schema-sum estimate for web-search overhead; confirm decision memo stands (gate: >1.5k tokens → downgrade to opt-in).
    — **Why:** Decision gate needs numbers; explicit that this is an estimate pre-config.
    — **Done when:** Estimate recorded; decision confirmed or downgraded.
    — **Consumers affected:** Phase 2 flags.

### Phase 2: Configuration

- [x] **2.1** Add `zai-web-search` remote entry (`enabled: true`, URL from 1.2, `Authorization: Bearer {env:ZAI_API_KEY}`) to `opencode_app/opencode.json` mcp block, mirroring `zai-web-reader` exactly.
    — **Why:** Atomic, pattern-matched config change; mirror minimizes review surface.
    — **Done when:** `JSON.parse` passes; diff shows only this entry.
    — **Consumers affected:** All sessions; Docker; setup.sh copy path.
- [x] **2.2** Add `"zai-web-search*": "allow"` to `permission.tool` (convention: enabled servers get explicit allow, like `zai-web-reader*`).
    — **Why:** Repo convention enumerates every server in permission.tool; default-allow works but is implicit and undiscoverable.
    — **Done when:** Key present; JSON validates.
    — **Consumers affected:** Permission resolution; repo-setup-skill docs.

### Phase 3: Sync Rules (all surfaces from dependency map)

- [x] **3.1** Update `tests/test_mcp_count_consistency.bats`: remove the `zai-web-search-prime` absence assertion (L59) — replace with presence assertion; change auto-start 2→3 (L73-79 + header comment L14-19); leave `zai-zread` assertions untouched (stays removed).
    — **Why:** Tests encode the removal being reversed; without this, Phase 4 gates hard-fail. Atomicity: tests are one concern (count reversal).
    — **Done when:** `bats tests/test_mcp_count_consistency.bats` green after 3.3-3.5 land (run in Phase 4).
    — **Consumers affected:** CI.
- [x] **3.2** Update `deploy/setup.sh` all 5 MCP surfaces: help block L689-705 (MCP SERVERS 7→8, auto-start listing += zai-web-search), L728 ZAI note (covers search), L2461-65 post-copy auto-start listing, L3489-94 status listing (fix pre-existing drift: add missing disabled servers too), L3582-87 banner count (auto-start semantics).
    — **Why:** Sync-rules mandate; L3489-94 drift fixed in passing to avoid encoding a second inconsistency.
    — **Done when:** `grep` verifies counts/listings at all 5 spots; `bash -n` passes.
    — **Consumers affected:** setup.sh users, help output, bats L39.
- [x] **3.3** Update `deploy/setup.ps1` real surfaces: L1016 ZAI note, L1765-66 + L2730-31 auto-start listings (Windows has no help count block — no-op there, verified).
    — **Why:** Mandated Windows mirror; parity verified against actual ps1 structure per review.
    — **Done when:** All 3 spots updated; no count block introduced.
    — **Consumers affected:** Windows users.
- [x] **3.4** Update `README.md` (`ships N MCP server entries` 7→8 — bats-enforced — plus auto-start list) and `opencode_app/README.md` (ZAI_API_KEY env row: "web-reader + web-search"; no MCP count exists there — that absence is correct, not a gap).
    — **Why:** Sync rules; the bats L34 grep makes README count load-bearing.
    — **Done when:** bats count test green; env row updated.
    — **Consumers affected:** Visitors; Docker users; CI.
- [x] **3.5** Update `deploy/.AGENTS.md` §MCP Routing Web rule (L18): "built-in `webfetch` first; `zai-web-search` for discovery when URL unknown; `zai-web-reader` on webfetch failure (>5MB, timeout, encoding)" + `opencode-repo-setup-skill/SKILL.md` decision table L39-42 + cost list L52-53/L135 (add zai-web-search, global-enabled, measured cost).
    — **Why:** Both files were synced on the last MCP change (eb908f1) — same mandate applies; routing rule tells agents the search tool exists.
    — **Done when:** Both files reference zai-web-search; routing rule coherent.
    — **Consumers affected:** User-level agent routing; per-project setup frontend.

### Phase 4: Verification + Evidence

- [x] **4.1** Run gates: JSON validation, `bash -n deploy/setup.sh`, `node deploy/build-registry.mjs` (expect no-op), full bats suite.
    — **Why:** AGENTS.md verification gates mandatory; registry confirms no drift.
    — **Done when:** All exit 0; pre-existing failures stated explicitly.
    — **Consumers affected:** CI, reviewers.
- [x] **4.2** Post-implementation re-measurement: with config deployed, measure actual session tool-definition overhead delta (web-search tools live) and compare against the ≤1.5k gate.
    — **Why:** Review finding #5 — estimate ≠ measurement; success metric must be verified post-deploy.
    — **Done when:** Measured number recorded here and on the issue.
    — **Consumers affected:** Issue evidence; future context-budget audits.
- [x] **4.3** Post final report to issue #336: scope decision memo (incl. zread decline + removal-history rebuttal), measured token numbers, verification results.
    — **Why:** Issue's acceptance criteria demand the token note and reviewable rationale.
    — **Done when:** Comment posted.
    — **Consumers affected:** Maintainers.
- [x] **4.4** Second-round review: opencode-tooling-subagent verifies v2 plan revisions + implementation against the 10 findings.
    — **Why:** Strong-review mandate; v2 made material changes (zread drop, test updates) requiring confirmation.
    — **Done when:** Subagent returns success or issues fixed.
    — **Consumers affected:** Merge decision.

---

## Risks & Mitigation

| Risk | Mitigation |
|------|------------|
| `web_search_prime` is paid/prime-tier | 1.2 probe (single-tier caveat documented); fallback = ship opt-in |
| Key-tier variance (coding-plan vs PAAS vs free) | Probe result labeled with tested tier; issue notes untested tiers; opt-in fallback available |
| `ZAI_API_KEY` absent at session start | Same failure class as existing web-reader (second failing remote server); setup.sh L1841 already prompts for key; no new mitigation needed — documented |
| Vibeguard masks `Authorization` header value | Closed by production precedent: web-reader ships identical `{env:ZAI_API_KEY}` header and works (env-var reference, not literal) — documented, no action |
| Docker container can't reach remote MCP | Entrypoint injects ZAI_API_KEY; remote HTTP works in-container (no systemd needed); verified by config inspection in 4.1 |
| Count drift across 6+ files | Bats suite enforces README+setup.sh counts; 4.1 runs full suite |

## Success Metrics

- Auto-start = 3 (codegraph, zai-web-reader, zai-web-search); total servers = 8
- Measured (not estimated) token overhead ≤ ~1.5k tokens/session
- Zero bats failures; registry unchanged
- Second review round returns success
