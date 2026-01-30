# Duplicity Scoring Matrix Report

**Generated**: {{GENERATION_DATE}}
**Auditor Version**: opencode-skill-auditor v{{VERSION}}
**Skills Analyzed**: {{NUM_SKILLS}}
**Scoring Methodology**: Weighted semantic similarity (difflib)

---

## Executive Summary

This report provides quantitative similarity scores (0-100%) between all {{NUM_SKILLS}} OpenCode skills. Skills with high duplicity (>70%) are candidates for merging, while those with moderate duplicity (50-70%) may benefit from extracting common patterns.

### Key Metrics

- **High Duplicity Pairs** (≥70%): {{HIGH_DUP_COUNT}} pairs
- **Moderate Duplicity Pairs** (50-69%): {{MODERATE_DUP_COUNT}} pairs
- **Low Duplicity Pairs** (<50%): {{LOW_DUP_COUNT}} pairs
- **Average Similarity**: {{AVG_SIMILARITY}}%

### Most Duplicated Skills

| Rank | Skill | High Duplicity Pairs | Highest Match |
|------|-------|---------------------|---------------|
{{MOST_DUPLICATED_TABLE}}

---

## Scoring Methodology

### Weighted Components

| Component | Weight | Description |
|-----------|--------|-------------|
| Name | 15% | Functional overlap indicator |
| Description | 25% | Scope and purpose definition |
| What I Do | 30% | Actual capabilities and functionality |
| When to Use Me | 20% | Use case overlap |
| Steps | 10% | Implementation approach similarity |

### Score Interpretation

| Score Range | Interpretation | Action |
|-------------|----------------|--------|
| 86-100% | Very High Duplicity | **Merge** - Skills are redundant |
| 71-85% | High Duplicity | **Consider Consolidation** - Strong overlap |
| 50-70% | Moderate Duplicity | **Extract Common Patterns** - Framework opportunity |
| 31-49% | Low-Moderate Duplicity | Monitor - Generally separate concerns |
| 0-30% | Low Duplicity | No Action - Skills are distinct |

---

## Full Duplicity Matrix

### Matrix Overview

| Skill |{{SKILL_HEADERS}}
|-------|{{SKILL_SEPARATOR}}
{{MATRIX_ROWS}}

**Legend**:
- `**score**` (bold): High duplicity (≥70%) - Recommend merging or consolidation
- `*score*` (italic): Moderate duplicity (50-69%) - Consider extracting patterns
- `score` (plain): Low duplicity (<50%) - Keep separate

---

## High Duplicity Pairs (≥70%)

{{HIGH_DUP_TABLE}}

### Recommendations

1. **Immediate Actions (86-100%)**
   {{IMMEDIATE_ACTIONS}}

2. **Consolidation Opportunities (71-85%)**
   {{CONSOLIDATION_OPPORTUNITIES}}

---

## Moderate Duplicity Pairs (50-69%)

{{MODERATE_DUP_TABLE}}

### Recommendations

1. **Framework Extraction**
   {{FRAMEWORK_EXTRACTION}}

2. **Shared Component Identification**
   {{SHARED_COMPONENTS}}

---

## Cluster Analysis

### Skill Clusters by Functional Domain

{{CLUSTER_ANALYSIS}}

---

## Duplicity by Skill Category

| Category | Avg Duplicity | High Dup Pairs | Moderate Dup Pairs |
|----------|---------------|----------------|-------------------|
{{CATEGORY_DUP_TABLE}}

---

## Action Items

### Merge Candidates (Score ≥ 86%)

{{MERGE_CANDIDATES}}

**Proposed Actions**:
{{MERGE_ACTIONS}}

### Consolidation Candidates (Score 71-85%)

{{CONSOLIDATION_CANDIDATES}}

**Proposed Actions**:
{{CONSOLIDATION_ACTIONS}}

### Framework Extraction Candidates (Score 50-70%)

{{FRAMEWORK_CANDIDATES}}

**Proposed Actions**:
{{FRAMEWORK_ACTIONS}}

---

## Detailed Pair Analysis

### Top 10 Most Similar Pairs

{{TOP_PAIRS_ANALYSIS}}

---

## Low Duplicity Analysis

### Most Unique Skills (Lowest Average Similarity)

| Rank | Skill | Avg Similarity | Distinctive Features |
|------|-------|----------------|-------------------|
{{UNIQUE_SKILLS_TABLE}}

---

## Improvement Opportunities

### Reduce Duplication

1. **Consolidate High-Duplicity Skills**
   - Target reduction: {{TARGET_REDUCTION_1}} duplicate skills
   - Expected token savings: {{TOKEN_SAVINGS_1}} tokens
   - Complexity reduction: {{COMPLEXITY_REDUCTION_1}}%

2. **Extract Common Patterns**
   - Target extractions: {{TARGET_EXTRACTIONS}} shared capabilities
   - New framework skills: {{NEW_FRAMEWORKS}} skills
   - Expected token savings: {{TOKEN_SAVINGS_2}} tokens

3. **Refactor Overlapping Workflows**
   - Target refactors: {{TARGET_REFACTORS}} workflows
   - Expected improvement: {{IMPROVEMENT_METRIC}}%

---

## Recommendations

### Short-term (Next 1-2 weeks)

{{SHORT_TERM_RECOMMENDATIONS}}

### Medium-term (Next 1-2 months)

{{MEDIUM_TERM_RECOMMENDATIONS}}

### Long-term (Next 3-6 months)

{{LONG_TERM_RECOMMENDATIONS}}

---

## Appendix: Full Scoring Data

{{FULL_SCORING_DATA}}

---

## Conclusion

The duplicity analysis reveals {{HIGH_DUP_COUNT}} high-duplicity skill pairs (≥70%), indicating significant opportunities for consolidation and optimization. By addressing these overlaps, the skill ecosystem can achieve:

- **Reduced Token Usage**: {{EXPECTED_TOKEN_REDUCTION}}% reduction
- **Improved Maintainability**: {{MAINTAINABILITY_IMPROVEMENT}}% improvement
- **Better User Experience**: {{UX_IMPROVEMENT}} improvement in skill discoverability

**Overall Assessment**: {{OVERALL_ASSESSMENT}}

**Priority Level**: {{PRIORITY_LEVEL}}

---

**Report Generation Time**: {{GENERATION_TIME}}
**Analysis Engine**: opencode-skill-auditor with Python difflib
**Scoring Algorithm**: Weighted SequenceMatcher
