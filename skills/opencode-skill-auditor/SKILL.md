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

- Analyze the current set of OpenCode skills for redundancy, overlap, and duplication
- Identify granular functionality that can be extracted into reusable skill components
- Recommend modularization strategies to improve skill ecosystem efficiency
- Ensure proposed new skills follow DRY principles and OpenCode best practices
- Provide comprehensive gap analysis and skill optimization recommendations
- Generate detailed reports on skill interdependencies and coupling issues
- Suggest consolidation opportunities for closely related skillsets

## When to use me

Use this when:
- You need to analyze the existing skill ecosystem for optimization opportunities
- You want to identify redundant functionality across multiple skills
- You're planning to refactor or consolidate the skill library
- You need to ensure new skills won't duplicate existing capabilities
- You want to improve maintainability and reduce code duplication in skills
- You're developing a strategy for skill ecosystem growth and organization

Ask me to analyze specific skill directories, focus on particular capability areas, or provide comprehensive ecosystem audits.

## Prerequisites

- Access to the skills directory containing all OpenCode skill definitions
- Basic understanding of OpenCode skill structure and YAML frontmatter format
- Familiarity with modular design principles and DRY methodology
- Permission to read and analyze skill documentation files
- (Optional) Git history access for tracking skill evolution and dependencies

## Steps

1. **Skill Discovery**
   ```bash
   # Locate all skill definitions in the repository
   find . -name "SKILL.md" -type f | sort
   
   # Extract skill metadata for analysis
   grep -h "^name:" skills/*/SKILL.md | sort
   ```

2. **Capability Analysis**
   - Read each skill's "What I do" section to identify core functionalities
   - Extract and categorize capability patterns across all skills
   - Map skill descriptions to functional domains and use cases

3. **Redundancy Detection**
    - Compare skill descriptions for overlapping functionality
    - Identify similar capability patterns and use case scenarios
    - Flag skills with near-identical purposes or target audiences

4. **Duplicity Scoring Matrix**
    - Generate quantitative similarity scores (0-100%) between all skill pairs
    - Use semantic text comparison algorithms to measure description overlap
    - Calculate weighted scores based on name, description, purpose, and steps
    - Identify high-duplicity pairs (>70%) for potential merging
    - Flag medium-duplicity pairs (50-70%) for extraction opportunities
    - Generate visual matrix for easy identification of skill clusters

   **Scoring Methodology:**
   - Extract text content from each skill: name, description, "What I do", "When to use me", "Steps"
   - Use Python difflib SequenceMatcher for semantic similarity
   - Apply weights to different content types:
     - Name: 15% weight (important for functional overlap)
     - Description: 25% weight (defines scope and purpose)
     - "What I do": 30% weight (actual capabilities)
     - "When to use me": 20% weight (use case overlap)
     - "Steps": 10% weight (implementation approach)

   **Score Interpretation:**
   - **0-30%**: Low duplicity - skills are distinct and serve different purposes
   - **31-50%**: Moderate-low duplicity - some overlap but generally separate concerns
   - **51-70%**: Moderate-high duplicity - significant overlap, consider extracting common patterns
   - **71-85%**: High duplicity - strong overlap, consider consolidation
   - **86-100%**: Very high duplicity - skills likely redundant, recommend merging

   **Duplicity Matrix Generation:**
   ```python
   import difflib
   from pathlib import Path
   import yaml

   def extract_skill_content(skill_path):
       """Extract all text content from a skill file"""
       with open(skill_path, 'r') as f:
           content = f.read()

       # Parse YAML frontmatter
       if content.startswith('---'):
           parts = content.split('---', 2)
           frontmatter = parts[1]
           body = parts[2] if len(parts) > 2 else ''
       else:
           frontmatter = ''
           body = content

       # Extract key sections
       name_match = re.search(r'^name: (.+)$', frontmatter, re.MULTILINE)
       desc_match = re.search(r'^description: (.+)$', frontmatter, re.MULTILINE)
       what_i_do = extract_section(body, 'What I do', 'When to use me')
       when_to_use = extract_section(body, 'When to use me', 'Prerequisites')
       steps = extract_section(body, 'Steps', 'Best Practices')

       return {
           'name': name_match.group(1) if name_match else '',
           'description': desc_match.group(1) if desc_match else '',
           'what_i_do': what_i_do,
           'when_to_use': when_to_use,
           'steps': steps
       }

   def calculate_similarity(skill1_content, skill2_content):
       """Calculate weighted similarity score between two skills"""
       weights = {'name': 0.15, 'description': 0.25, 'what_i_do': 0.30, 'when_to_use': 0.20, 'steps': 0.10}

       scores = {}
       for key, weight in weights.items():
           text1 = skill1_content[key].lower()
           text2 = skill2_content[key].lower()
           similarity = difflib.SequenceMatcher(None, text1, text2).ratio()
           scores[key] = similarity * weight

       return int(sum(scores.values()) * 100)

   def generate_duplicity_matrix(skills_dir):
       """Generate pairwise duplicity scores for all skills"""
       skill_files = list(Path(skills_dir).glob('*/SKILL.md'))
       skills_data = {}

       for skill_file in skill_files:
           skills_data[skill_file.parent.name] = extract_skill_content(skill_file)

       matrix = {}
       skill_names = sorted(skills_data.keys())

       for skill1 in skill_names:
           matrix[skill1] = {}
           for skill2 in skill_names:
               if skill1 == skill2:
                   matrix[skill1][skill2] = 100
               else:
                   score = calculate_similarity(skills_data[skill1], skills_data[skill2])
                   matrix[skill1][skill2] = score

       return matrix

   def generate_matrix_report(matrix):
       """Generate formatted duplicity matrix report"""
       skills = sorted(matrix.keys())

       # Header row
       report = "| Skill |"
       for skill in skills:
           report += f" {skill} |"
       report += "\n" + "|" * (len(skills) + 1)

       # Data rows
       for skill1 in skills:
           report += f"| {skill1} |"
           for skill2 in skills:
               score = matrix[skill1][skill2]
               if score >= 70:
                   report += f" **{score}** |"  # High duplicity
               elif score >= 50:
                   report += f" *{score}* |"   # Medium duplicity
               else:
                   report += f" {score} |"
           report += "\n"

       return report
   ```

   **Duplicity Matrix Output Example:**
   ```
   | Skill                          | linting-workflow | python-ruff-linter | javascript-eslint-linter | ... |
   |-------------------------------|------------------|-------------------|--------------------------|-----|
   | linting-workflow              | 100              | 45                | 42                       | ... |
   | python-ruff-linter            | 45               | 100               | 38                       | ... |
   | javascript-eslint-linter      | 42               | 38                | 100                      | ... |
   | python-pytest-creator         | 35               | 40                | 32                       | ... |
   | ...                           | ...              | ...               | ...                      | ... |
   ```

   **Recommendation Logic:**
   - **Score >= 70%**: Recommend merging skills
     - Create new consolidated skill with combined functionality
     - Document migration path for users
     - Mark original skills as deprecated

   - **Score 50-69%**: Recommend extracting common patterns
     - Identify shared capabilities (e.g., test generation framework)
     - Create base framework skill
     - Refactor skills to extend framework skill
     - Reduce duplication by 30-50%

   - **Score < 50%**: Skills are sufficiently distinct
     - No action required
     - Monitor for evolving overlap

5. **Granularity Assessment**
    - Evaluate whether skills can be broken down into smaller, reusable components
    - Identify compound skills that contain multiple distinct capabilities
    - Assess potential for extracting shared functionality into base skills

6. **Token Cost Estimation**
    - Calculate estimated token consumption for loading each skill
    - Compare skill sizes against subagent token budget constraints
    - Identify oversized skills that exceed reasonable loading limits
    - Provide optimization recommendations for reducing token usage
    - Prioritize skills for token optimization based on usage frequency

   **Token Cost Calculation:**
   - Base cost: Count total characters in skill file (including frontmatter)
   - Token conversion: Use industry standard ~4 characters per token
   - Overhead factor: Add 10% for parsing and processing overhead
   - Formula: `(character_count / 4) * 1.1 = estimated_tokens`

   **Budget Guidelines:**
   - Framework skills: Target < 2000 tokens (8KB file size)
   - Language-specific skills: Target < 1500 tokens (6KB file size)
   - Workflow skills: Target < 3000 tokens (12KB file size) - these can be larger due to complexity
   - Subagent skills: Must stay within 2000-2500 tokens depending on agent specialization

   **Optimization Strategies:**

   | Strategy | Token Reduction | Applicability | Example |
   |----------|-----------------|---------------|---------|
   | Extract code blocks to external files | 20-40% | Skills with >5 code examples | Move bash/Python snippets to examples/ |
   | Simplify verbose explanations | 15-30% | Skills with detailed tutorials | Replace with concise steps |
   | Use reference links instead of duplication | 10-25% | Skills referencing other skills | "See X skill for details" |
   | Consolidate similar sections | 10-20% | Skills with repetitive content | Merge similar "Common Issues" |
   | Remove redundant examples | 5-15% | Skills with multiple overlapping examples | Keep 1-2 representative examples |
   | Minimize frontmatter metadata | 2-5% | Skills with extensive metadata | Keep only essential fields |

   **Token Analysis Commands:**
   ```bash
   # Calculate token estimate for a single skill
   estimate_skill_tokens() {
     local skill_file=$1
     local char_count=$(wc -m < "$skill_file")
     local tokens=$(echo "$char_count / 4 * 1.1" | bc -l | cut -d. -f1)
     echo "$tokens"
   }

   # Generate token cost report for all skills
   generate_token_report() {
     echo "Skill                        | Chars    | Tokens   | Status    | Recommendations"
     echo "-----------------------------|----------|----------|-----------|------------------"

     for skill in skills/*/SKILL.md; do
       local skill_name=$(basename "$(dirname "$skill")")
       local char_count=$(wc -m < "$skill")
       local tokens=$(estimate_skill_tokens "$skill")
       local status="OK"

       if [ "$tokens" -gt 3000 ]; then
         status="CRITICAL"
       elif [ "$tokens" -gt 2000 ]; then
         status="WARNING"
       fi

       # Check for code blocks that can be extracted
       local code_blocks=$(grep -c '```' "$skill")
       local recommendations=""

       if [ "$code_blocks" -gt 5 ]; then
         recommendations="Extract $(echo "$code_blocks / 2" | bc) code blocks"
       elif [ "$char_count" -gt 8000 ]; then
         recommendations="Consider splitting into smaller skills"
       fi

       printf "%-28s | %8d | %8d | %-9s | %s\n" \
         "$skill_name" "$char_count" "$tokens" "$status" "$recommendations"
     done | sort -t'|' -k3 -nr
   }

   # Find oversized skills exceeding budget
   find_oversized_skills() {
     local budget=${1:-2000}

     for skill in skills/*/SKILL.md; do
       local tokens=$(estimate_skill_tokens "$skill")
       if [ "$tokens" -gt "$budget" ]; then
         echo "$(basename "$(dirname "$skill")"): $tokens tokens (exceeds $budget)"
       fi
     done
   }

   # Calculate total token cost for loading all skills
   calculate_total_cost() {
     local total=0
     for skill in skills/*/SKILL.md; do
       total=$((total + $(estimate_skill_tokens "$skill")))
     done
     echo "Total tokens for all skills: $total"
     echo "Approximate cost at \$1/1M tokens: \$(echo "$total / 1000000" | bc -l)"
   }

   # Identify optimization opportunities
   find_optimization_targets() {
     echo "=== High-impact optimization targets ==="

     for skill in skills/*/SKILL.md; do
       local skill_name=$(basename "$(dirname "$skill")")
       local tokens=$(estimate_skill_tokens "$skill")
       local char_count=$(wc -m < "$skill")

       # Check for optimization opportunities
       local code_blocks=$(grep -c '```' "$skill")
       local has_bash=$(grep -q '```bash' "$skill" && echo "yes" || echo "no")
       local has_python=$(grep -q '```python' "$skill" && echo "yes" || echo "no")
       local line_count=$(wc -l < "$skill")

       local potential_savings=0

       if [ "$code_blocks" -gt 5 ]; then
         potential_savings=$((potential_savings + (code_blocks * 150)))
       fi

       if [ "$line_count" -gt 200 ]; then
         potential_savings=$((potential_savings + (line_count * 2)))
       fi

       if [ "$potential_savings" -gt 200 ]; then
         echo "$skill_name: ~$potential_savings tokens potential savings (current: $tokens)"
         echo "  - Code blocks: $code_blocks"
         echo "  - Lines: $line_count"
         echo "  - Bash: $has_bash, Python: $has_python"
         echo
       fi
     done | sort -t':' -k2 -nr
   }
   ```

   **Token Cost Report Example:**
   ```
   Skill                        | Chars    | Tokens   | Status    | Recommendations
   -----------------------------|----------|----------|-----------|------------------
   nextjs-pr-workflow           | 12450    | 3423     | CRITICAL  | Extract 12 code blocks
   opencode-skill-creation      | 9823     | 2701     | WARNING   | Split into smaller skills
   git-issue-creator            | 8456     | 2325     | WARNING   | Extract 8 code blocks
   opentofu-provisioning-workflow| 7892    | 2167     | WARNING   | Consolidate sections
   linting-workflow             | 5234     | 1438     | OK        |
   python-pytest-creator       | 4123     | 1133     | OK        |
   ```

   **Expected Token Reduction:**
   - Extracting code blocks: 20-40% reduction
   - Simplifying verbose documentation: 15-30% reduction
   - Removing redundancy: 10-25% reduction
   - Overall target: 20-40% reduction in average skill loading cost

7. **Dependency Mapping**
     - Analyze skill interdependencies and coupling relationships
     - Identify skills that reference or build upon other skills
     - Map the skill hierarchy and dependency graph

8. **Subagent Suitability Analysis**
    - Extract tool requirements from each skill's "Steps", "Best Practices", and "Analysis Commands" sections
    - Compare skill tool requirements against subagent restrictions defined in `.AGENTS.md`
    - Generate suitability matrix showing which subagents can load which skills
    - Identify skills suitable for primary agents vs subagents
    - Validate MCP server requirements against subagent permissions
    - Provide recommendations for skill placement based on token budgets and access patterns

   **Tool Requirements Extraction:**
   - Scan skill documentation for bash commands requiring system access
   - Identify MCP server usage patterns (e.g., atlassian, drawio, zai-mcp-server)
   - Detect file modification patterns (write, edit operations)
   - Parse skill content for task/delegation patterns requiring `task` tool

   **Subagent Compatibility Logic:**
   ```bash
   # Check if skill requires tools not available to a subagent
   analyze_skill_compatibility() {
     local skill_file=$1
     local subagent=$2

     # Extract required tools from skill
     required_tools=$(extract_tool_requirements "$skill_file")

     # Get allowed tools from .AGENTS.md
     allowed_tools=$(get_subagent_allowed_tools "$subagent")

     # Check for forbidden tools
     if contains "$required_tools" "bash" && [ "$subagent" != "primary" ]; then
       return 1 # Incompatible: requires bash
     fi

     if contains "$required_tools" "task" && [ "$subagent" != "primary" ]; then
       return 1 # Incompatible: requires task tool
     fi

     # Check MCP server compatibility
     required_mcp=$(extract_mcp_servers "$skill_file")
     allowed_mcp=$(get_subagent_mcp_access "$subagent")

     if ! subset_of "$required_mcp" "$allowed_mcp"; then
       return 1 # Incompatible: MCP server not allowed
     fi

     return 0 # Compatible
   }
   ```

   **Suitability Matrix Output Example:**
   ```
   Skill                          | Primary | Linting | Testing | Git | Docs | Infrastructure | Workflow |
   ------------------------------ | ------- | ------- | ------- | --- | ---- | -------------- | -------- |
   linting-workflow              | ✓       | ✓       | ✓       | ✗   | ✗    | ✗              | ✗        |
   python-pytest-creator          | ✓       | ✗       | ✓       | ✗   | ✗    | ✗              | ✗        |
   git-issue-creator              | ✓       | ✗       | ✗       | ✓   | ✗    | ✗              | ✓        |
   opentofu-aws-explorer          | ✓       | ✗       | ✗       | ✗   | ✗    | ✓              | ✗        |
   opencode-skill-creation        | ✓       | ✗       | ✗       | ✗   | ✗    | ✗              | ✗        |
   ```

   **Placement Recommendations:**
   - Primary agents: Skills requiring bash, task, todowrite/todoread, question, or full MCP access
   - Linting subagent: Skills only requiring read/write/edit/glob/grep with linting specialization
   - Testing subagent: Skills only requiring read/write/edit/glob/grep with testing specialization
   - Git-workflow subagent: Skills requiring atlassian MCP with git/JIRA specialization
   - Documentation subagent: Skills only requiring read/write/edit/glob/grep with documentation specialization
   - Opentofu subagent: Skills only requiring read/write/edit/glob/grep with OpenTofu specialization
   - Workflow subagent: Skills requiring atlassian MCP with workflow/Git/JIRA specialization

9. **Recommendation Generation**
    - Propose specific modularization strategies with concrete examples
    - Suggest skill consolidation opportunities with migration paths
    - Recommend new granular skills to fill identified gaps
    - Provide priority rankings based on impact and feasibility

10. **Subagent-Specific Recommendations**
    - Differentiate recommendations for primary agents vs subagents
    - Provide tool restriction compliance table for each subagent type
    - Suggest delegation strategies for workflows requiring multiple skill types
    - Recommend token budget allocation patterns per subagent specialization
    - Document optimal skill loading sequences for subagent operations

   **Tool Restriction Compliance Table:**

   | Subagent | Allowed Tools | Allowed MCP | Recommended Skills | Forbidden Patterns |
   |----------|--------------|-------------|-------------------|-------------------|
   | `linting-subagent` | read, write, edit, glob, grep | None | linting-workflow, python-ruff-linter, javascript-eslint-linter | bash, task, todowrite/todoread, MCP servers |
   | `testing-subagent` | read, write, edit, glob, grep | None | test-generator-framework, python-pytest-creator, nextjs-unit-test-creator | bash, task, todowrite/todoread, MCP servers |
   | `git-workflow-subagent` | read, write, edit, glob, grep | atlassian | git-issue-creator, git-issue-labeler, git-issue-updater, git-pr-creator, git-semantic-commits | bash, task, todowrite/todoread |
   | `documentation-subagent` | read, write, edit, glob, grep | None | docstring-generator, coverage-readme-workflow | bash, task, todowrite/todoread, MCP servers |
   | `opentofu-explorer-subagent` | read, write, edit, glob, grep | None | All OpenTofu skills | bash, task, todowrite/todoread, MCP servers |
   | `workflow-subagent` | read, write, edit, glob, grep | atlassian | pr-creation-workflow, nextjs-pr-workflow, jira-git-workflow | bash, task, todowrite/todoread |

   **Delegation Strategy Pseudocode:**

   ```python
   def determine_ownership(skill_name, task_context):
       """
       Determine which agent should handle a task based on skill requirements
       and current execution context
       """
       # Extract skill requirements
       tool_requirements = get_tool_requirements(skill_name)
       mcp_requirements = get_mcp_requirements(skill_name)
       token_cost = estimate_skill_tokens(skill_name)

       # Check if primary agent is required
       if requires_bash(tool_requirements) or requires_task(tool_requirements):
           return 'primary-agent'

       if requires_todowrite_todoread(tool_requirements):
           return 'primary-agent'

       if requires_question(tool_requirements):
           return 'primary-agent'

       # Check MCP compatibility with subagents
       if requires_atlassian(mcp_requirements):
           # Can be handled by git-workflow-subagent or workflow-subagent
           if is_git_jira_task(task_context):
               return 'git-workflow-subagent'
           elif is_workflow_task(task_context):
               return 'workflow-subagent'
           else:
               return 'primary-agent'

       # Check tool-only compatibility
       if all(tool in ['read', 'write', 'edit', 'glob', 'grep']
              for tool in tool_requirements):
           # Determine subagent type based on skill domain
           domain = get_skill_domain(skill_name)

           if domain == 'linting':
               return 'linting-subagent'
           elif domain == 'testing':
               return 'testing-subagent'
           elif domain == 'documentation':
               return 'documentation-subagent'
           elif domain == 'opentofu':
               return 'opentofu-explorer-subagent'

       # Default to primary agent
       return 'primary-agent'
   ```

   **Token Budget Allocation Recommendations:**

   | Subagent Type | Base Budget | Recommended Skills | Loading Strategy |
   |---------------|-------------|-------------------|-----------------|
   | `linting-subagent` | 2500 tokens | linting-workflow + 1-2 linter skills | Load framework + language-specific linters |
   | `testing-subagent` | 2500 tokens | test-generator-framework + 1-2 test generators | Load framework + language-specific generators |
   | `git-workflow-subagent` | 3000 tokens | 2-4 git workflow skills | Load based on task type (issue vs PR) |
   | `documentation-subagent` | 2000 tokens | docstring-generator | Load as needed per task |
   | `opentofu-explorer-subagent` | 3000 tokens | 2-3 OpenTofu skills | Load relevant provider/explorers |
   | `workflow-subagent` | 3000 tokens | 1-2 workflow skills + git/JIRA skills | Load based on workflow type |

   **Optimal Loading Sequences:**

   For complex workflows requiring multiple subagent interactions:

   ```python
   # Example: nextjs-pr-workflow execution sequence
   def execute_nextjs_pr_workflow(task):
       # Phase 1: Testing (subagent)
       testing_subagent = launch_subagent('testing-subagent')
       testing_subagent.load_skill('nextjs-unit-test-creator')
       test_results = testing_subagent.run_tests()

       # Phase 2: Linting (subagent)
       linting_subagent = launch_subagent('linting-subagent')
       linting_subagent.load_skill('javascript-eslint-linter')
       lint_results = linting_subagent.run_linting()

       # Phase 3: Git Workflow (subagent)
       if test_results.passed and lint_results.passed:
           git_subagent = launch_subagent('git-workflow-subagent')
           git_subagent.load_skill('git-pr-creator')
           git_subagent.load_skill('git-issue-updater')
           git_subagent.create_pr_with_updates()

       # Phase 4: Documentation (subagent, optional)
       if task.update_docs:
           docs_subagent = launch_subagent('documentation-subagent')
           docs_subagent.load_skill('docstring-generator')
           docs_subagent.generate_docstrings()

       # Return to primary agent for final coordination
       return aggregate_results(test_results, lint_results)
   ```

   **Subagent-Specific Best Practices:**

   - **Linting Subagent**:
     - Load framework skill + 1-2 language-specific linters max
     - Use primary agent for git operations and task management
     - Report findings back to primary agent for action

   - **Testing Subagent**:
     - Load framework skill + language-specific test generator
     - Never execute tests (requires bash) - generate test files only
     - Delegate test execution to primary agent via bash

   - **Git Workflow Subagent**:
     - Load 2-3 related workflow skills at a time
     - Use atlassian MCP for GitHub/JIRA integration
     - Delegate bash git commands to primary agent

   - **Documentation Subagent**:
     - Load only docstring-generator skill as needed
     - Generate docstrings in isolation
     - Delegate file writes and edits via primary agent coordination

   - **OpenTofu Subagent**:
     - Load provider-specific explorers based on task
     - Generate OpenTofu configurations only
     - Delegate tofu execution and state management to primary agent

   - **Workflow Subagent**:
     - Load 1-2 workflow skills + supporting git/JIRA skills
     - Coordinate multi-phase workflows across subagents
     - Use atlassian MCP for integration operations

11. **Best Practices Validation**
    - Ensure proposed changes follow OpenCode naming conventions
    - Validate that new skill structures maintain proper YAML frontmatter
    - Verify that modularization preserves existing functionality

## Best Practices

- **Systematic Analysis**: Process skills in logical groups by capability domain or workflow type
- **Documentation-First**: Always preserve existing functionality and user-facing behavior
- **Incremental Changes**: Propose modularization in stages to minimize disruption
- **Backward Compatibility**: Ensure existing integrations continue to work during transitions
- **Clear Naming**: Use descriptive, distinguishable names for new granular skills
- **Cross-Reference**: Maintain clear documentation of relationships between original and modularized skills
- **Community Input**: Consider existing usage patterns and community feedback when proposing changes

## Common Issues

**Issue: Skills appear similar but serve different contexts**
- Solution: Focus on specific use cases and target audiences in your analysis
- Consider context-specific optimizations that justify separate skills

**Issue: Over-granularization leading to skill fragmentation**
- Solution: Balance between reusability and usability
- Group related capabilities logically while maintaining meaningful skill boundaries

**Issue: Missing documentation for skill interdependencies**
- Solution: Create dependency mapping as part of your analysis
- Document implicit relationships and usage patterns

**Issue: Legacy skills with outdated structures**
- Solution: Prioritize updates to skills that don't follow current best practices
- Provide migration paths for modernizing skill structures

**Issue: Difficulty measuring impact of proposed changes**
- Solution: Use usage metrics and community feedback when available
- Implement A/B testing or gradual rollouts for significant changes

## Analysis Commands

```bash
# Quick skill overview with metadata
for skill in skills/*/SKILL.md; do
  echo "=== $(basename $(dirname "$skill")) ==="
  grep -E "^name:|^description:|^metadata:" "$skill"
  echo
done

# Find skills with similar descriptions
grep -h "^description:" skills/*/SKILL.md | sort | uniq -c | sort -nr

# Analyze skill distribution by workflow type
grep -A1 "workflow:" skills/*/SKILL.md | grep "workflow:" | sort | uniq -c

# Check for naming convention compliance
ls skills/ | grep -E "^[a-z0-9]+(-[a-z0-9]+)*$"
```
# ============================================================================
# NEW: Subagent Suitability Analysis Commands
# ============================================================================

# Extract tool requirements from a skill
extract_tool_requirements() {
  local skill_file=$1
  echo "=== Tool Requirements for $(basename "$(dirname "$skill_file")") ==="

  # Check for bash commands in code blocks
  bash_blocks=$(grep -c '```bash' "$skill_file" || echo "0")
  echo "Bash code blocks: $bash_blocks"

  # Check for Python code blocks
  python_blocks=$(grep -c '```python' "$skill_file" || echo "0")
  echo "Python code blocks: $python_blocks"

  # Check for task/delegation patterns
  task_refs=$(grep -c 'task\|delegate\|subagent' "$skill_file" || echo "0")
  echo "Task/delegation references: $task_refs"

  # Check for MCP server references
  atlassian_refs=$(grep -c 'atlassian' "$skill_file" || echo "0")
  drawio_refs=$(grep -c 'drawio' "$skill_file" || echo "0")
  zai_refs=$(grep -c 'zai-mcp-server' "$skill_file" || echo "0")
  echo "MCP references - atlassian: $atlassian_refs, drawio: $drawio_refs, zai: $zai_refs"

  # Check for file operations
  write_refs=$(grep -c '\bwrite\b' "$skill_file" || echo "0")
  edit_refs=$(grep -c '\bedit\b' "$skill_file" || echo "0")
  echo "File operations - write: $write_refs, edit: $edit_refs"

  # Check for question/interactive patterns
  question_refs=$(grep -c '\bquestion\b' "$skill_file" || echo "0")
  echo "Question patterns: $question_refs"
}

# Generate subagent suitability matrix
generate_suitability_matrix() {
  local agents=(primary linting-subagent testing-subagent git-workflow-subagent
                documentation-subagent opentofu-explorer-subagent workflow-subagent)
  local skills=($(find skills/ -name "SKILL.md" -type f | xargs -n1 dirname | xargs -n1 basename))

  echo "Skill"
  printf "%-28s " ""
  for agent in "${agents[@]}"; do
    printf "%-20s " "$agent"
  done
  echo

  for skill in "${skills[@]}"; do
    printf "%-28s " "$skill"
    for agent in "${agents[@]}"; do
      # Simple heuristic: primary agents can load all skills
      # Subagents can only load skills without bash/task
      if [[ "$agent" == "primary" ]]; then
        printf "%-20s " "✓"
      else
        # Check if skill requires restricted tools
        skill_file="skills/$skill/SKILL.md"
        has_bash=$(grep -q '```bash' "$skill_file" && echo "1" || echo "0")
        has_task=$(grep -q '\btask\b' "$skill_file" && echo "1" || echo "0")
        has_mcp=$(grep -q 'atlassian\|drawio\|zai-mcp-server' "$skill_file" && echo "1" || echo "0")

        # Determine compatibility
        compatible="✓"
        if [[ "$has_bash" == "1" || "$has_task" == "1" ]]; then
          compatible="✗"
        fi

        # Check MCP compatibility for specific subagents
        if [[ "$has_mcp" == "1" ]]; then
          if [[ ! "$agent" =~ (git-workflow|workflow) ]]; then
            compatible="✗"
          fi
        fi

        printf "%-20s " "$compatible"
      fi
    done
    echo
  done
}

# ============================================================================
# NEW: Duplicity Scoring Matrix Commands
# ============================================================================

# Generate duplicity matrix using Python
generate_duplicity_matrix() {
  python3 - << 'PYEOF'
import difflib
import re
from pathlib import Path

def extract_text_from_skill(skill_path):
    """Extract key text sections from a skill file"""
    with open(skill_path, 'r') as f:
        content = f.read()

    # Extract name and description from YAML frontmatter
    name_match = re.search(r'^name: (.+)$', content, re.MULTILINE)
    desc_match = re.search(r'^description: (.+)$', content, re.MULTILINE)

    name = name_match.group(1) if name_match else ''
    desc = desc_match.group(1) if desc_match else ''

    # Extract key sections
    def extract_section(content, start_marker, end_marker):
        start_idx = content.find(start_marker)
        end_idx = content.find(end_marker)
        if start_idx == -1 or end_idx == -1:
            return ''
        return content[start_idx:end_idx]

    what_i_do = extract_section(content, '## What I do', '## When to use me')
    when_to_use = extract_section(content, '## When to use me', '## Prerequisites')
    steps = extract_section(content, '## Steps', '## Best Practices')

    return {
        'name': name,
        'description': desc,
        'what_i_do': what_i_do,
        'when_to_use': when_to_use,
        'steps': steps
    }

def calculate_similarity(skill1, skill2):
    """Calculate weighted similarity score between two skills"""
    weights = {
        'name': 0.15,
        'description': 0.25,
        'what_i_do': 0.30,
        'when_to_use': 0.20,
        'steps': 0.10
    }

    scores = {}
    for key, weight in weights.items():
        text1 = skill1[key].lower()
        text2 = skill2[key].lower()
        similarity = difflib.SequenceMatcher(None, text1, text2).ratio()
        scores[key] = similarity * weight

    return int(sum(scores.values()) * 100)

# Get all skill files
skills_dir = Path('skills')
skill_files = list(skills_dir.glob('*/SKILL.md'))
skills_data = {}

for skill_file in skill_files:
    skills_data[skill_file.parent.name] = extract_text_from_skill(skill_file)

# Generate matrix
matrix = {}
skill_names = sorted(skills_data.keys())

for skill1 in skill_names:
    matrix[skill1] = {}
    for skill2 in skill_names:
        if skill1 == skill2:
            matrix[skill1][skill2] = 100
        else:
            score = calculate_similarity(skills_data[skill1], skills_data[skill2])
            matrix[skill1][skill2] = score

# Print matrix in markdown format
print("| Skill |", end="")
for skill in skill_names:
    print(f" {skill} |", end="")
print()
print("|" + "---|" * (len(skill_names) + 1))

# Data rows
for skill1 in skill_names:
    print(f"| {skill1} |", end="")
    for skill2 in skill_names:
        score = matrix[skill1][skill2]
        if score >= 70:
            print(f" **{score}** |", end="")
        elif score >= 50:
            print(f" *{score}* |", end="")
        else:
            print(f" {score} |", end="")
    print()
PYEOF
}

# Find high-duplicity skill pairs
find_high_duplicity() {
  local threshold=${1:-70}
  echo "=== Skills with duplicity >= ${threshold}% ==="

  python3 << PYEOF
import difflib
import re
from pathlib import Path

def extract_text_from_skill(skill_path):
    with open(skill_path, 'r') as f:
        content = f.read()
    name_match = re.search(r'^name: (.+)$', content, re.MULTILINE)
    desc_match = re.search(r'^description: (.+)$', content, re.MULTILINE)
    what_i_do = content[content.find('## What I do'):content.find('## When to use me')]
    return {
        'name': name_match.group(1) if name_match else '',
        'description': desc_match.group(1) if desc_match else '',
        'what_i_do': what_i_do
    }

def calculate_similarity(skill1, skill2):
    weights = {'name': 0.15, 'description': 0.25, 'what_i_do': 0.30}
    scores = {}
    for key, weight in weights.items():
        similarity = difflib.SequenceMatcher(None, skill1[key].lower(), skill2[key].lower()).ratio()
        scores[key] = similarity * weight
    return int(sum(scores.values()) * 100)

skills_dir = Path('skills')
skill_files = list(skills_dir.glob('*/SKILL.md'))
skills_data = {sf.parent.name: extract_text_from_skill(sf) for sf in skill_files}
skill_names = sorted(skills_data.keys())
threshold = ${threshold}

for i, skill1 in enumerate(skill_names):
    for skill2 in skill_names[i+1:]:
        score = calculate_similarity(skills_data[skill1], skills_data[skill2])
        if score >= threshold:
            print(f"{skill1} <-> {skill2}: {score}%")
PYEOF
}

# ============================================================================
# NEW: Token Cost Estimation Commands
# ============================================================================

# Calculate token estimate for a skill
estimate_tokens() {
  local skill_file=$1
  local char_count=$(wc -m < "$skill_file")
  local tokens=$(python3 -c "print(int($char_count / 4 * 1.1))")
  echo "$tokens"
}

# Generate comprehensive token cost report
generate_token_report() {
  echo "Skill                        | Chars    | Tokens   | Status    | Code Blocks | Recommendations"
  echo "-----------------------------|----------|----------|-----------|-------------|------------------"

  for skill in skills/*/SKILL.md; do
    local skill_name=$(basename "$(dirname "$skill")")
    local char_count=$(wc -m < "$skill")
    local tokens=$(estimate_tokens "$skill")
    local status="OK"
    local code_blocks=$(grep -c '```' "$skill" || echo "0")
    local recommendations=""

    if [ "$tokens" -gt 3000 ]; then
      status="CRITICAL"
    elif [ "$tokens" -gt 2000 ]; then
      status="WARNING"
    fi

    if [ "$code_blocks" -gt 6 ]; then
      local extractable=$((code_blocks / 2))
      recommendations="Extract $extractable code blocks"
    elif [ "$char_count" -gt 8000 ]; then
      recommendations="Consider splitting"
    fi

    printf "%-28s | %8d | %8d | %-9s | %11d | %s\n" \
      "$skill_name" "$char_count" "$tokens" "$status" "$code_blocks" "$recommendations"
  done | sort -t'|' -k3 -nr
}

# Find oversized skills
find_oversized_skills() {
  local budget=${1:-2000}

  echo "=== Skills exceeding ${budget} token budget ==="
  for skill in skills/*/SKILL.md; do
    local tokens=$(estimate_tokens "$skill")
    if [ "$tokens" -gt "$budget" ]; then
      local skill_name=$(basename "$(dirname "$skill")")
      local char_count=$(wc -m < "$skill")
      local code_blocks=$(grep -c '```' "$skill" || echo "0")
      echo "$skill_name: $tokens tokens ($char_count chars, $code_blocks code blocks)"
    fi
  done | sort -t':' -k2 -nr
}

# Calculate total token cost
calculate_total_cost() {
  local total=0
  for skill in skills/*/SKILL.md; do
    total=$((total + $(estimate_tokens "$skill")))
  done
  echo "Total tokens for all skills: $total"
  echo "Estimated cost (assuming industry standard ~4 chars/token): $((total / 1000000))M tokens"
}

# Find high-impact optimization targets
find_optimization_targets() {
  echo "=== High-impact optimization targets (potential savings > 200 tokens) ==="
  for skill in skills/*/SKILL.md; do
    local skill_name=$(basename "$(dirname "$skill")")
    local tokens=$(estimate_tokens "$skill")
    local code_blocks=$(grep -c '```' "$skill" || echo "0")
    local line_count=$(wc -l < "$skill")
    local potential_savings=0

    if [ "$code_blocks" -gt 6 ]; then
      potential_savings=$((potential_savings + ((code_blocks / 2) * 150)))
    fi

    if [ "$line_count" -gt 200 ]; then
      potential_savings=$((potential_savings + (line_count * 2)))
    fi

    if [ "$potential_savings" -gt 200 ]; then
      echo "$skill_name: ~$potential_savings tokens potential savings (current: $tokens)"
      echo "  - Code blocks: $code_blocks (extract ~$((code_blocks / 2)))"
      echo "  - Lines: $line_count (consolidate verbose sections)"
      echo
    fi
  done | sort -t':' -k2 -nr
}
