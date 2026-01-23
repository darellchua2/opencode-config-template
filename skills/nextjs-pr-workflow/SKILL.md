---
name: nextjs-pr-workflow
description: Complete Next.js PR workflow with linting, building, and JIRA/git issue integration for PLAN.md completion
license: Apache-2.0
compatibility: opencode
metadata:
  audience: developers
  workflow: nextjs-pr
---

## What I do

I implement a complete Next.js PR creation workflow when finishing implementation of PLAN.md or new code:

1. **Run Linting**: Execute `npm run lint` and resolve all linting errors
2. **Verify Build**: Execute `npm run build` to ensure all builds complete successfully
3. **Identify Tracking**: Check PLAN.md for JIRA references or git issue associations
4. **Create Pull Request**: Create a PR linked to JIRA space or git issue
5. **Update Documentation**: Ensure all PR documentation is complete
6. **Add JIRA Comments**: If JIRA ticket exists, add appropriate comments
7. **Merge Prompt**: Ask user which branch to merge into

## When to use me

Use this workflow when:
- Completing implementation of a PLAN.md file
- Finishing new feature implementation in Next.js apps
- Ready to create a PR after development is complete
- Need to ensure code quality before submitting changes
- Following the standard practice of linting and building before PR

## Prerequisites

- Next.js project with `npm run lint` and `npm run build` scripts
- Git repository initialized and on a feature branch
- Active Atlassian/JIRA account (if using JIRA integration)
- Write access to the repository
- PLAN.md file with implementation details

## Steps

### Step 1: Check Project Structure
- Verify this is a Next.js project (check `package.json`)
- Ensure `npm run lint` and `npm run build` scripts exist
- Confirm you're on a feature branch (not main/master)

### Step 2: Run Linting
- Execute: `npm run lint`
- Review any linting errors
- Fix all linting errors iteratively:
  - Use `eslint` auto-fix where possible: `npm run lint -- --fix`
  - Manually fix remaining issues
  - Re-run linting until all errors are resolved
- Commit linting fixes if needed: `git commit -m "Fix linting errors"`

### Step 3: Verify Build
- Execute: `npm run build`
- Monitor build output for errors or warnings
- If build fails:
  - Identify the specific error(s)
  - Read error logs carefully to understand the issue
  - Fix the root cause (type errors, missing dependencies, import issues, etc.)
  - Re-run build until it succeeds
- Commit build fixes if needed: `git commit -m "Fix build errors"`

### Step 4: Identify Tracking System
- Read the PLAN.md file to find tracking references:
  - Search for JIRA ticket format (e.g., `IBIS-123`, `PROJECT-456`)
  - Look for git issue references or PR descriptions
  - Check commit messages for issue references
- Determine the tracking system to use:
  - **JIRA** if a ticket ID is found in PLAN.md
  - **Git Issue** if a git issue number is referenced
  - **Standalone PR** if neither is present

### Step 5: Check Git Status
- Run: `git status` to see all changes
- Run: `git diff --staged` to review staged changes
- Ensure all relevant changes are staged: `git add .`
- Verify the branch name aligns with the ticket (if applicable)

### Step 6: Create Pull Request

#### If using JIRA:
1. **Get JIRA Details**:
   - Use `atlassian_getAccessibleAtlassianResources` to get cloud ID
   - Note the JIRA ticket key from PLAN.md (e.g., `IBIS-123`)

2. **Get Branch Diff Summary**:
   - Run: `git diff <base-branch>...HEAD` to see full changes
   - Run: `git log <base-branch>...HEAD --oneline` for commit history

3. **Create PR via Git**:
   ```bash
   gh pr create --title "[<TICKET-KEY>] <Summary>" --body "$(cat <<'EOF'
   ## Summary
   <Bullet points describing the changes>

   ## JIRA Reference
   - Ticket: <TICKET-KEY>
   - Link: https://<jira-domain>.atlassian.net/browse/<TICKET-KEY>

   ## Changes
   - <Key change 1>
   - <Key change 2>

   ## Testing
   - Linting: Passed (`npm run lint`)
   - Build: Passed (`npm run build`)

   ## Checklist
   - [ ] Code follows project style guidelines
   - [ ] All linting errors resolved
   - [ ] Build passes without errors
   - [ ] Documentation updated
   - [ ] Self-reviewed
   EOF
   )"
   ```

4. **Add JIRA Comment**:
   - Use `atlassian_addCommentToJiraIssue` with:
     - `cloudId`: The Atlassian cloud ID
     - `issueIdOrKey`: The ticket key (e.g., `IBIS-123`)
     - `commentBody`: PR reference in Markdown format:
       ```markdown
       PR created for this ticket.

       **PR Details**:
       - Branch: <branch-name>
       - Target: <target-branch>
       - Status: Ready for review

       **Quality Checks**:
       - Linting: ✅ Passed
       - Build: ✅ Passed
       ```

#### If using Git Issue:
1. **Get Issue Details**:
   - Note the issue number from PLAN.md or commits
   - Fetch issue details: `gh issue view <issue-number>`

2. **Create PR referencing the issue**:
   ```bash
   gh pr create --title "Fix #<issue-number>: <Summary>" --body "$(cat <<'EOF'
   ## Summary
   <Bullet points describing the changes>

   ## Issue Reference
   - Resolves #<issue-number>
   - Link: <issue-url>

   ## Changes
   - <Key change 1>
   - <Key change 2>

   ## Testing
   - Linting: Passed (`npm run lint`)
   - Build: Passed (`npm run build`)

   ## Checklist
   - [ ] Code follows project style guidelines
   - [ ] All linting errors resolved
   - [ ] Build passes without errors
   - [ ] Documentation updated
   - [ ] Self-reviewed
   EOF
   )"
   ```

#### Standalone PR (no JIRA or git issue):
```bash
gh pr create --title "<Summary>" --body "$(cat <<'EOF'
## Summary
<Bullet points describing the changes>

## Changes
- <Key change 1>
- <Key change 2>

## Testing
- Linting: Passed (`npm run lint`)
- - Build: Passed (`npm run build`)

## Checklist
- [ ] Code follows project style guidelines
- [ ] All linting errors resolved
- [ ] Build passes without errors
- [ ] Documentation updated
- [ ] Self-reviewed
EOF
)"
```

### Step 7: Update PR Documentation
- Ensure the PR body is complete:
  - Clear summary of changes
  - References to JIRA/git issues
  - List of files modified
  - Testing methodology
  - Quality checks (linting, build)
- Add any necessary screenshots or diagrams
- Include links to related documentation

### Step 8: Prompt for Merge Target
After successful PR creation, ask the user:

> PR created successfully! 🎉
>
> **PR Details**:
> - Number: #<pr-number>
> - Title: <pr-title>
> - Branch: <current-branch>
> - URL: <pr-url>
>
> **Would you like to proceed with merging this PR? If yes, please specify the target branch to merge into** (e.g., `main`, `develop`, `staging`).

Wait for user response before proceeding with any merge operations.

## Example PLAN.md Integration

When your PLAN.md contains:
```markdown
# Plan: Add New Feature

## Overview
Implements a new feature for...

## JIRA Reference
IBIS-456: https://company.atlassian.net/browse/IBIS-456

## Implementation
...
```

This skill will:
1. Detect JIRA ticket `IBIS-456`
2. Run linting and build
3. Create PR with `[IBIS-456]` prefix
4. Add comment to JIRA ticket IBIS-456
5. Prompt for merge target

## Common Issues

### Linting Errors
- **Issue**: Many linting errors at once
- **Solution**: Run `npm run lint -- --fix` first, then manually fix remaining errors

### Build Failures
- **Type Errors**: Check TypeScript types and interfaces
- **Import Errors**: Verify all imports are correct and paths exist
- **Missing Dependencies**: Run `npm install` to ensure all dependencies are installed
- **Environment Variables**: Check `.env.local` or environment configuration

### JIRA Integration
- **Permission Denied**: Ensure your account has JIRA access and comment permissions
- **Cloud ID Not Found**: Use `atlassian_getAccessibleAtlassianResources` to locate it
- **Ticket Not Found**: Verify the ticket key exists and is accessible

### Git Issues
- **Branch Diverged**: Rebase with `git rebase <base-branch>` before PR creation
- **Unstaged Changes**: Ensure all changes are committed before PR
- **No gh CLI**: Install GitHub CLI: `https://cli.github.com/`

## Best Practices

- Always run linting and building before creating any PR
- Keep PRs focused and small (ideally < 400 lines changed)
- Write clear, descriptive PR titles that include ticket numbers
- Include the quality check status in every PR (linting ✓, build ✓)
- Add JIRA comments immediately after PR creation for traceability
- Never skip the build step - it catches production-breaking issues
- Commit linting and build fixes separately for clarity
- Use semantic branch names (e.g., `feature/IBIS-456-add-component`)
- Review your own changes before submitting PR

## Troubleshooting Checklist

Before creating PR:
- [ ] `npm run lint` passes with no errors
- [ ] `npm run build` completes successfully
- [ ] All changes are committed and staged
- [ ] Branch is up to date with target branch
- [ ] PLAN.md is updated if implementation changed
- [ ] JIRA ticket or git issue reference is identified
- [ ] PR body includes all necessary documentation

## Related Skills

- `jira-git-workflow`: For creating JIRA tickets and initial PLAN.md setup
