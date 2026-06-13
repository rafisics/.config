#!/usr/bin/env bash
# literature-retrieve.sh - Inject specs/literature/ files as <literature-context> block
#
# Usage: literature-retrieve.sh <description> <task_type>
#
# Exit 0 with content on stdout when files found
# Exit 1 (empty stdout) when directory missing or empty
#
# Constants:
#   TOKEN_BUDGET=4000  - Maximum total tokens to include
#   MAX_FILES=10       - Maximum number of files

set -euo pipefail

TOKEN_BUDGET=4000
MAX_FILES=10

description="${1:-}"
task_type="${2:-}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
LIT_DIR="$PROJECT_ROOT/specs/literature"

# Silently skip if directory doesn't exist
if [ ! -d "$LIT_DIR" ]; then
  exit 1
fi

# Find readable files
files=()
while IFS= read -r f; do
  files+=("$f")
done < <(find "$LIT_DIR" -maxdepth 1 -type f \( -name "*.md" -o -name "*.txt" \) | sort)

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
  est_tokens=$(awk "BEGIN { printf \"%d\", $word_count * 1.3 }")
  if [ $((total_tokens + est_tokens)) -gt "$TOKEN_BUDGET" ]; then
    output+="### [Truncated: $fname exceeds budget]\n\n"
    break
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
