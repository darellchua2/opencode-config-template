#!/usr/bin/env bats

# Tests for MCP server count consistency across documentation surfaces.
# Catches the latent off-by-one bug fixed in PLAN-GIT-262 Phase 6.
#
# Source of truth: opencode_app/opencode.json `mcp` block length.
# Documentation surfaces that must match:
#   - README.md "ships N MCP server entries"
#   - deploy/setup.sh "MCP SERVERS (N):"
#
# Note: deploy/setup.ps1 and setup.sh banner refs
# refer to the AUTO-START count, not the total — those are
# intentionally different and not asserted here.
# UPDATE (PLAN-GIT-333 Phase 6): auto-start was 2 (codegraph,
# zai-web-reader). atlassian is opt-in per-project
# (opencode-repo-setup-skill). zai-vision-mcp-server / zai-zread,
# and mermaid were removed entirely
# (native vision tier, inline mermaid blocks).
# UPDATE (PLAN-GIT-357 Phase 1): auto-start is now 3 — zai-web-search-prime
# re-added (plan-exclusive, enabled); zai-vision-mcp re-added but
# shipped opt-in (enabled: false; native multimodal subagents remain the default).
# Banner refs must say 3.

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

@test "mcp_count_zai_zread_removed_vision_opt_in" {
  # PLAN-GIT-357: zai-zread stays removed; zai-vision-mcp is back but
  # must ship opt-in (native multimodal subagents are the default path)
  python3 -c "import json; d=json.load(open('${CONFIG}')); assert 'zai-zread' not in d['mcp'], 'zai-zread must be removed'; assert d['mcp']['zai-vision-mcp']['enabled'] is False, 'zai-vision-mcp must be opt-in'"
}

@test "mcp_count_mermaid_removed_search_enabled" {
  # PLAN-GIT-357: mermaid stays removed (inline blocks); zai-web-search-prime
  # is back and enabled (plan-exclusive, mirrors zai-web-reader)
  python3 -c "import json; d=json.load(open('${CONFIG}')); assert 'mermaid' not in d['mcp'], 'mermaid MCP must be removed (inline blocks + mmdc)'; assert d['mcp']['zai-web-search-prime']['enabled'] is True, 'zai-web-search-prime must be enabled'"
}

@test "mcp_count_autodesk_not_shipped" {
  # GIT-333 — the 4 autodesk servers are pack-only (deploy/packs/pack-autodesk.json
  # carries full definitions); they must NOT appear in the base config.
  python3 -c "
import json
d = json.load(open('${CONFIG}'))['mcp']
for k in ('autodesk-revit','autodesk-model-data','autodesk-fusion','autodesk-help'):
    assert k not in d, f'{k} must be pack-only'
"
}

@test "mcp_count_auto_start_is_three" {
  # Three auto-start servers: codegraph, zai-web-reader, zai-web-search-prime.
  # atlassian / zai-vision-mcp / markitdown / docling / chrome-devtools /
  # next-devtools are opt-in (enabled: false).
  auto_count=$(python3 -c "import json; d=json.load(open('${CONFIG}')); print(sum(1 for v in d['mcp'].values() if v.get('enabled')))")
  echo "Auto-start (enabled) MCP count: ${auto_count}" >&3
  [ "$auto_count" = "3" ]
}
