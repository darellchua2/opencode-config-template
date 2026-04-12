# Plan: Remove Atlassian OAuth2 and PAT direct API implementations

## Issue Reference
- **Number**: #152
- **URL**: https://github.com/darellchua2/opencode-config-template/issues/152
- **Labels**: enhancement, refactoring

## Overview
Remove the two redundant Atlassian connectivity approaches (OAuth2 direct API and PAT direct API) from the repository. The `atlassian` MCP server in `config.json` already handles all JIRA/Confluence integration via `mcp-remote`. Keeping only the MCP approach eliminates manual token management, env var boilerplate, and duplicate skill maintenance.

## Acceptance Criteria
- [x] Delete `skills/jira-ticket-oauth-workflow/` directory entirely
- [x] Delete `skills/jira-ticket-pat-workflow/` directory entirely
- [x] Remove `setup_jira_oauth()` function from `setup.sh` (lines ~1213-1317)
- [x] Remove `setup_jira_pat()` function from `setup.sh` (lines ~1319-1394)
- [x] Remove JIRA OAuth2 env var initializations from `setup.sh` (JIRA_CLIENT_ID, JIRA_CLIENT_SECRET, JIRA_ACCESS_TOKEN, JIRA_REFRESH_TOKEN, JIRA_CLOUD_ID, JIRA_PAT, JIRA_SITE — around lines 308-317)
- [x] Remove JIRA OAuth2 credential persistence block from `setup_shell_vars()` in `setup.sh` (lines ~2099-2165)
- [x] Remove JIRA PAT credential persistence block from `setup_shell_vars()` in `setup.sh` (lines ~2167-2207)
- [x] Remove menu options 5 (Configure JIRA OAuth2) and 6 (Configure JIRA PAT) from setup menu in `setup.sh` (lines ~2806-2824), renumber subsequent option 7 to 5
- [x] Update JIRA skill count from 5 to 3 in `setup.sh` skill listing (line ~571): keep only `jira-ticket-plan-workflow, jira-status-updater, jira-git-integration`
- [x] Remove OAuth/PAT references from `setup.sh` summary and help text
- [x] Remove equivalent OAuth/PAT functions and env vars from `setup.ps1`
- [x] Update JIRA skill count from 5 to 3 in `setup.ps1` skill listing
- [x] Update `README.md` JIRA skill category: change "(5)" to "(3)", remove `jira-ticket-oauth-workflow` and `jira-ticket-pat-workflow` from the list
- [x] Remove "JIRA OAuth2" mention from README.md setup.sh description row
- [x] Keep `config.json` atlassian MCP entry untouched (this IS the MCP server we keep)
- [x] Keep `skills/jira-ticket-plan-workflow/`, `skills/jira-status-updater/`, `skills/jira-git-integration/` untouched (they use MCP tools)
- [x] Keep all `agents/` atlassian tool permissions untouched
- [x] Update cross-references to `jira-ticket-oauth-workflow` or `jira-ticket-pat-workflow` in other skill files if they mention oauth/pat as related
- [x] Run documentation-sync-workflow to ensure all counts are consistent

## Scope
- `skills/jira-ticket-oauth-workflow/` (delete)
- `skills/jira-ticket-pat-workflow/` (delete)
- `setup.sh` (remove functions, env vars, menu options, update counts)
- `setup.ps1` (remove equivalent functions, env vars, update counts)
- `README.md` (update JIRA category, counts, descriptions)
- `AGENTS.md` (if any oauth/pat routing references exist)

---

## Implementation Phases

### Phase 1: Analysis & Verification
- [x] Verify `config.json` atlassian MCP entry is correct and will NOT be touched
- [x] Identify all cross-references to oauth/pat workflows across the codebase (skill files, agents, docs)
- [x] Confirm `skills/jira-ticket-plan-workflow/SKILL.md` references to oauth/pat
- [x] Confirm `skills/jira-status-updater/SKILL.md` and `skills/jira-git-integration/SKILL.md` have no oauth/pat dependencies
- [x] Verify no agent files reference oauth/pat skills in their instructions

### Phase 2: Delete Skill Directories
- [x] Delete `skills/jira-ticket-oauth-workflow/` directory entirely
- [x] Delete `skills/jira-ticket-pat-workflow/` directory entirely

### Phase 3: Clean setup.sh
- [x] Remove JIRA OAuth2 env var initializations (~lines 308-317): JIRA_CLIENT_ID, JIRA_CLIENT_SECRET, JIRA_ACCESS_TOKEN, JIRA_REFRESH_TOKEN, JIRA_CLOUD_ID, JIRA_PAT, JIRA_SITE
- [x] Remove `setup_jira_oauth()` function (~lines 1213-1317)
- [x] Remove `setup_jira_pat()` function (~lines 1319-1394)
- [x] Remove JIRA OAuth2 credential persistence block in `setup_shell_vars()` (~lines 2099-2165)
- [x] Remove JIRA PAT credential persistence block in `setup_shell_vars()` (~lines ~2167-2207)
- [x] Remove menu options 5 (Configure JIRA OAuth2) and 6 (Configure JIRA PAT) from setup menu (~lines 2806-2824)
- [x] Renumber subsequent menu option 7 to 5
- [x] Update JIRA skill count from 5 to 3 in skill listing (~line 571): keep only `jira-ticket-plan-workflow, jira-status-updater, jira-git-integration`
- [x] Remove any OAuth/PAT references from summary/help text
- [x] Remove `setup_jira_oauth` and `setup_jira_pat` calls from any orchestration sections

### Phase 4: Clean setup.ps1
- [x] Remove equivalent OAuth/PAT env var initializations
- [x] Remove `Setup-JiraOAuth()` and `Setup-JiraPAT()` functions
- [x] Remove equivalent credential persistence blocks
- [x] Remove menu options for JIRA OAuth2 and JIRA PAT configuration
- [x] Renumber subsequent menu options
- [x] Update JIRA skill count from 5 to 3 in skill listing
- [x] Remove any OAuth/PAT references from summary/help text

### Phase 5: Update README.md
- [x] Change JIRA skill category count from "(5)" to "(3)"
- [x] Remove `jira-ticket-oauth-workflow` and `jira-ticket-pat-workflow` from JIRA skill list
- [x] Remove "JIRA OAuth2" mention from setup.sh description row
- [x] Update total skill count (reduce by 2)

### Phase 6: Update Cross-References
- [x] Remove/update any oauth/pat references in `jira-ticket-plan-workflow/SKILL.md`
- [x] Check `jira-status-updater/SKILL.md` and `skills/jira-git-integration/SKILL.md` for oauth/pat mentions
- [x] Check `AGENTS.md` for oauth/pat routing references
- [x] Check `.AGENTS.md` for oauth/pat routing references
- [x] Check any agent files in `agents/` or `.opencode/agents/` for oauth/pat skill references

### Phase 7: Documentation Sync & Final Validation
- [x] Run `documentation-sync-workflow` skill to ensure all counts are consistent across setup.sh, setup.ps1, README.md, and AGENTS.md
- [x] Verify `config.json` atlassian MCP entry is still intact
- [x] Verify remaining 3 JIRA skills are untouched and functional
- [x] Verify total skill count is accurate everywhere
- [x] Final review of all changes

---

## Technical Notes
The MCP server approach (`atlassian` entry in `config.json`) handles authentication via `opencode mcp auth atlassian` which uses OAuth2 under the hood but managed entirely by the MCP remote proxy. No manual `curl` calls, no token refresh logic, no env var management needed in our setup scripts.

## Risks & Mitigation
| Risk | Mitigation |
|------|-----------|
| Breaking existing users who rely on OAuth/PAT env vars | MCP approach is superior; document migration path in issue/PR |
| Accidentally removing MCP server config from config.json | Verify config.json explicitly before and after changes |
| Cross-references in skill files causing broken links | Phase 6 specifically targets cross-reference cleanup |
| Skill count mismatch across files | Phase 7 runs documentation-sync-workflow for consistency |

## Success Metrics
- Zero references to `jira-ticket-oauth-workflow` or `jira-ticket-pat-workflow` remain in the codebase
- `setup.sh` and `setup.ps1` have no OAuth/PAT functions, env vars, or menu options
- README.md shows JIRA skill count as "(3)"
- Total skill count is accurate and consistent across all documentation files
- `config.json` atlassian MCP entry is untouched
- Remaining 3 JIRA skills are fully functional
