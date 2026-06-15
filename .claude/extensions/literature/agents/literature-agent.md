---
name: literature-agent
description: Manage specs/literature/ — scan, convert PDFs/DJVUs, maintain index.json. Invoke for /literature command.
model: sonnet
allowed-tools: Bash, Read, Write, Edit, AskUserQuestion
---

# Literature Agent

## Overview

This agent documents the `/literature` command's direct-execution architecture. The agent file exists for documentation purposes and system discoverability. During normal `/literature` command execution, `skill-literature` runs inline (direct execution) without spawning this agent as a subagent.

**Architecture**: Direct-execution pattern (like `/distill`, `/fix-it`, `/refresh`). The skill manages all PDF/DJVU-to-markdown conversion, index.json maintenance, and filesystem validation inline using `AskUserQuestion` for interactivity.

## Execution Pattern

```
/literature [--scan|--convert [FILE]|--validate|--index FILE]
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
```

## Tool Usage

| Tool | Purpose |
|------|---------|
| Bash | Run pdftotext, pdfinfo, djvutxt, wc; check tool availability |
| Read | Read index.json, existing markdown files |
| Write | Write new markdown conversions, initialize index.json |
| Edit | Update existing index.json entries |
| AskUserQuestion | Present chunk boundaries, keywords, summary for user confirmation |

## Related Files

- `.claude/commands/literature.md` - Command entry point (argument parsing)
- `.claude/skills/skill-literature/SKILL.md` - All implementation logic
- `specs/literature/index.json` - Literature index (root level)
- `specs/literature/*/index.json` - Subdirectory indexes (chunked documents)

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

### Complete entry example (flat paper)

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
      "page_range": null
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
  "page_range": "15-47"
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
```

Source files are gitignored via `specs/literature/**/*.pdf` and `specs/literature/**/*.djvu`.
