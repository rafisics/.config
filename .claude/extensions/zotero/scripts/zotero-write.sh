#!/usr/bin/env bash
# zotero-write.sh - Write operations via Zotero Web API through zot
#
# Category A: CLI Wrapper (implemented in task 750)
#
# Usage:
#   zotero-write.sh <operation> <key> [options...]
#
# Operations:
#   note-add KEY "text"          - Add note to item
#   tag-add KEY TAG              - Add tag to item
#   tag-remove KEY TAG           - Remove tag from item
#   attach-file KEY FILEPATH     - Upload file as child attachment
#
# Options:
#   --dry-run                    - Preview operation; do not execute
#   --idempotency-key KEY        - Idempotency key for attach-file
#
# Exit codes:
#   0 - Success (or dry-run preview completed)
#   1 - API error; attachment upload failed; key not found
#   2 - ZOTERO_API_KEY not set; zot not installed
#
# Environment variables:
#   ZOTERO_API_KEY - Web API key (required for all write operations)
#   ZOT_DATA_DIR   - Path to Zotero data directory
#
# Implementation: task 750

set -euo pipefail

echo "zotero-write.sh: not yet implemented (task 750)" >&2
exit 2
