---
name: plan-execution-skill
description: Execute PLAN.md phases with automatic progress tracking. Parses plan, executes tasks sequentially, and auto-invokes plan-updater after each phase completion.
license: Apache-2.0
compatibility: opencode
metadata:
  audience: developers, agents, subagents
  workflow: planning, execution, progress-tracking
---

## What I do

I provide automatic PLAN.md execution with integrated progress tracking:

1. **Detect Current PLAN**: Extract branch name and find matching PLAN file
2. **Parse Plan Structure**: Read phases, tasks, and acceptance criteria
3. **Execute Phases**: Work through plan tasks in order
4. **Auto-Update Progress**: Invoke `plan-updater` after each phase completes
5. **Track Completion**: Mark tasks complete and commit progress automatically

## When to use me

Use this skill when:
- You say "implement the plan" or "execute the plan"
- Working on a branch with a PLAN.md file
- Want automatic progress tracking during development
- Need systematic phase-by-phase execution

**Trigger phrases**:
- "implement the plan"
- "execute the plan"
- "work on the plan"
- "continue with the plan"
- "resume plan execution"

## Subagents That Should Use This Skill

| Subagent | When to Invoke |
|----------|----------------|
| Any subagent | When user says "implement the plan" |

## Core Workflow

### Step 1: Detect Current PLAN

Identify the PLAN file for the current branch:

```bash
BRANCH_NAME=$(git branch --show-current)

# GitHub pattern: GIT-123
if [[ "$BRANCH_NAME" =~ ^GIT-([0-9]+)$ ]]; then
  ISSUE_NUM="${BASH_REMATCH[1]}"
  PLAN_FILE="PLANS/PLAN-GIT-${ISSUE_NUM}.md"
  PLAN_TYPE="github"
fi

# JIRA pattern: PROJECT-123
if [[ "$BRANCH_NAME" =~ ^([A-Z]+-[0-9]+)$ ]]; then
  PLAN_ID="${BASH_REMATCH[1]}"
  PLAN_FILE="PLANS/PLAN-${PLAN_ID}.md"
  PLAN_TYPE="jira"
fi

if [ ! -f "$PLAN_FILE" ]; then
  echo "No PLAN file found for branch: $BRANCH_NAME"
  echo "Expected: $PLAN_FILE"
  exit 1
fi

echo "Found PLAN: $PLAN_FILE"
```

### Step 2: Parse Plan Structure

Extract phases and tasks from PLAN.md:

```bash
# Extract phase headers
PHASES=$(grep -n "^### Phase" "$PLAN_FILE")

# Extract all tasks with checkboxes
TASKS=$(grep -n "^- \[ \]" "$PLAN_FILE")

# Extract completed tasks
COMPLETED=$(grep -n "^- \[x\]" "$PLAN_FILE")

echo "Found phases: $(echo "$PHASES" | wc -l)"
echo "Total tasks: $(echo "$TASKS" | wc -l)"
echo "Completed: $(echo "$COMPLETED" | wc -l)"
```

### Step 3: Analyze Current State

Determine which phase to work on:

```bash
# Find first incomplete phase
CURRENT_PHASE=$(grep -A 10 "^### Phase" "$PLAN_FILE" | grep -B 5 "^- \[ \]" | head -1)

# Find first incomplete task
NEXT_TASK=$(grep "^- \[ \]" "$PLAN_FILE" | head -1)

echo "Current phase: $CURRENT_PHASE"
echo "Next task: $NEXT_TASK"
```

### Step 4: Execute Tasks

Work through tasks systematically:

**Strategy**:
1. Group related tasks (e.g., all tests together)
2. Delegate to specialized subagents when appropriate:
   - Testing tasks → `testing-subagent`
   - Refactoring tasks → `refactoring-subagent`
   - Code review tasks → `code-review-subagent`
   - Build/deploy tasks → Parent agent
3. Execute simple tasks directly
4. Verify completion before marking done

**Example delegation logic**:
```markdown
If task involves:
- "test" or "spec" → testing-subagent
- "refactor" or "DRY" → refactoring-subagent
- "review" or "clean" → code-review-subagent
- "document" → documentation-subagent
- "build" or "deploy" → Handle directly
```

### Step 5: Auto-Update After Each Phase

After completing a phase, automatically invoke `plan-updater`:

```markdown
After Phase X completes:

1. Check if phase tasks are complete
2. Invoke plan-updater skill
   - This will update checkboxes
   - Commit progress with semantic message
3. Confirm update applied
4. Move to next phase
```

**Automatic triggers**:
- All tasks in phase marked complete
- Acceptance criteria for phase met
- Tests pass for phase deliverables

### Step 6: Final Validation

When all phases complete:

```bash
# Verify all acceptance criteria met
ACCEPTANCE_CRITERIA=$(grep "## Acceptance Criteria" -A 20 "$PLAN_FILE" | grep "^\- \[ \]")

if [ -z "$ACCEPTANCE_CRITERIA" ]; then
  echo "All acceptance criteria met!"
  echo "Invoking final plan-updater..."
  # plan-updater skill
else
  echo "Remaining acceptance criteria:"
  echo "$ACCEPTANCE_CRITERIA"
fi
```

### Step 7: Progress Reporting

Provide status updates during execution:

```markdown
## Plan Execution Status

**Branch**: GIT-123
**PLAN**: PLANS/PLAN-GIT-123.md

### Phase Progress
- [x] Phase 1: Setup & Analysis
- [x] Phase 2: Core Implementation
- [ ] Phase 3: Testing ← Currently here
- [ ] Phase 4: Documentation & Cleanup
- [ ] Phase 5: Final Validation

### Recent Progress
- Completed Phase 2 implementation
- Updated PLAN with progress (commit: abc1234)
- Starting Phase 3 testing

### Next Steps
1. Execute Phase 3 tasks
2. Auto-invoke plan-updater after completion
3. Proceed to Phase 4
```

## PLAN File Structure

I expect PLAN files to follow this structure:

```markdown
# Plan: Ticket Title

## Ticket Reference
- Platform: GitHub/JIRA
- ID: TICKET-ID

## Acceptance Criteria
- [ ] Criterion 1
- [ ] Criterion 2
- [ ] Criterion 3

---

## Implementation Phases

### Phase 1: Setup & Analysis
- [ ] Task 1
- [ ] Task 2
- [ ] Task 3

### Phase 2: Core Implementation
- [ ] Task 1
- [ ] Task 2
- [ ] Task 3

### Phase 3: Testing
- [ ] Task 1
- [ ] Task 2
- [ ] Task 3

### Phase 4: Documentation & Cleanup
- [ ] Task 1
- [ ] Task 2
- [ ] Task 3

### Phase 5: Final Validation
- [ ] Task 1
- [ ] Task 2
- [ ] Task 3
```

## Delegation Strategy

When executing plan, delegate appropriately:

| Task Type | Delegate To | Reason |
|-----------|-------------|---------|
| Test generation | `testing-subagent` | Specialized test frameworks |
| Refactoring | `refactoring-subagent` | SOLID/clean code expertise |
| Code review | `code-review-subagent` | Comprehensive quality analysis |
| Documentation | `documentation-subagent` | Industry-standard docs |
| Build/deploy | Parent agent | Requires full bash access |
| Simple implementation | Direct handle | Straightforward changes |

**Delegation pattern**:
```markdown
1. Identify task type
2. Select appropriate subagent
3. Spawn subagent with task description
4. Wait for completion
5. Verify results
6. Mark task complete in PLAN
```

## Automatic Update Triggers

I invoke `plan-updater` automatically when:

1. **Phase completion**: All phase tasks marked complete
2. **Milestone reached**: Significant deliverable finished
3. **Before PR**: If PR workflow starts
4. **User request**: "update plan" or "sync plan"

**Update process**:
```markdown
Auto-update flow:
1. Detect phase complete
2. Invoke plan-updater skill
3. Skill updates checkboxes
4. Skill commits: docs(plan): update PLAN-GIT-123.md
5. Confirm commit applied
6. Continue execution
```

## Error Handling

### PLAN File Not Found

```bash
if [ ! -f "$PLAN_FILE" ]; then
  echo "No PLAN file found for current branch: $BRANCH_NAME"
  echo "Have you run ticket-plan-workflow-skill to create a PLAN?"
  exit 1
fi
```

### Phase Execution Fails

```bash
# If task execution fails:
1. Log error with context
2. Ask user for guidance
3. Mark task as blocked in PLAN
4. Continue with other tasks if possible
5. Provide summary for manual fix
```

### Plan-updater Fails

```bash
# If plan-updater skill fails:
1. Try manual update
2. Commit PLAN manually
3. Warn user about sync gap
4. Continue execution
```

## Best Practices

### Phase Execution Order

1. **Follow PLAN order**: Don't skip ahead
2. **Complete phase before moving**: Ensure all tasks done
3. **Verify acceptance**: Check criteria after each phase
4. **Update progress**: Auto-invoke plan-updater

### Task Completion Criteria

A task is complete when:
- Code changes committed
- Tests pass (if applicable)
- Documentation updated (if needed)
- Review done (if required)

### When to Stop

Stop execution if:
- **Blocker encountered**: Task cannot be completed
- **User intervention needed**: Requires human decision
- **Plan complete**: All phases and criteria done
- **User requests pause**: "stop plan" or "pause"

## Example Usage

### User says "Implement the plan"

```markdown
User: Implement the plan

Agent: Found PLAN: PLANS/PLAN-GIT-123.md

**Plan Status**:
- 2 of 5 phases complete
- 8 of 20 tasks complete

**Next**: Phase 3 - Testing

Starting Phase 3 execution...

[Executes testing tasks]
[Invokes plan-updater automatically]
[Commits: docs(plan): update PLAN-GIT-123.md with Phase 3 progress]

Phase 3 complete! Updated PLAN with progress.
Next: Phase 4 - Documentation & Cleanup
```

### User says "Continue with the plan"

```markdown
User: Continue with the plan

Agent: Found PLAN: PLANS/PLAN-GIT-123.md

**Current Phase**: Phase 3 - Testing
**Next Task**: - [ ] Write unit tests for new functionality

[Executes task]
[Invokes plan-updater automatically]
[Commits: docs(plan): update PLAN-GIT-123.md]

Task complete! Next task in Phase 3...
```

### User says "What's the plan status?"

```markdown
User: What's the plan status?

Agent: **PLAN Execution Status**

**Branch**: GIT-123
**PLAN**: PLANS/PLAN-GIT-123.md

### Phase Progress
- [x] Phase 1: Setup & Analysis (100%)
- [x] Phase 2: Core Implementation (100%)
- [ ] Phase 3: Testing (40%)
- [ ] Phase 4: Documentation & Cleanup (0%)
- [ ] Phase 5: Final Validation (0%)

### Acceptance Criteria
- [x] Users can register with email/password
- [x] Users can login and receive JWT token
- [ ] Protected routes validate JWT ← Pending
- [ ] 24h token expiry works ← Pending

### Last Update
- Commit: abc1234 docs(plan): update PLAN-GIT-123.md
- Time: 2024-01-25 14:30

### Next Steps
1. Complete Phase 3: Testing tasks
2. Meet remaining acceptance criteria
3. Execute Phase 4: Documentation & Cleanup
```

## Integration with Planning Workflows

This skill integrates with:

| Workflow | Integration Point |
|-----------|------------------|
| ticket-plan-workflow-skill | Executes plans created by ticket workflow |
| pr-workflow-subagent | Provides final status before PR creation |
| plan-updater | Auto-invoked for progress tracking |

## References

- `ticket-plan-workflow-skill` - Creates GitHub issue and JIRA ticket PLAN files
- `plan-updater` - Updates PLAN.md files with progress
- `git-semantic-commits` - Commit message formatting
- `testing-subagent` - Test generation and execution
- `refactoring-subagent` - Code refactoring with quality checks
