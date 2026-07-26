# Plan: Add markitdown-mcp-skill + update office-document-primary-agent and documentation-subagent routing

## Ticket Reference
- Platform: GitHub
- ID: #264
- URL: https://github.com/darellchua2/opencode-config-template/issues/264
- Branch: GIT-264

## Acceptance Criteria
- [ ] `opencode_app/.opencode/skills/markitdown-mcp-skill/SKILL.md` exists with YAML frontmatter, Trigger Phrases, Setup section, Format Coverage table, Decision Tree, Usage Patterns, Privacy Guarantees section, link back to launcher README
- [ ] Decision tree covers: when to use markitdown vs `image-analyzer-subagent` vs bash `pdftotext`/`pdftoppm` vs built-in `Read`
- [ ] `office-document-primary-agent.md` Routing Matrix has a new row: `READ/EXTRACT text from .pdf/.docx/.pptx/.xlsx` → `Direct markitdown MCP call (after enable)`
- [ ] `office-document-primary-agent.md` permission block grants `markitdown*` access (or documents that it inherits from session-level tools config)
- [ ] `documentation-subagent.md` mentions markitdown as the preferred path for reading source PDFs/DOCX/PPTX when generating docs
- [ ] `deploy/setup.sh` skill count bumped (skills count goes up by 1 — verify actual count after creation)
- [ ] `deploy/setup.ps1` Windows parity: same count bump
- [ ] `README.md` skill categories table updated (markitdown-mcp-skill listed in appropriate category — likely "Documentation" or new "MCP Helpers" sub-section)
- [ ] `deploy/.AGENTS.md` Skill Routing section updated to mention markitdown-mcp-skill auto-discovery
- [ ] Skill follows `_common/` conventions if applicable (check `opencode_app/.opencode/skills/_common/`)
- [ ] SKILL.md validated via `python3 -c "import yaml; yaml.safe_load(open('...').read().split('---')[1])"` (frontmatter parses)
- [ ] `documentation-sync-workflow` skill invoked OR explicit grep checklist confirms counts consistent across setup.sh/setup.ps1/README/AGENTS.md

---

## Dependency & Consumer Map

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---------------------|---------------------------|---------------------------------|-------------|
| `opencode_app/.opencode/skills/markitdown-mcp-skill/SKILL.md` | markitdown MCP exists (PLAN-GIT-262 done) | `build`, `explore`, `general`, `office-document-primary-agent` (auto-discovered); setup.sh count | low — new skill, additive |
| `opencode_app/.opencode/agents/office-document-primary-agent.md` | Skill created | All office doc workflows; routes READ intent to markitdown | low — additive matrix row, no breaking change |
| `opencode_app/.opencode/agents/documentation-subagent.md` | Skill created | documentation generation workflows | low — additive note |
| `deploy/setup.sh` (skill count + category) | Skill created | `--help` output; deploy verification | low — count sync |
| `deploy/setup.ps1` (Windows parity) | Skill created | Windows deploy | low — mirror of setup.sh |
| `README.md` (skill categories table) | Skill created | Documentation readers | low — additive row |
| `deploy/.AGENTS.md` | Skill created | User-level agent routing | low — additive note (if applicable) |

## Implementation Phases

### Phase 1: Create markitdown-mcp-skill

Create the skill SKILL.md under `opencode_app/.opencode/skills/markitdown-mcp-skill/` with full documentation — peer to `codegraph-setup-skill`, `nextjs-devtools-mcp-skill`, `mermaid-diagram-creator-skill`.

- [ ] **1.1** Create `opencode_app/.opencode/skills/markitdown-mcp-skill/SKILL.md` with YAML frontmatter (`name`, `description`, trigger phrases)
    — **Why:** YAML frontmatter is required for OpenCode skill discovery; the `description` field is what appears in the skill list and enables auto-discovery by `build`/`explore`/`general` agents.
    — **Done when:** File exists, starts with `---` delimited YAML block containing at minimum `name: markitdown-mcp-skill` and a `description` field; file is valid Markdown.
    — **Consumers affected:** all agents that auto-discover skills.
- [ ] **1.2** Add Setup section — how to enable markitdown MCP in `opencode.json` (`enabled: true` + `"markitdown*": true`) and install the launcher via `pip install --user --force-reinstall` or `./deploy/setup.sh`
    — **Why:** The MCP is opt-in (`enabled: false` by default per #262). Without clear setup instructions, agents (and users) won't know the prerequisite steps.
    — **Done when:** Setup section documents: (1) flip `enabled: true` in `opencode.json` `mcp.markitdown`, (2) flip `"markitdown*": true` in `tools` block, (3) run `./deploy/setup.sh` to install the launcher via pip, (4) verify with `markitdown-local-mcp --help`.
    — **Consumers affected:** agents loading the skill; users enabling the MCP.
- [ ] **1.3** Add Format Coverage table (PDF/DOCX/PPTX/XLSX/XLS/MSG/HTML/CSV/JSON/XML/EPUB/IPYNB/ZIP + Image EXIF) with output characteristics
    — **Why:** Agents need to know what markitdown CAN convert and what the output looks like (e.g., tables become Markdown tables, images become `![alt](path)` references, multi-sheet XLSX becomes `## Sheet N` headers) to set correct expectations.
    — **Done when:** Table lists all supported formats with one-line output notes per format.
    — **Consumers affected:** all agents using the skill for format selection.
- [ ] **1.4** Add Decision Tree — concrete rules for when to use markitdown vs `image-analyzer-subagent` vs bash `pdftotext`/`pdftoppm` vs built-in `Read`
    — **Why:** This is the core value of the skill — without it, agents still default to vision subagent or bash for binary docs. The decision tree encodes the "TEXT vs VISUAL" distinction and the "installed-everywhere vs not" distinction.
    — **Done when:** Decision tree has at minimum 4 branches: (1) Use markitdown when you need TEXT from a binary office doc, (2) Use `image-analyzer-subagent` when you need VISUAL understanding (charts, diagrams, screenshots, layout), (3) Use bash `pdftotext` only when markitdown output is insufficient AND the doc is text-heavy, (4) Use built-in `Read` for plain text files (.md, .txt, .py, etc.).
    — **Consumers affected:** `office-document-primary-agent` routing, `documentation-subagent` toolkit selection, any agent reading binary office docs.
- [ ] **1.5** Add Usage Patterns — batch conversion, large doc handling, post-processing for table fidelity
    — **Why:** Common patterns beyond a single-file conversion. Large docs (>50 pages) still work via single MCP call (markitdown handles streaming), but agents may want to know about batch workflows and table post-processing.
    — **Done when:** Section covers: single-file conversion (pass URI), batch conversion (loop over URIs), and a note that markitdown handles large docs natively (no page-by-page splitting needed).
    — **Consumers affected:** agents processing multiple or large office docs.
- [ ] **1.6** Add Privacy Guarantees section — 1-paragraph summary + link to `opencode_app/mcp-servers/markitdown-local-mcp/README.md`
    — **Why:** The #262 hardening work (no cloud SDKs, `enable_plugins=false`, version cap) is the trust boundary. The skill must surface this so agents can reassure users when asked about privacy.
    — **Done when:** Section states: local-only converters, no network calls on `file:` URIs, no Azure/LLM dependencies, links to the launcher README for full rationale.
    — **Consumers affected:** agents responding to privacy questions about markitdown.
- [ ] **1.7** Validate SKILL.md YAML frontmatter parses via `python3 -c "import yaml; yaml.safe_load(open('opencode_app/.opencode/skills/markitdown-mcp-skill/SKILL.md').read().split('---')[1])"`
    — **Why:** Malformed YAML frontmatter breaks skill discovery. Mechanical validation catches syntax errors before deploy.
    — **Done when:** Python one-liner exits 0 and prints a dict with `name` and `description` keys.
    — **Consumers affected:** OpenCode skill loader.

### Phase 2: Update office-document-primary-agent

Update the routing agent to recognize READ/EXTRACT intent and route to markitdown MCP.

- [ ] **2.1** Add new row to Routing Matrix (`opencode_app/.opencode/agents/office-document-primary-agent.md` lines 42-48): `| READ/EXTRACT text from .pdf/.docx/.pptx/.xlsx | Direct markitdown MCP call (after enable) |`
    — **Why:** The Routing Matrix currently has no READ row — it only covers create/edit/convert-to-PDF and delegation to specialist subagents. Adding the READ row closes the documented gap where agents have no path to extract text from binary office docs.
    — **Done when:** New table row exists in the Routing Matrix with the exact text above; the markdown table renders correctly.
    — **Consumers affected:** all office doc workflows that need text extraction.
- [ ] **2.2** Update Trigger Phrases (lines 33-38): add "extract text from", "summarize PDF", "read PPTX content", "find in spreadsheet"
    — **Why:** The current trigger phrases are CREATE-focused ("create report", "edit slides", "update spreadsheet"). READ/EXTRACT phrases are missing, so the router may not activate for text extraction requests.
    — **Done when:** Trigger Phrases list includes at least the 4 new READ-focused phrases.
    — **Consumers affected:** agent activation for READ intent.
- [ ] **2.3** Update permission block (lines 5-19): decide whether to grant `markitdown*` explicitly in the skill permission list, or document that MCP tool access is inherited from session-level `tools` config
    — **Why:** Subagents inherit session MCP tools by default (OpenCode behavior), but an explicit grant is clearer for auditability. However, adding per-agent MCP grants is a pattern the repo has not adopted yet (see #262 Open Question #2). The decision should be documented either way.
    — **Done when:** Either (a) a `markitdown*` line appears in the permission block, OR (b) a comment/note in the agent file documents that markitdown access is inherited from session-level `tools` block and the user must opt in at that level.
    — **Consumers affected:** `office-document-primary-agent` tool access.
- [ ] **2.4** Update "What NOT to Handle" section (line 61): remove the implicit "PDF operations" exclusion for text extraction (keep "PDF creation/editing" exclusion)
    — **Why:** The current "What NOT to Handle" says "PDF operations (unless converting from office files) → use PDF tools". With markitdown covering text extraction, this blanket exclusion is stale — text extraction from PDFs IS now in scope. Only PDF creation/editing remains out of scope (that's `pdf-specialist-skill`).
    — **Done when:** "What NOT to Handle" distinguishes between "PDF text extraction" (now in scope via markitdown) and "PDF creation/editing" (still out of scope).
    — **Consumers affected:** routing accuracy.

### Phase 3: Update documentation-subagent

Add markitdown to the documentation subagent's toolkit for reading source binary docs.

- [ ] **3.1** Add markitdown to `documentation-subagent.md` available tools / workflow section for reading source PDFs/DOCX/PPTX when generating docs
    — **Why:** The documentation subagent currently has no path to read binary office docs. When asked to "generate documentation from this PDF spec" or "summarize this DOCX requirements doc", it falls back to vision subagent or fails. Adding a markitdown note gives it the direct text-extraction path.
    — **Done when:** `documentation-subagent.md` mentions markitdown MCP as available for reading binary office source documents.
    — **Consumers affected:** documentation generation workflows involving PDF/DOCX/PPTX source material.
- [ ] **3.2** Add a workflow note: "When asked to summarize or extract from a binary office doc, prefer markitdown MCP over image-analyzer-subagent (faster, preserves text fidelity, cheaper)"
    — **Why:** Without explicit guidance, the documentation subagent may default to the existing pattern of delegating to `image-analyzer-subagent` for binary docs. The note encodes the skill's decision tree in the agent's context.
    — **Done when:** A sentence matching the above guidance appears in the workflow section.
    — **Consumers affected:** documentation subagent routing decisions.

### Phase 4: Documentation sync

Update all documentation surfaces so skill counts and listings are consistent.

- [ ] **4.1** `deploy/setup.sh` skill count — find current count via grep, bump by 1; update category listing if markitdown-mcp-skill starts a new sub-category
    — **Why:** The setup script maintains a skill count in its `--help` output and banner. Adding a new skill requires bumping this count and adding the skill to the appropriate category listing.
    — **Done when:** Skill count is incremented by 1; `markitdown-mcp-skill` appears in the correct category listing.
    — **Consumers affected:** `setup.sh --help` output; deploy verification.
- [ ] **4.2** `deploy/setup.ps1` Windows parity — same count bump and category listing update
    — **Why:** Windows deploy must mirror Linux deploy for consistency.
    — **Done when:** Skill count and category listing match setup.sh.
    — **Consumers affected:** Windows deploy.
- [ ] **4.3** `README.md` skill categories table — add `markitdown-mcp-skill` row (likely under "Documentation" category, or new "MCP Helpers" alongside `codegraph-setup-skill` if precedent exists)
    — **Why:** README skill table is the user-facing catalog. The new skill must appear there.
    — **Done when:** A row for `markitdown-mcp-skill` exists in the skill categories table with correct category and description.
    — **Consumers affected:** documentation readers.
- [ ] **4.4** `deploy/.AGENTS.md` — if it has a Skill Routing section, add markitdown-mcp-skill auto-discovery note
    — **Why:** `deploy/.AGENTS.md` is deployed to `~/.config/opencode/AGENTS.md` as the user-level routing doc. Adding a note ensures agents know the skill exists and when to load it.
    — **Done when:** markitdown-mcp-skill is mentioned in the Skill Routing or equivalent section.
    — **Consumers affected:** all agents (user-level routing).
- [ ] **4.5** Run grep checklist to verify cross-file skill count consistency
    — **Why:** Counts span README, setup.sh, setup.ps1, and AGENTS.md — drift is easy to miss. A direct grep is the mechanical guarantee.
    — **Done when:** Skill count is identical across all files that list it.
    — **Consumers affected:** all documentation surfaces.
- [ ] **4.6** (Optional) Invoke `documentation-sync-workflow` skill OR delegate to `opencode-tooling-subagent` for automated sync verification
    — **Why:** The `documentation-sync-workflow` skill automates the count-check pattern. If available and functional, it provides a safety net beyond manual grep.
    — **Done when:** Either the skill was invoked and confirmed consistency, or a manual grep checklist (4.5) was completed.
    — **Consumers affected:** documentation integrity.

### Phase 5: Verification

Mechanically verify all artifacts are valid and consistent.

- [ ] **5.1** SKILL.md frontmatter parses via `python3 -c "import yaml; yaml.safe_load(open('opencode_app/.opencode/skills/markitdown-mcp-skill/SKILL.md').read().split('---')[1])"`
    — **Why:** Catch YAML syntax errors before deploy. Same check as 1.7 but run after all edits to confirm nothing was broken.
    — **Done when:** Python one-liner exits 0.
    — **Consumers affected:** OpenCode skill loader.
- [ ] **5.2** Skill loads via Skill tool — mock-load by reading SKILL.md and confirming frontmatter
    — **Why:** Confirms the skill is structurally valid for OpenCode's skill loading mechanism (YAML frontmatter + Markdown body).
    — **Done when:** Reading SKILL.md shows valid `---` delimited frontmatter with `name` key.
    — **Consumers affected:** skill discovery.
- [ ] **5.3** bats test — extend `tests/test_autoresearch_skills.bats` or create `tests/test_skill_registry.bats` asserting the skill exists and frontmatter is valid
    — **Why:** Automated regression prevention. The existing bats test already greps skill files; extending it to check the new skill's frontmatter prevents future breakage.
    — **Done when:** A bats test asserts `markitdown-mcp-skill/SKILL.md` exists and its frontmatter contains `name: markitdown-mcp-skill`.
    — **Consumers affected:** CI, future contributors.
- [ ] **5.4** Manual: `opencode --list-skills` includes `markitdown-mcp-skill` (verify after deploy, not block on this)
    — **Why:** End-to-end check that the skill is discoverable by OpenCode at runtime.
    — **Done when:** `opencode --list-skills` output includes `markitdown-mcp-skill`. May be post-merge verification.
    — **Consumers affected:** end users.
- [ ] **5.5** Updated `office-document-primary-agent.md` and `documentation-subagent.md` frontmatter still parses
    — **Why:** Agent edits in Phase 2-3 could introduce YAML syntax errors in the frontmatter block.
    — **Done when:** Both files' frontmatter parses via `python3 -c "import yaml; yaml.safe_load(open('...').read().split('---')[1])"`.
    — **Consumers affected:** agent loading.
- [ ] **5.6** Cross-file skill count consistency grep passes
    — **Why:** Final verification that Phase 4's sync is correct. Repeats 4.5 as a gate.
    — **Done when:** All skill counts match across setup.sh, setup.ps1, README.md, and AGENTS.md.
    — **Consumers affected:** documentation integrity.

## Open Questions (need user decision before execution)

1. **Audio/Image scope expansion (deferred):** #262 Open Question #3 remains deferred to a future ticket. The launcher currently installs Office essentials only (PDF/DOCX/PPTX/XLSX/XLS/Outlook MSG + EXIF-only images). HTML/CSV/JSON/XML/EPUB/IPYNB/ZIP converters are available upstream but not yet in scope. This ticket does NOT change the `pyproject.toml` extras — that's a separate decision.
2. **Per-agent MCP grant pattern:** Phase 2.3 decides whether to add explicit `markitdown*` to the agent's permission block or document inheritance. The repo currently has zero per-agent MCP grants (all MCP access is session-level). Adding one here sets a precedent — worth deciding before execution.
