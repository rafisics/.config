#!/bin/bash
# block-pr-submission.sh
# PreToolUse hook: block git push, gh pr create, and glab mr create operations.
#
# These operations require explicit user approval via the /merge command (GitHub PR
# or GitLab MR) or /pr command (CSLib PRs). The /merge and /pr commands include
# proper CI verification and user approval gates.
#
# Blocking mechanism: exit code 2 (takes precedence over allow rules, fires before
# permission evaluation). Does NOT use permissionDecision: deny due to documented
# bugs when tools are in the allow list (issues #4669, #13214, #18312).

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)

# Allow through if command is empty (non-Bash tool or parse failure)
if [ -z "$COMMAND" ]; then
  exit 0
fi

# Block actual git push / PR creation commands.
# Match patterns that start a command or follow && ; | — not strings inside quotes/variables.
# Uses word-boundary-aware patterns to avoid false positives on commands that merely
# mention "git push" in string literals (e.g., jq --arg val "... git push ...").
if echo "$COMMAND" | grep -qE '(^|[;&|] *)git push( |$)'; then
  echo "BLOCKED: git push is not allowed directly." >&2
  echo "Use /merge (GitHub/GitLab) or /pr (CSLib) to push and create PRs." >&2
  exit 2
fi
if echo "$COMMAND" | grep -qE '(^|[;&|] *)gh pr create'; then
  echo "BLOCKED: gh pr create is not allowed directly." >&2
  echo "Use /merge or /pr to create pull requests with proper approval." >&2
  exit 2
fi
if echo "$COMMAND" | grep -qE '(^|[;&|] *)glab mr create'; then
  echo "BLOCKED: glab mr create is not allowed directly." >&2
  echo "Use /merge to create merge requests with proper approval." >&2
  exit 2
fi

exit 0
