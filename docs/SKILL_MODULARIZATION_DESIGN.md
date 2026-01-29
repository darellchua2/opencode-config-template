# Skill Modularization Design Document

**Version:** 1.0
**Date:** 2026-01-29
**Phase:** Phase 4 - Skill Modularization

---

## Overview

This document designs the architecture for skill modularization, including framework interfaces, implementation patterns, and migration strategy. The goal is to create a maintainable, extensible skill architecture with clear separation of concerns.

---

## Design Principles

### 1. Separation of Concerns
- **Framework Skills:** Provide generic, reusable functionality
- **Specialized Skills:** Extend frameworks with domain-specific logic
- **Composite Skills:** Combine multiple skills into workflows
- **Standalone Skills:** Self-contained operations

### 2. Explicit Dependencies
- Skills explicitly declare framework dependencies
- Frameworks provide clear extension points
- Dependency graph is documented and visible

### 3. Backward Compatibility
- Existing skills continue to work during migration
- Gradual migration path for all skills
- Old skill patterns remain supported

### 4. Testability
- Each framework has clear testing strategy
- Extension points are well-defined and testable
- Mock frameworks for testing specialized skills

### 5. Documentation
- Each framework has comprehensive documentation
- Extension points are clearly documented
- Examples provided for each pattern

---

## Framework Architecture

### Framework Layer (Base)

```
┌─────────────────────────────────────────────────────────────┐
│                    Framework Layer                        │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────┐│
│  │  test-gen    │  │   linting    │  │   git    ││
│  │  framework   │  │   workflow    │  │  workflow││
│  └──────────────┘  └──────────────┘  └──────────┘│
│  ┌──────────────┐  ┌──────────────┐  ┌──────────┐│
│  │   pr-creation│  │   jira-git   │  │ opentofu ││
│  │  workflow    │  │ integration   │  │ framework││
│  └──────────────┘  └──────────────┘  └──────────┘│
└─────────────────────────────────────────────────────────────┘
```

### Specialized Skills Layer (Extension)

```
┌─────────────────────────────────────────────────────────────┐
│              Specialized Skills Layer                    │
│  ┌──────────────┐  ┌──────────────┐              │
│  │ python-pytest│  │ nextjs-unit  │  extends     │
│  │    creator    │  │   test-creat  │  test-gen    │
│  └──────────────┘  └──────────────┘  framework    │
│  ┌──────────────┐  ┌──────────────┐              │
│  │ python-ruff  │  │ javascript    │  extends     │
│  │   linter     │  │  eslint-lint  │  linting     │
│  └──────────────┘  └──────────────┘  workflow    │
└─────────────────────────────────────────────────────────────┘
```

### Composite Skills Layer (Workflow)

```
┌─────────────────────────────────────────────────────────────┐
│              Composite Skills Layer                     │
│  ┌───────────────────────────────────────┐            │
│  │      jira-git-workflow              │            │
│  │  ┌──────────────┐  ┌────────────┐ │  combines   │
│  │  │jira-git     │  │  ticket-   │ │  multiple   │
│  │  │ integration  │  │  branch-wf  │ │  skills     │
│  │  └──────────────┘  └────────────┘ │            │
│  └───────────────────────────────────────┘            │
└─────────────────────────────────────────────────────────────┘
```

---

## Framework Interface Design

### 1. git-workflow-framework

#### Purpose
Provide common Git operations for all Git-related skills.

#### Interface

```yaml
# Framework Extension Point
extends: git-workflow-framework

# Git Operations Provided
operations:
  branch:
    - name: create_branch
      description: Create a new Git branch
      parameters:
        - name: branch_name
          type: string
          required: true
        - name: base_branch
          type: string
          required: false
          default: "main"
    - name: checkout_branch
      description: Checkout to a specific branch
      parameters:
        - name: branch_name
          type: string
          required: true

  commit:
    - name: create_commit
      description: Create a new commit
      parameters:
        - name: message
          type: string
          required: true
        - name: files
          type: array
          required: false
          default: ["."]
        - name: amend
          type: boolean
          required: false
          default: false
    - name: format_commit_message
      description: Format commit message with semantic format
      parameters:
        - name: type
          type: string
          required: true
          enum: [feat, fix, docs, style, refactor, test, chore]
        - name: scope
          type: string
          required: false
        - name: description
          type: string
          required: true
        - name: body
          type: string
          required: false

  push:
    - name: push_branch
      description: Push branch to remote
      parameters:
        - name: branch_name
          type: string
          required: true
        - name: upstream
          type: boolean
          required: false
          default: true

  pull_request:
    - name: create_pr
      description: Create a pull request
      parameters:
        - name: title
          type: string
          required: true
        - name: body
          type: string
          required: true
        - name: head
          type: string
          required: true
        - name: base
          type: string
          required: false
          default: "main"
```

#### Usage Example

```python
# Specialized skill using git-workflow-framework

from git_workflow_framework import create_branch, create_commit, push_branch

def create_feature_branch(feature_name):
    """Create a feature branch with semantic commit"""
    branch = f"feature/{feature_name}"
    create_branch(branch)
    create_commit(
        type="feat",
        scope=feature_name,
        description=f"Add {feature_name} feature"
    )
    push_branch(branch, upstream=True)
```

#### Skills to Refactor
- `git-issue-creator` - Use for branch creation, commits
- `git-pr-creator` - Use for PR creation
- `git-semantic-commits` - Can be merged into this framework
- `ticket-branch-workflow` - Use for Git operations

---

### 2. documentation-framework

#### Purpose
Provide common documentation operations for all documentation-related skills.

#### Interface

```yaml
# Framework Extension Point
extends: documentation-framework

# Documentation Operations Provided
operations:
  read:
    - name: read_docstring
      description: Read docstring from code file
      parameters:
        - name: file_path
          type: string
          required: true
        - name: function_name
          type: string
          required: false
    - name: read_readme
      description: Read README.md content
      parameters:
        - name: path
          type: string
          required: false
          default: "./README.md"

  write:
    - name: write_docstring
      description: Write docstring to code file
      parameters:
        - name: file_path
          type: string
          required: true
        - name: function_name
          type: string
          required: true
        - name: docstring
          type: string
          required: true
    - name: write_readme
      description: Write content to README.md
      parameters:
        - name: path
          type: string
          required: false
          default: "./README.md"
        - name: content
          type: string
          required: true

  format:
    - name: format_docstring
      description: Format docstring according to language standard
      parameters:
        - name: docstring
          type: string
          required: true
        - name: language
          type: string
          required: true
          enum: [python, java, typescript, javascript]
        - name: style
          type: string
          required: false
          default: "google"
```

#### Usage Example

```python
# Specialized skill using documentation-framework

from documentation_framework import write_docstring, format_docstring

def add_python_docstrings(file_path, function_name, description):
    """Add Python docstring to function"""
    docstring = format_docstring(
        docstring=description,
        language="python",
        style="google"
    )
    write_docstring(
        file_path=file_path,
        function_name=function_name,
        docstring=docstring
    )
```

#### Skills to Refactor
- `docstring-generator` - Use for docstring formatting and writing
- `coverage-readme-workflow` - Use for README operations

---

### 3. issue-framework

#### Purpose
Provide common issue operations for GitHub and JIRA integration.

#### Interface

```yaml
# Framework Extension Point
extends: issue-framework

# Issue Operations Provided
operations:
  create:
    - name: create_issue
      description: Create a new issue
      parameters:
        - name: title
          type: string
          required: true
        - name: body
          type: string
          required: true
        - name: labels
          type: array
          required: false
        - name: platform
          type: string
          required: true
          enum: [github, jira]

  update:
    - name: add_comment
      description: Add comment to issue
      parameters:
        - name: issue_id
          type: string
          required: true
        - name: comment
          type: string
          required: true
    - name: update_status
      description: Update issue status
      parameters:
        - name: issue_id
          type: string
          required: true
        - name: status
          type: string
          required: true

  label:
    - name: assign_labels
      description: Assign labels to issue
      parameters:
        - name: issue_id
          type: string
          required: true
        - name: labels
          type: array
          required: true

  search:
    - name: find_issues
      description: Search for issues
      parameters:
        - name: query
          type: string
          required: true
        - name: platform
          type: string
          required: false
          enum: [github, jira]
```

#### Usage Example

```python
# Specialized skill using issue-framework

from issue_framework import create_issue, add_comment

def create_jira_ticket(title, description, project_key):
    """Create JIRA ticket"""
    issue_id = create_issue(
        title=title,
        body=description,
        platform="jira"
    )
    add_comment(
        issue_id=issue_id,
        comment=f"Project: {project_key}"
    )
```

#### Skills to Refactor
- `git-issue-creator` - Use for issue creation
- `git-issue-labeler` - Use for label assignment
- `git-issue-updater` - Use for comment/status updates
- `jira-git-integration` - Use for JIRA-specific operations

---

### 4. opentofu-framework

#### Purpose
Provide common OpenTofu operations for infrastructure-as-code skills.

#### Interface

```yaml
# Framework Extension Point
extends: opentofu-framework

# OpenTofu Operations Provided
operations:
  init:
    - name: init_workspace
      description: Initialize OpenTofu workspace
      parameters:
        - name: working_dir
          type: string
          required: false
          default: "."

  plan:
    - name: create_plan
      description: Create execution plan
      parameters:
        - name: out
          type: string
          required: false
        - name: var
          type: array
          required: false

  apply:
    - name: apply_changes
      description: Apply infrastructure changes
      parameters:
        - name: auto_approve
          type: boolean
          required: false
          default: false

  state:
    - name: show_state
      description: Show current state
      parameters:
        - name: resource
          type: string
          required: false

  resource:
    - name: create_resource
      description: Create OpenTofu resource
      parameters:
        - name: resource_type
          type: string
          required: true
        - name: resource_name
          type: string
          required: true
        - name: configuration
          type: object
          required: true
```

#### Usage Example

```python
# Specialized skill using opentofu-framework

from opentofu_framework import init_workspace, create_plan, apply_changes

def provision_aws_resource(resource_name, configuration):
    """Provision AWS resource using OpenTofu"""
    init_workspace(working_dir="./infrastructure")
    create_plan(out="tfplan")
    apply_changes(auto_approve=True)
```

#### Skills to Refactor
- `opentofu-aws-explorer` - Use for AWS resources
- `opentofu-keycloak-explorer` - Use for Keycloak resources
- `opentofu-kubernetes-explorer` - Use for K8s resources
- `opentofu-neon-explorer` - Use for Neon resources
- `opentofu-provider-setup` - Use for provider configuration
- `opentofu-provisioning-workflow` - Use for provisioning logic
- `opentofu-ecr-provision` - Use for ECR resources

---

## Enhanced Frameworks Design

### 1. Enhanced test-generator-framework

#### Plugin System

```yaml
# Plugin Interface
plugins:
  scenario_generator:
    - name: python_scenario_generator
      language: python
      priority: 10
      file: python_scenario_generator.py

    - name: javascript_scenario_generator
      language: javascript
      priority: 10
      file: javascript_scenario_generator.py

    - name: typescript_scenario_generator
      language: typescript
      priority: 10
      file: typescript_scenario_generator.py

  test_runner:
    - name: pytest_runner
      framework: pytest
      priority: 10
      file: pytest_runner.py

    - name: jest_runner
      framework: jest
      priority: 10
      file: jest_runner.py

  assertion_generator:
    - name: python_assertion_generator
      language: python
      priority: 10
      file: python_assertion_generator.py
```

#### Usage Example

```python
# Plugin Registration
from test_generator_framework import register_plugin

register_plugin(
    type="scenario_generator",
    name="python_scenario_generator",
    language="python",
    handler=generate_python_scenarios
)

# Plugin Usage
from test_generator_framework import get_scenario_generator

generator = get_scenario_generator(language="python")
scenarios = generator.generate(function_code)
```

---

### 2. Enhanced linting-workflow

#### Plugin System

```yaml
# Plugin Interface
plugins:
  linter:
    - name: ruff_linter
      language: python
      priority: 10
      file: ruff_linter.py

    - name: eslint_linter
      language: javascript
      priority: 10
      file: eslint_linter.py

    - name: prettier_linter
      language: javascript
      priority: 9
      file: prettier_linter.py

  fixer:
    - name: ruff_fixer
      language: python
      priority: 10
      file: ruff_fixer.py

    - name: eslint_fixer
      language: javascript
      priority: 10
      file: eslint_fixer.py
```

#### Usage Example

```python
# Plugin Registration
from linting_workflow import register_linter

register_linter(
    name="ruff_linter",
    language="python",
    runner=run_ruff,
    fixer=fix_ruff_issues
)

# Plugin Usage
from linting_workflow import get_linter

linter = get_linter(language="python")
issues = linter.lint(code)
fixed_code = linter.fix(code, issues)
```

---

## Workflow Composition Framework Design

### Purpose
Provide a way to compose multiple skills into workflows.

### Interface

```yaml
# Workflow Definition
workflow:
  name: jira-git-workflow
  steps:
    - name: create_jira_ticket
      skill: jira-git-integration
      operation: create_issue
      parameters:
        title: "${TASK_TITLE}"
        body: "${TASK_DESCRIPTION}"
        platform: "jira"

    - name: create_branch
      skill: git-workflow-framework
      operation: create_branch
      parameters:
        branch_name: "${JIRA_TICKET_KEY}"
        base_branch: "main"

    - name: create_plan
      skill: ticket-branch-workflow
      operation: create_plan_file
      parameters:
        ticket_key: "${JIRA_TICKET_KEY}"

    - name: commit_plan
      skill: git-workflow-framework
      operation: create_commit
      parameters:
        type: "docs"
        scope: "PLAN"
        description: "Add PLAN.md for ${JIRA_TICKET_KEY}"

    - name: push_branch
      skill: git-workflow-framework
      operation: push_branch
      parameters:
        branch_name: "${JIRA_TICKET_KEY}"
        upstream: true

    - name: update_jira_ticket
      skill: issue-framework
      operation: add_comment
      parameters:
        issue_id: "${JIRA_TICKET_KEY}"
        comment: "Branch created: ${JIRA_TICKET_KEY}"
```

### Usage Example

```python
# Workflow Definition
from workflow_composition import Workflow, Step

workflow = Workflow(name="jira-git-workflow")

workflow.add_step(
    Step(
        name="create_jira_ticket",
        skill="jira-git-integration",
        operation="create_issue",
        parameters={
            "title": "${TASK_TITLE}",
            "body": "${TASK_DESCRIPTION}",
            "platform": "jira"
        }
    )
)

# Workflow Execution
workflow.execute(context={
    "TASK_TITLE": "Implement feature",
    "TASK_DESCRIPTION": "Description here"
})
```

---

## USER Level Skill Control

### Configuration Schema

```json
{
  "skills": {
    "enabled": ["*"],
    "disabled": [],
    "priorities": {
      "git-workflow-framework": 10,
      "test-generator-framework": 9,
      "linting-workflow": 8,
      "issue-framework": 7,
      "documentation-framework": 6
    },
    "customSkillsPath": "/path/to/custom/skills",
    "autoLoad": true,
    "cacheEnabled": true,
    "cacheDuration": 3600
  }
}
```

### Implementation

1. **Skill Discovery**
   - Scan `~/.config/opencode/skills/`
   - Scan project `skills/` directory
   - Scan custom skills path if configured

2. **Skill Filtering**
   - Apply `enabled` patterns (glob matching)
   - Apply `disabled` patterns (glob matching)
   - Resolve conflicts based on priority

3. **Skill Loading**
   - Load skill SKILL.md files
   - Parse skill metadata
   - Build skill dependency graph

4. **Skill Caching**
   - Cache loaded skills if enabled
   - Invalidate cache on skill changes
   - Reduce startup time

---

## Migration Strategy

### Phase 4.1: Create Frameworks (Week 1-2)

**Tasks:**
1. Create `git-workflow-framework` skill
2. Create `documentation-framework` skill
3. Create `issue-framework` skill
4. Create `opentofu-framework` skill
5. Write comprehensive documentation for each framework
6. Create test suites for each framework

**Deliverables:**
- 4 new framework skills
- Framework documentation
- Test suites

### Phase 4.2: Refactor Skills (Week 3-4)

**Tasks:**
1. Refactor Git skills to use `git-workflow-framework`
2. Refactor Documentation skills to use `documentation-framework`
3. Refactor Issue skills to use `issue-framework`
4. Refactor OpenTofu skills to use `opentofu-framework`
5. Ensure backward compatibility
6. Test refactored skills

**Deliverables:**
- Refactored skills
- Backward compatibility layer
- Test results

### Phase 4.3: Enhance Frameworks (Week 5)

**Tasks:**
1. Add plugin system to `test-generator-framework`
2. Add plugin system to `linting-workflow`
3. Implement plugin loading mechanism
4. Create plugin examples
5. Update extended skills to use new features

**Deliverables:**
- Enhanced frameworks
- Plugin examples
- Updated skills

### Phase 4.4: Workflow Composition (Week 6)

**Tasks:**
1. Create `workflow-composition-framework` skill
2. Implement workflow definition language
3. Implement workflow execution engine
4. Refactor `jira-git-workflow` to use composition
5. Create workflow examples

**Deliverables:**
- Workflow composition framework
- Refactored composite skill
- Workflow examples

### Phase 4.5: Documentation and Testing (Week 7)

**Tasks:**
1. Document all frameworks and refactored skills
2. Create migration guide for users
3. Create user guide for skill control
4. Test all skill combinations
5. Verify backward compatibility
6. Create performance benchmarks

**Deliverables:**
- Complete documentation
- Migration guide
- User guide
- Test results
- Performance benchmarks

---

## Testing Strategy

### Framework Testing

1. **Unit Tests**
   - Test each framework operation in isolation
   - Mock dependencies
   - Verify interface contracts

2. **Integration Tests**
   - Test framework with real operations
   - Verify error handling
   - Test edge cases

3. **Plugin Tests**
   - Test plugin loading
   - Verify plugin interfaces
   - Test plugin priority resolution

### Skill Testing

1. **Backward Compatibility Tests**
   - Test old skill patterns still work
   - Verify existing workflows unchanged
   - Test with real projects

2. **Framework Integration Tests**
   - Test refactored skills use frameworks correctly
   - Verify framework extensions work
   - Test error propagation

3. **Migration Tests**
   - Test migration from old to new patterns
   - Verify no data loss
   - Test rollback if needed

---

## Risk Mitigation

### Breaking Changes

**Risk:** Refactoring may break existing workflows

**Mitigation:**
- Maintain backward compatibility layer
- Deprecation warnings before removing old patterns
- Comprehensive testing before release

### Framework Complexity

**Risk:** Too many frameworks increase complexity

**Mitigation:**
- Limit to essential frameworks (4-5)
- Clear documentation for each framework
- Use composition over complex inheritance

### Dependency Graph

**Risk:** Complex dependencies make maintenance hard

**Mitigation:**
- Keep dependency graph shallow (max 2-3 levels)
- Document all dependencies
- Visualize dependency graph

---

## Success Criteria

### Phase 4 Completion Criteria

- [ ] All 4 priority frameworks created and tested
- [ ] All high-priority skills refactored
- [ ] Backward compatibility maintained
- [ ] All tests passing
- [ ] Documentation complete
- [ ] Migration guide created
- [ ] USER skill control implemented
- [ ] Performance benchmarks acceptable
- [ ] User feedback positive

---

## Conclusion

This design provides a clear path for skill modularization with well-defined frameworks, explicit dependencies, and backward compatibility. The modularization will improve maintainability, reduce code duplication, and make it easier to add new skills.

**Next Steps:**
1. Implement Priority 1 frameworks
2. Refactor high-value skills
3. Test thoroughly
4. Document and migrate

---

**Design Date:** 2026-01-29
**Designer:** Build with Skills Agent
**Status:** Ready for Implementation
