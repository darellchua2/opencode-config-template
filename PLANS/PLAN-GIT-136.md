# Plan: Create Mermaid Diagram Generation Skill

## Issue Reference
- **Number**: #136
- **URL**: https://github.com/darellchua2/opencode-config-template/issues/136
- **Labels**: enhancement, skills

## Overview

Create a new OpenCode skill (`mermaid-diagram-creator`) that generates Mermaid diagrams (`.mmd` files) from workflow definitions or descriptions, converts them to PNG images for visual documentation, and handles complex diagrams by splitting them into multiple images. 

**Additionally:**
- Add Mermaid CLI installation to `setup.sh` and `setup.ps1` with version check/update
- Create a global subagent (`mermaid-diagram-subagent`) for delegated diagram creation

## Repository Context

This is `opencode-config-template` — a configurator repository that deploys user-level OpenCode configuration to `~/.config/opencode/`. All changes must update deployment scripts and counts.

## Acceptance Criteria

### Skill
- [ ] Skill follows the `opencode-skill-creation` best practices
- [ ] Supports various diagram types (flowchart, sequence, class, state, ER, Gantt, pie, mindmap, gitgraph)
- [ ] Automatically creates the target PLAN directory if it doesn't exist
- [ ] Generates high-quality PNG images suitable for documentation
- [ ] Handles large diagrams by offering to split into multiple images
- [ ] Integrates with existing `git-issue-plan-workflow` and `jira-ticket-plan-workflow`
- [ ] References `ascii-diagram-creator` skill for structural patterns
- [ ] Includes prerequisites section (e.g., `mmdc` CLI from Mermaid CLI)
- [ ] Provides troubleshooting guidance for common issues

### Setup Scripts
- [ ] `setup.sh` includes `setup_mermaid_cli()` function with version check/update
- [ ] `setup.ps1` includes `Set-MermaidCLI` function with version check/update
- [ ] Both scripts integrate Mermaid CLI setup into interactive flow

### Subagent
- [ ] Global subagent `mermaid-diagram-subagent` created in `agents/`
- [ ] Subagent follows `opencode-agent-creation` best practices
- [ ] Subagent handles diagram generation delegation tasks
- [ ] **Subagent checks for Mermaid CLI (`mmdc`) installation before execution**
- [ ] **Subagent provides clear installation instructions if mmdc is missing**
- [ ] **Subagent offers `npx` fallback option when mmdc is not installed**
- [ ] AGENTS.md updated with routing for diagram tasks

## Scope

| File | Change Type |
|------|-------------|
| `skills/mermaid-diagram-creator/SKILL.md` | New skill file |
| `agents/mermaid-diagram-subagent.md` | New global subagent |
| `setup.sh` | Add Mermaid CLI setup + skill listing + agent listing |
| `setup.ps1` | Add Mermaid CLI setup + skill listing + agent listing |
| `README.md` | Update skill categories, counts, and subagents table |
| `AGENTS.md` | Add routing entry for diagram subagent |

---

## Implementation Phases

### Phase 1: Research & Design
- [ ] Study `ascii-diagram-creator/SKILL.md` for structural patterns and conventions
- [ ] Review `opencode-skill-creation` skill for best practices
- [ ] Review `opencode-agent-creation` skill for subagent patterns
- [ ] Document Mermaid CLI (`mmdc`) capabilities and installation methods
- [ ] Define the YAML frontmatter metadata for the skill
- [ ] Design the skill's step-by-step workflow
- [ ] Design subagent capabilities and delegation patterns

### Phase 2: Core Skill Implementation
- [ ] Create `skills/mermaid-diagram-creator/SKILL.md` with full content:
  - YAML frontmatter (name, description, license, compatibility, metadata)
  - "What I do" section describing capabilities
  - "When to use me" section with trigger conditions
  - "Prerequisites" section (mmdc/npx installation)
  - Step-by-step workflow (analyze → generate → convert → verify)
  - Diagram type reference section (flowchart, sequence, class, state, ER, Gantt, etc.)
  - File storage convention section (PLANS/PLAN-[issue/ticket-number]/)
  - Examples section (at least 3 examples covering different diagram types)
  - Large diagram splitting strategy
  - Integration section for git-issue-plan-workflow and jira-ticket-plan-workflow
  - Troubleshooting section
  - Best practices section

### Phase 3: Subagent Implementation
- [ ] Create `agents/mermaid-diagram-subagent.md`:
  - YAML frontmatter with system prompt and tool configuration
  - Specialized instructions for diagram generation
  - Support for multiple diagram types
  - Automatic file storage in PLAN directories
  - Integration with planning workflows
- [ ] Update `AGENTS.md` with routing for diagram-related tasks

### Phase 4: Setup Script Updates (Mermaid CLI Installation)
- [ ] Add `setup_mermaid_cli()` function to `setup.sh`:
  - Check if `mmdc` is installed
  - Fetch latest version from npm: `npm view @mermaid-js/mermaid-cli version`
  - Compare with installed version and prompt for update if outdated
  - Install via `npm install -g @mermaid-js/mermaid-cli` if not present
  - Integrate into interactive setup flow
  - Update help text to document Mermaid CLI dependency
- [ ] Add `Set-MermaidCLI` function to `setup.ps1`:
  - Same logic for Windows/PowerShell
  - Integrate into interactive menu

### Phase 5: Deployment Configuration
- [ ] Add `mermaid-diagram-creator` to `setup.sh` skill listings (increment count)
- [ ] Add `mermaid-diagram-creator` to `setup.ps1` skill listings (increment count)
- [ ] Add `mermaid-diagram-subagent` to `setup.sh` AGENTS section (increment count)
- [ ] Add `mermaid-diagram-subagent` to `setup.ps1` AGENTS section (increment count)
- [ ] Update `README.md` skill categories table (add to Documentation/Tools category)
- [ ] Update `README.md` subagents table with new entry
- [ ] Update total skill count in `README.md` intro paragraph
- [ ] Update total subagent count in `README.md`

### Phase 6: Integration & Validation
- [ ] Verify skill is correctly deployed by running `setup.sh`
- [ ] Verify subagent is correctly deployed by running `setup.sh`
- [ ] Test skill trigger from OpenCode CLI
- [ ] Test subagent delegation from OpenCode CLI
- [ ] Validate Mermaid CLI installation and `.mmd` → PNG conversion works
- [ ] Test integration with `git-issue-plan-workflow` (diagram in PLANS/ directory)
- [ ] Test integration with `jira-ticket-plan-workflow` (diagram in PLANS/ directory)
- [ ] Test large diagram splitting behavior

### Phase 7: Documentation & Finalization
- [ ] Review skill content for completeness and accuracy
- [ ] Review subagent content for completeness and accuracy
- [ ] Ensure all acceptance criteria are met
- [ ] Run any existing lint/validation on modified files
- [ ] Code review preparation

---

## Technical Notes

### Mermaid CLI Installation

```bash
# Via npx (zero-install, recommended for fallback)
npx @mermaid-js/mermaid-cli -h

# Via npm global install (for setup.sh/ps1)
npm install -g @mermaid-js/mermaid-cli

# Verify installation
mmdc --version

# Check latest version
npm view @mermaid-js/mermaid-cli version
```

### Setup Function Template (setup.sh)

```bash
setup_mermaid_cli() {
    echo ""
    echo "=== Checking Mermaid CLI ==="
    
    if command_exists mmdc; then
        local installed_version
        installed_version=$(mmdc --version 2>/dev/null | grep -oP '\d+\.\d+\.\d+' || echo "unknown")
        log_info "Mermaid CLI is installed (v${installed_version})"
        
        local latest_version
        latest_version=$(npm view @mermaid-js/mermaid-cli version 2>/dev/null)
        log_info "Latest version: v${latest_version}"
        
        if [ "$installed_version" != "$latest_version" ]; then
            log_warn "A newer version of Mermaid CLI is available!"
            if prompt_yes_no "Update Mermaid CLI to v${latest_version}?" "y"; then
                run_cmd "npm install -g @mermaid-js/mermaid-cli@latest"
                log_success "Mermaid CLI updated successfully"
            fi
        else
            log_success "Mermaid CLI is up to date"
        fi
    else
        log_info "Mermaid CLI is not installed"
        if prompt_yes_no "Install Mermaid CLI?" "y"; then
            run_cmd "npm install -g @mermaid-js/mermaid-cli"
            log_success "Mermaid CLI installed successfully"
        fi
    fi
}
```

### Key Mermaid CLI Commands

```bash
# Convert .mmd to PNG
mmdc -i diagram.mmd -o diagram.png

# Convert with custom dimensions (default: 1920x1080)
mmdc -i diagram.mmd -o diagram.png -w 1920 -H 1080

# Convert with dark theme
mmdc -i diagram.mmd -o diagram.png -t dark

# Convert with custom background
mmdc -i diagram.mmd -o diagram.png -b white
```

### File Storage Convention

```
PLANS/
├── PLAN-GIT-136/
│   ├── architecture-flowchart.mmd
│   ├── architecture-flowchart.png
│   ├── sequence-diagram.mmd
│   └── sequence-diagram.png
└── PLAN-IBIS-456/
    ├── deployment-flow.mmd
    └── deployment-flow.png
```

### Subagent Structure

```yaml
---
name: mermaid-diagram-subagent
description: Specialized subagent for creating Mermaid diagrams with PNG conversion
tools:
  - read
  - write
  - edit
  - bash
  - skill
---

## Purpose
Handle delegated diagram generation tasks, supporting multiple diagram types and automatic splitting.

## Capabilities
- Parse natural language descriptions into Mermaid syntax
- Generate flowcharts, sequence, class, state, ER diagrams, etc.
- Render to PNG with configurable dimensions
- Split complex diagrams into multiple files
- Store outputs in correct PLAN directory structure

## Mermaid CLI Check (CRITICAL)

Before any diagram conversion, ALWAYS check if Mermaid CLI is installed:

### Check Workflow
1. Run `command -v mmdc` or `which mmdc` to verify installation
2. If NOT installed:
   - Display error message with installation instructions
   - Recommend: `npm install -g @mermaid-js/mermaid-cli`
   - Offer npx fallback: `npx @mermaid-js/mermaid-cli`
   - Ask user to proceed with npx or abort
3. If installed:
   - Proceed with mmdc command execution

### Error Message Template
```
⚠️  Mermaid CLI (mmdc) is not installed.

To install Mermaid CLI, run one of:
  npm install -g @mermaid-js/mermaid-cli

Or use npx for zero-install (slower):
  npx @mermaid-js/mermaid-cli -i diagram.mmd -o diagram.png
```

## Workflow
1. Check if mmdc is installed (abort with instructions if not)
2. Analyze request to determine diagram type
3. Generate Mermaid syntax
4. Save .mmd file to appropriate PLAN directory
5. Convert to PNG using mmdc (or npx fallback)
6. Verify output and report location
```

## Dependencies
- Mermaid CLI (`@mermaid-js/mermaid-cli`) — required for `.mmd` → PNG conversion
- Node.js / npm — required to run Mermaid CLI
- ImageMagick (optional) — for additional image processing if needed

## Risks & Mitigation

| Risk | Mitigation |
|------|------------|
| Mermaid CLI not installed on user machine | Provide clear installation instructions; suggest `npx` for zero-install |
| Large diagrams fail to render | Implement auto-detection and offer splitting into sub-diagrams |
| Mermaid syntax errors | Validate `.mmd` syntax before conversion; provide clear error messages |
| PNG quality insufficient for docs | Use 1920x1080 default resolution with configurable options |
| Setup script drift | Use documentation-sync-subagent to verify consistency |

## Success Metrics
- Skill follows all `opencode-skill-creation` conventions
- Subagent follows all `opencode-agent-creation` conventions
- Mermaid diagrams render correctly to PNG at 1920x1080
- File storage convention is consistent with PLANS/ directory structure
- Integration with planning workflows is seamless
- Skill and subagent are properly deployed via `setup.sh` and `setup.ps1`
- Mermaid CLI installation integrated into setup flow with version checking
