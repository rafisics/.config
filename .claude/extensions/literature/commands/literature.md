---
description: Manage specs/literature/ — scan, convert PDFs/DJVUs, and maintain index.json
allowed-tools: Skill
argument-hint: [--scan|--convert [FILE]|--validate|--index FILE]
---

# Command: /literature

**Purpose**: Manages `specs/literature/` by scanning for unprocessed PDFs/DJVUs, converting them to markdown, maintaining `index.json`, and validating filesystem consistency.
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

    **Additional Flags**:
    - `FILE` (after --convert or --index) -> Target file path for the operation

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

      | Sub-Mode | FILE Required | Description |
      |----------|--------------|-------------|
      | status   | No           | Show health report |
      | scan     | No           | Find unprocessed PDFs/DJVUs |
      | convert  | Optional     | Convert specific file or all unprocessed |
      | validate | No           | Check index.json consistency |
      | index    | Yes          | Add/update entry for existing markdown file |

      If sub_mode = "index" AND file = "":
        Print: "Error: --index requires a FILE argument. Usage: /literature --index path/to/file.md"
        Exit without delegating.
    </process>
  </step_1>

  <step_2>
    <action>Delegate to Literature Skill</action>
    <input>
      - skill: "skill-literature"
      - args: "mode={sub_mode} file={file}"
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
    </process>
  </step_3>
</workflow_execution>

---

## Error Handling

<error_handling>
  <argument_errors>
    - Unknown flag -> "Unknown flag: {flag}. Available: --scan, --convert [FILE], --validate, --index FILE"
    - --index without FILE -> "Error: --index requires a FILE argument. Usage: /literature --index path/to/file.md"
  </argument_errors>

  <execution_errors>
    - specs/literature/ missing -> "No specs/literature/ directory found. Create it and add PDF/DJVU files to convert."
    - pdftotext not available -> "pdftotext not found. Install with: nix-env -iA nixpkgs.poppler_utils"
    - djvutxt not available -> "djvutxt not found (DJVU files will be skipped). Install with: nix-env -iA nixpkgs.djvulibre"
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
  </reads>

  <writes>
    - specs/literature/*.md (flat document conversions)
    - specs/literature/{docname}/sectionNN_{slug}.md (content-aware chunked sections)
    - specs/literature/{docname}/{docname}_partNN.md (mechanical fallback chunks)
    - specs/literature/index.json (index entries with enriched schema: authors, title, year, doc_type, source_format, parent_doc, page_range)
  </writes>

  <source_file_convention>
    Source PDFs/DJVUs are placed in the same directory as their converted markdown.
    Gitignore patterns `specs/literature/**/*.pdf` and `specs/literature/**/*.djvu` prevent
    committing source files. Users re-add source files manually after checkout.
  </source_file_convention>
</state_management>
