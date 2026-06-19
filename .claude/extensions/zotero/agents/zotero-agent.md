---
name: zotero-agent
description: Manage Zotero library integration via per-repo index, PDF chunking, and --zot context injection. Invoke for /zotero command.
model: sonnet
allowed-tools: Bash, Read, Write, Edit, AskUserQuestion
---

# Zotero Agent

## Overview

This agent documents the `/zotero` command's direct-execution architecture. The agent file
exists for documentation purposes and system discoverability. During normal `/zotero` command
execution, `skill-zotero` runs inline (direct execution) without spawning this agent as a
subagent.

**Architecture**: Direct-execution pattern (like `/literature`, `/distill`, `/fix-it`). The
skill manages all index operations, PDF chunking, and Zotero interaction inline using
`AskUserQuestion` for interactive search mode.

**Two-tier model**: Global Zotero library (SQLite) accessed via `zot` CLI; per-repo
`specs/zotero-index.json` as curated relevance filter for `--zot` context injection.

## Execution Pattern

```
/zotero [--setup|--add KEY [--chunk]|--remove KEY [--delete-chunks]|--convert KEY|
         --attach KEY|--search "QUERY"|--sync|--validate|--status]
    |
    v
.claude/commands/zotero.md  (argument parsing)
    |
    v
skill-zotero (direct execution -- no agent subagent spawned)
    |
    +-- Status mode: show zot connectivity, index item count, token budget
    |
    +-- Setup mode: detect ZOT_DATA_DIR, validate zotero.sqlite, create index
    |     |
    |     +-- zotero-setup.sh --configure
    |
    +-- Add mode: fetch item metadata from Zotero, add to per-repo index
    |     |
    |     +-- zotero-index-add.sh KEY [--chunk]
    |     |     |
    |     |     +-- zotero-read.sh item KEY -> extract metadata
    |     |     +-- Build 20-field index entry
    |     |     +-- Update specs/zotero-index.json
    |     |     +-- If --chunk: zotero-chunk.sh KEY
    |
    +-- Remove mode: remove item from per-repo index
    |     |
    |     +-- zotero-index-remove.sh KEY [--delete-chunks]
    |     |     |
    |     |     +-- Find entry in specs/zotero-index.json
    |     |     +-- If --delete-chunks: rm -rf specs/literature/{citation_key}/
    |     |     +-- jq del filter -> update specs/zotero-index.json
    |
    +-- Convert mode: extract PDF text, chunk into sections
    |     |
    |     +-- zotero-chunk.sh KEY
    |     |     |
    |     |     +-- zotero-read.sh item KEY -> get citation_key, title
    |     |     +-- zotero-read.sh pdf KEY -> extract full text
    |     |     +-- literature-chunk.sh -> split into sections
    |     |     +-- Save to specs/literature/{citation_key}/
    |     |     +-- Update specs/zotero-index.json (has_chunks, chunk_dir, chunk_count)
    |
    +-- Attach mode: upload chunks as Zotero child attachments
    |     |
    |     +-- zotero-attach-chunks.sh KEY
    |     |     |
    |     |     +-- Read chunk_dir from specs/zotero-index.json
    |     |     +-- For each .md in chunk_dir:
    |     |     |     +-- zotero-write.sh attach-file KEY chunk.md --idempotency-key ...
    |     |     +-- Report success/failure per chunk
    |
    +-- Search mode: search index with Zotero library fallback
    |     |
    |     +-- zotero-search-index.sh "QUERY" --format pretty
    |     |     |
    |     |     +-- Score entries by weighted multi-field formula
    |     |     +-- If index empty: fallback to zotero-read.sh search "QUERY"
    |     |     +-- AskUserQuestion (multiSelect) to add results to index
    |
    +-- Sync mode: re-fetch metadata for all index entries
    |     |
    |     +-- Loop: zotero-index-add.sh KEY for each entry
    |
    +-- Validate mode: check index entry consistency
    |     |
    |     +-- Check each entry: PDF path exists, chunk dir non-empty
    |     +-- Report broken paths and suggest remediation
    |
    +-- Status (verbose) mode: full library stats and index health
          |
          +-- zotero-setup.sh --status
          +-- Per-entry listing from specs/zotero-index.json
```

### Context Injection Pattern (--zot flag)

The `--zot` flag is handled by `command-route-skill.sh`, not by this skill directly:

```
/research N --zot  (or /plan N --zot, /implement N --zot)
    |
    v
command-route-skill.sh
    |
    +-- ZOT_FLAG=true detected
    |
    +-- ZOTERO_CONTEXT=$(zotero-retrieve.sh "$description" "$task_type")
    |     |
    |     +-- Read specs/zotero-index.json
    |     +-- Extract query terms from description (stop-word filtered, length > 3)
    |     +-- Score each entry by weighted formula (threshold >= 4)
    |     +-- Greedy-select within TOKEN_BUDGET
    |     |     +-- has_chunks=true: literature-search.sh for chunk selection
    |     |     +-- has_pdf=true: metadata block + "run /zotero --convert KEY"
    |     |     +-- metadata only: available fields block
    |     +-- Emit <zotero-context> block (or empty string on graceful failure)
    |
    +-- Inject ZOTERO_CONTEXT into agent prompt after <literature-context>
    |
    v
skill-{task_type} (with <zotero-context> in prompt)
```

### Graceful Degradation Path

```
--zot flag active, but zot not installed:
    |
    v
zotero-retrieve.sh
    |
    +-- Precondition check: specs/zotero-index.json exists?
    |     NO -> exit 0, emit empty string
    |     YES -> continue
    |
    +-- Score entries (no zot call needed for scoring)
    |
    +-- For items with has_chunks=true:
    |     +-- literature-search.sh for chunk selection
    |     +-- No zot call needed (chunks already exist as .md files)
    |
    +-- For items without chunks:
    |     +-- Emit metadata block with "run /zotero --convert KEY" note
    |
    v
<zotero-context> block emitted with available data (no error)
```

## Script Categories and Task Map

| Category | Scripts | Implementing Task |
|----------|---------|------------------|
| A: CLI Wrappers | zotero-read.sh, zotero-write.sh, zotero-setup.sh | Task 750 |
| B: Chunk Pipeline | zotero-chunk.sh, zotero-attach-chunks.sh | Task 752 |
| C: Index Management | zotero-index-add.sh, zotero-index-remove.sh, zotero-search-index.sh | Task 751 |
| D: Context Injection | zotero-retrieve.sh | Task 753 |

Until each task is implemented, the corresponding scripts exit with code 2 ("not configured"),
causing the skill to display graceful "not yet implemented" messages.

## Tool Usage

| Tool | Purpose |
|------|---------|
| Bash | Run zot scripts, check configuration, validate index entries |
| Read | Read specs/zotero-index.json, chunk files |
| Write | Initialize specs/zotero-index.json, update entries |
| Edit | Update existing index entries |
| AskUserQuestion | Search results multi-select, import confirmation |

## Related Files

- `.claude/commands/zotero.md` - Command entry point (argument parsing)
- `.claude/skills/skill-zotero/SKILL.md` - All implementation logic
- `.claude/extensions/zotero/scripts/` - Script stubs (all exit 2 until implemented)
- `specs/zotero-index.json` - Per-repo relevance filter (created at project root by setup)
- `specs/literature/{citation_key}/` - Chunk storage (shared with literature extension)

## Index Schema Summary

`specs/zotero-index.json` has 20 entry fields. Key fields for retrieval scoring:

| Field | Weight | Notes |
|-------|--------|-------|
| `title` | 4 | Highest signal: query term in title |
| `tags` | 3 | User-curated expert classification |
| `abstract_snippet` | 2 | Author-provided description (first 300 chars) |
| `keywords` | 2 | Author-supplied keywords |
| `collections` | 1 | Collection membership (broad signal) |
| `notes_summary` | 1 | User's own notes (first 200 chars) |

Minimum score threshold for inclusion in `--zot` context: **4** (vs `--lit`'s threshold of 1).
