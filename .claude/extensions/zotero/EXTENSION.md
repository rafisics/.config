## Zotero Extension

Zotero library integration via the `zot` CLI tool (zotero-cli-cc v0.7.0). Uses a two-tier data
model: the full Zotero SQLite database as the global source and a per-repo
`specs/zotero-index.json` as a curated relevance filter for context injection.

Provides the `/zotero` command for library management and the `--zot` flag for context injection
into `/research`, `/plan`, and `/implement` commands.

### Two-Tier Data Model

| Tier | Location | Purpose |
|------|----------|---------|
| **Tier 1 (Global)** | `~/Documents/Zotero/zotero.sqlite` | Full library: all items, metadata, PDFs |
| **Tier 2 (Per-repo)** | `specs/zotero-index.json` | Relevance filter: which items matter to this project |

The per-repo index contains items the user has explicitly added via `/zotero --add KEY`. Only
these items are scored for context injection. The full Zotero library is accessed only via
`zot` CLI calls, never scanned wholesale.

### Skill-Agent Mapping

| Skill | Agent | Purpose |
|-------|-------|---------|
| skill-zotero | (direct execution) | Manage per-repo Zotero index, chunk PDFs, inject context |

### Commands

| Command | Usage | Description |
|---------|-------|-------------|
| `/zotero` | `/zotero` | Show library connectivity, index item count, and token budget |
| `/zotero` | `/zotero --setup` | Run setup wizard: detect data dir, validate, configure API key |
| `/zotero` | `/zotero --add KEY` | Add item from Zotero library to per-repo index |
| `/zotero` | `/zotero --add KEY --chunk` | Add item and immediately chunk its PDF |
| `/zotero` | `/zotero --remove KEY` | Remove item from per-repo index |
| `/zotero` | `/zotero --remove KEY --delete-chunks` | Remove item and delete its chunk files |
| `/zotero` | `/zotero --convert KEY` | Extract PDF, chunk into sections, update index |
| `/zotero` | `/zotero --attach KEY` | Upload chunks as Zotero child attachments |
| `/zotero` | `/zotero --search "QUERY"` | Search per-repo index with Zotero library fallback |
| `/zotero` | `/zotero --sync` | Re-fetch metadata for all index entries from Zotero |
| `/zotero` | `/zotero --validate` | Validate index entries: PDF paths, chunk directories |
| `/zotero` | `/zotero --status` | Full library stats and index health report |

### --zot Flag

The `--zot` flag injects relevant Zotero items as `<zotero-context>` into agent prompts.
Parallel to `--lit` in interface and injection order.

**Usage**: `/research N --zot`, `/plan N --zot`, `/implement N --zot`

**Context injection order** (when multiple context flags are active):
```
<memory-context>       <- from memory-retrieve.sh (suppressed by --clean)
<literature-context>   <- from literature-retrieve.sh (only when --lit)
<zotero-context>       <- from zotero-retrieve.sh (only when --zot)
[agent prompt]
```

**Retrieval scoring**: Multi-field weighted formula with threshold >= 4:
- Title match: weight 4 (highest signal)
- User tags: weight 3 (expert classification)
- Abstract: weight 2
- Keywords: weight 2
- Collections: weight 1
- Notes: weight 1

**Graceful degradation**: When `zot` is not installed, `ZOT_DATA_DIR` is unset, or
`specs/zotero-index.json` is missing, `--zot` emits empty context without error.

### Relationship to Literature Extension

The zotero extension depends on the literature extension and shares chunk storage in
`specs/literature/{citation_key}/`. Items chunked via `/zotero --convert KEY` are also
discoverable by `--lit` (if added to the literature index). The two systems are complementary:

**Use `--lit`** for documents not in Zotero or manually converted files.
**Use `--zot`** for curated academic papers tracked in your Zotero library.
**Use both** (`--lit --zot`) to maximize recall across both storage systems.
