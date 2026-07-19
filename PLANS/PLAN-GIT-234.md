# PLAN: Add java-reviewer-subagent (Java language code reviewer)

**GitHub**: [#234](https://github.com/darellchua2/opencode-config-template/issues/234)
**Branch**: `feat/java-reviewer-subagent`
**Created**: 2026-07-18
**Status**: Complete (all phases implemented, ready to commit)

## Overview

Add a Java-specific code review subagent that mirrors the existing 4 language reviewers (`python-reviewer`, `typescript-reviewer`, `go-reviewer`, `rust-reviewer`). The new subagent sits alongside them and is delegatable from `code-review-subagent` when Java files dominate the review (>60% of files reviewed, or `pom.xml`/`build.gradle` detected).

The repository currently has 4 language-specific reviewer subagents that share an identical scaffolding pattern (`glm-5.1`, `steps: 25`, read-only permission block, shared Code Quality skill allowlist). This ticket extends the same pattern to Java — no new skills, no new MCP servers, no architectural changes.

### Net impact

- **Agents**: +1 (`java-reviewer-subagent`) = **35 → 36** source files.
- **Skills**: +0.
- **Banner count correction**: `deploy/setup.sh` previously read `39` — a stale figure that conflated 35 source files with +4 config-builtins in a non-self-consistent way. Per user decision (2026-07-18), the banner count is **corrected** to the authoritative `ls opencode_app/.opencode/agents/ | wc -l` value: `39` → `36` (35 current files + 1 new = 36). This resolves a pre-existing count drift alongside the addition.

---

## Dependency & Consumer Map

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---|---|---|---|
| `agents/java-reviewer-subagent.md` (NEW) | Existing language-reviewer pattern (reference only) | `code-review-subagent` (delegation), README, setup.sh/ps1 | med |
| `agents/code-review-subagent.md` (EDIT) | `java-reviewer-subagent.md` exists (delegation target must be valid) | Primary agent routing (code review workflow) | low |
| `README.md` (EDIT) | `java-reviewer-subagent.md` exists (listing reflects source) | Documentation readers | low |
| `deploy/setup.sh` (EDIT) | All agent files finalized | setup.ps1 mirror, deployment | med |
| `deploy/setup.ps1` (EDIT) | setup.sh changes | Windows deployment | low |

---

## Implementation Phases

### Phase 1: Create the subagent

- [x] **1.1** Create `opencode_app/.opencode/agents/java-reviewer-subagent.md`
    — **Why:** Core deliverable — the new subagent itself. Must mirror the 4 existing language reviewer scaffolding patterns exactly (model, steps, permissions, skill allowlist) so deployment and routing behave consistently.
    — **Done when:** File exists with: frontmatter `mode: subagent`, `model: zai-coding-plan/glm-5.1`, `steps: 25`, `description:` covering Java code review (Effective Java, concurrency, Spring); permission block (`read: allow`, `edit: deny`, `glob: allow`, `grep: allow`, `bash: deny`, `task: {"*": deny, explore: allow, general: allow}`, `skill: {solid-principles-skill, clean-code-skill, code-smells-skill, continuous-learning-skill, search-first-skill: allow}`); Prompt Defense Baseline (copied verbatim from `go-reviewer-subagent.md`); Java-specific Review Checklist with 10 sections (1. Java Idioms [Effective Java, naming: camelCase methods/PascalCase classes/UPPER_SNAKE constants, `final` where appropriate, package naming], 2. Exceptions [checked vs unchecked, no swallowing, custom hierarchy, try-with-resources], 3. Generics & Types [bounds, no raw types, PECS `<? extends T>`/`<? super T>`, diamond operator], 4. Concurrency [`java.util.concurrent`, proper synchronization, `volatile`/`Atomic*`, `CompletableFuture`, no shared mutable state], 5. Null Handling [`Optional<T>` returns, `Objects.requireNonNull` on params, `@NonNull`/`@Nullable` annotations], 6. Modern Java 11+/17+/21 [records, sealed classes, pattern matching, switch expressions, text blocks, `var` where readable], 7. Streams & Collections [efficient stream chains, `EnumSet`/`EnumMap`, immutable copies, no side effects in streams], 8. Resource Management [try-with-resources for `Closeable`/`AutoCloseable`, no `finalizer`/`cleaner` misuse], 9. Testing [JUnit 5 `@ParameterizedTest` + lifecycle, Mockito patterns, AssertJ fluent assertions, test isolation], 10. Security [input validation, `PreparedStatement` not concatenation, no `Runtime.exec` with user input, no hardcoded secrets]); Framework-Specific Checks table with 4 rows (**Spring Boot**: DI, `@Transactional` boundaries, `@RestController` signatures, proper exception handlers with `@ControllerAdvice`; **Quarkus**: CDI vs Spring DI, native image compatibility, `@Blocking`/`@NonBlocking`; **Micronaut**: compile-time DI, no reflection in native, `@Singleton` scope; **Jakarta EE**: CDI scopes, JPA session management, EJB patterns); Severity Scoring table (Critical/Major/Minor with Java-specific examples — Critical: SQL injection, `Runtime.exec` user input, secret exposure, race condition; Major: missing `Optional`, raw types, unchecked exception leakage, missing `@Transactional`; Minor: naming inconsistency, missing Javadoc on public, unnecessary `var`); CodeGraph Integration clause (copied from Go reviewer — only the language word changes); Output Format block; Return Contract (copied verbatim).
    — **Skill allowlist rationale:** Go and Rust reviewers each have **5 skills** (solid-principles, clean-code, code-smells, continuous-learning, search-first) — NO `design-patterns-skill`. Python (7) and TypeScript (8) include design-patterns because they also carry language-specific extras (`python-backend-skill`, `react-nextjs-antipatterns-skill`, `typescript-dry-principle-skill`). Java has no language-specific skill in this repo, so it mirrors the Go/Rust 5-skill pattern exactly. If a future `java-spring-patterns-skill` is created, add it (and consider adding `design-patterns-skill`) at that time.
    — **Consumers affected:** `code-review-subagent` (1.2), README (2.1), setup.sh (3.1), setup.ps1 (3.2)

### Phase 2: Wire routing

- [x] **2.1** Update `opencode_app/.opencode/agents/code-review-subagent.md`
    — **Why:** `code-review-subagent` is the parent dispatcher for language-specific reviews; without adding Java to its `task` permission and delegation table, the new subagent cannot be invoked through the standard review flow.
    — **Done when:** Two edits applied: (a) In `permission.task` block, add `java-reviewer-subagent: allow` immediately after the `rust-reviewer-subagent: allow` line. (b) In the "Language-Specific Reviewer Delegation" table, add row: `| Java | java-reviewer-subagent | *.java files dominate, or pom.xml/build.gradle detected |` immediately after the Rust row.
    — **Consumers affected:** Anyone invoking code review on a Java codebase

- [x] **2.2** Update `README.md` (Subagents table + prose count at L308)
    — **Why:** README is the primary user-facing documentation; the Subagents table lists every available subagent. Missing the Java row would make it look like the repo still lacks a Java reviewer. Also: README.md:308 contains a prose count ("35 agent .md files (plus 4 config-builtin agents...)") that must update to 36 in lockstep — this was missed initially and surfaced by post-implementation code review.
    — **Done when:** Two edits: (a) In the Subagents table (around line 355, after the `rust-reviewer-subagent` row), add: `| **java-reviewer-subagent** | Java code review (Effective Java, concurrency, Spring) | solid-principles, clean-code, code-smells, continuous-learning | explore, general |`. **Skill column MUST match sibling rows exactly** — the 4 existing language reviewer rows (README lines 352-355) all list only `solid-principles, clean-code, code-smells, continuous-learning` (the README is a simplified projection that omits `design-patterns` and `search-first` for brevity). Do NOT add `design-patterns` to the Java row, even though the agent's actual frontmatter includes `search-first-skill` — match the documented sibling projection. (b) Line 308: change `35 agent \`.md\` files (plus 4 config-builtin...)` to `36 agent \`.md\` files (plus 4 config-builtin...)`. The "plus 4 config-builtin" stays at 4 — only the source `.md` count increments.
    — **Consumers affected:** Documentation readers

### Phase 3: Sync deployment scripts (repo AGENTS.md mandatory sync rule)

- [x] **3.1** Update `deploy/setup.sh`
    — **Why:** Banner + listing must match deployed files; setup.sh is the deploy entrypoint. Also corrects a pre-existing count drift alongside the addition. **IMPORTANT:** setup.sh has **7** stale count references (not 2 as a superficial grep might suggest) — all must be addressed or the banner will internally contradict itself.
    — **Done when:** Three categories of changes:
      **(a) Add Java reviewer to the language listing block** (around line 514): `java-reviewer         Java code review (Effective Java, concurrency, Spring)` immediately after the `rust-reviewer` line.
      **(b) Correct all 7 stale count references.** Verified locations (re-grep before editing — line numbers may drift):
      | Line | Current | New | Math |
      |------|---------|-----|------|
      | 503  | `AGENTS (39):` | `AGENTS (36):` | banner header |
      | 1664 | `echo "✓ Configured 39 agents:"` | `echo "✓ Configured 36 agents:"` | post-install block |
      | 1670 | `echo "    - ... and 34 more agents"` | `echo "    - ... and 31 more agents"` | 36 − 5 shown = 31 |
      | 2218 | `echo "✓ Configured 39 agents:"` | `echo "✓ Configured 36 agents:"` | status block |
      | 2223 | `echo "    - ... and 35 more agents"` | `echo "    - ... and 32 more agents"` | 36 − 4 shown = 32 |
      | 2395 | `echo "🤖 Agents (39):"` | `echo "🤖 Agents (36):"` | Quick Start block |
      | 2401 | `echo "  - ... and 34 more agents"` | `echo "  - ... and 31 more agents"` | 36 − 5 shown = 31 |
      **Math basis:** 36 = current `ls opencode_app/.opencode/agents/ \| wc -l` (35) + 1 new Java file. The "N more" counts are derived: total (36) − explicitly-listed-in-block = remaining. Block at L1664 lists 5 agents → 31 more; block at L2218 lists 4 → 32 more; block at L2395 lists 5 → 31 more.
      **(c) Do NOT touch any other count or listing** — only the 7 lines above + the new listing line at ~514. Other counts (skills, MCP servers) are unchanged by this ticket.
    — **Consumers affected:** Anyone running `setup.sh` or `--help`

- [x] **3.2** Mirror listing + count changes in `deploy/setup.ps1`
    — **Why:** Windows parity — repo AGENTS.md rule states "deploy/setup.ps1 — Mirror of setup.sh (Windows parity)". Original plan deferred banner count citing "Windows drift not verified", but post-implementation code review (`code-review-subagent`) correctly noted this violates the documented rule now that the actual count is known (36, not speculative).
    — **Done when:** Five edits: (a) Listing line addition (around L349): `java-reviewer        Java code review (Effective Java, concurrency, Spring)` after the `rust-reviewer` line. (b) Five banner count corrections: L338 `AGENTS (39):` → `AGENTS (36):`; L1176 `Configured 39 agents:` → `Configured 36 agents:`; L1751 `Agents (39):` → `Agents (36):`; L1757 `and 34 more agents` → `and 31 more agents`. (Note: setup.ps1 post-install block at L1176 lists 5 agents but has NO corresponding "and N more" line, unlike setup.sh — only the 39→36 count needs fixing there.)
    — **Decision reversal:** Original PLAN deferred banner count "avoiding speculative corrections" — reversed after code-review-subagent flagged the documented Windows-parity rule violation. The count is now known (36), so deferral had no justification.
    — **Consumers affected:** Windows users running `setup.ps1`

- [x] **3.3** Update `opencode_app/README.md` (Docker docs)
    — **Why:** Repo AGENTS.md sync rule explicitly lists `opencode_app/README.md` as a file to evaluate on agent changes. This file has TWO stale `35` counts that will become `36` after the new agent is added. Leaving them drifts Docker docs from source.
    — **Done when:** Two edits: (a) Line 25: `├── agents/            # 35 agent .md files (single source of truth)` → `36 agent .md files`. (b) Line 102: `- 22 of 35 agents have explicit \`task\` permissions; the remaining 13 default to full access` → `23 of 36 agents have explicit \`task\` permissions; the remaining 13 default to full access`. (Java reviewer has explicit `task: {"*": deny, explore: allow, general: allow}`, so the explicit-perm count goes 22 → 23; the "default to full access" remainder stays at 13 since the total grew by 1 and the explicit-perm side also grew by 1.) Skill count on line 26 (`106 skill directories`) is unchanged — no skill changes in this ticket.
    — **Consumers affected:** Docker users reading container-mode docs

### Phase 4: Verification

- [x] **4.1** Grep-confirm zero stale references and consistency
    — **Why:** Any leftover references or count mismatches will confuse users and break deploy verification. This ticket introduces `java-reviewer` as a new term and changes counts in multiple files — must verify nothing else needs updating and no stale `39`/`35`/`34` count lingers.
    — **Done when:** Three grep checks all pass:
      (a) `grep -rn "java-reviewer" opencode_app/ deploy/ README.md AGENTS.md` returns matches only in the **5 expected files** (`java-reviewer-subagent.md`, `code-review-subagent.md`, `README.md`, `setup.sh`, `setup.ps1`) and nowhere else.
      (b) `grep -n "39 agents\|39):\|and 3[145] more\|Agents (39)\|AGENTS (39)" deploy/setup.sh` returns **zero matches** (all 7 stale references from step 3.1 must be gone — re-grep after editing to confirm).
      (c) `grep -n "35 agent\|of 35 agents\|22 of" opencode_app/README.md` returns **zero matches** (step 3.3 edits must be applied).
      Plus: `ls opencode_app/.opencode/agents/ | wc -l` == 36.
    — **Consumers affected:** All consumers (correctness gate)

- [x] **4.2** Verify java-reviewer-subagent is structurally valid
    — **Why:** Malformed frontmatter or missing sections will silently break the subagent. A file-exists check is not sufficient.
    — **Done when:** `java-reviewer-subagent.md` has all of the following: (a) frontmatter parses as valid YAML (no tabs, correct indentation); (b) **all 7 sections present** matching Go reviewer scaffolding — 1. Prompt Defense Baseline, 2. Review Checklist (with 10 items), 3. Framework-Specific Checks table (with 4 rows), 4. Severity Scoring table, 5. CodeGraph Integration section, 6. Output Format block, 7. Return Contract; (c) skill allowlist contains **exactly 5 skills** (`solid-principles-skill`, `clean-code-skill`, `code-smells-skill`, `continuous-learning-skill`, `search-first-skill`) — NOT 6, matching Go/Rust sibling pattern exactly (no `design-patterns-skill`).
    — **Consumers affected:** Anyone invoking the subagent

- [x] **4.3** Run `documentation-sync-workflow` skill (or delegate to `opencode-tooling-subagent`)
    — **Why:** Repo AGENTS.md mandates doc sync after agent changes; validates cross-file count consistency.
    — **Done when:** Skill confirms setup.sh, setup.ps1, README, AGENTS.md counts/listings are mutually consistent.
    — **Consumers affected:** Documentation integrity

---

## Acceptance Criteria

- [x] `opencode_app/.opencode/agents/java-reviewer-subagent.md` exists with the 10-section Java checklist, 4-row Framework table, 7 sections total (Prompt Defense, Checklist, Framework, Severity, CodeGraph, Output Format, Return Contract — mirroring Go reviewer scaffolding), and **5-skill allowlist** (no `design-patterns-skill`)
- [x] `code-review-subagent.md` has `java-reviewer-subagent: allow` in `permission.task` and a Java row in the delegation table
- [x] `README.md` Subagents table has a `java-reviewer-subagent` row with skill column `solid-principles, clean-code, code-smells, continuous-learning` (matching sibling rows exactly) **AND** line 308 prose count updated `35 agent .md files` → `36 agent .md files`
- [x] `deploy/setup.sh` has the Java reviewer listing line AND zero stale `39`/`34`/`35` count references — all 7 occurrences (lines 503, 1664, 1670, 2218, 2223, 2395, 2401) updated to `36` / `31` / `32` per the math table in step 3.1
- [x] `deploy/setup.ps1` has the Java reviewer listing line **AND** 4 banner count corrections (L338, L1176, L1751, L1757) mirroring setup.sh — decision reversed during code review
- [x] `opencode_app/README.md` line 25 reads `36 agent .md files` AND line 102 reads `23 of 36 agents have explicit \`task\` permissions`
- [x] `ls opencode_app/.opencode/agents/ | wc -l` == 36
- [x] Zero unexpected `java-reviewer` references in non-target files
- [x] `documentation-sync-workflow` validation passes

---

## Risks & Mitigation

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| Java checklist omits a critical language concern | med | med | 10-section structure mirrors the depth of Go reviewer (which has 7 sections + framework table); reviewed against Effective Java items |
| Banner count correction (39→36) breaks downstream consumers expecting 39 | low | low | The 39 figure was already incorrect (drift = stale); correcting to actual is net-positive. README has one prose count at L308 (caught in code review, fixed); other docs use tables |
| setup.sh has more stale count refs than anticipated (7, not 2) | high | med | Step 3.1 enumerates all 7 with line numbers and math derivations; step 4.1(b) greps for `39 agents\|39):\|and 3[45] more` and asserts zero matches — false-positive verification closed |
| setup.ps1 banner NOT corrected (original deferral) | high | med | **REVERSED during code review** — original decision deferred banner count citing "unverified Windows drift"; code-review-subagent correctly noted the documented Windows-parity rule violation. Reversed: 4 setup.ps1 count refs now corrected (39→36, 34 more→31 more) |
| `code-review-subagent` delegation table row uses wrong trigger condition | low | med | Condition matches sibling rows (`*.java files dominate, or pom.xml/build.gradle detected`) — directly analogous to Rust's `Cargo.toml` condition |
| Skill allowlist accidentally includes `design-patterns-skill` (matching Python/TS, not Go/Rust) | med | med | Step 1.1 explicitly enumerates 5 skills with rationale; step 4.2 verification asserts "exactly 5 skills, NOT 6"; AC requires 5-skill allowlist |
| README Java row skill column drifts from sibling projection pattern | med | low | Step 2.2 mandates skill column `solid-principles, clean-code, code-smells, continuous-learning` matching the 4 sibling rows exactly; AC reasserts |
| `opencode_app/README.md` line 102 count math wrong (22→23, not 22→22) | med | med | Step 3.3 documents the math: total 35→36 AND explicit-perm 22→23 (Java has explicit task perms); remainder stays 13. Verified against actual file |
| setup.sh line numbers drift during editing | high | med | Use string matching for edits (`rust-reviewer        Rust code review` as anchor for listing; `39 agents`, `39):`, `and 3[145] more` as anchors for counts), not line numbers; step 4.1 re-greps after each change |

---

## Technical Notes

- All source-of-truth edits go in `opencode_app/.opencode/` (repo AGENTS.md rule); **never** edit deployed `~/.config/opencode/` copies — redeploy handles those.
- Model tier is `glm-5.1` (sound-reasoning) per the repo AGENTS.md model-tier table — language reviewers sit alongside `code-review-subagent` and `architecture-review-subagent` in that tier. **Never** assign a language reviewer to `glm-5.2` (primary-only) or `glm-5-turbo` (exploratory tier).
- Step count is 25, matching all 4 sibling language reviewers exactly. No bump needed — the review workflow scope is identical.
- **Skill allowlist (corrected during review):** Java mirrors Go and Rust reviewers with **5 skills** (solid-principles, clean-code, code-smells, continuous-learning, search-first) — NO `design-patterns-skill`. Python (7) and TypeScript (8) include design-patterns only because they also carry language-specific extras (`python-backend-skill`, `react-nextjs-antipatterns-skill`, `typescript-dry-principle-skill`) — those exist because the repo has language-specific skills for those languages. **No Java-specific skill exists in this repo**, so the 5-skill Go/Rust pattern is the correct mirror — NOT the 6/7/8-skill Python/TS pattern. Future work: if a `java-spring-patterns-skill` or similar is created, add it to the allowlist at that time (and consider adding `design-patterns-skill` alongside it).
- **Framework-Specific Checks table** — chose Spring Boot, Quarkus, Micronaut, Jakarta EE as the 4 rows because they represent the dominant modern JVM frameworks (Spring Boot = enterprise default, Quarkus = cloud-native/GraalVM, Micronaut = compile-time DI, Jakarta EE = legacy standard). This mirrors the depth of the Python reviewer's framework table (FastAPI/Django/Flask/SQLAlchemy) and Go's (net/http/Gin/gRPC/Cobra).
- **Files NOT changed** (with justification):
  - `deploy/.AGENTS.md` — has only generic `code-review-subagent` routing entry; no per-language routing table to update.
  - `opencode_app/AGENTS.md` (Docker) — same: no per-language routing table.
  - `AGENTS.md` (repo root) — model-tier table lists reviewer categories collectively (e.g., "reviewers: code-review, architecture-review, python-reviewer, etc."); no per-language row needed.
  - `deploy/setup.ps1` banner count — intentionally untouched; Windows banner value was not audited for drift (see step 3.2).
- **Commit message convention** (per recent merged PRs #230, #233): `feat(agents): add java-reviewer-subagent for Java language code review [closes #234]`. **Implementer must verify** with `git log --oneline | head -20` that the scope token `agents` is current before committing — the review subagent could not verify this from read-only access.

---

*Created by primary agent (build mode) — issue #234. 2026-07-18. Revised 2026-07-18 after `opencode-tooling-subagent` review surfaced 2 CRITICAL + 2 MAJOR issues: (1) Java skill allowlist corrected from 6 skills to 5 (dropped `design-patterns-skill` — Go/Rust siblings have 5, not 6); (2) setup.sh banner count scope expanded from 2 occurrences to all 7 (lines 503, 1664, 1670, 2218, 2223, 2395, 2401 — subagent found 6, primary agent verification found the 7th at line 1670); (3) added Phase 3.3 for `opencode_app/README.md` (2 stale `35` counts at lines 25, 102); (4) README Java row skill column aligned with sibling projection pattern. Plus 4 MINOR + 2 NIT fixes (section enumeration, file count typo, sibling comparison, dual framing, commit msg verification caveat).*

*Revised again 2026-07-18 after post-implementation `code-review-subagent` review surfaced 2 additional MAJOR issues: (5) README.md:308 prose count "35 agent .md files" was missed (PLAN incorrectly claimed "README has no count reference, only a table"); (6) original decision to defer setup.ps1 banner count reversed — the documented Windows-parity rule in repo AGENTS.md mandates mirror, and the count is now known (36), so deferral had no justification. 4 setup.ps1 count refs corrected (L338, L1176, L1751, L1757). All count drift now eliminated repo-wide.*
