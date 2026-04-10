#!/usr/bin/env bash

BATS_TEST_DIRNAME="$(cd "$(dirname "${BASH_SOURCE[1]}")" && pwd)"
PROJECT_ROOT="$(cd "${BATS_TEST_DIRNAME}/.." && pwd)"
SETUP_SH="${PROJECT_ROOT}/setup.sh"

source_setup_sh() {
    TEST_HOME="$(mktemp -d)"
    TEST_LOG="${TEST_HOME}/.opencode-setup.log"

    HOME="$TEST_HOME"
    LOG_FILE="$TEST_LOG"
    BACKUP_DIR="${TEST_HOME}/.opencode-backup-$(date +%Y%m%d_%H%M%S)"

    (
        set +e
        unset BASH_SOURCE
        source "$SETUP_SH"
    )
}

create_backup_dirs() {
    local count="$1"
    local prefix="${2:-.opencode-backup-}"
    local base_ts="20250101_010"

    for i in $(seq 1 "$count"); do
        local ts="${base_ts}$(printf '%02d' "$i")"
        mkdir -p "${TEST_HOME}/${prefix}${ts}"
        echo "file$i" > "${TEST_HOME}/${prefix}${ts}/test.txt"
    done
}

count_backup_dirs() {
    local prefix="${1:-.opencode-backup-}"
    find "${TEST_HOME}" -maxdepth 1 -type d -name "${prefix}*" 2>/dev/null | wc -l
}

count_all_backup_dirs() {
    local regular
    regular=$(find "${TEST_HOME}" -maxdepth 1 -type d -name ".opencode-backup-*" 2>/dev/null | wc -l)
    local update
    update=$(find "${TEST_HOME}" -maxdepth 1 -type d -name ".opencode-update-backup-*" 2>/dev/null | wc -l)
    echo $((regular + update))
}
