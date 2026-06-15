#!/usr/bin/env bash
# literature-retrieve.sh - Literature context injection for --lit flag
#
# Usage: literature-retrieve.sh <description> <task_type>
#
# Two-tier behavior depending on database availability:
#
#   TIER 1 (FTS5 database present): Emit <literature-tool> context block that
#     instructs the agent to use literature-search.sh for on-demand search.
#     The agent queries, browses metadata, follows cross-refs, reads full
#     content from disk, and decides when to stop. No preflight content injection.
#     Uses: specs/literature/.literature.db OR $LITERATURE_DIR/.literature.db
#
#   TIER 2 (legacy, no database): Fall back to keyword-based content injection
#     from specs/literature/. Score entries by keyword overlap, greedy-select
#     within token budget. Used when no .literature.db exists.
#
# Exit 0 with content on stdout when context produced
# Exit 1 (empty stdout) when directory missing, no matches, or all exceed budget
#
# Environment:
#   LITERATURE_DIR  - Override global library path (default: ~/Projects/Literature)
#                     Two-tier fallback: if set but non-existent, falls back to
#                     per-project specs/literature/
#
# Constants (legacy tier only):
#   TOKEN_BUDGET=8000 (or index.json token_budget)  - Maximum total tokens to include
#   MAX_FILES=10                                     - Maximum number of files
#   MIN_SCORE=1                                      - Minimum keyword overlap to include

set -euo pipefail

# --- Check for FTS5 database (Tier 1 behavior) ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GIT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
GLOBAL_LIT_DIR="${LITERATURE_DIR:-$HOME/Projects/Literature}"
LOCAL_DB="$GIT_ROOT/specs/literature/.literature.db"
GLOBAL_DB="$GLOBAL_LIT_DIR/.literature.db"
SEARCH_SCRIPT="$SCRIPT_DIR/literature-search.sh"

if { [ -f "$LOCAL_DB" ] || [ -f "$GLOBAL_DB" ]; } && [ -x "$SEARCH_SCRIPT" ]; then
  # Tier 1: Emit search tool context block
  DB_LOCATION=""
  if [ -f "$LOCAL_DB" ] && [ -f "$GLOBAL_DB" ]; then
    DB_LOCATION="both local (specs/literature/.literature.db) and global ($GLOBAL_LIT_DIR/.literature.db)"
  elif [ -f "$LOCAL_DB" ]; then
    DB_LOCATION="local (specs/literature/.literature.db)"
  else
    DB_LOCATION="global ($GLOBAL_LIT_DIR/.literature.db)"
  fi

  printf '<literature-tool>\n'
  printf 'Literature is available via on-demand search. Use the literature-search.sh tool\n'
  printf 'to find relevant content instead of reading files directly.\n\n'
  printf 'Database: %s\n\n' "$DB_LOCATION"
  printf 'SEARCH TOOL INTERFACE:\n\n'
  printf '  literature-search.sh "query string"\n'
  printf '    Returns: JSON array of ranked chunks with metadata (no full content).\n'
  printf '    Fields: chunk_id, doc_id, section_path, title, summary, token_count,\n'
  printf '            cross_refs, rank, snippet\n\n'
  printf '  literature-search.sh --read <chunk_id>\n'
  printf '    Returns: Full markdown content of the chunk from disk.\n'
  printf '    Fields: chunk_id, content, token_count, title, section_path\n\n'
  printf '  literature-search.sh --toc [doc_id]\n'
  printf '    Returns: TOC listing (metadata only, no content) for one doc or all docs.\n'
  printf '    Fields: chunk_id, doc_id, section_path, title, summary, token_count, level\n\n'
  printf '  literature-search.sh --refs <chunk_id>\n'
  printf '    Returns: Chunks linked via cross-references from this chunk.\n'
  printf '    Use to navigate: "by Definition 2.1" -> fetch the definition chunk.\n\n'
  printf '  literature-search.sh --next <chunk_id>\n'
  printf '  literature-search.sh --prev <chunk_id>\n'
  printf '    Returns: Next/previous chunk metadata + first paragraph.\n\n'
  printf '  literature-search.sh --doc <doc_id>\n'
  printf '    Returns: All chunks for a specific document.\n\n'
  printf 'AGENT SEARCH PROTOCOL:\n\n'
  printf '1. Initial search: Query for chunks matching the research question.\n'
  printf '2. TOC browse: Call --toc on promising documents to understand structure.\n'
  printf '3. Selective read: Call --read only for chunks likely to be relevant.\n'
  printf '4. Cross-ref follow: When encountering "by Definition 2.1", use --refs.\n'
  printf '5. Sequential navigation: Use --next/--prev for surrounding context.\n'
  printf '6. Budget tracking: Track token_count of chunks read; stop when satisfied.\n\n'
  printf 'STOPPING RULE: If you do not find relevant literature within 3 searches,\n'
  printf 'proceed without it rather than searching exhaustively.\n'
  printf '</literature-tool>\n'
  exit 0
fi

# --- Tier 2: Legacy keyword-based injection (no FTS5 database) ---

# --- Constants ---
TOKEN_BUDGET=8000
MAX_FILES=10
MIN_SCORE=1

# --- Arguments ---
description="${1:-}"
task_type="${2:-}"

# --- Paths ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
DEFAULT_LIT_DIR="$PROJECT_ROOT/specs/literature"

# Two-tier fallback: use LITERATURE_DIR if set and exists, otherwise fall back to per-project
if [ -n "${LITERATURE_DIR:-}" ]; then
  if [ -d "$LITERATURE_DIR" ]; then
    LIT_DIR="$LITERATURE_DIR"
  else
    # LITERATURE_DIR set but does not exist — fall back to per-project
    LIT_DIR="$DEFAULT_LIT_DIR"
  fi
else
  LIT_DIR="$DEFAULT_LIT_DIR"
fi
INDEX_FILE="$LIT_DIR/index.json"

# Exit if directory missing
if [ ! -d "$LIT_DIR" ]; then
  exit 1
fi

# --- INDEX PATH (when index.json exists and description is non-empty) ---
if [ -f "$INDEX_FILE" ] && [ -n "$description" ]; then

  # Read token_budget from index.json, fallback to default
  idx_budget=$(jq -r '.token_budget // empty' "$INDEX_FILE" 2>/dev/null)
  if [[ "$idx_budget" =~ ^[0-9]+$ ]]; then
    TOKEN_BUDGET="$idx_budget"
  fi

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

    # Extract root entries from index.json
    root_entries=$(jq '.entries // []' "$INDEX_FILE" 2>/dev/null)

    # Discover and normalize subdirectory index.json files (one level deep)
    # Map chapters[] format (file field) to entries[] shape (path field) with subdir prefix
    sub_entries='[]'
    while IFS= read -r sub_index; do
      subdir=$(basename "$(dirname "$sub_index")")
      normalized=$(jq --arg subdir "$subdir" '
        .chapters // [] |
        map({
          id: ($subdir + "_" + (.file // .id // "unknown")),
          path: ($subdir + "/" + (.file // "")),
          title: (.title // .file // .id // ""),
          token_count: (.token_count // 0),
          keywords: (.keywords // []),
          summary: (.summary // "")
        }) | map(select(.path != ($subdir + "/")))
      ' "$sub_index" 2>/dev/null)
      if [ -n "$normalized" ] && [ "$normalized" != "null" ] && [ "$normalized" != "[]" ]; then
        _a_tmp=$(mktemp)
        _b_tmp=$(mktemp)
        echo "$sub_entries" > "$_a_tmp"
        echo "$normalized" > "$_b_tmp"
        sub_entries=$(jq -n --slurpfile a "$_a_tmp" --slurpfile b "$_b_tmp" '$a[0] + $b[0]')
        rm -f "$_a_tmp" "$_b_tmp"
      fi
    done < <(find "$LIT_DIR" -maxdepth 2 -name "index.json" ! -path "$INDEX_FILE" | sort)

    # Merge root entries and subdirectory entries; root entries take precedence by path
    # Build a unified deduplicated pool
    # Use temp files to avoid "Argument list too long" when entries JSON is large
    _root_tmp=$(mktemp)
    _sub_tmp=$(mktemp)
    echo "$root_entries" > "$_root_tmp"
    echo "$sub_entries" > "$_sub_tmp"
    all_entries=$(jq -n \
      --slurpfile root "$_root_tmp" \
      --slurpfile sub "$_sub_tmp" '
      ($root[0]) as $root |
      ($sub[0]) as $sub |
      ($root | map({(.path): .}) | add // {}) as $root_by_path |
      ($sub | map(select(.path != null and .path != "")) | map(select($root_by_path[.path] == null))) as $sub_unique |
      $root + $sub_unique
    ')
    rm -f "$_root_tmp" "$_sub_tmp"

    scored_entries=$(echo "$all_entries" | jq --argjson kw "$keywords_json" '
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
    ' 2>/dev/null)

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
