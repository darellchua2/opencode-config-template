# PLAN-GIT-197: Mermaid diagram overhaul — MCP server + skill-only, remove 2 agents

**Issue**: [#197](https://github.com/darellchua2/opencode-config-template/issues/197)
**Branch**: `feature/mermaid-mcp-skill-only`
**Status**: Ready to begin execution

---

## Problem

Two overlapping diagram agents (`mermaid-diagram-subagent`, `diagram-subagent`) with broken permissions, global CLI install friction, and PNG rasterization issues.

## Solution

Replace with MCP server (`@peng-shawn/mermaid-mcp-server`) + single rewritten skill. SVG default. No global installs.

---

## Phase 1: Delete Agents

- [ ] Delete `opencode_app/.opencode/agents/mermaid-diagram-subagent.md`
- [ ] Delete `opencode_app/.opencode/agents/diagram-subagent.md`

## Phase 2: Add MCP Server Configuration

- [ ] Add mermaid MCP server entry to `deploy/config.json`:
  ```json
  "mermaid": {
    "command": "npx",
    "args": ["-y", "@peng-shawn/mermaid-mcp-server"],
    "env": {
      "CONTENT_IMAGE_SUPPORTED": "false"
    }
  }
  ```
- [ ] Add identical mermaid MCP server entry to `opencode_app/opencode.json`

## Phase 3: Rewrite Skill

- [ ] Rewrite `opencode_app/.opencode/skills/mermaid-diagram-creator-skill/SKILL.md`:
  - Switch from CLI-based (`mmdc`) to MCP `generate` tool
  - SVG as default output format
  - Remove all CLI install instructions
  - Document MCP tool parameters and usage patterns

## Phase 4: Update Setup Scripts

- [ ] Update agent counts 35→33 in `deploy/setup.sh` (L503, L518-519)
- [ ] Update agent counts 35→33 in `deploy/setup.ps1` (L338, L353-354)
- [ ] Remove `Set-MermaidCLI` function from `deploy/setup.ps1`
- [ ] Remove `setup_mermaid_cli` function from `deploy/setup.sh`
- [ ] Update Mermaid CLI recommendation — replace "install mmdc globally" with "MCP auto-starts via npx"

## Phase 5: Update Documentation

- [ ] Update `README.md` — remove 2 agent rows from Subagents table, update counts
- [ ] Fix `AGENTS.md` — remove `mermaid-diagram-subagent` from project-level subagents list

## Phase 6: Sync Verification

- [ ] Run `documentation-sync-workflow` skill to verify all counts and listings are consistent

---

## Key Decisions (pre-approved)

| Decision | Rationale |
|----------|-----------|
| MCP server over CLI | No global install; npx auto-provisions |
| Skill-only architecture | Primary agent loads on demand |
| SVG default | Resolution-independent |
| `CONTENT_IMAGE_SUPPORTED=false` | Forces file-to-disk (OpenCode can't handle inline images) |
| Agent count 35→33 | Two agents removed |

## Breaking Changes

- `mermaid-diagram-subagent` removed
- `diagram-subagent` removed
- Users must use `mermaid-diagram-creator-skill` instead
