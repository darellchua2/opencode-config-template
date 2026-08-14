#!/usr/bin/env bats

# Tests for MCP server count consistency across documentation surfaces.
# Catches the latent off-by-one bug fixed in PLAN-GIT-262 Phase 6.
#
# Source of truth: opencode_app/opencode.json `mcp` block length.
# Documentation surfaces that must match:
#   - README.md "ships N MCP server entries"
#   - deploy/setup.sh "MCP SERVERS (N):"
#
# Note: deploy/setup.ps1 and setup.sh banner "MCP Servers (6)" / "(6)"
# refer to the AUTO-START count (always 6), not the total — those are
# intentionally different and not asserted here.
# UPDATE (PLAN-GIT-333 Phase 6): auto-start is now 3 (codegraph,
# zai-web-reader, mermaid). atlassian/zai-vision/zai-zread are opt-in
# per-project (opencode-repo-setup-skill). Banner refs must say 3.

CONFIG="opencode_app/opencode.json"

# Compute the actual count from the source of truth.
# Uses python3 (already a setup.sh dependency for codegraph init).
actual_mcp_count() {
  python3 -c "import json; print(len(json.load(open('${CONFIG}'))['mcp']))"
}

@test "mcp_count_opencode_json_is_consistent_across_docs" {
  actual="$(actual_mcp_count)"
  echo "Actual MCP count in ${CONFIG}: ${actual}" >&3

  # README.md must match
  readme_count=$(grep -oE 'ships [0-9]+ MCP server entries' README.md | grep -oE '[0-9]+' | head -1)
  echo "README.md count: ${readme_count}" >&3
  [ "$readme_count" = "$actual" ]

  # setup.sh help text must match
  setup_count=$(grep -oE 'MCP SERVERS \([0-9]+\)' deploy/setup.sh | grep -oE '[0-9]+' | head -1)
  echo "setup.sh count: ${setup_count}" >&3
  [ "$setup_count" = "$actual" ]
}

@test "mcp_count_markitdown_present" {
  # Phase 2 of PLAN-GIT-262 — markitdown must be registered
  python3 -c "import json; d=json.load(open('${CONFIG}')); assert 'markitdown' in d['mcp'], 'markitdown missing'; assert d['mcp']['markitdown']['enabled'] is False, 'markitdown must be opt-in'"
}

@test "mcp_count_atlassian_is_opt_in" {
  # PLAN-GIT-333 Phase 6 — atlassian must be per-project opt-in
  python3 -c "import json; d=json.load(open('${CONFIG}')); assert d['mcp']['atlassian']['enabled'] is False, 'atlassian must be opt-in'"
}

@test "mcp_count_zai_vision_is_opt_in" {
  python3 -c "import json; d=json.load(open('${CONFIG}')); assert d['mcp']['zai-vision-mcp-server']['enabled'] is False, 'zai-vision-mcp-server must be opt-in'"
}

@test "mcp_count_zai_zread_is_opt_in" {
  python3 -c "import json; d=json.load(open('${CONFIG}')); assert d['mcp']['zai-zread']['enabled'] is False, 'zai-zread must be opt-in'"
}

@test "mcp_count_auto_start_is_three" {
  # Three auto-start servers: codegraph, zai-web-reader, mermaid.
  # atlassian + zai-vision-mcp-server + zai-zread are opt-in (Phase 6).
  auto_count=$(python3 -c "import json; d=json.load(open('${CONFIG}')); print(sum(1 for v in d['mcp'].values() if v.get('enabled')))")
  echo "Auto-start (enabled) MCP count: ${auto_count}" >&3
  [ "$auto_count" = "3" ]
}
