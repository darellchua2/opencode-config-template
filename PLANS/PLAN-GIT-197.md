# PLAN-GIT-197: Mermaid diagram overhaul — MCP server + skill-only, remove 2 agents

**Issue**: [#197](https://github.com/darellchua2/opencode-config-template/issues/197)
**Branch**: `feature/mermaid-mcp-skill-only`
**Status**: Completed

---

## Problem

Two overlapping diagram agents (`mermaid-diagram-subagent`, `diagram-subagent`) with broken permissions, global CLI install friction, and PNG rasterization issues.

## Solution

Replace with MCP server (`@peng-shawn/mermaid-mcp-server`) + single rewritten skill. SVG default. No global installs.

---

## Phase 1: Delete Agents

- [x] Delete `opencode_app/.opencode/agents/mermaid-diagram-subagent.md`
- [x] Delete `opencode_app/.opencode/agents/diagram-subagent.md`

## Phase 2: Add MCP Server Configuration

- [x] Add mermaid MCP server entry to `deploy/config.json`:
  ```json
  "mermaid": {
    "command": "npx",
    "args": ["-y", "@peng-shawn/mermaid-mcp-server"],
    "env": {
      "CONTENT_IMAGE_SUPPORTED": "false"
    }
  }
  ```
- [x] Add identical mermaid MCP server entry to `opencode_app/opencode.json`
- [x] Add `mermaid*` tool permission to both config.json files (in tools section)

## Phase 3: Rewrite Skill

- [x] Rewrite `opencode_app/.opencode/skills/mermaid-diagram-creator-skill/SKILL.md`:
  - Switch from CLI-based (`mmdc`) to MCP `generate` tool
  - SVG as default output format
  - Remove all CLI install instructions
  - Document MCP tool parameters and usage patterns

## Phase 4: Update Setup Scripts

### deploy/setup.sh

- [x] Update agent counts 35→33 in help text (L503)
- [x] Remove `diagram` and `mermaid-diagram` from AGENTS listing in help text (L518-519)
- [x] Update MCP SERVER count 16→17 in help text (L543)
- [x] Update Mermaid CLI recommendation in REQUIREMENTS section — replaced with "MCP auto-starts via npx"
- [x] Remove `setup_mermaid_cli` function definition (~L1456-1503)
- [x] Remove `setup_mermaid_cli || true` function CALL at L2565 in main execution flow
- [x] Update ALL summary sections that print "35 agents" or reference diagram agents (L1667-1674, L2222-2228, L2360-2366)

### deploy/setup.ps1

- [x] Update agent counts 35→33 in help text (L338)
- [x] Remove `diagram` and `mermaid-diagram` from AGENTS listing in help text (L353-354)
- [x] Update MCP server count 16→17 (summary sections)
- [x] Update Mermaid CLI recommendation in REQUIREMENTS section
- [x] Remove `Set-MermaidCLI` function definition (L1014-1057)
- [x] Remove `Set-MermaidCLI` function CALL at L1921 in Main function
- [x] Update `Set-Configuration` output that prints "diagram-creator" as featured agent (L1194-1199)
- [x] Update `Show-NextSteps` output that prints "diagram-creator" and "Agents (35)" (L1742-1747)

## Phase 5: Update Documentation

- [x] Update `README.md`:
  - Remove 2 agent rows from Subagents table (L318-319)
  - Update "33 agents (5 primary + 28 subagents)" → "31 agents (5 primary + 26 subagents)" (L287)
- [x] Fix `AGENTS.md` (repo root):
  - Remove `mermaid-diagram-subagent` from project-level subagents list (L97)
  - Update "31 subagent .md files" → "29" (L50, L67)
- [x] Update `opencode_app/.opencode/agents/startup-founder-primary-agent.md`:
  - Change `diagram-subagent` delegation reference at L39 to `mermaid-diagram-creator-skill`

## Phase 6: Docker Verification

- [x] Check if `opencode_app/Dockerfile` needs `chromium` added to apt-get install (mermaid MCP server uses Puppeteer)
- [x] Add `chromium` + `fonts-liberation` to Dockerfile, set `PUPPETEER_EXECUTABLE_PATH` and `PUPPETEER_SKIP_DOWNLOAD=true`

## Phase 7: Sync Verification

- [x] Run `documentation-sync-workflow` skill to verify all counts and listings are consistent
  - Agents: 29 .md files, 33 in setup scripts (includes 4 built-in/config agents), 31 in README (5 primary + 26 subagents) — consistent with pre-existing gap for built-in explore/general
  - Skills: 61 active (63 dirs - 2 non-skill dirs _archived/scripts) — matches setup scripts
  - MCP: 17 in setup.sh, matches new mermaid entry added

---

## Key Decisions (pre-approved)

| Decision | Rationale |
|----------|-----------|
| MCP server over CLI | No global install; npx auto-provisions |
| Skill-only architecture | Primary agent loads on demand |
| SVG default | Resolution-independent |
| `CONTENT_IMAGE_SUPPORTED=false` | Forces file-to-disk (OpenCode can't handle inline images) |
| Agent count 35→33 | Two agents removed |
| MCP count 16→17 | New mermaid MCP server added |
| Subagent count 31→29 | Two agent .md files deleted |
| Tool permissions needed | `mermaid*` entry in tools section of both configs |

## Breaking Changes

- `mermaid-diagram-subagent` removed
- `diagram-subagent` removed
- Users must use `mermaid-diagram-creator-skill` instead
- `startup-founder-primary-agent` delegation target updated
