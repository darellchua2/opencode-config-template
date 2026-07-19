# PLAN-GIT-247: Integrate LEARNINGS-ASSESSMENT skill improvements

**Issue:** [#247](https://github.com/darellchua2/opencode-config-template/issues/247)
**Branch:** `issue-247`
**Owner:** unassigned
**Status:** Phases 1–4 complete (uncommitted); Phase 5 BLOCKED on user confirmation (unchanged)

---

## Dependency & Consumer Map

### Skill → Agent dependencies

| Skill | Consuming Agents | Notes |
|-------|-----------------|-------|
| `clean-code-skill` | `code-review-subagent` (anti-pattern scan L167), `python-reviewer-subagent` (Backend Patterns L93) | Error Handling section added in Phase 1 |
| `security-audit-skill` | `code-review-subagent` (anti-pattern scan L168), `architecture-review-subagent` (Pattern Reference L92) | 3 new Learning sections in Phase 1 |
| `python-backend-skill` | `python-reviewer-subagent` (Backend Patterns L93), `architecture-review-subagent` (Pattern Reference L92) | DI singleton section added in Phase 1 |
| `design-patterns-skill` | `architecture-review-subagent` (Pattern Reference L92) | Concurrency Patterns section added in Phase 1 |
| `api-design-skill` | `code-review-subagent`, `architecture-review-subagent` | Phase 2 target |
| `docker-containerization-skill` | `code-review-subagent`, `architecture-review-subagent` | Phase 2 target |
| `authentication-authorization-skill` | `code-review-subagent` | Phase 3 target |
| `nextjs-devtools-mcp-skill` | — | Phase 3 target (no agent consumer currently) |
| `code-smells-skill` | `code-review-subagent` | Phase 5 granularization target |

### Phase-level dependencies

- **Phases 1–3** are independent across skills (each skill file is standalone); no cross-skill hard dependencies.
- **Phase 4** depends on a validation decision before work can begin.
- **Phase 5** depends on structural changes to `code-smells-skill` and downstream domain skills, plus a mandatory run of `documentation-sync-workflow` (skill scope changes affect `setup.sh` counts).

---

## Phase 1 — COMPLETE (8 atomic steps, all `[x]`)

- [x] **1.1** Add `### Learning: two-phase-dataclass-initialization` to `clean-code-skill/SKILL.md` (L398)
  — **Why:** Two-phase init silently masks validation gaps; agents need to flag this anti-pattern.
  — **Done when:** `rg "two-phase-dataclass-initialization" opencode_app/.opencode/skills/clean-code-skill/SKILL.md` matches.
  — **Consumers affected:** `code-review-subagent` (anti-pattern scan), `python-reviewer-subagent` (Backend Patterns).

- [x] **1.2** Add `### Learning: broad-except-masks-bugs` to `clean-code-skill/SKILL.md` (L493, merged with silent-error-swallowing)
  — **Why:** Bare `except:` clauses swallow errors silently; root-cause analysis becomes impossible.
  — **Done when:** `rg "broad-except-masks-bugs" opencode_app/.opencode/skills/clean-code-skill/SKILL.md` matches.
  — **Consumers affected:** `code-review-subagent` (anti-pattern scan), `python-reviewer-subagent` (Backend Patterns).

- [x] **1.3** Add `### Learning: silent-failure-sequential-async` to `clean-code-skill/SKILL.md` (L527) and new `## Error Handling` top-level section
  — **Why:** Sequential `await` without error handling fails silently in async chains; grouped under a dedicated section for discoverability.
  — **Done when:** `rg "silent-failure-sequential-async" opencode_app/.opencode/skills/clean-code-skill/SKILL.md` matches AND `rg "## Error Handling" opencode_app/.opencode/skills/clean-code-skill/SKILL.md` matches.
  — **Consumers affected:** `code-review-subagent` (anti-pattern scan), `python-reviewer-subagent` (Backend Patterns).

- [x] **1.4** Add `### Prefer DI Over Global Singletons` to `python-backend-skill/SKILL.md` (L214, under Step 2)
  — **Why:** Global singletons create hidden coupling and prevent test isolation; DI is the preferred pattern for FastAPI projects.
  — **Done when:** `rg "Prefer DI Over Global Singletons" opencode_app/.opencode/skills/python-backend-skill/SKILL.md` matches.
  — **Consumers affected:** `python-reviewer-subagent` (Backend Patterns L93), `architecture-review-subagent` (Pattern Reference L92).

- [x] **1.5** Add 3 Learning sections to `security-audit-skill/SKILL.md`: `auth-early-return-null-account-id` (L152, A01), `claim-check-ephemeral-secret-cache` (L196, A02), `encryption-key-length-not-validated` (L247, A02)
  — **Why:** These are real-world security gaps found in production code; the skill must teach agents to detect and flag them.
  — **Done when:** `rg "auth-early-return-null-account-id|claim-check-ephemeral-secret-cache|encryption-key-length-not-validated" opencode_app/.opencode/skills/security-audit-skill/SKILL.md` returns 3 matches.
  — **Consumers affected:** `code-review-subagent` (anti-pattern scan L168), `architecture-review-subagent` (Pattern Reference L92–96).

- [x] **1.6** Add `## Concurrency Patterns` with `### Learning: atomic-sql-update-race-free-transition` to `design-patterns-skill/SKILL.md` (L636)
  — **Why:** Race conditions in state transitions are a recurring production issue; the atomic UPDATE pattern is the correct fix.
  — **Done when:** `rg "atomic-sql-update-race-free-transition" opencode_app/.opencode/skills/design-patterns-skill/SKILL.md` matches.
  — **Consumers affected:** `architecture-review-subagent` (Pattern Reference L92–96).

- [x] **1.7** Update `code-review-subagent.md` anti-pattern scan list (L167–168) to reference new Phase 1 sections
  — **Why:** The code-review agent must know about new anti-patterns to flag them during reviews.
  — **Done when:** `rg "two-phase-dataclass|broad-except|claim-check|encryption-key-length|null-account-id" opencode_app/.opencode/agents/code-review-subagent.md` returns matches.
  — **Consumers affected:** `code-review-subagent` (self-reference).

- [x] **1.8** Update `python-reviewer-subagent.md` (L93) and `architecture-review-subagent.md` (L92–96) agent checklists to reference Phase 1 sections
  — **Why:** Both agents need expanded pattern lists to surface new findings during Python and architecture reviews.
  — **Done when:** `rg "two-phase-dataclass|global _service|broad-except" opencode_app/.opencode/agents/python-reviewer-subagent.md` matches AND `rg "singleton mutation|claim-check|Atomic conditional UPDATE" opencode_app/.opencode/agents/architecture-review-subagent.md` matches.
  — **Consumers affected:** `python-reviewer-subagent` (self-reference), `architecture-review-subagent` (self-reference).

---

## Phase 2 — COMPLETE (9 atomic steps, all `[x]`)

- [x] **2.1** Add `#### fail-closed-open-config-toggle` to `security-audit-skill/SKILL.md` (under A01, after auth-early-return-null-account-id)
  — **Why:** Open-by-default security toggles create exploitable misconfiguration vectors; agents must detect and flag.
  — **Done when:** `rg "fail-closed-open-config-toggle" opencode_app/.opencode/skills/security-audit-skill/SKILL.md` matches.
  — **Consumers affected:** `code-review-subagent` (anti-pattern scan).

- [x] **2.2** Add `#### missing-tenant-isolation-definitions` to `security-audit-skill/SKILL.md` (under A01, after 2.1)
  — **Why:** Multi-tenant systems without isolation boundaries leak data between tenants; a critical security pattern.
  — **Done when:** `rg "missing-tenant-isolation" opencode_app/.opencode/skills/security-audit-skill/SKILL.md` matches.
  — **Consumers affected:** `code-review-subagent` (anti-pattern scan), `architecture-review-subagent` (Pattern Reference).

- [x] **2.3** Add `#### local-terraform-state-production` to `security-audit-skill/SKILL.md` (under existing Cloud Security section)
  — **Why:** Local state files in production contain sensitive outputs and lack audit trails; must flag as infra-security anti-pattern.
  — **Done when:** `rg "local-terraform-state" opencode_app/.opencode/skills/security-audit-skill/SKILL.md` matches.
  — **Consumers affected:** `code-review-subagent` (anti-pattern scan), `architecture-review-subagent` (Pattern Reference).

- [x] **2.4** Add `### Learning: json-default-str-numpy-masking` to `python-backend-skill/SKILL.md` (after Instance Check Over Field Lists, near data/serialization)
  — **Why:** `json.dumps(default=str)` silently masks type errors when numpy arrays are passed; data corruption follows silently.
  — **Done when:** `rg "json-default-str-numpy-masking" opencode_app/.opencode/skills/python-backend-skill/SKILL.md` matches.
  — **Consumers affected:** `python-reviewer-subagent` (Backend Patterns).

- [x] **2.5** Add `### Learning: centralized-single-source-config` to `python-backend-skill/SKILL.md` (right after pydantic-settings Settings class)
  — **Why:** Scattered config values across modules cause drift and make environment-specific overrides error-prone.
  — **Done when:** `rg "centralized-single-source-config" opencode_app/.opencode/skills/python-backend-skill/SKILL.md` matches.
  — **Consumers affected:** `python-reviewer-subagent` (Backend Patterns), `architecture-review-subagent` (Pattern Reference).

- [x] **2.6** Add `### Learning: defensive-enum-mapping-from-db-strings` to `python-backend-skill/SKILL.md` (after Enum Strategy Resolution section)
  — **Why:** Unmapped DB strings crash enum construction; defensive mapping prevents production KeyError exceptions.
  — **Done when:** `rg "defensive-enum-mapping" opencode_app/.opencode/skills/python-backend-skill/SKILL.md` matches.
  — **Consumers affected:** `python-reviewer-subagent` (Backend Patterns).

- [x] **2.7** Add `### Learning: schema-output-contract-gap` to `api-design-skill/SKILL.md` (new `## Step 5.55: Output Schema Contract Verification` section after Step 5.5)
  — **Why:** API handlers that return ad-hoc dicts instead of schema-validated responses break consumer contracts silently.
  — **Done when:** `rg "schema-output-contract-gap" opencode_app/.opencode/skills/api-design-skill/SKILL.md` matches.
  — **Consumers affected:** `code-review-subagent` (anti-pattern scan), `architecture-review-subagent` (Pattern Reference).

- [x] **2.8** Add `### Learning: no-rollback-on-deploy` to `docker-containerization-skill/SKILL.md` (new `## Deployment Rollback Strategy` section at end of file)
  — **Why:** Deployments without rollback strategies leave production in a broken state when new images fail; a critical ops anti-pattern.
  — **Done when:** `rg "no-rollback-on-deploy" opencode_app/.opencode/skills/docker-containerization-skill/SKILL.md` matches.
  — **Consumers affected:** `code-review-subagent` (anti-pattern scan), `architecture-review-subagent` (Pattern Reference).

- [x] **2.9** Add `### Learning: double-checked-locking-async-refresh` to `design-patterns-skill/SKILL.md` (under Concurrency Patterns, after atomic-sql-update-race-free-transition)
  — **Why:** Double-checked locking in async contexts is a subtle correctness bug; the pattern section must warn against it.
  — **Done when:** `rg "double-checked-locking-async-refresh" opencode_app/.opencode/skills/design-patterns-skill/SKILL.md` matches.
  — **Consumers affected:** `architecture-review-subagent` (Pattern Reference).

---

## Phase 3 — COMPLETE (14 atomic steps, all `[x]`)

- [x] **3.1** Add `### Learning: inline-imports-in-functions` to `clean-code-skill/SKILL.md` (after brittle-single-strategy-data-extraction; CORRECTED from python-backend — this is a language-agnostic anti-pattern)
  — **Why:** Lazy imports obscure module-level dependencies and break static analysis; flag as readability/maintainability issue.
  — **Done when:** `rg "inline-imports-in-functions" opencode_app/.opencode/skills/clean-code-skill/SKILL.md` matches.
  — **Consumers affected:** `code-review-subagent` (anti-pattern scan).

- [x] **3.2** Add `### Learning: method-name-reuse-different-semantics` to `clean-code-skill/SKILL.md` (under Naming Principles, after Austerity)
  — **Why:** Reusing method names with different semantics across classes violates the principle of least surprise.
  — **Done when:** `rg "method-name-reuse-different-semantics" opencode_app/.opencode/skills/clean-code-skill/SKILL.md` matches.
  — **Consumers affected:** `code-review-subagent` (anti-pattern scan).

- [x] **3.3** Add `### Learning: hardcoded-sed-version-swap` to `docker-containerization-skill/SKILL.md` (new `## Build ARG Centralization` section at end of file)
  — **Why:** Sed-based version substitution in Dockerfiles is brittle and non-portable; prefer ARG/buildkit.
  — **Done when:** `rg "hardcoded-sed-version-swap" opencode_app/.opencode/skills/docker-containerization-skill/SKILL.md` matches.
  — **Consumers affected:** `code-review-subagent` (anti-pattern scan).

- [x] **3.4** Add `### Learning: self-documented-duplication` to `clean-code-skill/SKILL.md` (under Comments section, after Prefer Self-Documenting Code)
  — **Why:** Code that is self-documented yet duplicated across modules indicates missing abstraction; DRY violation disguised as clarity.
  — **Done when:** `rg "self-documented-duplication" opencode_app/.opencode/skills/clean-code-skill/SKILL.md` matches.
  — **Consumers affected:** `code-review-subagent` (anti-pattern scan).

- [x] **3.5** Add `### Learning: mock-headers-magicmock-truthy` to `test-generator-framework-skill/SKILL.md` (new `## Mock Pitfalls` section before Best Practices; CORRECTED from python-backend — this is a testing pattern)
  — **Why:** MagicMock returns truthy for any attribute access, masking header typos in tests; agents must flag as test anti-pattern.
  — **Done when:** `rg "mock-headers-magicmock-truthy" opencode_app/.opencode/skills/test-generator-framework-skill/SKILL.md` matches.
  — **Consumers affected:** `python-reviewer-subagent` (Backend Patterns) — and testing-subagent indirectly.

- [x] **3.6** Add `### Learning: toast-promise-await-without-catch` to `react-nextjs-antipatterns-skill/SKILL.md` (new `### C6.` under Section C; CORRECTED from clean-code — this is React/sonner-specific)
  — **Why:** Toast notifications wrapping Promises without catch handlers swallow errors silently from the user's perspective.
  — **Done when:** `rg "toast-promise-await-without-catch" opencode_app/.opencode/skills/react-nextjs-antipatterns-skill/SKILL.md` matches.
  — **Consumers affected:** `code-review-subagent` (anti-pattern scan).

- [x] **3.7** Add `### Learning: doc-claimed-purity-vs-reality` to `clean-architecture-skill/SKILL.md` (after Contracts section, under Dependency Rule; CORRECTED from clean-code — this is about layer boundaries)
  — **Why:** Functions documented as pure that perform I/O create false confidence and prevent correct refactoring.
  — **Done when:** `rg "doc-claimed-purity-vs-reality" opencode_app/.opencode/skills/clean-architecture-skill/SKILL.md` matches.
  — **Consumers affected:** `code-review-subagent` (anti-pattern scan).

- [x] **3.8** Add `### Learning: cross-container-hook-borrowing` to `clean-architecture-skill/SKILL.md` (after Frontend Structure under Feature-Driven; CORRECTED from design-patterns — this is about container isolation)
  — **Why:** Borrowing hooks from one Docker container into another creates implicit coupling and brittle deployment dependencies.
  — **Done when:** `rg "cross-container-hook-borrowing" opencode_app/.opencode/skills/clean-architecture-skill/SKILL.md` matches.
  — **Consumers affected:** `architecture-review-subagent` (Pattern Reference).

- [x] **3.9** Add `### Learning: placeholder-swap-validation` to `api-design-skill/SKILL.md` (new `## Step 5.57: Placeholder Swap for File-Reference Validation` section after Step 5.55; CORRECTED from python-backend — this is API validation)
  — **Why:** Template placeholder swaps without validation inject malformed content when keys are missing.
  — **Done when:** `rg "placeholder-swap-validation" opencode_app/.opencode/skills/api-design-skill/SKILL.md` matches.
  — **Consumers affected:** `python-reviewer-subagent` (Backend Patterns) — and API reviews.

- [x] **3.10** Add `### Learning: hardcoded-magic-timeout-activities` to `performance-optimization-skill/SKILL.md` (under Step 5 Memory Leak Detection, after React Cleanup; CORRECTED from python-backend — this is perf/tunability)
  — **Why:** Magic timeout values in activity/step functions create race conditions under load; must be configurable.
  — **Done when:** `rg "hardcoded-magic-timeout" opencode_app/.opencode/skills/performance-optimization-skill/SKILL.md` matches.
  — **Consumers affected:** `python-reviewer-subagent` (Backend Patterns) — and performance reviews.

- [x] **3.11** Add `### Learning: cookie-only-proxy-with-server-rbac` to `authentication-authorization-skill/SKILL.md` (new `### \`cookie-only-proxy-with-server-rbac\`` subsection at end of Step 7 Cookie Security)
  — **Why:** Cookie-only auth behind a proxy that also does RBAC creates a double-layer confusion; agents need to identify the correct enforcement boundary.
  — **Done when:** `rg "cookie-only-proxy-with-server-rbac" opencode_app/.opencode/skills/authentication-authorization-skill/SKILL.md` matches.
  — **Consumers affected:** `code-review-subagent` (anti-pattern scan).

- [x] **3.12** Add `### Learning: zero-copy-buffer-to-uint8array` to `performance-optimization-skill/SKILL.md` (under Step 5, after Hardcoded Timeouts; CORRECTED from python-backend — this is Node.js/Lambda memory)
  — **Why:** Converting buffers to Uint8Array without zero-copy creates unnecessary memory allocations in hot paths.
  — **Done when:** `rg "zero-copy-buffer-to-uint8array" opencode_app/.opencode/skills/performance-optimization-skill/SKILL.md` matches.
  — **Consumers affected:** `python-reviewer-subagent` (Backend Patterns) — and performance reviews.

- [x] **3.13** Add `### Learning: three-line-not-disposed-in-overlay-cleanup` to `performance-optimization-skill/SKILL.md` (under Step 5, after Zero-Copy; CORRECTED from nextjs-devtools-mcp — this is a Three.js perf pattern, not Next.js devtools)
  — **Why:** Three.js objects not disposed during overlay cleanup cause GPU memory leaks in long-running sessions.
  — **Done when:** `rg "three-line-not-disposed" opencode_app/.opencode/skills/performance-optimization-skill/SKILL.md` matches.
  — **Consumers affected:** None — content addition only (no agent currently references this skill).

- [x] **3.14** Add `### Learning: feature-bounds-value-object` to `code-smells-skill/SKILL.md` (new `#### \`feature-bounds-value-object\`` under `### 4. Primitive Obsession`; CORRECTED from clean-code — this is the value-object extraction for primitive obsession)
  — **Why:** Feature flags gating business logic without value-object encapsulation create scattered conditionals; encapsulate in value objects.
  — **Done when:** `rg "feature-bounds-value-object" opencode_app/.opencode/skills/code-smells-skill/SKILL.md` matches.
  — **Consumers affected:** `code-review-subagent` (anti-pattern scan).

---

## Phase 4 — COMPLETE (1 atomic step, validated and applied)

- [x] **4.1** Add `### Learning: parallel-hierarchies-for-report-type-variants` to `clean-code-skill/SKILL.md` (after two-phase-dataclass-initialization, under Object Calisthenics)
  — **Why:** Parallel class hierarchies for report variants indicate missing abstraction; the correct skill home depends on whether the pattern is a code smell or an architecture concern.
  — **Done when:** Validation decision recorded (which skill) AND `rg "parallel-hierarchies-for-report" <target-skill>/SKILL.md` matches.
  — **Consumers affected:** `code-review-subagent` (anti-pattern scan).
  — **VALIDATION DECISION:** Placed in `clean-code-skill/SKILL.md` near Object Calisthenics. Rationale: `clean-architecture-skill/SKILL.md` has NO existing "Parallel Inheritance" or "Variant Abstraction" section, and the assessment frames this as a >70% similarity duplication heuristic (a code smell). Per the task's decision tree, the absence of an architecture section combined with the code-smell framing routes it to clean-code near Object Calisthenics. The pattern is fundamentally about duplication/drift between two implementations, which is a clean-code concern (DRY), not a layer-boundary concern.

---

## Phase 5 — COMPLETE (1 atomic step, user confirmation received 2026-07-19)

- [x] **5.1** Granularize `code-smells-skill` items #8–11 — moved project-specific smells into domain skills (inline-http-header-parsing → `python-backend-skill`, duplicated-response-parsing → `python-backend-skill`, duplicate-service-account-check → `python-backend-skill`, scattered-z-index-magic-numbers → `clean-code-skill`)
  — **Why:** Generic code-smell descriptions with project-specific examples reduced the skill's reusability; domain skills provide better context.
  — **Done when:** Project-specific items removed from `code-smells-skill/SKILL.md` AND equivalent Learning sections added to target domain skills AND `documentation-sync-workflow` run to update `setup.sh` counts if skill file structure changed.
  — **Consumers affected:** `code-review-subagent` (references both code-smells-skill and domain skills), all domain target skills.
  — **Status:** User confirmation received 2026-07-19. Items #8-10 moved to `python-backend-skill/SKILL.md` (appended after defensive-enum-mapping section). Item #11 moved to `clean-code-skill/SKILL.md` under new `## Frontend Patterns` section. Source rows also removed from the Couplers summary table in code-smells-skill. **No sync-file update needed** — file counts unchanged (no skill directories added/removed); content edits only.
