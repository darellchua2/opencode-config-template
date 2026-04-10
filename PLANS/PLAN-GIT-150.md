# Plan: Add Unit Tests for Backup Cleanup Feature (setup.sh)

## Issue Reference
- **Number**: #150
- **URL**: https://github.com/darellchua2/opencode-config-template/issues/150
- **Labels**: enhancement, patch
- **Branch**: `feat/150-backup-cleanup-retention`

## Overview

Add unit tests for the `cleanup_old_backups()` function and `--keep-backups` argument parsing in `setup.sh` using the **bats** (Bash Automated Testing System) framework. No test infrastructure currently exists in this repo.

## Acceptance Criteria
- [ ] bats framework is installed and runnable locally
- [ ] Test directory `tests/` created at repo root
- [ ] Test helper sourced from setup.sh (functions + globals only, no side effects)
- [ ] All tests pass with `bats tests/`
- [ ] Tests cover: default retention, custom retention, keep=0, negative (disabled), dry-run, non-numeric arg rejection, no backups case

## Scope
- `tests/` — new directory (not deployed, stays in repo)
- `setup.sh` — may need a guard to allow sourcing without executing `main()`
- No changes to `setup.ps1` tests (PowerShell testing is out of scope)

---

## Implementation Phases

### Phase 1: Test Infrastructure
- [ ] Install bats via git submodule or local clone (`tests/lib/bats-core`)
- [ ] Create `tests/test_helper/common.bash` — helper that sources `setup.sh` functions without triggering `main()` execution
- [ ] Add a `main()` guard in `setup.sh` (wrap the bottom-level `main "$@"` call in `if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then ... fi`) so the script can be safely sourced by tests
- [ ] Verify `source setup.sh` doesn't execute anything destructive

### Phase 2: Test `parse_arguments()` — `--keep-backups` flag
- [ ] Create `tests/parse_arguments.bats`
- [ ] Test: `--keep-backups 3` sets `KEEP_BACKUPS=3`
- [ ] Test: `-k 10` sets `KEEP_BACKUPS=10`
- [ ] Test: `--keep-backups 0` sets `KEEP_BACKUPS=0`
- [ ] Test: `--keep-backups -1` sets `KEEP_BACKUPS=-1`
- [ ] Test: `--keep-backups abc` exits with error (non-numeric rejected)
- [ ] Test: `--keep-backups` with no arg exits with error
- [ ] Test: default value is 5 when flag not provided

### Phase 3: Test `cleanup_old_backups()` — core logic
- [ ] Create `tests/cleanup_old_backups.bats`
- [ ] Test: no backups exist → exits cleanly, no deletion
- [ ] Test: 3 backups, keep=5 → none deleted
- [ ] Test: 7 backups, keep=5 → 2 oldest deleted
- [ ] Test: 3 backups, keep=0 → all deleted
- [ ] Test: 3 backups, keep=-1 → none deleted (disabled)
- [ ] Test: mixed `.opencode-backup-*` and `.opencode-update-backup-*` patterns both cleaned
- [ ] Test: newest backups are kept, oldest removed
- [ ] Test: `DRY_RUN=true` → prints `[DRY-RUN]` but does not delete directories

### Phase 4: Test helper utilities
- [ ] Create `tests/test_helper/setup_teardown.bash` — `setup()` creates temp `$HOME` with fake backup dirs, `teardown()` cleans up
- [ ] Each test uses isolated temp dirs — no risk to real system

### Phase 5: Validation & Documentation
- [ ] Run `bats tests/` — all tests pass
- [ ] Verify `bash -n setup.sh` still passes after main guard addition
- [ ] Update README.md if a "Running Tests" section is warranted (optional)

---

## Technical Notes

### Sourcing setup.sh for testing
The script currently calls `main "$@"` at the bottom unconditionally. We need to guard it:
```bash
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
```
This allows `source setup.sh` from test files without executing `main()`.

### Test isolation
- Each test gets a fresh temp directory via `mktemp -d`
- `$HOME` is overridden in tests to point to temp dir
- Backup dirs are created as `.opencode-backup-YYYYMMDD_HHMMSS` and `.opencode-update-backup-YYYYMMDD_HHMMSS` inside the temp `$HOME`
- `teardown()` removes the temp dir

### bats installation
- Install bats-core as a git submodule under `tests/lib/bats-core/` OR install system-wide via `sudo apt install bats`
- Git submodule approach is preferred for reproducibility (no system dependency)
- bats executable: `tests/lib/bats-core/bin/bats` or system `bats`

### Functions under test
- `cleanup_old_backups()` — lines 768-809 of `setup.sh`
- `parse_arguments()` — lines 631-700 of `setup.sh`
- Both depend on globals: `KEEP_BACKUPS`, `DRY_RUN`, `HOME`, `VERBOSE`

## Dependencies
- bats-core (Bash Automated Testing System) — https://github.com/bats-core/bats-core

## Risks & Mitigation
| Risk | Likelihood | Mitigation |
|------|------------|------------|
| Sourcing setup.sh triggers side effects | Medium | Add `BASH_SOURCE` guard before Phase 2 |
| Temp dirs leak if test crashes | Low | `teardown()` with `rm -rf` runs even on failure |
| log functions write to real filesystem | Low | Override `LOG_FILE` to temp dir in test setup |
| ERR trap fires during tests | Medium | `set +e` in test helper or disable trap when sourcing |
| bats not available on all systems | Medium | Use git submodule for self-contained install |
