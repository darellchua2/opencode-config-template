# Skill Modularization Audit

**Date:** 2026-01-29
**Total Skills:** 33
**Phase:** Phase 4 - Skill Modularization

---

## Executive Summary

This audit analyzes the current 33 skills to identify modularization opportunities, dependencies, and coupling patterns. The goal is to create a more maintainable, extensible skill architecture with clear separation of concerns.

---

## Skill Categorization

### Current Organization (8 Categories)

| Category | Skills | Count |
|-----------|--------|-------|
| Framework | test-generator-framework, jira-git-integration, pr-creation-workflow, ticket-branch-workflow, linting-workflow | 5 |
| Language-Specific | python-pytest-creator, python-ruff-linter, javascript-eslint-linter | 3 |
| Framework-Specific | nextjs-pr-workflow, nextjs-unit-test-creator, nextjs-standard-setup, typescript-dry-principle | 4 |
| OpenCode Meta | opencode-agent-creation, opencode-skill-creation, opencode-skill-auditor | 3 |
| OpenTofu | opentofu-aws-explorer, opentofu-keycloak-explorer, opentofu-kubernetes-explorer, opentofu-neon-explorer, opentofu-provider-setup, opentofu-provisioning-workflow, opentofu-ecr-provision | 7 |
| Git/Workflow | ascii-diagram-creator, git-issue-creator, git-issue-labeler, git-issue-updater, git-pr-creator, git-semantic-commits | 6 |
| Documentation | coverage-readme-workflow, docstring-generator | 2 |
| JIRA | jira-git-workflow | 1 |

**Total:** 33 skills

---

## Skill Dependency Analysis

### Framework Skills (Base Layer)

Framework skills provide generic logic that specialized skills extend:

1. **test-generator-framework**
   - **Purpose:** Generic test generation workflow
   - **Extended by:**
     - `python-pytest-creator` (Python testing)
     - `nextjs-unit-test-creator` (Next.js testing)
   - **Provides:** Test discovery, framework detection, user confirmation, executability verification
   - **Coupling:** Low - well-defined extension points

2. **linting-workflow**
   - **Purpose:** Generic linting workflow with auto-fix
   - **Extended by:**
     - `python-ruff-linter` (Python/Ruff)
     - `javascript-eslint-linter` (JavaScript/ESLint)
   - **Provides:** Language detection, linter detection, auto-fix, error resolution
   - **Coupling:** Low - clear separation of concerns

3. **pr-creation-workflow**
   - **Purpose:** Generic PR creation workflow
   - **Extended by:**
     - `nextjs-pr-workflow` (Next.js PRs)
   - **Provides:** PR creation, review process, quality checks
   - **Coupling:** Medium - Next.js workflow heavily depends on this

4. **jira-git-integration**
   - **Purpose:** JIRA API operations
   - **Extended by:**
     - `jira-git-workflow` (complete JIRA→Git workflow)
     - Used by: `git-issue-updater` (issue updates)
   - **Provides:** JIRA API calls, project discovery, ticket management
   - **Coupling:** Medium - used by multiple skills

5. **ticket-branch-workflow**
   - **Purpose:** Generic ticket-to-branch workflow
   - **Extended by:**
     - `jira-git-workflow` (JIRA-specific workflow)
   - **Provides:** Branch creation, PLAN.md, semantic commits, push
   - **Coupling:** Low - clear workflow pattern

### Specialized Skills (Extension Layer)

Skills that extend framework skills with language or framework-specific logic:

1. **python-pytest-creator**
   - **Extends:** `test-generator-framework`
   - **Python-specific:** Poetry detection, pytest features, async testing
   - **Dependencies:** `test-generator-framework`
   - **Coupling:** Low - only extends, doesn't modify framework

2. **nextjs-unit-test-creator**
   - **Extends:** `test-generator-framework`
   - **Next.js-specific:** React testing, App Router, Server/Client Components
   - **Dependencies:** `test-generator-framework`
   - **Coupling:** Low - only extends framework

3. **python-ruff-linter**
   - **Extends:** `linting-workflow`
   - **Python-specific:** Ruff error codes, PEP 8 compliance
   - **Dependencies:** `linting-workflow`
   - **Coupling:** Low - only extends framework

4. **javascript-eslint-linter**
   - **Extends:** `linting-workflow**
   - **JS/TS-specific:** ESLint rules, TypeScript support
   - **Dependencies:** `linting-workflow`
   - **Coupling:** Low - only extends framework

5. **nextjs-pr-workflow**
   - **Extends:** `pr-creation-workflow`
   - **Next.js-specific:** Vercel deployment, Next.js checks
   - **Dependencies:** `pr-creation-workflow`, `test-generator-framework` (via linting-workflow)
   - **Coupling:** High - deeply integrated with framework

### Composite Skills (Workflow Layer)

Skills that combine multiple frameworks and skills:

1. **jira-git-workflow**
   - **Combines:**
     - `jira-git-integration` (JIRA operations)
     - `ticket-branch-workflow` (branch creation, PLAN.md)
     - `git-issue-updater` (issue updates)
   - **Purpose:** Complete JIRA ticket → Git branch workflow
   - **Coupling:** High - tightly coupled to multiple frameworks

### Standalone Skills

Skills that operate independently without extending frameworks:

1. **OpenTofu Skills** (7 skills)
   - All OpenTofu skills are standalone
   - Each handles specific OpenTofu functionality
   - No framework dependencies
   - **Coupling:** None - independent operations

2. **Git/Workflow Skills** (6 skills)
   - `ascii-diagram-creator` - Standalone
   - `git-issue-creator` - Standalone (can work with JIRA or GitHub)
   - `git-issue-labeler` - Standalone
   - `git-issue-updater` - Uses `jira-git-integration` for JIRA updates
   - `git-pr-creator` - Standalone
   - `git-semantic-commits` - Standalone
   - **Coupling:** Low - mostly independent

3. **Documentation Skills** (2 skills)
   - `coverage-readme-workflow` - Standalone
   - `docstring-generator` - Standalone
   - **Coupling:** None - independent operations

4. **OpenCode Meta Skills** (3 skills)
   - `opencode-agent-creation` - Standalone
   - `opencode-skill-creation` - Standalone
   - `opencode-skill-auditor` - Standalone
   - **Coupling:** None - independent operations

5. **Framework-Specific Skills** (4 skills)
   - `nextjs-standard-setup` - Standalone (Next.js app scaffolding)
   - `typescript-dry-principle` - Standalone (refactoring patterns)
   - **Coupling:** None - independent operations

---

## Modularization Opportunities

### High-Priority Opportunities

#### 1. Extract Common Git Operations
**Current State:**
- Git operations scattered across multiple skills
- `git-issue-creator`, `git-pr-creator`, `git-semantic-commits`, `ticket-branch-workflow` all duplicate Git logic

**Recommendation:**
- Create `git-workflow-framework` skill
- Provide common Git operations (branch, commit, push, PR)
- Allow skills to extend for Git operations

**Benefits:**
- Reduces code duplication
- Consistent Git behavior across all skills
- Easier to maintain Git workflows

#### 2. Extract Common Documentation Patterns
**Current State:**
- `docstring-generator` and `coverage-readme-workflow` both handle documentation
- Similar patterns for reading/writing documentation

**Recommendation:**
- Create `documentation-framework` skill
- Provide common documentation operations
- Allow skills to extend for documentation tasks

**Benefits:**
- Unified documentation approach
- Easier to create new documentation skills
- Consistent documentation format

#### 3. Extract Common Issue Operations
**Current State:**
- `git-issue-creator`, `git-issue-labeler`, `git-issue-updater` all handle issues
- Similar patterns for issue management

**Recommendation:**
- Create `issue-framework` skill
- Provide common issue operations (create, label, update)
- Allow skills to extend for GitHub/JIRA issues

**Benefits:**
- Unified issue management
- Easier to add issue tracking platforms
- Consistent issue handling

#### 4. Extract Common Infrastructure Patterns
**Current State:**
- 7 OpenTofu skills, each handling specific infrastructure
- Similar patterns for resource management

**Recommendation:**
- Create `opentofu-framework` skill
- Provide common OpenTofu operations (resources, state, modules)
- Allow skills to extend for specific resources

**Benefits:**
- Unified OpenTofu approach
- Easier to add new OpenTofu resources
- Consistent infrastructure as code patterns

### Medium-Priority Opportunities

#### 5. Consolidate Testing Frameworks
**Current State:**
- `test-generator-framework` is the only testing framework
- Good structure, but could be enhanced

**Recommendation:**
- Enhance `test-generator-framework` with more extensibility
- Add plugin system for test types
- Allow custom test scenario generators

**Benefits:**
- Easier to add new test types
- More flexible testing workflows
- Better test scenario management

#### 6. Consolidate Linting Frameworks
**Current State:**
- `linting-workflow` is good, but could be enhanced
- Limited to specific linters

**Recommendation:**
- Enhance `linting-workflow` with plugin system
- Allow custom linter adapters
- Support more linters out of the box

**Benefits:**
- Easier to add new linters
- More flexible linting workflows
- Better linter integration

#### 7. Create Workflow Composition Framework
**Current State:**
- `jira-git-workflow` is a composite skill
- No general framework for workflow composition

**Recommendation:**
- Create `workflow-composition-framework`
- Allow skills to be composed into workflows
- Provide workflow orchestration logic

**Benefits:**
- Easier to create composite workflows
- Reusable workflow patterns
- Better workflow management

### Low-Priority Opportunities

#### 8. Extract Common Code Patterns
**Current State:**
- Code patterns repeated across skills
- File operations, error handling, logging

**Recommendation:**
- Create `utility-framework` for common patterns
- Provide reusable code utilities
- Standardize error handling and logging

**Benefits:**
- Reduced code duplication
- Consistent error handling
- Better code quality

---

## Proposed Modularization Structure

### New Framework Skills (Priority 1)

1. **git-workflow-framework**
   - Common Git operations (branch, commit, push, PR)
   - Semantic commit formatting
   - Git workflow patterns

2. **documentation-framework**
   - Common documentation operations
   - Documentation format standards
   - Documentation generation patterns

3. **issue-framework**
   - Common issue operations (create, label, update)
   - Issue tracking platform abstraction
   - Issue workflow patterns

4. **opentofu-framework**
   - Common OpenTofu operations
   - Resource management patterns
   - Infrastructure as code patterns

### Enhanced Framework Skills (Priority 2)

1. **test-generator-framework** (enhanced)
   - Plugin system for test types
   - Custom scenario generators
   - More flexible test workflows

2. **linting-workflow** (enhanced)
   - Plugin system for linters
   - Custom linter adapters
   - Support for more linters

### Workflow Composition Framework (Priority 3)

1. **workflow-composition-framework**
   - Skill composition logic
   - Workflow orchestration
   - Reusable workflow patterns

### Utility Framework (Priority 4)

1. **utility-framework**
   - Common code patterns
   - Error handling standards
   - Logging and debugging utilities

---

## Migration Strategy

### Phase 1: Create New Framework Skills (Week 1-2)

1. Create `git-workflow-framework`
2. Create `documentation-framework`
3. Create `issue-framework`
4. Create `opentofu-framework`
5. Test all new frameworks with existing skills

### Phase 2: Refactor Existing Skills (Week 3-4)

1. Refactor Git skills to extend `git-workflow-framework`
2. Refactor Documentation skills to extend `documentation-framework`
3. Refactor Issue skills to extend `issue-framework`
4. Refactor OpenTofu skills to extend `opentofu-framework`
5. Ensure backward compatibility

### Phase 3: Enhance Existing Frameworks (Week 5)

1. Enhance `test-generator-framework` with plugin system
2. Enhance `linting-workflow` with plugin system
3. Update extended skills to use new features
4. Test enhanced frameworks

### Phase 4: Create Workflow Composition (Week 6)

1. Create `workflow-composition-framework`
2. Refactor `jira-git-workflow` to use composition framework
3. Create examples of workflow composition
4. Test workflow composition

### Phase 5: Documentation and Testing (Week 7)

1. Document all new frameworks
2. Update skill documentation with framework references
3. Create migration guide for users
4. Test all skills with new frameworks
5. Verify backward compatibility

---

## USER Level Skill Control

### Proposed Configuration Structure

**File:** `~/.config/opencode/user/config.user.json`

```json
{
  "skills": {
    "enabled": ["*"],
    "disabled": [],
    "priorities": {
      "git-workflow-framework": 10,
      "test-generator-framework": 9,
      "linting-workflow": 8
    },
    "customSkillsPath": "/path/to/custom/skills",
    "autoLoad": true
  }
}
```

### USER Level Skill Control Features

1. **Enable/Disable Skills**
   - `enabled`: List of skill patterns to enable
   - `disabled`: List of skill patterns to disable
   - Wildcard support: `"*"` for all skills

2. **Skill Priority**
   - `priorities`: Skill priority for conflict resolution
   - Higher priority skills override lower priority skills
   - Useful when multiple skills can handle a task

3. **Custom Skills Path**
   - `customSkillsPath`: Path to user-defined skills
   - Skills loaded from user path take precedence
   - Allows custom skill development

4. **Auto-Load**
   - `autoLoad`: Automatically load skills on startup
   - Disable for manual skill loading
   - Useful for performance optimization

---

## Risk Assessment

### High Risk

1. **Breaking Changes**
   - Risk: Refactoring skills may break existing workflows
   - Mitigation: Maintain backward compatibility
   - Timeline: Test thoroughly before releasing

2. **Framework Complexity**
   - Risk: Too many frameworks may increase complexity
   - Mitigation: Limit to essential frameworks
   - Timeline: Evaluate framework necessity

### Medium Risk

1. **Skill Dependencies**
   - Risk: Skills may have hidden dependencies
   - Risk: Dependency graph may become complex
   - Mitigation: Document all dependencies clearly
   - Timeline: Create dependency graph

2. **Testing Coverage**
   - Risk: Hard to test all skill combinations
   - Risk: May miss edge cases in refactoring
   - Mitigation: Comprehensive testing strategy
   - Timeline: Test all skill combinations

### Low Risk

1. **Documentation Updates**
   - Risk: Documentation may lag behind code
   - Mitigation: Update documentation with code
   - Timeline: Include documentation in PR reviews

2. **User Adoption**
   - Risk: Users may resist new structure
   - Mitigation: Provide clear migration guide
   - Timeline: User testing and feedback

---

## Recommendations

### Immediate Actions (Phase 4.1)

1. **Create Skill Dependency Graph**
   - Document all skill dependencies
   - Visualize skill relationships
   - Identify circular dependencies

2. **Design Framework Interfaces**
   - Define clear framework APIs
   - Document extension points
   - Create framework templates

3. **Create Migration Plan**
   - Document migration steps for each skill
   - Create backward compatibility layer
   - Rollback plan if needed

### Short-Term Actions (Phase 4.2)

1. **Create Priority 1 Frameworks**
   - Implement `git-workflow-framework`
   - Implement `documentation-framework`
   - Implement `issue-framework`
   - Implement `opentofu-framework`

2. **Refactor High-Value Skills**
   - Refactor Git skills first (most used)
   - Refactor Documentation skills
   - Refactor Issue skills

3. **Test and Validate**
   - Test each refactored skill
   - Verify backward compatibility
   - Get user feedback

### Long-Term Actions (Phase 4.3-4.5)

1. **Enhance Existing Frameworks**
   - Add plugin systems
   - Improve extensibility
   - Create framework documentation

2. **Create Workflow Composition**
   - Implement composition framework
   - Refactor composite skills
   - Create workflow examples

3. **Documentation and Migration**
   - Document all changes
   - Create migration guide
   - Train users on new structure

---

## Conclusion

The current skill structure is well-organized but has opportunities for modularization. The primary opportunities are:

1. **Extract common operations** into frameworks (Git, Documentation, Issues, OpenTofu)
2. **Enhance existing frameworks** with plugin systems (Test, Linting)
3. **Create workflow composition** for complex workflows

The modularization should be done incrementally to minimize risk and ensure backward compatibility. Priority should be given to frameworks that provide the most value and are used by the most skills.

**Next Steps:**
1. Create detailed design for proposed frameworks
2. Implement Priority 1 frameworks
3. Refactor high-value skills to use new frameworks
4. Test thoroughly and validate
5. Document and provide migration guide

---

**Audit Date:** 2026-01-29
**Auditor:** Build with Skills Agent
**Status:** Ready for Phase 4 Implementation
