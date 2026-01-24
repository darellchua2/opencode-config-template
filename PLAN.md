# Plan: Add git-issue-creator skill with industry-standard GitHub issue management

## Overview

Implement a new OpenCode skill called `git-issue-creator` that provides a complete GitHub issue and branch creation workflow. This skill will streamline the development process by automating issue creation, branch management, and planning documentation.

## Issue Reference

- Issue: #18
- URL: https://github.com/darellchua2/opencode-config-template/issues/18
- Labels: enhancement

## Files to Modify

1. `skills/git-issue-creator/SKILL.md` - Create new skill documentation file
2. `README.md` - Add documentation about the new skill (optional)

## Approach

### Step 1: Analyze Existing Skills
- Review existing skill files (e.g., `opencode-skill-creation/SKILL.md`, `nextjs-pr-workflow/SKILL.md`)
- Understand the standard YAML frontmatter format
- Follow the established structure: "What I do", "When to use me", "Prerequisites", "Steps", "Best Practices", "Common Issues"

### Step 2: Create SKILL.md
Generate `skills/git-issue-creator/SKILL.md` with:

**YAML Frontmatter:**
```yaml
---
name: git-issue-creator
description: Automate GitHub issue creation with intelligent tag detection, branch creation, PLAN.md setup, auto-checkout, and push to remote
license: Apache-2.0
compatibility: opencode
metadata:
  audience: developers
  workflow: github-issue-branch
---
```

**Content Sections:**
- What I do
- When to use me
- Prerequisites (gh CLI, git repo, write access)
- Steps (8 detailed steps from request analysis to push)
- Tag Detection Logic
- Examples (4 use cases)
- PLAN.md Template Structure
- Best Practices
- Common Issues (with solutions)
- Troubleshooting Checklist
- Related Commands
- Related Skills

### Step 3: Implement Tag Detection Logic
Define keyword matching for:
- Bug: fix, error, doesn't work, broken, crash, fails
- Feature: add, implement, create, new, support
- Enhancement: improve, optimize, refactor, update, enhance
- Documentation: document, readme, docs, guide, explain
- Task: setup, configure, deploy, clean, organize

### Step 4: Document Git Workflow
Include commands for:
- GitHub issue creation: `gh issue create --title "..." --body "..." --label "..." --assignee @me`
- Branch creation: `git checkout -b issue-<number>` or `git checkout -b feature/<number>-<title>`
- PLAN.md generation with template
- Commit: `git commit -m "Add PLAN.md for #<issue-number>: <title>"`
- Push: `git push -u origin <branch-name>`

### Step 5: Add Error Handling
Document solutions for:
- GitHub CLI not authenticated
- Repository not initialized
- Branch already exists
- PLAN.md already exists
- No tags detected

### Step 6: Provide Examples
Create 4 detailed examples:
1. Bug Fix
2. New Feature
3. Documentation
4. Multiple Tags

Each showing user input, detected tags, issue created, PLAN.md created, and branch pushed.

### Step 7: Add Troubleshooting Checklists
Pre-creation checklist (5 items)
Post-creation checklist (8 items)

### Step 8: Related Commands and Skills
List useful GitHub CLI and git commands
Reference `nextjs-pr-workflow` and `jira-git-workflow` as related skills

## Success Criteria

- [ ] SKILL.md file created with proper YAML frontmatter
- [ ] Skill follows OpenCode skill documentation standards
- [ ] All core functionality documented (issue creation, branch management, PLAN.md, git ops)
- [ ] Tag detection logic documented for all 5 issue types
- [ ] Error handling documented for common scenarios
- [ ] Troubleshooting checklist provided (pre and post creation)
- [ ] 4 detailed example use cases included
- [ ] Related skills section references `nextjs-pr-workflow` and `jira-git-workflow`
- [ ] Best practices section included
- [ ] Related commands documented
- [ ] Code blocks use proper bash language specifier
- [ ] All links are valid (absolute for external, relative for internal)

## Notes

- The skill description should be concise (1-1024 characters) and specific enough for agents to choose correctly
- Skill name follows naming convention: lowercase alphanumeric with single hyphens (git-issue-creator)
- License should match repository standard (Apache-2.0)
- All bash commands should include language specifier: ```bash
- Industry-standard issue format includes: Description, Type, Labels, Context, Acceptance Criteria
- Default tag should be "enhancement" if no keywords match
- Branch naming should support both simple (issue-123) and semantic (feature/123-add-dark-mode) formats
