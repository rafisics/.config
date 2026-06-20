---
name: skill-zotero
description: Manage Zotero library integration — per-repo index, PDF chunking, and context injection. Invoke for /zotero command.
allowed-tools: Bash, Read, Write, Edit, AskUserQuestion
---

# Zotero Skill (Direct Execution)

Direct execution skill for managing Zotero library integration. Handles the per-repo
`specs/zotero-index.json`, PDF chunking pipeline, and graceful degradation when `zot` is
not installed or configured.

**Key behavior**: All operations that call `zot` exit with code 2 (not configured) when
the CLI is unavailable, so `--zot` context injection fails silently rather than blocking
agent execution.

## Context References

Reference (do not load eagerly):
- Path: `@specs/zotero-index.json` - Per-repo Zotero index
- Path: `@.claude/context/project/zotero/domain/zotero-index.md` - Index schema reference
- Path: `@.claude/context/project/zotero/patterns/retrieval-flags.md` - --zot vs --lit guide

---

## Execution

### Step 1: Parse Arguments

Extract mode, optional key, and optional query from skill args:

```bash
# Parse from skill args
mode=$(echo "$ARGUMENTS" | grep -oP 'mode=\K\S+' | head -1)
key=$(echo "$ARGUMENTS" | grep -oP 'key=\K\S+' | head -1)
chunk_flag=$(echo "$ARGUMENTS" | grep -oP 'chunk=\K\S+' | head -1)
delete_chunks_flag=$(echo "$ARGUMENTS" | grep -oP 'delete_chunks=\K\S+' | head -1)
task_num=$(echo "$ARGUMENTS" | grep -oP 'task_num=\K\S+' | head -1)

# Extract query: everything after "query=" (supports spaces in query text)
query=$(echo "$ARGUMENTS" | sed 's/.*query=//' | sed 's/^[[:space:]]*//')

# Default to status mode if not specified
if [ -z "$mode" ]; then
  mode="status"
fi
```

### Step 2: Locate Scripts

```bash
# Find scripts relative to extension directory
SCRIPT_DIR=".claude/extensions/zotero/scripts"

zotero_setup_sh="$SCRIPT_DIR/zotero-setup.sh"
zotero_index_add_sh="$SCRIPT_DIR/zotero-index-add.sh"
zotero_index_remove_sh="$SCRIPT_DIR/zotero-index-remove.sh"
zotero_chunk_sh="$SCRIPT_DIR/zotero-chunk.sh"
zotero_attach_sh="$SCRIPT_DIR/zotero-attach-chunks.sh"
zotero_search_sh="$SCRIPT_DIR/zotero-search-index.sh"
zotero_retrieve_sh="$SCRIPT_DIR/zotero-retrieve.sh"
```

### Step 3: Dispatch to Mode Handler

Route to the appropriate mode handler:

```bash
case "$mode" in
  status)         handle_status ;;
  status_verbose) handle_status_verbose ;;
  setup)          handle_setup ;;
  add)            handle_add ;;
  remove)         handle_remove ;;
  convert)        handle_convert ;;
  attach)         handle_attach ;;
  search)         handle_search ;;
  task_search)    handle_task_search ;;
  sync)           handle_sync ;;
  validate)       handle_validate ;;
  *)
    echo "Error: Unknown mode '$mode'. Available: status, setup, add, remove, convert, attach, search, task_search, sync, validate"
    exit 1
    ;;
esac
```

---

## Mode: Status (Default)

Show library connectivity and per-repo index summary.

```bash
handle_status() {
  echo "## Zotero Status"
  echo ""

  # Check if zot is installed
  if ! command -v zot &>/dev/null; then
    echo "**zot**: NOT INSTALLED"
    echo ""
    echo "Install with: pip install zotero-cli-cc"
    echo "Then run: /zotero --setup"
    return
  fi
  echo "**zot**: installed"

  # Check specs/zotero-index.json
  if [ ! -f "specs/zotero-index.json" ]; then
    echo "**Per-repo index**: NOT FOUND"
    echo ""
    echo "Run /zotero --setup to initialize the per-repo index."
    return
  fi

  # Show index summary
  item_count=$(jq '.entries | length' specs/zotero-index.json 2>/dev/null || echo "0")
  chunked_count=$(jq '[.entries[] | select(.has_chunks == true)] | length' specs/zotero-index.json 2>/dev/null || echo "0")
  token_budget=$(jq '.token_budget // 8000' specs/zotero-index.json 2>/dev/null || echo "8000")

  echo "**Per-repo index**: specs/zotero-index.json"
  echo "**Index items**: $item_count"
  echo "**Items with chunks**: $chunked_count"
  echo "**Token budget**: $token_budget"

  # Call zotero-setup.sh --status for library stats
  if [ -x "$zotero_setup_sh" ]; then
    bash "$zotero_setup_sh" --status 2>/dev/null || echo "**Library access**: run /zotero --setup to configure"
  fi
}
```

---

## Mode: Setup

Run the setup wizard.

```bash
handle_setup() {
  if [ ! -x "$zotero_setup_sh" ]; then
    echo "Error: zotero-setup.sh not found at $zotero_setup_sh"
    echo "This script is implemented in task 750."
    exit 2
  fi

  bash "$zotero_setup_sh" --configure
  exit_code=$?
  case $exit_code in
    0) echo "Setup complete. Run /zotero to verify." ;;
    2) echo "zot not installed. Install with: pip install zotero-cli-cc" ;;
    *) echo "Setup encountered an error. Check stderr for details." ;;
  esac
}
```

---

## Mode: Add

Add a Zotero item to the per-repo index.

```bash
handle_add() {
  if [ -z "$key" ]; then
    echo "Error: --add requires a Zotero item KEY"
    exit 1
  fi

  if [ ! -x "$zotero_index_add_sh" ]; then
    echo "Error: zotero-index-add.sh not yet implemented (task 751)"
    exit 2
  fi

  if [ "$chunk_flag" = "true" ]; then
    bash "$zotero_index_add_sh" "$key" --chunk
  else
    bash "$zotero_index_add_sh" "$key"
  fi

  exit_code=$?
  case $exit_code in
    0) echo "Item $key added to specs/zotero-index.json" ;;
    1) echo "Error adding $key. Item may not exist in Zotero library." ;;
    2) echo "Not configured. Run /zotero --setup first." ;;
  esac
}
```

---

## Mode: Remove

Remove a Zotero item from the per-repo index.

```bash
handle_remove() {
  if [ -z "$key" ]; then
    echo "Error: --remove requires a Zotero item KEY"
    exit 1
  fi

  if [ ! -x "$zotero_index_remove_sh" ]; then
    echo "Error: zotero-index-remove.sh not yet implemented (task 751)"
    exit 2
  fi

  if [ "$delete_chunks_flag" = "true" ]; then
    bash "$zotero_index_remove_sh" "$key" --delete-chunks
  else
    bash "$zotero_index_remove_sh" "$key"
  fi

  exit_code=$?
  case $exit_code in
    0) echo "Item $key removed from specs/zotero-index.json" ;;
    1) echo "Error: Item $key not found in index." ;;
    2) echo "Error: specs/zotero-index.json not found. Run /zotero --setup first." ;;
  esac
}
```

---

## Mode: Convert

Extract PDF text and chunk into sections.

```bash
handle_convert() {
  if [ -z "$key" ]; then
    echo "Error: --convert requires a Zotero item KEY"
    exit 1
  fi

  if [ ! -x "$zotero_chunk_sh" ]; then
    echo "Error: zotero-chunk.sh not yet implemented (task 752)"
    exit 2
  fi

  bash "$zotero_chunk_sh" "$key"

  exit_code=$?
  case $exit_code in
    0) echo "PDF chunked successfully. Run /zotero to see updated index." ;;
    1) echo "Error during chunking. Check that item has a PDF and is in the index." ;;
    2) echo "Not configured or item not in index. Run /zotero --add $key first." ;;
  esac
}
```

---

## Mode: Attach

Upload local markdown chunks as Zotero child attachments.

```bash
handle_attach() {
  if [ -z "$key" ]; then
    echo "Error: --attach requires a Zotero item KEY"
    exit 1
  fi

  if [ ! -x "$zotero_attach_sh" ]; then
    echo "Error: zotero-attach-chunks.sh not yet implemented (task 752)"
    exit 2
  fi

  bash "$zotero_attach_sh" "$key"

  exit_code=$?
  case $exit_code in
    0) echo "Chunks uploaded to Zotero." ;;
    1) echo "One or more chunk uploads failed." ;;
    2) echo "Not configured. Set ZOTERO_API_KEY and run /zotero --setup." ;;
  esac
}
```

---

## Mode: Search

Search the per-repo index with full Zotero library fallback.

```bash
handle_search() {
  if [ -z "$query" ]; then
    echo "Error: --search requires a query"
    exit 1
  fi

  if [ ! -x "$zotero_search_sh" ]; then
    echo "Error: zotero-search-index.sh not found"
    exit 2
  fi

  bash "$zotero_search_sh" "$query" --format pretty

  # After displaying results, offer to add items to index
  # (interactive flow via AskUserQuestion — future enhancement)
}
```

---

## Mode: Task Search

Search the per-repo index using a task description extracted from specs/state.json.

```bash
handle_task_search() {
  if [ -z "$task_num" ]; then
    echo "Error: --task requires a task number. Usage: /zotero --task 751"
    exit 1
  fi

  if [ ! -x "$zotero_search_sh" ]; then
    echo "Error: zotero-search-index.sh not found"
    exit 2
  fi

  # Extract task description from specs/state.json
  state_file="specs/state.json"
  if [ ! -f "$state_file" ]; then
    echo "Error: specs/state.json not found"
    exit 1
  fi

  # Try to get description or title from active_projects; fall back to project_name
  desc=$(jq -r --arg n "$task_num" '
    .active_projects[] |
    select(.project_number == ($n | tonumber)) |
    .description // .title // .project_name // ""
  ' "$state_file" 2>/dev/null | head -1)

  if [ -z "$desc" ]; then
    # Try project_name and convert snake_case to spaces
    desc=$(jq -r --arg n "$task_num" '
      .active_projects[] |
      select(.project_number == ($n | tonumber)) |
      .project_name // ""
    ' "$state_file" 2>/dev/null | tr '_' ' ')
  fi

  if [ -z "$desc" ]; then
    echo "Error: Task $task_num not found in specs/state.json"
    echo ""
    echo "Available tasks:"
    jq -r '.active_projects[] | "  \(.project_number): \(.project_name)"' "$state_file" 2>/dev/null || echo "  (could not read state.json)"
    exit 1
  fi

  echo "Searching for task $task_num: $desc"
  echo ""
  bash "$zotero_search_sh" "$desc" --format pretty
}
```

---

## Mode: Sync

Re-fetch metadata for all index entries from current Zotero state.

```bash
handle_sync() {
  if [ ! -f "specs/zotero-index.json" ]; then
    echo "Error: specs/zotero-index.json not found. Run /zotero --setup first."
    exit 2
  fi

  if [ ! -x "$zotero_index_add_sh" ]; then
    echo "Error: zotero-index-add.sh not yet implemented (task 751)"
    exit 2
  fi

  # Re-add each entry to refresh metadata
  keys=$(jq -r '.entries[].zotero_key' specs/zotero-index.json 2>/dev/null || echo "")
  success=0
  failed=0

  while IFS= read -r k; do
    if [ -z "$k" ] || [ "$k" = "null" ]; then continue; fi
    if bash "$zotero_index_add_sh" "$k" 2>/dev/null; then
      success=$((success + 1))
    else
      failed=$((failed + 1))
      echo "Warning: Failed to refresh $k"
    fi
  done <<< "$keys"

  echo "Sync complete: $success refreshed, $failed failed"
}
```

---

## Mode: Validate

Validate index entries for consistency.

```bash
handle_validate() {
  if [ ! -f "specs/zotero-index.json" ]; then
    echo "Error: specs/zotero-index.json not found. Run /zotero --setup first."
    exit 2
  fi

  echo "## Zotero Index Validation"
  echo ""

  broken_pdf=0
  broken_chunks=0
  valid=0

  while IFS= read -r entry; do
    citation_key=$(echo "$entry" | jq -r '.citation_key')
    has_pdf=$(echo "$entry" | jq -r '.has_pdf')
    pdf_path=$(echo "$entry" | jq -r '.pdf_path // ""')
    has_chunks=$(echo "$entry" | jq -r '.has_chunks')
    chunk_dir=$(echo "$entry" | jq -r '.chunk_dir // ""')

    if [ "$has_pdf" = "true" ] && [ -n "$pdf_path" ] && [ "$pdf_path" != "null" ]; then
      if [ ! -f "$pdf_path" ]; then
        echo "**Broken PDF path**: $citation_key -> $pdf_path"
        broken_pdf=$((broken_pdf + 1))
      fi
    fi

    if [ "$has_chunks" = "true" ] && [ -n "$chunk_dir" ] && [ "$chunk_dir" != "null" ]; then
      if [ ! -d "$chunk_dir" ]; then
        echo "**Missing chunk dir**: $citation_key -> $chunk_dir"
        broken_chunks=$((broken_chunks + 1))
      fi
    fi

    valid=$((valid + 1))
  done < <(jq -c '.entries[]' specs/zotero-index.json 2>/dev/null)

  echo ""
  echo "**Total entries**: $valid"
  echo "**Broken PDF paths**: $broken_pdf"
  echo "**Missing chunk dirs**: $broken_chunks"

  if [ "$broken_pdf" -eq 0 ] && [ "$broken_chunks" -eq 0 ]; then
    echo "**Status**: All entries valid"
  fi
}
```

---

## Mode: Status (Verbose)

Full library stats and index health report.

```bash
handle_status_verbose() {
  handle_status  # Show standard status first
  echo ""

  # Show per-entry details
  if [ -f "specs/zotero-index.json" ]; then
    echo "## Index Entries"
    jq -r '.entries[] | "- \(.citation_key) (\(.year // "?")): \(.title[0:60])... [chunks: \(.has_chunks)]"' \
      specs/zotero-index.json 2>/dev/null || echo "(none)"
  fi
}
```

---

## Error Handling

See `rules/error-handling.md` for general patterns. Skill-specific behaviors:

- **zot not installed (exit 2)**: Show install instructions; do not treat as fatal error
- **specs/zotero-index.json missing**: Show setup instructions for add/remove/convert/attach modes
- **Script not found**: Print "not yet implemented (task NNN)" message, exit 2
- **KEY format mismatch**: Warn but pass through to script for validation
- **jq parse failure**: Log and report; do not silently continue with corrupt data
- **ZOTERO_API_KEY not set**: Specific message for attach mode failures

## Standards Reference

- Exit code 2 = "not configured" (zot not installed, ZOT_DATA_DIR not set, index missing)
- Exit code 1 = runtime error (key not found, parse failure, API error)
- Exit code 0 = success
- Scripts are installed to `.claude/extensions/zotero/scripts/` and symlinked to `.claude/scripts/`
- Per-repo index: `specs/zotero-index.json` (committed to repo)
- Chunk storage: `specs/literature/{citation_key}/` (shared with literature extension)
