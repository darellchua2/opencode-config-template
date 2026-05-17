---
name: microsoft-m365-config-skill
description: "Comprehensive Microsoft 365 MCP server reference — configuration examples, authentication methods, per-service tool documentation, troubleshooting guides, and example interactions for Teams, Mail, Calendar, SharePoint, OneDrive, Word, Copilot, and Dataverse."
license: Apache-2.0
compatibility: opencode
metadata:
  audience: developers, administrators
  workflow: m365-integration
---

## What I do

I provide comprehensive reference documentation for Microsoft's official Work IQ MCP servers. Use me when you need detailed configuration examples, authentication setup, tool documentation, troubleshooting guides, or example interactions for Microsoft 365 services via MCP.

## When to use me

- Need configuration examples for Microsoft MCP servers in config.json
- Setting up authentication (OAuth or service principal) for Microsoft 365 MCP
- Looking for detailed tool documentation per Microsoft 365 service
- Troubleshooting MCP connection or permission issues
- Want example interactions and workflows for Teams, Mail, Calendar, etc.
- Need prerequisites and environment setup details

## Available MCP Servers & Tools Reference

### Microsoft Teams (Work IQ Teams)

**Tools Available**: `microsoft-teams*`

**Tool Reference Table**:

| Tool | Description |
|------|-------------|
| `mcp_graph_chat_createChat` | Create one-on-one or group chat |
| `mcp_graph_chat_listChats` | List all chats |
| `mcp_graph_chat_postMessage` | Post message to chat |
| `mcp_graph_teams_listTeams` | List joined teams |
| `mcp_graph_teams_listChannels` | List channels in team |
| `mcp_graph_teams_postChannelMessage` | Post to channel |

**Capabilities**:
- Create, list, update, delete chats
- Post and retrieve messages
- Manage chat members
- List joined teams and channels
- Create channels and post messages
- Reply to channel messages

### Microsoft Mail (Work IQ Mail)

**Tools Available**: `microsoft-mail*`

**Capabilities**:
- Create, read, update, delete email messages
- Reply and reply-all
- Semantic search across emails
- Manage folders and rules

### Microsoft Calendar (Work IQ Calendar)

**Tools Available**: `microsoft-calendar*`

**Capabilities**:
- Create, list, update, delete events
- Accept and decline meeting invites
- Resolve scheduling conflicts
- Check availability

### Microsoft SharePoint (Work IQ SharePoint)

**Tools Available**: `microsoft-sharepoint*`

**Capabilities**:
- Upload and download files
- Get file metadata
- Search SharePoint sites
- Manage lists and list items

### Microsoft OneDrive (Work IQ OneDrive)

**Tools Available**: `microsoft-onedrive*`

**Capabilities**:
- Manage files and folders
- Upload and download files
- Share files and folders
- View storage usage

### Microsoft User (Work IQ User)

**Tools Available**: `microsoft-user*`

**Capabilities**:
- Get user profile information
- Get manager and direct reports
- Search users in organization
- Get user photo

### Microsoft Word (Work IQ Word)

**Tools Available**: `microsoft-word*`

**Capabilities**:
- Create Word documents
- Read document content
- Add comments to documents
- Reply to comments

### Microsoft Copilot (Work IQ Copilot)

**Tools Available**: `microsoft-copilot*`

**Capabilities**:
- Chat with Microsoft 365 Copilot
- Start and continue conversations
- Multi-turn conversation threads
- Ground responses with files

### Microsoft Dataverse

**Tools Available**: `microsoft-dataverse*`

**Capabilities**:
- CRUD operations on business data
- Domain-specific actions for Dynamics 365
- Query data using OData
- Execute business logic

**Requires**: `POWER_PLATFORM_ENV_ID` environment variable

## Full Configuration Examples

### config.json MCP Entries (All 9 Servers)

```json
{
  "mcp": {
    "microsoft-teams": {
      "type": "local",
      "command": ["npx", "-y", "mcp-remote", "https://mcp.cloud.microsoft/teams/v1/sse"],
      "enabled": true
    },
    "microsoft-mail": {
      "type": "local",
      "command": ["npx", "-y", "mcp-remote", "https://mcp.cloud.microsoft/mail/v1/sse"],
      "enabled": true
    },
    "microsoft-calendar": {
      "type": "local",
      "command": ["npx", "-y", "mcp-remote", "https://mcp.cloud.microsoft/calendar/v1/sse"],
      "enabled": true
    },
    "microsoft-sharepoint": {
      "type": "local",
      "command": ["npx", "-y", "mcp-remote", "https://mcp.cloud.microsoft/sharepoint/v1/sse"],
      "enabled": true
    },
    "microsoft-onedrive": {
      "type": "local",
      "command": ["npx", "-y", "mcp-remote", "https://mcp.cloud.microsoft/onedrive/v1/sse"],
      "enabled": true
    },
    "microsoft-user": {
      "type": "local",
      "command": ["npx", "-y", "mcp-remote", "https://mcp.cloud.microsoft/me/v1/sse"],
      "enabled": true
    },
    "microsoft-word": {
      "type": "local",
      "command": ["npx", "-y", "mcp-remote", "https://mcp.cloud.microsoft/word/v1/sse"],
      "enabled": true
    },
    "microsoft-copilot": {
      "type": "local",
      "command": ["npx", "-y", "mcp-remote", "https://mcp.cloud.microsoft/copilot/v1/sse"],
      "enabled": true
    },
    "microsoft-dataverse": {
      "type": "local",
      "command": ["npx", "-y", "mcp-remote", "https://mcp.cloud.microsoft/dataverse/v1/sse"],
      "environment": {
        "POWER_PLATFORM_ENV_ID": "${env:POWER_PLATFORM_ENV_ID}"
      },
      "enabled": true
    }
  }
}
```

## Authentication Methods

### Method 1: Interactive OAuth (Recommended for Development)

When you first use a Microsoft MCP server:

1. Run opencode with a Microsoft MCP tool enabled
2. Browser opens automatically to Microsoft login page
3. Enter credentials + MFA if required
4. Grant permissions to the application
5. Token is cached for future use

This is similar to how `gcloud auth login` works for Google MCP.

### Method 2: Service Principal (For Production/CI)

```bash
# Create app registration in Azure AD
az ad app create --display-name "OpenCode-M365-MCP"

# Create service principal
az ad sp create --id <app-id>

# Grant required API permissions
az ad app permission add --id <app-id> --api-permissions <permissions>

# Configure environment variables
export AZURE_TENANT_ID="<tenant-id>"
export AZURE_CLIENT_ID="<client-id>"
export AZURE_CLIENT_SECRET="<client-secret>"
```

### Environment Setup

```bash
# Required for all Microsoft MCP servers
export AZURE_TENANT_ID="<your-tenant-id>"

# Required only for Dataverse
export POWER_PLATFORM_ENV_ID="<your-power-platform-env-id>"
```

## Prerequisites Details

**IMPORTANT:** Microsoft 365 MCP servers require:

1. **Microsoft 365 Copilot License** (paid)
   - Required to access Work IQ MCP servers
   - See: https://www.microsoft.com/microsoft-365-copilot/pricing/individuals

2. **Microsoft Entra ID (Azure AD)**
   - Your organization's identity provider
   - OAuth2 authentication required

3. **Agent 365 Admin Consent**
   - IT admin must enable MCP servers in Microsoft 365 admin center
   - Navigate to Agents and Tools section

## Example Interactions

### Example 1: List Teams Chats (Active Usage)

```
Delegate: "List all my Microsoft Teams chats"

Input:
- Target: teams
- Operation: list

Output:
- Chat List: All chats with names, types, last messages
- Chat Types: oneOnOne, group
- Member Counts: For each chat
- Docs: https://learn.microsoft.com/en-us/microsoft-agent-365/mcp-server-reference/teams
```

### Example 2: Send Teams Message (Active Usage)

```
Delegate: "Send a message to John in Teams saying the meeting is rescheduled"

Input:
- Target: teams
- Operation: post_message
- Recipient: John
- Message: "The meeting is rescheduled"

Output:
- Message ID: Confirmation of sent message
- Chat ID: The chat where message was posted
- Timestamp: When message was sent
```

### Example 3: Get Calendar Events (Active Usage)

```
Delegate: "Show me my calendar events for tomorrow"

Input:
- Target: calendar
- Operation: list
- Date: tomorrow

Output:
- Event List: Meetings with times, attendees, locations
- Conflicts: Any scheduling conflicts detected
- Teams Links: Join URLs for online meetings
```

### Example 4: Search Emails (Active Usage)

```
Delegate: "Find emails from Sarah about the project proposal"

Input:
- Target: mail
- Operation: search
- Query: from:Sarah project proposal

Output:
- Email List: Matching emails with subjects, dates, snippets
- Folders: Which folders contain results
- Attachments: Any files attached to results
```

### Example 5: Configure Teams MCP (Configuration)

```
Delegate: "Set up Microsoft Teams MCP for my organization"

Input:
- Target: teams
- Purpose: Teams integration

Output:
- Configuration: MCP entry for microsoft-teams
- Auth Steps: Interactive OAuth login
- Usage: "List my Teams chats" or "Post message to channel"
- Docs: https://learn.microsoft.com/en-us/microsoft-agent-365/mcp-server-reference/teams
```

### Example 6: Configure All Microsoft MCP Servers (Configuration)

```
Delegate: "Set up all available Microsoft MCP servers"

Input:
- Target: all (teams, mail, calendar, sharepoint, onedrive, user, word, copilot, dataverse)
- Purpose: Full Microsoft 365 integration

Output:
- Configuration: MCP entries for all 9 servers
- Auth Steps: Interactive OAuth login
- Prerequisites: M365 Copilot license required
- Usage: Examples for each server
- Docs: https://learn.microsoft.com/en-us/microsoft-agent-365/tooling-servers-overview
```

## Troubleshooting Guides

### Authentication Errors

```bash
# Check if logged in to Azure CLI
az account show

# Re-authenticate if needed
az login

# For service principal issues, verify credentials
echo $AZURE_TENANT_ID
echo $AZURE_CLIENT_ID
```

**Symptoms**: "Authentication failed", "Invalid credentials", "Token expired"

**Solutions**:
- Verify AZURE_TENANT_ID is correctly set
- For service principal: verify AZURE_CLIENT_ID and AZURE_CLIENT_SECRET
- Re-run `az login` to refresh tokens
- Check that app registration exists in Azure AD
- Ensure required API permissions are granted

### Permission Denied

1. Verify Microsoft 365 Copilot license is assigned
2. Check IT admin has enabled MCP servers in Microsoft 365 admin center
3. Ensure the app has required API permissions in Azure AD
4. Verify user has appropriate Microsoft 365 licenses

**Symptoms**: "Access denied", "Insufficient permissions", "403 Forbidden"

**Solutions**:
- Confirm M365 Copilot license is active
- Ask IT admin to verify MCP server enablement in admin center
- Check Azure AD app registration has correct API permissions
- Verify user account has appropriate licenses and roles

### MCP Connection Issues

1. Verify the endpoint URL is correct (https://mcp.cloud.microsoft/...)
2. Check that AZURE_TENANT_ID is set (if using service principal)
3. Ensure the access token is not expired
4. Verify IT admin has not blocked the MCP server in admin center

**Symptoms**: "Connection failed", "Unable to connect", "Timeout"

**Solutions**:
- Verify endpoint URLs in config.json are correct
- Set AZURE_TENANT_ID environment variable if using service principal
- Refresh authentication tokens
- Contact IT admin to confirm servers are not blocked

### Missing Work IQ Features

1. Verify Microsoft 365 Copilot license is active
2. Check Agent 365 is enabled for your tenant
3. Ensure Work IQ MCP servers are activated in Microsoft 365 admin center
4. Contact IT admin if servers are blocked

**Symptoms**: "Work IQ not available", "Feature not enabled", "Server not found"

**Solutions**:
- Confirm M365 Copilot license is active and assigned
- Check Microsoft 365 admin center for Agent 365 status
- Verify Work IQ MCP servers are activated under Agents and Tools
- Work with IT admin if activation is blocked

## Documentation Links

- Main documentation: https://learn.microsoft.com/en-us/microsoft-agent-365/tooling-servers-overview
- Teams reference: https://learn.microsoft.com/en-us/microsoft-agent-365/mcp-server-reference/teams
- Mail reference: https://learn.microsoft.com/en-us/microsoft-agent-365/mcp-server-reference/mail
- Calendar reference: https://learn.microsoft.com/en-us/microsoft-agent-365/mcp-server-reference/calendar
- SharePoint reference: https://learn.microsoft.com/en-us/microsoft-agent-365/mcp-server-reference/sharepoint
- OneDrive reference: https://learn.microsoft.com/en-us/microsoft-agent-365/mcp-server-reference/onedrive
- User reference: https://learn.microsoft.com/en-us/microsoft-agent-365/mcp-server-reference/me
- Word reference: https://learn.microsoft.com/en-us/microsoft-agent-365/mcp-server-reference/word
- Copilot reference: https://learn.microsoft.com/en-us/microsoft-agent-365/mcp-server-reference/searchtools
- Dataverse reference: https://learn.microsoft.com/en-us/microsoft-agent-365/mcp-server-reference/dataverse

## Capabilities Summary

| Capability | Description |
|------------|-------------|
| **Configure** | Set up MCP entries in config.json |
| **Authenticate** | Guide through OAuth/service principal setup |
| **Manage Teams** | Chats, channels, messages, members |
| **Manage Email** | Create, read, reply, search emails |
| **Manage Calendar** | Events, meetings, availability |
| **Manage Files** | SharePoint and OneDrive operations |
| **User Operations** | Profile, manager, direct reports |
| **Document Operations** | Word document creation and comments |
| **Copilot Integration** | M365 Copilot conversations |
| **Business Data** | Dataverse CRUD operations |
| **Troubleshoot** | Diagnose auth and connection issues |

## Notes

- Microsoft MCP servers require **Microsoft 365 Copilot license** (paid)
- Uses **OAuth2 authentication** - interactive login on first use or service principal
- IT admin must **enable MCP servers** in Microsoft 365 admin center under Agents and Tools
- All tool calls are **auditable** via Microsoft Defender Advanced Hunting