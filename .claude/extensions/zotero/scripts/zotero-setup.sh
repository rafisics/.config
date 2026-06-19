#!/usr/bin/env bash
# zotero-setup.sh - Setup wizard, validation, and status reporting for the zotero extension
#
# Category A: CLI Wrapper (implemented in task 750)
#
# Usage:
#   zotero-setup.sh [--detect|--configure|--validate|--status]
#
# Sub-commands:
#   --detect      - Auto-detect Zotero data directory
#   --configure   - Interactive setup: detect dir, create specs/zotero-index.json
#   --validate    - Check: zot installed, ZOT_DATA_DIR valid, SQLite readable
#   --status      - Print configuration summary and library stats
#
# Exit codes:
#   0 - Success (detection found path; validation passed; status retrieved)
#   1 - Detection failed; validation failed; status unavailable
#   2 - zot not installed
#
# Dependencies: zot (zotero-cli-cc), jq
# Implementation: task 750

set -euo pipefail

echo "zotero-setup.sh: not yet implemented (task 750)" >&2
exit 2
