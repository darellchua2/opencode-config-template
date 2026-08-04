# Ponytail × Subagent/Skill Integration Audit

**Date:** 2026-08-03
**Scope:** Can the repo's 38 subagents + skills benefit from baking Ponytail principles in *statically* (per-agent tailored), versus the current one-size-fits-all *runtime* injection?
**Method:** Read all 38 `opencode_app/.opencode/agents/*.md`, the wrapper `ponytail-scoped.mjs`, the vendored `ponytail/SKILL.md` + `instructions.cjs`, the relevant skills, and the bats test suite. **No agent/skill files were edited** — this is the audit + checklist + drafted snippets only.

---

## 1. Executive Verdict

**Recommendation: (C) Hybrid — and it is the clear winner.**

Runtime injection alone (A) is too coarse: it fires into ~19 agents that write **no production code** (docs, business, integrations, vision, coverage) — wasting ~150 lines / ~1.5k tokens of context each with "code first, write less code" guidance that is irrelevant or counterproductive there. Static-embed-only (B) forfeits the runtime mode-switching (`/ponytail lite|full|ultra`) and creates a large per-file maintenance surface.

The hybrid (C) gives the best of both:

- **Bake role-tuned Ponytail lenses into the 8 highest-value coding agents** (`code-review`, `architecture-review`, `error-resolver`, `nextjs-specialist`, `autoresearch-code`, `loop-operator`, `tdd`, `testing`) and **add them to the off-set** so the runtime plugin skips them (no double injection). The role-tuned text is materially sharper than the generic "lazy senior dev" framing — e.g. *review = challenge over-engineering as a finding*, *TDD = reconcile the test discipline with the leave-one-check rule*.
- **Add 11 non-coding agents to the off-set with NO baked text** (pure context savings; Ponytail is N/A there).
- **Keep runtime injection for the long tail** (language reviewers, `autoresearch-ml`, `opentofu-explorer`, `responsive-audit`, `linting`, `uiux-reviewer`, `pr-workflow`, `repo-ops-specialist`, `opencode-tooling`, `cad-specialist`) — centrally updatable, mode-switchable, zero per-file work.

**Net effect:** every agent gets the *right* Ponytail signal (role-tuned, generic, or none), double injection is structurally impossible (off-set is the single source of "who is injected"), and ~11 agents shed dead context weight.

---

## 2. Current Setup (verified)

| Component | Location | Role |
|---|---|---|
| Scoped wrapper | `opencode_app/.opencode/plugins/ponytail-scoped.mjs` | Agent-type-aware injection via `experimental.chat.system.transform`; 6 slash commands; per-session/per-agent mode map |
| Vendored ruleset | `opencode_app/.opencode/plugins/ponytail/SKILL.md` (v4.8.4, MIT) | Canonical Ponytail text; re-vendored deliberately on upstream bumps |
| Instruction builder | `opencode_app/.opencode/plugins/ponytail/instructions.cjs` | Mode-filters the SKILL.md body (lite/full/ultra); emits `PONYTAIL MODE ACTIVE — level: <mode>` header |
| Attribution | `opencode_app/.opencode/plugins/ATTRIBUTION.md` | MIT attribution |
| Wiring | **Auto-discovered local plugin** from `~/.config/opencode/plugins/` (deployed from `opencode_app/.opencode/plugins/`); deliberately NOT in `opencode.json` `plugin[]` (double-injection guard vs stock npm adapter) |

**Default off-set (7 agents skip injection):** `explore`, `general`, `autoresearch-research-subagent`, `explorer-subagent`, `requirements-specialist-subagent`, `discovery-specialist-subagent`, `technical-design-specialist-subagent` (`ponytail-scoped.mjs:41-44`). The remaining **31 of 38** agents + the primary session receive the full ruleset every turn.

**Key gaps found:**
1. The off-set is too narrow — it lists only *read-only/research* agents, but ~11 *non-coding* agents (docs, business, integrations, vision) still get the full "lazy senior dev" injection, which is irrelevant and costs context.
2. For the highest-value coding agents, the generic injection is *correct but blunt* — a role-tuned lens would be sharper (review, bug-fix, TDD all interact with Ponytail in specific ways).

---

## 3. Agent Inventory (all 38, categorized)

`Off-set?` = currently skipped by the runtime plugin. `Recommend` = the target mode under hybrid (C).

| # | Agent | Category | Off-set? | Ponytail applies? | Recommend | Tailored focus |
|---|---|---|---|---|---|---|
| 1 | `code-review-subagent` | review |  | **Yes (differently)** — challenge over-engineering as a finding | **Bake + off-set** | Flag one-impl interfaces, speculative factories; prefer deletion suggestions |
| 2 | `architecture-review-subagent` | review |  | **Yes (differently)** — YAGNI at the architecture layer | **Bake + off-set** | No speculative extensibility; boring+fewer-components wins |
| 3 | `typescript-reviewer-subagent` | review |  | Yes | Runtime | Generic lens adequate (delegates from code-review) |
| 4 | `python-reviewer-subagent` | review |  | Yes | Runtime | Generic lens adequate |
| 5 | `go-reviewer-subagent` | review |  | Yes | Runtime | Generic lens adequate |
| 6 | `rust-reviewer-subagent` | review |  | Yes | Runtime | Generic lens adequate |
| 7 | `java-reviewer-subagent` | review |  | Yes | Runtime | Generic lens adequate |
| 8 | `error-resolver-subagent` | meta |  | **Yes** — root-cause not symptom = core Ponytail bug-fix rule | **Bake + off-set** | Fix once in shared path; grep every caller first |
| 9 | `nextjs-specialist-subagent` | frontend |  | **Yes** — scaffolding is the #1 over-build source in greenfield | **Bake + off-set** | Scaffold only what's named; platform feature before dep |
| 10 | `autoresearch-code-subagent` | research |  | **Yes** — smallest-diff-per-iteration aligns with keep/revert loop | **Bake + off-set** | Lazy iteration = minimum code that moves the metric |
| 11 | `loop-operator-subagent` | research |  | **Yes** — minimal fix clears the gate fastest | **Bake + off-set** | Shortest working diff per retry; leaner self-correction |
| 12 | `tdd-subagent` | meta |  | **Yes (tension)** — "minimal code to pass" = rung 7, but "no frameworks/one check" tensions with full-suite discipline | **Bake + off-set** | Reconcile: TDD red IS the check Ponytail demands |
| 13 | `testing-subagent` | meta |  | **Yes** — YAGNI applies to test code too | **Bake + off-set** | Reuse fixtures; one focused test per behavior |
| 14 | `linting-subagent` | meta |  | Partial (mechanical auto-fix) | Runtime | "No unrequested prose" output rule marginally helps |
| 15 | `autoresearch-ml-subagent` | research |  | Partial (ML has hardware-calibration exception) | Runtime | Keep; Ponytail's calibration-knob guardrail is relevant |
| 16 | `opentofu-explorer-subagent` | devops |  | Partial (IaC; reuse modules) | Runtime | Keep |
| 17 | `responsive-audit-subagent` | frontend |  | Partial (minimal CSS fixes) | Runtime | Keep |
| 18 | `uiux-reviewer-subagent` | frontend |  | Mostly N/A (design review, no code; `edit: LEARNINGS/**` only) | Runtime *(borderline)* | Could move to off-set; defer |
| 19 | `pr-workflow-subagent` | meta |  | Mostly N/A (runs checks, creates PRs) | Runtime *(borderline)* | Defer |
| 20 | `repo-ops-specialist-subagent` | devops |  | Marginal (writes workflow YAML/scripts) | Runtime *(borderline)* | Defer |
| 21 | `opencode-tooling-subagent` | meta |  | Marginal (writes markdown config, not code) | Runtime *(borderline)* | Defer |
| 22 | `cad-specialist-subagent` | cad |  | Marginal (CAD generation ≠ "lazy code") | Runtime *(borderline)* | Defer |
| 23 | `coverage-subagent` | docs |  | **N/A** (no code) | **Off-set (no bake)** | Pure context savings |
| 24 | `documentation-subagent` | docs |  | **N/A** (docs *need* prose) | **Off-set (no bake)** | Pure context savings |
| 25 | `docx-creation-subagent` | docs |  | **N/A** | **Off-set (no bake)** | Pure context savings |
| 26 | `pptx-specialist-subagent` | docs |  | **N/A** | **Off-set (no bake)** | Pure context savings |
| 27 | `xlsx-specialist-subagent` | docs |  | **N/A** | **Off-set (no bake)** | Pure context savings |
| 28 | `office-document-primary-agent` | docs |  | **N/A** | **Off-set (no bake)** | Pure context savings |
| 29 | `startup-ceo-subagent` | business |  | **N/A** | **Off-set (no bake)** | Pure context savings |
| 30 | `startup-founder-primary-agent` | business |  | **N/A** | **Off-set (no bake)** | Pure context savings |
| 31 | `google-mcp-specialist-subagent` | integrations |  | **N/A** | **Off-set (no bake)** | Pure context savings |
| 32 | `microsoft-m365-specialist-subagent` | integrations |  | **N/A** | **Off-set (no bake)** | Pure context savings |
| 33 | `image-analyzer-subagent` | meta |  | **N/A** (text-based vision via skill; writes no code) | **Off-set (no bake)** | Pure context savings |
| 34 | `requirements-specialist-subagent` | business |  | N/A | Keep off-set | Correct |
| 35 | `discovery-specialist-subagent` | business |  | N/A | Keep off-set | Correct |
| 36 | `technical-design-specialist-subagent` | business |  | N/A | Keep off-set | Correct |
| 37 | `autoresearch-research-subagent` | research |  | N/A (web-only lit review) | Keep off-set | Correct |
| 38 | `explorer-subagent` | meta |  | N/A (read-only) | Keep off-set | Correct |
| (builtin) | `explore` | — |  | N/A | Keep off-set | Correct |
| (builtin) | `general` | — |  | N/A | Keep off-set | Correct |

**Tally under hybrid (C):**
- **Bake + off-set:** 8 agents (rows 1, 2, 8, 9, 10, 11, 12, 13)
- **Off-set, no bake:** 11 agents (rows 23–33)
- **Runtime injection (kept):** 14 agents (rows 3–7, 14–22)
- **Already off-set (unchanged):** 5 + 2 builtins (rows 34–38 + explore/general)

> **Task-prompt correction:** The task prompt referenced `refactoring-subagent`, `prd-specialist-subagent`, `business-*` agents, and `ticket-creation-subagent`. **None of these exist** in `opencode_app/.opencode/agents/`. `requirements-specialist-subagent` absorbs the "PRD/BRD/SRS" role; no dedicated refactoring subagent exists (refactoring guidance flows through `code-review-subagent` → skills).

---

## 4. Off-Set Correction — Proposed Regex

The wrapper compiles the off-set with `new RegExp(pattern, 'i')` (`ponytail-scoped.mjs:49`). The pattern is an anchored alternation of agent names (agent name = filename minus `.md`). The proposed pattern adds **19 agents** (8 baked-in + 11 N/A) and is **valid JS regex** (verified: literal alternation, hyphens are literal outside character classes, anchored with `^…$`).

**Current** (`ponytail-scoped.mjs:41-44`):
```js
const DEFAULT_OFF_PATTERN =
  '^(explore|general|autoresearch-research-subagent|explorer-subagent|' +
  'requirements-specialist-subagent|discovery-specialist-subagent|' +
  'technical-design-specialist-subagent)$';
```

**Proposed:**
```js
const DEFAULT_OFF_PATTERN =
  '^(explore|general|' +
  // — read-only / research / planning (existing) —
  'autoresearch-research-subagent|explorer-subagent|' +
  'requirements-specialist-subagent|discovery-specialist-subagent|' +
  'technical-design-specialist-subagent|' +
  // — non-coding: Ponytail N/A (context savings, no baked text) —
  'docx-creation-subagent|pptx-specialist-subagent|xlsx-specialist-subagent|' +
  'office-document-primary-agent|startup-ceo-subagent|startup-founder-primary-agent|' +
  'google-mcp-specialist-subagent|microsoft-m365-specialist-subagent|' +
  'image-analyzer-subagent|coverage-subagent|documentation-subagent|' +
  // — baked-in Ponytail lens (avoid double injection; see audit) —
  'code-review-subagent|architecture-review-subagent|error-resolver-subagent|' +
  'nextjs-specialist-subagent|autoresearch-code-subagent|loop-operator-subagent|' +
  'tdd-subagent|testing-subagent' +
  ')$';
```

**Validation note:** `PONYTAIL_SUBAGENT_OFF` env var overrides this at runtime (`ponytail-scoped.mjs:47`), so the default is a floor, not a lock — a user can still force-inject via the env var if desired. The `try/catch` at `:48-52` falls back to the current default if the regex is malformed, so a typo degrades to the *narrow* off-set (over-injection), never a crash.

>  **No bats test asserts the off-set contents** (grep for `ponytail` across `tests/*.bats` → 0 hits), so this regex change is test-safe on its own. The only test surface for agents is count/category/`requiresSkills` (see §8).

---

## 5. Double-Injection Risk Analysis

### 5.1 Does OpenCode concatenate agent `.md` with plugin transform output?

**Yes, and in a specific order.** `experimental.chat.system.transform` receives `output.system` — the **already-assembled** system-prompt array (AGENTS.md + agent `.md` body + other pieces). The agent's `.md` instructions are present in `output.system` *before* the hook runs. The wrapper then **appends** the Ponytail text to the *last* entry of `output.system` (`ponytail-scoped.mjs:201-206`). Resulting order:

```
[ AGENTS.md , agent-.md-body , … ]  →  plugin appends  →  [ AGENTS.md , agent-.md-body + "\n\n" + Ponytail ]
```

So baked-in text (in the agent `.md` body) appears **before** any runtime-injected text; they are not deduplicated.

### 5.2 The idempotency guard (marker check)

The guard (`ponytail-scoped.mjs:194-199`) scans **every** entry of `output.system` for the literal marker `PONYTAIL_MODE ACTIVE` (`:133`). If found in *any* entry, injection is skipped. The injected text always begins with that marker (`instructions.cjs:67,108`).

**Implication for baked-in text:**
- If a baked-in snippet contains the **exact** string `PONYTAIL MODE ACTIVE`, the guard detects it and **skips** runtime injection → no double injection, **but** (a) it pollutes role-tuned prose with a meta-marker, and (b) it silently disables `/ponytail` mode-switching for that agent (the user can no longer raise/lower intensity).
- If a baked-in snippet does **not** contain the marker, the guard does **not** detect it, and the plugin **also** injects → **double injection** (role-tuned text *plus* the generic ~150-line ruleset).

### 5.3 Mitigation (recommended)

**Use the off-set, not the marker.** For every agent that receives a baked-in lens, add it to the off-set regex (§4). This:
- makes "who is injected" a **single, debuggable source** (the regex), not magic-string-in-prose;
- **preserves** runtime mode-switching for *other* agents;
- **structurally prevents** double injection (the plugin never runs for off-set agents).

Rejected alternative — *disable runtime injection entirely and go static (option B)*: forfeits `/ponytail lite|full|ultra` for the 14 agents that legitimately benefit from generic injection, and balloons the maintenance surface (every Ponytail re-vendor → re-edit 8 files instead of 1 vendored SKILL.md).

---

## 6. Skill Overlap Matrix

The repo ships skills that encode Ponytail-adjacent principles. The classification below treats Ponytail as a **meta-decision layer** (the 7-rung ladder that decides *whether* to write code / reach for a dep), and the skills as **execution canons** (how to structure the code once you've decided to write it).

| Skill | Ponytail overlap | Classification | Recommendation |
|---|---|---|---|
| `clean-code-skill` | Naming, small functions, self-doc | **Complementary** | Keep separate. Ponytail decides *if*; clean-code decides *how readable*. |
| `clean-architecture-skill` | Layer boundaries, dependency rule | **Complementary** | Keep. Ponytail-YAGNI challenges *speculative* layers; clean-architecture governs the layers that *do* exist. |
| `complexity-management-skill` (KISS/YAGNI/DRY) | **Direct overlap** with Ponytail rungs 1 (YAGNI) + 6-7 | **Mostly redundant** | Highest redundancy. See consolidation note below. |
| `code-smells-skill` | Long methods, large classes, feature envy | **Complementary** | Keep. Detection taxonomy; Ponytail is the deletion bias that acts on it. |
| `design-patterns-skill` | "Avoid over-engineering", simpler alternatives | **Partial overlap** | Its "patterns forced unnecessarily" row ≈ Ponytail "no unrequested abstractions". Keep (taxonomy value), cross-reference. |
| `object-design-skill` | Stereotypes, value objects, aggregates | **Complementary** | Keep. Distinct concern. |
| `solid-principles-skill` | SRP, OCP, ISP… | **Complementary** | Keep. SOLID is structure; Ponytail is minimalism. Occasional tension (ISP can *add* interfaces; Ponytail flags one-impl interfaces) — the review lens snippet handles this. |
| `typescript-dry-principle-skill` | Eliminate TS duplication | **Complementary** | Keep. DRY = Ponytail rung 2 (reuse) specialized to TS types. |
| `deprecated-code-cleanup-skill` | Phased @deprecated removal | **Complementary** | Keep. Deletion-over-addition specialized to deprecation lifecycle. |
| `search-first-skill` | adopt-extend-compose-build decision matrix | **Strong overlap** | **Nearly redundant** with Ponytail's ladder (rungs 2→5 ≈ reuse→stdlib→dep). See note. |
| `tdd-workflow-skill` | red-green-refactor | **Complementary (with tension)** | Keep. Reconciliation lives in the `tdd-subagent` baked snippet (§7). |

### Consolidation recommendation

No skill should be **deleted** — each carries taxonomy/execution value beyond the meta-decision. But two carry enough overlap that a **shared "lazy-code canon" reference** would reduce drift:

1. **`complexity-management-skill`** — its KISS/YAGNI/DRY section restates Ponytail rungs 1, 6, 7. Recommend adding a one-line cross-reference at the top: *"For the decision of whether to write code at all, Ponytail (runtime-injected or baked) is the authority; this skill governs structural complexity of code that must exist."* No content merge needed.
2. **`search-first-skill`** — its adopt-extend-compose-build matrix maps almost 1:1 onto Ponytail rungs 2→5. Recommend the same cross-reference pattern: *"Ponytail's ladder subsumes the adopt→build decision; this skill provides the evaluation matrix for the 'build' rung."*

This keeps each skill self-contained while making Ponytail the canonical "should this code exist / what rung" authority, avoiding three places that re-derive YAGNI.

---

## 7. Tailored Ponytail Snippets (role-specific, draft)

These are **distinct** from the generic runtime-injected text — each is a *role-tuned lens*, not a copy of the ladder. Each is intended to be appended to the agent's `.md` body (before the `## Return Contract` section) under a clearly-marked header, **and** the agent added to the off-set (§4) so the runtime plugin does not also inject.

Each snippet ends with a guard clause asserting it does **not** weaken the agent's existing correctness/security/gate rules.

### 7.1 `code-review-subagent`
**Path:** `opencode_app/.opencode/agents/code-review-subagent.md`
```markdown
## Ponytail review lens (baked-in, role-tuned)

Challenge over-engineering as a first-class finding, not just a style note:
- Flag speculative generality: interfaces with one implementation, factories for one product, config flags that never vary, base classes with a single subclass.
- When an addition and a deletion both fix the issue, recommend the deletion — the smaller, more boring fix is the better review outcome.
- A dependency added for what a few lines or the stdlib could do is a Major finding, named by package.

This sharpens the design-patterns checklist ("patterns forced unnecessarily") into an active deletion bias. It does **not** relax the security/correctness gates, the Mandatory Impact & Consumer Coverage gate, or the severity rubric above.
```

### 7.2 `architecture-review-subagent`
**Path:** `opencode_app/.opencode/agents/architecture-review-subagent.md`
```markdown
## Ponytail architecture lens (baked-in, role-tuned)

Apply YAGNI at the architecture layer, not just the code layer:
- Challenge speculative extensibility: a layer/seam added for a future consumer that does not yet exist is an architecture smell even when the code is clean.
- Prefer the design that makes the *next* change cheap over the design that tries to pre-build every change now. A seam nobody needs is coupling nobody asked for.
- When two architectures hold, the boring, fewer-component one wins unless you can name the concrete future need the richer one would block.

This complements `clean-architecture-skill`'s dependency rule. It does **not** weaken boundary discipline or the Mandatory Consumer Traversal Gate.
```

### 7.3 `error-resolver-subagent`
**Path:** `opencode_app/.opencode/agents/error-resolver-subagent.md`
```markdown
## Ponytail bug-fix lens (baked-in, role-tuned)

A report names a symptom; the lazy fix IS the root-cause fix. Before recommending a change:
- Grep every caller of the function the fix touches. One guard in the shared path is a smaller diff (and fewer sibling bugs) than a guard per caller.
- The smallest fix in the wrong place is a second bug, not laziness — confirm the real flow first, then fix once where all callers route through.

Never trade correctness for diff size: validation at trust boundaries, error handling that prevents data loss, and the actual root cause are not laziness targets. This aligns with the existing root-cause workflow; it makes "fix once, in the shared function" the default recommendation.
```

### 7.4 `nextjs-specialist-subagent`
**Path:** `opencode_app/.opencode/agents/nextjs-specialist-subagent.md`
```markdown
## Ponytail scaffolding lens (baked-in, role-tuned)

Scaffold only what the task names — "for later" is the most common bloat source in greenfield Next.js:
- Reach for the platform feature before a dependency: native form controls, CSS, route handlers, DB constraints over a library.
- One already-installed dependency (e.g. shadcn/ui) beats a new one. If a current dep covers it, do not add a package.
- Ship the minimal scaffold, then name the one thing you skipped and when to add it — never stall the scaffold waiting for a decision you can default.

This does **not** override Server/Client Component boundary discipline, React Compiler, or the security/accessibility best practices above.
```

### 7.5 `autoresearch-code-subagent`
**Path:** `opencode_app/.opencode/agents/autoresearch-code-subagent.md`
```markdown
## Ponytail iteration lens (baked-in, role-tuned)

Each iteration proposes ONE atomic change, and the laziest one that moves the metric wins:
- Prefer deleting dead code or reusing an existing helper over writing new code in the same iteration — deletion cannot regress the guard suite.
- The shortest working diff per iteration keeps revert cheap and the `*-results.tsv` signal clean; a large rewrite muddies whether the metric moved for the reason you think.

Never trade the Consumer Coverage Gate for a smaller diff: a rename that breaks an uninspected consumer reverts, no matter how lazy it looked. This aligns with the modify→verify loop; it makes "minimum code that moves the metric" the iteration default.
```

### 7.6 `loop-operator-subagent`
**Path:** `opencode_app/.opencode/agents/loop-operator-subagent.md`
```markdown
## Ponytail loop lens (baked-in, role-tuned)

Inside the self-correction protocol, the minimal fix that clears the gate is the right fix:
- Diagnose root cause, then apply the shortest working diff — a smaller change is easier to verify and easier to revert if the next iteration fails.
- Reuse an existing helper or stdlib over a new function; deletion of the offending code over a guard wrapping it, when both pass verification.

Never trade the completion criteria for brevity: a lazy fix that leaves a blocking error is unfinished, not done. This does not change the iteration limits or abort conditions; it makes each retry leaner.
```

### 7.7 `tdd-subagent`
**Path:** `opencode_app/.opencode/agents/tdd-subagent.md`
```markdown
## Ponytail × TDD reconciliation (baked-in, role-tuned)

TDD's "minimal code to pass" *is* Ponytail rung 7 — they agree on the implementation step. Reconcile the two on tests themselves:
- Write the smallest test that captures the behavior, not the most exhaustive suite for a single behavior. One focused test per red-green cycle is the cycle, not a constraint to fight.
- "Test behavior, not implementation" (already your rule) is also the lazy choice: a test pinned to implementation details is a test you rewrite on every refactor.
- Where the user asks for a full framework suite, build it fully (Ponytail yields to explicit request). Where they ask for a quick check, one runnable test is the honest TDD answer.

Ponytail does **not** mean "skip the test" — TDD red IS the runnable check Ponytail demands non-trivial logic leave behind.
```

### 7.8 `testing-subagent`
**Path:** `opencode_app/.opencode/agents/testing-subagent.md`
```markdown
## Ponytail test-generation lens (baked-in, role-tuned)

Apply the ladder to the tests themselves, not just the code under test:
- Reuse the project's existing test utilities, fixtures, and factories before writing new ones — duplicated test setup is the most common slop.
- One focused test per behavior beats a sprawling test that asserts everything; expand edge cases only where the risk tier (critical paths → 90%) demands it.
- Trivial one-liners need no dedicated test (YAGNI applies to tests too), but never skip the test for logic on a money/security/auth path — those always get one.

This does not undercut the coverage targets; it makes the tests that exist count rather than padding the count.
```

---

## 8. Bats Test Impact (verification)

Confirmed by reading `tests/init.bats`, `tests/test_markitdown_skill.bats`, `tests/test_default_behavior.bats`, `tests/test_mcp_count_consistency.bats`:

| Test | Assertion | Affected by this change? |
|---|---|---|
| `init.bats:27` | `registry.json` agents = **38** | **No** — editing agent *bodies* changes no count (`build-registry.mjs` parses frontmatter). |
| `init.bats:33` | `--list agents` = **38** | **No** — same. |
| `init.bats:38` | `--list agents --category review` = **7** | **No** — category frontmatter unchanged. |
| `init.bats:62` | `--describe code-review-subagent` requiresSkills = **11** | **No** — counts `permission.skill` entries, not body text. Snippet is body text; no skill permission added/removed. |
| `init.bats:71` | `--expand review` = **8** agents | **No** — delegation graph unchanged. |
| `test_markitdown_skill.bats:74` | skill count = actual dir count | **No** — no skills added/removed. |
| `test_default_behavior.bats` | `DO NOT execute…` string in 30 skills | **No** — no skill files touched. |
| *(none)* | off-set regex contents | **No bats test covers the plugin** (grep `ponytail` in `tests/*.bats` → 0 hits). |

**Conclusion: appending role-tuned snippets to agent `.md` bodies + editing the off-set regex in `ponytail-scoped.mjs` breaks zero bats tests**, provided no `permission.skill` entries are added/removed and no agents are added/removed.

**Caveat — non-bats surfaces that hardcode counts** (would break only if agent *counts* changed, which this plan does not): `deploy/setup.sh:603` ("AGENTS (38)"), `:2476`/`:3372` ("Configured 38 agents"), `deploy/setup.ps1:1735`, `README.md:174`, `opencode_app/README.md:172`. None affected by body edits.

---

## 9. Maintenance / Sync Plan

The vendored SKILL.md header says *"Pinned at tag v4.8.4. Re-vendor deliberately on upstream bumps."* Baked-in snippets are **derivative** (role-tuned paraphrases of principles), not verbatim copies — so re-vendoring does not break them *unless the ladder semantics change* (rung count, YAGNI/deletion emphasis, the "leave one check" rule).

**Single canonical source:** `opencode_app/.opencode/plugins/ponytail/SKILL.md` (+ `instructions.cjs`). Baked-in snippets **reference** the principles; they do not duplicate the text.

**Drift prevention (3 layers, lowest-cost first):**

1. **Provenance tag in each baked snippet** (zero tooling). Each snippet header carries a one-liner:
   `<!-- Ponytail lens derived from plugins/ponytail/SKILL.md (vendored v4.8.4); re-sync when the ladder or "when NOT to be lazy" semantics change -->`
   A maintainer re-vendoring Ponytail greps `Ponytail lens derived` to find all 8 files to re-review.

2. **Lint check (optional, low-effort).** Add a bats test (`tests/test_ponytail_baked_sync.bats`) that:
   - Asserts the 8 baked-in agents are present in the off-set regex (so double-injection can't silently reappear).
   - Asserts each baked snippet file contains the provenance tag.
   - Does *not* assert verbatim principle text (that would be brittle).

3. **Documentation-sync hook.** When `documentation-sync-workflow-skill` or `opencode-tooling-subagent` runs after a Ponytail re-vendor, the provenance tags surface the 8 files for review. No new mechanism needed — the tag is the signal.

**Rejected:** a shared include mechanism. OpenCode agent `.md` files support `prompt: "{file:./…}"` frontmatter for an *external* prompt file, but not inline transclusion of a fragment into the body. A per-agent external prompt file would fragment the agent definition and complicate `build-registry.mjs`'s parsing. Static body text with provenance tags is simpler and sufficient.

---

## 10. Ordered Implementation Checklist

Each item is independently shippable. **HIGH → LOW** priority. The primary agent decides what to apply; this audit does not edit agent/skill files.

### HIGH — correctness + context savings (no agent-body edits)

- [ ] **H1.** **Correct the off-set regex** in `opencode_app/.opencode/plugins/ponytail-scoped.mjs:41-44` → the §4 proposed pattern. This alone stops irrelevant injection into 19 agents (8 soon-to-be-baked + 11 N/A) and yields the context savings. *Files: 1.*
- [ ] **H2.** Verify after H1: spot-check that `/ponytail` still works for a *kept* agent (e.g. `typescript-reviewer-subagent`) and is skipped for a newly-off-set agent (e.g. `docx-creation-subagent`). Manual; no automation exists for the plugin.

### MEDIUM — role-tuned precision (agent-body edits, do AFTER H1 so the off-set is already correct)

- [ ] **M1.** Append the §7.1 snippet to `opencode_app/.opencode/agents/code-review-subagent.md` (before `## Return Contract`).
- [ ] **M2.** Append §7.2 to `…/architecture-review-subagent.md`.
- [ ] **M3.** Append §7.3 to `…/error-resolver-subagent.md`.
- [ ] **M4.** Append §7.4 to `…/nextjs-specialist-subagent.md`.
- [ ] **M5.** Append §7.5 to `…/autoresearch-code-subagent.md`.
- [ ] **M6.** Append §7.6 to `…/loop-operator-subagent.md`.
- [ ] **M7.** Append §7.7 to `…/tdd-subagent.md`.
- [ ] **M8.** Append §7.8 to `…/testing-subagent.md`.
- [ ] **M9.** Run `bats tests/` — expect all-pass (per §8). Run `opencode-init --check` (registry drift guard) — expect in-sync.

### LOW — skill cross-references + drift guard (optional hardening)

- [ ] **L1.** Add the one-line Ponytail cross-reference to `complexity-management-skill/SKILL.md` and `search-first-skill/SKILL.md` (§6 consolidation note).
- [ ] **L2.** Add `tests/test_ponytail_baked_sync.bats` (§9 layer 2): assert the 8 baked agents are in the off-set regex + each carries the provenance tag.
- [ ] **L3.** Update `README.md` §Ponytail (~line 592) and `opencode_app/README.md` §Ponytail (~line 176) to document the hybrid model (runtime for the tail, baked for the 8, off-set for the rest).

> **`[UNVERIFIED]` items:**
> - The exact composition of `output.system` entries (whether AGENTS.md and agent `.md` land in the same array entry or separate ones) — inferred from the wrapper's append-to-last-entry logic and OpenCode plugin docs, not from a runtime trace. The double-injection conclusion holds either way (the guard scans all entries), but the *ordering* of baked vs injected text is `[UNVERIFIED]` at the array-entry granularity.
> - Whether `PONYTAIL_AGENT_MODE_MAP` is set in any deployed environment (Docker `docker-entrypoint.sh:75` is "read by the plugin at load time" but the env value itself `[UNVERIFIED]`). If set, per-agent overrides survive the off-set change because `resolveMode` runs *before* `isInOffSet` is checked... actually no — `isInOffSet` is checked at `:186` *after* `resolveMode` at `:183`, and an off-set agent returns at `:188` before injection regardless of mode. So the off-set **overrides** the mode map. **This is intended** (off-set = "no Ponytail at all"), but worth confirming no deployment relies on forcing Ponytail into an off-set agent via the map. `[UNVERIFIED]` whether any does.

---

## 11. Risks & Rollback

| Risk | Likelihood | Impact | Mitigation / Rollback |
|---|---|---|---|
| A baked snippet conflicts with an agent's existing rule (e.g. TDD vs "one check") | Med | Med | Each snippet ends with an explicit guard clause. If conflict observed, edit the snippet — it is local to one file. Revert = delete the appended section. |
| Off-set regex typo → over-injection (degrades to narrow off-set) | Low | Low | `try/catch` at `ponytail-scoped.mjs:48-52` falls back to the *current* default. Over-injection is the safe failure mode (no crash). Validate the regex in a REPL before commit. |
| Ponytail upstream changes ladder semantics; baked snippets drift | Low | Low | Provenance tags (§9) surface the 8 files on re-vendor. Snippets are paraphrases, so verbatim drift is impossible; only *semantic* drift needs review. |
| A user relied on `/ponytail` for a now-off-set N/A agent | Low | Low | `PONYTAIL_SUBAGENT_OFF` env var overrides the default, so a user can re-enable per agent. Documented in §4. |
| Double injection if an agent is baked but NOT added to off-set | Med (process) | Med | L2 bats test (§9) asserts the 8 baked agents are in the off-set — CI catches the mismatch. |
| Bats count test breaks | — | — | §8 verified: zero tests broken by body edits + regex edit. |

**Rollback (any stage):**
- H1: revert the single regex string in `ponytail-scoped.mjs:41-44`.
- M1–M8: delete the appended `## Ponytail … lens` section in each agent `.md` (each is self-contained and clearly delimited).
- The two are independent: reverting M1–M8 while keeping H1 leaves the 8 agents in the off-set with *no* Ponytail at all (a regression to "under-injected", not broken). Reverting H1 while keeping M1–M8 re-enables double injection (caught by the marker guard only if snippets contained the marker — they do **not**, by design — so this combination is undesirable; revert H1 and M1–M8 together if rolling back the whole hybrid).

---

## 12. Summary Verdict

**Go hybrid (C).** Correct the off-set (H1) for immediate context savings + correctness; then bake the 8 role-tuned lenses (M1–M8) for precision where the generic "lazy senior dev" framing is too blunt. The off-set is the single structural guard against double injection; no magic-string hacks. Zero bats tests break. The vendored SKILL.md remains the canonical source; baked snippets are derivative paraphrases with provenance tags for low-cost drift review.
