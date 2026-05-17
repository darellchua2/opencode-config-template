# PLAN-GIT-182: Update GitHub Actions to Latest Major Versions

**Issue**: [#182](https://github.com/darellchua2/opencode-config-template/issues/182)
**Branch**: `chore/182-update-github-actions`
**Type**: chore (dependencies)
**Priority**: medium

## Overview

GitHub Actions running on Node.js 20 will be forced to Node.js 24 starting **June 2, 2026**. Update all actions in `.github/workflows/release.yml` to their latest major versions to stay ahead of the deprecation.

## Scope

| File | Change |
|------|--------|
| `.github/workflows/release.yml` | Update 3 action versions |

## Action Updates

| Action | Current | Target | Line |
|--------|---------|--------|------|
| `actions/checkout` | `@v4` | `@v6` | 24 |
| `actions/setup-node` | `@v4` | `@v6` | 41 |
| `actions/upload-artifact` | `@v4` | `@v7` | 72 |

## Phases

### Phase 1: Update Action Versions
- [ ] Verify latest major versions on GitHub Marketplace
- [ ] Update `actions/checkout@v4` → `@v6` (line 24)
- [ ] Update `actions/setup-node@v4` → `@v6` (line 41)
- [ ] Update `actions/upload-artifact@v4` → `@v7` (line 72)
- [ ] Update `setup-node` `node-version` from `'20'` to `'24'`

### Phase 2: Validate & Push
- [ ] Verify YAML syntax is valid
- [ ] Commit with semantic message
- [ ] Push branch to remote

### Phase 3: Create Pull Request
- [ ] Create PR targeting `main`
- [ ] Reference issue #182 in PR body
- [ ] Verify CI workflow triggers and passes on the PR

## Acceptance Criteria

- [ ] All three actions updated to latest major version
- [ ] `setup-node` node-version updated to `24`
- [ ] Release workflow YAML is syntactically valid
- [ ] PR created and CI passes

## Risks

| Risk | Mitigation |
|------|------------|
| v6/v7 breaking changes | Verified on GitHub Marketplace; reviewed release notes |
| CI fails after update | PR-based validation catches issues before merge |
| CI fails after update | PR-based validation catches issues before merge |

## References

- [GitHub Actions Node.js 20 deprecation](https://github.blog/changelog/2025-05-08-actions-node20-deprecation/)
- [actions/checkout](https://github.com/actions/checkout/releases)
- [actions/setup-node](https://github.com/actions/setup-node/releases)
- [actions/upload-artifact](https://github.com/actions/upload-artifact/releases)
