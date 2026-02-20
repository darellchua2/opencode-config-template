# Plan: Remove duplicated sections from skill files

## Overview
Clean up duplicate section headers in SKILL.md files to improve consistency and readability.

## Issue Reference
- Issue: #67
- URL: https://github.com/darellchua2/opencode-config-template/issues/67
- Labels: enhancement, documentation
- Branch: issue-67

## Analysis Results

After reviewing all 8 flagged files, only **1 file** had true duplicates:

| File | Status | Action |
|------|--------|--------|
| `skills/nextjs-pr-workflow/SKILL.md` | ✅ FIXED | Removed 2 duplicate `## When to use me` sections |
| `skills/opencode-skill-creation/SKILL.md` | ✅ No action | "Duplicates" are in template examples (intentional) |
| `skills/coverage-readme-workflow/SKILL.md` | ✅ No action | `## Test Coverage` is in README template example |
| `skills/git-issue-plan-workflow/SKILL.md` | ✅ No action | Headers are in issue body template example |
| `skills/git-issue-updater/SKILL.md` | ✅ No action | `## Progress Update` is in comment template example |
| `skills/git-pr-creator/SKILL.md` | ✅ No action | `## Pull Request Created` is in comment template |
| `skills/jira-ticket-plan-workflow/SKILL.md` | ✅ No action | Headers are in ticket description template |
| `skills/opencode-skills-maintainer/SKILL.md` | ✅ No action | Headers are in report template example |

## Implementation Phases

### Phase 1: Analysis ✅ COMPLETE
- [x] Read all flagged skill files
- [x] Identify which duplicates are actual duplicates vs template examples
- [x] Determine that only `nextjs-pr-workflow/SKILL.md` needs fixing

### Phase 2: Fix True Duplicates ✅ COMPLETE
- [x] Remove duplicate `## When to use me` sections from nextjs-pr-workflow

### Phase 3: Validation ✅ COMPLETE
- [x] Verify fix applied correctly
- [x] Confirm template examples are preserved
- [x] No content loss

## Success Criteria
- [x] True duplicate sections removed from nextjs-pr-workflow
- [x] Template examples preserved (intentional "duplicates" in code blocks)
- [x] No content loss during consolidation

## Notes
- The grep-based detection flagged headers inside markdown code blocks (template examples)
- These are intentional and should NOT be removed
- Only actual duplicate sections outside code blocks should be removed
- `nextjs-pr-workflow/SKILL.md` had the same `## When to use me` content repeated 3 times outside code blocks
