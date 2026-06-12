# Anti-Analysis Contract (H2)

This contract implements H2: Anti-Analysis-Paralysis. It is a hard behavioral constraint
for all hard-mode agents. The single highest-value technique distilled from the BimodalLogic
task-273 orchestration session: per-phase dispatch moved implementation from 0 lines across
3 dispatches to 2,400+ lines across 13 dispatches only after this contract was in force.

## Read Budget

- Maximum 15-20% of total effort on reading, searching, and analysis before first file edit
- First file creation or modification MUST happen within the first 20% of tool calls
- Reading an existing file for context is permitted; re-reading a file you already read is
  a context-pressure signal (see context-exhaustion-detection.md), not a license to plan

**Enforcement**: If you have made 15+ tool calls with no Write or Edit, you are in violation.
Write something immediately. A partial first file is better than continued analysis.

## Forbidden Conclusions

The following outputs are NOT acceptable as final deliverables from an implementation dispatch:

1. "The current approach is wrong" — without a concrete counterexample and an alternative
2. "A different representation is needed" — without implementing at least the skeleton of
   the new representation in the same dispatch
3. "Estimated N lines of work remain" — as the primary output of a dispatch
4. "I need to understand X better before proceeding" — without having attempted X
5. "This requires further research" — in an implementation dispatch (research dispatches exist)
6. "The design has a fundamental issue" — without either fixing it or stating the exact
   counterexample that makes it unfixable

These are analysis-paralysis signatures. Agents that produce them without accompanying
implementation have failed the dispatch.

## Defect Bar

An agent may claim a design decision is defective ONLY when ALL of the following hold:

1. **Concrete counterexample**: A specific case is stated verbatim (not described in general)
2. **Current behavior**: What the current implementation does on that case
3. **Required behavior**: What the correct implementation must do
4. **Isolation**: The defect is in a specific identified component (not "the whole approach")

Without all four elements, a defect claim is analysis, not implementation work.

## Sub-Sorry Policy (for formal verification domains)

- Tightly scoped, documented leaf sub-sorrys are acceptable progress markers
- Main target theorems as sorry-stubs are not acceptable as final dispatch output
- Each sorry must include a comment stating: (a) what it assumes, (b) why it was deferred,
  (c) which next dispatch should address it

## Settled-Design Preamble Protocol

At the start of each dispatch, the agent MUST restate:

1. The decided design (1-3 sentences)
2. Ruled-out alternatives (brief list with rejection reasons)
3. What has been completed and must not regress

This prevents "re-opening" settled decisions during implementation.

## Domain Specialization

This is the domain-agnostic baseline. Extensions may override with stricter versions:

- **lean4**: H2 applies with a formal proof line bar (first sorry-free lemma within 20 tool calls)
- **z3**: H2 applies with a satisfying-assignment bar (first passing assert within 20 tool calls)
- Extension overrides live in `.claude/extensions/{domain}/context/contracts/anti-analysis.md`
