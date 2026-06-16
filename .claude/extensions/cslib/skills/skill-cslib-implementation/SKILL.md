---
name: skill-cslib-implementation
description: Implement CSLib proofs following Lean 4 and CSLib contribution standards. Invoke for cslib implementation tasks.
allowed-tools: Agent, Bash, Edit, Read, Write
---

# CSLib Implementation Skill

Thin wrapper that delegates CSLib proof implementation to `cslib-implementation-agent` subagent.

## Trigger Conditions

This skill activates when:
- Task type is "cslib"
- /implement command targets a CSLib task
- Lean 4 proofs or CSLib definitions need to be created or modified

## Execution Flow

### Stage 1: Input Validation
Validate task_number exists, task_type is "cslib", and an implementation plan is present.

### Stage 2: Preflight Status Update
Update status to "implementing" BEFORE invoking subagent.

### Stage 2b: Preflight Cache Warming

Ensure Mathlib cache is warm before delegating to the agent:

```bash
cd /home/benjamin/Projects/cslib && lake exe cache get 2>&1 || echo "Warning: cache fetch failed (non-fatal)"
```

This is non-blocking. Cache fetch failure does not prevent delegation. On a cache hit, this
completes in ~1-2 minutes and prevents 30-45 minute Mathlib rebuilds during CI verification.

### Stage 3: Prepare Delegation Context

Domain-specific context for the cslib-implementation-agent:
- CSLib coding standards from `.claude/extensions/cslib/context/`
- Verification: `lake build`, `lake test`, `lake lint`, `lake exe checkInitImports`, `lake exe lint-style`, `lake shake`
- lean-lsp MCP tools for proof state inspection (inherited via lean dependency)

```json
{
  "session_id": "sess_{timestamp}_{random}",
  "delegation_depth": 1,
  "delegation_path": ["orchestrator", "implement", "skill-cslib-implementation"],
  "timeout": 7200,
  "task_context": {
    "task_number": N,
    "task_name": "{project_name}",
    "description": "{description}",
    "task_type": "cslib"
  },
  "plan_path": "specs/{NNN}_{SLUG}/plans/MM_{short-slug}.md",
  "orchestrator_mode": true,
  "metadata_file_path": "specs/{NNN}_{SLUG}/.return-meta.json"
}
```

### Stage 4: Invoke Subagent
Use Agent tool with subagent_type: "cslib-implementation-agent".

### Stage 4b: Self-Execution Fallback

**CRITICAL**: If you performed the work above WITHOUT using the Agent tool (i.e., you read files,
wrote artifacts, or updated metadata directly instead of spawning a subagent), you MUST write a
`.return-meta.json` file now before proceeding to postflight. Use the schema from
`return-metadata-file.md` with the appropriate status value for this operation.

If you DID use the Agent tool, skip this stage -- the subagent already wrote the metadata.

## Postflight (ALWAYS EXECUTE)

The following stages MUST execute after work is complete, whether the work was done by a
subagent or inline (Stage 4b). Do NOT skip these stages for any reason.

### Stage 5: Parse Subagent Return
Read the metadata file from `specs/{N}_{SLUG}/.return-meta.json`.

### Stage 6: Update Task Status (Postflight)
Update state.json and TODO.md based on result.

### Stage 7: Link Artifacts
Add artifact to state.json with summary. Update TODO.md per `@.claude/context/patterns/artifact-linking-todo.md` with `field_name=**Summary**`, `next_field=**Description**`.

### Stage 8: Git Commit
Commit changes with session ID.

### Stage 9: Return Brief Summary

## MUST NOT (Postflight Boundary)

After the agent returns, this skill MUST NOT:

1. **Edit .lean files** - All CSLib proof work is done by agent
2. **Run lake build/test/lint** - Verification is done by agent
3. **Use lean-lsp MCP tools** - Domain tools are for agent use only
4. **Grep for sorries** - Debt analysis is agent work
5. **Write summary/reports** - Artifact creation is agent work

> **PROHIBITION**: If the subagent returned partial or failed status, the lead skill MUST NOT attempt to continue, complete, or "fill in" the subagent's work. Report the partial/failed status and let the user re-run `/implement` to resume.

The postflight phase is LIMITED TO:
- Reading agent metadata file
- Updating state.json via jq
- Updating TODO.md status marker via Edit
- Linking artifacts in state.json
- Git commit
- Cleanup of temp/marker files

Reference: @.claude/context/standards/postflight-tool-restrictions.md

## Return Format

Brief text summary (NOT JSON).
