# PLAN-GIT-323 — Give reviewer subagents web access for package/framework lookups

**Issue:** https://github.com/darellchua2/opencode-config-template/issues/323
**Branch:** `feat/323-reviewer-web-references`
**Labels:** enhancement, subagent, size: M, agents-md

## Overview

Reviewer subagents review code that uses frameworks and packages whose correct usage or version-specific behavior they may not know precisely, but they have no way to look anything up. `webfetch`/`websearch` are built-in opencode tools (default `allow`) that the reviewers never use because their prompts never mention them. This change makes the capability explicit in frontmatter and tells reviewers they may check the web when it would genuinely help a review — verifying current/correct API usage or whether a dependency is the right choice.

No citation regime, no references output, no new agent, no MCP changes. Reviewers search directly.

## Acceptance Criteria

- All 8 reviewers have explicit `webfetch: allow` + `websearch: allow` in frontmatter.
- Each reviewer has a short "Web lookups" note: you may `websearch`/`webfetch` when the code under review uses a framework/package and you want to confirm correct/current usage, whether a dependency is appropriate, or version-specific behavior — prefer official docs, keep it to a few lookups, skip what you already know.
- No change to any Return Contract, no new output field, no AGENTS.md change.

## Scope

- `opencode_app/.opencode/agents/{architecture-review,code-review,python-reviewer,typescript-reviewer,java-reviewer,go-reviewer,rust-reviewer,uiux-reviewer}-subagent.md` (8 files)

## Dependency & Consumer Map

_Blast radius before steps. Agent `.md` files are prompts — no application code imports them; consumers are the agents that spawn/delegate to them._

| Node (file) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---|---|---|---|
| 8 reviewers (frontmatter + note) | — | primary session; `code-review-subagent` (delegates to 5 language reviewers) | low — additive permission + short prompt note |

## Implementation Phases

_Every step is atomic (one reversible concern) and carries Why / Done when / Consumers affected._

### Phase 1: Permissions — explicit web access in frontmatter

- [ ] **1.1** Add `webfetch: allow` + `websearch: allow` to the `permission` block of all 8 reviewers (`architecture-review`, `code-review`, `python-reviewer`, `typescript-reviewer`, `java-reviewer`, `go-reviewer`, `rust-reviewer`, `uiux-reviewer`)
    — **Why:** capability technically exists by default (`allow`), but making it explicit documents intent, matches the convention already used by 6 non-review agents + `autoresearch-research-subagent`, and survives a future global-default change to `deny`/`ask`.
    — **Done when:** `rg -n "webfetch: allow|websearch: allow" opencode_app/.opencode/agents/*review*.md` shows both keys present in all 8 files (16+ matches).
    — **Consumers affected:** none at runtime (default already allow); benefits future readers + survives config tightening.

### Phase 2: Web lookups prompt note

- [ ] **2.1** Add a short "Web lookups" section (before each Return Contract) to all 8 reviewers: you MAY `websearch`/`webfetch` when the code under review uses a framework/package and you want to confirm correct/current usage, whether a dependency is the right choice, or version-specific behavior — prefer official docs, keep it to a few lookups, skip what you already know.
    — **Why:** permission alone changes nothing — the prompt must invite the lookup and bound it lightly.
    — **Done when:** `rg -n "Web lookups" opencode_app/.opencode/agents/*review*.md` returns 8 matches.
    — **Consumers affected:** the primary session reading reviewer output (better-informed findings); reviewers themselves.

### Phase 3: Verification

- [ ] **3.1** Confirm no agent added/removed (README/setup.sh agent counts unchanged), the 8 reviewer frontmatter blocks are valid YAML, and every "Web lookups" section is present. Use `rg`/shell for glob checks (the `glob` tool skips the `.opencode` dot-directory and would false-negative).
    — **Why:** catches YAML breakage (which would hide the agent from opencode) and count drift.
    — **Done when:** `rg` counts match expectations; spot-check one reviewer renders valid frontmatter.
    — **Consumers affected:** none (verification only).

## Step Authoring Rules

- **Atomic**: one reversible concern per step; if a step does two things, split it.
- **Rationale mandatory**: every step has a **Why**; a step without one is malformed and blocks commit.
- **Completion signal**: every step has an objective **Done when** check, not a subjective "done".
- **Consumers explicit**: list affected consumers; write "none" if truly isolated.

## Technical Notes

- `webfetch`/`websearch` are built-in opencode permissions (default `allow`); explicit `allow` documents intent. Convention established by `nextjs-specialist`, `cad-specialist`, `pptx`, `startup-ceo`, `startup-founder`, `opencode-tooling`, `autoresearch-research-subagent`.
- Reviewers search directly — no delegation to other subagents.
- No new agent → no README/setup.sh agent-count sync; no MCP changes; no Return Contract / AGENTS.md changes.
- `.releaserc.json` exists + `.opencode/branch-workflow-skipped` present → no branch-workflow setup.

## Dependencies

None external. Built on existing built-in `webfetch`/`websearch` tooling.

## Risks & Mitigation

| Risk | Mitigation |
|---|---|
| Cost / latency of web calls per review | "a few lookups" + "skip what you already know"; opportunistic, not mandatory |
| Frontmatter YAML breakage hides agent | Phase 3 YAML validity check (using `rg`/shell, not the `glob` tool) |

## Success Metrics

- All 8 reviewers can look up package/framework usage when it helps a review.
- No increase in agent count; README/setup.sh counts unchanged; no Return Contract changes.
