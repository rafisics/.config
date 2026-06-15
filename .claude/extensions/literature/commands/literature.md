---
description: Manage specs/literature/ — scan, convert PDFs/DJVUs, and maintain index.json
allowed-tools: Skill
argument-hint: [--scan|--convert [FILE]|--validate|--index FILE|--search "QUERY"|--task N]
---

# Command: /literature

**Purpose**: Manages `specs/literature/` by scanning for unprocessed PDFs/DJVUs, converting them to markdown, maintaining `index.json`, validating filesystem consistency, and searching the Zotero library for import.
**Layer**: 2 (Command File - Argument Parsing Agent)
**Delegates To**: skill-literature (direct execution)

**Input**: $ARGUMENTS

---

## Argument Parsing

<argument_parsing>
  <step_1>
    Parse arguments with sub-mode priority:

    **Sub-Mode Dispatch** (first match wins):
    1. No arguments (bare invocation) -> Status mode (health report)
    2. `--scan` -> Scan mode (find unprocessed PDFs/DJVUs)
    3. `--convert` -> Convert mode (convert specific or all unprocessed files)
    4. `--validate` -> Validate mode (check index.json against filesystem)
    5. `--index` -> Index mode (add/update index entry for existing markdown file)
    6. `--search` -> Search mode (search Zotero library and Literature/ index)
    7. `--task` -> Task-search mode (extract task description as Zotero search query)

    **Additional Flags**:
    - `FILE` (after --convert or --index) -> Target file path for the operation
    - `QUERY` (after --search) -> Search query text (everything after --search flag)
    - `N` (after --task) -> Task number to extract description from

    ```
    sub_mode = "status"  # default

    if "--scan" in $ARGUMENTS:
      sub_mode = "scan"
    elif "--convert" in $ARGUMENTS:
      sub_mode = "convert"
      # Extract optional FILE argument (next token after --convert)
      file = extract_arg_after("--convert", $ARGUMENTS) or ""
    elif "--validate" in $ARGUMENTS:
      sub_mode = "validate"
    elif "--index" in $ARGUMENTS:
      sub_mode = "index"
      # Extract required FILE argument (next token after --index)
      file = extract_arg_after("--index", $ARGUMENTS) or ""
    elif "--search" in $ARGUMENTS:
      sub_mode = "search"
      # Extract query text: everything after "--search" flag
      query = extract_text_after("--search", $ARGUMENTS) or ""
    elif "--task" in $ARGUMENTS:
      sub_mode = "search"
      # Extract task number N after "--task"
      task_num = extract_arg_after("--task", $ARGUMENTS) or ""
      # Read task description from specs/state.json via jq
      if task_num != "":
        query = $(jq -r --arg n "$task_num" '.active_projects[] | select(.project_number == ($n | tonumber)) | .project_name' specs/state.json 2>/dev/null)
        # If project_name is just a slug, also try to get description from TODO.md
        # Use task number as fallback query if description not found
        if query == "" or query == "null":
          error: "Error: Task $task_num not found in specs/state.json"
          exit
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

      | Sub-Mode | FILE Required | QUERY Required | Description |
      |----------|--------------|----------------|-------------|
      | status   | No           | No             | Show health report |
      | scan     | No           | No             | Find unprocessed PDFs/DJVUs |
      | convert  | Optional     | No             | Convert specific file or all unprocessed |
      | validate | No           | No             | Check index.json consistency |
      | index    | Yes          | No             | Add/update entry for existing markdown file |
      | search   | No           | Yes (from --search) | Search Zotero + Literature/ index |
      | search   | No           | Yes (from --task N) | Extract task description as search query |

      Validation rules:
      - If sub_mode = "index" AND file = "": Print error, exit without delegating
      - If `--search` flag present AND query = "": Print error, exit without delegating
      - If `--task` flag present AND task_num = "": Print error, exit without delegating
      - If `--task N` AND task not found in state.json: Print error, exit without delegating

      Error messages:
      - --index without FILE: "Error: --index requires a FILE argument. Usage: /literature --index path/to/file.md"
      - --search without QUERY: "Error: --search requires a query. Usage: /literature --search \"modal logic\""
      - --task without N: "Error: --task requires a task number. Usage: /literature --task 714"
      - --task N not found: "Error: Task N not found in specs/state.json"
    </process>
  </step_1>

  <step_2>
    <action>Delegate to Literature Skill</action>
    <input>
      - skill: "skill-literature"
      - args: "mode={sub_mode} file={file}" (for status/scan/convert/validate/index modes)
      - args: "mode=search query={query text}" (for --search and --task N modes)
    </input>
    <expected_return>
      {
        "status": "completed",
        "mode": "{sub_mode}",
        "files_processed": N,
        "index_entries": M,
        "report": "..."
      }
    </expected_return>
  </step_2>

  <step_3>
    <action>Present Results</action>
    <process>
      Status mode:
        - Display processed vs unprocessed file counts
        - Show index.json health summary
        - Show any warnings (missing files, stale entries)
        - Suggest next actions

      Scan mode:
        - List unprocessed PDF/DJVU files with page counts
        - Show tool availability (pdftotext, djvutxt)
        - Suggest: "Run /literature --convert to process all, or /literature --convert FILE for one"

      Convert mode:
        - Display converted file names and token counts
        - Show index.json entries added/updated
        - Report any files skipped (scanned-only PDFs, missing djvutxt)

      Validate mode:
        - List stale entries (path in index.json but file missing)
        - List unindexed files (markdown files not in index.json)
        - Show token count drift warnings (>20% change)
        - Suggest: "Run /literature --index FILE to add unindexed entries"

      Index mode:
        - Confirm entry added/updated in index.json
        - Show keywords and summary used

      Search mode (--search "QUERY" or --task N):
        - Display multi-select results with availability tags
        - Show import progress for selected entries
        - Report any Zotero setup issues gracefully
    </process>
  </step_3>
</workflow_execution>

---

## Error Handling

<error_handling>
  <argument_errors>
    - Unknown flag -> "Unknown flag: {flag}. Available: --scan, --convert [FILE], --validate, --index FILE, --search \"QUERY\", --task N"
    - --index without FILE -> "Error: --index requires a FILE argument. Usage: /literature --index path/to/file.md"
    - --search without QUERY -> "Error: --search requires a query. Usage: /literature --search \"modal logic\""
    - --task without N -> "Error: --task requires a task number. Usage: /literature --task 714"
    - --task N not found -> "Error: Task N not found in specs/state.json. Check the task number and try again."
  </argument_errors>

  <execution_errors>
    - specs/literature/ missing -> "No specs/literature/ directory found. Create it and add PDF/DJVU files to convert."
    - pdftotext not available -> "pdftotext not found. Install with: nix-env -iA nixpkgs.poppler_utils"
    - djvutxt not available -> "djvutxt not found (DJVU files will be skipped). Install with: nix-env -iA nixpkgs.djvulibre"
    - zotero-library.json not found -> Show setup instructions from zotero-search.sh; fall back to index-only search
    - Skill failure -> Return error details
  </execution_errors>
</error_handling>

---

## State Management

<state_management>
  <reads>
    - specs/literature/ (PDF/DJVU source files — gitignored, co-located with markdown)
    - specs/literature/ (markdown conversion files)
    - specs/literature/index.json (current index state)
    - specs/state.json (for --task N mode: read task description)
    - $LITERATURE_DIR/zotero-library.json (via zotero-search.sh, for --search and --task modes)
  </reads>

  <writes>
    - specs/literature/*.md (flat document conversions)
    - specs/literature/{docname}/sectionNN_{slug}.md (content-aware chunked sections)
    - specs/literature/{docname}/{docname}_partNN.md (mechanical fallback chunks)
    - specs/literature/index.json (index entries with enriched schema: authors, title, year, doc_type, source_format, parent_doc, page_range)
    - $LITERATURE_DIR/pdfs/{citation_key}.pdf (symlink to Zotero PDF, for import)
    - $LITERATURE_DIR/index.json (Zotero metadata fields: bib_key, zotero_key, zotero_path, project_tags)
  </writes>

  <source_file_convention>
    Source PDFs/DJVUs are placed in the same directory as their converted markdown.
    Gitignore patterns `specs/literature/**/*.pdf` and `specs/literature/**/*.djvu` prevent
    committing source files. Users re-add source files manually after checkout.
  </source_file_convention>
</state_management>
