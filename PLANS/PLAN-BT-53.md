# PLAN-BT-53: Add Strict Input Validation to y/n Prompts

**Issue**: [BT-53](https://betekk.atlassian.net/browse/BT-53)
**Branch**: `BT-53`
**Type**: bug / UX improvement
**Priority**: medium

## Overview

Both `setup.sh` and `setup.ps1` have `prompt_yes_no` / `Read-YesNo` functions that accept any user input without validation. Typing "maybe", "sure", "ok", or any other string silently falls through as "no". These functions should loop until the user enters a valid character (`y`, `Y`, `n`, `N`, or empty for default).

## Current Behavior

**setup.sh** `prompt_yes_no()` (line 765):
- Accepts any input; only `Y`/`y` returns true, everything else returns false
- No re-prompt on invalid input

**setup.ps1** `Read-YesNo` (line 169):
- Same issue: accepts any string, no loop on invalid input

## Scope

### Files to Modify

| # | File | Change |
|---|------|--------|
| 1 | `setup.sh` | Add `while` loop + regex validation to `prompt_yes_no()` (line 765) |
| 2 | `setup.ps1` | Add `while` loop + regex validation to `Read-YesNo` (line 169) |

### Files NOT Modified

- All other files — the fix is scoped to the two prompt utility functions only
- Existing callers remain unchanged (function signatures and return values stay the same)

## Phases

### Phase 1: Fix `prompt_yes_no()` in setup.sh
- [x] Wrap the `read` + default logic in a `while true` loop
- [x] Validate input against `^[YyNn]$` before breaking
- [x] Print "Invalid input. Please enter y or n." on bad input
- [x] Preserve `AUTO_ACCEPT` bypass behavior
- [x] Preserve return value semantics (`[[ "$result" =~ ^[Yy]$ ]]`)

### Phase 2: Fix `Read-YesNo` in setup.ps1
- [x] Wrap the `Read-Host` + default logic in a `while ($true)` loop
- [x] Validate input against `^[YyNn]$` before returning
- [x] Print "Invalid input. Please enter y or n." on bad input
- [x] Preserve `$Yes` auto-accept bypass behavior
- [x] Preserve return value semantics (`$response -match "^[Yy]"`)

### Phase 3: Manual Verification
- [x] Run `setup.sh` and test entering invalid input at a y/n prompt (e.g., "maybe", "x", "yes")
- [x] Run `setup.ps1` and test entering invalid input at a y/n prompt
- [x] Verify `--yes` / `-Yes` flag still auto-accepts without prompting
- [x] Verify empty input still falls back to default
- [x] Verify `y`/`Y` returns true and `n`/`N` returns false

## Acceptance Criteria

- [x] `prompt_yes_no()` loops until valid input is received (y/Y/n/N/empty)
- [x] `Read-YesNo` loops until valid input is received (y/Y/n/N/empty)
- [x] Invalid input shows "Invalid input. Please enter y or n."
- [x] `--yes` / `-Yes` auto-accept flag bypasses validation
- [x] Empty input uses the default value
- [x] All existing callers work unchanged
