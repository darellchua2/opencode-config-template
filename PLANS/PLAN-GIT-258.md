# Plan: Fix read_mcp_resource tool confusion + defend against OpenCode v1.18.4 GLM adapter regression

## Ticket Reference
- Platform: GitHub
- ID: #258
- URL: https://github.com/darellchua2/opencode-config-template/issues/258
- Branch: GIT-258

## Acceptance Criteria
- [ ] Agent permission blocks in configurator repo deny `read_mcp_resource`, `list_mcp_resources`, `list_mcp_resource_templates` for file-focused agents
- [ ] Global tool-selection rule added to `deploy/.AGENTS.md` (deployed to `~/.config/opencode/AGENTS.md`)
- [ ] Skill instructions in `plan-execution-skill` disambiguated (replace "load" with explicit `Read` tool reference)
- [ ] Documentation updated (README.md, setup scripts) with any new permission entries
- [ ] OpenCode version pinned to v1.18.3 until upstream fix (separate action, documented in issue)
- [ ] `filesystem` MCP server removed from canvastekk `opencode.json` (separate action, documented in issue)

---

## Dependency & Consumer Map

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---------------------|---------------------------|---------------------------------|-------------|
| `opencode_app/.opencode/agents/*.md` (permission blocks) | — | All subagents launched from configurator repo; deployed to `~/.config/opencode/agents/` | med — denies MCP resource tools globally for file-focused agents |
| `deploy/.AGENTS.md` | — | All agents (global routing rules); deployed to `~/.config/opencode/AGENTS.md` | low — additive rule, no breaking change |
| `opencode_app/.opencode/skills/plan-execution-skill/SKILL.md` | — | plan-execution-skill consumers (testing-subagent, tdd-subagent, any agent executing PLANs) | low — wording disambiguation only |
| `README.md` | Agent changes complete | Documentation readers, deploy scripts | low — count/table sync only |

## Implementation Phases

### Phase 1: Add MCP Resource Tool Deny Rules to File-Focused Agents

Add `read_mcp_resource: deny`, `list_mcp_resources: deny`, `list_mcp_resource_templates: deny` to the `permission` block of all file-focused agents that don't need MCP resource access.

- [ ] **1.1** Add deny rules to `ticket-creation-subagent.md` permission block
    — **Why:** Primary agent exhibiting the bug; creates and reads PLAN files locally
    — **Done when:** Permission block contains all three deny entries and frontmatter parses correctly
    — **Consumers affected:** ticket-creation-subagent (all projects)
- [ ] **1.2** Add deny rules to `code-review-subagent.md` permission block
    — **Why:** Reviews local source files; no need for MCP resource tools
    — **Done when:** Permission block contains all three deny entries
    — **Consumers affected:** code-review-subagent (all projects)
- [ ] **1.3** Add deny rules to `architecture-review-subagent.md` permission block
    — **Why:** Reviews local architecture files and PLAN files; no need for MCP resource tools
    — **Done when:** Permission block contains all three deny entries
    — **Consumers affected:** architecture-review-subagent (all projects)
- [ ] **1.4** Add deny rules to `explorer-subagent.md` permission block
    — **Why:** Explores local codebase; no need for MCP resource tools
    — **Done when:** Permission block contains all three deny entries
    — **Consumers affected:** explorer-subagent (all projects)
- [ ] **1.5** Add deny rules to `testing-subagent.md` permission block
    — **Why:** Reads/writes local test files; no need for MCP resource tools
    — **Done when:** Permission block contains all three deny entries
    — **Consumers affected:** testing-subagent (all projects)
- [ ] **1.6** Add deny rules to `linting-subagent.md` permission block
    — **Why:** Reads local source files for linting; no need for MCP resource tools
    — **Done when:** Permission block contains all three deny entries
    — **Consumers affected:** linting-subagent (all projects)
- [ ] **1.7** Add deny rules to `documentation-subagent.md` permission block
    — **Why:** Reads/writes local doc files; no need for MCP resource tools
    — **Done when:** Permission block contains all three deny entries
    — **Consumers affected:** documentation-subagent (all projects)
- [ ] **1.8** Add deny rules to `pr-workflow-subagent.md` permission block
    — **Why:** Reads local files for PR checks; no need for MCP resource tools
    — **Done when:** Permission block contains all three deny entries
    — **Consumers affected:** pr-workflow-subagent (all projects)
- [ ] **1.9** Add deny rules to remaining file-focused agents (`coverage-subagent.md`, `tdd-subagent.md`, `error-resolver-subagent.md`, `technical-design-specialist-subagent.md`, `requirements-specialist-subagent.md`, `discovery-specialist-subagent.md`, `opencode-tooling-subagent.md`, `loop-operator-subagent.md`, `autoresearch-code-subagent.md`, `autoresearch-research-subagent.md`)
    — **Why:** All work with local files and don't need MCP resource access; defense-in-depth across the full agent suite
    — **Done when:** All listed agents have three deny entries in their permission blocks
    — **Consumers affected:** all listed subagents (all projects)

### Phase 2: Add Tool Selection Rules Guidance

Add explicit tool-selection guidance to the most affected agent.

- [ ] **2.1** Add "Tool Selection Rules" section to `ticket-creation-subagent.md` (after Prompt Defense Baseline, before CRITICAL section)
    — **Why:** Even with permission denies, explicit guidance prevents confusion in edge cases where permissions are overridden or new MCP tools are added
    — **Done when:** Section present with rule: "Always use built-in `Read` tool for local files; NEVER use `read_mcp_resource` etc."
    — **Consumers affected:** ticket-creation-subagent

### Phase 3: Add Global Tool-Selection Rule to deploy/.AGENTS.md

- [ ] **3.1** Add "Local File Reading Rule" subsection under existing "## MCP Tool Routing" in `deploy/.AGENTS.md`
    — **Why:** Global rule that benefits ALL agents across ALL projects, not just ticket-creation; prevents the error class from recurring with other agents or other MCP servers
    — **Done when:** Subsection present with rule + comparison table (Read vs read_mcp_resource)
    — **Consumers affected:** all agents (global, user-space)

### Phase 4: Disambiguate plan-execution-skill Instructions

- [ ] **4.1** Update `opencode_app/.opencode/skills/plan-execution-skill/SKILL.md` line 105: replace "load the PLAN's" with "Use the built-in `Read` tool to open the PLAN file and review its"
    — **Why:** The word "load" is ambiguous and could trigger the model to use `read_mcp_resource` (loading MCP resources)
    — **Done when:** Line 105 uses explicit `Read` tool reference instead of generic "load"
    — **Consumers affected:** plan-execution-skill consumers (testing-subagent, tdd-subagent, any agent executing PLANs)
- [ ] **4.2** Update `opencode_app/.opencode/skills/plan-execution-skill/SKILL.md` line 128: replace "read its" with "use the `Read` tool to review its"
    — **Why:** Lowercase "read" is ambiguous; explicit tool name removes confusion
    — **Done when:** Line 128 uses explicit `Read` tool reference
    — **Consumers affected:** same as 4.1

### Phase 5: Documentation Sync

- [ ] **5.1** Run documentation-sync-workflow or manually verify README.md agent tables and setup script counts are consistent with permission block changes
    — **Why:** Permission block changes are additive (deny rules) and don't change agent counts, but README permission documentation should reflect the new deny pattern if documented
    — **Done when:** No count drift; README accurately reflects agent capabilities
    — **Consumers affected:** documentation readers, deploy scripts
