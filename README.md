# Antigravity CLI (`agy`) Docker Image with Azure DevOps & Git MCP

A production-ready Docker container combining Google's **Antigravity CLI (`agy`)**, the **Official Microsoft Azure DevOps MCP Server** (`@azure-devops/mcp`), and the **Git MCP Server** (`mcp-server-git`).

Engineered for autonomous and interactive code tasks in Azure DevOps environments:
- 🔍 **Automated & Interactive PR Reviews**: Deep code diff analysis, vulnerability scanning, and threaded comment generation.
- 🚀 **Smart PR Creation**: Semantic branch inspection, work item linking, and structured description drafting.
- 🛠️ **Seamless Git & MCP Integration**: Both Azure DevOps remote tools and local Git tools exposed natively to `agy`.
- ⚙️ **Fully Configurable via Environment Variables**: Zero hardcoded credentials or org settings.

---

## 📋 Table of Contents
1. [Architecture](#-architecture)
2. [Prerequisites](#-prerequisites)
3. [Quick Start](#-quick-start)
4. [Environment Variables Reference](#-environment-variables-reference)
5. [Usage Modes](#-usage-modes)
   - [Interactive Terminal Mode](#1-interactive-terminal-mode)
   - [Headless / CI/CD Mode](#2-headless--cicd-mode)
   - [Built-in Helper Scripts](#3-built-in-helper-scripts)
6. [Azure DevOps Pipeline Integration](#-azure-devops-pipeline-integration)
7. [Customizing Rules & Skills](#-customizing-rules--skills)

---

## 🏗️ Architecture

```
                                  ┌─────────────────────────────┐
                                  │    Antigravity CLI (agy)    │
                                  │      (Gemini AI Engine)     │
                                  └──────────────┬──────────────┘
                                                 │
                   ┌─────────────────────────────┴─────────────────────────────┐
                   ▼                                                           ▼
       ┌────────────────────────┐                                  ┌───────────────────────┐
       │ Azure DevOps MCP Server│                                  │    Git MCP Server     │
       │  (@azure-devops/mcp)   │                                  │   (mcp-server-git)    │
       └───────────┬────────────┘                                  └───────────┬───────────┘
                   │ Stdio / API                                               │ Local Stdio
                   ▼                                                           ▼
       ┌────────────────────────┐                                  ┌───────────────────────┐
       │   Azure DevOps Cloud   │                                  │   Local Git Repo      │
       │  (PRs, Commits, Work)  │                                  │     (/workspace)      │
       └────────────────────────┘                                  └───────────────────────┘
```

When the container boots:
1. `entrypoint.sh` reads your environment variables.
2. It dynamically generates `~/.gemini/config/mcp_config.json` with configuration for both MCP servers.
3. It configures `~/.gemini/antigravity-cli/settings.json` and git authentication/safe directories.
4. It hands off execution to `agy` or your specified command/script.

---

## 🔑 Prerequisites

- [Docker](https://docs.docker.com/get-docker/) installed.
- **Gemini API Key**: From [Google AI Studio](https://aistudio.google.com/) or Vertex AI.
- **Azure DevOps Personal Access Token (PAT)**: With scopes:
  - **Code**: `Read & Write`
  - **Work Items**: `Read & Write` (if linking issues)
  - **Pull Request Threads**: `Read & Write`

---

## 🚀 Quick Start

### 1. Clone & Configure Environment
```bash
cp .env.example .env
```
Edit `.env` and fill in your credentials:
```env
GEMINI_API_KEY=your_gemini_api_key_here
AZURE_DEVOPS_ORG=your-org-name
AZURE_DEVOPS_PAT=your_pat_token_here
AZURE_DEVOPS_PROJECT=YourProject
```

### 2. Build the Docker Image
```bash
docker build -t agy-azuredevops:latest .
```

### 3. Run with Docker Compose
```bash
docker compose run --rm agy
```

---

## ⚙️ Environment Variables Reference

| Variable | Description | Required | Default |
| :--- | :--- | :---: | :--- |
| `GEMINI_API_KEY` | Google Gemini API key for Antigravity | **Yes** | — |
| `AZURE_DEVOPS_ORG` | Azure DevOps organization name or URL | **Yes** | — |
| `AZURE_DEVOPS_PAT` | Personal Access Token for Azure DevOps | **Yes** | — |
| `AZURE_DEVOPS_PROJECT`| Default Azure DevOps project | Recommended | — |
| `AZURE_DEVOPS_DOMAINS`| Enabled tool domains (`core,repositories,work-items,work,pipelines`) | No | All code domains |
| `AZURE_DEVOPS_AUTH_METHOD` | Auth method for MCP server (`envvar`, `azcli`, `interactive`) | No | `envvar` |
| `GIT_USER_NAME` | Git committer name | No | `Antigravity Agent` |
| `GIT_USER_EMAIL` | Git committer email | No | `antigravity@example.com` |
| `GIT_DEFAULT_BRANCH` | Default repository branch | No | `main` |
| `GIT_REPO_PATH` | Path to git repository in container | No | `/workspace` |
| `AGY_MODEL` | Override LLM model (e.g., `gemini-2.5-pro`) | No | Default CLI model |
| `AGY_VERBOSE` | Output verbose banner information on startup | No | `false` |

---

## 💻 Usage Modes

### 1. Interactive Terminal Mode
Run an interactive session directly inside a local repository:
```bash
docker run -it --rm \
  --env-file .env \
  -v "$(pwd):/workspace" \
  agy-azuredevops:latest
```
Inside the interactive session, you can converse with `agy` using natural language:
```text
agy> List active PRs in project CoreBanking
agy> Review PR #142 and highlight potential security issues
```

---

### 2. Headless / CI/CD Mode
Run one-shot automated tasks without interactive prompts:
```bash
docker run --rm \
  --env-file .env \
  -v "$(pwd):/workspace" \
  agy-azuredevops:latest \
  agy -p "Review Azure DevOps PR #1042 in project CoreBanking and print summary" --dangerously-skip-permissions
```

---

### 3. Built-in Helper Scripts

The image bundles pre-configured scripts inside `/usr/local/bin`:

#### A. Review a Pull Request (`review-pr`)
```bash
# Dry run review on stdout
docker run --rm --env-file .env -v "$(pwd):/workspace" agy-azuredevops:latest review-pr 1042

# Autonomous review with comment posting enabled
docker run --rm --env-file .env -v "$(pwd):/workspace" agy-azuredevops:latest review-pr 1042 --post-comments -n
```

#### B. Create a Pull Request (`create-pr`)
```bash
# Create PR for current branch linked to work item #4589
docker run --rm --env-file .env -v "$(pwd):/workspace" agy-azuredevops:latest create-pr --title "feat: implement caching" --target main -w 4589 -n
```

#### C. Generate PR Summary (`pr-summary`)
```bash
# Generate markdown summary comparing current branch against main
docker run --rm --env-file .env -v "$(pwd):/workspace" agy-azuredevops:latest pr-summary --base main
```

---

## 🔄 Azure DevOps Pipeline Integration

You can execute automated PR reviews directly inside an Azure DevOps pipeline (`azure-pipelines.yml`):

```yaml
trigger: none

pr:
  branches:
    include:
      - main
      - develop

pool:
  vmImage: 'ubuntu-latest'

steps:
- checkout: self
  fetchDepth: 0

- script: |
    docker run --rm \
      -e GEMINI_API_KEY="$(GEMINI_API_KEY)" \
      -e AZURE_DEVOPS_ORG="$(System.CollectionUri)" \
      -e AZURE_DEVOPS_PAT="$(System.AccessToken)" \
      -e AZURE_DEVOPS_PROJECT="$(System.TeamProject)" \
      -v "$(Build.SourcesDirectory):/workspace" \
      agy-azuredevops:latest \
      review-pr $(System.PullRequest.PullRequestId) --post-comments -n
  displayName: 'Antigravity Automated PR Review'
  env:
    GEMINI_API_KEY: $(GEMINI_API_KEY)
    SYSTEM_ACCESSTOKEN: $(System.AccessToken)
```

---

## 🎯 Customizing Rules & Skills

The image copies standard review guidelines into `~/.gemini/config/rules/`.

You can also mount your repository-specific rules and skills at runtime:
```bash
docker run -it --rm \
  --env-file .env \
  -v "$(pwd):/workspace" \
  -v "$(pwd)/.agents:/home/agyuser/.gemini/config/agents" \
  agy-azuredevops:latest
```
Any `.agents/rules/*.md` files located in your repo root will be automatically recognized and applied by `agy`.
