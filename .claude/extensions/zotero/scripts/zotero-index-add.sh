#!/usr/bin/env bash
# zotero-index-add.sh - Add a Zotero item to the per-repo index
#
# Category C: Index Management (implemented in task 751)
#
# Usage:
#   zotero-index-add.sh <zotero_key> [--chunk]
#
# Arguments:
#   <zotero_key>  - 8-char Zotero item key (required)
#   --chunk       - After adding to index, automatically run zotero-chunk.sh if item has PDF
#
# Pipeline steps:
#   1. zotero-read.sh item KEY -> full item metadata JSON
#   2. Extract: title, authors, year, item_type, abstract (300 chars), keywords, tags, collections
#   3. Resolve PDF path from data.attachments
#   4. Extract relevance_keywords (stop-word filtered, length > 3)
#   5. Optionally fetch notes_summary (first 200 chars of first note)
#   6. Build 20-field entry JSON
#   7. Update or append to specs/zotero-index.json
#   8. If --chunk and has_pdf: zotero-chunk.sh KEY
#
# Exit codes:
#   0 - Item added or updated successfully
#   1 - Metadata fetch failed; JSON parse error; index write error
#   2 - zot not installed; specs/zotero-index.json not found (run /zotero --setup first)
#
# Dependencies: zotero-read.sh, jq
# Implementation: task 751

set -euo pipefail

echo "zotero-index-add.sh: not yet implemented (task 751)" >&2
exit 2
