#!/usr/bin/env bash
# zotero-read.sh - Read-only operations against Zotero via zot CLI
#
# Category A: CLI Wrapper (implemented in task 750)
#
# Usage:
#   zotero-read.sh <operation> [key] [options...]
#
# Operations:
#   search "query string"   - Search Zotero library items
#   item KEY                - Get full metadata for item KEY
#   pdf KEY [--pages N-M]   - Extract PDF text for item KEY
#   outline KEY             - Get document outline for item KEY
#   annotations KEY         - Get PDF annotations for item KEY
#   note KEY                - Get notes for item KEY
#   tags KEY                - Get tags for item KEY
#   collections             - List collection hierarchy
#   stats                   - Get library statistics
#
# Exit codes:
#   0 - Success
#   1 - Runtime error (key not found, zot error, parse failure)
#   2 - Not configured (zot not installed, ZOT_DATA_DIR not set)
#
# Environment variables:
#   ZOT_DATA_DIR - Path to Zotero data directory (required)
#
# Implementation: task 750

set -euo pipefail

echo "zotero-read.sh: not yet implemented (task 750)" >&2
exit 2
