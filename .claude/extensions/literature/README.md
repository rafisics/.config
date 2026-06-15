# Literature Extension

Extension for managing `specs/literature/` directories. Handles PDF/DJVU-to-markdown conversion
with content-aware chunking, index.json maintenance, and filesystem validation.

## Loading the Extension

```
Extension picker -> select "literature"
```

---

## Commands

| Command | Usage | Description |
|---------|-------|-------------|
| `/literature` | `/literature` | Show health report |
| `/literature` | `/literature --scan` | Find unprocessed PDFs/DJVUs |
| `/literature` | `/literature --convert [FILE]` | Convert to markdown with content-aware chunking |
| `/literature` | `/literature --validate` | Check index.json consistency |
| `/literature` | `/literature --index FILE` | Add/update index entry |
| `/literature` | `/literature --search "QUERY"` | Search Zotero library and Literature/ index by keyword |
| `/literature` | `/literature --task N` | Extract task N description as Zotero search query |

---

## Directory Convention

PDF/DJVU source files are **co-located** with their converted markdown in the same directory.
Source files are gitignored (via `specs/literature/**/*.pdf` and `specs/literature/**/*.djvu`)
and must be re-added manually after checkout.

**Centralized repository**: Set `LITERATURE_DIR=/path/to/Literature` in `.claude/settings.json`
to use a shared centralized repo instead of per-project `specs/literature/` directories. When
`LITERATURE_DIR` is set, all `/literature` commands operate on that directory. The centralized
repo may include a `pdfs/` subdirectory for organizing Zotero-imported PDFs separately from
converted markdown.

```
specs/literature/              # Per-project OR $LITERATURE_DIR (centralized)
  index.json                   # Root literature index
  zotero-library.json          # Better BibTeX CSL-JSON export (centralized only)
  pdfs/                        # Zotero-imported PDFs (gitignored)
    Smith_2023_PropLogic.pdf
  Smith_2023_PropositionalLogic.pdf  # Gitignored source (co-located)
  Smith_2023_PropositionalLogic.md   # Converted markdown (flat paper)
  Brastmckie_2024_BimodalLogic/      # Chunked document directory
    Brastmckie_2024_BimodalLogic.pdf # Gitignored source (co-located)
    section01_introduction.md
    section02_syntax.md
    section03_semantics.md
```

---

## Content-Aware Chunking

Documents are split at logical section boundaries rather than fixed page counts. The algorithm:

1. **Detects headings**: Chapter/section headings via regex (`Chapter N`, numbered sections,
   `Part N`, markdown `## headings`)
2. **Merges small sections**: Adjacent sections below 500 lines are merged toward the
   4,000-line target
3. **Falls back**: When no headings detected, splits mechanically at 4,000-line boundaries

**Output naming**:
- Structure-detected: `{dirname}/sectionNN_{slug}.md` (e.g., `section02_syntax.md`)
- Mechanical fallback: `{dirname}/{basename}_partNN.md` (e.g., `bimodal_part02.md`)

---

## Zotero Search and Import

The `/literature --search` and `/literature --task` commands integrate with a Zotero library
exported via Better BibTeX's CSL-JSON format.

### Setup

1. Install the **Better BibTeX** plugin for Zotero
2. In Zotero: File > Export Library > Better CSL JSON > check "Keep updated"
3. Save to `$LITERATURE_DIR/zotero-library.json` (or `specs/literature/zotero-library.json`)
4. The export auto-updates whenever Zotero is open and the library changes

### Usage

```bash
# Search by keyword
/literature --search "modal logic completeness"

# Derive search query from a task description
/literature --task 273
```

### Scoring Algorithm

Results are ranked by a weighted multi-field score:

| Field | Weight | Notes |
|-------|--------|-------|
| Title match | 3x | Substring or word match |
| Keyword match | 2x | Against index.json keywords array |
| Author match | 1x | Last name substring match |
| Abstract match | 1x | Partial text match |

Results already converted to markdown are tagged `[indexed]`. Results present in the Zotero
library but not yet converted are tagged `[zotero-only]`.

### Interactive Import Pipeline

After search results are displayed, the agent prompts for item selection. For each selected item:

1. **Symlink**: Creates a symlink from `pdfs/{key}.pdf` to the Zotero storage PDF (or copies if
   the storage path is unavailable)
2. **Convert**: Runs `--convert` on the PDF using the content-aware chunking pipeline
3. **Index patch**: Adds `bib_key`, `zotero_key`, `zotero_path`, and `project_tags` fields to
   the generated `index.json` entry
4. **Commit**: Creates a git commit with message `literature: import {title}`

### Graceful Degradation

- If `zotero-library.json` does not exist, `--search` falls back to keyword search over
  `index.json` only (no Zotero results)
- If the Zotero storage PDF is missing, import prompts for a manual PDF path
- If Better BibTeX is not installed, export must be done manually (standard BibTeX CSL-JSON)

---

## Index Schema

Each `index.json` entry contains:

| Field | Type | Description |
|-------|------|-------------|
| `id` | string | Unique identifier |
| `path` | string | Path relative to `specs/literature/` |
| `token_count` | integer | Estimated token count |
| `keywords` | string[] | Relevance scoring keywords |
| `summary` | string | One-sentence description |
| `authors` | string[] | Author list |
| `title` | string | Full document or section title |
| `year` | integer\|null | Publication year |
| `doc_type` | string | `paper`, `book`, `chapter`, or `section` |
| `source_format` | string | `pdf`, `djvu`, or `manual` |
| `parent_doc` | string\|null | Parent entry ID for section chunks |
| `page_range` | string\|null | Page/line range in source document |
| `bib_key` | string\|null | Original BibTeX key from source .bib file |
| `zotero_key` | string\|null | Zotero/Better BibTeX canonical item key |
| `zotero_path` | string\|null | Path to PDF in Zotero storage |
| `project_tags` | string[] | List of originating project names |

---

## Integration with --lit Flag

The `--lit` flag on `/research`, `/plan`, `/implement`, and `/orchestrate` injects literature
files as `<literature-context>` into agent prompts. This flag is handled by the core extension's
`literature-retrieve.sh` script and works independently of whether this extension is loaded.

This extension provides the `/literature` command for managing the files that `--lit` consumes.

---

## Tool Requirements

- **pdftotext** (from poppler_utils): Required for PDF conversion
- **pdfinfo** (from poppler_utils): Used for page count detection
- **djvutxt** (from djvulibre): Required for DJVU conversion (optional)

Install via Nix: `nix-env -iA nixpkgs.poppler_utils nixpkgs.djvulibre`

---

## Provided Artifacts

| Type | Name | Purpose |
|------|------|---------|
| Agent | literature-agent.md | Documentation agent (direct execution pattern) |
| Skill | skill-literature | All conversion and index logic |
| Command | /literature | Command entry point |
| Script | scripts/zotero-search.sh | Zotero library search and import pipeline |
