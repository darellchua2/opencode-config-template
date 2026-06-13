# PLAN: Curate 48 Generic LEARNINGS into opencode-config-template Skills

**Issue**: [BT-69 — Curate 48 generic LEARNINGS: 1 NEW skill + augment 18 existing skills](https://betekk.atlassian.net/browse/BT-69)
**Epic**: [BT-64 — Curate 65 LEARNINGS across 9 repos into opencode-config-template skills](https://betekk.atlassian.net/browse/BT-64)
**Branch**: `BT-69-curate-learnings-skills`
**Status**: Implementation Complete

---

## Summary

Distill 48 generic learnings from 9 repos into skills — 1 new (`react-nextjs-antipatterns-skill`, 19 learnings) + 18 existing skills augmented (42 learnings). 17 project-specific learnings are out of scope.

### Scope Breakdown

| # | Skill | Action | Learnings |
|---|-------|--------|-----------|
| 1 | `react-nextjs-antipatterns-skill` | **NEW** | 19 |
| 2 | `python-backend-skill` | Augment | 8 |
| 3 | `security-audit-skill` | Augment | 3 |
| 4 | `authentication-authorization-skill` | Augment | 3 |
| 5 | `design-patterns-skill` | Augment | 3 |
| 6 | `code-smells-skill` | Augment | 4 |
| 7 | `clean-code-skill` | Augment | 2 |
| 8 | `object-design-skill` | Augment | 2 |
| 9 | `performance-optimization-skill` | Augment | 2 |
| 10 | `api-design-skill` | Augment | 2 |
| 11 | `database-migration-skill` | Augment | 1 |
| 12 | `typescript-dry-principle-skill` | Augment | 2 |
| 13 | `accessibility-a11y-skill` | Augment | 1 |
| 14 | `logging-observability-skill` | Augment | 1 |
| 15 | `opentofu-provider-setup-skill` | Augment | 1 |
| 16 | `opentofu-aws-explorer-skill` | Augment | 1 |
| 17 | `opentofu-ecr-provision-skill` | Augment | 1 |
| 18 | `opentofu-provisioning-workflow-skill` | Augment | 2 |
| 19 | `python-pytest-creator-skill` | Augment | 2 |

### Cross-Skill Learning References (ensure consistent wording)

| Learning ID | Skills |
|-------------|--------|
| `fail-open-rbac-middleware` | react-nextjs-antipatterns, security-audit |
| `module-scope-map-cache` | react-nextjs-antipatterns, performance-optimization |
| `chunked-cookie-secure-prefix-mismatch` | react-nextjs-antipatterns, authentication-authorization |
| `enum-strategy-resolution` | python-backend, design-patterns, object-design |
| `async-api-blocking-poll-pattern` | python-backend, api-design |
| `migration-jsonb-dicts` | python-backend, database-migration |
| `detached-orm-across-sessions` | python-backend, python-pytest-creator |
| `duplicate-type-definitions` | react-nextjs-antipatterns, typescript-dry |
| `duplicated-status-mappings` | react-nextjs-antipatterns, typescript-dry |
| `duplicate-service-account-check` | clean-code, code-smells |

---

## Phase 1: Create NEW `react-nextjs-antipatterns-skill` (19 learnings)

- [x] **1.1** Create `opencode_app/.opencode/skills/react-nextjs-antipatterns-skill/SKILL.md` with frontmatter
- [x] **1.2** Section A: Critical Anti-Patterns — `revalidatepath-try-catch`, `fail-open-rbac`, `derived-state-props`, `ref-guard-early-return`, `route-removal-runtime-nav`
- [x] **1.3** Section B: Memory & Performance — `module-scope-map-cache`, `loading-state-usecallback-deps`, `inline-computed-usememo-dep`, `reset-refs-on-effect-restart`
- [x] **1.4** Section C: React-Specific — `fragment-key-in-map`, `unsafe-json-parse-handler`, `inconsistent-visibility-toggle`, `duplicated-status-mappings`, `duplicate-type-definitions`
- [x] **1.5** Section D: Next.js-Specific — `ssr-false-hydration-mismatch`, `chunked-cookie-secure-prefix-mismatch`
- [x] **1.6** Section E: Recommended Patterns — `hook-decomposition`, `folder-tabs-theme-driven`
- [x] **1.7** Section F: Testing — `browserName-playwright-routing`
- [x] **1.8** Add `Related Skills` cross-links + before/after code examples

## Phase 2: Augment Python/Backend Skills (11 learnings)

- [x] **2.1** `python-backend-skill` — SQLAlchemy sessions (`detached-orm`, `pydantic-jsonb`, `instance-check`), async SSE (`asyncio-queue-sse`, `sse-backpressure`), async API (`blocking-poll`, `enum-strategy`)
- [x] **2.2** `database-migration-skill` — JSONB+asyncpg `bulk_insert` gotcha
- [x] **2.3** `python-pytest-creator-skill` — MagicMock truthy headers, session boundary integration test

## Phase 3: Augment Security & Auth Skills (6 learnings)

- [x] **3.1** `security-audit-skill` — fail-open RBAC detection, debug panel leak, Lambda public without auth
- [x] **3.2** `authentication-authorization-skill` — cookie/session timing, two-layer Keycloak authz, cookie prefix consistency

## Phase 4: Augment Code Quality Skills (11 learnings)

- [x] **4.1** `design-patterns-skill` — Strategy+Enum, Facade Client, Mixin composition
- [x] **4.2** `code-smells-skill` — inline header parsing, duplicated LLM parsing, duplicate service account check, scattered z-index magic numbers
- [x] **4.3** `clean-code-skill` — single level of abstraction, fail loudly not silently
- [x] **4.4** `object-design-skill` — replace primitive with Enum, Enum as Value Object
- [x] **4.5** `typescript-dry-principle-skill` — canonical type import, shared status mapping utility

## Phase 5: Augment Frontend/Perf/API Skills (6 learnings)

- [x] **5.1** `performance-optimization-skill` — N+1 enrichment queries, module-scope cache leak
- [x] **5.2** `api-design-skill` — multi-source schema consistency, async polling API pattern
- [x] **5.3** `accessibility-a11y-skill` — dynamic error banners ARIA
- [x] **5.4** `logging-observability-skill` — silent async failure detection

## Phase 6: Augment OpenTofu/Infra Skills (6 learnings)

- [x] **6.1** `opentofu-provider-setup-skill` — local state warning (migrate to S3+DynamoDB)
- [x] **6.2** `opentofu-aws-explorer-skill` — Lambda function URL with CNAME
- [x] **6.3** `opentofu-ecr-provision-skill` — ECR lowercase naming
- [x] **6.4** `opentofu-provisioning-workflow-skill` — GHA artifact name mismatch, no-rollback-on-deploy

## Phase 7: Documentation Sync

- [x] **7.1** `deploy/setup.sh` + `deploy/setup.ps1` — increment skill count (77→78), add `react-nextjs-antipatterns-skill` to category listing
- [x] **7.2** `README.md` — update skill count, add to Skill Categories table
- [x] **7.3** `AGENTS.md` — add skill routing row
- [x] **7.4** Verify bidirectional cross-links for all 10 cross-skill references
- [x] **7.5** Run `documentation-consistency-skill` audit

## Phase 8: Testing & PR

- [x] **8.1** Verify no existing skill content regressed
- [x] **8.2** Spot-check 3-5 augmented skills for correct formatting
- [x] **8.3** Verify setup scripts list 78 skills
- [x] **8.4** Commit, push, create PR targeting `main`
