# Plan: Add opencode-gemini-auth plugin to config.json

## Issue Reference
- **Number**: #144
- **URL**: https://github.com/darellchua2/opencode-config-template/issues/144
- **Labels**: enhancement, patch

## Overview

Add the `opencode-gemini-auth` plugin to the `plugin` array in `config.json`. This is a Google Gemini authentication plugin for OpenCode, and should be placed alongside the existing `opencode-claude-auth` plugin. Also verify that `opencode-md-table-formatter` remains properly configured in the plugin array.

## Acceptance Criteria
- [ ] `"opencode-gemini-auth"` is added to the `plugin` array in `config.json`
- [ ] It is placed alongside `opencode-claude-auth` (as a fellow auth plugin)
- [ ] `"opencode-md-table-formatter"` remains in the `plugin` array (already present, verify no regression)
- [ ] `config.json` remains valid JSON after the change
- [ ] `setup.sh` deployment still works correctly

## Scope
- `config.json` — lines 5–13 (the `plugin` array)

---

## Implementation Phases

### Phase 1: Implementation
- [ ] Add `"opencode-gemini-auth"` to the `plugin` array in `config.json` alongside `opencode-claude-auth`
- [ ] Verify `"opencode-md-table-formatter"` remains in the plugin array (already present, no regression)
- [ ] Verify `config.json` is valid JSON

### Phase 2: Validation
- [ ] Run `setup.sh` to verify deployment still works
- [ ] Confirm the plugin appears in the deployed `~/.config/opencode/config.json`

---

## Technical Notes

- This is a Google Gemini authentication plugin for OpenCode
- It should be grouped with `opencode-claude-auth` as both are authentication-related plugins
- `opencode-md-table-formatter` is already present and should remain unchanged
- No other configuration changes are needed in this issue

## Dependencies
None.

## Risks & Mitigation
| Risk | Likelihood | Mitigation |
|------|------------|------------|
| Invalid JSON after edit | Low | Validate JSON after edit with `jq` or similar |
| Plugin not recognized by OpenCode | Low | This is a configuration-only change; runtime errors are outside scope |
