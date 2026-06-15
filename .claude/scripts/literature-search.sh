#!/usr/bin/env bash
# literature-search.sh - Agent-callable FTS5 search tool for literature retrieval
#
# Usage:
#   literature-search.sh "query"             # FTS5 search, returns ranked metadata JSON
#   literature-search.sh --read <chunk_id>   # Read full chunk content from disk
#   literature-search.sh --toc [doc_id]      # Browse TOC (metadata only, no content)
#   literature-search.sh --refs <chunk_id>   # Follow cross-references from chunk
#   literature-search.sh --next <chunk_id>   # Next chunk in sequence (metadata + first paragraph)
#   literature-search.sh --prev <chunk_id>   # Previous chunk in sequence (metadata + first paragraph)
#   literature-search.sh --doc <doc_id>      # List all chunks for a document
#
# Output: JSON to stdout. Errors as {"error": "...", "code": N} to stdout, exit non-zero.
#
# Two-tier search: queries local specs/literature/.literature.db first,
# then global ~/Projects/Literature/.literature.db. Local results take
# precedence on duplicate doc_id. Results merged and re-ranked by BM25.
#
# Query sanitization: strips FTS5 operators (AND/OR/NOT at word boundaries,
# unbalanced quotes/parens). Allows "quoted phrases". Escapes apostrophes.
#
# Environment:
#   LITERATURE_DIR  — Global library path (default: ~/Projects/Literature)
#   LITERATURE_LIMIT — Default result limit (default: 20)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LITERATURE_DIR="${LITERATURE_DIR:-$HOME/Projects/Literature}"
LITERATURE_LIMIT="${LITERATURE_LIMIT:-20}"

# --- Error output ---
error_json() {
  local msg="$1"
  local code="${2:-1}"
  printf '{"error": %s, "code": %d}\n' "$(printf '%s' "$msg" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()))')" "$code"
  exit "$code"
}

# --- Find databases ---
find_databases() {
  local git_root
  git_root=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
  local local_db="$git_root/specs/literature/.literature.db"
  local global_db="$LITERATURE_DIR/.literature.db"

  # Return: local_db (may be empty if not found), global_db (may be empty if not found)
  echo "${local_db}:${global_db}"
}

# --- Query sanitization ---
sanitize_query() {
  local query="$1"

  python3 << PYEOF
import re
import sys

query = "$query"

# Escape shell substitution issues - get query from variable
import os
query = os.environ.get('_SEARCH_QUERY', query)

# Remove bare FTS5 operators at word boundaries (case-insensitive)
# Allow "quoted phrases" by preserving balanced double-quote pairs
query = re.sub(r'\bAND\b', ' ', query, flags=re.IGNORECASE)
query = re.sub(r'\bOR\b', ' ', query, flags=re.IGNORECASE)
query = re.sub(r'\bNOT\b', ' ', query, flags=re.IGNORECASE)

# Remove unanchored wildcards (keep * inside "..." quotes)
# Simple approach: strip * not inside double quotes
in_quote = False
chars = []
for c in query:
    if c == '"':
        in_quote = not in_quote
    if c == '*' and not in_quote:
        chars.append(' ')
    else:
        chars.append(c)
query = ''.join(chars)

# Balance double quotes: if odd number, strip all quotes
quote_count = query.count('"')
if quote_count % 2 != 0:
    query = query.replace('"', ' ')

# Balance parentheses: if unbalanced, strip all parens
open_count = query.count('(')
close_count = query.count(')')
if open_count != close_count:
    query = query.replace('(', ' ').replace(')', ' ')

# Strip apostrophes/single quotes from FTS5 query
# FTS5 does not accept SQL-escaped '' in query strings
# The porter+unicode61 tokenizer strips apostrophes during indexing anyway
query = query.replace("'", '')

# Normalize whitespace
query = ' '.join(query.split())

print(query)
PYEOF
}

# --- Main search function ---
do_search() {
  local query="$1"
  local limit="${2:-$LITERATURE_LIMIT}"

  export _SEARCH_QUERY="$query"
  local sanitized
  sanitized=$(sanitize_query "$query")
  unset _SEARCH_QUERY

  if [ -z "$sanitized" ]; then
    error_json "Query is empty after sanitization" 1
  fi

  local db_paths
  db_paths=$(find_databases)
  local local_db="${db_paths%%:*}"
  local global_db="${db_paths##*:}"

  python3 << PYEOF
import sqlite3
import json
import os
import sys

local_db = "$local_db"
global_db = "$global_db"
query = "$sanitized"
limit = $limit

def search_db(db_path, query, limit):
    """Search a single database, return list of result dicts"""
    if not os.path.isfile(db_path):
        return []

    try:
        conn = sqlite3.connect(db_path)
        conn.row_factory = sqlite3.Row

        sql = """
            SELECT d.chunk_id, d.doc_id, d.section_path, d.title, d.summary,
                   d.token_count, d.cross_refs, d.source_path,
                   d.prev_chunk_id, d.next_chunk_id,
                   bm25(chunks_fts, 10, 5, 3, 1) AS rank,
                   substr(d.content, 1, 200) AS snippet
            FROM chunks_fts
            JOIN chunks_data d ON d.id = chunks_fts.rowid
            WHERE chunks_fts MATCH ?
            ORDER BY rank
            LIMIT ?
        """

        try:
            cursor = conn.execute(sql, (query, limit))
            rows = cursor.fetchall()
        except sqlite3.OperationalError as e:
            print(f"[search] Query error: {e}", file=sys.stderr)
            conn.close()
            return []

        results = []
        for row in rows:
            cross_refs = row['cross_refs'] or '[]'
            try:
                cross_refs = json.loads(cross_refs)
            except (json.JSONDecodeError, TypeError):
                cross_refs = []

            results.append({
                'chunk_id': row['chunk_id'],
                'doc_id': row['doc_id'],
                'section_path': row['section_path'],
                'title': row['title'],
                'summary': row['summary'],
                'token_count': row['token_count'],
                'cross_refs': cross_refs,
                'rank': row['rank'],
                'snippet': (row['snippet'] or '').strip()[:200],
                '_source_path': row['source_path'],
                '_db_path': db_path,
            })

        conn.close()
        return results
    except Exception as e:
        print(f"[search] Database error ({db_path}): {e}", file=sys.stderr)
        return []

# Search local then global
local_results = search_db(local_db, query, limit)
global_results = search_db(global_db, query, limit)

# Merge: local takes precedence on duplicate doc_id
local_doc_ids = {r['doc_id'] for r in local_results}
merged = local_results + [r for r in global_results if r['doc_id'] not in local_doc_ids]

# Re-sort by rank (BM25 returns negative values; lower is better)
merged.sort(key=lambda r: r['rank'])
merged = merged[:limit]

# Remove internal fields from output
for r in merged:
    r.pop('_source_path', None)
    r.pop('_db_path', None)

print(json.dumps(merged, indent=2, ensure_ascii=False))
PYEOF
}

# --- Read chunk ---
do_read() {
  local chunk_id="$1"

  local db_paths
  db_paths=$(find_databases)
  local local_db="${db_paths%%:*}"
  local global_db="${db_paths##*:}"

  python3 << PYEOF
import sqlite3
import json
import os
import sys

local_db = "$local_db"
global_db = "$global_db"
chunk_id = "$chunk_id"

def find_chunk(db_path, chunk_id):
    if not os.path.isfile(db_path):
        return None
    try:
        conn = sqlite3.connect(db_path)
        conn.row_factory = sqlite3.Row
        cursor = conn.execute(
            "SELECT * FROM chunks_data WHERE chunk_id=?", (chunk_id,)
        )
        row = cursor.fetchone()
        conn.close()
        if row:
            return dict(row), db_path
    except Exception:
        pass
    return None

# Try local first, then global
result = find_chunk(local_db, chunk_id) or find_chunk(global_db, chunk_id)

if not result:
    print(json.dumps({"error": f"Chunk not found: {chunk_id}", "code": 404}))
    sys.exit(1)

chunk_row, db_path = result
source_path = chunk_row.get('source_path', '')
db_dir = os.path.dirname(db_path)

# Resolve the chunk file path
chunk_file = os.path.join(db_dir, source_path)

# Also try checking if this is a nested path (chunks in subdirectory)
if not os.path.isfile(chunk_file):
    # Try finding the file under the db directory
    chunk_file_basename = os.path.basename(source_path)
    doc_id = chunk_row.get('doc_id', '')
    alt_path = os.path.join(db_dir, doc_id, chunk_file_basename)
    if os.path.isfile(alt_path):
        chunk_file = alt_path

content = ''
if os.path.isfile(chunk_file):
    try:
        with open(chunk_file, encoding='utf-8', errors='replace') as f:
            content = f.read()
    except IOError as e:
        content = f"[Error reading file: {e}]"
else:
    content = f"[Chunk file not found: {chunk_file}]"

cross_refs = chunk_row.get('cross_refs', '[]')
try:
    cross_refs = json.loads(cross_refs)
except Exception:
    cross_refs = []

output = {
    'chunk_id': chunk_id,
    'doc_id': chunk_row.get('doc_id', ''),
    'title': chunk_row.get('title', ''),
    'section_path': chunk_row.get('section_path', ''),
    'token_count': chunk_row.get('token_count', 0),
    'cross_refs': cross_refs,
    'content': content,
}

print(json.dumps(output, indent=2, ensure_ascii=False))
PYEOF
}

# --- TOC listing ---
do_toc() {
  local doc_id="${1:-}"

  local db_paths
  db_paths=$(find_databases)
  local local_db="${db_paths%%:*}"
  local global_db="${db_paths##*:}"

  python3 << PYEOF
import sqlite3
import json
import os
import sys

local_db = "$local_db"
global_db = "$global_db"
doc_id_filter = "$doc_id"

def get_toc(db_path, doc_id_filter):
    if not os.path.isfile(db_path):
        return []
    try:
        conn = sqlite3.connect(db_path)
        conn.row_factory = sqlite3.Row
        if doc_id_filter:
            sql = """SELECT chunk_id, doc_id, section_path, title, summary, token_count, level
                     FROM chunks_data WHERE doc_id=?
                     ORDER BY id"""
            cursor = conn.execute(sql, (doc_id_filter,))
        else:
            sql = """SELECT chunk_id, doc_id, section_path, title, summary, token_count, level
                     FROM chunks_data
                     ORDER BY doc_id, id"""
            cursor = conn.execute(sql)
        rows = [dict(r) for r in cursor.fetchall()]
        conn.close()
        return rows
    except Exception as e:
        print(f"[search] TOC error ({db_path}): {e}", file=sys.stderr)
        return []

# Get from local first, then global (local takes precedence)
local_results = get_toc(local_db, doc_id_filter)
global_results = get_toc(global_db, doc_id_filter)

# Merge (local wins on duplicate doc_id)
local_doc_ids = {r['doc_id'] for r in local_results}
merged = local_results + [r for r in global_results if r['doc_id'] not in local_doc_ids]

print(json.dumps(merged, indent=2, ensure_ascii=False))
PYEOF
}

# --- Cross-reference lookup ---
do_refs() {
  local chunk_id="$1"

  local db_paths
  db_paths=$(find_databases)
  local local_db="${db_paths%%:*}"
  local global_db="${db_paths##*:}"

  python3 << PYEOF
import sqlite3
import json
import os
import sys

local_db = "$local_db"
global_db = "$global_db"
chunk_id = "$chunk_id"

def get_refs(db_path, chunk_id):
    if not os.path.isfile(db_path):
        return []
    try:
        conn = sqlite3.connect(db_path)
        conn.row_factory = sqlite3.Row
        # Get all chunks linked from this chunk via chunk_relations
        sql = """
            SELECT d.chunk_id, d.doc_id, d.section_path, d.title, d.summary,
                   d.token_count, r.relation_type, r.weight
            FROM chunk_relations r
            JOIN chunks_data d ON d.chunk_id = r.to_chunk_id
            WHERE r.from_chunk_id = ?
            ORDER BY r.relation_type, d.id
        """
        cursor = conn.execute(sql, (chunk_id,))
        rows = [dict(r) for r in cursor.fetchall()]
        conn.close()
        return rows
    except Exception as e:
        print(f"[search] Refs error ({db_path}): {e}", file=sys.stderr)
        return []

local_results = get_refs(local_db, chunk_id)
global_results = get_refs(global_db, chunk_id)

# Merge (local wins)
seen = {r['chunk_id'] for r in local_results}
merged = local_results + [r for r in global_results if r['chunk_id'] not in seen]

print(json.dumps(merged, indent=2, ensure_ascii=False))
PYEOF
}

# --- Next/Prev navigation ---
do_navigate() {
  local direction="$1"  # 'next' or 'prev'
  local chunk_id="$2"

  local db_paths
  db_paths=$(find_databases)
  local local_db="${db_paths%%:*}"
  local global_db="${db_paths##*:}"

  python3 << PYEOF
import sqlite3
import json
import os
import sys

local_db = "$local_db"
global_db = "$global_db"
chunk_id = "$chunk_id"
direction = "$direction"

def get_adjacent(db_path, chunk_id, direction):
    if not os.path.isfile(db_path):
        return None
    try:
        conn = sqlite3.connect(db_path)
        conn.row_factory = sqlite3.Row

        # Get the adjacent chunk_id
        field = 'next_chunk_id' if direction == 'next' else 'prev_chunk_id'
        cursor = conn.execute(f"SELECT {field} FROM chunks_data WHERE chunk_id=?", (chunk_id,))
        row = cursor.fetchone()
        if not row or not row[0]:
            conn.close()
            return None

        adj_id = row[0]
        cursor = conn.execute(
            "SELECT chunk_id, doc_id, section_path, title, summary, token_count, content FROM chunks_data WHERE chunk_id=?",
            (adj_id,)
        )
        adj_row = cursor.fetchone()
        conn.close()

        if adj_row:
            # First paragraph of content
            content = adj_row['content'] or ''
            paragraphs = [p.strip() for p in content.split('\n\n') if p.strip()]
            first_para = paragraphs[0] if paragraphs else content[:200]

            return {
                'chunk_id': adj_row['chunk_id'],
                'doc_id': adj_row['doc_id'],
                'section_path': adj_row['section_path'],
                'title': adj_row['title'],
                'summary': adj_row['summary'],
                'token_count': adj_row['token_count'],
                'first_paragraph': first_para[:500],
            }
    except Exception as e:
        print(f"[search] Navigate error ({db_path}): {e}", file=sys.stderr)
    return None

result = get_adjacent(local_db, chunk_id, direction) or get_adjacent(global_db, chunk_id, direction)

if result:
    print(json.dumps(result, indent=2, ensure_ascii=False))
else:
    print(json.dumps({"error": f"No {direction} chunk for: {chunk_id}", "code": 404}))
    sys.exit(1)
PYEOF
}

# --- Main dispatch ---
if [ $# -eq 0 ]; then
  error_json "No arguments provided. Usage: literature-search.sh \"query\" | --read <id> | --toc [doc_id] | --refs <id> | --next <id> | --prev <id> | --doc <doc_id>" 1
fi

case "$1" in
  --read)
    if [ -z "${2:-}" ]; then
      error_json "Missing chunk_id for --read" 1
    fi
    do_read "$2"
    ;;
  --toc)
    do_toc "${2:-}"
    ;;
  --refs)
    if [ -z "${2:-}" ]; then
      error_json "Missing chunk_id for --refs" 1
    fi
    do_refs "$2"
    ;;
  --next)
    if [ -z "${2:-}" ]; then
      error_json "Missing chunk_id for --next" 1
    fi
    do_navigate "next" "$2"
    ;;
  --prev)
    if [ -z "${2:-}" ]; then
      error_json "Missing chunk_id for --prev" 1
    fi
    do_navigate "prev" "$2"
    ;;
  --doc)
    if [ -z "${2:-}" ]; then
      error_json "Missing doc_id for --doc" 1
    fi
    do_toc "$2"
    ;;
  -*)
    error_json "Unknown flag: $1. Use --read, --toc, --refs, --next, --prev, --doc, or a search query string." 1
    ;;
  *)
    # Default: full-text search
    do_search "$1" "${2:-$LITERATURE_LIMIT}"
    ;;
esac
