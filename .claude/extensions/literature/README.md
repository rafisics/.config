# Literature Extension (v2.0.0)

Unified extension for managing the global Literature/ repository and per-repo sub-indices.
Handles source discovery, PDF/DJVU-to-markdown conversion, FTS5-backed search, and agent
context briefing. Absorbs the former zotero extension.

## Loading the Extension

```
Extension picker -> select "literature"
```

---

## Architecture Overview

### Single Source of Truth: Global Literature/ Repo

All converted literature lives in `~/Projects/Literature/` (configured via `LITERATURE_DIR` in
`.claude/settings.json`). The global repo contains:
- `index.json` — Enriched v2 metadata for every document (222+ entries)
- `sources/` — Converted markdown files organized by document
- `.literature.db` — SQLite FTS5 database for full-text search
- `zotero-library.json` — Better BibTeX CSL-JSON export (auto-updated by Zotero)

Per-project copies of content are **not maintained**. Agents access the global repo directly
via absolute paths.

### Per-Repo Sub-Index: `specs/literature-index.json`

Each project maintains a lightweight reference index listing which global documents are
relevant to that project. Entries are reference-only (doc_id pointers); no metadata is cached.

```json
{
  "project": "nvim",
  "literature_dir": null,
  "entries": [
    {
      "doc_id": "blackburn_2001_modal_logic",
      "relevance": "Core reference for modal logic formalization",
      "added": "2026-06-23",
      "source": "discover"
    }
  ]
}
```

Sub-index operations are provided by `/literature` (Mode B) and `skill-literature`.

### Briefing+Tools Pattern for Agents

When `--lit` is passed to `/research`, `/plan`, `/implement`, or `/orchestrate`:

1. `literature-briefing.sh` reads `specs/literature-index.json`
2. Resolves each `doc_id` against `$LITERATURE_DIR/index.json` to get metadata
3. Outputs a `<literature-briefing>` block (~300-500 tokens) into the agent prompt

Agents then use existing tools on-demand:
- **Read specific chunks**: `Read` tool with absolute paths from the briefing
- **Search full corpus**: `bash .claude/scripts/literature-search.sh "query"`
- **Browse TOC**: `bash .claude/scripts/literature-search.sh --toc doc_id`
- **Get related entries**: `bash .claude/scripts/literature-search.sh --refs doc_id`

This is strictly cheaper than full content injection (~300 tokens briefing vs 4,000-8,000
tokens injection) while enabling selective, on-demand access to the entire corpus.

---

## Commands

Two modes, one command:

| Command | Mode | Description |
|---------|------|-------------|
| `/literature N` | Discover (A) | Find sources relevant to task N |
| `/literature "query"` | Discover (A) | Find sources matching the query |
| `/literature N "query"` | Discover (A) | Find sources using task+query |
| `/literature` | Integrate (B) | Status report + scan for unprocessed files |
| `/literature ~/path/to/file.pdf` | Integrate (B) | Ingest a specific PDF/DJVU |
| `/literature ~/path/to/dir/` | Integrate (B) | Ingest all PDFs in a directory |
| `/literature --validate` | Both | Validate sub-index against global index |

### Mode A: Source Discovery

Runs a three-tier discovery pipeline via `literature-discover.sh`:
1. **Tier 1 (offline)**: Search `$LITERATURE_DIR/index.json` by title/keyword
2. **Tier 2 (local)**: Search Zotero library (`zotero-library.json`) for available PDFs
3. **Tier 3 (online)**: Semantic Scholar API, Unpaywall DOI lookup, arXiv direct PDF

Results are presented interactively. Selected items are added to `specs/literature-index.json`.
Unresolved items are appended to `specs/literature/SOURCES.md` for later acquisition.

### Mode B: Integration

Processes source files (PDF/DJVU) through the ingestion pipeline:
1. Runs `literature-ingest.sh` for conversion and FTS5 indexing
2. Updates `specs/literature-index.json` with new doc_ids
3. Marks entries as `[RESOLVED]` in `SOURCES.md`

---

## --lit Flag Semantics

Pass `--lit` to any research/plan/implement command to enable literature context:

```bash
/research 42 --lit        # Research with literature briefing
/implement 42 --lit       # Implement with literature briefing
/orchestrate 42 --lit     # Full lifecycle with literature briefing
```

**What changes**: `<literature-briefing>` block appears in agent prompt (not `<literature-context>`).
Agents get a compact catalog of available papers with paths; they fetch what they need.

**When to use**: Any task that implements from a paper, proves a theorem, or requires
verifiable citations. The briefing costs ~300 tokens; follow-up reads cost tokens proportional
to what the agent actually reads.

No `--zot` flag exists. All Zotero functionality is accessed via Mode A discovery or the
`zotero-search.sh` script directly.

---

## Zotero Integration

Zotero integration is internal to this extension (absorbed from the former zotero extension).
Scripts are in `.claude/extensions/literature/scripts/zotero-*.sh`.

### Setup

1. Install **Better BibTeX** plugin for Zotero
2. File > Export Library > Better CSL JSON > "Keep updated"
3. Save to `~/Projects/Literature/zotero-library.json`
4. The export auto-updates whenever Zotero is open

### Available Scripts

| Script | Purpose |
|--------|---------|
| `zotero-search.sh` | Search CSL-JSON export by keyword (used by Mode A) |
| `zotero-read.sh` | Read item metadata and PDFs via `zot` CLI |
| `zotero-write.sh` | Write/attach files to Zotero items |
| `zotero-setup.sh` | Setup wizard: detect data dir, validate, configure |
| `zotero-chunk.sh` | Extract PDF text and chunk into sections |
| `zotero-attach-chunks.sh` | Upload chunks as Zotero child attachments |
| `zotero-index-add.sh` | Add item to per-repo `specs/literature-index.json` |
| `zotero-index-remove.sh` | Remove item from per-repo index |
| `cite-extract.sh` | Extract citation patterns from markdown artifacts |

---

## Content-Aware Chunking

Documents are split at logical section boundaries (chapters, numbered sections, markdown
headings) with a 4,000-line threshold. Adjacent small sections are merged. Falls back to
mechanical 4,000-line splits when no headings are detected.

Output naming:
- Structure-detected: `{dirname}/sectionNN_{slug}.md`
- Mechanical fallback: `{dirname}/{basename}_partNN.md`

---

## Global Index Schema (v2)

Each `index.json` entry in the global repo includes:

| Field | Type | Description |
|-------|------|-------------|
| `id` | string | Unique identifier (`doc_id`) |
| `path` | string | Path relative to `$LITERATURE_DIR` |
| `token_count` | integer | Estimated token count |
| `keywords` | string[] | Search and scoring keywords |
| `summary` | string | One-sentence description |
| `authors` | string[] | Author list |
| `title` | string | Full document or section title |
| `year` | integer\|null | Publication year |
| `doc_type` | string | `paper`, `book`, `chapter`, or `section` |
| `source_format` | string | `pdf`, `djvu`, or `manual` |
| `parent_doc` | string\|null | Parent entry ID for section chunks |
| `page_range` | string\|null | Page/line range in source document |
| `bib_key` | string\|null | BibTeX key from source .bib file |
| `zotero_key` | string\|null | Zotero/Better BibTeX canonical item key |
| `zotero_path` | string\|null | Path to PDF in Zotero storage |
| `project_tags` | string[] | Originating project names |

---

## Tool Requirements

- **pdftotext** (from poppler_utils): Required for PDF conversion
- **pdfinfo** (from poppler_utils): Used for page count detection
- **djvutxt** (from djvulibre): Required for DJVU conversion (optional)
- **zot** (zotero-cli-cc v0.7.0): Optional, for Zotero direct access

Install via Nix: `nix-env -iA nixpkgs.poppler_utils nixpkgs.djvulibre`

---

## Provided Artifacts

| Type | Name | Purpose |
|------|------|---------|
| Agent | literature-agent.md | Briefing+tools architecture description |
| Skill | skill-literature | All conversion, index, and sub-index operations |
| Skill | skill-cite | Citation verification against Literature/ and Zotero |
| Command | /literature | Discover (Mode A) and integrate (Mode B) entry point |
| Command | /cite | Citation verification command |
| Script | scripts/literature-briefing.sh | Generates `<literature-briefing>` blocks for agents |
| Script | scripts/literature-discover.sh | Three-tier source discovery pipeline |
