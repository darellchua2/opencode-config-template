# Plan: Add Playwright MCP server integration to config.json

## Overview
Implement and integrate the Playwright MCP server from https://github.com/microsoft/playwright-mcp into the config.json configuration. This will enable automated browser testing capabilities within the OpenCode agent system.

## Issue Reference
- Issue: #61
- URL: https://github.com/darellchua2/opencode-config-template/issues/61
- Labels: enhancement, good first issue
- Assignee: darellchua2
- Branch: feature/61-playwright-mcp-server

## Files to Modify
1. `config.json` - Add Playwright MCP server configuration to the `mcp` section

## Approach

### Step 1: Research Playwright MCP Server Configuration
- Review the Playwright MCP server documentation at https://github.com/microsoft/playwright-mcp
- Understand the required configuration parameters:
  - Command to start the server
  - Environment variables needed
  - Any additional configuration options

### Step 2: Add MCP Server Configuration to config.json
- Add a new entry under `mcp` section for Playwright
- Configuration pattern based on existing MCP servers:
  ```json
  "playwright": {
    "type": "local" or "remote",
    "command": ["npx", "-y", "@playwright/mcp-server"],
    "environment": {
      // Required environment variables
    },
    "enabled": true
  }
  ```

### Step 3: Test Configuration
- Validate the JSON syntax of config.json
- Ensure the MCP server configuration follows the correct schema
- Verify that the configuration is properly formatted

### Step 4: Consider Agent Integration (Optional)
- Determine which agents should have access to the Playwright MCP server
- Potential candidates:
  - `image-analyzer` - for UI screenshot testing
  - `testing-subagent` - for automated testing workflows
- Update agent `mcp` sections if needed

### Step 5: Documentation Updates (Optional)
- Update README.md if new capabilities are enabled
- Document the Playwright MCP server integration
- Provide usage examples for testing workflows

## Configuration Details

### Playwright MCP Server
Based on the Microsoft Playwright MCP server, the configuration should include:

**Type**: `local` (npm package) or `remote` (depending on implementation)

**Command**:
```json
"command": ["npx", "-y", "@playwright/mcp-server"]
```

**Environment Variables**:
- Check if any API keys or configuration are required
- Document any required environment variables

**Enabled**: `true`

## Success Criteria
- [ ] Playwright MCP server configuration added to config.json
- [ ] JSON is valid and follows the schema
- [ ] Configuration is properly formatted and indented
- [ ] No syntax errors in config.json
- [ ] Documentation updated (if applicable)

## Notes
- The configuration should follow the existing pattern of other MCP servers in config.json
- Pay attention to indentation and JSON formatting (2 spaces)
- The `mcp` section currently has: `atlassian`, `web-reader`, `web-search-prime`, `zai-mcp-server`, `zread`, `drawio`
- Playwright will be added as a new entry in this section
- Consider whether to enable it globally or only for specific agents

## MCP Server Structure Reference
```json
"mcp": {
  "atlassian": { ... },
  "web-reader": { ... },
  "web-search-prime": { ... },
  "zai-mcp-server": { ... },
  "zread": { ... },
  "drawio": { ... },
  "playwright": {  // Add this
    "type": "...",
    "command": [...],
    "environment": { ... },
    "enabled": true
  }
}
```
