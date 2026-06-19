---
description: Manage Zotero library integration — add items, search, convert PDFs, and inject context with --zot flag
allowed-tools: Skill
argument-hint: [--setup|--add KEY [--chunk]|--remove KEY [--delete-chunks]|--convert KEY|--attach KEY|--search "QUERY"|--sync|--validate|--status]
---

# Command: /zotero

**Purpose**: Manages the Zotero library integration via a curated per-repo `specs/zotero-index.json`. Dispatches to skill-zotero for all operations.
**Layer**: 2 (Command File - Argument Parsing Agent)
**Delegates To**: skill-zotero (direct execution)

**Input**: $ARGUMENTS

---

## Argument Parsing

<argument_parsing>
  <step_1>
    Parse arguments with sub-mode priority:

    **Sub-Mode Dispatch** (first match wins):
    1. No arguments (bare invocation) -> Status mode (show connectivity + index summary)
    2. `--setup` -> Setup mode (run setup wizard)
    3. `--add KEY` -> Add mode (add item to per-repo index)
    4. `--remove KEY` -> Remove mode (remove item from per-repo index)
    5. `--convert KEY` -> Convert mode (extract PDF and chunk)
    6. `--attach KEY` -> Attach mode (upload chunks as Zotero attachments)
    7. `--search QUERY` -> Search mode (search index with Zotero fallback)
    8. `--sync` -> Sync mode (re-fetch all index entries from Zotero)
    9. `--validate` -> Validate mode (check index entry integrity)
    10. `--status` -> Status mode (full stats report, verbose)

    **Additional Flags**:
    - `KEY` (after --add, --remove, --convert, --attach) -> 8-char Zotero item key
    - `--chunk` (after --add KEY) -> Also chunk PDF after adding
    - `--delete-chunks` (after --remove KEY) -> Also delete chunk files
    - `QUERY` (after --search) -> Search query text (everything after --search flag)

    ```
    sub_mode = "status"  # default for bare invocation

    if "--setup" in $ARGUMENTS:
      sub_mode = "setup"
    elif "--add" in $ARGUMENTS:
      sub_mode = "add"
      key = extract_arg_after("--add", $ARGUMENTS) or ""
      chunk_flag = "--chunk" in $ARGUMENTS
    elif "--remove" in $ARGUMENTS:
      sub_mode = "remove"
      key = extract_arg_after("--remove", $ARGUMENTS) or ""
      delete_chunks_flag = "--delete-chunks" in $ARGUMENTS
    elif "--convert" in $ARGUMENTS:
      sub_mode = "convert"
      key = extract_arg_after("--convert", $ARGUMENTS) or ""
    elif "--attach" in $ARGUMENTS:
      sub_mode = "attach"
      key = extract_arg_after("--attach", $ARGUMENTS) or ""
    elif "--search" in $ARGUMENTS:
      sub_mode = "search"
      query = extract_text_after("--search", $ARGUMENTS) or ""
    elif "--sync" in $ARGUMENTS:
      sub_mode = "sync"
    elif "--validate" in $ARGUMENTS:
      sub_mode = "validate"
    elif "--status" in $ARGUMENTS:
      sub_mode = "status_verbose"
    ```
  </step_1>
</argument_parsing>

---

## Workflow Execution

<workflow_execution>
  <step_1>
    <action>Validate Sub-Mode and Arguments</action>
    <process>
      Check if the requested sub-mode has required arguments:

      | Sub-Mode | KEY Required | QUERY Required | Description |
      |----------|-------------|----------------|-------------|
      | status   | No          | No             | Show connectivity + index summary |
      | setup    | No          | No             | Run setup wizard |
      | add      | Yes         | No             | Add item to per-repo index |
      | remove   | Yes         | No             | Remove item from per-repo index |
      | convert  | Yes         | No             | Extract PDF and chunk |
      | attach   | Yes         | No             | Upload chunks as attachments |
      | search   | No          | Yes            | Search index with fallback |
      | sync     | No          | No             | Re-fetch all entries |
      | validate | No          | No             | Check index integrity |
      | status_verbose | No   | No             | Full stats report |

      Validation rules:
      - If sub_mode in ["add", "remove", "convert", "attach"] AND key = "": Print error, exit
      - If sub_mode = "search" AND query = "": Print error, exit
      - KEY format: 8 alphanumeric characters (warn but do not block if format mismatch)

      Error messages:
      - --add without KEY: "Error: --add requires a Zotero item KEY. Usage: /zotero --add Z7T6Q25X"
      - --remove without KEY: "Error: --remove requires a Zotero item KEY. Usage: /zotero --remove Z7T6Q25X"
      - --convert without KEY: "Error: --convert requires a Zotero item KEY. Usage: /zotero --convert Z7T6Q25X"
      - --attach without KEY: "Error: --attach requires a Zotero item KEY. Usage: /zotero --attach Z7T6Q25X"
      - --search without QUERY: "Error: --search requires a query. Usage: /zotero --search \"modal logic\""
    </process>
  </step_1>

  <step_2>
    <action>Delegate to Zotero Skill</action>
    <input>
      - skill: "skill-zotero"
      - args: "mode={sub_mode} key={key} chunk={chunk_flag} delete_chunks={delete_chunks_flag}"
      - args: "mode=search query={query text}" (for --search mode)
    </input>
    <expected_return>
      {
        "status": "completed",
        "mode": "{sub_mode}",
        "items_processed": N,
        "report": "..."
      }
    </expected_return>
  </step_2>

  <step_3>
    <action>Present Results</action>
    <process>
      Status/status_verbose mode:
        - Display library connectivity (zot installed, ZOT_DATA_DIR, zotero.sqlite found)
        - Show per-repo index: item count, items with chunks, token budget
        - List recently added items (last 5)
        - Suggest next actions based on state

      Setup mode:
        - Display detected ZOT_DATA_DIR
        - Show validation results (zot installed, SQLite accessible)
        - Confirm specs/zotero-index.json created
        - Print instructions for ZOTERO_API_KEY if needed for --attach

      Add mode:
        - Confirm item added: title, citation_key, authors, year
        - Show PDF availability (has_pdf true/false)
        - If --chunk was passed: show chunk count and storage path
        - Suggest next: /zotero --convert KEY (if has_pdf and not chunked)

      Remove mode:
        - Confirm item removed by title and citation_key
        - If --delete-chunks: confirm chunk directory deleted

      Convert mode:
        - Show chunking progress: N chunks created
        - Display chunk directory path
        - Show token count estimate
        - Suggest: /zotero --attach KEY (to sync chunks to Zotero)

      Attach mode:
        - Show per-chunk upload results (N succeeded, M failed)
        - Report any API errors

      Search mode:
        - Display scored results from per-repo index
        - If index empty: show full library fallback results with notice
        - Offer to add selected items to index via AskUserQuestion

      Sync mode:
        - Report per-entry refresh results
        - Show success count and any failures

      Validate mode:
        - List entries with broken PDF paths
        - List entries with missing chunk directories
        - Show entries where chunk_count != actual files
        - Suggest remediation actions
    </process>
  </step_3>
</workflow_execution>

---

## Error Handling

<error_handling>
  <argument_errors>
    - Unknown flag -> "Unknown flag: {flag}. Usage: /zotero [--setup|--add KEY [--chunk]|--remove KEY [--delete-chunks]|--convert KEY|--attach KEY|--search \"QUERY\"|--sync|--validate|--status]"
    - --add/remove/convert/attach without KEY -> mode-specific error with usage example
    - --search without QUERY -> "Error: --search requires a query. Usage: /zotero --search \"modal logic\""
  </argument_errors>

  <execution_errors>
    - zot not installed (exit 2) -> "zot not installed. Install with: pip install zotero-cli-cc"
    - ZOT_DATA_DIR not set (exit 2) -> "ZOT_DATA_DIR not configured. Run /zotero --setup to configure."
    - specs/zotero-index.json missing (exit 2) -> "Per-repo index not found. Run /zotero --setup to initialize."
    - Item KEY not found in Zotero -> "Item {KEY} not found in Zotero library. Try /zotero --search to find the correct key."
    - ZOTERO_API_KEY not set (exit 2) -> "ZOTERO_API_KEY not set. Set it in your shell profile or run /zotero --setup."
    - Script exit 2 (not configured) -> Show graceful degradation message; do not report as error
    - Skill failure -> Return error details from skill
  </execution_errors>
</error_handling>

---

## State Management

<state_management>
  <reads>
    - specs/zotero-index.json (per-repo index: items, metadata, chunk paths)
    - ~/Documents/Zotero/zotero.sqlite (via zot CLI — read-only, no direct SQLite access)
    - specs/literature/{citation_key}/ (chunk directories, for validate mode)
  </reads>

  <writes>
    - specs/zotero-index.json (add/remove/sync/convert modes update entries)
    - specs/literature/{citation_key}/*.md (convert mode creates chunk files)
  </writes>

  <graceful_degradation>
    All modes degrade gracefully when zot is not installed or ZOT_DATA_DIR is not set:
    - Scripts exit 2 (not configured) instead of 1 (error)
    - Status mode shows setup instructions instead of failing
    - --zot flag emits empty context instead of blocking agent execution
  </graceful_degradation>
</state_management>
