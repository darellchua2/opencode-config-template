# Plan: Add JIRA status updater to transition ticket to Done after PR merge

## Overview
Implement JIRA ticket status transitions (e.g., "In Progress" → "Done") when pull requests are successfully merged. This fills a critical gap in the current workflow where JIRA tickets receive PR comments but their status remains unchanged.

## Issue Reference
- Issue: #52
- URL: https://github.com/darellchua2/opencode-config-template/issues/52
- Labels: enhancement, good first issue

## Problem Statement

**Current Workflow:**
1. JIRA ticket is created (e.g., IBIS-101)
2. Git branch is created from ticket key
3. PR is created and linked to JIRA ticket
4. PR receives a comment with details in JIRA
5. PR is successfully merged
6. ❌ **GAP**: JIRA ticket status remains unchanged (stays in "In Progress" or similar)

**Impact:**
- JIRA tickets accumulate without proper status updates
- Manual intervention required to close tickets
- Loss of automation benefits
- Inconsistent tracking between PR system and JIRA

## Solution Overview

Implement automated JIRA status transitions in PR-related skills to automatically update ticket status after successful PR merge.

## Files to Modify

1. **`skills/pr-creation-workflow/SKILL.md`**
   - Add JIRA status update step after successful PR merge
   - Include status transition logic and error handling
   - Document configuration options (enable/disable)

2. **`skills/git-pr-creator/SKILL.md`**
   - Add optional JIRA status update after PR merge
   - Prompt user for JIRA integration before creating PR
   - Include status update in verification/summary

3. **`skills/jira-git-workflow/SKILL.md`**
   - Document JIRA status update process in best practices
   - Add status transition examples
   - Reference new status update functionality

4. **`skills/jira-git-integration/SKILL.md`** (Optional Enhancement)
   - Add status transition step documentation
   - Include `atlassian_getTransitionsForJiraIssue` and `atlassian_transitionJiraIssue` usage
   - Provide transition examples and error handling

## Approach

### Phase 1: Audit and Validation (COMPLETED)
- [x] Analyzed existing skills for redundancy
- [x] Confirmed no skill handles JIRA status transitions
- [x] Verified MCP tools available: `atlassian_getTransitionsForJiraIssue`, `atlassian_transitionJiraIssue`

### Phase 2: Framework Updates

**Step 1: Update `pr-creation-workflow`**
1. Add new step after "Merge Confirmation" section:
   - Detect if PR was merged successfully
   - Extract JIRA ticket key from PR title or commits
   - Query available transitions for ticket
   - Identify target status ("Done" or "Closed")
   - Execute status transition using `atlassian_transitionJiraIssue`
   - Add final comment with merge details
   - Handle edge cases (transition unavailable, permissions)

2. Add documentation:
   - Status transition workflow
   - Configuration options (enable/disable)
   - Error handling and troubleshooting

**Step 2: Update `git-pr-creator`**
1. Add prompt after PR creation: "Update JIRA ticket status after merge? (yes/no)"
2. If yes, execute status update logic
3. Include status update in success summary

**Step 3: Update `jira-git-workflow`**
1. Document complete workflow including status updates
2. Add examples of status transitions
3. Update best practices section

### Phase 3: Testing and Validation

1. Test status transition with valid JIRA ticket
2. Test error handling (missing ticket, invalid transition)
3. Test without JIRA integration (backward compatibility)
4. Verify documentation completeness
5. Test edge cases (already Done status, custom workflows)

## Technical Implementation Details

### Status Transition Logic

```bash
# 1. Detect JIRA ticket from PR/commits
JIRA_TICKET=$(git log --oneline -1 | grep -oE '[A-Z]+-[0-9]+')

# 2. Get available transitions
TRANSITIONS=$(atlassian_getTransitionsForJiraIssue \
  --cloudId "$CLOUD_ID" \
  --issueIdOrKey "$JIRA_TICKET")

# 3. Find "Done" or "Closed" transition ID
TARGET_TRANSITION_ID=$(echo "$TRANSITIONS" | jq '.transitions[] | select(.to.name == "Done" or .to.name == "Closed") | .id' | head -1)

# 4. Execute transition
if [ -n "$TARGET_TRANSITION_ID" ]; then
  atlassian_transitionJiraIssue \
    --cloudId "$CLOUD_ID" \
    --issueIdOrKey "$JIRA_TICKET" \
    --transition '{"id": "'$TARGET_TRANSITION_ID'"}'
else
  echo "Warning: No 'Done' or 'Closed' transition available for $JIRA_TICKET"
fi
```

### Error Handling

1. **Transition Unavailable**
   - Log warning message
   - Continue workflow without error
   - Suggest manual status update

2. **Permission Denied**
   - Log error with details
   - Ask user for manual update
   - Provide link to JIRA ticket

3. **Already Done**
   - Skip transition
   - Log "Ticket already in target status"

4. **Invalid Ticket**
   - Log error
   - Continue workflow

## Success Criteria

- [ ] JIRA ticket status automatically transitions after PR merge
- [ ] Status transition is logged with user, date, time, PR details
- [ ] Skills documentation includes JIRA status update process
- [ ] Error handling for missing transitions or permissions
- [ ] Backward compatibility (works without JIRA integration)
- [ ] Configuration option to enable/disable status updates
- [ ] Clear documentation and examples
- [ ] Tests pass for all scenarios

## Prerequisites

- Atlassian MCP tools available and authenticated
- Valid JIRA cloud ID configured
- User has permission to transition ticket status
- Test JIRA ticket available for validation

## Potential Challenges

1. **JIRA Workflow Variations**
   - Different projects may use different status names
   - Solution: Query available transitions dynamically, don't hardcode

2. **Custom Workflow Configurations**
   - Some workflows require additional fields before transition
   - Solution: Check if transition requires fields, provide fallback

3. **Permission Issues**
   - Users may lack transition permissions
   - Solution: Graceful error handling with clear messages

4. **Backward Compatibility**
   - Must work without JIRA integration
   - Solution: Make JIRA integration optional

## Related Skills

- `jira-git-integration` - Provides JIRA utilities
- `git-issue-updater` - Adds progress comments to JIRA
- `pr-creation-workflow` - PR creation framework (to be updated)
- `git-pr-creator` - PR creation with JIRA (to be updated)
- `jira-git-workflow` - JIRA ticket creation and branching (to document)

## Notes

- Audit confirmed: No existing skill handles JIRA status transitions after PR merge
- `git-issue-updater` only adds comments, doesn't change status
- `jira-git-integration` provides basic JIRA utilities but doesn't document transitions
- Use `atlassian_getTransitionsForJiraIssue` to validate transitions before executing
- Consider JIRA project-specific workflow configurations (different transition names)
- Implementation should be backward compatible (works without JIRA)
