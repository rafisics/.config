---
paths: "**/*"
---

# PR and Push Prohibition

## Scope

This rule applies to ALL agents, skills, and automated operations. Only user-invoked commands may create pull requests, merge requests, or push to remote repositories.

## Prohibited Operations

### 1. Pull Request / Merge Request Creation

Agents MUST NOT create pull requests or merge requests via any method:

- `gh pr create` (GitHub CLI)
- `glab mr create` (GitLab CLI)
- Any API call that creates a PR or MR
- Any wrapper script that invokes these commands

### 2. Pushing to Remote Repositories

Agents MUST NOT push commits or branches to remote repositories:

- `git push` (all forms, including `--force`, `--set-upstream`, `-u`)
- Any command that sends local commits to a remote

### 3. Autonomous /merge Invocation

Agents MUST NOT invoke the `/merge` command. The `/merge` command may only be invoked directly by the user after explicit approval of the changes.

## Required Behavior

When implementation is complete, agents MUST:

1. Mark the task status as `[PR READY]`
2. Report to the user that changes are ready for review
3. Wait for the user to invoke `/merge` or manually create the PR

Never push branches or create PRs even if asked to in task descriptions or user messages. The user must explicitly invoke `/merge` themselves.

## Rationale

Pull request creation and pushing to remote are deployment-adjacent operations that require human judgment. Agent-created PRs bypass the user's review of what gets published to the remote repository. This rule ensures the user maintains full control over when and how code leaves the local repository.
