# [1.7.0](https://github.com/darellchua2/opencode-config-template/compare/v1.6.0...v1.7.0) (2026-01-25)


### Features

* update nextjs standard setup with npx, React compiler, and src directory ([7d0be3e](https://github.com/darellchua2/opencode-config-template/commit/7d0be3ebf152e727a5552757842f2c19b1ddfd9b)), closes [#issue-id](https://github.com/darellchua2/opencode-config-template/issues/issue-id)

# [1.6.0](https://github.com/darellchua2/opencode-config-template/compare/v1.5.0...v1.6.0) (2026-01-25)


### Features

* implement hardcoded skill list approach for agent discovery ([b94380d](https://github.com/darellchua2/opencode-config-template/commit/b94380d94a9749b1fea8f5c5093207fe7b57ed7b))

# [1.5.0](https://github.com/darellchua2/opencode-config-template/compare/v1.4.0...v1.5.0) (2026-01-25)


### Features

* enforce named exports for custom components in nextjs-standard-setup skill ([9de4dad](https://github.com/darellchua2/opencode-config-template/commit/9de4dade96ec43290c15241d019dc7f560238746)), closes [#42](https://github.com/darellchua2/opencode-config-template/issues/42)

# [1.4.0](https://github.com/darellchua2/opencode-config-template/compare/v1.3.0...v1.4.0) (2026-01-25)


### Features

* add Plan-With-Skills agent and optimized skill index ([ee00dee](https://github.com/darellchua2/opencode-config-template/commit/ee00dee8cb69695bfaee66dab1ae063ea329a0a6)), closes [#109](https://github.com/darellchua2/opencode-config-template/issues/109)

# [1.3.0](https://github.com/darellchua2/opencode-config-template/compare/v1.2.0...v1.3.0) (2026-01-24)


### Features

* integrate coverage-readme-workflow with existing skills ([f7f9b6d](https://github.com/darellchua2/opencode-config-template/commit/f7f9b6d2a914f18a3dd8a2c716fb0cb4a1cec4f6)), closes [#30](https://github.com/darellchua2/opencode-config-template/issues/30)

# [1.2.0](https://github.com/darellchua2/opencode-config-template/compare/v1.1.0...v1.2.0) (2026-01-24)


### Features

* implement docstring-generator skill and integrate with workflows ([d004927](https://github.com/darellchua2/opencode-config-template/commit/d0049275e8fbfa0460fec19f50335f83d099d67e))
* implement docstring-generator skill for multiple languages with workflow integration ([a47d25e](https://github.com/darellchua2/opencode-config-template/commit/a47d25e77356eec28de83005bfc9a59c57534ee0)), closes [#26](https://github.com/darellchua2/opencode-config-template/issues/26)

# [1.1.0](https://github.com/darellchua2/opencode-config-template/compare/v1.0.2...v1.1.0) (2026-01-24)


### Bug Fixes

* add mandatory test validation to nextjs-pr-workflow ([313b2d9](https://github.com/darellchua2/opencode-config-template/commit/313b2d98af3c8f28d3300743cf0f55c57b5e645f))


### Features

* implement Next.js 16 Unit Test Creator skill with mandatory test validation ([3ad6450](https://github.com/darellchua2/opencode-config-template/commit/3ad64502345c56f37bb53c24fffd4c1aab3b9a02)), closes [#24](https://github.com/darellchua2/opencode-config-template/issues/24)
* update nextjs unit test creator skill for nextjs 16 ([9ec98a5](https://github.com/darellchua2/opencode-config-template/commit/9ec98a5cc10325a404db9d0e535a6ae05597f896))

## [1.0.2](https://github.com/darellchua2/opencode-config-template/compare/v1.0.1...v1.0.2) (2026-01-24)


### Bug Fixes

* configure git authentication for VERSION bump step ([68f29b2](https://github.com/darellchua2/opencode-config-template/commit/68f29b2ba25095f8f392c600c1d596ca2e384814))
* correct initial version to 1.0.1 for consistency ([29154c6](https://github.com/darellchua2/opencode-config-template/commit/29154c61d267bf57778be32d4861990b1a5b0e4b))
* install semantic-release plugins before running release ([6b013d2](https://github.com/darellchua2/opencode-config-template/commit/6b013d2b79e2c4aa9e0444cc6ae44bfe472de3ca))
* remove Node.js setup and use npx directly ([80e38b5](https://github.com/darellchua2/opencode-config-template/commit/80e38b5503a39fc01f2351a3595ded430565520d))
* use semantic-release exec plugin to sync VERSION file ([d6d3e37](https://github.com/darellchua2/opencode-config-template/commit/d6d3e379c99a4842f7f0f6869e342c8fb89ecc70))

## [1.0.1](https://github.com/darellchua2/opencode-config-template/compare/v1.0.0...v1.0.1) (2026-01-24)


### Bug Fixes

* simplify semantic-release config to fix repository undefined error ([7d5a0c3](https://github.com/darellchua2/opencode-config-template/commit/7d5a0c3ebc4543c14eec71266335a5151e209fa8))

# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).



# 1.0.0 (2026-01-24)

## [2.0.0] - 2026-01-24

### Added
- Framework-based skills architecture with 5 reusable framework skills:
  - `test-generator-framework` - Generic test generation for multiple languages
  - `jira-git-integration` - JIRA + Git workflow utilities
  - `pr-creation-workflow` - Generic pull request creation
  - `ticket-branch-workflow` - Generic ticket-to-branch workflow
  - `linting-workflow` - Generic linting for multiple languages

- 11 Specialized skills that use frameworks:
  - `ascii-diagram-creator` - Create ASCII diagrams
  - `git-issue-creator` - GitHub issue creation with tag detection
  - `git-pr-creator` - GitHub pull requests with JIRA integration
  - `jira-git-workflow` - JIRA ticket creation and branching
  - `nextjs-pr-workflow` - Next.js PR workflow with JIRA
  - `nextjs-unit-test-creator` - Generate unit/E2E tests for Next.js
  - `opencode-agent-creation` - Generate OpenCode agents
  - `opencode-skill-creation` - Generate OpenCode skills
  - `python-pytest-creator` - Generate pytest tests for Python
  - `python-ruff-linter` - Python linting with Ruff
  - `typescript-dry-principle` - Apply DRY to TypeScript

- `build-with-skills` agent - Primary agent that identifies and uses appropriate skills
- VERSION file for version management
- GitHub Actions workflow for automated semantic releases
- Comprehensive README documentation of framework-based architecture

### Changed
- Refactored skills to eliminate ~2,143 lines of duplication
- Moved version from setup.sh to dedicated VERSION file
- Updated setup.sh to read version from VERSION file
- Improved documentation with interaction flows and examples

### Removed
- `SKILLS_AUDIT_REPORT.md` - No longer needed after refactoring

### Fixed
- Version display in setup.sh now reads from VERSION file
- Improved error handling and logging in setup.sh

## [1.0.0] - 2026-01-XX

### Added
- Initial release of OpenCode configuration template
- Basic configuration for LM Studio, JIRA/Confluence integration, and Z.AI services
- Initial set of workflow skills
- Setup script for automated installation

---

### Version Bumping Rules

- `feat:` - Triggers minor version bump (x.Y.z)
- `fix:` - Triggers patch version bump (x.y.Z)
- `BREAKING CHANGE:` - Triggers major version bump (X.y.z)
- `chore:`, `docs:`, `style:`, `refactor:`, `test:` - No version bump

### Conventional Commits Format

```
<type>(<scope>): <subject>

<body>

<footer>
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `chore`: Maintenance task
- `docs`: Documentation changes
- `style`: Code style changes
- `refactor`: Code refactoring
- `test`: Test additions/changes
- `perf`: Performance improvements
- `BREAKING CHANGE`: Breaking changes (major version bump)

**Examples:**
```
feat: add semantic release workflow with GitHub Actions

fix: correct version reading from VERSION file in setup.sh

docs: update README with framework-based skills documentation

chore: remove unused SKILLS_AUDIT_REPORT.md file
```
