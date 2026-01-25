# Plan: Update nextjs standard setup with npx, React compiler, and src directory

## Overview
Update the nextjs-standard-setup skill to always use npx setup, integrate React Compiler, and configure the src directory with path aliases for modern Next.js 16 development.

## Issue Reference
- Issue: #45
- URL: https://github.com/darellchua2/opencode-config-template/issues/45
- Labels: enhancement

## Files to Modify
1. `skills/nextjs-standard-setup/SKILL.md` - Update workflow steps to include npx, React Compiler, and src directory
2. Skills may need additional example files or templates updated

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

6. **Testing and Validation**
   - Test the updated skill end-to-end
   - Verify npx commands work correctly
   - Validate React Compiler configuration
   - Ensure path aliases resolve properly

## Success Criteria
- [ ] All setup commands in SKILL.md use `npx -y` prefix
- [ ] React Compiler configuration is documented and functional
- [ ] tsconfig.json path alias configuration is included
- [ ] src directory structure is clearly documented
- [ ] All examples demonstrate the new setup approach
- [ ] Documentation is comprehensive and easy to follow
- [ ] Testing confirms the setup works correctly

## Notes
- React Compiler requires Next.js 16 or later
- Path aliases improve code organization and import readability
- npx -y ensures zero-install experience without prompts
- Maintain backward compatibility if possible, but prioritize modern best practices
- Consider adding troubleshooting section for common setup issues
