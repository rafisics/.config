# Anti-Analysis Contract (H2) — Lean4 Override

This file overrides the core `anti-analysis.md` contract for Lean4 tasks.
It adds a formal proof line bar, lean-specific forbidden conclusions, and
sub-sorry policy enforcement for leaf-only sorries.

Base contract: `@.claude/context/contracts/anti-analysis.md`

## Formal Proof Line Bar (Lean4 H2 Enforcement)

The H2 read budget applies with a lean4-specific milestone requirement:

**The first sorry-free lemma MUST be proved within the first 30% of tool calls.**

This replaces the base contract's generic "first file creation within 20% of tool calls"
bar. For lean4 implementation dispatches, a file write that contains only `sorry`-stubs
does NOT satisfy the bar. A file write satisfies the bar only when at least one lemma
has a complete, sorry-free proof body.

**Enforcement**: If you have used 30% of your estimated tool call budget and every lemma
written so far contains `sorry`, you are in violation. Prove at least one complete leaf
lemma immediately before continuing with more complex goals.

## Lean4 Forbidden Conclusions

The following outputs are NOT acceptable as final deliverables from a lean4 implementation
dispatch (in addition to the base contract's forbidden conclusions):

1. "This theorem needs a different approach" — without stating the concrete type-mismatch
   (exact goal state, exact type of the proposed term, exact unification failure)
2. "The tactic failed but the approach is correct" — without a `lean_goal` state showing
   what remains and at least one alternative tactic attempt via `lean_multi_attempt`
3. "Mathlib likely has a lemma for this" — without having called `lean_leansearch` or
   `lean_loogle` to find it
4. "This is a known issue with lean's elaboration" — without a minimal reproducer in
   `lean_run_code` demonstrating the issue

These are lean4-specific analysis-paralysis signatures. Dispatches that produce them
without accompanying proof progress have failed.

## Settled-Design Preamble for Lean4

At the start of each lean4 implementation dispatch, restate:

1. The proof strategy for this phase (direct, induction, contradiction, construction)
2. The tactic pipeline decided for the main goal (simp / omega / aesop / etc.)
3. Which sorries are inherited from the previous dispatch (cite the sorry_inventory)
4. What has been built and verified in prior phases (do not regress)

Example preamble:
```
Settled design for this phase:
- Strategy: structural induction on the list argument
- Tactic pipeline: intro + induction + simp [List.length_cons]
- Inherited sorries: none (prior phase had zero sorry at exit)
- Preserved: Ns.base_case (proved, committed in phase 1)
- Phase scope: Ns.inductive_step and Ns.main_theorem in Theories/Ns.lean
```

## Sub-Sorry Policy for Leaf Sorries

Leaf sub-sorries are permitted as progress markers under STRICT conditions:

**A sorry is a leaf sorry if and only if ALL of the following hold**:
1. It appears inside a `have` step or auxiliary `lemma` that is itself the argument
   to a larger theorem, NOT as the body of a top-level theorem
2. It has a comment: `-- sorry: assumes X; deferred because Y; next dispatch: Z`
3. It does NOT appear in the sorry_inventory of the final handoff as "main target"
   (it may appear as a leaf entry with `why_deferred` populated)

**Non-leaf sorries (i.e., main-target sorries) are NEVER acceptable as final output.**

If the main theorem body is `by sorry`, the dispatch has failed to make progress.
The escalation protocol (from lean-implementation-agent) applies.

## Interaction with H9 Sorry Inventory

Lean4 hard dispatches use the sorry_inventory field in `.orchestrator-handoff.json`
to track leaf sorries across dispatch boundaries. At the end of each dispatch:

1. All remaining sorries (leaf or otherwise) MUST be enumerated in `sorry_inventory`
2. Each entry requires: `{file, line, statement, assumption, why_deferred, next_dispatch}`
3. The orchestrator uses sorry_inventory to dispatch targeted follow-ups
4. A dispatch with sorries but an empty sorry_inventory is NON-CONFORMING
