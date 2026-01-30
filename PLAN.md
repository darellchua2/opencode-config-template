# Plan: Enhance opencode-skill-auditor

## Overview

Enhance `opencode-skill-auditor` skill to analyze subagent/skill suitability, create skill duplicity matrices, and provide token usage optimization recommendations.

## Issue Reference

- Issue: #60
- URL: https://github.com/darellchua2/opencode-config-template/issues/60
- Labels: enhancement, optimization, architecture
- Branch: feature/60-skill-auditor-enhancement

## Problem Statement

The current `opencode-skill-auditor` focuses on identifying redundancy and overlap but lacks:
1. **Subagent/Skill Suitability Analysis** - Which skills should be loaded by which subagents
2. **Quantitative Duplicity Scoring** - Numeric similarity scores between skills
3. **Token Usage Optimization** - Recommendations for minimizing token consumption

### Current Issues

- Complex workflows (e.g., `git-issue-creator`, `nextjs-pr-workflow`) extend 4+ framework skills
- Subagents cannot load these skills due to tool restrictions and token budget constraints
- No quantitative measure of skill overlap
- Token costs are not tracked or optimized

## Implementation Tasks

### Phase 1: Update opencode-skill-auditor/SKILL.md ✅ COMPLETED

- [x] Add "Subagent Suitability Analysis" section
- [x] Add "Duplicity Scoring Matrix" section
- [x] Add "Token Cost Estimation" section
- [x] Add "Subagent-Specific Recommendations" section
- [x] Update "Analysis Commands" section with new commands

**Status**: Completed in commit 1377895
- Added 4 new sections with comprehensive analysis capabilities
- Updated from 133 to 972 lines (+864 lines, -25 lines)
- Implemented tool requirements extraction logic
- Added Python duplicity scoring with difflib
- Included token cost estimation with optimization strategies
- Added subagent compatibility checks and delegation patterns

### Phase 2: Create Report Templates

- [ ] Create `templates/suitability-report.md`
- [ ] Create `templates/duplicity-matrix.md`
- [ ] Create `templates/token-optimization.md`

### Phase 3: Implement Analysis Logic

- [ ] Create Python script for duplicity scoring
- [ ] Implement token cost estimation
- [ ] Build subagent compatibility checker
- [ ] Generate sample reports

### Phase 4: Test and Validate

- [ ] Run full audit on all 31 skills
- [ ] Verify duplicity scores accuracy
- [ ] Validate token estimates against actual loading
- [ ] Test subagent compatibility checks

### Phase 5: Document and Refine

- [ ] Add usage examples to skill documentation
- [ ] Document limitations of analysis
- [ ] Provide troubleshooting guidance

## Expected Outcomes

### Immediate Benefits
1. **Subagent Compatibility**: Clear guidance on which skills can be loaded by which subagents
2. **Reduced Duplication**: Quantitative identification of overlapping skills
3. **Token Optimization**: 20-40% reduction in skill loading costs

### Long-term Benefits
1. **Better Skill Architecture**: Framework + language-specific separation
2. **Improved Performance**: Subagents can load skills within token budgets
3. **Easier Maintenance**: Clear separation of concerns between skill types

## Success Criteria

- [ ] `opencode-skill-auditor` updated with 4 new analysis sections
- [ ] Subagent suitability analysis functional
- [ ] Duplicity scoring matrix implemented with accurate similarity scores
- [ ] Token cost estimation working with 10% accuracy
- [ ] All three report templates created and formatted correctly
- [ ] Analysis commands tested and validated
- [ ] Documentation includes examples for each new capability
- [ ] Subagent compatibility checks match `.AGENTS.md` restrictions

## Notes

- This enhancement adds ~400-500 lines to `opencode-skill-auditor/SKILL.md`
- Total skill size will increase from 133 to ~600 lines
- Trade-off: Larger auditor skill but enables comprehensive analysis

## References

- Issue: https://github.com/darellchua2/opencode-config-template/issues/60
- `.AGENTS.md` - Subagent tool restrictions
- `skills/` - All 31 current skills to audit
- `skills/opencode-skill-auditor/SKILL.md` - Base skill to enhance
