# PLAN-GIT-201: Update ticket-creation-subagent with prompt-first workflow and architecture review

**Issue**: [#201](https://github.com/darellchua2/opencode-config-template/issues/201)
**Branch**: `issue-201`
**Status**: In Progress

---

## Problem

The `ticket-creation-subagent` executes steps without user confirmation, includes plan execution in its workflow (outside its responsibility), and offers no architectural review of generated plans.

## Solution

Refactor the subagent to adopt a prompt-first behavior pattern, remove plan execution, add an architecture review step, and include a standardized return contract.

---

## Phase 1: Prompt-First Behavior

- [x] Add `CRITICAL: Prompt-First Behavior` section with 5 mandatory confirmation rules
- [x] Add prompt-first pattern example
- [x] Document "never assume — always confirm" rule

## Phase 2: Remove Plan Execution

- [x] Remove plan execution from workflow steps
- [x] Add explicit note: "This subagent does NOT execute the plan"
- [x] Update workflow to stop at plan creation + architecture review offer

## Phase 3: Architecture Review Step

- [x] Add architecture review prompt after PLAN push (Step 12)
- [x] Add `task` permission: `architecture-review-subagent: allow`, `explore: allow` (deny all others)
- [x] Define Task tool invocation template for architecture-review-subagent
- [x] Include architecture review status in return output

## Phase 4: Return Contract & Cleanup

- [x] Add standardized return contract section (Status/Output/Summary/Issues)
- [x] Add "do NOT return" list to prevent context bloat
- [x] Increase step budget from 20 to 25
- [x] Update examples to show prompt-first interaction pattern

---

## Acceptance Criteria

- [ ] Prompt-first confirmation added before ticket creation, after gathering info, at decision points, and after PLAN generation
- [ ] Plan execution removed from workflow — subagent stops after creating the plan
- [ ] Architecture review step added — asks user if they want architecture-review-subagent to review the plan
- [ ] `task` permission updated: architecture-review-subagent allow, explore allow (deny all others)
- [ ] Standardized return contract format added
- [ ] Step budget increased from 20 to 25

## Scope

- `opencode_app/.opencode/agents/ticket-creation-subagent.md`

## Risks & Mitigation

- **Risk**: Subagent may be too chatty with constant prompts → Mitigated by keeping confirmations brief (single yes/no)
- **Risk**: Architecture review adds latency → Mitigated by making it optional (user can skip)
