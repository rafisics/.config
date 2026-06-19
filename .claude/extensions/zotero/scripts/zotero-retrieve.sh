#!/usr/bin/env bash
# zotero-retrieve.sh - Context injection script for the --zot flag
#
# Category D: Context Injection (implemented in task 753)
#
# Usage:
#   zotero-retrieve.sh <description> <task_type>
#
# Arguments:
#   <description>  - Task description string (from skill preflight)
#   <task_type>    - Task type string (e.g., meta, neovim, lean4)
#
# Algorithm:
#   1. Check: specs/zotero-index.json exists and has entries; else exit 0 silently
#   2. Extract query terms from description (stop-word filtered, length > 3)
#   3. Score each entry: title*4 + tags*3 + abstract*2 + keywords*2 + collections*1 + notes*1
#   4. Filter: total_score >= 4
#   5. Sort by score descending
#   6. Greedy-select within TOKEN_BUDGET:
#      - has_chunks: use literature-search.sh for chunk-level selection
#      - has_pdf (no chunks): add metadata block + convert suggestion
#      - metadata only: add available fields block
#   7. Update last_retrieved timestamp (best-effort; non-blocking)
#   8. Emit <zotero-context>...</zotero-context> block (or empty string on graceful failure)
#
# stdout: <zotero-context> block or empty string
# stderr: Diagnostic messages only (not surfaced to agent)
#
# Exit codes:
#   0 - Context emitted or gracefully empty (no entries, index missing, no matches)
#   1 - Fatal error (JSON parse failure in index)
#
# Environment variables:
#   TOKEN_BUDGET - Override default (from index.token_budget or 8000)
#
# Dependencies: jq, literature-search.sh (from literature extension)
# Implementation: task 753

set -euo pipefail

# Graceful empty output (not configured)
echo "zotero-retrieve.sh: not yet implemented (task 753)" >&2
exit 2
