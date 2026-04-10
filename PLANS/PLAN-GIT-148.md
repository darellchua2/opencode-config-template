# Plan: Migrate Atlassian MCP server from deprecated /v1/sse to /v1/mcp endpoint

## Issue Reference
- **Number**: #148
- **URL**: https://github.com/darellchua2/opencode-config-template/issues/148
- **Labels**: enhancement, patch

## Overview

The Atlassian MCP server is currently configured to use the deprecated `/v1/sse` endpoint via `mcp-remote`. Atlassian now recommends using the `/v1/mcp` endpoint instead. This issue migrates the endpoint URL in `config.json` and verifies no other files reference the old URL.

## Acceptance Criteria
- [x] Update `config.json` Atlassian MCP entry from `/v1/sse` to `/v1/mcp`
- [x] Verify no other files in the repo reference the old `/v1/sse` endpoint
- [x] `config.json` remains valid JSON after the change
- [x] `setup.sh` and `setup.ps1` do not reference the old endpoint (or are updated if they do)

## Scope
- `config.json` (line 36) — primary change
- `setup.sh` / `setup.ps1` — verify no references

---

## Implementation Phases

### Phase 1: Implementation
- [x] Update `config.json` Atlassian MCP URL from `https://mcp.atlassian.com/v1/sse` to `https://mcp.atlassian.com/v1/mcp`
- [x] Search `setup.sh` and `setup.ps1` for any references to the old endpoint
- [x] Update if found (none found)
- [x] Validate `config.json` is valid JSON

### Phase 2: Validation
- [x] Verify `config.json` is valid JSON with `jq`
- [x] Confirm no remaining references to `/v1/sse` in the repo

---

## Technical Notes

- Atlassian officially recommends migrating from `/sse` to `/mcp` per their README
- The proxy command (`npx -y mcp-remote`) remains unchanged
- No authentication changes required
- This is a URL-only change

## Dependencies
None.

## Risks & Mitigation
| Risk | Likelihood | Mitigation |
|------|------------|------------|
| Invalid JSON after edit | Low | Validate with `jq` after edit |
| `/v1/mcp` endpoint not yet supported by `mcp-remote` | Low | Atlassian docs confirm it works with remote MCP clients |
