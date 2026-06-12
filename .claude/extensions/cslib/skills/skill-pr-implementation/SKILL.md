---
name: skill-pr-implementation
description: PR branch and description preparation for CSLib tasks. Delegates to cslib-implementation-agent with PR-specific context and transitions task to [PR READY] instead of [COMPLETED]. Invoke for pr implementation tasks.
allowed-tools: Agent, Bash, Edit, Read, Write
---

# PR Implementation Skill

Thin wrapper that delegates PR preparation work to `cslib-implementation-agent` subagent with
PR-specific delegation context. The critical difference from `skill-cslib-implementation` is
the postflight status transition: this skill calls `pr_ready` (not `implement`), setting the
task to `[PR READY]` to direct the user to run `/merge`.

## Trigger Conditions

This skill activates when:
- Task type is "pr"
- /implement command targets a PR preparation task
- A PR branch, pr-description.md, and CI verification are needed

## Execution Flow

### Stage 1: Input Validation
Validate task_number exists, task_type is "pr", and an implementation plan is present.

### Stage 2: Preflight Status Update
Update status to "implementing" BEFORE invoking subagent.

```bash
bash .claude/scripts/update-task-status.sh preflight "$task_number" implement "$session_id"
```

### Stage 3: Prepare Delegation Context

PR-specific context for the cslib-implementation-agent:

- Target output: `specs/{NNN}_{SLUG}/pr-description.md` (canonical PR description file)
- Branch strategy: Create from `upstream/main` using `git checkout upstream/main -b feat/{slug}`, or validate existing `feat/` branch
- CI verification: Run the 7-step pipeline (lake test, checkInitImports, lint-style, lake shake)
- Standards: `pr-description-format.md` and `pr-conventions.md` (loaded via index-entries.json `languages: ["pr"]`)

```json
{
  "session_id": "sess_{timestamp}_{random}",
  "delegation_depth": 1,
  "delegation_path": ["orchestrator", "implement", "skill-pr-implementation"],
  "timeout": 3600,
  "task_context": {
    "task_number": N,
    "task_name": "{project_name}",
    "description": "{description}",
    "task_type": "pr"
  },
  "plan_path": "specs/{NNN}_{SLUG}/plans/MM_{short-slug}.md",
  "orchestrator_mode": true,
  "metadata_file_path": "specs/{NNN}_{SLUG}/.return-meta.json",
  "pr_branch_strategy": "create_from_upstream_main",
  "pr_description_path": "specs/{NNN}_{SLUG}/pr-description.md",
  "ci_verification_mode": "full_7_step_pipeline"
}
```

**Important**: The subagent's task is PR description generation and branch preparation --
NOT Lean proof implementation. The agent should:
1. Analyze code changes on the feature branch
2. Generate pr-description.md following the canonical format from pr-description-format.md
3. Create or validate the feature branch
4. Run the CI verification pipeline
5. Write `.return-meta.json` with status `implemented` when done

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

### Stage 6: Update Task Status (Postflight — PR READY)

**CRITICAL DIFFERENCE**: This skill calls `pr_ready` as the status target, NOT `implement`.
This sets the task to `[PR READY]` instead of `[COMPLETED]`, directing the user to run `/merge`.

```bash
bash .claude/scripts/update-task-status.sh postflight "$task_number" pr_ready "$session_id"
```

Do NOT call `postflight implement` -- that would incorrectly mark the task as `[COMPLETED]`
before the PR has been submitted.

### Stage 7: Link Artifacts
Add pr-description.md artifact to state.json with summary. Update TODO.md per
`@.claude/context/patterns/artifact-linking-todo.md` with `field_name=**Summary**`,
`next_field=**Description**`.

Artifact type: `pr_description`, path: `specs/{NNN}_{SLUG}/pr-description.md`.

**base_branch**: Also record the base branch in the state.json task entry. This field is read
by the `/pr` command to set `--base` when creating the PR. Use the branch name the PR will
target (e.g., `"main"` for direct upstream PRs, or `"feat/parent-branch"` for stacked PRs).

The subagent should determine and report the base branch used (typically `"main"` unless
this task is stacked on top of another unmerged PR).

```bash
# Write base_branch to state.json task metadata
CSLIB_DIR="/home/benjamin/Projects/cslib"
CSLIB_STATE="$CSLIB_DIR/specs/state.json"
base_branch_used="main"  # or the parent branch for stacked PRs

jq --argjson num "$task_number" \
   --arg branch "$base_branch_used" \
   '.active_projects |= map(if .project_number == $num then . + {"base_branch": $branch} else . end)' \
   "$CSLIB_STATE" > /tmp/state.tmp && mv /tmp/state.tmp "$CSLIB_STATE"
```

### Stage 8: Git Commit
Commit changes with session ID.

### Stage 9: Return Brief Summary

Include a message directing the user to run `/merge` now that the task is `[PR READY]`:

> PR preparation complete. Task is now [PR READY].
> Run `/merge` to create the pull request.

## MUST NOT (Postflight Boundary)

After the agent returns, this skill MUST NOT:

1. **Edit .lean files** - All CSLib proof work is done by agent
2. **Run lake build/test/lint** - Verification is done by agent
3. **Use lean-lsp MCP tools** - Domain tools are for agent use only
4. **Grep for sorries** - Debt analysis is agent work
5. **Write pr-description.md** - Artifact creation is agent work
6. **Call `postflight implement`** - This skill MUST use `postflight pr_ready` to set [PR READY]

> **PROHIBITION**: If the subagent returned partial or failed status, the lead skill MUST NOT attempt to continue, complete, or "fill in" the subagent's work. Report the partial/failed status and let the user re-run `/implement` to resume.

The postflight phase is LIMITED TO:
- Reading agent metadata file
- Updating state.json via jq (using `pr_ready` status target)
- Updating TODO.md status marker via Edit
- Linking artifacts in state.json
- Git commit
- Cleanup of temp/marker files

Reference: @.claude/context/standards/postflight-tool-restrictions.md

## Return Format

Brief text summary (NOT JSON).
