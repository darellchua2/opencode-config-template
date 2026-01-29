# Plan: Optimize OpenCode Skills for Conciseness

## Overview

Optimize 33 OpenCode skills to reduce documentation size by ~53% (from ~17,000 to ~8,000 lines) while maintaining utility and clarity.

## Issue Reference

- Issue: #61
- JIRA: IBIS-111
- URL: https://betekk.atlassian.net/browse/IBIS-111
- Branch: IBIS-111

## Problem Statement

The current skills documentation suffers from excessive verbosity, with 33 skills totaling ~17,000 lines (average ~515 lines per skill). This results in:
1. **High token consumption** - Loading skills is expensive
2. **Subagent limitations** - Complex skills cannot be loaded by subagents
3. **Redundant documentation** - Same patterns repeated across skills
4. **Maintenance burden** - Large files are harder to update

## Analysis Summary

**Current State:**
- Total skills: 33
- Total lines: ~17,000
- Average per skill: ~515 lines
- Estimated tokens: ~127,500

**Target State:**
- Target reduction: 53%
- Target lines: ~8,000
- Target average: ~242 lines per skill
- Expected tokens: ~60,000

**Verbosity Categories Identified:**

1. **Verbose Explanations** - Multi-step bash examples where simple commands suffice
2. **Redundant Code Examples** - Duplicate implementations in "Steps" vs "Best Practices"
3. **Excessive Tables** - Wide tables better represented as compact lists
4. **Duplicate Sections** - Content repeated in multiple sections
5. **Over-Detailed Workflow Steps** - Granular steps for simple tasks
6. **Long Code Blocks** - Full examples when snippets would suffice

## Optimization Strategies

### Category 1: Reduce Verbose Explanations

**Pattern:**
```markdown
# Before (verbose)
### Step 1: Check for package.json
First, you need to check if there is a package.json file in the current directory. This file indicates that this is a JavaScript project. You can use the `ls` command to list all files:
```bash
ls -la
```
Look for package.json in the output.

# After (concise)
### Step 1: Detect Project Type
Check for project files:
- `package.json` → JavaScript/TypeScript
- `pyproject.toml` or `requirements.txt` → Python
- `Cargo.toml` → Rust
```

### Category 2: Consolidate Redundant Content

**Pattern:**
- Keep implementation in "Steps" only
- Remove duplicates from "Best Practices" and "Common Issues"
- Use "See Also" references instead of repeating

### Category 3: Simplify Tables

**Pattern:**
```markdown
# Before (wide table)
| Language | Linter Command | Fix Command | Auto-fix Available | Config File |
|----------|----------------|------------|-------------------|-------------|
| Python | `ruff check` | `ruff check --fix` | Yes | `ruff.toml` |
| JavaScript | `eslint .` | `eslint . --fix` | Yes | `.eslintrc.json` |
| TypeScript | `eslint . --ext .ts` | `eslint . --fix --ext .ts` | Yes | `.eslintrc.json` |

# After (compact list)
- Python: `ruff check` → `ruff check --fix` (config: `ruff.toml`)
- JavaScript: `eslint .` → `eslint . --fix` (config: `.eslintrc.json`)
- TypeScript: `eslint . --ext .ts` → `eslint . --fix --ext .ts` (config: `.eslintrc.json`)
```

### Category 4: Delegate to Framework Skills

**Pattern:**
```markdown
# Before (duplicate)
## Steps
### Step 1: Create branch
Use git to create a branch... [full git commands]

### Step 2: Commit changes
Use git to commit... [full git commands]

### Step 3: Create PR
Use gh CLI to create PR... [full gh commands]

# After (delegation)
## Steps
### Step 1: Create Branch
**Framework**: `git-issue-creator`
Create feature branch: `git checkout -b feature/name`

### Step 2: Commit
Use semantic commits: See `git-semantic-commits` framework

### Step 3: Create PR
**Framework**: `git-pr-creator`
Create PR with: `gh pr create --title "..." --body "..."`
```

### Category 5: Reduce Code Block Verbosity

**Pattern:**
```markdown
# Before (full example)
```javascript
// Full component with imports, hooks, styles
import React, { useState } from 'react';

export default function MyComponent() {
  const [count, setCount] = useState(0);
  return (
    <div className="p-4">
      <button onClick={() => setCount(c => c + 1)}>
        Clicked {count} times
      </button>
    </div>
  );
}
```

# After (snippet)
**Key pattern:**
```javascript
const [state, setState] = useState(initialValue);
```
See official docs for full component examples.
```

### Category 6: Standardize Structure

All skills should follow this structure:
```markdown
---
name: skill-name
description: Concise description (50-150 chars)
license: Apache-2.0
compatibility: opencode
metadata:
  audience: developers
  workflow: category
---

## What I do
- Core capability 1 (1 sentence)
- Core capability 2 (1 sentence)
- Core capability 3 (1 sentence)

## When to use me
Use when:
- [Specific scenario 1]
- [Specific scenario 2]

## Prerequisites (optional)
- Requirement 1

## Steps
### Step 1: Brief Title
Concise description.
**Command/Action**: `command`

## Best Practices
- Concise guideline 1

## Common Issues (optional)
### Issue Title
**Solution**: Concise solution

## References (if applicable)
- Link 1
```

## Tasks

### Phase 1: Framework Skills (4 skills, ~3,000 lines to remove)

- [x] 1. linting-workflow (669 → 130 lines, 80% reduction)
  - Removed verbose bash examples
  - Consolidated duplicate configurations
  - Delegated to specific linter skills
  - Reduced tables to compact lists
  - Simplified all 11 workflow steps

- [x] 2. test-generator-framework (424 → 185 lines, 56% reduction)
  - Removed redundant testing framework details
  - Simplified code examples and templates
  - Consolidated scenario generation rules
  - Reduced workflow steps from 8 to 6

- [x] 3. ticket-branch-workflow (688 → 235 lines, 66% reduction)
  - Consolidated duplicate workflow steps
  - Simplified JIRA/git integration examples
  - Removed redundant command explanations
  - Delegated to framework skills
  - Removed duplicate PLAN.md templates
  - Reduced troubleshooting checklist to essentials

- [x] 4. pr-creation-workflow (1028 → 320 lines, 69% reduction)
  - Extracted duplicate content from framework skills
  - Simplified quality check descriptions
  - Removed 600+ lines of virtual environment content
  - Consolidated duplicate PR description templates
  - Delegated platform-specific details to frameworks
  - Reduced troubleshooting checklist to essentials

### Phase 2: Longest Skills (7 skills, ~5,000 lines to remove)

- [x] 5. opentofu-kubernetes-explorer (1213 → 566 lines, 53% reduction)
  - Reduced verbose resource descriptions
  - Simplified command examples
  - Consolidated duplicate resource patterns (3 namespaces, 3 service types)
  - Removed duplicate troubleshooting and example sections
  - Reference official Kubernetes docs
  - Reduced 15 steps to 10 concise steps

- [x] 6. opentofu-neon-explorer (777 → 363 lines, 53% reduction)
  - Reduced database operation examples
  - Simplified configuration snippets
  - Removed redundant connection patterns
  - Removed duplicate troubleshooting and example sections
  - Reduced 15 steps to 7 concise steps
  - Reference Neon docs

- [x] 7. docstring-generator (749 → 372 lines, 50% reduction)
  - Reduced language-specific examples (consolidated duplicates)
  - Simplified pattern descriptions
  - Removed duplicate special cases and troubleshooting sections
  - Show one example per language/style instead of multiple
  - Reference official PEP/Javadoc docs

- [x] 8. nextjs-standard-setup (791 → 336 lines, 58% reduction)
  - Reduced verbose setup instructions
  - Simplified configuration examples (removed duplicates)
  - Removed redundant explanations and examples
  - Show key patterns instead of full implementations
  - Reference Next.js, Tailwind v4, shadcn docs

- [ ] 9. python-pytest-creator (514 → <300 lines)
  - Reduce verbose test examples
  - Simplify test pattern descriptions
  - Consolidate duplicate test types
  - Reference pytest docs

- [ ] 10. git-semantic-commits (756 → <400 lines)
  - Reduce verbose commit examples
  - Simplify commit type descriptions
  - Consolidate duplicate patterns
  - Reference conventional commits spec

- [ ] 11. opencode-skill-creation (513 → <300 lines)
  - Reduce verbose creation steps
  - Simplify template examples
  - Remove redundant documentation
  - Reference skill creation guidelines

### Phase 3: Remaining Skills (15 skills, ~1,000 lines to remove)

- [ ] 12. opencode-skill-auditor (133 → <100 lines)
- [ ] 13. opentofu-provisioning-workflow (pending)
- [ ] 14. opentofu-aws-explorer (pending)
- [ ] 15. opentofu-provider-setup (pending)
- [ ] 16. opentofu-keycloak-explorer (pending)
- [ ] 17. opentofu-ecr-provision (pending)
- [ ] 18. jira-git-integration (pending)
- [ ] 19. git-issue-updater (pending)
- [ ] 20. coverage-readme-workflow (pending)
- [ ] 21. ascii-diagram-creator (pending)
- [ ] 22. typescript-dry-principle (pending)
- [ ] 23. tdd-workflow (pending)
- [ ] 24. git-issue-labeler (pending)
- [ ] 25. git-pr-creator (pending)
- [ ] 26. jira-status-updater (pending)

## Implementation Approach

### For Each Skill Optimization

1. **Read the skill file**: `read filePath="skills/[skill-name]/SKILL.md"`
2. **Analyze verbosity patterns**:
   - Identify which of 6 categories apply
   - Note sections to consolidate
   - Mark duplicate content
3. **Apply optimizations**:
   - Replace verbose explanations with concise alternatives
   - Remove duplicate sections
   - Simplify tables and code blocks
   - Delegate to framework skills
4. **Write optimized version**: `write filePath="skills/[skill-name]/SKILL.md"`
5. **Verify quality**:
   - Check line count meets target
   - Ensure essential info preserved
   - Verify structure compliance
6. **Commit changes**: `git commit -m "refactor(skills): optimize [skill-name] for conciseness"`
7. **Update PLAN.md**: Mark task checkbox as complete
8. **Continue to next skill**

### Success Criteria (Per Skill)

- [ ] Follows standardized structure
- [ ] Essential information preserved
- [ ] Verbose explanations reduced
- [ ] Duplicate content eliminated
- [ ] Code examples minimal and focused
- [ ] Reference links provided for detailed docs
- [ ] Line count reduced to target
- [ ] Skill still functional and clear

## Progress Tracking

**Phase 1 Status**: ✅ 4/4 complete (100%)
**Phase 2 Status**: 4/7 complete (57%)
**Phase 3 Status**: 0/15 complete (0%)
**Overall Progress**: 8/33 complete (24%)

**Lines Reduced**: 3,793 / ~9,000 (42%)
**Tokens Saved**: ~28,447 / ~67,500 (42%)

## References

- JIRA Ticket: https://betekk.atlassian.net/browse/IBIS-111
- Branch: IBIS-111
- GitHub Issue: #61
- Good examples:
  - `opencode-skill-auditor` (133 lines) - concise structure
  - `opencode-agent-creation` (27 lines) - minimal essential info
