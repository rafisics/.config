# Retrieval Flags: --zot vs --lit Coexistence

This file documents when to use `--zot` vs `--lit` flags, how they interact, and the
coexistence strategy for using both simultaneously.

## Overview

The `--zot` and `--lit` flags are independent context injection mechanisms:
- `--lit` injects chunks from `specs/literature/` (all files, looser threshold)
- `--zot` injects chunks from `specs/zotero-index.json` entries (curated, higher threshold)

## Coexistence Table

| Flags | Memory | Literature | Zotero |
|-------|--------|------------|--------|
| (none) | active | inactive | inactive |
| `--clean` | suppressed | inactive | inactive |
| `--lit` | active | active | inactive |
| `--zot` | active | inactive | active |
| `--lit --zot` | active | active | active |
| `--clean --lit` | suppressed | active | inactive |
| `--clean --zot` | suppressed | inactive | active |
| `--clean --lit --zot` | suppressed | active | active |

## When to Use Which

**Use `--lit`** when:
- Documents not in Zotero (local PDFs, internal documents)
- Literature directory built before zotero extension was installed
- Task does not involve academic papers

**Use `--zot`** when:
- Project has a curated `specs/zotero-index.json`
- Task involves papers tracked in your Zotero library
- Retrieval precision matters (higher threshold reduces noise)

**Use both (`--lit --zot`)** when:
- Project mixes Zotero-tracked papers with locally-managed documents
- Maximizing recall is more important than token budget

**Token budget**: Combined `--lit --zot` may inject up to 16,000 tokens. Each flag uses its
own independent budget (default: 8000 tokens each).

## Scoring Thresholds

| Flag | Threshold | Rationale |
|------|-----------|-----------|
| `--lit` | >= 1 | Broader recall; items manually placed in specs/literature/ |
| `--zot` | >= 4 | Precision focus; items explicitly curated in per-repo index |

## Chunk Storage Overlap

Both flags retrieve from `specs/literature/{citation_key}/`. Items chunked via
`/zotero --convert KEY` are also discoverable by `--lit` (and vice versa). This
shared storage is intentional — no duplication required.
