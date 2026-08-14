---
name: ticket-plan-workflow-skill
description: >-
  Unified GitHub Issues and JIRA planning — structured description, branch,
  PLAN.md, phased execution. Triggers: create issue, new issue, jira ticket, bug
  report, feature request, create plan, ticket with plan.
license: Apache-2.0
compatibility: opencode
category: Git/Workflow
---

## What I do

I implement a unified ticket/issue creation and planning workflow supporting both GitHub Issues and JIRA:

1. **Detect Platform**: Determine whether to use GitHub Issues or JIRA based on user input and project setup
2. **Gather Ticket Requirements**: Prompt user for structured description following industry best practices
3. **Determine Ticket Scope**: Ask if work should be broken into sub-issues/subtasks
4. **Create Ticket**: Use GitHub CLI or Atlassian MCP tools to create the ticket with appropriate labels/type
5. **Create Git Branch**: Generate branch from ticket identifier (e.g., `GIT-123` or `PROJ-456`)
5.5. **Adopt/Rename PLAN**: If an existing draft plan in `PLANS/` matches this ticket, adopt it (rename to the canonical ticket-scoped filename via `git mv`) instead of regenerating from scratch
6. **Generate PLAN file**: Create comprehensive plan with **atomic steps + rationale** (Why / Done when / Consumers affected) and a **Dependency & Consumer Map** in `PLANS/` directory
7. **Commit and Push**: Commit PLAN file with semantic formatting and push to remote
8. **Update Ticket**: Post progress comment to GitHub issue or JIRA ticket
9. **Prompt Execution**: Ask user if they want to proceed with plan execution

## Framework Skills Used

| Skill | Purpose | Used In |
|-------|---------|---------|
| `git-issue-labeler` | GitHub label assessment and assignment | Step 4 (GitHub) |
| `jira-ticket-labeler` | JIRA issue type and priority classification | Step 4 (JIRA) |
| `git-semantic-commits` | Conventional commit message formatting | Step 7 |
| `git-issue-updater` | Progress updates to GitHub issues | Step 8 (GitHub) |

## When to use me

Use this workflow when:
- Starting a new development task tracked in GitHub Issues or JIRA
- You want a standardized approach to ticket creation and planning
- You need to break down large work into structured phases
- Following the practice of planning before implementation

## Prerequisites

### GitHub Issues
- GitHub CLI (`gh`) installed and authenticated
- Git repository initialized with GitHub remote
- Write access to repository
- `gh auth status` shows valid authentication

### JIRA
- Active Atlassian/JIRA account with project access
- Git repository initialized with remote configured
- Write access to repository
- `atlassian` MCP server enabled in this session (opt-in — see MCP Availability Guard)

## MCP Availability Guard (JIRA steps)

The `atlassian` MCP server is **disabled by default**. Before any JIRA step, check whether `atlassian_*` tools exist in your tool list:

- **Present** → proceed normally.
- **Absent** → do NOT attempt or hallucinate `atlassian_*` calls. Options, in order:
  1. Interactive: offer per-project enable via `opencode-repo-setup-skill` (writes `"mcp":{"atlassian":{"enabled":true}}` into the project `opencode.json`; effective next session — this session must degrade).
  2. REST fallback: API token + `curl -u email:token` against `https://<site>.atlassian.net` (discover cloudId: `curl https://<site>.atlassian.net/_edge/tenant_info`).
  3. Degrade gracefully: run the GitHub-only flow, report JIRA steps as skipped.
- Headless/CI: skip option 1; use option 2 if credentials exist, else option 3.

## Steps

### Step 1: Detect Platform

**Detection Logic**:
```bash
# Check if user specified a platform
# If user mentions JIRA ticket format (e.g., "PROJ-123") → JIRA
# If user mentions GitHub issue (#123) → GitHub
# If user says "create issue" → GitHub
# If user says "create ticket" → Ask which platform

# Auto-detect: Check for JIRA project access
# ONLY if atlassian_* tools exist in your tool list (see MCP Availability Guard);
# otherwise treat JIRA as unavailable and default to GitHub
atlassian_getVisibleJiraProjects --cloudId "$CLOUD_ID" 2>/dev/null

# Prompt user if ambiguous
"Which platform for this ticket?
- GitHub Issues (default)
- JIRA"
```

**Platform Selection**:
- Set `PLATFORM` variable: `github` or `jira`
- This determines all subsequent steps

### Step 2: Gather Ticket Description

Prompt the user for a structured ticket description with these sections:

**Required Information**:
1. **Title/Summary**: Concise title (max 72 characters)
2. **Overview**: Brief description of what needs to be done
3. **Acceptance Criteria**: Definition of done (bullet points)
4. **Scope**: Files or areas affected
5. **Technical Notes**: Implementation considerations (optional)

**Prompt Template**:
```
Please provide the following for your ticket:

1. **Title** (required): Brief title for the ticket
   Example: "Implement user authentication API"

2. **Overview** (required): What does this ticket accomplish?
   Example: "Add JWT-based authentication endpoints for user login/registration"

3. **Acceptance Criteria** (required): How do we know it's done?
   Example:
   - Users can register with email/password
   - Users can login and receive JWT token
   - Protected routes validate JWT

4. **Scope** (required): What files/areas will be affected?
   Example: src/api/auth/, src/middleware/, tests/auth/

5. **Technical Notes** (optional): Any implementation details?
   Example: Use bcrypt for password hashing, 24h token expiry
```

### Step 3: Determine Ticket Scope

Ask user to choose ticket complexity:

**Question**: "Should this be broken into smaller sub-issues/subtasks?"

**Options**:
- **Parent with Sub-items**: Creates a parent ticket, then prompts for sub-items
- **Single Ticket**: Creates one ticket for contained work

**Parent Flow (GitHub)**:
```markdown
If Parent selected:
1. Create parent issue
2. Prompt for sub-issues (repeat until done):
   - Sub-issue title
   - Sub-issue description
3. Create each sub-issue and link to parent
4. Branch name uses parent issue number (e.g., GIT-123)
```

**Parent Flow (JIRA)**:
```markdown
If Story selected:
1. Create parent Story ticket
2. Prompt for subtasks (repeat until done):
   - Subtask summary
   - Subtask description
3. Create each subtask linked to parent Story
4. Branch name uses Story key (e.g., PROJ-123)
```

**Single Ticket Flow**:
```markdown
If Single selected:
1. Create single ticket with appropriate labels/type
2. Branch name uses ticket identifier
```

### Step 4: Create Ticket

#### GitHub Issues

**Label Detection** — delegate to `git-issue-labeler` skill:
```bash
# Use git-issue-labeler to determine appropriate labels
# The skill analyzes issue content and assigns GitHub default labels
# See: skills/git-issue-labeler-skill/SKILL.md
```

**Available Labels** (handled by `git-issue-labeler`):
- `bug`, `enhancement`, `documentation`, `good first issue`, `help wanted`
- `question`, `invalid`, `wontfix`, `duplicate`
- `priority: critical`, `priority: high`, `priority: medium`, `priority: low`
- `major`, `minor`, `patch` (semantic versioning — PRs only)

**For Single Issue**:
```bash
ISSUE_URL=$(gh issue create \
  --title "$TITLE" \
  --body "$FORMATTED_BODY" \
  --label "$LABELS" \
  --assignee @me)

ISSUE_NUMBER=$(echo "$ISSUE_URL" | grep -oE '[0-9]+$')
```

**For Parent with Sub-issues**:
```bash
PARENT_URL=$(gh issue create \
  --title "$TITLE" \
  --body "$FORMATTED_BODY" \
  --label "$LABELS" \
  --assignee @me)

PARENT_NUMBER=$(echo "$PARENT_URL" | grep -oE '[0-9]+$')

for subissue in "${SUBISSUES[@]}"; do
  gh issue create \
    --title "$subissue.title" \
    --body "$subissue.body\n\nParent: #$PARENT_NUMBER" \
    --label "$subissue.labels" \
    --assignee @me
done
```

#### JIRA Tickets

**Issue Type Detection** — delegate to `jira-ticket-labeler` skill:
```
# Use jira-ticket-labeler to determine appropriate issue type and priority
# The skill analyzes ticket content and maps to JIRA types (Bug, Story, Task, Epic)
# See: skills/jira-ticket-labeler-skill/SKILL.md
```

**Available Types** (handled by `jira-ticket-labeler`):
- Bug, Story, Task, Epic
- Priority: Highest, High, Medium, Low, Lowest

**Select JIRA Project** (if not specified):
```bash
atlassian_getVisibleJiraProjects --cloudId "$CLOUD_ID"
# Prompt user to select project by key (e.g., IBIS, PROJ, DA)
```

**For Single Task**:
```bash
TICKET_KEY=$(atlassian_createJiraIssue \
  --cloudId "$CLOUD_ID" \
  --projectKey "$PROJECT_KEY" \
  --issueTypeName "Task" \
  --summary "$SUMMARY" \
  --description "$FORMATTED_DESCRIPTION")
```

**For Story with Subtasks**:
```bash
STORY_KEY=$(atlassian_createJiraIssue \
  --cloudId "$CLOUD_ID" \
  --projectKey "$PROJECT_KEY" \
  --issueTypeName "Story" \
  --summary "$SUMMARY" \
  --description "$FORMATTED_DESCRIPTION")

for subtask in "${SUBTASKS[@]}"; do
  atlassian_createJiraIssue \
    --cloudId "$CLOUD_ID" \
    --projectKey "$PROJECT_KEY" \
    --issueTypeName "Sub-task" \
    --summary "$subtask.summary" \
    --description "$subtask.description" \
    --parent "$STORY_KEY"
done
```

### Step 5.5: Adopt or Rename Existing PLAN File

Before generating a PLAN from scratch (Step 6), check whether an existing draft should be adopted and renamed to the canonical ticket-scoped filename. This avoids duplicate plans and preserves git history.

**Canonical filenames**:
- GitHub: `PLANS/PLAN-GIT-<issue-number>.md`
- JIRA: `PLANS/PLAN-<TICKET_KEY>.md`

**Logic** (run all cases against the current ticket `$TICKET_ID`):

1. **Search candidates** in `PLANS/` only — do NOT search the repo root, where a `PLAN.md` may belong to unrelated active work (e.g. a separate initiative). Candidate patterns:
   - `PLANS/PLAN.md`
   - `PLANS/PLAN-DRAFT-*.md`
   - `PLANS/PLAN-GIT-*.md` / `PLANS/PLAN-<KEY>.md` (a prior iteration)
   - `PLANS/TODO-*.md`

   ```bash
   ls PLANS/PLAN.md PLANS/PLAN-DRAFT-*.md PLANS/TODO-*.md 2>/dev/null
   ```

2. **Already adopted?** If the canonical name (`PLAN-GIT-<n>.md` or `PLAN-<KEY>.md`) already exists → skip this step (already adopted) and proceed to **Step 7**.

3. **Single candidate → auto-adopt** via `git mv` (preserves history):
   ```bash
   git mv "PLANS/PLAN-DRAFT-<slug>.md" "PLANS/PLAN-GIT-${ISSUE_NUMBER}.md"
   ```
   - 3a. Before auto-adopting a generic `PLANS/PLAN.md` (no issue number in the filename), verify its `**Issue:**` header matches the current ticket. If it mismatches → treat it as a non-candidate and warn.

4. **Multiple candidates → prompt the user** (safer than guessing the right draft):
   ```
   Found N existing plan files in PLANS/. Which should we adopt for <TICKET_ID>?
   - PLANS/PLAN-DRAFT-foo.md
   - PLANS/PLAN-DRAFT-bar.md
   ```

5. **Non-adopted candidates → left in place with a warning** (non-destructive; the user cleans them up manually).

6. **No candidate → proceed to Step 6** (generate the PLAN from scratch using the template below).

7. **`PLANS/` directory doesn't exist → create it and proceed to Step 6** (generate from scratch):
   ```bash
   mkdir -p PLANS
   ```

After adopting, update the renamed file's `**Issue:**` / **Ticket Reference** header with the ticket URL, then proceed directly to **Step 7** (Commit and Push) — skip Step 6 generation.

> **History preservation**: always use `git mv`, never a plain `mv`, so the rename is tracked across commits.

### Step 5.6: Document Auto-Detect (BRD/SRS Draft Linking)

[Migrated from the former ticket-creation subagent on removal — preserves document-traceability when this skill runs directly in the primary session.]

After adopting/renaming the PLAN (Step 5.5) and before generating the PLAN body (Step 6), scan for draft requirement documents and offer to link them to the ticket. Document-ladder order: **BRD first, then SRS**.

**5.6a. BRD Auto-Detect** (`docs/brd/`):
```bash
ls docs/brd/BRD-draft-*.md 2>/dev/null
```
- If drafts found: ask the user (via `question`) "Found draft BRD(s): [list]. Link to this ticket?"
- If the user confirms and selects a draft:
  - Rename: `git mv docs/brd/BRD-draft-{slug}.md docs/brd/BRD-{ticket-key}.md` (if the draft was never committed / untracked on a new branch, use plain `mv` + `git add`)
  - Update the BRD header `**PLAN**:` placeholder to `PLANS/PLAN-{ticket-key}.md`
  - Set `BRD_PATH=docs/brd/BRD-{ticket-key}.md` for PLAN header injection (Step 6)
- If no drafts found or user declines: `BRD_PATH=""` (skip — backward-compatible)

**5.6b. SRS Auto-Detect** (`docs/srs/`):
```bash
ls docs/srs/SRS-draft-*.md 2>/dev/null
```
- If drafts found: ask the user "Found draft SRS(s): [list]. Link to this ticket?"
- If the user confirms and selects a draft:
  - Rename: `git mv docs/srs/SRS-draft-{slug}.md docs/srs/SRS-{ticket-key}.md` (plain `mv` + `git add` if untracked)
  - Update the SRS header `**PLAN**:` placeholder to `PLANS/PLAN-{ticket-key}.md`
  - Set `SRS_PATH=docs/srs/SRS-{ticket-key}.md` for PLAN header injection (Step 6)
- If no drafts found or user declines: `SRS_PATH=""` (skip — backward-compatible)

> **Document header injection**: when generating the PLAN (Step 6), inject linked documents into the PLAN header after the `**Branch**:` line, in ladder order — `**BRD**: {BRD_PATH}` (if set) then `**SRS**: {SRS_PATH}` (if set). Both are optional and present only when linked.

**Formatted Body/Description Template**:
```markdown
## Overview
$OVERVIEW

**BRD**: $BRD_PATH  _(optional — present only when a BRD was linked via docs/brd/)_
**SRS**: $SRS_PATH  _(optional — present only when an SRS was linked via docs/srs/)_

## Acceptance Criteria
$ACCEPTANCE_CRITERIA

## Scope
$SCOPE

## Technical Notes
$TECHNICAL_NOTES

---
*Tracking progress with ticket-plan-workflow-skill*
---

## Dependency & Consumer Map

_Before writing steps, list each touched file/module and who consumes it. Use `codegraph_callers` (code) or `tofu graph` + grep (IaC). This surfaces blast radius and execution order._

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---------------------|---------------------------|---------------------------------|-------------|
| `path/to/file`      | —                         | caller-A, module-B              | low/med/high |

## Implementation Phases

_Every step MUST be atomic (one reversible concern) and carry a rationale. Reject any step missing a "Why" — see Step Authoring Rules below._

### Canonical step format (every step must follow this shape)

- [ ] **N.M** <single atomic action — verb + target + outcome>
    — **Why:** <what this unblocks / why it must precede others>
    — **Done when:** <objective, checkable completion signal>
    — **Consumers affected:** <who depends on this; none if N/A>

### Phase 1: <name>
- [ ] **1.1** <atomic action>
    — **Why:** <rationale>
    — **Done when:** <checkable signal>
    — **Consumers affected:** <consumers or "none">
- [ ] **1.2** <atomic action>
    — **Why:** <rationale>
    — **Done when:** <checkable signal>
    — **Consumers affected:** <consumers or "none">

### Phase 2: <name>
- [ ] **2.1** <atomic action>
    — **Why:** <rationale>
    — **Done when:** <checkable signal>
    — **Consumers affected:** <consumers or "none">

### Phase 3: <name>
- [ ] **3.1** <atomic action>
    — **Why:** <rationale>
    — **Done when:** <checkable signal>
    — **Consumers affected:** <consumers or "none">

---

## Step Authoring Rules
- **Atomic**: one reversible concern per step; if a step does two things, split it.
- **Rationale mandatory**: every step MUST have a **Why**; a step without rationale is malformed and blocks commit (enforced by this skill's Step 6.5 self-check; flagged by `plan-updater-skill`).
- **Completion signal**: every step MUST have an objective **Done when** check, not a subjective "done".
- **Consumers explicit**: list affected consumers so reviewers/execution know blast radius; write "none" if truly isolated.

## Technical Notes
$TECHNICAL_NOTES

## Dependencies
_List any external dependencies or blocked-by tickets_

## Risks & Mitigation
_Identify potential risks and how to mitigate them_

## Success Metrics
_How will we measure success?_
```

### Step 6.5: Atomicity Self-Check (Commit Gate)

[Migrated from the former ticket-creation subagent on removal — enforces well-formed PLANs regardless of invocation path.]

Before committing the PLAN (Step 7), verify every implementation step is atomic and complete. **This gate blocks the commit** if any step is malformed.

**Procedure**:
1. Read the generated PLAN file back from disk.
2. Find every implementation-step line matching the checkbox marker: `- [ ] **N.M**` (and `- [x]` for completed steps).
3. For each step, confirm it carries all three rationale fields on the lines immediately following:
   - `— **Why:**`
   - `— **Done when:**`
   - `— **Consumers affected:**`
4. **If ANY step is missing any of the three** → **do NOT commit/push**. Surface the malformed steps (line number + step text) to the user, ask them to supply the missing fields, regenerate, and re-check. Only proceed once the self-check passes (zero malformed steps).
5. Stage the PLAN (and any linked BRD/SRS) only after the gate passes.

> This gate is what makes "a step without a Why is malformed and blocks commit" enforceable. It runs whether the skill is loaded directly by the primary or invoked any other way.

### Step 7: Commit and Push PLAN file

**Use `git-semantic-commits` skill** for proper commit message formatting:

```bash
# Determine PLAN filename based on platform
if [ "$PLATFORM" = "github" ]; then
  PLAN_FILE="PLANS/PLAN-GIT-${ISSUE_NUMBER}.md"
else
  PLAN_FILE="PLANS/PLAN-${TICKET_KEY}.md"
fi

# Stage PLAN file
git add "$PLAN_FILE"

# Format commit message using git-semantic-commits pattern
COMMIT_MSG="docs(plan): add $(basename $PLAN_FILE) for $TICKET_ID

Plan file created for $TICKET_ID tracking implementation phases."

git commit -m "$COMMIT_MSG"

# Push to remote
git push -u origin "$BRANCH_NAME"

echo "Committed and pushed $PLAN_FILE"
```

**Semantic Commit Format**:
- Type: `docs` (PLAN files are documentation)
- Scope: `plan` (identifies plan-related commits)
- Subject: Describes the PLAN file added
- Body: Optional additional context

### Step 7.5: Branch-Workflow Setup Signal (post-push)

[Migrated from the former ticket-creation subagent on removal — ensures new projects get offered branch-workflow setup.]

After pushing the branch (Step 7), check whether the project needs dev→uat→main release-workflow setup, applying the detection logic from `git-branch-workflow-setup-skill` §Detection Logic:

1. Check for the skip marker: `.opencode/branch-workflow-skipped`. If present → skip (do not signal).
2. Check for existing release tooling (any of): `.releaserc.json`, `release.config.js`, semantic-release / release-please / standard-version config, or `dev`/`uat`/`release` branches.
3. **If release tooling is already present** → the workflow is already set up; do not signal.
4. **If the skip marker is absent AND no release tooling is found** → emit `NEEDS_GIT_BRANCH_SETUP: true` in the return contract / summary so the primary agent can offer branch-workflow setup (the primary loads `git-branch-workflow-setup-skill` and prompts the user).

> Do NOT invoke `git-branch-workflow-setup-skill` or spawn `repo-ops-specialist-subagent` from within this skill — the primary agent owns that handoff (hub-and-spoke). This step only emits the signal.

### Step 8: Update Ticket with Initial Progress

#### GitHub Issues

**Use `git-issue-updater` skill** to add progress comment:

```bash
gh issue comment "$ISSUE_NUMBER" --body "## Planning Complete - $(date '+%Y-%m-%d %H:%M')

**Branch**: \`GIT-$ISSUE_NUMBER\`
**PLAN File**: \`PLANS/PLAN-GIT-${ISSUE_NUMBER}.md\`
**Status**: Ready to begin execution

### Completed
- [x] GitHub issue created
- [x] Branch created and checked out
- [x] PLAN file generated (atomic steps + rationale + Dependency & Consumer Map)
- [x] Initial commit pushed to remote

### Next Steps
1. Review \`PLANS/PLAN-GIT-${ISSUE_NUMBER}.md\`
2. Begin Phase 1 (first atomic step)

---
*Tracking progress with ticket-plan-workflow-skill*"
```

#### JIRA Tickets

```bash
COMMENT="**Planning Complete**

- Branch created: \`$TICKET_KEY\`
- PLANS/PLAN-${TICKET_KEY}.md committed with implementation phases
- Ready to begin execution

**Next Steps**:
1. Review PLANS/PLAN-${TICKET_KEY}.md
2. Begin Phase 1 (first atomic step)"

atlassian_addCommentToJiraIssue \
  --cloudId "$CLOUD_ID" \
  --issueIdOrKey "$TICKET_KEY" \
  --commentBody "$COMMENT"
```

**git-issue-updater Integration**:
For subsequent commits, use `git-issue-updater` skill to maintain consistent progress tracking with user, date, time, and file statistics.

### Step 9: Prompt for Plan Execution

Ask user if they want to proceed:

```
$TICKET_ID created: $TICKET_ID
Branch created and checked out: $BRANCH_NAME
$PLAN_FILE committed and pushed

Would you like to proceed with executing the plan?
- Yes: Start with Phase 1 tasks
- No: Stop here and execute manually later

[If Yes]: Begin executing todo items from $PLAN_FILE
[If No]: Workflow complete. Run tasks manually when ready.
```

## Best Practices

### Ticket Description
- **Be specific**: "Add JWT authentication" vs "Add auth"
- **Include context**: Why is this needed?
- **Define done**: Clear acceptance criteria
- **Limit scope**: One feature/fix per ticket

### Labels (GitHub)
- Use appropriate labels for discoverability
- `bug` vs `enhancement` distinction
- `help wanted` for community contributions
- `good first issue` for newcomers

### Branch Naming
- GitHub: Use `GIT-{number}` format for traceability
- JIRA: Use ticket key (e.g., `PROJ-123`)
- Keep it consistent with PLAN file naming

### PLAN File Structure
- Start with a **Dependency & Consumer Map** (blast radius before steps)
- Group work into phases for large efforts
- Every step is **atomic** (one reversible concern) and carries **Why** + **Done when** + **Consumers affected**
- A step without a **Why** is malformed — it blocks commit
- Include success criteria

### Commit Messages
- Use semantic commits: `docs(plan):`, `feat:`, `fix:`
- Reference ticket ID in message
- Keep first line under 72 chars

## Common Issues

### GitHub CLI Not Authenticated
**Issue**: `gh` command fails with auth error

**Solution**:
```bash
gh auth login
gh auth status
```

### Cannot Create JIRA Ticket
**Issue**: Permission denied or project not found

**Solution**:
- Verify project key is correct
- Check user has create permissions
- Use `atlassian_getVisibleJiraProjects` to list accessible projects

### Branch Already Exists
**Issue**: Branch with same name exists

**Solution**:
```bash
# Switch to existing branch
git checkout "$BRANCH_NAME"

# Or force create new
git checkout -B "$BRANCH_NAME"
```

### Push Rejected
**Issue**: Remote has updates

**Solution**:
```bash
git pull --rebase origin main
git push -u origin "$BRANCH_NAME"
```

### Subtask/Sub-issue Creation Fails
**Issue**: Cannot link subtask to parent

**Solution (GitHub)**:
- Reference parent manually in body: "Parent: #123"
- Use GitHub's task lists for hierarchical tracking

**Solution (JIRA)**:
- Ensure parent Story exists first
- Use correct parent key format
- Verify subtask issue type is enabled in project

## Troubleshooting Checklist

**Before starting**:
- [ ] Platform selected (GitHub or JIRA)
- [ ] CLI authenticated (`gh auth status` or Atlassian MCP)
- [ ] Git repository initialized
- [ ] Remote repository configured
- [ ] Working directory clean

**After ticket creation**:
- [ ] Ticket ID/number captured
- [ ] Ticket accessible via URL
- [ ] Labels/type assigned correctly
- [ ] Sub-items created (if parent)

**After branch creation**:
- [ ] Branch name includes ticket identifier
- [ ] Branch checked out successfully

**After PLAN file**:
- [ ] File created in PLANS/ directory
- [ ] All sections populated
- [ ] Phases have actionable todos
- [ ] Acceptance criteria listed

**After commit/push**:
- [ ] PLAN file committed with semantic message
- [ ] Branch pushed to remote
- [ ] Ticket updated with progress

## Platform Comparison

| Aspect | GitHub Issues | JIRA |
|--------|---------------|------|
| Issue Type | Labels only | Task, Story, Bug, Subtask |
| Hierarchy | Manual linking | Native parent/subtask |
| Labels | Custom + defaults | Components, Labels |
| Projects | GitHub Projects | JIRA Boards |
| Branch naming | `GIT-123` | `PROJ-123` |
| PLAN file | `PLAN-GIT-123.md` | `PLAN-PROJ-123.md` |

## Example Usage

### GitHub Issues
```
User: Create a GitHub issue for adding user authentication

Agent: I'll help you create a GitHub issue. Please provide:

1. **Title**: [Brief title, max 72 chars]
2. **Overview**: [What this issue accomplishes]
3. **Acceptance Criteria**: [Definition of done]
4. **Scope**: [Files/areas affected]
5. **Technical Notes**: [Implementation details, optional]

User: 
1. Implement user authentication API
2. Add JWT-based authentication endpoints
3. Users can register, login, logout. Protected routes work.
4. src/api/auth/, src/middleware/
5. Use bcrypt, 24h token expiry

Agent: Should this be broken into smaller sub-issues?
- Parent with Sub-issues
- Single Issue

User: Single Issue

Agent: Labels detected: enhancement
Creating issue...

Created GitHub issue: #456
Created branch: GIT-456
Created PLANS/PLAN-GIT-456.md with 5 phases
Committed and pushed to remote

Proceed with plan execution? (yes/no)
```

### JIRA Tickets
```
User: Create a JIRA ticket for adding user authentication

Agent: I'll help you create a JIRA ticket. Please provide:

1. **Summary**: [Brief title, max 72 chars]
2. **Overview**: [What this ticket accomplishes]
3. **Acceptance Criteria**: [Definition of done]
4. **Scope**: [Files/areas affected]
5. **Technical Notes**: [Implementation details, optional]

User: 
1. Implement user authentication API
2. Add JWT-based authentication endpoints
3. Users can register, login, logout. Protected routes work.
4. src/api/auth/, src/middleware/
5. Use bcrypt, 24h token expiry

Agent: Is this a large piece of work that should be broken into subtasks?
- Story with Subtasks
- Single Task

User: Single Task

Agent: Which JIRA project?
- IBIS
- PROJ
- DA

User: IBIS

Agent: 
Created JIRA ticket: IBIS-456
Created branch: IBIS-456
Created PLANS/PLAN-IBIS-456.md with 5 phases
Committed and pushed to remote

Proceed with plan execution? (yes/no)
```
