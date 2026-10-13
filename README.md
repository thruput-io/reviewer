# Azure DevOps PR Reviewer

Automated pull request code reviews using Google's Antigravity CLI (`agy`) and the `thruput-io/agents` review skill. Organization, project, repository, and PR ID are parsed directly from the PR URL.

---

## How to Run

### 1. Build the image
```bash
podman build -t reviewer .
# or
docker build -t reviewer .
```

### 2. Run a review (Dry-run)
Prints the review report to stdout without modifying the PR:
```bash
podman run --rm \
  -e GEMINI_API_KEY="your-gemini-key" \
  -e AZURE_DEVOPS_PAT="your-azure-pat" \
  reviewer https://dev.azure.com/myorg/myproject/_git/myrepo/pullrequest/1042
```

### 3. Post review comments to PR threads
```bash
podman run --rm \
  -e GEMINI_API_KEY="your-gemini-key" \
  -e AZURE_DEVOPS_PAT="your-azure-pat" \
  reviewer https://dev.azure.com/myorg/myproject/_git/myrepo/pullrequest/1042 --post-comments
```

---

## Command Reference

```text
reviewer <PR_URL> [--post-comments]
```

| Parameter | Description |
| :--- | :--- |
| `<PR_URL>` | Full Azure DevOps Pull Request URL (*required*) |
| `--post-comments` | Post comments directly to the PR threads (default: dry-run on stdout) |

---

## Required Environment Variables

| Variable | Description |
| :--- | :--- |
| `GEMINI_API_KEY` | Google Gemini API key |
| `AZURE_DEVOPS_PAT` | Azure DevOps Personal Access Token (Code `Read`, or `Read & Write` to post comments) |

---

## Passing Credentials Elegantly

To avoid typing tokens into the command line, use one of these cleaner approaches:

### 1. Shell Wrapper Function *(Recommended)*
Add a helper function to your `~/.zshrc` or `~/.bashrc`:
```bash
reviewer() {
  podman run --rm \
    -e GEMINI_API_KEY \
    -e AZURE_DEVOPS_PAT \
    reviewer "$@"
}
```
Export your credentials once in your shell profile:
```bash
export GEMINI_API_KEY="your-gemini-key"
export AZURE_DEVOPS_PAT="your-azure-pat"
```
Now you can run reviews like a native CLI tool:
```bash
reviewer https://dev.azure.com/myorg/myproject/_git/myrepo/pullrequest/1042
reviewer https://dev.azure.com/myorg/myproject/_git/myrepo/pullrequest/1042 --post-comments
```

### 2. Environment File (`--env-file`)
Store credentials in a local `.env` file:
```env
GEMINI_API_KEY=your-gemini-key
AZURE_DEVOPS_PAT=your-azure-pat
```
Run with:
```bash
podman run --rm --env-file .env reviewer <PR_URL>
```

### 3. Host Passthrough
If tokens are already exported in your shell environment, pass the flag names without values (keeps secrets out of shell history and process lists):
```bash
podman run --rm -e GEMINI_API_KEY -e AZURE_DEVOPS_PAT reviewer <PR_URL>
```

---

## Azure DevOps Pipeline (`azure-pipelines.yml`)

```yaml
trigger: none

pr:
  branches:
    include: [main]

pool:
  vmImage: 'ubuntu-latest'

steps:
- script: |
    PR_URL="$(System.CollectionUri)$(System.TeamProject)/_git/$(Build.Repository.Name)/pullrequest/$(System.PullRequest.PullRequestId)"

    docker run --rm \
      -e GEMINI_API_KEY="$(GEMINI_API_KEY)" \
      -e AZURE_DEVOPS_PAT="$(System.AccessToken)" \
      reviewer "$PR_URL" --post-comments
  env:
    GEMINI_API_KEY: $(GEMINI_API_KEY)
    SYSTEM_ACCESSTOKEN: $(System.AccessToken)
```

