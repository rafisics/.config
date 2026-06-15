## Literature Extension

Manage `specs/literature/` directories: scan for unprocessed PDFs/DJVUs, convert them to markdown with content-aware chunking, maintain `index.json`, and validate filesystem consistency.

### Key Conventions

**Source file co-location**: PDF/DJVU source files live in the same `specs/literature/` directory or subdirectory as their converted markdown. Source files are gitignored via `specs/literature/**/*.pdf` and `specs/literature/**/*.djvu`.

**Content-aware chunking**: Documents are split at logical section boundaries (chapters, numbered sections, markdown headings) with a 4,000-line threshold. Adjacent small sections are merged. Falls back to mechanical 4,000-line splits when no headings are detected. Output uses structure-aware naming (`sectionNN_slug.md`) or fallback naming (`{basename}_partNN.md`).

**Enriched index schema**: Each `index.json` entry includes: `id`, `path`, `token_count`, `keywords`, `summary`, `authors`, `title`, `year`, `doc_type` (paper/book/chapter/section), `source_format` (pdf/djvu/manual), `parent_doc` (for section chunks), and `page_range`.

### Skill-Agent Mapping

| Skill | Agent | Purpose |
|-------|-------|---------|
| skill-literature | (direct execution) | Scan, convert, validate, and index literature files |

### Commands

| Command | Usage | Description |
|---------|-------|-------------|
| `/literature` | `/literature` | Show specs/literature/ status and index health |
| `/literature` | `/literature --scan` | Scan for unprocessed PDFs/DJVUs |
| `/literature` | `/literature --convert [FILE]` | Convert PDF/DJVU to markdown with content-aware chunking |
| `/literature` | `/literature --validate` | Validate index.json against filesystem |
| `/literature` | `/literature --index FILE` | Add/update index entry for existing markdown file |
