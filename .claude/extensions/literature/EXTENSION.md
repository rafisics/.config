## Literature Extension

Manage literature directories: scan for unprocessed PDFs/DJVUs, convert them to markdown with
content-aware chunking, maintain `index.json`, validate filesystem consistency, and search or
import papers from Zotero via Better BibTeX CSL-JSON export.

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
| `/literature` | `/literature --search "QUERY"` | Search Zotero library and Literature/ index by keyword |
| `/literature` | `/literature --task N` | Extract task N description as Zotero search query |

### /cite Command

Verify citation claims in task artifacts against the Literature/ index and Zotero library. Extracts citations from task reports, plans, and summaries; scores each against available sources; and creates research tasks for claims that cannot be verified.

| Command | Usage | Description |
|---------|-------|-------------|
| `/cite` | `/cite N` | Verify all citations in task N artifacts |
| `/cite` | `/cite N --gaps` | Also flag citations found in Zotero but lacking a PDF |

**Workflow**:
1. **Extract** — `cite-extract.sh` scans artifact files (.md) under `specs/{NNN}_{SLUG}/` and identifies citation patterns: author-year `(Smith, 2020)`, parenthetical `(Author et al.)`, theorem attributions, direct quotes, numeric bracket `[1]`, LaTeX `\cite{key}`, and others.
2. **Search** — Each extracted citation is matched against `specs/literature/index.json` (keyword overlap scoring) and the Zotero library via `zotero-search.sh` (if configured).
3. **Score** — Citations are classified by confidence:
   - **confirmed**: Zotero top-result score ≥ 3 OR index keyword overlap ≥ 2
   - **partial**: Zotero score 1–2 OR index overlap == 1 (weak match, may need review)
   - **unconfirmed**: No match in either source
   - **gap** (with `--gaps`): Source found in Zotero but no PDF available locally
4. **Select** — Results are displayed grouped by status. Unconfirmed, gap, and partial citations are presented via interactive `AskUserQuestion` multiSelect for user selection.
5. **Create tasks** — A research/verification task is created in `state.json` for each selected citation, with description, source location, pattern type, and suggested search queries.

**Output format** (Step 9 display):
```
## Citation Verification Results

Task: #{N} — {task_slug}
Artifacts Scanned: {count} files
Citations Found: {total} total
  - Confirmed: N
  - Partial: N
  - Unconfirmed: N
  - Gap: N

### Confirmed — No action needed
| Claim | Source | File | Match |

### Partial Matches — May need verification
| Claim | Source | File | Best Match |

### Unconfirmed — No source found
| Claim | Source | File | Pattern |
```

**Dependencies**: `cite-extract.sh` (pattern extraction), `zotero-search.sh` (Zotero search, optional), `specs/literature/index.json` (Literature/ index, optional). Both external sources degrade gracefully — if Zotero is unavailable, index-only matching is used; if the index is missing, Zotero-only matching is used.
