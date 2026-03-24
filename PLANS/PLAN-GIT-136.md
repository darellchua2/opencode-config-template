# Plan: Create Mermaid Diagram Generation Skill

## Issue Reference
- **Number**: #136
- **URL**: https://github.com/darellchua2/opencode-config-template/issues/136
- **Labels**: enhancement, skills

## Overview

Create a new OpenCode skill (`mermaid-diagram-creator`) that generates Mermaid diagrams (`.mmd` files) from workflow definitions or descriptions, converts them to PNG images for visual documentation, and handles complex diagrams by splitting them into multiple images. The skill should integrate with existing planning workflows.

## Acceptance Criteria
- [ ] Skill follows the `opencode-skill-creation` best practices
- [ ] Supports various diagram types (flowchart, sequence, class, state, ER, Gantt, pie, mindmap, gitgraph)
- [ ] Automatically creates the target PLAN directory if it doesn't exist
- [ ] Generates high-quality PNG images suitable for documentation
- [ ] Handles large diagrams by offering to split into multiple images
- [ ] Integrates with existing `git-issue-plan-workflow` and `jira-ticket-plan-workflow`
- [ ] References `ascii-diagram-creator` skill for structural patterns
- [ ] Includes prerequisites section (e.g., `mmdc` CLI from Mermaid CLI)
- [ ] Provides troubleshooting guidance for common issues

## Scope
- `skills/mermaid-diagram-creator/SKILL.md` — New skill file
- `setup.sh` — Add new skill to deployment listings
- `setup.ps1` — Add new skill to deployment listings (Windows)
- `README.md` — Update skill categories and counts
- `AGENTS.md` — Add routing entry if applicable

---

## Implementation Phases

### Phase 1: Research & Design
- [ ] Study `ascii-diagram-creator/SKILL.md` for structural patterns and conventions
- [ ] Review `opencode-skill-creation` skill for best practices
- [ ] Document Mermaid CLI (`mmdc`) capabilities and installation methods
- [ ] Define the YAML frontmatter metadata for the skill
- [ ] Design the skill's step-by-step workflow

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

### Phase 3: Deployment Configuration
- [ ] Add `mermaid-diagram-creator` to `setup.sh` skill listings and increment count
- [ ] Add `mermaid-diagram-creator` to `setup.ps1` skill listings and increment count
- [ ] Update `README.md` skill categories table (add to Documentation/Tools category)
- [ ] Update total skill count in `README.md` intro paragraph

### Phase 4: Integration & Validation
- [ ] Verify skill is correctly deployed by running `setup.sh`
- [ ] Test skill trigger from OpenCode CLI
- [ ] Validate Mermaid CLI installation and `.mmd` → PNG conversion works
- [ ] Test integration with `git-issue-plan-workflow` (diagram in PLANS/ directory)
- [ ] Test integration with `jira-ticket-plan-workflow` (diagram in PLANS/ directory)
- [ ] Test large diagram splitting behavior

### Phase 5: Documentation & Finalization
- [ ] Review skill content for completeness and accuracy
- [ ] Ensure all acceptance criteria are met
- [ ] Run any existing lint/validation on modified files
- [ ] Code review preparation

---

## Technical Notes

### Mermaid CLI Installation
```bash
# Via npx (zero-install, recommended)
npx @mermaid-js/mermaid-cli -h

# Via npm global install
npm install -g @mermaid-js/mermaid-cli

# Verify installation
mmdc --version
```

### Key Commands
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

### Structural Patterns (from ascii-diagram-creator)
- YAML frontmatter with name, description, license, compatibility, metadata
- Sections: What I do, When to use me, Prerequisites, Steps, Examples, Best Practices, Common Issues
- Troubleshooting checklist at the end
- Related commands section

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

## Success Metrics
- Skill follows all `opencode-skill-creation` conventions
- Mermaid diagrams render correctly to PNG at 1920x1080
- File storage convention is consistent with PLANS/ directory structure
- Integration with planning workflows is seamless
- Skill is properly deployed via `setup.sh` and `setup.ps1`
