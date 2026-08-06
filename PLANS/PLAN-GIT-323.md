# PLAN-GIT-323 — Add web-search-backed references to reviewer subagents

**Issue:** https://github.com/darellchua2/opencode-config-template/issues/323
**Branch:** `feat/323-reviewer-web-references`
**Labels:** enhancement, subagent, size: M, agents-md

## Overview

Reviewer subagents make findings that sometimes hinge on time-sensitive or version-specific external facts (CVE/CWE numbers, deprecations, framework behavior, contested best-practice claims) but cannot cite authoritative sources, so findings risk being stale or uncorroborated. `webfetch`/`websearch` are built-in opencode tools (default `allow`) that reviewers never use because their prompts never mention them. This change makes the capability explicit in frontmatter and instructs reviewers to back external-authority claims with **fetched** references, with a hard-required rule for CVE/CWE and deprecation findings.

Approach: direct, gated access — no new agent (no README/setup.sh agent-count sync), no MCP changes (built-in tools only).

## Acceptance Criteria

- All 8 reviewers have explicit `webfetch: allow` + `websearch: allow` in frontmatter.
- Each reviewer has a gated "Authoritative References" section (search only for CVE/CWE, deprecation/EOL, documented framework behavior, contested best-practice claims; never for stable fundamentals).
- Hard-required rule: CVE/CWE or deprecation claim MUST carry a fetched reference, else downgraded to `unverified (no source found as of YYYY-MM-DD)`.
- Integrity rule: references only for URLs the reviewer `webfetch`-ed and copied verbatim; ~3–5 lookup cap; deeper sweeps delegate to `autoresearch-research-subagent`.
- Each reviewer Return Contract has `References:` `[{claim, url, retrieved}]`; `code-review-subagent` instructs delegated reviewers to return + aggregate it.
- Repo `AGENTS.md` "Return Contract Convention → Reviewer Additions" documents the new field.

## Scope

- `opencode_app/.opencode/agents/{architecture-review,code-review,python-reviewer,typescript-reviewer,java-reviewer,go-reviewer,rust-reviewer,uiux-reviewer}-subagent.md` (8 files)
- `AGENTS.md` (Return Contract convention block)

## Dependency & Consumer Map

_Blast radius before steps. Agent `.md` files are prompts — no application code imports them; consumers are the agents that spawn/delegate to them._

| Node (file) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---|---|---|---|
| 7 leaf reviewers (`architecture/python/typescript/java/go/rust/uiux`) | — | primary session; `code-review-subagent` (delegates to the 5 language reviewers) | low — additive (new permission + prompt section + return field) |
| `code-review-subagent.md` | — | primary session; delegates to language reviewers | med — orchestrator; gains aggregation note |
| `AGENTS.md` (Return Contract convention) | reviewer Return Contracts exist (Phase 3) | all agents (documents the convention) | low — additive doc line |

## Implementation Phases

_Every step is atomic (one reversible concern) and carries Why / Done when / Consumers affected._

### Phase 1: Permissions — explicit web access in frontmatter

- [ ] **1.1** Add `webfetch: allow` + `websearch: allow` to the `permission` block of all 8 reviewers (`architecture-review`, `code-review`, `python-reviewer`, `typescript-reviewer`, `java-reviewer`, `go-reviewer`, `rust-reviewer`, `uiux-reviewer`)
    — **Why:** capability technically exists by default (`allow`), but making it explicit documents intent, matches the convention already used by 6 non-review agents + `autoresearch-research-subagent`, and survives a future global-default change to `deny`/`ask`.
    — **Done when:** `rg -n "webfetch: allow|websearch: allow" opencode_app/.opencode/agents/*review*.md` shows both keys present in all 8 files (16+ matches).
    — **Consumers affected:** none at runtime (default already allow); benefits future readers + survives config tightening.

### Phase 2: Authoritative References prompt section (gated search policy)

- [ ] **2.1** Add an "Authoritative References" section (before each Return Contract) to all 8 reviewers defining: (a) **search only when** a finding cites a CVE/CWE/advisory, a deprecation/removal/EOL, documented or version-specific framework behavior, or a contested/recent best-practice claim; (b) **never search** for stable fundamentals already known (SOLID, clean-code, syntax, GoF names); (c) **cap** ~3–5 lookups/review, deeper sweeps delegate to `autoresearch-research-subagent`; (d) **integrity** — list a reference only for a URL the reviewer `webfetch`-ed and copied verbatim (no bare `websearch` suggestions), prefer official sources (MDN, framework docs, RFC, CWE/OWASP, CVE DB, upstream changelog), always include retrieval date; (e) **hard-required** — a CVE/CWE-number or deprecation claim MUST carry a fetched reference, else downgrade to `unverified (no source found as of YYYY-MM-DD)` rather than asserting at full severity.
    — **Why:** permission alone changes nothing — the prompt must instruct when/whether to search; the gate bounds cost and the integrity rule prevents hallucinated citations.
    — **Done when:** each of the 8 reviewers contains an "Authoritative References" heading and `rg -n "Authoritative References" opencode_app/.opencode/agents/*review*.md` returns 8 matches.
    — **Consumers affected:** the primary session reading reviewer output (now gets corroborated claims); reviewers themselves.

### Phase 3: Return Contract — References field

- [ ] **3.1** Add a `**References:** \`[{claim, url, retrieved}]\`` field (required when external-authority claims were made; `[]` otherwise) to the Return Contract of the 7 leaf reviewers (`architecture`, `python`, `typescript`, `java`, `go`, `rust`, `uiux`), placed immediately after `Patterns applied/violated`.
    — **Why:** makes the citation requirement machine-visible + consistent across the leaf reviewers that the primary + code-review consume.
    — **Done when:** `rg -n "^\*\*References:\*\*" opencode_app/.opencode/agents/*review*.md` returns ≥8 matches (7 leaves + code-review from 3.2).
    — **Consumers affected:** primary session + `code-review-subagent` (aggregates delegated findings).
- [ ] **3.2** Add the same `References:` field to `code-review-subagent` Return Contract, plus a one-line delegation note: when delegating to a language reviewer, instruct it to return `References:` and aggregate them into code-review's own report.
    — **Why:** code-review is the orchestrator for language-specific reviews; without the aggregation note, delegated citations would be lost.
    — **Done when:** `code-review-subagent.md` Return Contract has `References:` and its delegation section references returning/merging `References:`.
    — **Consumers affected:** primary session (receives one merged citation set).

### Phase 4: Repo docs — AGENTS.md convention

- [ ] **4.1** Update `AGENTS.md` "Return Contract Convention → Reviewer Additions" to document the new `References:` field alongside the existing `Patterns applied/violated` requirement (required when external-authority claims made; `[]` otherwise).
    — **Why:** AGENTS.md is the single source for the return-contract convention; the new field must be discoverable there or it drifts from practice.
    — **Done when:** the "Reviewer Additions" block in `AGENTS.md` mentions `References:`; `rg -n "References:" AGENTS.md` matches within the Return Contract section.
    — **Consumers affected:** all reviewer agents + anyone authoring a new reviewer.

### Phase 5: Verification

- [ ] **5.1** Run a documentation-consistency check (`documentation-consistency-skill` or equivalent) confirming: no agent added/removed (README/setup.sh agent counts unchanged), the 8 reviewer frontmatter blocks are valid YAML, and every "Authoritative References" section + `References:` field is present.
    — **Why:** catches YAML breakage (which would hide the agent from opencode) and count drift before push.
    — **Done when:** consistency check passes; `rg` counts match expectations; spot-check one reviewer renders valid frontmatter.
    — **Consumers affected:** none (verification only).

## Step Authoring Rules

- **Atomic**: one reversible concern per step; if a step does two things, split it.
- **Rationale mandatory**: every step has a **Why**; a step without one is malformed and blocks commit.
- **Completion signal**: every step has an objective **Done when** check, not a subjective "done".
- **Consumers explicit**: list affected consumers; write "none" if truly isolated.

## Technical Notes

- `webfetch`/`websearch` are built-in opencode permissions (default `allow`); explicit `allow` documents intent. Convention established by `nextjs-specialist`, `cad-specialist`, `pptx`, `startup-ceo`, `startup-founder`, `opencode-tooling`, `autoresearch-research-subagent`.
- No new agent → no README/setup.sh agent-count sync; no MCP changes (built-in tools, not `zai-web-reader`/`zai-web-search-prime`).
- `.releaserc.json` exists + `.opencode/branch-workflow-skipped` present → no branch-workflow setup.

## Dependencies

None external. Built on existing built-in `webfetch`/`websearch` tooling.

## Risks & Mitigation

| Risk | Mitigation |
|---|---|
| Hallucinated URLs | Integrity rule: cite only URLs actually `webfetch`-ed + copied verbatim + retrieval date |
| Cost / latency of web calls per review | ~3–5 lookup cap + "external-authority only" trigger; deeper sweeps delegate |
| Stale references | Retrieval date makes staleness explicit; reviewers note "as of retrieved date" |
| Frontmatter YAML breakage hides agent | Phase 5 YAML validity check before push |

## Success Metrics

- All 8 reviewers can produce web-backed references for external-authority findings.
- CVE/CWE and deprecation findings never asserted at full severity without a fetched source.
- No increase in agent count; README/setup.sh counts unchanged.
