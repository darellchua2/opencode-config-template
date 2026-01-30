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

### Phase 2: Create Report Templates ✅ COMPLETED

- [x] Create `templates/suitability-report.md`
- [x] Create `templates/duplicity-matrix.md`
- [x] Create `templates/token-optimization.md`

**Status**: Completed in commit efb82f7
- Created templates/suitability-report.md (316 lines)
  - Subagent compatibility matrix
  - Tool requirements analysis
  - Budget allocation recommendations
- Created templates/duplicity-matrix.md (213 lines)
  - Full similarity matrix
  - High/medium duplicity pair tables
  - Consolidation recommendations
- Created templates/token-optimization.md (446 lines)
  - Token cost breakdown
  - 6 optimization strategies
  - Subagent-specific budget optimization

Templates use {{VARIABLE}} placeholders for dynamic content generation.

### Phase 3: Implement Analysis Logic ✅ COMPLETED

- [x] Create Python script for duplicity scoring
- [x] Implement token cost estimation
- [x] Build subagent compatibility checker
- [x] Generate sample reports

**Status**: Completed in commit e75a148
- Created analyze.py (898 lines) - Comprehensive Python analysis engine
- SkillAuditor class with methods for all analyses:
  - load_all_skills(): Extract and parse skills
  - calculate_duplicity_matrix(): Weighted similarity scoring
  - estimate_tokens(): Token cost calculation
  - analyze_token_costs(): Identify critical/oversized skills
  - check_subagent_compatibility(): Subagent validation
  - generate_*_report(): Automated report generation
- CLI interface with argparse (--all, --suitability, --duplicity, --tokens)
- Generated sample reports (reports/):
  - suitability_report_*.md (384 lines)
  - duplicity_report_*.md (247 lines)
  - token_report_*.md (536 lines)
- Created README.md (266 lines) with usage documentation

Analysis Results (34 skills):
- Duplicity: 0 high (≥70%), 2 moderate (50-69%), 559 low (<50%) pairs
- Tokens: 150,870 total, 4,437 avg, 23 critical (>3000), 28 oversized (>2000)
- Subagent: 100% primary, 64-76% subagent compatibility

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
