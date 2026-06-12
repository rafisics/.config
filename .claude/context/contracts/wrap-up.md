# Wrap-Up and Handoff Contract (H9)

This contract implements H9: Handoff and Commit Discipline. Every hard-mode implementation
dispatch ends with a complete handoff artifact and a set of green-build incremental commits.
The orchestrator relies on handoff JSON to drive the next dispatch cycle; incomplete handoffs
break the pipeline.

## Orchestrator Handoff JSON Schema

Every hard-mode implementation dispatch MUST write `.orchestrator-handoff.json` before
terminating. Maximum 400 tokens. Required fields:

```json
{
  "status": "implemented | partial | blocked",
  "phases_completed": 2,
  "phases_total": 5,
  "sorry_inventory": [],
  "blockers": [
    {
      "phase": 3,
      "target": "exact description of what was attempted",
      "verbatim_goal": "exact text from plan checklist item",
      "what_was_tried": "one sentence",
      "why_it_failed": "one sentence"
    }
  ],
  "continuation_path": "specs/{NNN}_{SLUG}/handoffs/phase-{P}-handoff-{TS}.md"
}
```

**Field semantics**:
- `sorry_inventory`: Array of {file, line, statement} for each sorry introduced (lean4 domains)
- `blockers`: MUST include verbatim goal text (from the plan checklist) for each blocker.
  Paraphrasing is a defect -- the orchestrator uses verbatim text for re-dispatch prompts.
- `continuation_path`: Path to the handoff markdown artifact if `status != "implemented"`.
  Null when status is "implemented".

## Continuation Handoff Markdown

When `status = "partial"` or `status = "blocked"`, the agent MUST also write a handoff
markdown artifact at `continuation_path`. Required sections:

1. **Immediate Next Action**: Exactly what the next agent should do first (1-3 sentences)
2. **Current State**: What files exist, what was completed, what is in an inconsistent state
3. **Key Decisions Made**: Architectural choices made during this dispatch that bind successors
4. **What NOT to Try**: Approaches attempted and failed, with brief failure reasons
5. **Remaining Goals** (verbatim from plan): Copy checklist items for incomplete work
6. **References**: Plan path, progress file path, key files

The handoff markdown is read by the successor agent, not the orchestrator. Write it for
an agent with no prior context about this task.

## Incremental Commit Discipline

Hard-mode agents commit at every green-build milestone. Never accumulate all changes into
a single end-of-dispatch commit.

**Commit triggers**:
- A new file is complete and syntactically valid
- A phase checklist item is verified done
- A test passes that previously failed
- Any other "green checkpoint"

**Commit format**:
```bash
git commit -m "task {N} phase {P}: {step description}

Session: {session_id}"
```

**Before each commit**:
1. Verify the build is green (or explicitly note "no build applicable for task type")
2. Check that no previously-passing tests now fail
3. Verify no sorry was introduced without being in the sorry_inventory

## Build-Green Invariant

At every commit, the following invariants hold:

1. **No regressions**: Completed work (phases marked [COMPLETED]) continues to pass its
   verification criteria
2. **Syntactically valid**: All modified files are syntactically valid for their language
3. **No leftover scaffolding**: No TODO-stubs, placeholder functions, or half-written code
   blocks (except explicitly noted sorry-placeholders in lean4 domains)

Violating the build-green invariant is a critical defect. Do not commit broken work and
"continue in the next dispatch." Fix the regression before committing.

## Domain Specialization

- **lean4**: sorry_inventory is mandatory and must be populated. Each sorry includes
  the statement (verbatim from source), the location (file:line), and the justification
- **z3**: handoff JSON includes `assertion_inventory` with any un-verified assertions
