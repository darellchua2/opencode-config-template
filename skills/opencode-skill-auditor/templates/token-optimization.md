# Token Cost Estimation & Optimization Report

**Generated**: {{GENERATION_DATE}}
**Auditor Version**: opencode-skill-auditor v{{VERSION}}
**Skills Analyzed**: {{NUM_SKILLS}}
**Token Rate**: ~4 characters/token (industry standard)

---

## Executive Summary

This report analyzes token consumption across {{NUM_SKILLS}} OpenCode skills, identifying optimization opportunities to reduce skill loading costs. The analysis provides token estimates, identifies oversized skills, and recommends optimization strategies.

### Key Metrics

- **Total Tokens**: {{TOTAL_TOKENS}} tokens ({{TOTAL_MB}} MB)
- **Average Tokens per Skill**: {{AVG_TOKENS}} tokens
- **Oversized Skills** (>2000 tokens): {{OVERSIZED_COUNT}} ({{OVERSIZED_PERCENT}}%)
- **Critical Skills** (>3000 tokens): {{CRITICAL_COUNT}} ({{CRITICAL_PERCENT}}%)
- **Estimated Optimization Potential**: {{OPTIMIZATION_POTENTIAL}}% reduction

### Budget Status

| Category | Budget | Used | Status |
|----------|--------|------|--------|
| Framework Skills | 2000 | {{FRAMEWORK_AVG}} | {{FRAMEWORK_STATUS}} |
| Language-Specific | 1500 | {{LANG_AVG}} | {{LANG_STATUS}} |
| Workflow Skills | 3000 | {{WORKFLOW_AVG}} | {{WORKFLOW_STATUS}} |

---

## Token Cost Analysis by Skill

### Overview Table

| Skill | Characters | Tokens | Status | Code Blocks | Recommendations |
|-------|------------|--------|--------|-------------|-----------------|
{{SKILL_TOKEN_TABLE}}

---

## Critical & Oversized Skills

### Critical Skills (>3000 tokens)

{{CRITICAL_SKILLS_TABLE}}

**Immediate Action Required**: These skills significantly exceed budget and should be prioritized for optimization.

---

### Oversized Skills (2000-3000 tokens)

{{OVERSIZED_SKILLS_TABLE}}

**Action Recommended**: These skills moderately exceed budget and should be optimized soon.

---

## Token Budget Breakdown

### By Skill Category

| Category | Skills | Avg Tokens | Total Tokens | % of Total |
|----------|--------|------------|--------------|------------|
| Framework | {{FRAMEWORK_COUNT}} | {{FRAMEWORK_AVG}} | {{FRAMEWORK_TOTAL}} | {{FRAMEWORK_PERCENT}}% |
| Linting | {{LINTING_COUNT}} | {{LINTING_AVG}} | {{LINTING_TOTAL}} | {{LINTING_PERCENT}}% |
| Testing | {{TESTING_COUNT}} | {{TESTING_AVG}} | {{TESTING_TOTAL}} | {{TESTING_PERCENT}}% |
| Git/JIRA | {{GIT_COUNT}} | {{GIT_AVG}} | {{GIT_TOTAL}} | {{GIT_PERCENT}}% |
| Documentation | {{DOCS_COUNT}} | {{DOCS_AVG}} | {{DOCS_TOTAL}} | {{DOCS_PERCENT}}% |
| OpenTofu | {{OPENTOFU_COUNT}} | {{OPENTOFU_AVG}} | {{OPENTOFU_TOTAL}} | {{OPENTOFU_PERCENT}}% |
| Workflow | {{WORKFLOW_COUNT}} | {{WORKFLOW_AVG}} | {{WORKFLOW_TOTAL}} | {{WORKFLOW_PERCENT}}% |
| OpenCode Meta | {{META_COUNT}} | {{META_AVG}} | {{META_TOTAL}} | {{META_PERCENT}}% |
| Project Setup | {{SETUP_COUNT}} | {{SETUP_AVG}} | {{SETUP_TOTAL}} | {{SETUP_PERCENT}}% |

---

## Optimization Opportunities

### High-Impact Targets (Potential Savings > 200 tokens)

{{HIGH_IMPACT_TARGETS}}

### Medium-Impact Targets (Potential Savings 100-200 tokens)

{{MEDIUM_IMPACT_TARGETS}}

### Low-Impact Targets (Potential Savings < 100 tokens)

{{LOW_IMPACT_TARGETS}}

---

## Optimization Strategies

### Strategy 1: Extract Code Blocks to External Files

**Potential Savings**: 20-40% reduction per affected skill

**Applicable Skills**:
{{CODE_BLOCK_SKILLS}}

**Implementation Plan**:
1. Create `examples/` directory for each skill
2. Extract bash/Python code blocks to separate files
3. Replace code blocks with file references or shorter examples
4. Keep 1-2 representative inline examples for quick reference

**Expected Impact**:
- Skills optimized: {{CODE_BLOCK_OPT_COUNT}}
- Total tokens saved: {{CODE_BLOCK_SAVINGS}} tokens
- Files created: {{CODE_BLOCK_FILES}} example files

---

### Strategy 2: Simplify Verbose Explanations

**Potential Savings**: 15-30% reduction per affected skill

**Applicable Skills**:
{{VERBOSE_SKILLS}}

**Implementation Plan**:
1. Identify verbose sections (>500 characters)
2. Replace detailed tutorials with concise step-by-step instructions
3. Move detailed explanations to separate documentation
4. Use bullet points and tables for clarity

**Expected Impact**:
- Skills optimized: {{VERBOSE_OPT_COUNT}}
- Total tokens saved: {{VERBOSE_SAVINGS}} tokens

---

### Strategy 3: Use Reference Links Instead of Duplication

**Potential Savings**: 10-25% reduction per affected skill

**Applicable Skills**:
{{DUPLICATE_SKILLS}}

**Implementation Plan**:
1. Identify duplicated content across skills
2. Extract common content to shared documentation
3. Replace duplicates with "See X skill for details" references
4. Maintain sufficient context for standalone usage

**Expected Impact**:
- Skills optimized: {{DUPLICATE_OPT_COUNT}}
- Total tokens saved: {{DUPLICATE_SAVINGS}} tokens

---

### Strategy 4: Consolidate Similar Sections

**Potential Savings**: 10-20% reduction per affected skill

**Applicable Skills**:
{{SIMILAR_SECTION_SKILLS}}

**Implementation Plan**:
1. Identify similar sections (e.g., "Common Issues", "Best Practices")
2. Consolidate redundant content
3. Use tables and lists to reduce repetition
4. Extract shared patterns to base documentation

**Expected Impact**:
- Skills optimized: {{SIMILAR_SECTION_OPT_COUNT}}
- Total tokens saved: {{SIMILAR_SECTION_SAVINGS}} tokens

---

### Strategy 5: Remove Redundant Examples

**Potential Savings**: 5-15% reduction per affected skill

**Applicable Skills**:
{{REDUNDANT_EXAMPLE_SKILLS}}

**Implementation Plan**:
1. Identify overlapping examples within a skill
2. Keep 1-2 representative examples per use case
3. Remove edge-case examples that don't add significant value
4. Reference external documentation for comprehensive examples

**Expected Impact**:
- Skills optimized: {{REDUNDANT_EXAMPLE_OPT_COUNT}}
- Total tokens saved: {{REDUNDANT_EXAMPLE_SAVINGS}} tokens

---

### Strategy 6: Minimize Frontmatter Metadata

**Potential Savings**: 2-5% reduction per affected skill

**Applicable Skills**:
{{METADATA_SKILLS}}

**Implementation Plan**:
1. Review YAML frontmatter for excessive metadata
2. Remove non-essential fields
3. Keep only: name, description, license, compatibility, metadata.audience
4. Document extended metadata in external file if needed

**Expected Impact**:
- Skills optimized: {{METADATA_OPT_COUNT}}
- Total tokens saved: {{METADATA_SAVINGS}} tokens

---

## Token Budget Optimization by Subagent

### Linting Subagent

**Budget**: 2500 tokens
**Current Load**: {{LINTING_CURRENT}} tokens
**Recommended Load**: {{LINTING_RECOMMENDED}} tokens
**Optimization Potential**: {{LINTING_POTENTIAL}}%

**Optimal Loading Strategy**:
```
load_skill linting-workflow (1438 tokens)
load_skill python-ruff-linter (estimated 1200 tokens)
load_skill javascript-eslint-linter (estimated 1200 tokens)
Total: 3838 tokens → Optimize to: ~2500 tokens
```

**Action Items**:
{{LINTING_ACTIONS}}

---

### Testing Subagent

**Budget**: 2500 tokens
**Current Load**: {{TESTING_CURRENT}} tokens
**Recommended Load**: {{TESTING_RECOMMENDED}} tokens
**Optimization Potential**: {{TESTING_POTENTIAL}}%

**Optimal Loading Strategy**:
```
load_skill test-generator-framework (estimated 1500 tokens)
load_skill python-pytest-creator (estimated 1300 tokens)
Total: 2800 tokens → Optimize to: ~2500 tokens
```

**Action Items**:
{{TESTING_ACTIONS}}

---

### Git Workflow Subagent

**Budget**: 3000 tokens
**Current Load**: {{GIT_CURRENT}} tokens
**Recommended Load**: {{GIT_RECOMMENDED}} tokens
**Optimization Potential**: {{GIT_POTENTIAL}}%

**Optimal Loading Strategy**:
```
Load pattern 1 (Issue workflows):
  load_skill git-issue-creator (estimated 2200 tokens)
  load_skill git-issue-labeler (estimated 1100 tokens)
  Total: 3300 tokens → Optimize to: ~2500 tokens

Load pattern 2 (PR workflows):
  load_skill git-pr-creator (estimated 2100 tokens)
  load_skill git-semantic-commits (estimated 1400 tokens)
  Total: 3500 tokens → Optimize to: ~2500 tokens
```

**Action Items**:
{{GIT_ACTIONS}}

---

### Documentation Subagent

**Budget**: 2000 tokens
**Current Load**: {{DOCS_CURRENT}} tokens
**Recommended Load**: {{DOCS_RECOMMENDED}} tokens
**Optimization Potential**: {{DOCS_POTENTIAL}}%

**Optimal Loading Strategy**:
```
load_skill docstring-generator (estimated 1100 tokens)
load_skill coverage-readme-workflow (estimated 1300 tokens)
Total: 2400 tokens → Optimize to: ~2000 tokens
```

**Action Items**:
{{DOCS_ACTIONS}}

---

### OpenTofu Explorer Subagent

**Budget**: 3000 tokens
**Current Load**: {{OPENTOFU_CURRENT}} tokens
**Recommended Load**: {{OPENTOFU_RECOMMENDED}} tokens
**Optimization Potential**: {{OPENTOFU_POTENTIAL}}%

**Optimal Loading Strategy**:
```
Load pattern 1 (AWS):
  load_skill opentofu-aws-explorer (estimated 1800 tokens)
  load_skill opentofu-provider-setup (estimated 1600 tokens)
  Total: 3400 tokens → Optimize to: ~2800 tokens

Load pattern 2 (Kubernetes):
  load_skill opentofu-kubernetes-explorer (estimated 1900 tokens)
  load_skill opentofu-provider-setup (estimated 1600 tokens)
  Total: 3500 tokens → Optimize to: ~2800 tokens
```

**Action Items**:
{{OPENTOFU_ACTIONS}}

---

### Workflow Subagent

**Budget**: 3000 tokens
**Current Load**: {{WORKFLOW_CURRENT}} tokens
**Recommended Load**: {{WORKFLOW_RECOMMENDED}} tokens
**Optimization Potential**: {{WORKFLOW_POTENTIAL}}%

**Optimal Loading Strategy**:
```
Load pattern 1 (Next.js PR):
  load_skill nextjs-pr-workflow (estimated 2800 tokens)
  Total: 2800 tokens → Optimize to: ~2500 tokens

Load pattern 2 (JIRA Integration):
  load_skill jira-git-workflow (estimated 2500 tokens)
  Total: 2500 tokens → Optimize to: ~2200 tokens
```

**Action Items**:
{{WORKFLOW_ACTIONS}}

---

## Action Plan

### Immediate Actions (Week 1)

{{IMMEDIATE_ACTIONS}}

### Short-term Actions (Weeks 2-4)

{{SHORT_TERM_ACTIONS}}

### Medium-term Actions (Month 2)

{{MEDIUM_TERM_ACTIONS}}

### Long-term Actions (Months 3-6)

{{LONG_TERM_ACTIONS}}

---

## Expected Outcomes

### Token Reduction Targets

| Metric | Current | Target | Reduction | Timeline |
|--------|---------|--------|-----------|----------|
| Average skill tokens | {{AVG_TOKENS}} | {{TARGET_AVG_TOKENS}} | {{AVG_REDUCTION}}% | 6 months |
| Oversized skills | {{OVERSIZED_COUNT}} | {{TARGET_OVERSIZED}} | {{OVERSIZED_REDUCTION}}% | 3 months |
| Critical skills | {{CRITICAL_COUNT}} | {{TARGET_CRITICAL}} | {{CRITICAL_REDUCTION}}% | 1 month |
| Total tokens | {{TOTAL_TOKENS}} | {{TARGET_TOTAL_TOKENS}} | {{TOTAL_REDUCTION}}% | 6 months |

### Quality Improvements

- **Maintainability**: +{{MAINTAINABILITY_GAIN}}%
- **Discoverability**: +{{DISCOVERABILITY_GAIN}}%
- **Performance**: +{{PERFORMANCE_GAIN}}%
- **User Experience**: +{{UX_GAIN}}%

---

## Best Practices for Skill Authors

### Writing Efficient Skills

1. **Keep It Concise**
   - Target <2000 tokens for framework skills
   - Target <1500 tokens for language-specific skills
   - Target <3000 tokens for workflow skills

2. **Use External References**
   - Extract code blocks to `examples/` directory
   - Reference external documentation for detailed guides
   - Use tables and lists instead of verbose text

3. **Avoid Duplication**
   - Check for overlapping content with existing skills
   - Use "See X skill" references for common patterns
   - Extract shared functionality to framework skills

4. **Optimize Examples**
   - Keep 1-2 representative examples
   - Remove edge-case examples
   - Focus on common use cases

5. **Review Frontmatter**
   - Keep only essential metadata fields
   - Document extended metadata externally
   - Use standard YAML format

---

## Appendix: Detailed Token Data

### Skill-by-Skill Breakdown

{{DETAILED_TOKEN_BREAKDOWN}}

### Code Block Analysis

{{CODE_BLOCK_ANALYSIS}}

### Line Count Analysis

{{LINE_COUNT_ANALYSIS}}

---

## Conclusion

The token optimization analysis reveals significant opportunities for reducing skill loading costs while maintaining functionality. By implementing the recommended strategies, the skill ecosystem can achieve:

- **Overall Token Reduction**: {{OVERALL_REDUCTION}}%
- **Budget Compliance**: {{BUDGET_COMPLIANCE}}% of skills within budget
- **Improved Performance**: {{PERFORMANCE_IMPROVEMENT}}% faster loading

**Priority**: {{PRIORITY_LEVEL}}
**Next Review**: {{NEXT_REVIEW_DATE}}

---

**Report Generation Time**: {{GENERATION_TIME}}
**Analysis Engine**: opencode-skill-auditor
**Token Calculation**: `(characters / 4) * 1.1` (with 10% overhead)
