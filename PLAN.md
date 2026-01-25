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
6. Skills may need additional example files or templates updated

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

8. **Streamline Git-Related Skills**
   - Analyze git-issue-creator and ticket-branch-workflow for label detection overlap
   - Refactor to use git-issue-labeler as a shared framework skill
   - Remove duplicate label detection logic from git-issue-creator
   - Remove duplicate label detection logic from ticket-branch-workflow
   - Ensure both skills delegate to git-issue-labeler for label assessment
   - Update related skills sections to reference git-issue-labeler
   - Test streamlined workflow end-to-end

9. **Testing and Validation**
   - Test the updated skill end-to-end
   - Verify npx commands work correctly
   - Validate React Compiler configuration
   - Ensure path aliases resolve properly
   - Test that opencode-skill-creation reads PLAN.md before updating
   - Verify no data loss occurs when updating existing PLAN.md files
   - Test git-issue-labeler with various issue types
   - Verify streamlined git workflows work correctly

## Success Criteria
- [ ] All setup commands in SKILL.md use `npx -y` prefix
- [ ] React Compiler configuration is documented and functional
- [ ] tsconfig.json path alias configuration is included
- [ ] src directory structure is clearly documented
- [ ] All examples demonstrate the new setup approach
- [ ] Documentation is comprehensive and easy to follow
- [ ] git-issue-assessor renamed to git-issue-labeler
- [ ] git-issue-labeler can be invoked correctly
- [ ] git-issue-creator uses git-issue-labeler for label detection
- [ ] ticket-branch-workflow uses git-issue-labeler for label detection
- [ ] Duplicate label detection logic removed from git-issue-creator
- [ ] Duplicate label detection logic removed from ticket-branch-workflow
- [ ] Testing confirms all workflows work correctly

## Notes
- React Compiler requires Next.js 16 or later
- Path aliases improve code organization and import readability
- npx -y ensures zero-install experience without prompts
- Maintain backward compatibility if possible, but prioritize modern best practices
- Consider adding troubleshooting section for common setup issues
- git-issue-labeler should use GitHub default labels: bug, enhancement, documentation, duplicate, good first issue, help wanted, invalid, question, wontfix
- Streamlining git skills will reduce maintenance burden and improve consistency
- After renaming git-issue-assessor to git-issue-labeler, run opencode-skills-maintainer to update agents
