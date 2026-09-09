#!/usr/bin/env bats

# Tests for MCP provider pack permission keys (issue #370).
# All MCP packs must flip permissions via ROOT-level `permission` pattern keys
# with string enum values ("allow"), never the deprecated top-level `tools`
# map or the inert nested `permission.tool` key (opencode permission engine
# reads root patterns only; booleans are schema-invalid). Peer to
# tests/test_voice_pack.bats (tui-only pack — intentionally NOT covered here).

MERGE_SCRIPT="deploy/merge-packs.mjs"
SETUP="deploy/setup.sh"
SETUP_PS1="deploy/setup.ps1"

# pack-name:server-keys pairs (explicit enumeration — no dir glob: voice is
# tui-only and legitimately carries no permission key)
PACK_SERVERS="markitdown:markitdown docling:docling chrome-devtools:chrome-devtools nextjs:next-devtools autodesk:autodesk-revit,autodesk-model-data,autodesk-fusion,autodesk-help"

# =============================================================================
# Pack file shape (all 5 MCP packs)
# =============================================================================

@test "all_five_mcp_packs_exist_and_are_valid_json" {
  for entry in $PACK_SERVERS; do
    pack="${entry%%:*}"
    f="deploy/packs/pack-${pack}.json"
    [ -f "$f" ]
    node -e "JSON.parse(require('fs').readFileSync('$f','utf8'))"
  done
}

@test "mcp_packs_use_root_permission_allow_string_enum" {
  for entry in $PACK_SERVERS; do
    pack="${entry%%:*}"
    node -e "
      const p = JSON.parse(require('fs').readFileSync('deploy/packs/pack-${pack}.json','utf8'));
      const keys = Object.keys(p);
      if (keys[0] !== '\$comment') { console.error('${pack}: \$comment must be first key (merge-packs stripJsonComments strips whole-line entries only)'); process.exit(1); }
      if (p.tools !== undefined) { console.error('${pack}: top-level tools is deprecated — use root permission'); process.exit(1); }
      if (p.permission === undefined || typeof p.permission !== 'object' || Array.isArray(p.permission)) { console.error('${pack}: root permission object required'); process.exit(1); }
      if (p.permission.tool !== undefined) { console.error('${pack}: nested permission.tool is inert — patterns belong at the permission root'); process.exit(1); }
      for (const [k, v] of Object.entries(p.permission)) {
        if (!k.endsWith('*')) { console.error('${pack}: permission key ' + k + ' must be a wildcard pattern'); process.exit(1); }
        if (v !== 'allow') { console.error('${pack}: permission ' + k + ' must be the string \"allow\" (got ' + JSON.stringify(v) + ')'); process.exit(1); }
      }
      if (Object.keys(p.permission).length === 0) { console.error('${pack}: permission must not be empty'); process.exit(1); }
    "
  done
}

@test "mcp_packs_enable_their_servers" {
  for entry in $PACK_SERVERS; do
    pack="${entry%%:*}"
    servers="${entry#*:}"
    node -e "
      const p = JSON.parse(require('fs').readFileSync('deploy/packs/pack-${pack}.json','utf8'));
      const want = '${servers}'.split(',');
      for (const s of want) {
        if (!p.mcp || !p.mcp[s]) { console.error('${pack}: missing mcp.' + s); process.exit(1); }
        if (p.mcp[s].enabled !== true) { console.error('${pack}: mcp.' + s + '.enabled must be true'); process.exit(1); }
      }
    "
  done
}

# =============================================================================
# merge-packs semantics: pack allow flips a root deny (the #370 bug class)
# =============================================================================

@test "pack_merge_flips_root_deny_to_allow_and_enables_server" {
  local dir
  dir="$(mktemp -d)"
  cat > "$dir/opencode.json" <<'EOF'
{
  "mcp": { "markitdown": { "type": "local", "command": ["markitdown-local-mcp"], "enabled": false } },
  "permission": { "markitdown*": "deny" }
}
EOF
  node "$MERGE_SCRIPT" --config "$dir/opencode.json" --packs-dir deploy/packs --packs markitdown >/dev/null
  node -e "
    const c = JSON.parse(require('fs').readFileSync('$dir/opencode.json','utf8'));
    if (c.mcp.markitdown.enabled !== true) { console.error('enabled must flip to true'); process.exit(1); }
    if (c.permission['markitdown*'] !== 'allow') { console.error('deny must flip to allow, got ' + JSON.stringify(c.permission['markitdown*'])); process.exit(1); }
    if (c.permission.tool !== undefined) { console.error('permission.tool must never appear'); process.exit(1); }
  "
  rm -rf "$dir"
}

@test "pack_merge_preserves_unrelated_permission_patterns" {
  local dir
  dir="$(mktemp -d)"
  cat > "$dir/opencode.json" <<'EOF'
{
  "mcp": {},
  "permission": { "codegraph*": "allow", "docling*": "deny", "read": { "mcp:*": "deny" } }
}
EOF
  node "$MERGE_SCRIPT" --config "$dir/opencode.json" --packs-dir deploy/packs --packs markitdown >/dev/null
  node -e "
    const c = JSON.parse(require('fs').readFileSync('$dir/opencode.json','utf8'));
    if (c.permission['codegraph*'] !== 'allow') { console.error('unrelated allow must survive'); process.exit(1); }
    if (c.permission['docling*'] !== 'deny') { console.error('unrelated deny must survive'); process.exit(1); }
    if (!c.permission.read || c.permission.read['mcp:*'] !== 'deny') { console.error('nested permission sub-blocks must survive'); process.exit(1); }
  "
  rm -rf "$dir"
}

# =============================================================================
# Install-on-enable surface (setup.sh + setup.ps1 mirror)
# =============================================================================

@test "setup_sh_installer_has_installed_check" {
  grep -q 'pip show markitdown-local-mcp' "$SETUP"
}

@test "setup_sh_run_pack_merger_gates_install_on_enable_pack" {
  # hook must be dry-run-safe and keyed to the markitdown pack
  grep -q 'grep -qw "markitdown"' "$SETUP"
  grep -q 'install_local_mcp_launchers' "$SETUP"
  local hook
  hook="$(sed -n '/run_pack_merger()/,/^}/p' "$SETUP" | grep -A2 'grep -qw "markitdown"')"
  [[ "$hook" == *'DRY_RUN'* ]]
}

@test "setup_ps1_mirrors_rc_gated_install_hook" {
  grep -q 'mergeRc = \$LASTEXITCODE' "$SETUP_PS1"
  # EnablePack regex gate: '(^|,)markitdown(,|$)'
  grep -qF ',)markitdown(,' "$SETUP_PS1"
  grep -q 'Install-LocalMcpLaunchers' "$SETUP_PS1"
  grep -q 'pip show markitdown-local-mcp' "$SETUP_PS1"
}
