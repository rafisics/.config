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

---

## Directory Convention

PDF/DJVU source files are **co-located** with their converted markdown in the same directory.
Source files are gitignored (via `specs/literature/**/*.pdf` and `specs/literature/**/*.djvu`)
and must be re-added manually after checkout.

```
specs/literature/
  index.json                        # Root literature index
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
