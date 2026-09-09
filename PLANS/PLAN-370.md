# PLAN: MCP enable-pack flips dead permission keys

**Branch**: feat/370
**Issue**: https://github.com/darellchua2/opencode-config-template/issues/370
**Base**: main

## Acceptance Criteria
- [ ] All 4 packs write `permission: {"<server>*": "allow"}` at the permission root with string enum values; no nested `permission.tool`, no top-level `tools` in any pack
- [ ] Source `opencode_app/opencode.json` opt-in denies migrated from `permission.tool` to root-level `permission` patterns
- [ ] `--enable-pack markitdown` installs the launcher (gated on `ENABLE_PACK`, dry-run skips; mirrored in `setup.ps1`)
- [ ] SKILL.md + office-document-primary-agent.md corrected; `--help` verify suggestion replaced with `opencode mcp list`
- [ ] Bats regression test: pack permission patterns are root-level string enums; install hook present
- [ ] `bash -n` setup.sh, `node --check` merge-packs.mjs, full `bats tests/` green

## Dependency & Consumer Map

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---------------------|---------------------------|---------------------------------|-------------|
| `deploy/packs/pack-{markitdown,docling,chrome-devtools,nextjs}.json` | Phase 2 (source denies must exist at root so pack `allow` wins the merge) | `deploy/merge-packs.mjs`, `validate_enable_pack`, setup.sh/ps1 help text, new bats test | med |
| `opencode_app/opencode.json` (permission block) | — | setup.sh config copy → deployed config, opencode runtime, `tests/test_mcp_count_consistency.bats`, merge-packs.mjs (merge base) | high (inert denies become real denies) |
| `deploy/merge-packs.mjs` (dry-run snapshot + header) | Phase 1 pack format | setup.sh `run_pack_merger`, setup.ps1 `Invoke-PackMerger`, standalone CLI users | low |
| `deploy/setup.sh` (`run_pack_merger` hook, usage text) | Phase 1 (pack no longer references tools) | `--enable-pack` users, CI bats | low |
| `deploy/setup.ps1` (`Invoke-PackMerger` hook, help text) | Phase 1 | Windows users | low |
| `opencode_app/.opencode/skills/markitdown-mcp-skill/SKILL.md`, `opencode_app/.opencode/agents/office-document-primary-agent.md` | Phases 1-2 (docs must match shipped keys) | runtime skill/agent loading, installer registry (category only) | low |
| `tests/test_pack_permissions.bats` (new) | Phases 1-5 | CI | low |

## Implementation Phases

### Phase 1: Fix the four pack files
- [ ] **1.1** Rewrite `deploy/packs/pack-markitdown.json` to `{"mcp":{"markitdown":{"enabled":true}},"permission":{"markitdown*":"allow"}}`; update `$comment` to state the root-permission key (string enum, deprecated `tools` removed) and that `--enable-pack markitdown` now installs the launcher
    — **Why:** top-level `tools` is deprecated since v1.1.1 and loses conflicts to explicit `permission`; the string value is what the schema enum (`ask|allow|deny`) requires
    — **Done when:** `node -e` asserts `p.permission["markitdown*"]==="allow"`, `p.tools===undefined`, `p.permission.tool===undefined`
    — **Consumers affected:** merge-packs.mjs merge output, deployed config after `--enable-pack markitdown`
- [ ] **1.2** Same rewrite for `deploy/packs/pack-docling.json` (`permission:{"docling*":"allow"}`), replacing the inert `permission.tool: true` and its stale `$comment`
    — **Why:** #310's fix targets a key opencode never reads; boolean `true` is schema-invalid
    — **Done when:** same node assertion for `docling*`; no `tool` key anywhere in the pack
    — **Consumers affected:** `--enable-pack docling` merges
- [ ] **1.3** Same rewrite for `deploy/packs/pack-chrome-devtools.json` and `deploy/packs/pack-nextjs.json` (`chrome-devtools*` / `next-devtools*` → `"allow"`), updating `$comment`s
    — **Why:** same deprecated-key bug; prevents identical reports for those packs
    — **Done when:** node assertions pass for both packs; `grep -l '"tools"' deploy/packs/` returns nothing
    — **Consumers affected:** `--enable-pack chrome-devtools|nextjs` merges

### Phase 2: Migrate the source config deny block
- [ ] **2.1** In `opencode_app/opencode.json`, move the 7 pattern entries out of `permission.tool` (L142-150) to the `permission` root (siblings of `read`/`skill`), preserving values (`codegraph*`/`atlassian*`/`zai-web-reader*`/`zai-web-search*` allow; `markitdown*`/`docling*`/`next-devtools*` deny), then delete the `tool` sub-object
    — **Why:** `permission.tool` matches nothing in opencode's permission engine; root-level patterns are the documented mechanism, making the intended opt-in denies actually enforce
    — **Done when:** node asserts `permission["markitdown*"]==="deny"` and `permission.tool===undefined`; `read`/`skill` blocks byte-identical; JSON parses
    — **Consumers affected:** fresh deploys (real denies), pack merges (allow wins, Phase 1), `test_mcp_count_consistency.bats` (no permission assertions — verified)

### Phase 3: merge-packs.mjs snapshot + header
- [ ] **3.1** Add `permission: config.permission || {}` to the before/after dry-run diff snapshots (L181-185, L241-244); update header comment (L6) to describe `mcp.<server>.enabled` + root `permission` allows
    — **Why:** snapshot only tracks `mcp`+`tools`; with packs now writing `permission`, the `changed:` report would falsely say "nothing (already merged)"
    — **Done when:** `node --check deploy/merge-packs.mjs` passes; dry-run merge simulation reports `changed: yes` against a config with root denies
    — **Consumers affected:** setup.sh/ps1 dry-run output, standalone CLI users

### Phase 4: Install-on-enable hook (setup.sh + setup.ps1)
- [ ] **4.1** In `run_pack_merger` (deploy/setup.sh:3312), after the merge rc check: `if [ "$DRY_RUN" != true ] && echo "$ENABLE_PACK" | grep -qw "markitdown"; then install_local_mcp_launchers; fi`
    — **Why:** `install_local_mcp_launchers` only runs during full-setup config copy (L2468), so `--enable-pack markitdown` never installs the binary — the reproduced root cause; docling/voice set the gating precedent (L2618/2688)
    — **Done when:** `bash -n` passes; grep shows the gate inside `run_pack_merger`; dry-run path leaves `$DRY_RUN` guard intact
    — **Consumers affected:** `--enable-pack markitdown` users (real deploys); Docker path (idempotent force-reinstall, non-fatal offline)
- [ ] **4.2** Mirror in `deploy/setup.ps1` `Invoke-PackMerger` (after the node merge call): `if (-not $DryRun -and $EnablePack -match '(^|,)markitdown(,|$)') { Install-LocalMcpLaunchers }`
    — **Why:** repo sync rules require the Windows mirror; `Install-LocalMcpLaunchers` already exists (ps1:2083)
    — **Done when:** grep shows the gate in setup.ps1 following the merge call
    — **Consumers affected:** Windows `-EnablePack markitdown` users
- [ ] **4.3** Update help text in both scripts (setup.sh ~L577-578, setup.ps1 ~L921-922): replace "and tools.<ns>* flags ON" with "and sets permission `\"<ns>*\": \"allow\"`"
    — **Why:** help text would otherwise teach the removed key
    — **Done when:** `grep -c "tools.<ns>" deploy/setup.sh deploy/setup.ps1` returns 0 for both
    — **Consumers affected:** `--help` readers

### Phase 5: Docs
- [ ] **5.1** Rewrite `markitdown-mcp-skill/SKILL.md`: L14 (both-blocks phrasing), L29 (state table row), config block ~L35-64 (root `permission` example), L60 (two-flip step 2), L64 (`--help` → `opencode mcp list`), L183-190 troubleshooting (root-permission flip)
    — **Why:** the skill teaches the exact dead keys this ticket removes; it is the documented enable path
    — **Done when:** `grep -n 'tools\.\?"markitdown\|permission.tool\|--help' SKILL.md` returns no stale hits; new examples show `permission:{"markitdown*":"allow"}`
    — **Consumers affected:** markitdown-mcp-skill runtime copies (redeploy), installer registry metadata untouched (frontmatter unchanged)
- [ ] **5.2** Update `office-document-primary-agent.md` note (~L69): session-inherited access now governed by root `permission["markitdown*"]` + `mcp.markitdown.enabled`; flip guidance matches SKILL.md
    — **Why:** agent prompt would instruct users to edit a key that does nothing
    — **Done when:** grep finds no `tools["markitdown*"]` guidance in the agent file
    — **Consumers affected:** office-document-primary-agent runtime prompt

### Phase 6: Regression test + gates
- [ ] **6.1** Add `tests/test_pack_permissions.bats` (modeled on test_voice_pack.bats): pack shapes (root string-enum permission, no `tools`/`permission.tool`), merge-packs simulation flipping a root deny to allow, install-gate presence in setup.sh + setup.ps1
    — **Why:** the packs had zero key-structure coverage; this class of bug shipped twice (#269, #310)
    — **Done when:** `bats tests/test_pack_permissions.bats` all green
    — **Consumers affected:** CI suite
- [ ] **6.2** Run full gates: `bash -n deploy/setup.sh`, `node --check deploy/merge-packs.mjs`, `bats tests/`
    — **Why:** repo verification gates; `test_mcp_count_consistency.bats` guards against count drift (no MCP added/removed, so counts stay)
    — **Done when:** all three commands exit 0
    — **Consumers affected:** CI

## Technical Notes
- Permission semantics (docs + source, 2026-09-09): patterns at the `permission` root; last matching rule wins; default allow-all; string enum only (`ask|allow|deny`); explicit `permission` overlays legacy `tools`-derived entries.
- `merge-packs.mjs` deep-merges every non-`tui` pack key — root `permission` passes through unmodified; strips `$comment`.
- `install_local_mcp_launchers` is function-defined before `run_pack_merger` executes (call sites at L2468 prove ordering); pip `--user` lands on PATH (`~/.local/bin`), non-fatal offline.
- MCP servers boot at process start; no hot-reload — users must restart opencode after enabling.
- Behavior change note for release notes: source-config opt-in denies (`markitdown*`, `docling*`, `next-devtools*`) become enforcing at the root; packs flip them to allow on `--enable-pack`.
- Sync rules: no MCP servers added/removed, no skill/agent count changes → setup.sh/README counts and registry.json untouched.
- No duplicate issues: searched open + closed (markitdown/permission/packs).

## Dependencies
None external; all vendored.

## Risks & Mitigation
- **Real denies break hand-enabled setups** — users who flipped `mcp.<server>.enabled` manually without packs would hit enforced denies after redeploy. Mitigation: packs flip allow; note in release notes + SKILL.md troubleshooting row.
- **Windows path unverifiable in CI (Linux)** — ps1 changes are grep-asserted only. Mitigation: exact mirror of the sh shell gate; voice-pack precedent (ps1:1904) uses the same regex form.
- **`changed:` under-report regression** — covered by Phase 3 snapshot update + a test assertion on dry-run output.
