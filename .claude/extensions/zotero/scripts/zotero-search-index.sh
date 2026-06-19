#!/usr/bin/env bash
# zotero-search-index.sh - Search the per-repo index with multi-field scoring
#
# Category C: Index Management (implemented in task 751)
#
# Usage:
#   zotero-search-index.sh "query string" [--limit N] [--format json|pretty]
#
# Arguments:
#   "query string"       - Search query (required)
#   --limit N            - Return at most N results (default: 10)
#   --format json|pretty - Output format (default: pretty)
#
# Algorithm:
#   1. Extract query terms (stop-word filtered, length > 3)
#   2. Score each specs/zotero-index.json entry using weighted formula
#   3. Filter: total_score >= 1 (looser than --zot threshold of 4)
#   4. Sort by score descending
#   5. Return top N results
#
# Fallback: If index is empty/missing, search full Zotero library via zotero-read.sh
#   and display with notice to add items via /zotero --add KEY
#
# stdout: Scored results (JSON array or formatted table)
# stderr: Error details
#
# Exit codes:
#   0 - Results returned (may be empty array)
#   1 - JSON parse error; query string empty
#   2 - specs/zotero-index.json not found AND zot not installed (both paths unavailable)
#
# Dependencies: jq, zotero-read.sh (for fallback)
# Implementation: task 751

set -euo pipefail

echo "zotero-search-index.sh: not yet implemented (task 751)" >&2
exit 2
