# Plan: Create docx-creation skill and subagent for Word document operations

## Issue Reference
- **Number**: #93
- **URL**: https://github.com/darellchua2/opencode-config-template/issues/93
- **Labels**: enhancement

## Overview
Create a new OpenCode skill (`docx-creation`) and corresponding subagent (`docx-creation-subagent`) for comprehensive Word document manipulation including creation, reading, editing, tracked changes, comments, and conversions.

## Acceptance Criteria
- [x] `skills/docx-creation/SKILL.md` created with proper OpenCode format
- [x] `docx-creation-subagent` added to `config.json`
- [x] `.AGENTS.md` updated with new subagent domain

## Scope
- `skills/docx-creation/SKILL.md` (new)
- `config.json` (modify - add subagent)
- `.AGENTS.md` (modify - add domain entry)

---

## Implementation Phases

### Phase 1: Create Skill Directory and SKILL.md
- [x] Create `skills/docx-creation/` directory
- [x] Create `SKILL.md` with proper YAML frontmatter

### Phase 2: Add Subagent to config.json
- [x] Add `docx-creation-subagent` entry

### Phase 3: Update .AGENTS.md
- [x] Add docx-creation-subagent to subagent domains table

---

## Success Metrics
- Skill can be loaded by OpenCode
- Subagent routes docx-related tasks correctly
