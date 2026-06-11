#!/bin/bash
# lifecycle-notify.sh - Bridge script for orchestrator phase transition notifications
#
# Usage:
#   lifecycle-notify.sh STATUS           # Normal mode: tab color + TTS
#   lifecycle-notify.sh STATUS --quiet   # Quiet mode: tab color only (no TTS)
#   lifecycle-notify.sh ""               # Empty status: no-op, exits 0
#
# Called by orchestrator-postflight.sh Stage 8b for lifecycle phase transitions.
#
# Arguments:
#   $1  STATUS   - Lifecycle status string (e.g., "researched", "planned", "implemented")
#   $2  --quiet  - Optional flag to suppress TTS announcement
#
# Behavior:
#   Always calls wezterm-notify.sh STATUS for tab color update
#   In normal mode (no --quiet): also calls tts-notify.sh --lifecycle STATUS

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOKS_DIR="$SCRIPT_DIR/../hooks"

# Parse arguments
STATUS="${1:-}"
QUIET="${2:-}"

# No-op if status is empty
if [[ -z "$STATUS" ]]; then
    exit 0
fi

# Always update WezTerm tab color via wezterm-notify.sh
if [[ -f "$HOOKS_DIR/wezterm-notify.sh" ]]; then
    bash "$HOOKS_DIR/wezterm-notify.sh" "$STATUS" 2>/dev/null || true
fi

# In normal mode (not --quiet): also announce via TTS
if [[ "$QUIET" != "--quiet" ]]; then
    if [[ -f "$HOOKS_DIR/tts-notify.sh" ]]; then
        bash "$HOOKS_DIR/tts-notify.sh" --lifecycle "$STATUS" 2>/dev/null || true
    fi
fi

exit 0
