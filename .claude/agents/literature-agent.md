---
name: literature-agent
description: Manage specs/literature/ — scan, convert PDFs/DJVUs, maintain index.json. Invoke for /literature command.
model: sonnet
allowed-tools: Bash, Read, Write, Edit, AskUserQuestion
---

# Literature Agent

## Overview

This agent documents the `/literature` command's direct-execution architecture. The agent file exists for documentation purposes and system discoverability. During normal `/literature` command execution, `skill-literature` runs inline (direct execution) without spawning this agent as a subagent.

**Architecture**: Direct-execution pattern (like `/distill`, `/fix-it`, `/refresh`). The skill manages all PDF/DJVU-to-markdown conversion, index.json maintenance, and filesystem validation inline using `AskUserQuestion` for interactivity.

## Execution Pattern

```
/literature [--scan|--convert [FILE]|--validate|--index FILE]
    |
    v
.claude/commands/literature.md  (argument parsing)
    |
    v
skill-literature (direct execution — no agent subagent spawned)
    |
    +-- Status mode: read index.json, scan for PDFs/DJVUs, show health report
    +-- Scan mode: find unprocessed files, show with page counts
    +-- Convert mode: pdftotext -> markdown + index.json updates (with AskUserQuestion)
    +-- Validate mode: check index.json against filesystem, report drift
    +-- Index mode: add/update entry for existing markdown file (with AskUserQuestion)
```

## Tool Usage

| Tool | Purpose |
|------|---------|
| Bash | Run pdftotext, pdfinfo, djvutxt, wc; check tool availability |
| Read | Read index.json, existing markdown files |
| Write | Write new markdown conversions, initialize index.json |
| Edit | Update existing index.json entries |
| AskUserQuestion | Present chunk boundaries, keywords, summary for user confirmation |

## Related Files

- `.claude/commands/literature.md` - Command entry point (argument parsing)
- `.claude/skills/skill-literature/SKILL.md` - All implementation logic
- `specs/literature/index.json` - Literature index (root level)
- `specs/literature/*/index.json` - Subdirectory indexes (chunked documents)

## Index Schema

Root `specs/literature/index.json`:
```json
{
  "token_budget": 4000,
  "entries": [
    {
      "id": "author_year",
      "path": "author_year.md",
      "token_count": 3500,
      "keywords": ["keyword1", "keyword2"],
      "summary": "Brief description of the document content."
    }
  ]
}
```

Subdirectory `specs/literature/author_year/index.json`:
```json
{
  "title": "Document Title",
  "chapters": [
    { "file": "ch01_intro.md" },
    { "file": "ch02_background.md" }
  ]
}
```
