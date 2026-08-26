// mcp-resource-guard.ts — Prevents the read_mcp_resource / list_mcp_resources /
// list_mcp_resource_templates loop that affects explore/general subagents.
//
// ── Problem ─────────────────────────────────────────────────────────────────
// When ANY connected MCP server advertises a `resources` capability (common in
// MCP SDK v2 builds, including remote HTTP-based servers), opencode registers
// three built-in tools globally:
//   - read_mcp_resource
//   - list_mcp_resources
//   - list_mcp_resource_templates
//
// These tools are hard-mapped to the `read` permission key inside
// packages/opencode/src/permission/index.ts disabled().  The hiding logic
// only removes them when the rule is { pattern: "*", action: "deny" } for
// the `read` key.  A scoped deny like  read: { "*": "allow", "mcp:*": "deny" }
// denies at RUNTIME but does NOT hide them from the LLM tool list.
//
// The fast-tier model (glm-5.3-flash) used by the explore agent sees the tool,
// calls it, hallucinates a "files" server name (from training data about
// Claude Code's filesystem MCP convention), gets "server not connected",
// retries → unbounded loop wasting context and tokens.
//
// See anomalyco/opencode#23045 (closed, root cause identified but not fixed as
// code) and anomalyco/opencode#35720 (open, related scope issue).
//
// ── Fix (two-pronged) ───────────────────────────────────────────────────────
// 1. tool.definition  — rewrite descriptions to prefix DISABLED warning,
//    reducing call probability at generation time.
// 2. tool.execute.before — throw a clear, actionable error instead of the
//    ambiguous "The MCP server 'X' is not connected" message that fed the
//    retry loop.  The error text tells the model exactly what to use instead.
//
// This applies GLOBALLY because every agent in this deployment has
//   read: { "*": "allow", "mcp:*": "deny" }
// so no agent loses real capability.

const MCP_RESOURCE_TOOLS = new Set([
  "read_mcp_resource",
  "list_mcp_resources",
  "list_mcp_resource_templates",
])

const GUARD_MSG =
  " is disabled in this environment — no usable MCP resource servers. Use the built-in Read tool for files, glob for patterns, grep for content. Do not retry "

export const McpResourceGuard = async () => {
  return {
    "tool.definition": async (
      input: { toolID: string },
      output: { description: string },
    ) => {
      if (MCP_RESOURCE_TOOLS.has(input.toolID)) {
        output.description =
          `[DISABLED — always fails] ${output.description} This tool is disabled here; calling it will return an error. Use Read/glob/grep instead.`
      }
    },

    "tool.execute.before": async (input: { tool: string }) => {
      if (MCP_RESOURCE_TOOLS.has(input.tool)) {
        throw new Error(`${input.tool}${GUARD_MSG}${input.tool}.`)
      }
    },
  }
}
