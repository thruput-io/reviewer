# Azure DevOps Pull Request & Code Guidelines

When performing code reviews, PR creation, and git workflows in Azure DevOps, adhere to the following principles:

## 1. Pull Request Reviews
- **Precision & Line Anchoring**: Anchor review comments to specific lines of code where possible.
- **Categorization**: Prefix comments with clear tags:
  - `[BLOCKER]` / `[BUG]`: Critical correctness or crash bug that must be addressed.
  - `[SECURITY]`: Vulnerabilities, unvalidated input, insecure secrets/creds handling.
  - `[PERF]`: Performance bottlenecks, N+1 queries, unindexed lookups, memory leaks.
  - `[SUGGESTION]`: Optional stylistic or structural improvements.
  - `[QUESTION]`: Inquiries for clarification or intent.
  - `[NIT]`: Minor polish or formatting.
- **Constructive & Actionable**: Provide code suggestions and explain the "why" behind every recommendation.
- **Context Awareness**: Check linked Azure DevOps work items to ensure the implementation matches the acceptance criteria.

## 2. Pull Request Creation
- **Conventional Commits**: Use semantic PR titles (e.g., `feat: ...`, `fix: ...`, `refactor: ...`, `docs: ...`).
- **Structured Description**:
  - **Summary**: Concise overview of what changed.
  - **Motivation / Problem**: Why this change is needed.
  - **Work Item Link**: Reference Azure DevOps Work Item `#<id>`.
  - **Validation & Testing**: List of automated tests run and manual checks verified.
  - **Checklist**: Any follow-up items or breaking changes.

## 3. Tool Usage Best Practices
- Use **Azure DevOps MCP tools** (`repo_pull_request`, `repo_pull_request_thread`, `repo_pull_request_thread_write`, `wit_work_item`, etc.) for interacting with Azure DevOps PRs, comments, and work items.
- Use **Git MCP tools** and local `git` commands for repository analysis, branch inspection, and local diffing.
