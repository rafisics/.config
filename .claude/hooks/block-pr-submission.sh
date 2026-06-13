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

# Block PR creation and git push commands
if echo "$COMMAND" | grep -qE 'git push|gh pr create|glab mr create'; then
  echo "BLOCKED: PR submission and git push operations are not allowed directly." >&2
  echo "Use the /merge command (GitHub PR or GitLab MR) or /pr command instead." >&2
  echo "These commands include proper CI verification and user approval gates." >&2
  exit 2
fi

exit 0
