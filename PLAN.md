# Plan: Add semantic releases with GitHub Actions

## Overview
Implement automated semantic releases for the repository using GitHub Actions. This will automatically package and publish releases when code is merged to the main branch, following semantic versioning conventions.

## Issue Reference
- Issue: #22
- URL: https://github.com/darellchua2/opencode-config-template/issues/22
- Labels: enhancement

## Files to Modify
1. `.releaserc.json` - Semantic release configuration
2. `.github/workflows/release.yml` - GitHub Actions workflow for automated releases
3. `package.json` - Add semantic-release as dev dependency (if not exists)
4. `CHANGELOG.md` - Auto-generated changelog (will be updated by semantic-release)
5. `README.md` - Document the release process

## Files to Create
1. `.releaserc.json` - Configuration for semantic release
2. `.github/workflows/release.yml` - GitHub Actions workflow file
3. `CHANGELOG.md` - Initial changelog file

## Approach
Detailed steps or implementation methodology:

1. **Step 1: Configure Semantic Release**
   - Create `.releaserc.json` with appropriate configuration
   - Configure branches to trigger on (main)
   - Set up release rules for different commit types
   - Configure changelog generation

2. **Step 2: Create GitHub Actions Workflow**
   - Create `.github/workflows/release.yml`
   - Set up trigger for push to main branch
   - Configure steps:
     - Checkout code
     - Setup Node.js
     - Install dependencies
     - Run semantic release
   - Add permissions for creating releases

3. **Step 3: Update Dependencies**
   - Add semantic-release and plugins to package.json
   - If package.json doesn't exist, create minimal package.json for config template
   - Configure necessary plugins (changelog, git, etc.)

4. **Step 4: Configure Commit Conventions**
   - Document conventional commit format in README
   - Provide examples of commit messages
   - Explain version bumping rules

5. **Step 5: Testing**
   - Create a test commit with conventional format
   - Merge to main and verify workflow runs
   - Verify release is created with correct version
   - Verify CHANGELOG.md is updated

6. **Step 6: Documentation**
   - Update README.md with release process documentation
   - Include instructions for contributors
   - Document how to create a release

## Success Criteria
- [ ] Semantic release configuration file created (.releaserc.json)
- [ ] GitHub Actions workflow file created (.github/workflows/release.yml)
- [ ] Workflow triggers correctly on push to main
- [ ] Release is created with correct semantic version
- [ ] CHANGELOG.md is automatically generated and updated
- [ ] Release notes include relevant commit messages
- [ ] README.md documents the release process
- [ ] Testing confirms workflow works end-to-end

## Notes
- This is a configuration template repository, so package.json may not exist
- If package.json is needed, create minimal version only for semantic-release
- Ensure the workflow has proper permissions to create releases
- Use conventional commits format: `feat:`, `fix:`, `chore:`, `docs:`, etc.
- Version bumping rules:
  - `feat:` triggers minor version bump (x.Y.z)
  - `fix:` triggers patch version bump (x.y.Z)
  - `BREAKING CHANGE:` triggers major version bump (X.y.z)
  - Other types don't trigger releases
- Consider adding `.github/CONTRIBUTING.md` with commit guidelines
- The workflow should only run on main branch pushes, not PRs
