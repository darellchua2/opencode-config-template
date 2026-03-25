# Plan: Create new skill for HTML to PPTX conversion

## Issue Reference
- **Number**: #141
- **URL**: https://github.com/darellchua2/opencode-config-template/issues/141
- **Labels**: enhancement, minor, skills

## Overview

Create a new OpenCode skill that enables conversion of HTML content to PowerPoint presentations (.pptx files). The skill handles HTML parsing and converts common HTML elements into properly formatted PowerPoint slides, following the repository's established skill creation patterns.

## Acceptance Criteria
- [ ] Skill SKILL.md file created with proper documentation
- [ ] Skill follows the opencode-skill-creation best practices
- [ ] Skill triggers on relevant keywords (html to pptx, convert html to powerpoint, etc.)
- [ ] Documentation sync workflow invoked to update setup.sh, setup.ps1, README.md, and AGENTS.md

## Scope
- `skills/html-to-pptx/` — New skill directory (SKILL.md)
- `setup.sh` — Updated skill listings and counts
- `setup.ps1` — Updated skill listings and counts
- `README.md` — Updated skill categories table
- `AGENTS.md` — Updated routing if needed

---

## Implementation Phases

### Phase 1: Research & Analysis
- [ ] Review existing skill structure (e.g., `docx-creation`, `opencode-skill-creation`)
- [ ] Review `opencode-tooling-framework` for skill structure requirements
- [ ] Identify trigger phrases and description patterns from similar skills
- [ ] Research Python libraries for HTML-to-PPTX conversion (`python-pptx`, `beautifulsoup4`)

### Phase 2: Skill Creation
- [ ] Create `skills/html-to-pptx/SKILL.md` with full documentation
- [ ] Define trigger phrases (html to pptx, convert html to powerpoint, powerpoint from html, etc.)
- [ ] Document workflow steps for HTML parsing and PPTX generation
- [ ] Include examples for common use cases (tables, images, lists)
- [ ] Reference complementary skills (`docx-creation`)

### Phase 3: Documentation Sync
- [ ] Run documentation-sync-workflow to update setup.sh (skill count + listings)
- [ ] Run documentation-sync-workflow to update setup.ps1 (skill count + listings)
- [ ] Update README.md skill categories table
- [ ] Verify AGENTS.md routing if needed

### Phase 4: Validation
- [ ] Verify SKILL.md follows opencode-skill-creation best practices
- [ ] Verify skill is discoverable via trigger phrases
- [ ] Verify setup.sh and setup.ps1 deploy the new skill correctly
- [ ] Final review of all modified files

---

## Technical Notes
- Follow the existing skill file structure: `SKILL.md` with trigger phrases, workflow, and examples
- Consider using Python libraries: `python-pptx` for PPTX generation, `beautifulsoup4`/`lxml` for HTML parsing
- Reference `docx-creation` skill as a related/complementary skill
- The skill should be language-agnostic in its SKILL.md (documenting the approach), with implementation details as guidance

## Dependencies
- None (no blocked-by issues)

## Risks & Mitigation
| Risk | Mitigation |
|------|------------|
| Complex HTML structures may not map cleanly to PPTX | Define supported element subset in SKILL.md; document limitations |
| Large HTML files may produce unwieldy presentations | Include guidance on chunking/splitting content into slides |
| Library compatibility issues | Pin library versions and document requirements |

## Success Metrics
- Skill is properly deployed via `setup.sh` / `setup.ps1`
- Trigger phrases correctly activate the skill
- Documentation is consistent with existing skill patterns
