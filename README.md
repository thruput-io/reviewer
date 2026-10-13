# Azure DevOps Pull Request Reviewer (`reviewer`)

A purpose-built container combining Google's **Antigravity CLI (`agy`)**, the **Official Microsoft Azure DevOps MCP Server** (`@azure-devops/mcp`), and the **Git MCP Server** (`mcp-server-git`) to perform automated and interactive pull request reviews in Azure DevOps.

- 🔍 **Automated PR Reviews**: Deep code diff analysis, vulnerability scanning, and review summaries.
- 💬 **Thread Comments**: Optionally post actionable review feedback directly to PR threads.
- 🎯 **PR ID as Default Argument**: Pass the PR ID directly (e.g. `podman run reviewer 1042`).
- ⚡ **TTY Auto-Detection**: Automatically runs headlessly in CI/CD without pseudo-terminal errors.

---

## 📋 Table of Contents
1. [Architecture](#-architecture)
2. [Prerequisites](#-prerequisites)
3. [Quick Start](#-quick-start)
4. [Environment Variables Reference](#-environment-variables-reference)
5. [Usage](#-usage)
   - [CLI / Docker Examples](#cli--docker-examples)
   - [Auto-detection of Non-Interactive Mode](#auto-detection-of-non-interactive-mode)
6. [Azure DevOps Pipeline Integration](#-azure-devops-pipeline-integration)
7. [Customizing Review Skills & Rules](#-customizing-review-skills--rules)

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

---

## 🔑 Prerequisites

- [Podman](https://podman.io/) or [Docker](https://docs.docker.com/get-docker/) installed.
- **Gemini API Key**: From [Google AI Studio](https://aistudio.google.com/) or Vertex AI.
- **Azure DevOps Personal Access Token (PAT)**: With scopes:
  - **Code**: `Read` (or `Read & Write` to post comments)
  - **Pull Request Threads**: `Read & Write` (if posting comments)

---

## 🚀 Quick Start

### 1. Configure Environment
Create `.env`:
```env
GEMINI_API_KEY=your_gemini_api_key_here
AZURE_DEVOPS_ORG=your-org-name
AZURE_DEVOPS_PAT=your_pat_token_here
AZURE_DEVOPS_PROJECT=YourProject
```

### 2. Build the Image
```bash
podman build -t reviewer .
# or
docker build -t reviewer .
```

### 3. Review a PR
Pass the PR ID directly as the argument:
```bash
podman run --env-file .env reviewer 1042
```

---

## ⚙️ Environment Variables Reference

| Variable | Description | Required | Default |
| :--- | :--- | :---: | :--- |
| `GEMINI_API_KEY` | Google Gemini API key | **Yes** | — |
| `AZURE_DEVOPS_ORG` | Azure DevOps organization name or URL | **Yes** | — |
| `AZURE_DEVOPS_PAT` | Personal Access Token for Azure DevOps | **Yes** | — |
| `AZURE_DEVOPS_PROJECT`| Azure DevOps project name | Recommended | — |
| `PR_ID` | Default Pull Request ID to review | No | — |
| `PR_REVIEW_SKILL` | Review skill name to use | No | `pr-review` |
| `AZURE_DEVOPS_DOMAINS`| Enabled MCP tool domains | No | `core,repositories,work-items,work,pipelines` |
| `GIT_REPO_PATH` | Path to git repository in container | No | `/workspace` |
| `AGY_MODEL` | Override LLM model (e.g., `gemini-2.5-pro`) | No | Default CLI model |
| `AGY_VERBOSE` | Output verbose banner information on startup | No | `false` |

---

## 💻 Usage

`review-pr` is the default command. You can pass the PR ID and options directly to `podman run` or `docker run`:

### Dry-run Review (Prints to stdout)
```bash
podman run --env-file .env reviewer 1042
```

### Post Comments to PR Threads
```bash
podman run --env-file .env reviewer 1042 --post-comments
```

### Mount Workspace & Review
```bash
podman run --rm --env-file .env \
  -v "$(pwd):/workspace" \
  reviewer 1042
```

### Interactive Session
If you want to converse interactively with the agent about the PR review, allocate a TTY with `-it`:
```bash
podman run -it --rm --env-file .env reviewer 1042
```

### Supported Arguments & Flags
```text
review-pr [PR_ID] [options]

Arguments:
  [PR_ID]                 Azure DevOps Pull Request ID (or pass via PR_ID env var)

Options:
  -p, --project <name>    Azure DevOps Project name (default: $AZURE_DEVOPS_PROJECT)
  -r, --repo <name>       Azure DevOps Repository name
  -s, --skill <name>      Skill name to use (default: pr-review or $PR_REVIEW_SKILL)
  --post-comments         Post review comments directly to the PR threads
  -n, --non-interactive   Execute headlessly without prompts (auto-detected when no TTY)
  -i, --instructions <tx> Extra instructions or focus areas for the review
  -h, --help              Show help message
```

---

## 🔄 Azure DevOps Pipeline Integration

Run automated PR reviews directly inside `azure-pipelines.yml`:

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
      reviewer $(System.PullRequest.PullRequestId) --post-comments
  displayName: 'Antigravity Automated PR Review'
  env:
    GEMINI_API_KEY: $(GEMINI_API_KEY)
    SYSTEM_ACCESSTOKEN: $(System.AccessToken)
```

---

## 🎯 Customizing Review Skills & Rules

Mount custom review skills or rules into the container at runtime:

```bash
podman run --rm \
  --env-file .env \
  -v "$(pwd):/workspace" \
  -v "/path/to/my-pr-skill:/home/agyuser/.gemini/config/skills/pr-review:ro" \
  reviewer 1042
```
