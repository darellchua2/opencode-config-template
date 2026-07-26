# Skill Permission Scoping Optimization (Allowlist Strategy)

**Issue**: https://github.com/darellchua2/opencode-config-template/issues/270
**Branch**: issue-270
**Type**: enhancement
**Labels**: enhancement, documentation

## Overview

Optimize initial-context token consumption by implementing an **allowlist** skill permission scoping strategy. The opencode primary session loads every skill's `description` into the `<available_skills>` listing at startup ([docs-confirmed](https://opencode.ai/docs/skills/#recognize-tool-description)). With ~124 deployed skills, this listing is a significant per-session token tax.

The **allowlist** approach: set `"*": "deny"` (hide ALL skills from the primary by default), then explicitly `"allow"` only the curated set of primary-visible skills. This is a bigger optimization than the original denylist strategy (which only hid 17–19 skills) because it can hide 40+ skill descriptions from every primary session.

**Why allowlist > denylist:** with ~124 skills and a denylist of ~19, the primary still loads ~105 descriptions. An allowlist of ~80 primary-visible skills hides ~44 — more than double the savings — and scales automatically (new skills added to the repo default to hidden until explicitly added to the allowlist).

**Doc basis (verified):**
- [Permissions §Granular Rules](https://opencode.ai/docs/permissions/#granular-rules-object-syntax): *"Rules are evaluated by pattern match, with the **last matching rule winning**. A common pattern is to put the catch-all `"*"` rule first, and more specific rules after it."* So `"*": "deny"` followed by specific `"skill-name": "allow"` entries works — the specific allow (placed after) overrides the catch-all deny.
- [Skills §Configure permissions](https://opencode.ai/docs/skills/#configure-permissions): `"deny"` → "Skill hidden from agent."
- [Skills §Override per agent](https://opencode.ai/docs/skills/#override-per-agent): per-agent frontmatter `permission.skill` can re-`allow`.

**Subagent impact — minimal:** 36 of 39 subagents already have their own `permission.skill` blocks (self-scoped — the global allowlist is irrelevant to them). Only 3 subagents lack `permission.skill` (explorer, google-mcp-specialist, image-analyzer) — none of these load skills via the Skill tool. The global allowlist effectively governs only the **primary session**.

This enforces hub-and-spoke routing (already the repo's pattern per `deploy/.AGENTS.md`): the primary delegates to the subagent, which loads the skill. Consistent, not a behavior break — but should be documented so direct-load attempts aren't surprising.

## Acceptance Criteria

- [x] GitHub issue created (#270)
- [x] Branch created (issue-270)
- [x] PLAN file generated with atomic steps + rationale + Dependency & Consumer Map
- [ ] Add `permission.skill` allowlist block to the EXISTING `permission` key in `opencode_app/opencode.json` (L19–23), merged as a new `skill` sub-key
- [ ] Confirm all consumer subagent `allow` overrides are present and complete (verify-only — no additions needed)
- [ ] Verify no consumer subagent regresses (all can still load required skills)
- [ ] Document allowlist enforcement in `deploy/.AGENTS.md`
- [ ] Verify denied skills absent from primary's `<available_skills>` (manual runtime test)
- [ ] Validate `opencode_app/opencode.json` syntax (JSONC — use `node -e`, not `jq`)

## Scope

- `opencode_app/opencode.json` — merge `skill` sub-key into EXISTING top-level `permission` block (L19–23)
- `deploy/.AGENTS.md` — documentation
- **No agent file edits** — all consumer subagent `allow` overrides already exist (Phase 3 = verify only)

## Technical Notes

### Implementation Location (B3 — definitive, no hedging)

The `permission.skill` allowlist is merged INTO the **EXISTING** top-level `permission` key at L19–23 of `opencode_app/opencode.json` as a new `skill` sub-key. It is NOT a separate `permission` block. The current block:

```jsonc
"permission": {
  "read_mcp_resource": "deny",
  "list_mcp_resources": "deny",
  "list_mcp_resource_templates": "deny"
},
```

Becomes:

```jsonc
"permission": {
  "read_mcp_resource": "deny",
  "list_mcp_resources": "deny",
  "list_mcp_resource_templates": "deny",
  "skill": {
    "*": "deny",
    "<primary-visible-skill-1>": "allow",
    "<primary-visible-skill-2>": "allow"
    // ... full allowlist from classification table below
  }
},
```

**JSONC note:** the file uses `//` comments. `jq` cannot parse JSONC. Validate with `node -e "JSON.parse(require('fs').readFileSync('opencode_app/opencode.json','utf8').replace(/\/\/.*/g,''))"` or use `jsonc-parser` / `json5`.

### ticket-creation-subagent Clarification (§4 review fix)

`ticket-creation-subagent` loads `srs-creation-skill` and `brd-creation-skill` for **naming/numbering only** (deriving the ticket key from the document slug), NOT for rendering `.docx` outputs. It is therefore **NOT** a consumer of `interactive-document-rendering-skill`. Its existing skill block (`semantic-release-convention`, `ticket-plan-workflow`, `git-issue-updater`, `git-issue-labeler`, `jira-ticket-labeler`) is correct and complete.

## Skill Classification

### Methodology

Each of the 124 deployed skills (excluding `_archived/` and `_common/`) was classified using:

1. **User-confirmed classifications** (authoritative — do not override)
2. **Verified consumer subagent `permission.skill` blocks** (36 of 39 subagents have self-scoped blocks; a skill can only be denied if every agent that needs it has an explicit `allow` override)
3. **Classification heuristics** (user-invoked orchestrators → primary; niche specialist → subagent-only; broad-purpose → primary)
4. **Uncertainty rule:** lean PRIMARY-VISIBLE (hiding a skill the primary needs is worse than showing one it doesn't)

### DENIED — Subagent-only / Internal (44 skills, caught by `"*": "deny"`)

These skills are hidden from the primary's `<available_skills>`. Every consumer subagent that needs them already has an explicit `allow` override in its frontmatter (verified).

| # | Skill | Consumer Subagent(s) with `allow` Override | Rationale |
|---|-------|---------------------------------------------|-----------|
| **CAD Cluster (14)** | | | |
| 1 | `cad-generation-skill` | cad-specialist-subagent | Primary always delegates CAD to cad-specialist |
| 2 | `cad-viewer-skill` | cad-specialist-subagent | Same |
| 3 | `cad-step-parts-skill` | cad-specialist-subagent | Same |
| 4 | `cad-dxf-skill` | cad-specialist-subagent | Same |
| 5 | `cad-urdf-skill` | cad-specialist-subagent | Same |
| 6 | `cad-srdf-skill` | cad-specialist-subagent | Same |
| 7 | `cad-sdf-skill` | cad-specialist-subagent | Same |
| 8 | `cad-sendcutsend-skill` | cad-specialist-subagent | Same |
| 9 | `cad-gcode-skill` | cad-specialist-subagent | Same |
| 10 | `cad-bambu-labs-skill` | cad-specialist-subagent | Same |
| 11 | `cad-implicit-skill` | cad-specialist-subagent | Same |
| 12 | `autodesk-aps-skill` | cad-specialist-subagent | Same |
| 13 | `civil-3d-skill` | cad-specialist-subagent | Same |
| 14 | `open3d-skill` | cad-specialist-subagent | Same |
| **Autoresearch Cluster (4)** | | | |
| 15 | `autoresearch-core-skill` | autoresearch-{code,ml,research}-subagent | Internal protocol skill; loaded by derivative skills only |
| 16 | `autoresearch-code-skill` | autoresearch-code-subagent | Autonomous loop skill; primary delegates to subagent |
| 17 | `autoresearch-ml-skill` | autoresearch-ml-subagent | Same |
| 18 | `autoresearch-research-skill` | autoresearch-research-subagent | Same |
| **OpenTofu Cluster (7)** | | | |
| 19 | `opentofu-kubernetes-explorer-skill` | opentofu-explorer-subagent | Niche IaC; primary delegates to opentofu-explorer |
| 20 | `opentofu-neon-explorer-skill` | opentofu-explorer-subagent | Same |
| 21 | `opentofu-aws-explorer-skill` | opentofu-explorer-subagent | Same |
| 22 | `opentofu-keycloak-explorer-skill` | opentofu-explorer-subagent | Same |
| 23 | `opentofu-provisioning-workflow-skill` | opentofu-explorer-subagent | Same |
| 24 | `opentofu-provider-setup-skill` | opentofu-explorer-subagent | Same |
| 25 | `opentofu-ecr-provision-skill` | opentofu-explorer-subagent | Same |
| **Internal Framework / Helper (2)** | | | |
| 26 | `test-generator-framework-skill` | testing-subagent | Internal framework; loaded by language-specific test creators |
| 27 | `interactive-document-rendering-skill` | discovery, requirements, technical-design-specialist | Internal helper; loaded by document-creation skills (brd/srs/vision/technical-design) |
| **Explicitly Subagent-Only (2)** | | | |
| 28 | `uiux-review-skill` | uiux-reviewer-subagent | Description: routed via uiux-reviewer-subagent |
| 29 | `playwright-responsive-audit-skill` | responsive-audit-subagent | Description: "invoked exclusively via permission.skill by the audit subagent" |
| **PPTX Engine (3)** | | | |
| 30 | `pptx-generate-slide-skill` | pptx-specialist-subagent, office-document-primary-agent | Engine skill; primary delegates to pptx-specialist |
| 31 | `pptx-generate-template-skill` | pptx-specialist-subagent, office-document-primary-agent | Same |
| 32 | `pptx-template-modifier-skill` | pptx-specialist-subagent, office-document-primary-agent | Same |
| **OOXML / Thumbnail (2)** | | | |
| 33 | `ooxml-editing-skill` | pptx-specialist-subagent | Surgical XML editing engine; primary delegates |
| 34 | `office-thumbnail-skill` | pptx-specialist-subagent | Niche utility; primary delegates |
| **Language-Specific Linters (2)** | | | |
| 35 | `python-ruff-linter-skill` | linting-subagent | Specialist linter; primary delegates to linting-subagent |
| 36 | `javascript-eslint-linter-skill` | linting-subagent | Same |
| **Language-Specific Test Creators (2)** | | | |
| 37 | `python-pytest-creator-skill` | testing-subagent | Specialist test creator; primary delegates to testing-subagent |
| 38 | `nextjs-unit-test-creator-skill` | testing-subagent | Same |
| **Next.js Specialist (4)** | | | |
| 39 | `nextjs-standard-setup-skill` | nextjs-specialist-subagent | Framework setup; primary delegates to nextjs-specialist |
| 40 | `nextjs-image-usage-skill` | nextjs-specialist-subagent | Same |
| 41 | `react-nextjs-antipatterns-skill` | nextjs-specialist-subagent | Same |
| 42 | `amplify-nextjs-deployment-skill` | nextjs-specialist-subagent | Same |
| **Docs / Coverage (2)** | | | |
| 43 | `docstring-generator-skill` | documentation-subagent, nextjs-specialist-subagent | Specialist doc generator; primary delegates |
| 44 | `coverage-readme-workflow-skill` | documentation-subagent, coverage-subagent | Specialist coverage skill; primary delegates |

### ALLOWED — Primary-Visible (80 skills)

These skills appear in the primary's `<available_skills>` listing. Grouped by category with rationale.

| Category | Skills | Rationale |
|----------|--------|-----------|
| **Explicitly primary-loaded** (deploy/.AGENTS.md routing) | `openapi-contract-adherence-skill`, `markitdown-mcp-skill`, `git-branch-workflow-setup-skill`, `git-semantic-commits-skill`, `documentation-sync-workflow-skill`, `ticket-plan-workflow-skill`, `grilling-skill`, `linting-workflow-skill` | deploy/.AGENTS.md explicitly routes these to the primary; user-confirmed for `grilling` and `linting-workflow` |
| **User-invoked orchestrators** | `grill-me-skill`, `grill-with-docs-skill`, `wireframer-skill`, `vision-creation-skill`, `srs-creation-skill`, `brd-creation-skill`, `technical-design-creation-skill`, `domain-modeling-skill`, `research-paper-generation-skill`, `horseshoe-paper-writing-skill` | User triggers these directly from the primary session |
| **Process / workflow** (git, plan, PR, JIRA) | `git-compact-commits-skill`, `git-issue-labeler-skill`, `git-issue-updater-skill`, `jira-git-integration-skill`, `jira-status-updater-skill`, `jira-ticket-labeler-skill`, `plan-execution-skill`, `plan-updater-skill`, `pr-creation-workflow-skill`, `pr-merge-workflow-skill`, `nextjs-pr-workflow-skill`, `semantic-release-convention-skill`, `version-bump-standard-skill` | Primary manages these workflows directly |
| **OpenCode tooling** | `opencode-agent-creation-skill`, `opencode-skill-creation-skill`, `opencode-skills-maintainer-skill`, `agent-introspection-debugging-skill`, `documentation-consistency-skill` | Primary manages OpenCode configuration |
| **Context / session management** | `context-budget-skill`, `strategic-compact-skill`, `continuous-learning-skill`, `verification-loop-skill`, `eval-harness-skill` | Primary loads these for session optimization |
| **Broad knowledge** (design, architecture, quality) | `clean-code-skill`, `clean-architecture-skill`, `solid-principles-skill`, `design-patterns-skill`, `code-smells-skill`, `complexity-management-skill`, `object-design-skill`, `search-first-skill`, `security-audit-skill`, `performance-optimization-skill` | Primary loads for inline guidance; task heuristic: "broad-purpose → primary-visible" |
| **MCP reference / utility** | `microsoft-m365-config-skill`, `nextjs-devtools-mcp-skill`, `codegraph-setup-skill`, `ascii-diagram-creator-skill`, `mermaid-diagram-creator-skill` | Primary loads for MCP routing and quick utilities |
| **API / data / infra knowledge** | `api-design-skill`, `authentication-authorization-skill`, `database-migration-skill`, `docker-containerization-skill`, `logging-observability-skill`, `tdd-workflow-skill`, `deprecated-code-cleanup-skill`, `error-resolver-workflow-skill` | Primary loads for inline knowledge while doing work directly |
| **Document creation** (user-facing) | `docx-creation-skill`, `pdf-specialist-skill`, `xlsx-specialist-skill` | User invokes directly from primary; pdf-specialist has NO consumer override (must stay visible) |
| **No consumer override** (must stay visible — no subagent can load if denied) | `construction-bd-skill`, `startup-business-docs-skill`, `startup-pitch-deck-skill`, `python-packaging-skill`, `python-backend-skill`, `csharp-linter-skill`, `java-linter-skill`, `typescript-dry-principle-skill`, `monorepo-management-skill`, `threejs-nextjs-skill`, `frontend-design-skill`, `accessibility-a11y-skill`, `changelog-python-cliff-skill` | These skills have no verified consumer subagent with an explicit `allow` override; denying would make them inaccessible to all scoped subagents. Some have consumer overrides but the primary may also need them (uncertain → lean primary) |

### Full `permission.skill` Block for opencode.json

```jsonc
"skill": {
  "*": "deny",

  // --- Explicitly primary-loaded (8) ---
  "openapi-contract-adherence-skill": "allow",
  "markitdown-mcp-skill": "allow",
  "git-branch-workflow-setup-skill": "allow",
  "git-semantic-commits-skill": "allow",
  "documentation-sync-workflow-skill": "allow",
  "ticket-plan-workflow-skill": "allow",
  "grilling-skill": "allow",
  "linting-workflow-skill": "allow",

  // --- User-invoked orchestrators (10) ---
  "grill-me-skill": "allow",
  "grill-with-docs-skill": "allow",
  "wireframer-skill": "allow",
  "vision-creation-skill": "allow",
  "srs-creation-skill": "allow",
  "brd-creation-skill": "allow",
  "technical-design-creation-skill": "allow",
  "domain-modeling-skill": "allow",
  "research-paper-generation-skill": "allow",
  "horseshoe-paper-writing-skill": "allow",

  // --- Process / workflow (13) ---
  "git-compact-commits-skill": "allow",
  "git-issue-labeler-skill": "allow",
  "git-issue-updater-skill": "allow",
  "jira-git-integration-skill": "allow",
  "jira-status-updater-skill": "allow",
  "jira-ticket-labeler-skill": "allow",
  "plan-execution-skill": "allow",
  "plan-updater-skill": "allow",
  "pr-creation-workflow-skill": "allow",
  "pr-merge-workflow-skill": "allow",
  "nextjs-pr-workflow-skill": "allow",
  "semantic-release-convention-skill": "allow",
  "version-bump-standard-skill": "allow",

  // --- OpenCode tooling (5) ---
  "opencode-agent-creation-skill": "allow",
  "opencode-skill-creation-skill": "allow",
  "opencode-skills-maintainer-skill": "allow",
  "agent-introspection-debugging-skill": "allow",
  "documentation-consistency-skill": "allow",

  // --- Context / session management (5) ---
  "context-budget-skill": "allow",
  "strategic-compact-skill": "allow",
  "continuous-learning-skill": "allow",
  "verification-loop-skill": "allow",
  "eval-harness-skill": "allow",

  // --- Broad knowledge (10) ---
  "clean-code-skill": "allow",
  "clean-architecture-skill": "allow",
  "solid-principles-skill": "allow",
  "design-patterns-skill": "allow",
  "code-smells-skill": "allow",
  "complexity-management-skill": "allow",
  "object-design-skill": "allow",
  "search-first-skill": "allow",
  "security-audit-skill": "allow",
  "performance-optimization-skill": "allow",

  // --- MCP reference / utility (5) ---
  "microsoft-m365-config-skill": "allow",
  "nextjs-devtools-mcp-skill": "allow",
  "codegraph-setup-skill": "allow",
  "ascii-diagram-creator-skill": "allow",
  "mermaid-diagram-creator-skill": "allow",

  // --- API / data / infra knowledge (8) ---
  "api-design-skill": "allow",
  "authentication-authorization-skill": "allow",
  "database-migration-skill": "allow",
  "docker-containerization-skill": "allow",
  "logging-observability-skill": "allow",
  "tdd-workflow-skill": "allow",
  "deprecated-code-cleanup-skill": "allow",
  "error-resolver-workflow-skill": "allow",

  // --- Document creation — user-facing (3) ---
  "docx-creation-skill": "allow",
  "pdf-specialist-skill": "allow",
  "xlsx-specialist-skill": "allow",

  // --- No consumer override — must stay visible (13) ---
  "construction-bd-skill": "allow",
  "startup-business-docs-skill": "allow",
  "startup-pitch-deck-skill": "allow",
  "python-packaging-skill": "allow",
  "python-backend-skill": "allow",
  "csharp-linter-skill": "allow",
  "java-linter-skill": "allow",
  "typescript-dry-principle-skill": "allow",
  "monorepo-management-skill": "allow",
  "threejs-nextjs-skill": "allow",
  "frontend-design-skill": "allow",
  "accessibility-a11y-skill": "allow",
  "changelog-python-cliff-skill": "allow"
}
```

**Allowlist size: 80 skills.** Denied by `"*": "deny"`: 44 skills.

## Dependency & Consumer Map

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---------------------|---------------------------|---------------------------------|-------------|
| `opencode_app/opencode.json` (L19–23, `permission` block) | — | Primary session (via skill loading), 3 unscooped subagents (explorer, google-mcp, image-analyzer) | medium (breaks skill loading if malformed) |
| 36 self-scoped subagents (have own `permission.skill`) | — | Their respective domains | none (self-scoped — global allowlist is irrelevant to them) |
| `cad-specialist-subagent.md` | — | CAD operations | none (already has 14 CAD allows — verify only) |
| `autoresearch-{code,ml,research}-subagent.md` | — | Autoresearch loops | none (already has domain+core allows — verify only) |
| `opentofu-explorer-subagent.md` | — | IaC operations | none (already has 7 opentofu allows — verify only) |
| `testing-subagent.md` | — | Test generation | none (already has test-generator+tdd allows — verify only) |
| `{discovery,requirements,technical-design}-specialist-subagent.md` | — | Document-creation workflows | none (already has interactive-document-rendering allow — verify only) |
| `uiux-reviewer-subagent.md` | — | UI/UX reviews | none (already has uiux-review allow — verify only) |
| `responsive-audit-subagent.md` | — | Responsive audits | none (already has playwright-responsive-audit allow — verify only) |
| `linting-subagent.md` | — | Linting | none (already has python-ruff-linter + javascript-eslint-linter allows — verify only) |
| `pptx-specialist-subagent.md` | — | PPTX creation | none (already has pptx-generate-* + ooxml-editing + office-thumbnail allows — verify only) |
| `nextjs-specialist-subagent.md` | — | Next.js work | none (already has nextjs-standard-setup + nextjs-image-usage + react-nextjs-antipatterns + amplify allows — verify only) |
| `documentation-subagent.md` | — | Documentation | none (already has docstring-generator + coverage-readme-workflow allows — verify only) |
| `coverage-subagent.md` | — | Coverage | none (already has coverage-readme-workflow allow — verify only) |
| `deploy/.AGENTS.md` | `opencode_app/opencode.json` changes | Future developers reading patterns | low (documentation only) |

## Implementation Phases

### Phase 1: Audit and Preparation

- [ ] **1.1** Read `opencode_app/opencode.json` L19–23 to confirm the existing `permission` block structure
    — **Why:** Verify the exact insertion point for the `skill` sub-key (must merge into existing block, not create a new one)
    — **Done when:** Confirmed the block contains `read_mcp_resource`, `list_mcp_resources`, `list_mcp_resource_templates` denies and the `skill` key does NOT yet exist
    — **Consumers affected:** None (read-only audit step)

- [ ] **1.2** Verify denied-skill consumer overrides exist (spot-check all 11 consumer subagents)
    — **Why:** With the allowlist approach, `"*": "deny"` hides skills from ALL agents. Each denied skill's consumer subagent MUST have an explicit `allow` in its frontmatter `permission.skill` block. This step confirms the 44 denied skills are covered.
    — **Done when:** Grep confirms the following allow entries exist:
  - `cad-specialist-subagent.md`: 14 CAD skill allows
  - `autoresearch-code-subagent.md`: `autoresearch-core-skill` + `autoresearch-code-skill` allows
  - `autoresearch-ml-subagent.md`: `autoresearch-core-skill` + `autoresearch-ml-skill` allows
  - `autoresearch-research-subagent.md`: `autoresearch-core-skill` + `autoresearch-research-skill` allows
  - `opentofu-explorer-subagent.md`: 7 opentofu skill allows
  - `testing-subagent.md`: `test-generator-framework-skill` allow
  - `discovery-specialist-subagent.md`: `interactive-document-rendering-skill` allow
  - `requirements-specialist-subagent.md`: `interactive-document-rendering-skill` allow
  - `technical-design-specialist-subagent.md`: `interactive-document-rendering-skill` allow
  - `uiux-reviewer-subagent.md`: `uiux-review-skill` allow
  - `responsive-audit-subagent.md`: `playwright-responsive-audit-skill` allow
  - `pptx-specialist-subagent.md`: `pptx-generate-slide-skill` + `pptx-generate-template-skill` + `pptx-template-modifier-skill` + `ooxml-editing-skill` + `office-thumbnail-skill` allows
  - `linting-subagent.md`: `python-ruff-linter-skill` + `javascript-eslint-linter-skill` allows
  - `nextjs-specialist-subagent.md`: `nextjs-standard-setup-skill` + `nextjs-image-usage-skill` + `react-nextjs-antipatterns-skill` + `amplify-nextjs-deployment-skill` allows
  - `documentation-subagent.md`: `docstring-generator-skill` + `coverage-readme-workflow-skill` allows
  - `coverage-subagent.md`: `coverage-readme-workflow-skill` allow
    — **Consumers affected:** None (read-only audit step)
    — **AC:** No consumer subagent regresses (all can still load required skills)

- [ ] **1.3** Verify the 3 unscooped subagents (explorer, google-mcp-specialist, image-analyzer) do NOT load skills via the Skill tool
    — **Why:** These 3 subagents lack `permission.skill` blocks and would inherit the global allowlist. Confirm they don't need any denied skills.
    — **Done when:** Reading each subagent's prompt confirms no Skill tool usage or skill references
    — **Consumers affected:** None (read-only audit step)

### Phase 2: Add Allowlist to opencode.json

- [ ] **2.1** Merge the `skill` sub-key into the EXISTING `permission` block at L19–23 of `opencode_app/opencode.json`
    — **Why:** Implements the allowlist strategy — `"*": "deny"` hides all skills by default, explicit allows restore primary-visible skills. The `"*": "deny"` catch-all goes FIRST (lowest priority), specific allows go AFTER (last match wins per [permissions docs](https://opencode.ai/docs/permissions/#granular-rules-object-syntax)).
    — **Done when:** The `permission` block contains all 3 existing MCP denies PLUS the new `skill` sub-key with `"*": "deny"` and 80 `"allow"` entries matching the classification table above
    — **Consumers affected:** Primary session (sees 80 skill descriptions instead of 124 — 44 fewer); 3 unscooped subagents inherit the same 80-skill view

- [ ] **2.2** Validate `opencode_app/opencode.json` syntax (JSONC)
    — **Why:** Prevent JSON parsing errors that would break opencode startup. The file uses `//` comments (JSONC), so `jq` CANNOT parse it.
    — **Done when:** `node -e "JSON.parse(require('fs').readFileSync('opencode_app/opencode.json','utf8').replace(/\/\/.*/g,''))"` exits with code 0 and no errors
    — **Consumers affected:** All of opencode (malformed opencode.json breaks entire system)

### Phase 3: Confirm Consumer Subagent Overrides (B1 — verify only, no additions)

> **All consumer subagent `allow` overrides ALREADY EXIST** (verified during plan authoring from actual frontmatter reads). This phase is **confirm-only** — no file edits to agent files.

- [ ] **3.1** Confirm `cad-specialist-subagent.md` has all 14 CAD skill allows
    — **Why:** With `"*": "deny"` globally, cad-specialist-subagent needs explicit allows to load CAD skills. Its frontmatter already has these — verify they remain.
    — **Done when:** Grep confirms 14 `allow` entries for CAD skills in the file
    — **Consumers affected:** cad-specialist-subagent (no change expected); CAD operations (no impact)

- [ ] **3.2** Confirm `autoresearch-{code,ml,research}-subagent.md` each have `autoresearch-core-skill` + their domain skill allows
    — **Why:** Each autoresearch subagent needs explicit allows for the core protocol + domain skill. Already present — verify.
    — **Done when:** Grep confirms allows in all 3 files
    — **Consumers affected:** Autoresearch subagents (no change expected); autoresearch loops (no impact)

- [ ] **3.3** Confirm `opentofu-explorer-subagent.md` has all 7 opentofu skill allows
    — **Why:** opentofu-explorer needs explicit allows for all 7 IaC skills. Already present — verify.
    — **Done when:** Grep confirms 7 `allow` entries for opentofu skills
    — **Consumers affected:** opentofu-explorer-subagent (no change expected); IaC operations (no impact)

- [ ] **3.4** Confirm `testing-subagent.md` has `test-generator-framework-skill` allow
    — **Why:** testing-subagent needs the test framework skill. Already present — verify.
    — **Done when:** Grep confirms the allow entry
    — **Consumers affected:** testing-subagent (no change expected); test generation (no impact)

- [ ] **3.5** Confirm `{discovery,requirements,technical-design}-specialist-subagent.md` each have `interactive-document-rendering-skill` allow
    — **Why:** These 3 specialist subagents load document-creation skills that internally use interactive-document-rendering. Already present — verify.
    — **Done when:** Grep confirms allows in all 3 files
    — **Consumers affected:** Specialist subagents (no change expected); document-creation workflows (no impact)

- [ ] **3.6** Confirm `uiux-reviewer-subagent.md` has `uiux-review-skill` allow
    — **Why:** uiux-reviewer needs the review skill. Already present — verify.
    — **Done when:** Grep confirms the allow entry
    — **Consumers affected:** uiux-reviewer-subagent (no change expected); UI/UX reviews (no impact)

- [ ] **3.7** Confirm `responsive-audit-subagent.md` has `playwright-responsive-audit-skill` allow
    — **Why:** responsive-audit needs the audit skill. Already present — verify.
    — **Done when:** Grep confirms the allow entry
    — **Consumers affected:** responsive-audit-subagent (no change expected); responsive audits (no impact)

- [ ] **3.8** Confirm specialist subagents for newly-denied skills have allows (linting, pptx, nextjs, documentation, coverage)
    — **Why:** Skills newly classified as subagent-only (language linters, PPTX engine, Next.js specialist, docstring/coverage) were not in the original denylist. Their consumer subagents already have allows — verify these are present and complete.
    — **Done when:** Grep confirms:
  - `linting-subagent.md`: `python-ruff-linter-skill` + `javascript-eslint-linter-skill` allows
  - `pptx-specialist-subagent.md`: `pptx-generate-slide-skill` + `pptx-generate-template-skill` + `pptx-template-modifier-skill` + `ooxml-editing-skill` + `office-thumbnail-skill` allows
  - `nextjs-specialist-subagent.md`: `nextjs-standard-setup-skill` + `nextjs-image-usage-skill` + `react-nextjs-antipatterns-skill` + `amplify-nextjs-deployment-skill` allows
  - `documentation-subagent.md`: `docstring-generator-skill` + `coverage-readme-workflow-skill` allows
  - `coverage-subagent.md`: `coverage-readme-workflow-skill` allow
    — **Consumers affected:** All listed subagents (no change expected); their respective domains (no impact)
    — **AC:** No consumer subagent regresses (all can still load required skills)

### Phase 4: Documentation and Verification

- [ ] **4.1** Add "Skill Permission Allowlist" subsection to `deploy/.AGENTS.md` documenting the hub-and-spoke enforcement
    — **Why:** Documents the allowlist pattern so future developers understand: (a) new skills default to hidden, (b) add to the allowlist if the primary should see them, (c) add `permission.skill` overrides if only a subagent needs them.
    — **Done when:** File contains a new subsection explaining the `"*": "deny"` + allowlist pattern, how to add new skills, and the override mechanism
    — **Consumers affected:** Future developers (documentation only; no functional impact)

- [ ] **4.2** Manual runtime test: verify denied skills absent from primary's `<available_skills>`
    — **Why:** `opencode debug config` shows config structure, NOT the `<available_skills>` listing — it cannot verify which skills the model actually sees. A manual runtime test is required.
    — **Done when:** Start a primary session and confirm that:
  - A denied skill (e.g., `cad-generation-skill`) does NOT appear in `<available_skills>`
  - An allowed skill (e.g., `grilling-skill`) DOES appear
  - Loading `cad-generation-skill` from primary fails (or is hidden)
    — **Consumers affected:** None (verification step)

- [ ] **4.3** Verify the allowlist entry count in opencode.json
    — **Why:** Quick verification that all 80 allow entries are present and no denied skills leaked into the allowlist.
    — **Done when:** Grep counts 80 `"allow"` entries within the `skill` block (excluding the `"*": "deny"` catch-all)
    — **Consumers affected:** None (verification step)

- [ ] **4.4** Verify denied skills do NOT appear in the allowlist (no contradictions)
    — **Why:** Ensure none of the 44 denied skills accidentally have an `"allow"` entry (which would override the denylist intent).
    — **Done when:** For each of the 44 denied skills, grep confirms it does NOT appear as `"allow"` in the skill block
    — **Consumers affected:** None (verification step)

- [ ] **4.5** Functional spot-check: spawn cad-specialist-subagent and confirm it can still load CAD skills
    — **Why:** End-to-end verification that the global `"*": "deny"` + per-subagent `allow` override mechanism works for the largest cluster (14 CAD skills).
    — **Done when:** cad-specialist-subagent successfully loads `cad-generation-skill` (or any CAD skill) without error
    — **Consumers affected:** None (verification step)

## Verification Commands

```bash
# 1. Verify allowlist size (should be 80 allow entries in the skill block)
#    Note: the file is JSONC — strip // comments before counting
node -e "
  const raw = require('fs').readFileSync('opencode_app/opencode.json','utf8');
  const stripped = raw.replace(/\/\/.*/g, '');
  const cfg = JSON.parse(stripped);
  const skillPerms = cfg.permission?.skill || {};
  const allows = Object.entries(skillPerms).filter(([k,v]) => v === 'allow');
  const denies = Object.entries(skillPerms).filter(([k,v]) => v === 'deny');
  console.log('Allow entries:', allows.length);
  console.log('Deny entries:', denies.length, denies.map(([k]) => k));
  if (allows.length !== 80) console.error('ERROR: expected 80 allows, got', allows.length);
"

# 2. Verify JSONC syntax is valid (jq CANNOT parse JSONC — use node)
node -e "JSON.parse(require('fs').readFileSync('opencode_app/opencode.json','utf8').replace(/\/\/.*/g,'')); console.log('JSONC valid')"

# 3. Verify consumer subagent allow overrides (direct skill-name greps — NOT permission.skill structure greps)
# CAD cluster (14 allows expected)
grep -c "allow" opencode_app/.opencode/agents/cad-specialist-subagent.md  # should include 14 CAD allows

# Autoresearch core + domain (each subagent)
grep "autoresearch-core-skill: allow\|autoresearch-code-skill: allow" opencode_app/.opencode/agents/autoresearch-code-subagent.md
grep "autoresearch-core-skill: allow\|autoresearch-ml-skill: allow" opencode_app/.opencode/agents/autoresearch-ml-subagent.md
grep "autoresearch-core-skill: allow\|autoresearch-research-skill: allow" opencode_app/.opencode/agents/autoresearch-research-subagent.md

# OpenTofu cluster (7 allows expected)
grep -c "opentofu.*allow" opencode_app/.opencode/agents/opentofu-explorer-subagent.md  # should be 7

# Other consumers
grep "test-generator-framework-skill: allow" opencode_app/.opencode/agents/testing-subagent.md
grep "interactive-document-rendering-skill: allow" opencode_app/.opencode/agents/discovery-specialist-subagent.md
grep "interactive-document-rendering-skill: allow" opencode_app/.opencode/agents/requirements-specialist-subagent.md
grep "interactive-document-rendering-skill: allow" opencode_app/.opencode/agents/technical-design-specialist-subagent.md
grep "uiux-review-skill: allow" opencode_app/.opencode/agents/uiux-reviewer-subagent.md
grep "playwright-responsive-audit-skill: allow" opencode_app/.opencode/agents/responsive-audit-subagent.md
grep "pptx-generate-slide-skill: allow" opencode_app/.opencode/agents/pptx-specialist-subagent.md
grep "python-ruff-linter-skill: allow" opencode_app/.opencode/agents/linting-subagent.md
grep "nextjs-standard-setup-skill: allow" opencode_app/.opencode/agents/nextjs-specialist-subagent.md
grep "docstring-generator-skill: allow" opencode_app/.opencode/agents/documentation-subagent.md

# 4. Verify denied skills are NOT in the allowlist (no contradictions)
for skill in cad-generation-skill autoresearch-core-skill opentofu-aws-explorer-skill test-generator-framework-skill interactive-document-rendering-skill uiux-review-skill; do
  if node -e "
    const raw = require('fs').readFileSync('opencode_app/opencode.json','utf8');
    const cfg = JSON.parse(raw.replace(/\/\/.*/g, ''));
    if (cfg.permission?.skill?.['$skill'] === 'allow') { console.error('ERROR: $skill is allowed!'); process.exit(1); }
  "; then echo "OK: $skill is denied"; else echo "FAIL: $skill is allowed"; fi
done

# 5. Manual runtime test (NOT automatable via opencode debug config):
#    - Start a primary session
#    - Confirm a denied skill (e.g. cad-generation-skill) is absent from <available_skills>
#    - Confirm an allowed skill (e.g. grilling-skill) is present
#    - Spawn cad-specialist-subagent and confirm it can load cad-generation-skill
```

## Dependencies

None (self-contained optimization work)

## Risks & Mitigation

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| JSONC syntax error in opencode.json breaks opencode startup | Low | Critical (system unusable) | Validate with `node -e` JSON.parse after stripping comments (Phase 2.2); `jq` cannot parse JSONC |
| New skill added to repo defaults to hidden (not in allowlist) | Medium | Low (skill works from subagents but not visible to primary until added) | Document in `deploy/.AGENTS.md` (Phase 4.1): "new skills must be added to the `permission.skill` allowlist in `opencode.json` if the primary should see them" |
| Consumer subagent missing an allow override for a denied skill | Low | Medium (specific functionality broken) | Phase 1.2 verifies all 44 denied skills have consumer overrides; Phase 3 re-confirms; Phase 4.5 spot-checks cad-specialist |
| 3 unscooped subagents (explorer, google-mcp, image-analyzer) need a denied skill | Very Low | Low (minor subagent functionality) | Phase 1.3 confirms none load skills via the Skill tool; these are read-only/vision/exploration agents |
| Over-denial hides a skill the primary needs | Low | Medium (primary can't load the skill directly; must delegate) | "Lean primary when uncertain" heuristic applied during classification; 80-skill allowlist is conservative; any missed skill can be added in a follow-up |
| Allowlist becomes stale as new skills are added | Medium | Low (new skills invisible to primary until added) | Document the maintenance pattern; consider a CI check that flags skills not in the allowlist |

## Success Metrics

- **Allowlist size:** 80 skills explicitly allowed in `opencode_app/opencode.json` `permission.skill` block
- **Denied count:** 44 skills hidden from primary via `"*": "deny"` (vs 17 under original denylist)
- **Token savings:** 44 skill descriptions removed from primary's `<available_skills>` on every session (vs 17 under denylist — ~2.6x improvement)
- **No consumer subagent regresses:** All 11+ consumer subagents can still load their required skills (verified in Phase 3)
- **Syntax validation:** `node -e` JSON.parse passes on modified `opencode_app/opencode.json` (JSONC)
- **Documentation:** `deploy/.AGENTS.md` contains Skill Permission Allowlist subsection explaining the pattern and maintenance

## Notes

- This optimization is opt-in with no breaking changes; it enforces existing hub-and-spoke patterns already in use
- The `permission.skill` allowlist mechanism is opencode-native and supported by the docs; this is not a hack or workaround
- **36 of 39 subagents have their own `permission.skill` blocks** — they are self-scoped and completely unaffected by the global allowlist. Only the primary session + 3 unscooped subagents (explorer, google-mcp-specialist, image-analyzer) inherit the global allowlist
- **`pdf-specialist-skill` has NO consumer subagent override** — it MUST stay in the allowlist because denying it would make it inaccessible to all scoped subagents. Same applies to: `construction-bd-skill`, `startup-business-docs-skill`, `python-packaging-skill`, `csharp-linter-skill`, `java-linter-skill`, `typescript-dry-principle-skill`, `monorepo-management-skill`, `threejs-nextjs-skill`
- **`autoresearch-code/ml/research-skill` consumer overrides were not in the task's confirmed list** (only `autoresearch-core-skill` was confirmed) but verified from actual frontmatter reads — all 3 autoresearch subagents have explicit allows for their domain skill + core
- The 44-skill deny set exceeds the original 17-skill denylist by including: 7 OpenTofu, 3 PPTX engine, 2 OOXML/thumbnail, 2 language linters, 2 test creators, 4 Next.js specialist, 2 docs/coverage, and 3 autoresearch domain skills
- **Future optimization:** the allowlist can be trimmed further by adding `permission.skill` overrides to the 3 unscooped subagents (if they ever need skills) and then removing those skills from the global allowlist. Each removal saves ~200–400 tokens per primary session
- Token savings should be measurable by comparing `<available_skills>` listing size before and after changes

---
*Tracking progress with ticket-plan-workflow-skill*
---
