# Plan: Add skills folder support and remove JIRA/GitHub agents

## Overview

This implementation adds support for copying the `skills/` folder during setup and removes JIRA-related agents from the configuration. The skills folder will be deployed to `~/.config/opencode/skills/` alongside `config.json`, enabling users to have reusable workflow definitions.

## GitHub Issue Reference
- Issue: #13
- Link: https://github.com/darellchua2/opencode-config-template/issues/13

## Files to Modify

1. `setup.sh` (lines 758-801)
   - Update `setup_config()` function to handle skills folder
   - Add skills directory creation
   - Add skills folder copy logic
   - Update summary function to show skills status

2. `config.json`
   - Remove `jira-handler` agent (lines 20-43)
   - Remove `issue-creator` agent (lines 75-96)
   - Remove `atlassian` MCP server from global config (lines 104-113)
   - Remove `github` MCP server from global config (lines 99-103)

3. `README.md`
   - Update documentation to reflect skills folder deployment
   - Remove JIRA/GitHub agent references

## Approach

### Phase 1: Remove Agents and MCP Servers from config.json
1. Remove the `jira-handler` agent definition
2. Remove the `issue-creator` agent definition
3. Remove the `atlassian` MCP server from the global `mcp` section
4. Remove the `github` MCP server from the global `mcp` section
5. Validate JSON syntax after changes

### Phase 2: Update setup.sh for Skills Deployment
1. Add `SKILLS_DIR` global variable (after `CONFIG_FILE`)
2. Modify `setup_config()` function:
   - Create `${CONFIG_DIR}/skills/` directory
   - Copy entire `skills/` folder from script directory
   - Handle backup of existing skills folder
3. Update `print_summary()` function to show skills deployment status

### Phase 3: Update Documentation
1. Update README.md to mention skills folder deployment
2. Remove references to JIRA/GitHub agents
3. Update installation steps if needed

### Phase 4: Testing
1. Run `bash -n setup.sh` to validate syntax
2. Run `jq . config.json` to validate JSON
3. Test setup script in dry-run mode
4. Verify skills folder is created and copied correctly

## Order of Implementation

1. **First**: Modify config.json (removing agents and MCP servers)
2. **Second**: Update setup.sh (add skills deployment)
3. **Third**: Update README.md (documentation)
4. **Fourth**: Validate and test all changes

## Success Criteria

- [ ] config.json is valid JSON after removals
- [ ] JIRA and GitHub agents are completely removed
- [ ] setup.sh creates `~/.config/opencode/skills/` directory
- [ ] All skills from `skills/` are copied to destination
- [ ] Setup summary shows skills deployment status
- [ ] Quick setup mode (`-q`) also copies skills
- [ ] README.md reflects all changes
- [ ] Shell script syntax is valid
- [ ] Dry-run mode works correctly

## Notes

- The `skills/` folder currently contains:
  - `jira-git-workflow/SKILL.md` - May need follow-up task to remove/update
  - `nextjs-pr-workflow/SKILL.md` - Can be kept as example workflow
- Since we're removing JIRA handlers, the `jira-git-workflow` skill references will need attention in a separate issue
- Skills folder structure should maintain subdirectories
- Back up existing skills folder if it exists before overwriting
