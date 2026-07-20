# PLAN-GIT-254: Enforce mandatory consumer-coverage gates in reviewer + autoresearch-code agents

**Issue:** [#254](https://github.com/darellchua2/opencode-config-template/issues/254)
**Branch:** `GIT-254`
**Created:** 2026-07-20
**Status:** in progress

---

## Dependency & Consumer Map

| Node (file) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---|---|---|---|
| `code-review-subagent.md:201-227` | — (gold standard, read-only reference) | All 6 reviewer agents (mirrored gate) | none (reference) |
| `architecture-review-subagent.md:98-126` | — (gold standard, read-only reference) | All 6 reviewer agents (mirrored gate) | none (reference) |
| `go-reviewer-subagent.md` | code-review gold standard read | Any Go project review | med |
| `java-reviewer-subagent.md` | code-review gold standard read | Any Java project review | med |
| `python-reviewer-subagent.md` | code-review gold standard read | Any Python project review | med |
| `rust-reviewer-subagent.md` | code-review gold standard read | Any Rust project review | med |
| `typescript-reviewer-subagent.md` | code-review gold standard read | Any TypeScript project review | med |
| `uiux-reviewer-subagent.md` | code-review gold standard read | Any UI/UX design review | med |
| `autoresearch-code-subagent.md` | code-review gold standard read | autoresearch-code loop consumers | med |
| `autoresearch-code-skill/SKILL.md` | autoresearch-code-subagent (protocol must match) | autoresearch-code loop consumers | med |
| 28 `SKILL.md` files (metadata array values) | Audit report in `docs/audits/` | Deployed skill metadata consumers | low |

### Phase-level dependencies

- **Phase 1** (reviewer gates): 6 independent file edits — no cross-file dependencies. All can be done in any order or in parallel.
- **Phase 2** (autoresearch changes): 2 file edits — 2.1 (agent) should precede 2.2 (skill) so the protocol in the skill mirrors the agent's actual flow.
- **Phase 3** (verification): depends on Phases 1 + 2 completing.
- **Phase 4** (metadata convention): independent of Phases 1–3. Can run in parallel or after.

---

## Overview

A blast-radius audit found that only 2 of 8 reviewer subagents enforce a mandatory consumer-coverage gate. The other 6 have soft "fall back to grep/glob/read normally" boilerplate that allows a reviewer to return `success` without inspecting consumers of changed symbols. Additionally, the `autoresearch-code` loop relies solely on its benchmark evaluator and has no consumer-enumeration step before the keep/revert decision — meaning downstream breakage that the benchmark does not exercise goes undetected.

A parallel skill-YAML audit found all 121 `SKILL.md` files are already frontmatter-compliant. The only surviving item is an UNKNOWN-severity question about 28 skills using YAML array values inside `metadata:` while the docs specify a string-to-string map.

---

## Implementation Phases

### Phase 1 — Mandatory Consumer Coverage Gates for Reviewer Agents (6 files)

- [ ] **1.1** Add "Mandatory Consumer Coverage Gate" section to `opencode_app/.opencode/agents/go-reviewer-subagent.md` (~line 108)
  — **Why:** Currently has weak "fall back to grep/glob/read normally" wording that lets the review finish without verifying consumer impact. Must mirror the gold standard gate from `code-review-subagent.md:201-227`.
  — **Done when:** A `### Mandatory Consumer Coverage Gate` (or equivalent heading) section exists with: (a) `codegraph_impact` mandate when `.codegraph/` exists, (b) explicit `grep -r`/`glob` instructions for importers/references when `.codegraph/` is absent, (c) a rule returning `Status: partial` if any changed symbol's consumers were uninspected.
  — **Consumers affected:** Any Go project review run by this agent.

- [ ] **1.2** Add "Mandatory Consumer Coverage Gate" section to `opencode_app/.opencode/agents/java-reviewer-subagent.md` (~line 138)
  — **Why:** Same weak wording issue as 1.1. Java reviewers must trace consumers before declaring success.
  — **Done when:** Same gate structure as 1.1 present in the file. Verify `rg "Status: partial"` matches the new section.
  — **Consumers affected:** Any Java project review run by this agent.

- [ ] **1.3** Add "Mandatory Consumer Coverage Gate" section to `opencode_app/.opencode/agents/python-reviewer-subagent.md` (~line 110)
  — **Why:** Same weak wording issue. Python reviewers must trace consumers (importers, callers, subclass overrides) before declaring success.
  — **Done when:** Same gate structure as 1.1 present. Includes Python-specific grep patterns (e.g., `from <module> import`, `class.*\(<Base>\)`).
  — **Consumers affected:** Any Python project review run by this agent.

- [ ] **1.4** Add "Mandatory Consumer Coverage Gate" section to `opencode_app/.opencode/agents/rust-reviewer-subagent.md` (~line 109)
  — **Why:** Same weak wording issue. Rust reviewers must trace consumers (`use` statements, trait impls, public API surface) before declaring success.
  — **Done when:** Same gate structure as 1.1 present. Includes Rust-specific grep patterns (e.g., `use\s+crate::`, `impl\s+\w+\s+for`).
  — **Consumers affected:** Any Rust project review run by this agent.

- [ ] **1.5** Add "Mandatory Consumer Coverage Gate" section to `opencode_app/.opencode/agents/typescript-reviewer-subagent.md` (~line 117)
  — **Why:** Same weak wording issue. TypeScript reviewers must trace consumers (importers, type references, React component usage) before declaring success.
  — **Done when:** Same gate structure as 1.1 present. Includes TypeScript-specific grep patterns (e.g., `import.*from\s+['"]\./`, `<ComponentName`).
  — **Consumers affected:** Any TypeScript/Next.js project review run by this agent.

- [ ] **1.6** Add "Mandatory Consumer Coverage Gate" section to `opencode_app/.opencode/agents/uiux-reviewer-subagent.md` (~line 111)
  — **Why:** Currently explicitly says "the review still proceeds" even without consumer inspection — this must become a hard gate. UI/UX reviewers must trace which components, layouts, or design tokens depend on changed files before declaring success.
  — **Done when:** Same gate structure as 1.1 present. The existing "the review still proceeds" wording is replaced with a `Status: partial` gate. Includes UI-specific grep/glob (component name references, CSS class usage, design token imports).
  — **Consumers affected:** Any UI/UX design review run by this agent.

### Phase 2 — Autoresearch Consumer-Enumeration Step (2 files)

- [ ] **2.1** Add mandatory consumer-enumeration step to `opencode_app/.opencode/agents/autoresearch-code-subagent.md` (~line 129, CodeGraph Integration section)
  — **Why:** The autoresearch-code loop's benchmark evaluator cannot detect downstream breakage that the benchmark does not exercise. A pre-commit consumer enumeration step catches breakage the benchmark misses (e.g., a renamed function that callers still reference). This mirrors the gold standard from `code-review-subagent.md:201-227` but adapted to the autoresearch loop's keep/revert decision point.
  — **Done when:** A step exists in the iteration flow (between the benchmark evaluate and the keep/revert decision) that: (a) enumerates consumers of changed symbols via `codegraph_callers` or `grep -r`/`glob` when `.codegraph/` is absent, (b) checks each consumer for breakage (syntax errors, missing references, failing imports), (c) forces a **revert** if any consumer is broken even when the benchmark passes. The step is clearly labeled and not conflated with the existing Guard command.
  — **Consumers affected:** Any project using the autoresearch-code loop for optimization.

- [ ] **2.2** Add "Consumer Coverage" sub-step to `opencode_app/.opencode/skills/autoresearch-code-skill/SKILL.md`
  — **Why:** The skill's iteration protocol must document the consumer-enumeration step so it survives skill reloads and is visible to the agent. Must also clarify that the user-defined `Guard` command is necessary but not sufficient — it validates the optimization target, not the downstream consumers.
  — **Done when:** A `#### Consumer Coverage` (or equivalent) sub-step exists within the iteration protocol section (between Evaluate and Keep/Revert). It documents: (a) the consumer enumeration action, (b) the revert-if-broken rule, (c) a note that `Guard` is necessary but not sufficient. Cross-references the agent's implementation in 2.1.
  — **Consumers affected:** Any project using the autoresearch-code loop for optimization.

### Phase 3 — Verification

- [ ] **3.1** Spot-check 2 patched reviewer agents by reading back the gate sections
  — **Why:** Confirm the gate is syntactically correct, the `Status: partial` rule is present, and the grep/glob fallback instructions are explicit (not "normally").
  — **Done when:** At least 2 of the 6 reviewer agents are read back and the gate section contains all three required elements (codegraph_impact mandate, grep/glob fallback, Status: partial rule).
  — **Consumers affected:** Correctness of all reviewer agent edits.

- [ ] **3.2** Spot-check autoresearch agent and skill by reading back the consumer-enumeration step
  — **Why:** Confirm the step is positioned correctly in the iteration flow (between evaluate and keep/revert) and that the revert-if-broken rule is present.
  — **Done when:** Both `autoresearch-code-subagent.md` and `autoresearch-code-skill/SKILL.md` are read back; the consumer-enumeration step exists in the correct position with the revert-if-broken rule.
  — **Consumers affected:** Correctness of autoresearch edits.

- [ ] **3.3** Cross-reference: confirm `autoresearch-ml-*` and `autoresearch-research-*` were NOT modified
  — **Why:** These are explicitly out of scope. Verify no accidental edits.
  — **Done when:** `git diff --name-only` shows no changes to files matching `autoresearch-ml-*` or `autoresearch-research-*`.
  — **Consumers affected:** None (verification-only).

### Phase 4 — Skill Metadata Array-Value Convention (appendix, UNKNOWN severity)

- [ ] **4.1** Decide: normalize 28 skills' array values in `metadata:` to comma-separated strings, OR verify runtime tolerance and document it
  — **Why:** The OpenCode docs specify `metadata:` as a string-to-string map, but 28 skills use array values (e.g., `languages: [typescript, python]`). Runtime tolerance is undocumented. The decision determines whether 28 files need editing.
  — **Done when:** A decision is recorded — either "normalize to comma-separated strings" with rationale, or "runtime tolerates arrays; document it" with evidence (e.g., a test showing the runtime handling both forms).
  — **Consumers affected:** The 28 affected skills (list in `docs/audits/skill-yaml-compliance-audit.md`).

- [ ] **4.2** Apply chosen convention across the 28 affected skills
  — **Why:** If normalizing, all 28 files need the array values converted. If documenting tolerance, the audit report needs a resolution section.
  — **Done when:** If normalizing: all 28 files updated, verified via grep that no array values remain in `metadata:` blocks. If documenting: audit report updated with resolution section.
  — **Consumers affected:** The 28 affected skills, deployed skill metadata consumers.

- [ ] **4.3** Document the decision in `docs/audits/skill-yaml-compliance-audit.md` — append a "Resolution" section
  — **Why:** Future maintainers need to know why the convention was chosen and what was done.
  — **Done when:** A `## Resolution` section exists at the end of the audit report documenting: (a) the decision, (b) the rationale, (c) what was changed, (d) date.
  — **Consumers affected:** Documentation readers, future auditors.

---

## Acceptance Criteria

- [ ] All 6 reviewer agents have a Mandatory Consumer Coverage Gate with grep/glob fallback instructions and a `Status: partial` rule.
- [ ] `autoresearch-code-subagent` and `autoresearch-code-skill` enforce consumer enumeration before keep/revert.
- [ ] Metadata array-value convention is decided and applied (or explicitly waived with reasoning documented).
- [ ] No changes to `autoresearch-ml-*` or `autoresearch-research-*`.

## Out of Scope

- `autoresearch-ml-subagent.md` / `autoresearch-ml-skill` — single-file focus (`train.py`); CodeGraph optional by design.
- `autoresearch-research-subagent.md` / `autoresearch-research-skill` — web-only, bash denied, no code changes.

## References

- Issue: https://github.com/darellchua2/opencode-config-template/issues/254
- Gold standard (reviewer gate): `opencode_app/.opencode/agents/code-review-subagent.md:201-227`
- Gold standard (architecture gate): `opencode_app/.opencode/agents/architecture-review-subagent.md:98-126`
- Audit report: `docs/audits/skill-yaml-compliance-audit.md`
- Repo conventions: `AGENTS.md`, `deploy/.AGENTS.md`

---

*Created for #254 — Mandatory consumer-coverage gates for reviewer + autoresearch-code agents.*
