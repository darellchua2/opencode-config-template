# PLAN-GIT-308: Office Document Extraction Routing + docling CLI-on-demand

**Issue:** https://github.com/darellchua2/opencode-config-template/issues/308
**Branch:** `chore/remove-google-microsoft-mcp` (no branch switch — user request; PLAN commit is isolated from unrelated WIP on this branch)
**Status:** Planning

## Goal

Binary office docs (`.docx`, `.pptx`, `.xlsx`, born-digital `.pdf`) fail extraction out-of-the-box: create-focused skills are weak at reading, the extraction tool (`markitdown-mcp-skill`) is opt-in/disabled (#262) with no routing guidance, and there is no escalation path for hard PDFs (complex tables, scanned, layout). Close three gaps: (1) routing, (2) markitdown discoverability, (3) docling CLI-on-demand escalation.

## Locked Decisions

| # | Decision | Choice |
|---|---|---|
| 1 | markitdown default | **Opt-in** (`enabled: false`) — respects #262; improved discoverability only. |
| 2 | docling mechanism | **CLI-on-demand primary** (codegraph-init pattern); MCP optional persistent tier via `--enable-pack docling`. |
| 3 | docling install consent | **Always ask in primary** via `question` before ~3-4 GB install; headless/subagent soft-fails; never auto. |
| 4 | build-agent guidance | **AGENTS.md routing rule.** |
| 5 | xlsx-subagent allowlist | **Yes** — add `markitdown-mcp-skill`. |
| 6 | Docker | docling **NOT** baked into default Dockerfile (avoids ~3-4 GB bloat); opt-in/manual-build. |

## Dependency & Consumer Map

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---|---|---|---|
| `AGENTS.md` + `deploy/.AGENTS.md` routing rule | — | build/general agent, all office subagents, `office-document-primary-agent` | low (additive section) |
| `opencode_app/opencode.json` docling MCP block + `"docling*": deny` | — | `deploy/packs/pack-docling.json` (Phase 2.2 flips it), `office-document-primary-agent`, any subagent calling `docling*` | med (config edit — no `//` per LEARNINGS) |
| `markitdown-mcp-skill` added to subagent allowlists | `opencode_app/opencode.json` primary `permission.skill` already allows it (it does) | `docx-creation-subagent`, `pptx-specialist-subagent`, `xlsx-specialist-subagent` | low |
| `markitdown-mcp-skill/SKILL.md` discoverability + docling tier | docling-mcp-skill exists (Phase 2.1) for the escalation reference | `markitdown-mcp-skill` callers, decision tree readers | low |
| `docling-mcp-skill/SKILL.md` (new) | AGENTS.md routing rule names it | primary `permission.skill`, `office-document-primary-agent`, `pdf-specialist-skill` consumers | med (new skill — trust boundary must be honest) |
| `deploy/packs/pack-docling.json` (new) | opencode.json docling block exists | `deploy/merge-packs.mjs`, `deploy/setup.sh` ENABLE_PACK validation | low |
| `deploy/setup.sh` + `setup.ps1` `install_docling()` + pack enum | pack-docling.json exists | end user running `--enable-pack docling` | med (shell edit — Windows parity required) |
| docling-mcp-skill in primary `permission.skill` | docling-mcp-skill exists | primary session visibility of the skill | low |
| Doc-sync (README, THIRD_PARTY, counts) | all prior phases | template consumers, setup banner | low (mechanical) |
| Bats tests | opencode.json + pack-docling.json final state | CI | low |

---

## Phase 1 — markitdown routing + discoverability + allowlists (zero footprint)

- [ ] **1.1** Add "Office Document Extraction Routing" section to `AGENTS.md` (repo root)
    — **Why:** The build/general agent currently has no hint that read/extract of binary office docs should route to markitdown → docling → image-analyzer → pdf-specialist; without this it hand-rolls python-docx or fails on a binary zip.
    — **Done when:** Section present with the 4 tiers and the explicit `--enable-pack markitdown` / `--enable-pack docling` enable hints for denied cases.
    — **Consumers affected:** build agent, general agent, any primary-session extraction task.

- [ ] **1.2** Mirror the routing section into `deploy/.AGENTS.md`
    — **Why:** `deploy/.AGENTS.md` deploys to `~/.config/opencode/AGENTS.md` (user-space) and is the source the primary session actually reads; the repo-root `AGENTS.md` is project-scoped. Both must carry the rule for it to apply in user-space deploys.
    — **Done when:** `deploy/.AGENTS.md` contains the same routing section (single source of truth: edit deploy version, repo-root copies the relevant rule).
    — **Consumers affected:** all user-space-deployed sessions.

- [ ] **1.3** Add `markitdown-mcp-skill: allow` to `docx-creation-subagent.md` `skill:` block
    — **Why:** `docx-creation-subagent` has `bash: deny` and currently cannot load markitdown to extract text; its description claims "read and analyze existing .docx files" but the skill is unreachable. Adding the allow lets it load the skill and request markitdown calls via the parent (hub-and-spoke).
    — **Done when:** `permission.skill` block in `opencode_app/.opencode/agents/docx-creation-subagent.md` lists `markitdown-mcp-skill: allow`.
    — **Consumers affected:** `docx-creation-subagent`, `office-document-primary-agent` (which delegates to it).

- [ ] **1.4** Add `markitdown-mcp-skill: allow` to `pptx-specialist-subagent.md` `skill:` block
    — **Why:** The pptx subagent can hand-roll `python-pptx` extraction (it has bash) but the routing matrix in `office-document-primary-agent.md:54` says to use markitdown for read/extract; the subagent cannot currently load that skill.
    — **Done when:** `permission.skill` block lists `markitdown-mcp-skill: allow`.
    — **Consumers affected:** `pptx-specialist-subagent`.

- [ ] **1.5** Add `markitdown-mcp-skill: allow` to `xlsx-specialist-subagent.md` `skill:` block
    — **Why:** xlsx reads work natively via openpyxl/pandas, but adding markitdown gives parity (e.g., .xls legacy, .msg, consistent decision tree) — user confirmed "yes for q2".
    — **Done when:** `permission.skill` block lists `markitdown-mcp-skill: allow`.
    — **Consumers affected:** `xlsx-specialist-subagent`.

- [ ] **1.6** Update `markitdown-mcp-skill/SKILL.md` Requirements table + decision tree
    — **Why:** The Requirements table (lines 27-34) currently frames opt-in as a limitation; given the `pyproject.toml` trust boundary proves local conversion is phone-home-safe, the skill should say so so users feel comfortable enabling. Also add docling as the escalation tier in the Decision Tree (lines 112-149).
    — **Done when:** Requirements table notes "privacy-safe for local files (no phone-home — see pyproject.toml trust boundary)"; Decision Tree has a docling escalation branch for "markitdown output insufficient (complex tables, scanned, layout)".
    — **Consumers affected:** anyone reading the skill to decide whether to enable markitdown.

---

## Phase 2 — docling CLI-on-demand (primary) + MCP (optional persistent)

- [ ] **2.1** Create `opencode_app/.opencode/skills/docling-mcp-skill/SKILL.md`
    — **Why:** This is the core artifact — it carries the on-demand CLI recipe the LLM triggers mid-session (the codegraph-init analog), the optional MCP pack path, and the honest trust-boundary note. Without it, routing rule references a non-existent skill.
    — **Done when:** SKILL.md exists with: (a) on-demand CLI recipe (detect `command -v docling` → ask consent via `question` → `pip install --user docling` → `docling convert <file> -o <out.md>` → read output); (b) persistent MCP recipe (`--enable-pack docling` + restart); (c) trust-boundary section stating models download from huggingface.co (breaks markitdown's "zero TCP" guarantee) mitigated by one-time download + cache, with `DOCLING_CONVERSION_MODE=local` hard-set; (d) consent policy (primary asks; headless/subagent soft-fails; never silent 3-4 GB install); (e) decision tree docling vs markitdown vs image-analyzer vs pdf-specialist.
    — **Consumers affected:** primary session, `office-document-primary-agent`, `pdf-specialist-skill` consumers.

- [ ] **2.2** Add disabled `docling` MCP block + `"docling*": "deny"` to `opencode_app/opencode.json`
    — **Why:** The optional persistent MCP tier needs a config block present (disabled) so `--enable-pack docling` can flip it via deep-merge; the tools deny mirrors markitdown's opt-in posture.
    — **Done when:** `mcp` block has `"docling": { "type": "local", "command": ["docling-mcp-server"], "environment": { "DOCLING_CONVERSION_MODE": "local" }, "enabled": false }`; `tools` block has `"docling*": "deny"`. JSON validates with `jq .` (no `//` comments).
    — **Consumers affected:** `deploy/packs/pack-docling.json` (Phase 2.3 flips these), `office-document-primary-agent`.

- [ ] **2.3** Create `deploy/packs/pack-docling.json`
    — **Why:** The deep-merge fragment that `--enable-pack docling` applies to flip `mcp.docling.enabled` → true and `tools."docling*"` → true; mirrors `pack-markitdown.json` structure.
    — **Done when:** File exists with `$comment` documenting heavy install, `mcp.docling.enabled: true`, `tools."docling*": true`.
    — **Consumers affected:** `deploy/merge-packs.mjs`, `deploy/setup.sh` ENABLE_PACK validation.

- [ ] **2.4** Add `docling` to `--enable-pack` enum + `install_docling()` in `deploy/setup.sh`
    — **Why:** Without pack-enum registration, `--enable-pack docling` fails validation; without `install_docling()`, enabling the pack flips config but the `docling-mcp-server` binary is never installed so the MCP won't start.
    — **Done when:** (a) `docling` added to ENABLE_PACK csv enum at L343/571/674/873/2431; (b) new `install_docling()` function (sibling to `install_local_mcp_launchers` ~L2500) runs only when pack requested, does `pip install --user "docling-mcp[local]"`, runs a smoke-test convert, soft-fails offline with a warn (mirrors markitdown soft-fail); (c) call site near L2415/2490 invokes it conditionally.
    — **Consumers affected:** end user running `--enable-pack docling`.

- [ ] **2.5** Mirror 2.4 in `deploy/setup.ps1` (Windows parity)
    — **Why:** Repo convention requires setup.sh  setup.ps1 parity; a docling pack that only works on Linux breaks the Windows deploy path.
    — **Done when:** `setup.ps1` has the equivalent pack-enum entries + `Install-Docling` function + call site.
    — **Consumers affected:** Windows users.

- [ ] **2.6** Add `docling-mcp-skill: allow` to primary `permission.skill` + `office-document-primary-agent` skill block
    — **Why:** Primary session uses a global skill allowlist (80 explicit allows); a new skill the primary should route to must be added or it stays hidden. `office-document-primary-agent` is the office router and needs the skill to delegate docling escalation.
    — **Done when:** `opencode_app/opencode.json` `permission.skill` lists `docling-mcp-skill: allow` (after `markitdown-mcp-skill`, ~L28); `office-document-primary-agent.md` `skill:` block lists it.
    — **Consumers affected:** primary session skill visibility, `office-document-primary-agent`.

- [ ] **2.7** Add `docling-mcp-skill: allow` to `pdf-specialist-skill`-consuming subagents
    — **Why:** PDFs are the primary docling use case (complex tables, scanned, layout); subagents that handle PDFs need the escalation skill available.
    — **Done when:** Identify PDF-handling subagents (via grep for `pdf-specialist-skill` references) and add `docling-mcp-skill: allow` to each `permission.skill` block.
    — **Consumers affected:** PDF-handling subagents.

---

## Phase 3 — documentation sync (per repo AGENTS.md "Adding Skills" rules)

- [ ] **3.1** Update `deploy/setup.sh` + `setup.ps1` counts/banner
    — **Why:** New skill (docling-mcp-skill) bumps skill count 128→129; new MCP server (docling, opt-in) changes the opt-in MCP listing; help text must list `docling` in the `--enable-pack` enum. Repo AGENTS.md mandates setup-script sync on skill/agent add.
    — **Done when:** Skill count references updated to 129; opt-in MCP listing includes docling (heavy); `--enable-pack` help text lists `docling`.
    — **Consumers affected:** template deploy banner, `--help` output.

- [ ] **3.2** Update `README.md` skill categories + MCP section
    — **Why:** README is the template's public face; skill categories table and MCP servers section must reflect docling-mcp-skill + the opt-in docling MCP. Also clarify markitdown wording if it says "disabled by default" → privacy-safe opt-in.
    — **Done when:** Skill Categories table has a docling row; MCP servers section lists docling (opt-in, heavy, CLI-on-demand); markitdown wording clarified.
    — **Consumers affected:** template consumers reading README.

- [ ] **3.3** Update `opencode_app/README.md` Docker note
    — **Why:** docling is NOT baked into the default Docker image (3-4 GB bloat decision); Docker users need to know docling is opt-in/manual-build.
    — **Done when:** `opencode_app/README.md` has a note: docling not baked; opt-in via `--enable-pack docling` in user-space or custom Dockerfile build.
    — **Consumers affected:** Docker standalone users.

- [ ] **3.4** Update `THIRD_PARTY_LICENSES.md`
    — **Why:** docling (MIT), docling-core, torch (BSD-style), rapidocr, huggingface deps are new transitive licenses introduced by the docling pack install; repo convention requires license attribution.
    — **Done when:** Licenses for docling + key transitive deps listed.
    — **Consumers affected:** license-audit readers.

- [ ] **3.5** Invoke `documentation-sync-workflow-skill` (or delegate to `opencode-tooling-subagent`)
    — **Why:** The skill orchestrates cross-file count sync (PLAN vs reality drift, structural integrity, orphan reference detection) — catches anything 3.1-3.4 missed.
    — **Done when:** Skill run completes with no unresolved drift flags.
    — **Consumers affected:** none (verification step).

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

- [ ] **4.3** Persistent MCP flow verification
    — **Why:** Validates the optional `--enable-pack docling` tier for power users.
    — **Done when:** `./deploy/setup.sh --enable-pack docling` installs docling-mcp[local], flips config; after opencode restart `docling*` tools register and are callable.
    — **Consumers affected:** none (verification).

- [ ] **4.4** markitdown opt-in + subagent allowlist verification
    — **Why:** Confirms Phase 1 changes (allowlists + discoverability) actually unlock markitdown for the create-focused subagents.
    — **Done when:** `./deploy/setup.sh --enable-pack markitdown` enables markitdown; `docx-creation-subagent`/`pptx-specialist-subagent`/`xlsx-specialist-subagent` can each load `markitdown-mcp-skill` (no permission denied).
    — **Consumers affected:** none (verification).

- [ ] **4.5** Add bats tests in `tests/`
    — **Why:** Locks in the default-disabled contract and pack-merge correctness so future changes can't silently regress the opt-in posture.
    — **Done when:** Bats cases assert: (a) docling MCP block disabled by default; (b) `--enable-pack docling` passes validation; (c) `pack-docling.json` deep-merges cleanly (enabled→true, tools→true); (d) AGENTS.md routing section exists. Tests pass.
    — **Consumers affected:** CI.

- [ ] **4.6** Config lint
    — **Why:** `//` comments in opencode.json break CI (LEARNINGS anti-pattern `anti-patterns/jsonc-comments-in-opencode-json.md`); the Phase 2.2 edit must not introduce any.
    — **Done when:** `jq . opencode_app/opencode.json >/dev/null` exits 0; `rg '^\s*//' opencode_app/opencode.json` returns nothing.
    — **Consumers affected:** CI.

---

## Step Authoring Rules

- **Atomic**: one reversible concern per step; if a step does two things, split it.
- **Rationale mandatory**: every step has a **Why**; a step without rationale is malformed and blocks commit (enforced by Step 6.5 self-check in `ticket-plan-workflow-skill`).
- **Completion signal**: every step has an objective **Done when** check, not subjective "done".
- **Consumers explicit**: list affected consumers; write "none" if truly isolated.

## Risks & Mitigation

| Risk | Mitigation |
|---|---|
| HuggingFace model download (3rd-party network call) breaks markitdown's "zero TCP" precedent | Honest doc in `docling-mcp-skill` trust boundary; one-time download + cache; `DOCLING_CONVERSION_MODE=local` prevents accidental remote. |
| Docker image bloat if docling baked | Decision: NOT baked (Phase 2 / Decision 6); opt-in/manual-build only. |
| docling version drift introduces new OCR engines / model changes that shift trust boundary | Pin `docling>=2.0,<3.0` (mirror markitdown's `<0.2` discipline); bump requires trust-boundary re-audit documented in the skill. |
| First-convert model wait surprises user | Install only; models fetch on first real convert; consent prompt sets expectation of "few min". |
| Phase 1.3 allows markitdown on a `bash: deny` subagent — it still can't call the MCP directly | Hub-and-spoke: subagent loads skill for knowledge, requests markitdown calls via parent agent (which has bash). Documented in routing rule. |

## Success Metrics

- A user pasting "extract the text from report.docx" gets markdown via markitdown (after one-time opt-in), with the agent telling them the exact `--enable-pack markitdown` command if disabled.
- A user pasting a complex/scanned PDF where markitdown returns garbage gets offered docling (with consent prompt for the heavy install) and receives layout-aware markdown — no session restart.
- Zero regression in default-state footprint (no torch, no docling, no markitdown server) unless the user explicitly opts in.
- All verification steps (4.1-4.6) pass.
