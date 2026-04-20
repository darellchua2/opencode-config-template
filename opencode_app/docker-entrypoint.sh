#!/bin/bash
set -e

PORT="${OPENCODE_SERVER_PORT:-4096}"
HOST="${OPENCODE_SERVER_HOST:-0.0.0.0}"

AUTH_DIR="/home/opencode/.local/share/opencode"
AUTH_FILE="${AUTH_DIR}/auth.json"
mkdir -p "${AUTH_DIR}"

if [ -n "${ZAI_API_KEY}" ]; then
    cat > "${AUTH_FILE}" <<AUTHJSON
{
  "zai": {
    "type": "api",
    "key": "${ZAI_API_KEY}"
  }
}
AUTHJSON
    echo "Injected ZAI API key into ${AUTH_FILE}"
fi

if [ -n "${GEMINI_API_KEY}" ]; then
    if [ -f "${AUTH_FILE}" ]; then
        python3 -c "
import json, sys
with open('${AUTH_FILE}', 'r') as f:
    data = json.load(f)
data['gemini'] = {'type': 'api', 'key': '${GEMINI_API_KEY}'}
with open('${AUTH_FILE}', 'w') as f:
    json.dump(data, f, indent=2)
"
    else
        cat > "${AUTH_FILE}" <<AUTHJSON
{
  "gemini": {
    "type": "api",
    "key": "${GEMINI_API_KEY}"
  }
}
AUTHJSON
    fi
    echo "Injected Gemini API key into ${AUTH_FILE}"
fi

echo "Starting OpenCode server on ${HOST}:${PORT}..."
exec opencode serve --port "${PORT}" --hostname "${HOST}"
