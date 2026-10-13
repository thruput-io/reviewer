# Azure DevOps Pull Request Reviewer (`reviewer`)

A purpose-built container combining Google's **Antigravity CLI (`agy`)**, the **Official Microsoft Azure DevOps MCP Server** (`@azure-devops/mcp`), and the **Git MCP Server** (`mcp-server-git`) to perform automated and interactive pull request reviews in Azure DevOps.

- 🔍 **Automated PR Reviews**: Deep code diff analysis, vulnerability scanning, and review reports using the `pr-review` skill from `thruput-io/agents`.
- 💬 **Thread Comments**: Optionally post actionable review feedback directly to PR threads.
- 🔗 **Zero Configuration from URL**: Pass the full Azure DevOps PR URL — organization, project, repository, and PR ID are automatically extracted.
- ⚡ **TTY Auto-Detection**: Automatically runs headlessly in CI/CD without pseudo-terminal errors.

---

## 📋 Table of Contents
1. [Architecture](#-architecture)
2. [Prerequisites](#-prerequisites)
3. [Quick Start](#-quick-start)
4. [Environment Variables Reference](#-environment-variables-reference)
5. [Usage](#-usage)
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

### 1. Build the Image
```bash
podman build -t reviewer .
# or
docker build -t reviewer .
```

### 2. Review a Pull Request
Pass the full PR URL directly as the argument:
```bash
podman run --rm \
  -e GEMINI_API_KEY="your-gemini-key" \
  -e AZURE_DEVOPS_PAT="your-azure-pat" \
  reviewer https://dev.azure.com/myorg/myproject/_git/myrepo/pullrequest/1042
```

---

## ⚙️ Environment Variables Reference

Only **two** environment variables are required:

| Variable | Description | Required |
| :--- | :--- | :---: |
| `GEMINI_API_KEY` | Google Gemini API key for Antigravity engine | **Yes** |
| `AZURE_DEVOPS_PAT` | Personal Access Token for Azure DevOps MCP server | **Yes** |

All other configurations (organization, project, repository, PR ID) are parsed directly from the PR URL argument.

---

## 💻 Usage

`review-pr` is the default container command. Pass the full PR URL and options directly to `podman run` or `docker run`:

### Dry-run Review (Prints to stdout)
```bash
podman run --rm \
  -e GEMINI_API_KEY="your-gemini-key" \
  -e AZURE_DEVOPS_PAT="your-azure-pat" \
  reviewer https://dev.azure.com/myorg/myproject/_git/myrepo/pullrequest/1042
```

### Post Comments to PR Threads
```bash
podman run --rm \
  -e GEMINI_API_KEY="your-gemini-key" \
  -e AZURE_DEVOPS_PAT="your-azure-pat" \
  reviewer https://dev.azure.com/myorg/myproject/_git/myrepo/pullrequest/1042 --post-comments
```

### Mount Workspace & Review
Mount your local checkout to allow local diffing alongside the Azure DevOps MCP tools:
```bash
podman run --rm \
  -e GEMINI_API_KEY="your-gemini-key" \
  -e AZURE_DEVOPS_PAT="your-azure-pat" \
  -v "$(pwd):/workspace" \
  reviewer https://dev.azure.com/myorg/myproject/_git/myrepo/pullrequest/1042
```

### Interactive Session
To converse interactively with the reviewer agent, allocate a pseudo-TTY with `-it`:
```bash
podman run -it --rm \
  -e GEMINI_API_KEY="your-gemini-key" \
  -e AZURE_DEVOPS_PAT="your-azure-pat" \
  reviewer https://dev.azure.com/myorg/myproject/_git/myrepo/pullrequest/1042
```

### Supported Arguments & Flags
```text
review-pr <PR_URL> [options]

Arguments:
  <PR_URL>                Full Azure DevOps Pull Request URL (required)
                          e.g. https://dev.azure.com/org/project/_git/repo/pullrequest/1042

Options:
  --post-comments         Allow the agent to post review comments directly to PR threads
  -n, --non-interactive   Execute headlessly without prompts (auto-detected when no TTY)
  -i, --instructions <tx> Extra instructions or focus areas for the review
  -h, --help              Show this help message
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
    PR_URL="$(System.CollectionUri)$(System.TeamProject)/_git/$(Build.Repository.Name)/pullrequest/$(System.PullRequest.PullRequestId)"

    docker run --rm \
      -e GEMINI_API_KEY="$(GEMINI_API_KEY)" \
      -e AZURE_DEVOPS_PAT="$(System.AccessToken)" \
      -v "$(Build.SourcesDirectory):/workspace" \
      reviewer "$PR_URL" --post-comments
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
  -e GEMINI_API_KEY="your-gemini-key" \
  -e AZURE_DEVOPS_PAT="your-azure-pat" \
  -v "$(pwd):/workspace" \
  -v "/path/to/my-pr-skill:/home/agyuser/.gemini/config/skills/pr-review:ro" \
  reviewer https://dev.azure.com/myorg/myproject/_git/myrepo/pullrequest/1042
```
