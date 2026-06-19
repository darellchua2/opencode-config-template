# PLAN: Filesystem MCP doc accuracy + Mandatory post-review learning gate in code-review-subagent

**Issue**: [#214 — Filesystem MCP documentation accuracy + Mandatory post-review learning gate in code-review-subagent](https://github.com/darellchua2/opencode-config-template/issues/214)
**Branch**: `GIT-214`
**Status**: Completed

---

## Summary

Two related improvements scoped from a planning session:

1. **Task 1 — Filesystem MCP documentation:** Originally requested to be "turned on by default". After research, the decision is to **keep it disabled** and instead fix documentation accuracy + record the rationale. Rationale: OpenCode's built-in `read`/`write`/`edit`/`glob`/`grep`/`bash` tools already provide full file I/O, so the `@modelcontextprotocol/server-filesystem` MCP is redundant. Additionally the server command requires allowed-directory path arguments the current config lacks, so enabling out-of-the-box would start broken.
2. **Task 2 — code-review-subagent learning gate:** The `code-review-subagent` currently has a *soft*, optional "Post-Review Learning" section. Add a **mandatory gated step** that, after every review run, systematically detects anti-patterns and triages findings to decide whether they are suitable to persist to `LEARNINGS/`.

> **Key technical finding (critical for Task 2):** Per the [opencode permissions docs](https://opencode.ai/docs/agents/#permissions), the `edit` permission key gates **`write`, `edit`, AND `apply_patch`**. The agent's current `edit: deny` therefore **also blocks `write`** — meaning its existing "Save to LEARNINGS/ markdown" instruction is effectively broken today. The `edit` key accepts a fine-grained object form keyed by **file path** (docs example: `"packages/web/src/content/docs/*.mdx": "allow"`), so write access can be scoped to ONLY `LEARNINGS/` while keeping all other edits denied. **Verified (post-review):** opencode uses **simple-wildcard** matching where `*` matches zero-or-more of any character *including* `/` ([permissions docs §Wildcards](https://opencode.ai/docs/permissions/#wildcards)), and **last matching rule wins** — so `edit: { "*": deny, "LEARNINGS/**": allow }` (order matters) correctly permits writes only under `LEARNINGS/`. The `memory` tool is a separate plugin (`opencode-superlocalmemory`), NOT gated by `edit`, so the "always save to memory" path works regardless.

### Step format (canonical)

```
- [ ] **N.M** <single atomic action — verb + target + outcome>
    — **Why:** <what this unblocks / why it must precede others>
    — **Done when:** <objective, checkable completion signal>
    — **Consumers affected:** <who depends on this; none if N/A>
```

### Files Affected (4 files — modifications only, NO count/deploy sync)

| #  | File | Task | Status |
|----|------|------|--------|
| 1  | `deploy/setup.sh` | 1a — help text accuracy + label clarity | DONE |
| 2  | `deploy/setup.ps1` | 1c — banner accuracy (web-search-prime opt-in) | DONE |
| 3  | `README.md` | 1b — rationale note | DONE |
| 4  | `opencode_app/.opencode/agents/code-review-subagent.md` | 2a/2b/2c — permission + gate + contract | DONE |

---

## Dependency & Consumer Map

Execution flows top-to-bottom (Phase 1 → 2 → 3). Task 1 (Phase 1) and Task 2 (Phase 2) are independent of each other; within Task 2 the steps are strictly ordered.

| Node (file under edit) | Depends on (must be done first) | Consumers (who depends on this node) | Blast radius if changed |
|------------------------|---------------------------------|--------------------------------------|-------------------------|
| `deploy/setup.sh` (help text accuracy) | — (independent) | Users reading `--help`; setup accuracy | Help-text only, no behavior change |
| `deploy/setup.ps1` (banner accuracy) | — (independent; mirrors 1.1) | Windows users reading deploy output; cross-platform consistency | Banner text only, no behavior change |
| `README.md` (filesystem-disabled rationale) | — (independent) | Users evaluating MCP servers; future maintainers | Documentation only |
| `code-review-subagent.md` permission (`edit` → scoped `LEARNINGS/**`) | — (foundation for the gate) | The mandatory learning gate (2.2); every review run that persists learnings | Whether LEARNINGS writes succeed at all |
| `code-review-subagent.md` mandatory learning gate | Permission fix (2.1) | Return Contract (2.3); review pipeline; LEARNINGS knowledge base | What gets persisted per review |
| `code-review-subagent.md` Return Contract | Learning gate (2.2) | Parent agents reading the review result | Reported output shape |

**Key ordering constraints:**
- **2.1 must precede 2.2** — the mandatory gate instructs writing to `LEARNINGS/`, which requires the scoped write permission; without 2.1 the gate's markdown-write path is non-functional (memory-only fallback).
- **2.2 must precede 2.3** — the Return Contract reports learning entries saved, which the gate produces.
- Phase 1 (filesystem docs) is independent of Phase 2 and may be interleaved.
- Phase 3 verification gates merge — it re-checks syntax, counts, glob semantics, and rendering.

---

## Phase 0: Issue & Branch Setup

- [x] **0.1** Create GitHub issue #214 and checkout branch `GIT-214`
    — **Why:** Establishes traceability between the work and a trackable ticket + isolated branch before any file edits.
    — **Done when:** Issue #214 exists at its URL and `git branch --show-current` reports `GIT-214`.
    — **Consumers affected:** All subsequent steps (branch is the commit target).

---

## Phase 1: Filesystem MCP Documentation (Task 1)

- [x] **1.1** Fix the misleading "Auto-start (npx)" section in `deploy/setup.sh` (lines ~548-556): list only the 4 truly-enabled local servers (`codegraph`, `atlassian`, `zai-vision-mcp-server`, `mermaid`) under "Auto-start (local npx servers)"; move `filesystem` and `next-devtools` to a new "Available but disabled (opt-in — set enabled: true in config.json)" block with a redundancy note on `filesystem`. Label uses "local npx servers" (not "enabled by default") so readers don't infer only 4 servers run overall (2 remote servers are enabled too, listed separately)
    — **Why:** The previous help text listed `filesystem` and `next-devtools` as auto-start despite both being `enabled: false`, misrepresenting the actual config to every user running `--help`.
    — **Done when:** `deploy/setup.sh` help shows the two-block split under "Auto-start (local npx servers)" / "Available but disabled (opt-in)" and `bash -n deploy/setup.sh` passes.
    — **Consumers affected:** Users reading setup help; setup accuracy.

- [x] **1.2** Add a rationale note to `README.md` as a compact "### MCP Servers" subsection (placed at the end of "## Configuration Overview", before "## Knowledge Persistence"): list the 6 enabled servers (4 local npx + 2 remote) and state the filesystem MCP is intentionally disabled because OpenCode's built-in file tools provide equivalent I/O; enable per-project only if a specific tool requires MCP filesystem access (and note it needs path args)
    — **Why:** Without the rationale recorded where users discover MCP servers, the disabled state reads as an oversight and invites a future "just enable it" change that reintroduces the redundancy/path-arg problem.
    — **Done when:** `README.md` has an MCP Servers subsection with the intentional-disable rationale referencing built-in file tools + the path-arg caveat.
    — **Consumers affected:** Users evaluating MCP servers; future maintainers.

- [x] **1.3** Fix the same class of inaccuracy in `deploy/setup.ps1`'s deployment banner (~line 1166): the "Remote (needs key)" line lists `web-search-prime`, but `zai-web-search-prime` is `enabled: false` in config. Split into enabled remote servers (`web-reader`, `zread`) vs. an opt-in note for `web-search-prime` to mirror the setup.sh accuracy fix
    — **Why:** Cross-platform consistency is a stated repo value; leaving setup.ps1 inaccurate after fixing setup.sh would reintroduce the exact defect on Windows. Surfaced by the opencode-tooling-subagent plan review.
    — **Done when:** `deploy/setup.ps1` banner lists only enabled remote servers as active and marks `web-search-prime` as opt-in/disabled.
    — **Consumers affected:** Windows users reading the deploy output; cross-platform accuracy.

---

## Phase 2: Code-Review Mandatory Learning Gate (Task 2)

All edits in `opencode_app/.opencode/agents/code-review-subagent.md` (single source of truth, deployed to `~/.config/opencode/agents/` by `deploy/setup.sh`).

- [x] **2.1** Fix the permission blocker (frontmatter, lines ~6-9): change `edit: deny` to the scoped object form `edit: { "*": deny, "LEARNINGS/**": allow }` so the agent can create/update files ONLY under `LEARNINGS/` while all other edits stay denied
    — **Why:** `edit` gates `write`+`edit`+`apply_patch`, so the current `edit: deny` blocks the LEARNINGS markdown writes the existing learning section already instructs — the gate in 2.2 cannot function without this. Scoping to `LEARNINGS/**` preserves the review-only posture for all code.
    — **Done when:** The frontmatter `edit` field is the object form with `LEARNINGS/**: allow` and `*: deny`, and (verified in 3.3) the glob is confirmed to match file paths.
    — **Consumers affected:** The mandatory learning gate (2.2); every review run that persists learnings.

- [x] **2.2** Replace the soft "Post-Review Learning" section (lines ~145-159) with a **Mandatory Post-Review Learning Gate** comprising: (a) anti-pattern & finding triage every run — classify each Critical/Major/Minor issue + positive observation into `anti-pattern|pattern|convention|decision|solution`, explicitly scanning with `react-nextjs-antipatterns-skill`, `code-smells-skill`, `security-audit-skill`; (b) dedup check via `memory(mode: "search")` + `glob LEARNINGS/**/*.md` before writing (bump confidence on match instead of duplicating); (c) write criteria — persist to `LEARNINGS/<category>/` + memory when ANY hold (anti-pattern in 3+ files / finding changes future behavior / non-obvious solution), skip if trivial/duplicate/standard-docs; (d) always persist qualifying findings to the `memory` tool (primary store, not gated by `edit`)
    — **Why:** The current section is advisory ("if warranted") with no rubric, no dedup, and no anti-pattern triage, so learnings are rarely and inconsistently captured; a mandatory gate with a decision rubric is what converts "should" into "must" and makes the user's "determine if suitable to update LEARNINGS" requirement executable every run.
    — **Done when:** The agent file contains a clearly-marked mandatory gate section with all four sub-behaviors (triage / dedup / write-criteria / always-memory) and references the three anti-pattern-detection skills.
    — **Consumers affected:** Return Contract (2.3); review pipeline; LEARNINGS knowledge base.

- [x] **2.3** Update the Return Contract (lines ~224-229) Output line to report learning entries explicitly: `**Output:** [Issue count by severity + file list + learning entries saved: N (anti-patterns/patterns/conventions/decisions)]`
    — **Why:** The Output line already references "learning entries saved" but only as vague text; with the gate now mandatory, the contract must surface a concrete count-by-category so the parent agent can verify learning persistence actually occurred.
    — **Done when:** The Return Contract Output line includes the `learning entries saved: N (...)` segment.
    — **Consumers affected:** Parent agents reading the review result.

---

## Phase 3: Verification

- [x] **3.1** Run `bash -n deploy/setup.sh` to confirm no syntax error was introduced by the help-text edit (1.1)
    — **Why:** The edit sits inside a `cat << EOF` heredoc; a stray quote/indentation would break the script at runtime. Syntax check is the objective signal.
    — **Done when:** `bash -n deploy/setup.sh` exits 0.
    — **Consumers affected:** None (verification gate).

- [x] **3.2** Confirm counts in `deploy/setup.sh`, `deploy/setup.ps1`, and `README.md` are unchanged (modifications only — no agent/skill/MCP added/removed; filesystem stays disabled so MCP totals stay 26 total / 6-enabled)
    — **Why:** This issue's scope is content modifications + one agent edit; touching counts would imply structural additions and trigger unwanted deploy-sync side effects, violating the stated constraint.
    — **Done when:** Skill count, agent count, and MCP counts in the three files match their pre-change values.
    — **Consumers affected:** None (verification gate).

- [x] **3.3** Runtime-confirm the scoped `edit` writes: `edit: { "*": deny, "LEARNINGS/**": allow }` already has strong documentation support (simple-wildcard `*` matches `/`; `edit` matches file paths; last-match-wins — see Summary). Confirm the specific behavior at runtime if an opencode session is available (a one-shot write to `LEARNINGS/test.md` should succeed; a write to `src/test.txt` should be denied). The `memory` tool remains the always-on primary store, so the gate degrades gracefully even if the path-normalization (relative vs absolute) differs from expectation.
    — **Why:** The docs confirm the mechanism, but only a live run confirms this project's exact path form (relative `LEARNINGS/...` vs absolute). This is a confidence check, not a blocker.
    — **Done when:** Either a runtime write confirms the scoping, OR (if no live session is available) the documented mechanism is accepted as sufficient given the memory-tool fallback.
    — **Consumers affected:** None (verification gate).

- [x] **3.4** Markdown-render sanity check: confirm the new gate section, the scoped `edit` frontmatter object, and the Return Contract Output line render/parse as intended in `code-review-subagent.md`
    — **Why:** YAML frontmatter with an inline object and the multi-line gate block must survive parsing; a malformed frontmatter would disable the agent entirely.
    — **Done when:** The agent file's frontmatter is valid YAML and the gate section renders without broken structure.
    — **Consumers affected:** None (verification gate).

---

## Risks & Mitigations

| Risk | Mitigation |
|------|------------|
| `edit` glob does not scope to `LEARNINGS/**` (path-normalization: relative vs absolute) | **Mechanism verified against docs** (simple-wildcard `*` matches `/`, last-match-wins). 3.3 runtime-confirms the exact path form; the `memory` tool is the always-on primary store, so the gate degrades (not breaks) if path form differs. |
| Scoped `edit` widens the review agent's write surface | Limited to `LEARNINGS/**` only; all code edits stay `deny`. Acceptable trade-off for enabling learning persistence. |
| Mandatory gate adds latency/overhead to every review | Dedup check + write criteria skip trivial/duplicate findings; memory writes are cheap; markdown writes only when the rubric's criteria are met. |
| Count drift introduced by accident | 3.2 re-confirms counts against pre-change baseline before merge. |
| README rationale note location/wording drifts from existing style | 1.2 adds a compact "### MCP Servers" subsection mirroring existing table/note style under Configuration Overview. |
| `next-devtools` / `web-search-prime` share the enabled-listed-as-available inaccuracy | 1.1 (setup.sh) and 1.3 (setup.ps1) move both to opt-in/disabled, resolving cross-platform. |
| `LEARNINGS/**` vs `LEARNINGS/*` confusion | Equivalent under opencode simple-wildcard (`*` matches `/`); `**` kept to match opencode's own docs house style (`~/projects/personal/**`). |

---

*Plan authored in the atomic+rationale format defined by `ticket-plan-workflow-skill`. Tracking progress with `plan-updater-skill`.*

---

## Review Revisions (opencode-tooling-subagent review)

Incorporated findings from the plan review (verdict: APPROVE-WITH-CHANGES). All core technical claims were independently verified.

**Verified correct (no change needed):**
- `edit` gates `write`+`edit`+`apply_patch`; object form matches file paths; `memory` not gated by `edit`.
- All line refs (6-9, 145-159, 224-229) accurate; all 4 gate skills already permitted.
- "No count/deploy sync needed" confirmed against AGENTS.md rules.
- All steps carry Why/Done-when/Consumers; Dependency & Consumer Map internally consistent.

**Revisions applied:**
1. **(Major → done)** Added step **1.3** — fix the same-class inaccuracy in `deploy/setup.ps1` banner (`web-search-prime` listed as available but `enabled: false`). Files Affected updated to 4 files.
2. **(Major → done)** Downgraded step **3.3** — docs DO show a file-path `edit` example, so the glob behavior is strongly supported; 3.3 is now a runtime confidence check, not a critical unknown. Summary updated with the verified simple-wildcard mechanism.
3. **(Minor → done)** Relabeled setup.sh block to "Auto-start (local npx servers)" in 1.1 so readers don't infer only 4 servers run overall.
4. **(Minor → noted)** `LEARNINGS/**` kept (not switched to `LEARNINGS/*`): equivalent under opencode simple-wildcard, and `**` matches opencode's own docs house style. Documented in Risks.

**Deferred (not in scope):**
- Live runtime test of the scoped write (3.3) — requires an opencode session; memory tool fallback covers the gap.
- Phase 3 has no behavioral agent-spawn test — acceptable for a PLAN; deferred to QA/manual verification.
