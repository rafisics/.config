#!/usr/bin/env bash
# literature-retrieve.sh - Keyword-based literature injection from specs/literature/
#
# Usage: literature-retrieve.sh <description> <task_type>
#
# When index.json exists: score entries by keyword overlap, greedy-select within budget
# When index.json absent: recursive file scan with token budget enforcement
#
# Exit 0 with content on stdout when files found
# Exit 1 (empty stdout) when directory missing, no matches, or all exceed budget
#
# Constants:
#   TOKEN_BUDGET=4000  - Maximum total tokens to include
#   MAX_FILES=10       - Maximum number of files
#   MIN_SCORE=1        - Minimum keyword overlap to include

set -euo pipefail

# --- Constants ---
TOKEN_BUDGET=4000
MAX_FILES=10
MIN_SCORE=1

# --- Arguments ---
description="${1:-}"
task_type="${2:-}"

# --- Paths ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
LIT_DIR="$PROJECT_ROOT/specs/literature"
INDEX_FILE="$LIT_DIR/index.json"

# Exit if directory missing
if [ ! -d "$LIT_DIR" ]; then
  exit 1
fi

# --- INDEX PATH (when index.json exists and description is non-empty) ---
if [ -f "$INDEX_FILE" ] && [ -n "$description" ]; then

  STOP_WORDS="the|a|an|and|or|but|in|on|at|of|to|for|is|are|was|were|be|been|being|have|has|had|do|does|did|will|would|could|should|may|might|can|shall|not|no|with|by|from|as|into|through|during|before|after|above|below|between|out|off|over|under|again|further|then|once|here|there|when|where|why|how|all|both|each|few|more|most|other|some|such|only|own|same|so|than|too|very|just|about|up|its|it|this|that|these|those|what|which|who|whom"

  keywords=$(echo "$description $task_type" | \
    tr '[:upper:]' '[:lower:]' | \
    tr -cs '[:alpha:]' '\n' | \
    grep -v -E "^($STOP_WORDS)$" | \
    awk 'length > 3' | \
    sort -u | \
    head -10 | \
    tr '\n' ' ' | \
    sed 's/ *$//')

  if [ -z "$keywords" ]; then
    # No usable keywords — fall through to fallback
    :
  else
    keywords_json=$(echo "$keywords" | tr ' ' '\n' | jq -R . | jq -s .)

    scored_entries=$(jq --argjson kw "$keywords_json" '
      .entries // [] |
      map(
        . as $entry |
        ($entry.keywords // []) as $entry_kw |
        ($entry.summary // "") as $entry_sum |
        ([$kw[] | ascii_downcase] | map(
          . as $k |
          if ([$entry_kw[] | ascii_downcase] | index($k)) then 1 else 0 end
        ) | add // 0) as $kw_score |
        ([$kw[] | ascii_downcase] | map(
          . as $k |
          if ($entry_sum | ascii_downcase | test($k)) then 1 else 0 end
        ) | add // 0 | if . > 0 then 1 else 0 end) as $summary_bonus |
        ($kw_score + $summary_bonus) as $total_score |
        {
          id: $entry.id,
          path: $entry.path,
          title: ($entry.title // $entry.id),
          token_count: ($entry.token_count // 0),
          score: $total_score
        }
      ) | map(select(.score >= 1)) | sort_by(-.score)
    ' "$INDEX_FILE" 2>/dev/null)

    if [ -n "$scored_entries" ] && [ "$scored_entries" != "[]" ] && [ "$scored_entries" != "null" ]; then
      selected=$(echo "$scored_entries" | jq --argjson budget "$TOKEN_BUDGET" --argjson max "$MAX_FILES" '
        reduce .[] as $entry (
          {selected: [], total_tokens: 0, count: 0};
          if .count < $max and (.total_tokens + $entry.token_count) <= $budget then
            .selected += [$entry] |
            .total_tokens += $entry.token_count |
            .count += 1
          else .
          end
        ) | .selected
      ')

      if [ -n "$selected" ] && [ "$selected" != "[]" ]; then
        output="<literature-context>\n"
        output+="The following literature files from specs/literature/ are provided for this task.\n\n"

        file_count=0
        while IFS= read -r entry_json; do
          entry_path=$(echo "$entry_json" | jq -r '.path')
          entry_title=$(echo "$entry_json" | jq -r '.title')
          entry_score=$(echo "$entry_json" | jq -r '.score')

          full_path="$LIT_DIR/$entry_path"

          if [ -f "$full_path" ]; then
            content=$(cat "$full_path")
            output+="### $entry_title (relevance: $entry_score)\n"
            output+="$content\n\n"
            file_count=$((file_count + 1))
          fi
        done < <(echo "$selected" | jq -c '.[]')

        output+="</literature-context>"

        if [ "$file_count" -gt 0 ]; then
          printf '%b' "$output"
          exit 0
        fi
      fi
    fi
  fi
fi

# --- FALLBACK PATH (no index.json, no keywords, or no matches) ---
files=()
while IFS= read -r f; do
  files+=("$f")
done < <(find "$LIT_DIR" -type f \( -name "*.md" -o -name "*.txt" \) ! -name "index.json" | sort)

if [ ${#files[@]} -eq 0 ]; then
  exit 1
fi

output="<literature-context>\n"
output+="The following literature files from specs/literature/ are provided for this task.\n\n"

total_tokens=0
file_count=0

for f in "${files[@]}"; do
  if [ "$file_count" -ge "$MAX_FILES" ]; then break; fi
  fname=$(basename "$f")
  word_count=$(wc -w < "$f")
  est_tokens=$(( (word_count * 13 + 5) / 10 ))
  if [ $((total_tokens + est_tokens)) -gt "$TOKEN_BUDGET" ]; then
    continue
  fi
  content=$(cat "$f")
  output+="### $fname\n$content\n\n"
  total_tokens=$((total_tokens + est_tokens))
  file_count=$((file_count + 1))
done

output+="</literature-context>"

if [ "$file_count" -eq 0 ]; then
  exit 1
fi

printf '%b' "$output"
exit 0
