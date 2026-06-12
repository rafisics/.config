#!/usr/bin/env bash
# command-route-skill.sh — Resolve task_type to skill_name via extension manifest lookup
#
# USAGE:
#   source .claude/scripts/command-route-skill.sh "$operation" "$TASK_TYPE" "$default_skill" ["$effort_flag"]
#   echo "$SKILL_NAME"  # resolved skill name
#
# PARAMETERS:
#   $1 = operation      : "research" | "plan" | "implement"
#   $2 = task_type      : TASK_TYPE exported by command-gate-in.sh
#                         May be simple ("neovim") or compound ("founder:deck")
#   $3 = default_skill  : fallback if no extension routing found
#                         e.g., "skill-researcher", "skill-planner", "skill-implementer"
#   $4 = effort_flag    : optional; "hard" activates hard-mode routing
#                         If empty or omitted, standard routing applies (backward compatible)
#
# EXPORTS:
#   SKILL_NAME          : resolved skill name (from extension or default)
#
# EDGE CASES:
#   - No extensions loaded: SKILL_NAME = $default_skill
#   - Missing manifest files: skipped silently
#   - Empty routing section: falls back to default
#   - Compound keys (e.g., "founder:deck"): tries exact key first, then base type
#   - effort_flag="hard" with no hard variant: falls back to standard skill with stderr note
#
# NOTE: This script uses source semantics. It must be sourced (not executed) to
#       export SKILL_NAME to the calling shell environment.

_route_operation="$1"
_route_task_type="$2"
_route_default_skill="$3"
_route_effort_flag="${4:-}"

SKILL_NAME=""

# Step 1: Search extension manifests for exact task_type match
for _manifest in .claude/extensions/*/manifest.json; do
  if [ -f "$_manifest" ]; then
    _ext_skill=$(jq -r --arg op "$_route_operation" --arg tt "$_route_task_type" \
      '.routing[$op][$tt] // empty' "$_manifest" 2>/dev/null)
    if [ -n "$_ext_skill" ]; then
      SKILL_NAME="$_ext_skill"
      break
    fi
  fi
done

# Step 2: If compound key (contains ":"), try base type as fallback
if [ -z "$SKILL_NAME" ] && echo "$_route_task_type" | grep -q ":"; then
  _base_type=$(echo "$_route_task_type" | cut -d: -f1)
  for _manifest in .claude/extensions/*/manifest.json; do
    if [ -f "$_manifest" ]; then
      _ext_skill=$(jq -r --arg op "$_route_operation" --arg tt "$_base_type" \
        '.routing[$op][$tt] // empty' "$_manifest" 2>/dev/null)
      if [ -n "$_ext_skill" ]; then
        SKILL_NAME="$_ext_skill"
        break
      fi
    fi
  done
fi

# Step 3: Fall back to default skill if no extension routing found
SKILL_NAME="${SKILL_NAME:-$_route_default_skill}"

# Step 4: Hard-mode routing (when effort_flag="hard")
# If hard mode requested, try routing_hard in extension manifests first,
# then construct candidate by appending -hard to the resolved skill name.
if [ "$_route_effort_flag" = "hard" ]; then
  _hard_skill=""

  # Step 4a: Check routing_hard.$operation.$task_type in each extension manifest
  for _manifest in .claude/extensions/*/manifest.json; do
    if [ -f "$_manifest" ]; then
      _ext_hard_skill=$(jq -r --arg op "$_route_operation" --arg tt "$_route_task_type" \
        '.routing_hard[$op][$tt] // empty' "$_manifest" 2>/dev/null)
      if [ -n "$_ext_hard_skill" ]; then
        _hard_skill="$_ext_hard_skill"
        break
      fi
    fi
  done

  # Step 4b: If compound key and no hard extension skill found, try base type
  if [ -z "$_hard_skill" ] && echo "$_route_task_type" | grep -q ":"; then
    _base_type=$(echo "$_route_task_type" | cut -d: -f1)
    for _manifest in .claude/extensions/*/manifest.json; do
      if [ -f "$_manifest" ]; then
        _ext_hard_skill=$(jq -r --arg op "$_route_operation" --arg tt "$_base_type" \
          '.routing_hard[$op][$tt] // empty' "$_manifest" 2>/dev/null)
        if [ -n "$_ext_hard_skill" ]; then
          _hard_skill="$_ext_hard_skill"
          break
        fi
      fi
    done
  fi

  # Step 4c: If no extension hard variant, construct candidate by appending -hard
  if [ -z "$_hard_skill" ]; then
    _hard_candidate="${SKILL_NAME}-hard"
    if [ -f ".claude/skills/${_hard_candidate}/SKILL.md" ]; then
      _hard_skill="$_hard_candidate"
    else
      echo "[route] No hard variant for ${SKILL_NAME}; using standard skill" >&2
    fi
  fi

  # Use hard skill if found, otherwise keep standard skill
  if [ -n "$_hard_skill" ]; then
    SKILL_NAME="$_hard_skill"
  fi
fi

# Clean up local variables to avoid polluting caller's environment
unset _route_operation _route_task_type _route_default_skill _route_effort_flag
unset _manifest _ext_skill _base_type _hard_skill _hard_candidate _ext_hard_skill

export SKILL_NAME
