# OpenCode Skill Auditor

Comprehensive analysis tool for OpenCode skills, providing duplicity scoring, token cost estimation, and subagent compatibility checking.

## Features

- **Duplicity Scoring**: Quantitative similarity scores (0-100%) between skills using Python difflib
- **Token Cost Estimation**: Calculate token consumption with optimization recommendations
- **Subagent Suitability**: Check which subagents can load which skills based on tool restrictions
- **Automated Reports**: Generate formatted reports using Jinja-style templates

## Installation

No installation required. Just ensure Python 3.8+ is available:

```bash
python3 --version
```

## Usage

### Run All Analyses

Generate all three reports (suitability, duplicity, token):

```bash
python3 skills/opencode-skill-auditor/analyze.py --all
```

Reports are saved to `reports/` directory with timestamps:
- `suitability_report_YYYYMMDD_HHMMSS.md`
- `duplicity_report_YYYYMMDD_HHMMSS.md`
- `token_report_YYYYMMDD_HHMMSS.md`

### Run Individual Analyses

Generate specific reports:

```bash
# Subagent suitability report
python3 skills/opencode-skill-auditor/analyze.py --suitability

# Duplicity matrix report
python3 skills/opencode-skill-auditor/analyze.py --duplicity

# Token optimization report
python3 skills/opencode-skill-auditor/analyze.py --tokens
```

### Specify Output Directory

```bash
python3 skills/opencode-skill-auditor/analyze.py --all --output-dir output/
```

### Custom Skills Directory

```bash
python3 skills/opencode-skill-auditor/analyze.py --all --skills-dir /path/to/skills
```

## Command-Line Options

```
usage: analyze.py [-h] [--skills-dir SKILLS_DIR] [--all]
                [--suitability] [--duplicity] [--tokens]
                [--output-dir OUTPUT_DIR]

OpenCode Skill Auditor - Analyze skills for duplicity, token costs,
and subagent compatibility

optional arguments:
  -h, --help            Show this help message and exit
  --skills-dir SKILLS_DIR
                        Directory containing skills (default: skills)
  --all                  Run all analyses
  --suitability          Generate subagent suitability report
  --duplicity           Generate duplicity matrix report
  --tokens               Generate token optimization report
  --output-dir OUTPUT_DIR
                        Output directory for reports (default: reports)
```

## Reports

### Suitability Report

Analyzes which subagents can load which skills based on `.AGENTS.md` restrictions.

**Key Metrics:**
- Compatibility percentages per subagent
- Tool requirements summary
- Detailed suitability matrix
- Subagent-specific recommendations
- Token budget allocations

**Output:** `reports/suitability_report_*.md`

### Duplicity Report

Generates quantitative similarity scores between all skill pairs.

**Key Metrics:**
- High duplicity pairs (≥70%) - candidates for merging
- Moderate duplicity pairs (50-69%) - framework extraction opportunities
- Average similarity across all skills
- Full pairwise similarity matrix

**Scoring Methodology:**
- Name: 15% weight
- Description: 25% weight
- What I Do: 30% weight
- When to Use Me: 20% weight
- Steps: 10% weight

**Output:** `reports/duplicity_report_*.md`

### Token Report

Analyzes token consumption and identifies optimization opportunities.

**Key Metrics:**
- Total tokens across all skills
- Average tokens per skill
- Oversized skills (>2000 tokens)
- Critical skills (>3000 tokens)
- Optimization potential (20-40% reduction)

**Optimization Strategies:**
1. Extract code blocks (20-40% savings)
2. Simplify verbose explanations (15-30% savings)
3. Use reference links (10-25% savings)
4. Consolidate similar sections (10-20% savings)
5. Remove redundant examples (5-15% savings)
6. Minimize frontmatter metadata (2-5% savings)

**Output:** `reports/token_report_*.md`

## Token Cost Calculation

Tokens are estimated using the formula:

```
tokens = (character_count / 4) * 1.1
```

- **4 characters/token**: Industry standard approximation
- **1.1 multiplier**: 10% overhead for parsing and processing

## Budget Guidelines

| Skill Type | Target Tokens | Max Tokens |
|-------------|---------------|-------------|
| Framework | <2000 | 2500 |
| Language-specific | <1500 | 2000 |
| Workflow | <3000 | 3500 |
| Subagent skills | <2000 | 2500 |

## Templates

Reports are generated from templates in `skills/opencode-skill-auditor/templates/`:
- `suitability-report.md`: Subagent compatibility template
- `duplicity-matrix.md`: Similarity matrix template
- `token-optimization.md`: Token analysis template

Templates use `{{VARIABLE}}` placeholders for dynamic content.

## Integration with Issue #60

This tool is part of Phase 3 of the opencode-skill-auditor enhancement (GitHub issue #60).

**Features Implemented:**
- ✅ Python script for duplicity scoring
- ✅ Token cost estimation
- ✅ Subagent compatibility checker
- ✅ Report generation

## Examples

### Basic Usage

#### Run all analyses

```bash
python3 skills/opencode-skill-auditor/analyze.py --all
```

**Output**:
```
Running full analysis suite...
============================================================
Loading skills from skills...
Loaded 34 skills
Generating suitability report...
Checking subagent compatibility...
Subagent compatibility checked
Analyzing token costs...
Token analysis complete for 34 skills
Suitability report saved to reports/suitability_report_20260130_184201.md
Generating duplicity report...
Calculating duplicity matrix...
Duplicity matrix calculated
Duplicity report saved to reports/duplicity_report_20260130_184201.md
Generating token report...
Analyzing token costs...
Token analysis complete for 34 skills
Token report saved to reports/token_report_20260130_184201.md
============================================================
Analysis complete! Reports saved to reports/
  - suitability_report_20260130_184201.md
  - duplicity_report_20260130_184201.md
  - token_report_20260130_184201.md
```

#### Check subagent compatibility for a specific skill

```bash
python3 -c "
from pathlib import Path
import sys
sys.path.insert(0, 'skills/opencode-skill-auditor')
from analyze import SkillAuditor

auditor = SkillAuditor()
auditor.load_all_skills()

# Check compatibility
compat = auditor.check_subagent_compatibility()
for skill, agents in compat.items():
    if 'python-pytest-creator' in skill:
        print(f'{skill}:')
        for agent, can_load in agents.items():
            print(f'  {agent}: {\"✓\" if can_load else \"✗\"}')"
```

**Output**:
```
python-pytest-creator:
  primary: ✓
  linting: ✓
  testing: ✓
  git: ✓
  docs: ✓
  opentofu: ✓
  workflow: ✓
```

#### Analyze token costs for specific skill

```bash
python3 -c "
from pathlib import Path
import sys
sys.path.insert(0, 'skills/opencode-skill-auditor')
from analyze import SkillAuditor

auditor = SkillAuditor()
auditor.load_all_skills()

# Check token costs
tokens = auditor.estimate_tokens()
for skill, data in tokens.items():
    if 'nextjs-unit-test-creator' in skill:
        print(f'{skill}:')
        print(f'  Characters: {data[\"chars\"]:,}')
        print(f'  Tokens: {data[\"tokens\"]:,}')
        print(f'  Status: {data[\"status\"]}')"
```

**Output**:
```
nextjs-unit-test-creator:
  Characters: 37,834
  Tokens: 10,404
  Status: CRITICAL
```

#### Check duplicity between two skills

```bash
python3 -c "
from pathlib import Path
import sys
sys.path.insert(0, 'skills/opencode-skill-auditor')
from analyze import SkillAuditor

auditor = SkillAuditor()
auditor.load_all_skills()

# Check duplicity
duplicity = auditor.calculate_duplicity_matrix()
skill_a = 'javascript-eslint-linter'
skill_b = 'python-ruff-linter'
if skill_a in duplicity and skill_b in duplicity[skill_a]:
    score = duplicity[skill_a][skill_b]
    print(f'{skill_a} vs {skill_b}: {score}% similarity')"
```

**Output**:
```
javascript-eslint-linter vs python-ruff-linter: 50% similarity
```

### Advanced Usage

#### Generate reports with custom output directory

```bash
python3 skills/opencode-skill-auditor/analyze.py --all --output-dir custom-reports/
```

#### Analyze skills from custom directory

```bash
python3 skills/opencode-skill-auditor/analyze.py --all --skills-dir /path/to/custom/skills
```

#### Run multiple specific analyses

```bash
python3 skills/opencode-skill-auditor/analyze.py --suitability --duplicity
```

#### Filter report output

```bash
# Generate token report and filter for critical skills
python3 skills/opencode-skill-auditor/analyze.py --tokens | grep -A 1 "CRITICAL"

# Generate duplicity report and find moderate duplicity pairs
python3 skills/opencode-skill-auditor/analyze.py --duplicity | grep -E "50-69%|Moderate"
```

### Workflow Integration

#### Pre-commit skill validation

Create `.git/hooks/pre-commit`:

```bash
#!/bin/bash
# Validate skills before commit
python3 skills/opencode-skill-auditor/analyze.py --tokens --output-dir .tmp-skills-check/
# Check if any skills exceed 4000 tokens
if grep -q "4000" .tmp-skills-check/token_report_*.md; then
  echo "Warning: Some skills exceed 4000 tokens. Consider optimization."
fi
```

#### CI/CD pipeline integration

```yaml
# .github/workflows/skill-audit.yml
name: Skill Audit
on: [push, pull_request]
jobs:
  audit:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Run skill auditor
        run: python3 skills/opencode-skill-auditor/analyze.py --all
      - name: Upload reports
        uses: actions/upload-artifact@v3
        with:
          name: skill-audit-reports
          path: reports/
```

#### Monitor skill growth over time

```bash
#!/bin/bash
# Track skill token changes over time
DATE=$(date +%Y%m%d)
python3 skills/opencode-skill-auditor/analyze.py --tokens --output-dir history/$DATE/
echo "Saved token report to history/$DATE/"
```

## Troubleshooting

### Issue: "Template file not found"

**Solution:** Ensure templates exist in `skills/opencode-skill-auditor/templates/`

```bash
ls -la skills/opencode-skill-auditor/templates/
```

### Issue: "No skills found"

**Solution:** Check that skills directory exists and contains SKILL.md files

```bash
ls skills/*/SKILL.md
```

### Issue: "ImportError: No module named..."

**Solution:** Install required dependencies (none required for standard library)

```bash
# Only standard library modules used:
# - difflib, json, re, os, sys, argparse, datetime, pathlib
```

### Issue: "Permission denied when creating reports directory"

**Solution:** Ensure write permissions in the target directory

```bash
# Create reports directory with proper permissions
mkdir -p reports
chmod 755 reports
```

### Issue: "Duplicity scores seem incorrect"

**Solution:** Review scoring weights and skill content manually

```bash
# Check which components are being compared
python3 -c "
from pathlib import Path
import sys
sys.path.insert(0, 'skills/opencode-skill-auditor')
from analyze import SkillAuditor

auditor = SkillAuditor()
auditor.load_all_skills()

# View skill details
skill_a = auditor.skills.get('javascript-eslint-linter')
skill_b = auditor.skills.get('python-ruff-linter')
if skill_a and skill_b:
    print(f'Skill A: {skill_a.name}')
    print(f'  Description: {skill_a.description[:100]}...')
    print(f'Skill B: {skill_b.name}')
    print(f'  Description: {skill_b.description[:100]}...')"
```

## Limitations

### Semantic Similarity

**Limitation**: Duplicity scoring is based on text similarity, not functional equivalence.

**Details**:
- Two skills may have high text similarity but serve different purposes
- Semantic meaning of code examples is not analyzed
- Domain-specific terminology may inflate similarity scores
- The analysis uses difflib SequenceMatcher which is text-based, not semantic

**Impact**: Manual review recommended for duplicity scores >50%

### Token Estimation

**Limitation**: Token estimates are approximations based on character count.

**Details**:
- Actual token consumption varies by AI model
- Special tokens (e.g., `<|endoftext|>`) are not accounted for
- Overhead estimation (10%) is a general approximation
- Code blocks may have different tokenization patterns

**Impact**: Estimates are typically within ±10-15% of actual costs

### Subagent Compatibility

**Limitation**: Compatibility checks are based on static tool requirements, not dynamic usage patterns.

**Details**:
- Skills may require tools only in certain code paths
- Conditional tool usage is not detected
- Tool aliases and alternative approaches are not considered
- Delegation patterns assume parent agents have full access

**Impact**: Some skills marked "incompatible" may work with delegation patterns

### Report Coverage

**Limitation**: Reports analyze current state, not historical trends or dependencies.

**Details**:
- No tracking of skill growth over time
- Dependency relationships between skills are not analyzed
- Impact of skill changes on dependent workflows is not assessed
- No detection of circular dependencies

**Impact**: Requires manual tracking for trend analysis

### Skill Extraction

**Limitation**: The auditor does not actually modify skills; it only provides recommendations.

**Details**:
- Optimization strategies are suggestions, not automated implementations
- No automatic refactoring or code block extraction
- Manual intervention required to implement recommendations
- Validation of optimizations is not performed

**Impact**: Users must manually implement suggested optimizations

### Scalability

**Limitation**: Performance may degrade with very large skill sets.

**Details**:
- O(n²) complexity for duplicity matrix (n = number of skills)
- Not optimized for parallel processing
- Memory usage scales with skill count and content size
- Recommended limit: ~100 skills per analysis

**Impact**: Analysis time may exceed 30 seconds for >100 skills

### Custom Workflows

**Limitation**: Standard analysis may not capture custom workflow patterns.

**Details**:
- Assumes standard skill structure (SKILL.md format)
- Custom frontmatter or metadata formats may not be parsed
- Non-standard section names may be missed
- Nested or hierarchical skill structures not supported

**Impact**: Custom skill formats may require adaptation of the analyzer

### Platform-Specific Skills

**Limitation**: Platform-specific implementations may be over- or under-estimated.

**Details**:
- No distinction between framework vs. language-specific skills in analysis
- Platform-specific optimizations not detected
- Tool usage patterns may vary by platform
- MCP server access is binary (yes/no), not tiered

**Impact**: Recommendations may need adjustment for platform-specific contexts

### Data Quality

**Limitation**: Analysis quality depends on skill documentation completeness.

**Details**:
- Skills with incomplete "What I Do" sections may have inaccurate duplicity scores
- Missing or vague descriptions affect scoring
- Inconsistent section naming across skills reduces accuracy
- Copy-pasted content may inflate duplicity scores

**Impact**: Maintain consistent, complete skill documentation for best results

### Known Limitations Summary

| Category | Limitation | Impact | Mitigation |
|----------|------------|--------|------------|
| Semantic Similarity | Text-based, not semantic | May miss functional differences | Manual review for >50% scores |
| Token Estimation | Approximate formula | ±10-15% variance | Use as planning guideline |
| Subagent Compatibility | Static analysis | False positives/negatives | Test delegation patterns |
| Report Coverage | Current state only | No trend analysis | Track reports over time |
| Skill Extraction | Recommendations only | Manual implementation required | Apply suggestions manually |
| Scalability | O(n²) complexity | Slow for >100 skills | Batch large skill sets |
| Custom Workflows | Assumes standard format | May miss custom patterns | Adapt analyzer for formats |
| Platform-Specific | Generic analysis | May need context adjustment | Consider platform specifics |
| Data Quality | Documentation dependent | Incomplete skills skew results | Maintain skill standards |

### Future Work

Planned enhancements to address these limitations:

1. **Semantic Analysis**: Integrate NLP models for true semantic understanding
2. **Actual Token Tracking**: Measure real token consumption from AI model responses
3. **Dynamic Compatibility**: Analyze runtime tool usage patterns
4. **Historical Tracking**: Store and trend analysis results over time
5. **Automated Refactoring**: Implement recommended optimizations automatically
6. **Parallel Processing**: Add multiprocessing for large skill sets
7. **Dependency Analysis**: Track skill relationships and impacts
8. **Custom Format Support**: Flexible parsing for various skill formats
9. **Tiered MCP Access**: Detailed MCP server capability analysis
10. **Interactive Dashboard**: Web-based visualization and exploration

## Performance

- **Skills analyzed**: 34 skills
- **Analysis time**: ~2-3 seconds
- **Report generation**: ~5-10 seconds total
- **Memory usage**: <50MB

## Future Enhancements

- [ ] Add parallel processing for large skill sets
- [ ] Support for custom scoring weights
- [ ] Interactive report viewer (HTML/CSS)
- [ ] Export to JSON/CSV formats
- [ ] Trend analysis over time
- [ ] Skill dependency visualization

## License

Apache-2.0

## Contributing

Contributions welcome! Please follow OpenCode skill best practices.

## References

- **Issue**: #60 - Enhance opencode-skill-auditor
- **Skills**: `skills/` directory
- **Agents Configuration**: `.AGENTS.md`
- **Templates**: `skills/opencode-skill-auditor/templates/`
