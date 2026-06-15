---
name: skill-literature
description: Manage specs/literature/ — scan, convert PDFs/DJVUs, maintain index.json. Invoke for /literature command.
allowed-tools: Bash, Read, Write, Edit, AskUserQuestion
---

# Literature Skill (Direct Execution)

Direct execution skill for managing `specs/literature/` directories. Handles PDF/DJVU-to-markdown conversion, index.json maintenance, and filesystem validation. Runs inline using AskUserQuestion for interactivity.

**Key behavior**: Users see scan results and proposed keywords/summaries BEFORE any files are written. Users confirm chunk boundaries and metadata before conversion completes.

## Context References

Reference (do not load eagerly):
- Path: `@specs/literature/index.json` - Current literature index
- Path: `@specs/702_create_literature_command/reports/01_lit-command.md` - Research findings

---

## Execution

### Step 1: Parse Arguments

Extract mode and optional file from skill args:

```bash
# Parse from skill args: "mode={mode} file={file}"
mode=$(echo "$ARGUMENTS" | grep -oP 'mode=\K\S+' | head -1)
file=$(echo "$ARGUMENTS" | grep -oP 'file=\K\S+' | head -1)

# Default to status mode if not specified
if [ -z "$mode" ]; then
  mode="status"
fi

# Resolve file path (may be relative or absolute)
if [ -n "$file" ]; then
  if [[ "$file" != /* ]]; then
    file="specs/literature/$file"
  fi
fi
```

### Step 2: Generate Session ID

```bash
session_id="sess_$(date +%s)_$(od -An -N3 -tx1 /dev/urandom | tr -d ' ')"
lit_dir="specs/literature"
index_file="$lit_dir/index.json"
```

### Step 3: Check Tool Availability

Detect available conversion tools:

```bash
has_pdftotext=$(which pdftotext 2>/dev/null && echo "yes" || echo "no")
has_pdfinfo=$(which pdfinfo 2>/dev/null && echo "yes" || echo "no")
has_djvutxt=$(which djvutxt 2>/dev/null && echo "yes" || echo "no")
```

### Step 4: Dispatch to Mode Handler

Route to the appropriate mode:

```bash
case "$mode" in
  status)   handle_status ;;
  scan)     handle_scan ;;
  convert)  handle_convert ;;
  validate) handle_validate ;;
  index)    handle_index ;;
  *)
    echo "Error: Unknown mode '$mode'. Available: status, scan, convert, validate, index"
    exit 1
    ;;
esac
```

---

## Mode: Status (Default)

Show health report: processed vs unprocessed files and index.json state.

### Status Step 1: Check Directory

```bash
if [ ! -d "$lit_dir" ]; then
  echo "## Literature Status"
  echo ""
  echo "No specs/literature/ directory found."
  echo "Create it and add PDF/DJVU files to get started."
  echo ""
  echo "**Tool Availability**:"
  echo "- pdftotext: $has_pdftotext"
  echo "- djvutxt: $has_djvutxt ($([ "$has_djvutxt" = "no" ] && echo 'install: nix-env -iA nixpkgs.djvulibre' || echo 'available'))"
  exit 0
fi
```

### Status Step 2: Scan for Files

```bash
# Find all PDF and DJVU source files
pdf_files=$(find "$lit_dir" -name "*.pdf" 2>/dev/null | sort)
djvu_files=$(find "$lit_dir" -name "*.djvu" 2>/dev/null | sort)
all_source_files="$pdf_files $djvu_files"

# Find all markdown files (excluding any in subdirectory source_files/)
md_files=$(find "$lit_dir" -name "*.md" -not -path "*/source_files/*" 2>/dev/null | sort)
```

### Status Step 3: Read Index

```bash
if [ -f "$index_file" ]; then
  entry_count=$(jq '.entries | length' "$index_file" 2>/dev/null || echo "0")
  indexed_paths=$(jq -r '.entries[].path' "$index_file" 2>/dev/null || echo "")
else
  entry_count=0
  indexed_paths=""
fi
```

### Status Step 4: Compute Counts

```bash
# Count source files
pdf_count=$(echo "$pdf_files" | grep -c "\.pdf$" 2>/dev/null || echo 0)
djvu_count=$(echo "$djvu_files" | grep -c "\.djvu$" 2>/dev/null || echo 0)
md_count=$(echo "$md_files" | grep -c "\.md$" 2>/dev/null || echo 0)

# Identify unprocessed source files (PDFs/DJVUs without corresponding .md)
unprocessed=()
for src in $pdf_files $djvu_files; do
  basename_no_ext=$(basename "$src" | sed 's/\.[^.]*$//')
  # Check if any .md file starts with this basename
  if ! find "$lit_dir" -name "${basename_no_ext}*.md" -not -path "*/source_files/*" 2>/dev/null | grep -q .; then
    unprocessed+=("$src")
  fi
done
unprocessed_count=${#unprocessed[@]}
processed_count=$(( pdf_count + djvu_count - unprocessed_count ))
```

### Status Step 5: Display Report

```
## Literature Status

**Directory**: specs/literature/
**Source Files**: {pdf_count} PDFs, {djvu_count} DJVUs
**Converted**: {processed_count} processed, {unprocessed_count} unprocessed
**Markdown Files**: {md_count}
**Index Entries**: {entry_count}

**Tool Availability**:
- pdftotext: {has_pdftotext}
- djvutxt: {has_djvutxt} {install hint if no}

{if unprocessed_count > 0}
**Unprocessed Files** ({unprocessed_count}):
- {file1}
- {file2}
...

Run `/literature --convert` to convert all, or `/literature --scan` to see details.
{end if}

{if entry_count > 0 and md_count != entry_count}
**Index Health**: {entry_count} indexed entries, {md_count} markdown files — run `/literature --validate` to check consistency.
{end if}
```

---

## Mode: Scan

Find PDF/DJVU files lacking corresponding markdown conversions.

### Scan Step 1: Check Directory

Same as Status Step 1 — exit gracefully if directory missing.

### Scan Step 2: Find Unprocessed Files

```bash
unprocessed=()
for src in $(find "$lit_dir" -name "*.pdf" -o -name "*.djvu" 2>/dev/null | sort); do
  basename_no_ext=$(basename "$src" | sed 's/\.[^.]*$//')
  if ! find "$lit_dir" -name "${basename_no_ext}*.md" -not -path "*/source_files/*" 2>/dev/null | grep -q .; then
    unprocessed+=("$src")
  fi
done
```

### Scan Step 3: Get Page Counts

For each unprocessed file, get page count via pdfinfo:

```bash
for src in "${unprocessed[@]}"; do
  ext="${src##*.}"
  if [ "$ext" = "pdf" ]; then
    if [ "$has_pdfinfo" = "yes" ]; then
      pages=$(pdfinfo "$src" 2>/dev/null | grep "^Pages:" | awk '{print $2}')
    else
      pages="unknown"
    fi
  elif [ "$ext" = "djvu" ]; then
    if [ "$has_djvutxt" = "yes" ]; then
      # djvused can get page count: djvused -e n file.djvu
      pages=$(djvused -e n "$src" 2>/dev/null || echo "unknown")
    else
      pages="unknown (djvutxt not installed)"
    fi
  fi
  echo "- $src ($pages pages)"
done
```

### Scan Step 4: Display Results

```
## Literature Scan Results

**Unprocessed Files** ({count}):
- {file1} ({N} pages)
- {file2} ({N} pages)
...

**Tool Status**:
- pdftotext: {status}
- djvutxt: {status} {install hint if unavailable}

**Next Steps**:
- Convert all: `/literature --convert`
- Convert one: `/literature --convert path/to/file.pdf`
```

If no unprocessed files found:

```
## Literature Scan Results

All source files have been converted. No unprocessed PDFs or DJVUs found.

**Files**: {N} PDFs, {M} DJVUs — all converted
**Index**: {entry_count} entries in index.json

Run `/literature --validate` to check index.json consistency.
```

---

## Mode: Validate

Check index.json against the filesystem for stale entries, missing files, and token count drift.

### Validate Step 1: Load Index

```bash
if [ ! -f "$index_file" ]; then
  echo "## Literature Validation"
  echo ""
  echo "No index.json found at $index_file."
  echo "Run /literature to see status, or /literature --convert to convert files and create the index."
  exit 0
fi

entries=$(jq -r '.entries[] | .path' "$index_file" 2>/dev/null)
```

### Validate Step 2: Check Each Entry

For each indexed entry, check:

1. File exists at `specs/literature/{entry.path}`
2. Token count drift (recount vs stored, flag if >20% different)

```bash
stale_entries=()
drift_entries=()

while IFS= read -r entry_path; do
  full_path="$lit_dir/$entry_path"
  if [ ! -f "$full_path" ]; then
    stale_entries+=("$entry_path (missing)")
  else
    # Recount tokens
    char_count=$(wc -c < "$full_path" 2>/dev/null || echo 0)
    current_tokens=$(( char_count / 4 + 20 ))
    stored_tokens=$(jq --arg p "$entry_path" '.entries[] | select(.path == $p) | .token_count' "$index_file" 2>/dev/null || echo 0)

    if [ -n "$stored_tokens" ] && [ "$stored_tokens" -gt 0 ]; then
      # Calculate drift percentage
      diff=$(( current_tokens - stored_tokens ))
      if [ "$diff" -lt 0 ]; then diff=$(( -diff )); fi
      drift_pct=$(( diff * 100 / stored_tokens ))
      if [ "$drift_pct" -gt 20 ]; then
        drift_entries+=("$entry_path (stored: $stored_tokens, actual: $current_tokens, drift: ${drift_pct}%)")
      fi
    fi
  fi
done <<< "$entries"
```

### Validate Step 3: Find Unindexed Markdown Files

```bash
unindexed=()
while IFS= read -r md_file; do
  # Get path relative to lit_dir
  rel_path="${md_file#$lit_dir/}"
  if ! jq -e --arg p "$rel_path" '.entries[] | select(.path == $p)' "$index_file" >/dev/null 2>&1; then
    unindexed+=("$rel_path")
  fi
done < <(find "$lit_dir" -maxdepth 1 -name "*.md" 2>/dev/null | sort)
```

### Validate Step 4: Display Report

```
## Literature Validation Report

**Index**: specs/literature/index.json
**Total Entries**: {N}

### Stale Entries ({count}) — path in index but file missing
{for each stale entry:}
- {entry_path}

### Token Count Drift ({count}) — more than 20% change from stored count
{for each drift entry:}
- {entry_path}: stored {N}, actual {M} ({pct}% drift)

### Unindexed Files ({count}) — markdown files not in index.json
{for each unindexed file:}
- {file_path}
  Run: /literature --index {file_path}

{if all clean:}
### Validation Passed

All {N} index entries are valid. No stale paths, no drift, no unindexed files.
```

---

## Mode: Convert

Convert unprocessed PDF/DJVU files to markdown with interactive confirmation.

### Convert Step 1: Determine Target Files

```bash
if [ -n "$file" ]; then
  # Convert specific file
  targets=("$file")
else
  # Find all unprocessed files
  targets=()
  for src in $(find "$lit_dir" -name "*.pdf" -o -name "*.djvu" 2>/dev/null | sort); do
    basename_no_ext=$(basename "$src" | sed 's/\.[^.]*$//')
    if ! find "$lit_dir" -name "${basename_no_ext}*.md" -not -path "*/source_files/*" 2>/dev/null | grep -q .; then
      targets+=("$src")
    fi
  done
fi
```

### Convert Step 2: Check Tool Availability

```bash
if [ "$has_pdftotext" = "no" ]; then
  echo "Error: pdftotext not found. Install with: nix-env -iA nixpkgs.poppler_utils"
  exit 1
fi
```

### Convert Step 3: Process Each File

For each target file:

#### 3a: Get Page Count

```bash
src="$target_file"
ext="${src##*.}"
basename_no_ext=$(basename "$src" | sed 's/\.[^.]*$//')

if [ "$ext" = "djvu" ]; then
  if [ "$has_djvutxt" = "no" ]; then
    echo "Skipping $src: djvutxt not installed. Install with: nix-env -iA nixpkgs.djvulibre"
    continue
  fi
  # Get page count for DJVU
  page_count=$(djvused -e n "$src" 2>/dev/null || echo 1)
else
  # PDF: get page count
  if [ "$has_pdfinfo" = "yes" ]; then
    page_count=$(pdfinfo "$src" 2>/dev/null | grep "^Pages:" | awk '{print $2}')
  else
    page_count=1
  fi
fi
```

#### 3b: Determine Chunking

```bash
pages_per_chunk=10
if [ "$page_count" -le "$pages_per_chunk" ]; then
  # Single file
  chunks=(("1-$page_count"))
  output_files=("${basename_no_ext}.md")
else
  # Multi-chunk
  chunks=()
  output_files=()
  start=1
  while [ "$start" -le "$page_count" ]; do
    end=$(( start + pages_per_chunk - 1 ))
    if [ "$end" -gt "$page_count" ]; then end=$page_count; fi
    chunks+=("${start}-${end}")
    output_files+=("${basename_no_ext}_p${start}-${end}.md")
    start=$(( end + 1 ))
  done
fi
```

#### 3c: Confirm Chunk Boundaries with User

If multi-chunk, present proposed boundaries via AskUserQuestion:

```json
{
  "question": "Convert '{basename}' ({page_count} pages) into {N} chunks?",
  "header": "Chunk Boundaries for {basename}",
  "multiSelect": false,
  "options": [
    {
      "label": "Accept proposed chunks ({N} files)",
      "description": "Pages: {chunk1}, {chunk2}, ... -> {file1}, {file2}, ..."
    },
    {
      "label": "Use single file (no chunking)",
      "description": "Convert all {page_count} pages to one {basename}.md (~{approx_tokens} tokens)"
    },
    {
      "label": "Skip this file",
      "description": "Do not convert {basename} now"
    }
  ]
}
```

If user selects "Use single file": set `chunks=("1-$page_count")`, `output_files=("${basename_no_ext}.md")`
If user selects "Skip this file": continue to next file

#### 3d: Run Conversion

For each chunk:

```bash
for i in "${!chunks[@]}"; do
  chunk_range="${chunks[$i]}"
  start_page="${chunk_range%-*}"
  end_page="${chunk_range#*-}"
  output_md="$lit_dir/${output_files[$i]}"

  if [ "$ext" = "pdf" ]; then
    # Extract text from page range
    raw_text=$(pdftotext -f "$start_page" -l "$end_page" -layout "$src" - 2>/dev/null)
  elif [ "$ext" = "djvu" ]; then
    # djvutxt does not support page ranges directly; extract all text
    # For DJVU multi-chunk, extract full text and split by approximate position
    raw_text=$(djvutxt "$src" 2>/dev/null)
    # Note: DJVU chunking is approximate (character split, not page split)
  fi

  # Check if text was extracted
  if [ -z "$(echo "$raw_text" | tr -d '[:space:]')" ]; then
    echo "Warning: No text extracted from $src (pages $start_page-$end_page). File may be scanned/image-only and requires OCR."
    continue
  fi

  # Wrap in minimal markdown with title header
  title=$(basename "$src" | sed 's/\.[^.]*$//' | tr '_-' '  ' | sed 's/\b\(.\)/\u\1/g')
  chunk_header=""
  if [ "${#chunks[@]}" -gt 1 ]; then
    chunk_header=" (Pages $start_page-$end_page)"
  fi

  markdown_content="# $title$chunk_header

$raw_text"

  # Write to file
  echo "$markdown_content" > "$output_md"
done
```

#### 3e: Compute Token Count and Auto-Generate Metadata

After writing, for each output file:

```bash
output_md="$lit_dir/${output_files[$i]}"
char_count=$(wc -c < "$output_md" 2>/dev/null || echo 0)
token_count=$(( char_count / 4 + 20 ))

# Extract auto-generated keywords (word frequency, top 10 after stopword removal)
# Stopword list (minimal)
stopwords="the a an and or but in on at to of for is are was were be been being have has had do does did will would could should may might shall can"

# Get word frequencies, filter stopwords, take top 10
auto_keywords=$(echo "$raw_text" | \
  tr '[:upper:]' '[:lower:]' | \
  tr -cs 'a-z' '\n' | \
  grep -v '^$' | \
  grep -v -w -F "$(echo "$stopwords" | tr ' ' '\n')" | \
  grep -E '^[a-z]{4,}$' | \
  sort | uniq -c | sort -rn | head -10 | \
  awk '{print $2}' | \
  jq -R . | jq -s . 2>/dev/null || echo '[]')

# Extract summary: look for Abstract, else use first 2-3 sentences
abstract_match=$(echo "$raw_text" | grep -i -A 5 "^[[:space:]]*abstract[[:space:]]*$" | head -6 | tail -5)
if [ -n "$abstract_match" ]; then
  auto_summary="$(echo "$abstract_match" | tr '\n' ' ' | sed 's/  */ /g' | cut -c1-300)"
else
  # First 2-3 sentences
  auto_summary=$(echo "$raw_text" | tr '\n' ' ' | sed 's/  */ /g' | grep -oP '^.{0,300}[.!?]' | head -1)
  if [ -z "$auto_summary" ]; then
    auto_summary=$(echo "$raw_text" | tr '\n' ' ' | sed 's/  */ /g' | cut -c1-200)
  fi
fi
```

#### 3f: Confirm Keywords and Summary with User

```json
{
  "question": "Review metadata for '{output_filename}':",
  "header": "Metadata Confirmation",
  "multiSelect": false,
  "options": [
    {
      "label": "Accept auto-generated metadata",
      "description": "Keywords: {auto_keywords_preview}\nSummary: {auto_summary_preview}"
    },
    {
      "label": "Edit keywords",
      "description": "Keep summary, modify keyword list"
    },
    {
      "label": "Edit summary",
      "description": "Keep keywords, modify summary"
    },
    {
      "label": "Edit both",
      "description": "Modify both keywords and summary before indexing"
    }
  ]
}
```

If user selects "Edit keywords", prompt:
```json
{"question": "Enter keywords (comma-separated):"}
```
Parse response into JSON array.

If user selects "Edit summary", prompt:
```json
{"question": "Enter one-sentence summary:"}
```

#### 3g: Update index.json

```bash
# Generate entry ID from filename (lowercase, underscores)
entry_id=$(basename "$output_md" .md | tr '[:upper:]' '[:lower:]' | tr ' -' '_')

# Create or update index.json
if [ ! -f "$index_file" ]; then
  echo '{"token_budget": 4000, "entries": []}' > "$index_file"
fi

# Check if entry already exists
if jq -e --arg id "$entry_id" '.entries[] | select(.id == $id)' "$index_file" >/dev/null 2>&1; then
  # Update existing entry
  tmp=$(mktemp)
  jq --arg id "$entry_id" \
     --arg path "$(basename "$output_md")" \
     --argjson tc "$token_count" \
     --argjson kw "$final_keywords" \
     --arg sum "$final_summary" \
     '.entries = [.entries[] | if .id == $id then . + {"path": $path, "token_count": $tc, "keywords": $kw, "summary": $sum} else . end]' \
     "$index_file" > "$tmp" && mv "$tmp" "$index_file"
else
  # Append new entry
  tmp=$(mktemp)
  jq --arg id "$entry_id" \
     --arg path "$(basename "$output_md")" \
     --argjson tc "$token_count" \
     --argjson kw "$final_keywords" \
     --arg sum "$final_summary" \
     '.entries += [{"id": $id, "path": $path, "token_count": $tc, "keywords": $kw, "summary": $sum}]' \
     "$index_file" > "$tmp" && mv "$tmp" "$index_file"
fi
```

### Convert Step 4: Display Summary

```
## Conversion Complete

**Files Converted**: {N}

| Output File | Pages | Tokens | Status |
|-------------|-------|--------|--------|
| {file1.md}  | 1-10  | 3,500  | Written |
| {file2.md}  | 11-20 | 3,200  | Written |
...

**Index Updated**: specs/literature/index.json ({entry_count} entries)

**Skipped Files**:
- {file.djvu} — djvutxt not installed (install: nix-env -iA nixpkgs.djvulibre)
- {scan.pdf} — No text extracted (OCR required for scanned PDFs)
```

---

## Mode: Index

Add or update an index.json entry for an existing markdown file.

### Index Step 1: Validate File Exists

```bash
if [ -z "$file" ]; then
  echo "Error: --index requires a FILE argument."
  exit 1
fi

if [ ! -f "$file" ]; then
  echo "Error: File not found: $file"
  exit 1
fi

# Get relative path within specs/literature/
if [[ "$file" == "$lit_dir/"* ]]; then
  rel_path="${file#$lit_dir/}"
else
  rel_path="$(basename "$file")"
fi
```

### Index Step 2: Compute Token Count

```bash
char_count=$(wc -c < "$file" 2>/dev/null || echo 0)
token_count=$(( char_count / 4 + 20 ))
```

### Index Step 3: Auto-Generate Metadata

Same word-frequency keyword extraction and summary extraction as Convert Step 3e.

### Index Step 4: Prompt User for Metadata

```json
{
  "question": "Confirm metadata for '{rel_path}' ({token_count} tokens):",
  "header": "Index Entry Metadata",
  "multiSelect": false,
  "options": [
    {
      "label": "Accept auto-generated metadata",
      "description": "Keywords: {auto_keywords_preview}\nSummary: {auto_summary_preview}"
    },
    {
      "label": "Enter custom keywords",
      "description": "Manually specify keyword list"
    },
    {
      "label": "Enter custom summary",
      "description": "Manually write summary"
    },
    {
      "label": "Enter both custom",
      "description": "Specify both keywords and summary"
    }
  ]
}
```

If custom keywords requested:
```json
{"question": "Enter keywords (comma-separated):"}
```

If custom summary requested:
```json
{"question": "Enter one-sentence summary:"}
```

### Index Step 5: Write to index.json

```bash
# Initialize index.json if it does not exist
if [ ! -f "$index_file" ]; then
  echo '{"token_budget": 4000, "entries": []}' > "$index_file"
fi

entry_id=$(basename "$file" .md | tr '[:upper:]' '[:lower:]' | tr ' -' '_')

# Check if entry already exists
if jq -e --arg id "$entry_id" '.entries[] | select(.id == $id)' "$index_file" >/dev/null 2>&1; then
  # Update existing entry
  tmp=$(mktemp)
  jq --arg id "$entry_id" \
     --arg path "$rel_path" \
     --argjson tc "$token_count" \
     --argjson kw "$final_keywords" \
     --arg sum "$final_summary" \
     '.entries = [.entries[] | if .id == $id then . + {"path": $path, "token_count": $tc, "keywords": $kw, "summary": $sum} else . end]' \
     "$index_file" > "$tmp" && mv "$tmp" "$index_file"
  echo "Updated existing entry '$entry_id' in $index_file"
else
  # Append new entry
  tmp=$(mktemp)
  jq --arg id "$entry_id" \
     --arg path "$rel_path" \
     --argjson tc "$token_count" \
     --argjson kw "$final_keywords" \
     --arg sum "$final_summary" \
     '.entries += [{"id": $id, "path": $path, "token_count": $tc, "keywords": $kw, "summary": $sum}]' \
     "$index_file" > "$tmp" && mv "$tmp" "$index_file"
  echo "Added new entry '$entry_id' to $index_file"
fi
```

### Index Step 6: Display Result

```
## Index Entry Added

**File**: {rel_path}
**Entry ID**: {entry_id}
**Token Count**: {token_count}
**Keywords**: {keywords}
**Summary**: {summary}

**Index**: specs/literature/index.json ({N} entries total)
```

---

## Error Handling

See `rules/error-handling.md` for general patterns. Skill-specific behaviors:

- **specs/literature/ missing**: Not an error for status/scan — report and suggest next steps
- **index.json missing**: Initialize with empty structure for convert/index modes; warn for validate
- **pdftotext missing**: Hard error for convert mode on PDF files — show install command
- **djvutxt missing**: Soft warning — skip DJVU files with message, continue processing PDFs
- **Empty pdftotext output**: Warn "no text extracted, OCR required", skip file, continue
- **jq failure**: Use two-step write pattern (write to tmp file, then mv) to avoid corruption
- **Git commit failure**: Non-blocking — log and continue

## Standards Reference

- Token counting: `chars / 4 + 20` (matches memory-harvest.sh pattern)
- Chunking: 10 pages per chunk (~4000 tokens at 350 words/page, 1.3 tokens/word)
- Index schema: root uses `entries[]`, subdirectory uses `chapters[]`
- Drift threshold: >20% change in token count triggers validation warning
