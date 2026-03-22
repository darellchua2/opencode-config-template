# Plan: Update opencode.json example to include standard MCP servers

## Overview
Update the `nextjs-mcp-advisor-subagent.md` documentation to clarify opencode.json format and add filesystem MCP server to config.json.

## Ticket Reference
- Issue: #122
- URL: https://github.com/darellchua2/opencode-config-template/issues/122
- Labels: documentation, enhancement, next.js

## Files Modified
1. `agents/nextjs-mcp-advisor-subagent.md` - Added note about updating existing opencode.json
2. `config.json` - Added filesystem MCP server (disabled by default)
3. `agents/explore-primary-agent.md` - Added filesystem MCP documentation

## Implementation Complete

### Changes Made
- [x] Updated nextjs-mcp-advisor-subagent.md with note for existing configs
- [x] Added filesystem MCP server to config.json
- [x] Documented filesystem MCP in explore-primary-agent.md

### Subagents/Skills for Filesystem MCP

| Agent/Skill | Use Case |
|-------------|----------|
| **explore-primary-agent** | Enhanced codebase search/exploration |
| documentation-subagent | Batch documentation across directories |
| docx-creation-subagent | Document file operations |

### Commits
- \`7a6c786\` - docs(plan): add PLAN for issue #122
- \`edfe7dc\` - docs(agents): simplify opencode.json example
- \`25f95a9\` - feat(config): add filesystem MCP server
- \`d1cfbcd\` - docs(agents): add filesystem MCP option to explore-primary-agent
