#!/usr/bin/env bash
# zotero-chunk.sh - Extract full text from a Zotero item PDF and chunk into sections
#
# Category B: Chunk Management Pipeline (implemented in task 752)
#
# Usage:
#   zotero-chunk.sh <zotero_key> [--output-dir DIR] [--pages N-M]
#
# Arguments:
#   <zotero_key>       - 8-char Zotero item key (required)
#   --output-dir DIR   - Override chunk storage directory (default: specs/literature/{citation_key}/)
#   --pages N-M        - Restrict extraction to page range
#
# Pipeline steps:
#   1. zotero-read.sh item KEY -> extract citation_key, title, authors, year
#   2. zotero-read.sh pdf KEY [--pages N-M] -> full text to temp file
#   3. literature-chunk.sh -> split into logical sections
#   4. Save chunks to specs/literature/{citation_key}/
#   5. Count chunks and estimate tokens
#   6. Update specs/zotero-index.json: has_chunks, chunk_dir, chunk_count, token_count
#   7. literature-build-index.sh --local -> rebuild FTS5 search database
#
# Exit codes:
#   0 - Success; index updated
#   1 - PDF extraction failed; chunking failed; index update failed
#   2 - Item not in specs/zotero-index.json; zot not installed
#
# Dependencies: zotero-read.sh, literature-chunk.sh, literature-build-index.sh, jq
# Implementation: task 752

set -euo pipefail

echo "zotero-chunk.sh: not yet implemented (task 752)" >&2
exit 2
