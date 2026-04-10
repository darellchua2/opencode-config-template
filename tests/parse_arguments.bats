#!/usr/bin/env bats

PROJECT_ROOT="$(cd "${BATS_TEST_DIRNAME}/.." && pwd)"
SETUP_SH="${PROJECT_ROOT}/setup.sh"

setup() {
    TEST_HOME="$(mktemp -d)"
    TEST_LOG="${TEST_HOME}/.opencode-setup.log"
    export HOME="$TEST_HOME"
    export LOG_FILE="$TEST_LOG"
    export BACKUP_DIR="${TEST_HOME}/.opencode-backup-$(date +%Y%m%d_%H%M%S)"
    export DRY_RUN=false
    export VERBOSE=true

    source "$SETUP_SH"

    KEEP_BACKUPS=5
}

teardown() {
    rm -rf "$TEST_HOME"
}

@test "default KEEP_BACKUPS is 5" {
    [ "$KEEP_BACKUPS" -eq 5 ]
}

@test "--keep-backups 3 sets KEEP_BACKUPS to 3" {
    parse_arguments --keep-backups 3
    [ "$KEEP_BACKUPS" -eq 3 ]
}

@test "-k 10 sets KEEP_BACKUPS to 10" {
    parse_arguments -k 10
    [ "$KEEP_BACKUPS" -eq 10 ]
}

@test "--keep-backups 0 sets KEEP_BACKUPS to 0" {
    parse_arguments --keep-backups 0
    [ "$KEEP_BACKUPS" -eq 0 ]
}

@test "--keep-backups -1 sets KEEP_BACKUPS to -1" {
    KEEP_BACKUPS=-1
    [ "$KEEP_BACKUPS" -eq -1 ]
}

@test "--keep-backups with negative value directly assigned works" {
    KEEP_BACKUPS=-1
    run cleanup_old_backups
    [ "$status" -eq 0 ]
}

@test "--keep-backups abc exits with error" {
    run parse_arguments --keep-backups abc
    [ "$status" -ne 0 ]
}

@test "--keep-backups with no argument exits with error" {
    run parse_arguments --keep-backups
    [ "$status" -ne 0 ]
}

@test "--keep-backups 1.5 exits with error (non-integer)" {
    run parse_arguments --keep-backups 1.5
    [ "$status" -ne 0 ]
}

@test "--dry-run flag sets DRY_RUN=true" {
    parse_arguments --dry-run
    [ "$DRY_RUN" = true ]
}

@test "--verbose flag sets VERBOSE=true" {
    VERBOSE=false
    parse_arguments --verbose
    [ "$VERBOSE" = true ]
}

@test "unknown option exits with error" {
    run parse_arguments --nonexistent
    [ "$status" -ne 0 ]
}
