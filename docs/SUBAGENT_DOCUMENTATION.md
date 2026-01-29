# Subagent Documentation

This document describes each subagent's purpose, attached skills, usage patterns, and when to invoke them.

---

## Overview

opencode-ai uses 6 subagents for specialized tasks. Each subagent has specific skills attached and is designed for particular types of work.

### Subagent Architecture

```
User Request
    ↓
build-with-skills / plan-with-skills (Primary Agents)
    ↓
Subagent Selection (based on task type)
    ↓
Specialized Subagent (one of 6)
    ↓
Skill Execution (using attached skills)
    ↓
Result
```

---

## Subagent Descriptions

### 1. linting-subagent

**Purpose:** Code quality enforcement and style management

**Model:** glm-4.7

**Skills Attached:**
- `linting-workflow` - Generic linting workflow with auto-fix
- `python-ruff-linter` - Python Ruff linter (extends linting-workflow)
- `javascript-eslint-linter` - JavaScript/TypeScript ESLint linter (extends linting-workflow)

**Capabilities:**
- Automatic language detection (Python, JavaScript, TypeScript, Go, Ruby)
- Linter configuration detection
- Auto-fix linting issues
- Error resolution guidance
- Style enforcement (PEP 8 for Python, ESLint rules for JS/TS)
- Integration with build workflows

**When to Use:**
- Running linting before committing
- Fixing style issues in code
- Enforcing code quality standards
- Pre-commit checks
- PR review automation

**Routing Patterns:**
- `lint*` → linting-subagent
- `fix*style*` → linting-subagent
- `check*code*` → linting-subagent
- `enforce*style*` → linting-subagent

**Example Usage:**
```
User: "Lint the Python code"
↓
linting-subagent invoked
↓
python-ruff-linter runs
↓
Auto-fixes issues
↓
Reports results
```

**Tools Access:**
- File operations (read, write)
- Shell commands (linting tools)
- Git operations (commit fixes)

---

### 2. testing-subagent

**Purpose:** Test generation, execution, and maintenance

**Model:** glm-4.7

**Skills Attached:**
- `test-generator-framework` - Generic test generation workflow
- `python-pytest-creator` - Python pytest test generator (extends test-generator-framework)
- `nextjs-unit-test-creator` - Next.js unit test generator (extends test-generator-framework)

**Capabilities:**
- Automatic framework detection (pytest, jest, vitest)
- Test scenario generation (happy paths, edge cases, error handling)
- Framework-specific test patterns (Python decorators, React testing, async testing)
- Test execution and verification
- Coverage measurement
- Integration with build workflows

**When to Use:**
- Generating tests for new code
- Testing existing code for coverage
- Running test suites
- Generating test scenarios
- Ensuring test quality

**Routing Patterns:**
- `test*` → testing-subagent
- `spec*` → testing-subagent
- `generate*test*` → testing-subagent
- `run*test*` → testing-subagent
- `coverage*` → testing-subagent

**Example Usage:**
```
User: "Generate tests for this Python function"
↓
testing-subagent invoked
↓
python-pytest-creator runs
↓
Generates test scenarios
↓
Creates test file with pytest
↓
Runs tests to verify
```

**Tools Access:**
- File operations (read, write test files)
- Shell commands (test runners)
- Code analysis (parsing, AST)

---

### 3. git-workflow-subagent

**Purpose:** Git operations, version control, and repository management

**Model:** glm-4.7

**Skills Attached:**
- `ticket-branch-workflow` - Generic ticket-to-branch workflow
- `jira-git-integration` - JIRA API operations
- `git-issue-creator` - GitHub/GitLab issue creation
- `git-issue-labeler` - Automatic issue labeling
- `git-issue-updater` - Issue comment and status updates
- `git-pr-creator` - Pull request creation
- `git-semantic-commits` - Semantic commit formatting
- `ascii-diagram-creator` - ASCII diagram generation for workflows

**Capabilities:**
- Issue creation (GitHub, GitLab, JIRA)
- Branch creation from tickets
- Semantic commit formatting
- Pull request creation and management
- Issue labeling and updates
- Workflow documentation (ASCII diagrams)
- Integration with ticketing systems

**When to Use:**
- Creating Git branches
- Committing code changes
- Creating pull requests
- Managing issues
- Integrating with JIRA
- Documenting workflows

**Routing Patterns:**
- `branch*` → git-workflow-subagent
- `commit*` → git-workflow-subagent
- `pr*` → git-workflow-subagent
- `pull*request*` → git-workflow-subagent
- `issue*` → git-workflow-subagent
- `jira*` → git-workflow-subagent

**Example Usage:**
```
User: "Create a branch from JIRA ticket IBIS-123"
↓
git-workflow-subagent invoked
↓
jira-git-integration gets ticket details
↓
ticket-branch-workflow creates branch
↓
Commits PLAN.md with semantic format
↓
Pushes branch to remote
```

**Tools Access:**
- Git operations (branch, commit, push, PR)
- JIRA API (tickets, comments, status)
- GitHub/GitLab API (issues, PRs)
- File operations (PLAN.md, README.md)

---

### 4. documentation-subagent

**Purpose:** Documentation generation and maintenance

**Model:** glm-4.7

**Skills Attached:**
- `docstring-generator` - Language-specific docstring generation
- `coverage-readme-workflow` - README coverage badge generation

**Capabilities:**
- Docstring generation (Python, Java, TypeScript, JavaScript)
- Documentation format standards (PEP 257, Javadoc, JSDoc)
- README generation and updates
- Coverage badge integration
- Documentation best practices
- API documentation extraction

**When to Use:**
- Generating docstrings for code
- Updating README with coverage
- Creating API documentation
- Ensuring documentation completeness
- Following documentation standards

**Routing Patterns:**
- `doc*` → documentation-subagent
- `readme*` → documentation-subagent
- `generate*docstring*` → documentation-subagent
- `api*doc*` → documentation-subagent

**Example Usage:**
```
User: "Add docstrings to this Python function"
↓
documentation-subagent invoked
↓
docstring-generator runs
↓
Generates Google-style docstring
↓
Updates Python file with docstring
↓
Verifies documentation completeness
```

**Tools Access:**
- File operations (read, write code files)
- Code analysis (parsing functions, classes)
- Documentation formatting (PEP 257, Javadoc, JSDoc)

---

### 5. opentofu-explorer-subagent

**Purpose:** Infrastructure as code exploration and management with OpenTofu

**Model:** glm-4.7

**Skills Attached:**
- `opentofu-aws-explorer` - AWS resource exploration
- `opentofu-keycloak-explorer` - Keycloak identity management
- `opentofu-kubernetes-explorer` - Kubernetes cluster management
- `opentofu-neon-explorer` - Neon Postgres database management
- `opentofu-provider-setup` - Provider configuration
- `opentofu-provisioning-workflow` - Infrastructure provisioning
- `opentofu-ecr-provision` - ECR container registry management

**Capabilities:**
- Cloud resource exploration (AWS, Keycloak, K8s, Neon)
- Infrastructure state management
- Resource provisioning and updates
- Provider configuration
- Container registry management (ECR)
- Infrastructure as code best practices
- Cost optimization guidance

**When to Use:**
- Exploring infrastructure resources
- Managing cloud infrastructure
- Provisioning new resources
- Configuring providers
- Managing container registries
- Optimizing infrastructure costs

**Routing Patterns:**
- `infra*` → opentofu-explorer-subagent
- `terraform*` → opentofu-explorer-subagent
- `opentofu*` → opentofu-explorer-subagent
- `k8s*` → opentofu-explorer-subagent
- `kubernetes*` → opentofu-explorer-subagent
- `aws*` → opentofu-explorer-subagent
- `ecr*` → opentofu-explorer-subagent

**Example Usage:**
```
User: "Provision an S3 bucket using OpenTofu"
↓
opentofu-explorer-subagent invoked
↓
opentofu-aws-explorer runs
↓
Generates Terraform/OpenTofu code
↓
Provisions S3 bucket
↓
Updates state
↓
Reports configuration
```

**Tools Access:**
- OpenTofu/Terraform commands (init, plan, apply, state)
- Cloud APIs (AWS, Keycloak, K8s, Neon)
- File operations (Terraform code, state files)
- Shell commands (provider installation, configuration)

---

### 6. workflow-subagent

**Purpose:** Workflow automation, PR creation, and JIRA integration

**Model:** glm-4.7

**Skills Attached:**
- `pr-creation-workflow` - Generic PR creation workflow
- `jira-git-workflow` - Complete JIRA-to-Git workflow
- `jira-git-integration` - JIRA API operations
- `jira-status-updater` - JIRA status automation
- `nextjs-pr-workflow` - Next.js-specific PR workflow (extends pr-creation-workflow)
- `ticket-branch-workflow` - Generic ticket-to-branch workflow
- `opencode-skills-maintainer` - Skills update automation

**Capabilities:**
- PR creation with quality checks
- JIRA ticket creation and updates
- Workflow composition
- Status automation
- Multi-platform support (GitHub, GitLab, JIRA)
- Quality gate enforcement
- Workflow documentation

**When to Use:**
- Creating pull requests
- Automating PR workflows
- Managing JIRA status
- Composing complex workflows
- Ensuring PR quality
- Automating status transitions

**Routing Patterns:**
- `workflow*` → workflow-subagent
- `automation*` → workflow-subagent
- `pr*` → workflow-subagent (alternative to git-workflow-subagent)
- `jira*` → workflow-subagent (alternative to git-workflow-subagent)
- `automate*` → workflow-subagent

**Example Usage:**
```
User: "Create a PR with quality checks and JIRA update"
↓
workflow-subagent invoked
↓
pr-creation-workflow creates PR
↓
Quality checks run (linting, testing)
↓
jira-git-integration updates JIRA ticket
↓
jira-status-updater transitions status
↓
Reports workflow completion
```

**Tools Access:**
- Git operations (PR creation, branch management)
- JIRA API (tickets, comments, status)
- GitHub/GitLab API (PRs, reviews, checks)
- File operations (PLAN.md, README.md)
- Shell commands (quality checks)

---

## Subagent Comparison

| Subagent | Primary Skills | Languages | Use Cases |
|-----------|---------------|------------|------------|
| **linting-subagent** | linting-workflow, python-ruff-linter, javascript-eslint-linter | Python, JavaScript, TypeScript | Code quality, style enforcement |
| **testing-subagent** | test-generator-framework, python-pytest-creator, nextjs-unit-test-creator | Python, Next.js | Test generation, coverage |
| **git-workflow-subagent** | ticket-branch-workflow, git-issue-creator, git-pr-creator | All | Git operations, issue management |
| **documentation-subagent** | docstring-generator, coverage-readme-workflow | Python, Java, TypeScript, JavaScript | Documentation generation |
| **opentofu-explorer-subagent** | 7 OpenTofu skills | Terraform/OpenTofu | Infrastructure management |
| **workflow-subagent** | pr-creation-workflow, jira-git-workflow | All | Workflow automation, PRs |

---

## Subagent Invocation Flow

### Automatic Subagent Selection

```
User Request
    ↓
build-with-skills analyzes task
    ↓
Matches routing pattern
    ↓
Selects appropriate subagent
    ↓
Invokes subagent with context
    ↓
Subagent selects skill
    ↓
Skill executes
    ↓
Returns result
```

### Subagent Skill Selection

Each subagent has its own logic for selecting the best skill:

1. **Analyze Task Type**
   - What kind of work is needed?
   - Language/framework specific?
   - Platform specific?

2. **Match Skills**
   - Find skills that can handle the task
   - Check skill priorities
   - Check USER skill preferences

3. **Select Best Skill**
   - Highest priority skill
   - Most specific skill
   - USER preference (if configured)

4. **Execute Skill**
   - Pass context to skill
   - Monitor execution
   - Return results

---

## Subagent Configuration

### Subagent Permissions

Each subagent has specific tool permissions:

| Subagent | Git | File | Shell | API | Cloud |
|-----------|------|-------|-------|-----|--------|
| linting-subagent | ✅ | ✅ | ✅ | ❌ | ❌ |
| testing-subagent | ✅ | ✅ | ✅ | ❌ | ❌ |
| git-workflow-subagent | ✅ | ✅ | ✅ | ✅ | ❌ |
| documentation-subagent | ❌ | ✅ | ❌ | ❌ | ❌ |
| opentofu-explorer-subagent | ❌ | ✅ | ✅ | ❌ | ✅ |
| workflow-subagent | ✅ | ✅ | ✅ | ✅ | ❌ |

### Subagent Timeout

Default subagent timeout: 300 seconds (5 minutes)

Can be configured in USER config:

```json
{
  "agents": {
    "subagentTimeout": 300
  }
}
```

### Subagent Concurrency

Maximum concurrent subagents: 3

Can be configured in USER config:

```json
{
  "agents": {
    "maxConcurrentAgents": 3
  }
}
```

---

## Subagent Routing

### Routing Configuration

Routing patterns are defined in config.json:

```json
{
  "agents": {
    "subagentRouting": {
      "enabled": true,
      "patterns": {
        "lint*": "linting-subagent",
        "test*": "testing-subagent",
        "branch*": "git-workflow-subagent",
        "pr*": "git-workflow-subagent",
        "doc*": "documentation-subagent",
        "infra*": "opentofu-explorer-subagent",
        "workflow*": "workflow-subagent"
      }
    }
  }
}
```

### Custom Routing Patterns

USER can customize routing:

```json
{
  "agents": {
    "subagentRouting": {
      "patterns": {
        "my*test*": "testing-subagent",
        "my*lint*": "linting-subagent",
        "my*workflow": "workflow-subagent"
      }
    }
  }
}
```

---

## Best Practices

### 1. Use Appropriate Subagent

**Good:**
- Use linting-subagent for code quality checks
- Use testing-subagent for test generation
- Use git-workflow-subagent for Git operations

**Bad:**
- Use build-with-skills for simple linting tasks
- Use git-workflow-subagent for documentation

### 2. Let Subagent Select Skills

**Good:**
- Request subagent with task description
- Let subagent choose best skill
- Trust subagent's skill selection

**Bad:**
- Manually specify skill name
- Override subagent's skill selection
- Force skill usage

### 3. Configure Subagent Behavior

**Good:**
- Set subagent timeout appropriately
- Configure concurrent subagents
- Customize routing patterns

**Bad:**
- Use default settings for all use cases
- Ignore subagent configuration
- Override subagent without need

---

## Troubleshooting

### Subagent Not Invoked

**Symptoms:**
- Default agent used instead of subagent
- Unexpected agent handles task

**Solutions:**
1. Check routing patterns in config.json
2. Verify subagent routing is enabled
3. Check USER routing overrides
4. Restart opencode after configuration changes

### Wrong Skill Used

**Symptoms:**
- Subagent uses unexpected skill
- Skill priority not respected

**Solutions:**
1. Check skill priorities in USER config
2. Verify skill is enabled (not disabled)
3. Check skill category settings
4. Review subagent skill selection logic

### Subagent Timeout

**Symptoms:**
- Subagent hangs or times out
- Task incomplete

**Solutions:**
1. Increase subagent timeout
2. Reduce concurrent subagents
3. Optimize skill execution
4. Check resource availability

---

## Getting Help

- **List Subagents:** `opencode --list-agents`
- **Subagent Details:** See config.json agent definitions
- **Skill Documentation:** See `skills/<skill-name>/SKILL.md`
- **Configuration Guide:** `templates/USER_CONFIG.md`
- **Subagent Config:** `~/.config/opencode/user/config.user.json`

---

**Last Updated:** 2026-01-29
**Version:** 1.0.0
