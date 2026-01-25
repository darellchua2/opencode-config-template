# Plan: Update nextjs standard setup with npx, React compiler, and src directory

## Overview
Update the nextjs-standard-setup skill to always use npx setup, integrate React Compiler, and configure the src directory with path aliases for modern Next.js 16 development. Additionally, update opencode-skill-creation to always use the read tool before updating PLAN.md files.

## Issue Reference
- Issue: #45
- URL: https://github.com/darellchua2/opencode-config-template/issues/45
- Labels: enhancement

## Files to Modify
1. `skills/nextjs-standard-setup/SKILL.md` - Update workflow steps to include npx, React Compiler, and src directory
2. `skills/opencode-skill-creation/SKILL.md` - Add requirement to use read tool before updating PLAN.md
3. `skills/git-issue-assessor/SKILL.md` - Rename to git-issue-labeler
4. `skills/git-issue-creator/SKILL.md` - Streamline to use git-issue-labeler
5. `skills/ticket-branch-workflow/SKILL.md` - Streamline to use git-issue-labeler
6. `skills/git-semantic-commits/SKILL.md` - NEW SKILL for semantic commit message formatting
7. `skills/git-issue-updater/SKILL.md` - NEW SKILL for updating issues after commits
8. Skills may need additional example files or templates updated

## Approach
Detailed steps for implementation:

1. **Update SKILL.md Documentation**
   - Review current workflow steps in skills/nextjs-standard-setup/SKILL.md
   - Modify all setup commands to use `npx -y` prefix
   - Add React Compiler configuration instructions
   - Add src directory structure guidelines
   - Update path alias configuration (tsconfig.json paths)

2. **Add React Compiler Configuration**
   - Include next.config.ts configuration for React Compiler:
     ```typescript
     const nextConfig = {
       experimental: {
         reactCompiler: true,
       },
     }
     ```
   - Document compiler benefits and requirements

3. **Configure Path Aliases**
   - Add tsconfig.json configuration for src directory:
     ```json
     {
       "compilerOptions": {
         "baseUrl": ".",
         "paths": {
           "@/*": ["./src/*"]
         }
       }
     }
     ```
   - Update import examples to use @/ prefix

4. **Update Project Structure**
   - Document src directory layout: src/app, src/components, src/lib, src/types, etc.
   - Update all folder structure examples
   - Ensure consistency throughout documentation

5. **Update Examples and Templates**
   - Modify any code examples to use npx commands
   - Update import statements in examples to use path aliases
   - Add React Compiler compatibility notes

6. **Update opencode-skill-creation**
   - Read skills/opencode-skill-creation/SKILL.md
   - Add explicit instruction to always use the read tool before updating PLAN.md
   - Document the importance of reading existing files to avoid data loss
   - Add to best practices section
   - Update any examples that show PLAN.md creation or updates

7. **Rename and Create git-issue-labeler**
   - Rename git-issue-assessor to git-issue-labeler
   - Move skills/git-issue-assessor/ to skills/git-issue-labeler/
   - Update all references in related skills to use git-issue-labeler
   - Update skill name and frontmatter in SKILL.md
   - Test that the renamed skill can be invoked correctly

8. **Create git-semantic-commits Skill**
   - Use opencode-skill-creation to create new skill
   - Implement semantic commit message formatting (Conventional Commits spec)
   - Support commit types: feat, fix, docs, style, refactor, test, chore, perf, ci, build, revert
   - Add scope support (e.g., feat(api): add authentication)
   - Add breaking change indicator (!)
   - Add body and footer support
   - Provide commit message validation
   - Include commit message examples for each type
   - Document versioning implications (MAJOR.MINOR.PATCH)

9. **Create git-issue-updater Skill**
   - Use opencode-skill-creation to create new skill
   - Implement issue update functionality for GitHub and JIRA
   - Extract latest commit details: hash, message, author, date, time, files changed
   - Format comment with consistent documentation: user, date, time, changes summary
   - Support both GitHub issues and JIRA tickets
   - Include commit link (GitHub) or commit hash (JIRA)
   - Provide update templates for different commit types
   - Add support for incremental progress updates
   - Include verification step to confirm issue comment was added

10. **Assess Git Workflows for Issue Updates**
   - Review git-issue-creator - needs to add issue comment after initial commit
   - Review ticket-branch-workflow - needs to add issue comment after PLAN.md commit
   - Review jira-git-workflow - needs to add ticket comment after initial commit
   - Review git-pr-creator - needs to add issue comment when PR is ready
   - Review nextjs-pr-workflow - needs to add issue comment for PR creation
   - Identify all skills that create commits and would benefit from issue updates
   - Update related skills to use git-issue-updater for progress tracking

11. **Assess Git Workflows for Commit Type Awareness**
   - Review git-issue-creator - needs semantic commit support for PLAN.md commit
   - Review ticket-branch-workflow - needs semantic commit support for PLAN.md commit
   - Review git-pr-creator - needs semantic commit support for PR titles
   - Review nextjs-pr-workflow - needs semantic commit support
   - Identify all skills that create commits or PRs
   - Update related skills to use git-semantic-commits for formatting

10. **Streamline Git-Related Skills** ✅ DONE
   - Analyze git-issue-creator and ticket-branch-workflow for label detection overlap
   - Refactor to use git-issue-labeler as a shared framework skill
   - Remove duplicate label detection logic from git-issue-creator ✅ DONE
   - Remove duplicate label detection logic from ticket-branch-workflow ✅ DONE
   - Ensure both skills delegate to git-issue-labeler for label assessment
   - Update related skills sections to reference git-issue-labeler
   - Test streamlined workflow end-to-end

11. **Assess and Update jira-git-workflow** ⏳ PENDING
   - Review jira-git-workflow for commit message formatting
   - Use git-semantic-commits for commit formatting
   - Use git-issue-updater for issue comment after commits
   - Update related skills sections to reference new frameworks

12. **Assess and Update git-pr-creator** ⏳ PENDING
   - Review for commit message formatting needs
   - Use git-semantic-commits for commit formatting
   - Use git-issue-updater for issue comments after PRs (if applicable)
   - Update related skills sections

13. **Testing and Validation**
   - Test the updated skill end-to-end
   - Verify npx commands work correctly
   - Validate React Compiler configuration
   - Ensure path aliases resolve properly
   - Test that opencode-skill-creation reads PLAN.md before updating
   - Verify no data loss occurs when updating existing PLAN.md files
   - Test git-issue-labeler with various issue types
   - Test git-semantic-commits with all commit types
   - Test git-issue-updater with GitHub issues
   - Test git-issue-updater with JIRA tickets
   - Verify issue comments include user, date, time, and changes
   - Verify streamlined git workflows work correctly
   - Validate all skills use semantic commit formatting
   - Validate all skills use git-issue-updater for progress tracking

## Success Criteria
- [ ] All setup commands in SKILL.md use `npx -y` prefix
- [ ] React Compiler configuration is documented and functional
- [ ] tsconfig.json path alias configuration is included
- [ ] src directory structure is clearly documented
- [ ] All examples demonstrate the new setup approach
- [ ] Documentation is comprehensive and easy to follow
- [ ] git-issue-assessor renamed to git-issue-labeler
- [ ] git-issue-labeler can be invoked correctly
- [ ] git-semantic-commits skill created
- [ ] git-semantic-commits supports all commit types (feat, fix, docs, style, refactor, test, chore, perf, ci, build, revert)
- [ ] git-semantic-commits includes scope and breaking change support
- [ ] git-semantic-commits provides commit message validation
- [ ] git-issue-updater skill created
- [ ] git-issue-updater supports GitHub issues
- [ ] git-issue-updater supports JIRA tickets
- [ ] git-issue-updater includes user, date, time in comments
- [ ] git-issue-updater provides consistent documentation format
- [ ] All git-related skills assessed for commit type awareness
- [ ] All git-related skills assessed for issue update needs
- [ ] git-issue-creator uses git-semantic-commits for commit formatting
- [ ] git-issue-creator uses git-issue-updater for issue comments
- [ ] ticket-branch-workflow uses git-semantic-commits for commit formatting
- [ ] ticket-branch-workflow uses git-issue-updater for issue comments
- [ ] jira-git-workflow uses git-semantic-commits for commit formatting
- [ ] jira-git-workflow uses git-issue-updater for ticket comments
- [ ] git-pr-creator uses git-semantic-commits for PR title formatting
- [ ] git-pr-creator uses git-issue-updater for issue updates (when linked)
- [ ] nextjs-pr-workflow uses git-semantic-commits for commit formatting
- [ ] nextjs-pr-workflow uses git-issue-updater for issue updates (when linked)
- [ ] git-issue-creator uses git-issue-labeler for label detection
- [ ] ticket-branch-workflow uses git-issue-labeler for label detection
- [ ] Duplicate label detection logic removed from git-issue-creator
- [ ] Duplicate label detection logic removed from ticket-branch-workflow
- [ ] Testing confirms all workflows work correctly
- [ ] All commit messages follow semantic conventions
- [ ] All issue comments are consistent with user, date, time
- [ ] Versioning implications documented clearly

## Notes
- React Compiler requires Next.js 16 or later
- Path aliases improve code organization and import readability
- npx -y ensures zero-install experience without prompts
- Maintain backward compatibility if possible, but prioritize modern best practices
- Consider adding troubleshooting section for common setup issues
- git-issue-labeler should use GitHub default labels: bug, enhancement, documentation, duplicate, good first issue, help wanted, invalid, question, wontfix
- Streamlining git skills will reduce maintenance burden and improve consistency
- After renaming git-issue-assessor to git-issue-labeler, run opencode-skills-maintainer to update agents
- git-semantic-commits should follow Conventional Commits specification: https://www.conventionalcommits.org/
- Semantic commit types affect versioning: feat (MINOR), fix (PATCH), breaking change (MAJOR)
- Scope helps identify which part of project is affected (e.g., feat(api):, fix(ui):)
- Breaking changes indicated by ! after type/scope or BREAKING CHANGE: in footer
- All git-related skills that create commits or PRs should use git-semantic-commits for formatting
- Consistent commit formatting enables automated changelog generation and versioning tools
- git-issue-updater should include consistent fields: user, date, time, commit hash, commit message, files changed
- Issue updates provide traceability and maintain consistency in project documentation
- All git-related skills that create commits should use git-issue-updater for progress tracking
- GitHub issue updates use gh issue comment command
- JIRA ticket updates use atlassian_addCommentToJiraIssue command
- Date and time should use ISO 8601 format or consistent timezone (e.g., UTC)
- User information should be extracted from git config or gh CLI for GitHub
- Issue comments should link to commits for easy reference
- Multiple commits can be consolidated into a single progress update if appropriate
