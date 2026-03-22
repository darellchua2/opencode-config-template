#!/usr/bin/env bash
JIRA_TOKEN_MANAGER_SCRIPT="${JIRA_TOKEN_MANAGER_SCRIPT:-$(dirname "$0")/../scripts/jira-token-manager.sh}"
JIRA_TOKEN_FILE="${JIRA_TOKEN_FILE:-$HOME/.config/opencode/jira-tokens.json}"
JIRA_TOKEN_BUFFER_SECONDS="${JIRA_TOKEN_BUFFER_SECONDS:-300}"
JIRA_TOKEN_MAX_RETRIES="${JIRA_TOKEN_MAX_RETRIES:-3}"
JIRA_TOKEN_RETRY_DELAY="${JIRA_TOKEN_RETRY_DELAY:-2}"

source "$JIRA_TOKEN_MANAGER_SCRIPT" 2>/dev/null || return 1
fi

JIRA_TOKEN_MANAGER_SCRIPT="$(realpath "$0")/../scripts/jira-token-manager.sh"

jira_api_call() {
    local method="$1"
    local endpoint="$2"
    local data="${3:-}"
    jira_api_call "$method" "$endpoint" "$data"
}
jira_get() {
    local endpoint="$1"
    jira_api_call GET "$endpoint"
}
jira_post() {
    local endpoint="$1"
    local data="$2"
    jira_api_call POST "$endpoint" "$data"
}
jira_put() {
    local endpoint="$1"
    local data="$2"
    jira_api_call PUT "$endpoint" "$data"
}
jira_delete() {
    local endpoint="$1"
    jira_api_call DELETE "$endpoint"
}
jira_token_status() {
    "$JIRA_TOKEN_MANAGER_SCRIPT" status
2>/dev/null
    echo "$status"
}
