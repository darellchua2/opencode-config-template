# Skill Restructuring Plan: Framework + Language-Specific Pattern

**Issue**: #66
**Goal**: Standardize all skills to follow the Framework → Language-Specific pattern

---

## Current State Analysis

### Existing Framework Skills (5 Total)

| Framework Skill | Language-Specific Extensions | Status |
|-----------------|------------------------------|--------|
| `linting-workflow` | `python-ruff-linter`, `javascript-eslint-linter` | ✅ Complete |
| `test-generator-framework` | `python-pytest-creator`, `nextjs-unit-test-creator` | ✅ Complete |
| `docstring-generator` | `python-docstring-generator`, `nextjs-tsdoc-documentor` | ✅ Complete |
| `pr-creation-workflow` | `git-pr-creator`, `nextjs-pr-workflow` | ✅ Complete |
| `tdd-workflow` | None | ❌ Needs extensions |

### Skills Needing Framework Refactoring (33 Total)

| Skill | Current Type | Should Be |
|-------|-------------|-----------|
| `coverage-readme-workflow` | Standalone | Framework skill |
| `ascii-diagram-creator` | Standalone | Standalone (OK) |
| `typescript-dry-principle` | Standalone | Language-specific of `linting-workflow` |
| `nextjs-image-usage` | Standalone | Language-specific skill |
| `nextjs-standard-setup` | Standalone | Language-specific of framework |
| `nextjs-complete-setup` | Standalone | Combines standard-setup + docs |
| `git-*` skills (9) | Mixed | Platform-specific framework |
| `jira-*` skills (4) | Mixed | Platform-specific framework |
| `opentofu-*` skills (7) | Mixed | Platform-specific framework |
| `opencode-*` skills (4) | Mixed | Tooling framework |

---

## Proposed Structure

### 1. Code Quality Framework

```
linting-workflow/                    # Framework
├── SKILL.md                         # Generic linting workflow
└── Framework for:
    ├── python-ruff-linter/          # Python-specific
    ├── javascript-eslint-linter/    # JS/TS-specific
    ├── typescript-dry-principle/    # TS refactoring (NEW: should extend linting)
    ├── go-golangci-linter/          # Go-specific (NEW)
    └── ruby-rubocop-linter/         # Ruby-specific (NEW)
```

### 2. Testing Framework

```
test-generator-framework/            # Framework
├── SKILL.md                         # Generic test generation
└── Framework for:
    ├── python-pytest-creator/       # Python-specific
    ├── nextjs-unit-test-creator/    # Next.js-specific
    ├── tdd-workflow/                # TDD methodology (framework)
    │   └── Framework for:
    │       ├── python-tdd-creator/  # NEW
    │       └── nextjs-tdd-creator/  # NEW
    ├── go-test-creator/             # Go-specific (NEW)
    └── ruby-rspec-creator/          # Ruby-specific (NEW)
```

### 3. Documentation Framework

```
docstring-generator/                 # Framework
├── SKILL.md                         # Generic docstring generation
└── Framework for:
    ├── python-docstring-generator/  # Python PEP 257
    ├── nextjs-tsdoc-documentor/     # TypeScript TSDoc
    ├── java-javadoc-generator/      # Java Javadoc (NEW)
    └── csharp-xml-documentor/       # C# XML docs (NEW)
```

### 4. Project Setup Framework (NEW)

```
project-setup-framework/             # NEW Framework
├── SKILL.md                         # Generic project setup
└── Framework for:
    ├── nextjs-standard-setup/       # Next.js basic
    ├── nextjs-complete-setup/       # Next.js full
    ├── python-fastapi-setup/        # FastAPI (NEW)
    ├── go-project-setup/            # Go (NEW)
    └── rails-setup/                 # Rails (NEW)
```

### 5. Git/GitHub Framework

```
git-workflow-framework/              # NEW Framework
├── SKILL.md                         # Generic Git workflow
└── Framework for:
    ├── git-issue-creator/           # Issue creation
    ├── git-issue-updater/           # Issue updates
    ├── git-issue-labeler/           # Label assignment
    ├── git-issue-plan-workflow/     # Full issue workflow
    ├── git-pr-creator/              # PR creation
    └── git-semantic-commits/        # Commit formatting
```

### 6. JIRA Framework

```
jira-workflow-framework/             # NEW Framework
├── SKILL.md                         # Generic JIRA workflow
└── Framework for:
    ├── jira-git-integration/        # JIRA + Git
    ├── jira-ticket-plan-workflow/   # Full JIRA workflow
    └── jira-status-updater/         # Status transitions
```

### 7. OpenTofu Framework

```
opentofu-framework/                  # NEW Framework
├── SKILL.md                         # Generic OpenTofu workflow
└── Framework for:
    ├── opentofu-provider-setup/     # Provider config
    ├── opentofu-provisioning-workflow/ # Provisioning
    ├── opentofu-kubernetes-explorer/   # K8s
    ├── opentofu-neon-explorer/         # Neon DB
    ├── opentofu-aws-explorer/          # AWS
    ├── opentofu-keycloak-explorer/     # Keycloak
    └── opentofu-ecr-provision/         # ECR
```

### 8. OpenCode Tooling Framework

```
opencode-tooling-framework/          # NEW Framework
├── SKILL.md                         # Generic tooling workflow
└── Framework for:
    ├── opencode-skill-creation/     # Create skills
    ├── opencode-skill-auditor/      # Audit skills
    ├── opencode-skills-maintainer/  # Maintain skills
    └── opencode-agent-creation/     # Create agents
```

### 9. PR Workflow Framework

```
pr-creation-workflow/                # Framework
├── SKILL.md                         # Generic PR creation
└── Framework for:
    ├── git-pr-creator/              # Git-only PR
    ├── nextjs-pr-workflow/          # Next.js-specific PR
    ├── python-pr-workflow/          # Python-specific PR (NEW)
    └── go-pr-workflow/              # Go-specific PR (NEW)
```

### 10. Coverage Framework (NEW)

```
coverage-framework/                  # NEW Framework
├── SKILL.md                         # Generic coverage reporting
└── Framework for:
    ├── coverage-readme-workflow/    # README badges
    ├── python-coverage-workflow/    # Python coverage (NEW)
    └── nextjs-coverage-workflow/    # Next.js coverage (NEW)
```

---

## Naming Convention

### Framework Skills
- Pattern: `{domain}-{type}-framework` or `{domain}-workflow`
- Examples: `linting-workflow`, `test-generator-framework`, `opentofu-framework`

### Language-Specific Skills
- Pattern: `{language/framework}-{feature}-{type}`
- Examples: `python-ruff-linter`, `nextjs-unit-test-creator`, `python-docstring-generator`

### Platform-Specific Skills
- Pattern: `{platform}-{feature}-{type}`
- Examples: `git-issue-creator`, `jira-ticket-plan-workflow`

---

## Implementation Priority

### Phase A: Create Missing Framework Skills (High Priority)
1. `opentofu-framework` - Combine all OpenTofu skills
2. `git-workflow-framework` - Combine all Git skills
3. `jira-workflow-framework` - Combine all JIRA skills
4. `opencode-tooling-framework` - Combine all tooling skills
5. `project-setup-framework` - New framework for setup skills
6. `coverage-framework` - New framework for coverage skills

### Phase B: Create Missing Language-Specific Extensions (Medium Priority)
1. `typescript-dry-principle` → extend `linting-workflow`
2. `python-tdd-creator` → extend `tdd-workflow`
3. `nextjs-tdd-creator` → extend `tdd-workflow`
4. `python-pr-workflow` → extend `pr-creation-workflow`
5. `python-coverage-workflow` → extend `coverage-framework`

### Phase C: Update Subagent Permissions (High Priority)
1. Update `linting-subagent` to include `typescript-dry-principle`
2. Update `testing-subagent` to include new TDD extensions
3. Create new subagents if needed

---

## Files to Create/Modify

### New Framework Skills (6 files)
- `skills/opentofu-framework/SKILL.md`
- `skills/git-workflow-framework/SKILL.md`
- `skills/jira-workflow-framework/SKILL.md`
- `skills/opencode-tooling-framework/SKILL.md`
- `skills/project-setup-framework/SKILL.md`
- `skills/coverage-framework/SKILL.md`

### New Language-Specific Skills (5+ files)
- `skills/python-tdd-creator/SKILL.md`
- `skills/nextjs-tdd-creator/SKILL.md`
- `skills/python-pr-workflow/SKILL.md`
- `skills/python-coverage-workflow/SKILL.md`
- `skills/nextjs-coverage-workflow/SKILL.md`

### Updated Files
- `config.json` - Update subagent permissions
- `.AGENTS.md` - Update routing rules
- Existing skills - Add "extends" metadata

---

## Metadata Standard

Add to all skill frontmatter:

```yaml
---
name: skill-name
description: Description
extends: parent-framework-skill  # NEW: Link to framework
language: python                 # NEW: Language/platform
framework: pytest                # NEW: Specific framework
license: Apache-2.0
compatibility: opencode
metadata:
  audience: developers
  workflow: category
  extends: parent-framework      # Reference to framework
---
```

---

## Next Steps

1. **Decide approach**: Create all frameworks first, or incrementally?
2. **Priority order**: Which frameworks are most urgent?
3. **Backward compatibility**: Keep old skills or migrate?
4. **Subagent updates**: Update config.json in parallel?
