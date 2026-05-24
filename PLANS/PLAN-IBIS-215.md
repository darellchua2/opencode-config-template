# PLAN-IBIS-215: Add Tier 1 & Tier 2 high-value skills to OpenCode configurator

**JIRA**: [IBIS-215](https://betekk.atlassian.net/browse/IBIS-215)
**Branch**: `feature/IBIS-215-tier1-tier2-skills`
**Type**: Story — New Skill Creation (x11)
**Priority**: High
**Created**: 2026-05-24

---

## Overview

Based on a gap analysis of the current 62 active skills in `opencode-config-template`, 11 high-value skills are missing. Each addresses a currently uncovered domain broadly applicable to daily developer workflows.

**Current active skill count**: 62 (after completion: 73)
**Note**: `ls` shows 64 entries but `_archived/` and `scripts/` are not counted as active skills.

---

## Phase 1: Skill Creation (11 skills)

All 11 skills are independent SKILL.md file creations with no inter-dependencies. They are created in a single phase.

### Task 1.1: security-audit-skill

- [x] Create `opencode_app/.opencode/skills/security-audit-skill/SKILL.md`
- **Category**: Security (NEW)
- **Content**: OWASP Top 10 checklist, dependency vulnerability scanning (npm audit, pip-audit, Snyk), secret detection (git-secrets, truffleHog), input validation patterns, XSS/CSRF prevention, security headers, HTTPS enforcement
- **Related Skills**: authentication-authorization-skill (identity/session flows), error-resolver-workflow-skill (error diagnosis)
- **Primary Subagent Consumer**: code-review-subagent, architecture-review-subagent

### Task 1.2: docker-containerization-skill

- [x] Create `opencode_app/.opencode/skills/docker-containerization-skill/SKILL.md`
- **Category**: DevOps (NEW)
- **Content**: Dockerfile best practices, multi-stage builds, compose patterns, image size reduction (distroless, Alpine), layer caching, .dockerignore optimization, health checks, security scanning (hadolint, docker scout)
- **Related Skills**: opentofu-provisioning-workflow-skill (infrastructure provisioning)
- **Primary Subagent Consumer**: opentofu-explorer-subagent

### Task 1.3: api-design-skill

- [x] Create `opencode_app/.opencode/skills/api-design-skill/SKILL.md`
- **Category**: Framework
- **Content**: REST conventions (resource naming, HTTP methods, status codes), OpenAPI/Swagger spec generation, GraphQL schema design patterns, API versioning strategies, pagination patterns, rate limiting, error response formats, HATEOAS
- **Related Skills**: clean-architecture-skill (layer boundaries), design-patterns-skill (structural patterns)
- **Primary Subagent Consumer**: architecture-review-subagent

### Task 1.4: database-migration-skill

- [x] Create `opencode_app/.opencode/skills/database-migration-skill/SKILL.md`
- **Category**: DevOps (NEW)
- **Content**: Schema evolution principles, Prisma migration workflow, Alembic (Python/SQLAlchemy) workflow, Django migration workflow, rollback strategies, zero-downtime migrations, seed data management, migration testing
- **Related Skills**: performance-optimization-skill (query optimization — migration OWNS schema lifecycle, performance OWNS runtime profiling)
- **Primary Subagent Consumer**: (none — code-review-subagent may reference)

### Task 1.5: python-backend-skill

- [x] Create `opencode_app/.opencode/skills/python-backend-skill/SKILL.md`
- **Category**: Language-Specific
- **Content**: FastAPI project structure, Django project patterns, Flask blueprints, dependency injection, configuration management (pydantic-settings), project scaffolding (equivalent to nextjs-standard-setup for Python), virtual environment management, requirements/pyproject.toml standards
- **Related Skills**: python-pytest-creator-skill (testing), python-ruff-linter-skill (linting), nextjs-standard-setup-skill (pattern equivalent)
- **Primary Subagent Consumer**: testing-subagent

### Task 1.6: performance-optimization-skill

- [x] Create `opencode_app/.opencode/skills/performance-optimization-skill/SKILL.md`
- **Category**: Framework
- **Content**: Profiling techniques (cProfile, Chrome DevTools), caching strategies (Redis, memoization, CDN), bundle size analysis, lazy loading patterns, database query optimization, N+1 problem detection, memory leak detection
- **Related Skills**: database-migration-skill (schema lifecycle — not runtime), frontend-design-skill (rendering perf)
- **Primary Subagent Consumer**: code-review-subagent

### Task 1.7: authentication-authorization-skill

- [x] Create `opencode_app/.opencode/skills/authentication-authorization-skill/SKILL.md`
- **Category**: Security (NEW)
- **Content**: OAuth2/OIDC flows, JWT best practices, session management, RBAC/ABAC patterns, middleware patterns, NextAuth/Auth.js integration, Passport.js integration, password hashing (bcrypt, argon2), CSRF protection (implementation patterns, not auditing)
- **Related Skills**: security-audit-skill (vulnerability scanning — auth OWNS implementation, security OWNS auditing)
- **Primary Subagent Consumer**: architecture-review-subagent, code-review-subagent

### Task 1.8: accessibility-a11y-skill

- [x] Create `opencode_app/.opencode/skills/accessibility-a11y-skill/SKILL.md`
- **Category**: Framework-Specific
- **Content**: WCAG 2.1 compliance checklist, ARIA patterns, screen reader testing, keyboard navigation, color contrast requirements, automated a11y audits (axe-core, Lighthouse), semantic HTML, focus management
- **Related Skills**: frontend-design-skill (UI creation)
- **Primary Subagent Consumer**: code-review-subagent

### Task 1.9: logging-observability-skill

- [x] Create `opencode_app/.opencode/skills/logging-observability-skill/SKILL.md`
- **Category**: DevOps (NEW)
- **Content**: Structured logging (Winston, pino, structlog), OpenTelemetry integration, distributed tracing, error monitoring setup (Sentry integration, not diagnosis), log aggregation, correlation IDs, log levels best practices, observability stack setup
- **Related Skills**: error-resolver-workflow-skill (error diagnosis — logging OWNS instrumentation setup, error-resolver OWNS runtime diagnosis)
- **Primary Subagent Consumer**: error-resolver-subagent

### Task 1.10: monorepo-management-skill

- [x] Create `opencode_app/.opencode/skills/monorepo-management-skill/SKILL.md`
- **Category**: DevOps (NEW)
- **Content**: Turborepo configuration, Nx workspace setup, pnpm workspaces, package boundary enforcement, shared configs (ESLint, TypeScript, Tailwind), build caching, dependency graph management, changesets for versioning
- **Related Skills**: typescript-dry-principle-skill (code dedup), nextjs-standard-setup-skill (project scaffolding)
- **Primary Subagent Consumer**: (none — general usage)

### Task 1.11: python-packaging-skill

- [x] Create `opencode_app/.opencode/skills/python-packaging-skill/SKILL.md`
- **Category**: Language-Specific
- **Content**: Python packaging for both project-based and library-based pyproject.toml — Poetry, uv, setuptools, hatch, dependency versioning strategies (pinned for apps, ranges for libraries), virtual environment management, publishing to PyPI, build systems, src layout, entry points, CI/CD pipelines
- **Related Skills**: python-backend-skill (project structure uses these packaging tools), python-ruff-linter-skill (linting config in pyproject.toml), python-pytest-creator-skill (test config in pyproject.toml), monorepo-management-skill (monorepo packaging patterns)
- **Primary Subagent Consumer**: testing-subagent, linting-subagent

---

## Phase 2: Synchronization & Documentation

### Task 2.1: Update deploy/setup.sh

- [ ] Update `SKILLS (62):` count to `SKILLS (73):`
- [ ] Add new category `Security (2): security-audit-skill, authentication-authorization-skill`
- [ ] Add new category `DevOps (4): docker-containerization-skill, monorepo-management-skill, database-migration-skill, logging-observability-skill`
- [ ] Add to Framework category: `api-design, performance-optimization` (11 → 13)
- [ ] Add to Language-Specific category: `python-backend-skill, python-packaging-skill` (4 → 6)
- [ ] Add to Framework-Specific category: `accessibility-a11y-skill` (5 → 6)

### Task 2.2: Update deploy/setup.ps1

- [ ] Mirror all setup.sh changes to PowerShell equivalent

### Task 2.3: Update README.md

- [ ] Update Skill Categories table with 11 new skills
- [ ] Update total skill count (62 → 73)
- [ ] Add new Security and DevOps category rows

### Task 2.4: Update AGENTS.md

- [ ] Update skill count references (62 → 73)
- [ ] Update skill directory count references

---

## Category Architecture (Post-Implementation)

```
Framework (13)          Language-Specific (6)     Framework-Specific (6)
├── test-generator      ├── python-pytest         ├── nextjs-pr-workflow
├── linting-workflow    ├── python-ruff-linter    ├── nextjs-unit-test
├── pr-creation         ├── javascript-eslint     ├── nextjs-standard-setup
├── pr-merge            ├── changelog-python      ├── nextjs-image-usage
├── error-resolver      ├── python-backend [NEW]  ├── typescript-dry
├── tdd-workflow        └── python-packaging [N]  └── accessibility-a11y [NEW]
├── docx-creation
├── pptx-specialist     OpenCode Meta (3)         Security (2) [NEW]
├── xlsx-specialist     ├── agent-creation        ├── security-audit
├── pdf-specialist      ├── skill-creation        └── authentication-auth
├── frontend-design     └── skills-maintainer
├── api-design [NEW]                              DevOps (4) [NEW]
└── performance-opt [N] OpenTofu (7)              ├── docker-containerization
                        ├── aws-explorer           ├── monorepo-management
Git/Workflow (10)      ├── keycloak-explorer      ├── database-migration
├── ascii-diagram      ├── kubernetes-explorer     └── logging-observability
├── mermaid-diagram    ├── neon-explorer
├── ticket-plan        ├── provider-setup          Code Quality (7)
├── plan-execution     ├── provisioning           ├── solid-principles
├── git-issue-labeler  └── ecr-provision          ├── clean-code
├── git-issue-updater                              ├── clean-architecture
├── git-semantic       Documentation (3)          ├── design-patterns
├── semantic-release   ├── coverage-readme         ├── object-design
├── git-compact        ├── docstring-generator     ├── code-smells
└── plan-updater       └── documentation-sync      └── complexity-management

JIRA (3)               Agent Optimization (4)     Startup/Business (3)
├── jira-status        ├── continuous-learning     ├── startup-pitch-deck
├── jira-git           ├── eval-harness            ├── startup-business-docs
└── jira-ticket        ├── strategic-compact       └── construction-bd
                        └── verification-loop
Configuration (2)
├── microsoft-m365
└── codegraph-setup
```

---

## Subagent Integration Mapping

| New Skill                    | Primary Subagent Consumer    | Secondary                    |
| ---------------------------- | ---------------------------- | ---------------------------- |
| security-audit               | code-review-subagent         | architecture-review-subagent |
| docker-containerization      | opentofu-explorer-subagent   | —                            |
| api-design                   | architecture-review-subagent | —                            |
| database-migration           | code-review-subagent         | —                            |
| python-backend               | testing-subagent             | —                            |
| performance-optimization     | code-review-subagent         | —                            |
| authentication-authorization | architecture-review-subagent | code-review-subagent         |
| accessibility-a11y           | code-review-subagent         | —                            |
| logging-observability        | error-resolver-subagent      | —                            |
| monorepo-management          | general                      | —                            |
| python-packaging             | testing-subagent             | linting-subagent             |

---

## Scope

| File | Action |
|------|--------|
| `opencode_app/.opencode/skills/security-audit-skill/SKILL.md` | Create |
| `opencode_app/.opencode/skills/docker-containerization-skill/SKILL.md` | Create |
| `opencode_app/.opencode/skills/api-design-skill/SKILL.md` | Create |
| `opencode_app/.opencode/skills/database-migration-skill/SKILL.md` | Create |
| `opencode_app/.opencode/skills/python-backend-skill/SKILL.md` | Create |
| `opencode_app/.opencode/skills/performance-optimization-skill/SKILL.md` | Create |
| `opencode_app/.opencode/skills/authentication-authorization-skill/SKILL.md` | Create |
| `opencode_app/.opencode/skills/accessibility-a11y-skill/SKILL.md` | Create |
| `opencode_app/.opencode/skills/logging-observability-skill/SKILL.md` | Create |
| `opencode_app/.opencode/skills/monorepo-management-skill/SKILL.md` | Create |
| `opencode_app/.opencode/skills/python-packaging-skill/SKILL.md` | Create |
| `deploy/setup.sh` | Update (skill count 62→73 + category listing) |
| `deploy/setup.ps1` | Update (skill count 62→73 + category listing) |
| `README.md` | Update (Skill Categories table) |
| `AGENTS.md` | Update (skill count references) |

---

## Acceptance Criteria

- [x] All 11 skill directories created with valid `SKILL.md` files
- [x] Skill names match `^[a-z0-9]+(-[a-z0-9]+)*$`
- [x] Each description ≤1024 characters, unique among all 73 skills
- [x] Each SKILL.md includes `metadata` block with `audience`, `workflow`, `languages` conventions
- [x] Each SKILL.md includes `## Related Skills` section referencing overlapping skills
- [ ] 2 new categories created: Security (2), DevOps (4)
- [ ] Deploy scripts updated with accurate skill count and category listings
- [ ] README.md and AGENTS.md updated with new counts

---

## Skill Boundary Definitions

| Overlap Pair | Boundary |
|-------------|----------|
| `security-audit` ↔ `authentication-authorization` | security OWNS vulnerability scanning/secret detection/auditing; auth OWNS identity/session flow implementation |
| `logging-observability` ↔ `error-resolver-workflow` | logging OWNS instrumentation setup (Sentry integration, structured logging config); error-resolver OWNS runtime error diagnosis |
| `performance-optimization` ↔ `database-migration` | performance OWNS runtime profiling and query optimization; migration OWNS schema evolution lifecycle |
| `python-backend` ↔ `nextjs-standard-setup` | Intentional consistency — Python equivalent of the Next.js setup pattern |
| `python-packaging` ↔ `python-backend` | packaging OWNS pyproject.toml, dependency tools, publishing; backend OWNS project structure, frameworks, scaffolding |

---

## Risks

| Risk | Severity | Mitigation |
|------|----------|-----------|
| Skill content too generic | Low | Each skill includes language/framework-specific code examples and checklists |
| Description collision with existing skills | Medium | Pre-validate all 11 descriptions against existing 62 for uniqueness |
| Stale count in multiple files | High | setup.sh (62), README.md (62), AGENTS.md — all updated in Phase 2 |
| Subagent skill coverage gaps | Medium | 4 of 11 skills have no dedicated subagent — code-review-subagent covers as fallback |
| SKILL.md frontmatter validation errors | Low | Verify all names pass regex, descriptions within 1024-char limit |
