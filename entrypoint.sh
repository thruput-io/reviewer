#!/usr/bin/env bash
set -e

# ==============================================================================
# Azure DevOps PR Reviewer Container Entrypoint
# ==============================================================================

# 1. User & Directory Setup
export USER="${USER:-$(whoami)}"
export HOME="${HOME:-/home/agyuser}"
export WORKSPACE_DIR="${WORKSPACE_DIR:-/workspace}"

CONFIG_DIR="${HOME}/.gemini/config"
CLI_SETTINGS_DIR="${HOME}/.gemini/antigravity-cli"
mkdir -p "${CONFIG_DIR}" "${CLI_SETTINGS_DIR}"

# 2. Harmonize Environment Variables
if [ -z "${GEMINI_API_KEY:-}" ] && [ -n "${GOOGLE_API_KEY:-}" ]; then
    export GEMINI_API_KEY="${GOOGLE_API_KEY}"
fi

ADO_TOKEN="${AZURE_DEVOPS_PAT:-${ADO_MCP_AUTH_TOKEN:-${SYSTEM_ACCESSTOKEN:-}}}"
if [ -n "$ADO_TOKEN" ]; then
    export AZURE_DEVOPS_PAT="$ADO_TOKEN"
fi

# 3. Configure Git Environment
git config --global --add safe.directory "*" || true

# 4. Generate Antigravity CLI Settings (settings.json)
python3 - <<EOF
import json
import os

settings_path = os.path.expanduser("${CLI_SETTINGS_DIR}/settings.json")
settings = {
    "modelProvider": "gemini"
}
with open(settings_path, 'w') as f:
    json.dump(settings, f, indent=2)
EOF

# 5. Ensure Skills and Rules are available to agy
mkdir -p "${CONFIG_DIR}/rules" "${CONFIG_DIR}/skills" "${HOME}/.gemini/skills" "${WORKSPACE_DIR}/.agents/skills"

if [ -d "${HOME}/.agents/skills" ]; then
    cp -ru "${HOME}/.agents/skills/"* "${CONFIG_DIR}/skills/" 2>/dev/null || true
    cp -ru "${HOME}/.agents/skills/"* "${HOME}/.gemini/skills/" 2>/dev/null || true
    cp -ru "${HOME}/.agents/skills/"* "${WORKSPACE_DIR}/.agents/skills/" 2>/dev/null || true
fi

if [ -d "/etc/antigravity/rules" ]; then
    cp -u /etc/antigravity/rules/* "${CONFIG_DIR}/rules/" 2>/dev/null || true
fi

if [ -d "/etc/antigravity/skills" ]; then
    cp -ru /etc/antigravity/skills/* "${CONFIG_DIR}/skills/" 2>/dev/null || true
fi

# 6. Print Status Banner if Interactive
if [ -t 1 ]; then
    echo "============================================================"
    echo " 🚀 Azure DevOps PR Reviewer Ready"
    echo "============================================================"
    echo " Usage: review-pr <PR_URL> [options]"
    echo "============================================================"
fi

# 7. Execute Command
# Default to review-pr if no command given, or if flags/URL passed directly
if [ "$#" -eq 0 ]; then
    set -- review-pr
elif [ "$1" != "review-pr" ]; then
    case "$1" in
        -*|http://*|https://*)
            set -- review-pr "$@"
            ;;
    esac
fi

exec "$@"
