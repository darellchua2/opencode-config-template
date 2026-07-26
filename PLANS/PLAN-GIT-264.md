# Plan: Add markitdown-mcp-skill + update office-document-primary-agent, documentation-subagent, and 3 doc-reader specialists

## Ticket Reference
- Platform: GitHub
- ID: #264
- URL: https://github.com/darellchua2/opencode-config-template/issues/264
- Branch: GIT-264

## Acceptance Criteria
- [x] `opencode_app/.opencode/skills/markitdown-mcp-skill/SKILL.md` exists with **rich frontmatter** (`name`, `description` with embedded trigger phrases, `license: Apache-2.0`, `compatibility: opencode`, `metadata: { audience, workflow }`) — peer to `nextjs-devtools-mcp-skill` / `mermaid-diagram-creator-skill`, NOT the minimal `codegraph-setup-skill` pattern
- [x] SKILL.md contains peer-conventional sections: Setup, **MCP Tools Available After Setup** (listing exact tool name `convert_to_markdown`), Format Coverage table, Decision Tree, Usage Patterns, **Troubleshooting**, **Fallback Strategy (No MCP)**, Privacy Guarantees
- [x] Decision tree distinguishes: markitdown (fast text dump of born-digital docs) vs `pdf-specialist-skill` (structured/forms/OCR/edit) vs `image-analyzer-subagent` (visual understanding of charts/screenshots/layout) vs `pdftoppm`+image-analyzer chain (scanned/image-only PDFs) vs built-in `Read` (plain text)
- [x] `office-document-primary-agent.md` Routing Matrix uses peer-conventional row format: `| READ/EXTRACT text from .docx/.pptx/.xlsx (born-digital) | Load markitdown-mcp-skill → call markitdown MCP |` (NOT "Direct MCP call" — that breaks convention)
- [x] `office-document-primary-agent.md` `permission.skill` block adds `markitdown-mcp-skill: allow` (this governs SKILL LOADING, distinct from MCP tool access)
- [x] Trigger phrases added to `office-document-primary-agent.md` are scoped to office binaries (`.docx`/`.pptx`/`.xlsx`) — does NOT claim `.pdf` routing (that collides with `pdf-specialist-skill`)
- [x] `documentation-subagent.md` mentions markitdown in workflow + adds `markitdown-mcp-skill: allow` to `permission.skill`
- [x] `requirements-specialist-subagent.md`, `technical-design-specialist-subagent.md`, `discovery-specialist-subagent.md` get a workflow note: "When reading source PDFs/DOCX/PPTX, prefer markitdown MCP over image-analyzer-subagent for text-heavy content (faster, preserves text fidelity)"
- [x] MCP tool access documented as **session-inherited** from `opencode.json` `tools["markitdown*"]` (do NOT add `markitdown*` to any agent's permission block — no precedent, decided in #262)
- [x] `deploy/setup.sh` skill count bumped (verify actual count after creation; no pre-existing drift per tooling review)
- [x] `deploy/setup.ps1` Windows parity: same count bump
- [x] **`opencode_app/README.md:26` count bumped** (123 → 124) — listed in AGENTS.md sync table line 78; PLAN original draft missed this
- [x] `README.md` skill categories table: add `markitdown-mcp-skill` under **Configuration** category (peer to `codegraph-setup-skill`, `microsoft-m365-config-skill`) — count `Configuration (2)` → `(3)`. NOT Documentation, NOT a new "MCP Helpers" sub-section
- [x] `deploy/.AGENTS.md` — add proactive-load note (peer to `codegraph-setup-skill`'s proactive trigger): "When an agent encounters a `.docx`/`.pptx`/`.xlsx`/born-digital `.pdf` and needs text extraction, load `markitdown-mcp-skill`"
- [x] SKILL.md validated via `python3 -c "import yaml; yaml.safe_load(open('...').read().split('---')[1])"` (frontmatter parses)
- [x] bats test (peer to `tests/test_mcp_count_consistency.bats`) asserts: skill exists, frontmatter parses, required sections present, exact MCP tool name referenced
- [x] Cross-file skill count consistency verified via grep checklist

---

## Dependency & Consumer Map

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---------------------|---------------------------|---------------------------------|-------------|
| `opencode_app/.opencode/skills/markitdown-mcp-skill/SKILL.md` | markitdown MCP exists (#262 done in v4.1.0) | `build`, `explore`, `general` (auto-discovered); `office-document-primary-agent`, `documentation-subagent`, `requirements-specialist-subagent`, `technical-design-specialist-subagent`, `discovery-specialist-subagent` (after permission grants); setup.sh count | low — new skill, additive |
| `opencode_app/.opencode/agents/office-document-primary-agent.md` | Skill created | All office doc workflows (router); routes READ intent to markitdown | low — additive matrix row + 1 permission entry, no breaking change |
| `opencode_app/.opencode/agents/documentation-subagent.md` | Skill created | documentation generation workflows | low — additive note + 1 permission entry |
| `opencode_app/.opencode/agents/{requirements,technical-design,discovery}-specialist-subagent.md` | Skill created | Doc-reader workflows that today over-use image-analyzer-subagent | low — additive workflow note + 1 permission entry each |
| `deploy/setup.sh` (skill count + Configuration category listing) | Skill created | `--help` output; deploy verification | low — count sync |
| `deploy/setup.ps1` (Windows parity) | Skill created | Windows deploy | low — mirror of setup.sh |
| `opencode_app/README.md:26` (skill directory count) | Skill created | Docker doc readers; AGENTS.md sync table line 78 | low — count bump 123→124 |
| `README.md` (skill categories table, Configuration row) | Skill created | Documentation readers | low — additive row, count 2→3 in Configuration |
| `deploy/.AGENTS.md` (proactive load note) | Skill created | User-level agent routing (deployed to `~/.config/opencode/AGENTS.md`) | low — additive note |

## Implementation Phases

### Phase 1: Create markitdown-mcp-skill

Create the skill SKILL.md under `opencode_app/.opencode/skills/markitdown-mcp-skill/` — peer to `nextjs-devtools-mcp-skill` / `mermaid-diagram-creator-skill` (rich frontmatter + full section structure), NOT the minimal `codegraph-setup-skill` pattern.

- [x] **1.1** Create `opencode_app/.opencode/skills/markitdown-mcp-skill/SKILL.md` with **rich frontmatter** mirroring `nextjs-devtools-mcp-skill/SKILL.md:3-11`
    — **Why:** Rich MCP-helper peers use `license: Apache-2.0`, `compatibility: opencode`, and a `metadata` block. Trigger phrases live INSIDE the `description` string (how discovery works) — not as a separate YAML field.
    — **Done when:** Frontmatter contains: `name: markitdown-mcp-skill`, `description:` (with embedded triggers: "convert PDF/DOCX/PPTX/XLSX to Markdown, extract text from office documents, read binary docs"), `license: Apache-2.0`, `compatibility: opencode`, `metadata: { audience: developers, workflow: document-conversion }`.
    — **Consumers affected:** all agents that auto-discover skills.
- [x] **1.2** Add **Setup** section — the session-level prerequisite (single source of truth)
    — **Why:** The MCP is opt-in (`enabled: false` per #262). State verbatim: (1) flip `mcp.markitdown.enabled` to `true` in `opencode.json`, (2) flip `tools["markitdown*"]` to `true`, (3) run `./deploy/setup.sh` to install the launcher via pip, (4) verify with `markitdown-local-mcp --help`.
    — **Done when:** Setup section states both flips explicitly with line refs into `opencode.json`; mentions the pip install path; notes Docker users get the launcher baked in (no setup needed).
    — **Consumers affected:** agents loading the skill; users enabling the MCP.
- [x] **1.3** Add **MCP Tools Available After Setup** table (peer convention: `codegraph-setup-skill:60`, `nextjs-devtools-mcp-skill:59`, `mermaid:57`)
    — **Why:** Agents need the exact tool name to call it. Currently the PLAN never names it.
    — **Done when:** Table lists exactly one tool: `convert_to_markdown(uri: str) -> str` with its input schema and accepted URI schemes (`file:`, `data:`, `http:`, `https:`).
    — **Consumers affected:** all agents calling the MCP.
- [x] **1.4** Add **Format Coverage** table with output characteristics
    — **Why:** Agents need to know what the converted output looks like to plan post-processing.
    — **Done when:** Table covers PDF/DOCX/PPTX/XLSX/XLS/MSG/HTML/CSV/JSON/XML/EPUB/IPYNB/ZIP + Image EXIF; columns: Format | Local library | Output characteristic (e.g., "XLSX multi-sheet → `## Sheet N` headers", "PPTX → `<!-- Slide number: N -->` separators", "Images → EXIF metadata only, no LLM description").
    — **Consumers affected:** agents deciding whether markitdown output fits their need.
- [x] **1.5** Add **Decision Tree** — concrete routing rules with the pdf-specialist-skill collision resolved
    — **Why:** The tree must distinguish 5 paths, not just 4. Critical: resolve the `.pdf` overlap with `pdf-specialist-skill` (which already triggers on "extract text from PDF").
    — **Done when:** Decision tree covers:
        1. Born-digital `.pdf` / `.docx` / `.pptx` / `.xlsx` needing fast text dump → **markitdown** (fast, preserves text fidelity, ~1s for 50 pages)
        2. Scanned / image-only PDF where `pdftotext` yields nothing → `pdftoppm` → **image-analyzer-subagent** chain (OCR + visual understanding)
        3. Structured PDF / forms / tables / edit / OCR-as-purpose → **pdf-specialist-skill** (purpose-built)
        4. Visual understanding of charts / diagrams / screenshots / layout in any format → **image-analyzer-subagent**
        5. Remote URL → `webfetch` first, then markitdown on the saved file (or pass `https:` URI directly — single fetch, no telemetry)
        6. Plain text / `.md` / `.txt` → built-in **Read** (no conversion needed)
    — **Consumers affected:** all agents choosing between markitdown and alternatives.
- [x] **1.6** Add **Usage Patterns** — batch conversion, large-doc handling, post-processing
    — **Why:** Agents need patterns for non-trivial cases (50-page PDFs, table fidelity loss, multi-sheet XLSX).
    — **Done when:** Section covers: (a) large docs — pass URI directly, markitdown handles streaming; (b) table post-processing — note that complex tables may need re-alignment; (c) batch — loop over URIs (no batch API); (d) when to follow up with image-analyzer-subagent for visual elements within a converted doc.
    — **Consumers affected:** agents doing non-trivial conversions.
- [x] **1.7** Add **Troubleshooting** section (peer convention: `codegraph-setup-skill:99`, `nextjs-devtools-mcp-skill:121`)
    — **Why:** Common failures need documented fixes.
    — **Done when:** Section covers: (a) MCP not connected → verify both `enabled: true` AND `tools["markitdown*"]: true` (two-flip gotcha); (b) launcher not on PATH → run `./deploy/setup.sh` or check `~/.local/bin`; (c) `ImportError` on `youtube_transcript_api` / `azure` → expected, means a cloud-only converter was invoked; (d) large-file timeout → break into page ranges.
    — **Consumers affected:** agents and users debugging.
- [x] **1.8** Add **Fallback Strategy (No MCP)** section (peer convention: `nextjs-devtools-mcp-skill:161`)
    — **Why:** When the MCP is disabled or unavailable, agents still need a path.
    — **Done when:** Section documents fallbacks in priority order: (1) bash `pdftotext` (if installed) for born-digital PDFs, (2) `pdftoppm` + `image-analyzer-subagent` for scanned, (3) `python-docx` / `openpyxl` / `python-pptx` direct (if agent has python and the lib), (4) `image-analyzer-subagent` (universal fallback, slow), (5) tell user "please enable markitdown MCP" with the setup steps.
    — **Consumers affected:** agents in environments without markitdown enabled.
- [x] **1.9** Add **Privacy Guarantees** section — 1-paragraph summary + link to launcher README
    — **Why:** Users evaluating the MCP for company-internal docs need the trust-boundary summary at hand.
    — **Done when:** Section summarizes: structural dep exclusion (no `markitdown[all]`, no Azure/Speech/YouTube deps), `enable_plugins=False` hard-coded, stdio-only transport, version cap `<0.2`, user-supplied HTTP(S) URIs trigger only `requests.get()` (no Microsoft endpoints). Links to `opencode_app/mcp-servers/markitdown-local-mcp/README.md`.
    — **Consumers affected:** security reviewers, company-internal users.
- [x] **1.10** Validate SKILL.md YAML frontmatter parses
    — **Why:** Mechanical guarantee before integration.
    — **Done when:** `python3 -c "import yaml; yaml.safe_load(open('opencode_app/.opencode/skills/markitdown-mcp-skill/SKILL.md').read().split('---')[1])"` exits 0.

### Phase 2: Update office-document-primary-agent

Update `opencode_app/.opencode/agents/office-document-primary-agent.md` to route READ intent for OFFICE BINARIES (not PDF — that collides with `pdf-specialist-skill`).

- [x] **2.1** Add new row to Routing Matrix (line 42-48) using peer-conventional format
    — **Why:** "Direct markitdown MCP call" was alien to the matrix style (every existing row delegates to a subagent or skill). Use "Load markitdown-mcp-skill → call markitdown MCP" to match the skill-loading pattern of `cad-specialist-subagent.md:85-104`. Scope to office binaries ONLY — `.pdf` routing stays with `pdf-specialist-skill` to avoid the collision flagged in arch-C2.
    — **Done when:** Row added: `| READ/EXTRACT text from .docx/.pptx/.xlsx (born-digital) | Load markitdown-mcp-skill → call markitdown MCP |`
    — **Consumers affected:** all office doc READ workflows.
- [x] **2.2** Update Trigger Phrases (line 33-38) — scope to office binaries
    — **Why:** Original draft's "summarize PDF" / "extract text from" collided with `pdf-specialist-skill` which already owns those triggers. Scope new phrases to `.docx`/`.pptx`/`.xlsx`.
    — **Done when:** Added: "extract text from .docx", "summarize PowerPoint", "read PPTX content", "find in spreadsheet". NOT added: anything mentioning "PDF" (covered by pdf-specialist-skill). Add a one-line note: "For PDF text extraction, defer to `pdf-specialist-skill`; for fast text dumps of born-digital PDFs, markitdown-mcp-skill is acceptable after enabling."
    — **Consumers affected:** routing accuracy.
- [x] **2.3** Add `markitdown-mcp-skill: allow` to `permission.skill` block (lines 13-18)
    — **Why:** `permission.skill` governs SKILL LOADING via the Skill tool — distinct from MCP tool access. The agent must be allowed to load the skill to read its decision tree. This is separate from MCP tool access, which is session-inherited.
    — **Done when:** `permission.skill` block contains `markitdown-mcp-skill: allow` (peer to existing `docx-creation-skill: allow`, `xlsx-specialist-skill: allow`).
    — **Consumers affected:** office-document-primary-agent runtime.
- [x] **2.4** Resolve Phase 2.3 ambiguity — document MCP tool inheritance (NO `permission.tool` block)
    — **Why:** Arch-C1: #262 already decided "session-level inheritance, no per-agent MCP grant". Grep confirmed zero subagents in the repo re-declare MCP tool grants. Adding `markitdown*` to a permission block would be unprecedented and wrong.
    — **Done when:** A comment in the frontmatter or routing section states: "MCP tool access is session-inherited from `opencode.json` `tools['markitdown*']`. To enable, flip both `mcp.markitdown.enabled` and `tools['markitdown*']` to `true`."
    — **Consumers affected:** future contributors who might be tempted to add a `permission.tool` block.
- [x] **2.5** Update "What NOT to Handle" section (line 61) — keep PDF creation exclusion, refine PDF read exclusion
    — **Why:** Original "PDF operations → use PDF tools" excluded ALL PDF ops. Now markitdown handles born-digital PDF text extraction, but pdf-specialist-skill still owns structured/forms/edit. Disambiguate.
    — **Done when:** "What NOT to Handle" reads: "PDF creation/editing → use pdf-specialist-skill. PDF structured extraction (forms, tables, OCR-as-purpose) → pdf-specialist-skill. PDF fast text dump of born-digital content → markitdown-mcp-skill (this agent)."
    — **Consumers affected:** routing clarity.

### Phase 3: Update documentation-subagent + 3 doc-reader specialists

Phase 3 expands from just `documentation-subagent` (which arch-I1 flagged as the wrong target — it's scoped to docstrings/README badges) to also cover the three specialists that actually ingest binary source docs: `requirements-specialist-subagent`, `technical-design-specialist-subagent`, `discovery-specialist-subagent` — all of which today over-use `image-analyzer-subagent` for text-heavy content.

- [x] **3.1** Update `documentation-subagent.md` workflow + permissions
    — **Why:** Even though scoped to docstrings/README badges, it occasionally reads source PDFs for documentation extraction. Adding markitdown-awareness + permission is cheap.
    — **Done when:** (a) Add `markitdown-mcp-skill: allow` to `permission.skill` (lines 13-15). (b) Workflow note: "When extracting text from a binary office doc (PDF/DOCX/PPTX) for documentation cross-referencing, prefer markitdown MCP over image-analyzer-subagent (faster, preserves text fidelity). Note: `bash: deny` in this agent's permissions does NOT block MCP tool calls — MCP access is separate from bash."
    — **Consumers affected:** documentation workflows.
- [x] **3.2** Update `requirements-specialist-subagent.md` workflow
    — **Why:** Arch-I1: this agent reads source PDFs (BRDs inputs, stakeholder docs) and currently defaults to `image-analyzer-subagent` for them (lines 16, 149). For text-heavy source docs, markitdown is faster and preserves fidelity.
    — **Done when:** (a) Add `markitdown-mcp-skill: allow` to `permission.skill`. (b) Workflow note near line 149: "When reading source PDFs/DOCX provided by stakeholders, prefer markitdown MCP for text-heavy content. Reserve image-analyzer-subagent for diagrams, charts, or scanned/image-only PDFs."
    — **Consumers affected:** BRD/SRS workflows.
- [x] **3.3** Update `technical-design-specialist-subagent.md` workflow
    — **Why:** Arch-I1: same rationale as 3.2 — this agent reads source specs and currently over-uses image-analyzer-subagent (lines 16, 132).
    — **Done when:** (a) Add `markitdown-mcp-skill: allow` to `permission.skill`. (b) Same workflow note as 3.2, near line 132.
    — **Consumers affected:** TDD workflows.
- [x] **3.4** Update `discovery-specialist-subagent.md` workflow
    — **Why:** Arch-I1: discovery reads client-provided briefs, slide decks, vision docs. Same over-use pattern.
    — **Done when:** (a) Add `markitdown-mcp-skill: allow` to `permission.skill`. (b) Same workflow note, placed near where image-analyzer-subagent is mentioned.
    — **Consumers affected:** Vision document workflows.

### Phase 4: Documentation sync

Update all documentation surfaces per AGENTS.md "Adding Skills or Subagents — Sync Rules" table.

- [x] **4.1** `deploy/setup.sh` skill count — find actual current count, bump by 1; update Configuration category listing if markitdown-mcp-skill belongs there (it does — peer to codegraph-setup-skill)
    — **Done when:** Count string updated (e.g., `SKILLS (124)`); Configuration category listing includes markitdown-mcp-skill if it has a per-category breakdown.
- [x] **4.2** `deploy/setup.ps1` Windows parity — same count bump + category update
    — **Done when:** Mirrors setup.sh.
- [x] **4.3** `README.md` skill categories table — add markitdown-mcp-skill under **Configuration** (count `Configuration (2)` → `(3)`)
    — **Why:** Tooling review: Configuration already holds both MCP-setup peers (`codegraph-setup-skill`, `microsoft-m365-config-skill`). This is the unambiguous home — NOT Documentation, NOT a new "MCP Helpers" sub-section.
    — **Done when:** Table row added under Configuration; count bumped from 2 to 3.
- [x] **4.4** `opencode_app/README.md:26` count bump (123 → 124)
    — **Why:** AGENTS.md sync table line 78 requires this; PLAN original draft missed it (flagged by tooling review).
    — **Done when:** Line 26 reads "124 skill directories" (or whatever the verified count is).
- [x] **4.5** `deploy/.AGENTS.md` — add proactive-load note (peer to `codegraph-setup-skill`'s proactive trigger)
    — **Why:** Make the skill discoverable by primary agents when they encounter binary office docs.
    — **Done when:** Note added in the appropriate routing/AGENTS section: "When an agent encounters a `.docx`/`.pptx`/`.xlsx` or born-digital `.pdf` and needs text extraction, load `markitdown-mcp-skill` for the decision tree."
- [x] **4.6** Run grep checklist to verify cross-file skill count consistency
    — **Done when:** All of the following return consistent counts:
        ```
        rg -n "SKILLS \([0-9]+\)|skills count|skill directories" deploy/ README.md opencode_app/README.md
        rg -n "Configuration \([0-9]+\)" README.md deploy/
        rg -n "markitdown-mcp-skill" deploy/ README.md opencode_app/ opencode_app/.opencode/agents/
        ```

### Phase 5: Verification

- [x] **5.1** SKILL.md frontmatter parses via YAML lint
- [x] **5.2** Skill loads via Skill tool (mock-load by reading SKILL.md and confirming frontmatter + required sections)
- [x] **5.3** Create bats test `tests/test_skill_registry.bats` (peer to `tests/test_mcp_count_consistency.bats`) asserting:
    - `markitdown-mcp-skill` directory exists with valid `SKILL.md`
    - YAML frontmatter parses
    - Required sections present (Setup, MCP Tools Available, Decision Tree, Troubleshooting, Fallback Strategy, Privacy Guarantees)
    - Exact MCP tool name `convert_to_markdown` referenced in the skill
    - All 4 agents (office-document-primary, documentation, requirements-specialist, technical-design-specialist, discovery-specialist) have `markitdown-mcp-skill: allow` in `permission.skill`
    - Cross-file skill count consistency (opencode_app/README.md vs setup.sh vs setup.ps1 vs README.md)
- [x] **5.4** Updated agent frontmatter still parses (all 5 .md files modified in Phases 2-3)
- [x] **5.5** Cross-file skill count consistency grep passes

## Open Questions (need user decision before/during execution)

1. **Confirmed:** markitdown = fast text dump of born-digital PDFs; `pdf-specialist-skill` = structured/forms/OCR/edit. Disambiguation rule accepted as stated in Phase 1.5 + 2.5.
2. **Confirmed:** MCP tool access is session-inherited (no per-agent grants); `permission.skill` grants skill LOADING only (Phase 2.3 + 3.x).
3. **Deferred to future ticket:** #262 Open Question #3 — audio/image scope expansion (HTML/CSV/JSON/XML/EPUB/IPYNB/ZIP converters as explicit skill extras). Out of scope for #264.
4. **Confirmed:** Category = Configuration (peer to `codegraph-setup-skill`/`microsoft-m365-config-skill`). NOT Documentation, NOT new "MCP Helpers".
5. **Note:** `opencode_app/Dockerfile` already pip-installs the markitdown launcher (done in #262 Phase 3.3). No Dockerfile change needed in #264 — only the README count + agent/skill .md files change.
