## Literature Extension

Manage literature directories: scan for unprocessed PDFs/DJVUs, convert them to markdown with
content-aware chunking, maintain `index.json`, and validate filesystem consistency.

Supports both per-project `specs/literature/` directories and a shared centralized repository
via the `LITERATURE_DIR` environment variable.

### Centralized Repository (Recommended)

Set `LITERATURE_DIR=/home/benjamin/Projects/Literature` to use the shared centralized repo
instead of per-project `specs/literature/` directories. The `--lit` flag in `/research`,
`/plan`, and `/implement` reads from this central repo when the variable is set.

**Two-tier fallback**: If `LITERATURE_DIR` is set but the directory does not exist, the system
falls back to per-project `specs/literature/`. If `LITERATURE_DIR` is unset, per-project
directories are used directly.

**Configuration**: `LITERATURE_DIR` is set in `.claude/settings.json` (Claude Code sessions)
and `~/.dotfiles/home.nix` (shell sessions). See `~/Projects/Literature/README.md` for full
architecture documentation.

### Key Conventions

**Source file co-location**: PDF/DJVU source files live in the same literature directory or
subdirectory as their converted markdown. Source files are gitignored via
`specs/literature/**/*.pdf` and `specs/literature/**/*.djvu` (or the equivalent in the central
repo's `.gitignore`).

**Content-aware chunking**: Documents are split at logical section boundaries (chapters,
numbered sections, markdown headings) with a 4,000-line threshold. Adjacent small sections are
merged. Falls back to mechanical 4,000-line splits when no headings are detected. Output uses
structure-aware naming (`sectionNN_slug.md`) or fallback naming (`{basename}_partNN.md`).

**Enriched index schema (v2)**: Each `index.json` entry includes: `id`, `path`, `token_count`,
`keywords`, `summary`, `authors`, `title`, `year`, `doc_type` (paper/book/chapter/section),
`source_format` (pdf/djvu/manual), `parent_doc` (for section chunks), `page_range`,
`bib_key` (original BibTeX key), `zotero_key` (Zotero/Better BibTeX canonical key),
`zotero_path` (path to PDF in Zotero storage), and `project_tags` (list of originating
projects).

**Zotero integration**: The central repo supports Better BibTeX CSL-JSON auto-export to
`~/Projects/Literature/zotero-library.json`. Configure in Zotero: File > Export Library >
Better CSL JSON > "Keep updated" > save to `~/Projects/Literature/zotero-library.json`.

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
