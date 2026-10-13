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

