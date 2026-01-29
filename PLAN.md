# Plan: Enhance opencode-skill-auditor

## Overview

Enhance the `opencode-skill-auditor` skill to analyze subagent/skill suitability, create skill duplicity matrices, and provide token usage optimization recommendations.

## Issue Reference

- Issue: #60
- URL: https://github.com/darellchua2/opencode-config-template/issues/60
- Labels: enhancement, optimization, architecture

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

### Phase 1: Update opencode-skill-auditor Skill

#### 1.1 Add Subagent Suitability Analysis Section

**File**: `skills/opencode-skill-auditor/SKILL.md`

**Add after "Dependency Mapping" section:**

```markdown
## Subagent Suitability Analysis

### Purpose

Determine which subagents should load which skills based on tool requirements and MCP access.

### Analysis Steps

1. **Tool Requirements Extraction**
   - Parse skill documentation for tool references (read, write, bash, etc.)
   - Identify MCP server requirements (atlassian, drawio, zai-mcp-server, etc.)
   - Check against `.AGENTS.md` subagent tool restrictions

2. **Subagent Compatibility Check**
   - For each subagent type (linting, testing, git-workflow, etc.):
     - Verify tool requirements match allowed tools
     - Verify MCP access matches permitted servers
     - Flag violations (e.g., skills requiring `bash` cannot be loaded by subagents)

3. **Suitability Matrix Output**
   | Skill | Suitable Subagents | Tool Requirements | MCP Access | Decomposition Needed |
   |-------|-------------------|-------------------|------------|---------------------|
   | `javascript-eslint-linter` | `linting-subagent` | read, write, edit, glob, grep | None | No |
   | `python-ruff-linter` | `linting-subagent` | read, write, edit, glob, grep | None | No |
   | `git-issue-creator` | None (primary only) | bash, gh CLI, read, write, edit | None | Yes - too complex |
   | `nextjs-pr-workflow` | None (primary only) | bash, npm, atlassian MCP | atlassian | Yes - 4+ frameworks |

4. **Decomposition Recommendations**
   - Identify complex skills that need to be split
   - Suggest framework components for subagent use
   - Provide migration paths for skill refactoring
```

#### 1.2 Add Duplicity Scoring Matrix

**File**: `skills/opencode-skill-auditor/SKILL.md`

**Add after "Redundancy Detection" section:**

```markdown
## Duplicity Scoring Matrix

### Purpose

Quantify overlap between skills using semantic similarity and capability matching.

### Scoring Methodology

**Score Calculation (0-100):**
- 70-100: High overlap → Consider merging
- 50-70: Medium overlap → Extract shared functionality
- 30-50: Low overlap → Separate is acceptable
- 0-30: No overlap → Distinct skills

**Scoring Factors:**

| Factor | Weight | Measurement |
|--------|--------|-------------|
| Description similarity | 30% | Semantic text comparison |
| Capability overlap | 40% | Shared "What I do" items |
| Dependency overlap | 20% | Shared framework skills |
| Token redundancy | 10% | Repeated documentation |

**Implementation:**

```bash
# Calculate description overlap (semantic similarity)
for skill1 in skills/*/SKILL.md; do
  for skill2 in skills/*/SKILL.md; do
    if [ "$skill1" \< "$skill2" ]; then
      # Extract descriptions
      desc1=$(grep "^description:" "$skill1")
      desc2=$(grep "^description:" "$skill2")

      # Calculate similarity (use Python difflib or similar)
      similarity=$(python3 -c "
import difflib
desc1 = '''$desc1'''
desc2 = '''$desc2'''
ratio = difflib.SequenceMatcher(None, desc1, desc2).ratio()
print(int(ratio * 100))
")

      echo "$skill1 vs $skill2: $similarity%"
    fi
  done
done

# Extract capability overlap
# Compare "What I do" sections using keyword matching

# Check dependency overlap
# Count shared framework skill references
```

**Example Matrix:**

```
                    git-issue-creator  jira-git-workflow  nextjs-pr-workflow
git-issue-creator         -               65%                55%
jira-git-workflow        65%              -                  60%
nextjs-pr-workflow       55%              60%                 -
```

**Recommendation Logic:**

```python
if score >= 70:
    action = "Consider merging skills"
elif score >= 50:
    action = "Extract shared functionality into new framework"
elif score >= 30:
    action = "Separate is acceptable, monitor for future overlap"
else:
    action = "No overlap, maintain separate skills"
```
```

#### 1.3 Add Token Cost Estimation

**File**: `skills/opencode-skill-auditor/SKILL.md`

**Add after "Granularity Assessment" section:**

```markdown
## Token Cost Estimation

### Purpose

Estimate token costs for loading skills and identify optimization opportunities.

### Cost Calculation

**Token Estimation:**
- Average: 4 characters per token
- Formula: `tokens = line_count × characters_per_line_avg / 4`

**Metrics per Skill:**
| Metric | Description |
|--------|-------------|
| Lines | Total lines in SKILL.md |
| Characters | Total character count |
| Estimated Tokens | Lines × ~30 chars/line / 4 |
| Redundancy % | Percentage of duplicated content |
| Load Time Overhead | Estimated loading time (relative) |

**Implementation:**

```bash
# Calculate token costs for all skills
for skill in skills/*/SKILL.md; do
  skill_name=$(basename $(dirname "$skill"))
  lines=$(wc -l < "$skill")
  chars=$(wc -c < "$skill")
  tokens=$((chars / 4))

  # Calculate redundancy (shared with framework skills)
  redundancy=$(python3 <<'PYTHON'
import re
with open("$skill", 'r') as f:
    content = f.read()
# Simple heuristic: count repeated sections
# (implementation detail)
print("25")  # example percentage
PYTHON
)

  printf "%-40s %5s lines, %7s tokens, %2s%% redundancy\n" \
    "$skill_name" "$lines" "$tokens" "$redundancy"
done | sort -k3 -nr
```

**Optimization Recommendations:**

| Token Cost | Optimization Action | Priority |
|------------|-------------------|----------|
| >2000 tokens | Extract language-specific sections, externalize docs | High |
| 1500-2000 tokens | Remove redundant examples, simplify tables | High |
| 1000-1500 tokens | Delegate to framework, reduce verbosity | Medium |
| <1000 tokens | Already optimized, maintain current state | Low |

**Token Reduction Strategies:**

1. **Lazy Loading**
   - Only load skill sections needed for current task
   - Example: Don't load Python examples if working with JavaScript

2. **External Documentation**
   - Move verbose examples to separate `docs/` directory
   - Reference external docs with links

3. **Template Skills**
   - Create minimal skill templates
   - Reference framework docs instead of duplicating

4. **Composition over Inheritance**
   - Use skill composition instead of extending multiple skills
   - Reduces redundant documentation

**Example Analysis:**

| Skill | Lines | Tokens | Redundancy | Optimization | Expected Reduction |
|-------|-------|--------|------------|--------------|-------------------|
| `linting-workflow` | 669 | ~5,000 | 30% | Extract language sections | -30% (3,500 tokens) |
| `git-issue-creator` | 384 | ~2,900 | 40% | Remove redundant examples | -40% (1,740 tokens) |
| `nextjs-pr-workflow` | 266 | ~2,000 | 25% | Reference framework docs | -25% (1,500 tokens) |
```

#### 1.4 Add Subagent-Specific Recommendations

**File**: `skills/opencode-skill-auditor/SKILL.md`

**Add new section after "Recommendation Generation":**

```markdown
## Subagent-Specific Recommendations

### Primary Agents

**When to Load Full Skills:**
- Complex workflows that extend multiple framework skills
- Skills requiring `bash` or system commands
- Skills needing full MCP server access
- Skills with comprehensive guidance needed

**Example Skills:**
- `git-issue-creator` (extends 4 framework skills)
- `jira-git-workflow` (JIRA + Git integration)
- `nextjs-pr-workflow` (complex Next.js workflow)

### Subagents

**When to Load Minimal Skills:**
- Skills that only read/write files
- Skills with limited tool requirements
- Framework reference skills (not implementations)
- Skills within token budget constraints

**Example Skills:**
- `javascript-eslint-linter` (file read/write only)
- `python-ruff-linter` (file read/write only)
- `python-pytest-creator` (file read/write only)

**Tool Restriction Compliance:**

| Subagent Type | Allowed Tools | Forbidden Tools | Skill Loading Strategy |
|--------------|--------------|-----------------|---------------------|
| `linting-subagent` | read, write, edit, glob, grep | bash, task, todowrite | Load linting skills only |
| `testing-subagent` | read, write, edit, glob, grep | bash, task, todowrite | Load testing skills only |
| `git-workflow-subagent` | read, write, edit, glob, grep + atlassian MCP | bash, task, todowrite | Load Git/JIRA skills, delegate bash |
| `documentation-subagent` | read, write, edit, glob, grep | bash, task, todowrite | Load documentation skills only |
| `opentofu-explorer-subagent` | read, write, edit, glob, grep | bash, task, todowrite | Load OpenTofu skills only |
| `workflow-subagent` | read, write, edit, glob, grep + atlassian MCP | bash, task, todowrite | Load workflow skills, delegate bash |

**Delegation Strategy:**

```python
def should_subagent_load_skill(skill_name, subagent_type):
    # Check tool requirements
    required_tools = extract_tool_requirements(skill_name)

    # Check subagent permissions
    allowed_tools = get_subagent_allowed_tools(subagent_type)

    # If skill requires forbidden tools, don't load
    if not required_tools.issubset(allowed_tools):
        return False, "Requires forbidden tools: " + str(required_tools - allowed_tools)

    # Check MCP server access
    required_mcp = extract_mcp_requirements(skill_name)
    allowed_mcp = get_subagent_allowed_mcp(subagent_type)

    if not required_mcp.issubset(allowed_mcp):
        return False, "Requires forbidden MCP: " + str(required_mcp - allowed_mcp)

    # Check token budget
    skill_tokens = estimate_tokens(skill_name)
    budget = get_subagent_token_budget(subagent_type)

    if skill_tokens > budget:
        return False, f"Exceeds token budget ({skill_tokens} > {budget})"

    return True, "Skill is compatible"
```
```

### Phase 2: Update Analysis Commands

**File**: `skills/opencode-skill-auditor/SKILL.md`

**Add to "Analysis Commands" section:**

```bash
# Subagent suitability analysis
echo "=== Subagent Suitability Analysis ==="
for skill in skills/*/SKILL.md; do
  skill_name=$(basename $(dirname "$skill"))
  echo "Skill: $skill_name"

  # Extract tool requirements
  echo "  Tools required:"
  grep -oE "(read|write|edit|glob|grep|bash|task|todowrite)" "$skill" | sort | uniq

  # Extract MCP requirements
  echo "  MCP servers:"
  grep -oE "(atlassian|drawio|zai-mcp-server)" "$skill" | sort | uniq
  echo
done

# Calculate duplicity scores
echo "=== Duplicity Scoring Matrix ==="
python3 <<'PYTHON'
import difflib
import glob
import yaml

skills = glob.glob('skills/*/SKILL.md')
skill_names = [s.split('/')[1] for s in skills]

print(f"{'':<40}", end='')
for name in skill_names:
    print(f'{name:<20}', end='')
print()

for i, skill1 in enumerate(skills):
    name1 = skill_names[i]
    print(f'{name1:<40}', end='')

    with open(skill1, 'r') as f:
        desc1 = f.read()

    for j, skill2 in enumerate(skills):
        if j < i:
            print(f'{'':<20}', end='')
            continue

        name2 = skill_names[j]
        with open(skill2, 'r') as f:
            desc2 = f.read()

        similarity = int(difflib.SequenceMatcher(None, desc1, desc2).ratio() * 100)
        print(f'{similarity}%{"":<{19-len(str(similarity))-1}}', end='')
    print()
PYTHON

# Estimate token costs
echo "=== Token Cost Estimation ==="
for skill in skills/*/SKILL.md; do
  skill_name=$(basename $(dirname "$skill"))
  lines=$(wc -l < "$skill")
  chars=$(wc -c < "$skill")
  tokens=$((chars / 4))

  printf "%-40s %5s lines, %7s tokens\n" "$skill_name" "$lines" "$tokens"
done | sort -k3 -nr
```

### Phase 3: Create Audit Output Templates

**Create**: `skills/opencode-skill-auditor/templates/`

#### 3.1 Subagent Suitability Report Template

**File**: `skills/opencode-skill-auditor/templates/suitability-report.md`

```markdown
# OpenCode Skill Subagent Suitability Report

Generated: [DATE]

## Summary

- Total Skills: [COUNT]
- Primary Agent Compatible: [COUNT]
- Subagent Compatible: [COUNT]
- Requires Decomposition: [COUNT]

## Subagent Compatibility Matrix

### Primary Agent Skills
Skills that should only be loaded by primary agents:

| Skill | Reason | Token Cost | Decomposition Priority |
|-------|---------|------------|----------------------|
| `git-issue-creator` | Extends 4 frameworks, requires bash | ~2,900 | High |
| `nextjs-pr-workflow` | Extends 4 frameworks, requires npm | ~2,000 | High |
| [Additional skills...] | [Reason] | [Tokens] | [Priority] |

### Linting Subagent Skills
Skills compatible with `linting-subagent`:

| Skill | Tools Required | Token Cost | Status |
|-------|--------------|------------|--------|
| `javascript-eslint-linter` | read, write, edit, glob, grep | ~400 | ✓ Compatible |
| `python-ruff-linter` | read, write, edit, glob, grep | ~300 | ✓ Compatible |

### Testing Subagent Skills
Skills compatible with `testing-subagent`:

| Skill | Tools Required | Token Cost | Status |
|-------|--------------|------------|--------|
| [Skills...] | [Tools] | [Tokens] | [Status] |

## Decomposition Recommendations

### High Priority (Token >2000)
[Recommendations for decomposing complex skills]

### Medium Priority (Token 1000-2000)
[Recommendations for optimizing medium-complexity skills]

### Low Priority (Token <1000)
[Skills that are already optimized]

## Migration Path

For skills requiring decomposition:

1. Extract framework components
2. Create subagent-compatible versions
3. Update `.AGENTS.md` with new mappings
4. Test skill loading with subagents
5. Deploy changes incrementally
```

#### 3.2 Duplicity Matrix Report Template

**File**: `skills/opencode-skill-auditor/templates/duplicity-matrix.md`

```markdown
# OpenCode Skill Duplicity Matrix Report

Generated: [DATE]

## Scoring Methodology

- **70-100%**: High overlap → Consider merging
- **50-70%**: Medium overlap → Extract shared functionality
- **30-50%**: Low overlap → Separate is acceptable
- **0-30%**: No overlap → Distinct skills

## Duplicity Matrix

[Full matrix with all skills and similarity scores]

## High Overlap (>70%)

These skills should be considered for merging:

| Skill Pair | Score | Recommendation |
|------------|-------|----------------|
| `git-issue-creator` vs `jira-git-workflow` | 75% | Consider merging into unified Git workflow skill |
| [Additional pairs...] | [Score] | [Recommendation] |

## Medium Overlap (50-70%)

These skills should extract shared functionality:

| Skill Pair | Score | Recommendation |
|------------|-------|----------------|
| [Skills...] | [Score] | [Recommendation] |

## Low Overlap (<50%)

These skills are distinct and should remain separate:

| Skill Pair | Score | Recommendation |
|------------|-------|----------------|
| [Skills...] | [Score] | Maintain separate skills |
```

#### 3.3 Token Optimization Report Template

**File**: `skills/opencode-skill-auditor/templates/token-optimization.md`

```markdown
# OpenCode Skill Token Optimization Report

Generated: [DATE]

## Token Cost Summary

- Total Skills: [COUNT]
- Total Tokens: [TOTAL]
- Average Tokens per Skill: [AVERAGE]
- Highest Token Cost: [SKILL] ([TOKENS])
- Lowest Token Cost: [SKILL] ([TOKENS])

## Skills by Token Cost

### High Cost (>2000 tokens)

| Skill | Tokens | Lines | Redundancy | Optimization Action | Expected Reduction |
|-------|--------|-------|------------|-------------------|-------------------|
| [Skills...] | [Tokens] | [Lines] | [%] | [Action] | [-%] |

### Medium Cost (1000-2000 tokens)

| Skill | Tokens | Lines | Redundancy | Optimization Action |
|-------|--------|-------|------------|-------------------|
| [Skills...] | [Tokens] | [Lines] | [%] | [Action] |

### Low Cost (<1000 tokens)

| Skill | Tokens | Lines | Status |
|-------|--------|-------|--------|
| [Skills...] | [Tokens] | [Lines] | ✓ Already optimized |

## Optimization Strategies

### Priority 1: Extract Language-Specific Sections
[Skills and extraction details]

### Priority 2: Remove Redundant Examples
[Skills and example removal]

### Priority 3: Delegate to Framework Skills
[Skills and delegation details]

### Priority 4: Externalize Documentation
[Skills and externalization details]

## Expected Impact

- **Current Total Tokens**: [TOTAL]
- **Projected Total Tokens**: [PROJECTED]
- **Reduction**: [%]
- **Projected Savings**: [TOKENS] tokens
```

## Files to Modify

1. **skills/opencode-skill-auditor/SKILL.md**
   - Add "Subagent Suitability Analysis" section
   - Add "Duplicity Scoring Matrix" section
   - Add "Token Cost Estimation" section
   - Add "Subagent-Specific Recommendations" section
   - Update "Analysis Commands" section

2. **skills/opencode-skill-auditor/templates/** (new directory)**
   - `suitability-report.md` - Report template
   - `duplicity-matrix.md` - Report template
   - `token-optimization.md` - Report template

## Approach

### Step 1: Update SKILL.md
- Add new sections to `skills/opencode-skill-auditor/SKILL.md`
- Implement analysis commands for each new capability
- Update "Best Practices" with subagent-specific guidance
- Add examples for each new analysis type

### Step 2: Create Report Templates
- Create `templates/` directory
- Implement report templates with proper formatting
- Include clear sections for each analysis type
- Add placeholders for dynamic data

### Step 3: Implement Analysis Logic
- Create Python script for duplicity scoring
- Implement token cost estimation
- Build subagent compatibility checker
- Generate sample reports

### Step 4: Test and Validate
- Run full audit on all 31 skills
- Verify duplicity scores are accurate
- Validate token estimates against actual loading
- Test subagent compatibility checks

### Step 5: Document and Refine
- Add usage examples to skill documentation
- Document limitations of analysis
- Provide troubleshooting guidance
- Create test cases for edge cases

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
- Alternative: Split into multiple smaller skills (not recommended for audit tool)
- Consider adding automated report generation in future iteration

## References

- Issue: https://github.com/darellchua2/opencode-config-template/issues/60
- `.AGENTS.md` - Subagent tool restrictions
- `skills/` - All 31 current skills to audit
- `skills/opencode-skill-auditor/SKILL.md` - Base skill to enhance
