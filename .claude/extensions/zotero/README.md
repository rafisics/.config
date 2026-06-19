# Zotero Extension

Zotero library integration for the Claude Code agent system. Connects your Zotero library to
agent context via a curated per-repo index and the `--zot` flag.

## Prerequisites

- **zotero-cli-cc v0.7.0** (`zot`): `pip install zotero-cli-cc`
- Zotero desktop application with your library (must have `zotero.sqlite`)
- Optional: Zotero Web API key (only needed for `/zotero --attach`)

## Quick Start

```bash
# 1. Install zot CLI
pip install zotero-cli-cc

# 2. Run setup wizard (detects Zotero data directory, validates access)
/zotero --setup

# 3. Add a paper to the per-repo index (KEY = 8-char Zotero item key)
/zotero --add Z7T6Q25X

# 4. Use --zot flag to inject relevant papers as context
/research 42 --zot
/plan 42 --zot
/implement 42 --zot
```

## Common Workflows

### Add a Paper to the Project Index

```bash
# Add metadata only (fast)
/zotero --add Z7T6Q25X

# Add metadata and chunk the PDF immediately
/zotero --add Z7T6Q25X --chunk
```

### Search for Papers

```bash
# Search per-repo index (falls back to full Zotero library if index is empty)
/zotero --search "modal logic completeness"
```

### Convert a PDF to Markdown Chunks

```bash
# Extract text from Zotero PDF, split into sections, update index
/zotero --convert Z7T6Q25X
```

### Upload Chunks to Zotero

```bash
# Upload markdown chunks as child attachments (requires ZOTERO_API_KEY)
/zotero --attach Z7T6Q25X
```

### Use Zotero Context in Agent Tasks

```bash
# Inject relevant Zotero items as <zotero-context> into agent prompts
/research 42 --zot
/plan 42 --zot --lit    # Use both Zotero and literature context
/implement 42 --zot --clean    # Zotero context only (suppress memory)
```

### Index Management

```bash
# Show library status and index summary
/zotero

# Full status report with library stats
/zotero --status

# Re-sync all index entries from current Zotero metadata
/zotero --sync

# Validate index: check PDF paths and chunk directories
/zotero --validate

# Remove item from index
/zotero --remove Z7T6Q25X

# Remove item and delete its chunk files
/zotero --remove Z7T6Q25X --delete-chunks
```

## Graceful Degradation

The extension is designed for offline-first operation and degrades gracefully:

| Condition | Behavior |
|-----------|---------|
| `zot` not installed | Exit 2; suggest `pip install zotero-cli-cc` |
| `ZOT_DATA_DIR` not set | Exit 2; suggest `/zotero --setup` |
| `specs/zotero-index.json` missing | Exit 2; suggest `/zotero --setup` |
| Index is empty | `--zot` emits empty context silently (not an error) |
| No items score above threshold | `--zot` emits empty context silently |
| PDF path missing | Skip PDF extraction; use metadata block only |
| `ZOTERO_API_KEY` not set | Exit 2 for write operations only; reads still work |

## Per-Repo Index: specs/zotero-index.json

Each project maintains its own `specs/zotero-index.json` with items explicitly curated for
that project. This file is committed to the repository.

- Items are added via `/zotero --add KEY`
- Only indexed items are scored for `--zot` context injection
- The full Zotero library (800+ items) is never scanned during agent invocation

## Script Architecture

| Script | Category | Purpose |
|--------|----------|---------|
| `zotero-read.sh` | A: CLI Wrappers | Read-only Zotero operations via `zot` |
| `zotero-write.sh` | A: CLI Wrappers | Write operations via Zotero Web API |
| `zotero-setup.sh` | A: CLI Wrappers | Setup wizard and validation |
| `zotero-chunk.sh` | B: Chunk Pipeline | Extract PDF text and chunk into sections |
| `zotero-attach-chunks.sh` | B: Chunk Pipeline | Upload chunks as Zotero attachments |
| `zotero-index-add.sh` | C: Index Management | Add item to per-repo index |
| `zotero-index-remove.sh` | C: Index Management | Remove item from per-repo index |
| `zotero-search-index.sh` | C: Index Management | Search index with scoring |
| `zotero-retrieve.sh` | D: Context Injection | Score and retrieve context for `--zot` |

## Configuration

### Environment Variables

| Variable | Purpose | Required |
|----------|---------|---------|
| `ZOT_DATA_DIR` | Path to Zotero data directory | Set via `/zotero --setup` |
| `ZOTERO_API_KEY` | Web API key for write operations | Only for `--attach` |
| `TOKEN_BUDGET` | Override default token budget (8000) | Optional |
| `LITERATURE_DIR` | Override chunk storage directory | Optional |

### First-Time Configuration

```bash
# Automatic detection and configuration
/zotero --setup

# The setup wizard:
# 1. Detects ZOT_DATA_DIR automatically
# 2. Validates zotero.sqlite access via zot stats
# 3. Creates specs/zotero-index.json with detected ZOT_DATA_DIR
# 4. Optionally prompts for ZOTERO_API_KEY (for --attach operations)
```

## Relationship to Literature Extension

This extension depends on the literature extension and reuses its chunk storage:
- Chunks are stored in `specs/literature/{citation_key}/` (same as literature extension)
- `literature-chunk.sh` and `literature-search.sh` are reused for PDF processing
- Items chunked via `/zotero --convert` are also accessible via `--lit` if indexed there

The two systems are complementary, not mutually exclusive.

## Implementation Status

| Task | Scope | Status |
|------|-------|--------|
| Task 749 | Extension skeleton (this directory) | Complete |
| Task 750 | CLI wrapper scripts (read/write/setup) | Not started |
| Task 751 | Index management scripts (add/remove/search) | Not started |
| Task 752 | Chunk pipeline (convert/attach) | Not started |
| Task 753 | Context injection (`--zot` flag wiring) | Not started |

Scripts exit with code 2 ("not configured") until their implementing task is complete.
