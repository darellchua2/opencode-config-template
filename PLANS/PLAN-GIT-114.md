# Plan: Add google-mcp-specialist subagent for Google MCP server integration

## Issue Reference
- **Number**: #114
- **URL**: https://github.com/darellchua2/opencode-config-template/issues/114
- **Labels**: enhancement

## Overview

Create a new subagent (`agents/google-mcp-specialist-subagent.md`) that helps users configure and use Google's official MCP servers (Maps, BigQuery, GCE, GKE). This subagent will assist with MCP server setup, configuration, authentication, and provide usage guidance for Google's fully-managed remote MCP servers.

## Acceptance Criteria

- [ ] Create `agents/google-mcp-specialist-subagent.md` following existing subagent patterns
- [ ] Include frontmatter with proper description, mode, model, and permissions
- [ ] Document all 4 currently available Google MCP servers with links:
  - Google Maps (Grounding Lite): https://developers.google.com/maps/ai/grounding-lite
  - BigQuery: https://docs.cloud.google.com/bigquery/docs/use-bigquery-mcp
  - Google Compute Engine (GCE): https://docs.cloud.google.com/compute/docs/reference/mcp
  - Google Kubernetes Engine (GKE): https://docs.cloud.google.com/kubernetes-engine/docs/reference/mcp
- [ ] Include trigger phrases for invoking the subagent
- [ ] Include delegation instructions and expected return values
- [ ] Include workflow for authentication verification and configuration
- [ ] Add usage examples for common scenarios
- [ ] Reference main docs: https://docs.cloud.google.com/mcp/overview and GitHub: https://github.com/google/mcp

## Scope

- `agents/google-mcp-specialist-subagent.md` (new file)

---

## Implementation Phases

### Phase 1: Research & Analysis
- [ ] Review existing subagent patterns in `agents/ticket-creation-subagent.md`
- [ ] Review frontmatter structure across existing subagents
- [ ] Research Google MCP server documentation and capabilities
- [ ] Identify all required tools/permissions for the subagent

### Phase 2: Core Implementation
- [ ] Create `agents/google-mcp-specialist-subagent.md` with frontmatter
- [ ] Add proper description, mode (`subagent`), model (`zai-coding-plan/glm-5-turbo`), and permissions
- [ ] Write trigger phrases section covering Google MCP-related keywords
- [ ] Write delegation instructions with required/optional input
- [ ] Document all 4 Google MCP servers with descriptions and links
- [ ] Include authentication verification workflow (gcloud CLI, ADC, service accounts)
- [ ] Add configuration examples for `config.json` MCP entries
- [ ] Write usage examples for common scenarios (setup, auth, troubleshooting)
- [ ] Add return values section

### Phase 3: Review & Validation
- [ ] Verify frontmatter format matches existing subagent conventions
- [ ] Verify all 4 Google MCP servers are documented with correct URLs
- [ ] Verify trigger phrases cover common user intents
- [ ] Verify permissions are appropriate (read, write, edit, bash, glob, grep)
- [ ] Confirm no local installation steps are needed (remote MCP servers)
- [ ] Check that main docs references are included

### Phase 4: Documentation & Cleanup
- [ ] Ensure consistent formatting with other subagent files
- [ ] Verify all acceptance criteria are met
- [ ] Final review of the subagent file

---

## Technical Notes

- Follow the pattern established in `agents/ticket-creation-subagent.md`
- Use model: `zai-coding-plan/glm-5-turbo`
- These are fully-managed remote MCP servers (no local installation required)
- Requires Google Cloud authentication (gcloud CLI, ADC, or service accounts)
- Google MCP servers connect via `mcp-remote` with SSE endpoints
- Configuration goes in `config.json` under the `mcp` section

## Dependencies

- None (standalone subagent file creation)

## Risks & Mitigation

| Risk | Mitigation |
|------|------------|
| Google MCP server URLs change | Reference official docs pages rather than direct endpoints |
| Authentication complexity varies by user | Document multiple auth methods (gcloud, ADC, service accounts) |
| Permissions may be too broad | Limit to only necessary read/write/bash/glob/grep |

## Success Metrics

- Subagent file follows established patterns exactly
- All 4 Google MCP servers documented with accurate links
- Clear trigger phrases enable reliable subagent invocation
- Authentication workflow covers common Google Cloud auth scenarios
- Usage examples help users get started quickly
