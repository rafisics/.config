#!/usr/bin/env bash
# zotero-attach-chunks.sh - Upload local markdown chunks as Zotero child attachments
#
# Category B: Chunk Management Pipeline (implemented in task 752)
#
# Usage:
#   zotero-attach-chunks.sh <zotero_key> [--dry-run]
#
# Arguments:
#   <zotero_key>  - 8-char Zotero item key (required)
#   --dry-run     - Preview uploads without executing
#
# Pipeline steps:
#   1. Read chunk_dir from specs/zotero-index.json for the given key
#   2. Exit 1 if has_chunks is false or chunk_dir is null
#   3. For each .md file in chunk_dir (sorted lexicographically):
#      zotero-write.sh attach-file KEY chunk.md --idempotency-key "chunk-{KEY}-{N}"
#   4. Print summary: N succeeded, M failed
#
# Exit codes:
#   0 - All chunks uploaded (or dry-run completed)
#   1 - One or more chunk uploads failed
#   2 - ZOTERO_API_KEY not set; item not in index; has_chunks is false
#
# Dependencies: zotero-write.sh, jq
# Implementation: task 752

set -euo pipefail

echo "zotero-attach-chunks.sh: not yet implemented (task 752)" >&2
exit 2
