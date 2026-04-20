#!/bin/bash
set -e

PORT="${OPENCODE_SERVER_PORT:-4096}"
HOST="${OPENCODE_SERVER_HOST:-0.0.0.0}"

AUTH_DIR="/home/opencode/.local/share/opencode"
AUTH_FILE="${AUTH_DIR}/auth.json"
mkdir -p "${AUTH_DIR}"

# Build auth.json with all available API keys
python3 << 'PYEOF'
import json
import os

auth = {}

zai_key = os.environ.get("ZAI_API_KEY", "").strip()
if zai_key:
    auth["zai"] = {"type": "api", "key": zai_key}

gemini_key = os.environ.get("GEMINI_API_KEY", "").strip()
if gemini_key:
    auth["gemini"] = {"type": "api", "key": gemini_key}

auth_file = os.environ.get("AUTH_FILE", "")

if auth:
    with open(auth_file, "w") as f:
        json.dump(auth, f, indent=2)
    print(f"Injected {len(auth)} API key(s) into {auth_file}: {', '.join(auth.keys())}")
else:
    print("WARNING: No API keys provided (ZAI_API_KEY, GEMINI_API_KEY)")
    print("OpenCode will start but LLM calls will fail without authentication")
PYEOF
export AUTH_FILE

echo "Starting OpenCode server on ${HOST}:${PORT}..."
exec opencode serve --port "${PORT}" --hostname "${HOST}"
