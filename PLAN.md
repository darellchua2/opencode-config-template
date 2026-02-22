# Plan: Create Error Resolver Subagent and Skill

## Overview
Create a new error resolver subagent and associated skill that can diagnose and help resolve errors, exceptions, and stack traces when explicitly invoked by users.

## Ticket Reference
- Issue: #73
- URL: https://github.com/darellchua2/opencode-config-template/issues/73
- Labels: enhancement, good first issue

## Files to Modify
1. `config.json` - Add error-resolver-subagent configuration
2. `skills/error-resolver-workflow/SKILL.md` - Create new skill file
3. `.AGENTS.md` - Update routing rules
4. `README.md` - Add documentation for usage (optional)

## Approach
### Phase 1: Configuration Setup
1. Create the error-resolver-subagent configuration in config.json
2. Configure with Opus 4.6 model
3. Set up tool access for error analysis (zai-mcp-server)
4. Configure permission restrictions

### Phase 2: Skill Implementation
1. Create error-resolver-workflow/SKILL.md
2. Define error analysis workflow
3. Document MCP tool integration
4. Add examples and use cases

### Phase 3: Documentation
1. Update .AGENTS.md with routing rules
2. Document explicit invocation requirement
3. Add usage examples
4. Update main README.md if needed

### Phase 4: Testing
1. Test subagent configuration loading
2. Verify routing rules work correctly
3. Test error analysis capabilities
4. Validate MCP tool integration

## Success Criteria
- [ ] Subagent is properly configured with Opus 4.6 model
- [ ] Skill workflow implements error analysis capabilities
- [ ] Routing rules are added to AGENTS.md
- [ ] Documentation explains explicit invocation requirement
- [ ] MCP tools for error analysis are properly integrated
- [ ] Subagent only triggers on explicit user request

## Notes
- The error-resolver-subagent should NOT be automatically triggered
- Must use explicit invocation phrases: "error resolver", "resolve error", "fix error"
- MCP tool access should include zai-mcp-server for error screenshot diagnosis
- Tool restrictions should prevent access to bash/task tools (delegation required)
- Skill should handle various error types: runtime errors, compilation errors, stack traces