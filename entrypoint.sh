#!/usr/bin/env bash
set -e

# ==============================================================================
# Antigravity (agy) Container Entrypoint
# Dynamically configures Git, Azure DevOps MCP, and Antigravity CLI via Env Vars
# ==============================================================================

# 1. User & Directory Setup
export USER="${USER:-$(whoami)}"
export HOME="${HOME:-/home/agyuser}"
export WORKSPACE_DIR="${WORKSPACE_DIR:-/workspace}"
export GIT_REPO_PATH="${GIT_REPO_PATH:-$WORKSPACE_DIR}"

CONFIG_DIR="${HOME}/.gemini/config"
CLI_SETTINGS_DIR="${HOME}/.gemini/antigravity-cli"
mkdir -p "${CONFIG_DIR}" "${CLI_SETTINGS_DIR}"

# 2. Harmonize Environment Variables
# API Key
if [ -z "${GEMINI_API_KEY:-}" ] && [ -n "${GOOGLE_API_KEY:-}" ]; then
    export GEMINI_API_KEY="${GOOGLE_API_KEY}"
fi

# Azure DevOps Org
ADO_ORG_RAW="${AZURE_DEVOPS_ORG:-${AZURE_DEVOPS_ORG_URL:-${ADO_ORG:-}}}"
# Extract clean organization name if a full URL was provided
# e.g., "https://dev.azure.com/myorg/" -> "myorg" or "https://myorg.visualstudio.com/" -> "myorg"
ADO_ORG_CLEAN=""
if [ -n "$ADO_ORG_RAW" ]; then
    ADO_ORG_CLEAN=$(echo "$ADO_ORG_RAW" | sed -E 's#https?://dev\.azure\.com/([^/]+)/?.*#\1#' | sed -E 's#https?://([^.]+)\.visualstudio\.com/?.*#\1#' | sed -E 's#^/+|/+$##g')
fi

# Azure DevOps PAT / Auth Token
ADO_TOKEN="${ADO_MCP_AUTH_TOKEN:-${AZURE_DEVOPS_PAT:-${AZURE_PERSONAL_ACCESS_TOKEN:-${SYSTEM_ACCESSTOKEN:-}}}}"
if [ -n "$ADO_TOKEN" ]; then
    export ADO_MCP_AUTH_TOKEN="$ADO_TOKEN"
    export AZURE_DEVOPS_EXT_PAT="$ADO_TOKEN"
fi

# Azure DevOps Project
ADO_PROJECT="${AZURE_DEVOPS_PROJECT:-${ADO_PROJECT:-${ado_mcp_project:-}}}"
if [ -n "$ADO_PROJECT" ]; then
    export ado_mcp_project="$ADO_PROJECT"
fi

# Azure DevOps Team
ADO_TEAM="${AZURE_DEVOPS_TEAM:-${ADO_TEAM:-${ado_mcp_team:-}}}"
if [ -n "$ADO_TEAM" ]; then
    export ado_mcp_team="$ADO_TEAM"
fi

# Azure DevOps Auth Method (default: envvar)
ADO_AUTH_METHOD="${AZURE_DEVOPS_AUTH_METHOD:-${ADO_AUTH_METHOD:-envvar}}"

# Azure DevOps MCP Domains (default: core,repositories,work-items,work,pipelines)
ADO_DOMAINS="${AZURE_DEVOPS_DOMAINS:-${ADO_DOMAINS:-core,repositories,work-items,work,pipelines}}"

# 3. Configure Git Environment
git config --global --add safe.directory "*" || true
git config --global user.name "${GIT_USER_NAME:-Antigravity Agent}" || true
git config --global user.email "${GIT_USER_EMAIL:-antigravity@example.com}" || true
git config --global init.defaultBranch "${GIT_DEFAULT_BRANCH:-main}" || true

# 4. Generate Antigravity CLI Settings (settings.json)
python3 - <<EOF
import json
import os

settings_path = os.path.expanduser("${CLI_SETTINGS_DIR}/settings.json")
existing_settings = {}
if os.path.exists(settings_path):
    try:
        with open(settings_path, 'r') as f:
            existing_settings = json.load(f)
    except Exception:
        existing_settings = {}

settings = {
    "modelProvider": "gemini",
    **existing_settings
}

model_override = os.environ.get("AGY_MODEL") or os.environ.get("MODEL")
if model_override:
    settings["model"] = model_override

with open(settings_path, 'w') as f:
    json.dump(settings, f, indent=2)
EOF

# 5. Generate MCP Servers Configuration (mcp_config.json)
python3 - <<EOF
import json
import os

config_path = os.path.expanduser("${CONFIG_DIR}/mcp_config.json")
org = "${ADO_ORG_CLEAN}"
auth_method = "${ADO_AUTH_METHOD}"
domains_str = "${ADO_DOMAINS}"
ado_token = "${ADO_MCP_AUTH_TOKEN:-}"
ado_project = "${ADO_PROJECT:-}"
ado_team = "${ADO_TEAM:-}"
repo_path = "${GIT_REPO_PATH}"

mcp_servers = {}

# 1. Configure Azure DevOps MCP Server if organization is specified
if org:
    args = [org, "--authentication", auth_method]
    if domains_str:
        domains = [d.strip() for d in domains_str.split(",") if d.strip()]
        if domains:
            args.append("-d")
            args.extend(domains)
            
    server_env = {}
    if ado_token:
        server_env["ADO_MCP_AUTH_TOKEN"] = ado_token
    if ado_project:
        server_env["ado_mcp_project"] = ado_project
    if ado_team:
        server_env["ado_mcp_team"] = ado_team
    if os.environ.get("LOG_LEVEL"):
        server_env["LOG_LEVEL"] = os.environ.get("LOG_LEVEL")

    mcp_servers["azure-devops"] = {
        "command": "mcp-server-azuredevops",
        "args": args,
        "env": server_env
    }

# 2. Configure Git MCP Server
# Points to local git repository directory
mcp_servers["git"] = {
    "command": "mcp-server-git",
    "args": ["--repository", repo_path]
}

config_data = {
    "mcpServers": mcp_servers
}

with open(config_path, 'w') as f:
    json.dump(config_data, f, indent=2)
EOF

# 6. Copy Rules if available and not present in workspace
if [ -d "/etc/antigravity/rules" ]; then
    mkdir -p "${CONFIG_DIR}/rules"
    cp -u /etc/antigravity/rules/* "${CONFIG_DIR}/rules/" 2>/dev/null || true
fi

# 7. Print Status Banner if Interactive or Informational
if [ -t 1 ] || [ "${AGY_VERBOSE:-}" = "true" ] || [ "${AGY_VERBOSE:-}" = "1" ]; then
    echo "============================================================"
    echo " 🚀 Antigravity CLI (agy) Container Ready"
    echo "============================================================"
    echo " Workspace:   ${WORKSPACE_DIR}"
    echo " Git Repo:    ${GIT_REPO_PATH}"
    if [ -n "$ADO_ORG_CLEAN" ]; then
        echo " Azure Org:   ${ADO_ORG_CLEAN} (Auth: ${ADO_AUTH_METHOD})"
        if [ -n "$ADO_PROJECT" ]; then
            echo " Default Proj:${ADO_PROJECT}"
        fi
    else
        echo " Azure Org:   [Not configured - set AZURE_DEVOPS_ORG to activate]"
    fi
    echo " MCP Config:  ${CONFIG_DIR}/mcp_config.json"
    echo "============================================================"
fi

# 8. Execute Command
exec "$@"
