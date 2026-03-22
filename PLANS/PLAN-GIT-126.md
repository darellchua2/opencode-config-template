# Plan: Add Microsoft 365 Work IQ MCP servers and Microsoft specialist subagent

## Overview

Add Microsoft 365 Work IQ MCP server integration and create a Microsoft specialist subagent
to configure and use Microsoft's official MCP servers for Teams, Mail, Calendar, SharePoint,
OneDrive, User, Word, Copilot, and Dataverse.

## Ticket Reference

- **Issue**: #126
- **URL**: https://github.com/darellchua2/opencode-config-template/issues/126
- **Labels**: enhancement
- **Branch**: feat/126-microsoft-m365-mcp

## Files to Modify

| File | Action | Description |
|------|--------|-------------|
| `config.json` | Modify | Add 9 MCP servers + tool permissions |
| `agents/microsoft-m365-specialist-subagent.md` | Create | New subagent definition |
| `setup.sh` | Modify | Add subagent listing |
| `setup.ps1` | Modify | Add subagent listing |
| `README.md` | Modify | Add MCP servers table + subagent entry |

## Authentication Requirements

**IMPORTANT:** OAuth authentication is required for Microsoft 365 MCP servers.

### Prerequisites
1. **Microsoft 365 Copilot License** (paid) — Required to access Work IQ MCP servers
2. **Microsoft Entra ID (Azure AD)** — Your organization's identity provider
3. **Agent 365 Admin Consent** — IT admin must enable MCP servers in Microsoft 365 admin center

### Connection Methods

**Method 1: Interactive OAuth (Development)**
- Browser opens automatically to Microsoft login page
- Enter credentials + MFA if required
- Token is cached for future use

**Method 2: Service Principal (Production/CI)**
```bash
export AZURE_TENANT_ID="<tenant-id>"
export AZURE_CLIENT_ID="<client-id>"
export AZURE_CLIENT_SECRET="<client-secret>"
```

## MCP Servers to Add

| Server | Config Key | Endpoint | Description |
|--------|------------|----------|-------------|
| Work IQ Teams | `microsoft-teams` | /teams/v1/sse | Chats, channels, messages |
| Work IQ Mail | `microsoft-mail` | /mail/v1/sse | Email CRUD, search |
| Work IQ Calendar | `microsoft-calendar` | /calendar/v1/sse | Event management |
| Work IQ SharePoint | `microsoft-sharepoint` | /sharepoint/v1/sse | Files, lists, search |
| Work IQ OneDrive | `microsoft-onedrive` | /onedrive/v1/sse | Personal files |
| Work IQ User | `microsoft-user` | /me/v1/sse | Profile, manager |
| Work IQ Word | `microsoft-word` | /word/v1/sse | Document creation |
| Work IQ Copilot | `microsoft-copilot` | /copilot/v1/sse | Copilot conversations |
| Dataverse | `microsoft-dataverse` | /dataverse/v1/sse | Business data CRUD |

## Approach

### Phase 1: Configuration

#### Step 1.1: Add MCP servers to config.json
- Add 9 MCP server entries to `mcp` section
- All servers disabled by default (`"enabled": false`)
- Use `mcp-remote` with SSE transport
- Add environment variables where needed (AZURE_TENANT_ID, POWER_PLATFORM_ENV_ID)

#### Step 1.2: Add tool permissions to config.json
- Add 9 tool permission entries to `tools` section
- All permissions set to `false` (disabled by default)

### Phase 2: Subagent Creation

#### Step 2.1: Create microsoft-m365-specialist-subagent.md
Follow pattern from `google-mcp-specialist-subagent.md`:
- Description with trigger phrases
- Model: zai-coding-plan/glm-5-turbo
- Permissions: read, write, edit, glob, grep, bash, webfetch
- Tool permissions: Full access to all microsoft-* tools
- Include authentication guidance
- Include usage examples

#### Step 2.2: Define trigger phrases
- "microsoft mcp" / "m365 mcp" / "teams mcp" / "outlook mcp"
- "sharepoint mcp" / "onedrive mcp" / "word mcp"
- "configure microsoft mcp" / "microsoft 365 mcp setup"

### Phase 3: Documentation Sync

#### Step 3.1: Update setup.sh
- Add subagent to listing section
- Increment subagent count

#### Step 3.2: Update setup.ps1
- Add subagent to listing section
- Increment subagent count

#### Step 3.3: Update README.md
- Add MCP servers table (Infrastructure section)
- Add subagent entry (Subagents table)
- Update counts

### Phase 4: Verification

#### Step 4.1: Run documentation-sync-subagent
- Ensure all docs are synchronized
- Verify counts match across all files

## Success Criteria

- [ ] All 9 MCP servers added to config.json (disabled by default)
- [ ] Tool permissions configured for all Microsoft MCP tools
- [ ] Microsoft M365 specialist subagent created with full tool access
- [ ] setup.sh updated with new subagent
- [ ] setup.ps1 updated with new subagent
- [ ] README.md updated with MCP servers and subagent
- [ ] Documentation synchronized across all files
- [ ] No syntax errors in config.json
- [ ] PLAN.md committed and pushed

## Notes

- All MCP servers disabled by default to avoid auth errors without M365 Copilot license
- Subagent has full tool access when enabled (similar to Google specialist pattern)
- OAuth required - interactive login on first use
- Dataverse requires POWER_PLATFORM_ENV_ID environment variable

## Documentation References

- [Work IQ MCP Overview](https://learn.microsoft.com/en-us/microsoft-agent-365/tooling-servers-overview)
- [Work IQ Teams Reference](https://learn.microsoft.com/en-us/microsoft-agent-365/mcp-server-reference/teams)
- [Microsoft 365 Copilot Licensing](https://www.microsoft.com/microsoft-365-copilot/pricing/individuals)
- [Agent 365 SDK Documentation](https://learn.microsoft.com/en-us/microsoft-agent-365/developer)
