## CSLib Extension

This project includes CSLib Lean 4 computer science library support via the cslib extension.

### Language Routing

| Language | Research Tools | Implementation Tools |
|----------|----------------|---------------------|
| `cslib` | WebSearch, WebFetch, Read, lean-lsp MCP (inherited) | Read, Write, Edit, Bash (lake build, lake test, lake lint, lake exe checkInitImports, lake exe lint-style, lake shake) |
| `pr` | WebSearch, WebFetch, Read, Bash | Read, Write, Edit, Bash (git, lake build, lake test) |

### Skill-Agent Mapping

| Skill | Agent | Model | Purpose |
|-------|-------|-------|---------|
| skill-cslib-research | cslib-research-agent | opus | CSLib formalization research with lean-lsp MCP |
| skill-cslib-implementation | cslib-implementation-agent | sonnet | CSLib proof implementation with CI verification |
| skill-pr-implementation | cslib-implementation-agent | sonnet | PR description preparation only -- produces pr-description.md, transitions task to [PR READY]; branch creation and CI handled by /pr |
| skill-cslib-research-hard | cslib-research-hard-agent | opus | Hard-mode CSLib research: adversarial verification (H4), BibKey citation grounding (H3) |
| skill-cslib-implementation-hard | cslib-implementation-hard-agent | sonnet | Hard-mode CSLib proof implementation: anti-analysis (H2), sorry_inventory (H9), territory (H7) |

### When to Use --hard for CSLib Tasks

Use `/research N --hard`, `/plan N --hard`, or `/implement N --hard` when one or more of
the following apply to a CSLib task:

1. **Previous research produced analysis-only output** with no actionable proof direction
   (no Lean code sketches, no Mathlib lemma candidates, no reuse check results)
2. **Task involves faithful transcription of a published CS paper** into Lean 4
   (literature-backed: bisimulation theorems, operational semantics rules, type system proofs)
3. **Task has been in [IMPLEMENTING] for 2+ dispatch cycles** without completing any phase
4. **Proof requires BibKey citation traceability** against CSLib's `references.bib`
5. **Task involves multiple parallel proof obligations** requiring territory contracts (H7)
   to prevent file conflicts between agents

**Hard mode adds** (over standard cslib skills):
- H2: Strict read budget -- first proof write within 20% of tool calls
- H3: BibKey verification against `references.bib` for all cited theorems
- H4: Adversarial self-verification pass challenging every recommendation
- H7: Territory contracts for parallel implementation phases
- H9: `sorry_inventory` in every orchestrator handoff JSON

**Cost impact**: `--hard` multiplies token cost ~3-5x over standard cslib skills.
Use for formally complex or previously-deflected tasks only.

### MCP Integration

The `lean-lsp` MCP server is inherited from the lean extension dependency and provides:
- Goal state inspection (`lean_goal`)
- Proof search (`lean_state_search`, `lean_hammer_premise`)
- Mathlib/CSLib lookup (`lean_loogle`, `lean_leansearch`, `lean_leanfinder`)

### CI Verification Pipeline

CSLib implementations must pass:
- `lake test` - Run CslibTests suite
- `lake exe checkInitImports` - Verify Cslib.Init imports
- `lake exe lint-style` - Style linting
- `lake shake --add-public --keep-implied --keep-prefix` - Dependency analysis
