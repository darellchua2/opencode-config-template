# Git-Related Skills Audit Report

## Overview
Systematic analysis of OpenCode git-related skills to identify duplications, overlapping responsibilities, and opportunities for streamlining.

## Audit Date
2024-01-25

## Skills Analyzed

### 1. git-issue-labeler (formerly git-issue-assessor)
**Purpose**: Assess and assign GitHub default labels to issues
**Current Responsibilities**:
- Analyze issue content to determine appropriate GitHub default labels
- Use keyword matching to identify issue types
- Assign single or multiple labels based on issue complexity
- Provide label descriptions for clarity and consistency
- Support 9 GitHub default labels: bug, enhancement, documentation, duplicate, good first issue, help wanted, invalid, question, wontfix

### 2. git-semantic-commits
**Purpose**: Format Git commit messages following Conventional Commits specification
**Current Responsibilities**:
- Format commit messages following Conventional Commits format
- Detect commit type from content (feat, fix, docs, style, refactor, test, chore, perf, ci, build, revert)
- Support scopes for affected component/package
- Detect breaking changes (! or BREAKING CHANGE: footer)
- Provide versioning guidance (MAJOR.MINOR.PATCH)
- Validate commit messages
- Generate templates for each commit type

### 3. git-issue-updater
**Purpose**: Update GitHub issues and JIRA tickets with commit progress
**Current Responsibilities**:
- Extract latest commit details: hash, message, author, date, time, files changed
- Determine issue reference from commit message
- Format comment with consistent documentation: user, date, time, changes summary
- Support both GitHub issues and JIRA tickets
- Include commit link (GitHub) or hash (JIRA)
- Provide update templates for different commit types
- Verify comment was successfully added

### 4. git-issue-creator
**Purpose**: GitHub issue creation with intelligent tag detection, extending ticket-branch-workflow
**Current Responsibilities**:
- Analyze request to determine issue type
- Detect tags: feature, bug, documentation, enhancement, task (DUPLICATE with git-issue-labeler)
- Create GitHub issue with title, description, auto-detected labels, and assignee
- Execute ticket-branch-workflow for branch creation, PLAN.md, commit, and push (uses git-semantic-commits?)
- Display summary of work completed

### 5. ticket-branch-workflow
**Purpose**: Generic ticket-to-branch-to-PLAN workflow supporting multiple platforms
**Current Responsibilities**:
- Analyze request and detect platform (GitHub or JIRA)
- Create ticket with appropriate labels/tags/issue type (DUPLICATE label detection with git-issue-labeler)
- Generate branch name from ticket number/ID
- Create and checkout git branch
- Create PLAN.md with issue reference
- Commit PLAN.md with ticket reference (should use git-semantic-commits)
- Push branch to remote

### 6. jira-git-workflow
**Purpose**: JIRA ticket creation and branching, extending ticket-branch-workflow and jira-git-integration
**Current Responsibilities**:
- Identify JIRA project using jira-git-integration
- Create JIRA ticket with summary and description using jira-git-integration
- Add comments to JIRA tickets if needed using jira-git-integration
- Create Git branch named after JIRA ticket
- Commit PLAN.md using ticket-branch-workflow (should use git-semantic-commits)
- Push branch to remote

### 7. jira-git-integration
**Purpose**: Generic JIRA + Git workflow utilities for ticket management, branch creation, and integration
**Current Responsibilities**:
- Get JIRA resources (cloud ID, projects)
- Get JIRA user information for ticket assignment
- Create JIRA tickets (tasks, stories, bugs)
- Add JIRA comments with Markdown formatting
- Upload images to JIRA as attachments
- Generate JIRA branch names from ticket keys
- Fetch JIRA issue details

### 8. git-pr-creator
**Purpose**: Create Git pull requests and optionally update JIRA tickets with comments and image attachments
**Current Responsibilities**:
- Check JIRA integration (ask user)
- Create pull request with comprehensive description
- Scan for diagrams/images
- Attach images to JIRA (local/temporary images)
- Add JIRA comments with PR details using jira-git-integration
- Handle image detection and categorization

### 9. pr-creation-workflow
**Purpose**: Generic pull request creation workflow with configurable quality checks and multi-platform integration
**Current Responsibilities**:
- Identify target branch for PR (configurable, not hardcoded)
- Run quality checks (linting, building, testing) using linting-workflow
- Identify tracking (JIRA tickets or git issue references)
- Create pull request linked to tracking systems
- Handle images (upload local and embed in PR description)
- Prompt user for merge target after PR creation

### 10. nextjs-pr-workflow
**Purpose**: Complete Next.js PR workflow using pr-creation-workflow, jira-git-integration, and linting-workflow
**Current Responsibilities**:
- Identify target branch for PR
- Run Next.js quality checks using linting-workflow
- Identify tracking (JIRA tickets or git issue references)
- Create PR using pr-creation-workflow framework
- Add JIRA comments using jira-git-integration
- **CRITICAL**: All tests must pass before PR creation (blocking)

---

## Duplications Identified

### 1. Label Detection Duplication ⚠️

| Skill | Label Detection Logic | Status |
|--------|---------------------|--------|
| git-issue-creator | Custom tags: feature, bug, documentation, enhancement, task | ⚠️ DUPLICATE - Should use git-issue-labeler |
| ticket-branch-workflow | Generic detection for GitHub and JIRA | ⚠️ DUPLICATE - Should use git-issue-labeler |
| git-issue-labeler | GitHub default labels: bug, enhancement, documentation, duplicate, good first issue, help wanted, invalid, question, wontfix | ✅ CORRECT - Framework skill |

**Recommendation**:
- Remove label detection logic from git-issue-creator
- Remove label detection logic from ticket-branch-workflow
- Both skills should delegate to git-issue-labeler

### 2. Commit Message Duplication ⚠️

| Skill | Commit Message Logic | Status |
|--------|---------------------|--------|
| git-issue-creator | Custom PLAN.md commit format | ⚠️ INCONSISTENT - Should use git-semantic-commits |
| ticket-branch-workflow | Custom PLAN.md commit format | ⚠️ INCONSISTENT - Should use git-semantic-commits |
| git-semantic-commits | Conventional Commits specification | ✅ CORRECT - Framework skill |

**Recommendation**:
- Update git-issue-creator to use git-semantic-commits for formatting PLAN.md commits
- Update ticket-branch-workflow to use git-semantic-commits for formatting PLAN.md commits
- Ensure commit messages follow: `<type>(<scope>): <subject>` format

### 3. Issue Update Duplication ⚠️

| Skill | Issue Update Logic | Status |
|--------|---------------------|--------|
| git-pr-creator | Adds JIRA comments with PR details | ⚠️ PARTIAL - Should use git-issue-updater for consistency |
| None of current skills | Updates issues after commits | ⚠️ MISSING - git-issue-updater is NEW skill |

**Recommendation**:
- Update git-pr-creator to use git-issue-updater for adding progress comments
- Add git-issue-updater calls to git-issue-creator and ticket-branch-workflow after commits
- Ensure all issue updates include: user, date, time, commit hash, files changed

### 4. PR Creation Duplication ⚠️

| Skill | PR Creation Logic | Status |
|--------|---------------------|--------|
| git-pr-creator | Creates PRs with JIRA integration | ✅ CORRECT - Specific skill |
| pr-creation-workflow | Generic PR creation framework | ✅ CORRECT - Framework skill |
| nextjs-pr-workflow | Extends pr-creation-workflow | ✅ CORRECT - Uses framework appropriately |

**Recommendation**:
- No changes needed - these skills are properly structured (framework + specific)
- Ensure nextjs-pr-workflow continues to use pr-creation-workflow as framework

### 5. Framework Skills (No Duplication) ✅

| Skill | Type | Purpose | Status |
|--------|-------|---------|--------|
| ticket-branch-workflow | Framework | Ticket-to-branch-to-PLAN workflow | ✅ CORRECT - Framework skill |
| jira-git-integration | Framework | JIRA utilities (API operations) | ✅ CORRECT - Framework skill |
| linting-workflow | Framework | Linting across multiple languages | ✅ CORRECT - Framework skill |

**Recommendation**:
- These skills are correctly structured as frameworks
- Other skills should use these frameworks appropriately

---

## Streamlining Recommendations

### Priority 1: High ⚡

**Remove Label Detection Duplication**

**Affected Skills**:
1. git-issue-creator
2. ticket-branch-workflow

**Actions**:
```diff
- # Remove label detection logic
- ## Tag Detection Logic

- The skill uses keyword matching to determine appropriate tags:

- ### Bug Detection
- Keywords: `fix`, `error`, `doesn't work`, `broken`, `crash`, `fails`, `issue`, `problem`, `incorrect`, `wrong`, `bug`
- ...
+ # Delegate to git-issue-labeler for label detection
+ Use `git-issue-labeler` skill to determine and assign appropriate labels to issues.
+ The git-issue-labeler skill uses GitHub default labels: bug, enhancement, documentation, duplicate, good first issue, help wanted, invalid, question, wontfix
```

**Implementation**:
- Update git-issue-creator to remove Step 2 "Determine Tags" and "Tag Detection Logic" section
- Update ticket-branch-workflow to remove Step 2 "Determine Ticket Type and Labels"
- Both skills should call git-issue-labeler as a framework skill
- Update related skills sections to reference git-issue-labeler

**Benefits**:
- Single source of truth for label detection
- Consistent label assignment across all workflows
- Easier maintenance (update logic in one place)
- Reduced code duplication

### Priority 2: High ⚡

**Standardize Commit Message Formatting**

**Affected Skills**:
1. git-issue-creator
2. ticket-branch-workflow

**Actions**:
```diff
- # Commit PLAN.md with custom format
- git commit -m "Add PLAN.md for #${ISSUE_NUMBER}: ${TICKET_TITLE}"

+ # Commit PLAN.md with semantic format
+ git commit -m "docs(plan): add PLAN.md for #${ISSUE_NUMBER}"

# Use git-semantic-commits for formatting:
COMMIT_MSG=$(git-semantic-commits --type docs --scope plan --subject "Add PLAN.md for #${ISSUE_NUMBER}")
git commit -m "$COMMIT_MSG"
```

**Implementation**:
- Update git-issue-creator to use git-semantic-commits for commit formatting
- Update ticket-branch-workflow to use git-semantic-commits for commit formatting
- Ensure commit type is "docs" for PLAN.md commits
- Use scope "plan" for consistency
- Update related skills sections to reference git-semantic-commits

**Benefits**:
- Consistent commit message format across all workflows
- Semantic versioning support enabled
- Better git history readability
- Automated changelog generation possible

### Priority 3: Medium 📊

**Add Issue Update After Commits**

**Affected Skills**:
1. git-issue-creator
2. ticket-branch-workflow
3. jira-git-workflow

**Actions**:
```diff
# Add issue update after creating PLAN.md commit
- git commit -m "Add PLAN.md for #${ISSUE_NUMBER}: ${TICKET_TITLE}"
- git push -u origin "$BRANCH_NAME"

+ # Add issue update after creating PLAN.md commit
+ git commit -m "docs(plan): add PLAN.md for #${ISSUE_NUMBER}"
+ git push -u origin "$BRANCH_NAME"
+
+ # Update issue with commit progress
+ git-issue-updater --issue "$ISSUE_NUMBER" --platform github
```

**Implementation**:
- Add git-issue-updater call after committing PLAN.md
- Ensure updates include user, date, time, commit hash
- Format updates consistently using git-issue-updater templates
- Update related skills sections to reference git-issue-updater

**Benefits**:
- Automatic progress tracking in issues
- Consistent documentation with timestamps
- Better traceability between commits and issues
- Enhanced team collaboration visibility

### Priority 4: Low ℹ️

**Review and Consolidate PR Skills**

**Status**: Already properly structured

**Analysis**:
- git-pr-creator is a specific skill for Git PRs with JIRA integration
- pr-creation-workflow is a framework skill for generic PR creation
- nextjs-pr-workflow properly extends pr-creation-workflow

**Recommendation**:
- No changes needed - structure is correct
- Maintain current framework + specific pattern

---

## Integration Matrix

### Current State (Before Streamlining)

```
┌─────────────────────────────────────────────────────────────────────────┐
│                     git-issue-creator                             │
│  ├─ Custom label detection (DUPLICATE)                            │
│  ├─ Custom commit format (INCONSISTENT)                           │
│  └─ No issue update (MISSING)                                 │
│                                                                 │
├─────────────────────────────────────────────────────────────────────────┤
│                  ticket-branch-workflow                           │
│  ├─ Custom label detection (DUPLICATE)                            │
│  ├─ Custom commit format (INCONSISTENT)                           │
│  └─ No issue update (MISSING)                                 │
│                                                                 │
├─────────────────────────────────────────────────────────────────────────┤
│                    git-semantic-commits                            │
│  └─ Conventional Commits specification (Framework) ✅              │
│                                                                 │
├─────────────────────────────────────────────────────────────────────────┤
│                     git-issue-labeler                              │
│  └─ GitHub default labels (Framework) ✅                            │
│                                                                 │
├─────────────────────────────────────────────────────────────────────────┤
│                     git-issue-updater                               │
│  └─ Issue updates with user, date, time (Framework) ✅             │
│                                                                 │
├─────────────────────────────────────────────────────────────────────────┤
│                  jira-git-integration                            │
│  └─ JIRA utilities (Framework) ✅                                   │
│                                                                 │
└─────────────────────────────────────────────────────────────────────────┘
```

### Target State (After Streamlining)

```
┌─────────────────────────────────────────────────────────────────────────┐
│                     git-issue-creator                             │
│  ├─ Uses git-issue-labeler (DELEGATED) ✅                         │
│  ├─ Uses git-semantic-commits (DELEGATED) ✅                    │
│  ├─ Uses git-issue-updater (DELEGATED) ✅                          │
│  └─ Ticket creation + branch + PLAN.md                           │
│                                                                 │
├─────────────────────────────────────────────────────────────────────────┤
│                  ticket-branch-workflow                           │
│  ├─ Uses git-issue-labeler (DELEGATED) ✅                         │
│  ├─ Uses git-semantic-commits (DELEGATED) ✅                    │
│  ├─ Uses git-issue-updater (DELEGATED) ✅                          │
│  └─ Generic ticket-to-branch-to-PLAN                                 │
│                                                                 │
├─────────────────────────────────────────────────────────────────────────┤
│                    git-semantic-commits                            │
│  └─ Conventional Commits specification (Framework) ✅              │
│                                                                 │
├─────────────────────────────────────────────────────────────────────────┤
│                     git-issue-labeler                              │
│  └─ GitHub default labels (Framework) ✅                            │
│                                                                 │
├─────────────────────────────────────────────────────────────────────────┤
│                     git-issue-updater                               │
│  └─ Issue updates with user, date, time (Framework) ✅             │
│                                                                 │
├─────────────────────────────────────────────────────────────────────────┤
│                  jira-git-integration                            │
│  └─ JIRA utilities (Framework) ✅                                   │
│                                                                 │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## Migration Path

### Phase 1: Create Framework Skills ✅
- [x] Create git-semantic-commits skill
- [x] Create git-issue-updater skill
- [x] Create git-issue-labeler skill (renamed from git-issue-assessor)

### Phase 2: Update git-issue-creator
- [ ] Remove custom label detection logic
- [ ] Delegate to git-issue-labeler for label assignment
- [ ] Use git-semantic-commits for commit formatting
- [ ] Add git-issue-updater call after PLAN.md commit
- [ ] Update related skills section
- [ ] Update examples and documentation

### Phase 3: Update ticket-branch-workflow
- [ ] Remove custom label detection logic
- [ ] Delegate to git-issue-labeler for label assignment
- [ ] Use git-semantic-commits for commit formatting
- [ ] Add git-issue-updater call after PLAN.md commit
- [ ] Update related skills section
- [ ] Update examples and documentation

### Phase 4: Update jira-git-workflow
- [ ] Use git-semantic-commits for commit formatting
- [ ] Add git-issue-updater call after PLAN.md commit
- [ ] Update related skills section
- [ ] Update examples and documentation

### Phase 5: Verify Integration
- [ ] Test all git-related workflows end-to-end
- [ ] Verify consistent commit message formatting
- [ ] Verify consistent label assignment
- [ ] Verify issue updates work correctly
- [ ] Run opencode-skills-maintainer to update agents

---

## Success Metrics

### Code Duplication Reduction
- **Label Detection**: Remove 2 duplicate implementations → ~500 lines saved
- **Commit Formatting**: Remove 2 inconsistent implementations → ~300 lines saved
- **Total Duplication Removed**: ~800 lines

### Maintainability Improvements
- **Single Source of Truth**: Label detection in git-issue-labeler only
- **Standardized Format**: Commit messages via git-semantic-commits only
- **Consistent Documentation**: Issue updates via git-issue-updater only

### User Experience Improvements
- **Consistent Labels**: All issues labeled with GitHub defaults
- **Semantic Commits**: All commits follow Conventional Commits format
- **Progress Tracking**: Automatic issue updates with timestamps

---

## Conclusion

The git-related skills ecosystem has significant duplications that can be resolved by:

1. **Delegating to Framework Skills**: Use git-issue-labeler, git-semantic-commits, and git-issue-updater
2. **Removing Duplicate Logic**: Eliminate custom label detection and commit formatting implementations
3. **Adding Missing Capabilities**: Integrate git-issue-updater for automatic progress tracking
4. **Maintaining Framework Structure**: Keep pr-creation-workflow and jira-git-integration as frameworks

**Estimated Impact**:
- Code reduction: ~800 lines of duplication
- Maintenance effort: Reduced by 60% (update in 3 places instead of 8)
- Consistency: Improved across all git workflows
- Quality: Better traceability and documentation

**Recommended Priority**: High ⚡
**Estimated Effort**: 4-6 hours for complete streamlining

---

## Audit Completed By
OpenCode Skill Auditor (manual analysis)
Date: 2024-01-25
