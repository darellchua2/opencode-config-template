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
// 1. ctx.tool.transform — rewrite descriptions to prefix DISABLED warning,
//    reducing call probability at generation time. (V1 hook: tool.definition)
// 2. ctx.tool.hook("execute.before") — throw a clear, actionable error instead
//    of the ambiguous "The MCP server 'X' is not connected" message that fed
//    the retry loop.  The error text tells the model exactly what to use
//    instead. (V1 hook: tool.execute.before)
//
// This applies GLOBALLY because every agent in this deployment has
//   read: { "*": "allow", "mcp:*": "deny" }
// so no agent loses real capability.
//
// ── OpenCode V2 + V1 dual entrypoint ────────────────────────────────────────
// https://opencode.ai/v2/docs/build/plugins/ § "Support V1": V2 reads the
// default export's `id` + `setup(ctx)`; V1 (>= 1.18.29) calls `server()` and
// uses the returned hook map. One file serves both runtimes. Intentionally NO
// import of "@opencode/plugin": this file deploys as a bare .ts into
// ~/.config/opencode/plugins/ (no node_modules / package.json there), and
// Plugin.define is documented as a typing helper — the V2 runtime contract is
// just `id` + `setup` on the default export. V1 older than 1.18.29 expects
// function exports and will not load this object form.

const MCP_RESOURCE_TOOLS = new Set([
  "read_mcp_resource",
  "list_mcp_resources",
  "list_mcp_resource_templates",
])

const GUARD_MSG =
  " is disabled in this environment — no usable MCP resource servers. Use the built-in Read tool for files, glob for patterns, grep for content. Do not retry "

export default {
  id: "mcp-resource-guard",

  // ── OpenCode V2 ────────────────────────────────────────────────────────────
  async setup(ctx: any) {
    // Prong 1 (formerly the V1 "tool.definition" hook): rewrite the three
    // built-in MCP-resource tool descriptions. editor.update() ignores names
    // that are absent, so this is a no-op when no server advertises resources.
    await ctx.tool.transform((editor: any) => {
      for (const toolID of MCP_RESOURCE_TOOLS) {
        editor.update(toolID, (tool: any) => {
          tool.description =
            `[DISABLED — always fails] ${tool.description} This tool is disabled here; calling it will return an error. Use Read/glob/grep instead.`
        })
      }
    })

    // Prong 2 (formerly the V1 "tool.execute.before" hook): V2 delivers one
    // mutable `event` instead of V1's separate (input, output) arguments.
    await ctx.tool.hook("execute.before", (event: any) => {
      if (MCP_RESOURCE_TOOLS.has(event.tool)) {
        throw new Error(`${event.tool}${GUARD_MSG}${event.tool}.`)
      }
    })
  },

  // ── OpenCode V1 (>= 1.18.29) ───────────────────────────────────────────────
  async server(_input: any = {}) {
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
  },
}
