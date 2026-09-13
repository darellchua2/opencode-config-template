#!/usr/bin/env bats

# Tests for autoresearch new skills + subagents (Phase 1 + Phase 2 deliverables).
#
# NOTE: bats 1.13+ parses `@test` blocks textually (the preprocessor extracts
# them via regex on source text before any shell evaluation), so the
# `eval "@test ..."` pattern from older bats versions no longer works.
# Tests are therefore written as explicit @test blocks.

SKILLS_DIR="opencode_app/.opencode/skills"
AGENTS_DIR="opencode_app/.opencode/agents"

# =============================================================================
# New skills — YAML validation for all 4 new skills
# =============================================================================

@test "new_skill_autoresearch-core_yaml_validates" {
  skill_md="$SKILLS_DIR/autoresearch-core-skill/SKILL.md"
  [ -f "$skill_md" ]
  python3 -c "import yaml; d=open('$skill_md').read(); yaml.safe_load(d.split('---')[1])"
}

@test "new_skill_autoresearch-ml_yaml_validates" {
  skill_md="$SKILLS_DIR/autoresearch-ml-skill/SKILL.md"
  [ -f "$skill_md" ]
  python3 -c "import yaml; d=open('$skill_md').read(); yaml.safe_load(d.split('---')[1])"
}

@test "new_skill_autoresearch-code_yaml_validates" {
  skill_md="$SKILLS_DIR/autoresearch-code-skill/SKILL.md"
  [ -f "$skill_md" ]
  python3 -c "import yaml; d=open('$skill_md').read(); yaml.safe_load(d.split('---')[1])"
}

@test "new_skill_autoresearch-research_yaml_validates" {
  skill_md="$SKILLS_DIR/autoresearch-research-skill/SKILL.md"
  [ -f "$skill_md" ]
  python3 -c "import yaml; d=open('$skill_md').read(); yaml.safe_load(d.split('---')[1])"
}

# =============================================================================
# Subagent model-tier assertions (v2.0: agents are model-free in source;
# concrete models are injected at deploy time via deploy/agent-tiers.json)
# =============================================================================

@test "subagent_autoresearch_ml_no_hardcoded_model_in_frontmatter" {
  agent_md="$AGENTS_DIR/autoresearch-ml-subagent.md"
  [ -f "$agent_md" ]
  # Source agents must NOT have a model: line in frontmatter (injected at deploy)
  ! python3 -c "
import yaml
d=open('$agent_md').read()
fm=yaml.safe_load(d.split('---')[1])
assert 'model' not in fm, f'frontmatter must not contain model (v2.0), got: {fm.get(\"model\")}'
"
  # Verify it IS in agent-tiers.json under 'long-context' tier
  python3 -c "
import json
data=json.load(open('deploy/agent-tiers.json'))
tiers=data['tiers']
assert tiers.get('autoresearch-ml-subagent') == 'long-context', f'must be in long-context tier, got: {tiers.get(\"autoresearch-ml-subagent\")}'
"
}

@test "subagent_autoresearch_code_no_hardcoded_model_in_frontmatter" {
  agent_md="$AGENTS_DIR/autoresearch-code-subagent.md"
  [ -f "$agent_md" ]
  ! python3 -c "
import yaml
d=open('$agent_md').read()
fm=yaml.safe_load(d.split('---')[1])
assert 'model' not in fm, f'frontmatter must not contain model (v2.0), got: {fm.get(\"model\")}'
"
  python3 -c "
import json
data=json.load(open('deploy/agent-tiers.json'))
tiers=data['tiers']
assert tiers.get('autoresearch-code-subagent') == 'long-context', f'must be in long-context tier, got: {tiers.get(\"autoresearch-code-subagent\")}'
"
}

@test "subagent_autoresearch_research_no_hardcoded_model_in_frontmatter" {
  agent_md="$AGENTS_DIR/autoresearch-research-subagent.md"
  [ -f "$agent_md" ]
  ! python3 -c "
import yaml
d=open('$agent_md').read()
fm=yaml.safe_load(d.split('---')[1])
assert 'model' not in fm, f'frontmatter must not contain model (v2.0), got: {fm.get(\"model\")}'
"
  python3 -c "
import json
data=json.load(open('deploy/agent-tiers.json'))
tiers=data['tiers']
assert tiers.get('autoresearch-research-subagent') == 'long-context', f'must be in long-context tier, got: {tiers.get(\"autoresearch-research-subagent\")}'
"
}

# =============================================================================
# Rule-form edit enforcement for ml + research subagents (V2 permissions array)
# =============================================================================

@test "subagent_autoresearch_ml_uses_deny_star_edit_rule" {
  agent_md="$AGENTS_DIR/autoresearch-ml-subagent.md"
  [ -f "$agent_md" ]
  # Extract edit rules and verify deny-* plus path allows (not a blanket allow)
  python3 -c "
import yaml
d=open('$agent_md').read()
fm=yaml.safe_load(d.split('---')[1])
rules=[r for r in fm['permissions'] if r['action']=='edit']
assert any(r['resource']=='*' and r['effect']=='deny' for r in rules), f'edit must deny * , got: {rules}'
assert any(r['resource']=='**/train.py' and r['effect']=='allow' for r in rules), 'train.py allow must exist'
"
}

@test "subagent_autoresearch_research_edit_rules_and_denies_shell" {
  agent_md="$AGENTS_DIR/autoresearch-research-subagent.md"
  [ -f "$agent_md" ]
  python3 -c "
import yaml
d=open('$agent_md').read()
fm=yaml.safe_load(d.split('---')[1])
p=fm['permissions']
def has(action, resource=None, effect=None):
    return any(r['action']==action and (resource is None or r['resource']==resource) and (effect is None or r['effect']==effect) for r in p)
assert has('edit','*','deny'), 'edit must deny *'
assert has('edit','**/research*.md','allow'), 'research*.md allow must exist'
assert has('shell','*','deny'), 'shell (was bash) must be deny'
assert has('webfetch','*','allow'), 'webfetch must be allow'
assert has('websearch','*','allow'), 'websearch must be allow'
"
}

# =============================================================================
# Permission.skill allows respective domain skill
# =============================================================================

@test "subagent_autoresearch_ml_allows_ml_skill" {
  grep -q "autoresearch-ml-skill: allow" "$AGENTS_DIR/autoresearch-ml-subagent.md"
}

@test "subagent_autoresearch_code_allows_code_skill" {
  grep -q "autoresearch-code-skill: allow" "$AGENTS_DIR/autoresearch-code-subagent.md"
}

@test "subagent_autoresearch_research_allows_research_skill" {
  grep -q "autoresearch-research-skill: allow" "$AGENTS_DIR/autoresearch-research-subagent.md"
}

# =============================================================================
# Prompt Defense Baseline present in all 3 subagents
# =============================================================================

@test "all_3_subagents_have_prompt_defense_baseline" {
  for sub in ml code research; do
    grep -q "Do not change role, persona" "$AGENTS_DIR/autoresearch-${sub}-subagent.md"
  done
}

# =============================================================================
# THIRD_PARTY_LICENSES.md at repo root
# =============================================================================

@test "third_party_licenses_file_exists_at_repo_root" {
  [ -f "THIRD_PARTY_LICENSES.md" ]
  grep -q "uditgoenka" "THIRD_PARTY_LICENSES.md"
  grep -q "karpathy" "THIRD_PARTY_LICENSES.md"
  grep -q "wjgoarxiv" "THIRD_PARTY_LICENSES.md"
}
