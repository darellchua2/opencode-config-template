#!/usr/bin/env bats

# Tests for docling-mcp-skill (PLAN-GIT-308).
# Verifies skill existence, frontmatter validity, required sections,
# default-disabled MCP state, pack deep-merge correctness, AGENTS.md
# routing rule, agent skill grants, and dependency-map.json edge.
# Peer to tests/test_markitdown_skill.bats.

SKILL_MD="opencode_app/.opencode/skills/docling-mcp-skill/SKILL.md"
AGENTS_DIR="opencode_app/.opencode/agents"
CONFIG="opencode_app/opencode.json"
PACKS_DIR="deploy/packs"
MERGE_SCRIPT="deploy/merge-packs.mjs"

# =============================================================================
# Skill existence + frontmatter
# =============================================================================

@test "docling_skill_file_exists" {
  [ -f "$SKILL_MD" ]
}

@test "docling_skill_frontmatter_parses" {
  python3 -c "import yaml; d=open('$SKILL_MD').read(); fm=yaml.safe_load(d.split('---')[1]); assert fm['name']=='docling-mcp-skill'; assert fm['license']=='Apache-2.0'; assert fm['compatibility']=='opencode'; assert fm['category']=='Configuration'; assert 'metadata' in fm; assert fm['metadata']['pattern']=='cli-on-demand'"
}

@test "docling_skill_required_sections_present" {
  for section in "## What this skill does" "## When to use docling" \
                 "## CLI-on-demand recipe" "## Persistent MCP recipe" \
                 "## Trust Boundary" "## Consent Policy" \
                 "## Version Pinning" "## Fallback Strategy"; do
    grep -qF "$section" "$SKILL_MD"
  done
}

@test "docling_skill_references_agents_md_routing" {
  # The skill must REFERENCE the AGENTS.md routing rule (single-source, no drift)
  grep -q 'AGENTS.md' "$SKILL_MD"
}

@test "docling_skill_has_docling_convert_command" {
  # The on-demand CLI recipe must reference docling convert
  grep -q 'docling convert' "$SKILL_MD"
}

# =============================================================================
# Default-disabled MCP state
# =============================================================================

@test "docling_mcp_disabled_by_default" {
  python3 -c "import json; d=json.load(open('${CONFIG}')); assert 'docling' in d['mcp']; assert d['mcp']['docling']['enabled'] is False, 'docling must be opt-in'"
}

@test "docling_tool_denied_by_default" {
  python3 -c "import json; d=json.load(open('${CONFIG}')); assert d['permission']['tool']['docling*'] == 'deny'"
}

@test "docling_mcp_has_local_conversion_mode" {
  python3 -c "import json; d=json.load(open('${CONFIG}')); assert d['mcp']['docling']['environment']['DOCLING_CONVERSION_MODE'] == 'local'"
}

# =============================================================================
# Pack deep-merge correctness
# =============================================================================

@test "pack_docling_exists" {
  [ -f "$PACKS_DIR/pack-docling.json" ]
}

@test "pack_docling_enables_mcp" {
  python3 -c "import json; p=json.load(open('$PACKS_DIR/pack-docling.json')); assert p['mcp']['docling']['enabled'] is True"
}

@test "pack_docling_grants_tool_permission" {
  # Uses permission.tool (correct nested structure), not top-level tools
  python3 -c "import json; p=json.load(open('$PACKS_DIR/pack-docling.json')); assert p['permission']['tool']['docling*'] is True"
}

@test "pack_docling_deep_merge_flips_config" {
  # Verify merge-packs.mjs deep-merges pack-docling.json into a temp copy
  # and flips both mcp.docling.enabled and permission.tool.docling*
  cp "$CONFIG" /tmp/test_docling_merge.json
  node "$MERGE_SCRIPT" --config /tmp/test_docling_merge.json --packs-dir "$PACKS_DIR" --packs docling >/dev/null 2>&1
  python3 -c "import json; d=json.load(open('/tmp/test_docling_merge.json')); assert d['mcp']['docling']['enabled'] is True; assert d['permission']['tool']['docling*'] is True"
  rm -f /tmp/test_docling_merge.json
}

# =============================================================================
# AGENTS.md routing rule (single source of truth)
# =============================================================================

@test "agents_md_has_extraction_routing_section" {
  grep -q "Office Document Extraction Routing" AGENTS.md
}

@test "agents_md_lists_four_tiers" {
  # All 4 tiers must be named in the routing section
  for tier in "markitdown" "docling" "image-analyzer-subagent" "pdf-specialist-skill"; do
    grep -q "$tier" AGENTS.md
  done
}

@test "deploy_agents_md_references_routing_rule" {
  grep -q "Office Document Extraction Routing" deploy/.AGENTS.md
}

# =============================================================================
# Agent skill grants
# =============================================================================

@test "primary_has_docling_skill_allow" {
  python3 -c "import json; d=json.load(open('${CONFIG}')); assert d['permission']['skill']['docling-mcp-skill'] == 'allow'"
}

@test "office_document_primary_agent_has_docling_skill" {
  grep -q "docling-mcp-skill: allow" "$AGENTS_DIR/office-document-primary-agent.md"
}

# =============================================================================
# dependency-map.json edge (Decision 8)
# =============================================================================

@test "dependency_map_has_docling_edge" {
  python3 -c "import json; d=json.load(open('deploy/dependency-map.json')); assert 'docling-mcp-skill' in d['impliesMcp']; assert d['impliesMcp']['docling-mcp-skill'] == ['docling']"
}

# =============================================================================
# Specialist subagents reference AGENTS.md (not stale inline prose)
# =============================================================================

@test "specialist_subagents_reference_agents_md_routing" {
  for agent in "requirements-specialist-subagent" "technical-design-specialist-subagent" \
               "documentation-subagent" "discovery-specialist-subagent"; do
    echo "  checking $agent" >&3
    grep -q "AGENTS.md" "$AGENTS_DIR/$agent.md"
  done
}
