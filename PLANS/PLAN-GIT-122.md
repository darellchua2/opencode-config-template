# Plan: Update opencode.json example to include standard MCP servers

## Overview
Update the `nextjs-mcp-advisor-subagent.md` documentation to show the complete `opencode.json` configuration including all standard MCP servers (next-devtools, filesystem, github) instead of just next-devtools alone.

## Ticket Reference
- Issue: #122
- URL: https://github.com/darellchua2/opencode-config-template/issues/122
- Labels: documentation, enhancement, next.js

## Files to Modify
1. `agents/nextjs-mcp-advisor-subagent.md` - Update opencode.json example at lines 65-76

## Approach

### Phase 1: Analysis
- Review current opencode.json example (lines 65-76)
- Identify the correct format with all three MCP servers
- Ensure note about OpenCode format is preserved

### Phase 2: Implementation
- Update JSON example to include `filesystem` and `github` MCP servers
- Maintain existing documentation context
- Keep the explanatory note about OpenCode's config format

## Success Criteria
- [ ] opencode.json example includes all three MCP servers
- [ ] JSON format is valid
- [ ] Existing note about format differences is preserved
- [ ] Documentation is clear and complete

## Notes
- Keep only `next-devtools` in the example (no filesystem/github)
- Add note: "If `opencode.json` already exists, add the `next-devtools` entry to the existing `mcp` object"
