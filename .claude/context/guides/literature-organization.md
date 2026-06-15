# Literature Organization Guide

Reference guide for the `specs/literature/` directory and the `--lit` injection system.

## Overview

The `specs/literature/` directory holds reference documents (papers, specifications, algorithm
descriptions) that agents can consult when the `--lit` flag is passed to `/research`, `/plan`,
`/implement`, or `/orchestrate`. The directory is user-maintained and not created automatically.

Literature injection uses keyword scoring to select the most relevant files for a given task,
staying within a fixed token budget. If no `index.json` exists, the system falls back to a
lexicographic scan of all `.md` and `.txt` files in the directory.

## Directory Structure

Two organization patterns are supported:

### Flat files (single papers or short specifications)

```
specs/literature/
├── index.json
├── Smith_2023_PropositionalLogic.md
└── Brastmckie_2024_BimodalLogic.md
```

Use flat files for papers or documents that fit within the ~3000-token chunk target in a single
file. Each `.md` or `.txt` file corresponds to one entry in `index.json`.

### Subdirectory layout (books or long documents)

```
specs/literature/
├── index.json
└── Brastmckie_2024_BimodalLogic/
    ├── index.json          (optional, organizational only)
    ├── sec01_introduction.md
    ├── sec02_syntax.md
    └── sec03_semantics.md
```

Long documents are chunked into section files inside a named subdirectory. The global
`specs/literature/index.json` contains one entry per section, with `path` pointing to the
section file (e.g., `Brastmckie_2024_BimodalLogic/sec02_syntax.md`).

> **Note**: A per-book `index.json` inside a subdirectory is an organizational convention for
> human reference only. The `literature-retrieve.sh` script reads only the top-level
> `specs/literature/index.json`. Any `chapters[]` array in a per-book `index.json` is not
> parsed by the script.

## Naming Conventions

### Flat paper files

Format: `Author_Year_Title.md`

- `Author`: Last name of first author, capitalized (e.g., `Smith`, `Brastmckie`)
- `Year`: Four-digit publication year
- `Title`: CamelCase abbreviated title (no spaces)

Examples:
- `Smith_2023_PropositionalLogic.md`
- `Brastmckie_2024_BimodalLogic.md`
- `VanBenthem_2010_ModalLogicGameSemantics.md`

### Chapter/section files inside a subdirectory

Format: `secNN_slug.md`

- `NN`: Zero-padded section number for lexicographic ordering (01, 02, 03...)
- `slug`: 2-4 word kebab-case description of the section content

Examples:
- `sec01_introduction.md`
- `sec02_syntax.md`
- `sec03_canonical-models.md`

## index.json Schema

The top-level `specs/literature/index.json` file controls keyword-scored injection. Without it,
the system falls back to a blind lexicographic scan.

### File structure

```json
{
  "entries": [
    { ... },
    { ... }
  ]
}
```

### Entry fields

#### Script-required fields (used by literature-retrieve.sh)

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | string | Yes | Unique identifier for this entry (logged internally) |
| `path` | string | Yes | File path relative to `specs/literature/` |
| `token_count` | integer | Yes | Estimated token count; used for greedy budget enforcement |
| `keywords` | string[] | Yes | Keywords for relevance scoring against the task description |
| `title` | string | Recommended | Display name shown in the injected context heading |
| `summary` | string | Recommended | Short summary; earns a +1 bonus if any task keyword matches |

#### Metadata convention fields (not read by script; useful for humans and tooling)

| Field | Type | Purpose |
|-------|------|---------|
| `bib_key` | string | BibTeX cite key (e.g., `Smith2023`) |
| `authors` | string[] | Author list |
| `year` | integer | Publication year |
| `section` | string | Section identifier for chapter entries (e.g., `ch02`) |
| `page_range` | string | Source page range in the original document (e.g., `"15-47"`) |

### Complete entry example (flat paper)

```json
{
  "id": "smith2023-proplogic",
  "bib_key": "Smith2023",
  "title": "Propositional Logic: A Modern Introduction",
  "authors": ["Alice Smith"],
  "year": 2023,
  "section": null,
  "path": "Smith_2023_PropositionalLogic.md",
  "page_range": null,
  "token_count": 1850,
  "keywords": ["propositional", "logic", "syntax", "semantics", "proof"],
  "summary": "Introduces propositional logic with natural deduction and truth tables."
}
```

### Complete entry example (chapter file)

```json
{
  "id": "brastmckie2024-bimodal-ch2",
  "bib_key": "Brastmckie2024",
  "title": "BimodalLogic - Chapter 2: Syntax",
  "authors": ["Benjamin Brastmckie"],
  "year": 2024,
  "section": "ch02",
  "path": "Brastmckie_2024_BimodalLogic/sec02_syntax.md",
  "page_range": "15-47",
  "token_count": 2100,
  "keywords": ["bimodal", "syntax", "formula", "operator", "modal"],
  "summary": "Defines the formal syntax of bimodal logic with operator precedence rules."
}
```

## Chunk Sizing Policy

### Token budget

The injection system enforces a hard ceiling of **4000 tokens total** across all selected files
(`TOKEN_BUDGET=4000`). Up to 10 files may be injected (`MAX_FILES=10`).

A single file that would push the running total past the budget is silently skipped. Files are
evaluated in descending relevance score order, so lower-relevance files are skipped first.

### Recommended chunk target

Each file should target **~3000 tokens** (~2300 words) to allow room for at least one
additional file within the budget. Avoid files that exceed 4000 tokens on their own -- they
will always be skipped in index mode if any other file has been selected first.

### Token estimation formula

The script estimates tokens in fallback mode as:

```bash
est_tokens=$(( (word_count * 13 + 5) / 10 ))
```

This approximates 1.3 tokens per word. Use the same formula to populate the `token_count`
field in `index.json`:

```bash
echo $(( ($(wc -w < file.md) * 13 + 5) / 10 ))
```

Re-run this command after significant edits to keep `token_count` accurate.

## How --lit Injection Works

### End-to-end flow

1. User runs a command with `--lit` (e.g., `/research 703 --lit`).
2. The skill's preflight calls `literature-retrieve.sh <task_description> <task_type>`.
3. The script checks that `$PROJECT_ROOT/specs/literature/` exists. If not, it exits with
   code 1 and the flag is silently ignored.
4. If `index.json` exists and the task description is non-empty, the script runs
   **Mode A: keyword scoring**.
5. Otherwise, the script runs **Mode B: fallback scan**.
6. The script writes a `<literature-context>` XML block to stdout.
7. The skill injects this block into the agent prompt after `<memory-context>` (if any) and
   before the task-specific instructions.
8. If the script produces no output (empty stdout or exit 1), `--lit` has no effect.

### Mode A: keyword-scored injection

**Step 1 -- Keyword extraction**: The script combines the task description and task type,
lowercases, strips stop words, filters to tokens longer than 3 characters, deduplicates, and
takes the top 10 keywords.

**Step 2 -- Scoring**: For each `index.json` entry:
- `kw_score` = count of task keywords found in `entry.keywords[]` (case-insensitive)
- `summary_bonus` = 1 if any task keyword appears in `entry.summary`, else 0
- `total_score = kw_score + summary_bonus`
- Entries with `total_score < 1` are excluded (`MIN_SCORE=1`)
- Remaining entries are sorted descending by score

**Step 3 -- Greedy selection**: Iterates scored entries in score order. An entry is selected if:
- Fewer than 10 files have been selected so far (`MAX_FILES=10`)
- Adding the entry would not exceed the 4000-token budget (`TOKEN_BUDGET=4000`)

**Step 4 -- Output**: Selected files are wrapped in `<literature-context>` with headings
showing each file's title and relevance score.

### Mode B: fallback scan

Used when `specs/literature/index.json` does not exist, or when the task description is empty.

The script scans `specs/literature/` recursively for `*.md` and `*.txt` files, sorts them
lexicographically, and includes each file that fits within the remaining token budget (using the
`(word_count * 13 + 5) / 10` estimation). Headings show the file's basename.

**Implication**: Without `index.json`, all files in the directory are candidates regardless of
relevance, and selection is purely first-fit by alphabetical order. For more than a few papers,
create `index.json` to enable keyword scoring.

## Adding New Papers

### Step 1: Prepare the source material

Convert the paper to plain text or Markdown. If the paper is longer than ~3000 tokens (~2300
words), split it into section files inside a subdirectory.

**Flat paper** (short):
```
specs/literature/Author_Year_Title.md
```

**Long document** (chunked):
```
specs/literature/Author_Year_Title/sec01_slug.md
specs/literature/Author_Year_Title/sec02_slug.md
```

### Step 2: Estimate token counts

For each file, run:

```bash
echo $(( ($(wc -w < specs/literature/Author_Year_Title.md) * 13 + 5) / 10 ))
```

Record the output as the `token_count` value for that file's index entry.

### Step 3: Choose keywords

Select 5-10 keywords that capture the core concepts of the paper or section. Keywords should
match the vocabulary an agent would naturally use when describing a task that needs this paper.

Good keywords are: domain-specific nouns (`modal`, `completeness`, `canonical`), algorithm
names, formal system names, and key technical terms.

Avoid generic terms (`paper`, `introduction`, `section`) that appear in most documents.

### Step 4: Write the index entry

If `specs/literature/index.json` does not exist, create it with an empty `entries` array first:

```json
{
  "entries": []
}
```

Add one entry per file (or per section for chunked documents) to the `entries` array. Use the
template from the schema section above. Ensure:
- `id` is unique across all entries
- `path` is relative to `specs/literature/` (not an absolute path)
- `token_count` matches the estimate from Step 2
- `keywords` reflects the task vocabulary where this paper is relevant
- `summary` is a single sentence capturing the file's content

### Step 5: Validate the index

```bash
jq . specs/literature/index.json
```

A clean exit with formatted output confirms the file is valid JSON.

### Step 6: Test the injection

Run a command with `--lit` and a relevant task description to verify the paper appears:

```bash
# Example: verify injection for a research task
/research 123 --lit
```

Check the agent context for a `<literature-context>` block containing the paper.

## Maintenance

- **Token counts go stale**: After editing a file, re-estimate its `token_count` using the
  formula above and update `index.json`.
- **Irrelevant files are selected**: Tighten `keywords` to better match task vocabulary, or
  remove generic keywords.
- **Files are never selected**: Check that `keywords` overlaps with terms appearing in the task
  descriptions for the tasks that should use this paper.
- **Budget exhausted before high-priority files**: Reduce chunk sizes or split large files.
