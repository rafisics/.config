---
name: skill-planner
description: Create phased implementation plans from research findings. Invoke when a task needs an implementation plan.
allowed-tools: Agent, Bash, Edit, Read, Write
# Original context (now loaded by subagent):
#   - .claude/context/formats/plan-format.md
#   - .claude/context/workflows/task-breakdown.md
# Original tools (now used by subagent):
#   - Read, Write, Edit, Glob, Grep
---

# Planner Skill

Thin wrapper that delegates plan creation to `planner-agent` subagent.

**IMPORTANT**: This skill implements the skill-internal postflight pattern. After the subagent returns,
this skill handles all postflight operations (status update, artifact linking, git commit) before returning.
This eliminates the "continue" prompt issue between skill return and orchestrator.

## Context References

Reference (do not load eagerly):
- Path: `.claude/context/formats/return-metadata-file.md` - Metadata file schema
- Path: `.claude/context/patterns/postflight-control.md` - Marker file protocol
- Path: `.claude/context/patterns/file-metadata-exchange.md` - File I/O helpers
- Path: `.claude/context/patterns/jq-escaping-workarounds.md` - jq escaping patterns (Issue #1132)
- Path: `.claude/scripts/orchestrator-postflight.sh` - Shared postflight pipeline (Stages 6-10)

Note: This skill is a thin wrapper with internal postflight. Context is loaded by the delegated agent.

## Trigger Conditions

This skill activates when:
- Task status is any non-terminal state (not completed, not abandoned)
- /plan command is invoked
- Implementation approach needs to be formalized

---

## Execution Flow

### Stage 1: Input Validation

Validate required inputs:
- `task_number` - Must be provided and exist in state.json
- Task status must allow planning

```bash
# Lookup task
task_data=$(jq -r --argjson num "$task_number" \
  '.active_projects[] | select(.project_number == $num)' \
  specs/state.json)

# Validate exists
if [ -z "$task_data" ]; then
  return error "Task $task_number not found"
fi

# Extract fields
task_type=$(echo "$task_data" | jq -r '.task_type // "general"')
status=$(echo "$task_data" | jq -r '.status')
project_name=$(echo "$task_data" | jq -r '.project_name')
description=$(echo "$task_data" | jq -r '.description // ""')

# Validate status (only block terminal states)
if [ "$status" = "completed" ] || [ "$status" = "abandoned" ] || [ "$status" = "expanded" ]; then
  return error "Task is in terminal state [$status]"
fi
```

---

### Stage 2: Preflight Status Update

Update task status to "planning" BEFORE invoking subagent.

The centralized script handles state.json, TODO.md task entry status marker, and TODO.md Task Order status marker atomically:

```bash
bash .claude/scripts/update-task-status.sh preflight $task_number plan $session_id
```

If the script exits non-zero, stop execution and return error. Exit code 2 indicates state.json failure; exit code 3 indicates TODO.md failure.

---

### Stage 3: Create Postflight Marker

Create the marker file to prevent premature termination:

```bash
# Ensure task directory exists
padded_num=$(printf "%03d" "$task_number")
mkdir -p "specs/${padded_num}_${project_name}"

cat > "specs/${padded_num}_${project_name}/.postflight-pending" << EOF
{
  "session_id": "${session_id}",
  "skill": "skill-planner",
  "task_number": ${task_number},
  "operation": "plan",
  "reason": "Postflight pending: status update, artifact linking, git commit",
  "created": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "stop_hook_active": false
}
EOF
```

---

### Stage 3a: Calculate Artifact Number

Read `next_artifact_number` from state.json and use (current-1) since plan stays in the same round as research:

```bash
# Read next_artifact_number from state.json
next_num=$(jq -r --argjson num "$task_number" \
  '.active_projects[] | select(.project_number == $num) | .next_artifact_number // 1' \
  specs/state.json)

# Plan uses (current - 1) to stay in the same round as research
# If next_artifact_number is 1 (no research yet), use 1
if [ "$next_num" -le 1 ]; then
  artifact_number=1
else
  artifact_number=$((next_num - 1))
fi

# Fallback for legacy tasks: count existing plan artifacts
if [ "$next_num" = "null" ] || [ -z "$next_num" ]; then
  padded_num=$(printf "%03d" "$task_number")
  count=$(ls "specs/${padded_num}_${project_name}/plans/"*[0-9][0-9]*.md 2>/dev/null | wc -l)
  artifact_number=$((count + 1))
fi

artifact_padded=$(printf "%02d" "$artifact_number")
```

**Note**: Plan does NOT increment `next_artifact_number` in state.json. Only research advances the sequence. Plan uses `(current - 1)` to share the same round number as the preceding research.

---

### Stage 4a: Memory Retrieval (Auto)

Retrieve relevant memories from the memory system to inject into the delegation context.

**Skip if**: `clean_flag` is true in the delegation context (from `--clean` command flag).

```bash
# Check clean_flag
if [ "$clean_flag" != "true" ]; then
  memory_context=$(bash .claude/scripts/memory-retrieve.sh "$description" "$task_type" "" 2>/dev/null) || memory_context=""
fi

# memory_context will be empty string if:
# - clean_flag is true (skipped)
# - memory-index.json missing or empty
# - no keywords matched any entries
# - script exited with error
```

If `memory_context` is non-empty, it will be injected into the Stage 5 prompt alongside the format specification from Stage 4b. If empty, no memory block is injected.

---

### Stage 4: Prepare Delegation Context

**Prior plan discovery**: Find the latest existing plan file (if any) to pass as reference context.

```bash
# Discover prior plan (if any)
padded_num=$(printf "%03d" "$task_number")
prior_plan_path=$(ls -1 "specs/${padded_num}_${project_name}/plans/"*.md 2>/dev/null | sort -V | tail -1)
# prior_plan_path will be empty if no prior plans exist
```

Prepare delegation context for the subagent:

```json
{
  "session_id": "sess_{timestamp}_{random}",
  "delegation_depth": 1,
  "delegation_path": ["orchestrator", "plan", "skill-planner"],
  "timeout": 1800,
  "task_context": {
    "task_number": N,
    "task_name": "{project_name}",
    "description": "{description}",
    "task_type": "{task_type}"
  },
  "artifact_number": "{artifact_number from Stage 3a}",
  "effort_flag": "{effort_flag from command, null if not set}",
  "model_flag": "{model_flag from command, null if not set}",
  "roadmap_flag": "{roadmap_flag from command, false if not set}",
  "research_path": "{path to research report if exists}",
  "prior_plan_path": "{path to latest prior plan if exists}",
  "roadmap_path": "specs/ROADMAP.md",
  "metadata_file_path": "specs/{NNN}_{SLUG}/.return-meta.json"
}
```

**Note**: The `artifact_number` field tells the agent which sequence number to use for artifact naming (e.g., `01`, `02`). Plan uses `(next_artifact_number - 1)` to share the same round as the preceding research.

**Model/Effort Flags**: If `model_flag` is set (haiku, sonnet, opus), pass it as the `model` parameter on the Agent tool to override the agent's frontmatter default. If `effort_flag` is set (fast, hard), include it as prompt context for reasoning depth guidance.

---

### Stage 4b: Read and Inject Format Specification

Read the plan format file and prepare it for injection into the subagent prompt. This ensures the subagent always has the full format specification in its context, regardless of whether it reads the file itself.

```bash
format_content=$(cat .claude/context/formats/plan-format.md)
```

The format content will be included as a delimited section in the Stage 5 prompt (see below).

---

### Stage 5: Invoke Subagent

**CRITICAL**: You MUST use the **Agent** tool to spawn the subagent.

**Required Tool Invocation**:
```
Tool: Agent (NOT Skill, NOT Plan)
Parameters:
  - subagent_type: "planner-agent"
  - prompt: [Include task_context, delegation_context, research_path, metadata_file_path,
             AND the format specification from Stage 4b as shown below]
  - description: "Execute planning for task {N}"
```

**Format Injection**: Include the format specification from Stage 4b in the prompt as a clearly-delimited section:

```
<artifact-format-specification>
## CRITICAL: Plan Format Requirements

You MUST follow this format specification exactly when writing the plan artifact.
Non-compliance will be caught by postflight validation.

{format_content from Stage 4b}
</artifact-format-specification>
```

Place this section AFTER the delegation context JSON and BEFORE any other instructions.

**Memory Context Injection**: If `memory_context` from Stage 4a is non-empty, include it in the prompt as a separate block:

```
{memory_context from Stage 4a -- already wrapped in <memory-context> tags}
```

Place the memory context block AFTER the format specification and BEFORE the task-specific instructions. Do NOT inject an empty `<memory-context>` block when no memories were retrieved.

**DO NOT** use `Skill(planner-agent)` - this will FAIL.

The subagent will:
- Load planning context files
- Analyze task requirements and research
- Decompose into logical phases
- Identify risks and mitigations
- Create plan in `specs/{NNN}_{SLUG}/plans/`
- Write metadata to `specs/{NNN}_{SLUG}/.return-meta.json`
- Return a brief text summary (NOT JSON)

---

### Stage 5b: Self-Execution Fallback

**CRITICAL**: If you performed the work above WITHOUT using the Agent tool (i.e., you read files,
wrote artifacts, or updated metadata directly instead of spawning a subagent), you MUST write a
`.return-meta.json` file now before proceeding to postflight. Use the schema from
`return-metadata-file.md` with status value `"planned"` and the appropriate artifact information.

If you DID use the Agent tool (Stage 5), skip this stage -- the subagent already wrote the metadata.

---

## Postflight (ALWAYS EXECUTE)

The following stages MUST execute after work is complete, whether the work was done by a
subagent (Stage 5) or inline (Stage 5b). Do NOT skip these stages for any reason.

### Stage 6: Run Shared Postflight Script

Delegate all postflight operations (metadata read, artifact validation, status update, memory
candidates propagation, artifact linking, TODO.md regeneration, TTS notification, git commit,
and cleanup) to the shared script:

```bash
bash .claude/scripts/orchestrator-postflight.sh \
    "$task_number" "$project_name" "$padded_num" "$session_id" "plan"
```

The shared script handles Stages 6-10 (read metadata, validate plan artifact, update task
status to "planned", propagate memory_candidates, link artifacts in state.json, regenerate
TODO.md, fire TTS notification, git commit with "task N: create implementation plan", and
cleanup). This also fixes the previously missing memory_candidates propagation for the planner.

**On partial/failed**: The script still runs cleanup. Task status remains "planning" for
resume (the shared script only calls `update-task-status.sh` when status is "planned").

---

### Stage 7: Return Brief Summary

Return a brief text summary (NOT JSON). Example:

```
Plan created for task {N}:
- {phase_count} phases defined, {estimated_hours} hours estimated
- Key phases: {phase names}
- Created plan at specs/{NNN}_{SLUG}/plans/MM_{short-slug}.md
- Status updated to [PLANNED]
- Changes committed
```

---

## Error Handling

### Input Validation Errors
Return immediately with error message if task not found or status invalid.

### Metadata File Missing
If subagent didn't write metadata file:
1. Keep status as "planning"
2. Do not cleanup postflight marker
3. Report error to user

### Git Commit Failure
Non-blocking: Log failure but continue with success response.

### jq Parse Failure
jq postflight operations are handled by `orchestrator-postflight.sh` which uses Issue #1132-safe
patterns throughout (`--arg atype` and `select(.type == "X" | not)`). If the shared script
fails, check its output for jq error details. See `jq-escaping-workarounds.md` for patterns.

### Subagent Timeout
Return partial status if subagent times out (default 1800s).
Keep status as "planning" for resume.

---

## MUST NOT (Postflight Boundary)

After the agent returns, this skill MUST NOT:

1. **Edit source files** - All planning work is done by agent
2. **Run build/test commands** - Verification is done by agent
3. **Use research tools** - Web/codebase search is for agent use only
4. **Analyze task requirements** - Analysis is agent work
5. **Write plan files** - Artifact creation is agent work

The postflight phase is LIMITED TO:
- Calling `orchestrator-postflight.sh` which handles: reading metadata, validating artifact,
  calling `update-task-status.sh`, propagating memory_candidates, linking artifacts in state.json,
  regenerating TODO.md, TTS notification, git commit, and cleanup

Reference: @.claude/context/standards/postflight-tool-restrictions.md

---

## Return Format

This skill returns a **brief text summary** (NOT JSON). The JSON metadata is written to the file and processed internally.

Example successful return:
```
Plan created for task 414:
- 5 phases defined, 2.5 hours estimated
- Covers: agent structure, execution flow, error handling, examples, verification
- Created plan at specs/414_create_planner_agent/plans/MM_{short-slug}.md
- Status updated to [PLANNED]
- Changes committed with session sess_1736700000_abc123
```

Example partial return:
```
Plan partially created for task 414:
- 3 of 5 phases defined before timeout
- Partial plan saved at specs/414_create_planner_agent/plans/MM_{short-slug}.md
- Status remains [PLANNING] - run /plan 414 to complete
```
