# Plan: Align setup.sh display text consistency when using colons

## Overview
This task addresses inconsistent display text formatting in setup.sh when colons are used. The goal is to establish a consistent style for all display messages throughout the script.

## Ticket Reference
- Ticket: IBIS-108
- URL: https://betekk.atlassian.net/browse/IBIS-108

## Current Issues
The setup.sh script has inconsistent colon usage across various display messages:

**Inconsistent patterns observed:**
1. **Space before colon**: `nvm: Installed`, `Node.js: $(node --version)`, `Model: zai-coding-plan/glm-4.7`
2. **Colon at end**: `✓ Configured 4 agents:`, `✓ Configured 6 MCP servers:`, `✓ Deployed 27 skills:`
3. **No colon**: `=== Installing Node.js v24 ===`, `=== Installing/Updating OpenCode ===`
4. **Mixed usage**: Some sections use colons consistently while others don't

## Files to Modify
1. `setup.sh` - Review and update all display text with colons throughout the file

## Approach

### Step 1: Define Standard
Before making changes, establish standard pattern to use:
- **Recommendation**: Use space before colon for key-value pairs (e.g., `nvm: Installed`)
- Use colon at end only for category headers (e.g., `✓ Configured 4 agents:`)
- Keep section headers without colons (e.g., `=== Installing Node.js v24 ===`)

### Step 2: Identify All Affected Lines
Search for all lines in setup.sh that contain colons in display text:
- Lines 54, 890, 896, 937, 1000, 1021-1022, 1025-1026, 1033-1034, 1039-1041, 1043-1045, 1050-1055, 1062, 1072, etc.
- Any `echo` statements with colons
- Any `log_*` calls with colons in the message

### Step 3: Apply Consistent Formatting
Update each affected line to follow the established standard:
- Key-value pairs: `key: value` format
- Category headers: `✓ Category: ` (with trailing space for following content)
- Section headers: No colons (keep `=== Title ===` format)

### Step 4: Validate Changes
- Run `bash -n setup.sh` to validate shell syntax
- Test the script with `./setup.sh --dry-run` to verify output
- Ensure no logic or functionality changes

## Success Criteria
- [ ] All display text with colons follows a consistent pattern
- [ ] No changes to logic or functionality
- [ ] Script passes shell validation: `bash -n setup.sh`
- [ ] Output remains clear and readable
- [ ] Changes tested with dry-run mode
