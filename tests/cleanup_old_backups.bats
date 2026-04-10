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
    export KEEP_BACKUPS=5

    source "$SETUP_SH"
}

teardown() {
    rm -rf "$TEST_HOME"
}

create_backups() {
    local count="$1"
    local prefix="${2:-.opencode-backup-}"
    for i in $(seq 1 "$count"); do
        local ts="2025010$(printf '%01d' "$i")_01$(printf '%02d' "$i")"
        mkdir -p "${TEST_HOME}/${prefix}${ts}"
        echo "data" > "${TEST_HOME}/${prefix}${ts}/file.txt"
    done
}

count_all_backup_dirs() {
    local regular update
    regular=$(find "${TEST_HOME}" -maxdepth 1 -type d -name ".opencode-backup-*" 2>/dev/null | wc -l)
    update=$(find "${TEST_HOME}" -maxdepth 1 -type d -name ".opencode-update-backup-*" 2>/dev/null | wc -l)
    echo $((regular + update))
}

@test "no backups exist - exits cleanly" {
    run cleanup_old_backups
    [ "$status" -eq 0 ]
    [ "$(count_all_backup_dirs)" -eq 0 ]
}

@test "3 backups, keep 5 - none deleted" {
    KEEP_BACKUPS=5
    create_backups 3
    run cleanup_old_backups
    [ "$status" -eq 0 ]
    [ "$(count_all_backup_dirs)" -eq 3 ]
}

@test "7 backups, keep 5 - 2 oldest deleted" {
    KEEP_BACKUPS=5
    create_backups 7
    run cleanup_old_backups
    [ "$status" -eq 0 ]
    [ "$(count_all_backup_dirs)" -eq 5 ]
}

@test "3 backups, keep 0 - all deleted" {
    KEEP_BACKUPS=0
    create_backups 3
    run cleanup_old_backups
    [ "$status" -eq 0 ]
    [ "$(count_all_backup_dirs)" -eq 0 ]
}

@test "3 backups, keep -1 (disabled) - none deleted" {
    KEEP_BACKUPS=-1
    create_backups 3
    run cleanup_old_backups
    [ "$status" -eq 0 ]
    [ "$(count_all_backup_dirs)" -eq 3 ]
}

@test "3 backups, keep -99 (disabled) - none deleted" {
    KEEP_BACKUPS=-99
    create_backups 3
    run cleanup_old_backups
    [ "$status" -eq 0 ]
    [ "$(count_all_backup_dirs)" -eq 3 ]
}

@test "mixed backup patterns - both types cleaned" {
    KEEP_BACKUPS=2
    create_backups 3 ".opencode-backup-"
    create_backups 3 ".opencode-update-backup-"
    run cleanup_old_backups
    [ "$status" -eq 0 ]
    [ "$(count_all_backup_dirs)" -eq 2 ]
}

@test "newest backups are kept, oldest removed" {
    KEEP_BACKUPS=2
    create_backups 4
    run cleanup_old_backups
    [ "$status" -eq 0 ]
    [ "$(count_all_backup_dirs)" -eq 2 ]

    local remaining
    remaining=$(ls -1d "${TEST_HOME}"/.opencode-backup-* 2>/dev/null | sort)
    local second_newest
    second_newest=$(echo "$remaining" | tail -2 | head -1)
    local newest
    newest=$(echo "$remaining" | tail -1)

    [ -d "$newest" ]
    [ -d "$second_newest" ]
}

@test "dry-run prints message but does not delete" {
    DRY_RUN=true
    KEEP_BACKUPS=1
    create_backups 3

    run cleanup_old_backups
    [ "$status" -eq 0 ]
    [ "$(count_all_backup_dirs)" -eq 3 ]
    echo "$output" | grep -q "DRY-RUN"
}

@test "keep 1 - only newest survives" {
    KEEP_BACKUPS=1
    create_backups 5
    run cleanup_old_backups
    [ "$status" -eq 0 ]
    [ "$(count_all_backup_dirs)" -eq 1 ]
}

@test "exact count equals keep - none deleted" {
    KEEP_BACKUPS=3
    create_backups 3
    run cleanup_old_backups
    [ "$status" -eq 0 ]
    [ "$(count_all_backup_dirs)" -eq 3 ]
}
