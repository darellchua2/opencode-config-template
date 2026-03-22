# Plan: Add nextjs-mcp-advisor subagent for Next.js MCP server integration

## Issue Reference
- **Number**: #118
- **URL**: https://github.com/darellchua2/opencode-config-template/issues/118
- **Labels**: enhancement

## Overview

Create a new subagent called `nextjs-mcp-advisor` that leverages the Next.js MCP server (`next-devtools-mcp`) to provide real-time, project-specific guidance on Next.js development best practices. This subagent acts as an advisor that helps users implement Next.js patterns correctly, diagnose issues using live application state, and follow App Router conventions.

**Reference**: https://nextjs.org/docs/app/guides/mcp

## Acceptance Criteria

- [ ] Create `agents/nextjs-mcp-advisor-subagent.md` following existing subagent patterns
- [ ] Include frontmatter with `mode: subagent`, `model: zai-coding-plan/glm-5`, and appropriate permissions
- [ ] Include trigger phrases for Next.js MCP advisor tasks
- [ ] Document all available `next-devtools-mcp` tools and their usage patterns
- [ ] Include configuration instructions for adding `next-devtools-mcp` to project `.mcp.json` files
- [ ] Add `next-devtools` MCP server entry to `config.json` (disabled by default)
- [ ] Include tool permissions in subagent frontmatter for `next-devtools*` tools
- [ ] Provide usage examples for common advisor scenarios
- [ ] Include a dedicated workflow section for dev server interaction
- [ ] Reference the official Next.js MCP documentation

## Scope

- `agents/nextjs-mcp-advisor-subagent.md` (new file)
- `config.json` (add `next-devtools` MCP server entry)
- `.AGENTS.md` (potential update for routing if needed)

---

## Implementation Phases

### Phase 1: Research & Pattern Analysis
- [ ] Review `agents/autodesk-specialist-subagent.md` as the primary reference pattern for MCP-based subagents
- [ ] Review `agents/nextjs-setup-subagent.md` to understand existing Next.js coverage and avoid overlap
- [ ] Review Next.js MCP documentation: https://nextjs.org/docs/app/guides/mcp
- [ ] Identify all trigger phrases and tool permission patterns needed
- [ ] Determine the boundary between `nextjs-setup-subagent` (scaffolding) and `nextjs-mcp-advisor` (runtime guidance)

### Phase 2: Create Subagent File
- [ ] Create `agents/nextjs-mcp-advisor-subagent.md`
- [ ] Add frontmatter with description, mode, model, permissions, and tool grants
- [ ] Add Purpose section describing the advisor's role and relationship to `nextjs-setup-subagent`
- [ ] Add Trigger Phrases section covering Next.js MCP, devtools, error diagnosis, and best practices
- [ ] Add Available MCP Tools section documenting all 6 `next-devtools-mcp` tools
- [ ] Add Project Configuration section with `.mcp.json` setup instructions
- [ ] Add Workflow section explaining how the advisor interacts with running Next.js dev servers
- [ ] Add Usage Examples section with common scenarios (error detection, upgrades, best practices, routing)
- [ ] Add Troubleshooting section covering common MCP connection issues
- [ ] Add Notes section with key caveats (Next.js 16+ requirement, project-level config)

### Phase 3: Config Updates
- [ ] Add `next-devtools` MCP server entry to `config.json` under the `mcp` section (disabled by default)
- [ ] Add `next-devtools*` tool permission entry to `config.json` under the `tools` section
- [ ] Verify JSON syntax is valid after changes
- [ ] Ensure tool permissions in subagent frontmatter match config.json entries

### Phase 4: Routing & Integration
- [ ] Evaluate if `.AGENTS.md` needs routing updates for Next.js MCP advisor tasks
- [ ] Verify the subagent can be properly discovered by OpenCode
- [ ] Ensure no conflicts with existing Next.js-related subagents and skills

### Phase 5: Validation
- [ ] Verify subagent file follows the same structure as `autodesk-specialist-subagent.md`
- [ ] Verify frontmatter YAML is valid
- [ ] Verify all 6 `next-devtools-mcp` tools are documented
- [ ] Verify trigger phrases cover common user phrases
- [ ] Verify `.mcp.json` configuration examples are syntactically correct JSON
- [ ] Cross-check against Next.js MCP documentation for accuracy
- [ ] Verify config.json is valid after additions

---

## Technical Notes

### Next.js MCP Architecture

Next.js 16+ includes a built-in MCP endpoint at `/_next/mcp` within the development server. The `next-devtools-mcp` package:
- Automatically discovers and connects to running Next.js instances
- Can connect to multiple Next.js instances on different ports
- Forwards tool calls to the appropriate dev server
- Provides a unified interface for coding agents

### Project-Level vs Global Configuration

The `next-devtools-mcp` is configured at the **project level** in `.mcp.json` (not in global `config.json`). However, we add an entry to `config.json` to ensure the tool permissions are available when the MCP server is active:

**Project `.mcp.json`** (advised by subagent):
```json
{
  "mcpServers": {
    "next-devtools": {
      "command": "npx",
      "args": ["-y", "next-devtools-mcp@latest"]
    }
  }
}
```

**Global `config.json`** (tool permissions):
```json
{
  "mcp": {
    "next-devtools": {
      "type": "local",
      "command": ["npx", "-y", "next-devtools-mcp@latest"],
      "enabled": false
    }
  },
  "tools": {
    "next-devtools*": false
  }
}
```

### Available MCP Tools

| Tool | Description |
|------|-------------|
| `get_errors` | Retrieve build, runtime, and type errors from dev server |
| `get_logs` | Get path to development log file (browser console + server output) |
| `get_page_metadata` | Get metadata about specific pages (routes, components, rendering) |
| `get_project_metadata` | Get project structure, configuration, dev server URL |
| `get_routes` | Get all routes grouped by router type (appRouter, pagesRouter) |
| `get_server_action_by_id` | Look up Server Actions by ID to find source file and function name |

### Relationship to Existing Next.js Subagent

| Aspect | `nextjs-setup-subagent` | `nextjs-mcp-advisor` (new) |
|--------|------------------------|---------------------------|
| Focus | Project scaffolding & initial config | Runtime guidance & best practices |
| MCP Usage | None | Leverages `next-devtools-mcp` |
| Skills | `nextjs-standard-setup`, `nextjs-complete-setup` | May reference docs, but focus is on live advice |
| Activation | "create next.js app", "next.js setup" | "next.js mcp", "next errors", "next advice" |
| Timing | Project creation phase | Ongoing development phase |

### Subagent Permissions

```yaml
permission:
  read: allow
  write: allow
  edit: allow
  glob: allow
  grep: allow
  bash: deny
  webfetch: allow
```

## Dependencies
- Next.js 16+ (required for MCP endpoint)
- `next-devtools-mcp` package (npm)
- Running Next.js development server for live features

## Risks & Mitigation

| Risk | Mitigation |
|------|------------|
| Next.js MCP server only works with Next.js 16+ | Document minimum version requirement clearly |
| MCP server requires running dev server | Include troubleshooting for "server not connecting" scenario |
| Overlap with `nextjs-setup-subagent` | Clearly delineate responsibilities in both subagent files |
| `next-devtools-mcp` API may evolve | Note in subagent that tools are subject to change with new Next.js releases |
| Project-level `.mcp.json` may conflict with global config | Advise users on proper configuration hierarchy |

## Success Metrics
- Subagent file follows the autodesk-specialist-subagent pattern
- All 6 `next-devtools-mcp` tools are documented with usage patterns
- Config.json entry is syntactically valid and properly disabled by default
- Trigger phrases cover common Next.js MCP advisor use cases
- Clear separation of concerns from existing `nextjs-setup-subagent`
