# Plan: Remove SKILL_INDEX.json generation from setup.sh

## Overview
Remove SKILL_INDEX.json generation code from setup.sh script as build-with-skills and plan-with-skills agents now use opencode-skills-maintainer skill with hardcoded skill lists.

## Issue Reference
- Issue: #47
- URL: https://github.com/darellchua2/opencode-config-template/issues/47
- Labels: enhancement, documentation, good first issue

## Files to Modify
1. `setup.sh` - Remove SKILL_INDEX.json generation section (lines 977-1047) and related logging

## Approach
1. Remove SKILL_INDEX.json generation Python script (lines 977-1047)
2. Remove validation and logging related to SKILL_INDEX.json
3. Ensure setup.sh still functions correctly without SKILL_INDEX.json generation
4. Maintain skills deployment functionality (copy skills to ~/.config/opencode/skills/)

## Success Criteria
- [x] SKILL_INDEX.json generation code removed from setup.sh
- [x] setup.sh syntax is valid (bash -n setup.sh passes)
- [x] No SKILL_INDEX references remain in setup.sh
- [ ] Skills deployment still works (cp -r ${SCRIPT_DIR}/skills/* ${SKILLS_DIR}/)
- [ ] Help text and summary sections correctly reflect 27 skills without SKILL_INDEX.json mention

## Notes
The build-with-skills and plan-with-skills agents now use opencode-skills-maintainer skill which maintains hardcoded skill lists in their system prompts. This eliminates the need for runtime skill indexing via JSON files.
