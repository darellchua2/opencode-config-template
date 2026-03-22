# Plan: Add google-mcp-specialist subagent for Google MCP server integration

## Issue Reference
- **Number**: #114
- **URL**: https://github.com/darellchua2/opencode-config-template/issues/114
- **Labels**: enhancement

## Overview

Create a new subagent (`agents/google-mcp-specialist-subagent.md`) that helps users configure and use Google's official MCP servers (Maps, BigQuery, GCE, GKE). This subagent will assist with MCP server setup, configuration, authentication, and provide usage guidance for Google's fully-managed remote MCP servers.

## Acceptance Criteria

- [x] Create `agents/google-mcp-specialist-subagent.md` following existing subagent patterns
- [x] Include frontmatter with proper description, mode, model, and permissions
- [x] Document all 4 currently available Google MCP servers with links:
  - Google Maps (Grounding Lite): https://developers.google.com/maps/ai/grounding-lite
  - BigQuery: https://docs.cloud.google.com/bigquery/docs/use-bigquery-mcp
  - Google Compute Engine (GCE): https://docs.cloud.google.com/compute/docs/reference/mcp
  - Google Kubernetes Engine (GKE): https://docs.cloud.google.com/kubernetes-engine/docs/reference/mcp
- [x] Include trigger phrases for invoking the subagent
- [x] Include delegation instructions and expected return values
- [x] Include workflow for authentication verification and configuration
- [x] Add usage examples for common scenarios
- [x] Reference main docs: https://docs.cloud.google.com/mcp/overview and GitHub: https://github.com/google/mcp

## Scope

- `agents/google-mcp-specialist-subagent.md` (new file) ✅
- `config.json` (Google MCP server entries) ✅

---

## Implementation Phases

### Phase 1: Research & Analysis
- [x] Review existing subagent patterns in `agents/ticket-creation-subagent.md`
- [x] Review frontmatter structure across existing subagents
- [x] Research Google MCP server documentation and capabilities
- [x] Identify all required tools/permissions for the subagent

### Phase 2: Core Implementation
- [x] Create `agents/google-mcp-specialist-subagent.md` with frontmatter
- [x] Add proper description, mode (`subagent`), model (`zai-coding-plan/glm-5-turbo`), and permissions
- [x] Write trigger phrases section covering Google MCP-related keywords
- [x] Write delegation instructions with required/optional input
- [x] Document all 4 Google MCP servers with descriptions and links
- [x] Include authentication verification workflow (gcloud CLI, ADC, service accounts)
- [x] Add configuration examples for `config.json` MCP entries
- [x] Write usage examples for common scenarios (setup, auth, troubleshooting)
- [x] Add return values section

### Phase 3: Review & Validation
- [x] Verify frontmatter format matches existing subagent conventions
- [x] Verify all 4 Google MCP servers are documented with correct URLs
- [x] Verify trigger phrases cover common user intents
- [x] Verify permissions are appropriate (read, write, edit, bash, glob, grep)
- [x] Confirm no local installation steps are needed (remote MCP servers)
- [x] Check that main docs references are included

### Phase 4: Documentation & Cleanup
- [x] Ensure consistent formatting with other subagent files
- [x] Verify all acceptance criteria are met
- [x] Final review of the subagent file

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
