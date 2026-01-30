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

### Check specific analysis

```bash
# Check which subagents can load a specific skill
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

### Analyze specific skills

```bash
# Analyze only a subset of skills by filtering
python3 skills/opencode-skill-auditor/analyze.py --all \
  | grep -E "(python|javascript)"
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
