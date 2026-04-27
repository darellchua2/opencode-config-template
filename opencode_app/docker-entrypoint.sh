#!/bin/bash
set -e

PORT="${OPENCODE_SERVER_PORT:-4096}"
HOST="${OPENCODE_SERVER_HOST:-0.0.0.0}"

AUTH_DIR="/home/opencode/.local/share/opencode"
AUTH_FILE="${AUTH_DIR}/auth.json"
mkdir -p "${AUTH_DIR}"

python3 << PYEOF
import json, os

auth = {}

zai_key = os.environ.get("ZAI_API_KEY", "").strip()
if zai_key:
    auth["zai"] = {"type": "api", "key": zai_key}

gemini_key = os.environ.get("GEMINI_API_KEY", "").strip()
if gemini_key:
    auth["gemini"] = {"type": "api", "key": gemini_key}

auth_file = "${AUTH_FILE}"

if auth:
    with open(auth_file, "w") as f:
        json.dump(auth, f, indent=2)
    keys = ", ".join(auth.keys())
    print("Injected " + str(len(auth)) + " API key(s) into " + auth_file + ": " + keys)
else:
    print("WARNING: No API keys provided (ZAI_API_KEY, GEMINI_API_KEY)")
    print("OpenCode will start but LLM calls will fail without authentication")
PYEOF

# ── SSH key setup ───────────────────────────────────────────────────────────
if [ -d /tmp/ssh-host ] && [ "$(ls -A /tmp/ssh-host 2>/dev/null)" ]; then
    mkdir -p ~/.ssh
    chmod 700 ~/.ssh
    cp -r /tmp/ssh-host/* ~/.ssh/ 2>/dev/null || true
    chmod 600 ~/.ssh/id_* 2>/dev/null || true
    chmod 600 ~/.ssh/config 2>/dev/null || true
    chmod 644 ~/.ssh/*.pub 2>/dev/null || true
    touch ~/.ssh/known_hosts
    chmod 644 ~/.ssh/known_hosts
    echo "SSH keys copied from host with correct permissions"
else
    mkdir -p ~/.ssh
    chmod 700 ~/.ssh
    touch ~/.ssh/known_hosts
    echo "No SSH keys found at /tmp/ssh-host — skipping SSH setup"
fi

# Add github.com to known_hosts (prevents first-connect prompt)
if ! grep -q "github.com" ~/.ssh/known_hosts 2>/dev/null; then
    ssh-keyscan -t ed25519,rsa github.com >> ~/.ssh/known_hosts 2>/dev/null || true
    echo "Added github.com to known_hosts"
fi

# ── Git identity ────────────────────────────────────────────────────────────
GIT_USER_NAME="${GIT_USER_NAME:-}"
GIT_USER_EMAIL="${GIT_USER_EMAIL:-}"

if [ -n "${GIT_USER_NAME}" ]; then
    git config --global user.name "${GIT_USER_NAME}"
    echo "Set git user.name: ${GIT_USER_NAME}"
fi
if [ -n "${GIT_USER_EMAIL}" ]; then
    git config --global user.email "${GIT_USER_EMAIL}"
    echo "Set git user.email: ${GIT_USER_EMAIL}"
fi

# ── Workspace ───────────────────────────────────────────────────────────────
mkdir -p /workspace
mkdir -p /workspace-extra 2>/dev/null || true

echo "Starting OpenCode server on ${HOST}:${PORT}..."
exec opencode serve --port "${PORT}" --hostname "${HOST}"
