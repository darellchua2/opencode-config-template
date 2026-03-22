# Plan: Add autodesk-mcp-specialist subagent for Autodesk MCP server integration

## Issue Reference
- **Number**: #116
- **URL**: https://github.com/darellchua2/opencode-config-template/issues/116
- **Labels**: enhancement

## Overview

Create a new subagent called `autodesk-mcp-specialist` that configures and actively uses Autodesk's official MCP servers. Autodesk is integrating Model Context Protocol (MCP) servers into their portfolio as part of Autodesk Platform Services (APS), providing managed, production-grade connectors for Design and Make agent workflows.

This subagent follows the pattern from `google-mcp-specialist-subagent.md` and will be a prepared configuration ready for activation once Autodesk publishes their MCP server endpoints.

**Reference**: https://www.autodesk.com/solutions/autodesk-ai/autodesk-mcp-servers

## Acceptance Criteria

- [ ] Create `agents/autodesk-mcp-specialist-subagent.md` following the pattern from `google-mcp-specialist-subagent.md`
- [ ] Include frontmatter with `mode: subagent`, `model: zai-coding-plan/glm-5-turbo`, and appropriate permissions
- [ ] Include trigger phrases for Autodesk MCP tasks (e.g., "autodesk mcp", "revit mcp", "fusion mcp", "autodesk help mcp")
- [ ] Include delegation instructions for both configuration and active usage tasks
- [ ] Document all 4 Autodesk MCP servers (Revit, Model Data Explorer, Fusion Data, Help) with tool permissions
- [ ] Include authentication workflow section (Autodesk account authentication)
- [ ] Include configuration examples for `config.json` MCP entries (remote endpoints)
- [ ] Include a "Coming Soon" section noting these are beta servers not yet publicly available
- [ ] Include troubleshooting section
- [ ] Reference main documentation URL and beta feedback URL
- [ ] Update `.AGENTS.md` (deployed) if routing instructions are needed

## Scope

- `agents/autodesk-mcp-specialist-subagent.md` (new file)
- `.AGENTS.md` (potential update for routing)
- `config.json` (potential MCP entries — placeholder only until endpoints are published)

---

## Implementation Phases

### Phase 1: Research & Pattern Analysis
- [ ] Review `google-mcp-specialist-subagent.md` on branch `issue-114` as the reference pattern
- [ ] Review Autodesk MCP server documentation for all 4 beta servers
- [ ] Identify all trigger phrases and tool permission patterns needed
- [ ] Document placeholder endpoint URLs from Autodesk docs

### Phase 2: Create Subagent File
- [ ] Create `agents/autodesk-mcp-specialist-subagent.md`
- [ ] Add frontmatter with description, mode, model, permissions, and tool grants
- [ ] Add Purpose section describing the subagent's role
- [ ] Add Trigger Phrases section with all relevant keywords
- [ ] Add Delegation Instructions section for configuration and usage tasks
- [ ] Add What This Subagent Returns section
- [ ] Add Available MCP Servers & Tools section (all 4 servers)
- [ ] Add Available MCP Servers table with descriptions and docs links
- [ ] Add Authentication Methods section (placeholder for Autodesk auth)
- [ ] Add Configuration Examples section (config.json snippets)
- [ ] Add Coming Soon / Beta Status section
- [ ] Add Workflow section
- [ ] Add Examples section with 5 usage scenarios
- [ ] Add Troubleshooting section
- [ ] Add Notes section with key caveats

### Phase 3: Config & Routing Updates
- [ ] Evaluate if `.AGENTS.md` needs routing updates for Autodesk MCP tasks
- [ ] Add placeholder MCP entries to `config.json` (disabled, with TODO comments)
- [ ] Ensure tool permissions in frontmatter match config.json entries

### Phase 4: Validation
- [ ] Verify subagent file follows the same structure as google-mcp-specialist
- [ ] Verify frontmatter YAML is valid
- [ ] Verify all 4 Autodesk MCP servers are documented
- [ ] Verify trigger phrases cover common user phrases
- [ ] Verify configuration examples are syntactically correct JSON
- [ ] Cross-check against Autodesk documentation for accuracy

### Phase 5: Documentation & Cleanup
- [ ] Remove any debug content or TODO comments from subagent file
- [ ] Ensure consistent formatting with other subagent files
- [ ] Verify the subagent can be properly loaded by OpenCode

---

## Technical Notes

### Pattern Reference
Follow the exact structure of `agents/google-mcp-specialist-subagent.md` (branch `issue-114`), adapting content for Autodesk services.

### Autodesk MCP Servers (Beta)

| Server | Status | Tools Pattern |
|--------|--------|---------------|
| Revit MCP Server | Coming Soon | `autodesk-revit*` |
| Model Data Explorer MCP Server | Coming Soon | `autodesk-model-data*` |
| Fusion Data MCP Server | Coming Soon | `autodesk-fusion*` |
| Help MCP Server | Coming Soon | `autodesk-help*` |

### Key Differences from Google MCP Specialist
- Autodesk servers are **not yet publicly available** (beta/coming soon)
- Authentication mechanism is TBD (likely Autodesk account / APS token)
- Endpoint URLs are not yet published
- Config entries should be placeholder/example with TODO comments

### Authentication (Placeholder)
Autodesk MCP servers will likely require:
- Autodesk account authentication
- Possibly Autodesk Platform Services (APS) access token
- Specific details TBD upon beta release

## Dependencies
- Autodesk MCP server endpoints (not yet published)
- Autodesk authentication documentation (not yet published)
- Beta access via https://feedback.autodesk.com/enter/

## Risks & Mitigation

| Risk | Mitigation |
|------|------------|
| Autodesk endpoints not yet available | Create as prepared configuration with placeholder URLs |
| Authentication flow unknown | Document placeholder auth section, update when known |
| API surface may change during beta | Note in file that tool permissions may need updating |
| Beta access may be restricted | Document how to request beta access |

## Success Metrics
- Subagent file follows the google-mcp-specialist pattern exactly
- All 4 Autodesk MCP servers are documented with tool permissions
- Configuration examples are valid JSON and can be activated when endpoints are published
- Trigger phrases cover all common Autodesk MCP use cases
