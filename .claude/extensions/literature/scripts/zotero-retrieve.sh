#!/usr/bin/env bash
# zotero-retrieve.sh - Context injection script for the --zot flag
#
# Category D: Context Injection (implemented)
#
# Usage:
#   zotero-retrieve.sh <description> <task_type>
#
# Arguments:
#   <description>  - Task description string (from skill preflight)
#   <task_type>    - Task type string (e.g., meta, neovim, lean4)
#
# Algorithm:
#   1. Check: specs/zotero-index.json exists and has entries; else exit 0 silently
#   2. Extract query terms from description + task_type (stop-word filtered, length > 3)
#   3. Score each entry: title*4 + tags*3 + abstract_snippet*2 + keywords*2 + collections*1 + notes_summary*1
#   4. Filter: total_score >= 4
#   5. Sort by score descending
#   6. Greedy-select within TOKEN_BUDGET (default: index.token_budget or 8000):
#      - has_chunks=true and chunk_dir exists: read *.md files from chunk_dir sequentially
#      - has_pdf=true but no chunks: emit metadata block + convert suggestion
#      - metadata only: emit available fields block
#   7. Update last_retrieved timestamp (best-effort; non-blocking)
#   8. Emit <zotero-context>...</zotero-context> block (empty string on graceful failure)
#
# stdout: <zotero-context> block or empty string
# stderr: Diagnostic messages only (not surfaced to agent)
#
# Exit codes:
#   0 - Context emitted or gracefully empty (no entries, index missing, no matches)
#   1 - Fatal error (JSON parse failure in index)
#
# Environment variables:
#   TOKEN_BUDGET - Override default (from index.token_budget or 8000)
#
# Dependencies: jq

set -euo pipefail

# --- Constants ---
DEFAULT_TOKEN_BUDGET=8000
MAX_FILES=10
MIN_SCORE=4

# --- Arguments ---
description="${1:-}"
task_type="${2:-}"

# --- Paths ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
INDEX_FILE="$PROJECT_ROOT/specs/zotero-index.json"

# --- Graceful exit if index missing ---
if [ ! -f "$INDEX_FILE" ]; then
  exit 0
fi

# --- Graceful exit if entries empty ---
entry_count=$(jq -r '.entries | length' "$INDEX_FILE" 2>/dev/null || echo "0")
if [ "$entry_count" = "0" ] || [ "$entry_count" = "null" ]; then
  exit 0
fi

# --- Read token_budget from index, fallback to default ---
TOKEN_BUDGET="${TOKEN_BUDGET:-}"
if [ -z "$TOKEN_BUDGET" ]; then
  idx_budget=$(jq -r '.token_budget // empty' "$INDEX_FILE" 2>/dev/null)
  if [[ "$idx_budget" =~ ^[0-9]+$ ]]; then
    TOKEN_BUDGET="$idx_budget"
  else
    TOKEN_BUDGET="$DEFAULT_TOKEN_BUDGET"
  fi
fi

# --- Query term extraction ---
# Graceful exit if no description provided
if [ -z "$description" ]; then
  exit 0
fi

STOP_WORDS="the|a|an|and|or|but|in|on|at|of|to|for|is|are|was|were|be|been|being|have|has|had|do|does|did|will|would|could|should|may|might|can|shall|not|no|with|by|from|as|into|through|during|before|after|above|below|between|out|off|over|under|again|further|then|once|here|there|when|where|why|how|all|both|each|few|more|most|other|some|such|only|own|same|so|than|too|very|just|about|up|its|it|this|that|these|those|what|which|who|whom"

# Extract keywords: tokenize, lowercase, filter stop words, length > 3, strip non-alphanumeric, deduplicate, take top 10
keywords=$(echo "$description $task_type" | \
  tr '[:upper:]' '[:lower:]' | \
  tr -cs '[:alpha:][:digit:]' '\n' | \
  grep -v -E "^($STOP_WORDS)$" | \
  awk 'length > 3' | \
  sed 's/[^a-z0-9]//g' | \
  grep -v '^$' | \
  sort -u | \
  head -10 | \
  tr '\n' ' ' | \
  sed 's/ *$//')

# Graceful exit if no usable keywords
if [ -z "$keywords" ]; then
  exit 0
fi

keywords_json=$(echo "$keywords" | tr ' ' '\n' | jq -R . | jq -s .)

# --- Score all entries ---
scored_entries=$(jq --argjson kw "$keywords_json" '
  .entries | map(
    . as $entry |

    # Helper: score a single text field (count unique query terms appearing, weighted)
    def score_text(text; weight):
      if (text == null or text == "") then 0
      else
        (text | ascii_downcase) as $t |
        ([$kw[] | if ($t | test(.; "i")) then weight else 0 end] | add // 0)
      end;

    # Helper: score an array field (sum score_text for each element)
    def score_arr(arr; weight):
      if (arr == null or (arr | length) == 0) then 0
      else
        ([arr[] | score_text(.; weight)] | add // 0)
      end;

    # Compute weighted total score
    (score_text($entry.title; 4) +
     score_arr($entry.tags; 3) +
     score_text($entry.abstract_snippet; 2) +
     score_arr($entry.keywords; 2) +
     score_arr($entry.collections; 1) +
     score_text($entry.notes_summary; 1)) as $total |

    # Only include entries that meet threshold
    if $total >= 4 then
      . + {"_score": $total}
    else
      empty
    end
  ) | sort_by(-._score)
' "$INDEX_FILE" 2>/dev/null) || {
  echo "zotero-retrieve.sh: JSON parse error in index" >&2
  exit 1
}

# Graceful exit if no entries scored above threshold
if [ -z "$scored_entries" ] || [ "$scored_entries" = "[]" ] || [ "$scored_entries" = "null" ]; then
  exit 0
fi

# --- Greedy selection within token budget ---
output="<zotero-context>\n"
output+="The following Zotero library items were selected as relevant to this task.\n\n"

total_tokens=0
file_count=0
retrieved_keys=()

while IFS= read -r entry_json; do
  if [ "$file_count" -ge "$MAX_FILES" ]; then break; fi

  citation_key=$(echo "$entry_json" | jq -r '.citation_key // ""')
  zotero_key=$(echo "$entry_json" | jq -r '.zotero_key // ""')
  title=$(echo "$entry_json" | jq -r '.title // ""')
  authors=$(echo "$entry_json" | jq -r '[.authors // [] | .[]] | join(", ")')
  year=$(echo "$entry_json" | jq -r '.year // ""')
  abstract=$(echo "$entry_json" | jq -r '.abstract_snippet // ""')
  has_chunks=$(echo "$entry_json" | jq -r '.has_chunks // false')
  has_pdf=$(echo "$entry_json" | jq -r '.has_pdf // false')
  chunk_dir=$(echo "$entry_json" | jq -r '.chunk_dir // ""')
  token_count=$(echo "$entry_json" | jq -r '.token_count // 0')
  entry_score=$(echo "$entry_json" | jq -r '._score // 0')

  # Resolve chunk_dir to absolute path
  abs_chunk_dir=""
  if [ -n "$chunk_dir" ] && [ "$chunk_dir" != "null" ]; then
    if [[ "$chunk_dir" = /* ]]; then
      abs_chunk_dir="$chunk_dir"
    else
      abs_chunk_dir="$PROJECT_ROOT/$chunk_dir"
    fi
  fi

  # Path A: has_chunks=true and chunk directory exists with .md files
  if [ "$has_chunks" = "true" ] && [ -n "$abs_chunk_dir" ] && [ -d "$abs_chunk_dir" ]; then
    chunk_files=()
    while IFS= read -r f; do
      chunk_files+=("$f")
    done < <(find "$abs_chunk_dir" -maxdepth 1 -name "*.md" | sort 2>/dev/null)

    if [ "${#chunk_files[@]}" -gt 0 ]; then
      # Estimate tokens for this entry if token_count field is set
      entry_est_tokens="$token_count"
      if [ "$entry_est_tokens" = "0" ] || [ "$entry_est_tokens" = "null" ]; then
        # Estimate from file sizes
        entry_est_tokens=0
        for cf in "${chunk_files[@]}"; do
          wc=$(wc -w < "$cf" 2>/dev/null || echo "0")
          entry_est_tokens=$((entry_est_tokens + (wc * 13 + 5) / 10))
        done
      fi

      # Check if adding this entry would exceed budget
      # If yes, try partial: read chunks until budget exhausted
      chunk_output=""
      chunk_tokens=0
      chunks_added=0
      for cf in "${chunk_files[@]}"; do
        wc=$(wc -w < "$cf" 2>/dev/null || echo "0")
        est=$((( wc * 13 + 5) / 10))
        if [ $(( total_tokens + chunk_tokens + est )) -gt "$TOKEN_BUDGET" ]; then
          break
        fi
        content=$(cat "$cf" 2>/dev/null || true)
        chunk_output+="$content\n\n"
        chunk_tokens=$((chunk_tokens + est))
        chunks_added=$((chunks_added + 1))
      done

      if [ "$chunks_added" -gt 0 ]; then
        output+="### $title"
        if [ -n "$authors" ] && [ "$authors" != "null" ]; then
          output+=" — $authors"
        fi
        if [ -n "$year" ] && [ "$year" != "null" ] && [ "$year" != "0" ]; then
          output+=" ($year)"
        fi
        output+=" [relevance: $entry_score]\n"
        output+="$chunk_output"
        total_tokens=$((total_tokens + chunk_tokens))
        file_count=$((file_count + 1))
        retrieved_keys+=("$zotero_key")
      fi
      continue
    fi
  fi

  # Path B: has_pdf=true but no chunks — emit metadata block + convert suggestion
  if [ "$has_pdf" = "true" ]; then
    meta_tokens=100  # estimate for metadata block
    if [ $((total_tokens + meta_tokens)) -gt "$TOKEN_BUDGET" ]; then
      continue
    fi
    output+="### $title"
    if [ -n "$authors" ] && [ "$authors" != "null" ]; then
      output+=" — $authors"
    fi
    if [ -n "$year" ] && [ "$year" != "null" ] && [ "$year" != "0" ]; then
      output+=" ($year)"
    fi
    output+=" [relevance: $entry_score, PDF available]\n"
    if [ -n "$abstract" ] && [ "$abstract" != "null" ]; then
      output+="Abstract: $abstract\n"
    fi
    output+="**Note**: PDF available but not yet chunked. Run \`/zotero --convert $zotero_key\` to generate searchable chunks.\n\n"
    total_tokens=$((total_tokens + meta_tokens))
    file_count=$((file_count + 1))
    retrieved_keys+=("$zotero_key")
    continue
  fi

  # Path C: metadata only — emit available fields
  meta_tokens=60  # estimate for metadata-only block
  if [ $((total_tokens + meta_tokens)) -gt "$TOKEN_BUDGET" ]; then
    continue
  fi
  output+="### $title"
  if [ -n "$authors" ] && [ "$authors" != "null" ]; then
    output+=" — $authors"
  fi
  if [ -n "$year" ] && [ "$year" != "null" ] && [ "$year" != "0" ]; then
    output+=" ($year)"
  fi
  output+=" [relevance: $entry_score, metadata only]\n"
  if [ -n "$abstract" ] && [ "$abstract" != "null" ]; then
    output+="Abstract: $abstract\n"
  fi
  output+="\n"
  total_tokens=$((total_tokens + meta_tokens))
  file_count=$((file_count + 1))
  retrieved_keys+=("$zotero_key")

done < <(echo "$scored_entries" | jq -c '.[]')

output+="</zotero-context>"

# Graceful exit if nothing was included
if [ "$file_count" -eq 0 ]; then
  exit 0
fi

# --- Update last_retrieved timestamp (best-effort, non-blocking) ---
if [ "${#retrieved_keys[@]}" -gt 0 ]; then
  now=$(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || true)
  if [ -n "$now" ]; then
    (
      keys_json=$(printf '%s\n' "${retrieved_keys[@]}" | jq -R . | jq -s .)
      jq --argjson keys "$keys_json" --arg ts "$now" '
        .entries = [.entries[] |
          if (.zotero_key as $k | $keys | index($k)) != null then
            .last_retrieved = $ts
          else .
          end
        ]
      ' "$INDEX_FILE" > "${INDEX_FILE}.tmp" && mv "${INDEX_FILE}.tmp" "$INDEX_FILE"
    ) 2>/dev/null || true
  fi
fi

# --- Emit output ---
printf '%b' "$output"
exit 0
