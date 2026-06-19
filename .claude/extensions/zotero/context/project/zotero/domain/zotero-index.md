# Zotero Index Schema and Workflow

<!-- Content populated in task 751 -->

This file provides the per-repo `specs/zotero-index.json` schema reference and workflow
guide for agents using the zotero extension.

## Overview

The per-repo index (`specs/zotero-index.json`) is the Tier 2 component of the two-tier
data model. It contains a curated subset of the user's full Zotero library, filtered for
relevance to the current project.

## Schema Summary (Placeholder)

<!-- Full schema documentation populated in task 751 -->

### Top-Level Fields

| Field | Type | Purpose |
|-------|------|---------|
| `version` | string | Schema version (current: "1.0") |
| `created` | ISO8601 | When index was first created |
| `last_updated` | ISO8601 | When index was last modified |
| `token_budget` | integer | Default token budget for --zot injection (default: 8000) |
| `zot_data_dir` | string | Absolute path to Zotero data directory |
| `entries` | array | Array of index entry objects |

### Entry Fields (20 fields)

See task 748 architecture design (Section 4) for the complete 20-field entry schema.

Key fields for retrieval scoring:
- `title` — weight 4 in scoring formula
- `tags` — weight 3 (user-curated)
- `abstract_snippet` — weight 2 (first 300 chars)
- `keywords` — weight 2 (author-supplied)
- `collections` — weight 1
- `notes_summary` — weight 1 (first 200 chars)

Minimum threshold for `--zot` inclusion: `total_score >= 4`

## Workflow for Agents

When `--zot` is active and `<zotero-context>` is injected:

1. Items in the context block have been scored and selected based on task description
2. Items with `has_chunks=true` provide actual text content from PDF sections
3. Items with `has_pdf=true` but no chunks provide metadata blocks with a conversion note
4. Items in the context are highly relevant — treat them as authoritative references

To add an item to the per-repo index: `/zotero --add KEY`
To convert a PDF to chunks: `/zotero --convert KEY`
To view index status: `/zotero` or `/zotero --status`
