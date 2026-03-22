#!/usr/bin/env bash
set -euo pipefail

JIRA_TOKEN_FILE="${JIRA_TOKEN_FILE:-$HOME/.config/opencode/jira-tokens.json}"
JIRA_TOKEN_BUFFER_SECONDS="${JIRA_TOKEN_BUFFER_SECONDS:-300}"
JIRA_TOKEN_MAX_RETRIES="${JIRA_TOKEN_MAX_RETRIES:-3}"
JIRA_TOKEN_RETRY_DELAY="${JIRA_TOKEN_RETRY_DELAY:-2}"

_jtm_debug() {
    if [ "${JIRA_TOKEN_DEBUG:-}" = "true" ]; then
        echo "[JTM-DEBUG] $*" >&2
    fi
}

_jtm_error() {
    echo "[JTM-ERROR] $*" >&2
}

_jtm_info() {
    echo "[JTM] $*" >&2
}

_ensure_token_dir() {
    local dir
    dir=$(dirname "$JIRA_TOKEN_FILE")
    if [ ! -d "$dir" ]; then
        mkdir -p "$dir"
        chmod 700 "$dir"
    fi
}

_unix_timestamp() {
    date +%s
}

get_token_file() {
    echo "$JIRA_TOKEN_FILE"
}

init_tokens() {
    local client_id="${1:-$JIRA_CLIENT_ID}"
    local client_secret="${2:-$JIRA_CLIENT_SECRET}"
    local access_token="${3:-$JIRA_ACCESS_TOKEN}"
    local refresh_token="${4:-$JIRA_REFRESH_TOKEN}"
    local cloud_id="${5:-$JIRA_CLOUD_ID}"
    local expires_in="${6:-3600}"
    
    if [ -z "$client_id" ] || [ -z "$access_token" ]; then
        _jtm_error "Missing required parameters: client_id and access_token"
        return 1
    fi
    
    _ensure_token_dir
    
    local current_time
    current_time=$(_unix_timestamp)
    local expires_at=$((current_time + expires_in))
    
    cat > "$JIRA_TOKEN_FILE" <<EOF
{
  "client_id": "$client_id",
  "client_secret": "$client_secret",
  "access_token": "$access_token",
  "refresh_token": "$refresh_token",
  "cloud_id": "$cloud_id",
  "expires_at": $expires_at,
  "created_at": $current_time,
  "last_refreshed_at": null,
  "refresh_count": 0
}
EOF
    
    chmod 600 "$JIRA_TOKEN_FILE"
    _jtm_info "Token file initialized: $JIRA_TOKEN_FILE"
    _jtm_debug "Token expires at: $(date -d "@$expires_at" 2>/dev/null || date -r "$expires_at" 2>/dev/null || echo "$expires_at")"
}

load_tokens() {
    if [ ! -f "$JIRA_TOKEN_FILE" ]; then
        _jtm_debug "Token file not found, using environment variables"
        
        if [ -n "${JIRA_ACCESS_TOKEN:-}" ]; then
            echo "{\"access_token\": \"${JIRA_ACCESS_TOKEN}\", \"refresh_token\": \"${JIRA_REFRESH_TOKEN:-}\", \"client_id\": \"${JIRA_CLIENT_ID:-}\", \"client_secret\": \"${JIRA_CLIENT_SECRET:-}\", \"cloud_id\": \"${JIRA_CLOUD_ID:-}\", \"expires_at\": 0}"
            return 0
        fi
        return 1
    fi
    
    cat "$JIRA_TOKEN_FILE"
}

save_tokens() {
    local token_data="$1"
    
    _ensure_token_dir
    echo "$token_data" > "$JIRA_TOKEN_FILE"
    chmod 600 "$JIRA_TOKEN_FILE"
}

get_access_token() {
    local token_data
    token_data=$(load_tokens) || return 1
    echo "$token_data" | grep -o '"access_token": *"[^"]*"' | cut -d'"' -f4
}

get_refresh_token() {
    local token_data
    token_data=$(load_tokens) || return 1
    echo "$token_data" | grep -o '"refresh_token": *"[^"]*"' | cut -d'"' -f4
}

get_cloud_id() {
    local token_data
    token_data=$(load_tokens) || return 1
    echo "$token_data" | grep -o '"cloud_id": *"[^"]*"' | cut -d'"' -f4
}

get_expires_at() {
    local token_data
    token_data=$(load_tokens) || return 1
    echo "$token_data" | grep -o '"expires_at": *[0-9]*' | grep -o '[0-9]*'
}

is_token_expired() {
    local buffer="${1:-$JIRA_TOKEN_BUFFER_SECONDS}"
    local expires_at
    
    expires_at=$(get_expires_at) || return 0
    
    if [ "$expires_at" -eq 0 ]; then
        _jtm_debug "Token expiration unknown, assuming expired"
        return 0
    fi
    
    local current_time
    current_time=$(_unix_timestamp)
    local adjusted_expiry=$((expires_at - buffer))
    
    if [ "$current_time" -ge "$adjusted_expiry" ]; then
        _jtm_debug "Token expired or expiring soon (current: $current_time, adjusted_expiry: $adjusted_expiry)"
        return 0
    fi
    
    return 1
}

refresh_token() {
    local token_data client_id client_secret refresh_token
    
    token_data=$(load_tokens) || {
        _jtm_error "No token data available"
        return 1
    }
    
    client_id=$(echo "$token_data" | grep -o '"client_id": *"[^"]*"' | cut -d'"' -f4)
    client_secret=$(echo "$token_data" | grep -o '"client_secret": *"[^"]*"' | cut -d'"' -f4)
    refresh_token=$(echo "$token_data" | grep -o '"refresh_token": *"[^"]*"' | cut -d'"' -f4)
    
    if [ -z "$client_id" ] || [ -z "$refresh_token" ]; then
        _jtm_error "Missing client_id or refresh_token for refresh"
        return 1
    fi
    
    _jtm_debug "Refreshing token..."
    
    local response http_code
    response=$(curl -s -w "\n%{http_code}" -X POST "https://auth.atlassian.com/oauth/token" \
        -H "Content-Type: application/json" \
        -d "{
            \"grant_type\": \"refresh_token\",
            \"client_id\": \"${client_id}\",
            \"client_secret\": \"${client_secret:-}\",
            \"refresh_token\": \"${refresh_token}\"
        }")
    
    http_code=$(echo "$response" | tail -1)
    response=$(echo "$response" | sed '$d')
    
    if [ "$http_code" != "200" ]; then
        _jtm_error "Token refresh failed with HTTP $http_code"
        _jtm_debug "Response: $response"
        return 1
    fi
    
    local new_access_token new_refresh_token expires_in
    new_access_token=$(echo "$response" | grep -o '"access_token":"[^"]*"' | cut -d'"' -f4)
    new_refresh_token=$(echo "$response" | grep -o '"refresh_token":"[^"]*"' | cut -d'"' -f4)
    expires_in=$(echo "$response" | grep -o '"expires_in":[0-9]*' | grep -o '[0-9]*')
    
    if [ -z "$new_access_token" ]; then
        _jtm_error "No access_token in refresh response"
        return 1
    fi
    
    [ -z "$expires_in" ] && expires_in=3600
    
    local current_time cloud_id refresh_count
    current_time=$(_unix_timestamp)
    local new_expires_at=$((current_time + expires_in))
    cloud_id=$(echo "$token_data" | grep -o '"cloud_id": *"[^"]*"' | cut -d'"' -f4)
    refresh_count=$(echo "$token_data" | grep -o '"refresh_count": *[0-9]*' | grep -o '[0-9]*')
    [ -z "$refresh_count" ] && refresh_count=0
    refresh_count=$((refresh_count + 1))
    
    local updated_data
    updated_data=$(cat <<EOF
{
  "client_id": "$client_id",
  "client_secret": "$client_secret",
  "access_token": "$new_access_token",
  "refresh_token": "${new_refresh_token:-$refresh_token}",
  "cloud_id": "$cloud_id",
  "expires_at": $new_expires_at,
  "created_at": $(echo "$token_data" | grep -o '"created_at": *[0-9]*' | grep -o '[0-9]*'),
  "last_refreshed_at": $current_time,
  "refresh_count": $refresh_count
}
EOF
)
    
    save_tokens "$updated_data"
    _jtm_info "Token refreshed successfully (refresh #$refresh_count)"
    
    export JIRA_ACCESS_TOKEN="$new_access_token"
    [ -n "$new_refresh_token" ] && export JIRA_REFRESH_TOKEN="$new_refresh_token"
    
    return 0
}

ensure_valid_token() {
    local max_retries="${1:-$JIRA_TOKEN_MAX_RETRIES}"
    local retry=0
    
    while [ $retry -lt "$max_retries" ]; do
        if ! is_token_expired; then
            _jtm_debug "Token is valid"
            return 0
        fi
        
        _jtm_debug "Token expired or expiring soon, attempting refresh (attempt $((retry + 1))/$max_retries)"
        
        if refresh_token; then
            return 0
        fi
        
        retry=$((retry + 1))
        [ $retry -lt "$max_retries ] && sleep "$JIRA_TOKEN_RETRY_DELAY"
    done
    
    _jtm_error "Failed to obtain valid token after $max_retries attempts"
    return 1
}

jira_api_call() {
    local method="$1"
    local endpoint="$2"
    local data="${3:-}"
    local retry_on_401="${4:-true}"
    
    ensure_valid_token || return 1
    
    local access_token cloud_id url
    access_token=$(get_access_token)
    cloud_id=$(get_cloud_id)
    
    [ -z "$cloud_id" ] && {
        _jtm_error "JIRA_CLOUD_ID not set"
        return 1
    }
    
    url="https://api.atlassian.com/ex/jira/${cloud_id}/rest/api/3${endpoint}"
    
    _jtm_debug "API Call: $method $url"
    
    local response http_code
    if [ -n "$data" ]; then
        response=$(curl -s -w "\n%{http_code}" -X "$method" "$url" \
            -H "Authorization: Bearer $access_token" \
            -H "Content-Type: application/json" \
            -d "$data")
    else
        response=$(curl -s -w "\n%{http_code}" -X "$method" "$url" \
            -H "Authorization: Bearer $access_token" \
            -H "Content-Type: application/json")
    fi
    
    http_code=$(echo "$response" | tail -1)
    response=$(echo "$response" | sed '$d')
    
    if [ "$http_code" = "401" ] && [ "$retry_on_401" = "true" ]; then
        _jtm_debug "Got 401, forcing token refresh and retrying..."
        
        if refresh_token; then
            jira_api_call "$method" "$endpoint" "$data" "false"
            return $?
        fi
        
        _jtm_error "Token refresh failed on 401 retry"
        return 1
    fi
    
    if [ "$http_code" -ge 400 ]; then
        _jtm_error "API call failed with HTTP $http_code"
        _jtm_debug "Response: $response"
        return 1
    fi
    
    echo "$response"
}

jira_get() {
    local endpoint="$1"
    jira_api_call "GET" "$endpoint"
}

jira_post() {
    local endpoint="$1"
    local data="$2"
    jira_api_call "POST" "$endpoint" "$data"
}

jira_put() {
    local endpoint="$1"
    local data="$2"
    jira_api_call "PUT" "$endpoint" "$data"
}

jira_delete() {
    local endpoint="$1"
    jira_api_call "DELETE" "$endpoint"
}

token_status() {
    local token_data access_token expires_at current_time cloud_id
    
    if [ ! -f "$JIRA_TOKEN_FILE" ] && [ -z "${JIRA_ACCESS_TOKEN:-}" ]; then
        echo "Status: NOT_CONFIGURED"
        echo "Message: No JIRA tokens configured"
        return 1
    fi
    
    token_data=$(load_tokens) || {
        echo "Status: ERROR"
        echo "Message: Failed to load token data"
        return 1
    }
    
    access_token=$(get_access_token)
    expires_at=$(get_expires_at)
    current_time=$(_unix_timestamp)
    cloud_id=$(get_cloud_id)
    
    echo "Status: CONFIGURED"
    echo "Access Token: ${access_token:0:8}...${access_token: -4}"
    echo "Cloud ID: ${cloud_id:-<not set>}"
    echo "Expires At: $(date -d "@$expires_at" 2>/dev/null || date -r "$expires_at" 2>/dev/null || echo "$expires_at")"
    
    if [ "$expires_at" -eq 0 ]; then
        echo "Token Validity: UNKNOWN"
    elif [ "$current_time" -ge "$expires_at" ]; then
        echo "Token Validity: EXPIRED"
    elif [ "$current_time" -ge $((expires_at - JIRA_TOKEN_BUFFER_SECONDS)) ]; then
        echo "Token Validity: EXPIRING_SOON"
    else
        local remaining=$((expires_at - current_time))
        echo "Token Validity: VALID (${remaining}s remaining)"
    fi
    
    local refresh_count last_refreshed
    refresh_count=$(echo "$token_data" | grep -o '"refresh_count": *[0-9]*' | grep -o '[0-9]*')
    last_refreshed=$(echo "$token_data" | grep -o '"last_refreshed_at": *[0-9]*' | grep -o '[0-9]*')
    
    echo "Refresh Count: ${refresh_count:-0}"
    [ -n "$last_refreshed" ] && [ "$last_refreshed" != "null" ] && [ "$last_refreshed" != "0" ] && \
        echo "Last Refreshed: $(date -d "@$last_refreshed" 2>/dev/null || date -r "$last_refreshed" 2>/dev/null || echo "$last_refreshed")"
}

print_usage() {
    cat <<EOF
JIRA Token Manager - Automatic token refresh for JIRA OAuth2

Usage: $(basename "$0") <command> [options]

Commands:
  init <client_id> <client_secret> <access_token> <refresh_token> [cloud_id] [expires_in]
      Initialize token storage with OAuth2 credentials

  status
      Show current token status and validity

  refresh
      Manually refresh the access token

  ensure-valid
      Ensure a valid token exists (refresh if needed)

  get-token
      Get the current access token

  get-cloud-id
      Get the configured cloud ID

  api-get <endpoint>
      Make a GET request to JIRA API (auto-refresh if needed)

  api-post <endpoint> <json_data>
      Make a POST request to JIRA API (auto-refresh if needed)

  api-put <endpoint> <json_data>
      Make a PUT request to JIRA API (auto-refresh if needed)

  api-delete <endpoint>
      Make a DELETE request to JIRA API (auto-refresh if needed)

Environment Variables:
  JIRA_TOKEN_FILE          Token storage file (default: ~/.config/opencode/jira-tokens.json)
  JIRA_TOKEN_BUFFER_SECONDS  Refresh buffer in seconds (default: 300)
  JIRA_TOKEN_MAX_RETRIES   Max refresh retries (default: 3)
  JIRA_TOKEN_RETRY_DELAY   Delay between retries (default: 2)
  JIRA_TOKEN_DEBUG         Enable debug output (set to 'true')

Examples:
  # Initialize tokens
  $(basename "$0") init "client-id" "secret" "access-token" "refresh-token" "cloud-id" 3600

  # Check token status
  $(basename "$0") status

  # Make API call with auto-refresh
  $(basename "$0") api-get "/project"

  # Create issue with auto-refresh
  $(basename "$0") api-post "/issue" '{"fields":{"project":{"key":"PROJ"},"summary":"Test","issuetype":{"name":"Task"}}}'
EOF
}

main() {
    local command="${1:-help}"
    shift || true
    
    case "$command" in
        init)
            init_tokens "$@"
            ;;
        status)
            token_status
            ;;
        refresh)
            refresh_token
            ;;
        ensure-valid)
            ensure_valid_token
            ;;
        get-token)
            get_access_token
            ;;
        get-cloud-id)
            get_cloud_id
            ;;
        api-get)
            jira_get "$1"
            ;;
        api-post)
            jira_post "$1" "$2"
            ;;
        api-put)
            jira_put "$1" "$2"
            ;;
        api-delete)
            jira_delete "$1"
            ;;
        help|--help|-h)
            print_usage
            ;;
        *)
            _jtm_error "Unknown command: $command"
            print_usage
            exit 1
            ;;
    esac
}

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    main "$@"
fi
