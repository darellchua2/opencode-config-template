# Plan: Create Civil 3D Specialist Subagent

## Issue Reference
- **Number**: #137
- **URL**: https://github.com/darellchua2/opencode-config-template/issues/137
- **Labels**: enhancement, subagent
- **Branch**: issue-137-create-civil-3d-specialist-subagent

## Overview
Create a specialized subagent for Autodesk Civil 3D that helps users with model modifications and feature usage. The subagent must search for Civil 3D documentation when needed and must determine the user's Civil 3D version before providing guidance.

## Acceptance Criteria
- [ ] Subagent definition file created at `agents/civil-3d-specialist.md`
- [ ] Subagent prompts for Civil 3D version when not specified
- [ ] Subagent can search Civil 3D documentation for feature guidance
- [ ] Subagent provides version-specific, accurate instructions
- [ ] `setup.sh` updated with new subagent listing
- [ ] `setup.ps1` updated with new subagent listing
- [ ] `README.md` updated with new subagent in the Subagents table
- [ ] Documentation sync completed per AGENTS.md checklist

## Scope
- **New file**: `agents/civil-3d-specialist.md` (global subagent)
- **Modified files**: `README.md`, `setup.sh`, `setup.ps1`

---

## Implementation Phases

### Phase 1: Analysis & Design
- [ ] Review existing subagent patterns in `agents/` directory
- [ ] Identify common structure and conventions used
- [ ] Review AGENTS.md sync checklist requirements
- [ ] Design subagent prompt structure for Civil 3D expertise
- [ ] Define version prompting workflow

### Phase 2: Create Subagent Definition
- [ ] Create `agents/civil-3d-specialist.md` with proper frontmatter
- [ ] Define subagent capabilities and expertise areas
- [ ] Implement documentation search capability using WebFetch
- [ ] Add mandatory version prompting logic
- [ ] Include Civil 3D version detection guidance
- [ ] Add feature guidance workflow

### Phase 3: Update Documentation Files
- [ ] Update `setup.sh` - add subagent to AGENTS section
- [ ] Update `setup.sh` - increment subagent count
- [ ] Update `setup.ps1` - add subagent to AGENTS section
- [ ] Update `setup.ps1` - increment subagent count
- [ ] Update `README.md` - add row to Subagents table
- [ ] Update `README.md` - increment total subagent count

### Phase 4: Verification
- [ ] Verify all file modifications are consistent
- [ ] Verify subagent file follows existing patterns
- [ ] Verify all counts are correct across files
- [ ] Run `setup.sh` syntax check

### Phase 5: Commit & Push
- [ ] Stage all changes
- [ ] Create semantic commit message
- [ ] Push to remote branch
- [ ] Update GitHub issue with progress

---

## Technical Notes

### Subagent Requirements
1. **Version Awareness**: MUST determine Civil 3D version before providing guidance
2. **Version Prompting**: If version not specified, MUST prompt user - critical to prevent data loss
3. **Documentation Search**: Use WebFetch to search official Autodesk documentation
4. **Feature Guidance**: Provide version-specific, accurate instructions

### Civil 3D Versions to Support
- Civil 3D 2026
- Civil 3D 2025
- Civil 3D 2024
- Civil 3D 2023
- Older versions as needed

### File Update Locations (per AGENTS.md)
| File | Lines | Update Type |
|------|-------|-------------|
| `setup.sh` | ~523-556 | Add to AGENTS section, increment count |
| `setup.ps1` | ~304-337 | Add to AGENTS section, increment count |
| `README.md` | Subagents table | Add new row |

### Subagent Template Pattern
Based on existing subagents:
```markdown
---
name: civil-3d-specialist
description: |
  Autodesk Civil 3D specialist that provides version-specific guidance...
tools:
  - Read
  - Write
  - WebFetch
  - ...
---

# Civil 3D Specialist Subagent

## Purpose
...

## Capabilities
...

## Version Detection Workflow
...

## Feature Guidance Workflow
...
```

## Dependencies
- Existing subagent patterns in `agents/` directory
- AGENTS.md documentation sync checklist
- WebFetch tool for documentation search

## Risks & Mitigation
| Risk | Mitigation |
|------|------------|
| Incorrect version guidance | Mandatory version prompting before any guidance |
| Outdated documentation URLs | Use official Autodesk help URLs |
| Missing sync updates | Follow AGENTS.md checklist strictly |

## Success Metrics
- Subagent correctly prompts for version when not specified
- Subagent can retrieve and summarize Civil 3D documentation
- All sync files updated correctly
- All tests pass
