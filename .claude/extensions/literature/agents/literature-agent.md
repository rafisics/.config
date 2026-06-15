---
name: literature-agent
description: Manage specs/literature/ — scan, convert PDFs/DJVUs, maintain index.json, and search/import from Zotero. Invoke for /literature command.
model: sonnet
allowed-tools: Bash, Read, Write, Edit, AskUserQuestion
---

# Literature Agent

## Overview

This agent documents the `/literature` command's direct-execution architecture. The agent file exists for documentation purposes and system discoverability. During normal `/literature` command execution, `skill-literature` runs inline (direct execution) without spawning this agent as a subagent.

**Architecture**: Direct-execution pattern (like `/distill`, `/fix-it`, `/refresh`). The skill manages all PDF/DJVU-to-markdown conversion, index.json maintenance, filesystem validation, and Zotero search/import inline using `AskUserQuestion` for interactivity.

## Execution Pattern

```
/literature [--scan|--convert [FILE]|--validate|--index FILE|--search "QUERY"|--task N]
    |
    v
.claude/commands/literature.md  (argument parsing)
    |
    v
skill-literature (direct execution — no agent subagent spawned)
    |
    +-- Status mode: read index.json, scan for PDFs/DJVUs, show health report
    +-- Scan mode: find unprocessed files, show with page counts
    +-- Convert mode: pdftotext -> markdown + index.json updates (with AskUserQuestion)
    +-- Validate mode: check index.json against filesystem, report drift
    +-- Index mode: add/update entry for existing markdown file (with AskUserQuestion)
    +-- Search mode (--search "QUERY"): search Zotero library + Literature/ index
    |     |
    |     +-- Step 1: Resolve zotero-search.sh path
    |     +-- Step 2: Run zotero-search.sh (handle exit codes 0/1/2)
    |     +-- Step 3: Cross-reference results with Literature/ index
    |     +-- Step 4: Direct index keyword search (fallback/supplement)
    |     +-- Step 5: Merge and sort by score
    |     +-- Step 6: AskUserQuestion multi-select ([IMPORTED]/[PDF AVAILABLE]/[NO PDF])
    |     +-- Step 7: Route selections -> show path | import pipeline | message
    |
    +-- Task-search mode (--task N): extract task description -> same as search mode
          |
          +-- Read specs/state.json for task N project_name
          +-- Use project_name as search query -> search mode
```

### Import Pipeline (triggered from search mode for PDF-available entries)

```
Search Step 7 -> handle_import(citation_key)
    |
    +-- Step 8: AskUserQuestion per-entry import confirmation
    +-- Step 9: ln -s {zotero_pdf} $LITERATURE_DIR/pdfs/{citation_key}.pdf
    +-- Step 10: handle_convert() with PREFILL_* env vars (title, authors, year, doc_type, source_format)
    +-- Step 11: jq patch index entry with zotero_key, zotero_path, bib_key, project_tags
    +-- Step 12: git commit in $LITERATURE_DIR "import: {title} ({year})" (non-blocking)
```

## Zotero Integration

### Search-to-Import Pipeline Overview

The `/literature --search "QUERY"` and `/literature --task N` modes provide end-to-end Zotero discovery and import:

1. **Search**: invokes `zotero-search.sh --format=json --limit=20 {terms}` which searches the CSL-JSON library by weighted multi-field matching (title +3, keyword +2, abstract +1, author +1)
2. **Cross-reference**: checks Literature/ index for already-imported entries (match on `bib_key`, `zotero_key`, or `id` fields)
3. **Classify**: each result gets an availability status:
   - `[IMPORTED]` — already in Literature/ index
   - `[PDF AVAILABLE]` — Zotero has a PDF that can be symlinked
   - `[NO PDF]` — in Zotero library but no accessible PDF
4. **Multi-select**: user picks which entries to import via AskUserQuestion
5. **Import**: for each selected PDF-available entry, the import pipeline runs sequentially

### Availability States

| Tag | Meaning | User Action |
|-----|---------|-------------|
| `[IMPORTED]` | Entry already in Literature/ index | Shows existing path |
| `[PDF AVAILABLE]` | Zotero has accessible PDF | Triggers import pipeline |
| `[NO PDF]` | No accessible PDF in Zotero | Shows message, no import |

### zotero-library.json Dependency

The search mode requires a Zotero Better BibTeX CSL-JSON export:

**Setup**: In Zotero → File → Export Library → Better CSL JSON → save to one of:
- `$ZOTERO_LIBRARY` (environment variable)
- `$LITERATURE_DIR/zotero-library.json`
- `~/Projects/Literature/zotero-library.json`

**Graceful Degradation**: If `zotero-library.json` is not found:
- zotero-search.sh exits with code 1 and prints setup instructions
- skill-literature falls back to Literature/ index-only search
- User sees setup instructions + index-only results (no error termination)

### Exit Code Contract

| Exit Code | Meaning | Skill Behavior |
|-----------|---------|----------------|
| 0 | Results found | Parse JSON results, continue |
| 1 | Library file not found | Show setup instructions, fall back to index search |
| 2 | No results matched | Continue to index-only search |

## Tool Usage

| Tool | Purpose |
|------|---------|
| Bash | Run pdftotext, pdfinfo, djvutxt, wc; check tool availability; invoke zotero-search.sh; create symlinks; git commit |
| Read | Read index.json, existing markdown files, specs/state.json |
| Write | Write new markdown conversions, initialize index.json |
| Edit | Update existing index.json entries |
| AskUserQuestion | Present chunk boundaries, keywords, summary, search results, import confirmation |

## Related Files

- `.claude/commands/literature.md` - Command entry point (argument parsing)
- `.claude/skills/skill-literature/SKILL.md` - All implementation logic
- `.claude/extensions/literature/scripts/zotero-search.sh` - Zotero CSL-JSON search script
- `specs/literature/index.json` - Literature index (root level)
- `specs/literature/*/index.json` - Subdirectory indexes (chunked documents)
- `$LITERATURE_DIR/pdfs/` - Symlinked PDFs from Zotero (created by import pipeline)

## Index Schema

Root `specs/literature/index.json` uses an enriched entry schema with the following fields:

### Field Reference

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | string | Yes | Unique identifier (e.g., `smith2023_proplogic`) |
| `path` | string | Yes | File path relative to `specs/literature/` |
| `token_count` | integer | Yes | Estimated token count; used for budget enforcement |
| `keywords` | string[] | Yes | Keywords for relevance scoring against task description |
| `summary` | string | Yes | One-sentence description of the document content |
| `authors` | string[] | Yes | Author list (e.g., `["Alice Smith", "Bob Jones"]`) |
| `title` | string | Yes | Full document or section title |
| `year` | integer\|null | Yes | Publication year (null if unknown) |
| `doc_type` | string | Yes | One of: `paper`, `book`, `chapter`, `section` |
| `source_format` | string | Yes | One of: `pdf`, `djvu`, `manual` |
| `parent_doc` | string\|null | Yes | ID of parent entry for chunks/sections; null for top-level |
| `page_range` | string\|null | Yes | Page range in source document (e.g., `"15-47"`); null if not applicable |
| `bib_key` | string\|null | No | Better BibTeX citation key (e.g., `smith2023_proplogic`) — set by import pipeline |
| `zotero_key` | string\|null | No | Zotero internal item key — set by import pipeline |
| `zotero_path` | string\|null | No | Absolute path to source PDF in Zotero storage — set by import pipeline |
| `project_tags` | string[]\|null | No | Zotero collection names used as project tags — set by import pipeline |

### Complete entry example (flat paper, Zotero-imported)

```json
{
  "token_budget": 4000,
  "entries": [
    {
      "id": "smith2023_proplogic",
      "path": "Smith_2023_PropositionalLogic.md",
      "token_count": 1850,
      "keywords": ["propositional", "logic", "syntax", "semantics", "proof"],
      "summary": "Introduces propositional logic with natural deduction and truth tables.",
      "authors": ["Alice Smith"],
      "title": "Propositional Logic: A Modern Introduction",
      "year": 2023,
      "doc_type": "paper",
      "source_format": "pdf",
      "parent_doc": null,
      "page_range": null,
      "bib_key": "smith2023_proplogic",
      "zotero_key": "ABCD1234",
      "zotero_path": "/home/user/Zotero/storage/ABCD1234/Smith_2023.pdf",
      "project_tags": ["Modal Logic", "Formal Methods"]
    }
  ]
}
```

### Complete entry example (chunked book section)

```json
{
  "id": "brastmckie2024_bimodal_sec02",
  "path": "Brastmckie_2024_BimodalLogic/section02_syntax.md",
  "token_count": 2100,
  "keywords": ["bimodal", "syntax", "formula", "operator", "modal"],
  "summary": "Defines the formal syntax of bimodal logic with operator precedence rules.",
  "authors": ["Benjamin Brastmckie"],
  "title": "BimodalLogic - Section 2: Syntax",
  "year": 2024,
  "doc_type": "section",
  "source_format": "pdf",
  "parent_doc": "brastmckie2024_bimodal",
  "page_range": "15-47",
  "bib_key": null,
  "zotero_key": null,
  "zotero_path": null,
  "project_tags": null
}
```

### Source file co-location

PDF/DJVU source files are co-located with their converted markdown in the same directory:

```
specs/literature/
  index.json
  Smith_2023_PropositionalLogic.pdf    # gitignored source
  Smith_2023_PropositionalLogic.md     # converted markdown
  Brastmckie_2024_BimodalLogic/
    Brastmckie_2024_BimodalLogic.pdf   # gitignored source
    section01_introduction.md
    section02_syntax.md
  pdfs/                                # Zotero symlinks (created by import pipeline)
    smith2023_proplogic.pdf -> /home/user/Zotero/storage/ABCD1234/Smith_2023.pdf
```

Source files are gitignored via `specs/literature/**/*.pdf` and `specs/literature/**/*.djvu`.
