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

# ---------------------------------------------------------------------------
# Path resolution
# ---------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
ZOTERO_INDEX="$PROJECT_ROOT/specs/zotero-index.json"

# ---------------------------------------------------------------------------
# Argument parsing
# ---------------------------------------------------------------------------

QUERY=""
LIMIT=10
FORMAT="pretty"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --limit)
      shift
      LIMIT="${1:-10}"
      if ! [[ "$LIMIT" =~ ^[0-9]+$ ]] || [[ "$LIMIT" -lt 1 ]]; then
        echo "zotero-search-index.sh: --limit must be a positive integer" >&2
        exit 1
      fi
      ;;
    --limit=*)
      LIMIT="${1#--limit=}"
      if ! [[ "$LIMIT" =~ ^[0-9]+$ ]] || [[ "$LIMIT" -lt 1 ]]; then
        echo "zotero-search-index.sh: --limit must be a positive integer" >&2
        exit 1
      fi
      ;;
    --format)
      shift
      FORMAT="${1:-pretty}"
      if [[ "$FORMAT" != "json" && "$FORMAT" != "pretty" ]]; then
        echo "zotero-search-index.sh: --format must be 'json' or 'pretty'" >&2
        exit 1
      fi
      ;;
    --format=*)
      FORMAT="${1#--format=}"
      if [[ "$FORMAT" != "json" && "$FORMAT" != "pretty" ]]; then
        echo "zotero-search-index.sh: --format must be 'json' or 'pretty'" >&2
        exit 1
      fi
      ;;
    -h|--help)
      cat << 'USAGE'
Usage: zotero-search-index.sh "query string" [--limit N] [--format json|pretty]

Search the per-repo zotero index using multi-field weighted scoring.
Falls back to full Zotero library search if index is empty or missing.

Arguments:
  "query string"       Search query (required)
  --limit N            Return at most N results (default: 10)
  --format json|pretty Output format (default: pretty)

Exit codes:
  0 - Results returned (may be empty)
  1 - JSON parse error; query string empty
  2 - Index not found AND zot not installed (both paths unavailable)
USAGE
      exit 0
      ;;
    -*)
      echo "zotero-search-index.sh: unknown flag: $1" >&2
      exit 1
      ;;
    *)
      if [[ -z "$QUERY" ]]; then
        QUERY="$1"
      else
        QUERY="$QUERY $1"
      fi
      ;;
  esac
  shift
done

if [[ -z "$QUERY" ]]; then
  echo "zotero-search-index.sh: query string required" >&2
  echo "Usage: zotero-search-index.sh \"query string\" [--limit N] [--format json|pretty]" >&2
  exit 1
fi

# ---------------------------------------------------------------------------
# Query term extraction
# ---------------------------------------------------------------------------

STOP_WORDS="a an the in on at of to for is are was were be been being have has had do does did will would shall should may might can could and or but not with from by as if that this these those it its"

build_terms_array() {
  local query="$1"
  local terms=()
  while IFS= read -r token; do
    [[ "${#token}" -le 3 ]] && continue
    [[ "$token" =~ ^[a-z]+$ ]] || continue
    local is_stop=false
    for stop in $STOP_WORDS; do
      if [[ "$token" == "$stop" ]]; then
        is_stop=true
        break
      fi
    done
    [[ "$is_stop" == "true" ]] && continue
    terms+=("$token")
  done < <(echo "$query" | tr '[:upper:]' '[:lower:]' | tr -s '[:punct:][:space:]' '\n')

  # Build JSON array of unique terms
  local arr='[]'
  local seen=()
  for term in "${terms[@]:-}"; do
    [[ -z "$term" ]] && continue
    local already=false
    for s in "${seen[@]:-}"; do
      [[ "$s" == "$term" ]] && already=true && break
    done
    if [[ "$already" == "false" ]]; then
      seen+=("$term")
      arr="$(echo "$arr" | jq --arg t "$term" '. + [$t]')"
    fi
  done
  echo "$arr"
}

TERMS_ARRAY="$(build_terms_array "$QUERY")"

if [[ "$(echo "$TERMS_ARRAY" | jq 'length')" -eq 0 ]]; then
  echo "zotero-search-index.sh: no meaningful query terms after filtering" >&2
  exit 1
fi

# ---------------------------------------------------------------------------
# Fallback: full Zotero library search if index is empty/missing
# ---------------------------------------------------------------------------

use_fallback=false

if [[ ! -f "$ZOTERO_INDEX" ]]; then
  use_fallback=true
else
  entry_count="$(jq '.entries | length' "$ZOTERO_INDEX" 2>/dev/null || echo "0")"
  if [[ "$entry_count" -eq 0 ]]; then
    use_fallback=true
  fi
fi

if [[ "$use_fallback" == "true" ]]; then
  echo "Note: Per-repo index is empty or missing; showing results from full Zotero library." >&2
  echo "Use /zotero --add KEY to add items to the project index." >&2
  echo "" >&2

  if bash "$SCRIPT_DIR/zotero-read.sh" search "$QUERY" 2>/dev/null; then
    exit 0
  else
    fallback_exit=$?
    if [[ "$fallback_exit" -eq 2 ]]; then
      echo "zotero-search-index.sh: index not found and zot not installed; cannot search" >&2
      exit 2
    fi
    exit "$fallback_exit"
  fi
fi

# ---------------------------------------------------------------------------
# Multi-field weighted scoring via jq
# ---------------------------------------------------------------------------

JQ_SCORE_PROGRAM='
def score_field(text; weight; terms):
  if (text == null or text == "") then 0
  else
    (text | ascii_downcase) as $t |
    reduce terms[] as $term (0;
      if ($t | test($term; "i")) then . + weight else . end
    )
  end;

def score_array(arr; weight; terms):
  if (arr == null or (arr | length) == 0) then 0
  else
    reduce arr[] as $el (0;
      score_field($el; weight; terms) + .
    )
  end;

$terms as $t |
.entries[]? |
  (score_field(.title; 4; $t) +
   score_array(.tags; 3; $t) +
   score_field(.abstract_snippet; 2; $t) +
   score_array(.keywords; 2; $t) +
   score_array(.collections; 1; $t) +
   score_field(.notes_summary; 1; $t)) as $total |
  select($total >= 1) |
  . + {_score: $total}
'

raw_results="$(jq -c \
  --argjson terms "$TERMS_ARRAY" \
  "$JQ_SCORE_PROGRAM" \
  "$ZOTERO_INDEX" 2>/dev/null)"

# Sort by score descending and apply limit
sorted_results="$(echo "$raw_results" | jq -s "sort_by(._score | -.) | .[:${LIMIT}]" 2>/dev/null || echo "[]")"

result_count="$(echo "$sorted_results" | jq 'length')"

# ---------------------------------------------------------------------------
# Output: JSON format
# ---------------------------------------------------------------------------

if [[ "$FORMAT" == "json" ]]; then
  echo "$sorted_results"
  exit 0
fi

# ---------------------------------------------------------------------------
# Output: pretty format
# ---------------------------------------------------------------------------

if [[ "$result_count" -eq 0 ]]; then
  echo "No results found in project index for: $QUERY"
  echo ""
  echo "Try /zotero --search with a broader query, or add items first with /zotero --add KEY"
  exit 0
fi

echo ""
printf "%-5s  %-16s  %-42s  %-6s  %-14s\n" "SCORE" "KEY" "TITLE" "YEAR" "STATUS"
printf "%s\n" "$(printf '%0.s-' {1..90})"

for i in $(seq 0 $((result_count - 1))); do
  row="$(echo "$sorted_results" | jq ".[$i]")"

  score="$(echo "$row" | jq -r '._score')"
  key="$(echo "$row" | jq -r '.zotero_key // ""')"
  cite_key="$(echo "$row" | jq -r '.citation_key // ""')"
  t="$(echo "$row" | jq -r '.title // ""')"
  year="$(echo "$row" | jq -r '.year // "N/A"')"
  has_chunks="$(echo "$row" | jq -r '.has_chunks // false')"
  has_pdf="$(echo "$row" | jq -r '.has_pdf // false')"

  # Availability tag
  if [[ "$has_chunks" == "true" ]]; then
    status="[HAS MARKDOWN]"
  elif [[ "$has_pdf" == "true" ]]; then
    status="[PDF ONLY]"
  else
    status="[NO PDF]"
  fi

  # Truncate title for display
  if [[ "${#t}" -gt 42 ]]; then
    t="${t:0:39}..."
  fi

  printf "%-5s  %-16s  %-42s  %-6s  %-14s\n" \
    "$score" "$key" "$t" "$year" "$status"
  printf "       [%s]\n" "$cite_key"

  # Show abstract snippet if available
  abstract="$(echo "$row" | jq -r '.abstract_snippet // ""')"
  if [[ -n "$abstract" && "$abstract" != "null" ]]; then
    snippet="${abstract:0:100}"
    printf "       %s\n" "$snippet"
  fi
  printf "\n"
done

printf "Found %d result(s) for: %s\n" "$result_count" "$QUERY"
