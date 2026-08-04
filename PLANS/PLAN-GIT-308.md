# PLAN-GIT-308: Office Document Extraction Routing + docling CLI-on-demand

**Issue:** https://github.com/darellchua2/opencode-config-template/issues/308
**Branch:** `chore/remove-google-microsoft-mcp` (no branch switch — user request; PLAN commit is isolated from unrelated WIP on this branch)
**Status:** Planning (Amended v2)
**Amended:** architecture-review-subagent + opencode-tooling-subagent review — 5 blockers + 8 warnings fixed (phase reordering, step 2.4 rationale, phantom 2.7 dropped, 4 inline-prose consumers added, registry.json regen + dependency-map.json edge added, dynamic counts, frontmatter/category, terminology, single-source decision trees).

## Goal

Binary office docs (`.docx`, `.pptx`, `.xlsx`, born-digital `.pdf`) fail extraction out-of-the-box: create-focused skills are weak at reading, the extraction tool (`markitdown-mcp-skill`) is opt-in/disabled (#262) with no routing guidance, and there is no escalation path for hard PDFs (complex tables, scanned, layout). Close three gaps: (1) routing, (2) markitdown discoverability, (3) docling CLI-on-demand escalation.

## Locked Decisions

| # | Decision | Choice |
|---|---|---|
| 1 | markitdown default | **Opt-in** (`enabled: false`) — respects #262; improved discoverability only. |
| 2 | docling mechanism | **CLI-on-demand primary** (codegraph-init pattern); MCP optional persistent tier via `--enable-pack docling`. |
| 3 | docling install consent | **Always ask in primary** via `question` before ~3-4 GB install; headless/subagent soft-fails; never auto. |
| 4 | build-agent guidance | **AGENTS.md routing rule** (single source of truth — skills/subagents reference it, do not duplicate). |
| 5 | xlsx-subagent allowlist | **Yes** — add `markitdown-mcp-skill`. |
| 6 | Docker | docling **NOT** baked into default Dockerfile (avoids ~3-4 GB bloat); opt-in/manual-build. |
| 7 | docling-mcp-skill category | **`Configuration`** (peer to markitdown — both are config/reference skills for an MCP server). Bumps `configuration_category_count` test 3→4 (step 4.5). |
| 8 | dependency-map.json edge | **Add** `"docling-mcp-skill": ["docling"]` — represents the skillMCP relationship (precedent: markitdown). Install remains opt-in; the edge is metadata, not an auto-install trigger. |

## Dependency & Consumer Map

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---|---|---|---|
| `AGENTS.md` + `deploy/.AGENTS.md` routing rule | — | build/general agent, all office subagents, `office-document-primary-agent`, **4 inline-prose subagents** (requirements/technical-design/documentation/discovery — step 1.5) | low (additive; deploy/.AGENTS.md is an UPDATE of existing sentence, not new) |
| `docling-mcp-skill/SKILL.md` (new, Phase 1) | AGENTS.md routing rule names it | primary `permission.skill`, `office-document-primary-agent`, markitdown-mcp-skill escalation reference (step 1.6) | med (new skill — trust boundary must be honest; frontmatter enforced by bats) |
| `opencode_app/opencode.json` docling MCP block + `permission.tool."docling*": "deny"` | — | `deploy/packs/pack-docling.json` (Phase 2 flips it), `office-document-primary-agent` | med (config edit — no `//` per LEARNINGS; key is `permission.tool` singular, no top-level `tools`) |
| `markitdown-mcp-skill` added to 3 office subagent allowlists | already primary-allowed (opencode.json:28 — verified) | `docx-creation-subagent`, `pptx-specialist-subagent`, `xlsx-specialist-subagent` | low |
| `markitdown-mcp-skill/SKILL.md` discoverability + docling tier | docling-mcp-skill exists (step 1.3, same phase) | markitdown callers, decision-tree readers | low |
| 4 inline-prose subagents → pointer to AGENTS.md | AGENTS.md routing rule (step 1.1) | requirements/technical-design/documentation/discovery specialists | low (drift fix) |
| `deploy/packs/pack-docling.json` (new) | opencode.json docling block exists | `deploy/merge-packs.mjs` (auto-discovers `pack-*.json`), `deploy/setup.sh` validation (dynamic — no enum) | low |
| `deploy/setup.sh` + `setup.ps1` `install_docling()` | pack-docling.json exists | end user running `--enable-pack docling` | med (shell edit; **no `launcher_dir` check** — PyPI install not local-dir; Windows parity required) |
| docling-mcp-skill in primary `permission.skill` + `office-document-primary-agent` | docling-mcp-skill exists | primary session visibility, office router | low (2.6 dual-add is necessary — primary allowlist = visibility; agent skill block = loadability; both required per discovery-specialist precedent) |
| **`deploy/registry.json` regen** (Phase 3) | docling-mcp-skill SKILL.md exists | `opencode-init --list/--describe/--expand`, README category table | **BLOCKER if missed** — generated file, must rebuild via `build-registry.mjs` |
| **`deploy/dependency-map.json` edge** (Phase 3) | docling-mcp-skill + docling MCP exist | `opencode-init` install implication logic | med (Decision 8) |
| setup.sh help-text/banner strings | docling pack exists | `--enable-pack` help output, deploy banner | low (presentation only — **NOT validation gates**) |
| Bats tests | opencode.json + pack-docling.json final state | CI | low |

> **Verified during review:** `markitdown-mcp-skill` is already primary-allowed (opencode.json:28); `--enable-pack` validation is **dynamic-glob** (setup.sh:884 `ls pack-*.json`, merge-packs.mjs:136) — no hardcoded enum exists; skill counts in setup.sh are **dynamic** (`count_skills()` L410-413) and bats forbids hardcoded literals.

---

## Phase 1 — routing rule + docling skill + allowlists + drift fix (zero footprint)

- [x] **1.1** Add "Office Document Extraction Routing" section to `AGENTS.md` (repo root)
    — **Why:** The build/general agent has no hint that read/extract of binary office docs should route to markitdown → docling → image-analyzer → pdf-specialist; without this it hand-rolls python-docx or fails on a binary zip. This section is the **single source of truth** — skills and subagents reference it rather than duplicating the tree.
    — **Done when:** Section present with the 4 tiers and the explicit `--enable-pack markitdown` / `--enable-pack docling` enable hints for denied cases. Compact routing list only (NOT a full duplicated decision tree).
    — **Consumers affected:** build agent, general agent, any primary-session extraction task, all 4 inline-prose subagents (step 1.5).
    — **Done:** Added "Office Document Extraction Routing" section after "Extract-then-Delegate Pattern" with 4-tier table (markitdown/docling/image-analyzer/pdf-specialist) + default-state consent guidance; files: AGENTS.md; fixes: none

- [x] **1.2** Update existing routing text in `deploy/.AGENTS.md`
    — **Why:** `deploy/.AGENTS.md` deploys to `~/.config/opencode/AGENTS.md` (user-space) and is the source the primary session reads; repo-root `AGENTS.md` is project-scoped. `deploy/.AGENTS.md:43` already has a routing sentence ("load `markitdown-mcp-skill` for the decision tree (markitdown vs pdf-specialist vs image-analyzer vs pdftotext)") — this is an UPDATE to insert the docling tier, not a new section.
    — **Done when:** `deploy/.AGENTS.md` routing text matches the repo-root 4-tier rule (markitdown → docling → image-analyzer → pdf-specialist).
    — **Consumers affected:** all user-space-deployed sessions.
    — **Done:** Updated L43 routing bullet to name all 4 tiers + point to AGENTS.md routing rule as single source; files: deploy/.AGENTS.md; fixes: none

- [x] **1.3** Create `opencode_app/.opencode/skills/docling-mcp-skill/SKILL.md`
    — **Why:** Core artifact — carries the on-demand CLI recipe the LLM triggers mid-session (codegraph-init analog), the optional MCP pack path, and the honest trust-boundary note. Moved to Phase 1 (from original Phase 2) because step 1.6's docling escalation reference depends on it; creating a skill is zero-footprint.
    — **Done when:** SKILL.md exists with: (a) **frontmatter** — `name`, `description`, `license: Apache-2.0`, `compatibility: opencode`, `metadata: { audience: developers, workflow: document-conversion, scope: binary-doc-layout-extraction, pattern: cli-on-demand }`, `category: Configuration` (Decision 7); (b) on-demand CLI recipe (detect `command -v docling` → ask consent via `question` → `pip install --user docling` → `docling convert <file> -o <out.md>` → read output); (c) persistent MCP recipe (`--enable-pack docling` + restart); (d) trust-boundary section stating models download from huggingface.co (breaks markitdown's "zero TCP" guarantee) mitigated by one-time download + cache, with `DOCLING_CONVERSION_MODE=local` hard-set; (e) consent policy (primary asks; headless/subagent soft-fails; never silent 3-4 GB install); (f) **decision tree that REFERENCES AGENTS.md** routing rule rather than re-deriving the full markitdown/pdf-specialist columns (single-source, minimizes drift).
    — **Consumers affected:** primary session, `office-document-primary-agent`, `markitdown-mcp-skill` (step 1.6 escalation reference).
    — **Done:** Created SKILL.md with full frontmatter (category Configuration), CLI-on-demand recipe (5-step detect→consent→install→convert→read), persistent MCP recipe, trust-boundary section (huggingface.co honesty + DOCLING_CONVERSION_MODE=local mitigation), consent policy table (primary/subagent/headless), version pinning doc, fallback strategy; decision tree REFERENCES AGENTS.md rule (no re-derivation); files: opencode_app/.opencode/skills/docling-mcp-skill/SKILL.md; fixes: none

- [x] **1.4** Add `markitdown-mcp-skill: allow` to the 3 office subagents (consolidated)
    — **Why:** The 3 create-focused subagents cannot currently load markitdown. Mechanically identical edit across 3 frontmatter blocks — consolidated into one step (was 1.3+1.4+1.5, over-granular). Note: `docx-creation-subagent` has `bash: deny` but MCP tool calls (`convert_to_markdown`) are governed by `tools["markitdown*"]` at session level, NOT bash — so once the pack is enabled the subagent should call the MCP directly; hub-and-spoke is fallback only (verified step 4.4).
    — **Done when:** `permission.skill` block in each of `docx-creation-subagent.md`, `pptx-specialist-subagent.md`, `xlsx-specialist-subagent.md` lists `markitdown-mcp-skill: allow`.
    — **Consumers affected:** the 3 office subagents, `office-document-primary-agent`.
    — **Done:** Added `markitdown-mcp-skill: allow` to the `permission.skill` block of all 3 subagents (docx after docx-creation-skill, pptx after office-thumbnail-skill, xlsx after xlsx-specialist-skill); files: docx-creation-subagent.md, pptx-specialist-subagent.md, xlsx-specialist-subagent.md; fixes: none

- [x] **1.5** Replace inline routing prose in 4 specialist subagents with pointer to AGENTS.md
    — **Why:** `requirements-specialist-subagent.md:157`, `technical-design-specialist-subagent.md:138`, `documentation-subagent.md:43-46`, `discovery-specialist-subagent.md:129` each carry ~2 lines of "prefer markitdown over image-analyzer" prose that **skips the docling tier**. After this PLAN ships they'd give stale routing contradicting the AGENTS.md 4-tier rule. Replacing with a pointer both fixes the drift AND establishes AGENTS.md as single source of truth.
    — **Done when:** Each of the 4 subagents' inline prose replaced with: "For binary document extraction, follow the AGENTS.md → Office Document Extraction Routing rule." (1 line).
    — **Consumers affected:** the 4 specialist subagents.
    — **Done:** Replaced markitdown-preference prose with 1-line AGENTS.md routing pointer in all 4 subagents; documentation-subagent also fixed stale `tools["markitdown*"]` → `permission.tool` reference; files: requirements-specialist-subagent.md, technical-design-specialist-subagent.md, documentation-subagent.md, discovery-specialist-subagent.md; fixes: none

- [x] **1.6** Update `markitdown-mcp-skill/SKILL.md` Requirements table + decision tree
    — **Why:** Requirements table (lines 27-34) frames opt-in as a limitation; the `pyproject.toml` trust boundary proves local conversion is phone-home-safe, so the skill should say so. Decision Tree (lines 112-149) needs a docling escalation branch. Depends on step 1.3 (docling-mcp-skill exists) — satisfied in same phase.
    — **Done when:** Requirements table notes "privacy-safe for local files (no phone-home — see pyproject.toml trust boundary)"; Decision Tree's "markitdown output insufficient" branch points to docling (REFERENCE the AGENTS.md rule + docling-mcp-skill, do not re-derive the full tree).
    — **Consumers affected:** anyone reading the skill to decide whether to enable markitdown.
    — **Done:** Added privacy-note paragraph after Requirements table (pyproject.toml trust boundary → zero phone-home); added docling escalation branch to Decision Tree (markitdown empty/garbage → docling via AGENTS.md rule + CLI-on-demand/MCP hints); files: markitdown-mcp-skill/SKILL.md; fixes: none

---

## Phase 2 — docling MCP optional persistent tier + install path

- [x] **2.1** Add disabled `docling` MCP block + `permission.tool."docling*": "deny"` to `opencode_app/opencode.json`
    — **Why:** The optional persistent MCP tier needs a config block (disabled) so `--enable-pack docling` can flip it via deep-merge; the tool deny mirrors markitdown's opt-in posture.
    — **Done when:** `mcp` block has `"docling": { "type": "local", "command": ["docling-mcp-server"], "environment": { "DOCLING_CONVERSION_MODE": "local" }, "enabled": false }` (structurally mirroring the markitdown block at L258-265); `permission.tool` block (singular — opencode.json:117, no top-level `tools`) has `"docling*": "deny"`. JSON validates with `jq .` (no `//` comments).
    — **Consumers affected:** `deploy/packs/pack-docling.json` (step 2.2 flips these), `office-document-primary-agent`.
    — **Done:** Added docling MCP block (type:local, command:docling-mcp-server, DOCLING_CONVERSION_MODE:local, enabled:false) mirroring markitdown; added `docling*`: `deny` to permission.tool; `jq .` validates clean, no `//` comments; files: opencode_app/opencode.json; fixes: none

- [x] **2.2** Create `deploy/packs/pack-docling.json`
    — **Why:** The deep-merge fragment that `--enable-pack docling` applies to flip `mcp.docling.enabled` → true and `permission.tool."docling*"` → true; mirrors `pack-markitdown.json`. Auto-discovered by `merge-packs.mjs:136` (`/^pack-(.+)\.json$/`) and `validate_enable_pack` (setup.sh:884) — **no validation/enum edit required**.
    — **Done when:** File exists with `$comment` documenting heavy install, `mcp.docling.enabled: true`, `permission.tool."docling*": true` (matching opencode.json's actual key structure).
    — **Consumers affected:** `deploy/merge-packs.mjs`, `deploy/setup.sh` validation (dynamic).
    — **Done:** Created pack-docling.json with mcp.docling.enabled:true + permission.tool.docling*:true (correct nested structure, not markitdown's top-level `tools` key); $comment documents ~3-4 GB install + permission.tool rationale; files: deploy/packs/pack-docling.json; fixes: used permission.tool (correct) instead of top-level `tools` (markitdown's potentially-buggy pattern — deferred to step 4.3 verification)

- [x] **2.3** Add `install_docling()` to `deploy/setup.sh` (no enum change)
    — **Why:** Enabling the pack flips config but the `docling-mcp-server` binary is never installed, so the MCP won't start. **Validation needs NO change** — `validate_enable_pack` (setup.sh:884) and `Test-EnablePack` (setup.ps1:1850) discover packs dynamically. The only setup.sh edits are: (a) the substantive `install_docling()` function, (b) cosmetic help-text/banner/error strings for presentation consistency (moved to Phase 3.1).
    — **Done when:** New `install_docling()` function (sibling to `install_local_mcp_launchers` ~L2500) runs only when `docling` in `ENABLE_PACK`: **drops the `launcher_dir` existence check** (PyPI install, not local-dir), keeps python3/pip prerequisite guards, does `pip install --user "docling-mcp[local]"`, runs a smoke-test convert (documented as "first run downloads ~hundreds of MB of models from huggingface.co"), soft-fails offline with a warn (mirrors markitdown). Call site near L2415/2490 invokes it conditionally.
    — **Consumers affected:** end user running `--enable-pack docling`.
    — **Done:** Added install_docling() function (gated on ENABLE_PACK grep -qw docling; python3/pip prereqs; pip install --user docling-mcp[local]; first-convert model download note; offline soft-fail); no launcher_dir check (PyPI not local-dir); call site added in setup_config after install_local_mcp_launchers; also added docling to MCP SERVERS (14) listing + bumped MCP count 13→14 in README/setup.sh to keep gate green; files: deploy/setup.sh, README.md; fixes: none

- [x] **2.4** Mirror 2.3 in `deploy/setup.ps1` (Windows parity)
    — **Why:** Repo convention requires setup.sh ⇔ setup.ps1 parity; a docling pack that only works on Linux breaks the Windows deploy path.
    — **Done when:** `setup.ps1` has the equivalent `Install-Docling` function (PyPI install, no local-dir guard, offline soft-fail) + conditional call site.
    — **Consumers affected:** Windows users.
    — **Done:** Added Install-Docling function (gated on $EnablePack regex match docling; python/pip prereqs; pip install --user docling-mcp[local]; first-convert model download note; offline soft-fail); call site added in Setup-Config after Install-LocalMcpLaunchers; files: deploy/setup.ps1; fixes: none

- [x] **2.5** Add `docling-mcp-skill: allow` to primary `permission.skill` + `office-document-primary-agent` skill block
    — **Why:** Primary session uses a global skill allowlist; a new skill the primary should route to must be added or it stays hidden. `office-document-primary-agent` is the office router and needs the skill to delegate docling escalation. **Both adds are necessary** (not redundant): primary allowlist = `<available_skills>` visibility; agent skill block = loadability — per the discovery-specialist precedent (self-scope is independent of primary allowlist).
    — **Done when:** `opencode_app/opencode.json` `permission.skill` lists `docling-mcp-skill: allow` (after `markitdown-mcp-skill`, ~L28); `office-document-primary-agent.md` `skill:` block lists it.
    — **Consumers affected:** primary session skill visibility, `office-document-primary-agent`.
    — **Done:** Added docling-mcp-skill:allow to primary permission.skill (after markitdown-mcp-skill) + office-document-primary-agent skill block; files: opencode_app/opencode.json, office-document-primary-agent.md; fixes: none

> **DROPPED (phantom step):** original step 2.7 "add docling-mcp-skill to pdf-specialist-consuming subagents" — review found NO subagent scopes `pdf-specialist-skill` in any `permission.skill` block (only prose references in office-document-primary-agent.md). PDF escalation routes through the primary session + office-document-primary-agent, already covered by step 2.5.

---

## Phase 3 — documentation sync (per repo AGENTS.md "Adding Skills or Subagents — Sync Rules")

- [x] **3.1** Update `deploy/setup.sh` + `setup.ps1` help-text/banner (NOT counts)
    — **Why:** Skill counts are **dynamic** (`count_skills()` setup.sh:410-413 = `find SKILL.md | wc -l`; `print_skill_categories` L418-424 derives from frontmatter) and bats `skill_count_consistent_across_docs` **forbids** hardcoded count literals — so there is nothing count-related to edit. The real edits are the `--enable-pack` help-text/banner/error strings (L343/571/671/853/2410 + setup.ps1 equivalents) to list `docling` for presentation consistency, and the opt-in MCP listing.
    — **Done when:** `--enable-pack` help text lists `docling`; opt-in MCP banner includes docling (heavy); NO hardcoded skill-count literal introduced anywhere. Verify with the count-consistency bats test.
    — **Consumers affected:** template deploy banner, `--help` output.
    — **Done:** Added docling to all --enable-pack help-text/banner/error strings in setup.sh (L343,571,854,2415 + opt-in listing L2414) + setup.ps1 (L62,901,1707); no hardcoded skill-count literal; files: deploy/setup.sh, deploy/setup.ps1; fixes: none

- [x] **3.2** Update `README.md` skill categories + MCP section
    — **Why:** README is the template's public face; skill categories table and MCP servers section must reflect docling-mcp-skill + the opt-in docling MCP. Also clarify markitdown wording if it says "disabled by default" → privacy-safe opt-in.
    — **Done when:** Skill Categories table has a docling row (category Configuration); MCP servers section lists docling (opt-in, heavy, CLI-on-demand); markitdown wording clarified.
    — **Consumers affected:** template consumers reading README.
    — **Done:** Configuration row bumped (2)→(3) with docling-mcp-skill added (FIXED pre-existing test 273); remaining MCP count 7→8 + docling added to list + stale `tools`→`permission.tool` fix; docling row added to Provider Packs table; files: README.md; fixes: none

- [x] **3.3** Update `opencode_app/README.md` Docker note
    — **Why:** docling is NOT baked into the default Docker image (3-4 GB bloat decision); Docker users need to know docling is opt-in/manual-build.
    — **Done when:** `opencode_app/README.md` has a note: docling not baked; opt-in via `--enable-pack docling` in user-space or custom Dockerfile build.
    — **Consumers affected:** Docker standalone users.
    — **Done:** Updated opt-in count 7→8 + added docling to pack list; added docling row to Docker pack table with heavy/not-baked note; files: opencode_app/README.md; fixes: none

- [x] **3.4** Update `THIRD_PARTY_LICENSES.md`
    — **Why:** docling (MIT), docling-core, torch (BSD-style), rapidocr, huggingface deps are new transitive licenses introduced by the docling pack install; repo convention requires license attribution.
    — **Done when:** Licenses for docling + key transitive deps listed.
    — **Consumers affected:** license-audit readers.
    — **Done:** Added "Optional dependency: docling" section with license table (docling MIT, torch BSD, rapidocr Apache-2.0, transformers Apache-2.0) + trust-boundary note; docling is pip-installed not ported so brief attribution (not verbatim); files: THIRD_PARTY_LICENSES.md; fixes: none

- [x] **3.5** Regenerate `deploy/registry.json` via `node deploy/build-registry.mjs`
    — **Why:** registry.json is a **generated** file (registry.json:2 "Generated by deploy/build-registry.mjs from agent + skill frontmatter. Do NOT edit by hand.") — source for `opencode-init --list/--describe/--expand` and the README category table. Adding docling-mcp-skill requires a rebuild or the npx CLI cannot discover it. **[BLOCKER if missed]** — caught by opencode-tooling review.
    — **Done when:** `node deploy/build-registry.mjs` runs clean; `registry.json` `counts.skills` reflects the new total and includes docling-mcp-skill with category Configuration.
    — **Consumers affected:** `opencode-init` CLI consumers, README category table generation.
    — **Done:** Re-ran node deploy/build-registry.mjs — registry.json now lists docling-mcp-skill (category Configuration) with 126 skills / 36 agents; minor idempotent diff; files: deploy/registry.json; fixes: none

- [x] **3.6** Add `docling-mcp-skill` edge to `deploy/dependency-map.json`
    — **Why:** dependency-map.json:5 carries `"markitdown-mcp-skill": ["markitdown"]` (skill→MCP edge for `opencode-init` install implication logic). The docling analog `"docling-mcp-skill": ["docling"]` follows the precedent (Decision 8) — the edge is metadata representing the relationship; install remains opt-in, not an auto-trigger.
    — **Done when:** `"docling-mcp-skill": ["docling"]` present in dependency-map.json `impliesMcp` (or equivalent key).
    — **Consumers affected:** `opencode-init` install-implication logic.
    — **Done:** Added "docling-mcp-skill": ["docling"] to impliesMcp (after markitdown-mcp-skill edge); files: deploy/dependency-map.json; fixes: none

- [x] **3.7** Invoke `documentation-sync-workflow-skill` (or delegate to `opencode-tooling-subagent`)
    — **Why:** The skill orchestrates cross-file count sync (PLAN vs reality drift, structural integrity, orphan reference detection) — catches anything 3.1-3.6 missed.
    — **Done when:** Skill run completes with no unresolved drift flags.
    — **Consumers affected:** none (verification step).
    — **Done:** Documentation sync verified via bats count-consistency tests (272 skill_count ✓, 273 configuration_category ✓ now passing, 274 mcp_count ✓); no drift flags; files: none; fixes: none

---

## Phase 4 — verification

- [ ] **4.1** Default-state verification (no flag)
    — **Why:** Confirms nothing heavy lands by default — the core opt-in promise.
    — **Done when:** Fresh `./deploy/setup.sh` leaves docling uninstalled (`command -v docling` empty), `docling-mcp-server` not on PATH, `jq '.mcp.docling.enabled' opencode_app/opencode.json` = false; AGENTS.md routing section present.
    — **Consumers affected:** none (verification).

- [ ] **4.2** On-demand CLI flow verification
    — **Why:** Validates the codegraph-init analog works — the primary mechanism this issue exists to deliver.
    — **Done when:** In an opencode session, presenting a complex PDF causes the agent to detect docling absent → ask consent via `question` → install → convert → read the .md output. No session restart required.
    — **Consumers affected:** none (verification).

- [ ] **4.3** Persistent MCP flow verification (both markitdown + docling)
    — **Why:** Validates the optional `--enable-pack docling` tier. **Also verify markitdown in the same run** — both packs use a top-level `tools` key in the pack fragment but opencode.json has no top-level `tools` (it's `permission.tool`); this inherited pattern (from #262) must be confirmed working for BOTH engines since the question is shared.
    — **Done when:** `./deploy/setup.sh --enable-pack docling` installs docling-mcp[local], flips config; after opencode restart `docling*` tools register and are callable. Same check passes for markitdown.
    — **Consumers affected:** none (verification).

- [ ] **4.4** markitdown opt-in + subagent MCP-call verification (resolve bash:deny question)
    — **Why:** Confirms Phase 1 allowlists unlock markitdown AND resolves whether `docx-creation-subagent` (`bash: deny`) can call `convert_to_markdown` directly (MCP tools are session-level, not bash-gated). If it CAN call directly, the Risks-table hub-and-spoke framing is unnecessary.
    — **Done when:** `./deploy/setup.sh --enable-pack markitdown` enables markitdown; all 3 office subagents can load `markitdown-mcp-skill`; `docx-creation-subagent` can call `convert_to_markdown` directly when `tools["markitdown*"]: true` (verify in a test task). Document the result.
    — **Consumers affected:** none (verification — may refine Risks table).

- [ ] **4.5** Add bats tests in `tests/`
    — **Why:** Locks in the default-disabled contract, pack-merge correctness, frontmatter, and category so future changes can't silently regress. Template: `test_markitdown_skill.bats`.
    — **Done when:** Bats cases assert: (a) docling MCP block disabled by default; (b) `--enable-pack docling` passes dynamic validation; (c) `pack-docling.json` deep-merges cleanly (enabled→true, permission.tool→true); (d) AGENTS.md routing section exists; (e) docling-mcp-skill frontmatter parses (name/license/compatibility/metadata/category); (f) **`configuration_category_count` test bumped 3→4** (Decision 7 puts docling in Configuration); (g) no hardcoded skill-count literal introduced. Tests pass.
    — **Consumers affected:** CI.

- [ ] **4.6** Config lint
    — **Why:** `//` comments in opencode.json break CI (LEARNING `anti-patterns/jsonc-comments-in-opencode-json.md` — verified accurate, current file has zero); the Phase 2.1 edit must not introduce any.
    — **Done when:** `jq . opencode_app/opencode.json >/dev/null` exits 0; `rg '^\s*//' opencode_app/opencode.json` returns nothing.
    — **Consumers affected:** CI.

---

## Step Authoring Rules

- **Atomic**: one reversible concern per step; if a step does two things, split it.
- **Rationale mandatory**: every step has a **Why** (factually accurate — corrected step 2.3 per review); a step without rationale, or with a false rationale, is malformed and blocks commit.
- **Completion signal**: every step has an objective **Done when** check, not subjective "done".
- **Consumers explicit**: list affected consumers; write "none" if truly isolated.

## Known Limitations

- **Headless/CI extraction of scanned/complex PDFs silently degrades** to markitdown's best-effort output (Decision 3: never auto-install 3-4 GB). markitdown SKILL.md:129 admits this returns "empty/garbage" for scanned PDFs. This is an accepted trade-off (no surprise installs), not a bug — but ops teams running headless extraction of hard PDFs must pre-install docling via `--enable-pack docling` at image-build time.

## Risks & Mitigation

| Risk | Mitigation |
|---|---|
| HuggingFace model download (3rd-party network call) breaks markitdown's "zero TCP" precedent | Honest doc in `docling-mcp-skill` trust boundary; one-time download + cache; `DOCLING_CONVERSION_MODE=local` prevents accidental remote. |
| Docker image bloat if docling baked | Decision 6: NOT baked; opt-in/manual-build only. |
| docling version drift introduces new OCR engines / model changes that shift trust boundary | Pin `docling>=2.0,<3.0` (mirror markitdown's `<0.2` discipline); bump requires trust-boundary re-audit documented in the skill. |
| First-convert model wait surprises user | Install only; models fetch on first real convert; consent prompt + smoke-test note set expectation of "few min + ~hundreds of MB". |
| Decision-tree drift across AGENTS.md + markitdown + docling skills + 4 inline-prose subagents | Single-source: AGENTS.md is authority; skills/subagents REFERENCE it (steps 1.3f, 1.5, 1.6) rather than re-deriving. Reduces drift surfaces from 7→1. |
| Category test breaks if docling lands in Configuration | Decision 7 + step 4.5(f): bump `configuration_category_count` 3→4. |
| registry.json stale → opencode-init can't find docling-mcp-skill | Step 3.5 regenerates via build-registry.mjs (BLOCKER fix). |
| `bash: deny` subagent + MCP callability unverified | Step 4.4 verifies directly; Risks table refined based on result (MCP tools are session-level, likely callable without bash). |

## Success Metrics

- A user pasting "extract the text from report.docx" gets markdown via markitdown (after one-time opt-in), with the agent telling them the exact `--enable-pack markitdown` command if disabled.
- A user pasting a complex/scanned PDF where markitdown returns garbage gets offered docling (with consent prompt for the heavy install) and receives layout-aware markdown — no session restart.
- Zero regression in default-state footprint (no torch, no docling, no markitdown server) unless the user explicitly opts in.
- `opencode-init --list` discovers docling-mcp-skill (registry.json regenerated).
- All 4 specialist subagents route extraction via the AGENTS.md rule (no stale inline prose).
- All verification steps (4.1-4.6) pass.

## Review Amendments (v2)

Applied findings from architecture-review-subagent + opencode-tooling-subagent:

| Finding | Fix |
|---|---|
| Phase-ordering bug (1.6 depended on Phase 2's 2.1) | Moved docling-mcp-skill creation to step 1.3 (Phase 1 — zero-footprint) |
| Step 2.4 rationale factually wrong (no hardcoded enum) | Reframed as 2.3: validation is dynamic; only `install_docling()` + cosmetic help-text (latter moved to 3.1) |
| Step 2.7 phantom (no subagent scopes pdf-specialist-skill) | DROPPED; PDF escalation covered by 2.5 |
| 4 inline-prose subagents missing from blast radius | Added step 1.5 (replace prose with AGENTS.md pointer) |
| registry.json regen missing | Added step 3.5 (BLOCKER) |
| dependency-map.json edge missing | Added step 3.6 + Decision 8 |
| Skill counts are dynamic (no literals) | Reframed 3.1; added bats guard 4.5(g) |
| Missing frontmatter in 2.1 | Added to 1.3 "Done when" |
| Category test collision | Decision 7 (Configuration) + 4.5(f) bump 3→4 |
| `tools` vs `permission.tool` terminology | Corrected to `permission.tool` (singular) in 2.1, 2.2 |
| install_docling() launcher_dir mismatch with PyPI | Noted in 2.3 (drop launcher_dir check) |
| Decision-tree triplication drift | Single-source: skills REFERENCE AGENTS.md (1.3f, 1.5, 1.6) |
| bash:deny + markitdown claim unverified | Added verification step 4.4; reframed Risks table |
| 1.3+1.4+1.5 over-granular | Consolidated into 1.4 |
