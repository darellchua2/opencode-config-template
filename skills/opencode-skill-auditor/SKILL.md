---
name: opencode-skill-auditor
description: Audit existing OpenCode skills to identify modularization opportunities and eliminate redundancy
license: Apache-2.0
compatibility: opencode
metadata:
  audience: developers
  workflow: analysis-and-optimization
---

## What I do
- Analyze skills for redundancy, overlap, and duplication
- Identify modularization opportunities to extract reusable components
- Recommend consolidation strategies for efficiency
- Generate reports on interdependencies and coupling issues

## When to use me
Use when:
- Analyzing the skill ecosystem for optimization opportunities
- Identifying redundant functionality across skills
- Planning refactoring or consolidation
- Ensuring new skills don't duplicate existing capabilities

## Prerequisites
- Access to skills directory with all OpenCode skill definitions
- Basic understanding of skill structure and YAML frontmatter
- Familiarity with modular design principles and DRY methodology

## Steps

### Step 1: Skill Discovery
Locate and catalog all skill definitions.
**Commands**:
```bash
find . -name "SKILL.md" -type f | sort
grep -h "^name:" skills/*/SKILL.md | sort
```

### Step 2: Capability Analysis
Extract and categorize functionality from skill descriptions.

### Step 3: Redundancy Detection
Compare skills for overlapping functionality and use cases.

### Step 4: Granularity Assessment
Identify skills that can be broken into smaller, reusable components.

### Step 5: Dependency Mapping
Analyze skill interdependencies and coupling relationships.

### Step 6: Recommendation Generation
Propose modularization strategies, consolidation opportunities, and priority rankings.

## Best Practices
- Process skills in logical groups by capability domain
- Preserve existing functionality and user-facing behavior
- Propose modularization in stages to minimize disruption
- Maintain clear documentation of relationships between skills

## Common Issues

### Skills appear similar but serve different contexts
**Solution**: Focus on specific use cases and target audiences in analysis.

### Over-granularization leading to fragmentation
**Solution**: Balance reusability with usability; group related capabilities logically.

### Missing documentation for interdependencies
**Solution**: Create dependency mapping and document implicit relationships.

## Analysis Commands
```bash
# Quick skill overview with metadata
for skill in skills/*/SKILL.md; do
  echo "=== $(basename $(dirname "$skill")) ==="
  grep -E "^name:|^description:" "$skill"
done

# Find similar descriptions
grep -h "^description:" skills/*/SKILL.md | sort | uniq -c | sort -nr
```
